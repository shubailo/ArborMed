const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

const { rateLimit } = require('express-rate-limit');
const rateOptions = {
    windowMs: 15 * 60 * 1000,
    standardHeaders: 'draft-6',
    legacyHeaders: false,
    message: { message: 'Too many requests. Please try again later.' },
};
const signIn = rateLimit({
    ...rateOptions, limit: 50, skipSuccessfulRequests: true,
    // Only client-side refusals spend the failure budget after a request completes.
    requestWasSuccessful: (_req, res) => res.statusCode < 400 || res.statusCode >= 500,
});
const issueCode = rateLimit({ ...rateOptions, limit: 50 });
const confirm = rateLimit({ ...rateOptions, limit: 50 });
const refresh = rateLimit({ ...rateOptions, limit: 600 });

router.post('/register', issueCode, authController.register);
router.post('/login', signIn, authController.login);
router.post('/google', signIn, authController.googleLogin);
router.post('/refresh', refresh, authController.refreshToken);
router.post('/logout', protect, authController.logout);
router.get('/me', protect, authController.getMe);
router.post('/change-password', confirm, protect, authController.changePassword);
router.put('/profile', protect, authController.updateProfile);
router.post('/request-otp', issueCode, authController.requestOTP);
router.post('/reset-password', confirm, authController.resetPassword);
router.post('/verify-email', confirm, authController.verifyEmail);
router.post('/verify-registration', confirm, authController.verifyRegistration);
router.post('/resend-registration-otp', issueCode, authController.resendRegistrationOTP);
router.post('/claim-reward', protect, authController.claimReward);

module.exports = router;
