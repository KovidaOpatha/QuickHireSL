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
app.use('/api', chatRoutes);

// Chat routes
app.get('/api/jobs/:jobId/chat', authMiddleware, chatController.getJobChat);
app.post('/api/jobs/:jobId/chat', authMiddleware, chatController.addMessage);

// Feedback Schema & Model
const FeedbackSchema = new mongoose.Schema({
    rating: { type: Number, required: true },
    feedback: { type: String, required: true },
    date: { type: Date, default: Date.now }
});

const Feedback = mongoose.model("Feedback", FeedbackSchema);

// Feedback Routes
app.post("/api/feedback", async (req, res) => {
    try {
        console.log("Received Feedback Data:", req.body);
        const { rating, feedback } = req.body;

        if (!rating || !feedback) {
            return res.status(400).json({ message: "Missing required fields" });
        }

        const newFeedback = new Feedback({ rating, feedback });
        await newFeedback.save();

        console.log("Feedback Saved Successfully");
        res.status(201).json({ message: "Feedback submitted successfully" });
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