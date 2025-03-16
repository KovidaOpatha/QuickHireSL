const express = require('express');
const router = express.Router();
const jobMatchingController = require('../controllers/job-matching.controller');
const authMiddleware = require('../middleware/auth.middleware');

// Get matching jobs for a user - Protected route
router.get('/users/:userId/matching-jobs', authMiddleware, jobMatchingController.getMatchingJobs);

// Calculate match score between a user and a specific job - Protected route
router.get('/users/:userId/jobs/:jobId/match', authMiddleware, jobMatchingController.calculateJobMatch);

module.exports = router;
