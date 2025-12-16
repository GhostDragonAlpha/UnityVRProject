# HTTP API Monitoring and Profiling Guide

## Overview

This guide covers the production monitoring and profiling infrastructure for the SpaceTime VR HTTP API. The system provides real-time observability through Prometheus metrics, Grafana dashboards, detailed performance profiling, and comprehensive health checks.

## Table of Contents

1. [Architecture](#architecture)
2. [Prometheus Metrics](#prometheus-metrics)
3. [Grafana Dashboards](#grafana-dashboards)
4. [Performance Profiling](#performance-profiling)
5. [Health Checks](#health-checks)
6. [Alerting Rules](#alerting-rules)
7. [Setup Instructions](#setup-instructions)
8. [Common Investigations](#common-investigations)
9. [Alert Response Procedures](#alert-response-procedures)

---

## Architecture

### Components

```
┌─────────────────┐
│   HTTP API      │
│  (GodotBridge)  │
└────────┬────────┘
         │
         ├─────► MetricsExporter ──────► /metrics (Prometheus format)
         │
         ├─────► HttpApiProfiler ──────► /debug/profile (detailed timing)
         │
         └─────► HealthCheckSystem ────► /health (subsystem status)

                      ▼
              ┌──────────────┐
              │  Prometheus  │  ◄─── Scrapes metrics every 15s
              └──────┬───────┘
                     │
                     ├─────► Grafana Dashboards (visualization)
                     │
                     └─────► AlertManager (alerting)
```

### File Structure

```
C:/godot/
├── scripts/http_api/
│   ├── metrics_exporter.gd       # Prometheus metrics collection
│   ├── profiler.gd                # Request performance profiling
│   └── health_check.gd            # Health check system
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus_alerts.yml  # Alert rules
│   └── grafana/
│       └── dashboards/
│           └── http_api_overview.json  # Main dashboard
└── MONITORING.md                  # This file
```

---

## Prometheus Metrics

### Metrics Exposed at `/metrics`

#### Request Metrics

**`http_requests_total`** (counter)
- Description: Total HTTP requests by endpoint, method, and status code
- Labels: `endpoint`, `method`, `status`
- Example query: `rate(http_requests_total[5m])`

**`http_request_duration_seconds`** (histogram)
- Description: Request duration in seconds
- Labels: `endpoint`
- Buckets: 5ms, 10ms, 25ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s, 10s
- Example query: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`

**`http_request_size_bytes`** (histogram)
- Description: HTTP request body size in bytes
- Labels: `endpoint`
- Buckets: 100B, 500B, 1KB, 5KB, 10KB, 50KB, 100KB, 500KB, 1MB, 5MB
- Example query: `histogram_quantile(0.95, rate(http_request_size_bytes_bucket[5m]))`

**`http_response_size_bytes`** (histogram)
- Description: HTTP response body size in bytes
- Labels: `endpoint`
- Buckets: Same as request size
- Example query: `histogram_quantile(0.95, rate(http_response_size_bytes_bucket[5m]))`

**`http_request_latency_ms`** (gauge)
- Description: Pre-calculated latency percentiles
- Labels: `quantile` (0.50, 0.90, 0.95, 0.99)
- Example: `http_request_latency_ms{quantile="0.95"}`

#### Scene Operation Metrics

**`scene_loads_total`** (counter)
- Description: Total successful scene loads
- Labels: `scene` (scene path)
- Example query: `rate(scene_loads_total[5m])`

**`scene_load_errors_total`** (counter)
- Description: Total scene load errors
- Labels: `error_type`
- Example query: `sum(rate(scene_load_errors_total[5m])) by (error_type)`

#### Authentication Metrics

**`auth_attempts_total`** (counter)
- Description: Authentication attempts
- Labels: `result` (success, invalid_token, missing_token, expired_token)
- Example query: `rate(auth_attempts_total{result!="success"}[5m])`

#### Rate Limiting Metrics

**`rate_limit_hits_total`** (counter)
- Description: Rate limit hits
- Labels: `endpoint`
- Example query: `topk(5, rate(rate_limit_hits_total[1m]))`

#### Connection Metrics

**`active_connections`** (gauge)
- Description: Current number of active HTTP connections
- Example query: `active_connections`

### Metric Collection

The `MetricsExporter` class automatically collects metrics for all HTTP requests. To integrate with an existing HTTP router:

```gdscript
# In your HTTP handler
var metrics = MetricsExporter.new()

func handle_request(endpoint: String, method: String):
    var start_time = Time.get_ticks_msec()
    var request_size = request.body.length()

    # ... handle request ...

    var duration_ms = Time.get_ticks_msec() - start_time
    var response_size = response.body.length()

    metrics.record_request(endpoint, method, status_code,
                          duration_ms, request_size, response_size)
```

---

## Grafana Dashboards

### HTTP API Overview Dashboard

Location: `monitoring/grafana/dashboards/http_api_overview.json`

#### Panels

1. **Request Rate** (Time Series)
   - Total requests/sec
   - Breakdown by status code (2xx, 4xx, 5xx)

2. **Error Rate** (Stat)
   - Percentage of 5xx errors
   - Color-coded thresholds: <1% green, 1-5% yellow, >5% red

3. **Active Connections** (Stat)
   - Current active connections
   - Alert if 0 (service down) or >95 (near capacity)

4. **Request Latency Percentiles** (Time Series)
   - p50, p90, p95, p99 latency over time

5. **Latency Summary** (Stat)
   - Current p50, p95, p99 values
   - Color-coded: <100ms green, 100-500ms yellow, >500ms red

6. **Scene Operations** (Time Series)
   - Scene loads/sec
   - Scene errors/sec

7. **Scene Load Success Rate** (Gauge)
   - Percentage of successful loads
   - Target: >95%

8. **Authentication Metrics** (Time Series)
   - Successful vs failed auth attempts

9. **Rate Limit Hits** (Time Series)
   - Rate limit hits by endpoint

10. **Memory Usage** (Time Series)
    - Process memory usage in MB

11. **Top Endpoints by Request Count** (Table)
    - Most frequently accessed endpoints

12. **Top Endpoints by Latency** (Table)
    - Slowest endpoints (p95)

13. **Request/Response Size** (Time Series)
    - p95 request and response sizes

14. **Scene Load Errors by Type** (Pie Chart)
    - Breakdown of error types

15. **Recent Alerts** (Alert List)
    - Active and recent alerts

### Accessing the Dashboard

1. Open Grafana: `http://localhost:3000`
2. Navigate to Dashboards → Browse
3. Open "HTTP API Overview - SpaceTime VR"

---

## Performance Profiling

### HttpApiProfiler

The profiler tracks detailed timing for each request phase:

- **Auth validation**: Time spent validating authentication
- **Scene validation**: Time spent validating scene paths
- **File I/O**: Time spent reading/loading scene files
- **Response serialization**: Time spent converting response to JSON

### Using the Profiler

```gdscript
var profiler = HttpApiProfiler.new()

# Start profiling request
profiler.start_request("/scene", "POST", "req_12345")

# Profile each phase
profiler.start_phase("auth_validation")
# ... do auth validation ...
profiler.end_phase({"user": "api_client"})

profiler.start_phase("scene_validation")
# ... validate scene ...
profiler.end_phase({"scene": scene_path})

profiler.start_phase("file_io")
# ... load scene file ...
profiler.end_phase({"file_size": 1024})

profiler.start_phase("response_serialization")
# ... build response ...
profiler.end_phase({"response_size": 512})

# Complete request
var profile = profiler.end_request(200, 512)

# Profile contains detailed timing breakdown
```

### Debug Profile Endpoint

**GET/POST `/debug/profile`**

Requires authentication.

**Query Parameters:**
- `endpoint` - Filter by endpoint
- `method` - Filter by HTTP method
- `slow_only=true` - Only show slow requests (>100ms)
- `min_duration_ms` - Minimum duration filter

**Example Response:**
```json
{
  "timestamp": "2025-12-02 15:30:45",
  "total_profiles": 1000,
  "filtered_count": 15,
  "recent_requests": [
    {
      "request_id": "scene_1733158245",
      "endpoint": "/scene",
      "method": "POST",
      "total_duration_ms": 145.3,
      "is_slow": true,
      "phases": [
        {
          "name": "auth_validation",
          "duration_ms": 2.1,
          "details": {}
        },
        {
          "name": "scene_validation",
          "duration_ms": 15.8,
          "details": {"scene": "res://vr_main.tscn"}
        },
        {
          "name": "file_io",
          "duration_ms": 125.2,
          "details": {"file_size": 2048576}
        },
        {
          "name": "response_serialization",
          "duration_ms": 2.2,
          "details": {}
        }
      ]
    }
  ],
  "slow_requests": [...],
  "phase_statistics": {
    "auth_validation": {
      "avg_ms": 1.8,
      "max_ms": 5.2,
      "min_ms": 0.5,
      "count": 1000
    },
    ...
  },
  "endpoint_summary": {
    "/scene": {
      "count": 500,
      "avg_ms": 45.2,
      "max_ms": 145.3,
      "slow_count": 15
    }
  }
}
```

### Flame Graphs

**GET/POST `/debug/profile/flamegraph`**

**Query Parameters:**
- `request_id` - Specific request to analyze (optional, defaults to slowest recent)

**Example Response:**
```json
{
  "request_id": "scene_1733158245",
  "total_duration_ms": 145.3,
  "flame_graph": {
    "name": "POST /scene",
    "value": 145.3,
    "children": [
      {
        "name": "auth_validation",
        "value": 2.1,
        "details": {}
      },
      {
        "name": "scene_validation",
        "value": 15.8,
        "details": {"scene": "res://vr_main.tscn"}
      },
      {
        "name": "file_io",
        "value": 125.2,
        "details": {"file_size": 2048576}
      },
      {
        "name": "response_serialization",
        "value": 2.2,
        "details": {}
      }
    ]
  }
}
```

Visualize flame graphs using tools like:
- SpeedScope: https://www.speedscope.app/
- Flame Graph Generator: https://www.brendangregg.com/flamegraphs.html

---

## Health Checks

### HealthCheckSystem

Performs comprehensive subsystem health monitoring.

### Health Check Endpoint

**GET `/health`**

Public endpoint (no auth required).

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-12-02 15:30:45",
  "check_duration_ms": 12.5,
  "healthy": true,
  "issues": [],
  "subsystems": {
    "scene_loader": {
      "status": "healthy",
      "message": "Scene loader operational",
      "check_duration_ms": 8.2,
      "details": {
        "scene_path": "res://vr_main.tscn",
        "load_time_ms": 8.2
      }
    },
    "file_system": {
      "status": "healthy",
      "message": "File system accessible",
      "check_duration_ms": 1.5,
      "details": {
        "file_count": 156
      }
    },
    "memory": {
      "status": "healthy",
      "message": "Memory usage normal",
      "check_duration_ms": 0.3,
      "details": {
        "static_memory_mb": 128.5,
        "dynamic_memory_mb": 256.3,
        "total_memory_mb": 384.8,
        "warning_threshold_mb": 512.0,
        "critical_threshold_mb": 1024.0
      }
    },
    "connections": {
      "status": "degraded",
      "message": "LSP disconnected",
      "check_duration_ms": 0.8,
      "details": {
        "dap_connected": true,
        "lsp_connected": false,
        "dap_port": 6006,
        "lsp_port": 6005
      }
    },
    "resource_loader": {
      "status": "healthy",
      "message": "Resource loader operational",
      "check_duration_ms": 0.5,
      "details": {
        "resources_loading": 0
      }
    },
    "engine": {
      "status": "healthy",
      "message": "Engine running normally",
      "check_duration_ms": 1.2,
      "details": {
        "fps": 90.0,
        "frame_time_ms": 11.1,
        "godot_version": "4.5.0.stable",
        "is_paused": false
      }
    }
  }
}
```

### Health Status Levels

- **healthy**: All systems operational
- **degraded**: Some non-critical issues (e.g., LSP disconnected)
- **unhealthy**: Critical issues detected (e.g., scene loader failing)
- **unknown**: Unable to determine status

### Quick Health Check

**GET `/health/quick`**

Lightweight health check for frequent polling.

**Response:**
```json
{
  "healthy": true,
  "check_duration_ms": 0.5,
  "memory_mb": 384.8,
  "fps": 90.0
}
```

---

## Alerting Rules

Location: `monitoring/prometheus/prometheus_alerts.yml`

### Critical Alerts

#### HighHTTPErrorRate
- **Condition**: Error rate >5% for 5 minutes
- **Severity**: Critical
- **Action**: Immediate investigation required

#### CriticalSlowRequests
- **Condition**: p99 latency >2 seconds for 5 minutes
- **Severity**: Critical
- **Action**: Check profiling data, investigate slow endpoints

#### CriticalAuthFailureRate
- **Condition**: >50 failed auth attempts/min for 2 minutes
- **Severity**: Critical (Security)
- **Action**: Possible brute force attack, investigate immediately

#### CriticalMemoryUsage
- **Condition**: Memory >1GB for 5 minutes
- **Severity**: Critical
- **Action**: Check for memory leaks, restart service if necessary

#### HTTPAPIDown
- **Condition**: No active connections for 2 minutes
- **Severity**: Critical
- **Action**: Service down, restart immediately

#### HealthCheckFailing
- **Condition**: Health check endpoint down for 2 minutes
- **Severity**: Critical
- **Action**: Service unresponsive, investigate immediately

### Warning Alerts

#### SlowRequestLatency
- **Condition**: p95 latency >500ms for 10 minutes
- **Severity**: Warning
- **Action**: Review profiling data, optimize slow endpoints

#### HighRateLimitHits
- **Condition**: >50 rate limit hits/min for 5 minutes
- **Severity**: Warning
- **Action**: Review rate limit configuration, check for abuse

#### HighAuthFailureRate
- **Condition**: >10 failed auth attempts/min for 5 minutes
- **Severity**: Warning
- **Action**: Monitor for potential attack, review auth logs

#### HighMemoryUsage
- **Condition**: Memory >800MB for 10 minutes
- **Severity**: Warning
- **Action**: Monitor memory trends, prepare to investigate

#### HighSceneLoadErrorRate
- **Condition**: Scene error rate >10% for 5 minutes
- **Severity**: Warning
- **Action**: Check scene files, review error types

#### ServiceDegraded
- **Condition**: Health status degraded for 5 minutes
- **Severity**: Warning
- **Action**: Review subsystem details, address degradation

#### EndpointHighErrorRate
- **Condition**: Endpoint-specific error rate >20% for 5 minutes
- **Severity**: Warning
- **Action**: Investigate specific endpoint, check implementation

---

## Setup Instructions

### Prerequisites

- Godot Engine 4.5+ with HTTP API running
- Prometheus server
- Grafana server
- AlertManager (optional, for alert routing)

### 1. Configure Prometheus

Edit `prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

rule_files:
  - "C:/godot/monitoring/prometheus/prometheus_alerts.yml"

scrape_configs:
  - job_name: 'godot_http_api'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    scrape_interval: 15s
    scrape_timeout: 10s
```

### 2. Start Prometheus

```bash
prometheus --config.file=prometheus.yml
```

Access Prometheus UI: `http://localhost:9090`

### 3. Configure Grafana

1. Add Prometheus as data source:
   - URL: `http://localhost:9090`
   - Access: Server (default)

2. Import dashboard:
   - Navigate to Dashboards → Import
   - Upload `monitoring/grafana/dashboards/http_api_overview.json`
   - Select Prometheus data source

### 4. Integrate with HTTP API

Add metrics endpoint to your HTTP router:

```gdscript
# In godot_bridge.gd or equivalent
var metrics_exporter = MetricsExporter.new()
var profiler = HttpApiProfiler.new()
var health_check = HealthCheckSystem.new()

func _handle_request(endpoint: String, method: String, ...):
    # Start profiling
    profiler.start_request(endpoint, method)

    # Handle request phases with profiling
    profiler.start_phase("auth_validation")
    var auth_result = validate_auth(request)
    profiler.end_phase()

    # ... more phases ...

    # Complete and record metrics
    var profile = profiler.end_request(status_code, response.length())
    metrics_exporter.record_request(endpoint, method, status_code,
                                    profile.total_duration_ms,
                                    request.length(), response.length())

# Add monitoring endpoints
func handle_metrics_request():
    return metrics_exporter.export_metrics()

func handle_health_request():
    return JSON.stringify(health_check.perform_health_check())

func handle_profile_request(filters):
    return JSON.stringify(profiler.get_profile_data(filters))
```

### 5. Test Setup

```bash
# Test metrics endpoint
curl http://localhost:8080/metrics

# Test health endpoint
curl http://localhost:8080/health

# Test profile endpoint (requires auth)
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/debug/profile

# Query Prometheus
curl 'http://localhost:9090/api/v1/query?query=http_requests_total'
```

---

## Common Investigations

### Investigating High Latency

1. **Check Grafana Dashboard**
   - Open "Request Latency Percentiles" panel
   - Identify when latency increased
   - Check "Top Endpoints by Latency" table

2. **Query Profile Endpoint**
   ```bash
   curl -H "Authorization: Bearer TOKEN" \
        'http://localhost:8080/debug/profile?slow_only=true'
   ```

3. **Analyze Phase Breakdown**
   - Look at `phase_statistics` in profile response
   - Identify which phase is slow (auth, validation, file I/O, serialization)

4. **Generate Flame Graph**
   ```bash
   curl -H "Authorization: Bearer TOKEN" \
        'http://localhost:8080/debug/profile/flamegraph'
   ```

5. **Prometheus Queries**
   ```promql
   # 95th percentile by endpoint
   histogram_quantile(0.95,
     sum by (endpoint, le) (rate(http_request_duration_seconds_bucket[5m]))
   )

   # Slowest endpoints
   topk(10,
     histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
   )
   ```

### Investigating High Error Rate

1. **Check Error Rate Panel**
   - Identify when errors started
   - Check if it's all endpoints or specific ones

2. **Query Error Breakdown**
   ```promql
   # Error rate by endpoint
   sum by (endpoint, status) (rate(http_requests_total{status=~"5.."}[5m]))

   # Error rate by status code
   sum by (status) (rate(http_requests_total{status=~"5.."}[5m]))
   ```

3. **Check Scene Load Errors**
   ```promql
   # Scene errors by type
   sum by (error_type) (rate(scene_load_errors_total[5m]))
   ```

4. **Review Health Status**
   ```bash
   curl http://localhost:8080/health
   ```

5. **Check Godot Logs**
   - Look for error messages in Godot console
   - Check for failed scene loads, resource errors

### Investigating Memory Issues

1. **Check Memory Panel**
   - Identify memory growth patterns
   - Check if memory is growing over time (leak) or spiking (large requests)

2. **Query Memory Metrics**
   ```promql
   # Memory usage over time
   process_resident_memory_bytes / 1024 / 1024

   # Memory growth rate
   rate(process_resident_memory_bytes[5m])
   ```

3. **Check Health Endpoint**
   ```bash
   curl http://localhost:8080/health | jq '.subsystems.memory'
   ```

4. **Review Request/Response Sizes**
   ```promql
   # Large requests
   histogram_quantile(0.95, rate(http_request_size_bytes_bucket[5m]))

   # Large responses
   histogram_quantile(0.95, rate(http_response_size_bytes_bucket[5m]))
   ```

5. **Profile Memory Usage**
   - Check for large scene files being loaded
   - Look for response serialization creating large objects

### Investigating Security Issues

1. **Check Authentication Metrics**
   ```promql
   # Failed auth rate
   rate(auth_attempts_total{result!="success"}[1m])

   # Failed auth by result type
   sum by (result) (rate(auth_attempts_total{result!="success"}[5m]))
   ```

2. **Check Rate Limit Hits**
   ```promql
   # Rate limit hits by endpoint
   sum by (endpoint) (rate(rate_limit_hits_total[1m]))

   # Top offenders
   topk(5, rate(rate_limit_hits_total[1m]))
   ```

3. **Review Alert History**
   - Check for CriticalAuthFailureRate alerts
   - Look for patterns in failed attempts

4. **Investigate Source**
   - Review HTTP request logs
   - Check for suspicious patterns (automated attacks, brute force)

---

## Alert Response Procedures

### Critical Alerts

#### HighHTTPErrorRate / CriticalSlowRequests
1. **Immediate Actions**
   - Check Grafana dashboard for affected endpoints
   - Review recent deployments/changes
   - Check health endpoint: `curl http://localhost:8080/health`

2. **Investigation**
   - Query profile endpoint for slow requests
   - Check Godot console for errors
   - Review recent scene load errors

3. **Mitigation**
   - If specific endpoint, disable if possible
   - If all endpoints, consider restarting service
   - Roll back recent changes if applicable

4. **Resolution**
   - Fix underlying issue (code, configuration, resources)
   - Deploy fix
   - Monitor for recurrence

#### CriticalAuthFailureRate (Security)
1. **Immediate Actions**
   - Check AlertManager for alert details
   - Review failed auth attempts in metrics
   - Identify source IP/client if possible

2. **Threat Assessment**
   - Determine if automated attack or legitimate issue
   - Check for patterns (same IP, timing)

3. **Mitigation**
   - If attack: block source IP at firewall/load balancer
   - If legitimate: check for token expiration issues
   - Consider temporary rate limit reduction

4. **Post-Incident**
   - Review auth logs
   - Update security procedures if needed
   - Document incident

#### CriticalMemoryUsage / Memory Leak
1. **Immediate Actions**
   - Check memory panel in Grafana
   - Review health endpoint memory details
   - Check for memory growth trend

2. **Investigation**
   - Review recent requests (large scenes, responses)
   - Check profiler for memory-intensive operations
   - Look for resource leaks (unclosed file handles, etc.)

3. **Mitigation**
   - If growing continuously: likely leak, restart service
   - If spiking: optimize large operations
   - Consider reducing cache sizes

4. **Resolution**
   - Fix memory leak in code
   - Add resource cleanup
   - Monitor after fix deployment

#### HTTPAPIDown / HealthCheckFailing
1. **Immediate Actions**
   - Check if Godot process is running
   - Attempt to connect: `curl http://localhost:8080/health`
   - Check Godot console output

2. **Diagnosis**
   - Process crashed: check crash logs
   - Process hanging: check for deadlocks
   - Network issue: check firewall, port bindings

3. **Recovery**
   - Restart Godot with debug flags:
     ```bash
     godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
     ```
   - Or use restart script:
     ```bash
     ./restart_godot_with_debug.bat
     ```

4. **Post-Mortem**
   - Review logs leading to failure
   - Identify root cause
   - Implement fixes and monitoring improvements

### Warning Alerts

#### SlowRequestLatency / HighSceneLoadErrorRate
1. **Monitor Trend**
   - Check if issue is worsening or stable
   - Review affected endpoints/scenes

2. **Investigate**
   - Use profile endpoint to identify bottlenecks
   - Check scene file sizes and complexity
   - Review recent changes

3. **Optimize**
   - Optimize slow code paths
   - Reduce scene complexity if possible
   - Consider caching frequently loaded scenes

4. **Validate**
   - Deploy optimizations
   - Monitor metrics for improvement

#### HighRateLimitHits / ServiceDegraded
1. **Assess Impact**
   - Check if legitimate traffic or abuse
   - Review health subsystem details

2. **Investigate**
   - For rate limits: check client behavior
   - For degradation: review affected subsystems

3. **Adjust**
   - Tune rate limits if needed
   - Address subsystem issues (reconnect LSP, etc.)

4. **Monitor**
   - Track metrics after adjustments
   - Update alert thresholds if needed

---

## Example Queries

### Prometheus Queries

```promql
# Overall request rate
sum(rate(http_requests_total[5m]))

# Error rate percentage
sum(rate(http_requests_total{status=~"5.."}[5m])) /
sum(rate(http_requests_total[5m])) * 100

# 95th percentile latency (all endpoints)
histogram_quantile(0.95,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
)

# 95th percentile latency by endpoint
histogram_quantile(0.95,
  sum by (endpoint, le) (rate(http_request_duration_seconds_bucket[5m]))
)

# Top 5 slowest endpoints
topk(5,
  histogram_quantile(0.95,
    sum by (endpoint, le) (rate(http_request_duration_seconds_bucket[5m]))
  )
)

# Scene load success rate
sum(rate(scene_loads_total[5m])) /
(sum(rate(scene_loads_total[5m])) + sum(rate(scene_load_errors_total[5m]))) * 100

# Auth failure rate
sum(rate(auth_attempts_total{result!="success"}[1m]))

# Rate limit hits by endpoint
sum by (endpoint) (rate(rate_limit_hits_total[5m]))

# Memory usage trend
rate(process_resident_memory_bytes[5m])

# Request rate by status code
sum by (status) (rate(http_requests_total[5m]))

# Top endpoints by request count
topk(10,
  sum by (endpoint) (rate(http_requests_total[5m]))
)

# Average request size
sum(rate(http_request_size_bytes_sum[5m])) /
sum(rate(http_request_size_bytes_count[5m]))

# Active connections over time
active_connections
```

### cURL Commands

```bash
# Get current metrics
curl http://localhost:8080/metrics

# Health check
curl http://localhost:8080/health | jq

# Quick health check
curl http://localhost:8080/health/quick | jq

# Profile data (requires auth)
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:8080/debug/profile | jq

# Filter slow requests
curl -H "Authorization: Bearer YOUR_TOKEN" \
     'http://localhost:8080/debug/profile?slow_only=true' | jq

# Filter by endpoint
curl -H "Authorization: Bearer YOUR_TOKEN" \
     'http://localhost:8080/debug/profile?endpoint=/scene' | jq

# Get flame graph for slowest request
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:8080/debug/profile/flamegraph | jq

# Prometheus query API
curl 'http://localhost:9090/api/v1/query?query=http_requests_total'

# Prometheus range query (last hour)
curl 'http://localhost:9090/api/v1/query_range?query=rate(http_requests_total[5m])&start=2025-12-02T14:00:00Z&end=2025-12-02T15:00:00Z&step=15s'
```

---

## Best Practices

### Metrics Collection
- Keep metrics cardinality low (avoid high-cardinality labels like user IDs)
- Use histograms for latency and sizes
- Record both successes and failures
- Tag metrics with relevant dimensions (endpoint, method, status)

### Performance Profiling
- Profile all requests, not just slow ones
- Keep profile history limited (1000 requests max)
- Use profiling to identify optimization opportunities
- Generate flame graphs for complex performance issues

### Health Checks
- Run health checks regularly but not too frequently (every 30s-1m)
- Include all critical subsystems
- Provide actionable details in health status
- Use quick health checks for high-frequency polling

### Alerting
- Set alert thresholds based on actual performance baselines
- Use warning alerts for trends, critical alerts for immediate issues
- Include runbook links in alert annotations
- Test alert rules regularly

### Dashboard Design
- Group related panels together
- Use appropriate visualizations (time series for trends, stats for current values)
- Include relevant time ranges and refresh intervals
- Add annotations for deployments and incidents

---

## Troubleshooting

### Metrics Not Appearing in Prometheus

1. Check if metrics endpoint is accessible:
   ```bash
   curl http://localhost:8080/metrics
   ```

2. Verify Prometheus scrape configuration:
   - Check `prometheus.yml` for correct target
   - Verify scrape interval and timeout

3. Check Prometheus targets page:
   - Go to `http://localhost:9090/targets`
   - Look for errors on `godot_http_api` target

4. Review Prometheus logs for scrape errors

### Dashboard Not Loading

1. Verify Prometheus data source in Grafana:
   - Settings → Data Sources → Prometheus
   - Test connection

2. Check dashboard queries:
   - Edit panel
   - Verify query syntax
   - Test query in Prometheus UI first

3. Verify time range:
   - Ensure data exists for selected time range
   - Try "Last 5 minutes" to see recent data

### Alerts Not Firing

1. Check alert rules are loaded:
   - Go to `http://localhost:9090/alerts`
   - Verify rules appear

2. Test alert query manually:
   - Copy query from alert rule
   - Run in Prometheus UI
   - Verify it returns expected result

3. Check alert duration (`for` clause):
   - Condition may not have been true for required duration

4. Verify AlertManager is configured (if using)

### Profile Endpoint Not Working

1. Verify authentication:
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" \
        http://localhost:8080/debug/profile
   ```

2. Check if profiler is integrated:
   - Verify `HttpApiProfiler` is instantiated
   - Check that requests are being profiled

3. Review GDScript console for errors

---

## Performance Impact

### Metrics Collection
- **CPU**: <1% overhead per request
- **Memory**: ~100KB for 1000 stored metrics
- **Network**: ~50KB per Prometheus scrape (15s interval)

### Profiling
- **CPU**: <2% overhead per request
- **Memory**: ~500KB for 1000 stored profiles
- **Disk**: None (stored in memory only)

### Health Checks
- **CPU**: <0.5% overhead per check
- **Duration**: Typically 5-15ms per full check
- **Memory**: Negligible

### Recommendations
- Enable profiling always (minimal overhead, high value)
- Collect all metrics (essential for observability)
- Run full health checks every 30-60 seconds
- Use quick health checks for load balancer probes

---

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/best-practices/)
- [HTTP API Documentation](addons/godot_debug_connection/HTTP_API.md)
- [Development Workflow](DEVELOPMENT_WORKFLOW.md)

---

## Appendix: Metric Naming Conventions

### Counters
- Use `_total` suffix (e.g., `http_requests_total`)
- Represent cumulative values that only increase
- Use `rate()` function in queries

### Gauges
- No specific suffix (e.g., `active_connections`)
- Represent values that can go up or down
- Query directly without aggregation functions

### Histograms
- Use `_seconds` or `_bytes` suffix (e.g., `http_request_duration_seconds`)
- Automatically create `_bucket`, `_sum`, and `_count` metrics
- Use `histogram_quantile()` for percentiles

### Labels
- Use snake_case (e.g., `error_type`, not `errorType`)
- Keep cardinality low (<100 unique values per label)
- Avoid user-specific data in labels (IDs, emails, etc.)
- Use consistent label names across metrics

---

Last Updated: 2025-12-02
Version: 1.0
