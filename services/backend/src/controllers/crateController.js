const crateService = require('../services/crateService');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');

exports.openCrate = catchAsync(async (req, res, next) => {
    const userId = req.user.id;
    const { crateType } = req.body;

    try {
        const result = await crateService.openCrate(userId, crateType);
        res.status(200).json(result);
    } catch (err) {
        if (err.message === 'Insufficient coins for crate') {
            return next(new AppError(err.message, 400));
        }
        throw err;
    }
});

exports.getCrates = catchAsync(async (req, res) => {
    const crates = await crateService.getCrateConfig();
    res.status(200).json(crates);
});
