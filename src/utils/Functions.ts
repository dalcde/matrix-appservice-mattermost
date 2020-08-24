import { Post } from '../entities/Post';
import { ClientError } from '../mattermost/Client';
import * as assert from 'assert';

export function remove<T>(a: T[], x: T) {
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

export async function handlePostError(e: any, postid: string) {
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

export function deepEqual(a: any, b: any) {
    try {
        assert.deepStrictEqual(a, b);
        return true;
    } catch (e) {
        return false;
    }
}
