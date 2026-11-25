const db = require('../config/db');
const { questionScope, questionFilter } = require('../services/adminQuestionAccess');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

/**
 * @desc Report an issue with a question
 * POST /api/reports
 */
exports.submitReport = catchAsync(async (req, res, next) => {
    const { questionId, reasonCategory, description } = req.body;
    const userId = req.user.id;

    if (!questionId || !reasonCategory) {
        return next(new AppError('Question ID and Reason are required.', 400));
    }

    const result = await db.query(
        `INSERT INTO question_reports (question_id, user_id, reason_category, description)
         VALUES ($1, $2, $3, $4) RETURNING id`,
        [questionId, userId, reasonCategory, description]
    );

    res.status(201).json({
        message: 'Report submitted successfully.',
        reportId: result.rows[0].id
    });
});

/**
 * @desc Get reports for a specific question (Admin)
 * GET /api/reports/question/:id
 */
exports.getReportsByQuestion = catchAsync(async (req, res) => {
    const { id } = req.params;
    const params = [id];
    const allowed = questionFilter(await questionScope(req.user), params);
    const result = await db.query(
        `SELECT r.*, u.email as reporter_email 
         FROM question_reports r
         JOIN users u ON r.user_id = u.id
         JOIN questions q ON q.id = r.question_id
         WHERE r.question_id = $1 AND ${allowed}
         ORDER BY r.created_at DESC`,
        params
    );

    res.json(result.rows);
});

/**
 * @desc Resolve or update report status (Admin)
 * PATCH /api/reports/:id
 */
exports.updateReportStatus = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const { status, adminNotes } = req.body;

    if (!['pending', 'resolved', 'ignored'].includes(status)) {
        return next(new AppError('Invalid status.', 400));
    }

    const params = [status, adminNotes, id];
    const allowed = questionFilter(await questionScope(req.user), params);
    const result = await db.query(
        `UPDATE question_reports r
         SET status = $1, admin_notes = $2, updated_at = CURRENT_TIMESTAMP
         FROM questions q
         WHERE r.id = $3 AND q.id = r.question_id AND ${allowed} RETURNING r.*`,
        params
    );

    if (result.rows.length === 0) {
        return next(new AppError('Report not found.', 404));
    }

    res.json(result.rows[0]);
});
