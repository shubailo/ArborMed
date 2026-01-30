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
            })(),

            // Task D: Update Question Performance Cache
            (async () => {
                await db.query(`
                    INSERT INTO question_performance (question_id, total_attempts, correct_count, success_rate)
                    VALUES ($1, 1, $2, $3)
                    ON CONFLICT (question_id) DO UPDATE SET
                        total_attempts = question_performance.total_attempts + 1,
                        correct_count = question_performance.correct_count + EXCLUDED.correct_count,
                        success_rate = ((question_performance.correct_count + EXCLUDED.correct_count)::float / (question_performance.total_attempts + 1)::float) * 100,
                        last_updated = CURRENT_TIMESTAMP
                `, [questionId, isCorrect ? 1 : 0, isCorrect ? 100 : 0]);
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

exports.getTopics = async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM topics ORDER BY name ASC');
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error fetching topics' });
    }
};

// --- ADMIN CONTROLLERS ---

/**
 * @desc Get all questions with pagination and search
 */
exports.adminGetQuestions = async (req, res) => {
    try {
        const { page = 1, limit = 200, search = '', type = '', bloom_level = '', topic_id = '', sortBy = 'created_at', order = 'DESC' } = req.query;
        const offset = (page - 1) * limit;

        // Map frontend sort names to DB columns
        const sortMap = {
            'id': 'q.id',
            'bloom_level': 'q.difficulty',
            'topic_name': 't.name',
            'attempts': 'attempts',
            'success_rate': 'success_rate',
            'created_at': 'q.created_at'
        };

        const orderBy = sortMap[sortBy] || 'q.created_at';
        const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

        let query = `
            SELECT q.*, q.difficulty as bloom_level, t.name as topic_name, t.slug as topic_slug,
                   COALESCE(qp.total_attempts, 0) as attempts,
                   COALESCE(qp.success_rate, 0) as success_rate
            FROM questions q
            JOIN topics t ON q.topic_id = t.id
            LEFT JOIN question_performance qp ON qp.question_id = q.id
        `;
        let countQuery = `SELECT COUNT(*) FROM questions q JOIN topics t ON q.topic_id = t.id`;
        const conditions = [];
        const params = [];

        if (search) {
            params.push(`%${search}%`);
            conditions.push(`(q.text ILIKE $${params.length} OR t.name ILIKE $${params.length})`);
        }

        if (type) {
            params.push(type);
            conditions.push(`q.type = $${params.length}`);
        }

        if (bloom_level) {
            params.push(bloom_level);
            conditions.push(`q.difficulty = $${params.length}`);
        }

        if (topic_id) {
            params.push(topic_id);
            // Recursive query to get all children of the selected topic
            conditions.push(`q.topic_id IN (
                WITH RECURSIVE subtopics AS (
                    SELECT id FROM topics WHERE id = $${params.length}
                    UNION ALL
                    SELECT t.id FROM topics t INNER JOIN subtopics st ON t.parent_id = st.id
                )
                SELECT id FROM subtopics
            )`);
        }

        if (conditions.length > 0) {
            const whereClause = ` WHERE ` + conditions.join(' AND ');
            query += whereClause;
            countQuery += whereClause;
        }

        query += ` ORDER BY ${orderBy} ${sortOrder} LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
        const queryParams = [...params, limit, offset];

        const [results, countResult] = await Promise.all([
            db.query(query, queryParams),
            db.query(countQuery, params)
        ]);

        res.json({
            questions: results.rows,
            total: parseInt(countResult.rows[0].count),
            page: parseInt(page),
            limit: parseInt(limit)
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error fetching questions' });
    }
};

/**
 * @desc Create a new question
 */
exports.adminCreateQuestion = async (req, res) => {
    try {
        const { text, options, correct_answer, explanation, topic_id, difficulty, bloom_level, type } = req.body;

        const query = `
            INSERT INTO questions (text, options, correct_answer, explanation, topic_id, difficulty, bloom_level, type)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *
        `;

        // Ensure options is stringified if it comes as an array
        const optionsStr = typeof options === 'string' ? options : JSON.stringify(options);

        const result = await db.query(query, [
            text,
            optionsStr,
            correct_answer,
            explanation,
            topic_id,
            difficulty || bloom_level || 1,
            bloom_level || difficulty || 1,
            type || 'single_choice'
        ]);

        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error creating question' });
    }
};

/**
 * @desc Update a question
 */
exports.adminUpdateQuestion = async (req, res) => {
    try {
        const { id } = req.params;
        const { text, options, correct_answer, explanation, topic_id, difficulty, bloom_level, type } = req.body;

        const optionsStr = typeof options === 'string' ? options : JSON.stringify(options);

        const query = `
            UPDATE questions
            SET text = $1, options = $2, correct_answer = $3, explanation = $4, 
                topic_id = $5, difficulty = $6, bloom_level = $7, type = $8, updated_at = NOW()
            WHERE id = $9
            RETURNING *
        `;

        const result = await db.query(query, [
            text,
            optionsStr,
            correct_answer,
            explanation,
            topic_id,
            difficulty || bloom_level || 1,
            bloom_level || difficulty || 1,
            type || 'single_choice',
            id
        ]);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Question not found' });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error updating question' });
    }
};

/**
 * @desc Delete a question
 */
exports.adminDeleteQuestion = async (req, res) => {
    try {
        const { id } = req.params;

        // Note: soft delete is safer if we have responses, but for MVP we might just do hard delete
        // If we want to keep integrity, we check if there are responses first.
        const respCheck = await db.query('SELECT COUNT(*) FROM responses WHERE question_id = $1', [id]);

        if (parseInt(respCheck.rows[0].count) > 0) {
            return res.status(400).json({
                message: 'Cannot delete question with existing student responses. Consider soft-deleting (feature pending).'
            });
        }

        const result = await db.query('DELETE FROM questions WHERE id = $1 RETURNING *', [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Question not found' });
        }

        res.json({ message: 'Question deleted successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error deleting question' });
    }
};
