import { Entity, PrimaryColumn, Column, BaseEntity } from 'typeorm';
import { Client } from '../mattermost/Client';
import { config } from '../Config';
import { randomString } from '../utils/Functions';

@Entity('users')
export class User extends BaseEntity {
    @PrimaryColumn('text')
    public matrix_userid!: string;

    @Column('character', { length: '26' })
    public mattermost_userid!: string;

    @Column('text')
    public access_token!: string;

    @Column('boolean')
    public is_matrix_user!: boolean;

    @Column('text')
    public mattermost_username!: string;

    @Column('text')
    public matrix_displayname!: string;

    private _client?: Client;

    public get client(): Client {
        if (this._client === undefined) {
            this._client = new Client(
                config().mattermost_url,
                this.mattermost_userid,
                this.access_token,
            );
        }
        return this._client;
    }

    public static async createMatrixUser(
        client: Client,
        matrix_userid: string,
        username: string,
        displayname: string,
    ): Promise<User> {
        await client.post('/users', {
            username: username,
            password: randomString(45) + 'aA#2',
            first_name: displayname,
            email: config()
                .mattermost_email_template.replace(
                    '[USERNAME]',
                    randomString(16),
                )
                .replace('[RANDOM]', randomString(16)),
        });
        const resp = (await client.post('/users/usernames', [username]))[0];
        await client.post(`/users/${resp.id}/email/verify/member`);

        const token = await client.post(`/users/${resp.id}/tokens`, {
            description: 'bridge',
        });

        const user = User.create({
            matrix_userid,
            mattermost_userid: resp.id,
            access_token: token.token,
            is_matrix_user: true,
            mattermost_username: username,
            matrix_displayname: displayname,
        });

        await user.save();
        return user;
    }

    public static async createMattermostUser(
        matrix_userid: string,
        mattermost_userid: string,
        username: string,
        displayname: string,
    ): Promise<User> {
        const user = User.create({
            matrix_userid,
            mattermost_userid,
            access_token: '',
            is_matrix_user: false,
            mattermost_username: username,
            matrix_displayname: displayname,
        });
        await user.save();
        return user;
    }
}
