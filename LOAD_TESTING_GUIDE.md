# Flutter App Load Testing Guide

This guide explains how to test your Flutter app's performance under load, similar to k6 for backend APIs.

## 🚀 Available Testing Methods

### 1. **In-App Load Testing Widget**
Access the load testing interface directly in your app:

```dart
// Navigate to load testing screen
Navigator.pushNamed(context, '/load-testing');
```

**Features:**
- Quick Test (100 operations)
- Standard Test (500 operations) 
- Stress Test (1000 operations)
- Concurrent Test (10 users)
- Memory Test
- Real-time performance metrics

### 2. **Flutter Driver Tests**
Run automated UI tests with performance monitoring:

```bash
# Run Flutter Driver tests
flutter drive --target=test_driver/app.dart --driver=test/performance/load_test.dart
```

**Test Types:**
- Multiple rapid interactions
- Memory usage under load
- UI thread performance
- Frame rate monitoring

### 3. **Command Line Load Testing**
Run load tests from command line:

```bash
# Quick test (100 operations)
dart scripts/load_test_runner.dart quick 100

# Standard test (500 operations)
dart scripts/load_test_runner.dart standard 500

# Stress test (1000 operations)
dart scripts/load_test_runner.dart stress 1000

# Memory test (300 operations)
dart scripts/load_test_runner.dart memory 300

# Network test (200 operations)
dart scripts/load_test_runner.dart network 200
```

### 4. **Programmatic Load Testing**
Use the LoadTestingService in your code:

```dart
import 'package:skillzaar/core/services/load_testing_service.dart';

final loadTestingService = LoadTestingService();

// Run comprehensive load test
final report = await loadTestingService.runLoadTests(
  iterations: 1000,
  concurrentUsers: 20,
  testDuration: Duration(minutes: 10),
);

print('Success Rate: ${report.successfulTests / report.totalTests * 100}%');
print('Average Response Time: ${report.averageResponseTime}ms');
print('Throughput: ${report.throughput} ops/sec');
```

## 📊 Performance Metrics Tracked

### Response Time Metrics
- **Average Response Time**: Mean time for operations
- **Max Response Time**: Slowest operation time
- **Min Response Time**: Fastest operation time
- **95th Percentile**: 95% of operations under this time

### Throughput Metrics
- **Operations per Second**: How many operations completed per second
- **Concurrent Users**: Number of simultaneous users supported
- **Peak Throughput**: Maximum operations per second achieved

### Error Metrics
- **Error Rate**: Percentage of failed operations
- **Success Rate**: Percentage of successful operations
- **Timeout Rate**: Percentage of operations that timed out

### Memory Metrics
- **Memory Usage**: Current memory consumption
- **Memory Growth**: Memory increase over time
- **Memory Leaks**: Unfreed memory detection

### UI Performance Metrics
- **Frame Rate**: FPS during UI operations
- **Frame Time**: Time to render each frame
- **Jank**: Dropped or delayed frames
- **Build Time**: Widget build duration

## 🎯 Performance Benchmarks

### Excellent Performance
- Average Response Time: < 50ms
- Error Rate: < 1%
- Throughput: > 100 ops/sec
- Frame Rate: 60 FPS
- Memory Growth: < 10MB/hour

### Good Performance
- Average Response Time: < 100ms
- Error Rate: < 5%
- Throughput: > 50 ops/sec
- Frame Rate: 50+ FPS
- Memory Growth: < 50MB/hour

### Acceptable Performance
- Average Response Time: < 200ms
- Error Rate: < 10%
- Throughput: > 20 ops/sec
- Frame Rate: 30+ FPS
- Memory Growth: < 100MB/hour

### Poor Performance (Needs Optimization)
- Average Response Time: > 200ms
- Error Rate: > 10%
- Throughput: < 20 ops/sec
- Frame Rate: < 30 FPS
- Memory Growth: > 100MB/hour

## 🔧 Test Configuration

### Load Test Parameters
```dart
LoadTestConfig(
  iterations: 1000,           // Number of operations
  concurrentUsers: 20,        // Simultaneous users
  testDuration: Duration(minutes: 10), // Test duration
  rampUpTime: Duration(minutes: 2),    // Gradual load increase
  rampDownTime: Duration(minutes: 1),  // Gradual load decrease
  thinkTime: Duration(milliseconds: 100), // Delay between operations
)
```

### Test Scenarios
1. **Smoke Test**: Quick validation (10-50 operations)
2. **Load Test**: Normal expected load (100-500 operations)
3. **Stress Test**: Beyond normal capacity (1000+ operations)
4. **Spike Test**: Sudden load increases
5. **Endurance Test**: Long-running tests (hours)

## 📈 Monitoring and Analysis

### Real-time Monitoring
- Performance overlay in debug mode
- Live metrics dashboard
- Alert thresholds
- Performance regression detection

### Test Reports
- JSON reports saved automatically
- Performance trend analysis
- Comparative testing results
- Detailed operation breakdowns

### Performance Profiling
- Flutter DevTools integration
- Memory profiling
- CPU profiling
- Network profiling
- Timeline analysis

## 🚨 Troubleshooting Common Issues

### High Response Times
- Check for blocking operations on main thread
- Use isolates for heavy computations
- Optimize database queries
- Implement caching strategies

### Memory Issues
- Check for memory leaks
- Implement proper disposal
- Use const widgets
- Optimize image loading

### UI Performance Issues
- Use RepaintBoundary
- Implement lazy loading
- Optimize widget rebuilds
- Check for expensive operations in build methods

### Network Performance Issues
- Implement request batching
- Use connection pooling
- Add retry mechanisms
- Optimize payload sizes

## 📱 Device-Specific Testing

### Low-End Devices
- Test on devices with 2GB RAM or less
- Use older Android versions (API 21-26)
- Test with limited CPU cores
- Monitor battery usage

### High-End Devices
- Test on latest flagship devices
- Use latest Android/iOS versions
- Test with maximum performance settings
- Monitor thermal throttling

### Network Conditions
- Test on slow networks (2G, 3G)
- Test with network interruptions
- Test with high latency
- Test with packet loss

## 🔄 Continuous Integration

### Automated Testing
```yaml
# .github/workflows/performance-tests.yml
name: Performance Tests
on: [push, pull_request]
jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: dart scripts/load_test_runner.dart standard 500
      - run: flutter drive --target=test_driver/app.dart
```

### Performance Gates
- Set minimum performance thresholds
- Block deployments on performance regressions
- Generate performance reports
- Track performance trends

## 📚 Best Practices

### Test Design
1. **Start Small**: Begin with simple tests
2. **Gradual Increase**: Slowly increase load
3. **Realistic Scenarios**: Test real user behavior
4. **Multiple Environments**: Test on different devices
5. **Regular Testing**: Run tests frequently

### Performance Optimization
1. **Profile First**: Identify bottlenecks
2. **Measure Changes**: Track performance impact
3. **Test Incrementally**: Small, frequent changes
4. **Monitor Continuously**: Real-time performance tracking
5. **Document Results**: Keep performance history

### Load Testing Strategy
1. **Baseline Testing**: Establish performance baseline
2. **Load Testing**: Test expected load
3. **Stress Testing**: Find breaking points
4. **Spike Testing**: Test sudden load increases
5. **Volume Testing**: Test with large datasets

---

*This load testing guide ensures your Flutter app performs optimally under various load conditions, similar to backend API testing with k6.*
