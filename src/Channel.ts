import { Bridge, Intent } from 'matrix-appservice-bridge';
import { Client, Method, ClientError } from './mattermost/Client';
import log from './Logging';
import { remove, uniq, handlePostError } from './utils/Functions';
import Main from './Main';
import { Post } from './entities/Post';
import { MatrixMessage } from './Interfaces';
import { User } from './entities/User';
import {
    mattermostToMatrix,
    matrixToMattermost,
    constructMatrixReply,
} from './utils/Formatting';
import { config } from './Config';
import fetch from 'node-fetch';
import * as FormData from 'form-data';

const MAX_MEMBERS: number = 10000;

export default class Channel {
    team?: string;

    constructor(
        readonly main: Main,
        readonly matrixRoom: string,
        readonly mattermostChannel: string,
    ) {}

    async getMatrixUsers(): Promise<{
        real: Set<string>;
        remote: Set<string>;
    }> {
        const bot = this.main.bridge.getBot();

        const realMatrixUsers: Set<string> = new Set();
        const remoteMatrixUsers: Set<string> = new Set();

        const allMatrixUsers = Object.keys(
            await bot.getJoinedMembers(this.matrixRoom),
        );
        for (const matrixUser of allMatrixUsers) {
            if (bot.isRemoteUser(matrixUser)) {
                remoteMatrixUsers.add(matrixUser);
            } else {
                realMatrixUsers.add(matrixUser);
            }
        }
        return {
            real: realMatrixUsers,
            remote: remoteMatrixUsers,
        };
    }

    async getMattermostUsers(): Promise<Set<string>> {
        const mattermostUsers: Set<string> = new Set();
        const query = await this.main.client.send(
            'GET',
            `/channels/${this.mattermostChannel}/members?page=0&per_page=${MAX_MEMBERS}`,
        );

        for (let member of query) {
            mattermostUsers.add(member.user_id);
        }
        return mattermostUsers;
    }

    async getTeam(): Promise<string> {
        if (this.team === undefined) {
            this.team = (
                await this.main.client.get(
                    `/channels/${this.mattermostChannel}`,
                )
            ).team_id as string;
        }
        return this.team;
    }

    async joinMattermost(userid: string) {
        const team = await this.getTeam();
        try {
            await this.main.client.post(`/teams/${team}/members`, {
                user_id: userid,
                team_id: team,
            });
        } catch (e) {}
        await this.main.client.post(
            `/channels/${this.mattermostChannel}/members`,
            {
                user_id: userid,
            },
        );
    }

    async leaveMattermost(userid: string) {
        try {
            await this.main.client.delete(
                `/channels/${this.mattermostChannel}/members/${userid}`,
            );
        } catch (e) {
            if (
                e instanceof ClientError &&
                e.m.id === 'api.channel.remove.default.app_error'
            ) {
                log.debug(
                    `Cannot remove user ${userid} from default town-square channel`,
                );
            } else {
                throw e;
            }
        }
    }

    async syncChannel(): Promise<void> {
        const bridge = this.main.bridge;

        await Promise.all([
            bridge.getIntent().join(this.matrixRoom),
            this.joinMattermost(this.main.client.userid),
        ]);

        const [matrixUsers, mattermostUsers] = await Promise.all([
            this.getMatrixUsers(),
            this.getMattermostUsers(),
        ]);

        const ignoredMatrixUsers = config().ignored_matrix_users;
        const ignoredMattermostUsers = config().ignored_matrix_users;

        const promises: Promise<void>[] = [];
        for (const matrix_userid of matrixUsers.real) {
            if (this.main.skipMatrixUser(matrix_userid)) {
                continue;
            }
            promises.push(
                this.main.matrixUserStore
                    .getOrCreate(matrix_userid, true)
                    .then(user => {
                        mattermostUsers.delete(user.mattermost_userid);
                        return this.joinMattermost(user.mattermost_userid);
                    }),
            );
        }
        await Promise.all(promises);
        promises.length = 0;

        for (const userid of mattermostUsers) {
            if (this.main.skipMattermostUser(userid)) {
                continue;
            }
            promises.push(
                (async () => {
                    if (!(await this.main.isMattermostUser(userid))) {
                        this.leaveMattermost(userid);
                    } else {
                        const user = await this.main.mattermostUserStore.getOrCreate(
                            userid,
                            true,
                        );
                        matrixUsers.remote.delete(user.matrix_userid);
                        const intent = bridge.getIntent(user.matrix_userid);
                        await intent.join(this.matrixRoom);
                    }
                })(),
            );
        }

        await Promise.all(promises);
        promises.length = 0;

        for (const matrix_userid of matrixUsers.remote) {
            promises.push(
                (async () => {
                    const intent = bridge.getIntent(matrix_userid);
                    await intent.leave(this.matrixRoom);
                })(),
            );
        }
        await Promise.all(promises);
    }

    async onMattermostMessage(m: any) {
        const handler = Channel.mattermostMessageHandlers[m.event];
        if (handler === undefined) {
            log.debug(`Unknown matermost message type: ${m.event}`);
        } else {
            await handler.bind(this)(m);
        }
    }

    async onMatrixEvent(event: any) {
        const handler = Channel.matrixEventHandlers[event.type];
        if (handler === undefined) {
            log.debug(`Unknown matrix event type: ${event.type}`);
        } else {
            await handler.bind(this)(event);
        }
    }

    async sendMatrixMessage(
        intent: Intent,
        postid: string,
        message: MatrixMessage,
        metadata: { replyTo?: { matrix: string; mattermost: string } },
    ) {
        let rootid = postid;
        if (metadata.replyTo !== undefined) {
            const replyTo = metadata.replyTo;
            rootid = replyTo.mattermost;
            let original: any = undefined;
            try {
                original = await intent.getEvent(
                    this.matrixRoom,
                    replyTo.matrix,
                );
            } catch (e) {}
            if (original !== undefined) {
                constructMatrixReply(original, message);
            }
        }
        const event = await intent.sendMessage(this.matrixRoom, message);
        await Post.create({
            postid,
            rootid,
            eventid: event.event_id,
        }).save();
        return event.event_id;
    }

    static readonly mattermostMessageHandlers = {
        posted: async function (this: Channel, m: any) {
            const post = JSON.parse(m.data.post);
            if (post.type.startsWith('system_')) {
                return;
            }

            if (!(await this.main.isMattermostUser(post.user_id))) {
                return;
            }

            const intent = this.main.mattermostUserStore.getIntent(
                post.user_id,
            );
            if (intent === undefined) {
                return;
            }
            const metadata: {
                replyTo?: { matrix: string; mattermost: string };
            } = {};
            if (post.root_id !== '') {
                try {
                    const threadResponse = await this.main.client.get(
                        `/posts/${post.root_id}/thread`,
                    );

                    // threadResponse.order often contains duplicate entries
                    const threads = uniq(threadResponse.order);

                    const thisIndex = threads.indexOf(post.id);
                    const id = threads[thisIndex - 1] as string;
                    const replyTo = await Post.findOne({ postid: id });
                    if (replyTo !== undefined) {
                        metadata.replyTo = {
                            matrix: replyTo.eventid,
                            mattermost: post.root_id,
                        };
                    }
                } catch (e) {
                    await handlePostError(e, post.root_id);
                }
            }

            const handler = Channel.mattermostPostHandlers[post.type];
            if (handler !== undefined) {
                await handler.bind(this)(intent, post, metadata);
            } else {
                log.debug(`Unknown post type: ${post.type}`);
            }
        },
        post_edited: async function (this: Channel, m: any) {
            const post = JSON.parse(m.data.post);
            if (!(await this.main.isMattermostUser(post.user_id))) {
                return;
            }
            const intent = await this.main.mattermostUserStore.getOrCreateIntent(
                post.user_id,
            );

            const matrixEvent = await Post.findOne({
                postid: post.id,
            });
            const msgtype = post.type === '' ? 'm.text' : 'm.emote';

            const msg = await mattermostToMatrix(post.message, msgtype);
            msg.body = `* ${msg.body}`;
            if (msg.formatted_body) {
                msg.formatted_body = `* ${msg.formatted_body}`;
            }

            if (matrixEvent !== undefined) {
                msg['m.new_content'] = await mattermostToMatrix(
                    post.message,
                    msgtype,
                );
                msg['m.relates_to'] = {
                    event_id: matrixEvent.eventid,
                    rel_type: 'm.replace',
                };
            }
            await intent.sendMessage(this.matrixRoom, msg);
        },
        post_deleted: async function (this: Channel, m: any) {
            // See the README for details on the logic.
            const post = JSON.parse(m.data.post);

            const client = this.main.bridge.getIntent().client;
            // There can be multiple corresponding Matrix posts if it has
            // attachments.
            const matrixEvents = await Post.find({
                where: [{ rootid: post.id }, { postid: post.id }],
            });

            const promises: Promise<any>[] = [Post.removeAll(post.postid)];
            // It is okay to redact an event already redacted.
            for (const event of matrixEvents) {
                promises.push(
                    client.redactEvent(this.matrixRoom, event.eventid),
                );
                promises.push(event.remove());
            }
            await Promise.all(promises);
        },
        user_added: async function (this: Channel, m: any) {
            const intent = await this.main.mattermostUserStore.getOrCreateIntent(
                m.data.user_id,
            );
            await intent.join(this.matrixRoom);
        },
        user_removed: async function (this: Channel, m: any) {
            const intent = this.main.mattermostUserStore.getIntent(
                m.data.user_id,
            );
            if (intent !== undefined) {
                await intent.leave(this.matrixRoom);
            }
        },
        user_updated: async function (this: Channel, m: any) {
            const user = await this.main.mattermostUserStore.get(
                m.data.user.id,
            );
            if (user !== undefined) {
                this.main.mattermostUserStore.updateUser(m.data.user, user);
            }
        },
        leave_team: async function (this: Channel, m: any) {
            await Channel.mattermostMessageHandlers.user_removed.bind(this)(m);
        },
        typing: async function (this: Channel, m: any) {
            const intent = this.main.mattermostUserStore.getIntent(
                m.data.user_id,
            );
            if (intent !== undefined) {
                intent.client
                    .sendTyping(this.matrixRoom, true, 6000)
                    .catch(e =>
                        log.error(
                            `Error sending typing notification to ${this.matrixRoom}: ${e}`,
                        ),
                    );
            }
        },
        channel_viewed: () => {},
    };

    static readonly mattermostPostHandlers = {
        '': async function (
            this: Channel,
            intent: Intent,
            post: any,
            metadata: { replyTo?: { matrix: string; mattermost: string } },
        ) {
            await this.sendMatrixMessage(
                intent,
                post.id,
                await mattermostToMatrix(post.message),
                metadata,
            );

            if (post.metadata.files !== undefined) {
                for (const file of post.metadata.files) {
                    const body = (
                        await this.main.client.send_raw(
                            'GET',
                            `/files/${file.id}`,
                        )
                    ).body;
                    const mimetype = file.mime_type;

                    const url = await intent.client.uploadContent(body, {
                        name: file.name,
                        type: mimetype,
                        rawResponse: false,
                        onlyContentUri: true,
                    });

                    let msgtype = 'm.file';
                    if (mimetype.startsWith('image/')) {
                        msgtype = 'm.image';
                    } else if (mimetype.startsWith('audio/')) {
                        msgtype = 'm.audio';
                    } else if (mimetype.startsWith('video/')) {
                        msgtype = 'm.video';
                    }
                    await this.sendMatrixMessage(
                        intent,
                        post.id,
                        {
                            msgtype,
                            body: file.name,
                            url,
                            info: {
                                mimetype,
                                size: file.size,
                            },
                        },
                        metadata,
                    );
                }
            }
            intent.client
                .sendTyping(this.matrixRoom, false)
                .catch(e =>
                    log.error(
                        `Error sending typing notification to ${this.matrixRoom}: ${e}`,
                    ),
                );
        },
        me: async function (
            this: Channel,
            intent: Intent,
            post: any,
            metadata: { replyTo?: { matrix: string; mattermost: string } },
        ) {
            await this.sendMatrixMessage(
                intent,
                post.id,
                await mattermostToMatrix(post.props.message, 'm.emote'),
                metadata,
            );
            intent.client
                .sendTyping(this.matrixRoom, false)
                .catch(e =>
                    log.error(
                        `Error sending typing notification to ${this.matrixRoom}: ${e}`,
                    ),
                );
        },
    };

    static readonly matrixEventHandlers = {
        'm.room.message': async function (this: Channel, event: any) {
            const content = event.content;
            const user = await this.main.matrixUserStore.get(event.sender);
            if (user === undefined) {
                log.info(
                    `Received message from untracked matrix user ${event.sender}`,
                );
                return;
            }

            const relatesTo = event.content['m.relates_to'];
            const metadata: { edits?: string; root_id?: string } = {};
            if (relatesTo !== undefined) {
                if (relatesTo.rel_type === 'm.replace') {
                    const post = await Post.findOne({
                        eventid: relatesTo.event_id,
                    });
                    if (post !== undefined) {
                        metadata.edits = post.postid;
                    }
                } else if (relatesTo['m.in_reply_to'] !== undefined) {
                    const post = await Post.findOne({
                        eventid: relatesTo['m.in_reply_to'].event_id,
                    });
                    if (post !== undefined) {
                        try {
                            const props = await user.client.get(
                                `/posts/${post.postid}`,
                            );
                            metadata.root_id = props.root_id || post.postid;
                        } catch (e) {
                            await handlePostError(e, post.postid);
                        }
                    }
                }
            }

            let handler = Channel.matrixMessageHandlers[content.msgtype];
            if (handler === undefined) {
                handler = Channel.matrixMessageHandlers['m.text'];
            }
            await handler.bind(this)(user, event, metadata);
        },
        'm.room.member': async function (this: Channel, event: any) {
            const handler =
                Channel.matrixMembershipHandler[event.content.membership];
            if (handler === undefined) {
                log.error(
                    `Invalid membership state: ${event.content.membership}`,
                );
                return;
            }
            await handler.bind(this)(event.state_key);
        },
        'm.room.redaction': async function (this: Channel, event: any) {
            const botid = this.main.bridge.getBot().getUserId();
            // Matrix loop detection doesn't catch redactions.
            if (event.sender === botid) {
                return;
            }
            const post = await Post.findOne({
                eventid: event.redacts,
            });
            if (post === undefined) {
                return;
            }

            // Delete in database before sending the query, so that the
            // Mattermost event doesn't get processed.
            await Post.removeAll(post.postid);

            // The post might have been deleted already, either due to both
            // sides deleting simultaneously, or the message being deleted
            // while the bridge is down.
            try {
                await this.main.client.delete(`/posts/${post.postid}`);
            } catch (e) {
                if (
                    !(
                        e instanceof ClientError &&
                        e.m.status_code === 403 &&
                        e.m.id === 'api.context.permissions.app_error'
                    )
                ) {
                    throw e;
                }
            }
        },
    };

    static async uploadFile(
        this: Channel,
        user: User,
        event: any,
        metadata: { edits?: string; root_id?: string },
    ) {
        const mxc = event.content.url;

        const bot = this.main.bridge.getBot();
        const body = await fetch(
            `${bot.client.baseUrl}/_matrix/media/r0/download/${mxc.slice(6)}`,
        );
        const form = new FormData();
        form.append('files', body.body, {
            filename: event.content.body,
            contentType: event.content.info?.mimetype,
        });
        form.append('channel_id', this.mattermostChannel);

        // FormData incorrectly reports that hasKnownLength is `true` when
        // we pass in a `body` from `node-fetch`. This results in an
        // incorrect `Content-Length`. c.f.
        // https://github.com/form-data/form-data/issues/399
        form.hasKnownLength = () => false;

        const fileInfos = await user.client.post('/files', form);
        const fileid = fileInfos.file_infos[0].id;
        const post = await user.client.post('/posts', {
            channel_id: this.mattermostChannel,
            message: event.content.filename,
            root_id: metadata.root_id,
            file_ids: [fileid],
        });
        await Post.create({
            postid: post.id,
            eventid: event.event_id,
            rootid: metadata.root_id || post.id,
        }).save();
    }

    static readonly matrixMessageHandlers = {
        'm.text': async function (
            this: Channel,
            user: User,
            event: any,
            metadata: { edits?: string; root_id?: string },
        ) {
            if (metadata.edits) {
                try {
                    await user.client.put(`/posts/${metadata.edits}/patch`, {
                        message: await matrixToMattermost(
                            event.content['m.new_content'],
                        ),
                    });
                } catch (e) {
                    await handlePostError(e, metadata.edits);
                }
                return;
            }
            const post = await user.client.post('/posts', {
                channel_id: this.mattermostChannel,
                message: await matrixToMattermost(event.content),
                root_id: metadata.root_id,
            });
            await Post.create({
                postid: post.id,
                eventid: event.event_id,
                rootid: metadata.root_id || post.id,
            }).save();
        },
        'm.emote': async function (
            this: Channel,
            user: User,
            event: any,
            metadata: { edits?: string; root_id?: string },
        ) {
            if (metadata.edits) {
                const content = await matrixToMattermost(
                    event.content['m.new_content'],
                );
                try {
                    await user.client.put(`/posts/${metadata.edits}/patch`, {
                        message: `*${content}*`,
                        props: {
                            message: content,
                        },
                    });
                } catch (e) {
                    await handlePostError(e, metadata.edits);
                }

                return;
            }
            const content = await matrixToMattermost(event.content);
            await user.client.post('/commands/execute', {
                channel_id: this.mattermostChannel,
                team_id: await this.getTeam(),
                command: `/me ${content}`,
                root_id: metadata.root_id,
            });
            const posts = await user.client.get(
                `/channels/${this.mattermostChannel}/posts`,
            );
            for (let postid of posts.order) {
                const post = posts.posts[postid];
                if (post.type === 'me' && post.props.message === content) {
                    await Post.create({
                        postid: postid,
                        eventid: event.event_id,
                        rootid: metadata.root_id || post.id,
                    }).save();
                    return;
                }
            }
            log.info(`Cannot find post for ${content}`);
        },
        'm.file': Channel.uploadFile,
        'm.image': Channel.uploadFile,
        'm.audio': Channel.uploadFile,
        'm.video': Channel.uploadFile,
    };

    static readonly matrixMembershipHandler = {
        invite: () => {},
        knock: () => {},
        join: async function (this: Channel, userid: string) {
            if (this.main.skipMatrixUser(userid)) {
                return;
            }

            const user = await this.main.matrixUserStore.getOrCreate(
                userid,
                true,
            );
            await this.joinMattermost(user.mattermost_userid);
        },
        leave: async function (this: Channel, userid: string) {
            const bot = this.main.bridge.getBot();

            const user = await this.main.matrixUserStore.get(userid);
            if (user === undefined) {
                log.info(`Removing untracked matrix user ${userid}`);
                return;
            }
            await this.leaveMattermost(user.mattermost_userid);

            // Check if we have left all channels in the team. If so, leave the
            // team. This is useful because this is the only way to leave Town
            // Square.
            const team = await this.getTeam();
            const channels = this.main.channelsByTeam.get(team) as Channel[];

            const promises: Promise<boolean>[] = [];
            for (const channel of channels) {
                promises.push(
                    bot.client
                        .getJoinedRoomMembers(channel.matrixRoom)
                        .then(members =>
                            Object.keys(members.joined).includes(
                                user.matrix_userid,
                            ),
                        ),
                );
            }

            if (!(await Promise.all(promises)).some(x => x)) {
                await user.client.delete(
                    `/teams/${team}/members/${user.mattermost_userid}`,
                );
            }
        },
        ban: async function (this: Channel, userid: string) {
            await Channel.matrixMembershipHandler.leave.bind(this)(userid);
        },
    };
}
