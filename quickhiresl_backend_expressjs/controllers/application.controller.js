const Application = require('../models/application.model');
const Job = require('../models/job.model');
const User = require('../models/user.model');
const { createApplicationNotification, createApplicationStatusNotification } = require('./notification.controller');

console.log('Loading application controller...');

const applicationController = {
    // Create a new application
    createApplication: async (req, res) => {
        try {
            const { jobId, coverLetter } = req.body;
            
            if (!coverLetter) {
                return res.status(400).json({ message: 'Cover letter is required' });
            }
            
            // Get the job details to get the job owner
            const job = await Job.findById(jobId);
            if (!job) {
                return res.status(404).json({ message: 'Job not found' });
            }

            if (!job.postedBy) {
                return res.status(400).json({ message: 'Job owner not found' });
            }

            // Get the applicant's full details including studentDetails
            const applicant = await User.findById(req.user._id);
            if (!applicant || !applicant.studentDetails || !applicant.studentDetails.fullName) {
                return res.status(400).json({ message: 'Applicant details not found' });
            }

            const application = new Application({
                job: jobId,
                applicant: req.user._id, // From auth middleware
                jobOwner: job.postedBy, // From the job document
                coverLetter
            });

            await application.save();

            // Create notification with the correct applicant name
            await createApplicationNotification(
                application,
                { fullName: applicant.studentDetails.fullName },
                job
            );

            res.status(201).json(application);
        } catch (error) {
            console.error('Error creating application:', error);
            res.status(500).json({ message: error.message });
        }
    },

    // Get applications for a job owner
    getJobOwnerApplications: async (req, res) => {
        try {
            const applications = await Application.find({ jobOwner: req.user._id })
                .populate({
                    path: 'job',
                    populate: {
                        path: 'postedBy',
                        select: '-password'
                    }
                })
                .populate({
                    path: 'applicant',
                    select: '-password'
                })
                .populate({
                    path: 'jobOwner',
                    select: '-password'
                })
                .sort({ createdAt: -1 });

            // Transform the data to match the expected format
            const transformedApplications = applications.map(app => ({
                _id: app._id,
                job: app.job,
                applicant: app.applicant,
                jobOwner: app.jobOwner,
                status: app.status,
                coverLetter: app.coverLetter,
                appliedAt: app.appliedAt,
                createdAt: app.createdAt,
                updatedAt: app.updatedAt
            }));

            res.json({
                success: true,
                data: transformedApplications
            });
        } catch (error) {
            console.error('Error in getJobOwnerApplications:', error);
            res.status(500).json({ 
                success: false,
                message: error.message 
            });
        }
    },

    // Get applications for a specific job
    getJobApplications: async (req, res) => {
        try {
            const { jobId } = req.params;
            const applications = await Application.find({ job: jobId })
                .populate('applicant', '-password')
                .sort({ createdAt: -1 });
            res.json(applications);
        } catch (error) {
            res.status(500).json({ message: error.message });
        }
    },

    // Update application status
    updateApplicationStatus: async (req, res) => {
        try {
            const { applicationId } = req.params;
            const { status } = req.body;

            const application = await Application.findById(applicationId)
                .populate('job')
                .populate('applicant', '-password')
                .populate('jobOwner', '-password');

            if (!application) {
                return res.status(404).json({ message: 'Application not found' });
            }

            // Check if the application is completed
            if (application.status === 'completed') {
                return res.status(400).json({ message: 'Cannot modify a completed application' });
            }

            // Check if user is the job owner
            if (application.jobOwner._id.toString() !== req.user._id.toString()) {
                return res.status(403).json({ message: 'Only job owner can update application status' });
            }

            // Save the old status for comparison
            const oldStatus = application.status;

            // Update the status
            application.status = status;
            await application.save();  

            // If status has changed, create a notification
            if (oldStatus !== status) {
                await createApplicationStatusNotification(application, application.job, status);
            } 

            res.json({
                success: true,
                data: application
            });
        } catch (error) {
            console.error('Error updating application status:', error);
            res.status(500).json({ message: error.message });
        }
    },

    // Get applicant's applications
    getApplicantApplications: async (req, res) => {
        try {
            const applications = await Application.find({ applicant: req.user._id })
                .populate({
                    path: 'job',
                    populate: {
                        path: 'postedBy',
                        select: '-password'
                    }
                })
                .populate('jobOwner', '-password')
                .populate('applicant', '-password')
                .sort({ createdAt: -1 });
            res.json(applications);
        } catch (error) {
            res.status(500).json({ message: error.message });
        }
    },

    // Request job completion
    requestCompletion: async (req, res) => {
        try {
            const { applicationId } = req.params;

            const application = await Application.findById(applicationId)
                .populate('job')
                .populate('applicant', '-password')
                .populate('jobOwner', '-password');

            if (!application) {
                return res.status(404).json({ message: 'Application not found' });
            }

            // Check if the user is either the job owner or the applicant
            const isJobOwner = application.jobOwner._id.toString() === req.user._id.toString();
            const isApplicant = application.applicant._id.toString() === req.user._id.toString();

            if (!isJobOwner && !isApplicant) {
                return res.status(403).json({ message: 'Not authorized' });
            }

            // Check if the application is already completed
            if (application.status === 'completed') {
                return res.status(400).json({ message: 'This application is already completed' });
            }

            // Check if the application is in an acceptable state for completion
            if (application.status !== 'accepted') {
                return res.status(400).json({ message: 'Application must be accepted before requesting completion' });
            }

            // Check if completion is already requested
            if (application.completionDetails && application.completionDetails.requestedBy) {
                return res.status(400).json({ message: 'Completion has already been requested' });
            }

            // Update application status and completion details
            application.status = 'completion_requested';
            application.completionDetails = {
                requestedBy: isJobOwner ? 'jobOwner' : 'applicant',
                requestedAt: new Date()
            };

            await application.save();

            // Create notification for the other party
            const recipientId = isJobOwner ? application.applicant._id : application.jobOwner._id;
            const notificationRecipient = isJobOwner ? application.applicant : application.jobOwner;
            
             // Create a notification for the recipient
             await createApplicationStatusNotification(
                { ...application.toObject(), applicant: recipientId },
                application.job,
                'completion_requested'
            );

            res.json({
                success: true,
                data: application
            });
        } catch (error) {
            console.error('Error requesting completion:', error);
            res.status(500).json({ message: error.message });
        }
    },

    // Confirm job completion
    confirmCompletion: async (req, res) => {
        try {
            const { applicationId } = req.params;

            const application = await Application.findById(applicationId)
                .populate('job')
                .populate('applicant', '-password')
                .populate('jobOwner', '-password');

            if (!application) {
                return res.status(404).json({ message: 'Application not found' });
            }

            // Check if the user is either the job owner or the applicant
            const isJobOwner = application.jobOwner._id.toString() === req.user._id.toString();
            const isApplicant = application.applicant._id.toString() === req.user._id.toString();

            if (!isJobOwner && !isApplicant) {
                return res.status(403).json({ message: 'Not authorized' });
            }

            // Check if the application is already completed
            if (application.status === 'completed') {
                return res.status(400).json({ message: 'This application is already completed' });
            }

            // Check if the application is in completion_requested state
            if (application.status !== 'completion_requested') {
                return res.status(400).json({ message: 'Completion must be requested before confirming' });
            }

            // Check if the confirming user is different from the requesting user
            const requestedBy = application.completionDetails.requestedBy;
            if ((requestedBy === 'jobOwner' && isJobOwner) || (requestedBy === 'applicant' && isApplicant)) {
                return res.status(400).json({ message: 'Completion must be confirmed by the other party' });
            }

            // Update application status and completion details
            application.status = 'completed';
            application.completionDetails.confirmedAt = new Date();

            await application.save();

            res.json({
                success: true,
                data: application
            });
        } catch (error) {
            console.error('Error confirming completion:', error);
            res.status(500).json({ message: error.message });
        }
    },
};

console.log('Controller methods:', Object.keys(applicationController));
module.exports = applicationController;