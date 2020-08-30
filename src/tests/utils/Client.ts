import { createClient } from 'matrix-js-sdk';
import { Client } from '../../mattermost/Client';

import {
    MATTERMOST_TOKENS,
    MATRIX_TOKENS,
    MATTERMOST_CHANNEL_IDS,
    MATTERMOST_TEAM_ID,
    SYNAPSE_PORT,
    MATTERMOST_PORT,
    MattermostUsername,
    MatrixUsername,
    Channels,
} from './Data';

export function getMattermostClient(username: MattermostUsername): Client {
    return new Client(
        `http://localhost:${MATTERMOST_PORT}`,
        MATTERMOST_TOKENS[username].userid,
        MATTERMOST_TOKENS[username].token,
    );
}

export function getMatrixClient(username: MatrixUsername): any {
    return createClient({
        baseUrl: `http://localhost:${SYNAPSE_PORT}`,
        accessToken: MATRIX_TOKENS[username],
        userId: `@${username}:localhost`,
    } as any);
}

export async function getMatrixMessage(
    room: string,
    n: number = 1,
): Promise<any> {
    const filter = {
        presence: { types: [] },
        account_data: { types: [] },
        room: {
            rooms: [room],
            account_data: { types: [] },
            state: { types: [] },
            timeline: {
                limit: n,
                types: ['m.room.message'],
            },
        },
    };
    const response = await getMatrixClient('admin')._http.authedRequest(
        undefined,
        'GET',
        '/sync',
        {
            filter: JSON.stringify(filter),
        },
    );
    return response.rooms.join[room].timeline.events;
}

export async function getMattermostMembers(
    channel: Channels,
): Promise<Set<string>> {
    const mattermostClient = getMattermostClient('admin');

    const members = await mattermostClient.get(
        `/channels/${MATTERMOST_CHANNEL_IDS[channel]}/members`,
    );
    const membersInfo = await mattermostClient.post(
        '/users/ids',
        members.map(x => x.user_id),
    );
    return new Set(membersInfo.map(x => x.username));
}

export async function getMattermostTeamMembers(): Promise<Set<string>> {
    const mattermostClient = getMattermostClient('admin');

    const members = await mattermostClient.get(
        `/teams/${MATTERMOST_TEAM_ID}/members`,
    );
    const membersInfo = await mattermostClient.post(
        '/users/ids',
        members.map(x => x.user_id),
    );
    return new Set(membersInfo.map(x => x.username));
}
