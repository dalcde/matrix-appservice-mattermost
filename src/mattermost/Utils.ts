import { Client, ClientError } from './Client';
import { User } from '../entities/User';
import Channel from '../Channel';
import log from '../Logging';

const MAX_MEMBERS: number = 10000;

export async function getMattermostUsers(
    client: Client,
    channel: string,
): Promise<Set<string>> {
    const query = await client.send(
        'GET',
        `/channels/${channel}/members?page=0&per_page=${MAX_MEMBERS}`,
    );
    return new Set(query.map(member => member.user_id));
}

/* Joining a mattermost channel that we have already joined should not result
 * in an error. However, if a second join request is made before the first join
 * request is processed, the servers gets an internal error. In practice, this
 * happens when one of the "join requests" come from joining default channels
 * when joining a team.
 *
 * To get around this, when we receive 500 response, we retry the join with
 * exponential backoff.
 *
 * See https://github.com/mattermost/mattermost-server/issues/15366 .
 */
async function retryJoinMattermostChannel(
    client: Client,
    channelid: string,
    userid: string,
): Promise<void> {
    // Time before next retry
    let retry = 10;
    while (true) {
        try {
            return await client.post(`/channels/${channelid}/members`, {
                user_id: userid,
            });
        } catch (e: unknown) {
            if (
                retry > 1280 ||
                !(e instanceof ClientError && e.m.status_code === 500)
            ) {
                throw e;
            }
        }
        await new Promise(r => setTimeout(r, retry));
        retry *= 2;
    }
}

export async function joinMattermostChannel(
    channel: Channel,
    user: User,
): Promise<void> {
    const userid = user.mattermost_userid;
    const client = channel.main.client;

    try {
        await retryJoinMattermostChannel(
            client,
            channel.mattermostChannel,
            userid,
        );
    } catch (e) {
        if (
            e instanceof ClientError &&
            (e.m.id === 'store.sql_team.get_member.missing.app_error' ||
                e.m.id === 'app.team.get_member.missing.app_error' ||
                e.m.id ===
                    'api.channel.add_user.to.channel.failed.deleted.app_error')
        ) {
            const teamid = await channel.getTeam();
            await client.joinTeam(userid, teamid);
            // If the team has default channels, we leave the ones we are not
            // supposed to be in.
            const channels = await client.get(
                `/users/${userid}/teams/${teamid}/channels`,
            );
            await Promise.all(
                channels.map(async c => {
                    const channelid = c.id;

                    // We can't leave town square. Don't bother.
                    if (c.name === 'town-square') {
                        return;
                    }

                    // We want to join this room!
                    if (channelid === channel.mattermostChannel) {
                        return;
                    }

                    const matrixRoom = channel.main.mappingsByMattermost.get(
                        channelid,
                    )?.matrix;

                    // The mattermost room is not bridged at all. Just leave.
                    if (matrixRoom === undefined) {
                        await leaveMattermostChannel(client, channelid, userid);
                        return;
                    }

                    // This happens only when the user is the bot user, in which
                    // case the existence of a mapping indicates we should remain.
                    if (user.matrix_userid === undefined) {
                        return;
                    }

                    // We query the current state in matrix, not the state when the
                    // call originally happened. This is fine because we are
                    // blocked on processing events. If the user left matrix in
                    // between, the puppet will leave the mattermost room again,
                    // which is fine. If they joined in between, we would have a
                    // leave followed by a join, which is not disasterous.
                    const matrixMembers = Object.keys(
                        (
                            await channel.main.botClient.getJoinedRoomMembers(
                                matrixRoom,
                            )
                        ).joined,
                    );

                    // If the matrix user is not in the corresponding room, leave
                    // the mattermost channel.
                    if (!matrixMembers.includes(user.matrix_userid)) {
                        await leaveMattermostChannel(client, channelid, userid);
                    }
                }),
            );

            await retryJoinMattermostChannel(
                client,
                channel.mattermostChannel,
                userid,
            );
        } else {
            throw e;
        }
    }
}

export async function leaveMattermostChannel(
    client: Client,
    channel: string,
    userid: string,
): Promise<void> {
    try {
        await client.delete(`/channels/${channel}/members/${userid}`);
    } catch (e) {
        switch (e.m?.id) {
            case 'api.channel.remove.default.app_error':
                log.debug(
                    `Cannot remove user ${userid} from default town-square channel`,
                );
                break;
            case 'store.sql_channel.get_member.missing.app_error':
                log.debug(
                    `User ${userid} already removed from channel ${channel}`,
                );
                break;
            default:
                throw e;
        }
    }
}
