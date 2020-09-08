import { startBridge, test, main } from './utils/Bridge';
import {
    getMattermostClient,
    getMatrixClient,
    getMattermostMembers,
    getMattermostTeamMembers,
} from './utils/Client';

import { waitEvent } from '../utils/Functions';
import {
    MATTERMOST_CHANNEL_IDS,
    MATRIX_ROOM_IDS,
    CHANNELS,
} from './utils/Data';

test('Start bridge', async t => {
    await startBridge();
    t.end();
});

test('initial sync', async t => {
    await Promise.all(
        CHANNELS.map(async channel => {
            t.deepEqual(
                await getMattermostMembers(channel),
                new Set([
                    'admin',
                    'mattermost_a',
                    'mattermost_b',
                    'ignored_user',
                    'matrix_matrix_a',
                    'matrix_matrix_b',
                ]),
            );
        }),
    );

    const matrixClient = getMatrixClient('admin');
    await Promise.all(
        Object.values(MATRIX_ROOM_IDS).map(async room => {
            const members = await matrixClient.getJoinedRoomMembers(room);
            t.deepEqual(
                new Set(Object.keys(members.joined)),
                new Set([
                    '@admin:localhost',
                    '@ignored_user:localhost',
                    '@matrix_a:localhost',
                    '@matrix_b:localhost',
                    '@mm_mattermost_a:localhost',
                    '@mm_mattermost_b:localhost',
                    '@matterbot:localhost',
                ]),
            );
        }),
    );

    t.end();
});

test('mattermost display names', async t => {
    const client = getMattermostClient('admin');
    const users = await client.post('/users/usernames', [
        'matrix_matrix_a',
        'matrix_matrix_b',
    ]);
    t.equal(users[0].first_name, 'Matrix UserA');
    t.equal(users[0].last_name, '');
    t.equal(users[1].first_name, 'matrix_b');
    t.equal(users[1].last_name, '');
    t.end();
});

test('matrix display names', t => {
    t.plan(2);
    const client = getMatrixClient('admin');
    for (const [user, display] of [
        ['mm_mattermost_a', 'MattermostUser A'],
        ['mm_mattermost_b', 'mattermost_b'],
    ]) {
        client
            .getProfileInfo(`@${user}:localhost`, 'displayname')
            .then(profile => {
                t.equal(profile.displayname, display + ' [mm]');
            });
    }
});

test('Sync mattermost leave', async t => {
    const matrixClient = getMatrixClient('admin');
    const mattermostClient = getMattermostClient('mattermost_a');

    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost', 2),
        mattermostClient.delete(
            `/channels/${MATTERMOST_CHANNEL_IDS['off-topic']}/members/${mattermostClient.userid}`,
        ),
    ]);

    const members = await matrixClient.getJoinedRoomMembers(
        MATRIX_ROOM_IDS['off-topic'],
    );
    t.deepEqual(
        new Set(Object.keys(members.joined)),
        new Set([
            '@admin:localhost',
            '@ignored_user:localhost',
            '@matrix_a:localhost',
            '@matrix_b:localhost',
            '@mm_mattermost_b:localhost',
            '@matterbot:localhost',
        ]),
    );

    t.end();
});

test('Sync mattermost join', async t => {
    const matrixClient = getMatrixClient('admin');
    const mattermostClient = getMattermostClient('mattermost_a');

    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost', 2),
        mattermostClient.post(
            `/channels/${MATTERMOST_CHANNEL_IDS['off-topic']}/members`,
            {
                user_id: mattermostClient.userid,
            },
        ),
    ]);

    const members = await matrixClient.getJoinedRoomMembers(
        MATRIX_ROOM_IDS['off-topic'],
    );
    t.deepEqual(
        new Set(Object.keys(members.joined)),
        new Set([
            '@admin:localhost',
            '@ignored_user:localhost',
            '@matrix_a:localhost',
            '@matrix_b:localhost',
            '@mm_mattermost_a:localhost',
            '@mm_mattermost_b:localhost',
            '@matterbot:localhost',
        ]),
    );
    t.end();
});

test('Sync matrix leave', async t => {
    const matrixClient = getMatrixClient('matrix_a');

    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost', 2),
        matrixClient.leave(MATRIX_ROOM_IDS['off-topic']),
    ]);

    t.deepEqual(
        await getMattermostMembers('off-topic'),
        new Set([
            'admin',
            'mattermost_a',
            'mattermost_b',
            'ignored_user',
            'matrix_matrix_b',
        ]),
    );

    t.end();
});

test('Sync matrix join', async t => {
    const matrixClient = getMatrixClient('matrix_a');

    await Promise.all([
        waitEvent(main(), 'matrix'),
        // 3 matterost event --- join, join post and user update
        waitEvent(main(), 'mattermost', 3),
        matrixClient.joinRoom(MATRIX_ROOM_IDS['off-topic']),
    ]);

    t.deepEqual(
        await getMattermostMembers('off-topic'),
        new Set([
            'admin',
            'mattermost_a',
            'mattermost_b',
            'ignored_user',
            'matrix_matrix_a',
            'matrix_matrix_b',
        ]),
    );

    t.end();
});

test('Leave mattermost team when all channels left', async t => {
    const matrixClient = getMatrixClient('matrix_a');

    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost', 2),
        matrixClient.leave(MATRIX_ROOM_IDS['off-topic']),
    ]);
    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost', 2),
        matrixClient.leave(MATRIX_ROOM_IDS['town-square']),
    ]);

    t.deepEqual(
        await getMattermostTeamMembers(),
        new Set([
            'admin',
            'mattermost_a',
            'mattermost_b',
            'ignored_user',
            'matrix_matrix_b',
        ]),
    );

    t.end();
});

test('Do not automatically join default channels ', async t => {
    const matrixClient = getMatrixClient('matrix_a');

    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost', 5),
        matrixClient.joinRoom(MATRIX_ROOM_IDS['town-square']),
    ]);

    t.deepEqual(
        await getMattermostMembers('town-square'),
        new Set([
            'admin',
            'mattermost_a',
            'mattermost_b',
            'ignored_user',
            'matrix_matrix_a',
            'matrix_matrix_b',
        ]),
        'Mattermost puppet in channel after joining',
    );

    t.deepEqual(
        await getMattermostMembers('off-topic'),
        new Set([
            'admin',
            'mattermost_a',
            'mattermost_b',
            'ignored_user',
            'matrix_matrix_b',
        ]),
        'Mattermost puppet not in off-topic after joining town-square',
    );

    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost', 2),
        matrixClient.joinRoom(MATRIX_ROOM_IDS['off-topic']),
    ]);

    t.deepEqual(
        await getMattermostMembers('off-topic'),
        new Set([
            'admin',
            'mattermost_a',
            'mattermost_b',
            'ignored_user',
            'matrix_matrix_a',
            'matrix_matrix_b',
        ]),
    );

    t.end();
});

test('Kill bridge', async t => {
    await main().killBridge(0);
    t.end();
});

// This bridge kills itself because there are no bridged channels.
test('Start bridge with no channels mapped', async t => {
    await startBridge({ mappings: [] });
    t.end();
});

test('check users removed', async t => {
    await Promise.all(
        CHANNELS.map(async channel => {
            t.deepEqual(
                await getMattermostMembers(channel),
                new Set(['mattermost_a', 'mattermost_b', 'ignored_user']),
            );
        }),
    );

    const matrixClient = getMatrixClient('admin');
    await Promise.all(
        Object.values(MATRIX_ROOM_IDS).map(async room => {
            const members = await matrixClient.getJoinedRoomMembers(room);
            t.deepEqual(
                new Set(Object.keys(members.joined)),
                new Set([
                    '@admin:localhost',
                    '@ignored_user:localhost',
                    '@matrix_a:localhost',
                    '@matrix_b:localhost',
                ]),
            );
        }),
    );

    t.end();
});

test('Start bridge with all channels', async t => {
    await startBridge();
    t.end();
});

// This is the same as initial sync
test('All users returned', async t => {
    await Promise.all(
        CHANNELS.map(async channel => {
            t.deepEqual(
                await getMattermostMembers(channel),
                new Set([
                    'admin',
                    'mattermost_a',
                    'mattermost_b',
                    'ignored_user',
                    'matrix_matrix_a',
                    'matrix_matrix_b',
                ]),
            );
        }),
    );

    const matrixClient = getMatrixClient('admin');
    await Promise.all(
        Object.values(MATRIX_ROOM_IDS).map(async room => {
            const members = await matrixClient.getJoinedRoomMembers(room);
            t.deepEqual(
                new Set(Object.keys(members.joined)),
                new Set([
                    '@admin:localhost',
                    '@ignored_user:localhost',
                    '@matrix_a:localhost',
                    '@matrix_b:localhost',
                    '@mm_mattermost_a:localhost',
                    '@mm_mattermost_b:localhost',
                    '@matterbot:localhost',
                ]),
            );
        }),
    );

    t.end();
});

test('Kill bridge', async t => {
    await main().killBridge(0);
    t.end();
});
