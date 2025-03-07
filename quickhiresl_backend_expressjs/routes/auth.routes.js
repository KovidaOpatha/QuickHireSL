const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');

// Register new user
router.post('/register', authController.register);

// Login user
router.post('/login', authController.login);

// Update user role
router.patch('/role/:userId', authController.updateRole);

// Verify user data
router.get('/verify/:userId', authController.verifyUserData);

module.exports = router;
