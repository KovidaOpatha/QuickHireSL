/**
 * Performance testing utility functions
 */
const fs = require('fs');
const path = require('path');
const autocannon = require('autocannon');

/**
 * Run a performance test and save the results
 * @param {Object} options - Test options
 * @param {string} options.name - Test name
 * @param {string} options.url - URL to test
 * @param {number} options.connections - Number of concurrent connections
 * @param {number} options.duration - Test duration in seconds
 * @param {Object} options.headers - Headers to include in requests
 * @param {Object} options.body - Body to include in POST requests
 * @param {string} options.method - HTTP method (GET, POST, etc.)
 * @returns {Promise<Object>} - Test results
 */
async function runTest(options) {
  const {
    name,
    url,
    connections = 10,
    duration = 10,
    headers = {},
    body = null,
    method = 'GET'
  } = options;

  console.log(`Running performance test: ${name}`);
  console.log(`URL: ${url}`);
  console.log(`Connections: ${connections}`);
  console.log(`Duration: ${duration} seconds`);
  console.log(`Method: ${method}`);
  
  const testConfig = {
    url,
    connections,
    duration,
    headers,
    method
  };
  
  if (body && method === 'POST') {
    testConfig.body = JSON.stringify(body);
    testConfig.headers['Content-Type'] = 'application/json';
  }

  return new Promise((resolve, reject) => {
    const instance = autocannon(testConfig, (err, result) => {
      if (err) {
        console.error('Error running performance test:', err);
        return reject(err);
      }
      
      // Save results to file
      const resultsDir = path.join(__dirname, 'results');
      if (!fs.existsSync(resultsDir)) {
        fs.mkdirSync(resultsDir, { recursive: true });
      }
      
      const timestamp = new Date().toISOString().replace(/:/g, '-');
      const resultsPath = path.join(resultsDir, `${name}-${timestamp}.json`);
      
      fs.writeFileSync(resultsPath, JSON.stringify(result, null, 2));
      console.log(`Results saved to: ${resultsPath}`);
      
      resolve(result);
    });
    
    // Track progress
    autocannon.track(instance, { renderProgressBar: true });
  });
}

/**
 * Format and print test results
 * @param {Object} results - Test results from autocannon
 */
function printResults(results) {
  console.log('\n======= PERFORMANCE TEST RESULTS =======');
  console.log(`Requests: ${results.requests.total}`);
  console.log(`Throughput: ${results.requests.average} req/sec`);
  console.log(`Latency (avg): ${results.latency.average} ms`);
  console.log(`Latency (min): ${results.latency.min} ms`);
  console.log(`Latency (max): ${results.latency.max} ms`);
  console.log(`Latency (p99): ${results.latency.p99} ms`);
  console.log(`Errors: ${results.errors}`);
  console.log(`Non 2xx responses: ${results.non2xx}`);
  console.log('==========================================\n');
}

/**
 * Compare results with baseline or previous test
 * @param {Object} current - Current test results
 * @param {Object} baseline - Baseline test results
 * @returns {Object} - Comparison results
 */
function compareWithBaseline(current, baseline) {
  if (!baseline) {
    console.log('No baseline to compare with.');
    return null;
  }
  
  const requestsDiff = ((current.requests.average - baseline.requests.average) / baseline.requests.average) * 100;
  const latencyDiff = ((current.latency.average - baseline.latency.average) / baseline.latency.average) * 100;
  
  console.log('\n======= COMPARISON WITH BASELINE =======');
  console.log(`Throughput: ${requestsDiff.toFixed(2)}% (${requestsDiff > 0 ? 'increase' : 'decrease'})`);
  console.log(`Latency: ${latencyDiff.toFixed(2)}% (${latencyDiff > 0 ? 'increase' : 'decrease'})`);
  console.log('==========================================\n');
  
  return {
    requestsDiff,
    latencyDiff
  };
}

module.exports = {
  runTest,
  printResults,
  compareWithBaseline
};
