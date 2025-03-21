const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const bodyParser = require('body-parser');
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const indexRoutes = require('./routes/api');
const jobRoutes = require('./routes/job.routes');
const applicationRoutes = require('./routes/application.routes');
const notificationRoutes = require('./routes/notification.routes');
const jobMatchingRoutes = require('./routes/job-matching.routes');
const chatController = require('./controllers/chat.controller');
const authMiddleware = require('./middleware/auth.middleware');
const chatRoutes = require('./routes/chat.routes');
const messagesRoutes = require('./routes/messages.js');

dotenv.config();

const app = express();

// Middleware
const allowedOrigins = process.env.ALLOWED_ORIGINS ? 
  process.env.ALLOWED_ORIGINS.split(',') : 
  [
    'https://quickhiresl2-d8e9g7h6b0c5emgx.southeastasia-01.azurewebsites.net',
    'http://localhost:3000',
    'http://localhost:8080',
    'http://localhost:19006',
    '*'
  ];

app.use(cors({
  origin: function(origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) !== -1 || allowedOrigins.indexOf('*') !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: true
}));
app.use(express.json({ limit: '50mb' }));
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// Serve static files from public directory
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));

// Enhanced Health Check Route
app.get('/api/health', (req, res) => {
    const healthData = {
        status: "API is running",
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development',
        uptime: process.uptime() + ' seconds',
        memoryUsage: process.memoryUsage(),
        mongoDBConnection: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
    };
    
    res.status(200).json(healthData);
});

// API version route
app.get('/api/version', (req, res) => {
    res.status(200).json({
        version: '1.0.0',
        apiName: 'QuickHireSL API',
        environment: process.env.NODE_ENV || 'development'
    });
});

// Routes
app.use('/api', indexRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/jobs', jobRoutes);
app.use('/api/applications', applicationRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/matching', jobMatchingRoutes);
app.use('/api', chatRoutes);
app.use('/api/messages', messagesRoutes);

// Chat routes
app.get('/api/jobs/:jobId/chat', authMiddleware, chatController.getJobChat);
app.post('/api/jobs/:jobId/chat', authMiddleware, chatController.addMessage);

// Feedback Schema & Model
const FeedbackSchema = new mongoose.Schema({
    rating: { type: Number, required: true, min: 1, max: 5 },
    feedback: { type: String, required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    targetUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    applicationId: { type: String },
    date: { type: Date, default: Date.now }
});

const Feedback = mongoose.model("Feedback", FeedbackSchema);

// Feedback Routes
app.post("/api/feedback", authMiddleware, async (req, res) => {
    try {
        console.log("Received Feedback Data:", req.body);
        const { rating, feedback, applicationId, targetUserId } = req.body;
        const userId = req.user._id;

        if (!rating || !feedback || !targetUserId) {
            return res.status(400).json({ message: "Missing required fields" });
        }

        // Create and save the new feedback
        const newFeedback = new Feedback({ 
            rating, 
            feedback, 
            userId, 
            targetUserId, 
            applicationId 
        });
        await newFeedback.save();

        // Update the target user's rating
        const User = mongoose.model('User');
        
        try {
            // Get all ratings for the target user
            const allFeedbacks = await Feedback.find({ targetUserId });
            
            // Calculate the average rating
            const totalRating = allFeedbacks.reduce((sum, feedback) => sum + feedback.rating, 0);
            const averageRating = allFeedbacks.length > 0 ? Math.round(totalRating / allFeedbacks.length) : 0;
            
            console.log(`Updating user ${targetUserId} with new rating: ${averageRating}`);
            console.log(`Based on ${allFeedbacks.length} feedbacks with total rating: ${totalRating}`);
            
            // Update the user's rating in the database
            const updateResult = await User.findByIdAndUpdate(
                targetUserId, 
                { 
                    rating: averageRating,
                    $inc: { completedJobs: 1 } 
                },
                { new: true }
            );
            
            console.log("User update result:", updateResult ? "Success" : "Failed");
            if (updateResult) {
                console.log(`Updated user rating to ${updateResult.rating} and completed jobs to ${updateResult.completedJobs}`);
            }
            
            res.status(201).json({ 
                message: "Feedback submitted successfully",
                rating: averageRating
            });
        } catch (updateError) {
            console.error("Error updating user rating:", updateError);
            // Still return success for the feedback submission even if rating update fails
            res.status(201).json({ 
                message: "Feedback submitted, but rating update failed",
                error: updateError.message
            });
        }
    } catch (err) {
        console.error("Error Saving Feedback:", err);
        res.status(500).json({ message: "Server error", error: err.message });
    }
});

app.get("/api/feedbacks", async (req, res) => {
    try {
        const feedbacks = await Feedback.find().sort({ date: -1 });
        res.status(200).json(feedbacks);
    } catch (err) {
        res.status(500).json({ message: "Server error", error: err.message });
    }
});

// Get feedback for a specific user
app.get("/api/feedback/user/:userId", async (req, res) => {
    try {
        const { userId } = req.params;
        const feedbacks = await Feedback.find({ targetUserId: userId })
            .populate('userId', 'name email profileImage firstName lastName')
            .sort({ date: -1 });
        
        res.status(200).json({
            success: true,
            data: feedbacks
        });
    } catch (err) {
        console.error("Error getting user feedback:", err);
        res.status(500).json({ 
            success: false,
            message: "Server error while getting user feedback", 
            error: err.message 
        });
    }
});

// Get feedback for a specific application
app.get("/api/feedback/application/:applicationId", async (req, res) => {
    try {
        const { applicationId } = req.params;
        const feedbacks = await Feedback.find({ applicationId })
            .populate('userId', 'name email profileImage firstName lastName')
            .populate('targetUserId', 'name email profileImage firstName lastName')
            .sort({ date: -1 });
        
        res.status(200).json({
            success: true,
            data: feedbacks
        });
    } catch (err) {
        console.error("Error getting application feedback:", err);
        res.status(500).json({ 
            success: false,
            message: "Server error while getting application feedback", 
            error: err.message 
        });
    }
});

// Global Error Handling for Unhandled Promise Rejections
process.on('unhandledRejection', (err) => {
    console.error('Unhandled Rejection:', err);
    // In production, we might want to continue running instead of exiting
    if (process.env.NODE_ENV === 'production') {
        console.error('Unhandled rejection occurred, but server continues to run in production mode');
    } else {
        process.exit(1);
    }
});

// 404 handler for undefined routes
app.use((req, res, next) => {
    res.status(404).json({
        success: false,
        message: 'API endpoint not found',
        path: req.originalUrl
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error occurred:', err);
    
    // Log detailed error info but return limited info to client
    const statusCode = err.statusCode || 500;
    
    res.status(statusCode).json({ 
        success: false,
        message: err.message || 'Something went wrong!',
        error: process.env.NODE_ENV === 'production' ? 'An error occurred' : err.stack
    });
});

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI)
    .then(() => console.log('MongoDB Connected'))
    .catch(err => console.log('MongoDB Connection Error:', err));

const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    if (process.env.NODE_ENV === 'production') {
        console.log(`API URL: ${process.env.API_URL || 'Not configured'}`);
    }
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    server.close(() => {
        console.log('Process terminated');
    });
});