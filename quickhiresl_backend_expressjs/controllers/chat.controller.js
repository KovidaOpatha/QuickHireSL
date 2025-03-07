const Job = require('../models/job.model');

// Get chat messages for a specific job
exports.getJobChat = async (req, res) => {
    try {
        const job = await Job.findById(req.params.jobId)
            .populate({
                path: 'chat.messages.sender',
                select: 'name email profileImage'
            });

        if (!job) {
            return res.status(404).json({ message: 'Job not found' });
        }

        res.json({ messages: job.chat.messages });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching chat messages', error: error.message });
    }
};

// Add a new message to job chat
exports.addMessage = async (req, res) => {
    try {
        const { content } = req.body;
        const userId = req.user._id; // Assuming user is authenticated

        const job = await Job.findById(req.params.jobId);
        if (!job) {
            return res.status(404).json({ message: 'Job not found' });
        }

        const newMessage = {
            sender: userId,
            content,
            timestamp: new Date()
        };

        job.chat.messages.push(newMessage);
        await job.save();

        // Populate sender information for the response
        const populatedJob = await Job.findById(job._id)
            .populate({
                path: 'chat.messages.sender',
                select: 'name email profileImage'
            });

        const addedMessage = populatedJob.chat.messages[populatedJob.chat.messages.length - 1];
        res.status(201).json(addedMessage);
    } catch (error) {
        res.status(500).json({ message: 'Error adding message', error: error.message });
    }
};
