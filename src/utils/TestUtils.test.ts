import * as test from 'tape';

import { User } from '../entities/User';
import { setupDb, setConfig } from './TestUtils';
import { config } from '../Config';

test('test testutils setupDb', async t => {
    await setupDb();

    const user = await User.findOne({
        matrix_userid: '@mm_mmuser:matrix.org',
    });
    t.notEqual(user, undefined);
    // This is always true by the previous line, but typescript doesn't know that
    if (user !== undefined) {
        t.equal(user.matrix_displayname, 'mdisplay');
        t.equal(user.is_matrix_user, false);
    }
    t.end();
});

test('test testutils config', t => {
    setConfig({
        logging: 'trace',
    });
    setConfig({
        mattermost_url: 'http://localhost:8065/',
    });
    t.equal(config().mattermost_url, 'http://localhost:8065/');
    t.equal(config().logging, undefined);
    t.end();
});
