const mongoose = require('mongoose');
const Application = require('../../../models/application.model');

describe('Application Model Test', () => {
  // Test case
  it('should validate required fields', () => {
    const application = new Application({});
    
    // Validate the model
    const err = application.validateSync();
    
    // Check that validation errors exist for required fields
    expect(err.errors.job).toBeDefined();
    expect(err.errors.applicant).toBeDefined();
    expect(err.errors.jobOwner).toBeDefined();
    expect(err.errors.coverLetter).toBeDefined();
  });
  
  it('should accept a valid application', () => {
    const applicationData = {
      job: new mongoose.Types.ObjectId(),
      applicant: new mongoose.Types.ObjectId(),
      jobOwner: new mongoose.Types.ObjectId(),
      coverLetter: 'Test cover letter',
      status: 'pending'
    };
    
    const application = new Application(applicationData);
    const err = application.validateSync();
    
    expect(err).toBeUndefined();
  });
});
