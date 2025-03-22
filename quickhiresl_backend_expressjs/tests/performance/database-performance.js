/**
 * Performance test for database operations
 */
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const Job = require('../../models/job.model');
const User = require('../../models/user.model');
const Application = require('../../models/application.model');

// Configuration
const TEST_ITERATIONS = 100; // Number of operations to perform
const BATCH_SIZES = [1, 10, 50, 100]; // Different batch sizes to test

// Sample data generators
const generateUser = (index) => ({
  email: `user${index}@example.com`,
  password: 'password123',
  role: Math.random() > 0.5 ? 'student' : 'employer',
  studentDetails: {
    fullName: `Test User ${index}`,
    contactNumber: `123456789${index % 10}`,
    address: `Test Address ${index}`,
    education: 'Test University',
    skills: ['JavaScript', 'Node.js', 'MongoDB']
  },
  employerDetails: {
    companyName: `Test Company ${index}`,
    contactNumber: `987654321${index % 10}`,
    address: `Company Address ${index}`,
    website: `https://company${index}.example.com`
  },
  preferences: {
    locations: ['Colombo', 'Kandy'],
    jobCategories: ['IT', 'Software Development'],
    availableDates: [
      { date: `2025-04-0${index % 9 + 1}`, isFullDay: true },
      { 
        date: `2025-04-1${index % 9 + 1}`, 
        isFullDay: false,
        timeSlots: [
          { startTime: "09:00", endTime: "12:00" },
          { startTime: "13:00", endTime: "17:00" }
        ]
      }
    ]
  }
});

const generateJob = (index, userId) => ({
  title: `Test Job ${index}`,
  company: `Test Company ${index % 20}`,
  location: ['Colombo', 'Kandy', 'Galle', 'Jaffna'][index % 4],
  description: `This is a test job description ${index}`,
  category: ['IT', 'Software Development', 'Marketing', 'Finance'][index % 4],
  requirements: ['Node.js', 'MongoDB', 'Express'],
  salary: 50000 + (index * 1000),
  employmentType: ['Full-time', 'Part-time', 'Contract', 'Internship'][index % 4],
  experienceLevel: ['Entry', 'Mid-level', 'Senior', 'Lead'][index % 4],
  postedBy: userId,
  availableDates: [
    { date: `2025-04-0${index % 9 + 1}`, isFullDay: true },
    { 
      date: `2025-04-1${index % 9 + 1}`, 
      isFullDay: false,
      timeSlots: [
        { startTime: "09:00", endTime: "12:00" },
        { startTime: "14:00", endTime: "18:00" }
      ]
    }
  ],
  status: 'active'
});

/**
 * Setup MongoDB memory server for testing
 */
async function setupDatabase() {
  const mongoServer = await MongoMemoryServer.create();
  const mongoUri = mongoServer.getUri();
  
  await mongoose.connect(mongoUri);
  console.log('Connected to in-memory MongoDB server');
  
  return mongoServer;
}

/**
 * Clean up database connection
 */
async function teardownDatabase(mongoServer) {
  await mongoose.disconnect();
  await mongoServer.stop();
  console.log('Disconnected from in-memory MongoDB server');
}

/**
 * Test database read performance
 */
async function testDatabaseReadPerformance() {
  console.log('\nTesting database read performance...');
  const results = {};
  
  try {
    // Create test users and jobs first
    const users = [];
    console.log('Creating test users...');
    for (let i = 0; i < 100; i++) {
      const user = new User(generateUser(i));
      await user.save();
      users.push(user);
    }
    
    console.log('Creating test jobs...');
    for (let i = 0; i < 500; i++) {
      const job = new Job(generateJob(i, users[i % users.length]._id));
      await job.save();
    }
    
    // Test with different batch sizes
    for (const batchSize of BATCH_SIZES) {
      console.log(`\nTesting with batch size: ${batchSize}`);
      
      // Test Job.find performance
      const startTimeJobs = process.hrtime.bigint();
      
      for (let i = 0; i < TEST_ITERATIONS / batchSize; i++) {
        await Job.find().limit(batchSize);
      }
      
      const endTimeJobs = process.hrtime.bigint();
      const durationJobsMs = Number(endTimeJobs - startTimeJobs) / 1_000_000;
      
      // Test Job.find with populate
      const startTimeJobsPopulate = process.hrtime.bigint();
      
      for (let i = 0; i < TEST_ITERATIONS / batchSize; i++) {
        await Job.find().populate('postedBy', '-password').limit(batchSize);
      }
      
      const endTimeJobsPopulate = process.hrtime.bigint();
      const durationJobsPopulateMs = Number(endTimeJobsPopulate - startTimeJobsPopulate) / 1_000_000;
      
      // Calculate metrics
      const jobsPerSecond = Math.round((TEST_ITERATIONS / durationJobsMs) * 1000);
      const jobsPopulatePerSecond = Math.round((TEST_ITERATIONS / durationJobsPopulateMs) * 1000);
      
      console.log(`Job.find: ${jobsPerSecond} operations/sec (${durationJobsMs.toFixed(2)} ms total)`);
      console.log(`Job.find with populate: ${jobsPopulatePerSecond} operations/sec (${durationJobsPopulateMs.toFixed(2)} ms total)`);
      
      results[batchSize] = {
        jobsPerSecond,
        jobsPopulatePerSecond,
        durationJobsMs,
        durationJobsPopulateMs
      };
    }
    
    return results;
  } catch (error) {
    console.error('Error in read performance test:', error);
    throw error;
  }
}

/**
 * Test database write performance
 */
async function testDatabaseWritePerformance() {
  console.log('\nTesting database write performance...');
  const results = {};
  
  try {
    // Get a sample user ID for job creation
    const sampleUser = await User.findOne();
    
    // Test with different batch sizes
    for (const batchSize of BATCH_SIZES) {
      console.log(`\nTesting with batch size: ${batchSize}`);
      
      // Test Job creation performance
      const startTimeJobs = process.hrtime.bigint();
      
      for (let i = 0; i < TEST_ITERATIONS / batchSize; i++) {
        const jobs = Array.from({ length: batchSize }, (_, index) => 
          generateJob(i * batchSize + index, sampleUser._id)
        );
        
        await Job.insertMany(jobs);
      }
      
      const endTimeJobs = process.hrtime.bigint();
      const durationJobsMs = Number(endTimeJobs - startTimeJobs) / 1_000_000;
      
      // Calculate metrics
      const jobsPerSecond = Math.round((TEST_ITERATIONS / durationJobsMs) * 1000);
      
      console.log(`Job creation: ${jobsPerSecond} operations/sec (${durationJobsMs.toFixed(2)} ms total)`);
      
      results[batchSize] = {
        jobsPerSecond,
        durationJobsMs
      };
    }
    
    return results;
  } catch (error) {
    console.error('Error in write performance test:', error);
    throw error;
  }
}

/**
 * Main function
 */
async function main() {
  let mongoServer;
  
  try {
    mongoServer = await setupDatabase();
    
    // Run read performance tests
    const readResults = await testDatabaseReadPerformance();
    
    // Run write performance tests
    const writeResults = await testDatabaseWritePerformance();
    
    console.log('\n======= DATABASE PERFORMANCE SUMMARY =======');
    console.log('\nREAD OPERATIONS:');
    for (const [batchSize, result] of Object.entries(readResults)) {
      console.log(`\nBatch size: ${batchSize}`);
      console.log(`Job.find: ${result.jobsPerSecond} operations/sec`);
      console.log(`Job.find with populate: ${result.jobsPopulatePerSecond} operations/sec`);
    }
    
    console.log('\nWRITE OPERATIONS:');
    for (const [batchSize, result] of Object.entries(writeResults)) {
      console.log(`\nBatch size: ${batchSize}`);
      console.log(`Job creation: ${result.jobsPerSecond} operations/sec`);
    }
    console.log('============================================\n');
  } catch (error) {
    console.error('Error running database performance test:', error);
  } finally {
    if (mongoServer) {
      await teardownDatabase(mongoServer);
    }
  }
}

// Export for use in the main test runner
module.exports = {
  testDatabaseReadPerformance,
  testDatabaseWritePerformance,
  main
};

// Run directly if called from command line
if (require.main === module) {
  main();
}
