const db = require('../config/db');
require('dotenv').config();

async function normalizeTypes() {
    try {
        console.log('Starting question type normalization...');

        // Update questions table
        const res = await db.query(`
            UPDATE questions 
            SET 
                question_type = CASE 
                    WHEN question_type = 'relational_analysis' THEN 'relation_analysis'
                    ELSE question_type
                END,
                type = CASE 
                    WHEN type = 'relational_analysis' THEN 'relation_analysis'
                    ELSE type
                END
            WHERE question_type = 'relational_analysis' OR type = 'relational_analysis'
            RETURNING id;
        `);

        console.log(`Successfully normalized ${res.rowCount} questions.`);

    } catch (err) {
        console.error('Error during normalization:', err);
    } finally {
        process.exit();
    }
}

normalizeTypes();
