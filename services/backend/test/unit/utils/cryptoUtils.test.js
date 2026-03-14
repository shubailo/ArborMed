const { generateSecureOTP } = require('../../../src/utils/cryptoUtils');

describe('cryptoUtils', () => {
  describe('generateSecureOTP', () => {
    it('should generate a 6-digit OTP by default', () => {
      const otp = generateSecureOTP();
      expect(otp).toHaveLength(6);
      expect(otp).toMatch(/^\d{6}$/);
    });

    it('should generate an OTP of the specified length', () => {
      const length = 10;
      const otp = generateSecureOTP(length);
      expect(otp).toHaveLength(length);
      expect(otp).toMatch(/^\d{10}$/);
    });

    it('should only contain digits', () => {
      const otp = generateSecureOTP(100);
      expect(otp).toMatch(/^[0-9]+$/);
    });

    it('should throw an error if length is 0', () => {
      expect(() => generateSecureOTP(0)).toThrow('Length must be positive');
    });

    it('should throw an error if length is negative', () => {
      expect(() => generateSecureOTP(-5)).toThrow('Length must be positive');
    });

    it('should generate different OTPs on subsequent calls', () => {
      const otp1 = generateSecureOTP(10);
      const otp2 = generateSecureOTP(10);
      expect(otp1).not.toBe(otp2);
    });
  });
});
