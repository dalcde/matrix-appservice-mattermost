import Channel from './Channel';
import { User } from './entities/User';
import { Post } from './entities/Post';
import { ClientError } from './mattermost/Client';
import { handlePostError, none } from './utils/Functions';
import { matrixToMattermost } from './utils/Formatting';
import { MatrixEvent } from './Interfaces';
import * as FormData from 'form-data';
import log from './Logging';
import fetch from 'node-fetch';

interface Metadata {
    edits?: string;
    root_id?: string;
}
async function uploadFile(
    this: Channel,
    user: User,
    event: MatrixEvent,
    metadata: Metadata,
) {
    const mxc = event.content.url;

    const body = await fetch(
        `${this.main.botClient.baseUrl}/_matrix/media/r0/download/${mxc.slice(
            6,
        )}`,
    );
    if (body.body === null) {
        throw new Error(`Downloaded empty file: ${mxc}`);
    }

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

const MatrixMessageHandlers = {
    'm.text': async function (
        this: Channel,
        user: User,
        event: MatrixEvent,
        metadata: Metadata,
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
        event: MatrixEvent,
        metadata: Metadata,
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
        for (const postid of posts.order) {
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
    'm.file': uploadFile,
    'm.image': uploadFile,
    'm.audio': uploadFile,
    'm.video': uploadFile,
};

const MatrixMembershipHandler = {
    invite: none,
    knock: none,
    join: async function (this: Channel, userid: string): Promise<void> {
        if (this.main.skipMatrixUser(userid)) {
            return;
        }

        const user = await this.main.matrixUserStore.getOrCreate(userid, true);
        await this.joinMattermost(user.mattermost_userid);
    },
    leave: async function (this: Channel, userid: string) {
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

        const joined = await Promise.all(
            channels.map(async channel => {
                const members = await this.main.botClient.getJoinedRoomMembers(
                    channel.matrixRoom,
                );
                return Object.keys(members.joined).includes(user.matrix_userid);
            }),
        );

        if (!joined.some(x => x)) {
            await user.client.delete(
                `/teams/${team}/members/${user.mattermost_userid}`,
            );
        }
    },
    ban: async function (this: Channel, userid: string): Promise<void> {
        await MatrixMembershipHandler.leave.bind(this)(userid);
    },
};

const MatrixHandlers = {
    'm.room.message': async function (
        this: Channel,
        event: MatrixEvent,
    ): Promise<void> {
        const content = event.content;
        const user = await this.main.matrixUserStore.get(event.sender);
        if (user === undefined) {
            log.info(
                `Received message from untracked matrix user ${event.sender}`,
            );
            return;
        }

        const relatesTo = event.content['m.relates_to'];
        const metadata: Metadata = {};
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

        let handler = MatrixMessageHandlers[content.msgtype];
        if (handler === undefined) {
            handler = MatrixMessageHandlers['m.text'];
        }
        await handler.bind(this)(user, event, metadata);
    },
    'm.room.member': async function (
        this: Channel,
        event: MatrixEvent,
    ): Promise<void> {
        const handler = MatrixMembershipHandler[event.content.membership];
        if (handler === undefined) {
            log.warn(`Invalid membership state: ${event.content.membership}`);
            return;
        }
        await handler.bind(this)(event.state_key);
    },
    'm.room.redaction': async function (
        this: Channel,
        event: MatrixEvent,
    ): Promise<void> {
        const botid = this.main.botClient.getUserId();
        // Matrix loop detection doesn't catch redactions.
        if (event.sender === botid) {
            return;
        }
        const post = await Post.findOne({
            eventid: event.redacts as string,
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
export default MatrixHandlers;
