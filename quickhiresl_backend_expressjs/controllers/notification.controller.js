const Notification = require('../models/notification.model');
const User = require('../models/user.model');

// Get user's notifications
exports.getUserNotifications = async (req, res) => {
    try {
        const notifications = await Notification.find({ recipient: req.user._id })
            .sort({ createdAt: -1 })
            .populate('relatedJob');
        
        res.status(200).json(notifications);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching notifications', error: error.message });
    }
};

// Mark notification as read
exports.markAsRead = async (req, res) => {
    try {
        const notification = await Notification.findByIdAndUpdate(
            req.params.notificationId,
            { read: true },
            { new: true }
        );
        
        if (!notification) {
            return res.status(404).json({ message: 'Notification not found' });
        }
        
        res.status(200).json(notification);
    } catch (error) {
        res.status(500).json({ message: 'Error updating notification', error: error.message });
    }
};

// Mark all notifications as read
exports.markAllAsRead = async (req, res) => {
    try {
        await Notification.updateMany(
            { recipient: req.user._id },
            { read: true }
        );
        
        res.status(200).json({ message: 'All notifications marked as read' });
    } catch (error) {
        res.status(500).json({ message: 'Error updating notifications', error: error.message });
    }
};

// Create notification for new job
exports.createJobNotification = async (jobData, jobOwnerId) => {
    try {
        // Find all students
        const students = await User.find({ role: 'student' });
        
        // Create notifications for each student
        const notifications = students.map(student => ({
            recipient: student._id,
            type: 'job_posted',
            title: 'New Job Opportunity',
            message: `New job posted: ${jobData.title} at ${jobData.company}`,
            relatedJob: jobData._id
        }));
        
        // Insert all notifications
        const createdNotifications = await Notification.insertMany(notifications);
        
        // Update users' notification arrays
        await Promise.all(students.map(async (student) => {
            await User.findByIdAndUpdate(
                student._id,
                { $push: { notifications: { $each: createdNotifications.filter(n => n.recipient.equals(student._id)) } } }
            );
        }));
        
        return createdNotifications;
    } catch (error) {
        console.error('Error creating job notifications:', error);
        throw error;
    }
};

// Create notification for job application
exports.createApplicationNotification = async (applicationData, applicantData, jobData) => {
    try {
        // Only create notification for job owner
        const notification = {
            recipient: jobData.postedBy,
            type: 'application_received',
            title: 'New Job Application',
            message: `${applicantData.fullName || 'Unknown Applicant'} has applied for your job: ${jobData.title}`,
            relatedJob: jobData._id
        };
        
        // Insert notification
        const createdNotification = await Notification.create(notification);
        
        // Update job owner's notification array
        await User.findByIdAndUpdate(
            jobData.postedBy,
            { $push: { notifications: createdNotification._id } }
        );
        
        return createdNotification;
    } catch (error) {
        console.error('Error creating application notification:', error);
        throw error;
    }
};  

// Create notification for application status change
exports.createApplicationStatusNotification = async (applicationData, jobData, newStatus) => {
    try {
        // Format status message
        let statusMessage = '';
        let statusTitle = '';
        
        switch (newStatus) {
            case 'accepted':
                statusTitle = 'Application Accepted';
                statusMessage = `Your application for ${jobData.title} has been accepted!`;
                break;
            case 'rejected':
                statusTitle = 'Application Rejected';
                statusMessage = `Your application for ${jobData.title} has been rejected.`;
                break;
            case 'completion_requested':
                statusTitle = 'Job Completion Requested';
                statusMessage = `Job completion has been requested for ${jobData.title}.`;
                break;
            case 'completed':
                statusTitle = 'Job Completed';
                statusMessage = `Your job ${jobData.title} has been marked as completed.`;
                break;
            default:
                statusTitle = 'Application Status Updated';
                statusMessage = `Your application status for ${jobData.title} has been updated to ${newStatus}.`;
        }
        
        // Create notification for applicant
        const notification = {
            recipient: applicationData.applicant,
            type: 'application_status_changed',
            title: statusTitle,
            message: statusMessage,
            relatedJob: jobData._id
        };
        
        // Insert notification
        const createdNotification = await Notification.create(notification);
        
        // Update applicant's notification array
        await User.findByIdAndUpdate(
            applicationData.applicant,
            { $push: { notifications: createdNotification._id } }
        );
        
        return createdNotification;
    } catch (error) {
        console.error('Error creating application status notification:', error);
        throw error;
    }
};

