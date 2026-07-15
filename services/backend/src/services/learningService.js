const db = require('../config/db');

/**
 * LearningService: Core Orchestrator for Pedagogical Logic
 * Implementation: FSRS-lite (Free Spaced Repetition Scheduler) + Bloom Taxomony Climber
 */
class LearningService {
    constructor() {
        // FSRS Constants
        this.INITIAL_STABILITY = 2.0;
        this.STABILITY_DECAY = 0.9;
        this.MASTERY_THRESHOLD = 0.85;
        this.BLOOM_UPGRADE_COUNT = 20; // Correct answers needed for Bloom promotion
        this.NEXUS_THRESHOLD = 80;    // Mastery score for cross-topic boost
    }

    /**
     * Calculates retention percentage based on stability and time elapsed.
     * Formula: R = e^(-t/S)
     */
    calculateRetention(daysElapsed, stability) {
        const s = stability || 1.0;
        const retention = Math.exp(-daysElapsed / s);
        return Math.round(retention * 100);
    }

    /**
     * Calculates Exam Readiness Score.
     * Weights: 60% Mastery (Long-term) + 40% Retention (Short-term).
     */
    calculateReadiness(masteryScore, retention) {
        const readiness = (masteryScore * 0.6) + (retention * 0.4);
        return Math.round(Math.min(100, readiness));
    }

    /**
     * Fetches the next challenge for the user.
     * Logic Priority:
     * 1. Due Reviews (SRS)
     * 2. Diagnostic Fail-Down (Prerequisites)
     * 3. Bloom Climber (Next level)
     */
    async getChallenge(userId, topicSlug, excludedIds = []) {
        const excludeParam = excludedIds.length > 0 ? excludedIds : null;

        // 1. Spaced Repetition Priority
        const dueReview = await db.query(`
            SELECT q.*, uqp.interval_days as stability, uqp.easiness_factor as difficulty
            FROM questions q
            JOIN user_question_progress uqp ON q.id = uqp.question_id
            WHERE uqp.user_id = $1 
            AND uqp.next_review_at <= NOW()
            AND q.active = TRUE
            AND q.topic_id IN (SELECT id FROM topics WHERE slug = $2 OR parent_id = (SELECT id FROM topics WHERE slug = $2))
            AND ($3::int[] IS NULL OR q.id != ALL($3::int[]))
            ORDER BY uqp.next_review_at ASC LIMIT 1
        `, [userId, topicSlug, excludeParam]);

        if (dueReview.rows.length > 0) {
            return { ...dueReview.rows[0], selectionReason: 'SRS_REVIEW' };
        }

        // 2. Intelligence Layer: Diagnostic Fail-Down
        const lastResponse = await db.query(`
            SELECT q.id, q.metadata, r.is_correct 
            FROM responses r
            JOIN questions q ON r.question_id = q.id
            JOIN quiz_sessions qs ON r.session_id = qs.id
            WHERE qs.user_id = $1 AND r.is_correct = FALSE
            ORDER BY r.created_at DESC LIMIT 1
        `, [userId]);

        if (lastResponse.rows.length > 0) {
            const prereqs = lastResponse.rows[0].metadata?.prerequisite_ids || [];
            if (prereqs.length > 0) {
                const prereqQuestion = await db.query(`
                    SELECT q.* FROM questions q
                    WHERE q.id = ANY($1)
                    AND NOT EXISTS (SELECT 1 FROM user_question_progress uqp WHERE uqp.question_id = q.id AND user_id = $2 AND mastered = TRUE)
                    ORDER BY RANDOM() LIMIT 1
                `, [prereqs, userId]);

                if (prereqQuestion.rows.length > 0) {
                    return { ...prereqQuestion.rows[0], selectionReason: `FAIL_DOWN_PREREQ_${lastResponse.rows[0].id}` };
                }
            }
        }

        // 3. Standard Progression: Bloom Climber
        const userProgress = await this._ensureUserTopicProgress(userId, topicSlug);
        
        const nextQuestion = await db.query(`
            SELECT q.* FROM questions q
            WHERE q.bloom_level = $1
            AND q.active = TRUE
            AND q.topic_id IN (SELECT id FROM topics WHERE slug = $2 OR parent_id = (SELECT id FROM topics WHERE slug = $2))
            AND NOT EXISTS (SELECT 1 FROM user_question_progress uqp WHERE uqp.question_id = q.id AND uqp.user_id = $3)
            AND ($4::int[] IS NULL OR q.id != ALL($4::int[]))
            ORDER BY RANDOM() LIMIT 1
        `, [userProgress.current_bloom_level, topicSlug, userId, excludeParam]);

        if (nextQuestion.rows.length > 0) {
            return {
                ...nextQuestion.rows[0],
                selectionReason: `BLOOM_CLIMBER_L${userProgress.current_bloom_level}`
            };
        }

        // 4. Fallback: If no NEW questions at this level, allow repeated questions 
        // (excluding those currently in the session to avoid immediate repeats)
        const fallbackQuestion = await db.query(`
            SELECT q.* FROM questions q
            WHERE q.bloom_level = $1
            AND q.active = TRUE
            AND q.topic_id IN (SELECT id FROM topics WHERE slug = $2 OR parent_id = (SELECT id FROM topics WHERE slug = $2))
            AND ($3::int[] IS NULL OR q.id != ALL($3::int[]))
            ORDER BY RANDOM() LIMIT 1
        `, [userProgress.current_bloom_level, topicSlug, excludeParam]);

        if (fallbackQuestion.rows.length > 0) {
            return {
                ...fallbackQuestion.rows[0],
                selectionReason: `BLOOM_REPLAY_L${userProgress.current_bloom_level}`
            };
        }

        return null;
    }

    /**
     * Updates the persistence layer after a user answers a question.
     * Calculates FSRS stability and Bloom promotions.
     */
    async resolveResponse(userId, topicSlug, questionId, isCorrect, quality = null) {
        if (quality === null) quality = isCorrect ? 4 : 1;

        // 1. Update Spaced Repetition (FSRS-lite)
        const srsUpdate = await this._updateSRS(userId, questionId, isCorrect, quality);

        // 2. Update Topic Mastery & Bloom Level
        const progress = await this._ensureUserTopicProgress(userId, topicSlug);
        let { current_bloom_level, level_correct_count, mastery_score: _mastery_score } = progress;

        if (isCorrect) {
            level_correct_count++;
            if (level_correct_count >= this.BLOOM_UPGRADE_COUNT && current_bloom_level < 4) {
                current_bloom_level++;
                level_correct_count = 0;
            }
        } else {
            level_correct_count = 0; // Fail-Down logic handles the penalty via getChallenge
        }

        // Recalculate Weighted Mastery
        const stats = await db.query(`
            SELECT 
                COUNT(*) FILTER (WHERE q.bloom_level <= 2 AND uqp.mastered = TRUE) as m_easy,
                COUNT(*) FILTER (WHERE q.bloom_level > 2 AND uqp.mastered = TRUE) as m_hard,
                COUNT(*) FILTER (WHERE q.bloom_level <= 2) as t_easy,
                COUNT(*) FILTER (WHERE q.bloom_level > 2) as t_hard
            FROM questions q
            INNER JOIN topics t ON q.topic_id = t.id
            LEFT JOIN user_question_progress uqp ON q.id = uqp.question_id AND uqp.user_id = $1
            WHERE (t.slug = $2 OR t.parent_id = (SELECT id FROM topics WHERE slug = $2))
        `, [userId, topicSlug]);

        const { m_easy, m_hard, t_easy, t_hard } = stats.rows[0];
        const denominator = (parseInt(t_easy || 0) * 1.0) + (parseInt(t_hard || 0) * 2.5);
        const newMastery = denominator > 0 
            ? Math.min(100, Math.round(((parseInt(m_easy || 0) * 1.0) + (parseInt(m_hard || 0) * 2.5)) / denominator * 100))
            : 0;

        await db.query(`
            UPDATE user_topic_progress 
            SET current_bloom_level = $1, level_correct_count = $2, mastery_score = $3, last_studied_at = NOW()
            WHERE user_id = $4 AND topic_slug = $5
        `, [current_bloom_level, level_correct_count, newMastery, userId, topicSlug]);

        return { current_bloom_level, mastery_score: newMastery, srs: srsUpdate };
    }

    /**
     * Private Helper: FSRS-lite Update
     */
    async _updateSRS(userId, questionId, isCorrect, quality) {
        const current = await db.query(`
            SELECT interval_days as stability, easiness_factor as difficulty, repetition_count 
            FROM user_question_progress 
            WHERE user_id = $1 AND question_id = $2
        `, [userId, questionId]);

        let { stability, difficulty, repetition_count } = current.rows[0] || 
            { stability: this.INITIAL_STABILITY, difficulty: 3.0, repetition_count: 0 };

        if (isCorrect) {
            stability = stability * (1 + (quality * this.STABILITY_DECAY));
            repetition_count++;
        } else {
            stability = this.INITIAL_STABILITY / 2; // Immediate decay on failure
            difficulty = Math.min(5.0, difficulty + 0.5);
            repetition_count = 0;
        }

        const interval = Math.ceil(stability);
        const nextReview = `NOW() + INTERVAL '${interval} days'`;

        await db.query(`
            INSERT INTO user_question_progress (user_id, question_id, interval_days, easiness_factor, repetition_count, next_review_at, mastered)
            VALUES ($1, $2, $3, $4, $5, ${nextReview}, $6)
            ON CONFLICT (user_id, question_id) DO UPDATE SET
                interval_days = EXCLUDED.interval_days,
                easiness_factor = EXCLUDED.easiness_factor,
                repetition_count = EXCLUDED.repetition_count,
                next_review_at = EXCLUDED.next_review_at,
                mastered = EXCLUDED.mastered
        `, [userId, questionId, interval, difficulty, repetition_count, repetition_count >= 3]);

        return { interval, stability };
    }

    async _ensureUserTopicProgress(userId, topicSlug) {
        const res = await db.query(`
            SELECT * FROM user_topic_progress WHERE user_id = $1 AND topic_slug = $2
        `, [userId, topicSlug]);

        if (res.rows.length === 0) {
            // Nexus Boost skipped due to missing nexus_metadata column in topics table
            const baselineLevel = 1;

            const newProgress = await db.query(`
                INSERT INTO user_topic_progress (user_id, topic_slug, current_bloom_level, level_correct_count)
                VALUES ($1, $2, $3, 0)
                RETURNING *
            `, [userId, topicSlug, baselineLevel]);
            return newProgress.rows[0];
        }
        return res.rows[0];
    }
}

module.exports = new LearningService();
