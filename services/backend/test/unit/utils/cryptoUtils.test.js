const { generateSecureOTP } = require('../../../src/utils/cryptoUtils');

describe('cryptoUtils', () => {
    describe('generateSecureOTP', () => {
        test('should return a string of the correct length', () => {
            expect(generateSecureOTP(6)).toHaveLength(6);
            expect(generateSecureOTP(4)).toHaveLength(4);
            expect(generateSecureOTP(10)).toHaveLength(10);
        });

        test('should only contain digits', () => {
            const otp = generateSecureOTP(100);
            expect(otp).toMatch(/^\d+$/);
        });

        test('should return different values on subsequent calls', () => {
            const otp1 = generateSecureOTP(6);
            const otp2 = generateSecureOTP(6);
            expect(otp1).not.toBe(otp2);
        });

        test('should throw error for non-positive length', () => {
            expect(() => generateSecureOTP(0)).toThrow('Length must be positive');
            expect(() => generateSecureOTP(-1)).toThrow('Length must be positive');
        });

        test('should handle long lengths (up to 14)', () => {
            // 10^14 is less than crypto.randomInt max limit (2^48 - 1)
            expect(generateSecureOTP(14)).toHaveLength(14);
            expect(generateSecureOTP(14)).toMatch(/^\d+$/);
        });

        test('should handle lengths exceeding the optimized path', () => {
            expect(generateSecureOTP(16)).toHaveLength(16);
            expect(generateSecureOTP(16)).toMatch(/^\d+$/);
        });
    });
});
