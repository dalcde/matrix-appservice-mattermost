import { User } from '../entities/User';
import Mutex from '../utils/Mutex';
import Main from '../Main';
import { localpart, sanitizeMattermostUsername } from '../utils/Functions';
import { config } from '../Config';
import { findFirstAvailable } from '../utils/Functions';
import log from '../Logging';

export default class MatrixUserStore {
    public readonly byMatrixUserId: Map<string, User>;
    public readonly byMattermostUserId: Map<string, User>;
    private readonly mutex: Mutex;
    constructor(private readonly main: Main) {
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
                throw new Error(
                    'Trying to get Mattermost user from MatrixUserStore',
                );
            }
            await this.updateUser(user);
        } else {
            const client = this.main.client;
            const localpart_ = localpart(matrix_userid);
            const template = config().mattermost_username_template;

            let displayname = '';

            if (template.includes('[DISPLAY]')) {
                try {
                    const resp = await this.main.botClient.getProfileInfo(
                        matrix_userid,
                        'displayname',
                    );
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
            log.debug(
                `Creating mattermost puppet ${user.mattermost_userid} for ${matrix_userid}`,
            );
            this.mutex.unlock();
        }

        this.byMatrixUserId.set(matrix_userid, user);
        this.byMattermostUserId.set(user.mattermost_userid, user);

        return user;
    }

    public async updateUser(user: User): Promise<void> {
        let displayname = localpart(user.matrix_userid);

        try {
            const resp = await this.main.botClient.getProfileInfo(
                user.matrix_userid,
                'displayname',
            );
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

    /**
     * Given a mattermost userid, return the corresponding User if it is a
     * puppet of a matrix user, or null otherwise.
     */
    public async getByMattermost(
        mattermostUserId: string,
    ): Promise<User | null> {
        const cached = this.byMattermostUserId.get(mattermostUserId);
        if (cached !== undefined) {
            return cached;
        }
        const response = await User.findOne({
            mattermost_userid: mattermostUserId,
        });
        if (response === undefined || response.is_matrix_user === false) {
            return null;
        } else {
            return response;
        }
    }
}
