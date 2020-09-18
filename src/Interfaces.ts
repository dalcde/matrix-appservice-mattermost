export interface MattermostMessage {
    event: string;
    data: any;
    broadcast: {
        omit_user: string[] | null;
        user_id: string;
        channel_id: string;
        team_id: string;
    };
    seq: number;
}

export interface MattermostPost {
    id: string;
    create_at: number;
    update_at: number;
    edit_at: number;
    delete_at: number;
    is_pinned: boolean;
    user_id: string;
    channel_id: string;
    root_id: string;
    parent_id: string;
    original_id: string;
    message: string;
    type: string;
    props: any;
    hashtags: string;
    pending_post_id: string;
    reply_count: number;
    metadata: {
        files?: MattermostFileInfo[];
        [propName: string]: unknown;
    };
}

export interface MattermostFileInfo {
    id: string;
    user_id: string;
    post_id: string;
    create_at: number;
    update_at: number;
    delete_at: number;
    name: string;
    extension: string;
    size: number;
    mime_type: string;

    [propName: string]: unknown;
}
export interface MatrixMessage {
    body: string;
    msgtype: string;
    format?: string;
    formatted_body?: string;

    [propName: string]: unknown;
}

export interface MatrixEvent {
    content: any;
    type: string;
    event_id: string;
    sender: string;
    origin_server_ts: number;
    room_id: string;
    unsigned?: UnsignedData;
    state_key?: string;
    prev_content?: any;

    [propName: string]: unknown;
}

export interface UnsignedData {
    age?: number;
    redacted_because?: MatrixEvent;
    transaction_id?: string;
}

export interface MattermostUserInfo {
    username: string;
    first_name: string;
    last_name: string;

    [propName: string]: unknown;
}

export interface MatrixClient {
    sendMessage: (room: string, message: MatrixMessage) => Promise<MatrixEvent>;
    fetchRoomEvent: (room: string, eventid: string) => Promise<MatrixEvent>;
    [propName: string]: any;
}

export interface Registration {
    id: string;
    hs_token: string;
    as_token: string;
    namespaces: {
        users: {
            exclusive: boolean;
            regex: string;
        }[];
    };
    url: string;
    sender_localpart: string;
    rate_limited: boolean;
    protocols: string[];
}
