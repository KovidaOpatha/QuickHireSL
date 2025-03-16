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

// Update user availability - Protected route
router.patch('/:userId/availability', authMiddleware, userController.updateUserAvailability);

// Add a new availability date - Protected route
router.post('/:userId/availability', authMiddleware, userController.addAvailabilityDate);

// Remove an availability date - Protected route
router.delete('/:userId/availability/:dateId', authMiddleware, userController.removeAvailabilityDate);

module.exports = router;
