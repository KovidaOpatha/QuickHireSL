const User = require('../models/user.model');
const Application = require('../models/application.model');
const Job = require('../models/job.model');

// Create a model for feedback if it doesn't exist yet
const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const FeedbackSchema = new Schema({
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },
  feedback: {
    type: String,
    required: false
  },
  applicationId: {
    type: Schema.Types.ObjectId,
    ref: 'Application',
    required: true
  },
  fromUser: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  targetUser: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const Feedback = mongoose.model('Feedback', FeedbackSchema);

const feedbackController = {
  // Submit feedback
  submitFeedback: async (req, res) => {
    try {
      const { rating, feedback, applicationId, targetUserId } = req.body;
      const fromUserId = req.user._id;

      // Validate required fields
      if (!rating || !applicationId || !targetUserId) {
        return res.status(400).json({ 
          success: false, 
          message: 'Rating, application ID, and target user ID are required' 
        });
      }

      // Validate rating is between 1-5
      if (rating < 1 || rating > 5) {
        return res.status(400).json({
          success: false,
          message: 'Rating must be between 1 and 5'
        });
      }

      // Check if application exists
      const application = await Application.findById(applicationId);
      if (!application) {
        return res.status(404).json({
          success: false,
          message: 'Application not found'
        });
      }

      // Check if target user exists
      const targetUser = await User.findById(targetUserId);
      if (!targetUser) {
        return res.status(404).json({
          success: false,
          message: 'Target user not found'
        });
      }

      // Check if user is part of the application (either job owner or applicant)
      const isJobOwner = application.jobOwner.toString() === fromUserId.toString();
      const isApplicant = application.applicant.toString() === fromUserId.toString();

      if (!isJobOwner && !isApplicant) {
        return res.status(403).json({
          success: false,
          message: 'You are not authorized to submit feedback for this application'
        });
      }

      // Check if feedback already exists
      const existingFeedback = await Feedback.findOne({
        applicationId,
        fromUser: fromUserId,
        targetUser: targetUserId
      });

      if (existingFeedback) {
        return res.status(400).json({
          success: false,
          message: 'You have already submitted feedback for this application'
        });
      }

      // Create new feedback
      const newFeedback = new Feedback({
        rating,
        feedback,
        applicationId,
        fromUser: fromUserId,
        targetUser: targetUserId
      });

      await newFeedback.save();

      // Update user's rating
      const userFeedbacks = await Feedback.find({ targetUser: targetUserId });
      const totalRating = userFeedbacks.reduce((sum, item) => sum + item.rating, 0);
      const averageRating = Math.round(totalRating / userFeedbacks.length);

      await User.findByIdAndUpdate(targetUserId, { 
        rating: averageRating,
        $inc: { completedJobs: 1 } // Increment completed jobs count
      });

      // If job owner is receiving feedback, update job rating
      if (isApplicant) {
        // The feedback is from applicant to job owner
        await Job.findByIdAndUpdate(application.job, {
          ownerRating: averageRating,
          isCompleted: true
        });
      }

      res.status(201).json({
        success: true,
        message: 'Feedback submitted successfully',
        data: newFeedback
      });
    } catch (error) {
      console.error('Error submitting feedback:', error);
      res.status(500).json({
        success: false,
        message: 'Server error while submitting feedback'
      });
    }
  },

  // Get feedback for a user
  getUserFeedback: async (req, res) => {
    try {
      const { userId } = req.params;

      const feedbacks = await Feedback.find({ targetUser: userId })
        .populate('fromUser', 'name email profileImage')
        .populate('applicationId')
        .sort({ createdAt: -1 });

      res.status(200).json({
        success: true,
        data: feedbacks
      });
    } catch (error) {
      console.error('Error getting user feedback:', error);
      res.status(500).json({
        success: false,
        message: 'Server error while getting user feedback'
      });
    }
  }
};

module.exports = feedbackController;
