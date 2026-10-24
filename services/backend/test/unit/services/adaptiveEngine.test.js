const db = require('../../../src/config/db');
const analyticsEngine = require('../../../src/services/analyticsEngine');
const AdaptiveEngine = require('../../../src/services/adaptiveEngine');

jest.mock('../../../src/config/db', () => ({
    query: jest.fn(),
}));

jest.mock('../../../src/services/analyticsEngine', () => ({
    calculateSM2: jest.fn(),
}));

describe('AdaptiveEngine Unit Tests', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('getNextQuestion', () => {
        const userId = 1;
        const topicSlug = 'cardiovascular';

        it('should fetch question of overridden level when levelOverride is provided', async () => {
            const levelOverride = 3;
            const mockQuestion = { id: 42, bloom_level: 3, text: 'Prerequisites check' };
            db.query.mockResolvedValueOnce({ rows: [mockQuestion] });

            const result = await AdaptiveEngine.getNextQuestion(userId, topicSlug, [], levelOverride);

            expect(db.query).toHaveBeenCalledTimes(1);
            expect(db.query.mock.calls[0][1]).toEqual([topicSlug, levelOverride, userId, null]);
            expect(result).toEqual({
                ...mockQuestion,
                is_review: false,
                coverage: 0,
                streak: 0,
                streakProgress: 0,
                selectionReason: 'PREDICTIVE_LEVEL_3',
            });
        });

        it('should query SRS reviews first and return the due review question if present', async () => {
            const mockReviewQuestion = { id: 101, text: 'Review Question' };
            db.query
                // First call: SRS review questions query
                .mockResolvedValueOnce({ rows: [mockReviewQuestion] })
                // Second call: User topic progress query (mastery, streak, etc)
                .mockResolvedValueOnce({ rows: [{ mastery_score: 85, current_streak: 5, progress_counter: 10 }] });

            const result = await AdaptiveEngine.getNextQuestion(userId, topicSlug, []);

            expect(db.query).toHaveBeenCalledTimes(2);
            expect(result).toEqual({
                ...mockReviewQuestion,
                is_review: true,
                coverage: 85,
                streak: 5,
                streakProgress: 0.5,
                selectionReason: 'SRS_REVIEW',
            });
        });

        it('should query new content (Bloom Climber) if no reviews are due', async () => {
            const mockClimberQuestion = { id: 202, bloom_level: 1, text: 'Climber Question' };
            db.query
                // 1. SRS review query returns empty
                .mockResolvedValueOnce({ rows: [] })
                // 2. Fetch/Insert User topic progress
                .mockResolvedValueOnce({ rows: [{ current_bloom_level: 2 }] })
                // 3. Last response query (empty/no diagnostics required)
                .mockResolvedValueOnce({ rows: [] })
                // 4. Fetch Climber Question query
                .mockResolvedValueOnce({ rows: [mockClimberQuestion] })
                // 5. Fetch updated stats query
                .mockResolvedValueOnce({ rows: [{ mastery_score: 40, current_streak: 2, progress_counter: 4 }] });

            const result = await AdaptiveEngine.getNextQuestion(userId, topicSlug, []);

            expect(result).toEqual({
                ...mockClimberQuestion,
                is_review: false,
                coverage: 40,
                streak: 2,
                streakProgress: 0.2,
                selectionReason: 'BLOOM_CLIMBER_LEVEL_2',
            });
        });
    });

    describe('processAnswerResult', () => {
        const userId = 1;
        const topicSlug = 'respiratory';
        const questionId = 12;

        it('should calculate new SM-2 interval and update user progress on correct answer', async () => {
            // Mock SRS update query returns (read current EF)
            db.query
                // 1. select from user_question_progress
                .mockResolvedValueOnce({ rows: [{ easiness_factor: 2.5, interval_days: 2, repetition_count: 1 }] })
                // 2. insert/update user_question_progress
                .mockResolvedValueOnce({ rowCount: 1 })
                // 3. select from user_topic_progress
                .mockResolvedValueOnce({ rows: [{ current_bloom_level: 2, current_streak: 5, level_correct_count: 10, total_answered: 3, predictive_mastery_boost: null }] })
                // 4. select stats for mastery calculation
                .mockResolvedValueOnce({ rows: [{ m_l12: 2, m_l34: 1, t_l12: 2, t_l34: 2 }] })
                // 5. update user_topic_progress
                .mockResolvedValueOnce({ rowCount: 1 });

            analyticsEngine.calculateSM2.mockReturnValue({
                easinessFactor: 2.6,
                interval: 6,
                repetitions: 2,
            });

            const result = await AdaptiveEngine.processAnswerResult(userId, topicSlug, true, questionId, 2);

            expect(analyticsEngine.calculateSM2).toHaveBeenCalledWith(4, 2.5, 2, 1);
            expect(result).toEqual({
                newLevel: 2,
                promotedTo: null,
                mastery_score: 67, // (2*1 + 1*2) / (2*1 + 2*2) = 4 / 6 = 67%
                sm2: { easinessFactor: 2.6, interval: 6, repetitions: 2 },
                level_correct_count: 11, // incremented by 1
                streakProgress: 0.55,
            });
        });

        it('should promote user to next Bloom level on reaching correct count threshold', async () => {
            db.query
                // 1. select from user_question_progress
                .mockResolvedValueOnce({ rows: [] })
                // 2. insert/update user_question_progress
                .mockResolvedValueOnce({ rowCount: 1 })
                // 3. select from user_topic_progress (19 correct answers, Bloom level 2)
                .mockResolvedValueOnce({ rows: [{ current_bloom_level: 2, current_streak: 19, level_correct_count: 19, total_answered: 20, predictive_mastery_boost: null }] })
                // 4. select stats
                .mockResolvedValueOnce({ rows: [{ m_l12: 10, m_l34: 0, t_l12: 10, t_l34: 0 }] })
                // 5. update user_topic_progress
                .mockResolvedValueOnce({ rowCount: 1 });

            analyticsEngine.calculateSM2.mockReturnValue({
                easinessFactor: 2.5,
                interval: 1,
                repetitions: 1,
            });

            const result = await AdaptiveEngine.processAnswerResult(userId, topicSlug, true, questionId, 2);

            expect(result.newLevel).toBe(3); // Promoted from 2 to 3
            expect(result.promotedTo).toBe(3);
            expect(result.level_correct_count).toBe(0); // reset correct count to 0
        });
    });
});
