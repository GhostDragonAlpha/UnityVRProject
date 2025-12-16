# Dashboard Usage Guide - Planetary Survival VR

This guide explains how to use the Grafana dashboards for monitoring Planetary Survival VR game servers, performance metrics, and player activity.

## Table of Contents

1. [Dashboard Overview](#dashboard-overview)
2. [Server Mesh Overview Dashboard](#server-mesh-overview-dashboard)
3. [VR Performance Dashboard](#vr-performance-dashboard)
4. [Database Performance Dashboard](#database-performance-dashboard)
5. [Player Distribution Dashboard](#player-distribution-dashboard)
6. [HTTP API Overview Dashboard](#http-api-overview-dashboard)
7. [Common Operations](#common-operations)
8. [Alert Investigation](#alert-investigation)
9. [Performance Optimization](#performance-optimization)

## Dashboard Overview

### Accessing Dashboards

1. **Open Grafana**: http://localhost:3000
2. **Login**: admin/admin (change on first use)
3. **Navigate**: Dashboards > Planetary Survival

### Dashboard List

| Dashboard | Purpose | Refresh Rate | Key Metrics |
|-----------|---------|--------------|-------------|
| Server Mesh Overview | Monitor distributed server infrastructure | 10s | Server health, authority transfers, topology |
| VR Performance | Track VR-specific performance metrics | 5s | FPS, frame time, input latency, tracking quality |
| Database Performance | Monitor database queries and connections | 30s | Query rate, latency, connection pool usage |
| Player Distribution | Visualize player activity across regions | 30s | Player counts, heatmaps, region load |
| HTTP API Overview | Monitor API health and performance | 10s | Request rate, errors, latency |

### Time Range Selection

Use the time picker (top right) to adjust the viewing window:
- **Last 5 minutes**: Real-time troubleshooting
- **Last 1 hour**: Recent trends (default for most dashboards)
- **Last 24 hours**: Daily patterns
- **Last 7 days**: Weekly trends
- **Custom**: Specific time range investigation

### Auto-Refresh

Enable auto-refresh (top right) for real-time monitoring:
- **5s**: Active incident response
- **10s**: Standard real-time monitoring
- **30s**: Background monitoring
- **Off**: Historical analysis

## Server Mesh Overview Dashboard

**Purpose**: Monitor the health and performance of the distributed server mesh infrastructure.

### Key Panels

#### 1. Server Mesh Health Score (Gauge)

**Location**: Top left
**Description**: Composite health score (0-1) based on:
- CPU usage (30%)
- Memory usage (30%)
- FPS performance (20%)
- Authority transfer success rate (20%)

**Interpretation:**
- **Green (0.9-1.0)**: Healthy
- **Yellow (0.7-0.9)**: Degraded, monitor closely
- **Red (0.0-0.7)**: Critical, investigate immediately

**Actions:**
- Green: No action needed
- Yellow: Check individual server metrics, consider scaling
- Red: Identify bottleneck servers, trigger emergency scaling

#### 2. Active Server Nodes & Regions (Stats)

**Location**: Top center
**Description**: Current count of active servers and regions

**Interpretation:**
- Stable count: Normal operation
- Increasing: Dynamic scaling in response to load
- Decreasing: Servers being shut down (maintenance or scale-down)

**Actions:**
- Verify scaling is intentional
- Check for unexpected server failures
- Monitor player distribution during scaling events

#### 3. Total Players & Authority Transfer Success Rate (Stats)

**Location**: Top right
**Description**: Total players across all servers and transfer success percentage

**Interpretation:**
- Players: Monitor against capacity (100 per region max)
- Success rate >95%: Healthy
- Success rate 90-95%: Investigate network latency
- Success rate <90%: Critical, check server mesh connectivity

**Actions:**
- Low success rate: Check inter-server latency panel
- High player count: Verify regions are balanced
- Sudden drop in players: Check for server crashes

#### 4. Server CPU/Memory Usage (Time Series)

**Location**: Middle section
**Description**: CPU and memory usage per server over time

**Interpretation:**
- Usage <80%: Healthy
- Usage 80-95%: Warning, approaching limits
- Usage >95%: Critical, server overloaded

**Actions:**
- Identify hot servers (consistently high usage)
- Check if load is balanced across servers
- Consider migrating regions to lower-loaded servers
- Scale up if all servers are high

#### 5. Authority Transfer Latency (Time Series)

**Location**: Middle section
**Description**: Percentiles (p50, p90, p95, p99) of authority transfer times

**Target**: <100ms (p95)
**Critical**: >250ms (p95)

**Interpretation:**
- p50 vs p99 gap: Large gap indicates inconsistent performance
- Increasing trend: Network congestion or server overload
- Spikes: Temporary issues, note time for correlation

**Actions:**
- High latency: Check inter-server network
- Increasing trend: Investigate server load
- Spikes: Correlate with server events (scaling, deployments)

#### 6. Player Distribution Heatmap

**Location**: Lower section
**Description**: Heatmap showing player density across regions over time

**Interpretation:**
- Hot regions (red): High player density, may need split
- Cool regions (blue): Low player density, consider merge
- Patterns: Identify peak times and popular areas

**Actions:**
- Red regions with >80 players: Prepare for split
- Multiple adjacent red regions: Create new server
- Blue regions with <10 players: Consider merge

#### 7. Server Topology (Network Graph)

**Location**: Lower right
**Description**: Visual representation of server mesh connections

**Interpretation:**
- Nodes: Individual servers
- Lines: Communication paths
- Node size: Relative load or player count

**Actions:**
- Isolated nodes: Check network connectivity
- Dense clusters: Verify load balancing
- Node color: Indicates health status

#### 8. Top Regions by Player Count (Table)

**Location**: Bottom section
**Description**: Ranked list of regions by player count

**Interpretation:**
- Top regions: Monitor for approaching capacity (100 players)
- Rapid changes: Player migration or events
- Empty regions: Candidates for removal

**Actions:**
- Regions >80 players: Plan split
- Unbalanced load: Investigate why players cluster
- Check region characteristics (planet, resources)

### Use Cases

**Scenario 1: High Server Load**
1. Check Server Mesh Health Score (yellow/red)
2. Identify overloaded servers in CPU/Memory panels
3. Review Player Distribution to see if load is concentrated
4. Check Active Server Nodes - is auto-scaling working?
5. Action: Trigger manual scaling if needed

**Scenario 2: Authority Transfer Failures**
1. Check Authority Transfer Success Rate (<95%)
2. Review Authority Transfer Latency (high p95/p99)
3. Check Inter-Server Message Rate for drops
4. Review Server Topology for network issues
5. Action: Restart problem servers or check network

**Scenario 3: Planning for Player Growth**
1. Review Total Players trend over 24h
2. Check Player Distribution heatmap for patterns
3. Review Top Regions by Player Count
4. Estimate scaling needs based on growth rate
5. Action: Pre-emptively add servers before peak

## VR Performance Dashboard

**Purpose**: Monitor VR-specific performance metrics to ensure smooth player experience.

### Key Panels

#### 1. FPS (Time Series)

**Location**: Top left
**Target**: 90 FPS (VR standard)
**Critical**: <85 FPS

**Interpretation:**
- Stable 90 FPS: Optimal
- 85-90 FPS: Acceptable, monitor
- <85 FPS: Players may experience motion sickness

**Actions:**
- Check Frame Time Distribution for bottlenecks
- Review Performance Bottlenecks table
- Reduce render quality if needed (MSAA, resolution scale)

#### 2. Frame Time Distribution (Time Series)

**Location**: Top right
**Target**: <11.1ms (90 FPS = 11.1ms per frame)

**Interpretation:**
- Frame time vs Physics time gap: Render bottleneck
- High physics time: Physics simulation overhead
- Spikes: GC pauses or asset loading

**Actions:**
- Render bottleneck: Reduce draw calls, lower quality
- Physics bottleneck: Optimize collision detection
- Spikes: Investigate asset streaming

#### 3. VR Headset Tracking Quality (Gauge)

**Location**: Middle section
**Target**: >0.95 (95%)

**Interpretation:**
- >95%: Excellent tracking
- 80-95%: Degraded, check environment
- <80%: Poor tracking, unusable

**Actions:**
- Low quality: Check USB bandwidth
- Intermittent drops: Environmental factors (lighting, occlusion)
- Consistent low: Hardware issue

#### 4. Input Latency (Time Series)

**Location**: Middle section
**Target**: <11ms (p95) - Motion-to-photon latency

**Interpretation:**
- <11ms: Imperceptible lag
- 11-20ms: Noticeable to sensitive users
- >20ms: Significant lag, impacts gameplay

**Actions:**
- High latency: Check frame time first
- CPU-bound: Optimize game logic
- GPU-bound: Reduce render quality

#### 5. Reprojection Rate (Time Series)

**Location**: Middle right
**Target**: 0 (no reprojection)
**Acceptable**: <10/min

**Interpretation:**
- Reprojection: Frames missed, HMD interpolating
- Frequent reprojection: Performance issue
- Occasional: Transient load spikes

**Actions:**
- >10/min: Serious performance problem
- Check FPS and frame time
- Reduce quality settings immediately

#### 6. Comfort System Events (Time Series)

**Location**: Lower section
**Description**: Vignette activations, snap turns, teleports

**Interpretation:**
- High vignette use: Players uncomfortable with motion
- Frequent teleports: Normal movement mechanic
- Snap turns: Players prefer discrete rotation

**Actions:**
- High vignette: Consider reducing speed or acceleration
- Adjust comfort settings based on usage patterns

#### 7. VR Motion Sickness Events (Stat)

**Location**: Bottom section
**Target**: <5 reports/hour

**Interpretation:**
- Low reports: Good VR experience
- Moderate (5-20): Review motion mechanics
- High (>20): Critical UX issue

**Actions:**
- Investigate correlation with FPS drops
- Check if specific game events trigger reports
- Survey players for specific causes

#### 8. Performance Bottlenecks (Table)

**Location**: Bottom section
**Description**: Servers ranked by render time (frame - physics)

**Interpretation:**
- High render time: GPU bottleneck
- High physics time: CPU bottleneck
- Balanced: Well-optimized

**Actions:**
- GPU bottleneck: Reduce draw calls, quality
- CPU bottleneck: Optimize scripts, reduce AI
- Profile specific servers for optimization

### Use Cases

**Scenario 1: FPS Drops During Gameplay**
1. Check Average FPS and Min FPS panels
2. Review Frame Time Distribution for bottleneck
3. Check Reprojection Rate (indicator of missed frames)
4. Review Performance Bottlenecks table
5. Action: Reduce quality settings or optimize code

**Scenario 2: Player Reports of Motion Sickness**
1. Check VR Motion Sickness Events (reports/hour)
2. Review FPS stability (drops cause sickness)
3. Check Comfort System Events usage
4. Review Input Latency (lag causes discomfort)
5. Action: Improve FPS stability, adjust comfort settings

**Scenario 3: Tracking Issues**
1. Check VR Headset Tracking Quality gauge
2. Review Active VR Sessions (widespread or isolated?)
3. Check Controller Battery Levels
4. Review VR Error Events table
5. Action: Investigate USB bandwidth or environmental factors

## Database Performance Dashboard

**Purpose**: Monitor database health, query performance, and connection pool usage.

### Key Panels

#### 1. Database Query Rate (Time Series)

**Location**: Top left
**Description**: Queries per second by operation type

**Interpretation:**
- Steady rate: Normal operation
- Spikes: Batch jobs or player activity surge
- Drops: Potential issue or off-peak hours

**Actions:**
- Unexpected spikes: Check slow queries
- High rate: Verify connection pool is adequate
- Drops: Investigate if application is healthy

#### 2. Query Latency p95 (Time Series)

**Location**: Top right
**Target**: <50ms (p95)
**Critical**: >100ms (p95)

**Interpretation:**
- <50ms: Fast queries
- 50-100ms: Acceptable for complex queries
- >100ms: Slow, impacts user experience

**Actions:**
- High latency: Check Top Queries by Execution Time
- Increasing trend: Database overload or missing indexes
- Spikes: Large queries or lock contention

#### 3. Active Connections & Pool Utilization (Gauges)

**Location**: Middle section
**Target**: <70% pool utilization

**Interpretation:**
- <70%: Adequate capacity
- 70-90%: Approaching limit, monitor
- >90%: Insufficient connections, queries will queue

**Actions:**
- High utilization: Increase connection pool size
- Check for connection leaks (connections not closed)
- Review query efficiency to reduce hold time

#### 4. Slow Queries (Time Series)

**Location**: Middle section
**Target**: 0 queries >100ms

**Interpretation:**
- No slow queries: Well-optimized database
- Occasional: Complex reports or admin queries
- Frequent: Missing indexes or inefficient queries

**Actions:**
- Identify queries from Top Queries table
- Add indexes if table scans are happening
- Optimize query logic or cache results

#### 5. Deadlocks & Lock Timeouts (Time Series)

**Location**: Middle section
**Target**: 0 deadlocks/timeouts

**Interpretation:**
- Zero: No concurrency issues
- Occasional: May indicate race conditions
- Frequent: Critical concurrency problem

**Actions:**
- Review query patterns for lock ordering
- Consider optimistic locking for hot tables
- Reduce transaction scope to minimize lock duration

#### 6. Cache Hit Rate (Gauge)

**Location**: Lower section
**Target**: >95%

**Interpretation:**
- >95%: Effective caching
- 80-95%: Acceptable, may benefit from more cache
- <80%: Poor cache utilization, increase cache size

**Actions:**
- Low hit rate: Increase cache memory
- Check if working set fits in cache
- Review query patterns (sequential scans bypass cache)

#### 7. Top Queries by Execution Time (Table)

**Location**: Bottom section
**Description**: Slowest queries ranked by average execution time

**Interpretation:**
- Identify optimization candidates
- Check if slow queries are expected (reports)
- Look for missing indexes (full table scans)

**Actions:**
- Run EXPLAIN on slow queries
- Add indexes for frequently accessed columns
- Cache results for expensive queries
- Consider query rewriting

#### 8. Top Tables by Query Volume (Table)

**Location**: Bottom section
**Description**: Most frequently accessed tables

**Interpretation:**
- High query volume: Ensure proper indexing
- Unexpected tables: May indicate inefficient code
- Check if hot tables have adequate resources

**Actions:**
- Hot tables: Add read replicas if needed
- Verify indexes support query patterns
- Consider partitioning large tables

### Use Cases

**Scenario 1: Slow Application Performance**
1. Check Query Latency p95 (>50ms)
2. Review Top Queries by Execution Time
3. Check Active Connections (pool exhausted?)
4. Review Slow Queries rate
5. Action: Optimize slow queries or add indexes

**Scenario 2: Connection Pool Exhaustion**
1. Check Connection Pool Utilization (>90%)
2. Review Query Rate (abnormally high?)
3. Check for connection leaks in logs
4. Review Transaction Rate (long transactions?)
5. Action: Increase pool size or fix leaks

**Scenario 3: Database Deadlocks**
1. Check Deadlocks & Lock Timeouts rate
2. Review Transaction Rate (high concurrency?)
3. Identify queries involved in deadlocks (logs)
4. Check lock wait times
5. Action: Reorder query logic to prevent deadlocks

## Player Distribution Dashboard

**Purpose**: Visualize player activity, region load, and population trends.

### Key Panels

#### 1. Total Online Players (Stat)

**Location**: Top left
**Description**: Current total player count across all servers

**Interpretation:**
- Monitor against server capacity
- Track daily/weekly patterns
- Identify growth trends

**Actions:**
- High count: Verify servers are scaling
- Sudden drop: Check for crashes or issues
- Growth: Plan infrastructure scaling

#### 2. Player Count Over Time (Time Series)

**Location**: Top section
**Description**: Historical player count trend

**Interpretation:**
- Daily patterns: Peak hours for capacity planning
- Weekly trends: Weekend vs weekday
- Growth rate: Infrastructure planning

**Actions:**
- Identify peak times for maintenance windows
- Plan scaling for expected growth
- Investigate anomalies (drops, spikes)

#### 3. Player Distribution Heatmap

**Location**: Middle section
**Description**: Player density across regions over time

**Interpretation:**
- Hot spots: Popular regions, may need more capacity
- Cold spots: Underutilized regions
- Patterns: Player migration and behavior

**Actions:**
- Hot regions: Split if >80 players
- Cold regions: Merge if <10 players
- Identify content that attracts players

#### 4. Top 10 Most Populated Regions (Bar Gauge)

**Location**: Lower left
**Description**: Regions ranked by current player count

**Interpretation:**
- Shows region load distribution
- Identifies regions approaching capacity (100)
- Highlights imbalance

**Actions:**
- Regions >80: Plan split
- Multiple full regions: Add servers
- Investigate why specific regions are popular

#### 5. Player Density by Planet (Pie Chart)

**Location**: Lower right
**Description**: Player distribution across different planets

**Interpretation:**
- Shows content popularity
- Identifies underutilized areas
- Helps prioritize development

**Actions:**
- Imbalanced: Investigate why
- Low population planets: Add events or content
- Popular planets: Ensure adequate resources

#### 6. Join/Leave Rate (Time Series)

**Location**: Lower section
**Description**: Player joins and leaves per minute

**Interpretation:**
- Balanced: Normal churn
- High leaves: Issues causing disconnects
- High joins: Successful events or marketing

**Actions:**
- Spikes in leaves: Check for server issues
- Low joins: Review onboarding experience
- Compare to player count to calculate retention

#### 7. Region Scaling Events (Time Series)

**Location**: Lower section
**Description**: Region splits and merges over time

**Interpretation:**
- Active scaling: System responding to load
- No scaling: May indicate stuck system
- Frequent merges: Player population declining

**Actions:**
- Verify scaling is working as expected
- Tune thresholds if scaling too aggressive/passive
- Investigate if manual intervention needed

#### 8. Detailed Region Statistics (Table)

**Location**: Bottom section
**Description**: Complete list of regions with player counts

**Interpretation:**
- Comprehensive view of all regions
- Sortable by player count, server, planet
- Filterable by various criteria

**Actions:**
- Identify all overloaded regions
- Find empty regions for cleanup
- Balance load across servers

### Use Cases

**Scenario 1: Planning for Event**
1. Check Player Count Over Time for peak patterns
2. Review Player Distribution Heatmap for hot spots
3. Check Top Regions by Player Count
4. Estimate expected player increase
5. Action: Pre-add servers, prepare scaling

**Scenario 2: Balancing Server Load**
1. Check Detailed Region Statistics table
2. Sort by server_id to see load per server
3. Review Player Distribution Heatmap
4. Identify imbalanced servers
5. Action: Migrate regions to balance load

**Scenario 3: Investigating Player Drop**
1. Check Total Online Players (sudden decrease)
2. Review Join/Leave Rate (spikes in leaves?)
3. Check Region Statistics (specific regions?)
4. Correlate with other dashboards (server issues?)
5. Action: Identify and fix root cause

## HTTP API Overview Dashboard

**Purpose**: Monitor the health and performance of the Godot HTTP API.

### Key Panels

#### 1. Request Rate (Time Series)

**Location**: Top left
**Description**: Requests per second, broken down by status code

**Interpretation:**
- 2xx: Successful requests
- 4xx: Client errors (bad requests)
- 5xx: Server errors (critical)

**Actions:**
- High 4xx: Check client validation
- Any 5xx: Investigate immediately
- Sudden drop: API may be down

#### 2. Error Rate (Stat)

**Location**: Top right
**Target**: <1%
**Critical**: >5%

**Interpretation:**
- <1%: Healthy
- 1-5%: Elevated, investigate
- >5%: Critical issue

**Actions:**
- Check Top Endpoints by Error Rate
- Review logs for error details
- Verify downstream dependencies

#### 3. Request Latency Percentiles (Time Series)

**Location**: Middle section
**Target**: p95 <500ms

**Interpretation:**
- p50 vs p99 gap: Inconsistent performance
- Increasing trend: Degradation
- Spikes: Temporary overload

**Actions:**
- High latency: Check slow endpoints
- Increasing: Scale up or optimize
- Spikes: Correlate with traffic or deployments

#### 4. Top Endpoints by Request Count (Table)

**Location**: Bottom section
**Description**: Most frequently called endpoints

**Interpretation:**
- Shows API usage patterns
- Identifies hot endpoints for optimization
- Helps prioritize caching

**Actions:**
- Hot endpoints: Ensure optimized
- Unexpected patterns: May indicate inefficiency
- Consider caching for expensive endpoints

#### 5. Top Endpoints by Latency (Table)

**Location**: Bottom section
**Description**: Slowest endpoints by p95 latency

**Interpretation:**
- Optimization candidates
- May need caching or database tuning
- Check if expected (complex operations)

**Actions:**
- Profile slow endpoints
- Add caching where possible
- Optimize database queries
- Consider async processing

## Common Operations

### Investigating an Alert

1. **Click alert notification** to jump to relevant dashboard
2. **Check time range** - set to when alert fired
3. **Review correlated metrics** - CPU, memory, latency
4. **Check annotations** for deployments or events
5. **Drill down to specific servers/regions** using variables
6. **Export data** for detailed analysis if needed

### Comparing Time Periods

1. **Use time range picker** to select baseline period
2. **Click "Compare" (top menu)** to add comparison range
3. **Select comparison period** (e.g., previous week)
4. **Review differences** highlighted in panels
5. **Export comparison** for reports

### Creating Custom Queries

1. **Click panel title** > Edit
2. **Add query** in Queries tab
3. **Write PromQL** (see [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/))
4. **Set legend format** for clear labels
5. **Save** or **Apply** changes

Example PromQL queries:
```promql
# Average FPS across all servers
avg(fps)

# 95th percentile latency by endpoint
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Player count growth rate
rate(player_spawns_total[5m]) * 60 - rate(player_disconnects_total[5m]) * 60
```

### Exporting Data

1. **Click panel title** > Inspect > Data
2. **Select format**: CSV, Excel, JSON
3. **Download** for offline analysis
4. **Use for reports** or detailed investigation

## Alert Investigation

When an alert fires, use dashboards to investigate:

### 1. High CPU Alert

**Dashboard**: Server Mesh Overview
1. Go to **Server CPU Usage** panel
2. Identify which server(s) triggered alert
3. Check **Player Distribution** - is load balanced?
4. Review **Authority Transfer Rate** - high activity?
5. Check **Region Scaling Events** - scaling working?

### 2. Low FPS Alert

**Dashboard**: VR Performance
1. Go to **FPS** panel - identify affected server
2. Check **Frame Time Distribution** - render or physics bottleneck?
3. Review **Draw Calls per Frame** - too many?
4. Check **Performance Bottlenecks** table
5. Review **VR Error Events** - any anomalies?

### 3. Slow Query Alert

**Dashboard**: Database Performance
1. Go to **Query Latency p95** panel
2. Check **Top Queries by Execution Time**
3. Review **Active Connections** - pool exhausted?
4. Check **Slow Queries** rate
5. Review **Cache Hit Rate** - caching effective?

### 4. Authority Transfer Failure

**Dashboard**: Server Mesh Overview
1. Go to **Authority Transfer Success Rate**
2. Check **Authority Transfer Latency** - timeout?
3. Review **Inter-Server Message Rate** - network issues?
4. Check **Server Topology** - connectivity problems?
5. Review **Server Mesh Health Score** - overall health

## Performance Optimization

Use dashboards to identify optimization opportunities:

### CPU Optimization

1. **Identify hot servers** in Server CPU Usage
2. **Check player distribution** - imbalanced?
3. **Review physics time** - simulation overhead?
4. **Check draw calls** - rendering bottleneck?
5. **Optimize or scale** based on findings

### Memory Optimization

1. **Check memory usage trend** - leak?
2. **Review entity count per region** - too many?
3. **Check cache usage** - too much caching?
4. **Profile memory allocation** in game code
5. **Implement object pooling** if high churn

### Database Optimization

1. **Identify slow queries** in Top Queries table
2. **Check cache hit rate** - increase cache?
3. **Review connection pool** - adequate size?
4. **Add indexes** for common queries
5. **Consider read replicas** for high read load

### Network Optimization

1. **Check authority transfer latency**
2. **Review inter-server message rate**
3. **Check for packet loss** (external tools)
4. **Optimize message size** (compression)
5. **Consider regional servers** to reduce latency

## Best Practices

### Dashboard Usage

- **Set appropriate time ranges** for context
- **Use auto-refresh** during active monitoring
- **Enable annotations** to correlate events
- **Customize dashboards** for your workflow
- **Share dashboards** with team via links

### Alerting

- **Don't ignore alerts** - investigate or adjust threshold
- **Document common causes** in runbooks
- **Test alerts** periodically to verify functionality
- **Tune thresholds** based on operational experience
- **Use silences** for planned maintenance

### Monitoring Hygiene

- **Review dashboards regularly** for obsolete panels
- **Archive old dashboards** no longer used
- **Document custom queries** for team knowledge
- **Keep labels consistent** across metrics
- **Optimize expensive queries** for dashboard performance

## Troubleshooting Dashboards

### Dashboard Shows "No Data"

1. **Check time range** - is data available for this period?
2. **Verify Prometheus is scraping** - check targets in Prometheus UI
3. **Check data source** - test connection in Grafana
4. **Review query syntax** - any errors in query editor?

### Dashboard Loads Slowly

1. **Reduce time range** - less data to process
2. **Increase auto-refresh interval** - reduce query frequency
3. **Optimize queries** - use recording rules for expensive queries
4. **Remove unused panels** - fewer queries to run
5. **Check Prometheus performance** - may need scaling

### Metrics Gaps in Time Series

1. **Check Prometheus scrape failures** - target down?
2. **Review scrape interval** - expected for sparse metrics
3. **Check cardinality** - too many unique label combinations?
4. **Verify game server is healthy** - exporting metrics?

### Inconsistent Data Across Dashboards

1. **Check time ranges** - are they synchronized?
2. **Verify data sources** - using same Prometheus instance?
3. **Review metric labels** - filtering differently?
4. **Check aggregations** - different grouping?

## Support

For dashboard-related issues:

1. Check [Monitoring Deployment Guide](MONITORING_DEPLOYMENT.md)
2. Review [Alert Runbook](ALERT_RUNBOOK.md) for specific alerts
3. Consult [Grafana Documentation](https://grafana.com/docs/)
4. Review [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)

## Appendix: Useful PromQL Queries

```promql
# Server Performance
avg(cpu_usage) by (server_id)
avg(memory_usage) by (server_id)
avg(fps) by (server_id)

# Player Metrics
sum(region_player_count)
topk(10, region_player_count)
rate(player_spawns_total[5m]) * 60

# Authority Transfers
histogram_quantile(0.95, rate(authority_transfer_latency_ms_bucket[5m]))
rate(authority_transfers_total[5m])
rate(authority_transfer_failures_total[5m])

# Database Queries
rate(database_queries_total[5m])
histogram_quantile(0.95, rate(database_query_duration_ms_bucket[5m]))
database_connections_active / database_connections_max

# HTTP API
rate(http_requests_total[5m])
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```
