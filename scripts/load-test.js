// Load testing script for RX-DEX
// Run with: node load-test.js

const http = require('http');
const cluster = require('cluster');
const numCPUs = require('os').cpus().length;

const API_GATEWAY_URL = 'http://localhost:8080';
const TOTAL_REQUESTS = 100000; // 100K requests
const CONCURRENT_CONNECTIONS = 1000;

if (cluster.isMaster) {
  console.log(`Master ${process.pid} is running`);
  console.log(`Starting load test with ${TOTAL_REQUESTS} requests and ${CONCURRENT_CONNECTIONS} concurrent connections`);
  console.log(`Using ${numCPUs} workers`);

  // Fork workers
  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }

  let completedRequests = 0;
  let failedRequests = 0;
  let startTime = Date.now();

  cluster.on('message', (worker, message) => {
    if (message.type === 'request_complete') {
      completedRequests++;
      if (message.success) {
        // Request succeeded
      } else {
        failedRequests++;
      }

      // Log progress every 1000 requests
      if (completedRequests % 1000 === 0) {
        const elapsed = (Date.now() - startTime) / 1000;
        const rate = completedRequests / elapsed;
        console.log(`Completed: ${completedRequests}/${TOTAL_REQUESTS} (${Math.round((completedRequests/TOTAL_REQUESTS)*100)}%) - Rate: ${Math.round(rate)} req/s - Failed: ${failedRequests}`);
      }

      // Check if all requests are done
      if (completedRequests >= TOTAL_REQUESTS) {
        const elapsed = (Date.now() - startTime) / 1000;
        const rate = completedRequests / elapsed;
        console.log(`\nLoad test completed!`);
        console.log(`Total requests: ${completedRequests}`);
        console.log(`Failed requests: ${failedRequests}`);
        console.log(`Success rate: ${((completedRequests-failedRequests)/completedRequests*100).toFixed(2)}%`);
        console.log(`Total time: ${elapsed.toFixed(2)} seconds`);
        console.log(`Average rate: ${Math.round(rate)} req/s`);
        
        // Kill all workers
        for (const id in cluster.workers) {
          cluster.workers[id].kill();
        }
      }
    }
  });

  cluster.on('exit', (worker, code, signal) => {
    console.log(`Worker ${worker.process.pid} died`);
  });

} else {
  // Worker process
  console.log(`Worker ${process.pid} started`);

  let activeRequests = 0;
  let sentRequests = 0;

  function sendRequest() {
    if (sentRequests >= TOTAL_REQUESTS / numCPUs) {
      return;
    }

    if (activeRequests >= CONCURRENT_CONNECTIONS / numCPUs) {
      // Too many active requests, wait and try again
      setTimeout(sendRequest, 1);
      return;
    }

    sentRequests++;
    activeRequests++;

    // Randomly choose an endpoint to test
    const endpoints = [
      '/health',
      '/api/quote/simple'
    ];
    
    const endpoint = endpoints[Math.floor(Math.random() * endpoints.length)];
    
    const options = {
      hostname: 'localhost',
      port: 8080,
      path: endpoint,
      method: 'GET',
      timeout: 5000
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        activeRequests--;
        process.send({ type: 'request_complete', success: res.statusCode >= 200 && res.statusCode < 300 });
        // Send next request
        sendRequest();
      });
    });

    req.on('error', (e) => {
      activeRequests--;
      process.send({ type: 'request_complete', success: false });
      // Send next request
      sendRequest();
    });

    req.on('timeout', () => {
      req.destroy();
      activeRequests--;
      process.send({ type: 'request_complete', success: false });
      // Send next request
      sendRequest();
    });

    req.end();
  }

  // Start sending requests
  for (let i = 0; i < CONCURRENT_CONNECTIONS / numCPUs; i++) {
    sendRequest();
  }
}