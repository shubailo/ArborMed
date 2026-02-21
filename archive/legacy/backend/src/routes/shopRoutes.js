const express = require('express');
const router = express.Router();
const { getCatalog, buyItem } = require('../controllers/shopController');
const { getInventory, equipItem, unequipItem, syncRoomState } = require('../controllers/inventoryController');
const { protect } = require('../middleware/authMiddleware');

// Shop
router.get('/items', protect, getCatalog);
router.post('/buy', protect, buyItem);

// Inventory
router.get('/inventory', protect, getInventory);
router.post('/equip', protect, equipItem);
router.post('/unequip', protect, unequipItem);
router.post('/sync-room', protect, syncRoomState);

module.exports = router;
