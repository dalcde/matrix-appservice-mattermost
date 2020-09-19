import { startBridge, test, main } from './utils/Bridge';
import { getMattermostClient } from './utils/Client';

import fetch from 'node-fetch';

test('Start bridge', async t => {
    await startBridge();
    t.end();
});

test('Appservice should reject invalid token', async t => {
    const noToken = await fetch(
        'http://localhost:9995/_matrix/app/v1/users/@mm_mattermost_a:localhost',
    );
    t.equal(noToken.status, 401);
    t.deepEqual(await noToken.json(), {
        errcode: 'M_UNKNOWN_TOKEN',
        error: 'No token supplied',
    });

    const invalidToken = await fetch(
        'http://localhost:9995/_matrix/app/v1/users/@mm_mattermost_a:localhost?access_token=1234',
    );
    t.equal(invalidToken.status, 403);
    t.deepEqual(await invalidToken.json(), {
        errcode: 'M_UNKNOWN_TOKEN',
        error: 'Bad token supplied',
    });

    t.end();
});

test('Rename admin endpoint', async t => {
    const hsToken = main().registration.hs_token;
    const client = getMattermostClient('admin');

    await fetch(
        `http://localhost:9995/bridge/rename/matrix_matrix_a/matrix_a?access_token=${hsToken}`,
        { method: 'POST' },
    );
    t.equal((await client.post('/users/usernames', ['matrix_a'])).length, 1);
    t.deepEqual(await client.post('/users/usernames', ['matrix_matrix_a']), []);

    await fetch(
        `http://localhost:9995/bridge/rename/matrix_a/matrix_matrix_a?access_token=${hsToken}`,
        { method: 'POST' },
    );
    t.equal(
        (await client.post('/users/usernames', ['matrix_matrix_a'])).length,
        1,
    );
    t.deepEqual(await client.post('/users/usernames', ['matrix_a']), []);

    t.end();
});

test('Do not rename if target already exists', async t => {
    const hsToken = main().registration.hs_token;
    const client = getMattermostClient('admin');
    const result = await fetch(
        `http://localhost:9995/bridge/rename/matrix_matrix_a/matrix_matrix_b?access_token=${hsToken}`,
        { method: 'POST' },
    );
    t.equal(result.status, 500, 'Correct status code 500');
    t.equal(
        (await client.post('/users/usernames', ['matrix_matrix_a'])).length,
        1,
        'User not renamed',
    );
});

test('Do not rename non-puppet users', async t => {
    const hsToken = main().registration.hs_token;
    const client = getMattermostClient('admin');
    const result = await fetch(
        `http://localhost:9995/bridge/rename/mattermost_a/mattermost_c?access_token=${hsToken}`,
        { method: 'POST' },
    );
    t.equal(result.status, 400, 'Correct status code 400');
    t.equal(
        (await client.post('/users/usernames', ['mattermost_a'])).length,
        1,
        'User not renamed',
    );
});

test('Return correct error when renaming non-existent user', async t => {
    const hsToken = main().registration.hs_token;
    const result = await fetch(
        `http://localhost:9995/bridge/rename/nonexistent/newname?access_token=${hsToken}`,
        { method: 'POST' },
    );
    t.equal(result.status, 400, 'Correct status code 400');
});

test('Status does not need access token', async t => {
    const result = await fetch('http://localhost:9995/bridge/status');
    t.equal(result.status, 200);
    t.equal(await result.text(), 'running');

    t.end();
});

test('Kill bridge', async t => {
    await main().killBridge(0);
    t.end();
});
