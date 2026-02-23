const { validateEmail } = require('../../../src/utils/emailValidator');

describe('emailValidator', () => {
  describe('validateEmail', () => {
    it('should return error if email is missing', () => {
      const result = validateEmail(undefined);
      expect(result).toEqual({ isValid: false, message: 'Email is required' });
    });

    it('should return error if email is empty string', () => {
      const result = validateEmail('');
      expect(result).toEqual({ isValid: false, message: 'Email is required' });
    });

    it('should return error if email format is invalid (missing @)', () => {
      const result = validateEmail('invalidemail.com');
      expect(result).toEqual({
        isValid: false,
        message: 'Invalid email format',
      });
    });

    it('should return error if email format is invalid (missing domain)', () => {
      const result = validateEmail('user@');
      expect(result).toEqual({
        isValid: false,
        message: 'Invalid email format',
      });
    });

    it('should return error if email is from a disposable domain', () => {
      const disposableDomains = [
        'mailinator.com',
        'yopmail.com',
        'guerrillamail.com',
        'temp-mail.org',
        '10minutemail.com',
        'sharklasers.com',
        'getairmail.com',
        'dispostable.com',
        'maildrop.cc',
      ];

      disposableDomains.forEach((domain) => {
        const result = validateEmail(`user@${domain}`);
        expect(result).toEqual({
          isValid: false,
          message: 'Disposable email addresses are not allowed',
        });
      });
    });

    it('should return valid for a standard valid email', () => {
      const result = validateEmail('user@example.com');
      expect(result).toEqual({ isValid: true, message: 'Valid email' });
    });

    it('should return valid for an email with subdomains', () => {
      const result = validateEmail('user@sub.example.com');
      expect(result).toEqual({ isValid: true, message: 'Valid email' });
    });

    it('should return valid for an email with special characters in local part', () => {
      const result = validateEmail('user.name+tag@example.com');
      expect(result).toEqual({ isValid: true, message: 'Valid email' });
    });

    // Edge case: Case insensitivity for domain check
    it('should be case insensitive for disposable domain check', () => {
      const result = validateEmail('user@MAILINATOR.COM');
      expect(result).toEqual({
        isValid: false,
        message: 'Disposable email addresses are not allowed',
      });
    });
  });
});
