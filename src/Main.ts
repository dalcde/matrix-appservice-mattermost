import {
    Bridge,
    AppServiceRegistration,
    Request,
} from 'matrix-appservice-bridge';
import { Client, ClientWebsocket } from './mattermost/Client';
import {
    Config,
    Mapping,
    setConfig,
    config,
    RELOADABLE_CONFIG,
} from './Config';
import { isDeepStrictEqual } from 'util';
import { none, notifySystemd } from './utils/Functions';
import { User } from './entities/User';
import { MattermostMessage } from './Interfaces';
import AdminEndpoint from './AdminEndpoint';
import MatrixUserStore from './MatrixUserStore';
import MattermostUserStore from './MattermostUserStore';
import Channel from './Channel';
import Mutex from './utils/Mutex';
import log from './Logging';

export default class Main {
    readonly client: Client;
    readonly ws: ClientWebsocket;
    readonly mattermostUserStore: MattermostUserStore;
    readonly matrixUserStore: MatrixUserStore;

    // Channels include successfully bridge channels.
    readonly channelsByMattermost: Map<string, Channel>;
    readonly channelsByMatrix: Map<string, Channel>;
    readonly channelsByTeam: Map<string, Channel[]>;

    // Mappings are ones that are specified in the config file
    readonly mappingsByMattermost: Map<string, Mapping>;
    readonly mappingsByMatrix: Map<string, Mapping>;

    readonly bridge: Bridge;
    mattermostMutex: Mutex;
    matrixMutex: Mutex;
    initialized: boolean;
    adminEndpoint?: AdminEndpoint;

    constructor(registration: AppServiceRegistration) {
        this.bridge = new Bridge({
            homeserverUrl: config().homeserver.url,
            domain: config().homeserver.server_name,
            registration,
            controller: {
                onUserQuery: () => {
                    return {};
                },
                onEvent: request => {
                    this.onMatrixEvent(request);
                },
            },
            disableContext: true,
        });

        this.bridge.opts.userStore = undefined;
        this.bridge.opts.roomStore = undefined;
        this.bridge.opts.eventStore = undefined;

        this.bridge.run(
            config().appservice.port,
            config(),
            undefined,
            config().appservice.hostname,
        );

        this.initialized = false;

        this.client = new Client(
            config().mattermost_url,
            config().mattermost_bot_userid,
        );
        this.client.loginWithToken(config().mattermost_bot_access_token);
        this.ws = this.client.websocket();

        this.channelsByMatrix = new Map();
        this.channelsByMattermost = new Map();
        this.channelsByTeam = new Map();

        this.mappingsByMatrix = new Map();
        this.mappingsByMattermost = new Map();

        this.mattermostMutex = new Mutex();
        this.matrixMutex = new Mutex();
        this.mattermostUserStore = new MattermostUserStore(this);
        this.matrixUserStore = new MatrixUserStore(this);
        for (const map of config().mappings) {
            if (this.mappingsByMattermost.has(map.mattermost)) {
                log.error(
                    `Mattermost channel ${map.mattermost} already bridged. Skipping bridge ${map.mattermost} <-> ${map.matrix}`,
                );
                if (config().forbid_bridge_failure) {
                    this.killBridge(1);
                    return;
                }
                continue;
            }
            if (this.mappingsByMatrix.has(map.matrix)) {
                log.error(
                    `Matrix channel ${map.matrix} already bridged. Skipping bridge ${map.mattermost} <-> ${map.matrix}`,
                );
                if (config().forbid_bridge_failure) {
                    this.killBridge(1);
                    return;
                }
                continue;
            }

            const channel = new Channel(this, map.matrix, map.mattermost);
            this.channelsByMattermost.set(map.mattermost, channel);
            this.channelsByMatrix.set(map.matrix, channel);

            this.mappingsByMattermost.set(map.mattermost, map);
            this.mappingsByMatrix.set(map.matrix, map);
        }
        this.ws.on('message', m => this.onMattermostMessage(m));

        this.ws.on('error', e => {
            log.error(
                `Error when initializing websocket connection\n${e.stack}`,
            );
        });

        this.ws.on('close', () => {
            log.error('Mattermost websocket closed. Shutting down bridge');
            this.killBridge(1);
        });

        if (config().admin_port !== undefined) {
            this.adminEndpoint = new AdminEndpoint(this);
        }
    }

    async init(): Promise<void> {
        log.time.info('Bridge initialized');
        const botProfile = this.updateBotProfile().catch(e =>
            log.warn(`Error when updating bot profile\n${e.stack}`),
        );

        await Promise.all([
            this.mattermostMutex.lock(),
            this.matrixMutex.lock(),
        ]);

        await Promise.all(
            Array.from(this.channelsByMattermost, async ([, channel]) => {
                try {
                    await channel.syncChannel();
                    const team = await channel.getTeam();
                    const channels = this.channelsByTeam.get(team);
                    if (channels === undefined) {
                        this.channelsByTeam.set(team, [channel]);
                    } else {
                        channels.push(channel);
                    }
                } catch (e) {
                    log.error(
                        `Error when syncing ${channel.matrixRoom} with ${channel.mattermostChannel}\n${e.stack}`,
                    );
                    if (config().forbid_bridge_failure) {
                        await this.killBridge(1);
                    }
                    this.channelsByMattermost.delete(channel.mattermostChannel);
                    this.channelsByMatrix.delete(channel.matrixRoom);
                }
            }),
        );

        await this.leaveUnbridgedChannels();

        if (this.channelsByMattermost.size === 0) {
            log.info('No channels bridged successfully. Shutting down bridge.');
            // If we exit before notifying systemd, it is considered a failure
            await notifySystemd();
            await this.killBridge(0);
        }

        this.mattermostMutex.unlock();
        this.matrixMutex.unlock();

        await this.ws.openPromise;
        await botProfile;
        log.timeEnd.info('Bridge initialized');

        notifySystemd();
        this.initialized = true;
    }

    async leaveUnbridgedChannels(): Promise<void> {
        await Promise.all([
            this.leaveUnbridgedMattermostChannels(),
            this.leaveUnbridgedMatrixRooms(),
        ]);
    }

    async leaveUnbridgedMatrixRooms(): Promise<void> {
        const bot = this.bridge.getBot();
        const botIntent = this.bridge.getIntent();
        const rooms = await bot.getJoinedRooms();

        await Promise.all(
            rooms.map(async room => {
                if (this.mappingsByMatrix.has(room)) {
                    return;
                }
                const members = Object.keys(await bot.getJoinedMembers(room));
                await Promise.all(
                    members.map(async userid => {
                        if (bot.isRemoteUser(userid)) {
                            await this.bridge.getIntent(userid).leave(room);
                        }
                    }),
                );
                await botIntent.leave(room);
            }),
        );
    }

    async leaveUnbridgedMattermostChannels(): Promise<void> {
        const mattermostTeams = await this.client.get(
            `/users/${this.client.userid}/teams`,
        );

        const leaveMattermost = async (type: string, id: string) => {
            const members = await this.client.get(
                `/${type}s/${id}/members?page=0&per_page=10000`,
            );
            await Promise.all(
                members.map(async member => {
                    const user = await this.getPuppetMatrixUser(member.user_id);
                    if (user !== null) {
                        await user.client.delete(
                            `/${type}s/${id}/members/${member.user_id}`,
                        );
                    }
                }),
            );
            await this.client.delete(
                `/${type}s/${id}/members/${this.client.userid}`,
            );
        };

        await Promise.all(
            mattermostTeams.map(async team => {
                const teamId = team.id;
                const channels = await this.client.get(
                    `/users/${this.client.userid}/teams/${teamId}/channels`,
                );

                if (!channels.some(c => this.mappingsByMattermost.has(c.id))) {
                    await leaveMattermost('team', teamId);
                    return;
                }

                await Promise.all(
                    channels.map(async channel => {
                        if (this.mappingsByMattermost.has(channel.id)) {
                            return;
                        }
                        if (channel.name === 'town-square') {
                            // cannot leave town square
                            return;
                        }
                        await leaveMattermost('channel', channel.id);
                    }),
                );
            }),
        );
    }

    async killBridge(exitCode: number): Promise<never> {
        try {
            // Otherwise, closing the websocket connection will initiate
            // the shutdown sequence again.
            this.ws.removeAllListeners('close');
            clearTimeout(this.bridge._intentLastAccessedTimeout);
            await Promise.all([
                this.ws.close(),
                this.bridge.appService.close(),
                this.adminEndpoint?.kill(),
            ]);
            process.exit(exitCode);
        } catch (e) {
            log.error(`Failed to kill bridge. Exiting anyway\n${e.stack}`);
            process.exit(1);
        }
    }

    async updateConfig(oldConfig: Config, newConfig: Config): Promise<void> {
        for (const key of Object.keys(oldConfig)) {
            if (
                !RELOADABLE_CONFIG.has(key) &&
                !isDeepStrictEqual(oldConfig[key], newConfig[key])
            ) {
                log.error('Cannot hot reload config ');
            }
            log.setLevel(newConfig.logging);
            setConfig(newConfig);
        }
    }

    async updateBotProfile(): Promise<void> {
        const intent = this.bridge.getIntent();
        // The bot believes itelf to always be registered, even when it isn't.
        // This part is copied from matrix-appservice-slack.
        intent.opts.registered = false;
        await intent._ensureRegistered();
        const targetProfile = config().matrix_bot;
        const profile = await intent.getProfileInfo(
            this.bridge.getBot().getUserId(),
        );
        if (
            targetProfile.display_name &&
            profile.displayname !== targetProfile.display_name
        ) {
            await intent.setDisplayName(targetProfile.display_name);
        }
    }

    async onMattermostMessage(m: MattermostMessage): Promise<void> {
        await this.mattermostMutex.lock();
        log.time.debug('Process mattermost message');

        try {
            const userid = m.data.user_id ?? m.data.user?.id;

            if (userid) {
                if (
                    this.skipMattermostUser(userid) ||
                    !(await this.isMattermostUser(userid))
                ) {
                    log.debug(`Skipping echoed message from ${userid}`);
                    log.timeEnd.debug('Process mattermost message');
                    this.mattermostMutex.unlock();
                    return;
                }
            }

            log.debug(`Mattermost message: ${JSON.stringify(m)}`);
            const handler = Main.mattermostMessageHandlers[m.event];
            if (handler !== undefined) {
                await handler.bind(this)(m);
            } else if (m.broadcast.channel_id !== '') {
                // We may have been invited to channels that are not bridged;
                const channel = this.channelsByMattermost.get(
                    m.broadcast.channel_id,
                );
                if (channel !== undefined) {
                    await channel.onMattermostMessage(m);
                } else {
                    log.debug(
                        `Message for unknown channel_id: ${m.broadcast.channel_id}`,
                    );
                }
            } else if (m.broadcast.team_id !== '') {
                const channels = this.channelsByTeam.get(m.broadcast.team_id);
                if (channels === undefined) {
                    log.debug(
                        `Message for unknown team: ${m.broadcast.team_id}`,
                    );
                } else {
                    await Promise.all(
                        channels.map(c => c.onMattermostMessage(m)),
                    );
                }
            } else {
                log.debug(`Unkown event type: ${m.event}`);
            }
        } catch (e) {
            log.warn(`Error when processing mattermost message\n${e.stack}`);
        }
        log.timeEnd.debug('Process mattermost message');

        this.mattermostMutex.unlock();
    }

    async onMatrixEvent(request: Request): Promise<void> {
        await this.matrixMutex.lock();
        log.time.debug('Process matrix message');

        try {
            const bot = this.bridge.getBot();
            const event = request.getData();
            log.debug(`Matrix event: ${JSON.stringify(event)}`);

            const channel = this.channelsByMatrix.get(event.room_id);
            if (channel !== undefined) {
                await channel.onMatrixEvent(event);
            } else if (
                event.type === 'm.room.member' &&
                event.content.membership === 'invite' &&
                event.state_key &&
                (event.state_key === bot.getUserId() ||
                    bot.isRemoteUser(event.state_key)) &&
                event.content.is_direct
            ) {
                const intent = this.bridge.getIntent(event.state_key);
                await intent.sendEvent(event.room_id, 'm.room.message', {
                    body:
                        'Private messaging is not supported for this bridged user',
                    msgtype: 'm.notice',
                });
                await intent.leave(event.room_id);
            } else {
                log.debug(`Message for unknown room: ${event.room_id}`);
            }
        } catch (e) {
            log.warn(`Error when processing matrix event\n${e.stack}`);
        }
        log.timeEnd.debug('Process matrix message');

        this.matrixMutex.unlock();
    }

    async isMattermostUser(userid: string): Promise<boolean> {
        return (await this.getPuppetMatrixUser(userid)) === null;
    }

    async getPuppetMatrixUser(mattermostUserId: string): Promise<User | null> {
        const cached = this.matrixUserStore.byMattermostUserId.get(
            mattermostUserId,
        );
        if (cached !== undefined) {
            return cached;
        }
        const response = await User.findOne({
            mattermost_userid: mattermostUserId,
        });
        if (response === undefined || response.is_matrix_user === false) {
            return null;
        } else {
            return response;
        }
    }

    skipMattermostUser(userid: string): boolean {
        const botMattermostUser = this.client.userid;
        const ignoredMattermostUsers = config().ignored_mattermost_users ?? [];
        return (
            userid === botMattermostUser ||
            ignoredMattermostUsers.includes(userid)
        );
    }

    skipMatrixUser(userid: string): boolean {
        const botMatrixUser = this.bridge.getBot().getUserId();
        const ignoredMatrixUsers = config().ignored_matrix_users ?? [];
        return userid === botMatrixUser || ignoredMatrixUsers.includes(userid);
    }

    static readonly mattermostMessageHandlers = {
        hello: none,
        added_to_team: none,
        new_user: none,
        status_change: none,
        channel_viewed: none,
        preferences_changed: none,
        sidebar_category_updated: none,
        direct_added: async function (
            this: Main,
            m: MattermostMessage,
        ): Promise<void> {
            await this.client.post('/posts', {
                channel_id: m.broadcast.channel_id,
                message: 'This is a bot. You will not get a reply',
            });
        },
        user_updated: async function (
            this: Main,
            m: MattermostMessage,
        ): Promise<void> {
            const user = this.mattermostUserStore.get(m.data.user.id);
            if (user !== undefined) {
                await this.mattermostUserStore.updateUser(m.data.user, user);
            }
        },
    };
}
