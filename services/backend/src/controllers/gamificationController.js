const db = require('../config/db');
const residencyService = require('../services/residencyService');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/AppError');

/**
 * Controller for clinical residency gamification logic.
 * Handles rounds synchronization and clinical status reporting.
 */

exports.getStatus = catchAsync(async (req, res) => {
    const userId = req.user.id;

    const standing = await residencyService.ensureDailyClinicalStatus(db, userId);

    res.status(200).json({
        status: 'success',
        data: {
            rank: standing.rank,
            malpracticeStrikes: standing.malpractice_strikes,
            lastRoundsDate: standing.last_rounds_date,
            isOnProbation: standing.malpractice_strikes >= 3
        }
    });
});

exports.syncRounds = catchAsync(async (req, res) => {
    const userId = req.user.id;

    // We use a transaction to ensure either everything updates (strikes removed + rounds saved) or nothing
    const standing = await db.transaction(async (client) => {
        return await residencyService.syncCompletedRounds(client, userId);
    });

    res.status(200).json({
        status: 'success',
        data: {
            rank: standing.rank,
            malpracticeStrikes: standing.malpractice_strikes,
            lastRoundsDate: standing.last_rounds_date,
            isOnProbation: standing.malpractice_strikes >= 3
        }
    });
});
