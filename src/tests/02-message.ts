import { startBridge, test, main } from './utils/Bridge';
import {
    getMatrixMessage,
    getMattermostClient,
    getMatrixClient,
} from './utils/Client';
import { waitEvent } from '../utils/Functions';
import { MATTERMOST_CHANNEL_IDS, MATRIX_ROOM_IDS } from './utils/Data';
import { MattermostPost } from '../Interfaces';

test('Start bridge', async t => {
    await startBridge(t);
    t.end();
});

test('Mattermost -> Matrix plain text', async t => {
    const mattermostClient = getMattermostClient('mattermost_a');

    const promise = waitEvent(main(), 'mattermost');
    await mattermostClient.post('/posts', {
        channel_id: MATTERMOST_CHANNEL_IDS['town-square'],
        message: 'test',
    });
    await promise;

    const messages = await getMatrixMessage('town-square');
    t.equal(messages[0].sender, '@mm_mattermost_a:localhost');
    t.deepEqual(messages[0].content, {
        msgtype: 'm.text',
        body: 'test',
    });

    t.end();
});

test('Matrix -> Mattermost plain text', async t => {
    const mattermostClient = getMattermostClient('admin');
    const matrixClient = getMatrixClient('matrix_a');

    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost'),
        matrixClient.sendMessage(MATRIX_ROOM_IDS['town-square'], {
            msgtype: 'm.text',
            body: 'test2',
        }),
    ]);

    const posts = await mattermostClient.get(
        `/channels/${MATTERMOST_CHANNEL_IDS['town-square']}/posts?page=0&per_page=1`,
    );
    const post = Object.values(posts.posts)[0] as MattermostPost;
    t.equal(post.type, '');
    t.equal(post.message, 'test2');

    const user = await mattermostClient.get(`/users/${post.user_id}`);
    t.equal(user.username, 'matrix_matrix_a');

    t.end();
});

// The formatting function is unit tested. The main objective is to ensure this
// indeed goes through the formatting function.
test('Mattermost -> Matrix formatted', async t => {
    const mattermostClient = getMattermostClient('mattermost_a');

    const promise = waitEvent(main(), 'mattermost');
    await mattermostClient.post('/posts', {
        channel_id: MATTERMOST_CHANNEL_IDS['town-square'],
        message: '# Header\n\n**bold**',
    });
    await promise;

    const messages = await getMatrixMessage('town-square');
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
    const mattermostClient = getMattermostClient('admin');
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

    const posts = await mattermostClient.get(
        `/channels/${MATTERMOST_CHANNEL_IDS['town-square']}/posts?page=0&per_page=1`,
    );
    const post = Object.values(posts.posts)[0] as MattermostPost;
    t.equal(post.type, '');
    t.equal(post.message, 'Header\n======\n\n**Bolded text**');

    t.end();
});

test('Kill bridge', async t => {
    await main().killBridge(0);
    t.end();
});
