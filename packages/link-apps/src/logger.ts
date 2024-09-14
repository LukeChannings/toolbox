export const enum LogLevel {
  Trace = 0,
  Info = 10,
  Error = 20,
}

let logLevel: LogLevel = LogLevel.Error;

export function setLogLevel(level: LogLevel) {
  logLevel = level;
}

export function trace(...message: unknown[]) {
  if (logLevel <= LogLevel.Trace) {
    console.log(...message);
  }
}

export function info(...message: unknown[]) {
  if (logLevel <= LogLevel.Info) {
    console.info(...message);
  }
}

export function error(...message: unknown[]) {
  if (logLevel <= LogLevel.Error) {
    console.error(...message);
  }
}
