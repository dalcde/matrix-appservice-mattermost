import fetch from 'node-fetch';
import * as WebSocket from 'ws';
import { EventEmitter } from 'events';
import log from '../Logging';
import * as FormData from 'form-data';

export type Method = 'GET' | 'POST' | 'PUT' | 'DELETE';

export class Client {
    password?: string;
    username?: string;
    token?: string;

    constructor(public domain: string, public userid: string) {}

    public async send_raw(
        method: Method,
        endpoint: string,
        data?: object | FormData,
        auth: boolean = true,
    ): Promise<any> {
        if (auth && this.token === undefined) {
            throw 'Cannot send request without access token';
        }
        const options = {
            method: method,
            headers: {},
        };

        if (auth) {
            options['headers']['Authorization'] = `Bearer ${this.token}`;
        }
        if (data) {
            if (data instanceof FormData) {
                options['body'] = data;
            } else {
                options['headers']['Content-Type'] = 'application/json';
                options['body'] = JSON.stringify(data);
            }
        }
        return await fetch(`${this.domain}/api/v4${endpoint}`, options);
    }

    public async send(
        method: Method,
        endpoint: string,
        data?: object,
        auth: boolean = true,
    ): Promise<any> {
        let response = await this.send_raw(method, endpoint, data, auth);
        // If we used password login and we got a 401, the session token might
        // have expired. Log in again and try the request.
        if (
            response.status === 401 &&
            this.username !== undefined &&
            this.password !== undefined
        ) {
            this.login(this.username, this.password);
            response = await this.send_raw(method, endpoint, data, auth);
        }
        if (response.ok) {
            return await response.json();
        } else {
            const error = new ClientError(
                method,
                endpoint,
                data,
                await response.json(),
            );
            throw error;
        }
    }

    public async get(
        endpoint: string,
        data?: object,
        auth: boolean = true,
    ): Promise<any> {
        return await this.send('GET', endpoint, data, auth);
    }
    public async post(
        endpoint: string,
        data?: object,
        auth: boolean = true,
    ): Promise<any> {
        return await this.send('POST', endpoint, data, auth);
    }
    public async put(
        endpoint: string,
        data?: object,
        auth: boolean = true,
    ): Promise<any> {
        return await this.send('PUT', endpoint, data, auth);
    }
    public async delete(
        endpoint: string,
        data?: object,
        auth: boolean = true,
    ): Promise<any> {
        return await this.send('DELETE', endpoint, data, auth);
    }

    public async login(username: string, password: string) {
        const r = await this.send_raw(
            'POST',
            '/users/login',
            {
                login_id: username,
                password: password,
            },
            false,
        );
        this.username = username;
        this.password = password;
        this.token = r.headers.get('Token') || undefined;
    }

    public loginWithToken(token: string) {
        this.token = token;
    }

    public websocket(): ClientWebsocket {
        return new ClientWebsocket(this);
    }
}

interface PromiseCallbacks {
    resolve;
    reject;
}

export class ClientWebsocket extends EventEmitter {
    ws: WebSocket;
    seq: number;
    promises: PromiseCallbacks[];

    constructor(private client: Client) {
        super();
        if (this.client.token === null) {
            throw 'Cannot open websocket without access token';
        }
        this.ws = new WebSocket(
            `ws${this.client.domain.slice(4)}/api/v4/websocket`,
        );
        this.seq = 0;
        this.promises = [];

        this.ws.on('open', () => {
            this.send('authentication_challenge', {
                token: this.client.token,
            });
        });
        this.ws.on('message', m => {
            const ev = JSON.parse(m);
            if (ev.seq_reply !== undefined) {
                const promise = this.promises[ev.seq_reply];
                if (promise === null) {
                    log.warn(
                        `websocket: Received reply with unknown sequence number: ${m}`,
                    );
                }
                if (ev['status'] === 'OK') {
                    promise.resolve(ev.data);
                } else {
                    promise.reject(ev.error);
                }
                delete this.promises[ev.seq_reply];
            } else {
                this.emit('message', ev);
            }
        });
        this.ws.on('close', () => this.emit('close'));
        this.ws.on('error', e => this.emit('error', e));
    }

    async close() {
        this.ws.close();
        await new Promise(resolve => this.ws.once('close', resolve));
    }
    async send(action: string, data: object): Promise<any> {
        this.seq += 1;
        this.ws.send(
            JSON.stringify({
                action: action,
                seq: this.seq,
                data: data,
            }),
        );
        return await new Promise(
            (resolve, reject) =>
                (this.promises[this.seq] = {
                    resolve: resolve,
                    reject: reject,
                }),
        );
    }
}

export class ClientError extends Error {
    constructor(
        readonly method: Method,
        readonly endpoint: string,
        readonly data: object | undefined,
        readonly m: ErrorObject,
    ) {
        super();
    }

    public toString = (): string => {
        let string = `${this.m.status_code} ${this.method} ${
            this.endpoint
        }: ${JSON.stringify(this.m)}`;
        if (this.data !== undefined) {
            string += `\nData: ${JSON.stringify(this.data)}`;
        }
        return string;
    };
}

export interface ErrorObject {
    id: string;
    message: string;
    status_code: number;
    request_id: string;
    is_oauth: boolean;
}
