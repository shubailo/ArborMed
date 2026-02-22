const fs = require('fs');
const db = require('../config/db');
const adaptiveEngine = require('../services/adaptiveEngine');
const questionTypeRegistry = require('../services/questionTypes/registry');
const answerValidator = require('../utils/answerValidator');
const translationService = require('../services/translationService');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

exports.startSession = catchAsync(async (req, res, next) => {
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

    const excludedIds = exclude ? exclude.split(',').map(id => parseInt(id.trim())).filter(id => !isNaN(id)) : [];
    const levelOverride = bloomLevel ? parseInt(bloomLevel) : null;

    const question = await adaptiveEngine.getNextQuestion(userId, topic, excludedIds, levelOverride);

    if (!question) {
        return next(new AppError('No more questions available for this topic', 404));
    }

    const clientQuestion = questionTypeRegistry.prepareForClient(question);

    const qType = questionTypeRegistry.getType(question.question_type);
    const shouldShuffle = qType ? qType.shouldShuffleOptions : true;

    if (shouldShuffle) {
        if (Array.isArray(clientQuestion.options)) {
            clientQuestion.options = clientQuestion.options.sort(() => Math.random() - 0.5);
        } else if (typeof clientQuestion.options === 'string') {
            try {
                let opts = JSON.parse(clientQuestion.options);
                if (Array.isArray(opts)) {
                    clientQuestion.options = opts.sort(() => Math.random() - 0.5);
                }
            } catch { }
        }
    }

    res.json(clientQuestion);
});

exports.submitAnswer = catchAsync(async (req, res, next) => {
    const { sessionId, questionId, userAnswer, userIndex, responseTimeMs } = req.body;
    const userId = req.user.id;


    // 1. Verify answer and fetch Question Details
    const qResult = await db.query(`
        SELECT q.correct_answer, q.bloom_level, q.difficulty, q.explanation_en, q.explanation_hu, q.options, t.slug as topic_slug 
        FROM questions q
        JOIN topics t ON q.topic_id = t.id
        WHERE q.id = $1
    `, [questionId]);

    if (qResult.rows.length === 0) {
        return next(new AppError('Question not found', 404));
    }

    const question = qResult.rows[0];
    const options = (typeof question.options === 'string') ? JSON.parse(question.options) : question.options;

    const { isCorrect, normalizedCorrect: correctAnswerToReturn } = answerValidator.validateBilingual(
        userAnswer,
        question.correct_answer,
        options
    );

    const subject = question.topic_slug;

    // Validate and Clamp Response Time
    let validatedTime = parseInt(responseTimeMs) || 1000;
    if (validatedTime < 100) validatedTime = 100;
    if (validatedTime > 3600000) validatedTime = 3600000;

    // 2. Save response
    await db.query(
        'INSERT INTO responses (session_id, question_id, user_answer, is_correct, response_time_ms) VALUES ($1, $2, $3, $4, $5)',
        [sessionId, questionId, JSON.stringify(userAnswer), isCorrect, validatedTime]
    );

    // 3. Update Adaptive Logic
    const adaptiveResult = await adaptiveEngine.processAnswerResult(
        userId,
        subject,
        isCorrect,
        questionId,
        question.bloom_level || question.difficulty || 1
    );

    res.json({
        isCorrect,
        correctAnswer: correctAnswerToReturn,
        explanation: question.explanation_en,
        explanation_hu: question.explanation_hu,
        adaptive: adaptiveResult
    });
});

exports.getTopics = catchAsync(async (req, res, next) => {
    const query = `
        SELECT t.*, 
               (SELECT COUNT(*) FROM questions q WHERE q.topic_id = t.id AND q.active = TRUE) as question_count
        FROM topics t
        ORDER BY t.parent_id NULLS FIRST, t.id
    `;
    const result = await db.query(query);
    res.json(result.rows);
});

exports.getQuestionTypes = catchAsync(async (req, res, next) => {
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
