const jobMatchingService = require('../services/job-matching.service');

/**
 * Get matching jobs for a user
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
exports.getMatchingJobs = async (req, res) => {
    try {
        const userId = req.params.userId;
        console.log('[JobMatchingController] Finding matching jobs for user:', userId);
        
        // Extract query parameters
        const options = {
            limit: req.query.limit ? parseInt(req.query.limit) : 10,
            minScore: req.query.minScore ? parseInt(req.query.minScore) : 30,
            includeDetails: req.query.includeDetails === 'true',
            sortBy: ['score', 'date', 'salary'].includes(req.query.sortBy) ? req.query.sortBy : 'score',
            sortOrder: ['asc', 'desc'].includes(req.query.sortOrder) ? req.query.sortOrder : 'desc',
            location: req.query.location,
            category: req.query.category
        };
        
        console.log('[JobMatchingController] Search options:', options);
        
        // Find matching jobs
        const matchingJobs = await jobMatchingService.findMatchingJobs(userId, options);
        
        // Format the response
        const formattedJobs = matchingJobs.map(item => ({
            jobId: item.job._id,
            title: item.job.title,
            company: item.job.company,
            location: item.job.location,
            category: item.job.category,
            salary: item.job.salary,
            description: item.job.description,
            requiredSkills: item.job.requiredSkills,
            availableDates: item.job.availableDates,
            postedBy: item.job.postedBy,
            postedDate: item.job.createdAt,
            employmentType: item.job.employmentType,
            experienceLevel: item.job.experienceLevel,
            requirements: item.job.requirements || [],
            matchScore: item.score,
            matchReasons: item.reasons,
            ...(options.includeDetails && { matchDetails: item.details })
        }));
        
        console.log(`[JobMatchingController] Found ${formattedJobs.length} matching jobs`);
        
        res.status(200).json({
            success: true,
            count: formattedJobs.length,
            data: formattedJobs
        });
    } catch (error) {
        console.error('[JobMatchingController] Error finding matching jobs:', error);
        res.status(500).json({
            success: false,
            message: 'Error finding matching jobs',
            error: error.message
        });
    }
};

/**
 * Calculate match score between a user and a specific job
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
exports.calculateJobMatch = async (req, res) => {
    try {
        const { userId, jobId } = req.params;
        console.log('[JobMatchingController] Calculating match score for user:', userId, 'and job:', jobId);
        
        // Find the user and job
        const User = require('../models/user.model');
        const Job = require('../models/job.model');
        
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }
        
        const job = await Job.findById(jobId);
        if (!job) {
            return res.status(404).json({
                success: false,
                message: 'Job not found'
            });
        }
        
        // Calculate match score
        const matchResult = jobMatchingService.calculateMatchScore(user, job);
        
        console.log('[JobMatchingController] Match score calculated:', matchResult.score);
        
        res.status(200).json({
            success: true,
            jobId: job._id,
            title: job.title,
            company: job.company,
            matchScore: matchResult.score,
            matchReasons: matchResult.reasons,
            matchDetails: matchResult.details
        });
    } catch (error) {
        console.error('[JobMatchingController] Error calculating match score:', error);
        res.status(500).json({
            success: false,
            message: 'Error calculating match score',
            error: error.message
        });
    }
};
