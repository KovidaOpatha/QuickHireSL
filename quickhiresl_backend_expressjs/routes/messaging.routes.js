const express = require('express');
const router = express.Router();
const messagingController = require('../controllers/messaging.controller');
const authMiddleware = require('../middleware/auth.middleware');

// Apply authentication middleware to all routes
router.use(authMiddleware.verifyToken);

// Get all conversations for the current user
router.get('/conversations', messagingController.getConversations);

// Get a specific conversation by ID
router.get('/conversations/:conversationId', messagingController.getConversation);

// Create a new conversation
router.post('/conversations', messagingController.createConversation);

// Send a message in a conversation
router.post('/conversations/:conversationId/messages', messagingController.sendMessage);

// Mark messages as read
router.put('/conversations/:conversationId/read', messagingController.markAsRead);

// Delete a conversation
router.delete('/conversations/:conversationId', messagingController.deleteConversation);

module.exports = router;
