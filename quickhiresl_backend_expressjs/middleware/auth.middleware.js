const jwt = require('jsonwebtoken');
const User = require('../models/user.model');

const authMiddleware = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ message: 'Authentication required' });
        }

        const token = authHeader.split(' ')[1];
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

        // Set user information in the request
        req.userId = decoded._id;
        req.userEmail = decoded.email;
        req.userRole = decoded.role;
        req.user = user;
        
        next();
    } catch (error) {
        console.error('Auth Middleware error:', error);
        return res.status(401).json({ 
            message: error.name === 'TokenExpiredError' ? 'Token expired' : 'Authentication failed' 
        });
    }
};

module.exports = authMiddleware;