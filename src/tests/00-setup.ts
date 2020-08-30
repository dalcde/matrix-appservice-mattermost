import * as http from 'http';
import * as path from 'path';
import * as test from 'tape';
import { spawnSync, spawn as spawnAsync } from 'child_process';
import { MATTERMOST_PORT, SYNAPSE_PORT } from './utils/Data';

const DOCKER_PATH = path.join(__dirname, '../../docker/docker-compose.yaml');

function query(port: number, resolve: () => void): void {
    http.get(`http://localhost:${port}/`, () => {
        resolve();
    }).on('error', () => {
        setTimeout(() => query(port, resolve), 500);
    });
}

async function healthCheck(port: number): Promise<void> {
    await new Promise(resolve => query(port, resolve));
}

function spawn(args: string[]): void {
    const ret = spawnSync(args[0], args.slice(1), { stdio: 'inherit' });
    if (ret.status !== 0) {
        throw new Error(`Error when running ${args.join(' ')}`);
    }
}

function cleanup() {
    if (process.env.INTEGRATION_MANUAL_DOCKER !== 'true') {
        spawn(['docker-compose', '-f', DOCKER_PATH, 'kill']);
        spawn(['docker-compose', '-f', DOCKER_PATH, 'down', '-v']);
    }
}

test.onFinish(cleanup);
process.on('SIGTERM', () => {
    cleanup();
    process.exit(0);
});
process.on('SIGINT', () => {
    cleanup();
    process.exit(0);
});

test('Start docker', async t => {
    if (process.env.INTEGRATION_MANUAL_DOCKER !== 'true') {
        spawn(['docker-compose', '-f', DOCKER_PATH, 'kill']);
        spawn(['docker-compose', '-f', DOCKER_PATH, 'down', '-v']);
        spawn(['docker-compose', '-f', DOCKER_PATH, 'build']);
        spawnAsync('docker-compose', ['-f', DOCKER_PATH, 'up'], {
            stdio: 'inherit',
        });
    }

    t.timeoutAfter(20000);
    await Promise.all([
        healthCheck(MATTERMOST_PORT),
        healthCheck(SYNAPSE_PORT),
    ]);
    t.end();
});
