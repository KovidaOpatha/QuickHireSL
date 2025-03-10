const express = require('express');
const router = express.Router();
const Chat = require('../models/chat.model');
const Job = require('../models/job.model');
const mongoose = require('mongoose');

// Get messages for a specific job
router.get('/jobs/:jobId/chat', async (req, res) => {
    try {
        const { jobId } = req.params;

        // Validate jobId
        if (!mongoose.Types.ObjectId.isValid(jobId)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid job ID format'
            });
        }

        // Find or create chat for the job
        let chat = await Chat.findOne({ jobId });
        
        if (!chat) {
            // Verify job exists before creating chat
            const jobExists = await Job.findById(jobId);
            if (!jobExists) {
                return res.status(404).json({
                    success: false,
                    message: 'Job not found'
                });
            }

            chat = new Chat({
                jobId,
                messages: []
            });
            await chat.save();
        }

        res.status(200).json({
            success: true,
            messages: chat.messages
        });
    } catch (error) {
        console.error('Error fetching chat messages:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching chat messages',
            error: error.message
        });
    }
});

// Add a message to a job chat
router.post('/jobs/:jobId/chat', async (req, res) => {
    try {
        const { jobId } = req.params;
        const { content, sender } = req.body;

        // Validate required fields
        if (!content) {
            return res.status(400).json({
                success: false,
                message: 'Message content is required'
            });
        }

        if (!sender || !sender.name) {
            return res.status(400).json({
                success: false,
                message: 'Sender information is required'
            });
        }

        // Ensure sender._id is a valid ObjectId or create a temporary one
        let senderId = sender._id;
        if (!senderId || !mongoose.Types.ObjectId.isValid(senderId)) {
            console.log('Invalid sender ID, creating temporary ID');
            senderId = new mongoose.Types.ObjectId();
        }

        // Update sender object with valid ID
        const validSender = {
            _id: senderId,
            name: sender.name,
            avatar: sender.avatar || ''
        };

        // Validate jobId
        if (!mongoose.Types.ObjectId.isValid(jobId)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid job ID format'
            });
        }

        // Find or create chat for the job
        let chat = await Chat.findOne({ jobId });
        
        if (!chat) {
            // Verify job exists before creating chat
            const jobExists = await Job.findById(jobId);
            if (!jobExists) {
                return res.status(404).json({
                    success: false,
                    message: 'Job not found'
                });
            }

            chat = new Chat({
                jobId,
                messages: []
            });
        }

        // Add new message
        const newMessage = {
            content,
            sender: validSender,
            jobId,
            timestamp: new Date()
        };

        chat.messages.push(newMessage);
        await chat.save();

        res.status(201).json(newMessage);
    } catch (error) {
        console.error('Error adding chat message:', error);
        res.status(500).json({
            success: false,
            message: 'Error adding chat message',
            error: error.message
        });
    }
});

module.exports = router;
