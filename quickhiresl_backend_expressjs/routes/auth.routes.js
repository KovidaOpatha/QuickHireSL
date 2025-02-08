const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');
const upload = require('../middleware/upload.middleware');

// Public Routes
router.post('/register', upload.single('profileImage'), authController.register);
router.post('/login', authController.login);

// Protected Route: update role requires a valid token
router.put('/updateRole', authMiddleware, authController.updateRole);

module.exports = router;
