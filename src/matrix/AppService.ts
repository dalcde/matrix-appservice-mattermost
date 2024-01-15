import { Application, Request, Response } from 'express';
import * as express from 'express';
import { promisify } from 'util';
import { EventEmitter } from 'events';
import { Server, createServer } from 'http';
import { User } from '../entities/User';
import Main from '../Main';

export default class AppService extends EventEmitter {
    private app: Application;
    private server?: Server;
    private lastProcessedTxnId = '';

    constructor(private main: Main) {
        super();
        this.app = express();

        // This doesn't require a token, so is set before we add the
        // middleware
        this.app.get('/bridge/status', this.onStatus.bind(this));

        this.app.use(this.checkValidToken.bind(this));
        this.app.use(express.json());

        this.app.get(
            '/_matrix/app/v1/users/:userId',
            this.onGetUsers.bind(this),
        );
        this.app.get(
            '/_matrix/app/v1/rooms/:alias',
            this.onGetRoomAlias.bind(this),
        );
        this.app.put(
            '/_matrix/app/v1/transactions/:txnId',
            this.onTransaction.bind(this),
        );
        this.app.get('/users/:userId', this.onGetUsers.bind(this));
        this.app.get('/rooms/:alias', this.onGetRoomAlias.bind(this));
        this.app.put('/transactions/:txnId', this.onTransaction.bind(this));

        this.app.post(
            '/bridge/rename/:oldName/:newName',
            this.onRename.bind(this),
        );
    }

    public listen(port: number, hostname: string): Promise<void> {
        const serverApp: Server = createServer(this.app);
        return new Promise((resolve, reject) => {
            serverApp.on('error', err => {
                reject(err);
            });
            serverApp.on('listening', () => {
                resolve();
            });
            this.server = serverApp.listen(port, hostname);
        });
    }

    public async close(): Promise<void> {
        if (!this.server) {
            throw Error('Server has not started');
        }
        await promisify(this.server.close).apply(this.server);
    }

    private checkValidToken(
        req: Request,
        res: Response,
        next: () => void,
    ): void {
        const providedToken = req.header('Authorization');
        if (!providedToken) {
            res.status(401).send({
                errcode: 'M_UNKNOWN_TOKEN',
                error: 'No token supplied',
            });
        } else if (providedToken !== `Bearer ${this.main.registration.hs_token}`) {
            res.status(403).send({
                errcode: 'M_UNKNOWN_TOKEN',
                error: 'Bad token supplied',
            });
        } else {
            next();
        }
    }

    private async onGetUsers(req: Request, res: Response): Promise<void> {
        const userid = req.params.userId;
        const count = await User.count({
            matrix_userid: userid,
            is_matrix_user: false,
        });

        if (count > 0) {
            res.send({});
        } else {
            res.status(404).send({});
        }
    }

    private onGetRoomAlias(req: Request, res: Response): void {
        res.status(404).send({});
    }

    private onTransaction(req: Request, res: Response): void {
        const txnId = req.params.txnId;
        if (!txnId) {
            res.status(404).send({
                errcode: 'M_NOT_FOUND',
                error: 'Missing transaction ID',
            });
            return;
        }
        if (!req.body) {
            res.status(400).send({
                errcode: 'M_NOT_JSON',
                error: 'Missing body',
            });
            return;
        } else if (!req.body.events) {
            res.status(400).send({
                errcode: 'M_BAD_JSON',
                error: 'Missing events body',
            });
            return;
        }
        const events = req.body.events;

        if (this.lastProcessedTxnId === txnId) {
            // duplicate
            res.send({});
            return;
        }
        for (const event of events) {
            this.emit('event', event);
        }
        this.lastProcessedTxnId = txnId;
        res.send({});
    }

    private onStatus(req: Request, res: Response): void {
        if (this.main.initialized) {
            res.send('running');
        } else {
            res.send('initializing');
        }
    }

    private async onRename(req: Request, res: Response): Promise<void> {
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
