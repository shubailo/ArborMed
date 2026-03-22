const { withTransaction } = require('../utils/dbHelpers');
const economyService = require('../services/economyService');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');

exports.claimQuest = catchAsync(async (req, res, next) => {
    const { questId, rewardTokens } = req.body;
    const userId = req.user.id;

    if (!questId || rewardTokens === undefined || rewardTokens === null) {
        return next(new AppError('Missing questId or rewardTokens', 400));
    }

    // 🛡️ Sentinel: Validate and cap rewardTokens to prevent economy abuse
    const tokens = parseInt(rewardTokens, 10);
    if (isNaN(tokens) || tokens <= 0) {
        return next(new AppError('Invalid reward tokens amount', 400));
    }

    // Strict cap on tokens per claim (e.g., max 500)
    const cappedTokens = tokens > 500 ? 500 : tokens;

    try {
        const result = await withTransaction(async (client) => {
            return await economyService.processQuestClaim(client, userId, questId, cappedTokens);
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
