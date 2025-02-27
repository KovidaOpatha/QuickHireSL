const jwt = require('jsonwebtoken');
const User = require('../models/user.model');

const authMiddleware = async (req, res, next) => {
    try {
        // Expecting the token format: "Bearer <token>"
        const token = req.headers.authorization && req.headers.authorization.split(' ')[1];
        if (!token) {
            return res.status(401).json({ message: 'Authentication token missing' });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Find the user in the database to ensure they exist
        const user = await User.findById(decoded._id);
        if (!user) {
            return res.status(401).json({ message: 'User not found' });
        }

        // Check if the user is a job owner for job posting endpoints
        if (req.path.includes('/jobs') && req.method === 'POST' && user.role !== 'jobowner') {
            return res.status(403).json({ message: 'Only job owners can post jobs' });
        }

        // Set the user object in req.user
        req.user = user;
        
        next();
    } catch (error) {
        console.error('Auth Middleware error:', error);
        return res.status(401).json({ message: 'Authentication failed' });
    }
};

module.exports = authMiddleware;
