import { Post } from '../entities/Post';
import { ClientError } from '../mattermost/Client';
import { randomBytes } from 'crypto';
import { spawn } from 'child_process';
import { EventEmitter } from 'events';

export function remove<T>(a: T[], x: T): void {
    const index = a.indexOf(x, 0);
    if (index > -1) {
        a.splice(index, 1);
    }
}

const SUFFIXES: string[] = ['_', '-', '__', '--'];

export async function findFirstAvailable(
    s: string,
    check: (string) => Promise<boolean>,
): Promise<string> {
    if (await check(s)) {
        return s;
    }
    for (const suffix of SUFFIXES) {
        if (await check(`${s}${suffix}`)) {
            return `${s}${suffix}`;
        }
    }
    let suffix = 0;
    while (!(await check(`${s}${suffix}`))) {
        suffix += 1;
    }
    return `${s}${suffix}`;
}

export async function replaceAsync(
    s: string,
    regex: RegExp,
    f: (...string) => Promise<string>,
): Promise<string> {
    const promises: Promise<string>[] = [];
    s.replace(regex, (...args) => {
        promises.push(f(...args));
        return '';
    });
    const data = await Promise.all(promises);
    return s.replace(regex, () => data.shift() as string);
}

export function localpart(s: string): string {
    return s.slice(1).split(':')[0];
}

// Username must begin with a letter, and contain between 3 to 22 lowercase
// characters made up of numbers, letters, and the symbols ‘.’, ‘-‘, and ‘_’.
export function sanitizeMattermostUsername(s: string): string {
    s = s.toLowerCase();
    s = s.replace(/[^a-z0-9_\-\.]/g, '_');
    s = s.replace(/^_*/, '');
    if (!s[0].match(/[a-z]/)) {
        s = 'a' + s;
    }
    s = s.replace(/__+/g, '_');
    s = s.replace(/_$/g, '');
    while (s.length < 3) {
        s += '_';
    }
    if (s.length > 22) {
        s = s.slice(0, 22);
    }
    return s;
}

export function uniq<T>(a: T[]): T[] {
    return [...new Set(a)];
}

export async function handlePostError(
    e: unknown,
    postid: string,
): Promise<void> {
    if (
        e instanceof ClientError &&
        ((e.m.status_code === 400 &&
            e.m.id === 'api.context.invalid_url_param.app_error') ||
            (e.m.status_code === 404 &&
                e.m.id === 'store.sql_post.get.app_error'))
    ) {
        // The post we are replying to no longer exists. Delete the post from the database.
        await Post.removeAll(postid);
    } else {
        throw e;
    }
}

// eslint-disable-next-line @typescript-eslint/no-empty-function
export async function none(): Promise<void> {}

// Generates a random string of length n.
export function randomString(n: number): string {
    return randomBytes(1 + (n * 3) / 4)
        .toString('base64')
        .replace(/\+/g, '_')
        .replace(/\//g, '-')
        .replace(/=/g, '')
        .slice(0, n);
}

export async function notifySystemd(): Promise<void> {
    await new Promise(resolve => {
        const proc = spawn('systemd-notify', [
            '--ready',
            `--pid=${process.pid}`,
        ]);
        proc.on('exit', resolve);
        // systemd might not exist, etc. We've tried out best
        proc.on('error', resolve);
    });
}

export async function waitEvent(
    emitter: EventEmitter,
    event: string,
    n: number = 1,
): Promise<void> {
    await new Promise(resolve => {
        let counter = 0;
        function onEvent() {
            counter += 1;
            if (counter === n) {
                emitter.removeListener(event, onEvent);
                resolve();
            }
        }
        emitter.on(event, onEvent);
    });
}

type Fulfilled = {
    status: 'fulfilled';
    value: unknown;
};
type Rejected = {
    status: 'rejected';
    reason: Error;
};

export async function allSettled(
    promises: (Promise<unknown> | undefined)[],
): Promise<(Fulfilled | Rejected)[]> {
    return await Promise.all(
        promises.map(p =>
            // Promise.resolve handles the case where p is undefined
            Promise.resolve(p).then(
                val => ({ status: 'fulfilled', value: val } as Fulfilled),
                err => ({ status: 'rejected', reason: err } as Rejected),
            ),
        ),
    );
}
