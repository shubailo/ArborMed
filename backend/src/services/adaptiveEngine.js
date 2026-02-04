const db = require('../config/db');

class AdaptiveEngine {
    /**
     * Get the next best question for a user.
     * @param {number} userId - The user's ID.
     * @param {string} topicSlug - The topic slug (e.g., 'cardiovascular').
     */
    /**
     * Get the next best question for a user based on Bloom Level.
     */
    async getNextQuestion(userId, topicSlug) {
        // 1. SRS PRIORITY: Check for "Due" questions first (Leitner Box review)
        const dueReview = await db.query(`
            SELECT q.* 
            FROM questions q
            JOIN user_question_progress uqp ON q.id = uqp.question_id
            JOIN topics t ON q.topic_id = t.id
            WHERE uqp.user_id = $1 
            AND t.slug = $2
            AND uqp.next_review_at <= NOW() -- It's time to review!
            AND q.active = TRUE
            ORDER BY uqp.next_review_at ASC, RANDOM() -- Oldest due first, then random
            LIMIT 1
        `, [userId, topicSlug]);

        if (dueReview.rows.length > 0) {
            console.log(`[SRS] Serving Review Question for User ${userId}: ${dueReview.rows[0].id}`);
            const mRes = await db.query(
                `SELECT mastery_score FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
                [userId, topicSlug]
            );
            return {
                ...dueReview.rows[0],
                is_review: true,
                coverage: mRes.rows[0]?.mastery_score || 0
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
            SELECT q.* 
            FROM questions q
            JOIN topics t ON q.topic_id = t.id
            WHERE t.slug = $1
            AND q.bloom_level = $2
            AND q.active = TRUE
            AND q.id NOT IN (
                SELECT question_id FROM user_question_progress WHERE user_id = $3
            )
            ORDER BY RANDOM()
            LIMIT 1
        `, [topicSlug, currentBloom, userId]);

        // Mastery Score for progress bar
        let mRes = await db.query(
            `SELECT mastery_score FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
            [userId, topicSlug]
        );
        const qCoverage = mRes.rows[0]?.mastery_score || 0;

        if (result.rows.length > 0) {
            return {
                ...result.rows[0],
                is_review: false,
                coverage: qCoverage
            };
        }

        // Fallback: Buffer content (any level not yet tracked)
        const fallback = await db.query(`
            SELECT q.* 
            FROM questions q
            JOIN topics t ON q.topic_id = t.id
            WHERE t.slug = $1
            AND q.active = TRUE
            AND q.id NOT IN (
                SELECT question_id FROM user_question_progress WHERE user_id = $2
            )
            ORDER BY RANDOM()
            LIMIT 1
        `, [topicSlug, userId]);

        // Mastery Score for progress bar
        mRes = await db.query(
            `SELECT mastery_score FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
            [userId, topicSlug]
        );
        const fallbackCoverage = mRes.rows[0]?.mastery_score || 0;

        if (fallback.rows.length > 0) {
            return {
                ...fallback.rows[0],
                is_review: false,
                coverage: fallbackCoverage
            };
        }

        // LAST RESORT: Infinite Practice (Random from topic)
        const lastResort = await db.query(`
            SELECT q.* 
            FROM questions q
            JOIN topics t ON q.topic_id = t.id
            WHERE t.slug = $1
            AND q.active = TRUE
            ORDER BY RANDOM()
            LIMIT 1
        `, [topicSlug]);

        // Mastery Score for progress bar
        pRes = await db.query(
            `SELECT mastery_score FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
            [userId, topicSlug]
        );
        const finalCoverage = pRes.rows[0]?.mastery_score || 0;

        return lastResort.rows[0] ? { ...lastResort.rows[0], is_review: true, coverage: finalCoverage } : null;
    }

    /**
     * Update User Progress based on Answer (The Climber Logic)
     */
    async processAnswerResult(userId, topicSlug, isCorrect, questionId) {
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

        if (progressRes.rows.length === 0) return null;

        let { current_bloom_level, current_streak, consecutive_wrong, total_answered, correct_answered, sessions_completed, unlocked_bloom_level } = progressRes.rows[0];
        let event = null;

        // Ensure unlocked level exists (migration fallback)
        unlocked_bloom_level = unlocked_bloom_level || 1;

        // Live Analytics Capture
        total_answered = (total_answered || 0) + 1;
        if (isCorrect) {
            correct_answered = (correct_answered || 0) + 1;
        }

        // 3. True Clinical Mastery Calculation (Weighted Progress)
        // Mastered (Streak 3+) = 1.0 points
        // Attempted Correct (Streak 1-2) = 0.25 points
        const progressStats = await db.query(`
            SELECT 
                COUNT(*) FILTER (WHERE mastered = TRUE) as mastered_count,
                COUNT(*) FILTER (WHERE mastered = FALSE AND consecutive_correct > 0) as learning_count,
                (SELECT COUNT(*) FROM questions q 
                 JOIN topics t ON q.topic_id = t.id 
                 WHERE t.slug = $2 AND q.active = TRUE) as total_topic_questions
            FROM user_question_progress uqp
            JOIN topics t ON uqp.question_id IN (SELECT id FROM questions WHERE topic_id = t.id)
            WHERE uqp.user_id = $1 AND t.slug = $2
        `, [userId, topicSlug]);

        const masteredCount = parseInt(progressStats.rows[0].mastered_count) || 0;
        const learningCount = parseInt(progressStats.rows[0].learning_count) || 0;
        const totalTopicCount = parseInt(progressStats.rows[0].total_topic_questions) || 1;

        // Reactive Mastery: Balanced points for study effort
        const masteryPoints = (masteredCount * 1.0) + (learningCount * 0.5);
        const mastery_score = Math.min(100, Math.round((masteryPoints / totalTopicCount) * 100));

        // 4. Bloom Promotion Logic
        if (isCorrect) {
            current_streak += 1;
            consecutive_wrong = 0;

            // Check Coverage for Level Up 
            // (If user has mastered > 80% of current level questions, unlock next)
            const levelStats = await db.query(`
                 SELECT 
                    (SELECT COUNT(*) FROM questions q 
                     JOIN topics t ON q.topic_id = t.id 
                     WHERE t.slug = $2 AND q.bloom_level = $3 AND q.active = TRUE) as total_in_level,
                    (SELECT COUNT(*) FROM user_question_progress uqp
                     JOIN questions q ON uqp.question_id = q.id
                     JOIN topics t ON q.topic_id = t.id
                     WHERE uqp.user_id = $1 AND t.slug = $2 AND q.bloom_level = $3 AND uqp.mastered = TRUE) as mastered_in_level
            `, [userId, topicSlug, current_bloom_level]);

            const totalInLevel = parseInt(levelStats.rows[0].total_in_level) || 1;
            const masteredInLevel = parseInt(levelStats.rows[0].mastered_in_level) || 0;

            const coverage = masteredInLevel / totalInLevel;

            // PROMOTION GATE: > 80% Coverage OR Super Streak (20)
            // Only promote if not already at max
            if ((coverage >= 0.8 || current_streak >= 20) && current_bloom_level < 4) {
                // Check if we need to unlock the next level in DB tracking
                if (current_bloom_level >= unlocked_bloom_level) {
                    unlocked_bloom_level = current_bloom_level + 1;
                    event = 'LEVEL_UNLOCKED'; // Special celebration
                }

                current_bloom_level += 1;
                current_streak = 0;
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
                    event = 'DEMOTION';
                }
            }
        }

        // Update DB with all advanced stats
        await db.query(`
            UPDATE user_topic_progress
            SET current_bloom_level = $1, 
                current_streak = $2, 
                consecutive_wrong = $3, 
                total_answered = $4,
                correct_answered = $5,
                mastery_score = $6,
                unlocked_bloom_level = $7,
                questions_mastered = $8,
                last_studied_at = NOW()
            WHERE user_id = $9 AND topic_slug = $10
        `, [current_bloom_level, current_streak, consecutive_wrong, total_answered, correct_answered, mastery_score, unlocked_bloom_level, masteredCount, userId, topicSlug]);

        return {
            newLevel: current_bloom_level,
            streak: current_streak,
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

        let newBox = box;
        let intervalStr = '0 minutes';

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
            console.log(`[SRS] User ${userId} MASTERED Question ${questionId}!`);
        }

        // Postgres Interval Syntax
        await db.query(`
            INSERT INTO user_question_progress (user_id, question_id, box, consecutive_correct, mastered, next_review_at, updated_at, last_answered_at)
            VALUES ($1, $2, $3, $4, $5, NOW() + $6::INTERVAL, NOW(), NOW())
            ON CONFLICT (user_id, question_id) 
            DO UPDATE SET 
                box = EXCLUDED.box,
                consecutive_correct = EXCLUDED.consecutive_correct,
                mastered = EXCLUDED.mastered,
                next_review_at = EXCLUDED.next_review_at,
                updated_at = NOW(),
                last_answered_at = NOW();
        `, [userId, questionId, newBox, consecutive, isMastered, intervalStr]);

        console.log(`[SRS] User ${userId} Q ${questionId}: Box ${box} -> ${newBox} | Res ${isCorrect ? 'OK' : 'X'} | Strk ${consecutive} | Mastered: ${isMastered}`);
    }
}

module.exports = new AdaptiveEngine();
