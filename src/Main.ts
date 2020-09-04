import {
    Bridge,
    AppServiceRegistration,
    Request,
} from 'matrix-appservice-bridge';
// import { createClient } from 'matrix-js-sdk';
import * as sdk from 'matrix-js-sdk';
import { Client, ClientWebsocket } from './mattermost/Client';
import {
    Config,
    Mapping,
    setConfig,
    config,
    RELOADABLE_CONFIG,
} from './Config';
import { isDeepStrictEqual } from 'util';
import { none, notifySystemd, allSettled } from './utils/Functions';
import { User } from './entities/User';
import { MattermostMessage, MatrixClient } from './Interfaces';
import AdminEndpoint from './AdminEndpoint';
import MatrixUserStore from './MatrixUserStore';
import MattermostUserStore from './MattermostUserStore';
import Channel from './Channel';
import Mutex from './utils/Mutex';
import log from './Logging';
import { EventEmitter } from 'events';

export default class Main extends EventEmitter {
    private readonly matrixMutex: Mutex;
    private readonly mattermostMutex: Mutex;

    private readonly ws: ClientWebsocket;
    private readonly bridge: Bridge;

    private adminEndpoint?: AdminEndpoint;
    private remoteUserRegex: RegExp;

    public botClient: MatrixClient;

    public initialized: boolean;
    public killed: boolean;

    public readonly client: Client;

    public readonly channelsByMatrix: Map<string, Channel>;
    public readonly channelsByMattermost: Map<string, Channel>;
    public readonly channelsByTeam: Map<string, Channel[]>;

    // Channels include successfully bridge channels.
    // Mappings are ones that are specified in the config file
    public readonly mappingsByMatrix: Map<string, Mapping>;
    public readonly mappingsByMattermost: Map<string, Mapping>;

    public readonly matrixUserStore: MatrixUserStore;
    public readonly mattermostUserStore: MattermostUserStore;

    constructor(
        public readonly registration: AppServiceRegistration,
        private readonly exitOnFail: boolean = true,
    ) {
        super();
        this.bridge = new Bridge({
            homeserverUrl: config().homeserver.url,
            domain: config().homeserver.server_name,
            registration,
            controller: {
                onUserQuery: () => {
                    return {};
                },
                onEvent: request => {
                    void this.onMatrixEvent(request);
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

        this.botClient = this.getMatrixClient(
            `@${config().matrix_bot.username}:${
                config().homeserver.server_name
            }`,
        );

        this.remoteUserRegex = new RegExp(
            `@${config().matrix_localpart_prefix}.*:${
                config().homeserver.server_name
            }`,
        );

        this.initialized = false;

        this.client = new Client(
            config().mattermost_url,
            config().mattermost_bot_userid,
            config().mattermost_bot_access_token,
        );
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

        this.killed = false;

        for (const map of config().mappings) {
            if (this.mappingsByMattermost.has(map.mattermost)) {
                log.error(
                    `Mattermost channel ${map.mattermost} already bridged. Skipping bridge ${map.mattermost} <-> ${map.matrix}`,
                );
                if (config().forbid_bridge_failure) {
                    void this.killBridge(1);
                    return;
                }
                continue;
            }
            if (this.mappingsByMatrix.has(map.matrix)) {
                log.error(
                    `Matrix channel ${map.matrix} already bridged. Skipping bridge ${map.mattermost} <-> ${map.matrix}`,
                );
                if (config().forbid_bridge_failure) {
                    void this.killBridge(1);
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
            void this.killBridge(1);
        });

        if (config().admin_port !== undefined) {
            this.adminEndpoint = new AdminEndpoint(this);
        }
    }

    public async init(): Promise<void> {
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

        void notifySystemd();
        this.initialized = true;
        this.emit('initialize');
    }

    private async leaveUnbridgedChannels(): Promise<void> {
        await Promise.all([
            this.leaveUnbridgedMattermostChannels(),
            this.leaveUnbridgedMatrixRooms(),
        ]);
    }

    private async leaveUnbridgedMatrixRooms(): Promise<void> {
        const rooms = (await this.botClient.getJoinedRooms()).joined_rooms;

        await Promise.all(
            rooms.map(async room => {
                if (this.mappingsByMatrix.has(room)) {
                    return;
                }
                const members = Object.keys(
                    (await this.botClient.getJoinedRoomMembers(room)).joined,
                );
                await Promise.all(
                    members.map(async userid => {
                        if (this.isRemoteUser(userid)) {
                            await this.getMatrixClient(userid).leave(room);
                        }
                    }),
                );
                await this.botClient.leave(room);
            }),
        );
    }

    private async leaveUnbridgedMattermostChannels(): Promise<void> {
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

    public async killBridge(exitCode: number): Promise<void> {
        const killed = this.killed;
        this.killed = true;

        this.emit('kill');
        if (killed) {
            return;
        }
        // Otherwise, closing the websocket connection will initiate
        // the shutdown sequence again.
        this.ws.removeAllListeners('close');
        clearTimeout(this.bridge._intentLastAccessedTimeout);

        const results = await allSettled([
            this.ws.close(),
            this.bridge.appService.close(),
            this.adminEndpoint?.kill(),
            // Lock the channels so that we are not halfway through processing
            // a message.
            this.mattermostMutex.lock(),
            this.matrixMutex.lock(),
        ]);
        for (const result of results) {
            if (result.status === 'rejected') {
                log.error(`Error when killing bridge: ${result.reason.stack}`);
                exitCode = 1;
            }
        }
        if (this.exitOnFail) {
            process.exit(exitCode);
        }
    }

    public async updateConfig(
        oldConfig: Config,
        newConfig: Config,
    ): Promise<void> {
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

    private async updateBotProfile(): Promise<void> {
        try {
            await this.botClient.register(config().matrix_bot.username);
        } catch (e) {
            if (e.errcode !== 'M_USER_IN_USE') {
                throw e;
            }
        }

        const targetProfile = config().matrix_bot;
        const profile = await this.botClient
            .getProfileInfo(this.botClient.getUserId())
            .catch(() => ({ display_name: '' }));
        if (
            targetProfile.display_name &&
            profile.displayname !== targetProfile.display_name
        ) {
            await this.botClient.setDisplayName(targetProfile.display_name);
        }
    }

    private async onMattermostMessage(m: MattermostMessage): Promise<void> {
        await this.mattermostMutex.lock();
        log.time.debug('Process mattermost message');

        try {
            const userid = m.data.user_id ?? m.data.user?.id;

            if (userid) {
                if (
                    this.skipMattermostUser(userid) ||
                    !(await this.isMattermostUser(userid))
                ) {
                    log.debug(`Skipping echoed message: ${JSON.stringify(m)}`);
                    log.timeEnd.debug('Process mattermost message');
                    this.emit('mattermost');
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
        this.emit('mattermost');
    }

    private async onMatrixEvent(request: Request): Promise<void> {
        await this.matrixMutex.lock();
        log.time.debug('Process matrix message');

        try {
            const event = request.getData();
            log.debug(`Matrix event: ${JSON.stringify(event)}`);

            const channel = this.channelsByMatrix.get(event.room_id);
            if (channel !== undefined) {
                await channel.onMatrixEvent(event);
            } else if (
                event.type === 'm.room.member' &&
                event.content.membership === 'invite' &&
                event.state_key &&
                (event.state_key === this.botClient.userId ||
                    this.isRemoteUser(event.state_key)) &&
                event.content.is_direct
            ) {
                const client = this.getMatrixClient(event.state_key);
                await client.sendEvent(event.room_id, 'm.room.message', {
                    body:
                        'Private messaging is not supported for this bridged user',
                    msgtype: 'm.notice',
                });
                await client.leave(event.room_id);
            } else {
                log.debug(`Message for unknown room: ${event.room_id}`);
            }
        } catch (e) {
            log.warn(`Error when processing matrix event\n${e.stack}`);
        }
        log.timeEnd.debug('Process matrix message');

        this.matrixMutex.unlock();
        this.emit('matrix');
    }

    public async isMattermostUser(userid: string): Promise<boolean> {
        return (await this.getPuppetMatrixUser(userid)) === null;
    }

    public async getPuppetMatrixUser(
        mattermostUserId: string,
    ): Promise<User | null> {
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

    public isRemoteUser(userid: string): boolean {
        return this.remoteUserRegex.test(userid);
    }

    public skipMattermostUser(userid: string): boolean {
        const botMattermostUser = this.client.userid;
        const ignoredMattermostUsers = config().ignored_mattermost_users ?? [];
        return (
            userid === botMattermostUser ||
            ignoredMattermostUsers.includes(userid)
        );
    }

    public skipMatrixUser(userid: string): boolean {
        const botMatrixUser = this.botClient.getUserId();
        const ignoredMatrixUsers = config().ignored_matrix_users ?? [];
        return userid === botMatrixUser || ignoredMatrixUsers.includes(userid);
    }

    private static readonly mattermostMessageHandlers = {
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

    public getMatrixClient(userId: string): MatrixClient {
        return sdk.createClient({
            accessToken: this.registration.getAppServiceToken(),
            baseUrl: config().homeserver.url,
            userId,
            queryParams: {
                user_id: userId,
                access_token: this.registration.getAppServiceToken(),
            },
            scheduler: new (sdk as any).MatrixScheduler(),
            localTimeoutMs: 1000 * 60 * 2,
        } as any);
    }
}
