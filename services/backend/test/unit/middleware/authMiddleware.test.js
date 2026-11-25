const jwt = require('jsonwebtoken');
const { protect } = require('../../../src/middleware/authMiddleware');
const db = require('../../../src/config/db');

// Mock dependencies
jest.mock('jsonwebtoken', () => ({
    verify: jest.fn()
}), { virtual: true });
jest.mock('../../../src/config/db', () => ({
    query: jest.fn()
}));

describe('Auth Middleware', () => {
    let req, res, next;

    beforeEach(() => {
        process.env.JWT_SECRET = 'test_secret';
        req = {
            headers: {}
        };
        res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn()
        };
        next = jest.fn();
        jest.clearAllMocks();
        jest.spyOn(console, 'error').mockImplementation(() => {});
        jest.spyOn(console, 'warn').mockImplementation(() => {});
    });

    afterEach(() => {
        jest.restoreAllMocks();
    });

    it('should call next if token is valid and user is found', async () => {
        const token = 'valid.token';
        const decoded = { id: 1 };
        const user = { id: 1, email: 'test@example.com', role: 'student' };

        req.headers.authorization = `Bearer ${token}`;
        jwt.verify.mockReturnValue(decoded);
        db.query.mockResolvedValue({ rows: [user] });

        await protect(req, res, next);

        expect(jwt.verify).toHaveBeenCalledWith(token, process.env.JWT_SECRET, { algorithms: ['HS256'] });
        expect(db.query).toHaveBeenCalledWith(expect.stringContaining('email_session_version::text IS NOT DISTINCT FROM $2'), [decoded.id, null]);
        expect(req.user).toEqual(user);
        expect(next).toHaveBeenCalled();
        expect(res.status).not.toHaveBeenCalled();
    });

    it('should return 401 if no authorization header', async () => {
        await protect(req, res, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.json).toHaveBeenCalledWith({ message: 'Not authorized, no token' });
        expect(next).not.toHaveBeenCalled();
    });

    it('accepts the decimal user ID from older refresh responses as the same account', async () => {
        jwt.verify.mockReturnValue({ id: '17' });
        db.query.mockResolvedValue({ rows: [{ id: 17 }] });
        req.headers.authorization = 'Bearer session';
        await protect(req, res, next);
        expect(db.query).toHaveBeenCalledWith(expect.any(String), [17, null]);
        expect(next).toHaveBeenCalledTimes(1);
    });

    it.each([null, {}, { id: 0 }, { id: '2147483648' }, { id: [] }])(
        'rejects invalid access claims before a database lookup', async claims => {
            jwt.verify.mockReturnValue(claims);
            req.headers.authorization = 'Bearer session';
            await protect(req, res, next);
            expect(db.query).not.toHaveBeenCalled();
            expect(res.status).toHaveBeenCalledWith(401);
            expect(next).not.toHaveBeenCalled();
        }
    );

    it('should return 401 if authorization header does not start with Bearer', async () => {
        req.headers.authorization = 'Basic token';
        await protect(req, res, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.json).toHaveBeenCalledWith({ message: 'Not authorized, no token' });
        expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 if token verification fails', async () => {
        req.headers.authorization = 'Bearer invalid.token';
        jwt.verify.mockImplementation(() => {
            throw new Error('Invalid token');
        });

        await protect(req, res, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.json).toHaveBeenCalledWith({ message: 'Not authorized, token failed' });
        expect(next).not.toHaveBeenCalled();
    });

    it('uses only the ArborMed signing key even if a separate service key is configured', async () => {
        const priorKey = process.env.SUPABASE_JWT_SECRET;
        process.env.SUPABASE_JWT_SECRET = 'other-test-service';
        try {
            req.headers.authorization = 'Bearer session';
            jwt.verify.mockImplementation(() => { throw new Error('Rejected'); });
            await protect(req, res, next);
            expect(jwt.verify).toHaveBeenCalledTimes(1);
            expect(db.query).not.toHaveBeenCalled();
            expect(res.status).toHaveBeenCalledWith(401);
        } finally {
            if (priorKey === undefined) delete process.env.SUPABASE_JWT_SECRET;
            else process.env.SUPABASE_JWT_SECRET = priorKey;
        }
    });

    it('should return 401 if user is not found in database', async () => {
        const token = 'valid.token';
        const decoded = { id: 1 };

        req.headers.authorization = `Bearer ${token}`;
        jwt.verify.mockReturnValue(decoded);
        db.query.mockResolvedValue({ rows: [] }); // User not found

        await protect(req, res, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.json).toHaveBeenCalledWith({ message: 'Not authorized, user not found' });
        expect(next).not.toHaveBeenCalled();
    });

    it('should report temporary unavailability if the database lookup fails', async () => {
        const token = 'valid.token';
        const decoded = { id: 1 };

        req.headers.authorization = `Bearer ${token}`;
        jwt.verify.mockReturnValue(decoded);
        db.query.mockRejectedValue(new Error('DB Error'));

        await protect(req, res, next);

        expect(res.status).toHaveBeenCalledWith(503);
        expect(res.json).toHaveBeenCalledWith({ message: 'Authentication service temporarily unavailable' });
        expect(next).not.toHaveBeenCalled();
    });

    it('keeps the verified account available during an activity-recording failure', async () => {
        req.headers.authorization = 'Bearer session';
        jwt.verify.mockReturnValue({ id: 17 });
        db.query.mockResolvedValueOnce({ rows: [{ id: 17, role: 'student', activity_due: true }] })
            .mockRejectedValueOnce(new Error('Activity write unavailable'));
        await protect(req, res, next);
        expect(db.query).toHaveBeenCalledTimes(2);
        expect(req.user).toEqual({ id: 17, role: 'student' });
        expect(next).toHaveBeenCalledTimes(1);
    });
});
