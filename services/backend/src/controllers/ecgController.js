const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

// --- Diagnoses ---

exports.getDiagnoses = catchAsync(async (req, res, next) => {
    const result = await db.query('SELECT * FROM ecg_diagnoses ORDER BY code ASC');
    res.json(result.rows);
});

exports.createDiagnosis = catchAsync(async (req, res, next) => {
    const { code, name_en, name_hu, description_en, description_hu, severity_level } = req.body;

    try {
        const result = await db.query(
            `INSERT INTO ecg_diagnoses (code, name_en, name_hu, description_en, description_hu, severity_level)
             VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
            [code, name_en, name_hu, description_en, description_hu, severity_level]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        if (err.code === '23505') {
            return next(new AppError('Diagnosis code already exists', 409));
        }
        throw err;
    }
});

// --- Cases ---

exports.getCases = catchAsync(async (req, res, next) => {
    const { difficulty } = req.query;
    let query = `
      SELECT c.*, d.code as diagnosis_code, d.name_en as diagnosis_name 
      FROM ecg_cases c
      JOIN ecg_diagnoses d ON c.diagnosis_id = d.id
    `;
    const params = [];

    if (difficulty) {
        query += ` WHERE c.difficulty = $1`;
        params.push(difficulty);
    }

    query += ` ORDER BY c.created_at DESC`;

    const result = await db.query(query, params);

    // Security: Remove diagnosis info for students
    const sanitizedRows = result.rows.map(row => {
        if (req.user.role !== 'admin') {
            const { diagnosis_id, diagnosis_code, diagnosis_name, ...rest } = row;
            return rest;
        }
        return row;
    });

    res.json(sanitizedRows);
});

exports.getCaseById = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const result = await db.query(`
        SELECT c.*, d.code as diagnosis_code, d.name_en as diagnosis_name, d.description_en, d.description_hu
        FROM ecg_cases c
        JOIN ecg_diagnoses d ON c.diagnosis_id = d.id
        WHERE c.id = $1
    `, [id]);

    if (result.rows.length === 0) {
        return next(new AppError('Case not found', 404));
    }

    const ecgCase = result.rows[0];

    // Security: Remove diagnosis info for students
    if (req.user.role !== 'admin') {
        delete ecgCase.diagnosis_id;
        delete ecgCase.diagnosis_code;
        delete ecgCase.diagnosis_name;
        delete ecgCase.description_en;
        delete ecgCase.description_hu;
    }

    res.json(ecgCase);
});

exports.createCase = catchAsync(async (req, res, next) => {
    const { diagnosis_id, image_url, difficulty, findings_json, secondary_diagnoses_ids } = req.body;
    const result = await db.query(
        `INSERT INTO ecg_cases (diagnosis_id, image_url, difficulty, findings_json, secondary_diagnoses_ids)
         VALUES ($1, $2, $3, $4, $5) RETURNING *`,
        [diagnosis_id, image_url, difficulty, findings_json, secondary_diagnoses_ids || []]
    );
    res.status(201).json(result.rows[0]);
});

exports.updateCase = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const { diagnosis_id, image_url, difficulty, findings_json, secondary_diagnoses_ids } = req.body;

    const result = await db.query(
        `UPDATE ecg_cases 
         SET diagnosis_id = $1, image_url = $2, difficulty = $3, findings_json = $4, secondary_diagnoses_ids = $5
         WHERE id = $6 RETURNING *`,
        [diagnosis_id, image_url, difficulty, findings_json, secondary_diagnoses_ids || [], id]
    );

    if (result.rows.length === 0) {
        return next(new AppError('Case not found', 404));
    }
    res.json(result.rows[0]);
});

exports.deleteCase = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const result = await db.query('DELETE FROM ecg_cases WHERE id = $1 RETURNING id', [id]);
    if (result.rows.length === 0) {
        return next(new AppError('Case not found', 404));
    }
    res.json({ message: 'Deleted successfully' });
});
