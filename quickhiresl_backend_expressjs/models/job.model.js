const mongoose = require('mongoose');

const jobSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
        trim: true
    },
    company: {
        type: String,
        required: true,
        trim: true
    },
    location: {
        type: String,
        required: true,
        trim: true
    },
    description: {
        type: String,
        required: true
    },
    category: {
        type: String,
        required: true,
        trim: true
    },
    requirements: [{
        type: String,
        required: true
    }],
    salary: {
        type: Number,
        required: true
    },
    employmentType: {
        type: String,
        enum: ['Full-time', 'Part-time', 'Contract', 'Internship'],
        required: true
    },
    experienceLevel: {
        type: String,
        enum: ['Entry', 'Mid-level', 'Senior', 'Lead'],
        required: true
    },
    postedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    availableDates: [{
        date: {
            type: Date,
            required: true
        },
        timeSlots: [{
            startTime: { type: String, trim: true }, // Format: "HH:MM"
            endTime: { type: String, trim: true }   // Format: "HH:MM"
        }],
        isFullDay: {
            type: Boolean,
            default: false
        }
    }],
    status: {
        type: String,
        enum: ['active', 'closed', 'draft'],
        default: 'active'
    },
    applications: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Application'
    }],
    chat: {
        messages: [{
            sender: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User',
                required: true
            },
            content: {
                type: String,
                required: true
            },
            timestamp: {
                type: Date,
                default: Date.now
            }
        }]
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Job', jobSchema);
