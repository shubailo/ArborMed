jest.mock('pg', () => ({ Pool: jest.fn() }), { virtual: true });
const db = require('../../src/config/db');
const WalletService = require('../../src/services/walletService');

jest.mock('../../src/config/db', () => ({
    query: jest.fn(),
    pool: { on: jest.fn() }
}));

describe('WalletService', () => {
    let consoleSpy;

    beforeEach(() => {
        jest.clearAllMocks();
        consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    });

    afterEach(() => {
        consoleSpy.mockRestore();
    });

    describe('sinkWager', () => {
        it('should return true when wager is successfully deducted', async () => {
            db.query.mockResolvedValue({ rowCount: 1 });
            const result = await WalletService.sinkWager(1, 10);
            expect(result).toBe(true);
            expect(db.query).toHaveBeenCalledWith(
                expect.stringContaining('UPDATE users SET coins = coins - $1'),
                [10, 1]
            );
        });

        it('should return false when insufficient funds (rowCount 0)', async () => {
            db.query.mockResolvedValue({ rowCount: 0 });
            const result = await WalletService.sinkWager(1, 100);
            expect(result).toBe(false);
            expect(db.query).toHaveBeenCalledWith(
                expect.stringContaining('UPDATE users SET coins = coins - $1'),
                [100, 1]
            );
        });

        it('should return false and log error when database query fails', async () => {
            const error = new Error('Database connection failed');
            db.query.mockRejectedValue(error);

            const result = await WalletService.sinkWager(1, 10);

            expect(result).toBe(false);
            expect(consoleSpy).toHaveBeenCalledWith('Wallet Error:', error);
        });
    });

    describe('awardPot', () => {
        it('should return true when pot is successfully awarded', async () => {
            db.query.mockResolvedValue({ rowCount: 1 });
            const result = await WalletService.awardPot(1, 20);
            expect(result).toBe(true);
            expect(db.query).toHaveBeenCalledWith(
                expect.stringContaining('UPDATE users SET coins = coins + $1'),
                [20, 1]
            );
        });

        it('should return false and log error when database query fails', async () => {
            const error = new Error('Database error');
            db.query.mockRejectedValue(error);
            const result = await WalletService.awardPot(1, 20);
            expect(result).toBe(false);
            expect(consoleSpy).toHaveBeenCalledWith('Wallet Error:', error);
        });
    });

    describe('refund', () => {
        it('should call awardPot and return its result', async () => {
            // We can spy on awardPot to ensure it's called, but since it's a static method heavily coupled with db,
            // testing the db call is sufficient as it's an integration-like unit test.
            // Or we can mock awardPot if we want to isolate refund.
            // But since they are in the same class, testing the outcome is fine.

            db.query.mockResolvedValue({ rowCount: 1 });
            const result = await WalletService.refund(1, 10);
            expect(result).toBe(true);
            expect(db.query).toHaveBeenCalledWith(
                expect.stringContaining('UPDATE users SET coins = coins + $1'),
                [10, 1]
            );
        });
    });
});
