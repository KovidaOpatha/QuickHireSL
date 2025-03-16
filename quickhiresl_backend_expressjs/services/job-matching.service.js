/**
 * Job Matching Service
 * 
 * This service provides algorithms to match jobs with users based on:
 * - Location preferences
 * - Job category preferences
 * - Availability dates
 * - Skills
 */

const User = require('../models/user.model');
const Job = require('../models/job.model');

/**
 * Calculate match score between a user and a job
 * @param {Object} user - User document
 * @param {Object} job - Job document
 * @returns {Object} Match details with score and reasons
 */
const calculateMatchScore = (user, job) => {
    if (!user || !job) {
        return { score: 0, reasons: ['Invalid user or job data'] };
    }

    let score = 0;
    const reasons = [];
    const matchDetails = {};

    // Get student details
    const studentDetails = user.studentDetails || {};
    
    // 1. Location matching (30% weight)
    const locationScore = calculateLocationScore(studentDetails.preferredLocations || [], job.location);
    score += locationScore * 0.3;
    matchDetails.locationScore = locationScore;
    
    if (locationScore > 70) {
        reasons.push('Location matches your preferences');
    } else if (locationScore > 0) {
        reasons.push('Location is close to your preferred areas');
    }

    // 2. Job category matching (25% weight)
    const categoryScore = calculateCategoryScore(studentDetails.preferredJobs || [], job.category);
    score += categoryScore * 0.25;
    matchDetails.categoryScore = categoryScore;
    
    if (categoryScore > 70) {
        reasons.push('Job category matches your preferences');
    }

    // 3. Availability matching (25% weight)
    const availabilityScore = calculateAvailabilityScore(studentDetails.availability || [], job.availableDates || []);
    score += availabilityScore * 0.25;
    matchDetails.availabilityScore = availabilityScore;
    
    if (availabilityScore > 70) {
        reasons.push('Job dates match your availability');
    } else if (availabilityScore > 30) {
        reasons.push('Some job dates match your availability');
    }

    // 4. Skills matching (20% weight)
    const skillsScore = calculateSkillsScore(studentDetails.skills || [], job.requiredSkills || []);
    score += skillsScore * 0.2;
    matchDetails.skillsScore = skillsScore;
    
    if (skillsScore > 70) {
        reasons.push('Your skills match the job requirements');
    } else if (skillsScore > 30) {
        reasons.push('You have some of the required skills');
    }

    // Round the final score
    score = Math.round(score);

    return {
        score,
        reasons,
        details: matchDetails
    };
};

/**
 * Calculate location match score
 * @param {Array} preferredLocations - User's preferred locations
 * @param {String} jobLocation - Job location
 * @returns {Number} Score from 0-100
 */
const calculateLocationScore = (preferredLocations, jobLocation) => {
    if (!preferredLocations || !preferredLocations.length || !jobLocation) {
        return 0;
    }

    // Exact match
    if (preferredLocations.some(loc => loc.toLowerCase() === jobLocation.toLowerCase())) {
        return 100;
    }

    // Partial match (e.g., if preferred is "Colombo" and job is in "Colombo 7")
    for (const location of preferredLocations) {
        if (jobLocation.toLowerCase().includes(location.toLowerCase()) || 
            location.toLowerCase().includes(jobLocation.toLowerCase())) {
            return 70;
        }
    }

    return 0;
};

/**
 * Calculate job category match score
 * @param {Array} preferredCategories - User's preferred job categories
 * @param {String} jobCategory - Job category
 * @returns {Number} Score from 0-100
 */
const calculateCategoryScore = (preferredCategories, jobCategory) => {
    if (!preferredCategories || !preferredCategories.length || !jobCategory) {
        return 0;
    }

    // Exact match
    if (preferredCategories.some(cat => cat.toLowerCase() === jobCategory.toLowerCase())) {
        return 100;
    }

    // Partial match
    for (const category of preferredCategories) {
        if (jobCategory.toLowerCase().includes(category.toLowerCase()) || 
            category.toLowerCase().includes(jobCategory.toLowerCase())) {
            return 60;
        }
    }

    return 0;
};

/**
 * Calculate availability match score
 * @param {Array} userAvailability - User's availability dates
 * @param {Array} jobDates - Job available dates
 * @returns {Number} Score from 0-100
 */
const calculateAvailabilityScore = (userAvailability, jobDates) => {
    if (!userAvailability || !userAvailability.length || !jobDates || !jobDates.length) {
        return 0;
    }

    let totalScore = 0;
    let matchCount = 0;

    // Process each job date
    for (const jobDateEntry of jobDates) {
        const jobDate = new Date(jobDateEntry.date);
        const jobDateStr = jobDate.toISOString().split('T')[0]; // Format: YYYY-MM-DD
        const jobIsFullDay = jobDateEntry.isFullDay;
        const jobTimeSlots = jobDateEntry.timeSlots || [];
        
        // Find matching user availability date
        const matchingUserDate = userAvailability.find(userDateEntry => {
            const userDate = new Date(userDateEntry.date);
            const userDateStr = userDate.toISOString().split('T')[0];
            return userDateStr === jobDateStr;
        });

        if (matchingUserDate) {
            const userIsFullDay = matchingUserDate.isFullDay;
            const userTimeSlots = matchingUserDate.timeSlots || [];

            // Case 1: Both are full day - perfect match
            if (jobIsFullDay && userIsFullDay) {
                totalScore += 100;
                matchCount++;
                continue;
            }

            // Case 2: Job is full day, user has specific time slots
            if (jobIsFullDay && !userIsFullDay && userTimeSlots.length > 0) {
                totalScore += 80; // Good but not perfect match
                matchCount++;
                continue;
            }

            // Case 3: User is full day, job has specific time slots
            if (!jobIsFullDay && userIsFullDay && jobTimeSlots.length > 0) {
                totalScore += 90; // Very good match
                matchCount++;
                continue;
            }

            // Case 4: Both have specific time slots - check for overlaps
            if (!jobIsFullDay && !userIsFullDay && jobTimeSlots.length > 0 && userTimeSlots.length > 0) {
                let timeSlotMatches = 0;
                
                for (const jobSlot of jobTimeSlots) {
                    for (const userSlot of userTimeSlots) {
                        // Check if time slots overlap
                        if (doTimeSlotsOverlap(jobSlot, userSlot)) {
                            timeSlotMatches++;
                            break; // Found a match for this job slot
                        }
                    }
                }
                
                if (timeSlotMatches > 0) {
                    // Calculate percentage of job time slots that match
                    const slotMatchPercentage = (timeSlotMatches / jobTimeSlots.length) * 100;
                    totalScore += slotMatchPercentage;
                    matchCount++;
                }
            }
        }
    }

    // If no matches found
    if (matchCount === 0) {
        return 0;
    }

    // Calculate average score across all job dates
    return Math.min(100, totalScore / matchCount);
};

/**
 * Check if two time slots overlap
 * @param {Object} slot1 - First time slot with startTime and endTime
 * @param {Object} slot2 - Second time slot with startTime and endTime
 * @returns {Boolean} True if slots overlap
 */
const doTimeSlotsOverlap = (slot1, slot2) => {
    // Convert time strings to minutes for easier comparison
    const slot1Start = timeToMinutes(slot1.startTime);
    const slot1End = timeToMinutes(slot1.endTime);
    const slot2Start = timeToMinutes(slot2.startTime);
    const slot2End = timeToMinutes(slot2.endTime);
    
    // Check for overlap
    return (slot1Start < slot2End && slot1End > slot2Start);
};

/**
 * Convert time string (HH:MM) to minutes
 * @param {String} timeStr - Time in format HH:MM
 * @returns {Number} Time in minutes
 */
const timeToMinutes = (timeStr) => {
    const [hours, minutes] = timeStr.split(':').map(Number);
    return (hours * 60) + minutes;
};

/**
 * Calculate skills match score
 * @param {Array} userSkills - User's skills
 * @param {Array} requiredSkills - Job required skills
 * @returns {Number} Score from 0-100
 */
const calculateSkillsScore = (userSkills, requiredSkills) => {
    if (!userSkills || !userSkills.length || !requiredSkills || !requiredSkills.length) {
        return 0;
    }

    // Normalize skills (lowercase for comparison)
    const normalizedUserSkills = userSkills.map(skill => skill.toLowerCase());
    const normalizedRequiredSkills = requiredSkills.map(skill => skill.toLowerCase());

    // Count matching skills
    let matchingSkills = 0;
    for (const skill of normalizedRequiredSkills) {
        if (normalizedUserSkills.some(userSkill => 
            userSkill === skill || userSkill.includes(skill) || skill.includes(userSkill)
        )) {
            matchingSkills++;
        }
    }

    if (matchingSkills === 0) {
        return 0;
    }

    // Calculate percentage of required skills that match user skills
    const matchPercentage = (matchingSkills / normalizedRequiredSkills.length) * 100;
    return Math.min(100, matchPercentage);
};

/**
 * Find matching jobs for a user
 * @param {String} userId - User ID
 * @param {Object} options - Search options
 * @returns {Promise<Array>} Matching jobs with scores
 */
const findMatchingJobs = async (userId, options = {}) => {
    try {
        // Get user data
        const user = await User.findById(userId);
        if (!user) {
            throw new Error('User not found');
        }

        // Default options
        const defaultOptions = {
            limit: 10,
            minScore: 30,
            includeDetails: false,
            sortBy: 'score', // 'score', 'date', 'salary'
            sortOrder: 'desc' // 'asc', 'desc'
        };

        // Merge options
        const searchOptions = { ...defaultOptions, ...options };

        // Find active jobs
        const jobQuery = { status: 'active' };
        
        // Add location filter if specified
        if (options.location) {
            jobQuery.location = options.location;
        }
        
        // Add category filter if specified
        if (options.category) {
            jobQuery.category = options.category;
        }

        // Get jobs
        const jobs = await Job.find(jobQuery);

        // Calculate match scores
        const matchedJobs = jobs.map(job => {
            const matchResult = calculateMatchScore(user, job);
            return {
                job,
                score: matchResult.score,
                reasons: matchResult.reasons,
                ...(searchOptions.includeDetails && { details: matchResult.details })
            };
        });

        // Filter by minimum score
        const filteredJobs = matchedJobs.filter(item => item.score >= searchOptions.minScore);

        // Sort results
        let sortedJobs;
        if (searchOptions.sortBy === 'date') {
            sortedJobs = filteredJobs.sort((a, b) => {
                const dateA = new Date(a.job.createdAt);
                const dateB = new Date(b.job.createdAt);
                return searchOptions.sortOrder === 'desc' ? dateB - dateA : dateA - dateB;
            });
        } else if (searchOptions.sortBy === 'salary') {
            sortedJobs = filteredJobs.sort((a, b) => {
                const salaryA = a.job.salary || 0;
                const salaryB = b.job.salary || 0;
                return searchOptions.sortOrder === 'desc' ? salaryB - salaryA : salaryA - salaryB;
            });
        } else {
            // Default: sort by score
            sortedJobs = filteredJobs.sort((a, b) => {
                return searchOptions.sortOrder === 'desc' ? b.score - a.score : a.score - b.score;
            });
        }

        // Apply limit
        return sortedJobs.slice(0, searchOptions.limit);
    } catch (error) {
        console.error('Error finding matching jobs:', error);
        throw error;
    }
};

module.exports = {
    calculateMatchScore,
    findMatchingJobs
};
