const ecgController = require('../../src/controllers/ecgController');
const db = require('../../src/config/db');
const AppError = require('../../src/utils/AppError');

jest.mock('../../src/config/db', () => ({
    query: jest.fn(),
    pool: { on: jest.fn() }
}));

jest.mock('../../src/utils/catchAsync', () => (fn) => (req, res, next) => {
    return fn(req, res, next).catch(next);
});

describe('ecgController', () => {
    let req, res, next;

    beforeEach(() => {
        req = {
            user: { id: 'usr-1', role: 'student' },
            body: {},
            query: {},
            params: {}
        };
        res = {
            json: jest.fn(),
            status: jest.fn().mockReturnThis()
        };
        next = jest.fn();
        jest.clearAllMocks();
    });

    describe('getDiagnoses', () => {
        it('should return all diagnoses ordered by code', async () => {
            const mockRows = [
                { id: 1, code: 'AFIB', name_en: 'Atrial Fibrillation' },
                { id: 2, code: 'STEMI_INF', name_en: 'Inferior STEMI' }
            ];
            db.query.mockResolvedValueOnce({ rows: mockRows });

            await ecgController.getDiagnoses(req, res, next);

            expect(db.query).toHaveBeenCalledWith('SELECT * FROM ecg_diagnoses ORDER BY code ASC');
            expect(res.json).toHaveBeenCalledWith(mockRows);
        });
    });

    describe('createDiagnosis', () => {
        it('should insert and return new diagnosis', async () => {
            req.body = {
                code: 'VT',
                name_en: 'Ventricular Tachycardia',
                name_hu: 'Kamrai Tachycardia',
                description_en: 'Broad QRS tachycardia',
                description_hu: 'Szeles QRS tachycardia',
                severity_level: 'critical'
            };
            const mockRow = { id: 3, ...req.body };
            db.query.mockResolvedValueOnce({ rows: [mockRow] });

            await ecgController.createDiagnosis(req, res, next);

            expect(res.status).toHaveBeenCalledWith(201);
            expect(res.json).toHaveBeenCalledWith(mockRow);
        });

        it('should return 409 conflict when diagnosis code already exists', async () => {
            req.body = { code: 'AFIB' };
            const error = new Error('duplicate key');
            error.code = '23505';
            db.query.mockRejectedValueOnce(error);

            await ecgController.createDiagnosis(req, res, next);

            expect(next).toHaveBeenCalledWith(expect.any(AppError));
            const calledError = next.mock.calls[0][0];
            expect(calledError.statusCode).toBe(409);
        });
    });

    describe('getCases', () => {
        it('should return cases and sanitize diagnosis text for students while preserving diagnosis_id', async () => {
            const rawCases = [
                {
                    id: 10,
                    diagnosis_id: 1,
                    diagnosis_code: 'AFIB',
                    diagnosis_name: 'Atrial Fibrillation',
                    difficulty: 'beginner',
                    image_url: '/uploads/ecg/case_001.png'
                }
            ];
            db.query.mockResolvedValueOnce({ rows: rawCases });

            await ecgController.getCases(req, res, next);

            expect(res.json).toHaveBeenCalled();
            const output = res.json.mock.calls[0][0];
            expect(output).toHaveLength(1);
            expect(output[0].id).toBe(10);
            expect(output[0].diagnosis_id).toBe(1); // Preserved for client validation
            expect(output[0].diagnosis_code).toBeUndefined(); // Stripped
            expect(output[0].diagnosis_name).toBeUndefined(); // Stripped
        });

        it('should filter by difficulty when specified in query', async () => {
            req.query.difficulty = 'advanced';
            db.query.mockResolvedValueOnce({ rows: [] });

            await ecgController.getCases(req, res, next);

            expect(db.query).toHaveBeenCalledWith(
                expect.stringContaining('WHERE c.difficulty = $1'),
                ['advanced']
            );
        });

        it('should not sanitize diagnosis text if user is admin', async () => {
            req.user.role = 'admin';
            const rawCases = [
                {
                    id: 10,
                    diagnosis_id: 1,
                    diagnosis_code: 'AFIB',
                    diagnosis_name: 'Atrial Fibrillation'
                }
            ];
            db.query.mockResolvedValueOnce({ rows: rawCases });

            await ecgController.getCases(req, res, next);

            const output = res.json.mock.calls[0][0];
            expect(output[0].diagnosis_code).toBe('AFIB');
            expect(output[0].diagnosis_name).toBe('Atrial Fibrillation');
        });
    });

    describe('getCaseById', () => {
        it('should return 404 when case does not exist', async () => {
            req.params.id = 999;
            db.query.mockResolvedValueOnce({ rows: [] });

            await ecgController.getCaseById(req, res, next);

            expect(next).toHaveBeenCalledWith(expect.any(AppError));
            expect(next.mock.calls[0][0].statusCode).toBe(404);
        });

        it('should return sanitized case for students', async () => {
            req.params.id = 1;
            const rawCase = {
                id: 1,
                diagnosis_id: 2,
                diagnosis_code: 'STEMI_INF',
                diagnosis_name: 'Inferior STEMI',
                description_en: 'ST elevation in II, III, aVF',
                image_url: '/uploads/ecg/case_001.png'
            };
            db.query.mockResolvedValueOnce({ rows: [rawCase] });

            await ecgController.getCaseById(req, res, next);

            const output = res.json.mock.calls[0][0];
            expect(output.id).toBe(1);
            expect(output.diagnosis_id).toBe(2);
            expect(output.diagnosis_code).toBeUndefined();
            expect(output.description_en).toBeUndefined();
        });
    });

    describe('createCase, updateCase, deleteCase', () => {
        it('should create an ECG case', async () => {
            req.body = {
                diagnosis_id: 2,
                image_url: '/uploads/ecg/case_002.png',
                difficulty: 'intermediate',
                findings_json: { rhythm: 'sinus' }
            };
            db.query.mockResolvedValueOnce({ rows: [{ id: 5, ...req.body }] });

            await ecgController.createCase(req, res, next);

            expect(res.status).toHaveBeenCalledWith(201);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ id: 5 }));
        });

        it('should delete an ECG case', async () => {
            req.params.id = 5;
            db.query.mockResolvedValueOnce({ rows: [{ id: 5 }] });

            await ecgController.deleteCase(req, res, next);

            expect(res.json).toHaveBeenCalledWith({ message: 'Deleted successfully' });
        });
    });
});
