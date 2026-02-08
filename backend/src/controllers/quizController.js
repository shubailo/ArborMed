const db = require('../config/db');
const adaptiveEngine = require('../services/adaptiveEngine');
const questionTypeRegistry = require('../services/questionTypes/registry');
const AdminExcelService = require('../services/adminExcelService');
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
        const { topic, exclude, bloomLevel } = req.query; // topic slug, exclude = comma-separated IDs, bloomLevel = override level

        if (!topic) {
            return res.status(400).json({ message: 'Topic is required' });
        }

        // Parse excluded IDs (for batch fetching to prevent duplicates)
        const excludedIds = exclude ? exclude.split(',').map(id => parseInt(id.trim())).filter(id => !isNaN(id)) : [];

        // Parse optional bloom level override (for predictive caching)
        const levelOverride = bloomLevel ? parseInt(bloomLevel) : null;

        const question = await adaptiveEngine.getNextQuestion(userId, topic, excludedIds, levelOverride);

        if (!question) {
            return res.status(404).json({ message: 'No more questions available for this topic' });
        }

        // Use registry to prepare question for client (hides answers, adds type-specific content)
        const clientQuestion = questionTypeRegistry.prepareForClient(question);

        // Access the question type to check shuffling preference
        const qType = questionTypeRegistry.getType(question.question_type);
        const shouldShuffle = qType ? qType.shouldShuffleOptions : true;

        // Shuffle Options if allowed for this type
        if (shouldShuffle) {
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
            SELECT q.correct_answer, q.bloom_level, q.difficulty, q.explanation_en, q.explanation_hu, q.options, t.slug as topic_slug 
            FROM questions q
            JOIN topics t ON q.topic_id = t.id
            WHERE q.id = $1
        `, [questionId]);

        if (qResult.rows.length === 0) {
            return res.status(404).json({ message: 'Question not found' });
        }

        const question = qResult.rows[0];
        const options = (typeof question.options === 'string') ? JSON.parse(question.options) : question.options;

        let isCorrect = false;
        let correctAnswerToReturn = question.correct_answer;

        // Parse DB correct_answer (could be string "True" or JSON array ["A", "B"])
        let dbCorrectArr = [];
        try {
            dbCorrectArr = (typeof question.correct_answer === 'string' && question.correct_answer.startsWith('['))
                ? JSON.parse(question.correct_answer)
                : [question.correct_answer];
            if (!Array.isArray(dbCorrectArr)) dbCorrectArr = [question.correct_answer];
        } catch (e) {
            dbCorrectArr = [question.correct_answer];
        }

        if (userAnswer) {
            // Normalize user answers into an array
            let userArr = [];
            if (Array.isArray(userAnswer)) {
                userArr = userAnswer;
            } else if (typeof userAnswer === 'string' && userAnswer.startsWith('[')) {
                try { userArr = JSON.parse(userAnswer); } catch (e) { userArr = [userAnswer]; }
            } else {
                userArr = [userAnswer];
            }

            const uNorms = userArr.map(u => String(u).trim().toLowerCase());
            const cNorms = dbCorrectArr.map(c => String(c).trim().toLowerCase());

            // 1. Check if user is using Hungarian options
            let isUserHu = false;
            if (options && options.hu) {
                const huOptionsLower = options.hu.map(o => String(o).trim().toLowerCase());
                isUserHu = uNorms.some(u => huOptionsLower.includes(u));
            }

            // 2. Perform validation with bilingual fallback
            if (options && options.en && options.hu) {
                const enOptsLower = options.en.map(o => String(o).trim().toLowerCase());
                const huOptsLower = options.hu.map(o => String(o).trim().toLowerCase());

                // Map DB correct to indices
                const correctIndices = cNorms.map(c => enOptsLower.indexOf(c)).filter(idx => idx !== -1);

                // Map User answers to indices (checking both lang lists)
                const userIndices = uNorms.map(u => {
                    let idx = enOptsLower.indexOf(u);
                    if (idx === -1) idx = huOptsLower.indexOf(u);
                    return idx;
                }).filter(idx => idx !== -1);

                // Compare sets of indices
                isCorrect = (correctIndices.length > 0 &&
                    correctIndices.length === userIndices.length &&
                    correctIndices.every(idx => userIndices.includes(idx)));

                // Map correctAnswerToReturn to user's language
                if (isUserHu && correctIndices.length > 0) {
                    const huCorrects = correctIndices.map(idx => options.hu[idx]);
                    correctAnswerToReturn = huCorrects.length > 1 ? huCorrects : (huCorrects[0] || question.correct_answer);
                } else if (correctIndices.length > 0) {
                    const enCorrects = correctIndices.map(idx => options.en[idx] || dbCorrectArr[0]);
                    correctAnswerToReturn = enCorrects.length > 1 ? enCorrects : enCorrects[0];
                } else {
                    // Mapping failed? Return the raw DB values as fallback
                    correctAnswerToReturn = dbCorrectArr.length > 1 ? dbCorrectArr : dbCorrectArr[0];
                }
            } else {
                // Legacy / fallback simple match
                isCorrect = (cNorms.length === uNorms.length && cNorms.every(c => uNorms.includes(c)));
                correctAnswerToReturn = dbCorrectArr.length > 1 ? dbCorrectArr : dbCorrectArr[0];
            }

            console.log(`[Validation] UserIndices=${JSON.stringify(uNorms)} vs DBNorms=${JSON.stringify(cNorms)} Match=${isCorrect} Returned=${JSON.stringify(correctAnswerToReturn)}`);
        } else if (userIndex !== undefined) {
            console.warn("Submit with index only not fully supported");
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

        // 3. Fire-and-forget non-critical DB updates (Task B & D)
        db.query(
            `INSERT INTO responses (session_id, question_id, user_answer, is_correct, response_time_ms) VALUES ($1, $2, $3, $4, $5)`,
            [sessionId, questionId, userAnswer, isCorrect, responseTimeMs]
        ).catch(err => console.error("Response logging failed:", err));

        db.query(`
            INSERT INTO question_performance (question_id, total_attempts, correct_count, success_rate)
            VALUES ($1, 1, $2, $3)
            ON CONFLICT (question_id) DO UPDATE SET
                total_attempts = question_performance.total_attempts + 1,
                correct_count = question_performance.correct_count + EXCLUDED.correct_count,
                success_rate = ((question_performance.correct_count + EXCLUDED.correct_count)::float / (question_performance.total_attempts + 1)::float) * 100,
                last_updated = CURRENT_TIMESTAMP
        `, [questionId, isCorrect ? 1 : 0, isCorrect ? 100 : 0]).catch(err => console.error("Performance log failed:", err));

        // 4. PARALLEL EXECUTION: Fire critical updates (Climber + User Stats)
        const [climberResult] = await Promise.all([
            // Task A: Climber Logic (Returns critical UI data)
            adaptiveEngine.processAnswerResult(userId, subject, isCorrect, questionId, question.bloom_level),

            // Task C: Update User Coins & Session Score
            (async () => {
                if (coinsEarned > 0) {
                    await db.query(`UPDATE users SET coins = coins + $1, xp = xp + $2, last_active_date = NOW() WHERE id = $3`, [coinsEarned, coinsEarned, userId]);
                    await db.query(`UPDATE quiz_sessions SET score = score + 10, coins_earned = coins_earned + $1 WHERE id = $2`, [coinsEarned, sessionId]);
                } else {
                    await db.query(`UPDATE users SET last_active_date = NOW() WHERE id = $1`, [userId]);
                }
            })()
        ]);

        // Post-Processing: Update Global Streak with accurate data from Climber
        // This is fast single-row update, doing it after is fine, or we could have done it in parallel if we guessed logic.
        // Let's just do it here to ensure accuracy.
        // Post-Processing: Update Global Streak with accurate data from Climber
        const finalStreak = climberResult?.streak || 0;

        try {
            if (!isCorrect) {
                // Reset global streak
                await db.query('UPDATE users SET streak_count = 0, last_active_date = NOW() WHERE id = $1', [userId]);
            } else {
                // Increment global streak AND check/update longest_streak
                await db.query(`
                    UPDATE users 
                    SET streak_count = streak_count + 1,
                        last_active_date = NOW(),
                        longest_streak = CASE 
                            WHEN streak_count + 1 > longest_streak THEN streak_count + 1 
                            ELSE longest_streak 
                        END
                    WHERE id = $1
                `, [userId]);
            }
        } catch (e) {
            console.error('Error updating streaks in users table:', e);
        }

        // Prepare language-aware explanation with explicit correct answer if wrong
        let finalExplanation = question.explanation_hu || question.explanation_en || "No explanation provided.";
        if (!isCorrect) {
            const label = (question.explanation_hu) ? "Helyes válasz" : "Correct answer";
            const answerText = Array.isArray(correctAnswerToReturn)
                ? correctAnswerToReturn.join(", ")
                : String(correctAnswerToReturn);
            finalExplanation = `${label}: **${answerText}**\n\n${finalExplanation}`;
        }

        res.json({
            isCorrect,
            correctAnswer: correctAnswerToReturn,
            explanation: finalExplanation,
            coinsEarned,
            streak: finalStreak,
            streakProgress: climberResult?.streakProgress || 0,
            coverage: climberResult?.coverage || 0,
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
        const result = await db.query('SELECT id, name_en, name_hu, slug, parent_id FROM topics ORDER BY name_en ASC');
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error fetching topics' });
    }
};

/**
 * @desc Get all available question types
 * @route GET /api/quiz/question-types
 */
exports.getQuestionTypes = async (req, res) => {
    try {
        const types = questionTypeRegistry.getAllTypes();
        res.json(types);
    } catch (error) {
        console.error('Error fetching question types:', error);
        res.status(500).json({ message: 'Server error fetching question types' });
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
            'topic_name': 't.name_en',
            'attempts': 'attempts',
            'success_rate': 'success_rate',
            'created_at': 'q.created_at'
        };

        const orderBy = sortMap[sortBy] || 'q.created_at';
        const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

        let query = `
            SELECT q.*, q.difficulty as bloom_level, t.name_en as topic_name, t.slug as topic_slug,
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
            conditions.push(`(q.question_text_en ILIKE $${params.length} OR t.name_en ILIKE $${params.length})`);
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
            questions: results.rows.map(q => questionTypeRegistry.prepareForAdmin(q)),
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
        const {
            question_type, content, correct_answer,
            topic_id, difficulty, bloom_level, metadata,
            question_text_en, question_text_hu,
            explanation_en, explanation_hu,
            options_en, options_hu
        } = req.body;

        if (!topic_id) {
            return res.status(400).json({ message: 'A Topic (Section) MUST be selected for every question.' });
        }

        // Default to single_choice if no type specified
        const typeId = question_type || 'single_choice';

        // Validate using Question Type Registry (Basic validation)
        // Note: Registry validation might need updates for multi-lang, skipping strict check here for MVP flexibility
        // const validation = questionTypeRegistry.validate(...) 

        // Construct Options JSON
        let optionsJson = {};
        if (options_en || options_hu) {
            optionsJson = {
                en: options_en || [],
                hu: options_hu || []
            }
        }

        // Backward compatibility: 'text' = English text, 'options' = JSONB
        const text = question_text_en || content?.question_text || '';
        const definitionOptions = JSON.stringify(optionsJson);

        // Subject-based permission check (non-super admins only)
        const isSuperAdmin = req.user.email === 'shubailobeid@gmail.com';
        if (!isSuperAdmin && req.user.assigned_subject_id !== topic_id) {
            // Get user's assigned subject
            const userCheck = await db.query('SELECT assigned_subject_id FROM users WHERE id = $1', [req.user.id]);
            const assignedSubject = userCheck.rows[0]?.assigned_subject_id;

            if (assignedSubject && assignedSubject !== topic_id) {
                return res.status(403).json({
                    error: 'You can only create questions in your assigned subject',
                    assignedSubject
                });
            }
        }

        const query = `
            INSERT INTO questions (
                question_type, content, correct_answer, 
                explanation_en, explanation_hu,
                topic_id, difficulty, bloom_level, metadata,
                question_text_en, question_text_hu,
                options, type, created_by
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
            RETURNING *
        `;

        const result = await db.query(query, [
            typeId,
            content || {}, // JSONB
            correct_answer,
            explanation_en || '',
            explanation_hu || '',
            topic_id,
            difficulty || bloom_level || 1,
            bloom_level || difficulty || 1,
            metadata || {},
            question_text_en || '',
            question_text_hu || '',
            definitionOptions, // Legacy 'options' column (now stores full JSON structure)
            typeId, // Legacy 'type' column
            req.user.id // Track who created this question
        ]);

        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error creating question:', error);
        res.status(500).json({ message: 'Server error creating question', error: error.message });
    }
};

/**
 * @desc Update a question
 */
exports.adminUpdateQuestion = async (req, res) => {
    try {
        const { id } = req.params;
        const {
            question_type, content, correct_answer,
            topic_id, difficulty, bloom_level, metadata,
            question_text_en, question_text_hu,
            explanation_en, explanation_hu,
            options_en, options_hu
        } = req.body;

        // Permission check: Can this admin edit this question?
        const isSuperAdmin = req.user.email === 'shubailobeid@gmail.com';

        if (!isSuperAdmin) {
            // Check if question exists and belongs to admin's subject or was created by them
            const questionCheck = await db.query(`
                SELECT q.topic_id, q.created_by, u.assigned_subject_id
                FROM questions q
                LEFT JOIN users u ON u.id = $2
                WHERE q.id = $1
            `, [id, req.user.id]);

            if (questionCheck.rows.length === 0) {
                return res.status(404).json({ error: 'Question not found' });
            }

            const question = questionCheck.rows[0];
            const userAssignedSubject = question.assigned_subject_id;

            // Admin can edit if: created by them OR in their assigned subject
            const canEdit = question.created_by === req.user.id ||
                (userAssignedSubject && question.topic_id === userAssignedSubject);

            if (!canEdit) {
                return res.status(403).json({
                    error: 'You can only edit questions in your assigned subject or questions you created'
                });
            }
        }

        // Construct Options JSON
        let optionsJson = {};
        if (options_en || options_hu) {
            optionsJson = {
                en: options_en || [],
                hu: options_hu || []
            };
        }

        const text = question_text_en || content?.question_text || '';
        const definitionOptions = JSON.stringify(optionsJson);

        const query = `
            UPDATE questions
            SET 
                question_text_en = $1, question_text_hu = $2,
                explanation_en = $3, explanation_hu = $4,
                options = $5,
                correct_answer = $6,
                topic_id = $7, difficulty = $8, bloom_level = $9, 
                type = $10,
                question_type = $11,
                content = $12,
                updated_at = NOW()
            WHERE id = $13
            RETURNING *
        `;

        const result = await db.query(query, [
            question_text_en || '',
            question_text_hu || '',
            explanation_en || '',
            explanation_hu || '',
            definitionOptions,
            correct_answer,
            topic_id,
            difficulty || bloom_level || 1,
            bloom_level || difficulty || 1,
            question_type || 'single_choice',
            question_type || 'single_choice',
            content || {},
            id
        ]);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Question not found' });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error updating question:', error);
        res.status(500).json({ message: 'Server error updating question', error: error.message });
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

/**
 * @desc Create a new topic/section
 * @route POST /api/quiz/topics
 * @access Admin
 */
exports.createTopic = async (req, res) => {
    try {
        const { name_en, name_hu, name, parent_id } = req.body;
        const finalNameEn = name_en || name;
        const finalNameHu = name_hu || name_en || name || '';

        if (!finalNameEn) {
            return res.status(400).json({ message: 'Topic name (English) is required' });
        }

        // Generate slug from English name
        const slug = finalNameEn.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');

        // Check if parent exists (if parent_id provided)
        if (parent_id) {
            const parentCheck = await db.query('SELECT id FROM topics WHERE id = $1', [parent_id]);
            if (parentCheck.rows.length === 0) {
                return res.status(404).json({ message: 'Parent topic not found' });
            }
        }

        // Check for duplicate name within same parent
        const duplicateCheck = await db.query(
            'SELECT id FROM topics WHERE name_en = $1 AND (parent_id = $2 OR (parent_id IS NULL AND $2 IS NULL))',
            [finalNameEn, parent_id || null]
        );
        if (duplicateCheck.rows.length > 0) {
            return res.status(409).json({ message: 'A topic with this name already exists in this subject' });
        }

        // Create topic
        const result = await db.query(
            'INSERT INTO topics (name_en, name_hu, slug, parent_id) VALUES ($1, $2, $3, $4) RETURNING *',
            [finalNameEn, finalNameHu, slug, parent_id || null]
        );

        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error creating topic:', error);
        res.status(500).json({ message: 'Server error creating topic' });
    }
};

/**
 * @desc Update a topic/section name
 * @route PUT /api/quiz/admin/topics/:id
 * @access Admin
 */
exports.updateTopic = async (req, res) => {
    try {
        const { id } = req.params;
        const { name_en, name_hu, name } = req.body;
        const finalName = name_en || name;

        if (!finalName) {
            return res.status(400).json({ message: 'Topic name is required' });
        }

        // NOTE: We do NOT update the slug here to preserve referential integrity 
        // with user_topic_progress and other tables. Changing slug would require 
        // cascading updates or strict FK handling which might be missing.
        // The slug remains as the permanent identifier (like ID).

        const client = await db.pool.connect();
        try {
            await client.query('BEGIN');

            const result = await client.query(
                `UPDATE topics 
                 SET name_en = COALESCE($1, name_en), 
                     name_hu = COALESCE($2, name_hu) 
                 WHERE id = $3 
                 RETURNING *`,
                [finalName, name_hu, id]
            );

            if (result.rows.length === 0) {
                await client.query('ROLLBACK');
                return res.status(404).json({ message: 'Topic not found' });
            }

            await client.query('COMMIT');
            res.json(result.rows[0]);
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    } catch (error) {
        console.error('Error updating topic:', error);
        res.status(500).json({
            message: `Server error updating topic: ${error.message}`,
            error: error.message
        });
    }
};

/**
 * @desc Delete a topic/section
 * @route DELETE /api/quiz/topics/:id
 * @access Admin
 */
exports.deleteTopic = async (req, res) => {
    const client = await db.pool.connect();
    try {
        const { id } = req.params;
        const force = req.query.force === 'true';

        // Check if topic exists
        const topicCheck = await client.query('SELECT * FROM topics WHERE id = $1', [id]);
        if (topicCheck.rows.length === 0) {
            return res.status(404).json({ message: 'Topic not found' });
        }

        const topic = topicCheck.rows[0];

        // Prevent deletion of parent subjects
        if (!topic.parent_id) {
            return res.status(403).json({ message: 'Cannot delete parent subjects. Only sections can be deleted.' });
        }

        // Check if topic has questions
        const questionCheck = await client.query('SELECT COUNT(*) as count FROM questions WHERE topic_id = $1', [id]);
        const questionCount = parseInt(questionCheck.rows[0].count);

        if (questionCount > 0 && !force) {
            return res.status(409).json({
                message: `Section has ${questionCount} question(s).`,
                count: questionCount
            });
        }

        // Check if topic has children
        const childrenCheck = await client.query('SELECT COUNT(*) as count FROM topics WHERE parent_id = $1', [id]);
        if (parseInt(childrenCheck.rows[0].count) > 0) {
            return res.status(409).json({
                message: 'Cannot delete topic. It has child topics. Please delete child topics first.'
            });
        }

        await client.query('BEGIN');

        // If force deletion, remove all associated questions and their data first
        if (force && questionCount > 0) {
            // Get question IDs to clear related data
            const qIdsResult = await client.query('SELECT id FROM questions WHERE topic_id = $1', [id]);
            const qIds = qIdsResult.rows.map(r => r.id);

            if (qIds.length > 0) {
                // Delete from all tables that might have question_id foreign keys
                await client.query('DELETE FROM responses WHERE question_id = ANY($1)', [qIds]);
                await client.query('DELETE FROM user_question_progress WHERE question_id = ANY($1)', [qIds]);
                await client.query('DELETE FROM question_performance WHERE question_id = ANY($1)', [qIds]);

                // Finally delete the questions themselves
                await client.query('DELETE FROM questions WHERE topic_id = $1', [id]);
            }
        }

        // Clear any orphaned progress for this topic
        await client.query('DELETE FROM user_topic_progress WHERE topic_slug = $1', [topic.slug]);

        // Delete topic
        await client.query('DELETE FROM topics WHERE id = $1', [id]);

        await client.query('COMMIT');

        res.json({
            message: 'Topic deleted successfully',
            deletedQuestions: force ? questionCount : 0
        });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error deleting topic:', error);
        res.status(500).json({ message: 'Server error deleting topic' });
    } finally {
        client.release();
    }
};

/**
 * @desc Get the current motivational quote based on 10-minute rotation
 * @route GET /api/quiz/quote
 */
exports.getCurrentQuote = async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM quotes ORDER BY id ASC');
        const quotes = result.rows;

        if (quotes.length === 0) {
            return res.json({
                text: "Clear mind, focused goals. Take a deep breath.",
                author: "ArborMed"
            });
        }

        // 10 minute rotation (600 seconds)
        const nowInSeconds = Math.floor(Date.now() / 1000);
        const rotationIndex = Math.floor(nowInSeconds / 600) % quotes.length;

        const currentQuote = quotes[rotationIndex];
        res.json({
            text_en: currentQuote.text_en,
            text_hu: currentQuote.text_hu,
            author: currentQuote.author || "Anonymous",
            title_en: currentQuote.title_en || "Study Break",
            title_hu: currentQuote.title_hu || "Tanulás",
            icon_name: currentQuote.icon_name || "menu_book_rounded",
            custom_icon_url: currentQuote.custom_icon_url
        });
    } catch (error) {
        console.error('Error fetching current quote:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

/**
 * @desc Admin: Get all quotes
 */
exports.adminGetQuotes = async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM quotes ORDER BY created_at DESC');
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching admin quotes:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

/**
 * @desc Admin: Create a quote
 */
exports.adminCreateQuote = async (req, res) => {
    try {
        const { text_en, text_hu, author, text, title_en, title_hu, icon_name, custom_icon_url } = req.body;
        const finalTextEn = text_en || text;
        const finalTextHu = text_hu || finalTextEn || '';
        const finalTitleEn = title_en || 'Study Break';
        const finalTitleHu = title_hu || 'Tanulás';
        const finalIconName = icon_name || 'menu_book_rounded';

        if (!finalTextEn) {
            return res.status(400).json({ message: 'Quote text (English) is required' });
        }

        const result = await db.query(
            `INSERT INTO quotes (text_en, text_hu, author, title_en, title_hu, icon_name, custom_icon_url) 
             VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
            [finalTextEn, finalTextHu, author || '', finalTitleEn, finalTitleHu, finalIconName, custom_icon_url]
        );
        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Error creating quote:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

/**
 * @desc Admin: Delete a quote
 */
exports.adminDeleteQuote = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await db.query('DELETE FROM quotes WHERE id = $1 RETURNING *', [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Quote not found' });
        }

        res.json({ message: 'Quote deleted successfully' });
    } catch (error) {
        console.error('Error deleting quote:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

/**
 * @desc Admin: Update a quote
 * @route PUT /api/quiz/admin/quotes/:id
 */
exports.adminUpdateQuote = async (req, res) => {
    try {
        const { id } = req.params;
        const { text_en, text_hu, author, title_en, title_hu, icon_name, custom_icon_url } = req.body;

        // Validate: at least one language field should be non-empty
        if (!text_en && !text_hu) {
            return res.status(400).json({ message: 'At least one language field (text_en or text_hu) is required' });
        }

        const result = await db.query(
            `UPDATE quotes 
             SET text_en = COALESCE($1, text_en), 
                 text_hu = COALESCE($2, text_hu), 
                 author = COALESCE($3, author),
                 title_en = COALESCE($4, title_en),
                 title_hu = COALESCE($5, title_hu),
                 icon_name = COALESCE($6, icon_name),
                 custom_icon_url = COALESCE($7, custom_icon_url)
             WHERE id = $8 
             RETURNING *`,
            [text_en, text_hu, author, title_en, title_hu, icon_name, custom_icon_url, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Quote not found' });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error updating quote:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

/**
 * @desc Translate text using translation service
 * @route POST /api/quiz/translate
 */
exports.getQuestionById = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await db.query('SELECT * FROM questions WHERE id = $1', [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Question not found' });
        }

        const question = result.rows[0];
        const clientQuestion = questionTypeRegistry.prepareForClient(question);
        res.json(clientQuestion);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.translate = async (req, res) => {
    try {
        const { text, sourceLang, targetLang } = req.body;

        if (!text || !sourceLang || !targetLang) {
            return res.status(400).json({ message: 'text, sourceLang, and targetLang are required' });
        }

        const translationService = require('../services/translationService');
        const translated = await translationService.translateText(text, sourceLang, targetLang);

        res.json({ translatedText: translated });
    } catch (error) {
        console.error('Translation error:', error);
        res.status(500).json({ message: 'Translation failed', error: error.message });
    }
};

/**
 * @desc Admin: Bulk action on questions
 * @route POST /api/quiz/admin/questions/bulk
 */
exports.adminBulkAction = async (req, res) => {
    try {
        const { action, ids, targetTopicId } = req.body;

        if (!ids || !Array.isArray(ids) || ids.length === 0) {
            return res.status(400).json({ message: 'No question IDs provided' });
        }

        const client = await db.pool.connect();
        try {
            await client.query('BEGIN');

            if (action === 'delete') {
                // Check for responses before deleting
                const respCheck = await client.query('SELECT question_id FROM responses WHERE question_id = ANY($1)', [ids]);
                const questionsWithResponses = [...new Set(respCheck.rows.map(r => r.question_id))];

                if (questionsWithResponses.length > 0) {
                    await client.query('ROLLBACK');
                    return res.status(400).json({
                        message: 'Some questions have student responses and cannot be deleted.',
                        ids: questionsWithResponses
                    });
                }

                await client.query('DELETE FROM questions WHERE id = ANY($1)', [ids]);
            } else if (action === 'move') {
                if (!targetTopicId) {
                    await client.query('ROLLBACK');
                    return res.status(400).json({ message: 'Target topic ID is required for move action' });
                }
                await client.query('UPDATE questions SET topic_id = $1 WHERE id = ANY($2)', [targetTopicId, ids]);
            } else {
                await client.query('ROLLBACK');
                return res.status(400).json({ message: 'Invalid action' });
            }

            await client.query('COMMIT');
            res.json({ message: `Bulk ${action} successful` });
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    } catch (error) {
        console.error('Error in adminBulkAction:', error);
        res.status(500).json({ message: 'Server error during bulk action' });
    }
};

/**
 * @desc Admin: Batch upload questions
 * @route POST /api/quiz/admin/questions/batch
 */
/**
 * @desc Admin: Download Excel Template
 */
exports.adminDownloadTemplate = async (req, res) => {
    try {
        const workbook = await AdminExcelService.generateTemplate();
        res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        res.setHeader('Content-Disposition', 'attachment; filename=QUESTION_TEMPLATE.xlsx');
        await workbook.xlsx.write(res);
        res.end();
    } catch (error) {
        console.error('Error generating template:', error);
        res.status(500).json({ message: 'Error generating template' });
    }
};

/**
 * @desc Admin: Batch upload questions (Excel/CSV)
 * @route POST /api/quiz/admin/questions/batch
 */
exports.adminBatchUpload = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        const questions = await AdminExcelService.parseFile(req.file.buffer, req.file.mimetype);

        const client = await db.pool.connect();
        let successCount = 0;
        let errors = [];

        try {
            await client.query('BEGIN');

            for (let i = 0; i < questions.length; i++) {
                try {
                    const q = questions[i];

                    if (!q.topic_id) {
                        throw new Error(`Invalid or missing topic: ${q.topic}`);
                    }

                    const optListEn = q.optEn ? q.optEn.toString().split(';') : [];
                    const optListHu = q.optHu ? q.optHu.toString().split(';') : [];
                    const optionsJson = JSON.stringify({ en: optListEn, hu: optListHu });

                    if (q.db_id) {
                        // UPDATE existing
                        await client.query(
                            `UPDATE questions 
                             SET question_text_en = $1, question_text_hu = $2, topic_id = $3, 
                                 difficulty = $4, bloom_level = $4, type = $5, question_type = $5, 
                                 correct_answer = $6, options = $7, explanation_en = $8, explanation_hu = $9
                             WHERE id = $10`,
                            [q.q_en, q.q_hu, q.topic_id, parseInt(q.bloom) || 1, q.type || 'single_choice',
                            q.correctAns, optionsJson, q.expEn || '', q.expHu || '', q.db_id]
                        );
                    } else {
                        // INSERT new
                        await client.query(
                            `INSERT INTO questions 
                             (question_text_en, question_text_hu, topic_id, bloom_level, difficulty, type, question_type, correct_answer, options, explanation_en, explanation_hu, created_by)
                             VALUES ($1, $2, $3, $4, $4, $5, $5, $6, $7, $8, $9, $10)`,
                            [q.q_en || '', q.q_hu || '', q.topic_id, parseInt(q.bloom) || 1, q.type || 'single_choice',
                            q.correctAns || '', optionsJson, q.expEn || '', q.expHu || '', req.user.id]
                        );
                    }
                    successCount++;
                } catch (err) {
                    errors.push(`Row ${i + 2}: ${err.message}`);
                }
            }

            if (errors.length > 0 && successCount === 0) {
                await client.query('ROLLBACK');
                return res.status(400).json({ message: 'Upload failed', errors });
            }

            await client.query('COMMIT');
            res.json({ message: `Successfully processed ${successCount} questions`, errors: errors.length > 0 ? errors : null });
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    } catch (error) {
        console.error('Error in adminBatchUpload:', error);
        res.status(500).json({ message: 'Server error during batch upload' });
    }
};

/**
 * @desc Admin: Get "Wall of Pain" analytics (Pedagogical insights)
 */
exports.getWallOfPain = async (req, res) => {
    try {
        // 1. Top Failed Questions (Questions with most incorrect responses)
        const failedQuestionsQuery = `
            SELECT 
                q.id, 
                q.question_text_en, 
                q.question_text_hu,
                t.name_en as topic_name,
                COUNT(r.id) as failure_count,
                (
                    SELECT json_agg(sub.wrong_answer) 
                    FROM (
                        SELECT user_answer as wrong_answer, COUNT(*) as cnt
                        FROM responses 
                        WHERE question_id = q.id AND is_correct = false
                        GROUP BY user_answer
                        ORDER BY cnt DESC
                        LIMIT 3
                    ) sub
                ) as common_wrong_answers
            FROM responses r
            JOIN questions q ON r.question_id = q.id
            JOIN topics t ON q.topic_id = t.id
            WHERE r.is_correct = false
            GROUP BY q.id, t.name_en
            ORDER BY failure_count DESC
            LIMIT 10
        `;

        // 2. Most Difficult Topics (Topics with lowest success rates)
        const difficultTopicsQuery = `
            SELECT 
                t.id, 
                t.name_en, 
                t.name_hu,
                COUNT(r.id) as total_attempts,
                SUM(CASE WHEN r.is_correct THEN 1 ELSE 0 END) as correct_count,
                (SUM(CASE WHEN r.is_correct THEN 1 ELSE 0 END)::float / NULLIF(COUNT(r.id), 0)::float) * 100 as success_rate
            FROM responses r
            JOIN questions q ON r.question_id = q.id
            JOIN topics t ON q.topic_id = t.id
            GROUP BY t.id
            HAVING COUNT(r.id) > 5
            ORDER BY success_rate ASC
            LIMIT 5
        `;

        const [failedQuestions, difficultTopics] = await Promise.all([
            db.query(failedQuestionsQuery),
            db.query(difficultTopicsQuery)
        ]);

        res.json({
            failedQuestions: failedQuestions.rows,
            difficultTopics: difficultTopics.rows
        });
    } catch (error) {
        console.error('Error in getWallOfPain:', error);
        res.status(500).json({ message: 'Server error' });
    }
};
