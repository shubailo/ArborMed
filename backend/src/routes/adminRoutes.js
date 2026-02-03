const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { protect } = require('../middleware/authMiddleware');
const { admin } = require('../middleware/adminMiddleware');

// All routes here are PROTECTED and ADMIN-ONLY
router.use(protect);
router.use(admin);

/**
 * @route GET /api/admin/students
 */
router.get('/students', adminController.getStudents);

/**
 * @route GET /api/admin/admins
 */
router.get('/admins', adminController.getAdmins);

/**
 * @route PUT /api/admin/user-role
 */
router.put('/user-role', adminController.updateUserRole);

/**
 * @route DELETE /api/admin/users/:userId
 */
router.delete('/users/:userId', adminController.deleteUser);

/**
 * @route POST /api/admin/notify
 */
router.post('/notify', adminController.sendDirectMessage);

/**
 * @route PUT /api/admin/assign-subject
 */
router.put('/assign-subject', adminController.assignSubjectToAdmin);

module.exports = router;
