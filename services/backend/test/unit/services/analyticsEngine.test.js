const AnalyticsEngine = require('../../../src/services/analyticsEngine');

describe('AnalyticsEngine', () => {
    describe('calculateSM2', () => {
        it('should return interval 1 for first correct repetition', () => {
            const result = AnalyticsEngine.calculateSM2(4, 2.5, 0, 0);
            expect(result.interval).toBe(1);
            expect(result.repetitions).toBe(1);
        });

        it('should return interval 6 for second correct repetition', () => {
            const result = AnalyticsEngine.calculateSM2(4, 2.5, 1, 1);
            expect(result.interval).toBe(6);
            expect(result.repetitions).toBe(2);
        });

        it('should calculate interval using previous EF for subsequent correct repetitions', () => {
            const previousInterval = 6;
            const previousEF = 2.5;
            const result = AnalyticsEngine.calculateSM2(4, previousEF, previousInterval, 2);
            expect(result.interval).toBe(Math.round(previousInterval * previousEF)); // 15
            expect(result.repetitions).toBe(3);
        });

        it('should update EF correctly based on quality', () => {
             // quality 5: EF' = EF + (0.1 - (0) * (...)) = EF + 0.1
             const result = AnalyticsEngine.calculateSM2(5, 2.5, 6, 2);
             expect(result.easinessFactor).toBeCloseTo(2.6);
        });

        it('should decrease EF for lower quality correct answers', () => {
            // quality 3: EF' = EF + (0.1 - (2)*(0.08 + 0.04)) = EF + (0.1 - 0.24) = EF - 0.14
            const result = AnalyticsEngine.calculateSM2(3, 2.5, 6, 2);
            expect(result.easinessFactor).toBeCloseTo(2.36);
        });

        it('should reset repetitions and interval on incorrect answer (quality < 3)', () => {
            const result = AnalyticsEngine.calculateSM2(2, 2.5, 6, 2);
            expect(result.interval).toBe(1);
            expect(result.repetitions).toBe(0);
        });

        it('should ensure EF never drops below 1.3', () => {
            // Start with EF near limit
            const result = AnalyticsEngine.calculateSM2(3, 1.35, 6, 2);
            // new EF would be 1.35 - 0.14 = 1.21, so it should be clamped to 1.3
            expect(result.easinessFactor).toBe(1.3);
        });
    });

    describe('calculateRetentionModifier', () => {
        it('should return 1.0 if there are fewer than 10 results', () => {
            const result = AnalyticsEngine.calculateRetentionModifier([true, false]);
            expect(result).toBe(1.0);
        });

        it('should return 0.85 if retention is below 0.85', () => {
            // 8/10 = 0.8 < 0.85
            const results = new Array(10).fill(true).map((_, i) => i < 8);
            const result = AnalyticsEngine.calculateRetentionModifier(results);
            expect(result).toBe(0.85);
        });

        it('should return 1.15 if retention is above 0.90', () => {
            // 10/10 = 1.0 > 0.90
            const results = new Array(10).fill(true);
            const result = AnalyticsEngine.calculateRetentionModifier(results);
            expect(result).toBe(1.15);
        });

        it('should return 1.0 if retention is between 0.85 and 0.90 (inclusive range check)', () => {
            // 9/10 = 0.90
            const results = new Array(10).fill(true).map((_, i) => i < 9);
            const result = AnalyticsEngine.calculateRetentionModifier(results);
            expect(result).toBe(1.0);
        });
    });

    describe('calculateNewStability', () => {
        it('should increase stability on correct answer based on bloom level', () => {
            // bloom level 1: weight = 0.25
            // s = 1.0 * (1 + 2 * 0.25) = 1.5
            const result = AnalyticsEngine.calculateNewStability(1.0, 1, true);
            expect(result).toBe(1.5);
        });

        it('should increase stability significantly for higher bloom levels', () => {
            // bloom level 4: weight = 1.0
            // s = 2.0 * (1 + 2 * 1.0) = 6.0
            const result = AnalyticsEngine.calculateNewStability(2.0, 4, true);
            expect(result).toBe(6.0);
        });

        it('should decrease stability on incorrect answer', () => {
            // s = 2.0 * 0.4 = 0.8
            const result = AnalyticsEngine.calculateNewStability(2.0, 2, false);
            expect(result).toBeCloseTo(0.8);
        });

        it('should default current stability to 1.0 if not provided', () => {
            // bloom level 2: weight = 0.5
            // s = 1.0 * (1 + 2 * 0.5) = 2.0
            const result = AnalyticsEngine.calculateNewStability(undefined, 2, true);
            expect(result).toBe(2.0);
        });
    });
});
