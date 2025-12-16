# Alert Summary - Quick Reference

**SpaceTime HTTP Scene Management API**
**Version:** 2.5.0

---

## Alert Severity Levels

| Level | Response Time | Escalation | Examples |
|-------|---------------|------------|----------|
| **P0** | < 5 minutes | Immediate | Service down, data loss |
| **P1** | < 15 minutes | 30 minutes | High error rate, slow response |
| **P2** | < 1 hour | 4 hours | Minor degradation |
| **P3** | < 4 hours | Next day | Warnings, low priority |
| **P4** | Next business day | None | Informational |

---

## Critical Alerts (P0/P1)

### API_DOWN
- **Condition:** `up{job="spacetime-api"} == 0`
- **Meaning:** API completely unavailable
- **Response:** Restart service immediately
- **Command:**
  ```bash
  sudo systemctl restart godot-spacetime
  curl http://localhost:8080/status
  ```
- **Escalate:** If unresolved after 15 min

### HIGH_ERROR_RATE
- **Condition:** Error rate > 5%
- **Meaning:** Many requests failing
- **Response:** Check logs for error types
- **Command:**
  ```bash
  sudo journalctl -u godot-spacetime | grep ERROR | tail -50
  ```
- **Escalate:** If error rate increasing

### SLOW_RESPONSE_TIME
- **Condition:** P95 > 500ms
- **Meaning:** API responding slowly
- **Response:** Check resource usage
- **Command:**
  ```bash
  top -bn1 | head -20
  iostat -x 1 5
  ```
- **Escalate:** If P95 > 1s for 1 hour

### HIGH_MEMORY_USAGE
- **Condition:** Memory > 90%
- **Meaning:** Risk of OOM
- **Response:** Check for memory leak
- **Command:**
  ```bash
  free -h
  ps aux | grep godot
  ```
- **Escalate:** If memory > 95%

### DISK_SPACE_LOW
- **Condition:** Disk > 85%
- **Meaning:** Risk of disk full
- **Response:** Clean up logs/backups
- **Command:**
  ```bash
  df -h /opt/spacetime
  du -h /opt/spacetime/logs | sort -rh | head -10
  ```
- **Escalate:** If disk > 95%

---

## Alert Response Matrix

| Alert | P0 | P1 | P2 | P3 | Action |
|-------|----|----|----|----|--------|
| API Down | ✓ | | | | Restart service |
| Error Rate > 5% | ✓ | | | | Check logs |
| Error Rate 1-5% | | ✓ | | | Investigate |
| Response Time > 1s | | ✓ | | | Profile perf |
| Response Time > 500ms | | | ✓ | | Monitor |
| Memory > 95% | ✓ | | | | Restart |
| Memory 80-95% | | ✓ | | | Check leak |
| Disk > 95% | ✓ | | | | Cleanup |
| Disk 85-95% | | ✓ | | | Plan cleanup |
| Auth Failures | | ✓ | | | Check attack |
| Certificate Expiry < 7d | | ✓ | | | Renew cert |
| Backup Failed | | | ✓ | | Re-run backup |
| FPS < 85 | | | ✓ | | Check CPU |

---

## Alert Response Procedures

### Step 1: Acknowledge (< 5 min)
```bash
# In PagerDuty app or:
pd incident ack <incident-id>
```

### Step 2: Verify (< 2 min)
```bash
# Quick health check
curl -s http://localhost:8080/status | jq .overall_ready
```

### Step 3: Create Incident Channel (if P0/P1)
```bash
# In Slack:
/incident create "Alert: API_DOWN - investigating"
```

### Step 4: Investigate
```bash
# Follow runbook for alert type
# See RUNBOOK_INCIDENTS.md
```

### Step 5: Resolve
```bash
# Apply fix
# Verify resolution
# Monitor for 15 minutes
```

### Step 6: Document
```bash
# Update incident channel
# Resolve PagerDuty incident
# Create post-mortem (if needed)
```

---

## Common Alert Patterns

### Pattern: Spike then Recovery
**Cause:** Temporary load spike or transient issue
**Action:** Monitor, no action if recovered
**Example:** Brief traffic surge

### Pattern: Gradual Increase
**Cause:** Memory leak, disk filling, traffic growth
**Action:** Investigate root cause, plan fix
**Example:** Memory usage climbing over hours

### Pattern: Intermittent
**Cause:** Network issues, dependency failures
**Action:** Check dependencies and network
**Example:** Periodic connection timeouts

### Pattern: Sudden Jump
**Cause:** Deployment, configuration change, code bug
**Action:** Review recent changes, consider rollback
**Example:** Error rate jumps after deployment

---

## Alert Channels

### PagerDuty
- **URL:** https://company.pagerduty.com
- **Service:** spacetime-api
- **Escalation:** Auto-escalates per policy

### Slack
- **Alerts:** #spacetime-alerts
- **Incidents:** #incident-YYYY-MM-DD-XXX
- **On-Call:** #on-call-handoff

### Email
- **Critical:** oncall@company.com
- **High:** spacetime-team@company.com
- **Alerts:** spacetime-alerts@company.com

### SMS
- **Configured in PagerDuty**
- **Only for P0/P1 alerts**

---

## Alert Configuration

### Prometheus Alert Rules
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
```

### Alertmanager Config
```yaml
# /etc/alertmanager/config.yml
route:
  receiver: 'pagerduty'
  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
```

---

## Silencing Alerts

### Temporary Silence (Maintenance)
```bash
# Create silence in Alertmanager
amtool silence add \
  alertname=APIDown \
  --duration=2h \
  --comment="Planned maintenance"

# Or in Prometheus UI
# → Alerts → Silence → Create
```

### Permanent Alert Adjustment
```yaml
# Edit alert threshold
# /etc/prometheus/rules/spacetime-alerts.yml
- alert: HighMemoryUsage
  expr: memory_usage > 0.95  # Changed from 0.90
```

---

## False Positive Handling

### Identifying False Positives
1. Alert triggered but service actually healthy
2. Alert immediately resolves
3. No actual impact to users
4. Metrics show normal behavior

### Handling Procedure
```bash
# 1. Verify false positive
curl http://localhost:8080/status

# 2. Resolve with note
pd incident resolve <id> --note "False alarm - verified service healthy"

# 3. Create ticket to adjust alert
# "Alert APIDown triggering false positives"

# 4. Adjust threshold or condition
# Edit Prometheus alert rule
```

---

## Alert Metrics

### Track These Metrics
- **MTTA (Mean Time To Acknowledge):** Target < 5 min
- **MTTR (Mean Time To Resolve):** Target < 30 min (P0), < 1 hour (P1)
- **False Positive Rate:** Target < 5%
- **Alert Frequency:** Monitor trends

### Review Alerts
```bash
# Weekly alert summary
# How many alerts this week?
# What were the top alerts?
# Any trends?
# False positive rate?
```

---

## On-Call Quick Reference

### When You Get Paged

**1. Acknowledge (< 5 min)**
- Open PagerDuty app
- Acknowledge incident
- Note time acknowledged

**2. Assess Severity**
- Read alert description
- Check monitoring dashboards
- Determine P0/P1/P2

**3. Create War Room (if P0/P1)**
- Slack: `/incident create`
- Post initial status
- @ mention team if needed

**4. Investigate**
- Follow runbook for alert type
- Collect logs and metrics
- Form hypothesis

**5. Resolve**
- Apply fix
- Verify resolution
- Monitor stability

**6. Document**
- Update incident notes
- Resolve PagerDuty
- Create post-mortem (if P0/P1)

---

## Alert Quick Commands

```bash
# Check all alert status
curl -s http://prometheus:9090/api/v1/alerts | jq .

# View active alerts
curl -s http://alertmanager:9093/api/v2/alerts | jq '.[] | select(.status.state == "active")'

# Silence alert
amtool silence add alertname=TestAlert --duration=1h

# View silences
amtool silence query

# Delete silence
amtool silence expire <silence-id>

# Test alert
curl -X POST http://alertmanager:9093/api/v1/alerts -d '[{
  "labels": {"alertname": "TestAlert", "severity": "warning"},
  "annotations": {"summary": "Test alert"}
}]'
```

---

## Escalation Quick Reference

### Escalation Times
- **P0:** Escalate after 15 minutes if unresolved
- **P1:** Escalate after 30 minutes if unresolved
- **P2:** Escalate after 4 hours if unresolved

### Escalation Path
```
You (On-Call Engineer)
    ↓ 15 min (P0) / 30 min (P1)
Senior Engineer
    ↓ 30 min
Engineering Lead
    ↓ 1 hour
Engineering Manager
    ↓ 2 hours
Director of Engineering
```

### Escalation Contacts
```bash
# Check current on-call
pd schedule show --schedule-id PXXXXXX

# Page senior engineer
pd incident create --title "Escalation needed" \
  --service spacetime-api-escalation

# Emergency contact list
# Stored in 1Password: "SpaceTime Emergency Contacts"
```

---

## Alert Dashboard

### Grafana Alert Dashboard
**URL:** https://grafana.company.com/d/alerts-overview

**Panels:**
- Active Alerts Count
- Alert History (24h)
- MTTA Trend
- MTTR Trend
- False Positive Rate
- Alert Frequency by Type

### PagerDuty Dashboard
**URL:** https://company.pagerduty.com/incidents

**Filters:**
- Triggered
- Acknowledged
- Resolved
- By Service: spacetime-api

---

## Quick Reference Card

```
╔═══════════════════════════════════════════════════════════╗
║            ALERT QUICK REFERENCE                          ║
╠═══════════════════════════════════════════════════════════╣
║ SEVERITY LEVELS:                                          ║
║   P0: Service Down      → Respond < 5 min                 ║
║   P1: Major Issue       → Respond < 15 min                ║
║   P2: Minor Issue       → Respond < 1 hour                ║
║                                                           ║
║ RESPONSE:                                                 ║
║   1. Acknowledge in PagerDuty                             ║
║   2. Verify: curl localhost:8080/status                   ║
║   3. Create incident channel (P0/P1)                      ║
║   4. Follow runbook                                       ║
║   5. Resolve and document                                 ║
║                                                           ║
║ ESCALATE:                                                 ║
║   P0: After 15 min unresolved                             ║
║   P1: After 30 min unresolved                             ║
║                                                           ║
║ CONTACTS:                                                 ║
║   PagerDuty: company.pagerduty.com                        ║
║   Slack: #spacetime-incidents                             ║
╚═══════════════════════════════════════════════════════════╝
```
