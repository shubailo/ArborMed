const db = require('../../src/config/db');
const statsController = require('../../src/controllers/statsController');
const AppError = require('../../src/utils/AppError');

// Mock db
jest.mock('../../src/config/db', () => ({
    query: jest.fn(),
}));

// Mock catchAsync to allow awaiting the handler
jest.mock('../../src/utils/catchAsync', () => (fn) => (req, res, next) => {
    return fn(req, res, next).catch(next);
});

describe('statsController.getActivity', () => {
    let req, res, next;

    beforeEach(() => {
        req = {
            user: { id: 1 },
            query: {},
        };
        res = {
            json: jest.fn(),
            status: jest.fn().mockReturnThis(),
        };
        next = jest.fn();
        jest.clearAllMocks();
    });

    test('should fail for invalid timeframe', async () => {
        req.query.timeframe = 'invalid';
        await statsController.getActivity(req, res, next);
        expect(next).toHaveBeenCalledWith(expect.any(AppError));
        expect(next.mock.calls[0][0].statusCode).toBe(400);
        expect(next.mock.calls[0][0].message).toBe('Invalid timeframe');
    });

    test('should fail for invalid anchorDate format', async () => {
        req.query.anchorDate = '2023-1-1';
        await statsController.getActivity(req, res, next);
        expect(next).toHaveBeenCalledWith(expect.any(AppError));
        expect(next.mock.calls[0][0].statusCode).toBe(400);
        expect(next.mock.calls[0][0].message).toContain('Invalid anchorDate format');
    });

    test('should use parameterized queries and not interpolate anchorDate', async () => {
        req.query.anchorDate = '2023-01-01';
        req.query.timeframe = 'week';
        db.query.mockResolvedValue({ rows: [] });

        await statsController.getActivity(req, res, next);

        expect(db.query).toHaveBeenCalled();
        const [query, params] = db.query.mock.calls[0];

        // Check that the query does NOT contain the raw date string
        expect(query).not.toContain('2023-01-01');

        // Check that parameters are passed correctly
        expect(params).toContain('2023-01-01');
        expect(params).toContain(1); // userId
    });
});

describe('statsController.getMistakesByTimeframe', () => {
    let req, res, next;

    beforeEach(() => {
        req = {
            user: { id: 1 },
            query: {},
        };
        res = {
            json: jest.fn(),
            status: jest.fn().mockReturnThis(),
        };
        next = jest.fn();
        jest.clearAllMocks();
    });

    test('should fail for invalid timeframe', async () => {
        req.query.timeframe = 'invalid';
        await statsController.getMistakesByTimeframe(req, res, next);
        expect(next).toHaveBeenCalledWith(expect.any(AppError));
        expect(next.mock.calls[0][0].statusCode).toBe(400);
    });

    test('should use parameterized queries', async () => {
        req.query.anchorDate = '2023-01-01';
        db.query.mockResolvedValue({ rows: [] });

        await statsController.getMistakesByTimeframe(req, res, next);

        expect(db.query).toHaveBeenCalled();
        const [query, params] = db.query.mock.calls[0];

        expect(query).not.toContain('2023-01-01');
        expect(params).toContain('2023-01-01');
    });
});
