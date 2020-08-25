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

export interface MatrixMessage {
    body: string;
    msgtype: string;
    format?: string;
    formatted_body?: string;

    [propName: string]: any;
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

    [propName: string]: any;
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

    [propName: string]: any;
}
