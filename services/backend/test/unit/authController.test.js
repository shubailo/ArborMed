// Virtual mocks for missing dependencies
jest.mock('bcryptjs', () => ({
    compare: jest.fn(),
    genSalt: jest.fn(),
    hash: jest.fn(),
}), { virtual: true });

jest.mock('jsonwebtoken', () => ({
    sign: jest.fn().mockReturnValue('mocked-jwt-token'),
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
        connect: jest.fn(),
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

const googleClient = require('google-auth-library').OAuth2Client.mock.results[0].value;

test('verified Google identity cannot activate an unverified legacy password account', async () => {
    const audience = process.env.GOOGLE_CLIENT_ID;
    process.env.GOOGLE_CLIENT_ID = 'local-test-audience';
    try {
        googleClient.verifyIdToken.mockResolvedValue({ getPayload: () => ({
            sub: 'test-subject', email: 'student@gmail.com', email_verified: true
        }) });
        db.query.mockResolvedValueOnce({ rows: [{ id: 1, is_email_verified: false }] });
        const res = { json: jest.fn() };
        const next = jest.fn();
        await authController.googleLogin({ body: { idToken: 'test-identity' } }, res, next);
        expect(next).toHaveBeenCalledWith(expect.objectContaining({ statusCode: 403 }));
        expect(res.json).not.toHaveBeenCalled();
    } finally {
        if (audience === undefined) delete process.env.GOOGLE_CLIENT_ID;
        else process.env.GOOGLE_CLIENT_ID = audience;
    }
});

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
        db.pool.connect.mockResolvedValueOnce({query:db.query, release:jest.fn()});
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
        const client = { query: jest.fn().mockResolvedValue({ rowCount: 1 }), release: jest.fn() };
        db.pool.connect = jest.fn().mockResolvedValue(client);

        await authController.changePassword(req, res, next);

        expect(bcrypt.compare).toHaveBeenCalledWith('oldPassword123', 'old_hashed_password');
        expect(client.query).toHaveBeenCalledWith(
            expect.stringContaining('AND password_hash = $3'),
            ['new_hashed_password', 1, 'old_hashed_password', expect.any(String)]
        );
        expect(client.query).toHaveBeenCalledWith(expect.stringContaining('DELETE FROM auth_challenges'), [1]);
        expect(client.query).toHaveBeenCalledWith(expect.stringContaining('UPDATE refresh_tokens SET revoked'), [1]);
        expect(res.json).toHaveBeenCalledWith({ message: 'Password updated successfully' });
    });

    test('does not overwrite credentials changed since password verification', async () => {
        db.query.mockResolvedValueOnce({ rows: [{ password_hash: 'old_hashed_password' }] });
        const client = { query: jest.fn().mockResolvedValue({ rowCount: 0 }), release: jest.fn() };
        db.pool.connect = jest.fn().mockResolvedValue(client);
        bcrypt.compare.mockResolvedValue(true);
        await authController.changePassword(req, res, next);
        expect(next).toHaveBeenCalledWith(expect.objectContaining({statusCode: 401}));
        expect(client.query).toHaveBeenCalledWith('ROLLBACK');
        expect(res.json).not.toHaveBeenCalled();
    });

    test('marks an incorrect current password as a form error so the client keeps its valid session', async () => {
        db.query.mockResolvedValue({
            rows: [{ password_hash: 'old_hashed_password' }]
        });
        bcrypt.compare.mockResolvedValue(false);

        await authController.changePassword(req, res, next);

        expect(bcrypt.compare).toHaveBeenCalledWith('oldPassword123', 'old_hashed_password');
        expect(next).toHaveBeenCalledWith(expect.objectContaining({ statusCode: 400 }));
    });

    test('should call bcrypt.compare even when user is NOT found (timing attack mitigation)', async () => {
        db.query.mockResolvedValue({ rows: [] });
        bcrypt.compare.mockResolvedValue(false);

        await authController.changePassword(req, res, next);

        // Sentinel Fix: bcrypt.compare MUST be called to prevent timing attacks
        expect(bcrypt.compare).toHaveBeenCalled();
        expect(next).toHaveBeenCalledWith(expect.objectContaining({ statusCode: 400 }));
    });
});

test('rejects generic coin claims without updating the wallet', async () => {
    jest.clearAllMocks();
    const next = jest.fn();
    await authController.claimReward({ user: { id: 1 }, body: { amount: 10 } }, {}, next);
    expect(next).toHaveBeenCalledWith(expect.objectContaining({ statusCode: 410 }));
    expect(db.query).not.toHaveBeenCalled();
});

describe('authController.register', () => {
    let req, res, next;

    beforeEach(() => {
        req = {
            body: {
                email: 'student@example.com',
                password: 'Password123!',
                username: 'medstudent',
                display_name: 'Dr. Student',
            },
        };
        res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn(),
        };
        next = jest.fn();
        jest.clearAllMocks();
    });

    test('should reject missing email or password', async () => {
        req.body.email = '';
        await authController.register(req, res, next);
        expect(next).toHaveBeenCalledWith(expect.objectContaining({ statusCode: 400 }));
    });

    test('should reject existing email collision', async () => {
        db.query.mockResolvedValueOnce({
            rows: [{ id: 1, email: 'student@example.com', username: 'other' }]
        });
        await authController.register(req, res, next);
        expect(next).toHaveBeenCalledWith(expect.objectContaining({
            statusCode: 400,
            message: expect.stringContaining('already exists'),
        }));
    });

    test('stores pending credentials and sends the code only to the mailbox', async () => {
        db.query.mockResolvedValueOnce({ rows: [] }).mockResolvedValueOnce({ rowCount: 1 });
        bcrypt.hash.mockResolvedValue('hashed_pw');
        const mail = require('../../src/services/mailService');
        await authController.register(req, res, next);
        expect(next).not.toHaveBeenCalled();
        expect(db.query).toHaveBeenCalledWith(expect.stringContaining('INSERT INTO auth_challenges'),
            expect.arrayContaining(['student@example.com', 'hashed_pw', 'medstudent', 'Dr. Student']));
        expect(mail.sendOTP).toHaveBeenCalledWith('student@example.com', '123456', 'registration');
        expect(res.status).toHaveBeenCalledWith(202);
        expect(res.json).toHaveBeenCalledWith({registrationId: expect.any(String), message: expect.any(String)});
        expect(JSON.stringify(db.query.mock.calls)).not.toContain('123456');
    });

    test('requires a pending challenge before issuing any session', async () => {
        const client = { query: jest.fn().mockResolvedValue({ rows: [] }), release: jest.fn() };
        db.pool.connect = jest.fn().mockResolvedValue(client);
        db.query.mockResolvedValueOnce({ rows: [] }).mockResolvedValueOnce({rows: [{id: 3, email: req.body.email}]});
        req.body.otp = '321654';
        req.body.registrationId = '6937de87-15e4-4df5-9fe5-215a098bd975';
        await authController.verifyRegistration(req, res, next);
        expect(next).toHaveBeenCalledWith(expect.objectContaining({statusCode: 400}));
        expect(res.json).not.toHaveBeenCalled();
    });
});

test.each([
    [{ code: 'ECONNRESET' }, 503],
    [{ response: { status: 429 } }, 503],
    [{ response: { status: 502 } }, 503],
    [{}, 401],
])('Google verification errors preserve the correct response status (%j)', async (detail, statusCode) => {
    const previous = process.env.GOOGLE_CLIENT_ID;
    process.env.GOOGLE_CLIENT_ID = 'fixture';
    const res = { json: jest.fn() },
        next = jest.fn();
    try {
        googleClient.verifyIdToken.mockRejectedValueOnce(
            Object.assign(new Error('fixture verification failure'), detail)
        );
        await authController.googleLogin({ body: { idToken: 'fixture' } }, res, next);
        expect(next).toHaveBeenCalledWith(expect.objectContaining({ statusCode }));
        expect(res.json).not.toHaveBeenCalled();
    } finally {
        if (previous === undefined) delete process.env.GOOGLE_CLIENT_ID;
        else process.env.GOOGLE_CLIENT_ID = previous;
    }
});
