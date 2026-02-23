const { PASSWORD_REGEX, validatePassword, hashToken, findMatchingToken, formatUserResponse } = require('../../src/utils/validators');
const AppError = require('../../src/utils/AppError');

describe('validators', () => {
    describe('PASSWORD_REGEX', () => {
        const validPasswords = ['Hello1!abc', 'StrongP@ss1', 'Test1234!', 'Ab1$xxxx'];
        const invalidPasswords = ['short1!', 'nouppercase1!', 'NOLOWERCASE1!', 'NoDigit!abc', 'NoSpecial1abc', ''];

        test.each(validPasswords)('accepts valid password: %s', (pw) => {
            expect(PASSWORD_REGEX.test(pw)).toBe(true);
        });

        test.each(invalidPasswords)('rejects invalid password: %s', (pw) => {
            expect(PASSWORD_REGEX.test(pw)).toBe(false);
        });
    });

    describe('validatePassword', () => {
        test('returns true for valid password', () => {
            const next = jest.fn();
            expect(validatePassword('Hello1!abc', next)).toBe(true);
            expect(next).not.toHaveBeenCalled();
        });

        test('calls next with AppError for invalid password', () => {
            const next = jest.fn();
            validatePassword('weak', next);
            expect(next).toHaveBeenCalledWith(expect.any(AppError));
            expect(next.mock.calls[0][0].statusCode).toBe(400);
        });
    });

    describe('hashToken', () => {
        test('returns consistent SHA-256 hash', () => {
            const hash1 = hashToken('test-token');
            const hash2 = hashToken('test-token');
            expect(hash1).toBe(hash2);
            expect(hash1).toHaveLength(64); // SHA-256 hex = 64 chars
        });

        test('different tokens produce different hashes', () => {
            expect(hashToken('token-a')).not.toBe(hashToken('token-b'));
        });
    });

    describe('findMatchingToken', () => {
        test('finds matching token from stored list', () => {
            const rawToken = 'my-secret-refresh-token';
            const storedHash = hashToken(rawToken);
            const storedTokens = [
                { id: 1, token_hash: 'aabbccdd' + '0'.repeat(56) },
                { id: 2, token_hash: storedHash },
                { id: 3, token_hash: 'eeff0011' + '0'.repeat(56) },
            ];

            const result = findMatchingToken(rawToken, storedTokens);
            expect(result).toEqual(storedTokens[1]);
        });

        test('returns null when no match found', () => {
            const storedTokens = [
                { id: 1, token_hash: 'a'.repeat(64) },
            ];
            expect(findMatchingToken('wrong-token', storedTokens)).toBeNull();
        });

        test('returns null for empty array', () => {
            expect(findMatchingToken('any-token', [])).toBeNull();
        });
    });

    describe('formatUserResponse', () => {
        test('picks only the expected fields', () => {
            const user = {
                id: 1, email: 'test@test.com', username: 'tester', display_name: 'Test User',
                role: 'student', coins: 100, xp: 500, level: 3, streak_count: 5,
                longest_streak: 10, is_email_verified: true,
                password_hash: 'SHOULD_NOT_APPEAR', created_at: '2024-01-01',
            };

            const result = formatUserResponse(user);

            // Should include these fields
            expect(result).toEqual({
                id: 1, email: 'test@test.com', username: 'tester', display_name: 'Test User',
                role: 'student', coins: 100, xp: 500, level: 3, streak_count: 5,
                longest_streak: 10, is_email_verified: true,
            });

            // Should NOT include sensitive/extra fields
            expect(result).not.toHaveProperty('password_hash');
            expect(result).not.toHaveProperty('created_at');
        });
    });
});
