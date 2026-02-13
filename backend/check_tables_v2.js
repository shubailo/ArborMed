const db = require('./src/config/db');

async function checkTable() {
    try {
        const q1 = await db.query(`SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'question_reports');`);
        console.log('CHECK: question_reports exists =', q1.rows[0].exists);

        const q2 = await db.query(`SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'question_performance');`);
        console.log('CHECK: question_performance exists =', q2.rows[0].exists);
    } catch (err) {
        console.error('DIAGNOSTIC FAILED:', err.message);
    } finally {
        process.exit();
    }
}

checkTable();
