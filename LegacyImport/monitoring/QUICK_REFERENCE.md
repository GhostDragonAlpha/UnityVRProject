# HTTP API Monitoring - Quick Reference

## Quick Start

```bash
# Start monitoring stack
cd monitoring && ./start_monitoring.sh

# Start Godot with HTTP API
godot --path C:/godot --dap-port 6006 --lsp-port 6005

# Test monitoring
./test_monitoring.sh
```

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Prometheus | http://localhost:9090 | None |
| Grafana | http://localhost:3000 | admin/admin |
| AlertManager | http://localhost:9093 | None |
| Metrics | http://localhost:8080/metrics | None |
| Health | http://localhost:8080/health | None |
| Profiler | http://localhost:8080/debug/profile | Token required |

## Key Endpoints

```bash
# Get metrics
curl http://localhost:8080/metrics

# Check health
curl http://localhost:8080/health | jq

# Quick health
curl http://localhost:8080/health/quick | jq

# Profile data (requires auth)
curl -H "Authorization: Bearer TOKEN" \
     http://localhost:8080/debug/profile | jq

# Flame graph
curl -H "Authorization: Bearer TOKEN" \
     http://localhost:8080/debug/profile/flamegraph | jq
```

## Python Monitoring Client

```bash
pip install requests

# View metrics
python examples/monitoring_client.py metrics

# Health status
python examples/monitoring_client.py health

# Performance profiles
python examples/monitoring_client.py profile

# Filter slow requests
python examples/monitoring_client.py profile --slow_only=true

# Flame graph
python examples/monitoring_client.py flamegraph

# Live dashboard
python examples/monitoring_client.py dashboard
```

## Common PromQL Queries

```promql
# Request rate
sum(rate(http_requests_total[5m]))

# Error rate percentage
sum(rate(http_requests_total{status=~"5.."}[5m])) /
sum(rate(http_requests_total[5m])) * 100

# 95th percentile latency
histogram_quantile(0.95,
  rate(http_request_duration_seconds_bucket[5m])
)

# Top 5 slowest endpoints
topk(5, histogram_quantile(0.95,
  sum by (endpoint, le) (rate(http_request_duration_seconds_bucket[5m]))
))

# Scene load success rate
sum(rate(scene_loads_total[5m])) /
(sum(rate(scene_loads_total[5m])) + sum(rate(scene_load_errors_total[5m]))) * 100

# Failed auth rate
rate(auth_attempts_total{result!="success"}[1m])

# Memory usage
process_resident_memory_bytes / 1024 / 1024
```

## Key Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `http_requests_total` | Counter | Total requests by endpoint, method, status |
| `http_request_duration_seconds` | Histogram | Request latency |
| `http_request_latency_ms` | Gauge | Pre-calculated percentiles |
| `scene_loads_total` | Counter | Successful scene loads |
| `scene_load_errors_total` | Counter | Scene load errors |
| `auth_attempts_total` | Counter | Auth attempts by result |
| `rate_limit_hits_total` | Counter | Rate limit hits |
| `active_connections` | Gauge | Current connections |

## Alert Severity

| Level | Description | Response Time |
|-------|-------------|---------------|
| Critical | Immediate action required | <5 minutes |
| Warning | Investigation needed | <30 minutes |
| Info | Awareness only | Best effort |

## Critical Alerts

- HighHTTPErrorRate (>5%)
- CriticalSlowRequests (p99 >2s)
- CriticalAuthFailureRate (>50/min - security)
- CriticalMemoryUsage (>1GB)
- HTTPAPIDown (no connections)
- HealthCheckFailing

## Integration Example

```gdscript
# Initialize
var metrics = MetricsExporter.new()
var profiler = HttpApiProfiler.new()
var health_check = HealthCheckSystem.new()

# Profile request
profiler.start_request("/scene", "POST")
profiler.start_phase("auth_validation")
# ... do work ...
profiler.end_phase()
profiler.end_request(200, 1024)

# Record metrics
metrics.record_request("/scene", "POST", 200, 45.5, 512, 1024)

# Record scene load
metrics.record_scene_load("res://vr_main.tscn", true)

# Record auth attempt
metrics.record_auth_attempt("success")

# Export metrics
var prometheus_text = metrics.export_metrics()

# Health check
var health = health_check.perform_health_check()
```

## Troubleshooting

| Problem | Check | Solution |
|---------|-------|----------|
| No metrics | `curl localhost:8080/metrics` | Start Godot with HTTP API |
| Prometheus not scraping | http://localhost:9090/targets | Check target is "up" |
| Dashboard empty | Grafana datasource | Test Prometheus connection |
| Alerts not firing | http://localhost:9090/alerts | Check rule evaluation |

## File Locations

```
C:/godot/
├── scripts/http_api/
│   ├── metrics_exporter.gd
│   ├── profiler.gd
│   ├── health_check.gd
│   └── monitoring_integration_example.gd
├── monitoring/
│   ├── docker-compose.yml
│   ├── start_monitoring.sh
│   ├── test_monitoring.sh
│   ├── prometheus/
│   │   ├── prometheus.yml
│   │   └── prometheus_alerts.yml
│   └── grafana/dashboards/
│       └── http_api_overview.json
├── examples/
│   └── monitoring_client.py
└── MONITORING.md
```

## Performance Impact

| Component | CPU | Memory | Duration |
|-----------|-----|--------|----------|
| Metrics | <1% | ~100KB | <0.1ms |
| Profiler | <2% | ~500KB | <0.5ms |
| Health Check | <0.5% | <1KB | 5-15ms |
| Prometheus Scrape | - | - | <1s every 15s |

## Quick Commands

```bash
# Restart monitoring
docker-compose restart

# View logs
docker-compose logs -f prometheus
docker-compose logs -f grafana

# Stop monitoring
docker-compose down

# Stop and remove data
docker-compose down -v

# Update images
docker-compose pull && docker-compose up -d
```

## Documentation

- Full Guide: `MONITORING.md`
- Setup Guide: `monitoring/README.md`
- Implementation Report: `MONITORING_IMPLEMENTATION_REPORT.md`
- This Reference: `monitoring/QUICK_REFERENCE.md`

## Support Contacts

Check these first:
1. Grafana dashboard: http://localhost:3000
2. Prometheus alerts: http://localhost:9090/alerts
3. Health endpoint: http://localhost:8080/health
4. Documentation: `MONITORING.md`

---

**Quick Reference Version 1.0**
**Last Updated: 2025-12-02**
