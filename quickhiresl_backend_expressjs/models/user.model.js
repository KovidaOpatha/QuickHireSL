const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true, trim: true },
    password: { type: String, required: true, trim: true },
    role: { type: String, enum: ['student', 'jobowner', 'employer'], default: 'student' },
    profileImage: { type: String, default: null },
    rating: { type: Number, default: 0, min: 0, max: 5 },
    completedJobs: { type: Number, default: 0 },
    notifications: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Notification'
    }],
    studentDetails: {
        fullName: { type: String, trim: true },
        leavingAddress: { type: String, trim: true },
        dateOfBirth: { type: Date },
        mobileNumber: { type: String, trim: true },
        nicNumber: { type: String, trim: true },
        preferredLocations: [{ type: String, trim: true }]
    },
    jobOwnerDetails: {
        shopName: { type: String, trim: true },
        shopLocation: { type: String, trim: true },
        shopRegisterNo: { type: String, trim: true }
    }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);