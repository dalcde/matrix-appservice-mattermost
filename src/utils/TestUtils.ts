import { User } from '../entities/User';
import { Post } from '../entities/Post';
import { createConnection, getConnection } from 'typeorm';

const entities = [User, Post];
const connection = createConnection({
    type: 'sqlite',
    database: ':memory:',
    entities,
    dropSchema: true,
    synchronize: true,
    logging: false,
});

export async function setupDb() {
    await connection;

    await Promise.all([
        User.create({
            matrix_userid: '@bar:matrix.org',
            mattermost_userid: 'abcdabcdabcdabcdabcdabcdab',
            access_token: '',
            is_matrix_user: true,
            mattermost_username: 'b-_b',
            matrix_displayname: 'display',
        }).save(),
        User.create({
            matrix_userid: '@mm_mmuser:matrix.org',
            mattermost_userid: 'abcdabcdabcdabcdabcdabcdad',
            access_token: '',
            is_matrix_user: false,
            mattermost_username: 'mmuser',
            matrix_displayname: 'mdisplay',
        }).save(),
    ]);
}

import { Config, setConfig as realSetConfig } from '../Config';

export function setConfig(c) {
    realSetConfig((c as any) as Config);
}
