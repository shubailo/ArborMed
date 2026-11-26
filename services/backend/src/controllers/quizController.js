const db = require('../config/db');
const { isDeepStrictEqual } = require('node:util');
const { positiveId } = require('../utils/quizIds');
const { createHash } = require('node:crypto');
const pedagogicalEngine = require('../services/pedagogicalEngine');
const questionTypeRegistry = require('../services/questionTypes/registry');
const gradeableQuestion = require('../services/questionTypes/gradeableQuestion');
const translationService = require('../services/translationService');
const AppError = require('../utils/AppError');
const { secureShuffleArray } = require('../utils/cryptoUtils');
const catchAsync = require('../utils/catchAsync');
const { withTransaction } = require('../utils/dbHelpers');
const economyService = require('../services/economyService');

exports.startSession = catchAsync(async (req, res, _next) => {
  const userId = req.user.id;
  const result = await db.query(
    'INSERT INTO quiz_sessions (user_id) VALUES ($1) RETURNING *',
    [userId]
  );
  res.status(201).json(result.rows[0]);
});

exports.getNextQuestion = catchAsync(async (req, res, next) => {
  const userId = req.user.id;
  const topic = typeof req.query.topic === 'string' ? req.query.topic.trim() : '';
  const { exclude } = req.query;

  if (!topic) {
    return next(new AppError('Topic is required', 400));
  }

  const excludedIds = [].concat(exclude ?? []).filter(part => typeof part === 'string')
    .flatMap(part => part.split(',')).map(positiveId).filter(id => id !== null);
  let question;
  // Older databases can contain unusable keys. Preserve the engine ordering
  // and exclude each rejected candidate before selecting again.
  const seen = new Set(excludedIds);
  while (!question) {
    const candidate = await pedagogicalEngine.getChallenge(userId, topic, [...seen]);
    if (!candidate || seen.has(candidate.id)) break;
    seen.add(candidate.id);
    question = gradeableQuestion(candidate);
  }

  if (!question) {
    return next(
      new AppError('No more questions available for this topic', 404)
    );
  }

  const clientQuestion = questionTypeRegistry.prepareForClient(question);

  const qType = questionTypeRegistry.getType(question.question_type);
  const shouldShuffle = qType ? qType.shouldShuffleOptions : true;

  if (shouldShuffle) {
    if (clientQuestion.choice_options) secureShuffleArray(clientQuestion.choice_options);
    let opts = clientQuestion.options;
    if (typeof opts === 'string') {
      try {
        opts = JSON.parse(opts);
      } catch {
        /* keep as-is */
      }
    }
    if (Array.isArray(opts)) {
      clientQuestion.options = secureShuffleArray(opts);
    }
  }

  res.json({
    ...clientQuestion,
    selectionReason: question.selectionReason,
  });
});

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Installed clients predate UUIDs. Scope their retries to the same student,
// session, question and answer. Sessionless clients get a UTC-day scope.
function legacySubmissionId(userId, scope, questionId, answer) {
  const source = JSON.stringify([userId, scope, questionId,
    answer && typeof answer === 'object' && !Array.isArray(answer)
      ? Object.fromEntries(Object.entries(answer).sort(([a], [b]) => a.localeCompare(b))) : answer]);
  const hash = createHash('sha256').update(source).digest('hex');
  return [hash.slice(0,8), hash.slice(8,12), hash.slice(12,16), hash.slice(16,20), hash.slice(20,32)].join('-');
}

const isChoiceList = value => Array.isArray(value) && value.every(item => typeof item === 'string' || typeof item === 'number');

function sameSubmittedAnswer(first, second) {
  if (isChoiceList(first) && isChoiceList(second)) {
    // Checkbox order has no meaning. Retain types and duplicate counts.
    const ordered = values => values.map(item => JSON.stringify(item)).sort();
    return isDeepStrictEqual(ordered(first), ordered(second));
  }
  return isDeepStrictEqual(first, second);
}

exports.submitAnswer = catchAsync(async (req, res) => {
  const { sessionId, questionId, userAnswer, responseTimeMs, quality, selectionReason } = req.body;
  const userId = req.user.id;
  if (req.body.submissionUserId != null && req.body.submissionUserId !== userId) {
    throw new AppError('Submission belongs to another account', 403);
  }
  const id = positiveId(questionId);
  if (id === null) throw new AppError('Invalid question ID', 400);
  const legacy = req.body.submissionId === undefined;
  if (quality != null && (!Number.isInteger(quality) || quality < 0 || quality > 5)) {
    throw new AppError('Quality must be an integer between 0 and 5', 400);
  }
  if (userAnswer == null) throw new AppError('An answer is required', 400);
  const offline = sessionId == null || (typeof sessionId === 'string' && sessionId.startsWith('local_'));
  const session = offline ? null : positiveId(sessionId);
  if (!offline && session === null) throw new AppError('Invalid session ID', 400);

  // Older releases hashed the wire representation of sessionId. Recognize both
  // the numeric and canonical text form, as well as the submitted spelling.
  const scopes = legacy && session !== null
    ? [...new Set([session, String(session), sessionId])]
    : [sessionId ?? new Date().toISOString().slice(0, 10)];
  const receiptIds = legacy
    ? scopes.map(scope => legacySubmissionId(userId, scope, id, userAnswer))
    : [req.body.submissionId];
  const submissionId = receiptIds[0];
  if (typeof submissionId !== 'string' || !uuid.test(submissionId)) throw new AppError('A valid submission ID is required', 400);

  const result = await withTransaction(async client => {
    // Serialize all progress and reward changes for this student, including first-time rows.
    await client.query('SELECT id FROM users WHERE id = $1 FOR UPDATE', [userId]);
    const prior = await client.query(
      'SELECT question_id, session_id, submission_input, submission_result FROM responses WHERE user_id = $1 AND submission_id = ANY($2::uuid[]) ORDER BY id LIMIT 1',
      [userId, receiptIds]
    );
    if (prior.rows.length) {
      const saved = prior.rows[0];
      if ((saved.session_id ?? null) !== session || saved.question_id !== id || !sameSubmittedAnswer(saved.submission_input, userAnswer)) {
        throw new AppError('Submission ID already used for a different answer', 409);
      }
      return saved.submission_result;
    }
    if (legacy && isChoiceList(userAnswer) && userAnswer.length > 1) {
      // Installed clients derive the receipt ID from the original answer order.
      // Recognize old receipts without coalescing modern UUIDs or other sessions.
      const candidates = await client.query(
        `SELECT submission_id, submission_input, submission_result FROM responses
         WHERE user_id = $1 AND question_id = $2 AND session_id IS NOT DISTINCT FROM $3::int
           AND submission_input @> $4::jsonb AND submission_input <@ $4::jsonb`,
        [userId, id, session, JSON.stringify(userAnswer)]
      );
      const saved = candidates.rows.find(row => sameSubmittedAnswer(row.submission_input, userAnswer) &&
        scopes.some(scope => row.submission_id === legacySubmissionId(userId, scope, id, row.submission_input)));
      if (saved) return saved.submission_result;
    }
    if (session !== null) {
      const owned = await client.query('SELECT id FROM quiz_sessions WHERE id = $1 AND user_id = $2', [session, userId]);
      if (!owned.rows.length) throw new AppError('Invalid session ID', 400);
    }
    const qResult = await client.query(
      'SELECT q.*, t.slug AS topic_slug FROM questions q JOIN topics t ON q.topic_id = t.id WHERE q.id = $1', [id]
    );
    if (!qResult.rows.length) throw new AppError('Question not found', 404);
    const question = gradeableQuestion(qResult.rows[0]);
    if (!question) throw new AppError('Question is unavailable for practice', 422);
    const grade = questionTypeRegistry.checkAnswer(question, userAnswer);
    const isCorrect = grade.correct;
    const measuredQuality = quality == null || isCorrect ? quality : Math.min(quality, 2);
    const correctAnswer = grade.correctAnswer ?? question.correct_answer;
    const elapsed = Math.max(100, Math.min(3600000, parseInt(responseTimeMs) || 1000));
    const answered = await client.query(
      `INSERT INTO responses (user_id, session_id, question_id, user_answer, is_correct, response_time_ms,
          quality, selection_reason, submission_id, submission_input)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING id`,
      [userId, session, id, JSON.stringify(grade?.displayAnswer ?? userAnswer), isCorrect, elapsed,
        measuredQuality, selectionReason, submissionId, JSON.stringify(userAnswer)]
    );
    const adaptive = await pedagogicalEngine.resolveResponse(userId, question.topic_slug, id, isCorrect, measuredQuality, elapsed, client);
    let coinsEarned = 0;
    if (isCorrect) {
      // Retries of a different attempt can advance study history. Only the
      // first correct answer to each question per UTC day earns coin credit.
      const credit = await client.query(
        `UPDATE responses SET reward_day = (statement_timestamp() AT TIME ZONE 'UTC')::date
         WHERE id = $1 AND NOT EXISTS (
           SELECT 1 FROM responses WHERE user_id = $2 AND question_id = $3
             AND reward_day = (statement_timestamp() AT TIME ZONE 'UTC')::date
         ) RETURNING reward_day::text AS day`, [answered.rows[0].id, userId, id]
      );
      if (credit.rows.length) {
        coinsEarned = await economyService.processQuizCoinReward(client, userId, credit.rows[0].day);
      }
    }
    const receipt = {
      submissionId, topicSlug: question.topic_slug, isCorrect, correctAnswer, explanation: question.explanation_en, explanation_hu: question.explanation_hu,
      coinsEarned, masteryScore: adaptive.mastery_score, mastery: adaptive.mastery_score, coverage: adaptive.mastery_score,
      streak: adaptive.streak, currentBloom: adaptive.currentBloomLevel ?? question.bloom_level ?? 1,
      newLevel: adaptive.newLevel, levelDirection: adaptive.levelDirection, streakProgress: adaptive.streakProgress,
      level_correct_count: adaptive.level_correct_count, event: adaptive.event, adaptive,
    };
    await client.query(
      'UPDATE responses SET submission_result = $1, easiness_factor = $2, interval_days = $3, quality = $5 WHERE id = $4',
      [JSON.stringify(receipt), adaptive.srs?.easinessFactor ?? adaptive.srs?.stability ?? null,
        adaptive.srs?.interval ?? null, answered.rows[0].id, adaptive.quality ?? measuredQuality ?? null]
    );
    await client.query('INSERT INTO user_activity (user_id, action, metadata) VALUES ($1,$2,$3)',
      [userId, 'quiz_answer', JSON.stringify({ questionId: id, topicSlug: question.topic_slug, isCorrect, responseTimeMs: elapsed })]);
    return receipt;
  });
  res.json(result);
});

exports.getTopics = require('./topicController').getTopics;

exports.getQuestionTypes = catchAsync(async (req, res, _next) => {
  res.json(questionTypeRegistry.getAllTypes());
});

exports.getQuestionById = catchAsync(async (req, res, next) => {
  const id = positiveId(req.params.id);
  if (id === null) return next(new AppError('Invalid question ID', 400));
  const result = await db.query('SELECT q.*, t.slug AS topic_slug FROM questions q JOIN topics t ON t.id = q.topic_id WHERE q.id = $1', [id]);
  if (result.rows.length === 0) {
    return next(new AppError('Question not found', 404));
  }
  const question = result.rows[0];
  if (req.path.startsWith('/admin/')) return res.json(question);
  const practice = gradeableQuestion(question);
  if (!practice) return next(new AppError('Question unavailable', 404));
  res.json(questionTypeRegistry.prepareForClient(practice));
});

exports.translate = catchAsync(async (req, res, next) => {
  const { text, from, to } = req.body;
  if (![text, from, to].every(value => typeof value === 'string' && value.trim())) {
    return next(new AppError('Missing required fields: text, from, to', 400));
  }
  const translated = await translationService.translateText(text, from, to);
  res.json({ translated });
});
