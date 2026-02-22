const analyticsEngine = require('../src/services/analyticsEngine');

describe('Analytics Engine (SM-2)', () => {
    describe('calculateSM2', () => {
        // Standard SM-2 logic tests

        it('should return interval 1 and default EF for first repetition (good quality)', () => {
            // quality, previousEF, previousInterval, previousRepetitions
            const result = analyticsEngine.calculateSM2(4, 2.5, 0, 0);
            expect(result.interval).toBe(1);
            expect(result.repetitions).toBe(1);
            // EF shouldn't change much for 4, but let's check formula
            // EF' = EF + (0.1 - (5-q)*(0.08+(5-q)*0.02))
            // q=4: 5-4=1. 0.08+0.02=0.1. 1*0.1=0.1. 0.1-0.1=0. EF'=EF.
            expect(result.easinessFactor).toBe(2.5);
        });

        it('should return interval 6 for second repetition (good quality)', () => {
            const result = analyticsEngine.calculateSM2(4, 2.5, 1, 1);
            expect(result.interval).toBe(6);
            expect(result.repetitions).toBe(2);
        });

        it('should increase interval for third repetition based on EF', () => {
            const result = analyticsEngine.calculateSM2(4, 2.5, 6, 2);
            // 6 * 2.5 = 15
            expect(result.interval).toBe(15);
            expect(result.repetitions).toBe(3);
        });

        it('should reset repetitions and interval and decrease EF if quality < 3', () => {
            const result = analyticsEngine.calculateSM2(2, 2.5, 10, 3);
            expect(result.interval).toBe(1);
            expect(result.repetitions).toBe(0);
            expect(result.easinessFactor).toBeCloseTo(2.4);
        });

        it('should increase EF for quality 5', () => {
            // q=5: 5-5=0. 0.1 - 0 = 0.1. EF' = EF + 0.1.
            const result = analyticsEngine.calculateSM2(5, 2.5, 10, 3);
            expect(result.easinessFactor).toBeCloseTo(2.6);
        });

        it('should decrease EF for quality 3', () => {
            // q=3: 5-3=2. 0.08 + 2*0.02 = 0.12. 2*0.12 = 0.24. 0.1 - 0.24 = -0.14. EF' = EF - 0.14.
            const result = analyticsEngine.calculateSM2(3, 2.5, 10, 3);
            expect(result.easinessFactor).toBeCloseTo(2.36);
        });

        it('should clamp EF at 1.3 minimum', () => {
            const result = analyticsEngine.calculateSM2(3, 1.3, 10, 3);
            expect(result.easinessFactor).toBe(1.3);
        });
    });
});
