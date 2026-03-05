const { adminBatchUpload } = require('../controllers/adminQuestionController');
const AdminExcelService = require('../services/adminExcelService');
const db = require('../config/db');

async function runBenchmark() {
    console.log("Starting benchmark...");

    const numQuestions = 1000;
    const questions = [];
    for (let i = 0; i < numQuestions; i++) {
        questions.push({
            topic_id: 1,
            q_en: 'Question ' + i,
            q_hu: 'Kérdés ' + i,
            bloom: 1,
            type: 'single_choice',
            correctAns: 'A',
            optEn: 'A;B;C;D',
            optHu: 'A;B;C;D',
            expEn: 'Exp ' + i,
            expHu: 'Magy ' + i,
            db_id: i % 2 === 0 ? i + 1 : undefined // half update, half insert
        });
    }

    // Mock Excel Service
    AdminExcelService.parseFile = async () => questions;

    let queryCount = 0;

    const mockClient = {
        query: async (..._args) => {
            queryCount++;
            return { rows: [] };
        },
        release: () => {}
    };

    db.pool.connect = async () => mockClient;
    db.query = async (..._args) => {
        queryCount++;
        return { rows: [] };
    };

    const req = {
        file: { buffer: Buffer.from('test'), mimetype: 'application/vnd.ms-excel' },
        user: { id: 1 }
    };

    let responseData = null;
    const res = {
        json: (data) => { responseData = data; },
        status: () => res
    };

    const _next = (err) => console.log('Next called with:', err);

    const start = Date.now();
    // adminBatchUpload is wrapped with catchAsync, which returns a function
    // taking req, res, next. Let's call it and await it if possible, though it doesn't return a promise directly if we just call it.
    // wait, catchAsync does this: fn(req, res, next).catch(next);
    // So we need to await the inner function.
    // Let's just create a wrapper to run it safely
    await new Promise((resolve) => {
        const customRes = {
            json: (data) => {
                responseData = data;
                resolve();
            },
            status: () => customRes
        };
        const customNext = (err) => {
            console.log('Next called with:', err);
            resolve();
        };
        adminBatchUpload(req, customRes, customNext);
    });

    const end = Date.now();

    console.log(`Benchmark finished in ${end - start} ms`);
    console.log(`Total queries executed: ${queryCount}`);
    console.log(`Response: ${JSON.stringify(responseData)}`);
}

runBenchmark().catch(console.error);
