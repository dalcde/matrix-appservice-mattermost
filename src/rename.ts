// This is a command-line utility for changing the mattermost username of
// puppet users.

import { User } from './entities/User';
import * as fs from 'fs';
import { setConfig, Config } from './Config';
import { sanitizeMattermostUsername } from './utils/Functions';
import { createConnection } from 'typeorm';
import * as yaml from 'js-yaml';
import log from './Logging';

async function run(argv: string[]) {
    if (argv.length !== 3) {
        log.error('Invalid arguments');
        log.error(
            'Usage: node build/rename.js [config file] [old username] [new username]',
        );
        process.exit(1);
    }
    const [configPath, oldName, newName] = argv;

    if (
        oldName.length < 3 ||
        oldName.length > 22 ||
        !oldName.match(/^[a-z][a-z0-9_\-\.]*$/)
    ) {
        log.error(`Invalid mattermost username: ${oldName}`);
        log.error(
            "Username must begin with a letter, and contain between 3 to 22 lowercase characters made up of numbers, letters, and the symbols '.', '-', and '_'.",
        );
        process.exit(1);
    }

    log.info('Parsing config file');
    const config = (yaml.safeLoad(
        fs.readFileSync(configPath, 'utf8'),
    ) as any) as Config;

    log.setLevel(config.logging);
    setConfig(config);

    const db: any = config.database;
    db['entities'] = [User];
    db['synchronize'] = false;
    db['logging'] = false;

    log.info('Connecting to database');
    await createConnection(db);

    log.info('Finding user in database');
    const user = await User.findOne({
        mattermost_username: oldName,
    });
    if (user === undefined) {
        log.error(`No Mattermost user with username ${oldName}`);
        process.exit(1);
    } else if (!user.is_matrix_user) {
        log.error(`User ${oldName} is not a puppet. Cannot be renamed`);
        process.exit(1);
    }

    log.info('Updating mattermost user');
    try {
        await user.client.put(`/users/${user.mattermost_userid}/patch`, {
            username: newName,
        });
    } catch (e) {
        log.error(`Failed to change username: ${e}`);
        process.exit(1);
    }
    log.info('Updating database');
    user.mattermost_username = newName;
    await user.save();
    process.exit(0);
}

run(process.argv.slice(2));
