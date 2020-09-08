import { MatrixEvent, MattermostMessage } from './Interfaces';
import log from './Logging';
import Main from './Main';
import MatrixHandlers from './matrix/MatrixHandler';
import { getMatrixUsers, getMatrixClient } from './matrix/Utils';
import {
    getMattermostUsers,
    joinMattermostChannel,
    leaveMattermostChannel,
} from './mattermost/Utils';
import { MattermostHandlers } from './mattermost/MattermostHandler';

export default class Channel {
    private team?: string;

    constructor(
        public readonly main: Main,
        public readonly matrixRoom: string,
        public readonly mattermostChannel: string,
    ) {}

    public async getTeam(): Promise<string> {
        if (this.team === undefined) {
            this.team = (
                await this.main.client.get(
                    `/channels/${this.mattermostChannel}`,
                )
            ).team_id as string;
        }
        return this.team;
    }

    public async syncChannel(): Promise<void> {
        const [matrixUsers, mattermostUsers] = await Promise.all([
            getMatrixUsers(this.main, this.matrixRoom),
            getMattermostUsers(this.main.client, this.mattermostChannel),
        ]);

        await Promise.all(
            Array.from(matrixUsers.real, async matrix_userid => {
                if (this.main.skipMatrixUser(matrix_userid)) {
                    return;
                }
                const user = await this.main.matrixUserStore.getOrCreate(
                    matrix_userid,
                    true,
                );
                mattermostUsers.delete(user.mattermost_userid);
                await joinMattermostChannel(this, user);
            }),
        );

        await Promise.all(
            Array.from(mattermostUsers, async userid => {
                if (this.main.skipMattermostUser(userid)) {
                    return;
                }
                if (!(await this.main.isMattermostUser(userid))) {
                    await leaveMattermostChannel(
                        this.main.client,
                        this.mattermostChannel,
                        userid,
                    );
                } else {
                    const user = await this.main.mattermostUserStore.getOrCreate(
                        userid,
                        true,
                    );
                    matrixUsers.remote.delete(user.matrix_userid);
                    const client = this.main.mattermostUserStore.client(user);
                    await client.joinRoom(this.matrixRoom);
                }
            }),
        );

        await Promise.all(
            Array.from(matrixUsers.remote, async matrix_userid => {
                const client = getMatrixClient(
                    this.main.registration,
                    matrix_userid,
                );
                await client.leave(this.matrixRoom);
            }),
        );
    }

    public async onMattermostMessage(m: MattermostMessage): Promise<void> {
        const handler = MattermostHandlers[m.event];
        if (handler === undefined) {
            log.debug(`Unknown matermost message type: ${m.event}`);
        } else {
            await handler.bind(this)(m);
        }
    }

    public async onMatrixEvent(event: MatrixEvent): Promise<void> {
        const handler = MatrixHandlers[event.type];
        if (handler === undefined) {
            log.debug(`Unknown matrix event type: ${event.type}`);
        } else {
            await handler.bind(this)(event);
        }
    }
}
