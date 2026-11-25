const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

const { rateLimit } = require('express-rate-limit');
const rateOptions = { windowMs: 15 * 60 * 1000, standardHeaders: 'draft-6', legacyHeaders: false };
const signIn = rateLimit({ ...rateOptions, limit: 50, skipSuccessfulRequests: true });
const challenges = rateLimit({ ...rateOptions, limit: 50 });
const refresh = rateLimit({ ...rateOptions, limit: 600 });

router.use(['/login', '/google'], signIn);
router.use(['/register', '/change-password', '/request-otp', '/reset-password', '/verify-email',
    '/verify-registration', '/resend-registration-otp'], challenges);
router.use('/refresh', refresh);

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/google', authController.googleLogin);
router.post('/refresh', authController.refreshToken);
router.post('/logout', protect, authController.logout);
router.get('/me', protect, authController.getMe);
router.post('/change-password', protect, authController.changePassword);
router.put('/profile', protect, authController.updateProfile);
router.post('/request-otp', authController.requestOTP);
router.post('/reset-password', authController.resetPassword);
router.post('/verify-email', authController.verifyEmail);
router.post('/verify-registration', authController.verifyRegistration);
router.post('/resend-registration-otp', authController.resendRegistrationOTP);
router.post('/claim-reward', protect, authController.claimReward);

module.exports = router;
