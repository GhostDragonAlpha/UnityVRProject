# SpaceTime VR HTTP API Monitoring Stack

Complete production monitoring and observability infrastructure for the SpaceTime VR HTTP API.

## Quick Start

### 1. Start Monitoring Stack

```bash
cd monitoring
docker-compose up -d
```

This starts:
- **Prometheus** (port 9090) - Metrics collection and storage
- **Grafana** (port 3000) - Visualization and dashboards
- **AlertManager** (port 9093) - Alert routing and management
- **Node Exporter** (port 9100) - Host system metrics

### 2. Start Godot with HTTP API

```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

Or on Windows:
```bash
./restart_godot_with_debug.bat
```

### 3. Verify Setup

```bash
# Check if Prometheus is scraping metrics
curl http://localhost:8080/metrics

# Check health
curl http://localhost:8080/health

# Open Grafana
# http://localhost:3000 (admin/admin)
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Godot HTTP API (port 8080)               │
├─────────────────────────────────────────────────────────────┤
│  /metrics          │ Prometheus metrics (public)            │
│  /health           │ Health check (public)                  │
│  /health/quick     │ Quick health check (public)            │
│  /debug/profile    │ Performance profiling (auth required)  │
│  /debug/profile/   │                                        │
│    flamegraph      │ Flame graph data (auth required)       │
└──────────┬──────────────────────────────────────────────────┘
           │
           │ HTTP Scrape (15s)
           ▼
┌─────────────────────────────────────────────────────────────┐
│              Prometheus (port 9090)                         │
├─────────────────────────────────────────────────────────────┤
│  • Metrics storage (TSDB)                                   │
│  • Alert evaluation                                         │
│  • Query API (PromQL)                                       │
└──────────┬──────────────────────────────┬───────────────────┘
           │                              │
           │                              │ Alerts
           │                              ▼
           │                    ┌──────────────────────────┐
           │                    │   AlertManager           │
           │                    │   (port 9093)            │
           │                    ├──────────────────────────┤
           │                    │  • Alert routing         │
           │                    │  • Deduplication         │
           │                    │  • Silencing             │
           │                    └──────────────────────────┘
           │
           │ Data Source
           ▼
┌─────────────────────────────────────────────────────────────┐
│                  Grafana (port 3000)                        │
├─────────────────────────────────────────────────────────────┤
│  • Dashboards                                               │
│  • Alerting                                                 │
│  • Visualization                                            │
│  • User management                                          │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Prometheus (port 9090)

Metrics collection and storage.

**Access:** http://localhost:9090

**Features:**
- Scrapes `/metrics` endpoint every 15 seconds
- Stores time-series data in local TSDB
- Evaluates alert rules
- Provides PromQL query interface

**Useful URLs:**
- Targets: http://localhost:9090/targets
- Alerts: http://localhost:9090/alerts
- Query: http://localhost:9090/graph

### 2. Grafana (port 3000)

Visualization and dashboards.

**Access:** http://localhost:3000
**Default Login:** admin/admin (change on first login)

**Pre-configured Dashboards:**
- **HTTP API Overview** - Main monitoring dashboard
  - Request rates and error rates
  - Latency percentiles
  - Scene operations
  - Authentication metrics
  - Memory usage

**Creating Custom Dashboards:**
1. Navigate to Dashboards → New Dashboard
2. Add panels with PromQL queries
3. Save to "SpaceTime VR" folder

### 3. AlertManager (port 9093)

Alert routing and management.

**Access:** http://localhost:9093

**Features:**
- Groups related alerts
- Routes alerts to different receivers
- Silences alerts temporarily
- Inhibits lower-severity alerts when higher-severity alerts are active

**Configuration:** `alertmanager/alertmanager.yml`

### 4. Node Exporter (port 9100)

Host system metrics (CPU, memory, disk, network).

**Access:** http://localhost:9100/metrics

**Optional:** Can be disabled if not needed.

## Monitoring Endpoints

### Public Endpoints (No Authentication)

#### GET `/metrics`
Prometheus metrics in text format.

```bash
curl http://localhost:8080/metrics
```

**Metrics exposed:**
- `http_requests_total` - Request counter
- `http_request_duration_seconds` - Latency histogram
- `http_request_size_bytes` - Request size histogram
- `http_response_size_bytes` - Response size histogram
- `scene_loads_total` - Scene load counter
- `scene_load_errors_total` - Scene error counter
- `auth_attempts_total` - Auth attempt counter
- `rate_limit_hits_total` - Rate limit counter
- `active_connections` - Current connections gauge

#### GET `/health`
Comprehensive health check.

```bash
curl http://localhost:8080/health | jq
```

**Response includes:**
- Overall health status
- Subsystem statuses (scene loader, file system, memory, connections, etc.)
- Detailed timing for each check
- Issue list if problems detected

#### GET `/health/quick`
Lightweight health check for frequent polling.

```bash
curl http://localhost:8080/health/quick
```

**Response:**
```json
{
  "healthy": true,
  "check_duration_ms": 0.5,
  "memory_mb": 384.8,
  "fps": 90.0
}
```

### Protected Endpoints (Require Authentication)

#### GET/POST `/debug/profile`
Detailed performance profiling data.

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:8080/debug/profile | jq
```

**Query Parameters:**
- `endpoint` - Filter by endpoint
- `method` - Filter by HTTP method
- `slow_only=true` - Only slow requests (>100ms)
- `min_duration_ms` - Minimum duration threshold

**Response includes:**
- Recent request profiles
- Phase statistics (auth, validation, file I/O, serialization)
- Endpoint summaries
- Slow request list

#### GET `/debug/profile/flamegraph`
Flame graph data for performance analysis.

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     'http://localhost:8080/debug/profile/flamegraph?request_id=req_123' | jq
```

**Parameters:**
- `request_id` - Specific request (optional, defaults to slowest recent)

**Use with:**
- SpeedScope: https://www.speedscope.app/
- Chrome DevTools Performance panel

## Python Monitoring Client

Located at: `examples/monitoring_client.py`

### Installation

```bash
pip install requests
```

### Usage

```bash
# Get metrics
python examples/monitoring_client.py metrics

# Health check
python examples/monitoring_client.py health

# Profile data
python examples/monitoring_client.py profile

# Profile with filters
python examples/monitoring_client.py profile --endpoint=/scene --slow_only=true

# Flame graph
python examples/monitoring_client.py flamegraph

# Live dashboard (auto-refresh)
python examples/monitoring_client.py dashboard 5
```

## Alert Rules

Located at: `prometheus/prometheus_alerts.yml`

### Critical Alerts

- **HighHTTPErrorRate** - Error rate >5% for 5 minutes
- **CriticalSlowRequests** - p99 latency >2s for 5 minutes
- **CriticalAuthFailureRate** - >50 failed auth/min (possible attack)
- **CriticalMemoryUsage** - Memory >1GB for 5 minutes
- **HTTPAPIDown** - No active connections for 2 minutes
- **HealthCheckFailing** - Health check down for 2 minutes

### Warning Alerts

- **SlowRequestLatency** - p95 latency >500ms for 10 minutes
- **HighRateLimitHits** - >50 rate limit hits/min for 5 minutes
- **HighAuthFailureRate** - >10 failed auth/min for 5 minutes
- **HighMemoryUsage** - Memory >800MB for 10 minutes
- **HighSceneLoadErrorRate** - Scene error rate >10% for 5 minutes
- **ServiceDegraded** - Health status degraded for 5 minutes

## Common Queries

### PromQL Examples

```promql
# Request rate
sum(rate(http_requests_total[5m]))

# Error rate percentage
sum(rate(http_requests_total{status=~"5.."}[5m])) /
sum(rate(http_requests_total[5m])) * 100

# 95th percentile latency
histogram_quantile(0.95,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
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

# Failed auth attempts
sum(rate(auth_attempts_total{result!="success"}[1m]))

# Memory usage
process_resident_memory_bytes / 1024 / 1024
```

## Troubleshooting

### Prometheus Not Scraping Metrics

1. **Check if metrics endpoint is accessible:**
   ```bash
   curl http://localhost:8080/metrics
   ```

2. **Check Prometheus targets:**
   - Go to http://localhost:9090/targets
   - Look for errors on `godot_http_api` target

3. **Verify Godot is running:**
   ```bash
   curl http://localhost:8080/health
   ```

4. **Check Prometheus logs:**
   ```bash
   docker logs spacetime_prometheus
   ```

### Grafana Dashboard Not Loading

1. **Verify Prometheus datasource:**
   - Grafana → Configuration → Data Sources → Prometheus
   - Click "Test" - should show "Data source is working"

2. **Check if metrics exist:**
   - Go to Prometheus UI: http://localhost:9090
   - Query: `http_requests_total`
   - Should return results

3. **Verify time range:**
   - Check dashboard time picker (top right)
   - Try "Last 5 minutes" to see recent data

### Alerts Not Firing

1. **Check alert rules are loaded:**
   ```bash
   curl http://localhost:9090/api/v1/rules | jq
   ```

2. **Test alert query:**
   - Copy query from `prometheus_alerts.yml`
   - Run in Prometheus UI
   - Verify it returns expected result

3. **Check alert status:**
   - Go to http://localhost:9090/alerts
   - Look for alert state (pending, firing, inactive)

4. **Verify AlertManager:**
   ```bash
   curl http://localhost:9093/api/v2/status | jq
   ```

### High Memory Usage

1. **Check retention settings:**
   - Prometheus stores 15 days by default
   - Reduce with `--storage.tsdb.retention.time=7d`

2. **Check series cardinality:**
   ```promql
   # Count total series
   count({__name__=~".+"})

   # Top metrics by cardinality
   topk(10, count by (__name__)({__name__=~".+"}))
   ```

3. **Reduce scrape interval:**
   - Change from 15s to 30s or 60s in `prometheus.yml`

## Configuration Files

```
monitoring/
├── docker-compose.yml                    # Docker services
├── prometheus/
│   ├── prometheus.yml                    # Prometheus config
│   └── prometheus_alerts.yml             # Alert rules
├── grafana/
│   ├── datasources/
│   │   └── prometheus.yml                # Auto-provision datasource
│   └── dashboards/
│       ├── dashboard-provider.yml        # Auto-load dashboards
│       └── http_api_overview.json        # Main dashboard
└── alertmanager/
    └── alertmanager.yml                  # Alert routing config
```

## Best Practices

### Metrics Collection
- Keep metrics cardinality low
- Avoid high-cardinality labels (user IDs, IPs)
- Use histograms for latency and sizes
- Tag metrics appropriately

### Alerting
- Set thresholds based on baselines
- Use warning alerts for trends
- Use critical alerts for immediate action
- Include runbook links

### Dashboards
- Group related panels
- Use appropriate time ranges
- Add annotations for deployments
- Share dashboards with team

### Performance
- Monitor scrape duration (<1s)
- Watch for dropped metrics
- Optimize expensive queries
- Use recording rules for complex queries

## Advanced Features

### Recording Rules

Add to `prometheus.yml` for pre-computed queries:

```yaml
groups:
  - name: http_api_recordings
    interval: 30s
    rules:
      - record: job:http_request_duration_seconds:p95
        expr: |
          histogram_quantile(0.95,
            sum by (job, endpoint, le) (
              rate(http_request_duration_seconds_bucket[5m])
            )
          )
```

### Grafana Annotations

Automatically mark deployments on dashboards:

```yaml
# In dashboard JSON
"annotations": {
  "list": [
    {
      "datasource": "Prometheus",
      "enable": true,
      "expr": "changes(process_start_time_seconds[1m]) > 0",
      "iconColor": "blue",
      "name": "Deployments"
    }
  ]
}
```

### Alert Webhook Integration

Receive alerts in custom application:

```python
from flask import Flask, request
app = Flask(__name__)

@app.route('/alerts/webhook', methods=['POST'])
def alerts():
    data = request.json
    # Process alert
    print(f"Alert: {data}")
    return "OK"

app.run(port=8083)
```

## Maintenance

### Backup Configuration

```bash
# Backup Prometheus data
docker exec spacetime_prometheus tar czf /prometheus-backup.tar.gz /prometheus

# Backup Grafana dashboards
docker exec spacetime_grafana tar czf /grafana-backup.tar.gz /var/lib/grafana

# Copy to host
docker cp spacetime_prometheus:/prometheus-backup.tar.gz ./backups/
docker cp spacetime_grafana:/grafana-backup.tar.gz ./backups/
```

### Update Images

```bash
cd monitoring
docker-compose pull
docker-compose up -d
```

### Clean Up Old Data

```bash
# Prometheus retention is set in docker-compose.yml
# Default: 15 days

# Manually clean up:
docker exec spacetime_prometheus rm -rf /prometheus/*
docker restart spacetime_prometheus
```

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [AlertManager Guide](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Complete Monitoring Guide](../MONITORING.md)

## Support

For issues or questions:
1. Check logs: `docker-compose logs`
2. Review Prometheus targets: http://localhost:9090/targets
3. Test endpoints manually with curl
4. Check Godot console for errors

## License

Part of SpaceTime VR project.
