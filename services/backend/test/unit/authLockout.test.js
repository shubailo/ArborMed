const authController = require('../../src/controllers/authController');
const db = require('../../src/config/db');
const bcrypt = require('bcryptjs');
const auditController = require('../../src/controllers/auditController');
// const AppError = require('../../src/utils/AppError'); // Do not mock AppError

jest.mock('../../src/config/db', () => ({
  query: jest.fn(),
  pool: {
    on: jest.fn(),
  },
}));
jest.mock('bcryptjs');
jest.mock('../../src/controllers/auditController');
jest.mock('google-auth-library');

describe('Auth Controller - Login Lockout', () => {
  let req, res, next;

  beforeAll(() => {
    process.env.JWT_SECRET = 'test_secret';
  });

  beforeEach(() => {
    req = { body: {} };
    res = {
      json: jest.fn(),
      status: jest.fn().mockReturnThis(),
    };
    next = jest.fn();
    jest.clearAllMocks();
  });

  test('should prevent login if account is locked', async () => {
    req.body = { email: 'user@example.com', password: 'password123' };

    const lockoutTime = new Date(Date.now() + 1000 * 60 * 10); // 10 mins from now
    const mockUser = {
      id: 1,
      email: 'user@example.com',
      password_hash: 'hashed_password',
      failed_attempts: 5,
      lockout_until: lockoutTime,
    };

    db.query.mockResolvedValueOnce({ rows: [mockUser] });

    await authController.login(req, res, next);

    expect(db.query).toHaveBeenCalledTimes(1);
    expect(bcrypt.compare).not.toHaveBeenCalled();
    expect(next).toHaveBeenCalledWith(expect.any(Error));
    const error = next.mock.calls[0][0];
    expect(error.message).toContain('Account locked');
    expect(error.statusCode).toBe(429);
  });

  test('should increment failed attempts on incorrect password', async () => {
    req.body = { email: 'user@example.com', password: 'wrongpassword' };

    const mockUser = {
      id: 1,
      email: 'user@example.com',
      password_hash: 'hashed_password',
      failed_attempts: 0,
      lockout_until: null,
    };

    db.query.mockResolvedValueOnce({ rows: [mockUser] }); // Select user
    bcrypt.compare.mockResolvedValue(false);
    db.query.mockResolvedValueOnce({}); // Update user

    await authController.login(req, res, next);

    expect(db.query).toHaveBeenCalledTimes(2); // Select + Update

    const updateQuery = db.query.mock.calls[1];
    expect(updateQuery[0]).toContain('UPDATE users SET failed_attempts = $1');
    expect(updateQuery[1][0]).toBe(1); // failedAttempts

    expect(auditController.auditLog).toHaveBeenCalledWith(
      expect.objectContaining({
        actionType: 'LOGIN_FAILURE',
        metadata: expect.objectContaining({ failedAttempts: 1 }),
      })
    );
    expect(next).toHaveBeenCalledWith(expect.any(Error));
    expect(next.mock.calls[0][0].message).toBe('Invalid credentials');
  });

  test('should lock account after MAX_FAILED_ATTEMPTS', async () => {
    req.body = { email: 'user@example.com', password: 'wrongpassword' };

    const mockUser = {
      id: 1,
      email: 'user@example.com',
      password_hash: 'hashed_password',
      failed_attempts: 4, // 4 failed attempts so far
      lockout_until: null,
    };

    db.query.mockResolvedValueOnce({ rows: [mockUser] }); // Select user
    bcrypt.compare.mockResolvedValue(false);
    db.query.mockResolvedValueOnce({}); // Update user

    await authController.login(req, res, next);

    expect(db.query).toHaveBeenCalledTimes(2); // Select + Update

    const updateQuery = db.query.mock.calls[1];
    expect(updateQuery[1][0]).toBe(5); // failedAttempts
    expect(updateQuery[1][1]).not.toBeNull(); // lockoutUntil should be set

    expect(next).toHaveBeenCalledWith(expect.any(Error));
    const error = next.mock.calls[0][0];
    expect(error.message).toContain('Account locked');
  });

  test('should reset failed attempts on successful login', async () => {
    req.body = { email: 'user@example.com', password: 'correctpassword' };

    const mockUser = {
      id: 1,
      email: 'user@example.com',
      password_hash: 'hashed_password',
      failed_attempts: 3,
      lockout_until: null,
    };

    db.query.mockResolvedValueOnce({ rows: [mockUser] }); // Select user
    bcrypt.compare.mockResolvedValue(true);
    db.query.mockResolvedValueOnce({}); // Reset query
    db.query.mockResolvedValueOnce({}); // Insert refresh token

    await authController.login(req, res, next);

    const resetQuery = db.query.mock.calls[1];
    expect(resetQuery[0]).toContain(
      'UPDATE users SET failed_attempts = 0, lockout_until = NULL'
    );

    expect(res.json).toHaveBeenCalled();
  });
});
