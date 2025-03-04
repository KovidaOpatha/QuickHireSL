const Job = require('../models/job.model');
const User = require('../models/user.model');
const { createJobNotification } = require('./notification.controller');

// Create a new job posting
exports.createJob = async (req, res) => {
    try {
        console.log('Creating job with data:', req.body);
        console.log('User:', req.user);

        const job = new Job({
            ...req.body,
            postedBy: req.user._id
        });

        const savedJob = await job.save();
        
        // Create notifications for all students
        await createJobNotification(savedJob, req.user._id);

        console.log('Job created successfully:', savedJob);

        res.status(201).json({
            success: true,
            data: savedJob
        });
    } catch (error) {
        console.error('Error in createJob:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Get all jobs with filters
exports.getJobs = async (req, res) => {
    try {
        const {
            location,
            employmentType,
            experienceLevel,
            salaryMin,
            salaryMax,
            search
        } = req.query;

        let query = {};

        if (location) {
            query.location = { $regex: location, $options: 'i' };
        }
        if (employmentType) {
            query.employmentType = employmentType;
        }
        if (experienceLevel) {
            query.experienceLevel = experienceLevel;
        }
        if (salaryMin) {
            query['salary.min'] = { $gte: parseInt(salaryMin) };
        }
        if (salaryMax) {
            query['salary.max'] = { $lte: parseInt(salaryMax) };
        }
        if (search) {
            query.$or = [
                { title: { $regex: search, $options: 'i' } },
                { company: { $regex: search, $options: 'i' } },
                { description: { $regex: search, $options: 'i' } }
            ];
        }

        const jobs = await Job.find(query)
            .populate('postedBy', 'name email')
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: jobs.length,
            data: jobs
        });
    } catch (error) {
        console.error('Error in getJobs:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Get a single job by ID
exports.getJob = async (req, res) => {
    try {
        const job = await Job.findById(req.params.id)
            .populate('postedBy', 'name email')
            .populate('applications');

        if (!job) {
            return res.status(404).json({
                success: false,
                message: 'Job not found'
            });
        }

        res.status(200).json({
            success: true,
            data: job
        });
    } catch (error) {
        console.error('Error in getJob:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Update a job
exports.updateJob = async (req, res) => {
    try {
        const job = await Job.findById(req.params.id);

        if (!job) {
            return res.status(404).json({
                success: false,
                message: 'Job not found'
            });
        }

        // Check if the user is the owner of the job
        if (job.postedBy.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to update this job'
            });
        }

        const updatedJob = await Job.findByIdAndUpdate(
            req.params.id,
            req.body,
            {
                new: true,
                runValidators: true
            }
        );

        res.status(200).json({
            success: true,
            data: updatedJob
        });
    } catch (error) {
        console.error('Error in updateJob:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Delete a job
exports.deleteJob = async (req, res) => {
    try {
        const job = await Job.findById(req.params.id);

        if (!job) {
            return res.status(404).json({
                success: false,
                message: 'Job not found'
            });
        }

        // Check if the user is the owner of the job
        if (job.postedBy.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete this job'
            });
        }

        await job.deleteOne();

        res.status(200).json({
            success: true,
            message: 'Job deleted successfully'
        });
    } catch (error) {
        console.error('Error in deleteJob:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};
