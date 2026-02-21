const db = require('../config/db');

async function backfillAnalytics() {
    try {
        console.log('Starting Analytics Backfill...');

        // 1. Get all unique user-topic combinations from responses
        const topics = await db.query(`
            SELECT DISTINCT s.user_id, t.slug as topic_slug
            FROM responses r
            JOIN quiz_sessions s ON r.session_id = s.id
            JOIN questions q ON r.question_id = q.id
            JOIN topics t ON q.topic_id = t.id
        `);

        for (const row of topics.rows) {
            const { user_id, topic_slug } = row;

            // 2. Calculate aggregated stats for this topic
            const stats = await db.query(`
                SELECT 
                    COUNT(r.id) as total,
                    COUNT(CASE WHEN r.is_correct THEN 1 END) as correct,
                    COUNT(DISTINCT s.id) as sessions,
                    COALESCE(SUM(CASE WHEN r.is_correct THEN q.bloom_level ELSE 0 END), 0) as earned_bloom,
                    COALESCE(SUM(q.bloom_level), 0) as total_bloom
                FROM responses r
                JOIN quiz_sessions s ON r.session_id = s.id
                JOIN questions q ON r.question_id = q.id
                JOIN topics t ON q.topic_id = t.id
                WHERE s.user_id = $1 AND t.slug = $2
            `, [user_id, topic_slug]);

            const { total, correct, sessions, earned_bloom, total_bloom } = stats.rows[0];

            // Calculate Mastery Score (Weighted Percentage)
            const mastery = total_bloom > 0 ? Math.round((earned_bloom / total_bloom) * 100) : 0;

            console.log(`Backfilling User ${user_id} - ${topic_slug}: ${mastery}% Mastery (${correct}/${total})`);

            // 3. Update user_topic_progress
            await db.query(`
                INSERT INTO user_topic_progress (user_id, topic_slug, total_answered, correct_answered, mastery_score, sessions_completed, current_bloom_level, last_studied_at)
                VALUES ($1, $2, $3, $4, $5, $6, 1, NOW())
                ON CONFLICT (user_id, topic_slug) 
                DO UPDATE SET 
                    total_answered = EXCLUDED.total_answered,
                    correct_answered = EXCLUDED.correct_answered,
                    mastery_score = EXCLUDED.mastery_score,
                    sessions_completed = EXCLUDED.sessions_completed,
                    last_studied_at = NOW();
            `, [user_id, topic_slug, total, correct, mastery, sessions]);
        }

        console.log('✅ Backfill Complete!');
        process.exit(0);
    } catch (error) {
        console.error('Backfill Failed:', error);
        process.exit(1);
    }
}

backfillAnalytics();
