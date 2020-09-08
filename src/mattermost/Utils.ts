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

export async function joinMattermostChannel(
    channel: Channel,
    user: User,
): Promise<void> {
    const userid = user.mattermost_userid;
    const client = channel.main.client;

    try {
        await client.post(`/channels/${channel.mattermostChannel}/members`, {
            user_id: userid,
        });
    } catch (e) {
        // Mattermost has a race condition where if a member is added twice
        // in quick succession, then it returns an error. If we receive an
        // error, we check if the member is in the member. If so, we do
        // nothing.  c.f.
        // https://github.com/mattermost/mattermost-server/issues/15366 .
        // This would be triggered by default channels, where two different
        // join events end up causing the user to join the same channel
        // twice.
        if (e instanceof ClientError && e.m.status_code === 500) {
            try {
                await client.get(
                    `/channels/${channel.mattermostChannel}/members/${userid}`,
                );
            } catch (e_) {
                throw e;
            }
        } else if (
            e instanceof ClientError &&
            (e.m.id === 'store.sql_team.get_member.missing.app_error' ||
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

            // Now that we have finished joining the team, the above race condition cannot happen.
            await channel.main.client.post(
                `/channels/${channel.mattermostChannel}/members`,
                {
                    user_id: userid,
                },
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
