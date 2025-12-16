# Server Mesh Monitoring and Observability Guide

Complete guide for monitoring and observability of the Planetary Survival multiplayer server meshing system.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Quick Start](#quick-start)
4. [Metrics Reference](#metrics-reference)
5. [Distributed Tracing](#distributed-tracing)
6. [Alert Rules](#alert-rules)
7. [Grafana Dashboards](#grafana-dashboards)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Performance Tuning](#performance-tuning)
10. [API Reference](#api-reference)

---

## Overview

The server mesh monitoring system provides comprehensive observability for:
- **Server mesh topology** - Track server nodes, regions, and assignments
- **Authority transfers** - Monitor player handoffs between server regions
- **Performance metrics** - CPU, memory, FPS, and latency tracking
- **Distributed tracing** - End-to-end visibility of authority transfers
- **Dynamic scaling** - Monitor region splits, merges, and server spawning

### Key Requirements

Implements requirements **68.1-68.5**:
- **68.1**: Expose metrics for CPU, memory, network, and player count
- **68.2**: Generate alerts with severity levels
- **68.3**: Provide distributed tracing across server nodes
- **68.4**: Log region transfer times and synchronization latency
- **68.5**: Display real-time topology and load distribution

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Game Server Nodes                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  Server 1    │  │  Server 2    │  │  Server 3    │         │
│  │  (Region A)  │  │  (Region B)  │  │  (Region C)  │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                  │                  │                  │
│         └──────────────────┼──────────────────┘                  │
│                            │                                     │
│             MonitoringSystem (autoload on each server)          │
│             • Collects metrics                                  │
│             • Tracks distributed traces                         │
│             • Generates alerts                                  │
│             • Exports Prometheus format                         │
└─────────────────────────────────────────────────────────────────┘
                             │
                             │ HTTP Scrape (15s)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Prometheus                                │
│  • Scrapes metrics from all servers                            │
│  • Evaluates alert rules                                       │
│  • Stores time-series data                                     │
└────────────────┬────────────────────┬──────────────────────────┘
                 │                    │
      Data Source│                    │ Alerts
                 ▼                    ▼
      ┌──────────────────┐  ┌─────────────────┐
      │    Grafana       │  │  AlertManager   │
      │  • Dashboards    │  │  • Routing      │
      │  • Visualization │  │  • Deduplication│
      └──────────────────┘  └─────────────────┘
```

### Components

**MonitoringSystem** (GDScript autoload):
- Collects and aggregates metrics
- Implements distributed tracing
- Evaluates alert thresholds
- Exports Prometheus text format

**MonitoringIntegration** (GDScript):
- Instruments existing systems
- Connects signals to metrics
- Manages trace lifecycle

**Prometheus**:
- Scrapes `/metrics` endpoint from each server
- Stores time-series data
- Evaluates alert rules

**Grafana**:
- Visualizes metrics
- Server topology graphs
- Load distribution heatmaps

**AlertManager**:
- Routes alerts to administrators
- Deduplicates and groups alerts

---

## Quick Start

### 1. Set Up MonitoringSystem

Add to your server initialization:

```gdscript
# In your main server node or autoload setup
var monitoring_system := MonitoringSystem.new()
add_child(monitoring_system)

# Create integration adapter
var integration := MonitoringIntegration.new(monitoring_system)
add_child(integration)

# Instrument server mesh components
integration.instrument_server_mesh(mesh_coordinator)
integration.instrument_authority_transfer(authority_transfer_system)
integration.instrument_inter_server_comm(inter_server_comm)
```

### 2. Expose Metrics Endpoint

Add HTTP endpoint to expose Prometheus metrics:

```gdscript
# In your HTTP server (e.g., GodotBridge)
func handle_metrics_request() -> String:
	if monitoring_system:
		return monitoring_system.export_prometheus_metrics()
	return ""

# Register route
router.add_route("/metrics", "GET", handle_metrics_request)
```

### 3. Configure Prometheus

Edit `monitoring/prometheus/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'planetary-survival-server'
    static_configs:
      - targets:
          - 'server1:8080'
          - 'server2:8080'
          - 'server3:8080'
    metrics_path: '/metrics'
    scrape_interval: 15s
```

### 4. Start Monitoring Stack

```bash
cd monitoring
docker-compose up -d
```

### 5. Access Dashboards

- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **AlertManager**: http://localhost:9093

---

## Metrics Reference

### Server Metrics

#### `server_cpu_usage` (gauge)
CPU usage percentage (0.0-1.0) per server node.

**Labels**: `server_id`

**Alert Thresholds**:
- Warning: >0.80
- Critical: >0.95

**Example Query**:
```promql
server_cpu_usage{server_id="1"}
```

#### `server_memory_usage` (gauge)
Memory usage percentage (0.0-1.0) per server node.

**Labels**: `server_id`

**Alert Thresholds**:
- Warning: >0.80
- Critical: >0.95

#### `server_memory_bytes` (gauge)
Absolute memory usage in bytes.

**Labels**: `server_id`

#### `server_network_bandwidth_bytes` (gauge)
Network bandwidth utilization in bytes/sec.

**Labels**: `server_id`

### Region Metrics

#### `region_count` (gauge)
Total number of active regions across all servers.

**Example Query**:
```promql
region_count
```

#### `region_player_count` (gauge)
Number of players in each region.

**Labels**: `region_id`

**Alert Thresholds**:
- Warning: >80
- Critical: >100

**Example Query**:
```promql
# Top 10 most populated regions
topk(10, region_player_count)
```

#### `region_entity_count` (gauge)
Number of entities (NPCs, structures, etc.) in each region.

**Labels**: `region_id`

#### `region_sync_latency_ms` (histogram)
Time taken to synchronize region boundaries.

**Labels**: `region_id`

**Buckets**: 1ms, 5ms, 10ms, 25ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s, 10s, +Inf

**Alert Thresholds** (p95):
- Warning: >50ms
- Critical: >100ms

**Example Query**:
```promql
# 95th percentile sync latency per region
histogram_quantile(0.95, rate(region_sync_latency_ms_bucket[5m]))
```

### Authority Transfer Metrics

#### `authority_transfers_total` (counter)
Total number of authority transfers.

**Labels**: `from_server`, `to_server`

**Example Query**:
```promql
# Transfer rate per second
rate(authority_transfers_total[5m])
```

#### `authority_transfer_latency_ms` (histogram)
Latency of authority transfer operations.

**Buckets**: Same as region_sync_latency_ms

**Target**: <100ms (95th percentile)

**Alert Thresholds** (p95):
- Warning: >100ms
- Critical: >250ms

**Example Query**:
```promql
# 95th percentile transfer latency
histogram_quantile(0.95, rate(authority_transfer_latency_ms_bucket[5m]))
```

#### `authority_transfer_failures_total` (counter)
Number of failed authority transfers.

**Alert Thresholds**:
- Critical: >0.1 per second

**Example Query**:
```promql
# Failure rate
rate(authority_transfer_failures_total[5m])
```

#### `authority_transfer_retries_total` (counter)
Number of authority transfer retry attempts.

**Alert Thresholds**:
- Warning: >0.5 per second

### Player Metrics

#### `player_count_total` (gauge)
Total player count across all servers.

**Example Query**:
```promql
player_count_total
```

#### `player_spawns_total` (counter)
Cumulative player spawns.

#### `player_disconnects_total` (counter)
Cumulative player disconnects.

### Server Mesh Metrics

#### `server_node_count` (gauge)
Number of active server nodes.

**Example Query**:
```promql
server_node_count
```

#### `inter_server_messages_total` (counter)
Inter-server messages sent.

**Labels**: `message_type`

**Example Query**:
```promql
# Message rate by type
rate(inter_server_messages_total[5m])
```

#### `inter_server_latency_ms` (histogram)
Inter-server communication latency.

**Target**: <10ms (95th percentile)

**Alert Thresholds** (p95):
- Warning: >10ms

### Performance Metrics

#### `fps` (gauge)
Frames per second on each server.

**Target**: 90 FPS

**Alert Thresholds**:
- Warning: <85 FPS

#### `frame_time_ms` (gauge)
Frame processing time in milliseconds.

**Target**: <11.1ms (for 90 FPS)

**Alert Thresholds**:
- Warning: >12ms

#### `physics_time_ms` (gauge)
Physics processing time per frame.

### Dynamic Scaling Metrics

#### `region_splits_total` (counter)
Number of region split operations.

#### `region_merges_total` (counter)
Number of region merge operations.

#### `server_spawns_total` (counter)
Number of server nodes spawned.

#### `server_shutdowns_total` (counter)
Number of server nodes shut down gracefully.

---

## Distributed Tracing

The monitoring system implements distributed tracing for authority transfers to provide end-to-end visibility.

### Trace Lifecycle

```gdscript
# 1. Start trace when transfer is initiated
var trace_id: String = monitoring.start_trace("authority_transfer", {
	"player_id": player_id,
	"from_region": str(from_region),
	"to_region": str(to_region)
})

# 2. Add spans for each phase
monitoring.add_span(trace_id, "boundary_detection", detection_time_us)
monitoring.add_span(trace_id, "pre_loading", preload_time_us)
monitoring.add_span(trace_id, "handshake", handshake_time_us)
monitoring.add_span(trace_id, "state_transfer", transfer_time_us)

# 3. End trace
monitoring.end_trace(trace_id, success=true)
```

### Trace Storage

Traces are stored in-memory with a configurable limit (default: 1000 traces). Oldest traces are automatically evicted.

### Querying Traces

```gdscript
# Get specific trace
var trace: Dictionary = monitoring.get_trace(trace_id)

# Get all traces
var all_traces: Dictionary = monitoring.get_traces()

# Trace structure
{
	"operation": "authority_transfer",
	"start_time": 1234567890,
	"end_time": 1234567990,
	"success": true,
	"metadata": {
		"player_id": 42,
		"from_region": "(0, 0, 0)",
		"to_region": "(1, 0, 0)"
	},
	"spans": [
		{
			"name": "boundary_detection",
			"duration_us": 1500,
			"metadata": {}
		},
		{
			"name": "pre_loading",
			"duration_us": 15000,
			"metadata": {"preload_size_kb": 250}
		},
		{
			"name": "handshake",
			"duration_us": 2000,
			"metadata": {}
		},
		{
			"name": "state_transfer",
			"duration_us": 80000,
			"metadata": {"state_size_kb": 128}
		}
	]
}
```

### OpenTelemetry Compatibility

The trace format is compatible with OpenTelemetry and can be exported to external tracing systems:

```gdscript
# Export traces to OpenTelemetry collector
func export_traces_to_otel() -> void:
	var traces: Dictionary = monitoring.get_traces()
	for trace_id in traces:
		var trace: Dictionary = traces[trace_id]
		# Convert to OpenTelemetry format and send
		var otel_span = convert_to_otel_format(trace)
		send_to_otel_collector(otel_span)
```

---

## Alert Rules

Alert rules are defined in `monitoring/prometheus/server_meshing_alerts.yml`.

### Critical Alerts

#### CriticalServerCPU
**Condition**: `server_cpu_usage > 0.95` for 2 minutes

**Action**: Immediate investigation required. Consider:
1. Check what's consuming CPU (profiling)
2. Investigate if region load is too high
3. Consider splitting high-load regions
4. May need to spawn additional server node

#### CriticalTransferLatency
**Condition**: 95th percentile transfer latency >250ms for 3 minutes

**Action**: Authority transfers are critically slow. Check:
1. Network latency between servers
2. Server CPU/memory usage
3. Region sync performance
4. Database query performance

#### HighTransferFailureRate
**Condition**: Transfer failures >0.1/sec for 2 minutes

**Action**: Players are experiencing failed transfers. Check:
1. Error logs for failure reasons
2. Network connectivity between servers
3. Target server availability
4. Database connection health

#### RegionCapacityExceeded
**Condition**: `region_player_count > 100` for 1 minute

**Action**: Region has exceeded capacity. Immediately:
1. Trigger region split operation
2. Monitor split progress
3. Verify players distributed correctly

#### OrphanedRegion
**Condition**: `region_authoritative_server == -1` for 30 seconds

**Action**: Critical - region has no authority. Immediately:
1. Check why server unregistered
2. Promote backup server if available
3. Reassign region to healthy server
4. Verify player continuity

### Warning Alerts

#### HighServerCPU
**Condition**: `server_cpu_usage > 0.80` for 5 minutes

**Action**: Monitor trend. Consider:
1. Review recent load increases
2. Plan for region splitting if continuing
3. Monitor for progression to critical

#### SlowAuthorityTransfers
**Condition**: 95th percentile transfer latency >100ms for 5 minutes

**Action**: Transfers approaching target. Investigate:
1. Network latency trends
2. Server load trends
3. Optimize transfer protocol if possible

#### HighRegionDensity
**Condition**: `region_player_count > 80` for 3 minutes

**Action**: Region approaching capacity. Prepare:
1. Monitor player growth
2. Plan region split if growth continues
3. Pre-warm adjacent servers

### Alert Response Workflow

```
Alert Fired
    │
    ├─► Check Grafana Dashboard
    │   └─► Identify affected servers/regions
    │
    ├─► Check Alert Details
    │   └─► Review severity and threshold
    │
    ├─► Investigate Root Cause
    │   ├─► Query Prometheus metrics
    │   ├─► Review distributed traces
    │   └─► Check application logs
    │
    ├─► Take Action
    │   ├─► Scale resources (if capacity issue)
    │   ├─► Restart services (if crashed)
    │   ├─► Optimize code (if performance issue)
    │   └─► Split regions (if overloaded)
    │
    └─► Monitor Resolution
        └─► Verify alert clears
```

---

## Grafana Dashboards

### Server Mesh Overview Dashboard

Location: `monitoring/grafana/dashboards/server_mesh_overview.json`

Access: http://localhost:3000/d/server-mesh-overview

#### Key Panels

**1. Server Mesh Health Score** (Gauge)
- Composite health metric (0-1)
- Green: >0.9, Yellow: 0.7-0.9, Red: <0.7
- Formula: `(CPU health * 0.3) + (Memory health * 0.3) + (FPS health * 0.2) + (Transfer success * 0.2)`

**2. Active Server Nodes** (Stat)
- Current count of running server nodes
- Shows trend with sparkline

**3. Total Regions** (Stat)
- Number of active regions
- Color-coded by count

**4. Total Players** (Stat)
- Player count across all servers
- Thresholds: 100 (blue), 500 (green), 1000 (yellow), 1000+ (red)

**5. Authority Transfer Success Rate** (Stat)
- Percentage of successful transfers
- Green: >95%, Yellow: 90-95%, Red: <90%

**6. Server CPU Usage** (Time Series)
- CPU usage per server over time
- Horizontal lines at 80% (warning) and 95% (critical)

**7. Server Memory Usage** (Time Series)
- Memory usage per server over time
- Same thresholds as CPU

**8. Authority Transfer Latency** (Time Series)
- p50, p90, p95, p99 percentiles
- Horizontal line at 100ms target

**9. Region Boundary Sync Latency** (Time Series)
- p95 sync latency per region
- Horizontal line at 50ms target

**10. Player Distribution Heatmap** (Heatmap)
- Visual representation of player density across regions
- Color scale: cold (few players) to hot (many players)

**11. Server Topology** (Network Graph)
- Visual representation of server mesh
- Shows inter-server connections

**12. Authority Transfer Rate** (Time Series)
- Transfers per second over time

**13. Authority Transfer Failures** (Time Series)
- Failures and retries per second

**14. Region Scaling Activity** (Time Series)
- Region splits and merges over time

**15. Top Regions by Player Count** (Table)
- Sorted list of most populated regions
- Useful for identifying hotspots

**16. Active Alerts** (Alert List)
- Current firing and pending alerts
- Filtered by `server_mesh` tag

### Using Dashboards

**Time Range Selection**:
- Default: Last 1 hour
- Can change to: 5m, 15m, 1h, 6h, 24h, 7d

**Auto-Refresh**:
- Default: 10 seconds
- Options: 5s, 10s, 30s, 1m, 5m, off

**Variable Filters**:
- `$server_id`: Filter by specific server(s)
- `$region_id`: Filter by specific region(s)
- Both support multi-select and "All"

**Annotations**:
- Blue markers: Deployments (server count changes)
- Red markers: Alert firing events

---

## Troubleshooting Guide

### High Authority Transfer Latency

**Symptoms**: p95 transfer latency >100ms

**Investigation Steps**:

1. **Check Network Latency**:
   ```promql
   histogram_quantile(0.95, rate(inter_server_latency_ms_bucket[5m]))
   ```
   - If >10ms, network is the bottleneck

2. **Check Server Load**:
   ```promql
   server_cpu_usage
   server_memory_usage
   ```
   - If >80%, server is overloaded

3. **Check Transfer Phases** (from traces):
   - Look at slowest span in authority transfer traces
   - Common bottlenecks:
     - **Pre-loading**: Large state to transfer
     - **Handshake**: Network round-trip time
     - **State transfer**: Serialization overhead

4. **Check Region Sync**:
   ```promql
   histogram_quantile(0.95, rate(region_sync_latency_ms_bucket[5m]))
   ```
   - If high, boundary sync is slow

**Resolution**:

- **Network issue**: Check firewall, routing, bandwidth
- **Server overload**: Split regions or spawn new server
- **Large state**: Optimize serialization, reduce state size
- **Slow sync**: Optimize boundary synchronization algorithm

### High Server CPU Usage

**Symptoms**: CPU usage >80%

**Investigation Steps**:

1. **Check Player Count**:
   ```promql
   sum(region_player_count{server_id="1"})
   ```

2. **Check Entity Count**:
   ```promql
   sum(region_entity_count{server_id="1"})
   ```

3. **Check FPS**:
   ```promql
   fps{server_id="1"}
   ```
   - If <85, server can't keep up with game loop

4. **Check Frame Time**:
   ```promql
   frame_time_ms{server_id="1"}
   ```
   - If >11.1ms consistently, processing is too slow

**Resolution**:

- **Too many players**: Split high-density regions
- **Too many entities**: Implement entity culling/LOD
- **Slow processing**: Profile and optimize hot code paths
- **Inefficient algorithms**: Review and optimize game logic

### Authority Transfer Failures

**Symptoms**: Transfer failure rate >0

**Investigation Steps**:

1. **Check Error Logs**:
   - Look for transfer failure reasons in Godot console

2. **Check Target Server Health**:
   ```promql
   up{server_id="target_server"}
   ```

3. **Check Retry Count**:
   ```promql
   rate(authority_transfer_retries_total[5m])
   ```

4. **Check Network Connectivity**:
   - Ping between servers
   - Check inter-server message success rate

**Common Causes**:

- **Target server down**: Server crashed or network unreachable
- **Timeout**: Transfer took too long (>100ms)
- **State desync**: Region state inconsistent
- **Network partition**: Temporary disconnection between servers

**Resolution**:

- **Server down**: Restart server, investigate crash
- **Timeout**: Optimize transfer, check network
- **State desync**: Force resync, check replication
- **Network partition**: Check infrastructure, may need retry

### Region Capacity Exceeded

**Symptoms**: Region player count >100

**Investigation Steps**:

1. **Verify Region Density**:
   ```promql
   region_player_count{region_id="(x,y,z)"}
   ```

2. **Check Dynamic Scaling**:
   ```promql
   rate(region_splits_total[10m])
   ```
   - If 0, dynamic scaling may not be working

3. **Check Server Capacity**:
   ```promql
   server_node_count
   ```
   - May need more servers before splitting

**Resolution**:

1. **Trigger Manual Split**:
   ```gdscript
   mesh_coordinator.split_region(region_id)
   ```

2. **Spawn Additional Server** (if needed):
   ```gdscript
   mesh_coordinator.spawn_server_node()
   ```

3. **Monitor Split Progress**:
   - Watch for `region_splits_total` increment
   - Verify players redistributed

4. **Verify No Player Disconnections**:
   ```promql
   rate(player_disconnects_total[1m])
   ```

### Imbalanced Load Distribution

**Symptoms**: High CPU variance across servers

**Investigation Steps**:

1. **Check Load Distribution**:
   ```promql
   stddev(server_cpu_usage)
   ```
   - If >0.30, load is imbalanced

2. **Check Region Assignments**:
   - Review which regions are on which servers
   - Look for hotspots (high-density regions)

3. **Check Region Sizes**:
   - Large regions should be split
   - Small regions should be merged

**Resolution**:

- **Hotspots**: Split high-density regions
- **Cold spots**: Merge low-density regions
- **Reassign regions**: Move regions from overloaded to underloaded servers

---

## Performance Tuning

### Optimizing Metric Collection

**Default Settings**:
- Scrape interval: 15 seconds
- Metric history: 100 samples per metric
- Trace storage: 1000 traces

**Tuning for High-Frequency Systems**:

```gdscript
# Reduce metric history to save memory
MonitoringSystem.MAX_METRIC_HISTORY = 50

# Reduce trace storage
MonitoringSystem.MAX_TRACES = 500

# Increase Prometheus scrape interval
# Edit prometheus.yml:
scrape_interval: 30s
```

**Tuning for Low-Latency Requirements**:

```gdscript
# Increase history for better statistics
MonitoringSystem.MAX_METRIC_HISTORY = 200

# Increase trace storage for deeper analysis
MonitoringSystem.MAX_TRACES = 2000

# Decrease Prometheus scrape interval
# Edit prometheus.yml:
scrape_interval: 5s
```

### Optimizing Alert Rules

**Reduce Alert Noise**:

```yaml
# Increase alert duration before firing
- alert: HighServerCPU
  expr: server_cpu_usage > 0.80
  for: 10m  # Was 5m
```

**Increase Sensitivity for Critical Issues**:

```yaml
# Decrease alert duration for critical alerts
- alert: CriticalTransferLatency
  expr: histogram_quantile(0.95, rate(authority_transfer_latency_ms_bucket[5m])) > 250
  for: 1m  # Was 3m
```

### Optimizing Dashboard Performance

**For Large Server Counts (>10 servers)**:

- Use recording rules for complex queries
- Increase dashboard refresh interval to 30s
- Use server_id template variable to filter

**Recording Rule Example**:

```yaml
# In prometheus.yml
groups:
  - name: server_mesh_recordings
    interval: 30s
    rules:
      - record: job:authority_transfer_latency_ms:p95
        expr: histogram_quantile(0.95, rate(authority_transfer_latency_ms_bucket[5m]))
```

Then use in dashboard:
```promql
job:authority_transfer_latency_ms:p95
```

### Memory Optimization

**Prometheus Retention**:

```yaml
# In docker-compose.yml
command:
  - '--storage.tsdb.retention.time=7d'  # Reduce from 15d
  - '--storage.tsdb.retention.size=10GB'  # Add size limit
```

**GDScript Monitoring System**:

```gdscript
# Periodically clear old traces
func _on_cleanup_timer_timeout() -> void:
	monitoring.clear_traces()
```

---

## API Reference

### MonitoringSystem

#### Methods

**`register_metric(name: String, type: MetricType, description: String, labels: Array[String] = [])`**

Register a new metric.

**`set_gauge(name: String, value: float, labels: Dictionary = {})`**

Set gauge metric value.

**`increment_counter(name: String, amount: float = 1.0, labels: Dictionary = {})`**

Increment counter metric.

**`observe_histogram(name: String, value: float, labels: Dictionary = {})`**

Record histogram observation.

**`start_trace(operation: String, metadata: Dictionary = {}) -> String`**

Start distributed trace, returns trace_id.

**`add_span(trace_id: String, span_name: String, duration_us: int, metadata: Dictionary = {})`**

Add span to trace.

**`end_trace(trace_id: String, success: bool = true)`**

End distributed trace.

**`export_prometheus_metrics() -> String`**

Export all metrics in Prometheus text format.

**`get_metrics() -> Dictionary`**

Get all metrics as dictionary.

**`get_active_alerts() -> Dictionary`**

Get all active alerts.

**`get_traces() -> Dictionary`**

Get all traces.

**`get_trace(trace_id: String) -> Dictionary`**

Get specific trace.

**`get_metric_statistics(metric_name: String) -> Dictionary`**

Get statistics (min, max, avg, percentiles) for metric.

**`update_system_metrics()`**

Update system metrics (FPS, memory, etc.). Call from `_process`.

**`set_enabled(enabled: bool)`**

Enable or disable monitoring.

**`clear_metrics()`**

Clear all metrics.

**`clear_traces()`**

Clear all traces.

**`clear_alerts()`**

Clear all alerts.

#### Signals

**`alert_triggered(severity: String, message: String, details: Dictionary)`**

Emitted when alert is triggered.

**`metrics_updated(metrics: Dictionary)`**

Emitted when metrics are updated.

### MonitoringIntegration

#### Methods

**`instrument_server_mesh(coordinator: ServerMeshCoordinator)`**

Instrument ServerMeshCoordinator.

**`instrument_authority_transfer(transfer_system: AuthorityTransferSystem)`**

Instrument AuthorityTransferSystem.

**`instrument_inter_server_comm(comm: InterServerCommunication)`**

Instrument InterServerCommunication.

**`record_transfer_latency(latency_ms: float, from_server: int, to_server: int)`**

Manually record authority transfer latency.

**`record_region_sync_latency(region_id: Vector3i, latency_ms: float)`**

Manually record region sync latency.

**`get_monitoring() -> MonitoringSystem`**

Get monitoring system reference.

---

## Best Practices

### 1. Metric Naming

- Use snake_case: `authority_transfer_latency_ms`
- Include units: `_ms`, `_bytes`, `_percent`
- Use standard suffixes: `_total` for counters

### 2. Label Cardinality

- Keep labels low cardinality (<100 unique values)
- Avoid: player IDs, timestamps
- Good: server_id, region_id, message_type

### 3. Alert Threshold Tuning

- Start with conservative thresholds
- Adjust based on actual performance baselines
- Use percentiles (p95, p99) not averages

### 4. Dashboard Organization

- Group related panels
- Use consistent time ranges
- Add annotations for deployments

### 5. Trace Sampling

- For high-frequency operations, consider sampling
- Always trace failures
- Sample successes at 1-10%

---

## Example Queries

### Operational Queries

```promql
# Overall system health score
job:server_mesh_health:score

# Total player count
sum(region_player_count)

# Authority transfer success rate (last 5m)
1 - (rate(authority_transfer_failures_total[5m]) / rate(authority_transfers_total[5m]))

# Servers with CPU >80%
count(server_cpu_usage > 0.8)

# Regions approaching capacity
count(region_player_count > 80)

# Average players per region
avg(region_player_count)
```

### Performance Queries

```promql
# p95 authority transfer latency
histogram_quantile(0.95, rate(authority_transfer_latency_ms_bucket[5m]))

# p95 inter-server latency
histogram_quantile(0.95, rate(inter_server_latency_ms_bucket[5m]))

# Average FPS across all servers
avg(fps)

# Servers below target FPS
count(fps < 90)
```

### Capacity Planning Queries

```promql
# Player growth rate (players/hour)
rate(player_spawns_total[1h]) * 3600

# Region split rate (splits/hour)
rate(region_splits_total[1h]) * 3600

# Average server load trend
avg_over_time(server_cpu_usage[1h])

# Projected time until server capacity
predict_linear(server_cpu_usage[1h], 3600)
```

---

## Deployment Checklist

- [ ] MonitoringSystem autoload added to all server nodes
- [ ] MonitoringIntegration instrumenting all components
- [ ] HTTP `/metrics` endpoint exposed on all servers
- [ ] Prometheus configured to scrape all servers
- [ ] Alert rules loaded in Prometheus
- [ ] Grafana dashboards imported
- [ ] AlertManager configured for notifications
- [ ] Test alerts by triggering thresholds
- [ ] Verify distributed tracing working
- [ ] Document alert response procedures
- [ ] Train team on dashboard usage

---

## Support and Resources

- **Prometheus Documentation**: https://prometheus.io/docs/
- **Grafana Documentation**: https://grafana.com/docs/
- **PromQL Tutorial**: https://prometheus.io/docs/prometheus/latest/querying/basics/
- **Distributed Tracing**: https://opentelemetry.io/docs/

---

Last Updated: 2025-12-02
Version: 1.0
