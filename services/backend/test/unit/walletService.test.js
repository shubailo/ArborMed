const db = require('../../src/config/db');
const { withTransaction } = require('../../src/utils/dbHelpers');
const wallet = require('../../src/services/walletService');
jest.mock('../../src/config/db', () => ({ query: jest.fn() }));
jest.mock('../../src/utils/dbHelpers', () => ({ withTransaction: jest.fn() }));
beforeEach(() => {
  jest.clearAllMocks();
  withTransaction.mockImplementation(fn => fn(db));
});
it.each([0, -5, 2, 2.5, '10', null, {}, 1000])('rejects invalid wager %p before accessing balances', async wager => {
  expect(await wallet.reserve('hold', 1, wager)).toBe(false);
  expect(db.query).not.toHaveBeenCalled();
});
it('does not debit when another reservation already exists', async () => {
  db.query.mockResolvedValueOnce({ rowCount: 0 });
  expect(await wallet.reserve('hold', 1, 10)).toBe(false);
  expect(db.query).toHaveBeenCalledTimes(1);
});
it('rolls back the reservation when the balance cannot fund it', async () => {
  db.query.mockResolvedValueOnce({ rowCount: 1 }).mockResolvedValueOnce({ rowCount: 0 });
  expect(await wallet.reserve('hold', 1, 100)).toBe(false);
  expect(db.query.mock.calls[1][0]).toMatch(/coins >= \$2/);
});
it('treats a replayed settlement as already closed', async () => {
  db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });
  expect(await wallet.settle('match', 'draw', null)).toBe(false);
  expect(db.query).toHaveBeenCalledTimes(1);
});
