const db = require('./src/config/db');

async function checkTable() {
    try {
        const res = await db.query(`
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'question_reports'
            );
        `);
        console.log('question_reports exists:', res.rows[0].exists);

        const res2 = await db.query(`
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'question_performance'
            );
        `);
        console.log('question_performance exists:', res2.rows[0].exists);

        // Check columns of questions table
        const res3 = await db.query(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'questions';
        `);
        console.log('Columns in questions table:', res3.rows.map(r => r.column_name).join(', '));

    } catch (err) {
        console.error('Error checking tables:', err);
    } finally {
        process.exit();
    }
}

checkTable();
