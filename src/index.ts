console.time('Bridge loaded');
import { Bridge, Cli, AppServiceRegistration } from 'matrix-appservice-bridge';
import { Client } from './mattermost/Client';
import log from './Logging';
import { setConfig, Config } from './Config';
import { createConnection } from 'typeorm';
import * as path from 'path';
import Main from './Main';
import { User } from './entities/User';
import { Post } from './entities/Post';

const cli = new Cli({
    registrationPath: 'registration.yaml',
    generateRegistration(reg, callback) {
        const config: Config = cli.getConfig();

        reg.setId(AppServiceRegistration.generateToken());
        reg.setHomeserverToken(AppServiceRegistration.generateToken());
        reg.setAppServiceToken(AppServiceRegistration.generateToken());
        reg.setSenderLocalpart(`${config.matrix_bot.username}`);
        reg.setAppServiceUrl(
            `${config.appservice.schema}://${config.appservice.hostname}:${config.appservice.port}`,
        );
        reg.addRegexPattern(
            'users',
            `@${config.matrix_localpart_prefix}.*`,
            true,
        );

        callback(reg);
    },
    bridgeConfig: {
        schema: path.join(__dirname, '../config/mattermost-config-schema.yaml'),
        affectsRegistration: true,
        defaults: {
            matrix_localpart_suffix: 'mm_',
            matrix_display_name_template: '[DISPLAY]',
            mattermost_username_template: '[DISPLAY]',
        },
    },
    async run(port: number, config: Config, registration: any) {
        log.setLevel(config.logging);

        setConfig(config);

        const db: any = config.database;
        db['entities'] = [User, Post];
        db['synchronize'] = true;
        db['logging'] = false;

        await createConnection(db);

        const main = new Main(registration);
        log.timeEnd.info('Bridge loaded');
        main.init();

        process.on('SIGTERM', () => {
            log.info('Received SIGTERM. Shutting down bridge.');
            main.killBridge(143);
        });
        process.on('SIGINT', () => {
            log.info('Received SIGINT. Shutting down bridge.');
            main.killBridge(130);
        });
    },
});
cli.run();
