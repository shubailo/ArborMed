/**
 * Email Validation Utility
 * Handles format checking and disposable domain blacklisting.
 */

const DISPOSABLE_DOMAINS = [
    'mailinator.com',
    'yopmail.com',
    'guerrillamail.com',
    'temp-mail.org',
    '10minutemail.com',
    'sharklasers.com',
    'getairmail.com',
    'dispostable.com',
    'maildrop.cc'
];

/**
 * Validates email format and checks against blacklist
 * @param {string} email 
 * @returns {{isValid: boolean, message: string}}
 */
function validateEmail(email) {
    if (!email) return { isValid: false, message: 'Email is required' };

    // Standard RFC 5322 regex
    const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;

    if (!emailRegex.test(email)) {
        return { isValid: false, message: 'Invalid email format' };
    }

    const domain = email.split('@')[1].toLowerCase();
    if (DISPOSABLE_DOMAINS.includes(domain)) {
        return { isValid: false, message: 'Disposable email addresses are not allowed' };
    }

    return { isValid: true, message: 'Valid email' };
}

module.exports = { validateEmail };
