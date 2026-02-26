// Virtual mocks for missing dependencies
jest.mock('pg', () => ({
    Pool: jest.fn().mockImplementation(() => ({
        on: jest.fn(),
        connect: jest.fn(),
        query: jest.fn(),
    })),
}), { virtual: true });

jest.mock('bcryptjs', () => ({
    compare: jest.fn(),
    hash: jest.fn(),
}), { virtual: true });

jest.mock('jsonwebtoken', () => ({
    sign: jest.fn(),
    verify: jest.fn(),
}), { virtual: true });

// Mock local modules
jest.mock('../../src/config/db', () => ({
    query: jest.fn(),
    pool: {
        on: jest.fn(),
        connect: jest.fn(),
    }
}));

jest.mock('../../src/utils/dbHelpers', () => ({
    withTransaction: jest.fn()
}));

// Mock catchAsync to allow awaiting the handler
jest.mock('../../src/utils/catchAsync', () => (fn) => (req, res, next) => {
    return fn(req, res, next).catch(next);
});

const db = require('../../src/config/db');
const { withTransaction } = require('../../src/utils/dbHelpers');
const shopController = require('../../src/controllers/shopController');
const AppError = require('../../src/utils/AppError');

describe('shopController.buyItem', () => {
    let req, res, next;

    beforeEach(() => {
        req = {
            user: { id: 1 },
            body: { itemId: 101 }
        };
        res = {
            json: jest.fn()
        };
        next = jest.fn();
        jest.clearAllMocks();
    });

    it('should purchase item successfully when balance is sufficient', async () => {
        // Mock item lookup
        db.query.mockResolvedValueOnce({
            rows: [{ id: 101, name: 'Test Item', price: 50 }]
        });

        // Mock transaction
        const mockClient = {
            query: jest.fn()
        };

        // Mock user update (success)
        mockClient.query.mockResolvedValueOnce({
            rowCount: 1,
            rows: [{ coins: 50 }]
        });

        // Mock inventory insertion
        mockClient.query.mockResolvedValueOnce({
            rows: [{ id: 500 }]
        });

        withTransaction.mockImplementation(async (fn) => {
            return await fn(mockClient);
        });

        await shopController.buyItem(req, res, next);

        expect(db.query).toHaveBeenCalledWith(expect.stringContaining('SELECT * FROM items'), [101]);
        expect(mockClient.query).toHaveBeenCalledWith(
            expect.stringContaining('UPDATE users SET coins = coins - $1 WHERE id = $2 AND coins >= $1'),
            [50, 1]
        );
        expect(res.json).toHaveBeenCalledWith({
            message: 'Item purchased',
            userItemId: 500,
            newBalance: 50
        });
    });

    it('should return 400 when coins are insufficient', async () => {
        // Mock item lookup
        db.query.mockResolvedValueOnce({
            rows: [{ id: 101, name: 'Test Item', price: 50 }]
        });

        const mockClient = {
            query: jest.fn()
        };

        // Mock user update (insufficient coins -> rowCount: 0)
        mockClient.query.mockResolvedValueOnce({
            rowCount: 0,
            rows: []
        });

        withTransaction.mockImplementation(async (fn) => {
            try {
                return await fn(mockClient);
            } catch (err) {
                throw err;
            }
        });

        await shopController.buyItem(req, res, next);

        expect(next).toHaveBeenCalledWith(expect.any(AppError));
        const error = next.mock.calls[0][0];
        expect(error.statusCode).toBe(400);
        expect(error.message).toBe('Insufficient coins');
    });

    it('should return 404 when item is not found', async () => {
        // Mock item lookup (not found)
        db.query.mockResolvedValueOnce({
            rows: []
        });

        await shopController.buyItem(req, res, next);

        expect(next).toHaveBeenCalledWith(expect.any(AppError));
        const error = next.mock.calls[0][0];
        expect(error.statusCode).toBe(404);
        expect(error.message).toBe('Item not found');
    });
});
