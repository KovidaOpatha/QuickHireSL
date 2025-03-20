const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const Message = require('../models/message.model');
const User = require('../models/user.model');
const Notification = require('../models/notification.model');
const mongoose = require('mongoose');

// Get messages between current user and another user
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

// Send a message
router.post('/', auth, async (req, res) => {
  try {
    const { receiverId, content, jobId } = req.body;
    console.log(`Sending message to ${receiverId}, content: "${content}", jobId: ${jobId || 'none'}`);

    const newMessage = new Message({
      senderId: req.user._id,
      receiverId,
      content,
      jobId: jobId || null
    });

    const message = await newMessage.save();
    console.log(`Message saved with ID: ${message._id}`);

    // Create notification for receiver
    const notification = new Notification({
      userId: receiverId,
      type: 'message',
      content: `New message from ${req.user.name || req.user.fullName || 'a user'}`,
      relatedId: message._id,
      isRead: false
    });

    await notification.save();
    console.log(`Notification created for user ${receiverId}`);

    res.status(201).json(message);
  } catch (err) {
    console.error(`Error sending message: ${err}`);
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

module.exports = router; 