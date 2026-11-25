const { randomUUID } = require('node:crypto');
const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const { Pool } = require('pg');
const db = require('../../src/config/db');
const { submitAnswer } = require('../../src/controllers/quizController');

// Only the explicitly supplied test connection is used; the production config
// (including its dotenv initialization) is never loaded.
jest.mock('../../src/config/db', () => ({ pool: { connect: jest.fn() } }));
const integration = process.env.TEST_DATABASE_URL ? describe : describe.skip;

integration('PostgreSQL quiz receipts and rewards', () => {
  const schema = 'quiz_test_' + randomUUID().replaceAll('-', '');
  let pool;
  const connections = new Set();

  beforeAll(async () => {
    pool = new Pool({
      connectionString: process.env.TEST_DATABASE_URL,
      options: `-c search_path=${schema} -c timezone=Pacific/Kiritimati`,
      max: 8,
    });
    await pool.query(`CREATE SCHEMA ${schema}`);
    db.pool.connect.mockImplementation(async () => {
      const client = await pool.connect();
      connections.add(client.processID);
      return client;
    });
    await pool.query(`
      CREATE TABLE users (id int PRIMARY KEY, coins int DEFAULT 0, daily_coins_earned int DEFAULT 0,
        daily_coins_softcap_progress int DEFAULT 0, last_coin_reset_date date);
      CREATE TABLE topics (id int PRIMARY KEY, slug text, parent_id int, nexus_metadata jsonb);
      CREATE TABLE questions (id int PRIMARY KEY, topic_id int, question_type text, correct_answer text,
        options jsonb, bloom_level int, active boolean DEFAULT true);
      CREATE TABLE quiz_sessions (id int PRIMARY KEY, user_id int REFERENCES users);
      CREATE TABLE user_question_progress (user_id int, question_id int, easiness_factor decimal, interval_days int,
        repetition_count int, next_review_at timestamptz, mastered boolean, PRIMARY KEY(user_id,question_id));
      CREATE TABLE user_topic_progress (user_id int, topic_slug text, current_bloom_level int, current_streak int,
        consecutive_wrong int, level_correct_count int, mastery_score int, total_answered int, correct_answered int,
        last_studied_at timestamptz, PRIMARY KEY(user_id,topic_slug));
      CREATE TABLE responses (id serial PRIMARY KEY, user_id int, question_id int, session_id int, user_answer text,
        is_correct boolean, response_time_ms int, quality int, selection_reason text, easiness_factor decimal, interval_days int);
      CREATE TABLE user_activity (user_id int, action text, metadata jsonb);
      INSERT INTO users(id) VALUES (1), (2);
      INSERT INTO quiz_sessions VALUES (10,1);
      INSERT INTO topics(id,slug) VALUES (1,'test');
      INSERT INTO questions(id,topic_id,question_type,correct_answer,options,bloom_level) VALUES
        (7,1,'single_choice','Red','{"en":["Red","Blue"],"hu":["Piros","Kék"]}',1),
        (8,1,'single_choice','Red','{"en":["Red","Blue"],"hu":["Piros","Kék"]}',1);`);
    // The production grants explicitly qualify public.responses. Scope the same
    // statements to our disposable fixture, including sequence lookup.
    const migration = readFileSync(resolve(__dirname, '../../migrations/062_quiz_submissions.sql'), 'utf8')
      .replaceAll('public.responses', schema + '.responses');
    await pool.query(migration);
    await pool.query(migration);
  });

  afterAll(async () => {
    if (pool) {
      try { await pool.query(`DROP SCHEMA IF EXISTS ${schema} CASCADE`); }
      finally { await pool.end(); }
    }
  });

  beforeEach(async () => {
    await pool.query(`TRUNCATE responses, user_activity, user_topic_progress, user_question_progress;
      UPDATE users SET coins=0, daily_coins_earned=0, daily_coins_softcap_progress=0, last_coin_reset_date=NULL`);
    connections.clear();
  });

  const attempt = (questionId = 7) => ({ submissionId: randomUUID(), sessionId: 10, questionId,
    userAnswer: 'Piros', responseTimeMs: 2000 });
  const submit = async (body, userId = 1) => {
    let result, failure;
    await submitAnswer({ body, user: { id: userId } }, {
      json: receipt => { result = JSON.parse(JSON.stringify(receipt)); },
    }, err => { failure = err; });
    if (failure) throw failure;
    return result;
  };
  const counts = async () => (await pool.query(`
    SELECT coins, (SELECT count(*)::int FROM responses) AS answers,
      (SELECT count(*)::int FROM user_activity) AS activity,
      COALESCE((SELECT total_answered FROM user_topic_progress WHERE user_id=1),0) AS progress
    FROM users WHERE id=1`)).rows[0];

  test('concurrent retries replay one receipt, fresh attempts update progress and credit distinct questions', async () => {
    const first = attempt();
    const [a, replay, b] = await Promise.all([
      submit(first), submit(first), submit(attempt()), submit(attempt(8)),
    ]);
    expect(connections.size).toBeGreaterThan(1);
    expect(replay).toEqual(a);
    expect(a.isCorrect).toBe(true);
    expect(a.coinsEarned + b.coinsEarned).toBe(1);
    expect(await counts()).toEqual({ coins: 2, answers: 3, activity: 3, progress: 3 });
    const reset = await pool.query("SELECT last_coin_reset_date=(NOW() AT TIME ZONE 'UTC')::date AS ok FROM users WHERE id=1");
    expect(reset.rows[0].ok).toBe(true);
  });

  test('late database failure rolls every write back and the same attempt can succeed on retry', async () => {
    const payload = attempt();
    await pool.query('ALTER TABLE user_activity ADD CONSTRAINT reject_log CHECK (false) NOT VALID');
    try {
      await expect(submit(payload)).rejects.toMatchObject({ code: '23514' });
      expect(await counts()).toEqual({ coins: 0, answers: 0, activity: 0, progress: 0 });
      expect((await pool.query('SELECT * FROM user_question_progress')).rowCount).toBe(0);
    } finally {
      await pool.query('ALTER TABLE user_activity DROP CONSTRAINT reject_log');
    }
    const accepted = await submit(payload);
    expect(await submit(payload)).toEqual(accepted);
    expect(await counts()).toEqual({ coins: 1, answers: 1, activity: 1, progress: 1 });
    await expect(submit({...payload, userAnswer: 'Kék'})).rejects.toMatchObject({ statusCode: 409 });
    await expect(submit(payload, 2)).rejects.toMatchObject({ statusCode: 400 });
  });

  test('installed clients can replay a submission without a UUID', async () => {
    const legacy = {sessionId: 'local_123', questionId: 7, userAnswer: 'Piros'};
    expect(await submit(legacy)).toEqual(await submit(legacy));
    expect(await counts()).toEqual({ coins: 1, answers: 1, activity: 1, progress: 1 });
  });
});
