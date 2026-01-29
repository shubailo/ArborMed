const db = require('../config/db');

const check = async () => {
    try {
        const qCount = await db.query('SELECT count(*) FROM questions');
        const rCount = await db.query('SELECT count(*) FROM responses');
        console.log(`Questions in DB: ${qCount.rows[0].count}`);
        console.log(`Responses in DB: ${rCount.rows[0].count}`);

        const unanswered = await db.query(`
            SELECT count(*) FROM questions 
            WHERE id NOT IN (SELECT question_id FROM responses)
        `);
        console.log(`Unanswered Questions: ${unanswered.rows[0].count}`);

        process.exit();
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
};

check();
