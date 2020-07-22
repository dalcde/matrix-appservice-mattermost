enum LogLevel {
    DEBUG,
    INFO,
    WARNING,
    ERROR,
}

let logLevel = LogLevel.DEBUG;

export type LogLevelStrings = keyof typeof LogLevel;

export function setLogLevel(level: LogLevelStrings) {
    logLevel = LogLevel[level];
}

function log_(level: LogLevel, message: string) {
    if (level == LogLevel.ERROR) {
        console.error(message);
    } else if (level >= logLevel) {
        console.log(message);
    }
}

export function debug(message: string) {
    log_(LogLevel.DEBUG, message);
}
export function info(message: string) {
    log_(LogLevel.INFO, message);
}
export function warning(message: string) {
    log_(LogLevel.WARNING, message);
}
export function error(message: string) {
    log_(LogLevel.ERROR, message);
}
export function log(level: LogLevelStrings, message: string) {
    log_(LogLevel[level], message);
}
