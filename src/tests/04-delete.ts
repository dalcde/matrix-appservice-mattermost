import { startBridge, test, main } from './utils/Bridge';
import {
    getMatrixMessages,
    getMattermostMessages,
    getMatrixClient,
    getMattermostClient,
} from './utils/Client';
import { waitEvent } from '../utils/Functions';
import { MATTERMOST_CHANNEL_IDS, MATRIX_ROOM_IDS } from './utils/Data';

test('Start bridge', async t => {
    await startBridge();
    t.end();
});

test('Delete from mattermost', async t => {
    const client = getMattermostClient('mattermost_a');

    const [, , post] = await Promise.all([
        waitEvent(main(), 'mattermost'),
        waitEvent(main(), 'matrix'),
        client.post('/posts', {
            channel_id: MATTERMOST_CHANNEL_IDS['town-square'],
            message: 'mm to delete',
        }),
    ]);

    let messages = await getMatrixMessages('town-square');
    t.equal(messages[0].content.body, 'mm to delete');

    await Promise.all([
        waitEvent(main(), 'mattermost'),
        waitEvent(main(), 'matrix'),
        client.delete(`/posts/${post.id}`),
    ]);

    messages = await getMatrixMessages('town-square');
    t.notEqual(messages[0].content.body, 'mm to delete');

    t.end();
});

test('Delete from matrix', async t => {
    const client = getMatrixClient('matrix_a');

    const [, , post] = await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost'),
        client.sendMessage(MATRIX_ROOM_IDS['off-topic'], {
            msgtype: 'm.text',
            body: 'matrix to delete',
        }),
    ]);

    let messages = await getMattermostMessages('off-topic');
    t.equal(messages[0].message, 'matrix to delete');

    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost'),
        client.redactEvent(MATRIX_ROOM_IDS['off-topic'], post.event_id),
    ]);

    messages = await getMattermostMessages('off-topic');
    t.notEqual(messages[0].message, 'matrix to delete');

    t.end();
});

test('Delete thread', async t => {
    const client = getMattermostClient('mattermost_a');

    const promise = Promise.all([
        waitEvent(main(), 'mattermost', 3),
        waitEvent(main(), 'matrix', 3),
    ]);
    await client.post('/posts', {
        channel_id: MATTERMOST_CHANNEL_IDS['town-square'],
        message: 'pre-thread message',
    });
    const root = await client.post('/posts', {
        channel_id: MATTERMOST_CHANNEL_IDS['town-square'],
        message: 'first message',
    });
    await client.post('/posts', {
        channel_id: MATTERMOST_CHANNEL_IDS['town-square'],
        message: 'second message',
        root_id: root.id,
    });
    await promise;

    let messages = await getMatrixMessages('town-square');
    t.equal(
        messages[0].content.body,
        '> <@mm_mattermost_a:localhost> first message\n\nsecond message',
    );

    await Promise.all([
        waitEvent(main(), 'mattermost'),
        waitEvent(main(), 'matrix', 2),
        client.delete(`/posts/${root.id}`),
    ]);

    messages = await getMatrixMessages('town-square');
    t.notEqual(messages[0].content.body, 'pre-thread message');

    t.end();
});

test('Kill bridge', async t => {
    await main().killBridge(0);
    t.end();
});
