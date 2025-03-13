const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const User = require('../models/user.model');
const fs = require('fs');
const path = require('path');

// Helper function to save base64 image
const saveBase64Image = async (base64String) => {
    try {
        // Remove header from base64 string if present
        const base64Data = base64String.replace(/^data:image\/\w+;base64,/, '');
        
        // Create buffer from base64
        const imageBuffer = Buffer.from(base64Data, 'base64');
        
        // Generate unique filename
        const filename = `profile-${Date.now()}-${Math.round(Math.random() * 1E9)}.jpg`;
        const filepath = path.join(__dirname, '../public/uploads/profiles', filename);
        
        // Save file
        await fs.promises.writeFile(filepath, imageBuffer);
        
        // Return relative path
        return `/uploads/profiles/${filename}`;
    } catch (error) {
        console.error('[ERROR] Failed to save image:', error);
        return null;
    }
};

// Register User (Email & Password)
exports.register = async (req, res) => {
    try {
        const { email, password, profileImage } = req.body;
        console.log('[Register] Input received:', { email, password: '***', hasImage: !!profileImage });

        // Validate email and password input
        if (!email || !password) {
            return res.status(400).json({ message: 'Email and password are required' });
        }

        // Check if email already exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ message: 'Email already registered' });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Save profile image if provided
        let imageUrl = null;
        if (profileImage) {
            imageUrl = await saveBase64Image(profileImage);
            console.log('[Register] Profile image saved:', imageUrl);
        }

        // Create a new user with role as null (to be updated later)
        const user = new User({
            email,
            password: hashedPassword,
            role: null,
            profileImage: imageUrl
        });

        await user.save();
        console.log('[Register] User created:', { 
            userId: user._id, 
            email: user.email,
            hasProfileImage: !!imageUrl 
        });

        res.status(201).json({ 
            message: 'User registered successfully. Please select a role.', 
            userId: user._id,
            profileImage: imageUrl
        });
    } catch (error) {
        console.error('[ERROR] Registration error:', error);
        res.status(500).json({ error: error.message });
    }
};

// Login User
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;
        console.log('[Login] Attempt for:', email);

        const user = await User.findOne({ email });
        if (!user) {
            console.log('[ERROR] Login failed: User not found');
            return res.status(401).json({ message: 'Authentication failed' });
        }

        const isValidPassword = await bcrypt.compare(password, user.password);
        if (!isValidPassword) {
            console.log('[ERROR] Login failed: Invalid password');
            return res.status(401).json({ message: 'Authentication failed' });
        }

        // Generate token with user data
        const token = jwt.sign(
            { 
                _id: user._id, 
                email: user.email, 
                role: user.role 
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        console.log('[Login] Successful:', { 
            userId: user._id, 
            email: user.email, 
            role: user.role,
            hasProfileImage: !!user.profileImage,
            tokenGenerated: true
        });

        res.status(200).json({ 
            token, 
            userId: user._id.toString(), 
            role: user.role,
            profileImage: user.profileImage
        });
    } catch (error) {
        console.error('[ERROR] Login error:', error);
        res.status(500).json({ error: error.message });
    }
};

// Change Password
exports.changePassword = async (req, res) => {
    try {
        const userId = req.userId;
        const { currentPassword, newPassword } = req.body;
        console.log('[ChangePassword] Attempt for user:', userId);

        if (!currentPassword || !newPassword) {
            return res.status(400).json({ message: 'Current password and new password are required' });
        }

        const user = await User.findById(userId);
        if (!user) {
            console.log('[ERROR] Change password failed: User not found');
            return res.status(404).json({ message: 'User not found' });
        }

        const isValidPassword = await bcrypt.compare(currentPassword, user.password);
        if (!isValidPassword) {
            console.log('[ERROR] Change password failed: Incorrect current password');
            return res.status(401).json({ message: 'Current password is incorrect' });
        }

        user.password = await bcrypt.hash(newPassword, 10);
        await user.save();
        
        console.log('[ChangePassword] Successful for user:', userId);
        res.status(200).json({ message: 'Password changed successfully' });
    } catch (error) {
        console.error('[ERROR] Change password error:', error);
        res.status(500).json({ error: error.message });
    }
};

// Reset Password
exports.resetPassword = async (req, res) => {
    try {
        const { email, newPassword } = req.body;
        console.log('[ResetPassword] Attempt for email:', email);

        if (!email || !newPassword) {
            return res.status(400).json({ message: 'Email and new password are required' });
        }

        const user = await User.findOne({ email });
        if (!user) {
            console.log('[ERROR] Reset password failed: User not found');
            return res.status(404).json({ message: 'User not found' });
        }

        user.password = await bcrypt.hash(newPassword, 10);
        await user.save();
        
        console.log('[ResetPassword] Successful for email:', email);
        res.status(200).json({ message: 'Password reset successfully' });
    } catch (error) {
        console.error('[ERROR] Reset password error:', error);
        res.status(500).json({ error: error.message });
    }
};

// Update User Role
exports.updateRole = async (req, res) => {
    try {
        const { userId } = req.params;
        const { role } = req.body;
        console.log('[UpdateRole] Input:', { userId, role });
        console.log('[UpdateRole] Request body:', JSON.stringify(req.body, null, 2));

        // Validate role selection
        if (!role || !['student', 'jobowner'].includes(role)) {
            return res.status(400).json({ message: 'Invalid role selection' });
        }

        // Initialize update data with role
        const updateData = { role };
        
        // Handle student details
        if (role === 'student') {
            if (!req.body.studentDetails) {
                return res.status(400).json({ message: 'Student details are required' });
            }
            
            const { fullName, leavingAddress, dateOfBirth, mobileNumber, nicNumber } = req.body.studentDetails;
            
            // Validate required student fields
            if (!fullName || !leavingAddress || !dateOfBirth || !mobileNumber || !nicNumber) {
                return res.status(400).json({ 
                    message: 'All student details are required',
                    missingFields: [
                        !fullName ? 'fullName' : null,
                        !leavingAddress ? 'leavingAddress' : null,
                        !dateOfBirth ? 'dateOfBirth' : null,
                        !mobileNumber ? 'mobileNumber' : null,
                        !nicNumber ? 'nicNumber' : null
                    ].filter(Boolean)
                });
            }
            
            updateData.studentDetails = req.body.studentDetails;
            console.log('[UpdateRole] Student details received:', JSON.stringify(req.body.studentDetails, null, 2));
        } 
        // Handle job owner details
        else if (role === 'jobowner') {
            if (!req.body.jobOwnerDetails) {
                return res.status(400).json({ message: 'Job owner details are required' });
            }
            
            const { shopName, shopLocation, shopRegisterNo } = req.body.jobOwnerDetails;
            
            // Validate required job owner fields
            if (!shopName || !shopLocation || !shopRegisterNo) {
                return res.status(400).json({ 
                    message: 'All job owner details are required',
                    missingFields: [
                        !shopName ? 'shopName' : null,
                        !shopLocation ? 'shopLocation' : null,
                        !shopRegisterNo ? 'shopRegisterNo' : null
                    ].filter(Boolean)
                });
            }
            
            updateData.jobOwnerDetails = req.body.jobOwnerDetails;
            console.log('[UpdateRole] Job owner details received:', JSON.stringify(req.body.jobOwnerDetails, null, 2));
        }

        console.log('[UpdateRole] Final update data:', JSON.stringify(updateData, null, 2));

        // Update user role with transaction-like approach
        const session = await mongoose.startSession();
        session.startTransaction();

        try {
            // Update user role
            const user = await User.findByIdAndUpdate(
                userId,
                updateData,
                { new: true, session }
            );

            if (!user) {
                await session.abortTransaction();
                session.endSession();
                console.log('[ERROR] Update role failed: User not found');
                return res.status(404).json({ message: 'User not found' });
            }

            // Verify the update was successful
            const verifiedUser = await User.findById(userId).session(session);
            
            // Check if role-specific details were saved correctly
            let detailsSavedCorrectly = true;
            let missingDetails = [];
            
            if (role === 'student' && (!verifiedUser.studentDetails || Object.keys(verifiedUser.studentDetails).length === 0)) {
                detailsSavedCorrectly = false;
                missingDetails.push('studentDetails');
            } else if (role === 'jobowner' && (!verifiedUser.jobOwnerDetails || Object.keys(verifiedUser.jobOwnerDetails).length === 0)) {
                detailsSavedCorrectly = false;
                missingDetails.push('jobOwnerDetails');
            }
            
            if (!detailsSavedCorrectly) {
                await session.abortTransaction();
                session.endSession();
                console.log('[ERROR] Role details not saved correctly:', missingDetails);
                return res.status(500).json({ 
                    message: 'Failed to save role details', 
                    missingDetails 
                });
            }

            await session.commitTransaction();
            session.endSession();

            console.log('[UpdateRole] Successful:', { 
                userId: user._id, 
                role: user.role,
                hasStudentDetails: !!user.studentDetails,
                hasJobOwnerDetails: !!user.jobOwnerDetails,
                studentDetails: user.studentDetails,
                jobOwnerDetails: user.jobOwnerDetails
            });

            res.status(200).json({ 
                message: 'Role updated successfully',
                role: user.role,
                detailsSaved: true
            });
        } catch (error) {
            await session.abortTransaction();
            session.endSession();
            throw error;
        }
    } catch (error) {
        console.error('[ERROR] Update role error:', error);
        res.status(500).json({ error: error.message });
    }
};

// Verify user data was saved correctly
exports.verifyUserData = async (req, res) => {
    try {
        const { userId } = req.params;
        console.log('[VerifyUserData] Verifying data for user:', userId);

        const user = await User.findById(userId).select('-password');
        
        if (!user) {
            console.log('[VerifyUserData] User not found:', userId);
            return res.status(404).json({ message: 'User not found' });
        }

        // Check if role is set
        if (!user.role) {
            console.log('[VerifyUserData] Role not set for user:', userId);
            return res.status(400).json({ 
                verified: false, 
                message: 'User role not set',
                missingFields: ['role']
            });
        }

        // Check role-specific details
        let verified = true;
        let missingFields = [];

        if (user.role === 'student') {
            if (!user.studentDetails) {
                verified = false;
                missingFields.push('studentDetails');
            } else {
                const { fullName, leavingAddress, dateOfBirth, mobileNumber, nicNumber } = user.studentDetails;
                if (!fullName) missingFields.push('studentDetails.fullName');
                if (!leavingAddress) missingFields.push('studentDetails.leavingAddress');
                if (!dateOfBirth) missingFields.push('studentDetails.dateOfBirth');
                if (!mobileNumber) missingFields.push('studentDetails.mobileNumber');
                if (!nicNumber) missingFields.push('studentDetails.nicNumber');
                
                if (missingFields.length > 0) verified = false;
            }
        } else if (user.role === 'jobowner') {
            if (!user.jobOwnerDetails) {
                verified = false;
                missingFields.push('jobOwnerDetails');
            } else {
                const { shopName, shopLocation, shopRegisterNo } = user.jobOwnerDetails;
                if (!shopName) missingFields.push('jobOwnerDetails.shopName');
                if (!shopLocation) missingFields.push('jobOwnerDetails.shopLocation');
                if (!shopRegisterNo) missingFields.push('jobOwnerDetails.shopRegisterNo');
                
                if (missingFields.length > 0) verified = false;
            }
        }

        console.log('[VerifyUserData] Verification result:', { verified, missingFields });

        res.status(200).json({
            verified,
            role: user.role,
            missingFields: missingFields.length > 0 ? missingFields : undefined,
            message: verified ? 'User data verified successfully' : 'User data verification failed'
        });
    } catch (error) {
        console.error('[ERROR] Verify user data error:', error);
        res.status(500).json({ error: error.message });
    }
};

// const jwt = require('jsonwebtoken');
// const bcrypt = require('bcryptjs');
// const mongoose = require('mongoose');
// const User = require('../models/user.model');
// const fs = require('fs');
// const path = require('path');

// // Helper function to save base64 image
// const saveBase64Image = async (base64String) => {
//     try {
//         // Remove header from base64 string if present
//         const base64Data = base64String.replace(/^data:image\/\w+;base64,/, '');
        
//         // Create buffer from base64
//         const imageBuffer = Buffer.from(base64Data, 'base64');
        
//         // Generate unique filename
//         const filename = `profile-${Date.now()}-${Math.round(Math.random() * 1E9)}.jpg`;
//         const filepath = path.join(__dirname, '../public/uploads/profiles', filename);
        
//         // Save file
//         await fs.promises.writeFile(filepath, imageBuffer);
        
//         // Return relative path
//         return `/uploads/profiles/${filename}`;
//     } catch (error) {
//         console.error('[ERROR] Failed to save image:', error);
//         return null;
//     }
// };

// // Register User (Email & Password)
// exports.register = async (req, res) => {
//     try {
//         const { email, password, profileImage } = req.body;
//         console.log('[Register] Input received:', { email, password: '***', hasImage: !!profileImage });

//         // Validate email and password input
//         if (!email || !password) {
//             return res.status(400).json({ message: 'Email and password are required' });
//         }

//         // Check if email already exists
//         const existingUser = await User.findOne({ email });
//         if (existingUser) {
//             return res.status(400).json({ message: 'Email already registered' });
//         }

//         // Hash password
//         const hashedPassword = await bcrypt.hash(password, 10);

//         // Save profile image if provided
//         let imageUrl = null;
//         if (profileImage) {
//             imageUrl = await saveBase64Image(profileImage);
//             console.log('[Register] Profile image saved:', imageUrl);
//         }

//         // Create a new user with role as null (to be updated later)
//         const user = new User({
//             email,
//             password: hashedPassword,
//             role: null,
//             profileImage: imageUrl
//         });

//         await user.save();
//         console.log('[Register] User created:', { 
//             userId: user._id, 
//             email: user.email,
//             hasProfileImage: !!imageUrl 
//         });

//         res.status(201).json({ 
//             message: 'User registered successfully. Please select a role.', 
//             userId: user._id,
//             profileImage: imageUrl
//         });
//     } catch (error) {
//         console.error('[ERROR] Registration error:', error);
//         res.status(500).json({ error: error.message });
//     }
// };

// // Login User
// exports.login = async (req, res) => {
//     try {
//         const { email, password } = req.body;
//         console.log('[Login] Attempt for:', email);

//         const user = await User.findOne({ email });
//         if (!user) {
//             console.log('[ERROR] Login failed: User not found');
//             return res.status(401).json({ message: 'Authentication failed' });
//         }

//         const isValidPassword = await bcrypt.compare(password, user.password);
//         if (!isValidPassword) {
//             console.log('[ERROR] Login failed: Invalid password');
//             return res.status(401).json({ message: 'Authentication failed' });
//         }

//         // Generate token with user data
//         const token = jwt.sign(
//             { 
//                 _id: user._id, 
//                 email: user.email, 
//                 role: user.role 
//             },
//             process.env.JWT_SECRET,
//             { expiresIn: '24h' }
//         );

//         console.log('[Login] Successful:', { 
//             userId: user._id, 
//             email: user.email, 
//             role: user.role,
//             hasProfileImage: !!user.profileImage,
//             tokenGenerated: true
//         });

//         res.status(200).json({ 
//             token, 
//             userId: user._id.toString(), 
//             role: user.role,
//             profileImage: user.profileImage
//         });
//     } catch (error) {
//         console.error('[ERROR] Login error:', error);
//         res.status(500).json({ error: error.message });
//     }
// };

// // Update User Role
// exports.updateRole = async (req, res) => {
//     try {
//         const { userId } = req.params;
//         const { role } = req.body;
//         console.log('[UpdateRole] Input:', { userId, role });
//         console.log('[UpdateRole] Request body:', JSON.stringify(req.body, null, 2));

//         // Validate role selection
//         if (!role || !['student', 'jobowner'].includes(role)) {
//             return res.status(400).json({ message: 'Invalid role selection' });
//         }

//         // Initialize update data with role
//         const updateData = { role };
        
//         // Handle student details
//         if (role === 'student') {
//             if (!req.body.studentDetails) {
//                 return res.status(400).json({ message: 'Student details are required' });
//             }
            
//             const { fullName, leavingAddress, dateOfBirth, mobileNumber, nicNumber } = req.body.studentDetails;
            
//             // Validate required student fields
//             if (!fullName || !leavingAddress || !dateOfBirth || !mobileNumber || !nicNumber) {
//                 return res.status(400).json({ 
//                     message: 'All student details are required',
//                     missingFields: [
//                         !fullName ? 'fullName' : null,
//                         !leavingAddress ? 'leavingAddress' : null,
//                         !dateOfBirth ? 'dateOfBirth' : null,
//                         !mobileNumber ? 'mobileNumber' : null,
//                         !nicNumber ? 'nicNumber' : null
//                     ].filter(Boolean)
//                 });
//             }
            
//             updateData.studentDetails = req.body.studentDetails;
//             console.log('[UpdateRole] Student details received:', JSON.stringify(req.body.studentDetails, null, 2));
//         } 
//         // Handle job owner details
//         else if (role === 'jobowner') {
//             if (!req.body.jobOwnerDetails) {
//                 return res.status(400).json({ message: 'Job owner details are required' });
//             }
            
//             const { shopName, shopLocation, shopRegisterNo } = req.body.jobOwnerDetails;
            
//             // Validate required job owner fields
//             if (!shopName || !shopLocation || !shopRegisterNo) {
//                 return res.status(400).json({ 
//                     message: 'All job owner details are required',
//                     missingFields: [
//                         !shopName ? 'shopName' : null,
//                         !shopLocation ? 'shopLocation' : null,
//                         !shopRegisterNo ? 'shopRegisterNo' : null
//                     ].filter(Boolean)
//                 });
//             }
            
//             updateData.jobOwnerDetails = req.body.jobOwnerDetails;
//             console.log('[UpdateRole] Job owner details received:', JSON.stringify(req.body.jobOwnerDetails, null, 2));
//         }

//         console.log('[UpdateRole] Final update data:', JSON.stringify(updateData, null, 2));

//         // Update user role with transaction-like approach
//         const session = await mongoose.startSession();
//         session.startTransaction();

//         try {
//             // Update user role
//             const user = await User.findByIdAndUpdate(
//                 userId,
//                 updateData,
//                 { new: true, session }
//             );

//             if (!user) {
//                 await session.abortTransaction();
//                 session.endSession();
//                 console.log('[ERROR] Update role failed: User not found');
//                 return res.status(404).json({ message: 'User not found' });
//             }

//             // Verify the update was successful
//             const verifiedUser = await User.findById(userId).session(session);
            
//             // Check if role-specific details were saved correctly
//             let detailsSavedCorrectly = true;
//             let missingDetails = [];
            
//             if (role === 'student' && (!verifiedUser.studentDetails || Object.keys(verifiedUser.studentDetails).length === 0)) {
//                 detailsSavedCorrectly = false;
//                 missingDetails.push('studentDetails');
//             } else if (role === 'jobowner' && (!verifiedUser.jobOwnerDetails || Object.keys(verifiedUser.jobOwnerDetails).length === 0)) {
//                 detailsSavedCorrectly = false;
//                 missingDetails.push('jobOwnerDetails');
//             }
            
//             if (!detailsSavedCorrectly) {
//                 await session.abortTransaction();
//                 session.endSession();
//                 console.log('[ERROR] Role details not saved correctly:', missingDetails);
//                 return res.status(500).json({ 
//                     message: 'Failed to save role details', 
//                     missingDetails 
//                 });
//             }

//             await session.commitTransaction();
//             session.endSession();

//             console.log('[UpdateRole] Successful:', { 
//                 userId: user._id, 
//                 role: user.role,
//                 hasStudentDetails: !!user.studentDetails,
//                 hasJobOwnerDetails: !!user.jobOwnerDetails,
//                 studentDetails: user.studentDetails,
//                 jobOwnerDetails: user.jobOwnerDetails
//             });

//             res.status(200).json({ 
//                 message: 'Role updated successfully',
//                 role: user.role,
//                 detailsSaved: true
//             });
//         } catch (error) {
//             await session.abortTransaction();
//             session.endSession();
//             throw error;
//         }
//     } catch (error) {
//         console.error('[ERROR] Update role error:', error);
//         res.status(500).json({ error: error.message });
//     }
// };

// // Verify user data was saved correctly
// exports.verifyUserData = async (req, res) => {
//     try {
//         const { userId } = req.params;
//         console.log('[VerifyUserData] Verifying data for user:', userId);

//         const user = await User.findById(userId).select('-password');
        
//         if (!user) {
//             console.log('[VerifyUserData] User not found:', userId);
//             return res.status(404).json({ message: 'User not found' });
//         }

//         // Check if role is set
//         if (!user.role) {
//             console.log('[VerifyUserData] Role not set for user:', userId);
//             return res.status(400).json({ 
//                 verified: false, 
//                 message: 'User role not set',
//                 missingFields: ['role']
//             });
//         }

//         // Check role-specific details
//         let verified = true;
//         let missingFields = [];

//         if (user.role === 'student') {
//             if (!user.studentDetails) {
//                 verified = false;
//                 missingFields.push('studentDetails');
//             } else {
//                 const { fullName, leavingAddress, dateOfBirth, mobileNumber, nicNumber } = user.studentDetails;
//                 if (!fullName) missingFields.push('studentDetails.fullName');
//                 if (!leavingAddress) missingFields.push('studentDetails.leavingAddress');
//                 if (!dateOfBirth) missingFields.push('studentDetails.dateOfBirth');
//                 if (!mobileNumber) missingFields.push('studentDetails.mobileNumber');
//                 if (!nicNumber) missingFields.push('studentDetails.nicNumber');
                
//                 if (missingFields.length > 0) verified = false;
//             }
//         } else if (user.role === 'jobowner') {
//             if (!user.jobOwnerDetails) {
//                 verified = false;
//                 missingFields.push('jobOwnerDetails');
//             } else {
//                 const { shopName, shopLocation, shopRegisterNo } = user.jobOwnerDetails;
//                 if (!shopName) missingFields.push('jobOwnerDetails.shopName');
//                 if (!shopLocation) missingFields.push('jobOwnerDetails.shopLocation');
//                 if (!shopRegisterNo) missingFields.push('jobOwnerDetails.shopRegisterNo');
                
//                 if (missingFields.length > 0) verified = false;
//             }
//         }

//         console.log('[VerifyUserData] Verification result:', { verified, missingFields });

//         res.status(200).json({
//             verified,
//             role: user.role,
//             missingFields: missingFields.length > 0 ? missingFields : undefined,
//             message: verified ? 'User data verified successfully' : 'User data verification failed'
//         });
//     } catch (error) {
//         console.error('[ERROR] Verify user data error:', error);
//         res.status(500).json({ error: error.message });
//     }
// };
