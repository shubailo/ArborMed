const express = require('express');
const router = express.Router();
const { register, login, getMe, changePassword, updateProfile, requestOTP, resetPassword, verifyEmail, refreshToken, logout, googleLogin } = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

router.post('/register', register);
router.post('/login', login);
router.post('/google', googleLogin);
router.post('/refresh', refreshToken);
router.post('/logout', protect, logout);
router.get('/me', protect, getMe);
router.post('/change-password', protect, changePassword);
router.put('/profile', protect, updateProfile);
router.post('/request-otp', requestOTP);
router.post('/reset-password', resetPassword);
router.post('/verify-email', verifyEmail);

module.exports = router;
