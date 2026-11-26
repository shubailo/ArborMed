// Set DUEL_TEST_DATABASE_URL to exercise PostgreSQL locking and ledger semantics.
// All database objects belong to this test connection's temporary schema.
const { readFileSync } = require('fs');
const { join } = require('path');
const { randomUUID } = require('crypto');
const { Client } = require('pg');
jest.mock('../../src/config/db', () => ({query: jest.fn(), pool: {connect: jest.fn()}}));
const db = require('../../src/config/db');
const wallet = require('../../src/services/walletService');
const economy = require('../../src/services/economyService');
const { withTransaction } = require('../../src/utils/dbHelpers');

const run = process.env.DUEL_TEST_DATABASE_URL ? describe : describe.skip;
run('duel ledger and daily reward transactions', () => {
  let pg;
  const profile = async userId => (await pg.query('SELECT coins FROM users WHERE id=$1', [userId])).rows[0].coins;
  beforeAll(async () => {
    pg = new Client({connectionString: process.env.DUEL_TEST_DATABASE_URL});
    await pg.connect();
    await pg.query(`CREATE TEMP TABLE users(id int PRIMARY KEY, coins int, last_activity_at timestamptz);
      SET search_path = pg_temp;
      CREATE TEMP TABLE room_likes(liker_id int, receiver_id int);
      CREATE TEMP TABLE responses(id serial, user_id int, session_id int, question_id int, is_correct boolean, created_at timestamptz DEFAULT NOW());
      CREATE TEMP TABLE quiz_sessions(id int, user_id int, started_at timestamptz DEFAULT NOW(), completed_at timestamptz);
      CREATE TEMP TABLE user_claimed_quests(user_id int, quest_id text, claimed_at timestamptz DEFAULT NOW(),
        PRIMARY KEY(user_id, quest_id));`);
    const migration = readFileSync(join(__dirname, '../../migrations/061_duel_wagers.sql'), 'utf8');
    await pg.query(migration);
    db.query.mockImplementation((...args) => pg.query(...args));
    db.pool.connect.mockResolvedValue({query: (...args) => pg.query(...args), release() {}});
  });
  afterAll(async () => { await pg?.end(); });
  beforeEach(async () => {
    await pg.query('TRUNCATE duel_wagers, users, responses, quiz_sessions, user_claimed_quests');
    await pg.query('INSERT INTO users VALUES (1, 100), (2, 100)');
  });

  it('records the joining player and leaves the activity time alone during automated recovery', async () => {
    const id = randomUUID();
    await wallet.reserve(id, 1, 10);
    const timestamps = async () => (await pg.query('SELECT last_activity_at FROM users ORDER BY id')).rows;
    const joined = await timestamps();
    expect(joined).toEqual([{last_activity_at:expect.any(Date)},{last_activity_at:null}]);
    await pg.query("UPDATE duel_wagers SET expires_at=now()-interval '1 minute' WHERE id=$1", [id]);
    await wallet.recoverExpired();
    expect(await timestamps()).toEqual(joined);
  });

  it('pays the winner once and keeps the durable settlement', async () => {
    const a=randomUUID(), b=randomUUID(), m=randomUUID();
    expect(await wallet.reserve(a, 1, 25)).toBe(true);
    expect(await wallet.reserve(randomUUID(), 1, 25)).toBe(false);
    expect(await wallet.reserve(b, 2, 25)).toBe(true);
    expect(await wallet.start(m, [a,b], 25)).toBe(true);
    expect(await wallet.cancel(a)).toBe(false);
    expect(await wallet.settle(m, 'win', 2)).toBe(true);
    expect(await wallet.settle(m, 'draw')).toBe(false);
    expect(await profile(1)).toBe(75);
    expect(await profile(2)).toBe(125);
    expect((await pg.query('SELECT payout FROM duel_wagers ORDER BY user_id')).rows).toEqual([{payout:0},{payout:50}]);
  });
  it('cancels only a matching unannounced game and makes settled payouts readable to their owner', async () => {
    const a=randomUUID(), b=randomUUID(), match=randomUUID();
    await wallet.reserve(a,1,25);
    await wallet.reserve(b,2,25);
    await wallet.start(match,[a,b],25);
    expect(await wallet.cancel(a,randomUUID())).toBe(false);
    expect(await wallet.receipt(match,1)).toEqual({wager:25,payout:null});
    expect(await wallet.receipt(match,3)).toBeUndefined();
    expect(await wallet.cancel(a,match)).toBe(true);
    expect(await wallet.cancel(b,match)).toBe(true);
    expect(await wallet.cancel(b,match)).toBe(false);
    expect(await wallet.receipt(match,1)).toEqual({wager:25,payout:25});
    expect(await profile(1)).toBe(100);
    expect(await profile(2)).toBe(100);
  });

  it('refunds abandoned matches and queue slots without double credit', async () => {
    const a=randomUUID(), b=randomUUID();
    await wallet.reserve(a, 1, 100);
    await wallet.start(randomUUID(), [a], 100);
    await wallet.reserve(b, 2, 100);
    await pg.query("UPDATE duel_wagers SET expires_at = NOW() - INTERVAL '1 minute'");
    expect(await wallet.recoverExpired()).toBe(true);
    expect(await wallet.recoverExpired()).toBe(false);
    expect(await wallet.cancel(b)).toBe(false);
    expect(await profile(1)).toBe(100);
    expect(await profile(2)).toBe(100);
  });
  it('rolls back unfunded holds and partially matched wagers', async () => {
    await pg.query('UPDATE users SET coins=4 WHERE id=2');
    expect(await wallet.reserve(randomUUID(),2,5)).toBe(false);
    const a=randomUUID(); await wallet.reserve(a,1,5);
    expect(await wallet.start(randomUUID(), [a,randomUUID()], 5)).toBe(false);
    expect(await wallet.cancel(a)).toBe(true);
    expect(await profile(1)).toBe(100);
    expect((await pg.query('SELECT FROM duel_wagers WHERE user_id=2')).rows).toHaveLength(0);
  });
  it('daily quests exclude tomorrow’s responses, sessions and legacy claims at the UTC boundary', async () => {
    await pg.query('BEGIN');
    try {
      await pg.query("SET LOCAL TIME ZONE 'Pacific/Kiritimati'");
      const boundary = "((now() AT TIME ZONE 'UTC')::date + 1)::timestamp AT TIME ZONE 'UTC'";
      await pg.query(`INSERT INTO quiz_sessions(id,user_id,started_at) VALUES (1,1,${boundary}), (2,1,now());
        INSERT INTO responses(user_id,session_id,question_id,is_correct,created_at)
          VALUES (1,1,7,true,now()), (1,2,8,true,${boundary});
        INSERT INTO user_claimed_quests VALUES (1,'daily_1_1700000000000',${boundary})`);
      const { quests } = await economy.dailyProgress(pg, 1);
      expect(quests.map(q => [q.currentCount, q.status])).toEqual([[1,'active'],[1,'active'],[0,'active']]);
    } finally {
      await pg.query('ROLLBACK');
    }
  });

  it('verifies quest completion and credits a daily event only once', async () => {
    const claim = (id, quest) => withTransaction(client => economy.processQuestClaim(client, id, quest));
    await expect(claim(1,'daily_2')).rejects.toMatchObject({statusCode:409});
    await pg.query('INSERT INTO responses(user_id, question_id, is_correct) SELECT 1,1,true FROM generate_series(1,10)');
    await expect(claim(1,'daily_1')).rejects.toMatchObject({statusCode:409});
    await pg.query('INSERT INTO responses(user_id, question_id, is_correct) SELECT 1,n,true FROM generate_series(2,10) n');
    await claim(1,'daily_1');
    await claim(1,'daily_1_1000000000000');
    await claim(1,'daily_2');
    expect(await profile(1)).toBe(130);
    await expect(claim(2,'daily_1')).rejects.toMatchObject({statusCode:409});
  });

  it('returns the credited amount exactly once and binds new clients to the displayed UTC day', async () => {
    const controller = require('../../src/controllers/questController');
    await pg.query('INSERT INTO responses(user_id,question_id,is_correct) SELECT 1,n,true FROM generate_series(1,5) n');
    const {date} = await economy.dailyProgress(pg, 1);
    const claim = async body => {
      const res = {json: jest.fn()};
      await controller.claimQuest({user:{id:1},body}, res, error => {throw error;});
      return res.json.mock.calls[0][0];
    };
    await expect(claim({questId:'daily_2',date:'2000-01-01'})).rejects.toMatchObject({statusCode:409});
    expect(await profile(1)).toBe(100);
    expect(await claim({questId:'daily_2',date})).toMatchObject({date,awardedTokens:20,newBalance:120});
    expect(await claim({questId:'daily_2'})).toMatchObject({date,awardedTokens:0,newBalance:120});
    expect((await pg.query('SELECT count(*)::int AS count FROM user_claimed_quests')).rows[0].count).toBe(1);
  });

  it('counts legacy session-owned progress while respecting explicit response ownership', async () => {
    await pg.query(`INSERT INTO quiz_sessions(id,user_id) VALUES(10,1),(20,2);
      INSERT INTO responses(session_id,question_id,is_correct) SELECT 10,n,true FROM generate_series(1,5) n;
      INSERT INTO responses(user_id,session_id,question_id,is_correct) VALUES(2,10,6,true),(NULL,20,7,false)`);
    const counts = async id => (await economy.dailyProgress(pg,id)).quests.map(q => q.currentCount);
    expect(await counts(1)).toEqual([5,5,5]);
    expect(await counts(2)).toEqual([2,1,0]);
  });

  it('offers a perfect round after five different first answers in one owned session', async () => {
    await pg.query("INSERT INTO quiz_sessions(id,user_id) VALUES (1,1),(2,1),(3,2)");
    await pg.query(`INSERT INTO responses(user_id, session_id, question_id, is_correct)
      SELECT 1,1,n,n<>1 FROM generate_series(1,6) n
      UNION ALL SELECT 1,2,n,true FROM generate_series(1,4) n
      UNION ALL SELECT 1,3,n,true FROM generate_series(1,5) n`);
    const perfect = async () => (await economy.dailyProgress(pg, 1)).quests.find(q => q.id === 'daily_3');
    expect(await perfect()).toMatchObject({currentCount:4,status:'active'});
    await pg.query("INSERT INTO responses(user_id,session_id,question_id,is_correct) VALUES (1,2,5,true),(1,2,6,false)");
    expect(await perfect()).toMatchObject({currentCount:5,status:'completed'});
    await withTransaction(client => economy.processQuestClaim(client,1,'daily_3'));
    expect(await perfect()).toMatchObject({status:'claimed'});
    expect(await profile(1)).toBe(130);
  });
});
