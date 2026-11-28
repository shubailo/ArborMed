const crateService = require('../services/crateService');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');
exports.openCrate = catchAsync(async (req, res) => {
    if (!req.body || typeof req.body !== 'object' || Array.isArray(req.body)) {
        throw new AppError('A crate purchase object is required', 400);
    }
    const { crateType, purchaseId } = req.body;
    const result = await crateService.openCrate(req.user.id, crateType, purchaseId);
    res.status(200).json(result);
});

exports.getCrates = catchAsync(async (req, res) => {
    const crates = await crateService.getCrateConfig();
    res.status(200).json(crates);
});
