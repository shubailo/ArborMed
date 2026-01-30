const db = require('../config/db');
const adaptiveEngine = require('../services/adaptiveEngine');
const fs = require('fs');
const path = require('path');

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

        // Shuffle Options for Gamification/Anti-Cheating
        if (Array.isArray(clientQuestion.options)) {
            clientQuestion.options = clientQuestion.options.sort(() => Math.random() - 0.5);
        } else if (typeof clientQuestion.options === 'string') {
            try {
                let opts = JSON.parse(clientQuestion.options);
                if (Array.isArray(opts)) {
                    clientQuestion.options = opts.sort(() => Math.random() - 0.5);
                }
            } catch (e) {
                console.error("Failed to parse options for shuffling", e);
            }
        }

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

        console.log(`📝 Submit Answer: User ${userId}, Q ${questionId}, Answer: "${userAnswer}"`);

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

        // Fix: DB stores 'correct_answer' as TEXT (e.g. 'Right Ventricle')
        // We calculate correctness by comparing the user's text answer.
        let isCorrect = false;

        if (userAnswer && question.correct_answer) {
            const uNorm = String(userAnswer).trim().toLowerCase();
            const cNorm = String(question.correct_answer).trim().toLowerCase();
            isCorrect = (uNorm === cNorm);

            // fs.appendFileSync(path.join(__dirname, '../../debug_quiz.log'), ...);
            console.log(`[Validation] User="${uNorm}" vs DB="${cNorm}" Match=${isCorrect}`);
        } else if (userIndex !== undefined) {
            // Fallback logic
            console.warn("Submit with index only not fully supported without options text");
        } else {
            console.warn(`⚠️ Validation Warning: Missing answer data. User: "${userAnswer}", DB: "${question.correct_answer}"`);
            isCorrect = false;
        }

        const subject = question.topic_slug;

        // 2. Pre-calculate Coins (Needed for concurrent DB writes)
        const newStreak = 0; // Will be overwritten by climber result
        let coinsEarned = 0;
        if (isCorrect) {
            // New Scaling: 1 coin per Bloom Level, minimum 1
            coinsEarned = (question.bloom_level && question.bloom_level > 0) ? question.bloom_level : 1;
        }

        // 3. PARALLEL EXECUTION: Fire all independent DB ops at once
        // We strictly need 'climberResult' for the response. 
        // We DON'T strictly need the others to finish before sending response, 
        // but Promise.all is safer to ensure data integrity before next request.

        const [climberResult] = await Promise.all([
            // Task A: Climber Logic (Returns critical UI data)
            adaptiveEngine.processAnswerResult(userId, subject, isCorrect, questionId),

            // Task B: Record Response (Persistence)
            db.query(
                `INSERT INTO responses (session_id, question_id, user_answer, is_correct, response_time_ms) VALUES ($1, $2, $3, $4, $5)`,
                [sessionId, questionId, userAnswer, isCorrect, responseTimeMs]
            ),

            // Task C: Update User Coins/Streak & Session Score
            (async () => {
                let currentStreak = 0; // We might not know exact streak here if relying on climber, 
                // but climber handles UserTopicProgress. Users table streak is global.
                // We'll update global streak separately or let climber handle it?
                // Original code updated users table streak.
                // Let's rely on a simplified streak update or wait for climber if we want exact sync.
                // actually, original code used 'newStreak' from climberResult.
                // Optimization: We can't parallelize 'users' update perfectly if it depends on 'climberResult.streak'.
                // BUT, we can just increment/reset based on isCorrect without knowing the exact number if we use SQL logic?
                // Or just do Coin updates here and let Streak stay slightly async? 
                // Let's do Coins here. Streak is less critical for immediate "Cash" feedback.

                if (coinsEarned > 0) {
                    // Update Coins & XP
                    await db.query(`UPDATE users SET coins = coins + $1, xp = xp + $2 WHERE id = $3`, [coinsEarned, coinsEarned, userId]);
                    // Update Session
                    await db.query(`UPDATE quiz_sessions SET score = score + 10, coins_earned = coins_earned + $1 WHERE id = $2`, [coinsEarned, sessionId]);
                }
            })()
        ]);

        // Post-Processing: Update Global Streak with accurate data from Climber
        // This is fast single-row update, doing it after is fine, or we could have done it in parallel if we guessed logic.
        // Let's just do it here to ensure accuracy.
        const finalStreak = climberResult ? climberResult.streak : 0;
        if (!isCorrect) {
            // Reset streak
            db.query('UPDATE users SET streak_count = 0 WHERE id = $1', [userId]).catch(e => console.error(e));
        } else {
            // Increment streak (We assume climber logic matches global streak logic roughly)
            db.query('UPDATE users SET streak_count = streak_count + 1 WHERE id = $1', [userId]).catch(e => console.error(e));
        }

        res.json({
            isCorrect,
            correctAnswer: question.correct_answer,
            explanation: question.explanation || "No explanation provided.",
            coinsEarned,
            streak: finalStreak,
            climber: climberResult ? {
                newLevel: climberResult.newLevel,
                event: climberResult.event
            } : null,
            bonuses: {
                streak: 0
            }
        });

    } catch (error) {
        console.error(error);
        try { require('fs').appendFileSync('error_log.txt', `${new Date().toISOString()} - ${error.stack}\n`); } catch (e) { }
        res.status(500).json({ message: 'Server error' });
    }
};
