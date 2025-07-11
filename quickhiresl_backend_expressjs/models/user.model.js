const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true, trim: true },
    password: { type: String, required: true, trim: true },
    role: { type: String, enum: ['student', 'jobowner', 'employer'] },
    profileImage: { type: String, default: null },
    bio: { type: String, default: '' },
    rating: { type: Number, default: 0, min: 0, max: 5 },
    completedJobs: { type: Number, default: 0 },
    registrationComplete: { type: Boolean, default: false },
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
        preferredLocations: [{ type: String, trim: true }],
        preferredJobs: [{ type: String, trim: true }],
        availability: [{
            date: { type: Date },
            timeSlots: [{
                startTime: { type: String, trim: true }, // Format: "HH:MM"
                endTime: { type: String, trim: true },   // Format: "HH:MM"
            }],
            isFullDay: { type: Boolean, default: false },
            createdAt: { type: Date, default: Date.now }
        }],
        skills: [{ type: String, trim: true }]
    },
    jobOwnerDetails: {
        fullName: { type: String, trim: true },
        mobileNumber: { type: String, trim: true },
        nicNumber: { type: String, trim: true },
        shopName: { type: String, trim: true },
        shopLocation: { type: String, trim: true },
        shopRegisterNo: { type: String, trim: true },
        jobPosition: { type: String, trim: true }
    }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);