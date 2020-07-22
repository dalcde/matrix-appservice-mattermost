export interface MatrixMessage {
    body: string;
    msgtype: string;
    format?: string;
    formatted_body?: string;

    [propName: string]: any;
}

export interface MatrixRoomEvent {
    content: any;
    type: string;
    event_id: string;
    sender: string;
    origin_server_ts: number;
    room_id: string;
    unsigned: any;

    [propName: string]: any;
}

export interface MattermostUserInfo {
    username: string;
    first_name: string;
    last_name: string;

    [propName: string]: any;
}
