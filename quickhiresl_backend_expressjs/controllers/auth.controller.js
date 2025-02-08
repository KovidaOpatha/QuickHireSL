const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/user.model');

// Register User (Email & Password)
exports.register = async (req, res) => {
    try {
        const { email, password } = req.body;
        console.log('[Register] Input received:', { email, password: '***' });

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

        // Create a new user with role as null (to be updated later)
        const user = new User({
            email,
            password: hashedPassword,
            role: null
        });

        await user.save();
        console.log('[Register] User created:', { userId: user._id, email: user.email });

        res.status(201).json({ 
            message: 'User registered successfully. Please select a role.', 
            userId: user._id 
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
            tokenGenerated: true
        });

        res.status(200).json({ 
            token, 
            userId: user._id.toString(), 
            role: user.role
        });
    } catch (error) {
        console.error('[ERROR] Login error:', error);
        res.status(500).json({ error: error.message });
    }
};

// Update User Role
exports.updateRole = async (req, res) => {
    try {
        console.log('[UpdateRole] Request received');
        console.log('[Auth] User data:', req.userData);
        
        const { userId, role, studentDetails, jobOwnerDetails } = req.body;
        console.log('[UpdateRole] Input:', { userId, role });

        // Validate role selection
        if (!role || !['student', 'employer'].includes(role)) {
            console.log('[ERROR] Invalid role:', role);
            return res.status(400).json({ message: 'Invalid role selection' });
        }

        // Build update data
        const updateData = { role };

        if (role === 'student') {
            if (!studentDetails) {
                console.log('[ERROR] Missing student details');
                return res.status(400).json({ message: 'Student details are required' });
            }
            updateData.studentDetails = studentDetails;
            console.log('[UpdateRole] Adding student details');
        } else if (role === 'employer') {
            if (!jobOwnerDetails) {
                console.log('[ERROR] Missing employer details');
                return res.status(400).json({ message: 'Employer details are required' });
            }
            updateData.jobOwnerDetails = jobOwnerDetails;
            console.log('[UpdateRole] Adding employer details');
        }

        console.log('[UpdateRole] Updating user with data:', updateData);

        const updatedUser = await User.findByIdAndUpdate(userId, updateData, { 
            new: true, 
            runValidators: true 
        });

        if (!updatedUser) {
            console.log('[ERROR] User not found:', userId);
            return res.status(404).json({ message: 'User not found' });
        }

        console.log('[UpdateRole] Success:', {
            userId: updatedUser._id,
            role: updatedUser.role
        });

        res.status(200).json({ 
            message: 'Role updated successfully', 
            user: {
                userId: updatedUser._id,
                email: updatedUser.email,
                role: updatedUser.role
            }
        });
    } catch (error) {
        console.error('[ERROR] Update role error:', error);
        res.status(500).json({ error: error.message });
    }
};
