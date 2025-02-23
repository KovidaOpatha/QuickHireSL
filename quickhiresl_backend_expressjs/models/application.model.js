const mongoose = require('mongoose');

const applicationSchema = new mongoose.Schema({
    job: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Job',
        required: true
    },
    applicant: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    jobOwner: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'accepted', 'rejected', 'completion_requested', 'completed'],
        default: 'pending'
    },
    coverLetter: {
        type: String,
        required: true
    },
    appliedAt: {
        type: Date,
        default: Date.now
    },
    completionDetails: {
        requestedBy: {
            type: String,
            enum: ['jobOwner', 'applicant'],
        },
        requestedAt: Date,
        confirmedAt: Date
    }
}, {
    timestamps: true
});

const Application = mongoose.model('Application', applicationSchema);

module.exports = Application;
