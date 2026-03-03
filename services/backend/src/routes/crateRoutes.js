const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const crateController = require('../controllers/crateController');

router.get('/', protect, crateController.getCrates);
router.post('/open', protect, crateController.openCrate);

module.exports = router;
