const express = require('express');
const router = express.Router();
const {
    searchUsers,
    sendRequest,
    respondToRequest,
    getNetwork,
    leaveNote,
    getNotes,
    likeRoom,
    removeColleague
} = require('../controllers/socialController');
const { protect } = require('../middleware/authMiddleware');

router.get('/search', protect, searchUsers);
router.post('/request', protect, sendRequest);
router.put('/request', protect, respondToRequest);
router.get('/network', protect, getNetwork);
router.post('/note', protect, leaveNote);
router.get('/notes/:userId', protect, getNotes);
router.post('/like', protect, likeRoom);
router.delete('/colleague/:targetUserId', protect, removeColleague);

module.exports = router;
