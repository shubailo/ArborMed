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
                t_parent.name_en as subject,
                t_parent.name_en as name_en,
                t_parent.name_hu as name_hu,
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
            GROUP BY t_parent.id, t_parent.name_en, t_parent.name_hu, t_parent.slug
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
        const { topicId } = req.query;
        let topicFilter = '';
        let reponseTopicFilter = '';
        const params = [];

        if (topicId && topicId !== 'null' && topicId !== 'undefined') {
            params.push(topicId);
            // Include children if it's a parent topic
            topicFilter = `AND (q.topic_id = $1 OR q.topic_id IN (SELECT id FROM topics WHERE parent_id = $1))`;
            reponseTopicFilter = `AND r.question_id IN (SELECT id FROM questions WHERE topic_id = $1 OR topic_id IN (SELECT id FROM topics WHERE parent_id = $1))`;
        }

        const query = `
            SELECT 
                q.id::text as question_id,
                q.question_text_en as question_text,
                t.slug as topic_slug,
                q.bloom_level as bloom_level,
                COUNT(r.id)::int as total_attempts,
                COALESCE(SUM(CASE WHEN r.is_correct THEN 1 ELSE 0 END), 0)::int as correct_count,
                ROUND(AVG(r.response_time_ms))::int as avg_time_ms
            FROM questions q
            LEFT JOIN topics t ON q.topic_id = t.id
            LEFT JOIN responses r ON r.question_id = q.id
            WHERE 1=1 ${topicFilter}
            GROUP BY q.id, q.question_text_en, t.slug, q.bloom_level
            ORDER BY total_attempts DESC, question_text ASC
        `;

        const [result, userResults, bloomResult, trendResults] = await Promise.all([
            db.query(query, params),
            db.query(`
                SELECT 
                    (SELECT COUNT(*)::int FROM users WHERE role = 'student' AND email NOT IN ('test_reset@example.com', 'hemmy@medbuddy.ai')) as total_users,
                    (SELECT COUNT(*)::int FROM users WHERE role = 'student' AND email NOT IN ('test_reset@example.com', 'hemmy@medbuddy.ai') AND created_at > NOW() - INTERVAL '24 hours') as new_users_24h,
                    COALESCE(ROUND(AVG(EXTRACT(EPOCH FROM (COALESCE(completed_at, NOW()) - started_at)) / 60)), 0)::int as avg_session_mins
                FROM quiz_sessions
                WHERE user_id NOT IN (SELECT id FROM users WHERE email IN ('test_reset@example.com', 'hemmy@medbuddy.ai'))
                ${topicId ? `AND id IN (SELECT session_id FROM responses r WHERE 1=1 ${reponseTopicFilter.replace('$1', topicId)})` : ''}
            `),
            db.query(`
                SELECT COALESCE(AVG(current_bloom_level), 1.0)::float as avg_bloom 
                FROM user_topic_progress
                WHERE user_id NOT IN (SELECT id FROM users WHERE email IN ('test_reset@example.com', 'hemmy@medbuddy.ai'))
                ${topicId ? `AND (topic_slug IN (SELECT slug FROM topics WHERE id = ${topicId} OR parent_id = ${topicId}))` : ''}
            `),
            db.query(`
                SELECT 
                    COALESCE(AVG(CASE WHEN is_correct THEN 100 ELSE 0 END), 0)::float as class_avg_24h,
                    COALESCE(AVG(q.bloom_level), 0)::float as avg_bloom_24h
                FROM responses r
                JOIN questions q ON r.question_id = q.id
                JOIN quiz_sessions s ON r.session_id = s.id
                WHERE r.created_at > NOW() - INTERVAL '24 hours'
                AND s.user_id NOT IN (SELECT id FROM users WHERE email IN ('test_reset@example.com', 'hemmy@medbuddy.ai'))
                ${topicFilter.replace('$1', topicId || 'NULL')}
            `)
        ]);

        const stats = result.rows.map(row => ({
            ...row,
            correct_percentage: row.total_attempts > 0
                ? Math.round((row.correct_count / row.total_attempts) * 100)
                : 0
        }));

        const overall_avg = stats.length > 0
            ? stats.reduce((sum, s) => sum + s.correct_percentage, 0) / stats.length
            : 0;

        const trend = trendResults.rows[0];
        const classAvg24h = trend.class_avg_24h || overall_avg;
        const bloom24h = trend.avg_bloom_24h || bloomResult.rows[0].avg_bloom;

        res.json({
            questionStats: stats,
            userStats: {
                ...userResults.rows[0],
                avg_bloom: bloomResult.rows[0].avg_bloom,
                class_avg_trend: (classAvg24h - overall_avg).toFixed(1),
                bloom_trend: (bloom24h - bloomResult.rows[0].avg_bloom).toFixed(1)
            }
        });
    } catch (error) {
        console.error('Error in getQuestionStats:', error);
        res.status(500).json({ message: 'Server error fetching question stats' });
    }
};

/**
 * @desc Get hierarchical inventory summary (Admin Panel)
 */
exports.getInventorySummary = async (req, res) => {
    try {
        const query = `
            SELECT 
                p.id as subject_id,
                p.name_en as subject_name,
                c.id as section_id,
                c.name_en as section_name,
                q.bloom_level,
                COUNT(q.id)::int as count
            FROM topics p
            JOIN topics c ON c.parent_id = p.id
            LEFT JOIN questions q ON q.topic_id = c.id
            WHERE p.parent_id IS NULL
            GROUP BY p.id, p.name_en, c.id, c.name_en, q.bloom_level
            ORDER BY p.name_en, c.name_en, q.bloom_level;
        `;
        const result = await db.query(query);

        const hierarchy = {};
        result.rows.forEach(row => {
            if (!hierarchy[row.subject_id]) {
                hierarchy[row.subject_id] = {
                    id: row.subject_id,
                    name: row.subject_name,
                    sections: {}
                };
            }

            if (!hierarchy[row.subject_id].sections[row.section_id]) {
                hierarchy[row.subject_id].sections[row.section_id] = {
                    id: row.section_id,
                    name: row.section_name,
                    bloomCounts: { 1: 0, 2: 0, 3: 0, 4: 0 },
                    total: 0
                };
            }

            if (row.bloom_level) {
                hierarchy[row.subject_id].sections[row.section_id].bloomCounts[row.bloom_level] = row.count;
                hierarchy[row.subject_id].sections[row.section_id].total += row.count;
            }
        });

        const finalData = Object.values(hierarchy).map(subject => ({
            ...subject,
            sections: Object.values(subject.sections),
            total: Object.values(subject.sections).reduce((acc, sec) => acc + sec.total, 0)
        }));

        res.json(finalData);
    } catch (error) {
        console.error('Error in getInventorySummary:', error);
        res.status(500).json({ message: 'Server error fetching inventory summary' });
    }
};

/**
 * @desc Get global class-wide summary for major subjects (Admin Panel)
 * @route GET /api/stats/admin/summary
 */
exports.getAdminSummary = async (req, res) => {
    try {
        const query = `
            SELECT 
                t_parent.name_en as section, -- 'section' to match frontend expected key
                t_parent.name_en as name_en,
                t_parent.name_hu as name_hu,
                t_parent.slug as slug,
                COUNT(r.id)::int as attempts,
                COALESCE(AVG(CASE WHEN r.is_correct THEN 100 ELSE 0 END), 0)::int as proficiency,
                COALESCE(AVG(r.response_time_ms), 0)::int as avg_time_ms
            FROM topics t_parent
            JOIN topics t_child ON t_child.parent_id = t_parent.id OR t_child.id = t_parent.id
            JOIN questions q ON q.topic_id = t_child.id
            LEFT JOIN responses r ON r.question_id = q.id
            WHERE t_parent.parent_id IS NULL
            AND t_parent.slug IN ('pathophysiology', 'pathology', 'microbiology', 'pharmacology', 'ecg', 'case-studies')
            GROUP BY t_parent.id, t_parent.name_en, t_parent.name_hu, t_parent.slug
            ORDER BY t_parent.name_en ASC
        `;

        const result = await db.query(query);
        res.json(result.rows);
    } catch (error) {
        console.error('Error in getAdminSummary:', error);
        res.status(500).json({ message: 'Server error fetching admin summary' });
    }
};

/**
 * @desc Get all users with performance metrics (Admin Panel - Users Page)
 * @route GET /api/stats/admin/users-performance
 */
exports.getUsersPerformance = async (req, res) => {
    try {
        const query = `
            SELECT 
                u.id,
                u.email,
                u.created_at,
                u.last_active_date as last_activity,
                
                -- Pathophysiology
                COALESCE(ROUND(AVG(CASE WHEN t_parent.slug = 'pathophysiology' AND r.is_correct THEN 100 ELSE 0 END)), 0)::int as pathophysiology_avg,
                COUNT(CASE WHEN t_parent.slug = 'pathophysiology' THEN r.id END)::int as pathophysiology_total,
                COUNT(CASE WHEN t_parent.slug = 'pathophysiology' AND r.is_correct THEN r.id END)::int as pathophysiology_correct,
                COALESCE(ROUND(AVG(CASE WHEN t_parent.slug = 'pathophysiology' THEN r.response_time_ms END)), 0)::int as pathophysiology_time,
                
                -- Pathology
                COALESCE(ROUND(AVG(CASE WHEN t_parent.slug = 'pathology' AND r.is_correct THEN 100 ELSE 0 END)), 0)::int as pathology_avg,
                COUNT(CASE WHEN t_parent.slug = 'pathology' THEN r.id END)::int as pathology_total,
                COUNT(CASE WHEN t_parent.slug = 'pathology' AND r.is_correct THEN r.id END)::int as pathology_correct,
                COALESCE(ROUND(AVG(CASE WHEN t_parent.slug = 'pathology' THEN r.response_time_ms END)), 0)::int as pathology_time,
                
                -- Microbiology
                COALESCE(ROUND(AVG(CASE WHEN t_parent.slug = 'microbiology' AND r.is_correct THEN 100 ELSE 0 END)), 0)::int as microbiology_avg,
                COUNT(CASE WHEN t_parent.slug = 'microbiology' THEN r.id END)::int as microbiology_total,
                COUNT(CASE WHEN t_parent.slug = 'microbiology' AND r.is_correct THEN r.id END)::int as microbiology_correct,
                COALESCE(ROUND(AVG(CASE WHEN t_parent.slug = 'microbiology' THEN r.response_time_ms END)), 0)::int as microbiology_time,
                
                -- Pharmacology
                COALESCE(ROUND(AVG(CASE WHEN t_parent.slug = 'pharmacology' AND r.is_correct THEN 100 ELSE 0 END)), 0)::int as pharmacology_avg,
                COUNT(CASE WHEN t_parent.slug = 'pharmacology' THEN r.id END)::int as pharmacology_total,
                COUNT(CASE WHEN t_parent.slug = 'pharmacology' AND r.is_correct THEN r.id END)::int as pharmacology_correct,
                COALESCE(ROUND(AVG(CASE WHEN t_parent.slug = 'pharmacology' THEN r.response_time_ms END)), 0)::int as pharmacology_time,
                
                -- ECG
                COALESCE(ROUND(AVG(CASE WHEN t_parent.slug = 'ecg' AND r.is_correct THEN 100 ELSE 0 END)), 0)::int as ecg_avg,
                COUNT(CASE WHEN t_parent.slug = 'ecg' THEN r.id END)::int as ecg_total,
                COUNT(CASE WHEN t_parent.slug = 'ecg' AND r.is_correct THEN r.id END)::int as ecg_correct,
                COALESCE(ROUND(AVG(CASE WHEN t_parent.slug = 'ecg' THEN r.response_time_ms END)), 0)::int as ecg_time,
                
                -- Case Studies
                COALESCE(ROUND(AVG(CASE WHEN t_parent.slug = 'case-studies' AND r.is_correct THEN 100 ELSE 0 END)), 0)::int as cases_avg,
                COUNT(CASE WHEN t_parent.slug = 'case-studies' THEN r.id END)::int as cases_total,
                COUNT(CASE WHEN t_parent.slug = 'case-studies' AND r.is_correct THEN r.id END)::int as cases_correct,
                COALESCE(ROUND(AVG(CASE WHEN t_parent.slug = 'case-studies' THEN r.response_time_ms END)), 0)::int as cases_time
                
            FROM users u
            LEFT JOIN quiz_sessions s ON s.user_id = u.id
            LEFT JOIN responses r ON r.session_id = s.id
            LEFT JOIN questions q ON q.id = r.question_id
            LEFT JOIN topics t_child ON t_child.id = q.topic_id
            LEFT JOIN topics t_parent ON t_parent.id = t_child.parent_id OR (t_parent.id = t_child.id AND t_child.parent_id IS NULL)
            WHERE u.role = 'student'
            AND u.email NOT IN ('test_reset@example.com', 'hemmy@medbuddy.ai')
            GROUP BY u.id, u.email, u.created_at, u.last_active_date
            ORDER BY u.last_active_date DESC NULLS LAST, u.created_at DESC
        `;

        const result = await db.query(query);
        res.json(result.rows);
    } catch (error) {
        console.error('Error in getUsersPerformance:', error);
        res.status(500).json({ message: 'Server error fetching users performance' });
    }
};

/**
 * @desc Get detailed history for a specific user (Admin Panel - User Detail View)
 * @route GET /api/stats/admin/users/:userId/history
 */
exports.getUserHistory = async (req, res) => {
    try {
        const { userId } = req.params;
        const { limit = 100 } = req.query;

        const query = `
            SELECT 
                r.id,
                r.created_at,
                r.is_correct,
                r.response_time_ms,
                q.question_text_en,
                q.bloom_level,
                t_child.name_en as section_name,
                t_parent.name_en as subject_name,
                t_parent.slug as subject_slug
            FROM responses r
            JOIN quiz_sessions s ON r.session_id = s.id
            JOIN questions q ON q.id = r.question_id
            JOIN topics t_child ON t_child.id = q.topic_id
            LEFT JOIN topics t_parent ON t_parent.id = t_child.parent_id OR (t_parent.id = t_child.id AND t_child.parent_id IS NULL)
            WHERE s.user_id = $1
            ORDER BY r.created_at DESC
            LIMIT $2
        `;

        const result = await db.query(query, [userId, limit]);
        res.json(result.rows);
    } catch (error) {
        console.error('Error in getUserHistory:', error);
        res.status(500).json({ message: 'Server error fetching user history' });
    }
};
