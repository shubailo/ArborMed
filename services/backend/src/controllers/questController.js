const db = require('../config/db');
const { withTransaction } = require('../utils/dbHelpers');
const economyService = require('../services/economyService');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');
const { isUtcCalendarDay } = require('../utils/utcDate');

exports.claimQuest = catchAsync(async (req, res) => {
    const expectedDate = req.body?.date;
    if (expectedDate !== undefined && !isUtcCalendarDay(expectedDate)) {
        throw new AppError('Invalid daily quest date', 400);
    }
    const { newBalance, awardedTokens, date } = await withTransaction(client =>
        economyService.processQuestClaim(client, req.user.id, req.body?.questId, { expectedDate })
    );
    res.json({ message: 'Quest claimed successfully', newBalance, awardedTokens, date });
});

exports.getDaily = catchAsync(async (req, res) => {
    res.json(await economyService.dailyProgress(db, req.user.id));
});
