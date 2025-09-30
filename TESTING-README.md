# RX-DEX Testing Framework

This document explains how to use the comprehensive testing framework for the RX-DEX crypto exchange, optimized for your Xeon server with 46GB RAM and 36 cores.

## System Capabilities

Your server configuration is well-suited for concurrency testing:
- **36 CPU cores** for parallel processing
- **46GB RAM** for handling large numbers of concurrent connections
- **Multiple services** can run simultaneously without resource constraints

## Available Testing Scripts

### 1. Daily Development Workflow
```powershell
# Start all services in background jobs
.\scripts\daily-dev.ps1

# Stop all services
.\scripts\stop-daily-dev.ps1
```

### 2. Health Check
```powershell
# Verify all services are responding correctly
.\scripts\daily-health-check.ps1
```

### 3. Service Verification
```powershell
# Detailed verification of each service endpoint
.\scripts\verify-services.ps1
```

### 4. Concurrency Testing
```powershell
# Run standard concurrency test (1000 users, 100 requests each)
.\scripts\concurrency-test.ps1

# Customized test
.\scripts\concurrency-test.ps1 -concurrentUsers 2000 -requestsPerUser 50 -durationMinutes 10
```

### 5. Load Testing Suite
```powershell
# Standard load test
.\scripts\load-test-suite.ps1

# Stress test (uses all 36 cores)
.\scripts\load-test-suite.ps1 -testType stress

# Endurance test (5 minute duration)
.\scripts\load-test-suite.ps1 -testType endurance
```

### 6. Resource Monitoring
```powershell
# Monitor for 60 seconds, sample every 5 seconds
.\scripts\monitor-resources.ps1

# Long-term monitoring
.\scripts\monitor-resources.ps1 -durationSeconds 600 -intervalSeconds 10
```

### 7. Testing Dashboard
```powershell
# View all available tests and system information
.\scripts\test-dashboard.ps1
```

## Recommended Testing Scenarios

### Scenario 1: Baseline Performance Testing
```powershell
# 1. Start services
.\scripts\start-rxdex.ps1

# 2. Verify services
.\scripts\verify-services.ps1

# 3. Run standard load test
.\scripts\load-test-suite.ps1

# 4. Monitor resources during test
.\scripts\monitor-resources.ps1 -durationSeconds 60 -intervalSeconds 5
```

### Scenario 2: High-Concurrency Stress Testing
```powershell
# 1. Start services
.\scripts\start-rxdex.ps1

# 2. Run stress test using all 36 cores
.\scripts\load-test-suite.ps1 -testType stress

# 3. Monitor system resources
.\scripts\monitor-resources.ps1 -durationSeconds 120 -intervalSeconds 5
```

### Scenario 3: Endurance Testing
```powershell
# 1. Start services
.\scripts\start-rxdex.ps1

# 2. Run endurance test
.\scripts\load-test-suite.ps1 -testType endurance

# 3. Monitor resources throughout test
.\scripts\monitor-resources.ps1 -durationSeconds 360 -intervalSeconds 15
```

### Scenario 4: Custom Concurrency Testing
```powershell
# 1. Start services
.\scripts\start-rxdex.ps1

# 2. Run custom concurrency test
.\scripts\concurrency-test.ps1 -concurrentUsers 3000 -requestsPerUser 100 -durationMinutes 15

# 3. Monitor resources
.\scripts\monitor-resources.ps1 -durationSeconds 900 -intervalSeconds 30
```

## Performance Targets for Your Hardware

With your Xeon server, you should be able to achieve:
- **Concurrent Users**: 2,000-5,000 simultaneous users
- **Request Rate**: 10,000-50,000 requests per second
- **Response Time**: < 50ms for 95% of requests
- **Memory Usage**: < 75% under load
- **CPU Usage**: < 80% under load

## Interpreting Test Results

Test results are saved in the `test-results` and `monitoring` directories:
- **Concurrency Test Results**: `test-results/concurrency-test-*.txt`
- **Load Test Results**: `test-results/load-test-*.txt`
- **Resource Monitoring**: `monitoring/resource-monitor-*.csv`

Key metrics to watch:
1. **Success Rate**: Should be > 99.5%
2. **Response Time**: Average < 50ms, 95th percentile < 100ms
3. **Request Rate**: Higher is better (indicates system throughput)
4. **Resource Usage**: CPU < 80%, Memory < 75%

## Troubleshooting

### High Error Rates
1. Check service logs:
   ```powershell
   .\scripts\logs-rxdex.ps1
   ```
2. Monitor system resources during test
3. Reduce concurrent user count or request rate

### Slow Response Times
1. Check for CPU or memory bottlenecks using resource monitoring
2. Verify database performance
3. Check network latency

### Services Not Responding
1. Restart services:
   ```powershell
   .\scripts\stop-rxdex.ps1
   .\scripts\start-rxdex.ps1
   ```
2. Check Docker status:
   ```powershell
   docker-compose -f docker-compose.dev.yml ps
   ```

## Best Practices

1. **Warm-up Period**: Always run a short test before the main test to warm up services
2. **Cool-down Period**: Allow services to stabilize between tests
3. **Resource Monitoring**: Always monitor system resources during tests
4. **Incremental Testing**: Start with lower loads and gradually increase
5. **Baseline Comparison**: Keep records of baseline performance for comparison
6. **Multiple Runs**: Run tests multiple times to account for variance

## Advanced Testing Options

### Using wrk for Maximum Performance
```powershell
# Install wrk
.\scripts\install-wrk.ps1

# High-concurrency test using all cores
wrk -t36 -c3000 -d300s http://localhost:8081/quote/simple
```

### Custom Test Scripts
You can create custom PowerShell scripts for specific testing scenarios by copying and modifying existing scripts in the `scripts` directory.