const jwt = require('jsonwebtoken');
const { protect } = require('../../../src/middleware/authMiddleware');
const db = require('../../../src/config/db');

// Mock dependencies
jest.mock('jsonwebtoken');
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

        expect(jwt.verify).toHaveBeenCalledWith(token, process.env.JWT_SECRET);
        expect(db.query).toHaveBeenCalledWith(expect.stringContaining('SELECT'), [decoded.id]);
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

    it('should return 401 if database query fails', async () => {
        const token = 'valid.token';
        const decoded = { id: 1 };

        req.headers.authorization = `Bearer ${token}`;
        jwt.verify.mockReturnValue(decoded);
        db.query.mockRejectedValue(new Error('DB Error'));

        await protect(req, res, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.json).toHaveBeenCalledWith({ message: 'Not authorized, token failed' });
        expect(next).not.toHaveBeenCalled();
    });
});
