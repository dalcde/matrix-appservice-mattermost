import { MatrixMessage, MatrixEvent } from '../Interfaces';
import { User } from '../entities/User';
import { replaceAsync } from './Functions';
import { config } from '../Config';
import { marked } from 'marked';
import * as Turndown from 'turndown';

const MARKED_OPTIONS = {
    gfm: true,
    headerIds: false,
    breaks: true,
};

// Use an invalid character as a delimiter
const DELIMIT: string = '\x00';

const turndown = new Turndown();
turndown.addRule('mention', {
    filter: node => {
        return (
            node.nodeName === 'A' &&
            node.getAttribute('href').startsWith('https://matrix.to/')
        );
    },
    replacement: (content, node) => {
        const href = node.getAttribute('href');
        const id = href.split('/')[4];
        if (id === undefined) {
            return `${content}`;
        } else {
            return `${DELIMIT}${id}${DELIMIT}${content}${DELIMIT}`;
        }
    },
});
turndown.addRule('mx-reply', {
    filter: 'mx-reply',
    replacement: () => '',
});
async function translateMattermostUsername(body: string, html: boolean) {
    return await replaceAsync(body, /@[a-z0-9\.\-_]*/g, async s => {
        let tail = '';
        while (true) {
            const user = await User.findOne({
                mattermost_username: s.slice(1),
            });
            if (user !== undefined) {
                if (html) {
                    return `<a href='https://matrix.to/#/${user.matrix_userid}'>${user.matrix_displayname}</a>${tail}`;
                } else {
                    return user.matrix_displayname + tail;
                }
            }
            if (s.endsWith('.')) {
                s = s.slice(0, -1);
                tail = tail + '.';
            } else {
                break;
            }
        }
        return s + tail;
    });
}

export async function matrixToMattermost(
    content: MatrixMessage,
): Promise<string> {
    if (content.formatted_body === undefined) {
        return content.body;
    }
    const formatted = turndown.turndown(content.formatted_body);
    const match = new RegExp(
        `${DELIMIT}([^${DELIMIT}]*)${DELIMIT}([^${DELIMIT}]*)${DELIMIT}`,
        'g',
    );
    return await replaceAsync(formatted, match, async (s, p1, p2) => {
        if (p1[0] === '@') {
            const user = await User.findOne({
                matrix_userid: p1,
            });
            if (user !== undefined) {
                return `@${user.mattermost_username}`;
            } else {
                return p2;
            }
        } else {
            return p2;
        }
    });
}

export async function mattermostToMatrix(
    body: string,
    msgtype: string = 'm.text',
): Promise<MatrixMessage> {
    // Replace paragraphing with <br>
    const format0 = marked(body, MARKED_OPTIONS)
        .replace(/\n/g, '')
        .replace(/<\/p><p>/g, '<br>')
        .replace(/<p>/g, '')
        .replace(/<\/p>/g, '');

    const formatted_body = await translateMattermostUsername(format0, true);

    if (formatted_body === body) {
        return {
            msgtype,
            body,
        };
    } else {
        return {
            msgtype,
            body: await translateMattermostUsername(body, false),
            format: 'org.matrix.custom.html',
            formatted_body,
        };
    }
}

export function constructMatrixReply(
    original: MatrixEvent,
    message: MatrixMessage,
): void {
    message['m.relates_to'] = {
        'm.in_reply_to': {
            event_id: original.event_id,
        },
    };
    const block = `<mx-reply><blockquote><a href="https://matrix.to/#/${
        original.room_id
    }/${original.event_id}?via=${
        config().homeserver.server_name
    }">In reply to</a> <a href="https://matrix.to/#/${original.sender}">${
        original.sender
    }</a><br>${
        original.content.formatted_body ?? original.content.body
    }</blockquote></mx-reply>`;

    message.formatted_body = block + (message.formatted_body ?? message.body);
    message.format = 'org.matrix.custom.html';
    message.body = `> <${original.sender}> ${original.content.body.slice(
        0,
        30,
    )}\n\n${message.body}`;
}
