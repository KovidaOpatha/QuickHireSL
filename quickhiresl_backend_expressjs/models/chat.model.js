const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
    content: {
        type: String,
        required: true
    },
    sender: {
        _id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        name: {
            type: String,
            required: true
        },
        avatar: String
    },
    jobId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Job',
        required: true
    },
    timestamp: {
        type: Date,
        default: Date.now
    }
});

const chatSchema = new mongoose.Schema({
    jobId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Job',
        required: true,
        unique: true
    },
    messages: [messageSchema]
}, {
    timestamps: true
});

// Create indexes for better query performance
chatSchema.index({ jobId: 1 });
messageSchema.index({ timestamp: -1 });

module.exports = mongoose.model('Chat', chatSchema);
