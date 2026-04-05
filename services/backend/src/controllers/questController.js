const { withTransaction } = require('../utils/dbHelpers');
const economyService = require('../services/economyService');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');

exports.claimQuest = catchAsync(async (req, res, next) => {
    const { questId, rewardTokens } = req.body;
    const userId = req.user.id;

    if (!questId || rewardTokens === undefined) {
        return next(new AppError('Missing questId or rewardTokens', 400));
    }

    // 🛡️ Sentinel: Validate client-provided rewardTokens to prevent Mass Assignment and IDOR vulnerabilities
    // Ensure rewardTokens is a number and strictly cap the maximum allowed tokens per quest to prevent infinite money exploit
    const parsedTokens = parseInt(rewardTokens, 10);
    if (isNaN(parsedTokens) || parsedTokens <= 0 || parsedTokens > 500) {
        return next(new AppError('Invalid reward amount. Tokens must be between 1 and 500.', 400));
    }

    try {
        const result = await withTransaction(async (client) => {
            return await economyService.processQuestClaim(client, userId, questId, parsedTokens);
        });

        res.json({
            message: 'Quest claimed successfully',
            newBalance: result.newBalance
        });
    } catch (err) {
        console.error('❌ Quest Claim Error:', err);
        if (err.message === 'Quest already claimed') {
            return next(new AppError(err.message, 400));
        }
        throw err;
    }
});
