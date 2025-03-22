const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const Application = require('../../../models/application.model');
const User = require('../../../models/user.model');
const Job = require('../../../models/job.model');

// Mock the notification controller that might be used in the application controller
jest.mock('../../../controllers/notification.controller', () => ({
  createApplicationNotification: jest.fn().mockResolvedValue({}),
  createApplicationStatusNotification: jest.fn().mockResolvedValue({})
}));

// Import the controller directly for testing
const applicationController = require('../../../controllers/application.controller');

describe('Application Routes Integration', () => {
  let req, res, userId, jobId, jobOwnerId;
  
  beforeEach(() => {
    // Setup mock request and response
    userId = new mongoose.Types.ObjectId();
    jobId = new mongoose.Types.ObjectId();
    jobOwnerId = new mongoose.Types.ObjectId();
    
    req = {
      body: {
        jobId: jobId.toString(),
        coverLetter: 'Test cover letter'
      },
      user: {
        _id: userId.toString(),
        role: 'student'
      },
      params: {}
    };
    
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
    
    // Reset all mocks
    jest.clearAllMocks();
    
    // Mock the models
    Job.findById = jest.fn();
    User.findById = jest.fn();
    Application.find = jest.fn();
    Application.findById = jest.fn();
    Application.prototype.save = jest.fn();
  });
  
  describe('createApplication', () => {
    it('should create a new application', async () => {
      // Mock Job.findById
      const mockJob = {
        _id: jobId,
        title: 'Test Job',
        company: 'Test Company',
        location: 'Colombo',
        description: 'Test Description',
        category: 'IT',
        requirements: ['Test Requirement'],
        salary: 50000,
        employmentType: 'Full-time',
        experienceLevel: 'Entry',
        postedBy: jobOwnerId,
        availableDates: [{ date: '2025-04-01', isFullDay: true }]
      };
      
      Job.findById.mockResolvedValue(mockJob);
      
      // Mock User.findById
      const mockUser = {
        _id: userId,
        email: 'test@example.com',
        role: 'student',
        studentDetails: {
          fullName: 'Test Student'
        }
      };
      
      User.findById.mockResolvedValue(mockUser);
      
      // Mock Application.prototype.save
      const mockSavedApplication = {
        _id: new mongoose.Types.ObjectId(),
        job: jobId,
        applicant: userId,
        jobOwner: jobOwnerId,
        coverLetter: 'Test cover letter',
        status: 'pending',
        appliedAt: new Date(),
        createdAt: new Date(),
        updatedAt: new Date(),
        toObject: jest.fn().mockReturnThis()
      };
      
      Application.prototype.save.mockResolvedValue(mockSavedApplication);
      
      // Call the controller function
      await applicationController.createApplication(req, res);
      
      // Assertions
      expect(Job.findById).toHaveBeenCalledWith(jobId.toString());
      expect(User.findById).toHaveBeenCalledWith(userId.toString());
      expect(Application.prototype.save).toHaveBeenCalled();
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalled();
    });
    
    it('should return 400 if cover letter is missing', async () => {
      // Remove cover letter from request
      req.body.coverLetter = '';
      
      // Call the controller function
      await applicationController.createApplication(req, res);
      
      // Assertions
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({ message: expect.any(String) });
    });
  });
  
  describe('getApplicantApplications', () => {
    it('should return user\'s applications', async () => {
      // Mock Application.find
      const mockApplications = [{
        _id: new mongoose.Types.ObjectId(),
        job: {
          _id: jobId,
          title: 'Test Job',
          company: 'Test Company'
        },
        applicant: {
          _id: userId,
          email: 'test@example.com'
        },
        jobOwner: {
          _id: jobOwnerId,
          email: 'owner@example.com'
        },
        coverLetter: 'Test cover letter',
        status: 'pending',
        appliedAt: new Date(),
        toObject: jest.fn().mockReturnThis()
      }];
      
      // Create a simpler mock for Application.find
      Application.find.mockReturnValue({
        populate: jest.fn().mockReturnThis(),
        sort: jest.fn().mockResolvedValue(mockApplications)
      });
      
      // Call the controller function
      await applicationController.getApplicantApplications(req, res);
      
      // Assertions
      expect(Application.find).toHaveBeenCalled();
      expect(res.json).toHaveBeenCalled();
    });
  });
});
