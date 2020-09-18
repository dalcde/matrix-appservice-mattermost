import { startBridge, test, main } from './utils/Bridge';
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
