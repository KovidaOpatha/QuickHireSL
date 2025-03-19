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

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(bodyParser.json());

// Serve static files from public directory
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));

// Health Check Route
app.get('/api/health', (req, res) => {
    res.status(200).json({ status: "API is running" });
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

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI)
    .then(() => console.log('MongoDB Connected'))
    .catch(err => console.log('MongoDB Connection Error:', err));

// Global Error Handling for Unhandled Promise Rejections
process.on('unhandledRejection', (err) => {
    console.error(' Unhandled Rejection:', err);
    process.exit(1);
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ 
        success: false,
        message: 'Something went wrong!',
        error: err.message 
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});