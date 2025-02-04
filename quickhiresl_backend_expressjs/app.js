const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const authRoutes = require('./routes/auth.routes');
const indexRoutes = require('./routes/index');

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Health Check Route
app.get('/api/health', (req, res) => {
    res.status(200).json({ status: "API is running" });
});

// Routes
app.use('/api', indexRoutes);
app.use('/api/auth', authRoutes);

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI, { useNewUrlParser: true, useUnifiedTopology: true })
    .then(() => console.log('✅ Connected to MongoDB Atlas'))
    .catch(err => {
        console.error('❌ MongoDB Connection Error:', err.message);
        process.exit(1);
    });

// Global Error Handling for Unhandled Promise Rejections
process.on('unhandledRejection', (err) => {
    console.error('🔥 Unhandled Rejection:', err);
    process.exit(1);
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`🚀 Server running on port ${port}`);
});
