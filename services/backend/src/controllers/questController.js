const db = require('../config/db');
const { withTransaction } = require('../utils/dbHelpers');
const economyService = require('../services/economyService');
const catchAsync = require('../utils/catchAsync');

exports.claimQuest = catchAsync(async (req, res) => {
    const { newBalance } = await withTransaction(client =>
        economyService.processQuestClaim(client, req.user.id, req.body?.questId)
    );
    res.json({ message: 'Quest claimed successfully', newBalance });
});

exports.getDaily = catchAsync(async (req, res) => {
    res.json(await economyService.dailyProgress(db, req.user.id));
});
