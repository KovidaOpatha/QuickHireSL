const mongoose = require('mongoose');
const applicationController = require('../../../controllers/application.controller');
const Application = require('../../../models/application.model');

// Mock the notification controller
jest.mock('../../../controllers/notification.controller', () => ({
  createApplicationNotification: jest.fn().mockResolvedValue({}),
  createApplicationStatusNotification: jest.fn().mockResolvedValue({})
}));

// Mock the Application model
jest.mock('../../../models/application.model', () => {
  const mockApplication = {
    findById: jest.fn(),
    find: jest.fn()
  };
  return mockApplication;
});

describe('Application Controller', () => {
  let req, res;
  
  beforeEach(() => {
    jest.clearAllMocks();
    
    req = {
      params: {
        applicationId: new mongoose.Types.ObjectId().toString()
      },
      user: {
        _id: new mongoose.Types.ObjectId().toString()
      },
      body: {}
    };
    
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
  });
  
  describe('requestCompletion', () => {
    it('should return 404 if application not found', async () => {
      // Setup mock
      const mockPopulate = jest.fn().mockReturnThis();
      Application.findById.mockReturnValue({
        populate: mockPopulate
      });
      
      // Last populate call returns null (application not found)
      mockPopulate.mockReturnValueOnce({
        populate: mockPopulate
      }).mockReturnValueOnce({
        populate: jest.fn().mockResolvedValue(null)
      });
      
      await applicationController.requestCompletion(req, res);
      
      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({ message: 'Application not found' });
    });
  });
});
