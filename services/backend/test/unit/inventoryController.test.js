const inventoryController = require('../../src/controllers/inventoryController');
const db = require('../../src/config/db');
const AppError = require('../../src/utils/AppError');
const { withTransaction } = require('../../src/utils/dbHelpers');

jest.mock('../../src/config/db', () => ({
    query: jest.fn(),
    pool: { on: jest.fn() }
}));

jest.mock('../../src/utils/catchAsync', () => (fn) => (req, res, next) => {
    return fn(req, res, next).catch(next);
});

jest.mock('../../src/utils/dbHelpers', () => ({
    withTransaction: jest.fn()
}));

describe('inventoryController', () => {
    let req, res, next;
    let clientMock;

    beforeEach(() => {
        req = {
            user: { id: 1 },
            body: {}
        };
        res = {
            json: jest.fn(),
            status: jest.fn().mockReturnThis()
        };
        next = jest.fn();
        clientMock = {
            query: jest.fn()
        };
        jest.clearAllMocks();
    });

    describe('equipItem', () => {
        test('should equip item and unequip existing item in slot with actualRoomId', async () => {
            req.body = {
                userItemId: 10,
                roomId: 1,
                slot: 'desk'
            };

            withTransaction.mockImplementationOnce(fn => fn(clientMock));
            clientMock.query
                .mockResolvedValueOnce({ rows: [{ id: 1 }] })
                .mockResolvedValueOnce({ rows: [{ id: 42 }] })
                .mockResolvedValueOnce({ rowCount: 1 })
                .mockResolvedValueOnce({ rowCount: 1 });
            await inventoryController.equipItem(req, res, next);
            expect(clientMock.query).toHaveBeenCalledWith(expect.stringContaining('NOT uses_grid'), [1, 42, 'desk']);
            expect(clientMock.query).toHaveBeenCalledWith(expect.stringContaining('uses_grid = $5'), [42, 'desk', 0, 0, false, 10, 1]);
            expect(res.json).toHaveBeenCalledWith({ message: 'Item equipped', roomId: 42 });
        });

        test('should return 404 if item does not belong to user', async () => {
            req.body = { userItemId: 999, slot: 'desk' };
            withTransaction.mockImplementationOnce(fn => fn(clientMock));
            clientMock.query
                .mockResolvedValueOnce({ rows: [{ id: 1 }] })
                .mockResolvedValueOnce({ rows: [{ id: 42 }] })
                .mockResolvedValueOnce({ rowCount: 1 })
                .mockResolvedValueOnce({ rowCount: 0 });
            await inventoryController.equipItem(req, res, next);
            expect(next).toHaveBeenCalledWith(expect.objectContaining({ statusCode: 404 }));
        });
    });

    describe('unequipItem', () => {
        test('should unequip item and return success message', async () => {
            req.body = { userItemId: 10 };
            db.query.mockResolvedValueOnce({ rows: [{ id: 10 }] });

            await inventoryController.unequipItem(req, res, next);

            expect(db.query).toHaveBeenCalledWith(
                expect.stringMatching(/UPDATE user_items SET is_placed = false, .*uses_grid = false/i),
                [10, 1]
            );
            expect(res.json).toHaveBeenCalledWith({ message: 'Item removed from room' });
        });

        test('should return 404 if item to unequip is not found', async () => {
            req.body = { userItemId: 999 };
            db.query.mockResolvedValueOnce({ rows: [] });

            await inventoryController.unequipItem(req, res, next);

            expect(next).toHaveBeenCalledWith(expect.any(AppError));
            expect(next.mock.calls[0][0].statusCode).toBe(404);
        });
    });
});
