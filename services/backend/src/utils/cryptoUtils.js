const crypto = require('crypto');

/**
 * Generates a cryptographically secure numeric OTP of the specified length.
 * Uses crypto.randomInt for cryptographically strong pseudo-random data.
 *
 * @param {number} length - The length of the OTP (default 6).
 * @returns {string} - The numeric OTP string.
 */
function generateSecureOTP(length = 6) {
    if (length <= 0) throw new Error('Length must be positive');

    let otp = '';
    // Generate each digit independently to ensure uniform distribution
    // and strictly numeric output (0-9)
    for (let i = 0; i < length; i++) {
        otp += crypto.randomInt(0, 10).toString();
    }
    return otp;
}

module.exports = { generateSecureOTP };
