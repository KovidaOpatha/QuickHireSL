const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const MessageSchema = new Schema({
    sender: {
        type: Schema.Types.ObjectId,
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
    },
    isRead: {
        type: Boolean,
        default: false
    },
    attachmentUrl: {
        type: String
    },
    messageType: {
        type: String,
        enum: ['text', 'image', 'file'],
        default: 'text'
    }
});

const ConversationSchema = new Schema({
    participants: [{
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    }],
    messages: [MessageSchema],
    lastMessage: {
        type: MessageSchema
    },
    updatedAt: {
        type: Date,
        default: Date.now
    },
    name: {
        type: String
    },
    imageUrl: {
        type: String
    },
    isGroupChat: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

// Create index for faster queries
ConversationSchema.index({ participants: 1 });
ConversationSchema.index({ updatedAt: -1 });

// Pre-save middleware to update lastMessage and updatedAt
ConversationSchema.pre('save', function(next) {
    if (this.messages && this.messages.length > 0) {
        this.lastMessage = this.messages[this.messages.length - 1];
        this.updatedAt = new Date();
    }
    next();
});

// Method to check if a user is a participant in this conversation
ConversationSchema.methods.hasParticipant = function(userId) {
    return this.participants.some(participantId => 
        participantId.toString() === userId.toString()
    );
};

module.exports = mongoose.model('Conversation', ConversationSchema);
