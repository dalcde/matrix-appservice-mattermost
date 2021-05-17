import { startBridge, test, main } from './utils/Bridge';
import {
    getMatrixMessages,
    getMattermostMessages,
    getMatrixClient,
    getMattermostClient,
    getMattermostUsername,
} from './utils/Client';
import { waitEvent } from '../utils/Functions';
import { MATTERMOST_CHANNEL_IDS, MATRIX_ROOM_IDS } from './utils/Data';

test('Start bridge', async t => {
    await startBridge();
    t.end();
});

test('Mattermost -> Matrix thread', async t => {
    const clientA = getMattermostClient('mattermost_a');
    const clientB = getMattermostClient('mattermost_b');

    const promise = Promise.all([
        waitEvent(main(), 'mattermost', 3),
        waitEvent(main(), 'matrix', 3),
    ]);
    const root = await clientA.post('/posts', {
        channel_id: MATTERMOST_CHANNEL_IDS['town-square'],
        message: 'first mm message',
    });
    await clientB.post('/posts', {
        channel_id: MATTERMOST_CHANNEL_IDS['town-square'],
        message: 'second mm message',
        root_id: root.id,
    });
    await clientA.post('/posts', {
        channel_id: MATTERMOST_CHANNEL_IDS['town-square'],
        message: 'third mm message',
        root_id: root.id,
    });
    await promise;

    const matrixMessages = await getMatrixMessages('town-square', 3);
    t.equal(matrixMessages[0].sender, '@mm_mattermost_a:localhost');
    t.equal(matrixMessages[1].sender, '@mm_mattermost_b:localhost');
    t.equal(matrixMessages[2].sender, '@mm_mattermost_a:localhost');

    t.equal(matrixMessages[0].content.body, 'first mm message');
    t.equal(
        matrixMessages[1].content.body,
        '> <@mm_mattermost_a:localhost> first mm message\n\nsecond mm message',
    );
    t.equal(
        matrixMessages[2].content.body,
        '> <@mm_mattermost_b:localhost> > <@mm_mattermost_a:localhost>\n\nthird mm message',
    );

    t.equal(
        matrixMessages[2].content['m.relates_to']['m.in_reply_to'].event_id,
        matrixMessages[1].event_id,
    );
    t.equal(
        matrixMessages[1].content['m.relates_to']['m.in_reply_to'].event_id,
        matrixMessages[0].event_id,
    );

    t.end();
});

test('Matrix -> Mattermost thread', async t => {
    const clientA = getMatrixClient('matrix_a');
    const clientB = getMatrixClient('matrix_b');

    const roomId = MATRIX_ROOM_IDS['off-topic'];

    const promise = Promise.all([
        waitEvent(main(), 'matrix', 3),
        waitEvent(main(), 'mattermost', 3),
    ]);
    const first = await clientA.sendMessage(roomId, {
        msgtype: 'm.text',
        body: 'first matrix message',
    });
    const second = await clientB.sendMessage(roomId, {
        msgtype: 'm.text',
        body: '> <@matrix_a> first matrix message\n\nsecond matrix message',
        format: 'org.matrix.custom.html',
        formatted_body:
            '<mx-reply>Dummy content</mx-reply>second matrix message',
        'm.relates_to': {
            'm.in_reply_to': {
                event_id: first.event_id,
            },
        },
    });
    await clientA.sendMessage(roomId, {
        msgtype: 'm.text',
        body: '> <@matrix_b> > <@matrix_a>\n\nthird matrix message',
        format: 'org.matrix.custom.html',
        formatted_body:
            '<mx-reply>Dummy content</mx-reply>third matrix message',
        'm.relates_to': {
            'm.in_reply_to': {
                event_id: second.event_id,
            },
        },
    });
    await promise;

    const posts = await getMattermostMessages('off-topic', 3);
    const [usera, userb] = await getMattermostClient('admin').post(
        '/users/usernames',
        ['matrix_matrix_a', 'matrix_matrix_b'],
    );

    t.equal(posts[0].root_id, posts[2].id);
    t.equal(posts[1].root_id, posts[2].id);

    t.equal(posts[0].message, 'third matrix message');
    t.equal(posts[1].message, 'second matrix message');
    t.equal(posts[2].message, 'first matrix message');

    t.equal(posts[0].user_id, usera.id);
    t.equal(posts[1].user_id, userb.id);
    t.equal(posts[2].user_id, usera.id);

    t.end();
});

test('Interleaved thread', async t => {
    const mattermostClient = getMattermostClient('mattermost_a');
    const matrixClient = getMatrixClient('matrix_b');

    const roomId = MATRIX_ROOM_IDS['town-square'];
    const channelId = MATTERMOST_CHANNEL_IDS['town-square'];

    const [, , firstMattermost] = await Promise.all([
        waitEvent(main(), 'mattermost'),
        waitEvent(main(), 'matrix'),
        mattermostClient.post('/posts', {
            channel_id: channelId,
            message: 'first message',
        }),
    ]);
    const firstMatrix = (await getMatrixMessages('town-square'))[0];

    const [, , secondMatrix] = await Promise.all([
        waitEvent(main(), 'mattermost'),
        waitEvent(main(), 'matrix'),
        matrixClient.sendMessage(roomId, {
            msgtype: 'm.text',
            body: 'whatever',
            format: 'org.matrix.custom.html',
            formatted_body: '<mx-reply>Dummy content</mx-reply>second message',
            'm.relates_to': {
                'm.in_reply_to': {
                    event_id: firstMatrix.event_id,
                },
            },
        }),
    ]);
    const secondMattermost = (await getMattermostMessages('town-square'))[0];

    await Promise.all([
        waitEvent(main(), 'mattermost'),
        waitEvent(main(), 'matrix'),
        mattermostClient.post('/posts', {
            channel_id: channelId,
            root_id: firstMattermost.id,
            message: 'third message',
        }),
    ]);
    const thirdMatrix = (await getMatrixMessages('town-square'))[0];

    t.equal(thirdMatrix.sender, '@mm_mattermost_a:localhost');
    t.equal(
        await getMattermostUsername(secondMattermost.user_id),
        'matrix_matrix_b',
    );
    t.equal(firstMatrix.sender, '@mm_mattermost_a:localhost');

    t.equal(secondMattermost.root_id, firstMattermost.id);
    t.equal(
        thirdMatrix.content['m.relates_to']['m.in_reply_to'].event_id,
        secondMatrix.event_id,
    );

    t.equal(secondMattermost.message, 'second message');
    t.true(thirdMatrix.content.body.endsWith('\n\nthird message'));

    t.end();
});

test('Reply to deleted thread', async t => {
    // Create a thread, delete the root in matrix. The thread is deleted in
    // mattermost, but only the root is gone in matrix. Replying to the second
    // message should result in a non-reply in mattermost.
    const client = getMatrixClient('matrix_a');
    const roomId = MATRIX_ROOM_IDS['off-topic'];

    const promise = Promise.all([
        waitEvent(main(), 'matrix', 4),
        waitEvent(main(), 'mattermost', 4),
    ]);
    const first = await client.sendMessage(roomId, {
        msgtype: 'm.text',
        body: 'root message',
    });
    const second = await client.sendMessage(roomId, {
        msgtype: 'm.text',
        body: '> <@matrix_a> root message\n\nreply message',
        format: 'org.matrix.custom.html',
        formatted_body: '<mx-reply>Dummy content</mx-reply>reply message',
        'm.relates_to': {
            'm.in_reply_to': {
                event_id: first.event_id,
            },
        },
    });
    await client.redactEvent(roomId, first.event_id);
    await client.sendMessage(roomId, {
        msgtype: 'm.text',
        body: '> <@matrix_a> reply message\n\nlast message',
        format: 'org.matrix.custom.html',
        formatted_body: '<mx-reply>Dummy content</mx-reply>last message',
        'm.relates_to': {
            'm.in_reply_to': {
                event_id: second.event_id,
            },
        },
    });
    await promise;

    const mattermostMessage = (await getMattermostMessages('off-topic'))[0];
    t.equal(mattermostMessage.message, 'last message', 'Received last message');
    t.equal(mattermostMessage.root_id, '', 'Last message is not a reply');
});

test('Kill bridge', async t => {
    await main().killBridge(0);
    t.end();
});

test('Mattermost reply to messages sent while bridge is down', async t => {
    const mattermostClient = getMattermostClient('mattermost_a');
    const mattermostPost = await mattermostClient.post('/posts', {
        channel_id: MATTERMOST_CHANNEL_IDS['town-square'],
        message: 'hidden message',
    });

    await startBridge();

    await Promise.all([
        // There is a lot of noise from bridge startup. We only listen for the
        // matrix echo.
        waitEvent(main(), 'matrix'),
        mattermostClient.post('/posts', {
            channel_id: MATTERMOST_CHANNEL_IDS['town-square'],
            root_id: mattermostPost.id,
            message: 'new message',
        }),
    ]);

    const matrixReply = (await getMatrixMessages('town-square'))[0];
    t.equal(matrixReply.content.body, 'new message', 'Received last message');
    t.equal(
        matrixReply.content['m.relates_to'],
        undefined,
        'Mattermost message is not a reply',
    );

    await main().killBridge(0);
    t.end();
});
