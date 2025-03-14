const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');


// Register new user
router.post('/register', authController.register);

// Login user
router.post('/login', authController.login);

// changePassword
router.post('/change-password', authMiddleware, authController.changePassword);

// resetPassword
router.post('/reset-password', authController.resetPassword);

// Update user role
router.patch('/role/:userId', authController.updateRole);

// Verify user data
router.get('/verify/:userId', authController.verifyUserData);

module.exports = router;
