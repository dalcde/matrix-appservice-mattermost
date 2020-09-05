import Channel from './Channel';
import { Post } from './entities/Post';
import Main from './Main';
import log from './Logging';
import {
    MattermostMessage,
    MattermostPost,
    MatrixMessage,
    MatrixEvent,
    MatrixClient,
} from './Interfaces';
import { handlePostError, none } from './utils/Functions';
import { mattermostToMatrix, constructMatrixReply } from './utils/Formatting';

interface Metadata {
    replyTo?: {
        matrix: string;
        mattermost: string;
    };
}

async function sendMatrixMessage(
    client: MatrixClient,
    room: string,
    postid: string,
    message: MatrixMessage,
    metadata: Metadata,
) {
    let rootid = postid;
    if (metadata.replyTo !== undefined) {
        const replyTo = metadata.replyTo;
        rootid = replyTo.mattermost;
        let original: MatrixEvent | undefined = undefined;
        try {
            original = await client.fetchRoomEvent(room, replyTo.matrix);
        } catch (e) {}
        if (original !== undefined) {
            constructMatrixReply(original, message);
        }
    }
    const event = await client.sendMessage(room, message);
    await Post.create({
        postid,
        rootid,
        eventid: event.event_id,
    }).save();
    return event.event_id;
}

const MattermostPostHandlers = {
    '': async function (
        this: Channel,
        client: MatrixClient,
        post: MattermostPost,
        metadata: Metadata,
    ) {
        await sendMatrixMessage(
            client,
            this.matrixRoom,
            post.id,
            await mattermostToMatrix(post.message),
            metadata,
        );

        if (post.metadata.files !== undefined) {
            for (const file of post.metadata.files) {
                const body = (
                    await this.main.client.send_raw('GET', `/files/${file.id}`)
                ).body;
                const mimetype = file.mime_type;

                const url = await client.uploadContent(body, {
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
                await sendMatrixMessage(
                    client,
                    this.matrixRoom,
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
        client
            .sendTyping(this.matrixRoom, false)
            .catch(e =>
                log.warn(
                    `Error sending typing notification to ${this.matrixRoom}\n${e.stack}`,
                ),
            );
    },
    me: async function (
        this: Channel,
        client: MatrixClient,
        post: MattermostPost,
        metadata: Metadata,
    ) {
        await sendMatrixMessage(
            client,
            this.matrixRoom,
            post.id,
            await mattermostToMatrix(post.props.message, 'm.emote'),
            metadata,
        );
        client
            .sendTyping(this.matrixRoom, false)
            .catch(e =>
                log.warn(
                    `Error sending typing notification to ${this.matrixRoom}\n${e.stack}`,
                ),
            );
    },
};

export const MattermostHandlers = {
    posted: async function (
        this: Channel,
        m: MattermostMessage,
    ): Promise<void> {
        const post: MattermostPost = JSON.parse(m.data.post) as MattermostPost;
        if (post.type.startsWith('system_')) {
            return;
        }

        if (!(await this.main.isMattermostUser(post.user_id))) {
            return;
        }

        const client = this.main.mattermostUserStore.getClient(post.user_id);
        if (client === undefined) {
            return;
        }
        const metadata: Metadata = {};
        if (post.root_id !== '') {
            try {
                const threadResponse = await this.main.client.get(
                    `/posts/${post.root_id}/thread`,
                );

                // threadResponse.order often contains duplicate entries
                const threads = Object.values(threadResponse.posts)
                    .sort((a: any, b: any) => a.create_at - b.create_at)
                    .map((x: any) => x.id);

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

        const handler = MattermostPostHandlers[post.type];
        if (handler !== undefined) {
            await handler.bind(this)(client, post, metadata);
        } else {
            log.debug(`Unknown post type: ${post.type}`);
        }
    },
    post_edited: async function (
        this: Channel,
        m: MattermostMessage,
    ): Promise<void> {
        const post = JSON.parse(m.data.post);
        if (!(await this.main.isMattermostUser(post.user_id))) {
            return;
        }
        const client = await this.main.mattermostUserStore.getOrCreateClient(
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
        await client.sendMessage(this.matrixRoom, msg);
    },
    post_deleted: async function (
        this: Channel,
        m: MattermostMessage,
    ): Promise<void> {
        // See the README for details on the logic.
        const post = JSON.parse(m.data.post);

        // There can be multiple corresponding Matrix posts if it has
        // attachments.
        const matrixEvents = await Post.find({
            where: [{ rootid: post.id }, { postid: post.id }],
        });

        const promises: Promise<unknown>[] = [Post.removeAll(post.postid)];
        // It is okay to redact an event already redacted.
        for (const event of matrixEvents) {
            promises.push(
                this.main.botClient.redactEvent(this.matrixRoom, event.eventid),
            );
            promises.push(event.remove());
        }
        await Promise.all(promises);
    },
    user_added: async function (
        this: Channel,
        m: MattermostMessage,
    ): Promise<void> {
        const client = await this.main.mattermostUserStore.getOrCreateClient(
            m.data.user_id,
        );
        await client.joinRoom(this.matrixRoom);
    },
    user_removed: async function (
        this: Channel,
        m: MattermostMessage,
    ): Promise<void> {
        const client = this.main.mattermostUserStore.getClient(m.data.user_id);
        if (client !== undefined) {
            await client.leave(this.matrixRoom);
        }
    },
    user_updated: async function (
        this: Channel,
        m: MattermostMessage,
    ): Promise<void> {
        const user = await this.main.mattermostUserStore.get(m.data.user.id);
        if (user !== undefined) {
            await this.main.mattermostUserStore.updateUser(m.data.user, user);
        }
    },
    leave_team: async function (
        this: Channel,
        m: MattermostMessage,
    ): Promise<void> {
        await MattermostHandlers.user_removed.bind(this)(m);
    },
    typing: async function (
        this: Channel,
        m: MattermostMessage,
    ): Promise<void> {
        const client = this.main.mattermostUserStore.getClient(m.data.user_id);
        if (client !== undefined) {
            client
                .sendTyping(this.matrixRoom, true, 6000)
                .catch(e =>
                    log.warn(
                        `Error sending typing notification to ${this.matrixRoom}\n${e.stack}`,
                    ),
                );
        }
    },
    channel_viewed: none,
};

export const MattermostMainHandlers = {
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
