import Channel from './Channel';
import { Intent } from 'matrix-appservice-bridge';
import { Post } from './entities/Post';
import log from './Logging';
import { MatrixMessage } from './Interfaces';
import { uniq, handlePostError } from './utils/Functions';
import { mattermostToMatrix, constructMatrixReply } from './utils/Formatting';

async function sendMatrixMessage(
    intent: Intent,
    room: string,
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
            original = await intent.getEvent(room, replyTo.matrix);
        } catch (e) {}
        if (original !== undefined) {
            constructMatrixReply(original, message);
        }
    }
    const event = await intent.sendMessage(room, message);
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
        intent: Intent,
        post: any,
        metadata: { replyTo?: { matrix: string; mattermost: string } },
    ) {
        await sendMatrixMessage(
            intent,
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
                await sendMatrixMessage(
                    intent,
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
        intent.client
            .sendTyping(this.matrixRoom, false)
            .catch(e =>
                log.warn(
                    `Error sending typing notification to ${this.matrixRoom}\n${e.stack}`,
                ),
            );
    },
    me: async function (
        this: Channel,
        intent: Intent,
        post: any,
        metadata: { replyTo?: { matrix: string; mattermost: string } },
    ) {
        await sendMatrixMessage(
            intent,
            this.matrixRoom,
            post.id,
            await mattermostToMatrix(post.props.message, 'm.emote'),
            metadata,
        );
        intent.client
            .sendTyping(this.matrixRoom, false)
            .catch(e =>
                log.warn(
                    `Error sending typing notification to ${this.matrixRoom}\n${e.stack}`,
                ),
            );
    },
};

const MattermostHandlers = {
    posted: async function (this: Channel, m: any) {
        const post = JSON.parse(m.data.post);
        if (post.type.startsWith('system_')) {
            return;
        }

        if (!(await this.main.isMattermostUser(post.user_id))) {
            return;
        }

        const intent = this.main.mattermostUserStore.getIntent(post.user_id);
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

        const handler = MattermostPostHandlers[post.type];
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
            promises.push(client.redactEvent(this.matrixRoom, event.eventid));
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
        const intent = this.main.mattermostUserStore.getIntent(m.data.user_id);
        if (intent !== undefined) {
            await intent.leave(this.matrixRoom);
        }
    },
    user_updated: async function (this: Channel, m: any) {
        const user = await this.main.mattermostUserStore.get(m.data.user.id);
        if (user !== undefined) {
            this.main.mattermostUserStore.updateUser(m.data.user, user);
        }
    },
    leave_team: async function (this: Channel, m: any) {
        await MattermostHandlers.user_removed.bind(this)(m);
    },
    typing: async function (this: Channel, m: any) {
        const intent = this.main.mattermostUserStore.getIntent(m.data.user_id);
        if (intent !== undefined) {
            intent.client
                .sendTyping(this.matrixRoom, true, 6000)
                .catch(e =>
                    log.warn(
                        `Error sending typing notification to ${this.matrixRoom}\n${e.stack}`,
                    ),
                );
        }
    },
    channel_viewed: () => {},
};
export default MattermostHandlers;
