const { withTransaction } = require('../utils/dbHelpers');
const residencyService = require('../services/residencyService');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');
const { isUtcCalendarDay } = require('../utils/utcDate');

exports.getStatus = catchAsync(async (req, res) => {
    const data = await withTransaction(client => residencyService.dailyStatus(client, req.user.id));
    res.status(200).json({ status: 'success', data });
});

exports.syncRounds = catchAsync(async (req, res) => {
    const studyDay = req.body?.studyDay;
    if (studyDay !== undefined && !isUtcCalendarDay(studyDay)) {
        throw new AppError('Invalid UTC study day', 400);
    }
    const data = await withTransaction(client => residencyService.dailyStatus(client, req.user.id, {
        complete: true, studyDay
    }));
    res.status(200).json({ status: data.roundsCompleted ? 'success' : 'incomplete', data });
});
