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
    if (!s[0].match(/[a-zA-Z]/)) {
        s = 'a' + s;
    }
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
