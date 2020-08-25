import { User } from './entities/User';
import Mutex from './utils/Mutex';
import Main from './Main';
import { localpart, sanitizeMattermostUsername } from './utils/Functions';
import { config } from './Config';
import { findFirstAvailable } from './utils/Functions';

export default class MatrixUserStore {
    readonly byMatrixUserId: Map<string, User>;
    readonly byMattermostUserId: Map<string, User>;
    mutex: Mutex;
    constructor(readonly main: Main) {
        this.mutex = new Mutex();
        this.byMatrixUserId = new Map();
        this.byMattermostUserId = new Map();
    }

    public get(matrix_userid: string): User | undefined {
        return this.byMatrixUserId.get(matrix_userid);
    }

    public async getOrCreate(
        matrix_userid: string,
        sync: boolean = false,
    ): Promise<User> {
        let user = this.get(matrix_userid);
        if (user !== undefined) {
            if (sync) await this.updateUser(user);
            return user;
        }

        // Lock mutex
        await this.mutex.lock();
        // Try again. it might have been created in another call.
        user = this.get(matrix_userid);
        if (user !== undefined) {
            this.mutex.unlock();
            if (sync) await this.updateUser(user);
            return user;
        }

        user = await User.findOne({
            matrix_userid,
        });
        if (user !== undefined) {
            this.mutex.unlock();
            if (!user.is_matrix_user) {
                throw 'Trying to get Mattermost user from MatrixUserStore';
            }
            await this.updateUser(user);
        } else {
            const client = this.main.client;
            const localpart_ = localpart(matrix_userid);
            const template = config().mattermost_username_template;

            let displayname = '';

            if (template.includes('[DISPLAY]')) {
                try {
                    const resp = await this.main.bridge
                        .getIntent()
                        .getProfileInfo(matrix_userid, 'displayname');
                    if (resp.displayname) {
                        displayname = resp.displayname;
                    }
                } catch (e) {
                    // Some users have no display name
                }
            }

            const defaultUsername = template
                .replace('[DISPLAY]', displayname)
                .replace('[LOCALPART]', localpart_);

            const username = await findFirstAvailable(
                sanitizeMattermostUsername(defaultUsername),
                async s =>
                    (await client.post('/users/usernames', [s])).length === 0,
            );
            user = await User.createMatrixUser(
                client,
                matrix_userid,
                username,
                displayname,
            );
            this.mutex.unlock();
        }

        this.byMatrixUserId.set(matrix_userid, user);
        this.byMattermostUserId.set(user.mattermost_userid, user);

        return user;
    }

    async updateUser(user: User): Promise<void> {
        let displayname = localpart(user.matrix_userid);

        try {
            const resp = await this.main.bridge
                .getIntent()
                .getProfileInfo(user.matrix_userid, 'displayname');
            if (resp.displayname) {
                displayname = resp.displayname;
            }
        } catch (e) {
            // Some users have no display name
        }

        if (user.matrix_displayname !== displayname) {
            user.matrix_displayname = displayname;
            await user.save();
        }

        await this.main.client.put(`/users/${user.mattermost_userid}/patch`, {
            first_name: displayname,
            last_name: '',
        });
    }
}
