const jobMatchingService = require('../../../services/job-matching.service');

describe('Job Matching Service', () => {
  describe('Location Scoring', () => {
    it('should calculate location score correctly', () => {
      // Test exact match
      const preferredLocations = ['Colombo'];
      const jobLocation = 'Colombo';
      
      // Create test objects
      const user = { 
        studentDetails: { 
          preferredLocations 
        } 
      };
      const job = { location: jobLocation };
      
      const result = jobMatchingService.calculateMatchScore(user, job);
      
      // The location component should contribute to the overall score
      expect(result.score).toBeGreaterThan(0);
      expect(Array.isArray(result.reasons)).toBe(true);
    });
  });
  
  describe('Match Score Calculation', () => {
    it('should calculate overall match score', () => {
      // Create a job with good match characteristics
      const job = {
        location: 'Colombo',
        category: 'IT',
        availableDates: [{ date: '2025-04-01', isFullDay: true }]
      };
      
      // Create a user with matching preferences
      const user = {
        studentDetails: {
          preferredLocations: ['Colombo'],
          preferredCategories: ['IT']
        },
        availability: [{ date: '2025-04-01', isFullDay: true }]
      };
      
      const result = jobMatchingService.calculateMatchScore(user, job);
      
      // Should have a score and reasons
      expect(result.score).toBeGreaterThan(0);
      expect(Array.isArray(result.reasons)).toBe(true);
    });
    
    it('should handle missing user or job data', () => {
      const result = jobMatchingService.calculateMatchScore(null, null);
      
      expect(result.score).toBe(0);
      expect(result.reasons).toContain('Invalid user or job data');
    });
  });
});
