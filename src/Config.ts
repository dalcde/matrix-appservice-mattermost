import * as Ajv from 'ajv';
import { readFileSync } from 'fs';
import { join } from 'path';

let _config: Config | undefined = undefined;

const schema = JSON.parse(
    readFileSync(join(__dirname, 'config-schema.json'), { encoding: 'utf8' }),
);
const ajv = new Ajv({
    useDefaults: true,
    allErrors: true,
});
export const validator = ajv.compile(schema);

export function config(): Config {
    if (_config === undefined) {
        throw new Error('Config not yet set');
    }
    return _config;
}

export function setConfig(c: unknown, shouldValidate: boolean = true): void {
    if (shouldValidate) {
        validate(c);
    }
    _config = c as Config;
}

export function validate(c: unknown): Config {
    const valid = validator(c);
    if (valid) {
        return c as Config;
    } else {
        throw new Error(
            validator.errors
                ?.map(
                    e =>
                        `${e.dataPath}: ${e.message} (${JSON.stringify(
                            e.params,
                        )})`,
                )
                ?.join('\n'),
        );
    }
}

export interface Config {
    /**
     * @format uri
     */
    mattermost_url: string;
    /**
     * @default false
     */
    forbid_bridge_failure: boolean;
    mappings: Mapping[];
    appservice: {
        /**
         * @minimum 0
         * @maximum 65535
         */
        port: number;
        hostname: string;
        bind?: string;
        schema: 'https' | 'http';
    };
    /**
     * @minimum 0
     * @maximum 65535
     */
    admin_port?: number;
    /**
     * @default 'mm_'
     */
    matrix_localpart_prefix: string;
    /**
     * @default '[DISPLAY]'
     */
    matrix_display_name_template: string;
    /**
     * @default '[DISPLAY]'
     */
    mattermost_username_template: string;
    matrix_bot: {
        username: string;
        display_name?: string;
    };
    mattermost_bot_userid: string;
    mattermost_bot_access_token: string;
    homeserver: {
        /**
         * @pattern https?://
         */
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
    /**
     * @default []
     */
    ignored_mattermost_users: string[];
    /**
     * @default []
     */
    ignored_matrix_users: string[];
    mattermost_email_template: string;
}

export interface Mapping {
    /**
     * @pattern ^[a-z0-9]{26}$
     */
    mattermost: string;
    /**
     * @pattern ^!.*:.*$
     */
    matrix: string;
}
export const RELOADABLE_CONFIG: Set<string> = new Set([
    'logging',
    'mattermost_email_template',
    'mattermost_username_template',
]);
