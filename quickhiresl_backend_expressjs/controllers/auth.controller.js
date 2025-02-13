// const jwt = require('jsonwebtoken');
// const bcrypt = require('bcryptjs');
// const User = require('../models/user.model');

// // 🟢 Register User (Only Email & Password)
// exports.register = async (req, res) => {
//     try {
//         const { email, password } = req.body;

//         // Check if email already exists
//         const existingUser = await User.findOne({ email });
//         if (existingUser) {
//             return res.status(400).json({ message: 'Email already registered' });
//         }

//         // Hash password
//         const hashedPassword = await bcrypt.hash(password, 10);
        
//         const user = new User({
//             email,
//             password: hashedPassword,
//             role: null // Role will be chosen later
//         });

//         await user.save();

//         res.status(201).json({ 
//             message: 'User registered successfully. Please select a role.', 
//             userId: user._id 
//         });
//     } catch (error) {
//         res.status(500).json({ error: error.message });
//     }
// };

// // 🟢 Update User Role (After Registration)
// exports.updateRole = async (req, res) => {
//     try {
//         const { userId, role, studentDetails, jobOwnerDetails } = req.body;

//         console.log("🛠 Updating user role:", userId, role); // Debugging

//         if (!role || !['student', 'employer'].includes(role)) {
//             return res.status(400).json({ message: 'Invalid role selection' });
//         }

//         const updateData = { role };

//         if (role === 'student' && studentDetails) {
//             updateData.studentDetails = studentDetails;
//         } else if (role === 'employer' && jobOwnerDetails) {
//             updateData.jobOwnerDetails = jobOwnerDetails;
//         }

//         // 🔹 Fix: Use `{ new: true, runValidators: true }` to force update & return new user
//         const updatedUser = await User.findByIdAndUpdate(userId, updateData, { 
//             new: true, 
//             runValidators: true 
//         });

//         if (!updatedUser) {
//             return res.status(404).json({ message: 'User not found' });
//         }

//         console.log("✅ User updated successfully:", updatedUser); // Debugging

//         res.status(200).json({ 
//             message: 'Role updated successfully', 
//             user: updatedUser 
//         });
//     } catch (error) {
//         console.error("❌ Error updating role:", error);
//         res.status(500).json({ error: error.message });
//     }
// };

// // 🟢 Login User
// exports.login = async (req, res) => {
//     try {
//         const { email, password } = req.body;
//         const user = await User.findOne({ email });

//         if (!user) {
//             return res.status(401).json({ message: 'Authentication failed' });
//         }

//         const isValidPassword = await bcrypt.compare(password, user.password);
//         if (!isValidPassword) {
//             return res.status(401).json({ message: 'Authentication failed' });
//         }

//         const token = jwt.sign(
//             { userId: user._id, email: user.email, role: user.role },
//             process.env.JWT_SECRET,
//             { expiresIn: '24h' }
//         );

//         res.status(200).json({ 
//             token, 
//             userId: user._id, 
//             role: user.role,
//             user 
//         });
//     } catch (error) {
//         res.status(500).json({ error: error.message });
//     }
// };












// const jwt = require('jsonwebtoken');
// const bcrypt = require('bcryptjs');
// const User = require('../models/user.model');

// // 🟢 Register User (Only Email & Password)
// exports.register = async (req, res) => {
//     try {
//         const { email, password } = req.body;
//         console.log('Register input:', req.body);

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

//         // Create a new user with role as null (to be updated later)
//         const user = new User({
//             email,
//             password: hashedPassword,
//             role: null
//         });

//         await user.save();
//         console.log('User registered:', user);

//         res.status(201).json({ 
//             message: 'User registered successfully. Please select a role.', 
//             userId: user._id 
//         });
//     } catch (error) {
//         console.error('Register error:', error);
//         res.status(500).json({ error: error.message });
//     }
// };

// // 🟢 Update User Role (After Registration)
// exports.updateRole = async (req, res) => {
//     try {
//         // Log complete request body for debugging
//         console.log('UpdateRole input:', req.body);
        
//         const { userId, role, studentDetails, jobOwnerDetails } = req.body;

//         // Validate role selection
//         if (!role || !['student', 'employer'].includes(role)) {
//             return res.status(400).json({ message: 'Invalid role selection' });
//         }

//         // Build update data
//         const updateData = { role };

//         if (role === 'student') {
//             // Check for all required student details
//             if (
//                 !studentDetails ||
//                 !studentDetails.fullName ||
//                 !studentDetails.leavingAddress ||
//                 !studentDetails.dateOfBirth ||
//                 !studentDetails.mobileNumber ||
//                 !studentDetails.nicNumber
//             ) {
//                 return res.status(400).json({ message: 'All student details are required' });
//             }
//             updateData.studentDetails = studentDetails;
//         } else if (role === 'employer') {
//             // Check for all required employer details
//             if (
//                 !jobOwnerDetails ||
//                 !jobOwnerDetails.shopName ||
//                 !jobOwnerDetails.shopLocation ||
//                 !jobOwnerDetails.shopRegisterNo
//             ) {
//                 return res.status(400).json({ message: 'All employer details are required' });
//             }
//             updateData.jobOwnerDetails = jobOwnerDetails;
//         }

//         // Debug: log the data being updated
//         console.log('Update data:', updateData);

//         // Update user data and return the new document
//         const updatedUser = await User.findByIdAndUpdate(userId, updateData, { 
//             new: true, 
//             runValidators: true 
//         });

//         if (!updatedUser) {
//             return res.status(404).json({ message: 'User not found' });
//         }

//         console.log('User updated:', updatedUser);

//         res.status(200).json({ 
//             message: 'Role updated successfully', 
//             user: updatedUser 
//         });
//     } catch (error) {
//         console.error('UpdateRole error:', error);
//         res.status(500).json({ error: error.message });
//     }
// };

// // 🟢 Login User
// exports.login = async (req, res) => {
//     try {
//         console.log('Login input:', req.body);
//         const { email, password } = req.body;

//         // Validate inputs
//         if (!email || !password) {
//             return res.status(400).json({ message: 'Email and password are required' });
//         }

//         const user = await User.findOne({ email });
//         if (!user) {
//             return res.status(401).json({ message: 'Authentication failed' });
//         }

//         const isValidPassword = await bcrypt.compare(password, user.password);
//         if (!isValidPassword) {
//             return res.status(401).json({ message: 'Authentication failed' });
//         }

//         // Generate JWT token
//         const token = jwt.sign(
//             { userId: user._id, email: user.email, role: user.role },
//             process.env.JWT_SECRET,
//             { expiresIn: '24h' }
//         );

//         console.log('Login successful:', user);
//         res.status(200).json({ 
//             token, 
//             userId: user._id, 
//             role: user.role,
//             user 
//         });
//     } catch (error) {
//         console.error('Login error:', error);
//         res.status(500).json({ error: error.message });
//     }
// };




const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/user.model');

class AuthController {
    // 🟢 Register User
    static async register(req, res) {
        try {
            const { email, password, role, studentDetails, jobOwnerDetails } = req.body;
            console.log('Register input:', req.body);

            // Validate email and password
            if (!email || !password) {
                return res.status(400).json({ message: 'Email and password are required' });
            }

            // Check if user exists
            const existingUser = await User.findOne({ email });
            if (existingUser) {
                return res.status(400).json({ message: 'Email already registered' });
            }

            // Hash password
            const hashedPassword = await bcrypt.hash(password, 10);

            // Create user data object
            const userData = {
                email,
                password: hashedPassword,
                role: role || 'student', // Default role is student
            };

            // Assign role-based details
            if (role === 'student' && studentDetails) {
                userData.studentDetails = studentDetails;
            } else if (role === 'employer' && jobOwnerDetails) {
                userData.jobOwnerDetails = jobOwnerDetails;
            }

            // Save user
            const user = new User(userData);
            console.log('User to be saved:', user);
            await user.save();
            console.log('User registered:', user);

            res.status(201).json({
                message: 'User registered successfully. Please select a role.',
                userId: user._id
            });
        } catch (error) {
            console.error('Register error:', error);
            res.status(500).json({ error: error.message });
        }
    }

    // 🟢 Update User Role
    static async updateRole(req, res) {
        try {
            console.log('UpdateRole input:', req.body);
            const { userId, role, studentDetails, jobOwnerDetails } = req.body;

            // Validate role
            if (!role || !['student', 'employer'].includes(role)) {
                return res.status(400).json({ message: 'Invalid role selection' });
            }

            const updateData = { role };

            if (role === 'student') {
                if (!studentDetails || !studentDetails.fullName) {
                    return res.status(400).json({ message: 'All student details are required' });
                }
                updateData.studentDetails = studentDetails;
            } else if (role === 'employer') {
                if (!jobOwnerDetails || !jobOwnerDetails.shopName) {
                    return res.status(400).json({ message: 'All employer details are required' });
                }
                updateData.jobOwnerDetails = jobOwnerDetails;
            }

            console.log('Update data:', updateData);
            const updatedUser = await User.findByIdAndUpdate(userId, updateData, {
                new: true,
                runValidators: true
            });

            if (!updatedUser) {
                return res.status(404).json({ message: 'User not found' });
            }

            console.log('User updated:', updatedUser);
            res.status(200).json({
                message: 'Role updated successfully',
                user: updatedUser
            });
        } catch (error) {
            console.error('UpdateRole error:', error);
            res.status(500).json({ error: error.message });
        }
    }

    // 🟢 Login User
    static async login(req, res) {
        try {
            console.log('Login input:', req.body);
            const { email, password } = req.body;

            if (!email || !password) {
                return res.status(400).json({ message: 'Email and password are required' });
            }

            const user = await User.findOne({ email });
            if (!user) {
                return res.status(401).json({ message: 'Authentication failed' });
            }

            const isValidPassword = await bcrypt.compare(password, user.password);
            if (!isValidPassword) {
                return res.status(401).json({ message: 'Authentication failed' });
            }

            const token = jwt.sign(
                { userId: user._id, email: user.email, role: user.role },
                process.env.JWT_SECRET,
                { expiresIn: '24h' }
            );

            console.log('Login successful:', user);
            res.status(200).json({
                token,
                userId: user._id,
                role: user.role,
                user
            });
        } catch (error) {
            console.error('Login error:', error);
            res.status(500).json({ error: error.message });
        }
    }
}

module.exports = AuthController;



// const jwt = require('jsonwebtoken');
// const bcrypt = require('bcryptjs');
// const User = require('../models/user.model');

// class AuthController {
//     // 🟢 Register User
//     static async register(req, res) {
//         try {
//             const { email, password, role } = req.body;
//             console.log('Register input:', req.body);

//             // Validate email and password
//             if (!email || !password) {
//                 return res.status(400).json({ message: 'Email and password are required' });
//             }

//             // Check if user exists
//             const existingUser = await User.findOne({ email });
//             if (existingUser) {
//                 return res.status(400).json({ message: 'Email already registered' });
//             }

//             // Hash password
//             const hashedPassword = await bcrypt.hash(password, 10);

//             // Create a new user
//             const user = new User({
//                 email,
//                 password: hashedPassword,
//                 role: role || 'student'  // Default to 'student' if not provided
//             });

//             console.log('User to be saved:', user);
//             await user.save();
//             console.log('User registered:', user);

//             res.status(201).json({ 
//                 message: 'User registered successfully. Please select a role.', 
//                 userId: user._id 
//             });
//         } catch (error) {
//             console.error('Register error:', error);
//             res.status(500).json({ error: error.message });
//         }
//     }

//     // 🟢 Update User Role
//     static async updateRole(req, res) {
//         try {
//             console.log('UpdateRole input:', req.body);
//             const { userId, role, studentDetails, jobOwnerDetails } = req.body;

//             // Validate role
//             if (!role || !['student', 'employer'].includes(role)) {
//                 return res.status(400).json({ message: 'Invalid role selection' });
//             }

//             const updateData = { role };

//             if (role === 'student') {
//                 if (!studentDetails || !studentDetails.fullName) {
//                     return res.status(400).json({ message: 'All student details are required' });
//                 }
//                 updateData.studentDetails = studentDetails;
//             } else if (role === 'employer') {
//                 if (!jobOwnerDetails || !jobOwnerDetails.shopName) {
//                     return res.status(400).json({ message: 'All employer details are required' });
//                 }
//                 updateData.jobOwnerDetails = jobOwnerDetails;
//             }

//             console.log('Update data:', updateData);
//             const updatedUser = await User.findByIdAndUpdate(userId, updateData, { 
//                 new: true, 
//                 runValidators: true 
//             });

//             if (!updatedUser) {
//                 return res.status(404).json({ message: 'User not found' });
//             }

//             console.log('User updated:', updatedUser);
//             res.status(200).json({ 
//                 message: 'Role updated successfully', 
//                 user: updatedUser 
//             });
//         } catch (error) {
//             console.error('UpdateRole error:', error);
//             res.status(500).json({ error: error.message });
//         }
//     }

//     // 🟢 Login User
//     static async login(req, res) {
//         try {
//             console.log('Login input:', req.body);
//             const { email, password } = req.body;

//             if (!email || !password) {
//                 return res.status(400).json({ message: 'Email and password are required' });
//             }

//             const user = await User.findOne({ email });
//             if (!user) {
//                 return res.status(401).json({ message: 'Authentication failed' });
//             }

//             const isValidPassword = await bcrypt.compare(password, user.password);
//             if (!isValidPassword) {
//                 return res.status(401).json({ message: 'Authentication failed' });
//             }

//             const token = jwt.sign(
//                 { userId: user._id, email: user.email, role: user.role },
//                 process.env.JWT_SECRET,
//                 { expiresIn: '24h' }
//             );

//             console.log('Login successful:', user);
//             res.status(200).json({ 
//                 token, 
//                 userId: user._id, 
//                 role: user.role,
//                 user 
//             });
//         } catch (error) {
//             console.error('Login error:', error);
//             res.status(500).json({ error: error.message });
//         }
//     }
// }

// module.exports = AuthController;
