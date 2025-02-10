const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
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
                userId: user._id, 
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

// Update User Role
exports.updateRole = async (req, res) => {
    try {
        const { userId, role, studentDetails, jobOwnerDetails } = req.body;
        console.log('[UpdateRole] Input:', { userId, role });

        // Validate role selection
        if (!userId || !role || !['student', 'employer'].includes(role)) {
            return res.status(400).json({ message: 'Invalid role selection' });
        }

        // Validate role-specific details
        if (role === 'student' && !studentDetails) {
            return res.status(400).json({ message: 'Student details are required' });
        }
        if (role === 'employer' && !jobOwnerDetails) {
            return res.status(400).json({ message: 'Job owner details are required' });
        }

        // Update user role and details
        const updateData = { role };
        if (role === 'student') {
            updateData.studentDetails = studentDetails;
        } else {
            updateData.jobOwnerDetails = jobOwnerDetails;
        }

        const user = await User.findByIdAndUpdate(
            userId,
            updateData,
            { new: true }
        );

        if (!user) {
            console.log('[ERROR] Update role failed: User not found');
            return res.status(404).json({ message: 'User not found' });
        }

        console.log('[UpdateRole] Successful:', { 
            userId: user._id, 
            role: user.role,
            hasStudentDetails: !!user.studentDetails,
            hasJobOwnerDetails: !!user.jobOwnerDetails
        });

        res.status(200).json({ 
            message: 'Role updated successfully',
            role: user.role
        });
    } catch (error) {
        console.error('[ERROR] Update role error:', error);
        res.status(500).json({ error: error.message });
    }
};
