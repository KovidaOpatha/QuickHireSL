// const express = require('express');
// const router = express.Router();
// const authController = require('../controllers/auth.controller');

// // Register (Email & Password)
// router.post('/register', authController.register);

// // Update Role
// router.put('/updateRole', authController.updateRole);

// // Login
// router.post('/login', authController.login);

// module.exports = router;





const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');

// Public Routes
router.post('/register', authController.register);
router.post('/login', authController.login);

// Protected Route: update role requires a valid token
router.put('/updateRole', authMiddleware, authController.updateRole);

module.exports = router;

