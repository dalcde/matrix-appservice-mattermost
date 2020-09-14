import Main from '../Main';
import { AppServiceRegistration } from 'matrix-appservice';
import * as sdk from 'matrix-js-sdk';
import { MatrixClient } from '../Interfaces';
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
    registration: AppServiceRegistration,
    userId: string,
): MatrixClient {
    return sdk.createClient({
        accessToken: registration.getAppServiceToken() || '',
        baseUrl: config().homeserver.url,
        userId,
        queryParams: {
            user_id: userId,
            access_token: registration.getAppServiceToken(),
        },
        scheduler: new (sdk as any).MatrixScheduler(),
        localTimeoutMs: 1000 * 60 * 2,
    });
}
