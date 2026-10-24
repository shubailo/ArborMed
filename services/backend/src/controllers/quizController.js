const db = require('../config/db');
const pedagogicalEngine = require('../services/pedagogicalEngine');
const learningService = require('../services/learningService');
const questionTypeRegistry = require('../services/questionTypes/registry');
const answerValidator = require('../utils/answerValidator');
const translationService = require('../services/translationService');
const AppError = require('../utils/AppError');
const { secureShuffleArray } = require('../utils/cryptoUtils');
const catchAsync = require('../utils/catchAsync');

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
  const { topic, exclude, bloomLevel } = req.query;

  if (!topic) {
    return next(new AppError('Topic is required', 400));
  }

  const excludedIds = exclude
    ? exclude
        .split(',')
        .map((id) => parseInt(id.trim()))
        .filter((id) => !isNaN(id))
    : [];
  const levelOverride = bloomLevel ? parseInt(bloomLevel) : null;

  const question = await pedagogicalEngine.getChallenge(
    userId,
    topic,
    excludedIds,
    levelOverride
  );

  if (!question) {
    return next(
      new AppError('No more questions available for this topic', 404)
    );
  }

  const clientQuestion = questionTypeRegistry.prepareForClient(question);

  const qType = questionTypeRegistry.getType(question.question_type);
  const shouldShuffle = qType ? qType.shouldShuffleOptions : true;

  if (shouldShuffle) {
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

exports.submitAnswer = catchAsync(async (req, res, next) => {
  const {
    sessionId,
    questionId,
    userAnswer,
    responseTimeMs,
    quality,
    selectionReason,
  } = req.body;
  const userId = req.user.id;

  // Handle local/non-integer session IDs
  let validatedSessionId = parseInt(sessionId);
  if (isNaN(validatedSessionId)) {
    validatedSessionId = null;
  }

  const validatedQuestionId = parseInt(questionId);
  if (isNaN(validatedQuestionId)) {
    return next(new AppError('Invalid question ID', 400));
  }

  // 1. Verify answer and fetch Question Details
  const qResult = await db.query(
    `
        SELECT q.correct_answer, q.bloom_level, q.difficulty, q.explanation_en, q.explanation_hu, q.options, q.type, q.question_type, q.content, t.slug as topic_slug 
        FROM questions q
        JOIN topics t ON q.topic_id = t.id
        WHERE q.id = $1
    `,
    [validatedQuestionId]
  );

  if (qResult.rows.length === 0) {
    return next(new AppError('Question not found', 404));
  }

  const question = qResult.rows[0];
  const qType = question.question_type || question.type || 'single_choice';
  const typeHandler = questionTypeRegistry.getType(qType);

  let isCorrect = false;
  let correctAnswerToReturn = question.correct_answer;

  const options =
    typeof question.options === 'string'
      ? JSON.parse(question.options)
      : question.options;

  if (typeHandler && typeof typeHandler.checkAnswer === 'function') {
    const checkResult = typeHandler.checkAnswer(question, userAnswer);
    isCorrect = Boolean(checkResult.correct);
    if (checkResult.correctAnswer) {
      correctAnswerToReturn = checkResult.correctAnswer;
    }
  } else {
    const valResult = answerValidator.validateBilingual(
      userAnswer,
      question.correct_answer,
      options
    );
    isCorrect = valResult.isCorrect;
    correctAnswerToReturn = valResult.normalizedCorrect;
  }

  const subject = question.topic_slug;

  // Validate and Clamp Response Time
  let validatedTime = parseInt(responseTimeMs) || 1000;
  if (validatedTime < 100) validatedTime = 100;
  if (validatedTime > 3600000) validatedTime = 3600000;

  // 2. Save response (Now with user_id, quality and selection_reason)
  const responseRes = await db.query(
    'INSERT INTO responses (user_id, session_id, question_id, user_answer, is_correct, response_time_ms, quality, selection_reason) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id',
    [
      userId,
      validatedSessionId,
      validatedQuestionId,
      JSON.stringify(userAnswer),
      isCorrect,
      validatedTime,
      quality,
      selectionReason,
    ]
  );
  const responseId = responseRes.rows[0].id;

  // 3. Update Learning Logic (Pedagogical Engine)
  const adaptiveResult = await pedagogicalEngine.resolveResponse(
    userId,
    subject,
    validatedQuestionId,
    isCorrect,
    quality,
    validatedTime
  );

  // Persist memory metrics in response log for transparency
  if (adaptiveResult.srs) {
    await db.query(
      'UPDATE responses SET easiness_factor = $1, interval_days = $2 WHERE id = $3',
      [
        adaptiveResult.srs.easinessFactor || adaptiveResult.srs.stability || 2.5,
        adaptiveResult.srs.interval,
        responseId,
      ]
    );
  }

  // 4. Calculate Coins (Soft Cap Economy)
  let coinsEarned = 0;
  if (isCorrect) {
    try {
      const economyService = require('../services/economyService');
      // Run in transaction to prevent check-then-act race conditions
      const { withTransaction } = require('../utils/dbHelpers');
      coinsEarned = await withTransaction(async (client) => {
        return await economyService.processQuizCoinReward(client, userId);
      });
    } catch (error) {
      console.error(
        '[QUIZ] Economy reward failed but continuing answer submission:',
        error.message
      );
      // Non-blocking failure: User just doesn't get coins this time
    }
  }

  res.json({
    isCorrect,
    correctAnswer: correctAnswerToReturn,
    explanation: question.explanation_en,
    explanation_hu: question.explanation_hu,
    coinsEarned,
    masteryScore: adaptiveResult ? adaptiveResult.mastery_score : 0,
    mastery: adaptiveResult ? adaptiveResult.mastery_score : 0,
    coverage: adaptiveResult ? adaptiveResult.mastery_score : 0,
    streak: adaptiveResult ? adaptiveResult.streak : 0,
    newLevel: adaptiveResult ? adaptiveResult.newLevel : undefined,
    streakProgress: adaptiveResult ? adaptiveResult.streakProgress : 0,
    level_correct_count: adaptiveResult ? adaptiveResult.level_correct_count : 0,
    event: adaptiveResult ? adaptiveResult.event : null,
    adaptive: adaptiveResult,
  });
});

exports.getTopics = catchAsync(async (req, res, _next) => {
  const query = `
        SELECT t.*, 
               (SELECT COUNT(*) FROM questions q WHERE q.topic_id = t.id AND q.active = TRUE) as question_count
        FROM topics t
        ORDER BY t.parent_id NULLS FIRST, t.id
    `;
  const result = await db.query(query);
  res.json(result.rows);
});

exports.getQuestionTypes = catchAsync(async (req, res, _next) => {
  const types = require('../services/questionTypes/registry').activeTypes;
  res.json(types);
});

exports.getQuestionById = catchAsync(async (req, res, next) => {
  const { id } = req.params;
  const result = await db.query('SELECT * FROM questions WHERE id = $1', [id]);
  if (result.rows.length === 0) {
    return next(new AppError('Question not found', 404));
  }
  res.json(result.rows[0]);
});

exports.translate = catchAsync(async (req, res, next) => {
  const { text, from, to } = req.body;
  if (!text || !from || !to) {
    return next(new AppError('Missing required fields: text, from, to', 400));
  }
  const translated = await translationService.translateText(text, from, to);
  res.json({ translated });
});
