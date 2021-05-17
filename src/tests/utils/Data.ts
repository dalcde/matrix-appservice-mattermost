export type MattermostUsername =
    | 'admin'
    | 'mattermost_a'
    | 'mattermost_b'
    | 'ignored_user';
export type MatrixUsername = 'admin' | 'matrix_a' | 'matrix_b' | 'ignored_user';

export const MATRIX_TOKENS: Record<MatrixUsername, string> = {
    admin: 'MDAxN2xvY2F0aW9uIGxvY2FsaG9zdAowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMjNjaWQgdXNlcl9pZCA9IEBhZG1pbjpsb2NhbGhvc3QKMDAxNmNpZCB0eXBlID0gYWNjZXNzCjAwMjFjaWQgbm9uY2UgPSBXVU9yUTVRMFRnUkNjME1ACjAwMmZzaWduYXR1cmUgdYKA-yuTQ5JV5O0HWRak-48xavOYgA1MMc6A1V_Uw5kK',
    matrix_a:
        'MDAxN2xvY2F0aW9uIGxvY2FsaG9zdAowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMjZjaWQgdXNlcl9pZCA9IEBtYXRyaXhfYTpsb2NhbGhvc3QKMDAxNmNpZCB0eXBlID0gYWNjZXNzCjAwMjFjaWQgbm9uY2UgPSAwb3Y6eTZVdHojUk4jbFprCjAwMmZzaWduYXR1cmUgNNZKnOVRzj5svh9pEM0UUEqtXYnHjnj9XyNLJ1_uKoAK',
    matrix_b:
        'MDAxN2xvY2F0aW9uIGxvY2FsaG9zdAowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMjZjaWQgdXNlcl9pZCA9IEBtYXRyaXhfYjpsb2NhbGhvc3QKMDAxNmNpZCB0eXBlID0gYWNjZXNzCjAwMjFjaWQgbm9uY2UgPSBBYl9hbWthI0daSzgtfjdICjAwMmZzaWduYXR1cmUgOReBLkPURCMNtzORS9fpogQqVa3IWN9ZEu5gXW91QTMK',
    ignored_user:
        'MDAxN2xvY2F0aW9uIGxvY2FsaG9zdAowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMmFjaWQgdXNlcl9pZCA9IEBpZ25vcmVkX3VzZXI6bG9jYWxob3N0CjAwMTZjaWQgdHlwZSA9IGFjY2VzcwowMDIxY2lkIG5vbmNlID0gZU5ta1BBMj1FNnVPRGtwdgowMDJmc2lnbmF0dXJlIHSt8jrFU836Ne3it2HY88EhPD1Aoustsm211bbFjcLcCg',
};

export const MATTERMOST_TOKENS: Record<
    MattermostUsername,
    { userid: string; token: string }
> = {
    admin: {
        userid: 'bmq7jiumpib3xdz3mx5iyo99ro',
        token: 's537n3t8zib1tx7eyd44qzqnbr',
    },
    mattermost_a: {
        userid: '5bw66y36bff3umq1q57mfy4y5c',
        token: 'aqhn1jc1nbgjtpd7es83wckner',
    },
    mattermost_b: {
        userid: '3zats68fztgu9mgu944a4t35so',
        token: 'ox8n8edimjdbfkeybdf56pj4xw',
    },
    ignored_user: {
        userid: '0z4okgmv5lfhx3p0tf6pnpk8sk',
        token: '0z4okgmv5lfhx3p0tf6pnpk8sk',
    },
};

export type Channels = 'town-square' | 'off-topic';

export const CHANNELS: Channels[] = ['town-square', 'off-topic'];

export const MATRIX_ROOM_IDS: Record<Channels, string> = {
    'town-square': '!kmbTYjjsDRDHGgVqUP:localhost',
    'off-topic': '!dKcbdDATuwwphjRPQP:localhost',
};
export const MATTERMOST_CHANNEL_IDS: Record<Channels, string> = {
    'town-square': 'cxtmz3ubz3gfigd5m6prendmsw',
    'off-topic': '73uy6kj1jb8wdqrf3ti6zies6r',
};

export const MATTERMOST_TEAM_ID: string = 'tgrw7sjgbiy1jggs3qg3m6zpee';
export const MATTERMOST_PORT = 8065;
export const SYNAPSE_PORT = 8008;
