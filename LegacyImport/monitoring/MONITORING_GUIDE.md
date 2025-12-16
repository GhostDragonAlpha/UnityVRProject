# SpaceTime VR Production Monitoring Guide

Complete guide for monitoring and observability of the SpaceTime VR HttpApiServer and production environment.

**Version:** 2.0
**Last Updated:** 2025-12-04
**Status:** Production Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Quick Start](#quick-start)
4. [Monitoring Components](#monitoring-components)
5. [Metrics Reference](#metrics-reference)
6. [Alert Rules](#alert-rules)
7. [Grafana Dashboards](#grafana-dashboards)
8. [Health Monitor](#health-monitor)
9. [Log Aggregation](#log-aggregation)
10. [Troubleshooting](#troubleshooting)
11. [Alert Response Procedures](#alert-response-procedures)
12. [Performance Tuning](#performance-tuning)

---

## Overview

The SpaceTime VR monitoring system provides comprehensive observability for:

- **HttpApiServer (Port 8080)** - REST API health, performance, and security metrics
- **VR Performance** - FPS, frame time, and VR-specific metrics
- **System Resources** - CPU, memory, GPU usage
- **Scene Management** - Scene load times, failures, and history
- **Security** - JWT authentication, rate limiting, unauthorized access attempts
- **Telemetry WebSocket (Port 8081)** - Real-time telemetry streaming
- **Service Discovery (Port 8087)** - UDP broadcast monitoring

### Production Readiness

This monitoring setup implements:

- Real-time health checks with automatic alerting
- Prometheus metrics scraping (15s intervals)
- Grafana visualization with 9+ dashboards
- Alert rules for critical, high, medium, and low severity issues
- Log aggregation with ELK stack support
- Distributed tracing capabilities
- Response time SLA monitoring (<200ms target)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     SpaceTime VR Application                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Godot Engine with HttpApiServer (Port 8080)            │   │
│  │  • JWT Authentication                                     │   │
│  │  • Scene Management                                       │   │
│  │  • Performance Metrics (/performance endpoint)           │   │
│  │  • VR System Monitoring                                   │   │
│  └────────────────────┬─────────────────────────────────────┘   │
│                       │                                          │
│                       │ Exposes /performance endpoint            │
│                       │ (JSON metrics)                           │
└───────────────────────┼──────────────────────────────────────────┘
                        │
                        │ HTTP GET every 15s
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Health Monitor (Python)                      │
│  • Polls /performance endpoint                                  │
│  • Validates response time (<200ms)                            │
│  • Checks memory, FPS, cache, security stats                   │
│  • Generates alerts on failures                                │
│  • Logs to monitoring/health.log                               │
│  • Sends webhook alerts (Slack/Discord/PagerDuty)             │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 │ Metrics data
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Prometheus                                │
│  • Scrapes /performance endpoint (15s interval)                │
│  • Stores time-series data (15d retention)                     │
│  • Evaluates alert rules (30s interval)                        │
│  • Sends alerts to AlertManager                                │
└────────────────┬────────────────────┬──────────────────────────┘
                 │                    │
      Data Source│                    │ Alerts
                 ▼                    ▼
      ┌──────────────────┐  ┌─────────────────┐
      │    Grafana       │  │  AlertManager   │
      │  • Dashboards    │  │  • Routing      │
      │  • Visualization │  │  • Deduplication│
      │  • Alerting      │  │  • Notification │
      └──────────────────┘  └─────────────────┘
```

### Data Flow

1. **HttpApiServer** exposes `/performance` endpoint with JSON metrics
2. **Health Monitor** polls every 30s, validates health, sends alerts
3. **Prometheus** scrapes every 15s, stores time-series data
4. **AlertManager** receives alerts, deduplicates, and routes to channels
5. **Grafana** visualizes metrics with real-time dashboards

---

## Quick Start

### 1. Start SpaceTime VR with HttpApiServer

```bash
# Start Godot editor with HttpApiServer enabled
cd C:/godot
./Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe \
  --path "C:/godot" \
  --editor

# Verify API is running
curl http://localhost:8080/performance
```

**Note:** HttpApiServer requires JWT authentication. Get token from `jwt_token.txt`:

```bash
TOKEN=$(cat jwt_token.txt)
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/performance
```

### 2. Start Health Monitor

```bash
# Basic usage (polls every 30s)
python monitoring/health_monitor.py

# With custom interval and log file
python monitoring/health_monitor.py --interval 60 --log-file /var/log/spacetime/health.log

# With Slack webhook alerts
python monitoring/health_monitor.py --alert-webhook https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# With custom thresholds
python monitoring/health_monitor.py \
  --response-time 0.5 \
  --memory 8000 \
  --fps 85
```

### 3. Start Monitoring Stack (Docker)

```bash
# Start Prometheus, Grafana, and AlertManager
cd monitoring
docker-compose up -d

# Verify services
docker-compose ps

# Access Grafana
open http://localhost:3000
# Default credentials: admin / admin
```

### 4. Import Grafana Dashboard

1. Open Grafana: http://localhost:3000
2. Navigate to Dashboards → Import
3. Upload `monitoring/grafana-dashboard.json`
4. Select Prometheus datasource
5. Click Import

### 5. Test Alert Rules

```bash
# Validate Prometheus configuration
docker exec -it monitoring_prometheus_1 promtool check config /etc/prometheus/prometheus.yml

# Validate alert rules
docker exec -it monitoring_prometheus_1 promtool check rules /etc/prometheus/alerts.yml

# Check AlertManager configuration
docker exec -it monitoring_alertmanager_1 amtool check-config /etc/alertmanager/config.yml
```

---

## Monitoring Components

### HttpApiServer (Port 8080)

**Endpoints:**
- `POST /scene` - Load a scene (AUTH REQUIRED)
- `GET /scene` - Get current scene (AUTH REQUIRED)
- `PUT /scene` - Validate a scene (AUTH REQUIRED)
- `GET /scenes` - List available scenes (AUTH REQUIRED)
- `POST /scene/reload` - Reload current scene (AUTH REQUIRED)
- `GET /scene/history` - Get scene load history (AUTH REQUIRED)
- `GET /performance` - Performance metrics (AUTH REQUIRED)
- `GET /webhooks` - Webhook management (AUTH REQUIRED)
- `GET /jobs` - Job queue status (AUTH REQUIRED)

**Metrics Exposed:**
- FPS and frame time
- Memory usage (static, dynamic)
- Process time and physics time
- Object, resource, and node counts
- Cache statistics (hit rate, size)
- Security stats (rate limit violations, auth failures)

**Authentication:**
- JWT token-based authentication
- Token saved to `jwt_token.txt` on server start
- Include in requests: `Authorization: Bearer <token>`

### Health Monitor (Python Script)

**Features:**
- Continuous polling of `/performance` endpoint
- Response time validation (<200ms threshold)
- Memory usage monitoring (alerts at >10GB)
- FPS monitoring (alerts at <60 FPS for VR)
- Rate limit violation tracking
- Webhook alerting (Slack, Discord, PagerDuty)
- Detailed logging to `monitoring/health.log`

**Alert Types:**
- `API_DOWN` - API not responding
- `SLOW_RESPONSE` - Response time exceeds threshold
- `HIGH_MEMORY` - Memory usage exceeds 80% of limit
- `LOW_FPS` - FPS below VR threshold
- `RATE_LIMIT_VIOLATIONS` - High number of rate limit violations

**Alert Rate Limiting:**
- Max 1 alert per type per 5 minutes
- Prevents alert spam during outages

### Prometheus (Port 9090)

**Configuration:** `monitoring/prometheus.yml`

**Scrape Targets:**
- `spacetime-http-api` - HttpApiServer performance endpoint (15s interval)
- `spacetime-health` - Health check endpoint (30s interval)
- `spacetime-telemetry` - Telemetry WebSocket metrics (30s interval)
- `node-exporter` - System metrics (30s interval)

**Alert Rules:** `monitoring/alerts.yml`
- 4 severity levels (critical, high, medium, low)
- 20+ alert rules covering API, performance, security, and operations

**Data Retention:** 15 days (configurable)

### AlertManager (Port 9093)

**Configuration:** `monitoring/alertmanager/config.yml`

**Features:**
- Alert deduplication
- Alert grouping
- Route to multiple channels (Slack, Email, PagerDuty)
- Inhibition rules (suppress lower-priority alerts during critical issues)
- Silencing (manual alert suppression)

### Grafana (Port 3000)

**Configuration:** `monitoring/grafana/`

**Dashboards:**
- SpaceTime VR Production Monitoring (main dashboard)
- API Request Rate and Latency
- Memory and CPU Usage
- VR Performance (FPS, frame time)
- Scene Management
- Security Metrics
- Cache Performance
- Job Queue Status
- Webhook Delivery Tracking

**Default Credentials:**
- Username: `admin`
- Password: `admin` (change on first login)

---

## Metrics Reference

### Performance Metrics (from /performance endpoint)

#### Memory Metrics
```json
{
  "memory": {
    "static_memory_usage": 524288000,      // bytes
    "static_memory_max": 536870912,        // bytes
    "dynamic_memory_usage": 1048576        // bytes
  }
}
```

**Alert Thresholds:**
- High: >10GB (80% of 12GB limit)
- Critical: >12GB (100% of limit)

#### Engine Metrics
```json
{
  "engine": {
    "fps": 90.0,                          // frames per second
    "process_time": 0.008,                // seconds
    "physics_process_time": 0.011,        // seconds
    "objects_in_use": 1234,               // count
    "resources_in_use": 567,              // count
    "nodes_in_use": 890                   // count
  }
}
```

**Alert Thresholds:**
- FPS Critical: <45 (severe VR degradation)
- FPS High: <85 (VR comfort affected)
- FPS Medium: <90 (target not met)

#### Cache Metrics
```json
{
  "cache": {
    "hit_rate": 0.85,                     // 85%
    "miss_rate": 0.15,                    // 15%
    "total_size_bytes": 1048576,          // bytes
    "entry_count": 42,                    // count
    "eviction_count": 5                   // count
  }
}
```

**Performance Target:**
- Hit rate >80% (good performance)
- Hit rate <50% (consider cache tuning)

#### Security Metrics
```json
{
  "security": {
    "rate_limit_violations": 12,          // count
    "auth_failures": 3,                   // count
    "active_tokens": 5,                   // count
    "blocked_ips": ["192.168.1.100"]      // list
  }
}
```

**Alert Thresholds:**
- Rate limit violations >50/hour (medium)
- Auth failures >20/15min (medium)

---

## Alert Rules

### Critical Alerts (Immediate Response)

#### SpaceTimeAPIDown
**Condition:** `up{job="spacetime-http-api"} == 0` for >1 minute

**Impact:** Users cannot connect to SpaceTime VR

**Actions:**
1. Check Godot process: `ps aux | grep Godot`
2. Verify environment: `echo $GODOT_ENABLE_HTTP_API` (should be "true")
3. Check logs: `tail -f monitoring/health.log`
4. Restart Godot if necessary

#### SpaceTimeLowFPS
**Condition:** `spacetime_fps < 45` for >5 minutes

**Impact:** VR experience severely degraded, nausea risk

**Actions:**
1. Check GPU usage: `nvidia-smi` or Task Manager
2. Disable quality features: lower shadow quality, reduce MSAA
3. Check scene complexity: too many objects?
4. Profile with Godot profiler

#### SpaceTimeMemoryExhaustion
**Condition:** Memory usage >12GB for >10 minutes

**Impact:** OOM kill imminent, application crash likely

**Actions:**
1. Reload scene: `POST /scene/reload`
2. Check for memory leaks: review scene references
3. Restart service if necessary
4. Increase memory limit or optimize scene

### High Severity Alerts (Urgent Response)

#### SpaceTimeHighErrorRate
**Condition:** HTTP error rate >5% for 5 minutes

**Impact:** Many API requests failing

**Actions:**
1. Check logs for error patterns
2. Verify JWT authentication
3. Check database/storage connectivity
4. Review recent deployments

#### SpaceTimeHighMemory
**Condition:** Memory usage >10GB for 10 minutes

**Impact:** Memory leak suspected, approaching limit

**Actions:**
1. Monitor memory growth rate
2. Review scene for memory leaks
3. Prepare to reload scene
4. Check for orphaned resources

### Medium Severity Alerts (Business Hours)

#### SpaceTimeRequestLatencyHigh
**Condition:** p95 latency >500ms for 15 minutes

**Impact:** API responses slow, user experience degraded

**Actions:**
1. Check database performance
2. Review slow queries
3. Check network latency
4. Consider caching improvements

#### SpaceTimeRateLimitViolations
**Condition:** >50 rate limit violations per hour

**Impact:** Possible DoS attack or misconfigured client

**Actions:**
1. Review rate limit logs
2. Identify source IPs
3. Adjust rate limits if legitimate traffic
4. Block IPs if malicious

### Low Severity Alerts (Informational)

#### SpaceTimeSceneLoadSlow
**Condition:** Scene load time >3 seconds

**Impact:** User experience slightly degraded

**Actions:**
1. Optimize scene assets
2. Check disk I/O performance
3. Review scene complexity
4. Consider scene preloading

---

## Grafana Dashboards

### Main Dashboard: SpaceTime VR Production Monitoring

**Panels:**

1. **System Overview** (Stat panel)
   - API Status (up/down)
   - Current FPS
   - Memory usage
   - Requests per second

2. **API Health** (Graph)
   - API uptime percentage
   - Response time (p50, p95, p99)
   - Request rate

3. **VR Performance** (Graph)
   - FPS over time
   - Frame time
   - Process time vs physics time

4. **Memory Usage** (Graph)
   - Static memory
   - Dynamic memory
   - Memory growth rate

5. **Scene Management** (Table)
   - Recent scene loads
   - Load duration
   - Success/failure status

6. **Security Events** (Counter)
   - Rate limit violations
   - Auth failures
   - Active JWT tokens

7. **Cache Performance** (Gauge)
   - Hit rate percentage
   - Cache size
   - Eviction count

8. **Active Alerts** (Alert list)
   - Current firing alerts
   - Alert severity
   - Time since triggered

**Dashboard Variables:**
- `instance` - Select specific server instance
- `time_range` - Adjust time window (1h, 6h, 24h, 7d)

---

## Health Monitor

### Installation

```bash
# Health monitor is included in monitoring/health_monitor.py
cd C:/godot
python monitoring/health_monitor.py --help
```

### Configuration

**Command-line options:**
```bash
--api-url URL              # HttpApiServer base URL (default: http://localhost:8080)
--health-endpoint PATH     # Health check endpoint (default: /performance)
--interval SECONDS         # Poll interval (default: 30)
--log-file PATH           # Log file path (default: monitoring/health.log)
--response-time SECONDS   # Response time threshold (default: 0.2)
--memory MB               # Memory threshold in MB (default: 10000)
--fps FPS                 # FPS threshold (default: 60)
--alert-webhook URL       # Webhook URL for alerts
--jwt-token TOKEN         # JWT token (defaults to jwt_token.txt)
```

### Running as a Service

#### Linux (systemd)

Create `/etc/systemd/system/spacetime-health-monitor.service`:

```ini
[Unit]
Description=SpaceTime VR Health Monitor
After=network.target

[Service]
Type=simple
User=spacetime
WorkingDirectory=/opt/spacetime
ExecStart=/usr/bin/python3 monitoring/health_monitor.py \
  --interval 30 \
  --log-file /var/log/spacetime/health.log \
  --alert-webhook https://hooks.slack.com/services/YOUR/WEBHOOK
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable spacetime-health-monitor
sudo systemctl start spacetime-health-monitor
sudo systemctl status spacetime-health-monitor
```

#### Windows (NSSM)

```powershell
# Install NSSM (Non-Sucking Service Manager)
choco install nssm

# Install service
nssm install SpaceTimeHealthMonitor "C:\Python\python.exe" "C:\godot\monitoring\health_monitor.py --interval 30"
nssm set SpaceTimeHealthMonitor AppDirectory "C:\godot"
nssm set SpaceTimeHealthMonitor AppStdout "C:\godot\monitoring\health.log"
nssm set SpaceTimeHealthMonitor AppStderr "C:\godot\monitoring\health_error.log"

# Start service
nssm start SpaceTimeHealthMonitor
```

### Alert Webhook Integration

#### Slack

1. Create Slack incoming webhook: https://api.slack.com/messaging/webhooks
2. Use webhook URL with `--alert-webhook` flag

```bash
python monitoring/health_monitor.py \
  --alert-webhook https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
```

#### Discord

1. Create Discord webhook in channel settings
2. Use webhook URL with `--alert-webhook` flag

```bash
python monitoring/health_monitor.py \
  --alert-webhook https://discord.com/api/webhooks/123456789/abcdefghijklmnop
```

#### PagerDuty

1. Create PagerDuty integration
2. Use integration URL with `--alert-webhook` flag

---

## Log Aggregation

### Filebeat Configuration

See `monitoring/filebeat.yml` for collecting:
- Godot console logs
- HttpApiServer access logs
- Error logs
- Health monitor logs

### ELK Stack Integration

**Elasticsearch:**
- Stores log data with full-text search
- Index pattern: `spacetime-logs-*`

**Logstash:**
- Parses and enriches log data
- Grok patterns for Godot logs

**Kibana:**
- Log visualization and search
- Pre-built dashboards for error tracking

---

## Troubleshooting

### API Not Responding

**Symptoms:**
- Health monitor logs: "HEALTH CHECK FAILED: Connection error"
- Prometheus: `up{job="spacetime-http-api"} == 0`

**Diagnosis:**
```bash
# Check if Godot is running
ps aux | grep Godot

# Check if port 8080 is listening
netstat -an | grep 8080

# Try manual request
curl -v http://localhost:8080/performance
```

**Solutions:**
1. Verify Godot is running in GUI/editor mode (NOT headless)
2. Check `GODOT_ENABLE_HTTP_API=true` in environment
3. Verify port 8080 is not blocked by firewall
4. Check jwt_token.txt exists and contains valid token
5. Restart Godot editor

### Slow API Response

**Symptoms:**
- Health monitor logs: "SLOW RESPONSE: 0.523s"
- Response time >200ms consistently

**Diagnosis:**
```bash
# Measure response time
time curl -H "Authorization: Bearer $(cat jwt_token.txt)" http://localhost:8080/performance

# Check system load
top
```

**Solutions:**
1. Check CPU usage - is Godot using 100%?
2. Check disk I/O - slow disk causing delays?
3. Review scene complexity - too many objects?
4. Enable caching for frequently accessed endpoints
5. Increase hardware resources

### High Memory Usage

**Symptoms:**
- Health monitor logs: "HIGH MEMORY: 11234.5MB"
- Memory growing continuously

**Diagnosis:**
```bash
# Check memory details from /performance
curl -H "Authorization: Bearer $(cat jwt_token.txt)" http://localhost:8080/performance | jq '.memory'

# Monitor memory over time
watch -n 5 'curl -s -H "Authorization: Bearer $(cat jwt_token.txt)" http://localhost:8080/performance | jq ".memory.static_memory_usage / 1024 / 1024"'
```

**Solutions:**
1. Reload scene: `POST /scene/reload`
2. Check for memory leaks: review scene node references
3. Clear cache: restart Godot
4. Optimize assets: reduce texture sizes, mesh complexity
5. Increase memory limit or use smaller scenes

### Low FPS

**Symptoms:**
- Health monitor logs: "LOW FPS: 42.3"
- VR experience degraded

**Diagnosis:**
```bash
# Check FPS over time
watch -n 1 'curl -s -H "Authorization: Bearer $(cat jwt_token.txt)" http://localhost:8080/performance | jq .engine.fps'

# Check GPU usage
nvidia-smi  # NVIDIA GPUs
```

**Solutions:**
1. Reduce shadow quality in Godot settings
2. Lower MSAA level (2x → 1x)
3. Disable post-processing effects
4. Optimize scene: reduce polygon count
5. Check VR headset refresh rate settings

### JWT Authentication Failures

**Symptoms:**
- HTTP 401 errors
- Health monitor logs: "HTTP 401: Unauthorized"

**Diagnosis:**
```bash
# Check if jwt_token.txt exists
cat jwt_token.txt

# Verify token format (should be base64-encoded JWT)
cat jwt_token.txt | cut -d. -f2 | base64 -d

# Test with explicit token
TOKEN=$(cat jwt_token.txt)
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/performance
```

**Solutions:**
1. Verify jwt_token.txt exists in project root
2. Restart Godot to regenerate token
3. Check token hasn't expired (default: no expiration)
4. Verify `Authorization: Bearer <token>` header format
5. Check SecurityConfig whitelist configuration

---

## Alert Response Procedures

### On-Call Escalation

**Severity Levels:**
- **Critical** - Immediate response (5 minutes), page on-call engineer
- **High** - Urgent response (15 minutes), alert primary team
- **Medium** - Business hours response (1 hour), create ticket
- **Low** - Informational, review during daily standup

### Critical Alert Response

1. **Acknowledge alert** - Confirm you're investigating
2. **Assess impact** - How many users affected?
3. **Quick fix** - Restart services if needed
4. **Root cause** - Investigate logs and metrics
5. **Document** - Record incident in runbook
6. **Post-mortem** - Schedule blameless review

### Communication

**Internal:**
- Update incident channel (#incidents)
- Notify team lead and manager
- Post status updates every 30 minutes

**External:**
- Update status page if customer-facing
- Send notifications to affected users
- Post resolution announcement

---

## Performance Tuning

### Prometheus Optimization

**Reduce scrape interval for non-critical targets:**
```yaml
scrape_configs:
  - job_name: 'spacetime-status'
    scrape_interval: 60s  # Increase from 30s
```

**Adjust data retention:**
```yaml
# Command-line flag
--storage.tsdb.retention.time=30d  # Increase from 15d
```

**Enable remote storage:**
```yaml
remote_write:
  - url: "http://victoria-metrics:8428/api/v1/write"
```

### Grafana Optimization

**Reduce dashboard refresh rate:**
- Production: 30s (instead of 5s)
- Development: 5s

**Use recording rules:**
- Pre-compute expensive queries
- Reduce query load on Prometheus

**Enable caching:**
```ini
[caching]
enabled = true
```

### Health Monitor Optimization

**Increase poll interval:**
```bash
python monitoring/health_monitor.py --interval 60  # Increase from 30s
```

**Disable verbose logging:**
- Set log level to WARNING for production

**Use connection pooling:**
- Reuse HTTP connections to reduce overhead

---

## API Reference

### GET /performance

Returns comprehensive performance and system metrics.

**Authentication:** Required (JWT Bearer token)

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

**Status Codes:**
- `200 OK` - Success
- `401 Unauthorized` - Invalid or missing JWT token
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

---

## Additional Resources

- **CLAUDE.md** - SpaceTime VR development guide
- **alerts.yml** - Alert rule definitions
- **prometheus.yml** - Prometheus configuration
- **grafana-dashboard.json** - Dashboard definition
- **filebeat.yml** - Log aggregation config

---

## Support

For issues or questions:
- Review this guide and troubleshooting section
- Check logs: `monitoring/health.log`
- Review Grafana dashboards for metrics
- Contact DevOps team: #spacetime-ops

---

**End of Monitoring Guide**
