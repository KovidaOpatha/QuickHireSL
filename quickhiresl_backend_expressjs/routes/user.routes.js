const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const authMiddleware = require('../middleware/auth.middleware');

// Get user profile - Protected route
router.get('/:userId', authMiddleware, userController.getUserProfile);

// Update user profile - Protected route
router.put('/:userId', authMiddleware, userController.updateUserProfile);

// Update user preferences - Protected route
router.patch('/:userId/preferences', authMiddleware, userController.updateUserPreferences);

module.exports = router;
