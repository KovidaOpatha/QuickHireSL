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
            rating: user.rating || 0,
            completedJobs: user.completedJobs || 0,
            name: user.role === 'student' 
                ? user.studentDetails?.fullName 
                : user.jobOwnerDetails?.shopName
        };

        // Add role-specific details
        if (user.role === 'student' && user.studentDetails) {
            response.studentDetails = user.studentDetails;
        } else if (user.role === 'jobowner' && user.jobOwnerDetails) {
            response.jobOwnerDetails = user.jobOwnerDetails;
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
            rating: user.rating || 0,
            completedJobs: user.completedJobs || 0,
            name: user.role === 'student' 
                ? user.studentDetails?.fullName 
                : user.jobOwnerDetails?.shopName
        };

        // Add role-specific details
        if (user.role === 'student' && user.studentDetails) {
            response.fullName = user.studentDetails.fullName;
            response.address = user.studentDetails.leavingAddress;
            response.id = user.studentDetails.dateOfBirth;
            response.nic = user.studentDetails.nicNumber;
            response.studentDetails = user.studentDetails;
        } else if (user.role === 'jobowner' && user.jobOwnerDetails) {
            response.shopName = user.jobOwnerDetails.shopName;
            response.shopLocation = user.jobOwnerDetails.shopLocation;
            response.shopRegisterNo = user.jobOwnerDetails.shopRegisterNo;
            response.jobOwnerDetails = user.jobOwnerDetails;
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

        console.log('[UserController] Profile updated successfully');
        res.json({
            userId: user._id,
            email: user.email,
            role: user.role,
            profileImage: user.profileImage,
            rating: user.rating || 0,
            completedJobs: user.completedJobs || 0,
            name: user.role === 'student' 
                ? user.studentDetails?.fullName 
                : user.jobOwnerDetails?.shopName
        });
    } catch (error) {
        console.error('[UserController] Update error:', error);
        res.status(500).json({ message: 'Error updating user profile' });
    }
};
