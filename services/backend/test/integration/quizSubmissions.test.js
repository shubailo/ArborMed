const { randomUUID } = require('node:crypto');
const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const { Pool } = require('pg');
const db = require('../../src/config/db');
const { submitAnswer, getNextQuestion, getTopics } = require('../../src/controllers/quizController');

// Only the explicitly supplied test connection is used; the production config
// (including its dotenv initialization) is never loaded.
jest.mock('../../src/config/db', () => ({ query: jest.fn(), pool: { connect: jest.fn() } }));
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
    db.query.mockImplementation((sql, params) => pool.query(sql, params));
    db.pool.connect.mockImplementation(async () => {
      const client = await pool.connect();
      connections.add(client.processID);
      return client;
    });
    await pool.query(`
      CREATE TABLE users (id int PRIMARY KEY, coins int DEFAULT 0, daily_coins_earned int DEFAULT 0,
        daily_coins_softcap_progress int DEFAULT 0, last_coin_reset_date date);
      CREATE TABLE topics (id int PRIMARY KEY, slug text, parent_id int, nexus_metadata jsonb, name_en text, name_hu text);
      CREATE TABLE questions (id int PRIMARY KEY, topic_id int, question_type text, correct_answer text,
        options jsonb, metadata jsonb, bloom_level int, active boolean DEFAULT true);
      CREATE TABLE quiz_sessions (id int PRIMARY KEY, user_id int REFERENCES users, started_at timestamptz DEFAULT now());
      CREATE TABLE user_claimed_quests (user_id int REFERENCES users, quest_id text, claimed_at timestamptz DEFAULT now(),
        PRIMARY KEY (user_id, quest_id));
      CREATE TABLE user_question_progress (user_id int, question_id int, easiness_factor decimal, interval_days int,
        repetition_count int, next_review_at timestamptz, mastered boolean, PRIMARY KEY(user_id,question_id));
      CREATE TABLE user_topic_progress (user_id int, topic_slug text, current_bloom_level int, current_streak int,
        consecutive_wrong int, level_correct_count int, mastery_score int, total_answered int, correct_answered int,
        last_studied_at timestamptz, stability float, retention_score float, PRIMARY KEY(user_id,topic_slug));
      CREATE TABLE responses (id serial PRIMARY KEY, user_id int, question_id int, session_id int, user_answer text,
        is_correct boolean, response_time_ms int, quality int, selection_reason text, easiness_factor decimal, interval_days int, created_at timestamptz DEFAULT NOW());
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
    await pool.query('DELETE FROM questions WHERE id >= 100; DELETE FROM topics WHERE id >= 100');
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

  test('a rejected quest credit leaves no claim; concurrent retries return one credit and one replay', async () => {
    const controller = require('../../src/controllers/questController');
    const claim = async () => {
      const res = {json: jest.fn()};
      await controller.claimQuest({user:{id:1},body:{questId:'daily_2'}}, res, err => {throw err;});
      return res.json.mock.calls[0][0];
    };
    await pool.query(`INSERT INTO responses(user_id,question_id,is_correct) SELECT 1,n,true FROM generate_series(1,5) n;
      ALTER TABLE users ADD CONSTRAINT test_quest_credit CHECK(coins=0)`);
    try {
      await expect(claim()).rejects.toMatchObject({code:'23514'});
      expect((await pool.query('SELECT * FROM user_claimed_quests')).rowCount).toBe(0);
    } finally {
      await pool.query('ALTER TABLE users DROP CONSTRAINT test_quest_credit');
    }
    const receipts = await Promise.all([claim(), claim()]);
    expect(receipts.map(r => r.awardedTokens).sort((a,b) => a-b)).toEqual([0,20]);
    expect(receipts.map(r => r.newBalance)).toEqual([20,20]);
    expect((await pool.query('SELECT * FROM user_claimed_quests')).rowCount).toBe(1);
  });

  test('an explicit unsupported type cannot create a receipt, progress or reward', async () => {
    for (const type of ['', 'future_type']) {
      await pool.query(
        `INSERT INTO questions (id, topic_id, question_type, correct_answer, options, bloom_level)
         SELECT 107, topic_id, $1, correct_answer, options, bloom_level FROM questions WHERE id = 7
         ON CONFLICT (id) DO UPDATE SET question_type = EXCLUDED.question_type`, [type]
      );
      await expect(submit(attempt(107))).rejects.toMatchObject({statusCode: 422});
      expect(await counts()).toEqual({coins: 0, answers: 0, activity: 0, progress: 0});
    }
  });

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

  test('a newer failure with no usable prerequisite does not hide an older actionable one', async () => {
    await addSubject();
    await pool.query(`UPDATE questions SET bloom_level=3, metadata='{"prerequisite_ids":["junk"," 000101 ","999999999999999999999"]}' WHERE id=102;
      UPDATE questions SET bloom_level=4, metadata='{"prerequisite_ids":[8]}' WHERE id=103;
      INSERT INTO responses(user_id,question_id,is_correct) VALUES (1,102,false),(1,103,false)`);
    expect(await nextQuestion('subject', '8')).toMatchObject({id:101, selectionReason:'FAIL_DOWN_PREREQ_102'});
    expect(await nextQuestion('subject')).toMatchObject({id:8, selectionReason:'FAIL_DOWN_PREREQ_103'});
    await pool.query('UPDATE questions SET metadata=$1 WHERE id=103', [{prerequisite_ids:false}]);
    await pool.query('UPDATE questions SET metadata=$1::jsonb WHERE id=102', ['{"prerequisite_ids":[101.0]}']);
    expect(await nextQuestion('subject')).toMatchObject({id:101, selectionReason:'FAIL_DOWN_PREREQ_102'});
    await pool.query('UPDATE questions SET metadata=$1 WHERE id=102', [{prerequisite_ids:['\t00101\n']}]);
    expect(await nextQuestion('subject')).toMatchObject({id:101, selectionReason:'FAIL_DOWN_PREREQ_102'});
  });

  test('mastery commits once with duplicate, retired and malformed Nexus links', async () => {
    await addSubject();
    await pool.query(`UPDATE questions SET active=false WHERE id=102;
      UPDATE topics SET nexus_metadata='{"nexus_links":[null,5,{"topic_slug":"sibling"},{"topic_slug":"sibling"},{"topic_slug":"missing"},{"topic_slug":"section"},{"topic_slug":"test"}]}' WHERE id=101;
      INSERT INTO user_topic_progress(user_id,topic_slug,current_bloom_level,mastery_score) VALUES (1,'test',3,65);
      INSERT INTO user_question_progress(user_id,question_id,easiness_factor,interval_days,repetition_count)
        VALUES(1,101,2.5,6,2)`);
    const body = {...attempt(101), userAnswer:'Red'};
    const receipt = await submit(body);
    expect(receipt).toMatchObject({isCorrect:true, mastery:100, coinsEarned:1});
    expect(await submit(body)).toEqual(receipt);
    const progress = await pool.query('SELECT topic_slug,current_bloom_level FROM user_topic_progress ORDER BY topic_slug');
    expect(progress.rows).toEqual([
      {topic_slug:'section',current_bloom_level:1}, {topic_slug:'sibling',current_bloom_level:2}, {topic_slug:'test',current_bloom_level:3},
    ]);
  });

  test('a late compatibility-adapter error rolls back the SRS row and retry advances it once', async () => {
    const adapter = require('../../src/services/adaptiveEngine');
    const answer = () => adapter.processAnswerResult(1, 'test', true, 7);
    await pool.query('ALTER TABLE user_topic_progress ADD CONSTRAINT reject_progress CHECK (false) NOT VALID');
    try {
      await expect(answer()).rejects.toMatchObject({code:'23514'});
      expect((await pool.query('SELECT * FROM user_question_progress')).rows).toEqual([]);
    } finally {
      await pool.query('ALTER TABLE user_topic_progress DROP CONSTRAINT reject_progress');
    }
    await answer();
    expect((await pool.query('SELECT repetition_count FROM user_question_progress')).rows).toEqual([{repetition_count:1}]);
  });

  test.each([
    ['day', [4], 24], ['week', [3, 4], 7], ['month', [2, 3, 4, 5, 6], 30],
  ])('the %s activity buckets and mistake IDs cover the same calendar period and owner', async (timeframe, ids, buckets) => {
    const stats = require('../../src/controllers/statsController');
    await pool.query(`INSERT INTO responses(user_id,question_id,session_id,is_correct,created_at) VALUES
      (1,1,NULL,false,'2026-10-31 23:59'), (1,2,NULL,false,'2026-11-08 23:59'),
      (NULL,3,10,false,'2026-11-09'), (1,4,NULL,false,'2026-11-15 23:59'),
      (1,5,NULL,false,'2026-11-16'), (1,6,NULL,false,'2026-11-30 23:59'),
      (1,7,NULL,false,'2026-12-01'), (2,8,10,false,'2026-11-15')`);
    const req = { user: { id: 1 }, query: { timeframe, anchorDate: '2026-11-15' } };
    const read = async handler => {
      const res = { json: jest.fn() };
      await handler(req, res, err => { throw err; });
      return res.json.mock.calls[0][0];
    };
    expect(await read(stats.getMistakesByTimeframe)).toEqual(ids);
    const rows = await read(stats.getActivity);
    expect(rows).toHaveLength(buckets);
    expect(rows.reduce((sum, row) => sum + row.count, 0)).toBe(ids.length);
    expect(rows.find(row => row.calendar_date === '2026-11-15')).toBeDefined();
  });

  test('readiness omits seeded topics and retains legacy sections with recorded study', async () => {
    const stats = require('../../src/controllers/statsController');
    await addSubject();
    await pool.query(`INSERT INTO user_topic_progress(user_id,topic_slug,current_bloom_level,last_studied_at)
      VALUES(1,'sibling',2,now()),(1,'section',1,now());
      INSERT INTO responses(user_id,question_id,is_correct) VALUES(2,103,true),(1,101,false);`);
    let result;
    await stats.getReadiness({user:{id:1}}, {json: value => {result=value;}}, err => {throw err;});
    expect(result.breakdown.map(row => row.slug)).toEqual(['section']);
    await pool.query("UPDATE user_topic_progress SET total_answered=1 WHERE topic_slug='sibling'");
    await stats.getReadiness({user:{id:1}}, {json: value => {result=value;}}, err => {throw err;});
    expect(result.breakdown.map(row => row.slug).sort()).toEqual(['section','sibling']);
  });

  test('the soft cap uses the exact UTC day recorded by the locked credit operation', async () => {
    const economy = require('../../src/services/economyService');
    const { day } = (await pool.query("SELECT ((now() AT TIME ZONE 'UTC')::date + 1)::text AS day")).rows[0];
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query('UPDATE users SET last_coin_reset_date=$1, daily_coins_earned=50, daily_coins_softcap_progress=3 WHERE id=1', [day]);
      expect(await economy.processQuizCoinReward(client, 1, day)).toBe(0);
      expect(await economy.processQuizCoinReward(client, 1, day)).toBe(1);
      const state = (await client.query('SELECT last_coin_reset_date::text AS day,daily_coins_earned,coins FROM users WHERE id=1')).rows[0];
      expect(state).toEqual({day, daily_coins_earned:51, coins:1});
    } finally {
      await client.query('ROLLBACK');
      client.release();
    }
  });

  async function nextQuestion(topic, exclude = '') {
    let question, error;
    await getNextQuestion({user:{id:1}, query:{topic, exclude}}, {json: value => { question = value; }}, err => { error = err; });
    if (error) throw error;
    return question;
  }

  async function addSubject() {
    await pool.query(`INSERT INTO topics(id,slug,parent_id) VALUES (100,'subject',NULL),(101,'section',100),(102,'sibling',100);
      INSERT INTO questions(id,topic_id,question_type,correct_answer,options,bloom_level) VALUES
        (101,101,'single_choice','Red','["Red","Blue"]',1), (102,101,'single_choice','Red','["Red","Blue"]',2),
        (103,102,'single_choice','Red','["Red","Blue"]',1);`);
  }

  test('subject practice selects, reports and reviews at each question’s own section level', async () => {
    await addSubject();
    await pool.query("INSERT INTO user_topic_progress(user_id,topic_slug,current_bloom_level,level_correct_count) VALUES (1,'section',1,19)");
    const receipt = await submit({...attempt(101), userAnswer:'Red'});
    expect(receipt).toMatchObject({topicSlug:'section', currentBloom:2});
    expect(await nextQuestion('subject','103')).toMatchObject({id:102,topic_slug:'section',currentBloom:2,selectionReason:'BLOOM_CLIMBER_LEVEL_2'});
    expect(await nextQuestion('subject','102')).toMatchObject({id:103,topic_slug:'sibling',currentBloom:1});
    await pool.query("UPDATE user_question_progress SET next_review_at=NOW() - INTERVAL '1 day' WHERE question_id=101");
    expect(await nextQuestion('subject')).toMatchObject({id:101,currentBloom:2,selectionReason:'SRS_REVIEW'});
    let topics;
    await getTopics({}, {json: rows => {topics = rows;}}, err => { throw err; });
    expect(Number(topics.find(row => row.slug === 'subject').question_count)).toBe(3);
  });

  test('a first-time linked section starts at its Nexus level and empty topics create no student history', async () => {
    await addSubject();
    await pool.query(`UPDATE topics SET nexus_metadata='{"nexus_links":[{"topic_slug":"test"}]}' WHERE id=101;
      INSERT INTO user_topic_progress(user_id,topic_slug,mastery_score) VALUES(1,'test',80);`);
    expect(await nextQuestion('subject','103')).toMatchObject({id:102,topic_slug:'section',currentBloom:2});
    await expect(nextQuestion('missing')).rejects.toMatchObject({statusCode:404});
    expect((await pool.query("SELECT * FROM user_topic_progress WHERE topic_slug IN ('missing','subject')")).rowCount).toBe(0);
  });

  test('a corrected clinical question stops triggering its prerequisite and old nonnumeric links do not break selection', async () => {
    await addSubject();
    await pool.query(`UPDATE questions SET bloom_level=3, metadata='{"prerequisite_ids":["legacy-key",101]}' WHERE id=102;
      INSERT INTO responses(user_id,question_id,is_correct) VALUES (1,102,false);`);
    expect(await nextQuestion('subject')).toMatchObject({id:101,topic_slug:'section',selectionReason:'FAIL_DOWN_PREREQ_102'});
    await pool.query('INSERT INTO responses(user_id,question_id,is_correct) VALUES (1,102,true)');
    expect(await nextQuestion('subject','103')).toMatchObject({id:101,selectionReason:'BLOOM_CLIMBER_LEVEL_1'});
  });

  test('a legacy zero interval and saturated repetition count can receive a durable quiz receipt', async () => {
    await pool.query(`INSERT INTO user_question_progress
      (user_id,question_id,easiness_factor,interval_days,repetition_count)
      VALUES (1,7,2.5,0,2147483647)`);
    const body = attempt(7);
    const receipt = await submit(body);
    expect(receipt).toMatchObject({isCorrect:true});
    expect(await submit(body)).toEqual(receipt);
    const saved = await pool.query(`SELECT repetition_count,interval_days,next_review_at > now() AS scheduled
      FROM user_question_progress WHERE user_id=1 AND question_id=7`);
    expect(saved.rows).toEqual([{repetition_count:2147483647, interval_days:1, scheduled:true}]);
  });

  test('a long run of correct practice remains schedulable and a lapse still resets the review', async () => {
    const previous = {interval:70_000_000, repetition:19};
    await pool.query('INSERT INTO user_question_progress(user_id,question_id,easiness_factor,interval_days,repetition_count) VALUES (1,7,4,$1,$2)',
      [previous.interval, previous.repetition]);
    const payload = attempt(7);
    const receipt = await submit(payload);
    expect(receipt).toMatchObject({isCorrect:true});
    expect(await submit(payload)).toEqual(receipt);
    const {next_review_at: due, interval_days: interval} = (await pool.query('SELECT * FROM user_question_progress WHERE question_id=7')).rows[0];
    expect(Number.isFinite(due.valueOf())).toBe(true);
    expect(interval).toBe(receipt.adaptive.srs.interval);
    expect((await submit({...attempt(7), userAnswer:'Blue'})).adaptive.srs.interval).toBe(1);
  });

  test.each([true,false])('reordered checkbox selections replay the same attempt (UUID=%s)', async (useUuid) => {
    await addSubject();
    await pool.query(`UPDATE questions SET question_type='multiple_choice', correct_answer='["Red","Blue"]' WHERE id=101`);
    const body = {...attempt(101), userAnswer:['Red','Blue']};
    if (!useUuid) delete body.submissionId;
    const first = await submit(body);
    expect(first.isCorrect).toBe(true);
    expect(await submit({...body, userAnswer:['Blue','Red']})).toEqual(first);
    const saved = (await pool.query('SELECT quality FROM responses WHERE question_id=101')).rows;
    expect(saved).toEqual([{quality:first.adaptive.quality}]);
    if (useUuid) await expect(submit({...body,userAnswer:['Red','Red']})).rejects.toMatchObject({statusCode:409});
  });

  test('legacy numeric and text session IDs replay one submission and one reward', async () => {
    const body = {sessionId: 10, questionId: 7, userAnswer: 'Piros'};
    const first = await submit(body);
    expect(await submit({...body, sessionId: '10'})).toEqual(first);
    expect(await counts()).toEqual({coins: 1, answers: 1, activity: 1, progress: 1});
  });

  test('numeric retries recognize a historical receipt hashed with the text session ID', async () => {
    const body = {sessionId: 10, questionId: 7, userAnswer: 'Piros'};
    const first = await submit(body);
    const hex = require('node:crypto').createHash('sha256')
      .update(JSON.stringify([1, '10', 7, 'Piros'])).digest('hex');
    const historicalId = [hex.slice(0,8), hex.slice(8,12), hex.slice(12,16), hex.slice(16,20), hex.slice(20,32)].join('-');
    const receipt = {...first, submissionId: historicalId};
    await pool.query('UPDATE responses SET submission_id=$1, submission_result=$2', [historicalId, JSON.stringify(receipt)]);
    expect(await submit(body)).toEqual(receipt);
    expect(await counts()).toEqual({coins: 1, answers: 1, activity: 1, progress: 1});
  });

  test('a modern retry cannot attribute a saved receipt to a different study session', async () => {
    const first = attempt();
    await submit(first);
    await expect(submit({...first, sessionId: null})).rejects.toMatchObject({statusCode: 409});
    expect(await counts()).toEqual({coins: 1, answers: 1, activity: 1, progress: 1});
  });

  test('installed clients can replay a submission without a UUID', async () => {
    const legacy = {sessionId: 'local_123', questionId: 7, userAnswer: 'Piros'};
    expect(await submit(legacy)).toEqual(await submit(legacy));
    expect(await counts()).toEqual({ coins: 1, answers: 1, activity: 1, progress: 1 });
  });
});
