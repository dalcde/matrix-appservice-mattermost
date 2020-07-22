import { LogLevelStrings } from './Logging';

let _config: Config = (undefined as any) as Config;

export function config(): Config {
    return _config;
}

export function setConfig(c: Config) {
    _config = c;
}

export interface Config {
    mattermost_url: string;
    mappings: {
        mattermost: string;
        matrix: string;
    }[];
    appservice: {
        port: number;
        hostname: string;
        schema: string;
    };
    matrix_localpart_prefix: string;
    matrix_bot: {
        username: string;
        display_name?: string;
    };
    mattermost_bot_userid: string;
    mattermost_bot_access_token: string;
    homeserver: {
        url: string;
        server_name: string;
    };
    database: {
        type: string;
        host: string;
        port?: number;
        username: string;
        password?: string;
        database: string;
    };
    logging: LogLevelStrings;
    ignored_mattermost_users: string[];
    ignored_matrix_users: string[];
    mattermost_email_template: string;
}
