# Monitoring and Alerting Runbook

**Version:** 2.5.0
**Last Updated:** 2025-12-02
**Maintained By:** DevOps Team
**Review Cycle:** Monthly

## Table of Contents

1. [Overview](#overview)
2. [Alert Response Procedures](#alert-response-procedures)
3. [Alert Catalog](#alert-catalog)
4. [On-Call Procedures](#on-call-procedures)
5. [Monitoring Tools](#monitoring-tools)

---

## Overview

### Monitoring Stack

- **Metrics:** Prometheus + Grafana
- **Logs:** Journald + Loki (or ELK Stack)
- **Alerts:** PagerDuty
- **Uptime:** UptimeRobot or Pingdom
- **APM:** Custom telemetry via WebSocket (port 8081)
- **Status Page:** status.company.com

### Key Dashboards

**Main Dashboard:** https://grafana.company.com/d/spacetime-overview
**Panels:**
- Service health status
- Request rate (RPS)
- Error rate (%)
- Response time (P50, P95, P99)
- CPU/Memory utilization
- FPS (Godot frame rate)

**Detailed Dashboards:**
- **Performance:** https://grafana.company.com/d/spacetime-performance
- **Errors:** https://grafana.company.com/d/spacetime-errors
- **Resources:** https://grafana.company.com/d/spacetime-resources
- **Business:** https://grafana.company.com/d/spacetime-business

---

## Alert Response Procedures

### Critical Alert Response Workflow

```
Alert Triggered
      ↓
PagerDuty Notification (SMS + Phone)
      ↓
Acknowledge within 5 minutes
      ↓
Create Incident Channel (#incident-YYYY-MM-DD-XXX)
      ↓
Assess Severity (P0-P4)
      ↓
Follow Incident Runbook (RUNBOOK_INCIDENTS.md)
      ↓
Resolve + Document
      ↓
Post-Mortem (if P0/P1)
```

### Alert Acknowledgment

**Step 1: Acknowledge in PagerDuty (< 5 min)**
```bash
# Via mobile app, web, or CLI
pd incident ack <incident-id>

# Add note with initial assessment
pd incident note <incident-id> "Investigating API unresponsive alert. Checking service status."
```

**Step 2: Verify Alert is Real (< 2 min)**
```bash
# Quick health check
curl -s https://spacetime-api.company.com/status | jq .overall_ready

# Check Grafana for metrics confirmation
# If false alarm, resolve with note
pd incident resolve <incident-id> --note "False alarm - service healthy"
```

**Step 3: Create Incident Channel (< 3 min)**
```bash
# In Slack
/incident create "API Unresponsive - investigating"

# Post initial status
# Template:
# 🚨 ALERT: [Alert Name]
# Time: [HH:MM UTC]
# Severity: [P0/P1/P2]
# Status: Investigating
# On-Call: @[name]
```

---

## Alert Catalog

### High Priority Alerts (P0/P1)

#### ALERT: API_DOWN

**Condition:** `up{job="spacetime-api"} == 0`

**Severity:** P0 - Critical

**Description:** API is completely unavailable - all health checks failing

**Response Procedure:**
```bash
# 1. Acknowledge immediately (< 5 min)
pd incident ack $INCIDENT_ID

# 2. Check if service is running
for host in prod-api-01 prod-api-02 prod-api-03; do
  ssh $host "systemctl status godot-spacetime | grep Active"
done

# 3. If service down, restart
for host in prod-api-01 prod-api-02 prod-api-03; do
  ssh $host "sudo systemctl restart godot-spacetime"
done

# 4. Wait for startup (30 seconds)
sleep 30

# 5. Verify recovery
curl -s https://spacetime-api.company.com/status | jq .overall_ready

# 6. If still down, escalate immediately
# See RUNBOOK_INCIDENTS.md - Incident 1: API Completely Unresponsive

# 7. Once resolved, document in incident channel
# 8. Post-mortem required if outage > 5 minutes
```

**Escalation:** If unresolved after 15 minutes, page manager

**Prevention:**
- Implement health check retries
- Add pre-failure CPU/memory alerts
- Improve service restart automation

---

#### ALERT: HIGH_ERROR_RATE

**Condition:** `rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05`

**Severity:** P1 - High (if > 5%), P2 - Medium (if > 1%)

**Description:** More than 5% of requests returning HTTP 5xx errors

**Response Procedure:**
```bash
# 1. Acknowledge alert
pd incident ack $INCIDENT_ID

# 2. Identify failing endpoints
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '5 minutes ago' | grep 'HTTP 500' | awk '{print \$(NF-1)}' | sort | uniq -c | sort -rn"

# Expected output shows which endpoints are failing most:
#  125 /scene/load
#   45 /debug/evaluate

# 3. Check error messages for top failing endpoint
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '5 minutes ago' | grep '/scene/load' | grep ERROR | tail -20"

# 4. Follow resolution procedure based on error type
# See RUNBOOK_INCIDENTS.md - Incident 2: High Error Rate

# 5. Monitor error rate trend
watch -n 10 'curl -s "https://prometheus.company.com/api/v1/query?query=rate(http_requests_total{status=~\"5..\"}[5m])/rate(http_requests_total[5m])" | jq -r ".data.result[0].value[1]"'

# 6. Once error rate < 1% for 10 minutes, resolve
```

**Escalation:** If error rate continues to increase after 30 minutes

**Prevention:**
- Add endpoint-specific error rate alerts
- Implement circuit breakers
- Add better error handling in code

---

#### ALERT: SLOW_RESPONSE_TIME

**Condition:** `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.5`

**Severity:** P1 - High (if P95 > 1s), P2 - Medium (if P95 > 500ms)

**Description:** 95th percentile response time exceeding 500ms

**Response Procedure:**
```bash
# 1. Acknowledge alert
pd incident ack $INCIDENT_ID

# 2. Check current response times
for i in {1..10}; do
  curl -o /dev/null -s -w "%{time_total}\n" https://spacetime-api.company.com/status
done | awk '{sum+=$1} END {print "Average:", sum/NR*1000, "ms"}'

# 3. Identify slow endpoints
# Check Grafana performance dashboard for endpoint breakdown

# 4. Check resource usage
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host ==="
  ssh $host "top -bn1 | head -20"
done

# Look for:
# - High CPU (> 80%)
# - High memory (> 90%)
# - Swap usage
# - High iowait

# 5. Follow resolution based on bottleneck
# See RUNBOOK_INCIDENTS.md - Incident 3: Slow Response Times

# 6. Verify improvement
# Response time should be < 200ms (P95) before resolving
```

**Escalation:** If response time > 1s for 1 hour

**Prevention:**
- Implement response time budgets per endpoint
- Add performance testing to CI/CD
- Optimize hot paths

---

#### ALERT: HIGH_MEMORY_USAGE

**Condition:** `(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.90`

**Severity:** P1 - High

**Description:** Memory usage above 90% - risk of OOM

**Response Procedure:**
```bash
# 1. Acknowledge alert
pd incident ack $INCIDENT_ID

# 2. Check memory usage immediately
ssh prod-api-01 "free -h && ps aux | grep godot | grep -v grep"

# 3. Check if memory leak (growing over time)
# Look at Grafana memory trend over last 6 hours

# 4. If OOM imminent (> 95%), restart service immediately
if [ $(ssh prod-api-01 "free | grep Mem | awk '{print \$3/\$2 * 100.0}'") > 95 ]; then
  echo "CRITICAL: Memory > 95%, restarting service"
  ssh prod-api-01 "sudo systemctl restart godot-spacetime"
fi

# 5. If memory leak confirmed, implement temporary restarts
# See RUNBOOK_INCIDENTS.md - Incident 6: Memory Leak

# 6. Create ticket for memory leak investigation
# 7. Monitor memory for 2 hours after mitigation
```

**Escalation:** If memory leak is severe (> 2GB/hour growth)

**Prevention:**
- Implement memory profiling
- Add memory leak detection tests
- Review code for proper resource cleanup

---

#### ALERT: HIGH_CPU_USAGE

**Condition:** `100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80`

**Severity:** P2 - Medium

**Description:** CPU usage above 80% for 5 minutes

**Response Procedure:**
```bash
# 1. Acknowledge alert
pd incident ack $INCIDENT_ID

# 2. Identify CPU-intensive processes
ssh prod-api-01 "top -bn1 -o %CPU | head -20"

# 3. Check if Godot is using excessive CPU
GODOT_CPU=$(ssh prod-api-01 "ps aux | grep godot | grep -v grep | awk '{print \$3}'")
echo "Godot CPU usage: ${GODOT_CPU}%"

# 4. If Godot > 80%, check what's causing it
# - Check request rate (sudden traffic spike?)
# - Check for infinite loops in logs
# - Profile hot spots if possible

# 5. Temporary mitigation
# - If traffic spike, consider rate limiting
# - If bug, restart service
# - If sustained high load, scale horizontally

# 6. Monitor for 30 minutes
# CPU should drop below 60% before resolving
```

**Escalation:** If CPU sustained > 90% for 1 hour

**Prevention:**
- Implement CPU profiling
- Add load testing to CI/CD
- Set up auto-scaling

---

#### ALERT: DISK_SPACE_LOW

**Condition:** `(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes > 0.85`

**Severity:** P1 - High (if > 95%), P2 - Medium (if > 85%)

**Description:** Disk space above 85% - risk of disk full

**Response Procedure:**
```bash
# 1. Acknowledge alert
pd incident ack $INCIDENT_ID

# 2. Check disk usage
ssh prod-api-01 "df -h /opt/spacetime"

# 3. Find space consumers
ssh prod-api-01 "du -h /opt/spacetime --max-depth=2 | sort -rh | head -20"

# 4. Follow cleanup procedure
# See RUNBOOK_INCIDENTS.md - Incident 7: Disk Space Exhaustion

# 5. If critical (> 95%), immediate cleanup:
# - Compress and remove old logs
# - Remove old backups
# - Clear temp files

# 6. Verify space recovered
ssh prod-api-01 "df -h /opt/spacetime"

# Should be < 80% before resolving
```

**Escalation:** If disk fills completely and service fails

**Prevention:**
- Implement automated log rotation
- Set up disk space monitoring at 70%, 80%, 90%
- Automate backup cleanup
- Consider disk expansion if recurring

---

### Medium Priority Alerts (P2/P3)

#### ALERT: AUTHENTICATION_FAILURES

**Condition:** `rate(auth_failures_total[5m]) > 10`

**Severity:** P2 - Medium

**Description:** High rate of authentication failures - possible attack

**Response Procedure:**
```bash
# 1. Check authentication failure rate
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '10 minutes ago' | grep -c 'authentication failed'"

# 2. Identify source IPs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '10 minutes ago' | grep 'authentication failed' | awk '{print \$NF}' | sort | uniq -c | sort -rn | head -10"

# 3. If brute force attack suspected:
# - Block offending IPs
# - Implement rate limiting
# - Rotate tokens if necessary

# 4. Monitor for 15 minutes
```

**Prevention:**
- Implement rate limiting on auth endpoints
- Add IP-based blocking
- Use CAPTCHA for suspicious activity

---

#### ALERT: CERTIFICATE_EXPIRING

**Condition:** `ssl_certificate_expiry_days < 30`

**Severity:** P3 - Low

**Description:** SSL/TLS certificate expiring in less than 30 days

**Response Procedure:**
```bash
# 1. Verify certificate expiry
openssl s_client -connect spacetime-api.company.com:443 -servername spacetime-api.company.com </dev/null 2>/dev/null | openssl x509 -noout -dates

# 2. Schedule certificate renewal
# If using Let's Encrypt:
sudo certbot renew --dry-run

# If manual renewal needed, create ticket

# 3. Monitor auto-renewal status
systemctl status certbot.timer
```

**Escalation:** At 14 days before expiry if not renewed

**Prevention:**
- Ensure auto-renewal is working
- Add alerts at 60, 30, 14, 7 days
- Test renewal process quarterly

---

#### ALERT: GODOT_FPS_LOW

**Condition:** `godot_fps < 85` (via telemetry)

**Severity:** P2 - Medium

**Description:** Godot frame rate below target 90 FPS

**Response Procedure:**
```bash
# 1. Check current FPS via telemetry
python3 << 'EOF'
import asyncio
import websockets
import json

async def check_fps():
    async with websockets.connect('ws://prod-api-01:8081') as ws:
        await ws.recv()  # Connection message
        for _ in range(5):
            msg = await ws.recv()
            data = json.loads(msg)
            if data.get('event') == 'fps':
                print(f"FPS: {data['data']['fps']}, Frame Time: {data['data']['frame_time_ms']}ms")

asyncio.run(check_fps())
EOF

# 2. Check for CPU/memory pressure
ssh prod-api-01 "top -bn1 | head -15"

# 3. Check for heavy operations in logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '5 minutes ago' | grep -E 'processing|computation|heavy'"

# 4. Temporary mitigation:
# - Reduce logging verbosity
# - Disable non-critical features
# - Restart if needed

# 5. If persistent, investigate code optimization
```

**Prevention:**
- Add FPS performance tests
- Profile Godot performance regularly
- Optimize rendering pipeline

---

### Low Priority Alerts (P3/P4)

#### ALERT: BACKUP_FAILED

**Condition:** Daily backup job exit code != 0

**Severity:** P3 - Low

**Description:** Automated backup failed

**Response Procedure:**
```bash
# 1. Check backup logs
cat /var/log/spacetime-backup.log | tail -50

# 2. Identify failure reason
# - Disk space?
# - Permissions?
# - S3 connectivity?

# 3. Re-run backup manually
sudo /opt/spacetime/scripts/backup_full.sh

# 4. Fix underlying issue
# 5. Verify next scheduled backup succeeds
```

**Prevention:**
- Add disk space check before backup
- Verify S3 credentials regularly
- Add backup verification step

---

#### ALERT: LOG_ERRORS_INCREASING

**Condition:** `rate(log_errors_total[10m]) > rate(log_errors_total[10m] offset 10m) * 1.5`

**Severity:** P3 - Low

**Description:** Error rate in logs increasing by 50%

**Response Procedure:**
```bash
# 1. Review error types
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '20 minutes ago' | grep ERROR | awk '{for(i=5;i<=NF;i++) printf \"%s \", \$i; print \"\"}' | sort | uniq -c | sort -rn | head -10"

# 2. Identify new error patterns
# 3. Create ticket for investigation
# 4. Monitor if errors stabilize or continue increasing
```

---

## On-Call Procedures

### Shift Start Checklist

**Time:** 5 minutes before shift starts

```bash
# 1. Check PagerDuty shift assignment
# Login to PagerDuty, verify you're on-call

# 2. Test alert notification
# Send test page to yourself
pd incident trigger --service spacetime-api --title "Test Alert - [Your Name]"
# Verify you receive: push notification, SMS, phone call

# 3. Review current system status
curl -s https://spacetime-api.company.com/status | jq .

# 4. Check for active incidents
pd incident list --status triggered,acknowledged

# 5. Review recent alerts (last 24 hours)
# Check PagerDuty incident history

# 6. Read handoff notes from previous on-call
# Check Slack #on-call-handoff channel

# 7. Verify access to all systems
# - SSH to production hosts
# - Access to Grafana dashboards
# - Access to AWS console
# - Access to PagerDuty

# 8. Review on-call runbooks
# Skim RUNBOOK_INCIDENTS.md for common scenarios

# 9. Check escalation contacts
# Verify you have contact info for senior engineers and manager

# 10. Post in Slack
# "On-call shift started for [date range]. Ready to respond. ✅"
```

---

### During Shift

**Active Monitoring:**
```bash
# Every 2-4 hours, review dashboards
# - Grafana overview dashboard
# - Check for any yellow/red indicators
# - Review error rate trends
# - Check resource utilization trends

# Daily (once per shift):
# - Review backup status
# - Check certificate expiry
# - Review system logs for warnings
```

**Alert Response:**
1. Acknowledge within 5 minutes
2. Assess severity
3. Create incident channel if P0/P1
4. Follow incident runbook
5. Document actions taken
6. Resolve or escalate

---

### Shift End Checklist

**Time:** Last 15 minutes of shift

```bash
# 1. Review shift summary
# - Number of alerts: ____
# - Incidents handled: ____
# - Escalations: ____

# 2. Document any ongoing issues
# - Create handoff notes
# - Update incident channels
# - List any follow-up items

# 3. Write handoff notes
# Post in #on-call-handoff:
# """
# On-Call Handoff: [Date]
#
# Alerts This Shift: [number]
# Incidents: [list any significant incidents]
# Ongoing Issues: [list any unresolved items]
#
# Notes for Next On-Call:
# - [Important information]
# - [System status updates]
# - [Upcoming maintenance]
#
# Contact me if questions: @[name]
# """

# 4. Verify next on-call is ready
# Send direct message to confirm

# 5. Update on-call calendar
# Mark shift as complete

# 6. Post in Slack
# "On-call shift ended. Handing off to @[next-oncall]. ✅"
```

---

### False Positive Handling

**When Alert is False Positive:**

```bash
# 1. Verify it's truly false positive
# Don't resolve too quickly - investigate thoroughly

# 2. Document why it's false positive
# Add detailed note in PagerDuty:
pd incident note $INCIDENT_ID "False alarm: Service was healthy during alert window. Likely monitoring hiccup. Verified with direct checks."

# 3. Resolve with category
pd incident resolve $INCIDENT_ID --category "false_positive"

# 4. Create ticket to fix alert
# If recurring false positives, alert threshold may need adjustment

# 5. Update runbook if needed
# Document patterns that look like alerts but aren't
```

---

## Monitoring Tools

### Prometheus Queries

**Useful PromQL Queries:**

```promql
# Current error rate
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])

# Request rate by endpoint
sum(rate(http_requests_total[5m])) by (endpoint)

# P95 response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# CPU usage percentage
100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Disk usage percentage
(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100

# Active connections
sum(godot_connections_active)

# Requests per second
rate(http_requests_total[1m])

# Error count by type
sum(increase(http_requests_total{status=~"5.."}[5m])) by (status)
```

---

### Grafana Panels

**Essential Panels for Main Dashboard:**

1. **Overall Health**
   - Type: Stat
   - Query: `up{job="spacetime-api"}`
   - Thresholds: 1 = green, 0 = red

2. **Request Rate**
   - Type: Graph
   - Query: `sum(rate(http_requests_total[5m]))`

3. **Error Rate**
   - Type: Graph
   - Query: `rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])`
   - Thresholds: < 0.005 = green, < 0.01 = yellow, >= 0.01 = red

4. **Response Time (P95)**
   - Type: Graph
   - Query: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`
   - Thresholds: < 0.2 = green, < 0.5 = yellow, >= 0.5 = red

5. **CPU Usage**
   - Type: Graph
   - Query: `100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`

6. **Memory Usage**
   - Type: Graph
   - Query: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`

7. **Disk Usage**
   - Type: Gauge
   - Query: `(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100`

8. **Godot FPS**
   - Type: Stat
   - Query: `godot_fps`
   - Thresholds: >= 90 = green, >= 85 = yellow, < 85 = red

---

### Log Analysis

**Useful Log Queries:**

```bash
# Error count last hour
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep -c ERROR

# Top 10 error messages
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep ERROR | awk '{for(i=5;i<=NF;i++) printf "%s ", $i; print ""}' | sort | uniq -c | sort -rn | head -10

# Errors by endpoint
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep ERROR | grep -oP '/(\\w+/\\w+)' | sort | uniq -c | sort -rn

# Authentication failures
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep -i "authentication failed"

# Slow requests (> 1s)
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep "response_time" | awk '$NF > 1000 {print}'

# Service restarts
sudo journalctl -u godot-spacetime --since "1 day ago" | grep "Started\|Stopped"

# Memory allocation failures
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep -i "out of memory\|allocation failed"

# Connection errors
sudo journalctl -u godot-spacetime --since "1 hour ago" | grep -i "connection refused\|timeout\|unreachable"
```

---

### Telemetry WebSocket Monitoring

**Real-Time Monitoring Script:**

```python
#!/usr/bin/env python3
# monitor_telemetry.py
# Real-time telemetry monitoring

import asyncio
import websockets
import json
from datetime import datetime

async def monitor():
    uri = "ws://prod-api-01:8081"

    fps_samples = []
    error_count = 0

    async with websockets.connect(uri) as websocket:
        print(f"Connected to {uri}")

        # Skip connection message
        await websocket.recv()

        while True:
            try:
                message = await asyncio.wait_for(websocket.recv(), timeout=60)
                data = json.loads(message)

                event_type = data.get('event')
                timestamp = datetime.now().strftime("%H:%M:%S")

                if event_type == 'fps':
                    fps = data['data']['fps']
                    frame_time = data['data']['frame_time_ms']
                    fps_samples.append(fps)

                    # Keep last 10 samples
                    if len(fps_samples) > 10:
                        fps_samples.pop(0)

                    avg_fps = sum(fps_samples) / len(fps_samples)

                    # Alert if FPS low
                    if fps < 85:
                        print(f"⚠️  [{timestamp}] LOW FPS: {fps:.1f} (avg: {avg_fps:.1f})")
                    else:
                        print(f"✓ [{timestamp}] FPS: {fps:.1f}, Frame: {frame_time:.1f}ms")

                elif event_type == 'error':
                    error_count += 1
                    error_msg = data['data'].get('message', 'Unknown error')
                    print(f"❌ [{timestamp}] ERROR #{error_count}: {error_msg}")

                elif event_type == 'warning':
                    warning_msg = data['data'].get('message', 'Unknown warning')
                    print(f"⚠️  [{timestamp}] WARNING: {warning_msg}")

            except asyncio.TimeoutError:
                print(f"⚠️  No telemetry received for 60 seconds")
            except Exception as e:
                print(f"❌ Error: {e}")
                break

if __name__ == "__main__":
    print("Starting telemetry monitor...")
    asyncio.run(monitor())
```

---

## Appendix

### Alert Configuration Examples

**Prometheus Alert Rules:**

```yaml
# /etc/prometheus/rules/spacetime-alerts.yml
groups:
  - name: spacetime-api
    interval: 30s
    rules:
      - alert: APIDown
        expr: up{job="spacetime-api"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "SpaceTime API is down"
          description: "{{ $labels.instance }} has been down for more than 2 minutes"

      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
        for: 5m
        labels:
          severity: high
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }}"

      - alert: SlowResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.5
        for: 10m
        labels:
          severity: high
        annotations:
          summary: "Slow response times detected"
          description: "P95 response time is {{ $value }}s"

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.90
        for: 5m
        labels:
          severity: high
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value | humanizePercentage }}"

      - alert: DiskSpaceLow
        expr: (node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes > 0.85
        for: 10m
        labels:
          severity: medium
        annotations:
          summary: "Disk space low"
          description: "Disk usage is {{ $value | humanizePercentage }}"
```

---

### PagerDuty Integration

**Alertmanager Configuration:**

```yaml
# /etc/alertmanager/config.yml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'cluster']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'pagerduty'

  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      continue: true

    - match:
        severity: high
      receiver: 'pagerduty-high'

    - match:
        severity: medium
      receiver: 'slack'

receivers:
  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_SERVICE_KEY'
        description: '{{ .GroupLabels.alertname }}'
        severity: 'critical'

  - name: 'pagerduty-high'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_SERVICE_KEY'
        description: '{{ .GroupLabels.alertname }}'
        severity: 'high'

  - name: 'slack'
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#spacetime-alerts'
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

---

## Runbook Maintenance

- **Review Frequency:** Monthly, after major incidents
- **Last Reviewed:** 2025-12-02
- **Next Review:** 2026-01-02
- **Owner:** DevOps Team
- **Approver:** Engineering Manager
