const express = require('express');
const router = express.Router();
const { getCatalog, buyItem } = require('../controllers/shopController');
const { getInventory, equipItem, unequipItem, syncRoomState } = require('../controllers/inventoryController');
const { protect } = require('../middleware/authMiddleware');
const AppError = require('../utils/AppError');
const { positiveId } = require('../utils/quizIds');

function requireBody(req, res, next) {
    if (!req.body || typeof req.body !== 'object' || Array.isArray(req.body) ||
        Object.keys(req.body).length === 0) {
        return next(new AppError('A non-empty request body object is required', 400));
    }
    next();
}

function validateInventoryTarget(req, res, next) {
    if (req.query.userId !== undefined && positiveId(req.query.userId) === null) {
        return next(new AppError('Invalid user ID', 400));
    }
    next();
}

// Shop
router.get('/items', protect, getCatalog);
router.post('/buy', protect, requireBody, buyItem);

// Inventory
router.get('/inventory', protect, validateInventoryTarget, getInventory);
router.post('/equip', protect, requireBody, equipItem);
router.post('/unequip', protect, requireBody, unequipItem);
router.post('/sync-room', protect, requireBody, syncRoomState);

module.exports = router;
