import Main from '../Main';
import * as sdk from 'matrix-js-sdk';
import { MatrixClient, Registration } from '../Interfaces';
import { config } from '../Config';

export async function getMatrixUsers(
    main: Main,
    roomid: string,
): Promise<{
    real: Set<string>;
    remote: Set<string>;
}> {
    const realMatrixUsers: Set<string> = new Set();
    const remoteMatrixUsers: Set<string> = new Set();

    const allMatrixUsers = Object.keys(
        (await main.botClient.getJoinedRoomMembers(roomid)).joined,
    );
    for (const matrixUser of allMatrixUsers) {
        if (main.isRemoteUser(matrixUser)) {
            remoteMatrixUsers.add(matrixUser);
        } else {
            realMatrixUsers.add(matrixUser);
        }
    }
    return {
        real: realMatrixUsers,
        remote: remoteMatrixUsers,
    };
}

export function getMatrixClient(
    registration: Registration,
    userId: string,
): MatrixClient {
    return sdk.createClient({
        accessToken: registration.as_token,
        baseUrl: config().homeserver.url,
        userId,
        queryParams: {
            user_id: userId,
            access_token: registration.as_token,
        },
        scheduler: new (sdk as any).MatrixScheduler(),
        localTimeoutMs: 1000 * 60 * 2,
    });
}
