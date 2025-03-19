const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const Application = require('../models/application.model');
const Job = require('../models/job.model');
const User = require('../models/user.model');
const mongoose = require('mongoose');
const { createApplicationNotification } = require('../controllers/notification.controller');


router.get('/', (req, res) => {
    res.json({ message: 'API is working' });
});

// Get user by email
router.get('/getUser/:email', userController.getUserByEmail);

// Handle job applications
router.post('/apply', async (req, res) => {
    try {
        console.log('[API] Received job application:', req.body);
        
        // Validate required fields
        const { fullName, address, id, nic, message, jobTitle, email } = req.body;
        
        if (!fullName || !message || !jobTitle || !email) {
            return res.status(400).json({ 
                success: false,
                message: 'Missing required fields' 
            });
        }

        // Start a MongoDB session for transaction-like behavior
        const session = await mongoose.startSession();
        session.startTransaction();

        try {
            // Find the applicant user
            const applicant = await User.findOne({ email }).session(session);
            if (!applicant) {
                await session.abortTransaction();
                session.endSession();
                return res.status(404).json({ 
                    success: false, 
                    message: 'Applicant not found' 
                });
            }

            // Find the job by title
            const job = await Job.findOne({ title: jobTitle }).session(session);
            if (!job) {
                await session.abortTransaction();
                session.endSession();
                return res.status(404).json({ 
                    success: false, 
                    message: 'Job not found' 
                });
            }

            // Find the job owner
            const jobOwner = await User.findById(job.postedBy).session(session);
            if (!jobOwner) {
                await session.abortTransaction();
                session.endSession();
                return res.status(404).json({ 
                    success: false, 
                    message: 'Job owner not found' 
                });
            }

            // Create and save the application
            const application = new Application({
                job: job._id,
                applicant: applicant._id,
                jobOwner: jobOwner._id,
                coverLetter: message,
                status: 'pending',
                appliedAt: new Date()
            });

            await application.save({ session });

            // Update the job with the new application
            job.applications.push(application._id);
            await job.save({ session });

            // Create notification for job owner
            await createApplicationNotification(application, applicant, job);


            // Commit the transaction
            await session.commitTransaction();
            session.endSession();

            console.log('[API] Application saved successfully:', {
                jobId: job._id,
                applicantId: applicant._id,
                jobOwnerId: jobOwner._id,
                applicationId: application._id
            });

            res.status(200).json({ 
                success: true,
                message: 'Application submitted successfully',
                applicationId: application._id
            });
        } catch (error) {
            // If an error occurs, abort the transaction
            await session.abortTransaction();
            session.endSession();
            throw error;
        }
    } catch (error) {
        console.error('[API] Error handling job application:', error);
        res.status(500).json({ 
            success: false,
            message: 'Error processing application',
            error: error.message 
        });
    }
});

module.exports = router;
