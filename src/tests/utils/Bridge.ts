import * as tapeTest from 'tape';
import { join } from 'path';
import { readFileSync } from 'fs';
import { safeLoad } from 'js-yaml';
import { spawn } from 'child_process';
import { AppServiceRegistration } from 'matrix-appservice-bridge';

import { setConfig } from '../../Config';
import Main from '../../Main';
import log from '../../Logging';
import connection from './Connection';

const REGISTRATION_PATH = join(
    __dirname,
    '../../../docker/synapse/registration.yaml',
);
const CONFIG_PATH = join(__dirname, '../../../config.sample.yaml');

let main_: Main | undefined = undefined;
export function main(): Main {
    if (main_ === undefined) {
        throw new Error('Accessing main when bridge not started');
    }
    return main_;
}

function loadYaml(path: string): any {
    return safeLoad(readFileSync(path, 'utf8'));
}

export async function startBridge(
    extra: Record<string, unknown> = {},
): Promise<void> {
    await connection;
    const registration = AppServiceRegistration.fromObject(
        loadYaml(REGISTRATION_PATH),
    );
    const config = Object.assign(loadYaml(CONFIG_PATH), extra);

    setConfig(config);

    // Run reverse port forwarding to expose appservice to the docker network.
    const tunnel = spawn('ssh', [
        '-N',
        '-R',
        '9995:localhost:9995',
        '-o',
        'UserKnownHostsFile=/dev/null',
        '-o',
        'StrictHostKeyChecking=no',
        '-p',
        '8022',
        'proxy@localhost',
    ]);

    const m = new Main(registration, false);
    tunnel.on('close', () => {
        // Don't use main() because it might refer to a new Main after this
        // one.
        if (!m.killed) {
            log.error('ssh tunnel for appservice unexpectedly closed');
        }
    });
    m.on('kill', () => {
        main_ = undefined;
        tunnel.kill();
    });
    main_ = m;

    await m.init();
}

export function test(message: string, cb: (t) => void | Promise<void>): void {
    tapeTest(message, t => {
        log.error = msg => {
            log.error = console.error;
            main_?.killBridge(1);
            t.fail(msg);
            t.end();
        };
        return cb(t);
    });
}
