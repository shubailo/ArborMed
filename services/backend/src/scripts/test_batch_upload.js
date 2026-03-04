const { adminBatchUpload } = require('../controllers/adminQuestionController');
const AdminExcelService = require('../services/adminExcelService');
const db = require('../config/db');

async function testQueryGeneration() {
    const questions = [
        {
            topic_id: 1,
            q_en: 'Insert Q',
            bloom: 2,
            type: 'single_choice',
            correctAns: 'A',
            optEn: 'A;B'
        },
        {
            topic_id: 1,
            q_en: 'Update Q',
            bloom: 3,
            db_id: 42
        }
    ];

    AdminExcelService.parseFile = async () => questions;

    const queries = [];
    const mockClient = {
        query: async (sql, params) => {
            queries.push({ sql, params });
            return { rows: [] };
        },
        release: () => {}
    };

    db.pool.connect = async () => mockClient;

    const req = {
        file: { buffer: Buffer.from('test'), mimetype: 'excel' },
        user: { id: 1 }
    };

    await new Promise((resolve) => {
        const res = { json: resolve, status: () => res };
        adminBatchUpload(req, res, (err) => resolve(err));
    });

    console.log(JSON.stringify(queries, null, 2));
}

testQueryGeneration().catch(console.error);
