const db = require('../config/db');
const questionTypeRegistry = require('../services/questionTypes/registry');
const AdminExcelService = require('../services/adminExcelService');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');


/**
 * @desc Get all questions with pagination and search
 * @route GET /api/quiz/admin/questions
 */
exports.adminGetQuestions = catchAsync(async (req, res, next) => {
    const { page = 1, limit = 200, search = '', type = '', bloom_level = '', topic_id = '', sortBy = 'created_at', order = 'DESC' } = req.query;
    const offset = (page - 1) * limit;

    const sortMap = {
        'id': 'q.id',
        'type': 'q.type',
        'bloom_level': 'q.bloom_level',
        'topic_name': 't.name_en',
        'attempts': 'attempts',
        'success_rate': 'success_rate',
        'created_at': 'q.created_at'
    };

    const orderBy = sortMap[sortBy] || 'q.created_at';
    const sortOrder = order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    let query = `
        SELECT 
            q.id, q.question_text_en as text, q.question_text_hu, q.type, q.question_type, q.bloom_level, q.difficulty,
            q.options, q.correct_answer, q.explanation_en as explanation, q.explanation_hu, q.topic_id,
            t.name_en as topic_name, t.name_hu as topic_name_hu, t.slug as topic_slug,
            COALESCE(qp.total_attempts, 0) as attempts, COALESCE(qp.success_rate, 0) as success_rate,
            (SELECT COUNT(*)::int FROM question_reports qr WHERE qr.question_id = q.id AND qr.status = 'pending') as report_count
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
        conditions.push(`q.topic_id IN (
            WITH subtopics AS (
                SELECT id FROM topics WHERE id = $${params.length}
                OR parent_id IN (SELECT id FROM topics WHERE id = $${params.length})
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

    let results, countResult;
    try {
        [results, countResult] = await Promise.all([
            db.query(query, [...params, limit, offset]),
            db.query(countQuery, params)
        ]);
    } catch (dbError) {
        // Handle missing question_reports table fallback
        if (dbError.code === '42P01' && query.includes('question_reports')) {
            const sanitizedQuery = query.replace(/\(SELECT COUNT\(\*\)::int FROM question_reports[\s\S]*?\)/, '0 as report_count');
            [results, countResult] = await Promise.all([
                db.query(sanitizedQuery, [...params, limit, offset]),
                db.query(countQuery, params)
            ]);
        } else throw dbError;
    }

    const preparedQuestions = results.rows.map(q => questionTypeRegistry.prepareForAdmin(q));

    res.json({
        questions: preparedQuestions,
        total: parseInt(countResult.rows[0].count),
        page: parseInt(page),
        limit: parseInt(limit)
    });
});


/**
 * @desc Create a new question
 * @route POST /api/quiz/admin/questions
 */
exports.adminCreateQuestion = catchAsync(async (req, res, next) => {
    const {
        question_type, content, correct_answer,
        topic_id, difficulty, bloom_level, metadata,
        question_text_en, question_text_hu,
        explanation_en, explanation_hu,
        options_en, options_hu
    } = req.body;

    if (!topic_id) {
        return next(new AppError('A Topic (Section) MUST be selected for every question.', 400));
    }

    const typeId = question_type || 'single_choice';

    let optionsJson = {};
    if (options_en || options_hu) {
        optionsJson = {
            en: options_en || [],
            hu: options_hu || []
        }
    }

    const definitionOptions = JSON.stringify(optionsJson);

    // Subject-based permission check
    const isSuperAdmin = req.user.email === process.env.SUPER_ADMIN_EMAIL;
    if (!isSuperAdmin && req.user.assigned_subject_id !== topic_id) {
        const userCheck = await db.query('SELECT assigned_subject_id FROM users WHERE id = $1', [req.user.id]);
        const assignedSubject = userCheck.rows[0]?.assigned_subject_id;

        if (assignedSubject && assignedSubject !== topic_id) {
            return next(new AppError('You can only create questions in your assigned subject', 403));
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
        content || {},
        correct_answer,
        explanation_en || '',
        explanation_hu || '',
        topic_id,
        difficulty || bloom_level || 1,
        bloom_level || difficulty || 1,
        metadata || {},
        question_text_en || '',
        question_text_hu || '',
        definitionOptions,
        typeId,
        req.user.id
    ]);

    res.status(201).json(result.rows[0]);
});

/**
 * @desc Update a question
 * @route PUT /api/quiz/admin/questions/:id
 */
exports.adminUpdateQuestion = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const {
        question_type, content, correct_answer,
        topic_id, difficulty, bloom_level, metadata,
        question_text_en, question_text_hu,
        explanation_en, explanation_hu,
        options_en, options_hu
    } = req.body;

    const isSuperAdmin = req.user.email === process.env.SUPER_ADMIN_EMAIL;
    if (!isSuperAdmin) {
        const questionCheck = await db.query(`
            SELECT q.topic_id, q.created_by, u.assigned_subject_id
            FROM questions q
            LEFT JOIN users u ON u.id = $2
            WHERE q.id = $1
        `, [id, req.user.id]);

        if (questionCheck.rows.length === 0) {
            return next(new AppError('Question not found', 404));
        }

        const question = questionCheck.rows[0];
        const userAssignedSubject = question.assigned_subject_id;
        const canEdit = question.created_by === req.user.id || (userAssignedSubject && question.topic_id === userAssignedSubject);

        if (!canEdit) {
            return next(new AppError('You can only edit questions in your assigned subject or questions you created', 403));
        }
    }

    let optionsJson = {};
    if (options_en || options_hu) {
        optionsJson = { en: options_en || [], hu: options_hu || [] };
    }
    const definitionOptions = JSON.stringify(optionsJson);

    const query = `
        UPDATE questions
        SET question_text_en = $1, question_text_hu = $2, explanation_en = $3, explanation_hu = $4,
            options = $5, correct_answer = $6, topic_id = $7, difficulty = $8, bloom_level = $9, 
            type = $10, content = $12, metadata = $13, updated_at = NOW()
        WHERE id = $14
        RETURNING *
    `;

    const result = await db.query(query, [
        question_text_en || '', question_text_hu || '', explanation_en || '', explanation_hu || '',
        definitionOptions, correct_answer, topic_id, difficulty || bloom_level || 1, bloom_level || difficulty || 1,
        question_type || 'single_choice', question_type || 'single_choice', content || {}, metadata || {}, id
    ]);

    if (result.rows.length === 0) {
        return next(new AppError('Question not found', 404));
    }
    res.json(result.rows[0]);
});


/**
 * @desc Delete a question
 * @route DELETE /api/quiz/admin/questions/:id
 */
exports.adminDeleteQuestion = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const respCheck = await db.query('SELECT COUNT(*) FROM responses WHERE question_id = $1', [id]);

    if (parseInt(respCheck.rows[0].count) > 0) {
        return next(new AppError('Cannot delete question with existing student responses. Consider soft-deleting (feature pending).', 400));
    }

    const result = await db.query('DELETE FROM questions WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) return next(new AppError('Question not found', 404));
    res.json({ message: 'Question deleted successfully' });
});


/**
 * @desc Admin: Bulk action on questions
 * @route POST /api/quiz/admin/questions/bulk
 */
exports.adminBulkAction = catchAsync(async (req, res, next) => {
    const { action, ids, targetTopicId } = req.body;

    if (!ids || !Array.isArray(ids) || ids.length === 0) {
        return next(new AppError('No question IDs provided', 400));
    }

    const client = await db.pool.connect();
    try {
        await client.query('BEGIN');
        if (action === 'delete') {
            const respCheck = await client.query('SELECT question_id FROM responses WHERE question_id = ANY($1)', [ids]);
            const questionsWithResponses = [...new Set(respCheck.rows.map(r => r.question_id))];

            if (questionsWithResponses.length > 0) {
                await client.query('ROLLBACK');
                return next(new AppError('Some questions have student responses and cannot be deleted.', 400));
            }
            await client.query('DELETE FROM questions WHERE id = ANY($1)', [ids]);
        } else if (action === 'move') {
            if (!targetTopicId) {
                await client.query('ROLLBACK');
                return next(new AppError('Target topic ID is required for move action', 400));
            }
            await client.query('UPDATE questions SET topic_id = $1 WHERE id = ANY($2)', [targetTopicId, ids]);
        } else {
            await client.query('ROLLBACK');
            return next(new AppError('Invalid action', 400));
        }
        await client.query('COMMIT');
        res.json({ message: `Bulk ${action} successful` });
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
});


/**
 * @desc Admin: Download Excel Template
 * @route GET /api/quiz/admin/questions/template
 */
exports.adminDownloadTemplate = catchAsync(async (req, res, next) => {
    const workbook = await AdminExcelService.generateTemplate();
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename=QUESTION_TEMPLATE.xlsx');
    await workbook.xlsx.write(res);
    res.end();
});


/**
 * @desc Admin: Batch upload questions (Excel/CSV)
 * @route POST /api/quiz/admin/questions/batch
 */
exports.adminBatchUpload = catchAsync(async (req, res, next) => {
    if (!req.file) {
        return next(new AppError('No file uploaded', 400));
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
                if (!q.topic_id) throw new Error(`Invalid or missing topic: ${q.topic}`);

                const optListEn = q.optEn ? q.optEn.toString().split(';') : [];
                const optListHu = q.optHu ? q.optHu.toString().split(';') : [];
                const optionsJson = JSON.stringify({ en: optListEn, hu: optListHu });

                if (q.db_id) {
                    await client.query(
                        `UPDATE questions SET question_text_en = $1, question_text_hu = $2, topic_id = $3, difficulty = $4, bloom_level = $4, type = $5, question_type = $5, correct_answer = $6, options = $7, explanation_en = $8, explanation_hu = $9 WHERE id = $10`,
                        [q.q_en, q.q_hu, q.topic_id, parseInt(q.bloom) || 1, q.type || 'single_choice', q.correctAns, optionsJson, q.expEn || '', q.expHu || '', q.db_id]
                    );
                } else {
                    await client.query(
                        `INSERT INTO questions (question_text_en, question_text_hu, topic_id, bloom_level, difficulty, type, question_type, correct_answer, options, explanation_en, explanation_hu, created_by) VALUES ($1, $2, $3, $4, $4, $5, $5, $6, $7, $8, $9, $10)`,
                        [q.q_en || '', q.q_hu || '', q.topic_id, parseInt(q.bloom) || 1, q.type || 'single_choice', q.correctAns || '', optionsJson, q.expEn || '', q.expHu || '', req.user.id]
                    );
                }
                successCount++;
            } catch (err) {
                errors.push(`Row ${i + 2}: ${err.message}`);
            }
        }
        if (errors.length > 0 && successCount === 0) {
            await client.query('ROLLBACK');
            return next(new AppError('Upload failed: ' + errors.join(', '), 400));
        }
        await client.query('COMMIT');
        res.json({ message: `Successfully processed ${successCount} questions`, errors: errors.length > 0 ? errors : null });
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
});


/**
 * @desc Admin: Get "Wall of Pain" analytics
 * @route GET /api/quiz/admin/analytics/wall-of-pain
 */
exports.getWallOfPain = catchAsync(async (req, res, next) => {
    const failedQuestionsQuery = `
        SELECT q.id, q.question_text_en, q.question_text_hu, t.name_en as topic_name, COUNT(r.id) as failure_count,
        (SELECT json_agg(sub.wrong_answer) FROM (SELECT user_answer as wrong_answer, COUNT(*) as cnt FROM responses WHERE question_id = q.id AND is_correct = false GROUP BY user_answer ORDER BY cnt DESC LIMIT 3) sub) as common_wrong_answers
        FROM responses r JOIN questions q ON r.question_id = q.id JOIN topics t ON q.topic_id = t.id WHERE r.is_correct = false
        GROUP BY q.id, t.name_en ORDER BY failure_count DESC LIMIT 10
    `;
    const difficultTopicsQuery = `
        SELECT t.id, t.name_en, t.name_hu, COUNT(r.id) as total_attempts, SUM(CASE WHEN r.is_correct THEN 1 ELSE 0 END) as correct_count,
        (SUM(CASE WHEN r.is_correct THEN 1 ELSE 0 END)::float / NULLIF(COUNT(r.id), 0)::float) * 100 as success_rate
        FROM responses r JOIN questions q ON r.question_id = q.id JOIN topics t ON q.topic_id = t.id GROUP BY t.id HAVING COUNT(r.id) > 5 ORDER BY success_rate ASC LIMIT 5
    `;

    const [failedQuestions, difficultTopics] = await Promise.all([
        db.query(failedQuestionsQuery),
        db.query(difficultTopicsQuery)
    ]);

    res.json({
        failedQuestions: failedQuestions.rows,
        difficultTopics: difficultTopics.rows
    });
});
