type LogLevel = 'debug' | 'info' | 'warn' | 'error';

interface LogMeta {
  requestId?: string;
  [key: string]: unknown;
}

function write(level: LogLevel, message: string, meta: LogMeta = {}): void {
  const event = {
    ts: new Date().toISOString(),
    level,
    message,
    ...meta,
  };

  if (level === 'error') {
    console.error(JSON.stringify(event));
  } else if (level === 'warn') {
    console.warn(JSON.stringify(event));
  } else {
    console.log(JSON.stringify(event));
  }
}

export function logDebug(message: string, meta: LogMeta = {}): void {
  write('debug', message, meta);
}

export function logInfo(message: string, meta: LogMeta = {}): void {
  write('info', message, meta);
}

export function logWarn(message: string, meta: LogMeta = {}): void {
  write('warn', message, meta);
}

export function logError(message: string, meta: LogMeta = {}): void {
  write('error', message, meta);
}
