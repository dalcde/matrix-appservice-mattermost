import { createClient } from 'matrix-js-sdk';
import { Client } from '../../mattermost/Client';
import { MattermostPost, MatrixClient } from '../../Interfaces';

import {
    MATTERMOST_TOKENS,
    MATRIX_TOKENS,
    MATRIX_ROOM_IDS,
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

export function getMatrixClient(username: MatrixUsername): MatrixClient {
    return createClient({
        baseUrl: `http://localhost:${SYNAPSE_PORT}`,
        accessToken: MATRIX_TOKENS[username],
        userId: `@${username}:localhost`,
    });
}

export async function getMatrixMessages(
    room: Channels,
    n: number = 1,
): Promise<any> {
    const roomId = MATRIX_ROOM_IDS[room];
    const filter = {
        presence: { types: [] },
        account_data: { types: [] },
        room: {
            rooms: [roomId],
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
    return response.rooms.join[roomId].timeline.events;
}

export async function getMattermostMessages(
    room: Channels,
    n: number = 1,
): Promise<MattermostPost[]> {
    const postReply = await getMattermostClient('admin').get(
        `/channels/${MATTERMOST_CHANNEL_IDS[room]}/posts?page=0&per_page=${n}`,
    );
    return postReply.order.map(x => postReply.posts[x]);
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

export async function getMattermostUsername(userid: string): Promise<string> {
    return (await getMattermostClient('admin').get(`/users/${userid}`))
        .username;
}
