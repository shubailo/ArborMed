const db = require('../config/db');
const { withTransaction } = require('../utils/dbHelpers');
const economyService = require('../services/economyService');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');

exports.claimQuest = catchAsync(async (req, res) => {
    const expectedDate = req.body?.date;
    if (expectedDate !== undefined) {
        const parsed = typeof expectedDate === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(expectedDate)
            ? new Date(expectedDate) : null;
        if (!parsed || !Number.isFinite(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== expectedDate) {
            throw new AppError('Invalid daily quest date', 400);
        }
    }
    const { newBalance, awardedTokens, date } = await withTransaction(client =>
        economyService.processQuestClaim(client, req.user.id, req.body?.questId, { expectedDate })
    );
    res.json({ message: 'Quest claimed successfully', newBalance, awardedTokens, date });
});

exports.getDaily = catchAsync(async (req, res) => {
    res.json(await economyService.dailyProgress(db, req.user.id));
});
