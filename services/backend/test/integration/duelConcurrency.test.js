const { randomUUID } = require('node:crypto');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { setTimeout: delay } = require('node:timers/promises');
const { Client, Pool } = require('pg');
const db = require('../../src/config/db');
const wallet = require('../../src/services/walletService');

jest.mock('../../src/config/db', () => ({ query: jest.fn(), pool: { connect: jest.fn() } }));

const run = process.env.DUEL_TEST_DATABASE_URL ? describe : describe.skip;
run('concurrent duel wallet operations on separate PostgreSQL connections', () => {
  const schema = 'duel_test_' + randomUUID().replaceAll('-', '');
  let admin;
  let pool;

  beforeAll(async () => {
    const connectionString = process.env.DUEL_TEST_DATABASE_URL;
    admin = new Client({ connectionString });
    await admin.connect();
    await admin.query(`CREATE SCHEMA ${schema}`);
    pool = new Pool({ connectionString, application_name: schema, max: 8, options: `-c search_path=${schema}` });
    await pool.query(`
      CREATE TABLE users(id int PRIMARY KEY, coins int NOT NULL);
      CREATE TABLE user_claimed_quests(user_id int, quest_id text);
      CREATE TABLE room_likes(liker_id int, receiver_id int);
      INSERT INTO users VALUES (1,100), (2,100)`);
    await pool.query(readFileSync(join(__dirname, '../../migrations/061_duel_wagers.sql'), 'utf8'));
    db.query.mockImplementation((...args) => pool.query(...args));
    db.pool.connect.mockImplementation(() => pool.connect());
  });

  afterAll(async () => {
    await pool?.end();
    if (admin) {
      try { await admin.query(`DROP SCHEMA IF EXISTS ${schema} CASCADE`); }
      finally { await admin.end(); }
    }
  });

  async function race(lockSql, params, operations) {
    const gate = await pool.connect();
    let results;
    try {
      await gate.query('BEGIN');
      await gate.query(lockSql, params);
      results = Promise.allSettled(operations.map(fn => fn()));
      // Wait for real overlapping lock waits. A fast sequential run would pass
      // the final balance assertions without exercising the contention path.
      const deadline = Date.now() + 6000;
      while (true) {
        const { rows } = await admin.query(
          "SELECT count(*)::int AS n FROM pg_stat_activity WHERE application_name=$1 AND wait_event_type='Lock'",
          [schema]
        );
        if (rows[0].n >= 2) break;
        if (Date.now() >= deadline) throw new Error('Concurrent callers did not reach the lock');
        await delay(20);
      }
    } finally {
      try { await gate.query('ROLLBACK'); }
      finally { gate.release(); }
      if (results) await results;
    }
    return (await results).map(result => {
      if (result.status === 'rejected') throw result.reason;
      return result.value;
    });
  }

  it('takes a single stake and commits exactly one contested payout', async () => {
    const ids = Array.from({length: 4}, () => randomUUID());
    const joined = await race('SELECT id FROM users WHERE id=1 FOR NO KEY UPDATE', [],
      ids.map(id => () => wallet.reserve(id, 1, 25)));
    expect(joined.filter(Boolean)).toHaveLength(1);
    const holdA = ids[joined.indexOf(true)];
    const holdB = randomUUID();
    const match = randomUUID();
    expect(await wallet.reserve(holdB, 2, 25)).toBe(true);
    expect(await wallet.start(match, [holdA, holdB], 25)).toBe(true);

    const contenders = [['win', 1], ['draw', null], ['win', 2], ['win', 1]];
    const settled = await race('SELECT id FROM duel_wagers WHERE match_id=$1 FOR UPDATE', [match],
      contenders.map(([outcome, winner]) => () => wallet.settle(match, outcome, winner)));
    expect(settled.filter(Boolean)).toHaveLength(1);
    const [, winner] = contenders[settled.indexOf(true)];
    const payouts = winner === null ? [25,25] : winner === 1 ? [50,0] : [0,50];
    const ledger = await pool.query('SELECT payout FROM duel_wagers WHERE match_id=$1 ORDER BY user_id', [match]);
    expect(ledger.rows.map(row => row.payout)).toEqual(payouts);
    const balances = await pool.query('SELECT coins FROM users ORDER BY id');
    expect(balances.rows.map(row => row.coins)).toEqual(payouts.map(amount => 75 + amount));
  }, 20000);
});
