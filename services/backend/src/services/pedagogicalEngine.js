const db = require('../config/db');
const analyticsEngine = require('./analyticsEngine');

/**
 * PedagogicalEngine: Unified Medical Learning & Adaptive Assessment Engine
 * 
 * Enforces the 8 core pedagogical rules of ArborMed:
 * 1. Spaced Repetition Priority (SRS)
 * 2. Diagnostic Fail-Down (Automatic Prerequisite Remediation)
 * 3. Bloom Taxonomy Climber (Levels 1 to 4)
 * 4. Humane Rolling Progression (Soft decrement instead of brutal reset)
 * 5. Weighted Mastery Score (L3/L4 clinical reasoning weighed 2.0x)
 * 6. Cross-Topic Nexus Propagation
 * 7. Response Latency-Derived Quality Scoring
 * 8. Full Selection Transparency
 */
class PedagogicalEngine {
    constructor() {
        this.PROMOTION_THRESHOLD = 20; // 20 net points required for Bloom level promotion
        this.MAX_BLOOM_LEVEL = 4;
        this.NEXUS_THRESHOLD = 80;     // Topic mastery score required to trigger cross-topic boost
    }

    /**
     * Determines the next challenge for the medical student.
     * 
     * Priority Queue:
     * 1. Predictive Override (if requested)
     * 2. Overdue SRS Reviews
     * 3. Diagnostic Fail-Down (Prerequisites for recently failed L3/L4 questions)
     * 4. Bloom Climber (Unseen questions at student's current Bloom level)
     * 5. Bloom Replay (Spaced replay of questions at current level)
     * 
     * @param {number|string} userId
     * @param {string} topicSlug
     * @param {Array<number>} [excludedIds=[]]
     * @param {number|null} [levelOverride=null]
     * @returns {Promise<Object|null>}
     */
    async getChallenge(userId, topicSlug, excludedIds = [], levelOverride = null) {
        const excludeParam = Array.isArray(excludedIds) && excludedIds.length > 0 ? excludedIds : null;

        // --- 1. PREDICTIVE OVERRIDE ---
        if (levelOverride !== null && !isNaN(parseInt(levelOverride))) {
            const overrideLevel = parseInt(levelOverride);
            const overrideRes = await db.query(`
                SELECT q.* 
                FROM questions q
                JOIN topics t ON q.topic_id = t.id
                WHERE (t.slug = $1 OR t.parent_id = (SELECT id FROM topics WHERE slug = $1))
                AND q.bloom_level = $2
                AND q.active = TRUE
                AND NOT EXISTS (
                    SELECT 1 FROM user_question_progress uqp
                    WHERE uqp.question_id = q.id AND uqp.user_id = $3
                )
                AND ($4::int[] IS NULL OR q.id != ALL($4::int[]))
                ORDER BY RANDOM()
                LIMIT 1
            `, [topicSlug, overrideLevel, userId, excludeParam]);

            if (overrideRes.rows.length > 0) {
                return {
                    ...overrideRes.rows[0],
                    is_review: false,
                    coverage: 0,
                    streak: 0,
                    streakProgress: 0,
                    selectionReason: `PREDICTIVE_LEVEL_${overrideLevel}`
                };
            }
        }

        // --- 2. SPACED REPETITION (SRS) OVERDUE QUEUE ---
        const dueReview = await db.query(`
            SELECT q.*, uqp.interval_days as stability, uqp.easiness_factor as difficulty
            FROM questions q
            JOIN user_question_progress uqp ON q.id = uqp.question_id
            JOIN topics t ON q.topic_id = t.id
            WHERE uqp.user_id = $1 
            AND uqp.next_review_at <= NOW()
            AND q.active = TRUE
            AND (t.slug = $2 OR t.parent_id = (SELECT id FROM topics WHERE slug = $2))
            AND ($3::int[] IS NULL OR q.id != ALL($3::int[]))
            ORDER BY uqp.next_review_at ASC, RANDOM()
            LIMIT 1
        `, [userId, topicSlug, excludeParam]);

        if (dueReview.rows.length > 0) {
            const topicProgress = await this._ensureUserTopicProgress(userId, topicSlug);
            return {
                ...dueReview.rows[0],
                is_review: true,
                coverage: topicProgress.mastery_score || 0,
                streak: topicProgress.current_streak || 0,
                streakProgress: Math.min(1.0, (topicProgress.level_correct_count || 0) / this.PROMOTION_THRESHOLD),
                selectionReason: 'SRS_REVIEW'
            };
        }

        // Fetch user topic progress once for use in fail-down and climber
        const userProgress = await this._ensureUserTopicProgress(userId, topicSlug);
        const currentBloom = userProgress.current_bloom_level || 1;

        // --- 3. DIAGNOSTIC FAIL-DOWN ---
        // If student failed an L3/L4 clinical reasoning question in this topic,
        // automatically serve an unmastered prerequisite to fill the foundation gap.
        const lastFailedInTopic = await db.query(`
            SELECT q.id, q.metadata, q.bloom_level
            FROM responses r
            JOIN questions q ON r.question_id = q.id
            JOIN topics t ON q.topic_id = t.id
            WHERE r.user_id = $1
            AND (t.slug = $2 OR t.parent_id = (SELECT id FROM topics WHERE slug = $2))
            AND r.is_correct = FALSE
            AND q.bloom_level >= 3
            ORDER BY r.created_at DESC
            LIMIT 1
        `, [userId, topicSlug]);

        if (lastFailedInTopic?.rows?.length > 0) {
            const metadata = lastFailedInTopic.rows[0].metadata;
            const prereqs = Array.isArray(metadata?.prerequisite_ids) ? metadata.prerequisite_ids : [];

            if (prereqs.length > 0) {
                const prereqQuestion = await db.query(`
                    SELECT q.* FROM questions q
                    WHERE q.id = ANY($1)
                    AND q.active = TRUE
                    AND NOT EXISTS (
                        SELECT 1 FROM user_question_progress uqp 
                        WHERE uqp.question_id = q.id AND uqp.user_id = $2 AND uqp.mastered = TRUE
                    )
                    AND ($3::int[] IS NULL OR q.id != ALL($3::int[]))
                    ORDER BY RANDOM()
                    LIMIT 1
                `, [prereqs, userId, excludeParam]);

                if (prereqQuestion?.rows?.length > 0) {
                    return {
                        ...prereqQuestion.rows[0],
                        is_review: false,
                        coverage: userProgress.mastery_score || 0,
                        streak: userProgress.current_streak || 0,
                        streakProgress: Math.min(1.0, (userProgress.level_correct_count || userProgress.progress_counter || 0) / this.PROMOTION_THRESHOLD),
                        selectionReason: `FAIL_DOWN_PREREQ_${lastFailedInTopic.rows[0].id}`
                    };
                }
            }
        }

        // --- 4. BLOOM CLIMBER (Unseen Questions) ---
        const nextQuestion = await db.query(`
            SELECT q.* FROM questions q
            JOIN topics t ON q.topic_id = t.id
            WHERE q.bloom_level = $1
            AND q.active = TRUE
            AND (t.slug = $2 OR t.parent_id = (SELECT id FROM topics WHERE slug = $2))
            AND NOT EXISTS (
                SELECT 1 FROM user_question_progress uqp 
                WHERE uqp.question_id = q.id AND uqp.user_id = $3
            )
            AND ($4::int[] IS NULL OR q.id != ALL($4::int[]))
            ORDER BY RANDOM()
            LIMIT 1
        `, [currentBloom, topicSlug, userId, excludeParam]);

        if (nextQuestion?.rows?.length > 0) {
            let stats = userProgress;
            try {
                const statsRes = await db.query(
                    `SELECT mastery_score, current_streak, level_correct_count, progress_counter FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2`,
                    [userId, topicSlug]
                );
                if (statsRes?.rows?.[0]) stats = statsRes.rows[0];
            } catch (_) {}

            return {
                ...nextQuestion.rows[0],
                is_review: false,
                coverage: stats.mastery_score || 0,
                streak: stats.current_streak || 0,
                streakProgress: Math.min(1.0, (stats.level_correct_count || stats.progress_counter || 0) / this.PROMOTION_THRESHOLD),
                selectionReason: `BLOOM_CLIMBER_LEVEL_${currentBloom}`
            };
        }

        // --- 5. BLOOM REPLAY (Fallback when all questions at current level were seen) ---
        const fallbackQuestion = await db.query(`
            SELECT q.* FROM questions q
            JOIN topics t ON q.topic_id = t.id
            WHERE q.bloom_level = $1
            AND q.active = TRUE
            AND (t.slug = $2 OR t.parent_id = (SELECT id FROM topics WHERE slug = $2))
            AND ($3::int[] IS NULL OR q.id != ALL($3::int[]))
            ORDER BY RANDOM()
            LIMIT 1
        `, [currentBloom, topicSlug, excludeParam]);

        if (fallbackQuestion?.rows?.length > 0) {
            return {
                ...fallbackQuestion.rows[0],
                is_review: true,
                coverage: userProgress.mastery_score || 0,
                streak: userProgress.current_streak || 0,
                streakProgress: Math.min(1.0, (userProgress.level_correct_count || userProgress.progress_counter || 0) / this.PROMOTION_THRESHOLD),
                selectionReason: `BLOOM_REPLAY_LEVEL_${currentBloom}`
            };
        }

        return null;
    }

    /**
     * Backward-compatible alias for getChallenge.
     */
    async getNextQuestion(userId, topicSlug, excludedIds = [], levelOverride = null) {
        return this.getChallenge(userId, topicSlug, excludedIds, levelOverride);
    }

    /**
     * Resolves an answer submission, computes FSRS/SM-2 stability, applies humane rolling progress,
     * recalculates true weighted mastery, and checks for cross-topic Nexus propagation.
     * 
     * @param {number|string} userId
     * @param {string} topicSlug
     * @param {number|string} questionId
     * @param {boolean} isCorrect
     * @param {number|null} [quality=null] (0-5 scale)
     * @param {number|null} [responseTimeMs=null]
     * @returns {Promise<Object>}
     */
    async resolveResponse(userId, topicSlug, questionId, isCorrect, quality = null, responseTimeMs = null) {
        // Compute implicit quality from latency if not explicitly provided
        let computedQuality = quality;
        if (computedQuality === null || isNaN(parseInt(computedQuality))) {
            if (responseTimeMs !== null && !isNaN(parseInt(responseTimeMs))) {
                const time = parseInt(responseTimeMs);
                if (isCorrect) {
                    if (time <= 6000) computedQuality = 5;      // Confident instant recall
                    else if (time <= 20000) computedQuality = 4; // Normal thoughtful response
                    else computedQuality = 3;                    // Hesitant correct
                } else {
                    if (time > 15000) computedQuality = 2;       // Struggled incorrect
                    else computedQuality = 1;                    // Immediate lapse
                }
            } else {
                computedQuality = isCorrect ? 4 : 2;
            }
        } else {
            computedQuality = Math.max(0, Math.min(5, parseInt(computedQuality)));
        }

        // 1. Spaced Repetition (SRS / SM-2)
        const srsOutcome = await this._updateSRS(userId, questionId, isCorrect, computedQuality);

        // 2. Topic Progress & Humane Rolling Progression
        const progress = await this._ensureUserTopicProgress(userId, topicSlug);
        let currentBloom = Number(progress.current_bloom_level || 1);
        let currentStreak = Number(progress.current_streak || 0);
        let levelCorrectCount = Number(progress.level_correct_count ?? progress.progress_counter ?? 0);
        let promotedTo = null;

        if (isCorrect) {
            currentStreak += 1;
            levelCorrectCount += 1;

            // Promotion check: advance to next Bloom level
            if (levelCorrectCount >= this.PROMOTION_THRESHOLD && currentBloom < this.MAX_BLOOM_LEVEL) {
                currentBloom += 1;
                levelCorrectCount = 0;
                promotedTo = currentBloom;
            }
        } else {
            currentStreak = 0;
            // Humane soft-decrement: penalize by 2 points instead of wiping entire progress to 0!
            levelCorrectCount = Math.max(0, levelCorrectCount - 2);
        }

        // 3. Recalculate True Weighted Mastery
        const stats = await db.query(`
            SELECT 
                COUNT(*) FILTER (WHERE q.bloom_level <= 2 AND uqp.mastered = TRUE) as m_l12,
                COUNT(*) FILTER (WHERE q.bloom_level > 2 AND uqp.mastered = TRUE) as m_l34,
                COUNT(*) FILTER (WHERE q.bloom_level <= 2) as t_l12,
                COUNT(*) FILTER (WHERE q.bloom_level > 2) as t_l34
            FROM questions q
            JOIN topics t ON q.topic_id = t.id
            LEFT JOIN user_question_progress uqp ON q.id = uqp.question_id AND uqp.user_id = $1
            WHERE (t.slug = $2 OR t.parent_id = (SELECT id FROM topics WHERE slug = $2))
            AND q.active = TRUE
        `, [userId, topicSlug]);

        const { m_l12, m_l34, t_l12, t_l34 } = stats.rows[0];
        const num = (parseInt(m_l12 || 0) * 1.0) + (parseInt(m_l34 || 0) * 2.0);
        const den = (parseInt(t_l12 || 0) * 1.0) + (parseInt(t_l34 || 0) * 2.0);
        const masteryScore = den > 0 ? Math.min(100, Math.round((num / den) * 100)) : 0;

        // 4. Cross-Topic Nexus Propagation
        if (masteryScore >= this.NEXUS_THRESHOLD) {
            await this._propagateNexusBoost(userId, topicSlug);
        }

        // 5. Persist Topic Progress (including total answered and correct counters)
        await db.query(`
            UPDATE user_topic_progress
            SET current_bloom_level = $1,
                current_streak = $2,
                level_correct_count = $3,
                mastery_score = $4,
                total_answered = COALESCE(total_answered, 0) + 1,
                correct_answered = COALESCE(correct_answered, 0) + $5,
                consecutive_wrong = CASE WHEN $6 = TRUE THEN 0 ELSE COALESCE(consecutive_wrong, 0) + 1 END,
                last_studied_at = NOW()
            WHERE user_id = $7 AND topic_slug = $8
        `, [
            currentBloom,
            currentStreak,
            levelCorrectCount,
            masteryScore,
            isCorrect ? 1 : 0,
            isCorrect,
            userId,
            topicSlug
        ]);

        const streakProgress = Math.min(1.0, levelCorrectCount / this.PROMOTION_THRESHOLD);

        return {
            newLevel: currentBloom,
            promotedTo,
            mastery_score: masteryScore,
            srs: srsOutcome,
            sm2: srsOutcome,
            level_correct_count: levelCorrectCount,
            streakProgress: streakProgress,
            streak: currentStreak,
            current_streak: currentStreak,
            event: promotedTo ? 'PROMOTION' : null,
            quality: computedQuality
        };
    }

    /**
     * Backward-compatible alias for resolveResponse.
     */
    async processAnswerResult(userId, topicSlug, isCorrect, questionId, _bloomLevel = 1, quality = null) {
        return this.resolveResponse(userId, topicSlug, questionId, isCorrect, quality);
    }

    /**
     * Update SRS metrics for an individual question.
     * @private
     */
    async _updateSRS(userId, questionId, isCorrect, quality) {
        const res = await db.query(`
            SELECT * FROM user_question_progress 
            WHERE user_id = $1 AND question_id = $2
        `, [userId, questionId]);

        let { easiness_factor, interval_days, repetition_count } = res.rows[0] || {
            easiness_factor: 2.5,
            interval_days: 0,
            repetition_count: 0
        };

        const sm2 = analyticsEngine.calculateSM2(
            quality,
            parseFloat(easiness_factor) || 2.5,
            parseInt(interval_days) || 0,
            parseInt(repetition_count) || 0
        );

        const isMastered = sm2.repetitions >= 3;

        await db.query(`
            INSERT INTO user_question_progress (
                user_id, question_id, easiness_factor, interval_days, repetition_count, next_review_at, mastered
            )
            VALUES ($1, $2, $3, $4, $5, NOW() + ($6 || ' days')::INTERVAL, $7)
            ON CONFLICT (user_id, question_id) DO UPDATE SET
                easiness_factor = EXCLUDED.easiness_factor,
                interval_days = EXCLUDED.interval_days,
                repetition_count = EXCLUDED.repetition_count,
                next_review_at = EXCLUDED.next_review_at,
                mastered = EXCLUDED.mastered
        `, [userId, questionId, sm2.easinessFactor, sm2.interval, sm2.repetitions, sm2.interval, isMastered]);

        return {
            interval: sm2.interval,
            easinessFactor: sm2.easinessFactor,
            repetitions: sm2.repetitions,
            mastered: isMastered
        };
    }

    /**
     * Ensures user_topic_progress record exists and evaluates initial Nexus starting level.
     * @private
     */
    async _ensureUserTopicProgress(userId, topicSlug) {
        const res = await db.query(`
            SELECT * FROM user_topic_progress 
            WHERE user_id = $1 AND topic_slug = $2
        `, [userId, topicSlug]);

        if (res.rows.length > 0) {
            const row = res.rows[0];
            if (row.progress_counter !== undefined && row.level_correct_count === undefined) {
                row.level_correct_count = row.progress_counter;
            }
            return row;
        }

        // Determine baseline Bloom level (check if any related Nexus topic has >= 80% mastery)
        let startingBloom = 1;
        try {
            const topicRes = await db.query(`SELECT nexus_metadata FROM topics WHERE slug = $1`, [topicSlug]);
            const links = topicRes.rows[0]?.nexus_metadata?.nexus_links;
            if (Array.isArray(links) && links.length > 0) {
                const linkedSlugs = links.map(l => l.topic_slug).filter(Boolean);
                if (linkedSlugs.length > 0) {
                    const nexusCheck = await db.query(`
                        SELECT MAX(mastery_score) as max_score 
                        FROM user_topic_progress 
                        WHERE user_id = $1 AND topic_slug = ANY($2)
                    `, [userId, linkedSlugs]);

                    if ((nexusCheck.rows[0]?.max_score || 0) >= this.NEXUS_THRESHOLD) {
                        startingBloom = 2; // Nexus Boost to Level 2!
                    }
                }
            }
        } catch (err) {
            // Non-blocking fallback to Level 1
        }

        const inserted = await db.query(`
            INSERT INTO user_topic_progress (
                user_id, topic_slug, current_bloom_level, level_correct_count, current_streak, mastery_score
            )
            VALUES ($1, $2, $3, 0, 0, 0)
            ON CONFLICT (user_id, topic_slug) DO NOTHING
            RETURNING *
        `, [userId, topicSlug, startingBloom]);

        if (inserted.rows.length > 0) {
            return inserted.rows[0];
        }

        // In case of conflict race
        const recheck = await db.query(`
            SELECT * FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2
        `, [userId, topicSlug]);
        return recheck.rows[0];
    }

    /**
     * When student masters a topic (>= 80%), propagates baseline boost to related Nexus topics.
     * @private
     */
    async _propagateNexusBoost(userId, sourceTopicSlug) {
        try {
            const topicRes = await db.query(`SELECT nexus_metadata FROM topics WHERE slug = $1`, [sourceTopicSlug]);
            const links = topicRes?.rows?.[0]?.nexus_metadata?.nexus_links;
            if (!Array.isArray(links) || links.length === 0) return;

            for (const link of links) {
                if (!link.topic_slug) continue;
                // If the user has not started the linked topic, seed it at Level 2
                await db.query(`
                    INSERT INTO user_topic_progress (user_id, topic_slug, current_bloom_level, level_correct_count)
                    VALUES ($1, $2, 2, 0)
                    ON CONFLICT (user_id, topic_slug) DO UPDATE
                    SET current_bloom_level = GREATEST(user_topic_progress.current_bloom_level, 2)
                    WHERE user_topic_progress.current_bloom_level < 2 AND user_topic_progress.mastery_score = 0
                `, [userId, link.topic_slug]);
            }
        } catch (err) {
            console.error('[PEDAGOGICAL] Nexus propagation error:', err.message);
        }
    }
}

module.exports = new PedagogicalEngine();
