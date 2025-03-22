const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const Message = require('../models/message.model');
const User = require('../models/user.model');
const Notification = require('../models/notification.model');
const mongoose = require('mongoose');

// Simple in-memory cache to prevent duplicate messages
// This is a temporary solution - a more robust solution would use Redis
const messageCache = {
  // Structure: { userId_receiverId_content_timestamp: true }
  recentMessages: {},
  // Add message to cache with 10 second expiry
  add: function(userId, receiverId, content, timestamp) {
    const key = `${userId}_${receiverId}_${content}_${timestamp}`;
    this.recentMessages[key] = true;
    
    // Expire after 10 seconds
    setTimeout(() => {
      delete this.recentMessages[key];
    }, 10000);
    
    return key;
  },
  // Check if message exists in cache
  exists: function(userId, receiverId, content, timestamp) {
    const key = `${userId}_${receiverId}_${content}_${timestamp}`;
    return this.recentMessages[key] === true;
  }
};

// Get messages between current user and another user - main direct message endpoint
router.get('/:userId', auth, async (req, res) => {
  try {
    console.log(`Fetching messages between current user ${req.user._id} and user ${req.params.userId}`);
    
    const messages = await Message.find({
      $or: [
        { senderId: req.user._id, receiverId: req.params.userId },
        { senderId: req.params.userId, receiverId: req.user._id }
      ]
    })
    .sort({ timestamp: 1 })
    .limit(100);

    console.log(`Found ${messages.length} messages`);

    // Mark messages as read
    await Message.updateMany(
      { 
        receiverId: req.user._id,
        senderId: req.params.userId,
        messageType: 'direct',
        isRead: false
      },
      { isRead: true }
    );

    res.json(messages);
  } catch (err) {
    console.error(`Error fetching messages: ${err}`);
    res.status(500).send('Server Error');
  }
});

// Alias for direct messages (ensuring compatibility with frontend)
router.get('/direct/:userId', auth, async (req, res) => {
  try {
    console.log(`Direct message API: Fetching messages between current user ${req.user._id} and user ${req.params.userId}`);
    
    const messages = await Message.find({
      $or: [
        { senderId: req.user._id, receiverId: req.params.userId, messageType: 'direct' },
        { senderId: req.params.userId, receiverId: req.user._id, messageType: 'direct' }
      ]
    })
    .sort({ timestamp: 1 })
    .limit(100);

    console.log(`Found ${messages.length} direct messages`);

    // Mark messages as read
    await Message.updateMany(
      { 
        receiverId: req.user._id,
        senderId: req.params.userId,
        messageType: 'direct',
        isRead: false
      },
      { isRead: true }
    );

    res.json(messages);
  } catch (err) {
    console.error(`Error fetching direct messages: ${err}`);
    res.status(500).send('Server Error');
  }
});

// New endpoint: Get messages for a specific job between current user and another user
router.get('/job/:jobId/:userId', auth, async (req, res) => {
  try {
    const { jobId, userId } = req.params;
    
    console.log(`Fetching job-specific messages between current user ${req.user._id} and user ${userId} for job ${jobId}`);
    
    // Validate job ID format
    if (!mongoose.Types.ObjectId.isValid(jobId)) {
      return res.status(400).json({ msg: 'Invalid job ID format' });
    }
    
    // Find messages that match both the users and the specific job
    const messages = await Message.find({
      $or: [
        { senderId: req.user._id, receiverId: userId, messageType: 'direct' },
        { senderId: userId, receiverId: req.user._id, messageType: 'direct' }
      ],
      jobId: jobId
    })
    .sort({ timestamp: 1 })
    .limit(100);

    console.log(`Found ${messages.length} job-specific messages`);

    // Mark messages as read
    await Message.updateMany(
      { 
        receiverId: req.user._id,
        senderId: userId,
        jobId: jobId,
        messageType: 'direct',
        isRead: false
      },
      { isRead: true }
    );

    res.json(messages);
  } catch (err) {
    console.error(`Error fetching job-specific messages: ${err}`);
    res.status(500).send('Server Error');
  }
});

// Helper function to handle message creation logic
async function createMessage(senderId, receiverId, content, jobId, messageType = 'direct') {
  // Generate timestamp for cache check
  const timestamp = new Date().toISOString();
  
  // Check for duplicate message within the last 10 seconds
  if (messageCache.exists(senderId, receiverId, content, timestamp.substring(0, 16))) {
    console.log(`Preventing duplicate message: ${senderId} to ${receiverId}: "${content}"`);
    
    // Find the most recent message that matches our criteria to return
    const recentMessage = await Message.findOne({
      senderId,
      receiverId,
      content,
      messageType,
      // Find messages within the last 30 seconds
      timestamp: { $gte: new Date(Date.now() - 30000) }
    }).sort({ timestamp: -1 });
    
    if (recentMessage) {
      console.log(`Found recent duplicate message ${recentMessage._id}, returning it instead`);
      return recentMessage;
    }
  }
  
  // Add to cache to prevent duplicates
  messageCache.add(senderId, receiverId, content, timestamp.substring(0, 16));
  
  // Create and save new message
  const newMessage = new Message({
    senderId,
    receiverId,
    content,
    jobId: jobId || null,
    messageType
  });

  const message = await newMessage.save();
  console.log(`New message saved with ID: ${message._id}, type: ${messageType}`);
  
  // Create notification for receiver
  const notification = new Notification({
    userId: receiverId,
    type: 'message',
    content: `New message from ${senderId}`,
    relatedId: message._id,
    isRead: false
  });

  await notification.save();
  console.log(`Notification created for user ${receiverId}`);
  
  return message;
}

// Send a message - main endpoint
router.post('/', auth, async (req, res) => {
  try {
    const { receiverId, content, jobId } = req.body;
    console.log(`Sending message to ${receiverId}, content: "${content}", jobId: ${jobId || 'none'}`);

    const message = await createMessage(
      req.user._id, 
      receiverId, 
      content, 
      jobId,
      'direct'
    );

    res.status(201).json(message);
  } catch (err) {
    console.error(`Error sending message: ${err}`);
    res.status(500).send('Server Error');
  }
});

// Alias for sending direct messages (ensuring frontend compatibility)
router.post('/direct', auth, async (req, res) => {
  try {
    const { receiverId, content, jobId } = req.body;
    console.log(`Direct API: Sending message to ${receiverId}, content: "${content}", jobId: ${jobId || 'none'}`);

    const message = await createMessage(
      req.user._id, 
      receiverId, 
      content, 
      jobId,
      'direct'
    );

    res.status(201).json(message);
  } catch (err) {
    console.error(`Error sending direct message: ${err}`);
    res.status(500).send('Server Error');
  }
});

// Alias for sending messages (ensuring frontend compatibility)
router.post('/send', auth, async (req, res) => {
  try {
    const { receiverId, content, jobId } = req.body;
    console.log(`Send API: Sending message to ${receiverId}, content: "${content}", jobId: ${jobId || 'none'}`);

    const message = await createMessage(
      req.user._id, 
      receiverId, 
      content, 
      jobId,
      'direct'
    );

    res.status(201).json(message);
  } catch (err) {
    console.error(`Error in send message endpoint: ${err}`);
    res.status(500).send('Server Error');
  }
});

// Get user's conversations
router.get('/conversations', auth, async (req, res) => {
  try {
    // Get all messages where user is either sender or receiver
    const messages = await Message.aggregate([
      {
        $match: {
          $or: [
            { senderId: mongoose.Types.ObjectId(req.user._id) },
            { receiverId: mongoose.Types.ObjectId(req.user._id) }
          ]
        }
      },
      {
        $sort: { timestamp: -1 }
      },
      {
        $group: {
          _id: {
            $cond: {
              if: { $eq: ['$senderId', mongoose.Types.ObjectId(req.user._id)] },
              then: '$receiverId',
              else: '$senderId'
            }
          },
          lastMessage: { $first: '$$ROOT' },
          unreadCount: {
            $sum: {
              $cond: [
                { 
                  $and: [
                    { $eq: ['$receiverId', mongoose.Types.ObjectId(req.user._id)] },
                    { $eq: ['$isRead', false] }
                  ]
                },
                1,
                0
              ]
            }
          }
        }
      },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'otherUser'
        }
      },
      {
        $unwind: '$otherUser'
      },
      {
        $project: {
          _id: 1,
          lastMessage: 1,
          unreadCount: 1,
          'otherUser.name': 1,
          'otherUser.fullName': 1,
          'otherUser.profileImage': 1
        }
      }
    ]);

    res.json(messages);
  } catch (err) {
    console.error(`Error getting conversations: ${err}`);
    res.status(500).send('Server Error');
  }
});

// Mark message as read
router.patch('/:messageId/read', auth, async (req, res) => {
  try {
    const message = await Message.findOneAndUpdate(
      {
        _id: req.params.messageId,
        receiverId: req.user._id
      },
      { isRead: true },
      { new: true }
    );

    if (!message) {
      return res.status(404).json({ msg: 'Message not found' });
    }

    res.json(message);
  } catch (err) {
    console.error(`Error marking message as read: ${err}`);
    res.status(500).send('Server Error');
  }
});

// Community chat messages for a specific job
router.post('/community', auth, async (req, res) => {
  try {
    const { receiverId, content, jobId } = req.body;
    
    if (!jobId) {
      return res.status(400).json({ msg: 'Job ID is required for community messages' });
    }
    
    console.log(`Community chat: Sending message for job ${jobId}, content: "${content}"`);

    const message = await createMessage(
      req.user._id, 
      receiverId, 
      content, 
      jobId,
      'community'
    );

    res.status(201).json(message);
  } catch (err) {
    console.error(`Error sending community message: ${err}`);
    res.status(500).send('Server Error');
  }
});

// Get community chat messages for a specific job
router.get('/community/job/:jobId', auth, async (req, res) => {
  try {
    const { jobId } = req.params;
    console.log(`Fetching community messages for job ${jobId}`);
    
    // Validate job ID format
    if (!mongoose.Types.ObjectId.isValid(jobId)) {
      return res.status(400).json({ msg: 'Invalid job ID format' });
    }
    
    const messages = await Message.find({
      jobId: jobId,
      messageType: 'community'
    })
    .sort({ timestamp: 1 })
    .limit(100);

    console.log(`Found ${messages.length} community messages for job ${jobId}`);

    res.json(messages);
  } catch (err) {
    console.error(`Error fetching community messages: ${err}`);
    res.status(500).send('Server Error');
  }
});

module.exports = router; 