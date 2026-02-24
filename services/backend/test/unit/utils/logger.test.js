const logger = require('../../../src/utils/logger');

describe('Logger Utility', () => {
    let logSpy, errorSpy, warnSpy;

    beforeEach(() => {
        logSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
        errorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
    });

    afterEach(() => {
        logSpy.mockRestore();
        errorSpy.mockRestore();
        warnSpy.mockRestore();
    });

    test('logger.info should call console.log with formatted message', () => {
        logger.info('test info');
        expect(logSpy).toHaveBeenCalledWith(expect.stringContaining('INFO: test info'));
    });

    test('logger.error should call console.error with formatted message', () => {
        logger.error('test error');
        expect(errorSpy).toHaveBeenCalledWith(expect.stringContaining('ERROR: test error'));
    });

    test('logger.warn should call console.warn with formatted message', () => {
        logger.warn('test warn');
        expect(warnSpy).toHaveBeenCalledWith(expect.stringContaining('WARN: test warn'));
    });

    test('logger.debug should call console.log when NODE_ENV is not production', () => {
        const originalEnv = process.env.NODE_ENV;
        process.env.NODE_ENV = 'development';
        logger.debug('test debug');
        expect(logSpy).toHaveBeenCalledWith(expect.stringContaining('DEBUG: test debug'));
        process.env.NODE_ENV = originalEnv;
    });

    test('logger.debug should NOT call console.log when NODE_ENV is production', () => {
        const originalEnv = process.env.NODE_ENV;
        process.env.NODE_ENV = 'production';
        logger.debug('test debug');
        expect(logSpy).not.toHaveBeenCalled();
        process.env.NODE_ENV = originalEnv;
    });
});
