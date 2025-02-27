const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');  
const {
    createJob,
    getJobs,
    getJob,
    updateJob,
    deleteJob
} = require('../controllers/job.controller');

// Public routes
router.get('/', getJobs);
router.get('/:id', getJob);

// Protected routes (require authentication)
router.post('/', authMiddleware, createJob);
router.put('/:id', authMiddleware, updateJob);
router.delete('/:id', authMiddleware, deleteJob);

module.exports = router;
