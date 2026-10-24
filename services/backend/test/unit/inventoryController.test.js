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

            // 1. Verify Ownership
            db.query.mockResolvedValueOnce({ rows: [{ id: 10, user_id: 1, item_id: 200 }] });
            // 1.5 UPSERT Room
            db.query.mockResolvedValueOnce({ rows: [{ id: 42 }] }); // actualRoomId = 42

            withTransaction.mockImplementationOnce(async (fn) => {
                clientMock.query
                    .mockResolvedValueOnce({ rows: [], rowCount: 1 }) // unequip previous
                    .mockResolvedValueOnce({ rows: [{ id: 10 }], rowCount: 1 }); // equip new
                return await fn(clientMock);
            });

            await inventoryController.equipItem(req, res, next);

            expect(db.query).toHaveBeenCalledTimes(2);
            expect(withTransaction).toHaveBeenCalled();
            // Verify clientMock.query was called with actualRoomId (42)
            expect(clientMock.query).toHaveBeenCalledWith(
                expect.stringContaining('UPDATE user_items \n                SET is_placed = FALSE'),
                [1, 42, 'desk']
            );
            expect(clientMock.query).toHaveBeenCalledWith(
                expect.stringContaining('UPDATE user_items \n            SET is_placed = TRUE'),
                [42, 'desk', 0, 0, 10]
            );
            expect(res.json).toHaveBeenCalledWith({ message: 'Item equipped' });
        });

        test('should return 404 if item does not belong to user', async () => {
            req.body = { userItemId: 999, slot: 'desk' };
            db.query.mockResolvedValueOnce({ rows: [] });

            await inventoryController.equipItem(req, res, next);

            expect(next).toHaveBeenCalledWith(expect.any(AppError));
            expect(next.mock.calls[0][0].statusCode).toBe(404);
        });
    });

    describe('unequipItem', () => {
        test('should unequip item and return success message', async () => {
            req.body = { userItemId: 10 };
            db.query.mockResolvedValueOnce({ rows: [{ id: 10 }] });

            await inventoryController.unequipItem(req, res, next);

            expect(db.query).toHaveBeenCalledWith(
                expect.stringContaining('UPDATE user_items SET is_placed = FALSE'),
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
