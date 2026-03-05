const db = require('../config/db');
const analyticsEngine = require('./analyticsEngine');

const _MASTERY_THRESHOLD = 0.8;
const _STREAK_THRESHOLD = 20;
const _MAX_BLOOM_LEVEL = 4;

class AdaptiveEngine {
    /**
     * Get the next best question for a user based on Bloom Level.
     * @param {number} userId - The user's ID
     * @param {string} topicSlug - The topic slug
     * @param {number[]} excludedIds - Question IDs to exclude (for batch fetching)
     * @param {number|null} levelOverride - Override bloom level (for predictive caching)
     */
    async getNextQuestion(userId, topicSlug, excludedIds = [], levelOverride = null) {
        const excludeParam = excludedIds.length > 0 ? excludedIds : null;

        // If levelOverride is provided, skip SRS and use specified level directly
        if (levelOverride !== null) {
            console.log(`[PREDICTIVE] Fetching Level ${levelOverride} question for User ${userId}`);
            const result = await db.query(`
                WITH subtopics AS (
                    SELECT id FROM topics WHERE slug = $1
                    OR parent_id = (SELECT id FROM topics WHERE slug = $1)
                )
                SELECT q.* 
                FROM questions q
                INNER JOIN subtopics st ON q.topic_id = st.id
                WHERE q.bloom_level = $2
                AND q.active = TRUE
                -- ⚡ Bolt: Replaced NOT IN with NOT EXISTS to allow the query planner
                -- to utilize indexed lookups and halt execution for the row immediately upon match,
                -- preventing O(N) subquery materialization as progress data grows.
                AND NOT EXISTS (
                    SELECT 1 FROM user_question_progress uqp
                    WHERE uqp.question_id = q.id AND uqp.user_id = $3
                )
                AND ($4::int[] IS NULL OR q.id != ALL($4::int[]))
                ORDER BY RANDOM()
                LIMIT 1
            `, [topicSlug, levelOverride, userId, excludeParam]);

            if (result.rows.length > 0) {
                return {
                    ...result.rows[0],
                    is_review: false,
                    coverage: 0,
                    streak: 0,
                    streakProgress: 0,
                    selectionReason: `PREDICTIVE_LEVEL_${levelOverride}`
                };
            }
            return null;
        }

        // 1. SRS PRIORITY
        const dueReview = await db.query(`
            WITH subtopics AS (
                SELECT id FROM topics WHERE slug = $2
                OR parent_id = (SELECT id FROM topics WHERE slug = $2)
            )
            SELECT q.* 
            FROM questions q
            INNER JOIN subtopics st ON q.topic_id = st.id
            JOIN user_question_progress uqp ON q.id = uqp.question_id
            WHERE uqp.user_id = $1 
            AND uqp.next_review_at <= NOW()
            AND q.active = TRUE
            AND ($3::int[] IS NULL OR q.id != ALL($3::int[]))
            ORDER BY uqp.next_review_at ASC, RANDOM()
            LIMIT 1
        `, [userId, topicSlug, excludeParam]);

        if (dueReview.rows.length > 0) {
            console.log(`[SRS] Serving Review Question for User ${userId}: ${dueReview.rows[0].id}`);
            const mRes = await db.query(
                `SELECT mastery_score, current_streak, level_correct_count as progress_counter
                FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
                [userId, topicSlug]
            );
            return {
                ...dueReview.rows[0],
                is_review: true,
                coverage: mRes.rows[0]?.mastery_score || 0,
                streak: mRes.rows[0]?.current_streak || 0,
                streakProgress: Math.min(1.0, (mRes.rows[0]?.progress_counter || 0) / 20.0),
                selectionReason: 'SRS_REVIEW'
            };
        }

        // 2. NEW CONTENT (Bloom Climber)
        let pRes = await db.query(
            `SELECT * FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
            [userId, topicSlug]
        );

        let currentBloom = 1;
        if (pRes.rows.length === 0) {
            await db.query(`
                INSERT INTO user_topic_progress (user_id, topic_slug, current_bloom_level)
                VALUES ($1, $2, 1)
            `, [userId, topicSlug]);
        } else {
            currentBloom = pRes.rows[0].current_bloom_level;
        }

        const result = await db.query(`
            WITH subtopics AS (
                SELECT id FROM topics WHERE slug = $1
                OR parent_id = (SELECT id FROM topics WHERE slug = $1)
            )
            SELECT q.* 
            FROM questions q
            INNER JOIN subtopics st ON q.topic_id = st.id
            WHERE q.bloom_level = $2
            AND q.active = TRUE
            -- ⚡ Bolt: Replaced NOT IN with NOT EXISTS to allow the query planner
            -- to utilize indexed lookups and halt execution for the row immediately upon match,
            -- preventing O(N) subquery materialization as progress data grows.
            AND NOT EXISTS (
                SELECT 1 FROM user_question_progress uqp
                WHERE uqp.question_id = q.id AND uqp.user_id = $3
            )
            AND ($4::int[] IS NULL OR q.id != ALL($4::int[]))
            ORDER BY RANDOM()
            LIMIT 1
        `, [topicSlug, currentBloom, userId, excludeParam]);

        let mRes = await db.query(
            `SELECT mastery_score, current_streak, level_correct_count as progress_counter
            FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
            [userId, topicSlug]
        );

        if (result.rows.length > 0) {
            return {
                ...result.rows[0],
                is_review: false,
                coverage: mRes.rows[0]?.mastery_score || 0,
                streak: mRes.rows[0]?.current_streak || 0,
                streakProgress: Math.min(1.0, (mRes.rows[0]?.progress_counter || 0) / 20.0),
                selectionReason: `BLOOM_CLIMBER_LEVEL_${currentBloom}`
            };
        }

        return null;
    }

    /**
     * Update User Progress based on Answer (The Climber Logic)
     */
    async processAnswerResult(userId, topicSlug, isCorrect, questionId, _bloomLevel = 1, quality = null) {
        if (quality === null) {
            quality = isCorrect ? 4 : 2;
        }

        let sm2Outcome = null;
        if (questionId) {
            sm2Outcome = await this.updateSRS(userId, questionId, isCorrect, quality);
        }

        let progressRes = await db.query(
            `SELECT * FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
            [userId, topicSlug]
        );

        if (progressRes.rows.length === 0) {
            console.log(`[ADY] Initializing missing progress for User ${userId} on ${topicSlug}`);
            await db.query(`
                INSERT INTO user_topic_progress (user_id, topic_slug, current_bloom_level)
                VALUES ($1, $2, 1)
                ON CONFLICT (user_id, topic_slug) DO NOTHING
            `, [userId, topicSlug]);

            progressRes = await db.query(
                `SELECT * FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
                [userId, topicSlug]
            );

            if (progressRes.rows.length === 0) return null;
        }

        let { current_bloom_level, current_streak, level_correct_count } = progressRes.rows[0];

        // Weighted Mastery Logic
        const stats = await db.query(`
            WITH subtopics AS (
                SELECT id FROM topics WHERE slug = $2
                OR parent_id = (SELECT id FROM topics WHERE slug = $2)
            )
            SELECT 
                COUNT(*) FILTER (WHERE q.bloom_level <= 2 AND uqp.mastered = TRUE) as m_l12,
                COUNT(*) FILTER (WHERE q.bloom_level > 2 AND uqp.mastered = TRUE) as m_l34,
                COUNT(*) FILTER (WHERE q.bloom_level <= 2) as t_l12,
                COUNT(*) FILTER (WHERE q.bloom_level > 2) as t_l34
            FROM questions q
            LEFT JOIN user_question_progress uqp ON q.id = uqp.question_id AND uqp.user_id = $1
            INNER JOIN subtopics st ON q.topic_id = st.id
            WHERE q.active = TRUE
        `, [userId, topicSlug]);

        const { m_l12, m_l34, t_l12, t_l34 } = stats.rows[0];
        const weightedNumerator = (parseInt(m_l12) * 1.0) + (parseInt(m_l34) * 2.0);
        const weightedDenominator = (parseInt(t_l12) * 1.0) + (parseInt(t_l34) * 2.0);
        const weightedScore = weightedDenominator > 0 ? weightedNumerator / weightedDenominator : 0;
        const mastery_score = Math.min(100, Math.round(weightedScore * 100));

        // Bloom Promotion (Locked 1-4)
        if (isCorrect) {
            current_streak += 1;
            level_correct_count += 1;
            if ((level_correct_count >= 20) && current_bloom_level < 4) {
                current_bloom_level += 1;
                level_correct_count = 0;
            }
        } else {
            current_streak = 0;
            level_correct_count = 0;
        }

        await db.query(`
            UPDATE user_topic_progress
            SET current_bloom_level = $1, current_streak = $2, level_correct_count = $3, 
                mastery_score = $4, last_studied_at = NOW()
            WHERE user_id = $5 AND topic_slug = $6
        `, [current_bloom_level, current_streak, level_correct_count, mastery_score, userId, topicSlug]);

        return { newLevel: current_bloom_level, mastery_score, sm2: sm2Outcome, streakProgress: Math.min(1.0, (level_correct_count || 0) / 20.0) };
    }

    /**
     * Leitner System Logic
     */
    async updateSRS(userId, questionId, isCorrect, quality) {
        const res = await db.query(`
            SELECT * FROM user_question_progress WHERE user_id = $1 AND question_id = $2
        `, [userId, questionId]);

        let { easiness_factor, interval_days, repetition_count } = res.rows[0] || { easiness_factor: 2.5, interval_days: 0, repetition_count: 0 };

        const sm2 = analyticsEngine.calculateSM2(quality, parseFloat(easiness_factor), interval_days, repetition_count);

        await db.query(`
            INSERT INTO user_question_progress (user_id, question_id, easiness_factor, interval_days, repetition_count, next_review_at, mastered)
            VALUES ($1, $2, $3, $4, $5, NOW() + ($6 || ' days')::INTERVAL, $7)
            ON CONFLICT (user_id, question_id) DO UPDATE SET
                easiness_factor = EXCLUDED.easiness_factor,
                interval_days = EXCLUDED.interval_days,
                repetition_count = EXCLUDED.repetition_count,
                next_review_at = EXCLUDED.next_review_at,
                mastered = EXCLUDED.mastered
        `, [userId, questionId, sm2.easinessFactor, sm2.interval, sm2.repetitions, sm2.interval, sm2.repetitions >= 3]);

        return sm2;
    }
}

module.exports = new AdaptiveEngine();
