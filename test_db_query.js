const db = require('./backend/src/config/db');

async function testQuery() {
    const topic_id = '8';
    const limit = 200;
    const offset = 0;
    const orderBy = 'q.created_at';
    const sortOrder = 'DESC';

    const params = [topic_id];
    let query = `
        SELECT 
            q.id, 
            q.question_text_en as text, 
            q.question_text_hu, 
            q.type, 
            q.question_type, 
            q.bloom_level, 
            q.difficulty,
            q.options, 
            q.correct_answer, 
            q.explanation_en as explanation, 
            q.explanation_hu, 
            q.topic_id,
            t.name_en as topic_name, 
            t.name_hu as topic_name_hu,
            t.slug as topic_slug,
            COALESCE(qp.total_attempts, 0) as attempts,
            COALESCE(qp.success_rate, 0) as success_rate,
            (SELECT COUNT(*)::int FROM question_reports qr WHERE qr.question_id = q.id AND qr.status = 'pending') as report_count
        FROM questions q
        JOIN topics t ON q.topic_id = t.id
        LEFT JOIN question_performance qp ON qp.question_id = q.id
        WHERE q.topic_id IN (
            WITH subtopics AS (
                SELECT id FROM topics WHERE id = $1
                OR parent_id IN (SELECT id FROM topics WHERE id = $1)
            )
            SELECT id FROM subtopics
        )
        ORDER BY ${orderBy} ${sortOrder} LIMIT $2 OFFSET $3
    `;
    const queryParams = [topic_id, limit, offset];

    const countQuery = `
        SELECT COUNT(*) FROM questions q JOIN topics t ON q.topic_id = t.id
        WHERE q.topic_id IN (
            WITH subtopics AS (
                SELECT id FROM topics WHERE id = $1
                OR parent_id IN (SELECT id FROM topics WHERE id = $1)
            )
            SELECT id FROM subtopics
        )
    `;

    try {
        console.log('Testing main query...');
        const results = await db.query(query, queryParams);
        console.log(`Success! Main query returned ${results.rows.length} rows.`);

        console.log('Testing count query...');
        const countResult = await db.query(countQuery, params);
        console.log(`Success! Count query returned ${countResult.rows[0].count}.`);
    } catch (err) {
        console.error('QUERY FAILED:', err);
    } finally {
        process.exit();
    }
}

testQuery();
