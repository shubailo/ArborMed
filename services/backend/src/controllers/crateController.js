const crateService = require('../services/crateService');
const catchAsync = require('../utils/catchAsync');
exports.openCrate = catchAsync(async (req, res) => {
    const { crateType, purchaseId } = req.body;
    const result = await crateService.openCrate(req.user.id, crateType, purchaseId);
    res.status(200).json(result);
});

exports.getCrates = catchAsync(async (req, res) => {
    const crates = await crateService.getCrateConfig();
    res.status(200).json(crates);
});
