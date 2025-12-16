# Alert Runbook - Planetary Survival VR

This runbook provides step-by-step procedures for responding to monitoring alerts in the Planetary Survival VR game. Each alert includes severity levels, diagnostic steps, and resolution procedures.

## Table of Contents

1. [Alert Response Framework](#alert-response-framework)
2. [Server Mesh Alerts](#server-mesh-alerts)
3. [Performance Alerts](#performance-alerts)
4. [Authority Transfer Alerts](#authority-transfer-alerts)
5. [Database Alerts](#database-alerts)
6. [HTTP API Alerts](#http-api-alerts)
7. [VR Performance Alerts](#vr-performance-alerts)
8. [Escalation Procedures](#escalation-procedures)

## Alert Response Framework

### Alert Severity Levels

| Severity | Response Time | Impact | Example |
|----------|---------------|---------|---------|
| **CRITICAL** | <5 minutes | Service degradation or outage | Server down, high error rate |
| **WARNING** | <15 minutes | Potential future problem | High CPU usage, slow queries |
| **INFO** | <1 hour | Informational only | Scaling event, deployment |

### General Response Steps

1. **Acknowledge** - Acknowledge alert in AlertManager to prevent duplicate pages
2. **Assess** - Review dashboard, check scope (single server or widespread)
3. **Mitigate** - Take immediate action to restore service
4. **Diagnose** - Identify root cause
5. **Resolve** - Implement permanent fix
6. **Document** - Update runbook with findings

### Alert Acknowledgment

```bash
# Acknowledge alert in AlertManager
curl -X POST http://localhost:9093/api/v2/silences \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [{"name": "alertname", "value": "HighServerCPU"}],
    "startsAt": "2024-01-01T00:00:00Z",
    "endsAt": "2024-01-01T01:00:00Z",
    "createdBy": "oncall@example.com",
    "comment": "Investigating high CPU usage on server-1"
  }'
```

## Server Mesh Alerts

### CriticalServerCPU

**Alert**: `server_cpu_usage > 0.95 for 2m`
**Severity**: CRITICAL
**Impact**: Server may become unresponsive, affecting player experience

#### Diagnostic Steps

1. **Check dashboard**: Server Mesh Overview > Server CPU Usage
2. **Identify affected server(s)**:
   ```bash
   curl -s 'http://localhost:9090/api/v1/query?query=server_cpu_usage>0.95' | jq
   ```

3. **Check player load**:
   - Dashboard: Player Distribution > Top Regions by Player Count
   - Are players concentrated on this server?

4. **Check recent events**:
   - Dashboard annotations for deployments
   - Region scaling events
   - Authority transfers

#### Resolution Procedures

**Immediate Mitigation:**

1. **Redistribute load** - Migrate regions to other servers:
   ```bash
   # Via game orchestrator API
   curl -X POST http://orchestrator:8080/api/v1/regions/migrate \
     -d '{"region_id": "region-1", "target_server": "server-2"}'
   ```

2. **If persistent, restart server** (last resort):
   ```bash
   # Gracefully drain server first
   curl -X POST http://game-server-1:8080/admin/drain

   # Wait for players to migrate (60 seconds)
   sleep 60

   # Restart server
   docker restart game-server-1
   ```

**Root Cause Investigation:**

- Check for infinite loops or runaway processes
- Review recent code deployments
- Check for excessive entity counts
- Review physics simulation complexity

**Permanent Fix:**

- Optimize expensive game logic
- Tune region split thresholds (reduce max players per region)
- Scale horizontally (add more servers)
- Profile and optimize hot code paths

#### Escalation Criteria

- **Immediate**: Multiple servers >95% CPU for >5 minutes
- **1 hour**: Single server issue persists after restart
- **Next business day**: Recurring issue after optimization

---

### CriticalServerMemory

**Alert**: `server_memory_usage > 0.95 for 2m`
**Severity**: CRITICAL
**Impact**: Risk of OOM kill, server crash, data loss

#### Diagnostic Steps

1. **Check dashboard**: Server Mesh Overview > Server Memory Usage
2. **Check for memory leak**:
   ```bash
   # Get memory trend over last hour
   curl -s 'http://localhost:9090/api/v1/query_range?query=server_memory_usage&start=-1h&step=60s' | jq
   ```

3. **Check entity counts**:
   - Dashboard: Server Mesh Overview > Region Entity Count
   - High entity count = high memory usage

4. **Check for resource leaks**:
   - Review game logs for object allocation warnings
   - Check Godot memory profiler

#### Resolution Procedures

**Immediate Mitigation:**

1. **Force garbage collection** (if supported):
   ```bash
   curl -X POST http://game-server-1:8080/admin/gc
   ```

2. **Reduce entity count** - Despawn inactive entities:
   ```bash
   curl -X POST http://game-server-1:8080/admin/cleanup_entities
   ```

3. **If critical, restart server**:
   ```bash
   # Graceful restart with player migration
   curl -X POST http://orchestrator:8080/api/v1/servers/restart \
     -d '{"server_id": "server-1", "graceful": true}'
   ```

**Root Cause Investigation:**

- Check for memory leaks (increasing usage over time)
- Review entity lifecycle management
- Check texture/asset loading patterns
- Profile memory allocation in hot paths

**Permanent Fix:**

- Implement object pooling for frequently created/destroyed objects
- Optimize asset loading (streaming, unloading)
- Fix memory leaks in game code
- Tune GC settings for better performance
- Increase server memory limits if needed

#### Escalation Criteria

- **Immediate**: All servers >90% memory simultaneously
- **1 hour**: Memory leak confirmed (increasing >10% per hour)
- **Next business day**: One-time spike resolved by restart

---

### ServerNodeDown

**Alert**: `up{job="planetary-survival-server"} == 0 for 1m`
**Severity**: CRITICAL
**Impact**: Players on this server disconnected, regions unavailable

#### Diagnostic Steps

1. **Verify server is actually down**:
   ```bash
   # Ping server
   ping game-server-1

   # Check HTTP endpoint
   curl http://game-server-1:8080/health
   ```

2. **Check recent events**:
   - Deployment or restart in progress?
   - Infrastructure changes?
   - Crash logs?

3. **Check affected players**:
   - Dashboard: Player Distribution > Total Online Players (sudden drop?)
   - How many regions were on this server?

#### Resolution Procedures

**Immediate Mitigation:**

1. **Attempt automatic restart** (if not already done):
   ```bash
   # Via orchestrator
   curl -X POST http://orchestrator:8080/api/v1/servers/start \
     -d '{"server_id": "server-1"}'
   ```

2. **Reassign orphaned regions** to healthy servers:
   ```bash
   # List orphaned regions
   curl http://orchestrator:8080/api/v1/regions?status=orphaned

   # Reassign regions
   curl -X POST http://orchestrator:8080/api/v1/regions/reassign \
     -d '{"region_ids": ["region-1", "region-2"], "target_server": "server-2"}'
   ```

3. **Monitor player reconnections**:
   - Dashboard: Player Distribution > Join/Leave Rate
   - Verify players can reconnect successfully

**Root Cause Investigation:**

- Check server logs for crash reason:
  ```bash
  docker logs game-server-1 --tail 100
  ```
- Check host system logs (OOM killer, kernel panic)
- Review application error logs
- Check for hardware issues (disk full, network)

**Permanent Fix:**

- Fix application bug causing crash
- Increase resource limits if OOM killed
- Fix network configuration if connectivity issue
- Replace hardware if hardware failure
- Improve monitoring for early detection

#### Escalation Criteria

- **Immediate**: Multiple servers down (>25% of fleet)
- **Immediate**: Server won't restart after 3 attempts
- **1 hour**: Frequent restarts (>3 per hour)
- **Next business day**: One-time crash resolved

---

### OrphanedRegion

**Alert**: `region_authoritative_server == -1 for 30s`
**Severity**: CRITICAL
**Impact**: Players in region cannot interact with game state

#### Diagnostic Steps

1. **Identify orphaned region(s)**:
   ```bash
   curl -s 'http://localhost:9090/api/v1/query?query=region_authoritative_server==-1' | jq
   ```

2. **Check if server went down**:
   - Dashboard: Server Mesh Overview > Active Server Nodes
   - Recent drop in server count?

3. **Check how many players affected**:
   ```bash
   curl -s 'http://localhost:9090/api/v1/query?query=region_player_count{region_id="region-1"}' | jq
   ```

#### Resolution Procedures

**Immediate Mitigation:**

1. **Manually assign region to healthy server**:
   ```bash
   curl -X POST http://orchestrator:8080/api/v1/regions/assign \
     -d '{"region_id": "region-1", "server_id": "server-2"}'
   ```

2. **Verify players can reconnect**:
   - Monitor reconnection rate in dashboard
   - Check for errors in game client logs

**Root Cause Investigation:**

- Why did server lose authority?
- Was server shut down unexpectedly?
- Was there a network partition?
- Did region split/merge fail?

**Permanent Fix:**

- Improve authority transfer reliability
- Implement automatic region reassignment
- Add region heartbeat monitoring
- Improve failover detection speed

#### Escalation Criteria

- **Immediate**: >10 regions orphaned simultaneously
- **30 minutes**: Single region can't be reassigned
- **Next business day**: Isolated incident resolved

---

### RegionCapacityExceeded

**Alert**: `region_player_count > 100 for 1m`
**Severity**: CRITICAL
**Impact**: Performance degradation, players unable to join region

#### Diagnostic Steps

1. **Identify overloaded region(s)**:
   ```bash
   curl -s 'http://localhost:9090/api/v1/query?query=region_player_count>100' | jq
   ```

2. **Check why region wasn't split**:
   - Dashboard: Server Mesh Overview > Region Scaling Events
   - Was there a recent split attempt?
   - Is auto-scaling disabled?

3. **Check server capacity**:
   - Dashboard: Server Mesh Overview > Active Server Nodes
   - Are all servers at capacity?

#### Resolution Procedures

**Immediate Mitigation:**

1. **Manually split region**:
   ```bash
   curl -X POST http://orchestrator:8080/api/v1/regions/split \
     -d '{"region_id": "region-1"}'
   ```

2. **If servers at capacity, spawn new server**:
   ```bash
   curl -X POST http://orchestrator:8080/api/v1/servers/spawn \
     -d '{"capacity": "standard", "region": "us-east-1"}'
   ```

3. **Monitor split progress**:
   - Dashboard: Player Distribution > Region Scaling Events
   - Wait for split to complete (~30 seconds)

**Root Cause Investigation:**

- Why did auto-scaling fail?
- Is split threshold set correctly?
- Was there insufficient server capacity?
- Did split operation fail?

**Permanent Fix:**

- Tune region split thresholds (e.g., split at 80 instead of 100)
- Improve auto-scaling responsiveness
- Ensure adequate server capacity headroom
- Add pre-emptive scaling for events

#### Escalation Criteria

- **Immediate**: >5 regions over capacity simultaneously
- **30 minutes**: Split operation failing repeatedly
- **Next business day**: Isolated capacity spike handled

## Performance Alerts

### LowFPS

**Alert**: `fps < 85 for 2m`
**Severity**: WARNING
**Impact**: Degraded player experience, potential motion sickness

#### Diagnostic Steps

1. **Check dashboard**: VR Performance > FPS
2. **Identify bottleneck**:
   - Dashboard: VR Performance > Frame Time Distribution
   - High render time = GPU bottleneck
   - High physics time = CPU bottleneck

3. **Check if isolated or widespread**:
   ```bash
   # Count servers with FPS <85
   curl -s 'http://localhost:9090/api/v1/query?query=count(fps<85)' | jq
   ```

#### Resolution Procedures

**Immediate Mitigation:**

1. **Reduce render quality**:
   ```bash
   curl -X POST http://game-server-1:8080/admin/set_quality \
     -d '{"msaa": 2, "render_scale": 0.8}'
   ```

2. **Reduce physics complexity** (if physics bottleneck):
   ```bash
   curl -X POST http://game-server-1:8080/admin/reduce_physics_load \
     -d '{"reduce_entities": true}'
   ```

**Root Cause Investigation:**

- Check Performance Bottlenecks table in VR Performance dashboard
- Profile game code to identify hot paths
- Check entity counts (too many objects?)
- Review recent code changes

**Permanent Fix:**

- Optimize rendering pipeline (reduce draw calls, improve batching)
- Optimize physics simulation (spatial hashing, broadphase optimization)
- Implement level-of-detail (LOD) system
- Reduce asset complexity (mesh simplification, texture compression)

#### Escalation Criteria

- **1 hour**: FPS consistently <85 despite quality reduction
- **Next business day**: Isolated incident, FPS recovered
- **Immediate**: FPS <60 (unusable for VR)

---

### HighFrameTime

**Alert**: `frame_time_ms > 12 for 2m`
**Severity**: WARNING
**Impact**: Missed frames, potential reprojection

#### Diagnostic Steps

1. **Check dashboard**: VR Performance > Frame Time Distribution
2. **Identify spike cause**:
   - GC pause? (sudden spike)
   - Asset loading? (periodic spikes)
   - Expensive operation? (sustained increase)

3. **Check reprojection rate**:
   - Dashboard: VR Performance > Reprojection Rate
   - High reprojection = missed frames confirmed

#### Resolution Procedures

**Immediate Mitigation:**

1. **Reduce frame budget** for expensive operations:
   ```bash
   # Spread expensive operations across multiple frames
   curl -X POST http://game-server-1:8080/admin/reduce_frame_budget
   ```

2. **Force immediate optimization**:
   ```bash
   curl -X POST http://game-server-1:8080/admin/optimize_now
   ```

**Root Cause Investigation:**

- Profile frame time breakdown (render, physics, scripts, GC)
- Check for expensive operations running on main thread
- Review asset streaming patterns
- Check for GC pauses (tune GC settings)

**Permanent Fix:**

- Move expensive operations to background threads
- Optimize hot code paths
- Implement object pooling to reduce GC pressure
- Tune GC settings (incremental GC)
- Stream assets asynchronously

#### Escalation Criteria

- **1 hour**: Frame time >16ms (below 60 FPS)
- **Next business day**: Isolated spike resolved
- **Immediate**: Sustained >20ms (unusable)

## Authority Transfer Alerts

### CriticalTransferLatency

**Alert**: `histogram_quantile(0.95, rate(authority_transfer_latency_ms_bucket[5m])) > 250 for 3m`
**Severity**: CRITICAL
**Impact**: Slow region transitions, player experience degraded

#### Diagnostic Steps

1. **Check dashboard**: Server Mesh Overview > Authority Transfer Latency
2. **Check network latency between servers**:
   ```bash
   # From one server to another
   docker exec game-server-1 ping -c 5 game-server-2
   ```

3. **Check server load**:
   - Dashboard: Server Mesh Overview > Server CPU/Memory Usage
   - Overloaded servers = slow transfers

4. **Check transfer volume**:
   - Dashboard: Server Mesh Overview > Authority Transfer Rate
   - High volume = congestion

#### Resolution Procedures

**Immediate Mitigation:**

1. **Reduce transfer volume** - Throttle region migrations:
   ```bash
   curl -X POST http://orchestrator:8080/api/v1/config/set \
     -d '{"max_concurrent_transfers": 5}'
   ```

2. **Balance server load** - Migrate regions from overloaded servers:
   ```bash
   curl -X POST http://orchestrator:8080/api/v1/servers/balance
   ```

**Root Cause Investigation:**

- Check inter-server network latency
- Review server load during transfers
- Check transfer payload size (optimize if large)
- Review authority transfer protocol efficiency

**Permanent Fix:**

- Optimize transfer protocol (compression, differential updates)
- Reduce transfer payload size
- Improve network connectivity between servers
- Add transfer prioritization (critical transfers first)
- Implement predictive pre-loading

#### Escalation Criteria

- **Immediate**: Transfers timing out (>1000ms)
- **1 hour**: Latency >250ms despite optimizations
- **Next business day**: Temporary spike resolved

---

### HighTransferFailureRate

**Alert**: `rate(authority_transfer_failures_total[5m]) > 0.1 for 2m`
**Severity**: CRITICAL
**Impact**: Players stuck in regions, unable to move between regions

#### Diagnostic Steps

1. **Check dashboard**: Server Mesh Overview > Authority Transfer Failures
2. **Check failure reasons in logs**:
   ```bash
   docker logs game-server-1 | grep "transfer failed"
   ```

3. **Check network connectivity**:
   ```bash
   # Test connectivity between servers
   docker exec game-server-1 telnet game-server-2 8080
   ```

#### Resolution Procedures

**Immediate Mitigation:**

1. **Restart failed transfers** - Retry mechanism:
   ```bash
   curl -X POST http://orchestrator:8080/api/v1/transfers/retry_failed
   ```

2. **If persistent, restart problem servers**:
   ```bash
   # Identify servers with failures
   curl http://orchestrator:8080/api/v1/servers?health=degraded

   # Restart problem server
   curl -X POST http://orchestrator:8080/api/v1/servers/restart \
     -d '{"server_id": "server-1", "graceful": true}'
   ```

**Root Cause Investigation:**

- Network issues between servers?
- Server overload causing timeouts?
- Bug in transfer protocol?
- Database issues (state persistence)?

**Permanent Fix:**

- Improve transfer retry logic
- Add transfer validation and rollback
- Fix bugs in transfer protocol
- Increase transfer timeout if network latency high
- Improve error handling and recovery

#### Escalation Criteria

- **Immediate**: Failure rate >50%
- **1 hour**: Failures persist after server restart
- **Next business day**: Low failure rate (<5%), transient issue

## Database Alerts

### HighDatabaseLatency

**Alert**: `histogram_quantile(0.95, rate(database_query_duration_ms_bucket[5m])) > 100 for 5m`
**Severity**: WARNING
**Impact**: Slow application performance, degraded player experience

#### Diagnostic Steps

1. **Check dashboard**: Database Performance > Query Latency p95
2. **Identify slow queries**:
   - Dashboard: Database Performance > Top Queries by Execution Time
   ```bash
   # Query database for slow query log
   psql -h database -U admin -c "SELECT * FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"
   ```

3. **Check database load**:
   - Dashboard: Database Performance > Active Connections
   - Connection pool exhausted?

#### Resolution Procedures

**Immediate Mitigation:**

1. **Kill long-running queries** (if blocking others):
   ```bash
   psql -h database -U admin -c "SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE state = 'active' AND query_start < NOW() - INTERVAL '5 minutes';"
   ```

2. **Increase connection pool** (if exhausted):
   ```bash
   curl -X POST http://game-server-1:8080/admin/set_db_pool \
     -d '{"max_connections": 50}'
   ```

**Root Cause Investigation:**

- Missing indexes? (table scans in EXPLAIN output)
- Lock contention? (check pg_locks)
- Database overload? (check CPU/memory)
- Inefficient queries? (review query plans)

**Permanent Fix:**

- Add missing indexes
- Optimize slow queries
- Implement query result caching
- Add database read replicas
- Partition large tables
- Tune database configuration (shared_buffers, work_mem)

#### Escalation Criteria

- **1 hour**: Latency >200ms (critical impact)
- **Next business day**: Latency 100-200ms, queries optimized
- **Immediate**: Database unresponsive (>1000ms)

---

### ConnectionPoolExhausted

**Alert**: `database_connections_active / database_connections_max > 0.9 for 5m`
**Severity**: CRITICAL
**Impact**: New queries will be queued or rejected, application stalls

#### Diagnostic Steps

1. **Check dashboard**: Database Performance > Connection Pool Utilization
2. **Check for connection leaks**:
   ```bash
   psql -h database -U admin -c "SELECT * FROM pg_stat_activity WHERE state_change < NOW() - INTERVAL '10 minutes' AND state = 'idle';"
   ```

3. **Check query rate**:
   - Dashboard: Database Performance > Database Query Rate
   - Abnormally high?

#### Resolution Procedures

**Immediate Mitigation:**

1. **Increase connection pool size**:
   ```bash
   # Update database max_connections
   psql -h database -U admin -c "ALTER SYSTEM SET max_connections = 200;"
   psql -h database -U admin -c "SELECT pg_reload_conf();"

   # Update application pool size
   curl -X POST http://orchestrator:8080/api/v1/config/set \
     -d '{"database_pool_size": 100}'
   ```

2. **Kill idle connections** (free up connections):
   ```bash
   psql -h database -U admin -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle' AND state_change < NOW() - INTERVAL '30 minutes';"
   ```

**Root Cause Investigation:**

- Connection leaks in application code?
- Long-running transactions holding connections?
- Insufficient connection pool configuration?
- Sudden traffic spike?

**Permanent Fix:**

- Fix connection leaks (ensure connections are closed)
- Implement connection pooling middleware (PgBouncer)
- Set connection timeouts
- Optimize query efficiency to reduce hold time
- Scale database if consistently at capacity

#### Escalation Criteria

- **Immediate**: Pool 100% utilized, queries failing
- **1 hour**: Pool >95% despite increasing size
- **Next business day**: Leak fixed, pool adequate

## HTTP API Alerts

### HighHTTPErrorRate

**Alert**: `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > 0.05 for 5m`
**Severity**: CRITICAL
**Impact**: API unreliable, player actions failing

#### Diagnostic Steps

1. **Check dashboard**: HTTP API Overview > Error Rate
2. **Identify error source**:
   - Dashboard: HTTP API Overview > Top Endpoints by Error Rate
   ```bash
   # Check API logs
   docker logs spacetime_godot | grep "ERROR"
   ```

3. **Check affected endpoints**:
   ```bash
   curl -s 'http://localhost:9090/api/v1/query?query=sum(rate(http_requests_total{status=~"5.."}[5m]))by(endpoint)' | jq
   ```

#### Resolution Procedures

**Immediate Mitigation:**

1. **If specific endpoint failing, disable it**:
   ```bash
   curl -X POST http://localhost:8080/admin/disable_endpoint \
     -d '{"endpoint": "/scene/load", "message": "Temporarily disabled due to errors"}'
   ```

2. **Restart API server** (if widespread errors):
   ```bash
   docker restart spacetime_godot
   ```

**Root Cause Investigation:**

- Check error messages in logs
- Downstream service down? (database, cache)
- Recent deployment with bugs?
- Resource exhaustion? (memory, disk)

**Permanent Fix:**

- Fix bugs in failing endpoints
- Add retries for transient errors
- Improve error handling
- Add circuit breakers for downstream services
- Increase rate limits if overload

#### Escalation Criteria

- **Immediate**: Error rate >25%
- **1 hour**: Error rate >5% persists after restart
- **Next business day**: Error rate <1%, minor fix

---

### HTTPAPIDown

**Alert**: `active_connections == 0 for 2m`
**Severity**: CRITICAL
**Impact**: Complete API outage, no player actions possible

#### Diagnostic Steps

1. **Verify API is actually down**:
   ```bash
   curl http://localhost:8080/health
   ```

2. **Check if process is running**:
   ```bash
   docker ps | grep spacetime_godot
   ```

3. **Check logs for crash reason**:
   ```bash
   docker logs spacetime_godot --tail 100
   ```

#### Resolution Procedures

**Immediate Mitigation:**

1. **Restart API server**:
   ```bash
   docker restart spacetime_godot

   # Verify it started
   sleep 5
   curl http://localhost:8080/health
   ```

2. **If won't start, check for issues**:
   ```bash
   # Check disk space
   df -h

   # Check memory
   free -m

   # Check ports
   netstat -tulpn | grep 8080
   ```

**Root Cause Investigation:**

- Application crash? (check logs)
- OOM killed? (check dmesg)
- Port conflict? (check netstat)
- Configuration error? (check config files)

**Permanent Fix:**

- Fix crash bugs
- Increase memory limits
- Add health check restart policy
- Improve startup validation
- Add monitoring for early detection

#### Escalation Criteria

- **Immediate**: API won't restart after 3 attempts
- **Immediate**: Multiple API instances down
- **1 hour**: Frequent crashes (>3 per hour)

## VR Performance Alerts

### VRTrackingDegraded

**Alert**: `vr_tracking_quality < 0.8 for 2m`
**Severity**: WARNING
**Impact**: Poor VR experience, tracking issues

#### Diagnostic Steps

1. **Check dashboard**: VR Performance > VR Headset Tracking Quality
2. **Check if isolated or widespread**:
   ```bash
   curl -s 'http://localhost:9090/api/v1/query?query=count(vr_tracking_quality<0.8)' | jq
   ```

3. **Check for USB bandwidth issues** (if many devices):
   ```bash
   # Check USB controller usage
   lsusb -t
   ```

#### Resolution Procedures

**Immediate Mitigation:**

1. **Reduce visual complexity** (helps tracking processing):
   ```bash
   curl -X POST http://game-server-1:8080/admin/reduce_effects
   ```

2. **Notify affected players**:
   ```bash
   curl -X POST http://game-server-1:8080/admin/broadcast \
     -d '{"message": "If experiencing tracking issues, please check lighting and USB connections"}'
   ```

**Root Cause Investigation:**

- Environmental factors (lighting, occlusion)?
- USB bandwidth saturation?
- Hardware issues?
- Software bug in tracking code?

**Permanent Fix:**

- Add tracking quality warnings to players
- Implement tracking recovery mechanisms
- Optimize tracking algorithm
- Improve hardware recommendations

#### Escalation Criteria

- **1 hour**: Widespread tracking issues (>25% of players)
- **Next business day**: Isolated player issue
- **Immediate**: Tracking completely lost (quality < 0.5)

---

### HighReprojectionRate

**Alert**: `rate(vr_reprojection_events_total[1m]) * 60 > 50 for 2m`
**Severity**: WARNING
**Impact**: Missed frames, degraded VR experience

#### Diagnostic Steps

1. **Check dashboard**: VR Performance > Reprojection Rate
2. **Check FPS**:
   - Dashboard: VR Performance > FPS
   - Reprojection = missing 90 FPS target

3. **Identify bottleneck**:
   - Dashboard: VR Performance > Frame Time Distribution

#### Resolution Procedures

**Immediate Mitigation:**

1. **Reduce render quality**:
   ```bash
   curl -X POST http://game-server-1:8080/admin/emergency_quality_reduction
   ```

2. **Reduce physics complexity**:
   ```bash
   curl -X POST http://game-server-1:8080/admin/reduce_physics_timestep
   ```

**Root Cause Investigation:**

- GPU overload? (high render time)
- CPU overload? (high physics time)
- Memory pressure causing GC pauses?
- Asset loading causing frame spikes?

**Permanent Fix:**

- Same as LowFPS alert (optimize rendering/physics)
- Implement dynamic quality adjustment
- Add frame pacing to smooth out spikes

#### Escalation Criteria

- **1 hour**: Reprojection >100/min (severe)
- **Next business day**: Occasional reprojection (<10/min)
- **Immediate**: Constant reprojection (unusable)

## Escalation Procedures

### When to Escalate

**Escalate IMMEDIATELY if:**
- Multiple CRITICAL alerts firing simultaneously
- Service completely unavailable for >10 minutes
- Data loss or corruption suspected
- Security incident detected
- Unable to restore service with documented procedures

**Escalate within 1 HOUR if:**
- CRITICAL alert persists despite mitigation attempts
- WARNING alert not resolved within expected timeframe
- Root cause unknown and requires expert analysis
- Multiple players reporting the same issue

**Escalate NEXT BUSINESS DAY if:**
- INFO alert or resolved incident requires follow-up
- Documentation needs updating based on incident
- Permanent fix requires significant development work

### Escalation Contacts

```
On-Call Engineer (24/7):   +1-555-0100
Engineering Manager:        +1-555-0101
Database Administrator:     +1-555-0102
Network Operations:         +1-555-0103
Security Team:              +1-555-0104

Slack Channels:
  #incidents          - Active incident coordination
  #alerts-critical    - Critical alert notifications
  #on-call            - On-call engineer channel
```

### Escalation Template

When escalating, provide:

```
Incident ID: [AlertManager alert ID]
Severity: [CRITICAL / WARNING / INFO]
Alert: [Alert name]
Started: [Timestamp]
Impact: [Number of players affected, services impacted]
Actions Taken: [List of mitigation steps attempted]
Current Status: [Current state of the incident]
Need: [What assistance is needed]
```

### Post-Incident

After resolving a CRITICAL incident:

1. **Write incident report** within 24 hours
2. **Conduct blameless postmortem** within 1 week
3. **Update runbook** with lessons learned
4. **Implement preventive measures** identified in postmortem
5. **Share learnings** with team

## Appendix: Quick Reference

### Common Commands

```bash
# Check alert status
curl -s http://localhost:9093/api/v2/alerts | jq

# Silence alert
curl -X POST http://localhost:9093/api/v2/silences -d '...'

# Check server health
curl http://game-server-1:8080/health

# Restart server gracefully
curl -X POST http://orchestrator:8080/api/v1/servers/restart \
  -d '{"server_id": "server-1", "graceful": true}'

# Query metric
curl -s 'http://localhost:9090/api/v1/query?query=up' | jq

# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq
```

### Dashboard Quick Links

```
Grafana:          http://localhost:3000
Prometheus:       http://localhost:9090
AlertManager:     http://localhost:9093
VictoriaMetrics:  http://localhost:8428
```

### Useful PromQL Queries

```promql
# Servers with issues
up == 0
server_cpu_usage > 0.8
server_memory_usage > 0.8
fps < 85

# Database issues
database_connections_active / database_connections_max > 0.8
database_slow_queries_total > 0

# Transfer issues
rate(authority_transfer_failures_total[5m]) > 0.05
histogram_quantile(0.95, rate(authority_transfer_latency_ms_bucket[5m])) > 100

# Player impact
sum(region_player_count)
rate(player_disconnects_total[5m]) * 60
```

---

**Document Version**: 1.0
**Last Updated**: 2024-01-01
**Next Review**: 2024-04-01
