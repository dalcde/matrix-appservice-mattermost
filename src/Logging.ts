import * as loglevel from 'loglevel';

// This is the same logger as the one used by matrix-js-sdk
const log = loglevel.getLogger('matrix');

for (const f of ['time', 'timeEnd']) {
    log[f] = {};
    for (const level of ['trace', 'debug', 'info', 'warn', 'error']) {
        log[f][level] = (label: string) => {
            if (log.getLevel() <= log.levels[level.toUpperCase()]) {
                console[f](label);
            }
        };
    }
}

interface LoggerTime {
    time: { [key: string]: (string) => void };
    timeEnd: { [key: string]: (string) => void };
}
export default log as loglevel.Logger & LoggerTime;
