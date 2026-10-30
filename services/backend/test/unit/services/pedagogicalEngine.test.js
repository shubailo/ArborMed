const db = require('../../../src/config/db');
const analyticsEngine = require('../../../src/services/analyticsEngine');
const pedagogicalEngine = require('../../../src/services/pedagogicalEngine');

jest.mock('../../../src/config/db', () => ({
    query: jest.fn(),
}));

jest.mock('../../../src/services/analyticsEngine', () => ({
    calculateSM2: jest.fn(),
    calculateRetention: jest.fn(),
    calculateReadiness: jest.fn(),
}));

describe('PedagogicalEngine Unit Tests', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('getChallenge Priority Queue', () => {
        const userId = 1;
        const topicSlug = 'cardiovascular';

        it('Priority 1: should return levelOverride question when provided', async () => {
            const mockQ = { id: 42, bloom_level: 3, text: 'Override challenge' };
            db.query.mockResolvedValueOnce({ rows: [mockQ] });

            const result = await pedagogicalEngine.getChallenge(userId, topicSlug, [], 3);

            expect(result).toEqual({
                ...mockQ,
                is_review: false,
                coverage: 0,
                streak: 0,
                streakProgress: 0,
                selectionReason: 'PREDICTIVE_LEVEL_3',
            });
        });

        it('Priority 2: should return due SRS question when present', async () => {
            const mockReviewQ = { id: 101, text: 'Review Question', bloom_level: 2 };
            db.query
                // 1. Due review query
                .mockResolvedValueOnce({ rows: [mockReviewQ] })
                // 2. ensureUserTopicProgress query
                .mockResolvedValueOnce({ rows: [{ mastery_score: 80, current_streak: 4, level_correct_count: 6 }] });

            const result = await pedagogicalEngine.getChallenge(userId, topicSlug, []);

            expect(result).toEqual({
                ...mockReviewQ,
                is_review: true,
                coverage: 80,
                streak: 4,
                streakProgress: 6 / 20.0,
                selectionReason: 'SRS_REVIEW',
            });
        });

        it('Priority 3: should trigger Diagnostic Fail-Down for failed L3/L4 question with unmastered prerequisites', async () => {
            const mockPrereqQ = { id: 55, bloom_level: 1, text: 'Foundational Concept' };
            db.query
                // 1. Due review query (none)
                .mockResolvedValueOnce({ rows: [] })
                // 2. ensureUserTopicProgress
                .mockResolvedValueOnce({ rows: [{ mastery_score: 50, current_streak: 0, level_correct_count: 3 }] })
                // 3. Last failed response in topic
                .mockResolvedValueOnce({ rows: [{ id: 99, bloom_level: 3, metadata: { prerequisite_ids: [55, 56] } }] })
                // 4. Query for unmastered prerequisites
                .mockResolvedValueOnce({ rows: [mockPrereqQ] });

            const result = await pedagogicalEngine.getChallenge(userId, topicSlug, []);

            expect(result).toEqual({
                ...mockPrereqQ,
                is_review: false,
                coverage: 50,
                streak: 0,
                streakProgress: 3 / 20.0,
                selectionReason: 'FAIL_DOWN_PREREQ_99',
            });
        });

        it('Priority 4: should serve unseen Bloom Climber question at current level', async () => {
            const mockClimberQ = { id: 202, bloom_level: 2, text: 'Mechanism Question' };
            db.query
                // 1. Due review query (none)
                .mockResolvedValueOnce({ rows: [] })
                // 2. ensureUserTopicProgress
                .mockResolvedValueOnce({ rows: [{ current_bloom_level: 2, mastery_score: 30, current_streak: 1, level_correct_count: 2 }] })
                // 3. Last failed response (none)
                .mockResolvedValueOnce({ rows: [] })
                // 4. Query for unseen questions at current level
                .mockResolvedValueOnce({ rows: [mockClimberQ] });

            const result = await pedagogicalEngine.getChallenge(userId, topicSlug, []);

            expect(result).toEqual({
                ...mockClimberQ,
                is_review: false,
                coverage: 30,
                streak: 1,
                streakProgress: 2 / 20.0,
                selectionReason: 'BLOOM_CLIMBER_LEVEL_2',
            });
        });
    });

    describe('resolveResponse', () => {
        const userId = 1;
        const topicSlug = 'pharmacology';
        const questionId = 77;

        it('should increment progress and promote student to next Bloom level at threshold', async () => {
            analyticsEngine.calculateSM2.mockReturnValue({
                interval: 6,
                easinessFactor: 2.6,
                repetitions: 3,
            });

            db.query
                // 1. _updateSRS: select user_question_progress
                .mockResolvedValueOnce({ rows: [{ easiness_factor: 2.5, interval_days: 1, repetition_count: 2 }] })
                // 2. _updateSRS: upsert user_question_progress
                .mockResolvedValueOnce({ rowCount: 1 })
                // 3. _ensureUserTopicProgress: select user_topic_progress (19 points, current level 1)
                .mockResolvedValueOnce({ rows: [{ current_bloom_level: 1, current_streak: 19, level_correct_count: 19 }] })
                // 4. stats query for weighted mastery
                .mockResolvedValueOnce({ rows: [{ m_l12: 5, m_l34: 0, t_l12: 10, t_l34: 5 }] })
                // 5. update user_topic_progress
                .mockResolvedValueOnce({ rowCount: 1 });

            const result = await pedagogicalEngine.resolveResponse(userId, topicSlug, questionId, true, 5, 2500);

            expect(result.newLevel).toBe(2);
            expect(result.promotedTo).toBe(2);
            expect(result.event).toBe('PROMOTION');
            expect(result.level_correct_count).toBe(0);
            expect(result.streakProgress).toBe(0);
        });

        it('should apply humane soft-decrement (-2, not 0) on incorrect answer', async () => {
            analyticsEngine.calculateSM2.mockReturnValue({
                interval: 1,
                easinessFactor: 2.3,
                repetitions: 0,
            });

            db.query
                // 1. _updateSRS: select user_question_progress
                .mockResolvedValueOnce({ rows: [{ easiness_factor: 2.5, interval_days: 6, repetition_count: 2 }] })
                // 2. _updateSRS: upsert user_question_progress
                .mockResolvedValueOnce({ rowCount: 1 })
                // 3. _ensureUserTopicProgress: select user_topic_progress (had 10 points)
                .mockResolvedValueOnce({ rows: [{ current_bloom_level: 2, current_streak: 10, level_correct_count: 10 }] })
                // 4. stats query for weighted mastery
                .mockResolvedValueOnce({ rows: [{ m_l12: 4, m_l34: 1, t_l12: 10, t_l34: 5 }] })
                // 5. update user_topic_progress
                .mockResolvedValueOnce({ rowCount: 1 });

            const result = await pedagogicalEngine.resolveResponse(userId, topicSlug, questionId, false, null, 18000);

            // Level should remain 2 (no promotion, no demotion on single wrong answer)
            expect(result.currentBloomLevel).toBe(2);
            expect(result.newLevel).toBeNull();
            expect(result.levelDirection).toBe('NONE');
            expect(result.promotedTo).toBeNull();
            expect(result.demotedTo).toBeNull();
            expect(result.event).toBeNull();
            // 10 - 2 = 8 (humane soft-decrement)
            expect(result.level_correct_count).toBe(8);
            expect(result.streakProgress).toBeCloseTo(8 / 20.0);
        });

        it('should demote student to previous Bloom level after 3 consecutive wrong answers', async () => {
            analyticsEngine.calculateSM2.mockReturnValue({
                interval: 1,
                easinessFactor: 2.1,
                repetitions: 0,
            });

            db.query
                // 1. _updateSRS: select user_question_progress
                .mockResolvedValueOnce({ rows: [{ easiness_factor: 2.3, interval_days: 1, repetition_count: 1 }] })
                // 2. _updateSRS: upsert user_question_progress
                .mockResolvedValueOnce({ rowCount: 1 })
                // 3. _ensureUserTopicProgress: select user_topic_progress (level 2, already 2 consecutive wrong)
                .mockResolvedValueOnce({ rows: [{ current_bloom_level: 2, current_streak: 0, level_correct_count: 2, consecutive_wrong: 2 }] })
                // 4. stats query
                .mockResolvedValueOnce({ rows: [{ m_l12: 2, m_l34: 0, t_l12: 10, t_l34: 5 }] })
                // 5. update user_topic_progress
                .mockResolvedValueOnce({ rowCount: 1 });

            const result = await pedagogicalEngine.resolveResponse(userId, topicSlug, questionId, false, null, 15000);

            expect(result.currentBloomLevel).toBe(1);
            expect(result.newLevel).toBe(1);
            expect(result.demotedTo).toBe(1);
            expect(result.levelDirection).toBe('DOWN');
            expect(result.event).toBe('DEMOTION');
            expect(result.level_correct_count).toBe(0);
        });
    });
});
