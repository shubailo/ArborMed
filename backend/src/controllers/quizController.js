const db = require('../config/db');
const adaptiveEngine = require('../services/adaptiveEngine');

exports.startSession = async (req, res) => {
    try {
        const userId = req.user.id;
        // Create new session
        const result = await db.query(
            'INSERT INTO quiz_sessions (user_id) VALUES ($1) RETURNING *',
            [userId]
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.getNextQuestion = async (req, res) => {
    try {
        const userId = req.user.id;
        const { topic } = req.query; // topic slug, e.g. 'cardiovascular'

        if (!topic) {
            return res.status(400).json({ message: 'Topic is required' });
        }

        const question = await adaptiveEngine.getNextQuestion(userId, topic);

        if (!question) {
            return res.status(404).json({ message: 'No more questions available for this topic' });
        }

        // Hide correct answer and explanation for client
        const { correct_answer, explanation, ...clientQuestion } = question;

        res.json(clientQuestion);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.submitAnswer = async (req, res) => {
    try {
        const { sessionId, questionId, userAnswer, userIndex, responseTimeMs } = req.body;
        const userId = req.user.id; // User ID from auth middleware

        // 1. Verify answer and fetch Question Details (including Subject/Topic)
        const qResult = await db.query(`
            SELECT q.correct_answer, q.bloom_level, q.difficulty, t.slug as topic_slug 
            FROM questions q
            JOIN topics t ON q.topic_id = t.id
            WHERE q.id = $1
        `, [questionId]);

        if (qResult.rows.length === 0) {
            return res.status(404).json({ message: 'Question not found' });
        }

        const question = qResult.rows[0];

        // Use userIndex for reliable comparison, fallback to text if needed
        let isCorrect = false;
        if (userIndex !== undefined) {
            isCorrect = (parseInt(userIndex) === parseInt(question.correct_answer));
        } else {
            isCorrect = (userAnswer === question.correct_answer);
        }

        const subject = question.topic_slug;

        // 2. Record response
        await db.query(
            `INSERT INTO responses 
      (session_id, question_id, user_answer, is_correct, response_time_ms) 
      VALUES ($1, $2, $3, $4, $5)`,
            [sessionId, questionId, userAnswer, isCorrect, responseTimeMs]
        );

        // 3. Bloom Climber & SRS Logic
        const climberResult = await adaptiveEngine.processAnswerResult(userId, subject, isCorrect, questionId);

        // 4. Gamification Logic (Coins/XP)
        let coinsEarned = 0;
        let streakBonus = 0; // Keeping variable for response structure, set to 0
        let newStreak = climberResult ? climberResult.streak : 0;

        if (isCorrect) {
            // New Scaling: 1 coin per Bloom Level
            coinsEarned = question.bloom_level;
        }

        // 5. Persist Coin Updates
        if (coinsEarned > 0) {
            await db.query(`
                UPDATE users 
                SET coins = coins + $1, streak_count = $2, xp = xp + $3
                WHERE id = $4`,
                [coinsEarned, newStreak, coinsEarned, userId]
            );

            // Update Session
            await db.query(`
                UPDATE quiz_sessions 
                SET score = score + 10, coins_earned = coins_earned + $1 
                WHERE id = $2`,
                [coinsEarned, sessionId]
            );
        } else {
            // Just update streak on wrong answer (reset to 0)
            await db.query('UPDATE users SET streak_count = $1 WHERE id = $2', [newStreak, userId]);
        }

        res.json({
            isCorrect,
            correctAnswer: question.correct_answer,
            explanation: question.explanation || "No explanation provided.",
            coinsEarned,
            streak: newStreak,
            climber: climberResult ? {
                newLevel: climberResult.newLevel,
                event: climberResult.event // 'PROMOTION', 'DEMOTION', etc.
            } : null,
            bonuses: {
                streak: 0
            }
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};
