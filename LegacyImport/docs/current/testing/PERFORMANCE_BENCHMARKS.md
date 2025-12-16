# HTTP API Performance Benchmarks

Comprehensive performance benchmarking suite for the GodotBridge HTTP API. This document describes expected performance baselines, how to run benchmarks, how to interpret results, and performance optimization recommendations.

## Quick Start

### Prerequisites

```bash
# Install dependencies (if not already installed)
pip install requests psutil

# Ensure Godot is running with debug servers
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005

# Or on Windows:
./restart_godot_with_debug.bat
```

### Basic Usage

```bash
# Run full benchmark suite
cd tests/http_api
python benchmark_performance.py

# Quick benchmarks only (skip load tests)
python benchmark_performance.py --quick

# Test specific endpoint
python benchmark_performance.py --endpoint status

# Save results to file
python benchmark_performance.py --output results.json

# Skip memory profiling (faster)
python benchmark_performance.py --no-memory
```

## Benchmark Types

The suite includes three types of performance tests:

### 1. Sequential Benchmarks

Tests endpoint response time with sequential requests (no concurrency).

- **Purpose**: Baseline performance measurement
- **Requests**: 100 requests per endpoint
- **Warmup**: 5 requests before measurement
- **Metrics**: Mean, median, min, max, P95, P99, standard deviation

### 2. Concurrent Benchmarks

Tests endpoint performance under concurrent load.

- **Purpose**: Multi-client scalability testing
- **Concurrency Levels**: 1, 10, 50, 100 concurrent clients
- **Requests**: 100 total requests per level
- **Metrics**: Response times under concurrent load, throughput (RPS)

### 3. Load Tests

Sustained load over a fixed duration at target requests per second.

- **Purpose**: Stability and sustained performance
- **Duration**: 60 seconds
- **Target RPS**: 20 requests per second
- **Total Requests**: ~1200 requests
- **Metrics**: Performance degradation over time, memory stability

## Tested Endpoints

| Endpoint | Method | Description | Payload Required |
|----------|--------|-------------|------------------|
| `/status` | GET | Connection status | No |
| `/connect` | POST | Initiate connections | No |
| `/scene/list` | GET | List scenes | No |
| `/scene/current` | GET | Current scene | No |
| `/scene/load` | POST | Load scene | Yes |
| `/resonance/apply_interference` | POST | Apply interference | Yes |

## Expected Performance Baselines

These are target performance metrics for a typical development workstation:

### Sequential Performance (Single Client)

| Endpoint | Mean (ms) | P95 (ms) | P99 (ms) | Target RPS |
|----------|-----------|----------|----------|------------|
| `/status` | < 5 | < 10 | < 15 | > 200 |
| `/connect` | < 50 | < 100 | < 150 | > 20 |
| `/scene/list` | < 10 | < 20 | < 30 | > 100 |
| `/scene/current` | < 5 | < 10 | < 15 | > 200 |
| `/scene/load` | < 200 | < 400 | < 500 | > 5 |
| `/resonance/apply_interference` | < 20 | < 40 | < 60 | > 50 |

### Concurrent Performance (10 Clients)

| Endpoint | Mean (ms) | P95 (ms) | Success Rate |
|----------|-----------|----------|--------------|
| `/status` | < 15 | < 30 | > 99% |
| `/connect` | < 100 | < 200 | > 95% |
| `/scene/list` | < 25 | < 50 | > 99% |
| `/scene/current` | < 15 | < 30 | > 99% |
| `/scene/load` | < 400 | < 800 | > 95% |
| `/resonance/apply_interference` | < 50 | < 100 | > 99% |

### Load Test Performance (60s @ 20 RPS)

| Endpoint | Mean (ms) | Memory Δ (MB) | Success Rate |
|----------|-----------|---------------|--------------|
| `/status` | < 10 | < 10 | > 99% |
| `/connect` | < 60 | < 20 | > 95% |
| `/scene/list` | < 15 | < 10 | > 99% |
| `/scene/current` | < 10 | < 10 | > 99% |
| `/scene/load` | < 250 | < 50 | > 95% |
| `/resonance/apply_interference` | < 30 | < 20 | > 99% |

## Interpreting Results

### Response Time Metrics

- **Mean**: Average response time - good for overall performance assessment
- **Median**: Middle value - less affected by outliers than mean
- **P95**: 95th percentile - 95% of requests faster than this
- **P99**: 99th percentile - worst-case for most requests
- **Min/Max**: Best and worst case response times
- **Std Dev**: Consistency indicator (lower is more consistent)

### Throughput Metrics

- **RPS (Requests Per Second)**: How many requests handled per second
- **Success Rate**: Percentage of successful requests (2xx status codes)
- **Total Duration**: Wall-clock time for benchmark

### Memory Metrics

- **Memory Start**: Memory usage at benchmark start (MB)
- **Memory End**: Memory usage at benchmark end (MB)
- **Memory Delta**: Change in memory usage (MB)
  - Small positive delta (< 50 MB): Normal
  - Large positive delta (> 100 MB): Potential memory leak
  - Negative delta: Memory was freed (garbage collection)

### Performance Indicators

#### Good Performance

```
Results:
  Success Rate: 100/100 (100.0%)
  Mean:         5.23 ms
  Median:       4.98 ms
  P95:          8.45 ms
  P99:          11.23 ms
  RPS:          191.23
  Memory Delta: +2.3 MB
```

**Indicators**: Low mean/median, tight P95/P99, high RPS, minimal memory delta

#### Acceptable Performance

```
Results:
  Success Rate: 98/100 (98.0%)
  Mean:         45.67 ms
  Median:       42.34 ms
  P95:          89.12 ms
  P99:          156.78 ms
  RPS:          21.89
  Memory Delta: +15.7 MB
```

**Indicators**: Moderate latency, occasional failures acceptable, some memory growth

#### Poor Performance

```
Results:
  Success Rate: 85/100 (85.0%)
  Mean:         234.56 ms
  Median:       198.23 ms
  P95:          567.89 ms
  P99:          1234.56 ms
  RPS:          4.27
  Memory Delta: +245.8 MB
```

**Indicators**: High latency, frequent failures, large memory growth, low throughput

## Common Performance Issues

### High Response Times

**Symptoms**:
- Mean > 100ms for lightweight endpoints
- P99 > 500ms
- Increasing over time

**Possible Causes**:
1. Godot main thread blocked (VR rendering, physics)
2. TCP connection issues (DAP/LSP)
3. JSON parsing overhead
4. Network latency

**Solutions**:
- Ensure Godot running at stable 90 FPS
- Check DAP/LSP connection status
- Reduce VR scene complexity
- Use HTTP keep-alive connections

### Low Throughput (RPS)

**Symptoms**:
- RPS < 10 for simple endpoints
- Cannot handle concurrent clients
- Thread pool exhaustion

**Possible Causes**:
1. Request serialization bottlenecks
2. Godot server thread limitations
3. Resource contention

**Solutions**:
- Increase concurrent request handling
- Optimize GodotBridge request queue
- Profile with Godot profiler

### Memory Growth

**Symptoms**:
- Memory Delta > 100 MB over 60s
- Continuous growth with load
- Eventual crashes

**Possible Causes**:
1. Memory leaks in GodotBridge
2. Unclosed HTTP connections
3. JSON parsing accumulation
4. Scene loading without unloading

**Solutions**:
- Check GodotBridge for leaked references
- Implement connection pooling
- Clear request/response buffers
- Unload scenes after testing

### Request Failures

**Symptoms**:
- Success rate < 95%
- Timeout errors
- 503 Service Unavailable

**Possible Causes**:
1. DAP/LSP not connected
2. Request timeout too short
3. Godot server overloaded
4. Circuit breaker triggered

**Solutions**:
- Verify `/connect` succeeds before testing
- Increase timeout (default: 5s)
- Reduce concurrent load
- Check ConnectionManager circuit breaker state

## Performance Optimization Recommendations

### 1. Optimize Godot Main Thread

The HTTP API runs on Godot's main thread. Poor performance there affects API response times.

**Checklist**:
- [ ] Maintain 90 FPS in VR mode
- [ ] Use physics timestep of 11.1ms (1/90)
- [ ] Minimize `_process()` and `_physics_process()` work
- [ ] Use background threads for heavy computation
- [ ] Profile with Godot's built-in profiler

### 2. Optimize HTTP Server

GodotBridge HTTP server configuration can be tuned.

**Checklist**:
- [ ] Enable HTTP keep-alive connections
- [ ] Increase request queue size (default: 100)
- [ ] Use connection pooling for DAP/LSP
- [ ] Implement request batching for bulk operations
- [ ] Cache frequently accessed data (scene list, status)

### 3. Optimize Network Layer

Reduce network overhead between client and server.

**Checklist**:
- [ ] Run benchmarks on localhost only
- [ ] Use binary protocols for telemetry (not HTTP)
- [ ] Enable GZIP compression for large payloads
- [ ] Minimize JSON payload sizes
- [ ] Reuse TCP connections

### 4. Optimize Scene Loading

Scene loading is the most expensive operation.

**Checklist**:
- [ ] Preload frequently used scenes
- [ ] Use scene caching
- [ ] Implement background loading
- [ ] Unload unused scenes
- [ ] Use lighter scenes for testing

### 5. Memory Management

Prevent memory leaks and excessive allocation.

**Checklist**:
- [ ] Clear request/response buffers after use
- [ ] Implement object pooling for frequent allocations
- [ ] Use weak references where appropriate
- [ ] Monitor memory usage in long-running tests
- [ ] Profile with Godot memory profiler

### 6. Concurrent Request Handling

Scale to handle multiple clients.

**Checklist**:
- [ ] Test with realistic concurrent loads
- [ ] Implement request prioritization
- [ ] Use async processing for long operations
- [ ] Set appropriate timeouts
- [ ] Implement rate limiting to prevent overload

## Continuous Performance Testing

### Integration with CI/CD

Add performance benchmarks to your CI pipeline:

```bash
# Run quick benchmarks in CI
python benchmark_performance.py --quick --output ci-results.json

# Check if performance meets baselines
python check_performance_regression.py ci-results.json
```

### Performance Regression Detection

Compare benchmark results over time:

```bash
# Baseline (store after known good commit)
python benchmark_performance.py --output baseline.json

# After changes
python benchmark_performance.py --output current.json

# Compare (implement this script)
python compare_benchmarks.py baseline.json current.json
```

### Automated Monitoring

Set up automated performance monitoring:

1. **Scheduled Benchmarks**: Run daily/weekly benchmarks
2. **Threshold Alerts**: Alert on performance degradation
3. **Trend Analysis**: Track performance over time
4. **Environment Validation**: Ensure consistent test environment

## Benchmark Environment

For consistent results, control these variables:

### Hardware

- **CPU**: Record CPU model and core count
- **RAM**: Record total RAM and available at test start
- **GPU**: Record GPU model (affects VR rendering)
- **Storage**: SSD vs HDD affects scene loading

### Software

- **OS**: Windows 10/11, Linux, or macOS version
- **Godot**: Version 4.5+ (exact version)
- **Python**: Version 3.8+ (exact version)
- **Background Processes**: Minimize running applications

### Configuration

- **VR Mode**: Specify if VR headset connected
- **Scene Complexity**: Use consistent test scenes
- **Network**: Localhost only (no remote connections)
- **Debug Settings**: Record debug server configuration

## Example Benchmark Session

```bash
# 1. Start Godot with debug servers
./restart_godot_with_debug.bat

# 2. Wait for initialization (5-10 seconds)

# 3. Run quick benchmark to verify setup
cd tests/http_api
python benchmark_performance.py --quick --endpoint status

# 4. If successful, run full suite
python benchmark_performance.py --output results-$(date +%Y%m%d).json

# 5. Review results
cat results-*.json | jq '.endpoints.status[0]'

# 6. Compare with baselines
# (implement comparison script as needed)
```

## Troubleshooting

### Benchmark Won't Start

**Error**: "Cannot connect to HTTP API"

**Solution**:
1. Verify Godot is running: `tasklist | grep Godot`
2. Check HTTP API port: `curl http://127.0.0.1:8080/status`
3. Check debug server flags: `--dap-port 6006 --lsp-port 6005`
4. Try fallback ports: 8083, 8084, 8085

### Inconsistent Results

**Symptom**: Large variance in response times between runs

**Solution**:
1. Close background applications
2. Disable antivirus/Windows Defender temporarily
3. Ensure Godot maintains stable FPS
4. Run warmup before benchmarks
5. Increase sample size (more requests)

### Memory Tracking Not Working

**Error**: "psutil not available"

**Solution**:
```bash
pip install psutil
```

**Alternative**: Run with `--no-memory` flag to skip memory tracking

### Timeouts During Load Test

**Symptom**: Many requests timing out during sustained load

**Solution**:
1. Reduce target RPS (default: 20)
2. Increase timeout (edit `_make_request()`)
3. Check Godot server health during test
4. Verify network latency is low

## Advanced Usage

### Custom Endpoint Testing

Add your own endpoints to `ENDPOINTS` dictionary:

```python
ENDPOINTS["custom"] = EndpointConfig(
    path="/custom/endpoint",
    method="POST",
    payload={"key": "value"},
    requires_connection=True,
    description="Custom endpoint description"
)
```

### Custom Concurrency Levels

Modify `CONCURRENT_LEVELS` for different scaling tests:

```python
CONCURRENT_LEVELS = [1, 5, 10, 25, 50, 100, 200]
```

### Custom Load Test Parameters

Adjust load test duration and RPS:

```python
LOAD_TEST_DURATION = 120  # 2 minutes
LOAD_TEST_TARGET_RPS = 50  # Higher throughput
```

### Benchmark Result Analysis

Results are available as JSON for custom analysis:

```python
import json

with open('results.json', 'r') as f:
    data = json.load(f)

# Extract P95 for all endpoints
for endpoint, results in data['endpoints'].items():
    sequential = results[0]  # First result is sequential
    print(f"{endpoint}: P95 = {sequential['p95_ms']:.2f}ms")
```

## Performance Benchmarking Best Practices

1. **Isolate Tests**: Run one benchmark at a time
2. **Stable Environment**: Consistent hardware, OS, configuration
3. **Warmup Requests**: Always warm up before measurement
4. **Multiple Runs**: Run 3-5 times, report median
5. **Document Changes**: Note any code/config changes between runs
6. **Version Control**: Tag performance baseline commits
7. **Trend Tracking**: Track performance over time, not just snapshots
8. **Context Matters**: Compare apples to apples (same scene, VR state, etc.)

## Contributing

When adding new benchmarks:

1. Add endpoint configuration to `ENDPOINTS`
2. Update expected baselines in this document
3. Test with `--quick` first
4. Document any special setup requirements
5. Update troubleshooting section with any issues encountered

## References

- HTTP API Documentation: `addons/godot_debug_connection/HTTP_API.md`
- GodotBridge Implementation: `addons/godot_debug_connection/godot_bridge.gd`
- Telemetry Guide: `TELEMETRY_GUIDE.md`
- Testing Framework: `tests/http_api/README.md`

## Support

For performance issues or questions:

1. Check troubleshooting section above
2. Review HTTP API documentation
3. Check Godot console for errors
4. Examine GodotBridge logs
5. File issue with benchmark results attached
