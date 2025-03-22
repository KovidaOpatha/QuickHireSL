/**
 * Main performance test runner for QuickHireSL backend
 */
const { runTest, printResults, compareWithBaseline } = require('./utils');

// Configuration for the test server
const SERVER_URL = 'http://localhost:3000';
const API_BASE_URL = `${SERVER_URL}/api`;

// Sample JWT token for authenticated requests (replace with a valid token when testing)
const SAMPLE_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzYW1wbGUiOiJ0b2tlbiJ9.sample';

// Test definitions
const tests = [
  // Test 1: GET /api/jobs - List all jobs (unauthenticated)
  {
    name: 'list-jobs',
    url: `${API_BASE_URL}/jobs`,
    method: 'GET',
    connections: 50,
    duration: 10
  },
  
  // Test 2: GET /api/jobs/:id - Get job details (unauthenticated)
  {
    name: 'get-job-details',
    url: `${API_BASE_URL}/jobs/sample-job-id`, // Replace with a valid job ID when testing
    method: 'GET',
    connections: 50,
    duration: 10
  },
  
  // Test 3: GET /api/applications - Get user applications (authenticated)
  {
    name: 'get-user-applications',
    url: `${API_BASE_URL}/applications`,
    method: 'GET',
    connections: 20,
    duration: 10,
    headers: {
      'Authorization': `Bearer ${SAMPLE_TOKEN}`
    }
  },
  
  // Test 4: POST /api/apply - Create job application (authenticated)
  {
    name: 'create-application',
    url: `${API_BASE_URL}/apply`,
    method: 'POST',
    connections: 10,
    duration: 10,
    headers: {
      'Authorization': `Bearer ${SAMPLE_TOKEN}`
    },
    body: {
      jobId: 'sample-job-id', // Replace with a valid job ID when testing
      coverLetter: 'This is a sample cover letter for performance testing.'
    }
  },
  
  // Test 5: GET /api/jobs/matching - Get matching jobs (authenticated)
  {
    name: 'get-matching-jobs',
    url: `${API_BASE_URL}/jobs/matching`,
    method: 'GET',
    connections: 20,
    duration: 10,
    headers: {
      'Authorization': `Bearer ${SAMPLE_TOKEN}`
    }
  }
];

/**
 * Run all defined performance tests sequentially
 */
async function runAllTests() {
  console.log('Starting QuickHireSL backend performance tests...');
  console.log(`Server URL: ${SERVER_URL}`);
  console.log(`Number of tests: ${tests.length}`);
  console.log('==========================================\n');
  
  const results = {};
  
  for (const test of tests) {
    try {
      // Run the test
      const result = await runTest(test);
      
      // Print results
      printResults(result);
      
      // Store results
      results[test.name] = result;
      
      // Wait a bit between tests to let the server recover
      await new Promise(resolve => setTimeout(resolve, 2000));
    } catch (error) {
      console.error(`Error running test "${test.name}":`, error);
    }
  }
  
  console.log('All performance tests completed!');
  return results;
}

/**
 * Main function
 */
async function main() {
  try {
    // Check if we should run a specific test
    const testName = process.argv[2];
    
    if (testName) {
      const test = tests.find(t => t.name === testName);
      if (test) {
        console.log(`Running single test: ${testName}`);
        const result = await runTest(test);
        printResults(result);
      } else {
        console.error(`Test "${testName}" not found.`);
        console.log('Available tests:');
        tests.forEach(t => console.log(`- ${t.name}`));
      }
    } else {
      // Run all tests
      await runAllTests();
    }
  } catch (error) {
    console.error('Error running performance tests:', error);
    process.exit(1);
  }
}

// Run the main function
main();
