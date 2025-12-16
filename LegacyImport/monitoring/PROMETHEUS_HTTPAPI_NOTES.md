# Prometheus Integration with HttpApiServer

## Current Status

The HttpApiServer (port 8080) **does not expose a native Prometheus `/metrics` endpoint**. Instead, it provides performance metrics via the `/performance` endpoint in JSON format.

## Available Endpoints

### GET /performance (Auth Required)

**Authentication:** JWT Bearer token

**Example:**
```bash
curl -H "Authorization: Bearer $(cat jwt_token.txt)" http://localhost:8080/performance
```

**Response:**
```json
{
  "timestamp": 1701734400.0,
  "cache": {
    "hit_rate": 0.85,
    "miss_rate": 0.15,
    "total_size_bytes": 1048576,
    "entry_count": 42,
    "eviction_count": 5
  },
  "security": {
    "rate_limit_violations": 12,
    "auth_failures": 3,
    "active_tokens": 5,
    "blocked_ips": []
  },
  "memory": {
    "static_memory_usage": 524288000,
    "static_memory_max": 536870912,
    "dynamic_memory_usage": 1048576
  },
  "engine": {
    "fps": 90.0,
    "process_time": 0.008,
    "physics_process_time": 0.011,
    "objects_in_use": 1234,
    "resources_in_use": 567,
    "nodes_in_use": 890
  }
}
```

## Integration Options

### Option 1: Use health_monitor.py (Current)

The Python health monitor polls `/performance` every 30s and logs metrics. It does NOT expose Prometheus metrics.

**Pros:**
- Already implemented
- Includes alerting via webhooks
- Detailed logging

**Cons:**
- No Prometheus integration
- Manual alert configuration

### Option 2: Create Prometheus Exporter (Recommended)

Create a lightweight HTTP server that:
1. Polls `/performance` endpoint (with JWT auth)
2. Converts JSON to Prometheus text format
3. Exposes metrics on port 9091

**Implementation:**

```python
#!/usr/bin/env python3
"""Prometheus exporter for HttpApiServer"""

from prometheus_client import start_http_server, Gauge
import requests
import time

# Read JWT token
with open('jwt_token.txt') as f:
    JWT_TOKEN = f.read().strip()

# Define Prometheus metrics
fps = Gauge('spacetime_fps', 'Frames per second')
memory_usage = Gauge('spacetime_memory_bytes', 'Memory usage in bytes', ['type'])
cache_hit_rate = Gauge('spacetime_cache_hit_rate', 'Cache hit rate')
rate_limit_violations = Gauge('spacetime_rate_limit_violations_total', 'Rate limit violations')

def collect_metrics():
    """Fetch metrics from /performance and update Prometheus gauges"""
    try:
        headers = {'Authorization': f'Bearer {JWT_TOKEN}'}
        resp = requests.get('http://localhost:8080/performance', headers=headers, timeout=5)
        data = resp.json()

        # Update gauges
        fps.set(data['engine']['fps'])
        memory_usage.labels(type='static').set(data['memory']['static_memory_usage'])
        cache_hit_rate.set(data['cache']['hit_rate'])
        rate_limit_violations.set(data['security']['rate_limit_violations'])

    except Exception as e:
        print(f"Error collecting metrics: {e}")

if __name__ == '__main__':
    # Start HTTP server on port 9091
    start_http_server(9091)
    print("Prometheus exporter running on :9091")

    # Collect metrics every 15s
    while True:
        collect_metrics()
        time.sleep(15)
```

**Usage:**
```bash
# Install dependencies
pip install prometheus-client requests

# Run exporter
python monitoring/prometheus_exporter.py

# Verify metrics
curl http://localhost:9091/metrics

# Update prometheus.yml
# - job_name: 'spacetime-exporter'
#   static_configs:
#     - targets: ['localhost:9091']
```

### Option 3: Add /metrics endpoint to HttpApiServer

Modify `performance_router.gd` to also expose Prometheus text format:

```gdscript
# GET /metrics - Prometheus text format
func _handle_metrics_request(request: HttpRequest, response: GodottpdResponse) -> bool:
    var perf_data = _get_performance_data()

    var metrics_text = ""
    metrics_text += "# HELP spacetime_fps Frames per second\n"
    metrics_text += "# TYPE spacetime_fps gauge\n"
    metrics_text += "spacetime_fps %f\n" % perf_data.engine.fps

    metrics_text += "# HELP spacetime_memory_bytes Memory usage in bytes\n"
    metrics_text += "# TYPE spacetime_memory_bytes gauge\n"
    metrics_text += "spacetime_memory_bytes{type=\"static\"} %d\n" % perf_data.memory.static_memory_usage

    # ... more metrics ...

    response.send(200, metrics_text, "text/plain; version=0.0.4")
    return true
```

**Pros:**
- Native Prometheus support
- No external dependencies
- Better performance

**Cons:**
- Requires GDScript changes
- Auth handling for /metrics
- More complex to maintain

## Recommended Approach

For production deployment, **Option 2 (Prometheus Exporter)** is recommended:

1. Minimal code changes to Godot
2. Separate process for metrics collection
3. Easy to scale and monitor
4. Standard Prometheus integration

## Configuration

Once exporter is running, update `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'spacetime-exporter'
    static_configs:
      - targets: ['localhost:9091']
        labels:
          service: 'spacetime-vr'
          component: 'exporter'
    scrape_interval: 15s
```

## Metrics Mapping

| HttpApiServer Metric | Prometheus Metric | Type | Labels |
|---------------------|-------------------|------|--------|
| engine.fps | spacetime_fps | gauge | - |
| memory.static_memory_usage | spacetime_memory_bytes | gauge | type="static" |
| memory.dynamic_memory_usage | spacetime_memory_bytes | gauge | type="dynamic" |
| cache.hit_rate | spacetime_cache_hit_rate | gauge | - |
| cache.total_size_bytes | spacetime_cache_size_bytes | gauge | - |
| security.rate_limit_violations | spacetime_rate_limit_violations_total | counter | - |
| security.auth_failures | spacetime_auth_failures_total | counter | - |
| engine.process_time | spacetime_process_time_seconds | gauge | - |
| engine.physics_process_time | spacetime_physics_process_time_seconds | gauge | - |
| engine.objects_in_use | spacetime_objects_total | gauge | - |
| engine.nodes_in_use | spacetime_nodes_total | gauge | - |

## Next Steps

1. Implement `monitoring/prometheus_exporter.py`
2. Update `prometheus.yml` with exporter target
3. Test metrics collection: `curl http://localhost:9091/metrics`
4. Import Grafana dashboard
5. Configure alerts in AlertManager

## References

- Prometheus Text Format: https://prometheus.io/docs/instrumenting/exposition_formats/
- Prometheus Client Libraries: https://prometheus.io/docs/instrumenting/clientlibs/
- Prometheus Best Practices: https://prometheus.io/docs/practices/naming/
