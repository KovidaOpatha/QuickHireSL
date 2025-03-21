const express = require('express');
const router = express.Router();
const feedbackController = require('../controllers/feedback.controller');
const { authenticateToken } = require('../middleware/auth.middleware');

// Submit feedback (requires authentication)
router.post('/', authenticateToken, feedbackController.submitFeedback);

// Get feedback for a user
router.get('/user/:userId', feedbackController.getUserFeedback);

// Get feedback for an application
router.get('/application/:applicationId', feedbackController.getApplicationFeedback);

module.exports = router;
