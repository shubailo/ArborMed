const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

async function simulateQuery() {
    try {
        const userId = 1; // Assuming a user ID exists
        const subjectSlug = 'pathophysiology';

        const query = `
            SELECT 
                t_child.name_en as section,
                t_child.name_en as name_en,
                t_child.name_hu as name_hu,
                t_child.slug as slug,
                COALESCE(utp.total_answered, 0) as attempts,
                COALESCE(utp.sessions_completed, 0) as sessions_count,
                COALESCE(utp.last_studied_at, '1970-01-01'::timestamp) as last_studied,
                COALESCE(utp.current_bloom_level, 1) as bloom_level,
                COALESCE(utp.mastery_score, 0) as proficiency,
                COALESCE(AVG(r.response_time_ms), 0)::int as avg_time_ms
            FROM topics t_parent
            JOIN topics t_child ON t_child.parent_id = t_parent.id
            LEFT JOIN user_topic_progress utp ON utp.topic_slug = t_child.slug AND utp.user_id = $1
            LEFT JOIN questions q ON q.topic_id = t_child.id
            LEFT JOIN responses r ON r.question_id = q.id
            WHERE t_parent.slug = $2
            GROUP BY t_child.id, t_child.name_en, t_child.name_hu, t_child.slug, utp.total_answered, utp.sessions_completed, utp.last_studied_at, utp.current_bloom_level, utp.mastery_score
            ORDER BY t_child.name_en ASC
        `;

        console.log(`Running query for user ${userId}, subject ${subjectSlug}...`);
        const result = await pool.query(query, [userId, subjectSlug]);
        console.log('Result length:', result.rows.length);
        console.log('Result rows:', JSON.stringify(result.rows, null, 2));

        process.exit(0);
    } catch (error) {
        console.error('Error in simulateQuery:', error);
        process.exit(1);
    }
}

simulateQuery();
