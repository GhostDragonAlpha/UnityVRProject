# Server Meshing Monitoring - Quick Start

Fast setup guide for server meshing monitoring and observability.

## 5-Minute Setup

### 1. Add MonitoringSystem to Your Server

```gdscript
# In your main server script (e.g., planetary_survival_coordinator.gd)
extends Node

var monitoring_system: MonitoringSystem
var monitoring_integration: MonitoringIntegration

func _ready():
	# Create monitoring system
	monitoring_system = MonitoringSystem.new()
	add_child(monitoring_system)

	# Create integration adapter
	monitoring_integration = MonitoringIntegration.new(monitoring_system)
	add_child(monitoring_integration)

	# Instrument your systems
	if has_node("ServerMeshCoordinator"):
		monitoring_integration.instrument_server_mesh($ServerMeshCoordinator)

	if has_node("AuthorityTransferSystem"):
		monitoring_integration.instrument_authority_transfer($AuthorityTransferSystem)

	if has_node("InterServerCommunication"):
		monitoring_integration.instrument_inter_server_comm($InterServerCommunication)

	print("Monitoring enabled!")
```

### 2. Expose Metrics Endpoint

```gdscript
# In your HTTP server (e.g., godot_bridge.gd)
func _handle_request(endpoint: String, method: String, body: String) -> Dictionary:
	# ... existing routes ...

	# Add metrics endpoint
	if endpoint == "/metrics" and method == "GET":
		return {
			"status": 200,
			"body": monitoring_system.export_prometheus_metrics(),
			"content_type": "text/plain; version=0.0.4"
		}

	# ... rest of handler ...
```

### 3. Start Monitoring Stack

```bash
cd C:/godot/monitoring
docker-compose up -d
```

### 4. Verify Setup

```bash
# Check metrics endpoint
curl http://localhost:8080/metrics

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Open Grafana
start http://localhost:3000
```

### 5. Access Dashboards

- **Grafana**: http://localhost:3000
  - Username: `admin`
  - Password: `admin` (change on first login)
  - Navigate to: Dashboards → Server Mesh Overview

- **Prometheus**: http://localhost:9090
  - Query metrics directly

- **AlertManager**: http://localhost:9093
  - View active alerts

## Key Metrics to Monitor

### Critical Metrics

```promql
# Server CPU usage (critical if >95%)
server_cpu_usage > 0.95

# Authority transfer latency (critical if p95 >250ms)
histogram_quantile(0.95, rate(authority_transfer_latency_ms_bucket[5m])) > 250

# Region capacity (critical if >100 players)
region_player_count > 100

# Transfer failures (critical if >0.1/sec)
rate(authority_transfer_failures_total[5m]) > 0.1
```

### Performance Metrics

```promql
# Average FPS (target: 90)
avg(fps)

# Authority transfer success rate (target: >95%)
1 - (rate(authority_transfer_failures_total[5m]) / rate(authority_transfers_total[5m]))

# Inter-server latency (target: <10ms p95)
histogram_quantile(0.95, rate(inter_server_latency_ms_bucket[5m]))
```

### Capacity Metrics

```promql
# Total player count
sum(region_player_count)

# Server count
server_node_count

# Region count
region_count
```

## Common Alerts

### Critical Alerts

- **CriticalServerCPU**: Server CPU >95% for 2m
- **CriticalTransferLatency**: Transfer latency p95 >250ms for 3m
- **HighTransferFailureRate**: Transfer failures >0.1/sec for 2m
- **RegionCapacityExceeded**: Region players >100 for 1m
- **OrphanedRegion**: Region has no server for 30s

### Warning Alerts

- **HighServerCPU**: Server CPU >80% for 5m
- **SlowAuthorityTransfers**: Transfer latency p95 >100ms for 5m
- **HighRegionDensity**: Region players >80 for 3m
- **LowFPS**: FPS <85 for 2m

## Troubleshooting

### Metrics Not Appearing

**Check endpoint**:
```bash
curl http://localhost:8080/metrics
```

**Expected output**:
```
# HELP server_cpu_usage CPU usage percentage (0.0-1.0)
# TYPE server_cpu_usage gauge
server_cpu_usage{server_id="1"} 0.45
...
```

**If empty**: MonitoringSystem not initialized or metrics not being collected.

**If 404**: HTTP route not registered.

### Prometheus Not Scraping

**Check targets**:
```bash
curl http://localhost:9090/api/v1/targets
```

**Look for**:
- `"health": "up"` - Good
- `"health": "down"` - Check server accessibility

**If down**:
1. Verify server is running
2. Check firewall rules
3. Verify port 8080 is accessible
4. Check Prometheus logs: `docker logs spacetime_prometheus`

### Grafana Dashboard Empty

**Check data source**:
1. Grafana → Configuration → Data Sources
2. Select Prometheus
3. Click "Test" button
4. Should say "Data source is working"

**If failing**:
1. Check Prometheus is running: `docker ps`
2. Verify Prometheus URL: `http://prometheus:9090` (in Docker) or `http://localhost:9090` (outside Docker)

**Check time range**:
- Change dashboard time picker to "Last 5 minutes"
- Metrics may not have history yet

### Alerts Not Firing

**Check rules loaded**:
```bash
curl http://localhost:9090/api/v1/rules | jq '.data.groups[].name'
```

**Should see**:
- `server_meshing_critical`
- `server_meshing_warnings`
- `server_meshing_info`

**If missing**:
1. Check `prometheus.yml` has `rule_files` section
2. Verify `server_meshing_alerts.yml` exists
3. Restart Prometheus: `docker restart spacetime_prometheus`

## Manual Testing

### Test Metrics Collection

```gdscript
# In Godot console
var monitoring = get_node("/root/MonitoringSystem")

# Check metrics
print(monitoring.get_metrics().size())  # Should be >0

# Manually set a gauge
monitoring.set_gauge("server_cpu_usage", 0.85, {"server_id": "1"})

# Export metrics
print(monitoring.export_prometheus_metrics())
```

### Test Distributed Tracing

```gdscript
# Start a trace
var trace_id = monitoring.start_trace("test_operation", {"test": true})
print("Trace ID: ", trace_id)

# Add spans
monitoring.add_span(trace_id, "phase1", 1000, {"duration": "1ms"})
monitoring.add_span(trace_id, "phase2", 5000, {"duration": "5ms"})

# End trace
monitoring.end_trace(trace_id, true)

# Retrieve trace
var trace = monitoring.get_trace(trace_id)
print(JSON.stringify(trace, "\t"))
```

### Test Alert Triggering

```gdscript
# Set metric above threshold
monitoring.set_gauge("server_cpu_usage", 0.96, {"server_id": "1"})

# Wait 2 minutes (alert duration)
# Then check active alerts
print(monitoring.get_active_alerts())
```

## Configuration Files

### Minimal Prometheus Config

```yaml
# monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'planetary-survival'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'

rule_files:
  - 'server_meshing_alerts.yml'
```

### Minimal Docker Compose

```yaml
# monitoring/docker-compose.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - ./grafana:/etc/grafana/provisioning
```

## Next Steps

1. **Customize Alerts**: Edit `monitoring/prometheus/server_meshing_alerts.yml`
2. **Tune Thresholds**: Adjust based on your performance baselines
3. **Add Custom Metrics**: Register new metrics in MonitoringSystem
4. **Create Custom Dashboards**: Build dashboards for specific use cases
5. **Set Up Notifications**: Configure AlertManager to send alerts to Slack/email
6. **Enable Recording Rules**: Pre-compute expensive queries for faster dashboards

## Resources

- **Full Guide**: [SERVER_MESH_MONITORING_GUIDE.md](./SERVER_MESH_MONITORING_GUIDE.md)
- **Prometheus Docs**: https://prometheus.io/docs/
- **Grafana Docs**: https://grafana.com/docs/
- **PromQL Cheatsheet**: https://promlabs.com/promql-cheat-sheet/

## Support

For issues or questions:
1. Check the full monitoring guide
2. Review Prometheus/Grafana logs
3. Test endpoints manually with curl
4. Verify system instrumentation

---

Last Updated: 2025-12-02
