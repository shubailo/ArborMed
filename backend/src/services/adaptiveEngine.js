const db = require('../config/db');
const analyticsEngine = require('./analyticsEngine');

class AdaptiveEngine {
    /**
     * Get the next best question for a user.
     * @param {number} userId - The user's ID.
     * @param {string} topicSlug - The topic slug (e.g., 'cardiovascular').
     */
    /**
     * Get the next best question for a user based on Bloom Level.
     * @param {number} userId - The user's ID
     * @param {string} topicSlug - The topic slug
     * @param {number[]} excludedIds - Question IDs to exclude (for batch fetching)
     * @param {number|null} levelOverride - Override bloom level (for predictive caching)
     */
    async getNextQuestion(userId, topicSlug, excludedIds = [], levelOverride = null) {
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
                ${excludedIds.length > 0 ? 'AND q.id NOT IN (' + excludedIds.join(',') + ')' : ''}
                ORDER BY RANDOM()
                LIMIT 1
            `, [topicSlug, levelOverride, userId]);

            if (result.rows.length > 0) {
                return {
                    ...result.rows[0],
                    is_review: false,
                    coverage: 0,
                    streak: 0,
                    streakProgress: 0
                };
            }
            return null;
        }

        // 1. SRS PRIORITY: Check for "Due" questions first (Leitner Box review)
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
            AND uqp.next_review_at <= NOW() -- It's time to review!
            AND q.active = TRUE
            ${excludedIds.length > 0 ? 'AND q.id NOT IN (' + excludedIds.join(',') + ')' : ''}
            ORDER BY uqp.next_review_at ASC, RANDOM() -- Oldest due first, then random
            LIMIT 1
        `, [userId, topicSlug]);

        if (dueReview.rows.length > 0) {
            console.log(`[SRS] Serving Review Question for User ${userId}: ${dueReview.rows[0].id}`);
            const mRes = await db.query(
                `SELECT mastery_score, current_streak, 
                CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_topic_progress' AND column_name='level_correct_count') 
                THEN (SELECT level_correct_count FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2) 
                ELSE current_streak END as progress_counter
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
                streakProgress: Math.min(1.0, progressCounter / 20.0)
            };
        }

        // 2. NEW CONTENT: If no reviews, use Bloom Climber logic
        // Get User's Progress State
        let pRes = await db.query(
            `SELECT * FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
            [userId, topicSlug]
        );

        let currentBloom = 1;

        if (pRes.rows.length === 0) {
            // First time? Create record.
            await db.query(`
                INSERT INTO user_topic_progress (user_id, topic_slug, current_bloom_level)
                VALUES ($1, $2, 1)
            `, [userId, topicSlug]);
        } else {
            currentBloom = pRes.rows[0].current_bloom_level;
        }

        // Fetch Question for this Level (Exclude answered ones entirely for now, until they enter SRS loop)
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
            ${excludedIds.length > 0 ? 'AND q.id NOT IN (' + excludedIds.join(',') + ')' : ''}
            ORDER BY RANDOM()
            LIMIT 1
        `, [topicSlug, currentBloom, userId]);

        // Mastery Score for progress bar
        let mRes = await db.query(
            `SELECT mastery_score, current_streak, 
            CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_topic_progress' AND column_name='level_correct_count') 
            THEN (SELECT level_correct_count FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2) 
            ELSE current_streak END as progress_counter
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
                streakProgress: Math.min(1.0, progressCounter / 20.0)
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
            ${excludedIds.length > 0 ? 'AND q.id NOT IN (' + excludedIds.join(',') + ')' : ''}
            ORDER BY RANDOM()
            LIMIT 1
        `, [topicSlug, userId]);

        // Mastery Score for progress bar
        mRes = await db.query(
            `SELECT mastery_score, current_streak, 
            CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_topic_progress' AND column_name='level_correct_count') 
            THEN (SELECT level_correct_count FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2) 
            ELSE current_streak END as progress_counter
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
                streakProgress: Math.min(1.0, progressCounter / 20.0)
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
            ${excludedIds.length > 0 ? 'AND q.id NOT IN (' + excludedIds.join(',') + ')' : ''}
            ORDER BY RANDOM()
            LIMIT 1
        `, [topicSlug]);

        const finalCoverage = pRes.rows[0]?.mastery_score || 0;
        const streak = pRes.rows[0]?.current_streak || 0;
        const progressCounter = pRes.rows[0]?.level_correct_count || streak; // Fallback if result exists but count missing
        return lastResort.rows[0] ? {
            ...lastResort.rows[0],
            is_review: true,
            coverage: finalCoverage,
            streak: streak,
            streakProgress: Math.min(1.0, progressCounter / 20.0)
        } : null;
    }

    /**
     * Update User Progress based on Answer (The Climber Logic)
     */
    async processAnswerResult(userId, topicSlug, isCorrect, questionId, bloomLevel = 1) {
        // 1. Update SRS State (Leitner + Mastery)
        // Ensure questionId is passed from controller!
        // 1. Update SRS State (Leitner + Mastery) - Fire and Forget for speed
        if (questionId) {
            this.updateSRS(userId, questionId, isCorrect).catch(err => console.error("SRS Update Failed (Non-fatal):", err));
        }

        // 2. Fetch Topic State & Question Counts
        let progressRes = await db.query(
            `SELECT * FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
            [userId, topicSlug]
        );

        if (progressRes.rows.length === 0) {
            // Record missing? Initialize it now (e.g. if question was fetched via predictive cache)
            console.log(`[ADY] Initializing missing progress for User ${userId} on ${topicSlug}`);
            await db.query(`
                INSERT INTO user_topic_progress (user_id, topic_slug, current_bloom_level)
                VALUES ($1, $2, 1)
                ON CONFLICT (user_id, topic_slug) DO NOTHING
            `, [userId, topicSlug]);

            // Re-fetch
            progressRes = await db.query(
                `SELECT * FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
                [userId, topicSlug]
            );

            if (progressRes.rows.length === 0) return null;
        }

        let { current_bloom_level, current_streak, level_correct_count, consecutive_wrong, total_answered, correct_answered, unlocked_bloom_level, stability } = progressRes.rows[0];

        // 🚨 RESILIENCE: If level_correct_count is undefined (missing column), fallback to streak
        const hasCounter = 'level_correct_count' in progressRes.rows[0];

        let event = null;

        // retention_score = retention_score || 0; // Useless assignment 
        // stability = stability || 1.0; // Fixed below

        // Calculate New Stability & Retention
        stability = analyticsEngine.calculateNewStability(stability, bloomLevel, isCorrect);
        // Reset retention to 100% on active review (Decay happens over time)
        let retention_score = 100;

        // Ensure unlocked level exists (migration fallback)
        unlocked_bloom_level = unlocked_bloom_level || 1;

        // Live Analytics Capture
        total_answered = (total_answered || 0) + 1;
        if (isCorrect) {
            correct_answered = (correct_answered || 0) + 1;
        }

        // 3. True Clinical Mastery Calculation (Weighted Progress)
        // Mastered (Streak 3+) = 1.0 points
        // Attempted Correct (Streak 1-2) = 0.5 points
        const progressStats = await db.query(`
            WITH subtopics AS (
                SELECT id FROM topics WHERE slug = $2
                OR parent_id IN (SELECT id FROM topics WHERE slug = $2)
            )
            SELECT 
                COUNT(*) FILTER (WHERE mastered = TRUE) as mastered_count,
                COUNT(*) FILTER (WHERE mastered = FALSE AND consecutive_correct > 0) as learning_count,
                (SELECT COUNT(*) FROM questions q 
                 INNER JOIN subtopics st ON q.topic_id = st.id
                 WHERE q.active = TRUE) as total_topic_questions
            FROM user_question_progress uqp
            JOIN questions q ON uqp.question_id = q.id
            INNER JOIN subtopics st ON q.topic_id = st.id
            WHERE uqp.user_id = $1 
            AND q.active = TRUE
        `, [userId, topicSlug]);
        const masteredCount = parseInt(progressStats.rows[0].mastered_count) || 0;
        const learningCount = parseInt(progressStats.rows[0].learning_count) || 0;
        const totalTopicCount = parseInt(progressStats.rows[0].total_topic_questions) || 1;

        // Reactive Mastery: Balanced points for study effort
        const masteryPoints = (masteredCount * 1.0) + (learningCount * 0.5);
        const mastery_score = Math.min(100, Math.round((masteryPoints / totalTopicCount) * 100));

        // 4. Bloom Promotion Logic
        level_correct_count = level_correct_count || 0;
        if (isCorrect) {
            current_streak += 1;
            level_correct_count += 1;
            consecutive_wrong = 0;

            // Check Coverage for Level Up 
            // (If user has mastered > 80% of current level questions, unlock next)
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

            // 🔍 CONTENT CHECK: Does the next level actually have questions?
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

            // PROMOTION GATE: > 80% Coverage OR Super Streak (20)
            // AND next level must have questions
            if ((coverage >= 0.8 || current_streak >= 20) && current_bloom_level < 4 && nextLevelCount > 0) {
                // Check if we need to unlock the next level in DB tracking
                if (current_bloom_level >= unlocked_bloom_level) {
                    unlocked_bloom_level = current_bloom_level + 1;
                    event = 'LEVEL_UNLOCKED'; // Special celebration
                }

                current_bloom_level += 1;
                current_streak = 0;
                level_correct_count = 0; // Reset counter for new level
                event = event || 'PROMOTION';
            } else {
                if (current_streak > 1) event = 'STREAK_EXTENDED';
            }

        } else {
            current_streak = 0;
            consecutive_wrong += 1;

            if (consecutive_wrong >= 3) {
                if (current_bloom_level > 1) {
                    current_bloom_level -= 1;
                    consecutive_wrong = 0;
                    level_correct_count = 0; // Reset counter on demotion too
                    event = 'DEMOTION';
                }
            }
        }

        // Update DB with all advanced stats
        // 🚀 RESILIENT UPDATE: Only update level_correct_count if it exists
        const updateQuery = `
            UPDATE user_topic_progress
            SET current_bloom_level = $1,
            current_streak = $2,
            ${hasCounter ? 'level_correct_count = $3,' : ''}
            consecutive_wrong = ${hasCounter ? '$4' : '$3'},
            total_answered = ${hasCounter ? '$5' : '$4'},
            correct_answered = ${hasCounter ? '$6' : '$5'},
            mastery_score = ${hasCounter ? '$7' : '$6'},
            unlocked_bloom_level = ${hasCounter ? '$8' : '$7'},
            questions_mastered = ${hasCounter ? '$9' : '$8'},
            stability = ${hasCounter ? '$10' : '$9'},
            retention_score = ${hasCounter ? '$11' : '$10'},
            last_studied_at = NOW()
            WHERE user_id = ${hasCounter ? '$12' : '$11'} AND topic_slug = ${hasCounter ? '$13' : '$12'}
        `;

        const updateParams = hasCounter
            ? [current_bloom_level, current_streak, level_correct_count, consecutive_wrong, total_answered, correct_answered, mastery_score, unlocked_bloom_level, masteredCount, stability, retention_score, userId, topicSlug]
            : [current_bloom_level, current_streak, consecutive_wrong, total_answered, correct_answered, mastery_score, unlocked_bloom_level, masteredCount, stability, retention_score, userId, topicSlug];

        await db.query(updateQuery, updateParams);

        return {
            newLevel: current_bloom_level,
            streak: current_streak,
            levelCorrectCount: level_correct_count ?? current_streak,
            streakProgress: Math.min(1.0, (level_correct_count ?? current_streak) / 20.0),
            event: event,
            mastered: masteredCount, // For toast
            coverage: mastery_score
        };
    }

    /**
     * Leitner System Logic
     */
    async updateSRS(userId, questionId, isCorrect) {
        // Get current SRS state
        const res = await db.query(`
        SELECT * FROM user_question_progress 
            WHERE user_id = $1 AND question_id = $2
            `, [userId, questionId]);

        let box = 0;
        let consecutive = 0;
        let wasMastered = false;

        if (res.rows.length > 0) {
            box = res.rows[0].box || 0;
            consecutive = res.rows[0].consecutive_correct || 0;
            wasMastered = res.rows[0].mastered || false;
        }

        let newBox;
        let intervalStr;

        if (isCorrect) {
            consecutive += 1;
            // Promotion: Box 0 -> 1 -> 2 ... -> 5
            newBox = Math.min(box + 1, 5);
        } else {
            consecutive = 0; // RESET streak on wrong
            // Penalty: Reset to Box 1 (Review tomorrow/soon)
            newBox = 1;
        }

        // Calculate Interval (Flexible Units)
        switch (newBox) {
            case 1: intervalStr = '1 day'; break;
            case 2: intervalStr = '3 days'; break;
            case 3: intervalStr = '7 days'; break;
            case 4: intervalStr = '14 days'; break;
            case 5: intervalStr = '30 days'; break;
            default: intervalStr = '0 minutes'; // Box 0 = New/Immediate
        }

        // If wrong, review is buffered by 5 minutes (user requested ~10 question delay)
        if (!isCorrect) intervalStr = '5 minutes';

        // MASTERY CHECK: 3 Consecutive Correct -> Mastered
        const isMastered = consecutive >= 3;

        // Log mastery event if newly mastered
        if (isMastered && !wasMastered) {
            console.log(`[SRS] User ${userId} MASTERED Question ${questionId} !`);
        }

        // Postgres Interval Syntax
        await db.query(`
            INSERT INTO user_question_progress(user_id, question_id, box, consecutive_correct, mastered, next_review_at, updated_at, last_answered_at)
        VALUES($1, $2, $3, $4, $5, NOW() + $6:: INTERVAL, NOW(), NOW())
            ON CONFLICT(user_id, question_id) 
            DO UPDATE SET
        box = EXCLUDED.box,
            consecutive_correct = EXCLUDED.consecutive_correct,
            mastered = EXCLUDED.mastered,
            next_review_at = EXCLUDED.next_review_at,
            updated_at = NOW(),
            last_answered_at = NOW();
        `, [userId, questionId, newBox, consecutive, isMastered, intervalStr]);

        console.log(`[SRS] User ${userId} Q ${questionId}: Box ${box} -> ${newBox} | Res ${isCorrect ? 'OK' : 'X'} | Strk ${consecutive} | Mastered: ${isMastered} `);
    }
}

module.exports = new AdaptiveEngine();
