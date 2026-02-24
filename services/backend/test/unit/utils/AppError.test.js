const AppError = require('../../../src/utils/AppError');

describe('AppError Utility', () => {
  it('should be an instance of Error', () => {
    const error = new AppError('Something went wrong', 500);
    expect(error).toBeInstanceOf(Error);
  });

  it('should set the message property', () => {
    const message = 'Something went wrong';
    const error = new AppError(message, 500);
    expect(error.message).toBe(message);
  });

  it('should set the statusCode property', () => {
    const statusCode = 404;
    const error = new AppError('Not Found', statusCode);
    expect(error.statusCode).toBe(statusCode);
  });

  it('should set status to "fail" for 4xx status codes', () => {
    const error400 = new AppError('Bad Request', 400);
    expect(error400.status).toBe('fail');

    const error404 = new AppError('Not Found', 404);
    expect(error404.status).toBe('fail');

    const error499 = new AppError('Client Closed Request', 499);
    expect(error499.status).toBe('fail');
  });

  it('should set status to "error" for 5xx status codes', () => {
    const error500 = new AppError('Internal Server Error', 500);
    expect(error500.status).toBe('error');

    const error503 = new AppError('Service Unavailable', 503);
    expect(error503.status).toBe('error');
  });

  it('should set isOperational to true', () => {
    const error = new AppError('Operational Error', 500);
    expect(error.isOperational).toBe(true);
  });

  it('should capture the stack trace', () => {
    const error = new AppError('Stack Trace Error', 500);
    expect(error.stack).toBeDefined();
    // The stack trace typically starts with "ErrorType: Message"
    // Note: AppError does not currently set this.name, so it defaults to 'Error'
    expect(error.stack).toContain('Error: Stack Trace Error');
  });

  it('should handle non-string status codes correctly', () => {
    // The implementation uses `${statusCode}`.startsWith('4'), so numbers work
    const error = new AppError('Number Code', 400);
    expect(error.status).toBe('fail');

    const error2 = new AppError('Number Code', 500);
    expect(error2.status).toBe('error');
  });
});
