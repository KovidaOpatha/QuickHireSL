require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
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

const app = express();

// Middleware
app.use(cors());  // Allow all origins during development
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

// Community Chat Schemas
const reactionSchema = new mongoose.Schema({
    likes: { type: Number, default: 0 },
    likedBy: { type: [String], default: [] }
});

const replySchema = new mongoose.Schema({
    user: { type: String, required: true },
    avatar: { type: String, required: true },
    message: { type: String, required: true },
    time: { type: String, required: true },
    reactions: { type: reactionSchema, default: () => ({ likes: 0, likedBy: [] }) },
    replies: { type: Array, default: [] }
});

const chatSchema = new mongoose.Schema({
    user: { type: String, required: true },
    avatar: { type: String, required: true },
    message: { type: String, required: true },
    time: { type: String, required: true },
    replies: [replySchema],
    reactions: {
        likes: { type: Number, default: 0 },
        likedBy: { type: [String], default: [] },
    },
});

const Chat = mongoose.model("Community", chatSchema);

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

// Community Chat Routes
app.get("/api/chats", async (req, res) => {
    try {
        const chats = await Chat.find().sort({ _id: -1 });
        res.json(chats);
    } catch (err) {
        res.status(500).send(err.message);
    }
});

app.post("/api/chats", async (req, res) => {
    try {
        const newChat = new Chat(req.body);
        await newChat.save();
        res.status(201).json(newChat);
    } catch (err) {
        res.status(400).send(err.message);
    }
});

app.post("/api/chats/:id/reply", async (req, res) => {
    try {
        const postId = req.params.id;
        const reply = req.body;
        
        const post = await Chat.findById(postId);
        if (!post) {
            return res.status(404).json({ message: "Post not found" });
        }
        
        if (!reply.reactions) {
            reply.reactions = { likes: 0, likedBy: [] };
        }
        if (!reply.replies) {
            reply.replies = [];
        }
        
        post.replies.push(reply);
        await post.save();
        
        res.status(201).json(reply);
    } catch (err) {
        res.status(400).send(err.message);
    }
});

app.put("/api/chats/:id/react", async (req, res) => {
    try {
        const postId = req.params.id;
        const { user, liked } = req.body;
        
        const post = await Chat.findById(postId);
        if (!post) {
            return res.status(404).json({ message: "Post not found" });
        }
        
        if (liked) {
            if (!post.reactions.likedBy.includes(user)) {
                post.reactions.likes += 1;
                post.reactions.likedBy.push(user);
            }
        } else {
            if (post.reactions.likedBy.includes(user)) {
                post.reactions.likes = Math.max(0, post.reactions.likes - 1);
                post.reactions.likedBy = post.reactions.likedBy.filter(u => u !== user);
            }
        }
        
        await post.save();
        res.status(200).json(post);
    } catch (err) {
        res.status(400).send(err.message);
    }
});

app.post("/api/chats/:id/reply/:replyIndex/nested", async (req, res) => {
    try {
        const { id, replyIndex } = req.params;
        const nestedReply = req.body;
        const replyIndexNum = parseInt(replyIndex);
        
        const post = await Chat.findById(id);
        if (!post || !post.replies[replyIndexNum]) {
            return res.status(404).json({ message: "Post or reply not found" });
        }
        
        if (!nestedReply.reactions) {
            nestedReply.reactions = { likes: 0, likedBy: [] };
        }
        if (!nestedReply.replies) {
            nestedReply.replies = [];
        }
        
        if (!post.replies[replyIndexNum].replies) {
            post.replies[replyIndexNum].replies = [];
        }
        
        post.replies[replyIndexNum].replies.push(nestedReply);
        await post.save();
        
        res.status(201).json(post);
    } catch (err) {
        console.error("Error adding nested reply:", err);
        res.status(400).send(err.message);
    }
});

app.put("/api/chats/:id/reply/:replyIndex/react", async (req, res) => {
    try {
        const { id, replyIndex } = req.params;
        const { user, liked } = req.body;
        const replyIndexNum = parseInt(replyIndex);
        
        const post = await Chat.findById(id);
        if (!post || !post.replies[replyIndexNum]) {
            return res.status(404).json({ message: "Post or reply not found" });
        }
        
        const reply = post.replies[replyIndexNum];
        
        if (!reply.reactions) {
            reply.reactions = { likes: 0, likedBy: [] };
        }
        
        if (liked) {
            if (!reply.reactions.likedBy.includes(user)) {
                reply.reactions.likes += 1;
                reply.reactions.likedBy.push(user);
            }
        } else {
            if (reply.reactions.likedBy.includes(user)) {
                reply.reactions.likes = Math.max(0, reply.reactions.likes - 1);
                reply.reactions.likedBy = reply.reactions.likedBy.filter(u => u !== user);
            }
        }
        
        await post.save();
        res.status(200).json(post);
    } catch (err) {
        res.status(400).send(err.message);
    }
});

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI)
    .then(() => console.log('Connected to MongoDB'))
    .catch(err => console.error('MongoDB connection error:', err));

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

const port = process.env.PORT || 8080;
app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});

module.exports = app;