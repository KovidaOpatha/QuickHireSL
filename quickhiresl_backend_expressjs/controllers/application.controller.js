const Application = require('../models/application.model');
const Job = require('../models/job.model');

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

            const application = new Application({
                job: jobId,
                applicant: req.user._id, // From auth middleware
                jobOwner: job.postedBy, // From the job document
                coverLetter
            });

            await application.save();
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
                .populate('job')
                .populate('applicant', '-password')
                .sort({ createdAt: -1 });
            res.json(applications);
        } catch (error) {
            res.status(500).json({ message: error.message });
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

            const application = await Application.findById(applicationId);
            
            if (!application) {
                return res.status(404).json({ message: 'Application not found' });
            }

            // Ensure only the job owner can update the status
            if (application.jobOwner.toString() !== req.user._id.toString()) {
                return res.status(403).json({ message: 'Not authorized' });
            }

            application.status = status;
            await application.save();

            res.json(application);
        } catch (error) {
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
    }
};

console.log('Controller methods:', Object.keys(applicationController));
module.exports = applicationController;