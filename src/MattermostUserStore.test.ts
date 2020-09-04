import * as test from 'tape';
import MattermostUserStore from './MattermostUserStore';
import Main from './Main';

import { setConfig, setupDb } from './utils/TestUtils';
import { User } from './entities/User';

test('display name', async t => {
    await setupDb();
    setConfig({
        matrix_display_name_template: '[DISPLAY] [USERNAME] [m]',
    });
    const store = new MattermostUserStore((undefined as unknown) as Main);
    let displayName: string = '';

    store.client = () => {
        return {
            setDisplayName: (name: string) => {
                displayName = name;
            },
        } as any;
    };

    const user = (await User.findOne({
        matrix_userid: '@mm_mmuser:matrix.org',
    })) as User;
    const check = async (name: string) => {
        t.equal(displayName, name);
        const dbUser = (await User.findOne({
            matrix_userid: '@mm_mmuser:matrix.org',
        })) as User;
        t.equal(dbUser.matrix_displayname, name);
    };
    await store.updateUser(
        {
            username: 'mmuser',
            first_name: 'Foo',
            last_name: 'Bar',
        },
        user,
    );
    await check('Foo Bar mmuser [m]');
    await store.updateUser(
        {
            username: 'mmuser',
            first_name: 'Foo',
            last_name: '',
        },
        user,
    );
    await check('Foo mmuser [m]');
    await store.updateUser(
        {
            username: 'mmuser',
            first_name: '',
            last_name: 'Bar',
        },
        user,
    );
    await check('Bar mmuser [m]');
    await store.updateUser(
        {
            username: 'mmuser',
            first_name: '',
            last_name: '',
        },
        user,
    );
    await check('mmuser mmuser [m]');
    await store.updateUser(
        {
            username: 'mmuser2',
            first_name: '',
            last_name: '',
        },
        user,
    );
    await check('mmuser2 mmuser2 [m]');

    const dbUser = (await User.findOne({
        matrix_userid: '@mm_mmuser:matrix.org',
    })) as User;
    t.equal(dbUser.mattermost_username, 'mmuser2');

    t.end();
});
