/**
 * Performance test for the job matching service
 */
const { runTest, printResults } = require('./utils');
const mongoose = require('mongoose');
const Job = require('../../models/job.model');
const User = require('../../models/user.model');
const { calculateMatchScore } = require('../../services/job-matching.service');

// Configuration
const TEST_ITERATIONS = 1000; // Number of match calculations to perform
const BATCH_SIZES = [10, 50, 100, 500]; // Different batch sizes to test

/**
 * Create a sample user for testing
 */
function createSampleUser() {
  return {
    _id: new mongoose.Types.ObjectId(),
    preferences: {
      locations: ['Colombo', 'Kandy'],
      jobCategories: ['IT', 'Software Development'],
      availableDates: [
        { date: '2025-04-01', isFullDay: true },
        { date: '2025-04-02', timeSlots: ['morning', 'afternoon'] }
      ]
    }
  };
}

/**
 * Create a sample job for testing
 */
function createSampleJob(location, category) {
  return {
    _id: new mongoose.Types.ObjectId(),
    title: 'Test Job',
    location: location || 'Colombo',
    category: category || 'IT',
    availableDates: [
      { date: '2025-04-01', isFullDay: true },
      { date: '2025-04-02', timeSlots: ['morning', 'evening'] }
    ]
  };
}

/**
 * Generate a batch of random jobs
 */
function generateJobs(count) {
  const locations = ['Colombo', 'Kandy', 'Galle', 'Jaffna', 'Negombo'];
  const categories = ['IT', 'Software Development', 'Marketing', 'Finance', 'Healthcare'];
  
  return Array.from({ length: count }, () => {
    const location = locations[Math.floor(Math.random() * locations.length)];
    const category = categories[Math.floor(Math.random() * categories.length)];
    return createSampleJob(location, category);
  });
}

/**
 * Test the performance of the job matching service
 */
async function testJobMatchingPerformance() {
  console.log('Testing job matching service performance...');
  
  const user = createSampleUser();
  const results = {};
  
  // Test with different batch sizes
  for (const batchSize of BATCH_SIZES) {
    console.log(`\nTesting with batch size: ${batchSize}`);
    
    // Generate jobs
    const jobs = generateJobs(batchSize);
    
    // Measure time to calculate match scores
    const startTime = process.hrtime.bigint();
    
    for (let i = 0; i < TEST_ITERATIONS / batchSize; i++) {
      for (const job of jobs) {
        calculateMatchScore(user, job);
      }
    }
    
    const endTime = process.hrtime.bigint();
    const durationMs = Number(endTime - startTime) / 1_000_000;
    
    // Calculate metrics
    const operationsPerSecond = Math.round((TEST_ITERATIONS / durationMs) * 1000);
    const avgTimePerOperation = durationMs / TEST_ITERATIONS;
    
    console.log(`Completed ${TEST_ITERATIONS} match calculations in ${durationMs.toFixed(2)} ms`);
    console.log(`Operations per second: ${operationsPerSecond}`);
    console.log(`Average time per match calculation: ${avgTimePerOperation.toFixed(3)} ms`);
    
    results[batchSize] = {
      totalTime: durationMs,
      operationsPerSecond,
      avgTimePerOperation
    };
  }
  
  return results;
}

/**
 * Main function
 */
async function main() {
  try {
    const results = await testJobMatchingPerformance();
    
    console.log('\n======= JOB MATCHING PERFORMANCE SUMMARY =======');
    for (const [batchSize, result] of Object.entries(results)) {
      console.log(`\nBatch size: ${batchSize}`);
      console.log(`Operations per second: ${result.operationsPerSecond}`);
      console.log(`Average time per operation: ${result.avgTimePerOperation.toFixed(3)} ms`);
    }
    console.log('==================================================\n');
  } catch (error) {
    console.error('Error running job matching performance test:', error);
  }
}

// Export for use in the main test runner
module.exports = {
  testJobMatchingPerformance,
  main
};

// Run directly if called from command line
if (require.main === module) {
  main();
}
