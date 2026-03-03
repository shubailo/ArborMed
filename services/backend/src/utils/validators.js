const crypto = require('crypto');
const AppError = require('./AppError');

const PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$/;
const PASSWORD_ERROR_MSG = 'Password must be at least 8 characters long and include an uppercase letter, a number, and a special character.';

function validatePassword(password, next) {
    if (!PASSWORD_REGEX.test(password)) {
        return next(new AppError(PASSWORD_ERROR_MSG, 400));
    }
    return true;
}

function hashToken(rawToken) {
    return crypto
        .createHash('sha256')
        .update(rawToken)
        .digest('hex');
}

function findMatchingToken(rawToken, storedTokens) {
    const hashedInputBuffer = Buffer.from(hashToken(rawToken), 'hex');

    for (const t of storedTokens) {
        const storedBuffer = Buffer.from(t.token_hash, 'hex');
        if (
            hashedInputBuffer.length === storedBuffer.length &&
            crypto.timingSafeEqual(hashedInputBuffer, storedBuffer)
        ) {
            return t;
        }
    }
    return null;
}

const USER_FIELDS = 'id, email, username, display_name, role, coins, xp, level, streak_count, longest_streak, is_email_verified, daily_coins_earned, daily_coins_softcap_progress, last_coin_reset_date';

function formatUserResponse(user) {
    return {
        id: user.id,
        email: user.email,
        username: user.username,
        display_name: user.display_name,
        role: user.role,
        coins: user.coins,
        xp: user.xp,
        level: user.level,
        streak_count: user.streak_count,
        longest_streak: user.longest_streak,
        is_email_verified: user.is_email_verified,
        daily_coins_earned: user.daily_coins_earned,
        daily_coins_softcap_progress: user.daily_coins_softcap_progress,
        last_coin_reset_date: user.last_coin_reset_date,
    };
}

module.exports = {
    PASSWORD_REGEX,
    PASSWORD_ERROR_MSG,
    validatePassword,
    hashToken,
    findMatchingToken,
    USER_FIELDS,
    formatUserResponse,
};
