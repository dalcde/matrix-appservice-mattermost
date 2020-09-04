import * as test from 'tape';
import {
    remove,
    findFirstAvailable,
    localpart,
    sanitizeMattermostUsername,
    randomString,
    allSettled,
} from './Functions';

test('remove', t => {
    const x = [3, 5, 2, 6, 2];
    remove(x, 2);
    t.deepEqual(x, [3, 5, 6, 2]);

    remove(x, 4);
    t.deepEqual(x, [3, 5, 6, 2]);

    t.end();
});

test('findFirstAvailable', async t => {
    t.plan(2);

    const values = [
        'foo',
        'foo_',
        'bar',
        'bar_',
        'bar-',
        'bar__',
        'bar--',
        'bar0',
        'bar1',
    ];
    const check = async s => {
        return !values.includes(s);
    };

    t.equal(await findFirstAvailable('foo', check), 'foo-');
    t.equal(await findFirstAvailable('bar', check), 'bar2');

    t.end();
});

test('localpart', t => {
    t.equal(localpart('@foo:matrix.org'), 'foo');
    t.end();
});

test('sanitizeMattermostUsername', t => {
    t.equal(sanitizeMattermostUsername('test[irc]`-bot'), 'test_irc_-bot');
    t.equal(sanitizeMattermostUsername('13Gda'), 'a13gda');
    t.equal(sanitizeMattermostUsername('_13Gda'), 'a13gda');
    t.equal(sanitizeMattermostUsername('[b]Gda'), 'b_gda');
    t.equal(sanitizeMattermostUsername('_bGda'), 'bgda');
    t.equal(sanitizeMattermostUsername('a'), 'a__');
    t.equal(sanitizeMattermostUsername('foo-bar_12'), 'foo-bar_12');
    t.equal(sanitizeMattermostUsername('foo`_`foo'), 'foo_foo');
    t.equal(sanitizeMattermostUsername('foo`_`'), 'foo');
    t.equal(sanitizeMattermostUsername('John Smith'), 'john_smith');
    t.equal(sanitizeMattermostUsername('bar [irc]'), 'bar_irc');
    t.equal(sanitizeMattermostUsername('a'.repeat(50)), 'a'.repeat(22));
    t.end();
});

test('randomString', t => {
    for (const n of [5, 10, 12, 13, 14, 15]) {
        t.equal(randomString(n).length, n);
    }
    const rand = randomString(65);
    t.false(rand.includes('+'));
    t.false(rand.includes('='));
    t.false(rand.includes('/'));
    t.end();
});

test('allSettled', async t => {
    t.deepEqual(
        await allSettled([
            new Promise((resolve, reject) => reject('oops')),
            new Promise(resolve => resolve('yay')),
            undefined,
        ]),
        [
            { status: 'rejected', reason: 'oops' },
            { status: 'fulfilled', value: 'yay' },
            { status: 'fulfilled', value: undefined },
        ],
    );
    t.end();
});
