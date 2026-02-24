/**
 * Centralized Logger Utility
 * Provides a consistent logging interface across the application.
 * Currently wraps console methods, but can be easily swapped for a
 * dedicated logging library like Winston or Pino in the future.
 */

const formatMessage = (level, message) => {
    const timestamp = new Date().toISOString();
    return `[${timestamp}] ${level.toUpperCase()}: ${message}`;
};

const logger = {
    info: (message, ...args) => {
        console.log(formatMessage('info', message), ...args);
    },
    error: (message, ...args) => {
        console.error(formatMessage('error', message), ...args);
    },
    warn: (message, ...args) => {
        console.warn(formatMessage('warn', message), ...args);
    },
    debug: (message, ...args) => {
        if (process.env.NODE_ENV !== 'production') {
            console.log(formatMessage('debug', message), ...args);
        }
    }
};

module.exports = logger;
