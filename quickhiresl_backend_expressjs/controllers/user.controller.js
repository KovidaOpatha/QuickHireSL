const User = require('../models/user.model');

// Get user profile
exports.getUserProfile = async (req, res) => {
    try {
        const userId = req.params.userId;
        console.log('[UserController] Fetching profile for user:', userId);

        const user = await User.findById(userId).select('-password');
        
        if (!user) {
            console.log('[UserController] User not found:', userId);
            return res.status(404).json({ message: 'User not found' });
        }

        // Format the response based on user role
        const response = {
            userId: user._id,
            email: user.email,
            role: user.role,
            profileImage: user.profileImage,
            bio: user.bio || '',
            rating: user.rating || 0,
            completedJobs: user.completedJobs || 0,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
            name: user.role === 'student' 
                ? user.studentDetails?.fullName 
                : user.jobOwnerDetails?.shopName
        };

        // Add role-specific details
        if (user.role === 'student') {
            response.studentDetails = user.studentDetails || {};
        } else if (user.role === 'jobowner') {
            response.jobOwnerDetails = user.jobOwnerDetails || {};
        }

        console.log('[UserController] Profile data:', response);
        res.json(response);
    } catch (error) {
        console.error('[UserController] Error:', error);
        res.status(500).json({ message: 'Error fetching user profile' });
    }
};

// Get user by email or ID
exports.getUserByEmail = async (req, res) => {
    try {
        const emailOrId = req.params.email;
        console.log('[UserController] Fetching user by email or ID:', emailOrId);

        // Check if the parameter is an ObjectId or email
        let user;
        if (emailOrId.match(/^[0-9a-fA-F]{24}$/)) {
            // It's likely an ObjectId
            user = await User.findById(emailOrId).select('-password');
        } else {
            // It's likely an email
            user = await User.findOne({ email: emailOrId }).select('-password');
        }
        
        if (!user) {
            console.log('[UserController] User not found with email/ID:', emailOrId);
            return res.status(404).json({ message: 'User not found' });
        }

        // Format the response based on user role
        const response = {
            userId: user._id,
            email: user.email,
            role: user.role,
            profileImage: user.profileImage,
            bio: user.bio || '',
            rating: user.rating || 0,
            completedJobs: user.completedJobs || 0,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
            name: user.role === 'student' 
                ? user.studentDetails?.fullName 
                : user.jobOwnerDetails?.shopName
        };

        // Add role-specific details
        if (user.role === 'student') {
            response.studentDetails = user.studentDetails || {};
        } else if (user.role === 'jobowner') {
            response.jobOwnerDetails = user.jobOwnerDetails || {};
        }

        console.log('[UserController] User data by email/ID:', response);
        res.json(response);
    } catch (error) {
        console.error('[UserController] Error fetching user by email/ID:', error);
        res.status(500).json({ message: 'Error fetching user data' });
    }
};

// Update user profile
exports.updateUserProfile = async (req, res) => {
    try {
        const userId = req.params.userId;
        const updates = req.body;
        console.log('[UserController] Updating profile for user:', userId);
        console.log('[UserController] Update data:', updates);

        // Remove sensitive fields that shouldn't be updated directly
        delete updates.password;
        delete updates.email;
        delete updates.role;

        const user = await User.findByIdAndUpdate(
            userId,
            { $set: updates },
            { new: true }
        ).select('-password');

        if (!user) {
            console.log('[UserController] User not found for update:', userId);
            return res.status(404).json({ message: 'User not found' });
        }

        // Format the response based on user role
        const response = {
            userId: user._id,
            email: user.email,
            role: user.role,
            profileImage: user.profileImage,
            bio: user.bio || '',
            rating: user.rating || 0,
            completedJobs: user.completedJobs || 0,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
            name: user.role === 'student' 
                ? user.studentDetails?.fullName 
                : user.jobOwnerDetails?.shopName
        };

        // Add role-specific details
        if (user.role === 'student') {
            response.studentDetails = user.studentDetails || {};
        } else if (user.role === 'jobowner') {
            response.jobOwnerDetails = user.jobOwnerDetails || {};
        }

        console.log('[UserController] Profile updated successfully');
        res.json(response);
    } catch (error) {
        console.error('[UserController] Update error:', error);
        res.status(500).json({ message: 'Error updating user profile' });
    }
};

// Update user preferences
exports.updateUserPreferences = async (req, res) => {
    try {
        const userId = req.params.userId;
        const { preferredLocations, preferredJobs } = req.body;
        console.log('[UserController] Updating preferences for user:', userId);
        console.log('[UserController] Preferred locations:', preferredLocations);
        console.log('[UserController] Preferred jobs:', preferredJobs);

        // Validate the request
        if (!preferredLocations || !Array.isArray(preferredLocations)) {
            return res.status(400).json({ 
                message: 'Invalid request format. preferredLocations must be an array.' 
            });
        }

        // Find the user
        const user = await User.findById(userId);
        if (!user) {
            console.log('[UserController] User not found for preference update:', userId);
            return res.status(404).json({ message: 'User not found' });
        }

        // Ensure studentDetails exists
        if (!user.studentDetails) {
            user.studentDetails = {};
        }

        // Update the preferred locations
        user.studentDetails.preferredLocations = preferredLocations;
        
        // Update preferred jobs if provided
        if (preferredJobs && Array.isArray(preferredJobs)) {
            user.studentDetails.preferredJobs = preferredJobs;
            console.log('[UserController] Updated preferred jobs:', preferredJobs);
        }

        // Save the updated user
        await user.save();

        console.log('[UserController] User preferences updated successfully');
        res.status(200).json({ 
            message: 'Preferences updated successfully',
            preferredLocations: user.studentDetails.preferredLocations,
            preferredJobs: user.studentDetails.preferredJobs
        });
    } catch (error) {
        console.error('[UserController] Error updating preferences:', error);
        res.status(500).json({ 
            message: 'Error updating user preferences',
            error: error.message
        });
    }
};

// Update user availability
exports.updateUserAvailability = async (req, res) => {
    try {
        const userId = req.params.userId;
        const { availability } = req.body;
        console.log('[UserController] Updating availability for user:', userId);
        console.log('[UserController] Availability data:', availability);

        // Validate the request
        if (!availability || !Array.isArray(availability)) {
            return res.status(400).json({ 
                message: 'Invalid request format. Availability must be an array.' 
            });
        }

        // Validate each availability entry
        for (const entry of availability) {
            if (!entry.date) {
                return res.status(400).json({
                    message: 'Each availability entry must have a date.'
                });
            }
            
            // If timeSlots are provided, validate them
            if (entry.timeSlots && Array.isArray(entry.timeSlots)) {
                for (const slot of entry.timeSlots) {
                    if (!slot.startTime || !slot.endTime) {
                        return res.status(400).json({
                            message: 'Each time slot must have startTime and endTime.'
                        });
                    }
                }
            }
        }

        // Find the user
        const user = await User.findById(userId);
        if (!user) {
            console.log('[UserController] User not found for availability update:', userId);
            return res.status(404).json({ message: 'User not found' });
        }

        // Ensure studentDetails exists
        if (!user.studentDetails) {
            user.studentDetails = {};
        }

        // Update the availability
        user.studentDetails.availability = availability;

        // Save the updated user
        await user.save();

        console.log('[UserController] User availability updated successfully');
        res.status(200).json({ 
            message: 'Availability updated successfully',
            availability: user.studentDetails.availability
        });
    } catch (error) {
        console.error('[UserController] Error updating availability:', error);
        res.status(500).json({ 
            message: 'Error updating user availability',
            error: error.message
        });
    }
};

// Add a new availability date for a user
exports.addAvailabilityDate = async (req, res) => {
    try {
        const userId = req.params.userId;
        const newAvailability = req.body;
        console.log('[UserController] Adding availability date for user:', userId);
        console.log('[UserController] New availability data:', newAvailability);

        // Validate the request
        if (!newAvailability.date) {
            return res.status(400).json({ 
                message: 'Invalid request format. Date is required.' 
            });
        }
        
        // Validate time slots if provided
        if (newAvailability.timeSlots && Array.isArray(newAvailability.timeSlots)) {
            for (const slot of newAvailability.timeSlots) {
                if (!slot.startTime || !slot.endTime) {
                    return res.status(400).json({
                        message: 'Each time slot must have startTime and endTime.'
                    });
                }
            }
        }

        // Find the user
        const user = await User.findById(userId);
        if (!user) {
            console.log('[UserController] User not found for availability update:', userId);
            return res.status(404).json({ message: 'User not found' });
        }

        // Ensure studentDetails and availability array exist
        if (!user.studentDetails) {
            user.studentDetails = {};
        }
        if (!user.studentDetails.availability) {
            user.studentDetails.availability = [];
        }

        // Check if the date already exists
        const dateExists = user.studentDetails.availability.some(
            item => new Date(item.date).toDateString() === new Date(newAvailability.date).toDateString()
        );

        if (dateExists) {
            return res.status(400).json({ 
                message: 'This date is already in your availability list. Please update it instead.' 
            });
        }

        // Add the new availability
        user.studentDetails.availability.push({
            date: new Date(newAvailability.date),
            timeSlots: newAvailability.timeSlots || [],
            isFullDay: newAvailability.isFullDay || false,
            createdAt: new Date()
        });

        // Save the updated user
        await user.save();

        console.log('[UserController] User availability date added successfully');
        res.status(200).json({ 
            message: 'Availability date added successfully',
            availability: user.studentDetails.availability
        });
    } catch (error) {
        console.error('[UserController] Error adding availability date:', error);
        res.status(500).json({ 
            message: 'Error adding availability date',
            error: error.message
        });
    }
};

// Remove an availability date for a user
exports.removeAvailabilityDate = async (req, res) => {
    try {
        const userId = req.params.userId;
        const { dateId } = req.params;
        console.log('[UserController] Removing availability date for user:', userId);
        console.log('[UserController] Date ID to remove:', dateId);

        // Find the user
        const user = await User.findById(userId);
        if (!user) {
            console.log('[UserController] User not found for availability update:', userId);
            return res.status(404).json({ message: 'User not found' });
        }

        // Ensure studentDetails and availability array exist
        if (!user.studentDetails || !user.studentDetails.availability) {
            return res.status(404).json({ message: 'No availability data found for this user' });
        }

        // Find the index of the date to remove
        const dateIndex = user.studentDetails.availability.findIndex(
            item => item._id.toString() === dateId
        );

        if (dateIndex === -1) {
            return res.status(404).json({ message: 'Availability date not found' });
        }

        // Remove the date
        user.studentDetails.availability.splice(dateIndex, 1);

        // Save the updated user
        await user.save();

        console.log('[UserController] User availability date removed successfully');
        res.status(200).json({ 
            message: 'Availability date removed successfully',
            availability: user.studentDetails.availability
        });
    } catch (error) {
        console.error('[UserController] Error removing availability date:', error);
        res.status(500).json({ 
            message: 'Error removing availability date',
            error: error.message
        });
    }
};
