import * as test from 'tape';
import { setConfig, setupDb } from './TestUtils';
import {
    mattermostToMatrix,
    matrixToMattermost,
    constructMatrixReply,
} from './Formatting';

test('setup formatting config', async t => {
    await setupDb();
    setConfig({
        homeserver: {
            server_name: 'matrix.org',
            url: 'https://matrix.org',
        },
    });
    t.end();
});

test('mattermostToMatrix username translation', async t => {
    const message = await mattermostToMatrix('@b-_b... @foo @b-_b');
    t.deepEqual(message, {
        msgtype: 'm.text',
        body: 'display... @foo display',
        format: 'org.matrix.custom.html',
        formatted_body:
            "<a href='https://matrix.to/#/@bar:matrix.org'>display</a>... @foo <a href='https://matrix.to/#/@bar:matrix.org'>display</a>",
    });
    t.end();
});

test('mattermostToMatrix markdown', async t => {
    const message = await mattermostToMatrix('_emph_ **bold**\nline');
    t.deepEqual(message, {
        msgtype: 'm.text',
        body: '_emph_ **bold**\nline',
        format: 'org.matrix.custom.html',
        formatted_body: '<em>emph</em> <strong>bold</strong><br>line',
    });
    t.end();
});

test('mattermostToMatrix double linebreak', async t => {
    const message = await mattermostToMatrix('a\n\nb');
    t.deepEqual(message, {
        msgtype: 'm.text',
        body: 'a\n\nb',
        format: 'org.matrix.custom.html',
        formatted_body: 'a<br>b',
    });
    t.end();
});

test('matrixToMattermost username translation', async t => {
    const message = await matrixToMattermost({
        msgtype: 'm.text',
        body: 'empty',
        format: 'org.matrix.custom.html',
        formatted_body:
            "<a href='https://matrix.to/#/@bar:matrix.org'>display</a> <a href='https://matrix.to/#/@null:matrix.org'>non-existent</a> <a href='https://matrix.to/broken-link'>broken</a>",
    });
    t.equal(message, '@b-_b non-existent broken');
    t.end();
});

test('matrixToMattermost formatting', async t => {
    const message = await matrixToMattermost({
        msgtype: 'm.text',
        body: 'empty',
        format: 'org.matrix.custom.html',
        formatted_body: '<em>emph</em> <strong>bold</strong><br/>line',
    });
    t.equal(message, '_emph_ **bold**  \nline');
    t.end();
});

test('matrixToMattermost plain text', async t => {
    const body = 'display... @foo _emph_ **bold**\ndisplay';
    const message = await matrixToMattermost({
        msgtype: 'm.text',
        body,
    });
    t.equal(message, body);
    t.end();
});

// Events and replies obtained from Element client
const HTML_EVENT = {
    content: {
        body: '*hi*',
        format: 'org.matrix.custom.html',
        formatted_body: '<em>hi</em>',
        msgtype: 'm.text',
    },
    origin_server_ts: 1596337824697,
    sender: '@sender:matrix.org',
    type: 'm.room.message',
    unsigned: {
        age: 83,
    },
    event_id: '$T6ou9n_AGgvO8NdDsoq5DjC9nQGiyq7DUq9OOBAANJw',
    room_id: '!JquZHMOyPKgUWlLSfy:matrix.org',
};

const TEXT_EVENT = {
    content: {
        body: 'hi',
        msgtype: 'm.text',
    },
    origin_server_ts: 1596337395434,
    sender: '@sender:matrix.org',
    type: 'm.room.message',
    unsigned: {
        age: 115,
    },
    event_id: '$GXbUVDXOvAuRDchj-XM3KqCJ64NvjjErR5oHC6nT3HY',
    room_id: '!JquZHMOyPKgUWlLSfy:matrix.org',
};

const HTML_REPLY = {
    body: '*bye*',
    format: 'org.matrix.custom.html',
    formatted_body: '<em>bye</em>',
    msgtype: 'm.text',
};

const TEXT_REPLY = {
    body: 'bye',
    msgtype: 'm.text',
};
test('formatMatrixReply text text', t => {
    const newMessage = { ...TEXT_REPLY };

    const result = {
        body: '> <@sender:matrix.org> hi\n\nbye',
        format: 'org.matrix.custom.html',
        formatted_body:
            '<mx-reply><blockquote><a href="https://matrix.to/#/!JquZHMOyPKgUWlLSfy:matrix.org/$GXbUVDXOvAuRDchj-XM3KqCJ64NvjjErR5oHC6nT3HY?via=matrix.org">In reply to</a> <a href="https://matrix.to/#/@sender:matrix.org">@sender:matrix.org</a><br>hi</blockquote></mx-reply>bye',
        'm.relates_to': {
            'm.in_reply_to': {
                event_id: '$GXbUVDXOvAuRDchj-XM3KqCJ64NvjjErR5oHC6nT3HY',
            },
        },
        msgtype: 'm.text',
    };
    constructMatrixReply(TEXT_EVENT, newMessage);
    t.deepEqual(newMessage, result);
    t.end();
});

test('formatMatrixReply html html', t => {
    const newMessage = { ...HTML_REPLY };

    const result = {
        body: '> <@sender:matrix.org> *hi*\n\n*bye*',
        format: 'org.matrix.custom.html',
        formatted_body:
            '<mx-reply><blockquote><a href="https://matrix.to/#/!JquZHMOyPKgUWlLSfy:matrix.org/$T6ou9n_AGgvO8NdDsoq5DjC9nQGiyq7DUq9OOBAANJw?via=matrix.org">In reply to</a> <a href="https://matrix.to/#/@sender:matrix.org">@sender:matrix.org</a><br><em>hi</em></blockquote></mx-reply><em>bye</em>',
        'm.relates_to': {
            'm.in_reply_to': {
                event_id: '$T6ou9n_AGgvO8NdDsoq5DjC9nQGiyq7DUq9OOBAANJw',
            },
        },
        msgtype: 'm.text',
    };
    constructMatrixReply(HTML_EVENT, newMessage);
    t.deepEqual(newMessage, result);
    t.end();
});

test('formatMatrixReply html text', t => {
    const newMessage = { ...TEXT_REPLY };
    const result = {
        body: '> <@sender:matrix.org> *hi*\n\nbye',
        format: 'org.matrix.custom.html',
        formatted_body:
            '<mx-reply><blockquote><a href="https://matrix.to/#/!JquZHMOyPKgUWlLSfy:matrix.org/$T6ou9n_AGgvO8NdDsoq5DjC9nQGiyq7DUq9OOBAANJw?via=matrix.org">In reply to</a> <a href="https://matrix.to/#/@sender:matrix.org">@sender:matrix.org</a><br><em>hi</em></blockquote></mx-reply>bye',
        'm.relates_to': {
            'm.in_reply_to': {
                event_id: '$T6ou9n_AGgvO8NdDsoq5DjC9nQGiyq7DUq9OOBAANJw',
            },
        },
        msgtype: 'm.text',
    };
    constructMatrixReply(HTML_EVENT, newMessage);
    t.deepEqual(newMessage, result);
    t.end();
});
test('formatMatrixReply text html', t => {
    const newMessage = { ...HTML_REPLY };
    const result = {
        body: '> <@sender:matrix.org> hi\n\n*bye*',
        format: 'org.matrix.custom.html',
        formatted_body:
            '<mx-reply><blockquote><a href="https://matrix.to/#/!JquZHMOyPKgUWlLSfy:matrix.org/$GXbUVDXOvAuRDchj-XM3KqCJ64NvjjErR5oHC6nT3HY?via=matrix.org">In reply to</a> <a href="https://matrix.to/#/@sender:matrix.org">@sender:matrix.org</a><br>hi</blockquote></mx-reply><em>bye</em>',
        'm.relates_to': {
            'm.in_reply_to': {
                event_id: '$GXbUVDXOvAuRDchj-XM3KqCJ64NvjjErR5oHC6nT3HY',
            },
        },
        msgtype: 'm.text',
    };
    constructMatrixReply(TEXT_EVENT, newMessage);
    t.deepEqual(newMessage, result);
    t.end();
});
