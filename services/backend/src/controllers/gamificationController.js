const { withTransaction } = require('../utils/dbHelpers');
const residencyService = require('../services/residencyService');
const catchAsync = require('../utils/catchAsync');

exports.getStatus = catchAsync(async (req, res) => {
    const data = await withTransaction(client => residencyService.dailyStatus(client, req.user.id));
    res.status(200).json({ status: 'success', data });
});

exports.syncRounds = catchAsync(async (req, res) => {
    const data = await withTransaction(client => residencyService.dailyStatus(client, req.user.id, {
        complete: true, studyDay: req.body?.studyDay
    }));
    res.status(200).json({ status: data.roundsCompleted ? 'success' : 'incomplete', data });
});
