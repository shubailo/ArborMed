const { withTransaction } = require('../utils/dbHelpers');
const economyService = require('../services/economyService');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');

exports.claimQuest = catchAsync(async (req, res, next) => {
    const { questId, rewardTokens } = req.body;
    const userId = req.user.id;

    if (!questId || !rewardTokens) {
        return next(new AppError('Missing questId or rewardTokens', 400));
    }

    try {
        const result = await withTransaction(async (client) => {
            return await economyService.processQuestClaim(client, userId, questId, rewardTokens);
        });

        res.json({
            message: 'Quest claimed successfully',
            newBalance: result.newBalance
        });
    } catch (err) {
        if (err.message === 'Quest already claimed') {
            return next(new AppError(err.message, 400));
        }
        throw err;
    }
});
