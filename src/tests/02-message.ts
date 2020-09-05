import { startBridge, test, main } from './utils/Bridge';
import {
    getMattermostMessages,
    getMatrixMessages,
    getMattermostClient,
    getMatrixClient,
    getMattermostUsername,
} from './utils/Client';
import { waitEvent } from '../utils/Functions';
import { MATTERMOST_CHANNEL_IDS, MATRIX_ROOM_IDS } from './utils/Data';

test('Start bridge', async t => {
    await startBridge();
    t.end();
});

test('Mattermost -> Matrix plain text', async t => {
    const mattermostClient = getMattermostClient('mattermost_a');

    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost'),
        mattermostClient.post('/posts', {
            channel_id: MATTERMOST_CHANNEL_IDS['town-square'],
            message: 'test',
        }),
    ]);

    const messages = await getMatrixMessages('town-square');
    t.equal(messages[0].sender, '@mm_mattermost_a:localhost');
    t.deepEqual(messages[0].content, {
        msgtype: 'm.text',
        body: 'test',
    });

    t.end();
});

test('Matrix -> Mattermost plain text', async t => {
    const matrixClient = getMatrixClient('matrix_a');

    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost'),
        matrixClient.sendMessage(MATRIX_ROOM_IDS['town-square'], {
            msgtype: 'm.text',
            body: 'test2',
        }),
    ]);

    const posts = await getMattermostMessages('town-square', 1);
    t.equal(posts[0].type, '');
    t.equal(posts[0].message, 'test2');

    t.equal(await getMattermostUsername(posts[0].user_id), 'matrix_matrix_a');

    t.end();
});

// The formatting function is unit tested. The main objective is to ensure this
// indeed goes through the formatting function.
test('Mattermost -> Matrix formatted', async t => {
    const mattermostClient = getMattermostClient('mattermost_a');

    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost'),
        mattermostClient.post('/posts', {
            channel_id: MATTERMOST_CHANNEL_IDS['town-square'],
            message: '# Header\n\n**bold**',
        }),
    ]);

    const messages = await getMatrixMessages('town-square');
    t.equal(messages[0].sender, '@mm_mattermost_a:localhost');
    t.deepEqual(messages[0].content, {
        msgtype: 'm.text',
        body: '# Header\n\n**bold**',
        format: 'org.matrix.custom.html',
        formatted_body: '<h1>Header</h1><strong>bold</strong>',
    });

    t.end();
});

test('Matrix -> Mattermost formatted', async t => {
    const matrixClient = getMatrixClient('matrix_b');

    // Wait for the mattermost echo too
    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost'),
        matrixClient.sendMessage(MATRIX_ROOM_IDS['town-square'], {
            msgtype: 'm.text',
            body: 'random wrong message',
            format: 'org.matrix.custom.html',
            formatted_body: '<h1>Header</h1><b>Bolded text</b>',
        }),
    ]);

    const posts = await getMattermostMessages('town-square', 1);
    t.equal(posts[0].type, '');
    t.equal(posts[0].message, 'Header\n======\n\n**Bolded text**');

    t.end();
});

test('Kill bridge', async t => {
    await main().killBridge(0);
    t.end();
});
