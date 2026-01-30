const db = require('../config/db');

/**
 * Get overall mastery for major subjects
 * Calculates a proficiency percentage based on correct answers and Bloom levels
 */
exports.getSummary = async (req, res) => {
    try {
        const userId = req.user.id;

        // Optimized Query: Read aggregated stats from user_topic_progress
        const query = `
            SELECT 
                t_parent.name as subject,
                t_parent.slug as slug,
                COALESCE(SUM(utp.total_answered), 0)::int as total_answered,
                COALESCE(SUM(utp.correct_answered), 0)::int as correct_answered,
                
                -- Weighted Mastery for Parent Subject (Avg of children for now)
                COALESCE(ROUND(AVG(utp.mastery_score)), 0)::int as mastery_percent

            FROM topics t_parent
            LEFT JOIN topics t_child ON t_child.parent_id = t_parent.id
            LEFT JOIN user_topic_progress utp ON utp.topic_slug = t_child.slug AND utp.user_id = $1
            WHERE t_parent.parent_id IS NULL
            AND t_parent.slug IN ('pathophysiology', 'pathology', 'microbiology', 'pharmacology', 'ecg')
            GROUP BY t_parent.id, t_parent.name, t_parent.slug
        `;

        const result = await db.query(query, [userId]);

        // Formatter to match mobile-front needs
        // Include ECG as a subject if it's in the DB, otherwise empty array is handled by mobile
        res.json(result.rows);
    } catch (error) {
        console.error('Error in getSummary:', error);
        res.status(500).json({ message: 'Server error fetching summary stats' });
    }
};

exports.getActivity = async (req, res) => {
    try {
        const userId = req.user.id;
        const { timeframe = 'week', anchorDate } = req.query; // anchorDate: YYYY-MM-DD

        let interval = '7 days';
        if (timeframe === 'month') interval = '30 days';
        if (timeframe === 'year') interval = '365 days';

        // Anchor Date Logic: Default to NOW(), otherwise parse input
        const anchor = anchorDate ? `$2::date` : `CURRENT_DATE`;
        const params = anchorDate ? [userId, anchorDate] : [userId];

        // Optimized Query: correct_count + total_count
        const query = `
            SELECT 
                date_trunc('day', r.created_at)::date as date,
                COUNT(r.id) as count,
                COUNT(CASE WHEN r.is_correct THEN 1 END) as correct_count
            FROM responses r
            JOIN quiz_sessions s ON r.session_id = s.id
            WHERE s.user_id = $1 
              AND r.created_at <= ${anchor} + INTERVAL '1 day' -- Include full anchor day
              AND r.created_at > ${anchor} - INTERVAL '${interval}'
            GROUP BY date
            ORDER BY date ASC
        `;

        const result = await db.query(query, params);
        res.json(result.rows);
    } catch (error) {
        console.error('Error in getActivity:', error);
        res.status(500).json({ message: 'Server error fetching activity stats' });
    }
};

/**
 * Get detailed mastery for a specific subject (radar chart)
 */
exports.getSubjectDetail = async (req, res) => {
    try {
        const userId = req.user.id;
        const { subjectSlug } = req.params;

        // Optimized Query: Read granular stats from user_topic_progress
        const query = `
            SELECT 
                t_child.name as section,
                t_child.slug as slug,
                COALESCE(utp.total_answered, 0) as attempts,
                COALESCE(utp.sessions_completed, 0) as sessions_count,
                 COALESCE(utp.last_studied_at, '1970-01-01'::timestamp) as last_studied,
                COALESCE(utp.current_bloom_level, 1) as bloom_level,
                COALESCE(utp.mastery_score, 0) as proficiency
            FROM topics t_parent
            JOIN topics t_child ON t_child.parent_id = t_parent.id
            LEFT JOIN user_topic_progress utp ON utp.topic_slug = t_child.slug AND utp.user_id = $1
            WHERE t_parent.slug = $2
            ORDER BY last_studied DESC, attempts DESC, proficiency ASC, t_child.name ASC
        `;

        const result = await db.query(query, [userId, subjectSlug]);
        res.json(result.rows);
    } catch (error) {
        console.error('Error in getSubjectDetail:', error);
        res.status(500).json({ message: 'Server error fetching subject details' });
    }
};

/**
 * @desc Get aggregate stats for all questions (Admin Panel)
 * @route GET /api/stats/questions
 */
exports.getQuestionStats = async (req, res) => {
    try {
        const query = `
            SELECT 
                q.id::text as question_id,
                q.text as question_text,
                t.slug as topic_slug,
                q.difficulty as bloom_level,
                COUNT(r.id)::int as total_attempts,
                COALESCE(SUM(CASE WHEN r.is_correct THEN 1 ELSE 0 END), 0)::int as correct_count,
                ROUND(AVG(r.response_time_ms))::int as avg_time_ms
            FROM questions q
            LEFT JOIN topics t ON q.topic_id = t.id
            LEFT JOIN responses r ON r.question_id = q.id
            GROUP BY q.id, t.slug, q.difficulty
            ORDER BY total_attempts DESC, question_text ASC
        `;

        const [result, userResults, bloomResult] = await Promise.all([
            db.query(query),
            db.query(`
                SELECT 
                    (SELECT COUNT(*)::int FROM users) as total_users,
                    COALESCE(ROUND(AVG(EXTRACT(EPOCH FROM (COALESCE(completed_at, NOW()) - started_at)) / 60)), 0)::int as avg_session_mins
                FROM quiz_sessions
            `),
            db.query(`SELECT COALESCE(AVG(current_bloom_level), 1.0)::float as avg_bloom FROM user_topic_progress`)
        ]);

        const stats = result.rows.map(row => ({
            ...row,
            correct_percentage: row.total_attempts > 0
                ? Math.round((row.correct_count / row.total_attempts) * 100)
                : 0
        }));

        res.json({
            questionStats: stats,
            userStats: {
                ...userResults.rows[0],
                avg_bloom: bloomResult.rows[0].avg_bloom
            }
        });
    } catch (error) {
        console.error('Error in getQuestionStats:', error);
        res.status(500).json({ message: 'Server error fetching question stats' });
    }
};
