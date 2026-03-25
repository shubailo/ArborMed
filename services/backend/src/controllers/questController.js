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

    // 🛡️ Sentinel: Prevent Mass Assignment by capping and validating rewardTokens
    let parsedTokens = parseInt(rewardTokens, 10);
    if (isNaN(parsedTokens) || parsedTokens <= 0) {
        return next(new AppError('Invalid reward amount', 400));
    }
    if (parsedTokens > 500) {
        parsedTokens = 500; // Hard cap to prevent economy breaking
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
