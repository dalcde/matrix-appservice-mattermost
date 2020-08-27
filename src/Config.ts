let _config: Config = (undefined as unknown) as Config;

export function config(): Config {
    return _config;
}

export function setConfig(c: Config): void {
    _config = c;
}

export interface Config {
    mattermost_url: string;
    forbid_bridge_failure: boolean;
    mappings: Mapping[];
    appservice: {
        port: number;
        hostname: string;
        schema: string;
    };
    admin_port?: number;
    matrix_localpart_prefix: string;
    matrix_display_name_template: string;
    mattermost_username_template: string;
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
    logging: 'trace' | 'debug' | 'info' | 'warn' | 'error' | 'silent';
    ignored_mattermost_users: string[];
    ignored_matrix_users: string[];
    mattermost_email_template: string;
}

export interface Mapping {
    mattermost: string;
    matrix: string;
}
export const RELOADABLE_CONFIG: Set<string> = new Set([
    'logging',
    'mattermost_email_template',
    'mattermost_username_template',
]);
