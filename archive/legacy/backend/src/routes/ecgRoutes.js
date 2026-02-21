const express = require('express');
const router = express.Router();
const ecgController = require('../controllers/ecgController');
const { protect } = require('../middleware/authMiddleware');
const { admin } = require('../middleware/adminMiddleware');

// Public/Student routes
// Note: Diagnoses list is useful for the "Fast Forward" search
router.get('/diagnoses', protect, ecgController.getDiagnoses);

// Cases
router.get('/cases', protect, ecgController.getCases);
router.get('/cases/:id', protect, ecgController.getCaseById);

// --- ADMIN ROUTES ---

// Manage Diagnoses Library
router.post('/diagnoses', protect, admin, ecgController.createDiagnosis);

// Manage ECG Cases
router.post('/cases', protect, admin, ecgController.createCase);
router.put('/cases/:id', protect, admin, ecgController.updateCase);
router.delete('/cases/:id', protect, admin, ecgController.deleteCase);

module.exports = router;
