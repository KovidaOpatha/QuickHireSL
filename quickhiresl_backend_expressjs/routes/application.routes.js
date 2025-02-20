const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const applicationController = require('../controllers/application.controller');

console.log('Route handlers:', {
    createApplication: applicationController.createApplication,
    authMiddleware: authMiddleware
});

// Create a new application
router.post('/', authMiddleware, applicationController.createApplication);

// Get all applications for a job owner
router.get('/owner', authMiddleware, applicationController.getJobOwnerApplications);

// Get applications for a specific job
router.get('/job/:jobId', authMiddleware, applicationController.getJobApplications);

// Update application status
router.patch('/:applicationId/status', authMiddleware, applicationController.updateApplicationStatus);

// Get applicant's applications
router.get('/my-applications', authMiddleware, applicationController.getApplicantApplications);

module.exports = router;
