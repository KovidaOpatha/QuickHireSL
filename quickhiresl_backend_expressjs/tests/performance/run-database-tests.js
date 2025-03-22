/**
 * Script to run database performance tests
 */
const { main: runDatabaseTests } = require('./database-performance');

console.log('Starting database performance tests...');
runDatabaseTests()
  .then(() => {
    console.log('Database performance tests completed successfully.');
  })
  .catch(error => {
    console.error('Error running database performance tests:', error);
    process.exit(1);
  });
