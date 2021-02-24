import { startBridge, test, main } from './utils/Bridge';
import {
    getMattermostMessages,
    getMatrixMessages,
    getMattermostClient,
    getMatrixClient,
    getMattermostUsername,
} from './utils/Client';
import { waitEvent } from '../utils/Functions';
import {
    MATTERMOST_CHANNEL_IDS,
    MATRIX_ROOM_IDS,
    MATTERMOST_TEAM_ID,
} from './utils/Data';
import * as FormData from 'form-data';
import fetch from 'node-fetch';

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

test('Mattermost -> Matrix text /me', async t => {
    const mattermostClient = getMattermostClient('mattermost_a');

    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost'),
        mattermostClient.post('/commands/execute', {
            channel_id: MATTERMOST_CHANNEL_IDS['off-topic'],
            team_id: MATTERMOST_TEAM_ID,
            command: '/me hi me',
        }),
    ]);

    const messages = await getMatrixMessages('off-topic');
    t.equal(messages[0].sender, '@mm_mattermost_a:localhost');
    t.deepEqual(messages[0].content, {
        msgtype: 'm.emote',
        body: 'hi me',
    });

    t.end();
});

test('Matrix -> Mattermost text /me', async t => {
    const matrixClient = getMatrixClient('matrix_a');

    await Promise.all([
        waitEvent(main(), 'matrix'),
        waitEvent(main(), 'mattermost'),
        matrixClient.sendMessage(MATRIX_ROOM_IDS['town-square'], {
            msgtype: 'm.emote',
            body: 'test',
        }),
    ]);

    const posts = await getMattermostMessages('town-square');
    t.equal(posts[0].type, 'me');
    t.deepEqual(posts[0].props.message, 'test');

    t.end();
});

test('Mattermost -> Matrix file upload', async t => {
    const mattermostClient = getMattermostClient('mattermost_b');
    const data = 'abracadabra';

    const form = new FormData();
    form.append('files', data, {
        filename: 'filename',
        contentType: 'text/plain',
    });
    form.append('channel_id', MATTERMOST_CHANNEL_IDS['off-topic']);

    await Promise.all([
        waitEvent(main(), 'matrix', 2),
        waitEvent(main(), 'mattermost', 1),
        mattermostClient.post('/files', form).then(data =>
            mattermostClient.post('/posts', {
                channel_id: MATTERMOST_CHANNEL_IDS['off-topic'],
                message: 'filename',
                file_ids: [data.file_infos[0].id],
            }),
        ),
    ]);

    const messages = await getMatrixMessages('off-topic', 2);
    t.equal(messages[0].sender, '@mm_mattermost_b:localhost');
    t.deepEqual(messages[0].content, {
        msgtype: 'm.text',
        body: 'filename',
    });

    t.equal(messages[1].sender, '@mm_mattermost_b:localhost');
    t.deepEqual(messages[1].content.msgtype, 'm.file');
    const url = messages[1].content.url;
    const downloaded = await fetch(
        `${main().botClient.baseUrl}/_matrix/media/r0/download/${url.slice(6)}`,
    );
    t.equal(await downloaded.text(), data);

    t.end();
});

test('Matrix -> Mattermost file upload', async t => {
    const matrixClient = getMatrixClient('matrix_a');
    const data = 'miscdata';

    await Promise.all([
        waitEvent(main(), 'matrix', 1),
        waitEvent(main(), 'mattermost', 1),
        matrixClient
            .uploadContent(data, {
                name: 'mydata',
                type: 'text/plain',
                rawResponse: false,
                onlyContentUri: true,
            })
            .then(url =>
                matrixClient.sendMessage(MATRIX_ROOM_IDS['town-square'], {
                    msgtype: 'm.file',
                    body: 'mydata',
                    url,
                    info: {
                        mimetype: 'text/plain',
                    },
                }),
            ),
    ]);

    const posts = await getMattermostMessages('town-square');
    t.equal(posts[0].type, '');
    t.equal(posts[0].message, '');
    const files = posts[0].metadata.files;
    if (files === undefined) {
        t.fail('No files found');
        return;
    }
    const fileid = files[0].id;

    const mattermostClient = getMattermostClient('mattermost_b');
    const downloaded = await mattermostClient.send_raw(
        'GET',
        `/files/${fileid}`,
    );
    t.equal(await downloaded.text(), data);

    t.end();
});

test('Kill bridge', async t => {
    await main().killBridge(0);
    t.end();
});

test('Process matrix messages sent when bridge is down', async t => {
    const matrixClient = getMatrixClient('matrix_a');
    await matrixClient.sendMessage(MATRIX_ROOM_IDS['off-topic'], {
        msgtype: 'm.text',
        body: 'hidden message',
    });
    await Promise.all([
        // There is a lot of noise from bridge startup. We only listen for the
        // matrix message. We are killing the bridge afterwards anyway.
        startBridge(),
        waitEvent(main(), 'matrix'),
    ]);

    const mattermostReply = (await getMattermostMessages('off-topic'))[0];
    t.equal(
        mattermostReply.message,
        'hidden message',
        'Received message sent while bridge is down',
    );
    await main().killBridge(0);
    t.end();
});
