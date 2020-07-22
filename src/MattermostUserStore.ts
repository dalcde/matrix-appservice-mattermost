import { Intent, Bridge } from 'matrix-appservice-bridge';
import { User } from './entities/User';
import { Client } from './mattermost/Client';
import { getManager } from 'typeorm';
import { config } from './Config';
import * as Logger from './Logging';
import Mutex from './utils/Mutex';
import Main from './Main';
import { findFirstAvailable } from './utils/Functions';
import { MattermostUserInfo } from './Interfaces';

export default class MattermostUserStore {
    users: Map<string, User>;
    mutex: Mutex;
    constructor(readonly main: Main) {
        this.mutex = new Mutex();
        this.users = new Map();
    }

    public get(userid: string): User | undefined {
        return this.users.get(userid);
    }

    public async getOrCreate(
        userid: string,
        sync: boolean = false,
    ): Promise<User> {
        let user = this.users.get(userid);
        if (user !== undefined) {
            if (sync) await this.updateUser(undefined, user);
            return user;
        }

        // Lock mutex
        await this.mutex.lock();
        // Try again. it might have been created in another call.
        user = this.users.get(userid);
        if (user !== undefined) {
            this.mutex.unlock();
            if (sync) await this.updateUser(undefined, user);
            return user;
        }

        const data_promise = this.main.client.get(`/users/${userid}`);
        user = await User.findOne({
            mattermost_userid: userid,
        });
        if (user !== undefined && user.is_matrix_user) {
            throw 'Trying to get Matrix user from MattermostUserStore';
        }
        const data = await data_promise;
        const server_name = config().homeserver.server_name;

        if (user === undefined) {
            const localpart = await findFirstAvailable(
                `${config().matrix_localpart_prefix}${data.username}`,
                async s =>
                    (await User.findOne({
                        matrix_userid: `@${s}:${server_name}`,
                    })) === undefined,
            );
            user = await User.createMattermostUser(
                `@${localpart}:${server_name}`,
                userid,
                data.username,
                '', // Set the displayname to be '' for now. It will be updated in updateUser
            );
        }
        await this.updateUser(data, user);
        this.users.set(userid, user);

        this.mutex.unlock();

        return user;
    }

    async updateUser(data: MattermostUserInfo | undefined, user: User) {
        if (data === undefined) {
            data = (await this.main.client.get(
                `/users/${user.mattermost_userid}`,
            )) as MattermostUserInfo;
        }

        let displayName = data.username;
        if (data.first_name || data.last_name) {
            displayName = `${data.first_name} ${data.last_name}`.trim();
        }

        if (
            user.mattermost_username !== data.username ||
            user.matrix_displayname !== displayName
        ) {
            user.mattermost_username = data.username;
            user.matrix_displayname = displayName;
            await user.save();
        }
        await this.intent(user).setDisplayName(displayName);
    }

    intent(user: User): Intent {
        return this.main.bridge.getIntent(user.matrix_userid);
    }

    public async getOrCreateIntent(
        userid: string,
        sync: boolean = false,
    ): Promise<Intent> {
        return this.intent(await this.getOrCreate(userid, sync));
    }

    public getIntent(userid: string): Intent | undefined {
        const user = this.get(userid);
        if (user === undefined) {
            return undefined;
        } else {
            return this.intent(user);
        }
    }
}
