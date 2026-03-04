// Virtual mocks for missing dependencies
jest.mock('bcryptjs', () => ({
    compare: jest.fn(),
    genSalt: jest.fn(),
    hash: jest.fn(),
}), { virtual: true });

jest.mock('jsonwebtoken', () => ({
    sign: jest.fn(),
    verify: jest.fn(),
}), { virtual: true });

jest.mock('../../src/utils/cryptoUtils', () => ({
    generateSecureOTP: jest.fn().mockReturnValue('123456'),
}));

jest.mock('google-auth-library', () => ({
    OAuth2Client: jest.fn().mockImplementation(() => ({
        verifyIdToken: jest.fn(),
    })),
}), { virtual: true });

jest.mock('pg', () => ({
    Pool: jest.fn().mockImplementation(() => ({
        on: jest.fn(),
        connect: jest.fn(),
        query: jest.fn(),
    })),
}), { virtual: true });

jest.mock('dotenv', () => ({
    config: jest.fn(),
}), { virtual: true });

// Mock local modules that might import missing dependencies
jest.mock('../../src/config/db', () => ({
    query: jest.fn(),
    pool: {
        on: jest.fn(),
    }
}));

jest.mock('../../src/services/mailService', () => ({
    sendOTP: jest.fn(),
}));

jest.mock('../../src/controllers/auditController', () => ({
    auditLog: jest.fn(),
}));

// Mock catchAsync to allow awaiting the handler
jest.mock('../../src/utils/catchAsync', () => (fn) => (req, res, next) => {
    return fn(req, res, next).catch(next);
});

const bcrypt = require('bcryptjs');
const db = require('../../src/config/db');
const authController = require('../../src/controllers/authController');

describe('authController.login', () => {
    let req, res, next;

    beforeAll(() => {
        process.env.JWT_SECRET = 'test-secret';
    });

    beforeEach(() => {
        req = {
            body: {
                email: 'test@example.com',
                password: 'password123',
            },
        };
        res = {
            json: jest.fn(),
            status: jest.fn().mockReturnThis(),
        };
        next = jest.fn();
        jest.clearAllMocks();
    });

    test('should call bcrypt.compare when user is found (password match)', async () => {
        db.query.mockResolvedValue({
            rows: [{
                id: 1,
                email: 'test@example.com',
                password_hash: 'hashed_password',
                role: 'student'
            }]
        });
        bcrypt.compare.mockResolvedValue(true);

        await authController.login(req, res, next);

        expect(bcrypt.compare).toHaveBeenCalledWith('password123', 'hashed_password');
        expect(res.json).toHaveBeenCalled();
    });

    test('should call bcrypt.compare when user is found (password wrong)', async () => {
        db.query.mockResolvedValue({
            rows: [{
                id: 1,
                email: 'test@example.com',
                password_hash: 'hashed_password'
            }]
        });
        bcrypt.compare.mockResolvedValue(false);

        await authController.login(req, res, next);

        expect(bcrypt.compare).toHaveBeenCalledWith('password123', 'hashed_password');
        expect(next).toHaveBeenCalledWith(expect.objectContaining({ statusCode: 401 }));
    });

    test('should call bcrypt.compare even when user is NOT found (timing attack mitigation)', async () => {
        db.query.mockResolvedValue({ rows: [] });
        // Mock bcrypt.compare to return false (as dummy hash won't match)
        bcrypt.compare.mockResolvedValue(false);

        await authController.login(req, res, next);

        // Sentinel Fix: bcrypt.compare MUST be called to prevent timing attacks
        expect(bcrypt.compare).toHaveBeenCalled();
        expect(next).toHaveBeenCalledWith(expect.objectContaining({ statusCode: 401 }));
    });
});

describe('authController.changePassword', () => {
    let req, res, next;

    beforeEach(() => {
        req = {
            user: { id: 1 },
            body: {
                currentPassword: 'oldPassword123',
                newPassword: 'NewPassword123!',
            },
        };
        res = {
            json: jest.fn(),
            status: jest.fn().mockReturnThis(),
        };
        next = jest.fn();
        jest.clearAllMocks();
    });

    test('should change password successfully', async () => {
        db.query.mockResolvedValueOnce({
            rows: [{ password_hash: 'old_hashed_password' }]
        });
        bcrypt.compare.mockResolvedValue(true);
        bcrypt.genSalt.mockResolvedValue('salt');
        bcrypt.hash.mockResolvedValue('new_hashed_password');
        db.query.mockResolvedValueOnce({ rows: [] }); // For UPDATE query

        await authController.changePassword(req, res, next);

        expect(bcrypt.compare).toHaveBeenCalledWith('oldPassword123', 'old_hashed_password');
        expect(db.query).toHaveBeenCalledWith(
            expect.stringContaining('UPDATE users SET password_hash'),
            ['new_hashed_password', 1]
        );
        expect(res.json).toHaveBeenCalledWith({ message: 'Password updated successfully' });
    });

    test('should return 401 for incorrect current password', async () => {
        db.query.mockResolvedValue({
            rows: [{ password_hash: 'old_hashed_password' }]
        });
        bcrypt.compare.mockResolvedValue(false);

        await authController.changePassword(req, res, next);

        expect(bcrypt.compare).toHaveBeenCalledWith('oldPassword123', 'old_hashed_password');
        expect(next).toHaveBeenCalledWith(expect.objectContaining({ statusCode: 401 }));
    });

    test('should call bcrypt.compare even when user is NOT found (timing attack mitigation)', async () => {
        db.query.mockResolvedValue({ rows: [] });
        bcrypt.compare.mockResolvedValue(false);

        await authController.changePassword(req, res, next);

        // Sentinel Fix: bcrypt.compare MUST be called to prevent timing attacks
        expect(bcrypt.compare).toHaveBeenCalled();
        expect(next).toHaveBeenCalledWith(expect.objectContaining({ statusCode: 401 }));
    });
});
