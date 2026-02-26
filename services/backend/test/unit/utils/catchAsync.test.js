const catchAsync = require('../../../src/utils/catchAsync');

describe('catchAsync Utility', () => {
  it('should call the wrapped function with req, res, and next', async () => {
    const fn = jest.fn().mockResolvedValue('success');
    const req = {};
    const res = {};
    const next = jest.fn();

    const wrapped = catchAsync(fn);
    await wrapped(req, res, next);

    expect(fn).toHaveBeenCalledWith(req, res, next);
  });

  it('should catch errors from rejected promises and call next with the error', async () => {
    const error = new Error('Async error');
    const fn = jest.fn().mockRejectedValue(error);
    const req = {};
    const res = {};
    const next = jest.fn();

    const wrapped = catchAsync(fn);
    await wrapped(req, res, next);

    expect(next).toHaveBeenCalledWith(error);
  });

  it('should not interfere when the wrapped function resolves successfully', async () => {
    const fn = jest.fn().mockResolvedValue('success');
    const req = {};
    const res = {};
    const next = jest.fn();

    const wrapped = catchAsync(fn);
    await wrapped(req, res, next);

    expect(next).not.toHaveBeenCalled();
  });
});
