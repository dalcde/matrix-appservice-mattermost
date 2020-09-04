import { User } from './entities/User';
import { config } from './Config';
import Mutex from './utils/Mutex';
import Main from './Main';
import { findFirstAvailable } from './utils/Functions';
import { MattermostUserInfo, MatrixClient } from './Interfaces';
import log from './Logging';

export default class MattermostUserStore {
    private users: Map<string, User>;
    private mutex: Mutex;
    constructor(private readonly main: Main) {
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
        if (user?.is_matrix_user) {
            throw new Error(
                'Trying to get Matrix user from MattermostUserStore',
            );
        }
        const data = await data_promise;
        const server_name = config().homeserver.server_name;

        if (user === undefined) {
            const localpart = await findFirstAvailable(
                `${config().matrix_localpart_prefix}${data.username}`,
                async s => {
                    try {
                        await this.main.botClient.register(s);
                        return true;
                    } catch (e) {
                        if (e.errcode === 'M_USER_IN_USE') {
                            return false;
                        } else {
                            throw e;
                        }
                    }
                },
            );
            log.debug(
                `Creating matrix puppet @${localpart}:${server_name} for ${userid}`,
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

    public async updateUser(
        data: MattermostUserInfo | undefined,
        user: User,
    ): Promise<void> {
        if (data === undefined) {
            data = (await this.main.client.get(
                `/users/${user.mattermost_userid}`,
            )) as MattermostUserInfo;
        }

        let displayName = data.username;
        if (data.first_name || data.last_name) {
            displayName = `${data.first_name} ${data.last_name}`.trim();
        }
        displayName = config()
            .matrix_display_name_template.replace('[DISPLAY]', displayName)
            .replace('[USERNAME]', data.username);

        if (
            user.mattermost_username !== data.username ||
            user.matrix_displayname !== displayName
        ) {
            user.mattermost_username = data.username;
            user.matrix_displayname = displayName;
            await user.save();
        }
        await this.client(user).setDisplayName(displayName);
    }

    public client(user: User): MatrixClient {
        return this.main.getMatrixClient(user.matrix_userid);
    }

    public async getOrCreateClient(
        userid: string,
        sync: boolean = false,
    ): Promise<MatrixClient> {
        return this.client(await this.getOrCreate(userid, sync));
    }

    public getClient(userid: string): MatrixClient | undefined {
        const user = this.get(userid);
        if (user === undefined) {
            return undefined;
        } else {
            return this.client(user);
        }
    }
}
