const db = require('../config/db');
const analyticsEngine = require('./analyticsEngine');

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
                    OR parent_id IN (SELECT id FROM topics WHERE slug = $1)
                )
                SELECT q.* 
                FROM questions q
                INNER JOIN subtopics st ON q.topic_id = st.id
                WHERE q.bloom_level = $2
                AND q.active = TRUE
                AND q.id NOT IN (
                    SELECT question_id FROM user_question_progress WHERE user_id = $3
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

        // 1. SRS PRIORITY: Check for "Due" questions first (SM-2 / Leitner Review)
        const dueReview = await db.query(`
            WITH subtopics AS (
                SELECT id FROM topics WHERE slug = $2
                OR parent_id IN (SELECT id FROM topics WHERE slug = $2)
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
            const streak = mRes.rows[0]?.current_streak || 0;
            const progressCounter = mRes.rows[0]?.progress_counter || 0;
            return {
                ...dueReview.rows[0],
                is_review: true,
                coverage: mRes.rows[0]?.mastery_score || 0,
                streak: streak,
                streakProgress: Math.min(1.0, progressCounter / 20.0),
                selectionReason: 'SRS_REVIEW'
            };
        }

        // 2. NEW CONTENT: If no reviews, use Bloom Climber logic
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

        // Fetch Question for this Level
        const result = await db.query(`
            WITH subtopics AS (
                SELECT id FROM topics WHERE slug = $1
                OR parent_id IN (SELECT id FROM topics WHERE slug = $1)
            )
            SELECT q.* 
            FROM questions q
            INNER JOIN subtopics st ON q.topic_id = st.id
            WHERE q.bloom_level = $2
            AND q.active = TRUE
            AND q.id NOT IN (
                SELECT question_id FROM user_question_progress WHERE user_id = $3
            )
            AND ($4::int[] IS NULL OR q.id != ALL($4::int[]))
            ORDER BY RANDOM()
            LIMIT 1
        `, [topicSlug, currentBloom, userId, excludeParam]);

        // Mastery Score for progress bar
        let mRes = await db.query(
            `SELECT mastery_score, current_streak, level_correct_count as progress_counter
            FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
            [userId, topicSlug]
        );
        const qCoverage = mRes.rows[0]?.mastery_score || 0;

        if (result.rows.length > 0) {
            const streak = mRes.rows[0]?.current_streak || 0;
            const progressCounter = mRes.rows[0]?.progress_counter || 0;
            return {
                ...result.rows[0],
                is_review: false,
                coverage: qCoverage,
                streak: streak,
                streakProgress: Math.min(1.0, progressCounter / 20.0),
                selectionReason: `BLOOM_CLIMBER_LEVEL_${currentBloom}`
            };
        }

        // Fallback: Buffer content (any level not yet tracked)
        const fallback = await db.query(`
            WITH subtopics AS (
                SELECT id FROM topics WHERE slug = $1
                OR parent_id IN (SELECT id FROM topics WHERE slug = $1)
            )
            SELECT q.* 
            FROM questions q
            INNER JOIN subtopics st ON q.topic_id = st.id
            WHERE q.active = TRUE
            AND q.id NOT IN (
                SELECT question_id FROM user_question_progress WHERE user_id = $2
            )
            AND ($3::int[] IS NULL OR q.id != ALL($3::int[]))
            ORDER BY RANDOM()
            LIMIT 1
        `, [topicSlug, userId, excludeParam]);

        mRes = await db.query(
            `SELECT mastery_score, current_streak, level_correct_count as progress_counter
            FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
            [userId, topicSlug]
        );
        const fallbackCoverage = mRes.rows[0]?.mastery_score || 0;

        if (fallback.rows.length > 0) {
            const streak = mRes.rows[0]?.current_streak || 0;
            const progressCounter = mRes.rows[0]?.progress_counter || 0;
            return {
                ...fallback.rows[0],
                is_review: false,
                coverage: fallbackCoverage,
                streak: streak,
                streakProgress: Math.min(1.0, progressCounter / 20.0),
                selectionReason: 'FALLBACK_BUFFER'
            };
        }

        // LAST RESORT: Infinite Practice (Random from topic)
        const lastResort = await db.query(`
            WITH subtopics AS (
                SELECT id FROM topics WHERE slug = $1
                OR parent_id IN (SELECT id FROM topics WHERE slug = $1)
            )
            SELECT q.* 
            FROM questions q
            INNER JOIN subtopics st ON q.topic_id = st.id
            WHERE q.active = TRUE
            AND ($2::int[] IS NULL OR q.id != ALL($2::int[]))
            ORDER BY RANDOM()
            LIMIT 1
        `, [topicSlug, excludeParam]);

        const finalCoverage = pRes.rows[0]?.mastery_score || 0;
        const streak = pRes.rows[0]?.current_streak || 0;
        const progressCounter = pRes.rows[0]?.level_correct_count || streak;
        return lastResort.rows[0] ? {
            ...lastResort.rows[0],
            is_review: true,
            coverage: finalCoverage,
            streak: streak,
            streakProgress: Math.min(1.0, progressCounter / 20.0),
            selectionReason: 'RANDOM_PRACTICE'
        } : null;
    }

    /**
     * Update User Progress based on Answer (The Climber Logic)
     */
    async processAnswerResult(userId, topicSlug, isCorrect, questionId, bloomLevel = 1, quality = null) {
        // Calculate quality if not provided
        if (quality === null) {
            quality = isCorrect ? 4 : 2; // Default logic: Correct=4, Wrong=2
        }

        let sm2Outcome = null;

        // 1. Update SRS State (Leitner + Mastery) - Fire and Forget for speed
        if (questionId) {
            sm2Outcome = await this.updateSRS(userId, questionId, isCorrect, quality);
        }

        // 2. Fetch Topic State & Question Counts
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

        let { current_bloom_level, current_streak, level_correct_count, consecutive_wrong, total_answered, correct_answered, unlocked_bloom_level, stability } = progressRes.rows[0];

        let event = null;

        // Calculate New Stability & Retention
        stability = analyticsEngine.calculateNewStability(stability, bloomLevel, isCorrect);
        let retention_score = 100;

        // Ensure unlocked level exists (migration fallback)
        unlocked_bloom_level = unlocked_bloom_level || 1;

        // Live Analytics Capture
        total_answered = (total_answered || 0) + 1;
        if (isCorrect) {
            correct_answered = (correct_answered || 0) + 1;
        }

        // 3. True Clinical Mastery Calculation (Weighted Progress: L1-2=1x, L3-4=2x)
        const progressStats = await db.query(`
            WITH subtopics AS (
                SELECT id FROM topics WHERE slug = $2
                OR parent_id IN (SELECT id FROM topics WHERE slug = $2)
            )
            SELECT 
                COUNT(*) FILTER (WHERE uqp.mastered = TRUE AND q.bloom_level <= 2) as mastered_l12,
                COUNT(*) FILTER (WHERE uqp.mastered = TRUE AND q.bloom_level >= 3) as mastered_l34,
                COUNT(*) FILTER (WHERE uqp.mastered = TRUE) as total_mastered,
                (SELECT COUNT(*) FROM questions q
                 INNER JOIN subtopics st ON q.topic_id = st.id
                 WHERE q.active = TRUE AND q.bloom_level <= 2) as total_l12,
                (SELECT COUNT(*) FROM questions q 
                 INNER JOIN subtopics st ON q.topic_id = st.id
                 WHERE q.active = TRUE AND q.bloom_level >= 3) as total_l34
            FROM user_question_progress uqp
            JOIN questions q ON uqp.question_id = q.id
            INNER JOIN subtopics st ON q.topic_id = st.id
            WHERE uqp.user_id = $1 
            AND q.active = TRUE
        `, [userId, topicSlug]);

        const masteredL12 = parseInt(progressStats.rows[0].mastered_l12) || 0;
        const masteredL34 = parseInt(progressStats.rows[0].mastered_l34) || 0;
        const masteredCount = parseInt(progressStats.rows[0].total_mastered) || 0;

        const totalL12 = parseInt(progressStats.rows[0].total_l12) || 0;
        const totalL34 = parseInt(progressStats.rows[0].total_l34) || 0;

        const weightedMastered = (masteredL12 * 1.0) + (masteredL34 * 2.0);
        const weightedTotal = (totalL12 * 1.0) + (totalL34 * 2.0);

        const mastery_score = weightedTotal > 0 ? Math.min(100, Math.round((weightedMastered / weightedTotal) * 100)) : 0;

        // 4. Bloom Promotion Logic
        if (isCorrect) {
            current_streak += 1;
            level_correct_count = (level_correct_count || 0) + 1;
            consecutive_wrong = 0;

            // Check Coverage for Level Up
            const levelStats = await db.query(`
            WITH subtopics AS (
                SELECT id FROM topics WHERE slug = $2
                OR parent_id IN (SELECT id FROM topics WHERE slug = $2)
            )
            SELECT
                (SELECT COUNT(*) FROM questions q 
                         INNER JOIN subtopics st ON q.topic_id = st.id
                         WHERE q.bloom_level = $3 AND q.active = TRUE) as total_in_level,
                (SELECT COUNT(*) FROM user_question_progress uqp
                         JOIN questions q ON uqp.question_id = q.id
                         INNER JOIN subtopics st ON q.topic_id = st.id
                         WHERE uqp.user_id = $1 
                         AND q.bloom_level = $3 AND uqp.mastered = TRUE) as mastered_in_level
            `, [userId, topicSlug, current_bloom_level]);

            const totalInLevel = parseInt(levelStats.rows[0].total_in_level) || 1;
            const masteredInLevel = parseInt(levelStats.rows[0].mastered_in_level) || 0;

            const coverage = masteredInLevel / totalInLevel;

            // Content Check: Does the next level actually have questions?
            const nextLevelRes = await db.query(`
                WITH subtopics AS (
                    SELECT id FROM topics WHERE slug = $1
                    OR parent_id IN (SELECT id FROM topics WHERE slug = $1)
                )
                SELECT COUNT(*) FROM questions q 
                INNER JOIN subtopics st ON q.topic_id = st.id
                WHERE q.bloom_level = $2 AND q.active = TRUE
            `, [topicSlug, current_bloom_level + 1]);
            const nextLevelCount = parseInt(nextLevelRes.rows[0].count) || 0;

            // PROMOTION GATE: > 80% Coverage OR Super Streak (20) AND next level has questions
            if ((coverage >= 0.8 || level_correct_count >= 20) && current_bloom_level < 4 && nextLevelCount > 0) {
                if (current_bloom_level >= unlocked_bloom_level) {
                    unlocked_bloom_level = current_bloom_level + 1;
                    event = 'LEVEL_UNLOCKED';
                }

                current_bloom_level += 1;
                current_streak = 0;
                level_correct_count = 0;
                event = event || 'PROMOTION';
            } else {
                if (current_streak > 1) event = 'STREAK_EXTENDED';
            }

        } else {
            current_streak = 0;
            level_correct_count = 0;
            consecutive_wrong += 1;

            if (consecutive_wrong >= 3) {
                if (current_bloom_level > 1) {
                    current_bloom_level -= 1;
                    consecutive_wrong = 0;
                    level_correct_count = 0;
                    event = 'DEMOTION';
                }
            }
        }

        // Update DB with all stats
        await db.query(`
            UPDATE user_topic_progress
            SET current_bloom_level = $1,
            current_streak = $2,
            level_correct_count = $3,
            consecutive_wrong = $4,
            total_answered = $5,
            correct_answered = $6,
            mastery_score = $7,
            unlocked_bloom_level = $8,
            questions_mastered = $9,
            stability = $10,
            retention_score = $11,
            last_studied_at = NOW()
            WHERE user_id = $12 AND topic_slug = $13
        `, [current_bloom_level, current_streak, level_correct_count, consecutive_wrong, total_answered, correct_answered, mastery_score, unlocked_bloom_level, masteredCount, stability, retention_score, userId, topicSlug]);

        return {
            newLevel: current_bloom_level,
            streak: current_streak,
            levelCorrectCount: level_correct_count,
            streakProgress: Math.min(1.0, level_correct_count / 20.0),
            event: event,
            mastered: masteredCount,
            coverage: mastery_score,
            sm2: sm2Outcome
        };

    }

    /**
     * SM-2 System Logic with Retention Auto-Correction
     */
    async updateSRS(userId, questionId, isCorrect, quality) {
        // 1. Fetch current progress
        const res = await db.query(`
        SELECT easiness_factor, interval_days, consecutive_correct, mastered
        FROM user_question_progress
        WHERE user_id = $1 AND question_id = $2
        `, [userId, questionId]);

        let previousEF = 2.5;
        let previousInterval = 0;
        let previousRepetitions = 0;
        let wasMastered = false;

        if (res.rows.length > 0) {
            previousEF = parseFloat(res.rows[0].easiness_factor) || 2.5;
            previousInterval = parseFloat(res.rows[0].interval_days) || 0;
            previousRepetitions = res.rows[0].consecutive_correct || 0;
            wasMastered = res.rows[0].mastered || false;
        }

        // 2. Fetch Retention History (Last 50)
        const historyRes = await db.query(`
            SELECT r.is_correct
            FROM responses r
            JOIN quiz_sessions s ON r.session_id = s.id
            WHERE s.user_id = $1
            ORDER BY r.created_at DESC
            LIMIT 50
        `, [userId]);

        const recentResults = historyRes.rows.map(row => row.is_correct);
        const retentionModifier = analyticsEngine.calculateRetentionModifier(recentResults);

        // 3. Calculate SM-2
        const sm2Result = analyticsEngine.calculateSM2(quality, previousEF, previousInterval, previousRepetitions);

        // Apply modifier to EF
        let newEF = sm2Result.easinessFactor * retentionModifier;
        if (newEF < 1.3) newEF = 1.3;

        const newInterval = sm2Result.interval;
        const newRepetitions = sm2Result.repetitions;

        // Keep mastered logic consistent (3 successful reps)
        const isMastered = newRepetitions >= 3;

        // Interval String for Postgres
        const intervalString = `${newInterval} days`;

        await db.query(`
            INSERT INTO user_question_progress(user_id, question_id, easiness_factor, interval_days, consecutive_correct, mastered, next_review_at, updated_at, last_answered_at)
            VALUES($1, $2, $3, $4, $5, $6, NOW() + $7::INTERVAL, NOW(), NOW())
            ON CONFLICT(user_id, question_id) 
            DO UPDATE SET
                easiness_factor = EXCLUDED.easiness_factor,
                interval_days = EXCLUDED.interval_days,
                consecutive_correct = EXCLUDED.consecutive_correct,
                mastered = EXCLUDED.mastered,
                next_review_at = EXCLUDED.next_review_at,
                updated_at = NOW(),
                last_answered_at = NOW();
        `, [userId, questionId, newEF, newInterval, newRepetitions, isMastered, intervalString]);

        if (isMastered && !wasMastered) {
            console.log(`[SM-2] User ${userId} MASTERED Question ${questionId}!`);
        }

        console.log(`[SM-2] User ${userId} Q ${questionId}: Q=${quality} | EF ${previousEF.toFixed(2)}->${newEF.toFixed(2)} (Mod ${retentionModifier}) | Int ${previousInterval}->${newInterval} | Reps ${previousRepetitions}->${newRepetitions}`);

        return {
            easinessFactor: newEF,
            interval: newInterval,
            repetitions: newRepetitions,
            mastered: isMastered,
            retentionModifier: retentionModifier
        };
    }
}

module.exports = new AdaptiveEngine();
