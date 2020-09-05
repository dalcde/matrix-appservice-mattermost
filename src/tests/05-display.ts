import { startBridge, test, main } from './utils/Bridge';
import { getMattermostClient, getMatrixClient } from './utils/Client';

import { waitEvent } from '../utils/Functions';

test('Start bridge', async t => {
    await startBridge();
    t.end();
});

test('mattermost display names', async t => {
    const client = getMattermostClient('admin');
    const users = await client.post('/users/usernames', [
        'matrix_matrix_a',
        'matrix_matrix_b',
    ]);
    t.equal(users[0].first_name, 'Matrix UserA');
    t.equal(users[0].last_name, '');
    t.equal(users[1].first_name, 'matrix_b');
    t.equal(users[1].last_name, '');
    t.end();
});

test('matrix display names', t => {
    t.plan(3);
    const client = getMatrixClient('admin');
    for (const [user, display] of [
        ['mm_mattermost_a', 'MattermostUser A [mm]'],
        ['mm_mattermost_b', 'mattermost_b [mm]'],
        ['matterbot', 'Mattermost Bridge'],
    ]) {
        client
            .getProfileInfo(`@${user}:localhost`, 'displayname')
            .then(profile => {
                t.equal(profile.displayname, display);
            });
    }
});

test('change mattermost user display name', async t => {
    const client = getMattermostClient('mattermost_b');

    await Promise.all([
        waitEvent(main(), 'mattermost'),
        waitEvent(main(), 'matrix', 2),
        client.put(`/users/${client.userid}/patch`, {
            first_name: 'MMTest',
            last_name: 'Last',
        }),
    ]);

    const matrix = getMatrixClient('admin');

    let profile = await matrix.getProfileInfo(
        `@mm_mattermost_b:localhost`,
        'displayname',
    );
    t.equal(profile.displayname, 'MMTest Last [mm]');

    await Promise.all([
        waitEvent(main(), 'mattermost'),
        waitEvent(main(), 'matrix', 2),
        client.put(`/users/${client.userid}/patch`, {
            first_name: '',
            last_name: '',
        }),
    ]);

    profile = await matrix.getProfileInfo(
        `@mm_mattermost_b:localhost`,
        'displayname',
    );
    t.equal(profile.displayname, 'mattermost_b [mm]');

    t.end();
});

test('change matrix user display name', async t => {
    const client = getMatrixClient('matrix_b');

    await Promise.all([
        waitEvent(main(), 'matrix', 2),
        waitEvent(main(), 'mattermost'),
        client.setDisplayName('Hello World'),
    ]);

    const mattermost = getMattermostClient('admin');

    let user = await mattermost.get(`/users/username/matrix_matrix_b`);
    t.equal(user.first_name, 'Hello World');
    t.equal(user.last_name, '');

    await Promise.all([
        waitEvent(main(), 'matrix', 2),
        waitEvent(main(), 'mattermost'),
        client.setDisplayName(''),
    ]);

    user = await mattermost.get(`/users/username/matrix_matrix_b`);
    t.equal(user.first_name, 'matrix_b');
    t.equal(user.last_name, '');

    t.end();
});

test('Kill bridge', async t => {
    await main().killBridge(0);
    t.end();
});
