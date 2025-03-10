const Conversation = require('../models/conversation.model');
const User = require('../models/user.model');
const mongoose = require('mongoose');

// Get all conversations for the current user
exports.getConversations = async (req, res) => {
    try {
        const userId = req.user._id;

        const conversations = await Conversation.find({
            participants: userId
        })
        .populate({
            path: 'participants',
            select: 'name email profileImage'
        })
        .populate({
            path: 'lastMessage.sender',
            select: 'name email profileImage'
        })
        .sort({ updatedAt: -1 });

        res.json(conversations);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching conversations', error: error.message });
    }
};

// Get a specific conversation by ID
exports.getConversation = async (req, res) => {
    try {
        const { conversationId } = req.params;
        const userId = req.user._id;

        const conversation = await Conversation.findById(conversationId)
            .populate({
                path: 'participants',
                select: 'name email profileImage'
            })
            .populate({
                path: 'messages.sender',
                select: 'name email profileImage'
            });

        if (!conversation) {
            return res.status(404).json({ message: 'Conversation not found' });
        }

        // Check if user is a participant
        if (!conversation.hasParticipant(userId)) {
            return res.status(403).json({ message: 'You are not authorized to view this conversation' });
        }

        res.json(conversation);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching conversation', error: error.message });
    }
};

// Create a new conversation
exports.createConversation = async (req, res) => {
    try {
        const { participants, isGroupChat, name, imageUrl } = req.body;
        const userId = req.user._id;

        // Ensure current user is included in participants
        if (!participants.includes(userId.toString())) {
            participants.push(userId.toString());
        }

        // Validate participants
        const validParticipants = [];
        for (const participantId of participants) {
            if (!mongoose.Types.ObjectId.isValid(participantId)) {
                return res.status(400).json({ message: `Invalid participant ID: ${participantId}` });
            }

            const user = await User.findById(participantId);
            if (!user) {
                return res.status(404).json({ message: `User not found: ${participantId}` });
            }

            validParticipants.push(participantId);
        }

        // For direct messages (not group chats), check if conversation already exists
        if (!isGroupChat && validParticipants.length === 2) {
            const existingConversation = await Conversation.findOne({
                participants: { $all: validParticipants, $size: 2 },
                isGroupChat: false
            }).populate({
                path: 'participants',
                select: 'name email profileImage'
            });

            if (existingConversation) {
                return res.json(existingConversation);
            }
        }

        // Create new conversation
        const newConversation = new Conversation({
            participants: validParticipants,
            isGroupChat: isGroupChat || false,
            name,
            imageUrl,
            messages: []
        });

        await newConversation.save();

        // Populate participant info before sending response
        const populatedConversation = await Conversation.findById(newConversation._id)
            .populate({
                path: 'participants',
                select: 'name email profileImage'
            });

        res.status(201).json(populatedConversation);
    } catch (error) {
        res.status(500).json({ message: 'Error creating conversation', error: error.message });
    }
};

// Send a message in a conversation
exports.sendMessage = async (req, res) => {
    try {
        const { conversationId } = req.params;
        const { content, messageType, attachmentUrl } = req.body;
        const userId = req.user._id;

        if (!content && !attachmentUrl) {
            return res.status(400).json({ message: 'Message content or attachment is required' });
        }

        const conversation = await Conversation.findById(conversationId);
        if (!conversation) {
            return res.status(404).json({ message: 'Conversation not found' });
        }

        // Check if user is a participant
        if (!conversation.hasParticipant(userId)) {
            return res.status(403).json({ message: 'You are not authorized to send messages in this conversation' });
        }

        // Create new message
        const newMessage = {
            sender: userId,
            content: content || '',
            timestamp: new Date(),
            messageType: messageType || 'text',
            attachmentUrl
        };

        // Add message to conversation
        conversation.messages.push(newMessage);
        await conversation.save();

        // Populate sender info before sending response
        const populatedConversation = await Conversation.findById(conversationId)
            .populate({
                path: 'messages.sender',
                select: 'name email profileImage'
            });

        const addedMessage = populatedConversation.messages[populatedConversation.messages.length - 1];
        res.status(201).json(addedMessage);
    } catch (error) {
        res.status(500).json({ message: 'Error sending message', error: error.message });
    }
};

// Mark messages as read
exports.markAsRead = async (req, res) => {
    try {
        const { conversationId } = req.params;
        const userId = req.user._id;

        const conversation = await Conversation.findById(conversationId);
        if (!conversation) {
            return res.status(404).json({ message: 'Conversation not found' });
        }

        // Check if user is a participant
        if (!conversation.hasParticipant(userId)) {
            return res.status(403).json({ message: 'You are not authorized to access this conversation' });
        }

        // Mark all unread messages sent by others as read
        let updated = false;
        conversation.messages.forEach(message => {
            if (!message.sender.equals(userId) && !message.isRead) {
                message.isRead = true;
                updated = true;
            }
        });

        if (updated) {
            await conversation.save();
        }

        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ message: 'Error marking messages as read', error: error.message });
    }
};

// Delete a conversation
exports.deleteConversation = async (req, res) => {
    try {
        const { conversationId } = req.params;
        const userId = req.user._id;

        const conversation = await Conversation.findById(conversationId);
        if (!conversation) {
            return res.status(404).json({ message: 'Conversation not found' });
        }

        // Check if user is a participant
        if (!conversation.hasParticipant(userId)) {
            return res.status(403).json({ message: 'You are not authorized to delete this conversation' });
        }

        await Conversation.findByIdAndDelete(conversationId);
        res.json({ message: 'Conversation deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting conversation', error: error.message });
    }
};
