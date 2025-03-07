const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    role: { type: String, enum: ['student', 'jobowner'], default: null },
    profileImage: { type: String },
    rating: { type: Number, default: 0, min: 0, max: 5 },
    completedJobs: { type: Number, default: 0 },
    notifications: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Notification'
    }],
    studentDetails: {
        fullName: { type: String },
        leavingAddress: { type: String },
        dateOfBirth: { type: Date },
        mobileNumber: { type: String },
        nicNumber: { type: String }
    },
    jobOwnerDetails: {
        shopName: { type: String },
        shopLocation: { type: String },
        shopRegisterNo: { type: String }
    }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
