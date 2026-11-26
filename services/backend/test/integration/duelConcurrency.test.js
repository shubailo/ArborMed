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
      CREATE TABLE users(id int PRIMARY KEY, coins int NOT NULL, last_activity_at timestamptz,
        daily_coins_earned int DEFAULT 0, daily_coins_softcap_progress int DEFAULT 0, last_coin_reset_date date);
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

  it('does not start a match with a hold that expires during a lock wait', async () => {
    const hold = randomUUID(), match = randomUUID();
    await pool.query('INSERT INTO users(id,coins) VALUES (160,100)');
    await wallet.reserve(hold, 160, 5);
    const gate = await pool.connect();
    let starting;
    try {
      await gate.query('BEGIN');
      await gate.query('SELECT id FROM duel_wagers WHERE id=$1 FOR UPDATE', [hold]);
      starting = wallet.start(match, [hold], 5);
      const limit = Date.now() + 6000;
      while (!(await admin.query(
        "SELECT 1 FROM pg_stat_activity WHERE application_name=$1 AND wait_event_type='Lock'", [schema]
      )).rowCount) {
        if (Date.now() >= limit) throw new Error('Match start did not reach the hold lock');
        await delay(20);
      }
      await gate.query('UPDATE duel_wagers SET expires_at=clock_timestamp() WHERE id=$1', [hold]);
      await gate.query('COMMIT');
      expect(await starting).toBe(false);
      expect((await pool.query('SELECT match_id FROM duel_wagers WHERE id=$1', [hold])).rows[0].match_id).toBeNull();
      await wallet.cancel(hold);
      expect((await pool.query('SELECT coins FROM users WHERE id=160')).rows[0].coins).toBe(100);
    } finally {
      await gate.query('ROLLBACK');
      gate.release();
      if (starting) await starting;
    }
  });

  it('refunds the entire match when recovery overtakes a blocked settlement', async () => {
    await pool.query('INSERT INTO users(id,coins) VALUES (111,100),(112,100)');
    const holds = [randomUUID(), randomUUID()].sort();
    const match = randomUUID();
    for (const [i,id] of holds.entries()) expect(await wallet.reserve(id,111+i,25)).toBe(true);
    expect(await wallet.start(match,holds,25)).toBe(true);
    await pool.query("UPDATE duel_wagers SET expires_at = clock_timestamp() + interval '2 seconds' WHERE match_id=$1",[match]);
    const gate = await pool.connect();
    let settlement;
    try {
      await gate.query('BEGIN');
      await gate.query('SELECT id FROM duel_wagers WHERE id=$1 FOR UPDATE',[holds[0]]);
      settlement = wallet.settlePayouts(match,'win',111);
      const deadline = Date.now()+5000;
      while (!(await admin.query("SELECT FROM pg_stat_activity WHERE application_name=$1 AND wait_event_type='Lock'",[schema])).rowCount) {
        if (Date.now() > deadline) throw new Error('Settlement did not reach the locked wager');
        await delay(20);
      }
      await pool.query('SELECT pg_sleep(GREATEST(0,EXTRACT(epoch FROM expires_at-clock_timestamp()))) FROM duel_wagers WHERE id=$1',[holds[0]]);
      expect(await wallet.recoverExpired()).toBe(true);
      expect(await wallet.receipt(match,112)).toEqual({wager:25,payout:25});
    } finally {
      try { await gate.query('ROLLBACK'); } finally { gate.release(); }
    }
    expect(await settlement).toEqual([]);
    expect(await wallet.recoverExpired()).toBe(true);
    expect(await wallet.settlePayouts(match,'win',111)).toEqual([]);
    expect((await pool.query('SELECT coins FROM users WHERE id IN (111,112) ORDER BY id')).rows)
      .toEqual([{coins:100},{coins:100}]);
  });

  it('enforces refunds for unassigned wagers while retaining historical receipts on upgrade', async () => {
    const client = await pool.connect();
    const legacy = randomUUID();
    try {
      await client.query('BEGIN');
      await client.query("INSERT INTO duel_wagers (id,user_id,amount,expires_at,closed_at,payout) VALUES ($1,1,5,now(),now(),0)",[legacy]);
      const migration = readFileSync(join(__dirname,'../../migrations/070_unmatched_wager_refunds.sql'),'utf8');
      await client.query(migration);
      expect((await client.query('SELECT payout FROM duel_wagers WHERE id=$1',[legacy])).rows).toEqual([{payout:0}]);
      await client.query("INSERT INTO duel_wagers (id,user_id,amount,expires_at,closed_at,payout) VALUES ($1,1,5,now(),now(),5)",[randomUUID()]);
      await expect(client.query("INSERT INTO duel_wagers (id,user_id,amount,expires_at,closed_at,payout) VALUES ($1,1,5,now(),now(),10)",[randomUUID()]))
        .rejects.toMatchObject({code:'23514',constraint:'duel_wagers_unmatched_refund'});
    } finally {
      try { await client.query('ROLLBACK'); } finally { client.release(); }
    }
  });

  it('rejects foreign or bot winners in a human match and keeps a real bot win payable', async () => {
    await pool.query('INSERT INTO users(id,coins) VALUES (113,100),(114,100),(115,100)');
    const a=randomUUID(), b=randomUUID(), m=randomUUID();
    expect(await wallet.reserve(a,113,10)).toBe(true);
    expect(await wallet.reserve(b,114,10)).toBe(true);
    expect(await wallet.start(m,[a,b],10)).toBe(true);
    for (const winner of [115, null, 99999]) expect(await wallet.settlePayouts(m,'win',winner)).toEqual([]);
    expect(await wallet.receipt(m,113)).toEqual({wager:10,payout:null});
    expect(await wallet.receipt(m,114)).toEqual({wager:10,payout:null});
    expect(await wallet.settle(m,'win',114)).toBe(true);
    const solo=randomUUID(), botMatch=randomUUID();
    expect(await wallet.reserve(solo,113,5)).toBe(true);
    expect(await wallet.start(botMatch,[solo],5)).toBe(true);
    expect(await wallet.settlePayouts(botMatch,'win',115)).toEqual([]);
    expect(await wallet.settlePayouts(botMatch,'win',null)).toEqual([{user_id:113,payout:0}]);
  });

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
    const balances = await pool.query('SELECT coins FROM users WHERE id IN (1,2) ORDER BY id');
    expect(balances.rows.map(row => row.coins)).toEqual(payouts.map(amount => 75 + amount));
  }, 20000);

  it('refunds other expired holds while one is locked, then refunds the deferred hold exactly once', async () => {
    await pool.query('INSERT INTO users(id, coins) VALUES (101,100), (102,100)');
    const ids = [randomUUID(), randomUUID()];
    for (const [i,id] of ids.entries()) await wallet.reserve(id, 101+i, 5);
    await pool.query("UPDATE duel_wagers SET expires_at = now() - interval '1 second' WHERE id = ANY($1::uuid[])", [ids]);
    const lock = await pool.connect();
    const worker = await pool.connect();
    const balances = async () => (await pool.query('SELECT coins FROM users WHERE id IN (101,102) ORDER BY id')).rows.map(r => r.coins);
    try {
      await lock.query('BEGIN');
      await lock.query('SELECT id FROM duel_wagers WHERE id=$1 FOR UPDATE', [ids[0]]);
      await worker.query("SET statement_timeout TO '750ms'");
      db.query.mockImplementationOnce((...args) => worker.query(...args));
      expect(await wallet.recoverExpired()).toBe(true);
      expect(await balances()).toEqual([95,100]);
    } finally {
      await lock.query('ROLLBACK');
      lock.release();
      await worker.query('RESET statement_timeout');
      worker.release();
    }
    expect(await wallet.recoverExpired()).toBe(true);
    expect(await wallet.recoverExpired()).toBe(false);
    expect(await balances()).toEqual([100,100]);
  });


  it('preserves both a quiz reward and a duel payout contending for the same balance', async () => {
    const economy = require('../../src/services/economyService');
    const { withTransaction } = require('../../src/utils/dbHelpers');
    const userId = 211;
    const hold = randomUUID();
    const match = randomUUID();
    await pool.query('INSERT INTO users(id,coins) VALUES ($1,100)', [userId]);
    expect(await wallet.reserve(hold, userId, 5)).toBe(true);
    expect(await wallet.start(match, [hold], 5)).toBe(true);
    const [reward, payout] = await race('SELECT id FROM users WHERE id=$1 FOR UPDATE', [userId], [
      () => withTransaction(client => economy.processQuizCoinReward(client, userId)),
      () => wallet.settlePayouts(match, 'win', userId),
    ]);
    expect(reward).toBe(1);
    expect(payout).toEqual([{user_id:userId, payout:10}]);
    const { rows } = await pool.query('SELECT coins,daily_coins_earned FROM users WHERE id=$1', [userId]);
    expect(rows[0]).toEqual({coins:106, daily_coins_earned:1});
  });

  it('returns exactly the rows credited after an account is removed mid-match', async () => {
    await pool.query('INSERT INTO users(id,coins) VALUES (103,100),(104,100)');
    const a=randomUUID(), b=randomUUID(), match=randomUUID();
    await wallet.reserve(a,103,5); await wallet.reserve(b,104,5);
    await wallet.start(match,[a,b],5);
    await pool.query('DELETE FROM users WHERE id=104');
    expect(await wallet.settlePayouts(match,'win',104)).toEqual([{user_id:103,payout:0}]);
    expect(await wallet.settlePayouts(match,'win',104)).toEqual([]);
  });

});
