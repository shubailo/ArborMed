const db = require('./src/config/db');
const questionTypeRegistry = require('./src/services/questionTypes/registry');

async function debug() {
    try {
        console.log('--- START DEBUG ---');

        // 1. Test Query
        const query = `
            SELECT 
                q.id, q.question_text_en as text, q.question_text_hu, q.type, q.question_type, q.bloom_level, q.difficulty,
                q.options, q.correct_answer, q.explanation_en as explanation, q.explanation_hu, q.topic_id,
                t.name_en as topic_name, t.name_hu as topic_name_hu, t.slug as topic_slug,
                COALESCE(qp.total_attempts, 0) as attempts, COALESCE(qp.success_rate, 0) as success_rate,
                0 as report_count
            FROM questions q
            JOIN topics t ON q.topic_id = t.id
            LEFT JOIN question_performance qp ON qp.question_id = q.id
            ORDER BY q.created_at DESC 
            LIMIT 200 OFFSET 0
        `;

        console.log('Executing query...');
        const res = await db.query(query);
        console.log(`Query success. Returned ${res.rows.length} rows.`);

        if (res.rows.length > 0) {
            console.log('Sample row type:', res.rows[0].question_type);
        }

        // 2. Test Mapping
        console.log('Mapping results...');
        const prepared = res.rows.map((q, index) => {
            try {
                return questionTypeRegistry.prepareForAdmin(q);
            } catch (err) {
                console.error(`Mapping failed at index ${index} (ID: ${q.id}):`, err.message);
                throw err;
            }
        });
        console.log('Mapping finished successfully.');

    } catch (err) {
        console.error('--- DEBUG FAILED ---');
        console.error('Error Name:', err.name);
        console.error('Error Message:', err.message);
        console.error('Stack Trace:', err.stack);
    } finally {
        process.exit();
    }
}

debug();
