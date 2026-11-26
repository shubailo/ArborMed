const db = require('../config/db');
const { withTransaction } = require('../utils/dbHelpers');
const analyticsEngine = require('./analyticsEngine');

// In both selection and persistence, a previously unstudied topic starts at
// level two if any of its linked topics already meets the Nexus threshold.
const initialBloomSql = `CASE WHEN EXISTS (
    SELECT 1 FROM user_topic_progress linked
    WHERE linked.user_id = $1 AND linked.mastery_score >= $3
      AND (t.nexus_metadata->'nexus_links') @>
          jsonb_build_array(jsonb_build_object('topic_slug', linked.topic_slug))
) THEN 2 ELSE 1 END`;


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
                SELECT q.*, t.slug AS topic_slug
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
            SELECT q.*, t.slug AS topic_slug, uqp.interval_days AS stability, uqp.easiness_factor AS srs_easiness_factor
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
            const topicProgress = await this._ensureUserTopicProgress(userId, dueReview.rows[0].topic_slug);
            return {
                ...dueReview.rows[0],
                currentBloom: topicProgress.current_bloom_level || 1,
                is_review: true,
                coverage: topicProgress.mastery_score || 0,
                streak: topicProgress.current_streak || 0,
                streakProgress: Math.min(1.0, (topicProgress.level_correct_count || 0) / this.PROMOTION_THRESHOLD),
                selectionReason: 'SRS_REVIEW'
            };
        }

        // --- 3. DIAGNOSTIC FAIL-DOWN ---
        // If student failed an L3/L4 clinical reasoning question in this topic,
        // automatically serve an unmastered prerequisite to fill the foundation gap.
        const prerequisite = await db.query(`
            SELECT candidate.*, target.slug AS topic_slug, failed.id AS failed_id
            FROM responses r
            JOIN questions failed ON failed.id = r.question_id
            JOIN topics source ON source.id = failed.topic_id
            CROSS JOIN LATERAL jsonb_array_elements(
                CASE WHEN jsonb_typeof(failed.metadata->'prerequisite_ids') = 'array'
                     THEN failed.metadata->'prerequisite_ids' ELSE '[]'::jsonb END
            ) AS link(value)
            CROSS JOIN LATERAL (VALUES (ltrim(CASE jsonb_typeof(link.value)
                WHEN 'number' THEN trim_scale(link.value::numeric)::text
                WHEN 'string' THEN regexp_replace(link.value #>> '{}', '^[[:space:]]+|[[:space:]]+$', '', 'g')
            END, '0'))) AS normalized(id)
            JOIN questions candidate ON candidate.id = CASE
                WHEN normalized.id ~ '^[0-9]{1,10}$' THEN normalized.id::bigint END
            JOIN topics target ON target.id = candidate.topic_id
            WHERE r.user_id = $1 AND r.is_correct = FALSE
              AND (source.slug = $2 OR source.parent_id = (SELECT id FROM topics WHERE slug = $2))
              AND failed.bloom_level >= 3 AND failed.active AND candidate.active
              AND ($3::int[] IS NULL OR candidate.id != ALL($3::int[]))
              AND NOT EXISTS (
                  SELECT 1 FROM responses newer
                  WHERE newer.user_id = r.user_id AND newer.question_id = r.question_id
                    AND (newer.created_at, newer.id) > (r.created_at, r.id)
              )
              AND NOT EXISTS (
                  SELECT 1 FROM user_question_progress p
                  WHERE p.user_id = r.user_id AND p.question_id = candidate.id AND p.mastered
              )
            ORDER BY r.created_at DESC, r.id DESC, RANDOM()
            LIMIT 1
        `, [userId, topicSlug, excludeParam]);

        if (prerequisite.rows.length) {
            const { failed_id, ...question } = prerequisite.rows[0];
            const progress = await this._ensureUserTopicProgress(userId, question.topic_slug);
            return {
                ...question,
                currentBloom: progress.current_bloom_level || 1,
                is_review: false,
                coverage: progress.mastery_score || 0,
                streak: progress.current_streak || 0,
                streakProgress: Math.min(1, (progress.level_correct_count ?? progress.progress_counter ?? 0) / this.PROMOTION_THRESHOLD),
                selectionReason: `FAIL_DOWN_PREREQ_${failed_id}`,
            };
        }

        // Prefer an unseen question. For a parent subject, each section uses
        // the same topic progress that submitAnswer updates for its questions.
        const selection = await db.query(`
            WITH scoped_topics AS (
                SELECT t.id, t.slug,
                       COALESCE(p.current_bloom_level, ${initialBloomSql}) AS study_bloom,
                       COALESCE(p.mastery_score, 0) AS coverage,
                       COALESCE(p.current_streak, 0) AS streak,
                       COALESCE(p.level_correct_count, 0) AS level_count
                FROM topics t LEFT JOIN user_topic_progress p ON p.user_id = $1 AND p.topic_slug = t.slug
                WHERE t.slug = $2 OR t.parent_id = (SELECT id FROM topics WHERE slug = $2)
            )
            SELECT q.*, t.slug AS topic_slug, t.study_bloom, t.coverage, t.streak, t.level_count,
                   (uqp.question_id IS NOT NULL) AS is_review
            FROM scoped_topics t JOIN questions q ON q.topic_id = t.id AND q.bloom_level = t.study_bloom
            LEFT JOIN user_question_progress uqp ON uqp.question_id = q.id AND uqp.user_id = $1
            WHERE q.active = TRUE AND ($4::int[] IS NULL OR q.id != ALL($4::int[]))
            ORDER BY is_review, RANDOM() LIMIT 1
        `, [userId, topicSlug, this.NEXUS_THRESHOLD, excludeParam]);
        if (!selection.rows.length) return null;
        const { study_bloom, level_count, ...question } = selection.rows[0];
        return {
            ...question,
            currentBloom: study_bloom,
            streakProgress: Math.min(1, level_count / this.PROMOTION_THRESHOLD),
            selectionReason: `BLOOM_${question.is_review ? 'REPLAY' : 'CLIMBER'}_LEVEL_${study_bloom}`,
        };
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
    async resolveResponse(userId, topicSlug, questionId, isCorrect, quality = null, responseTimeMs = null, client = null) {
        if (!client) {
            return withTransaction(async tx => {
                await tx.query('SELECT id FROM users WHERE id = $1 FOR UPDATE', [userId]);
                return this.resolveResponse(userId, topicSlug, questionId, isCorrect, quality, responseTimeMs, tx);
            });
        }
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
        const srsOutcome = await this._updateSRS(userId, questionId, isCorrect, computedQuality, client);

        // 2. Topic Progress & Humane Rolling Progression
        const progress = await this._ensureUserTopicProgress(userId, topicSlug, client);
        let currentBloom = Number(progress.current_bloom_level || 1);
        let currentStreak = Number(progress.current_streak || 0);
        let levelCorrectCount = Number(progress.level_correct_count ?? progress.progress_counter ?? 0);
        let consecutiveWrong = Number(progress.consecutive_wrong || 0);
        let promotedTo = null;
        let demotedTo = null;

        if (isCorrect) {
            currentStreak += 1;
            levelCorrectCount += 1;
            consecutiveWrong = 0;

            // Promotion check: advance to next Bloom level
            if (levelCorrectCount >= this.PROMOTION_THRESHOLD && currentBloom < this.MAX_BLOOM_LEVEL) {
                currentBloom += 1;
                levelCorrectCount = 0;
                promotedTo = currentBloom;
            }
        } else {
            currentStreak = 0;
            consecutiveWrong += 1;
            // Humane soft-decrement: penalize by 2 points instead of wiping entire progress to 0!
            levelCorrectCount = Math.max(0, levelCorrectCount - 2);

            // Demotion check: 3 consecutive wrong answers and current level > 1
            if (consecutiveWrong >= 3 && currentBloom > 1) {
                currentBloom -= 1;
                levelCorrectCount = 0;
                demotedTo = currentBloom;
                consecutiveWrong = 0;
            }
        }

        // 3. Recalculate True Weighted Mastery
        const stats = await client.query(`
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
            await this._propagateNexusBoost(userId, topicSlug, client);
        }

        // 5. Persist Topic Progress (including total answered and correct counters)
        await client.query(`
            UPDATE user_topic_progress
            SET current_bloom_level = $1,
                current_streak = $2,
                level_correct_count = $3,
                mastery_score = $4,
                total_answered = COALESCE(total_answered, 0) + 1,
                correct_answered = COALESCE(correct_answered, 0) + $5,
                consecutive_wrong = $6,
                last_studied_at = NOW()
            WHERE user_id = $7 AND topic_slug = $8
        `, [
            currentBloom,
            currentStreak,
            levelCorrectCount,
            masteryScore,
            isCorrect ? 1 : 0,
            consecutiveWrong,
            userId,
            topicSlug
        ]);

        const streakProgress = Math.min(1.0, levelCorrectCount / this.PROMOTION_THRESHOLD);
        const levelDirection = promotedTo ? 'UP' : (demotedTo ? 'DOWN' : 'NONE');

        return {
            currentBloomLevel: currentBloom,
            newLevel: promotedTo || demotedTo || null,
            promotedTo,
            demotedTo,
            levelDirection,
            mastery_score: masteryScore,
            srs: srsOutcome,
            sm2: srsOutcome,
            level_correct_count: levelCorrectCount,
            streakProgress: streakProgress,
            streak: currentStreak,
            current_streak: currentStreak,
            event: promotedTo ? 'PROMOTION' : (demotedTo ? 'DEMOTION' : null),
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
    async _updateSRS(userId, questionId, isCorrect, quality, client = db) {
        const res = await client.query(`
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

        // PostgreSQL and the API must both be able to represent the scheduled
        // date. Keep review dates within the four-digit ISO-8601 year range.
        const maxReviewDays = Math.floor((Date.UTC(9999, 11, 31) - Date.now()) / 86_400_000);
        const interval = Math.min(sm2.interval, maxReviewDays);
        const isMastered = sm2.repetitions >= 3;

        await client.query(`
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
        `, [userId, questionId, sm2.easinessFactor, interval, sm2.repetitions, interval, isMastered]);

        return {
            interval,
            easinessFactor: sm2.easinessFactor,
            repetitions: sm2.repetitions,
            mastered: isMastered
        };
    }

    /**
     * Ensures user_topic_progress record exists and evaluates initial Nexus starting level.
     * @private
     */
    async _ensureUserTopicProgress(userId, topicSlug, client = db) {
        const res = await client.query(`
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

        const inserted = await client.query(`
            INSERT INTO user_topic_progress (
                user_id, topic_slug, current_bloom_level, level_correct_count, current_streak, mastery_score
            )
            SELECT $1, t.slug, ${initialBloomSql}, 0, 0, 0 FROM topics t WHERE t.slug = $2
            ON CONFLICT (user_id, topic_slug) DO NOTHING
            RETURNING *
        `, [userId, topicSlug, this.NEXUS_THRESHOLD]);

        if (inserted.rows.length > 0) {
            return inserted.rows[0];
        }

        // In case of conflict race
        const recheck = await client.query(`
            SELECT * FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2
        `, [userId, topicSlug]);
        return recheck.rows[0];
    }

    /**
     * When student masters a topic (>= 80%), propagates baseline boost to related Nexus topics.
     * @private
     */
    async _propagateNexusBoost(userId, sourceTopicSlug, client = db) {
        await client.query(`
            INSERT INTO user_topic_progress (user_id, topic_slug, current_bloom_level, level_correct_count)
            SELECT DISTINCT $1::int, target.slug, 2, 0
            FROM topics source
            CROSS JOIN LATERAL jsonb_array_elements(
                CASE WHEN jsonb_typeof(source.nexus_metadata->'nexus_links') = 'array'
                     THEN source.nexus_metadata->'nexus_links' ELSE '[]'::jsonb END
            ) AS link(value)
            JOIN topics target ON target.slug = link.value->>'topic_slug'
            WHERE source.slug = $2 AND target.id <> source.id
              AND jsonb_typeof(link.value->'topic_slug') = 'string'
            ON CONFLICT (user_id, topic_slug) DO UPDATE
            SET current_bloom_level = GREATEST(user_topic_progress.current_bloom_level, 2)
            WHERE user_topic_progress.current_bloom_level < 2 AND user_topic_progress.mastery_score = 0
        `, [userId, sourceTopicSlug]);
    }
}

module.exports = new PedagogicalEngine();
