import { Client, ClientError } from './Client';
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
    userid: string,
): Promise<void> {
    try {
        await channel.main.client.post(
            `/channels/${channel.mattermostChannel}/members`,
            {
                user_id: userid,
            },
        );
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
                await channel.main.client.get(
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
            await channel.main.client.post(`/teams/${teamid}/members`, {
                user_id: userid,
                team_id: teamid,
            });

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
