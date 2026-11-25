const db = require('../config/db');
const AppError = require('../utils/AppError');
const catchAsync = require('../utils/catchAsync');

const fs = require('fs');
const path = require('path');
const LOCAL_CASES_PATH = path.join(__dirname, '../../data/ecg_cases.json');

// --- Diagnoses ---

exports.getDiagnoses = catchAsync(async (req, res, _next) => {
    try {
        const result = await db.query('SELECT * FROM ecg_diagnoses ORDER BY code ASC');
        res.json(result.rows);
    } catch (err) {
        if (process.env.NODE_ENV === 'development' && fs.existsSync(LOCAL_CASES_PATH)) {
            const raw = JSON.parse(fs.readFileSync(LOCAL_CASES_PATH, 'utf8'));
            const list = raw.diagnoses || [];
            return res.json(list.map((d, i) => ({ id: i + 1, ...d })));
        }
        throw err;
    }
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

exports.getCases = catchAsync(async (req, res, _next) => {
    const { difficulty } = req.query;
    let query = `
      SELECT c.*, d.code as diagnosis_code, d.name_en as diagnosis_name, d.name_hu AS diagnosis_name_hu
      FROM ecg_cases c
      JOIN ecg_diagnoses d ON c.diagnosis_id = d.id
    `;
    const params = [];

    if (difficulty) {
        query += ` WHERE c.difficulty = $1`;
        params.push(difficulty);
    }

    query += ` ORDER BY c.created_at DESC`;

    let rows;
    try {
        const result = await db.query(query, params);
        rows = result.rows;
    } catch (err) {
        if (process.env.NODE_ENV === 'development' && fs.existsSync(LOCAL_CASES_PATH)) {
            const raw = JSON.parse(fs.readFileSync(LOCAL_CASES_PATH, 'utf8'));
            const list = raw.cases || [];
            const diagnoses = new Map(raw.diagnoses.map((d, i) => [d.code, i + 1]));
            rows = list.map((c, idx) => ({
                ...c,
                id: c.case_number || (idx + 1),
                case_number: c.case_number,
                diagnosis_id: diagnoses.get(c.diagnosis_code),
                diagnosis_code: c.diagnosis_code,
                diagnosis_name: c.diagnosis_name_en,
                diagnosis_name_hu: c.diagnosis_name_hu,
                difficulty: c.difficulty,
                image_url: c.image_url,
                findings_json: c.findings_json,
                created_at: new Date()
            }));
            if (difficulty) {
                rows = rows.filter(r => r.difficulty === difficulty);
            }
        } else {
            throw err;
        }
    }

    res.json(rows.map(row => presentCase(row, req.user.role)));
});

function presentCase(row, role) {
    if (role === 'admin') return row;
    const history = row.findings_json?.history;
    return {
        id: row.id, image_url: row.image_url, difficulty: row.difficulty,
        findings_json: history ? { history } : {},
    };
}

async function findCase(id) {
    try {
        const result = await db.query(`
            SELECT c.*, d.code AS diagnosis_code, d.name_en AS diagnosis_name, d.name_hu AS diagnosis_name_hu, d.description_en, d.description_hu
            FROM ecg_cases c JOIN ecg_diagnoses d ON c.diagnosis_id = d.id
            WHERE c.id = $1
        `, [id]);
        return result.rows[0];
    } catch (err) {
        if (process.env.NODE_ENV !== 'development' || !fs.existsSync(LOCAL_CASES_PATH)) throw err;
        const raw = JSON.parse(await fs.promises.readFile(LOCAL_CASES_PATH, 'utf8'));
        const row = raw.cases?.find((item, i) => (item.case_number || i + 1) === Number(id));
        if (!row) return undefined;
        const diagnosis = raw.diagnoses.findIndex(item => item.code === row.diagnosis_code);
        return { ...row, id: Number(id), diagnosis_id: diagnosis + 1 };
    }
}

exports.getCaseById = catchAsync(async (req, res, next) => {
    const row = await findCase(req.params.id);
    if (!row) return next(new AppError('Case not found', 404));
    res.json(presentCase(row, req.user.role));
});

// In self-directed practice, release the detailed rubric after a diagnosis has been submitted.
exports.submitInterpretation = catchAsync(async (req, res, next) => {
    const { diagnosisId, secondaryDiagnosisIds = [] } = req.body;
    if (!Number.isSafeInteger(diagnosisId) || diagnosisId < 1 || !Array.isArray(secondaryDiagnosisIds) ||
        !secondaryDiagnosisIds.every(id => Number.isSafeInteger(id) && id > 0)) {
        return next(new AppError('Select a valid diagnosis', 400));
    }
    const row = await findCase(req.params.id);
    if (!row) return next(new AppError('Case not found', 404));
    const expected = new Set(row.secondary_diagnoses_ids || []);
    const selected = new Set(secondaryDiagnosisIds);
    const secondaryCorrect = expected.size === selected.size && [...expected].every(id => selected.has(id));
    res.json({ case: row, primaryCorrect: diagnosisId === row.diagnosis_id, secondaryCorrect });
});

async function validateCase(body) {
    const {diagnosis_id, image_url, findings_json, secondary_diagnoses_ids: secondary} = body;
    const validId = id => Number.isInteger(id) && id > 0 && id <= 2147483647;
    if (!validId(diagnosis_id) || typeof image_url !== 'string' || !image_url.trim() ||
        !findings_json || typeof findings_json !== 'object' || Array.isArray(findings_json)) {
        throw new AppError('A primary diagnosis, an image and case findings are required.', 400);
    }
    if (secondary !== undefined && (!Array.isArray(secondary) || !secondary.every(validId) ||
        secondary.includes(diagnosis_id) || new Set(secondary).size !== secondary.length)) {
        throw new AppError('Select distinct secondary diagnoses different from the primary diagnosis.', 400);
    }
    if (secondary?.length) {
        const found = await db.query('SELECT id FROM ecg_diagnoses WHERE id = ANY($1::int[])', [secondary]);
        if (found.rows.length !== secondary.length) throw new AppError('Unknown secondary diagnosis.', 400);
    }
}

async function writeCase(sql, params) {
    try {
        return await db.query(sql, params);
    } catch (error) {
        if (error.code === '23503') throw new AppError('Unknown primary diagnosis.', 400);
        throw error;
    }
}

exports.createCase = catchAsync(async (req, res, _next) => {
    const { diagnosis_id, image_url, difficulty, findings_json, secondary_diagnoses_ids } = req.body;
    await validateCase(req.body);
    const result = await writeCase(
        `INSERT INTO ecg_cases (diagnosis_id, image_url, difficulty, findings_json, secondary_diagnoses_ids)
         VALUES ($1, $2, $3, $4, $5) RETURNING *`,
        [diagnosis_id, image_url, difficulty, findings_json, secondary_diagnoses_ids || []]
    );
    res.status(201).json(result.rows[0]);
});

exports.updateCase = catchAsync(async (req, res, next) => {
    const { id } = req.params;
    const { diagnosis_id, image_url, difficulty, findings_json, secondary_diagnoses_ids } = req.body;

    await validateCase(req.body);
    const result = await writeCase(
        `UPDATE ecg_cases 
         SET diagnosis_id = $1, image_url = $2, difficulty = $3, findings_json = $4,
             secondary_diagnoses_ids = COALESCE($5::int[], array_remove(secondary_diagnoses_ids, $1))
         WHERE id = $6 RETURNING *`,
        [diagnosis_id, image_url, difficulty, findings_json, secondary_diagnoses_ids, id]
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
