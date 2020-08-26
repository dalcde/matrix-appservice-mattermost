import { config } from './Config';
import Main from './Main';
import { Request, Response, Application } from 'express';
import * as express from 'express';
import { Server, createServer } from 'http';
import { User } from './entities/User';
import log from './Logging';

export default class AdminEndpoint {
    private app: Application;
    private server: Server;

    constructor(readonly main: Main) {
        this.app = express();
        this.app.get('/status', (_, res: Response): void => {
            log.info('Status requested');
            if (this.main.initialized) {
                res.send('running');
            } else {
                res.send('initializing');
            }
        });
        this.app.post('/rename/:oldName/:newName', this.rename.bind(this));

        this.server = createServer(this.app).listen(config().admin_port);
    }

    async kill(): Promise<void> {
        await new Promise(r => this.server.close(r));
    }

    async rename(req: Request, res: Response): Promise<void> {
        const params = req.params;
        const oldName = params.oldName;
        const newName = params.newName;

        if (
            oldName.length < 3 ||
            oldName.length > 22 ||
            !oldName.match(/^[a-z][a-z0-9_\-\.]*$/)
        ) {
            res.status(400).send(
                `Invalid mattermost username: ${oldName}\nUsername must begin with a letter, and contain between 3 to 22 lowercase characters made up of numbers, letters, and the symbols '.', '-', and '_'.\n`,
            );
            return;
        }

        const user = await User.findOne({
            mattermost_username: oldName,
        });
        if (user === undefined) {
            res.status(400).send(
                `No Mattermost user with username ${oldName}\n`,
            );
            return;
        } else if (!user.is_matrix_user) {
            res.status(400).send(
                `User ${oldName} is not a puppet. Cannot be renamed\n`,
            );
            return;
        }

        try {
            await user.client.put(`/users/${user.mattermost_userid}/patch\n`, {
                username: newName,
            });
        } catch (e) {
            res.status(500).send(`Failed to change username\n${e}\n`);
            return;
        }
        user.mattermost_username = newName;
        await user.save();
        res.send(`Renamed ${oldName} to ${newName}\n`);
    }
}
