# Operations Runbook

**Version:** 2.5.0
**Last Updated:** 2025-12-02
**Maintained By:** DevOps Team
**Review Cycle:** Monthly

## Table of Contents

1. [Overview](#overview)
2. [Daily Operations](#daily-operations)
3. [Weekly Operations](#weekly-operations)
4. [Monthly Operations](#monthly-operations)
5. [Quarterly Operations](#quarterly-operations)
6. [On-Call Procedures](#on-call-procedures)
7. [Capacity Planning](#capacity-planning)

---

## Overview

### Purpose
This runbook provides standard operating procedures for maintaining the SpaceTime HTTP Scene Management API in production environments.

### Service Level Objectives (SLOs)

**Availability:** 99.9% uptime (43.8 minutes downtime/month allowed)
**Performance:**
- 95th percentile response time < 200ms
- 99th percentile response time < 500ms
**Error Rate:** < 0.5% of all requests
**Recovery Time Objective (RTO):** 15 minutes
**Recovery Point Objective (RPO):** 1 hour

### Key Metrics to Monitor

1. **Availability Metrics**
   - Service uptime percentage
   - Health check success rate
   - Load balancer target health

2. **Performance Metrics**
   - Average response time
   - 95th/99th percentile response time
   - Requests per second (RPS)
   - Frame rate (FPS) - should maintain 90 FPS

3. **Error Metrics**
   - HTTP 4xx error rate
   - HTTP 5xx error rate
   - Connection failures
   - Timeout rate

4. **Resource Metrics**
   - CPU utilization
   - Memory utilization
   - Disk space usage
   - Network bandwidth

---

## Daily Operations

### Morning Health Check (9:00 AM UTC)

**Duration:** 15 minutes

#### Step 1: Review Overnight Alerts

```bash
# Check PagerDuty for triggered alerts
# Log in to: https://company.pagerduty.com

# Review alert summary
curl -X GET "https://api.pagerduty.com/incidents" \
  -H "Authorization: Token token=$PAGERDUTY_TOKEN" \
  -H "Accept: application/json" \
  -d "since=$(date -u -d '24 hours ago' '+%Y-%m-%dT%H:%M:%SZ')" | jq '.incidents | length'

# Expected output: 0 incidents (or < 3 minor incidents)
```

**Review Checklist:**
- [ ] Number of alerts: ____
- [ ] Critical alerts (P0/P1): ____ (should be 0)
- [ ] All alerts acknowledged: Yes/No
- [ ] Any alerts require follow-up: Yes/No

**Action Items:**
- If critical alerts exist, follow incident response procedures
- Create tickets for recurring alerts
- Document any workarounds applied

---

#### Step 2: Service Health Check

```bash
# Check production service status
curl -s https://spacetime-api.company.com/status | jq '{
  overall_ready: .overall_ready,
  dap_state: .debug_adapter.state,
  lsp_state: .language_server.state
}'

# Expected output:
# {
#   "overall_ready": true,
#   "dap_state": 2,
#   "lsp_state": 2
# }

# Check uptime
uptime -p

# Expected output: up 10 days, 5 hours, 23 minutes (varies)

# Check service status on all hosts
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host ==="
  ssh $host "systemctl status godot-spacetime | grep Active"
done

# Expected output: active (running) for all hosts
```

**Health Check Results:**
- [ ] API overall_ready: true
- [ ] DAP state: 2 (connected)
- [ ] LSP state: 2 (connected)
- [ ] All hosts active: Yes/No
- [ ] Uptime >= 24 hours: Yes/No

**Troubleshooting:**
- If overall_ready is false, check logs: `ssh prod-api-01 "sudo journalctl -u godot-spacetime -n 50"`
- If state is not 2, connection issue exists - verify DAP/LSP ports
- If uptime < 24 hours, investigate recent restarts

---

#### Step 3: Performance Review

```bash
# Check response times (last 24 hours)
# Query from Prometheus/Grafana API
curl -s "https://prometheus.company.com/api/v1/query?query=histogram_quantile(0.95,%20rate(http_request_duration_seconds_bucket[24h]))" | jq '.data.result[0].value[1]'

# Expected output: < 0.2 (200ms)

# Check error rate (last 24 hours)
curl -s "https://prometheus.company.com/api/v1/query?query=rate(http_requests_total{status=~'5..'}[24h])/rate(http_requests_total[24h])" | jq '.data.result[0].value[1]'

# Expected output: < 0.005 (0.5%)

# View traffic summary
echo "24-hour traffic summary:"
curl -s "https://prometheus.company.com/api/v1/query?query=sum(increase(http_requests_total[24h]))" | jq '.data.result[0].value[1]'

# Expected output: Varies based on load (e.g., 500000 requests/day)
```

**Performance Metrics:**
- [ ] 95th percentile < 200ms: Yes/No - Actual: ____ms
- [ ] Error rate < 0.5%: Yes/No - Actual: ____%
- [ ] Total requests 24h: ________
- [ ] Average requests/sec: ________

**Action Items:**
- If performance degraded, check resource usage
- If error rate elevated, review error logs
- Document any anomalies for weekly review

---

#### Step 4: Resource Utilization Check

```bash
# Check CPU and memory across all hosts
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host ==="
  ssh $host "top -bn1 | grep 'Cpu\\|Mem' | head -2"
done

# Expected output per host:
# %Cpu(s): 15.2 us, 2.3 sy, 0.0 ni, 80.5 id, ... (idle > 50%)
# MiB Mem : 32768.0 total, 12543.2 free, ... (< 70% used)

# Check disk space
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host ==="
  ssh $host "df -h /opt/spacetime | tail -1"
done

# Expected output: < 80% used
# /dev/sda1       100G   45G   55G   45% /opt/spacetime
```

**Resource Check:**
- [ ] CPU usage < 70%: Yes/No
- [ ] Memory usage < 80%: Yes/No
- [ ] Disk usage < 80%: Yes/No
- [ ] Any hosts showing high utilization: ________

**Action Items:**
- If CPU > 70%, investigate high load processes
- If memory > 80%, check for memory leaks
- If disk > 80%, plan cleanup or expansion

---

#### Step 5: Log Review

```bash
# Count errors in last 24 hours
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host errors ==="
  ssh $host "sudo journalctl -u godot-spacetime --since '24 hours ago' | grep -c ERROR"
done

# Expected output: < 100 errors per host per day

# Review unique error messages
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '24 hours ago' | grep ERROR | awk '{for(i=5;i<=NF;i++) printf \"%s \", \$i; print \"\"}' | sort | uniq -c | sort -rn | head -10"

# Output shows top 10 error types and counts
# Example:
#   45 Connection timeout to DAP server
#   12 Scene load failed: file not found
#    8 Memory allocation failed

# Check for critical patterns
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '24 hours ago' | grep -E 'CRITICAL|FATAL|segfault|OOM'"

# Expected output: No critical errors (empty)
```

**Log Analysis:**
- [ ] Total errors < 100 per host: Yes/No
- [ ] No critical errors: Yes/No
- [ ] Recurring error patterns: ________
- [ ] Errors requiring tickets: ________

**Action Items:**
- Create tickets for recurring errors
- Escalate critical errors immediately
- Update error monitoring rules if needed

---

### Midday Check (1:00 PM UTC)

**Duration:** 5 minutes

Quick health check during peak traffic hours.

```bash
# Quick status check
curl -s https://spacetime-api.company.com/status | jq .overall_ready

# Expected output: true

# Check current load
curl -s "https://prometheus.company.com/api/v1/query?query=rate(http_requests_total[5m])" | jq '.data.result[0].value[1]'

# Expected output: Current RPS (varies by time of day)

# Check for active incidents
curl -X GET "https://api.pagerduty.com/incidents?statuses[]=triggered&statuses[]=acknowledged" \
  -H "Authorization: Token token=$PAGERDUTY_TOKEN" | jq '.incidents | length'

# Expected output: 0
```

**Midday Status:**
- [ ] Service healthy: Yes/No
- [ ] Current load normal: Yes/No
- [ ] Active incidents: ____
- [ ] Any concerns: ________

---

### End of Day Summary (5:00 PM UTC)

**Duration:** 10 minutes

Summarize the day's operations and prepare for overnight monitoring.

```bash
# Generate daily report
cat << 'EOF' > /tmp/daily_report.sh
#!/bin/bash
echo "=== SpaceTime API Daily Report ==="
echo "Date: $(date '+%Y-%m-%d')"
echo ""
echo "Service Status:"
curl -s https://spacetime-api.company.com/status | jq '{overall_ready, debug_adapter: .debug_adapter.state, language_server: .language_server.state}'
echo ""
echo "24-Hour Summary:"
echo "Total Requests: $(curl -s 'https://prometheus.company.com/api/v1/query?query=sum(increase(http_requests_total[24h]))' | jq -r '.data.result[0].value[1]')"
echo "Error Rate: $(curl -s 'https://prometheus.company.com/api/v1/query?query=rate(http_requests_total{status=~\"5..\"}[24h])/rate(http_requests_total[24h])' | jq -r '.data.result[0].value[1]')%"
echo "95th Percentile Response Time: $(curl -s 'https://prometheus.company.com/api/v1/query?query=histogram_quantile(0.95,rate(http_request_duration_seconds_bucket[24h]))' | jq -r '.data.result[0].value[1]')s"
echo ""
echo "Incidents: $(curl -s -X GET 'https://api.pagerduty.com/incidents?since=$(date -u -d \"24 hours ago\" \"+%Y-%m-%dT%H:%M:%SZ\")' -H \"Authorization: Token token=$PAGERDUTY_TOKEN\" | jq '.incidents | length')"
EOF

chmod +x /tmp/daily_report.sh
/tmp/daily_report.sh
```

**Daily Summary Template:**
```
=== SpaceTime API Daily Report ===
Date: 2025-12-02

Service Status: ✓ Healthy / ✗ Issues
Total Requests: ________
Error Rate: ________%
95th Percentile: ________ms
Incidents: ____

Notable Events:
- [ List any significant events, maintenance, or issues ]

Action Items:
- [ List follow-up items for tomorrow ]

On-Call Notes:
- [ Any information for overnight on-call engineer ]
```

**Post to Slack:** Share summary in #spacetime-operations channel

---

## Weekly Operations

### Monday Morning Review (9:00 AM UTC)

**Duration:** 30 minutes

#### Step 1: Weekly Metrics Review

```bash
# Generate weekly report
cat << 'EOF' > /tmp/weekly_report.sh
#!/bin/bash
WEEK_START=$(date -u -d '7 days ago' '+%Y-%m-%dT%H:%M:%SZ')

echo "=== SpaceTime API Weekly Report ==="
echo "Week: $(date -d '7 days ago' '+%Y-%m-%d') to $(date '+%Y-%m-%d')"
echo ""

# Availability
UPTIME=$(curl -s "https://prometheus.company.com/api/v1/query?query=avg_over_time(up[7d])" | jq -r '.data.result[0].value[1]')
echo "Uptime: $(echo "$UPTIME * 100" | bc)%"

# Total requests
TOTAL_REQUESTS=$(curl -s "https://prometheus.company.com/api/v1/query?query=sum(increase(http_requests_total[7d]))" | jq -r '.data.result[0].value[1]')
echo "Total Requests: $TOTAL_REQUESTS"

# Error rate
ERROR_RATE=$(curl -s "https://prometheus.company.com/api/v1/query?query=rate(http_requests_total{status=~'5..'}[7d])/rate(http_requests_total[7d])" | jq -r '.data.result[0].value[1]')
echo "Error Rate: $(echo "$ERROR_RATE * 100" | bc)%"

# Performance
P95=$(curl -s "https://prometheus.company.com/api/v1/query?query=histogram_quantile(0.95,rate(http_request_duration_seconds_bucket[7d]))" | jq -r '.data.result[0].value[1]')
echo "95th Percentile Response Time: ${P95}ms"

# Incidents
INCIDENTS=$(curl -s -X GET "https://api.pagerduty.com/incidents?since=$WEEK_START" -H "Authorization: Token token=$PAGERDUTY_TOKEN" | jq '.incidents | length')
echo "Incidents: $INCIDENTS"

EOF

chmod +x /tmp/weekly_report.sh
/tmp/weekly_report.sh
```

**Weekly Metrics:**
- [ ] Uptime >= 99.9%: Yes/No - Actual: ____%
- [ ] Total requests: ________
- [ ] Error rate < 0.5%: Yes/No - Actual: ____%
- [ ] P95 response time < 200ms: Yes/No - Actual: ____ms
- [ ] Incidents: ____ (target: < 5)

---

#### Step 2: Capacity Planning Review

```bash
# Trend analysis - resource usage growth
for metric in cpu memory disk; do
  echo "=== $metric usage trend ==="
  curl -s "https://prometheus.company.com/api/v1/query?query=avg_over_time(${metric}_usage_percent[7d])" | jq -r '.data.result[] | "\(.metric.instance): \(.value[1])%"'
done

# Traffic growth analysis
echo "=== Traffic trend ==="
curl -s "https://prometheus.company.com/api/v1/query_range?query=rate(http_requests_total[1h])&start=$(date -u -d '7 days ago' +%s)&end=$(date +%s)&step=3600" | jq -r '.data.result[0].values[] | "\(.[0]): \(.[1]) req/s"' | tail -5

# Peak traffic identification
echo "=== Peak traffic times ==="
curl -s "https://prometheus.company.com/api/v1/query?query=max_over_time(rate(http_requests_total[5m])[7d])" | jq -r '.data.result[0].value[1]'
```

**Capacity Analysis:**
- [ ] CPU usage trend: Increasing/Stable/Decreasing
- [ ] Memory usage trend: Increasing/Stable/Decreasing
- [ ] Traffic growth rate: ____%
- [ ] Peak traffic time: ________
- [ ] Capacity concern: Yes/No

**Action Items:**
- If growth > 10% per week, plan for scaling
- If peak traffic causes issues, consider load balancing
- Update capacity forecast spreadsheet

---

#### Step 3: Security Patch Review

```bash
# Check for system updates
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host security updates ==="
  ssh $host "apt list --upgradable 2>/dev/null | grep -i security | wc -l"
done

# Expected output: Number of security updates available

# Check Godot version
ssh prod-api-01 "godot --version"

# Check for Godot security advisories
# Visit: https://github.com/godotengine/godot/security/advisories

# Check dependency vulnerabilities
ssh prod-api-01 "cd /opt/spacetime/production && pip3 list --format=json | jq -r '.[] | \"\(.name)==\(.version)\"' | safety check --stdin"
```

**Security Review:**
- [ ] System security updates: ____ available
- [ ] Godot version current: Yes/No - Version: ________
- [ ] Security advisories: ____ unresolved
- [ ] Dependency vulnerabilities: ____ found
- [ ] Patches to schedule: ________

**Action Items:**
- Schedule maintenance window for critical patches
- Create tickets for non-critical updates
- Review and apply security advisories

---

#### Step 4: Performance Trending

```bash
# Generate performance trend graphs
# Use Grafana snapshots or API

# Response time trend
curl -s "https://grafana.company.com/api/snapshots" -X POST \
  -H "Content-Type: application/json" \
  -d "{
    \"dashboard\": {
      \"panels\": [{
        \"targets\": [{
          \"expr\": \"histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[7d]))\"
        }]
      }]
    },
    \"expires\": 3600
  }" | jq -r '.url'

# Output: URL to response time trend graph

# Error rate trend
# Similar query for error rates

# Compare to previous weeks
echo "=== Week over week comparison ==="
CURRENT_P95=$(curl -s "https://prometheus.company.com/api/v1/query?query=histogram_quantile(0.95,rate(http_request_duration_seconds_bucket[7d]))" | jq -r '.data.result[0].value[1]')
PREVIOUS_P95=$(curl -s "https://prometheus.company.com/api/v1/query?query=histogram_quantile(0.95,rate(http_request_duration_seconds_bucket[7d] offset 7d))" | jq -r '.data.result[0].value[1]')
echo "P95 Response Time:"
echo "  Current week: ${CURRENT_P95}ms"
echo "  Previous week: ${PREVIOUS_P95}ms"
echo "  Change: $(echo "scale=2; ($CURRENT_P95 - $PREVIOUS_P95) / $PREVIOUS_P95 * 100" | bc)%"
```

**Performance Trends:**
- [ ] Response time trend: Improving/Stable/Degrading
- [ ] Error rate trend: Improving/Stable/Degrading
- [ ] Week-over-week change: ____%
- [ ] Performance concerns: ________

---

### Wednesday - Mid-Week Check

**Duration:** 15 minutes

Quick health verification and progress check on weekly action items.

```bash
# Verify weekly action items progress
# Review tickets created from Monday review
# Check if any patches scheduled for week are ready

# Quick capacity check
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host ==="
  ssh $host "df -h /opt/spacetime | tail -1 && free -h | grep Mem && uptime"
done

# Review incident count mid-week
curl -s -X GET "https://api.pagerduty.com/incidents?since=$(date -u -d '3 days ago' '+%Y-%m-%dT%H:%M:%SZ')" \
  -H "Authorization: Token token=$PAGERDUTY_TOKEN" | jq '.incidents | length'

# Expected: < 3 incidents
```

**Mid-Week Status:**
- [ ] Weekly action items on track: Yes/No
- [ ] Disk space adequate: Yes/No
- [ ] Incident count acceptable: Yes/No
- [ ] Any mid-week concerns: ________

---

### Friday - Weekly Wrap-Up

**Duration:** 20 minutes

Complete weekly operations and prepare for weekend monitoring.

```bash
# Generate comprehensive weekly report
/tmp/weekly_report.sh > /tmp/weekly_summary_$(date +%Y%m%d).txt

# Review all action items
echo "=== Action Items Review ==="
echo "Completed this week:"
# List completed tasks

echo "Carried over to next week:"
# List pending tasks

# Update capacity planning spreadsheet
# Document any significant events

# Verify backup retention
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host backups ==="
  ssh $host "ls -lt /opt/spacetime/backups/ | head -10"
done

# Expected: Daily backups for last 7 days, weekly backups for last 4 weeks
```

**Weekly Summary Template:**
```
=== SpaceTime API Weekly Summary ===
Week of: 2025-12-02

SLO Compliance:
- Uptime: ____% (Target: 99.9%)
- Error Rate: ____% (Target: < 0.5%)
- P95 Response Time: ____ms (Target: < 200ms)

Key Metrics:
- Total Requests: ________
- Peak RPS: ________
- Incidents: ____

Completed:
- [ List completed work ]

In Progress:
- [ List ongoing work ]

Next Week:
- [ List planned work ]

Weekend On-Call Notes:
- [ Information for weekend on-call ]
```

**Post Summary:** Share in #spacetime-operations and email to team

---

## Monthly Operations

### First Monday of Month - Monthly Review

**Duration:** 2 hours

#### Step 1: Service Level Review

```bash
# Generate monthly SLO report
cat << 'EOF' > /tmp/monthly_report.sh
#!/bin/bash
MONTH_START=$(date -u -d '30 days ago' '+%Y-%m-%dT%H:%M:%SZ')

echo "=== SpaceTime API Monthly Report ==="
echo "Month: $(date -d '30 days ago' '+%B %Y')"
echo ""

# Availability
UPTIME=$(curl -s "https://prometheus.company.com/api/v1/query?query=avg_over_time(up[30d])" | jq -r '.data.result[0].value[1]')
UPTIME_PERCENT=$(echo "$UPTIME * 100" | bc)
echo "Uptime: ${UPTIME_PERCENT}%"
echo "Downtime: $(echo "(1 - $UPTIME) * 30 * 24 * 60" | bc) minutes"
echo "SLO (99.9%): $([ $(echo "$UPTIME_PERCENT >= 99.9" | bc) -eq 1 ] && echo "✓ MET" || echo "✗ MISSED")"
echo ""

# Performance
P95=$(curl -s "https://prometheus.company.com/api/v1/query?query=histogram_quantile(0.95,rate(http_request_duration_seconds_bucket[30d]))" | jq -r '.data.result[0].value[1]')
P95_MS=$(echo "$P95 * 1000" | bc)
echo "P95 Response Time: ${P95_MS}ms"
echo "SLO (< 200ms): $([ $(echo "$P95_MS < 200" | bc) -eq 1 ] && echo "✓ MET" || echo "✗ MISSED")"
echo ""

# Error Rate
ERROR_RATE=$(curl -s "https://prometheus.company.com/api/v1/query?query=rate(http_requests_total{status=~'5..'}[30d])/rate(http_requests_total[30d])" | jq -r '.data.result[0].value[1]')
ERROR_PERCENT=$(echo "$ERROR_RATE * 100" | bc)
echo "Error Rate: ${ERROR_PERCENT}%"
echo "SLO (< 0.5%): $([ $(echo "$ERROR_PERCENT < 0.5" | bc) -eq 1 ] && echo "✓ MET" || echo "✗ MISSED")"
echo ""

# Volume
TOTAL_REQUESTS=$(curl -s "https://prometheus.company.com/api/v1/query?query=sum(increase(http_requests_total[30d]))" | jq -r '.data.result[0].value[1]')
echo "Total Requests: $TOTAL_REQUESTS"
echo "Average Daily: $(echo "$TOTAL_REQUESTS / 30" | bc)"
echo ""

# Incidents
INCIDENTS=$(curl -s -X GET "https://api.pagerduty.com/incidents?since=$MONTH_START" -H "Authorization: Token token=$PAGERDUTY_TOKEN" | jq '.incidents | length')
echo "Total Incidents: $INCIDENTS"
echo "Critical (P0/P1): $(curl -s -X GET "https://api.pagerduty.com/incidents?since=$MONTH_START&urgency=high" -H "Authorization: Token token=$PAGERDUTY_TOKEN" | jq '.incidents | length')"

EOF

chmod +x /tmp/monthly_report.sh
/tmp/monthly_report.sh
```

**Monthly SLO Status:**
- [ ] Uptime SLO met: Yes/No - Actual: ____%
- [ ] Performance SLO met: Yes/No - Actual: ____ms
- [ ] Error rate SLO met: Yes/No - Actual: ____%
- [ ] Total incidents: ____
- [ ] Critical incidents: ____

**Analysis:**
- If SLO missed, document reasons and corrective actions
- Identify trends requiring attention
- Update SLO targets if consistently exceeded or missed

---

#### Step 2: Capacity Planning

```bash
# Resource growth analysis
echo "=== 30-Day Resource Growth ==="

# CPU trend
CPU_NOW=$(curl -s "https://prometheus.company.com/api/v1/query?query=avg(cpu_usage_percent)" | jq -r '.data.result[0].value[1]')
CPU_30D=$(curl -s "https://prometheus.company.com/api/v1/query?query=avg(cpu_usage_percent offset 30d)" | jq -r '.data.result[0].value[1]')
echo "CPU Usage: ${CPU_30D}% -> ${CPU_NOW}% (Change: $(echo "$CPU_NOW - $CPU_30D" | bc)%)"

# Memory trend
MEM_NOW=$(curl -s "https://prometheus.company.com/api/v1/query?query=avg(memory_usage_percent)" | jq -r '.data.result[0].value[1]')
MEM_30D=$(curl -s "https://prometheus.company.com/api/v1/query?query=avg(memory_usage_percent offset 30d)" | jq -r '.data.result[0].value[1]')
echo "Memory Usage: ${MEM_30D}% -> ${MEM_NOW}% (Change: $(echo "$MEM_NOW - $MEM_30D" | bc)%)"

# Disk trend
DISK_NOW=$(curl -s "https://prometheus.company.com/api/v1/query?query=avg(disk_usage_percent)" | jq -r '.data.result[0].value[1]')
DISK_30D=$(curl -s "https://prometheus.company.com/api/v1/query?query=avg(disk_usage_percent offset 30d)" | jq -r '.data.result[0].value[1]')
echo "Disk Usage: ${DISK_30D}% -> ${DISK_NOW}% (Change: $(echo "$DISK_NOW - $DISK_30D" | bc)%)"

# Traffic trend
TRAFFIC_NOW=$(curl -s "https://prometheus.company.com/api/v1/query?query=avg_over_time(rate(http_requests_total[7d])[30d:])" | jq -r '.data.result[0].value[1]')
TRAFFIC_30D=$(curl -s "https://prometheus.company.com/api/v1/query?query=avg_over_time(rate(http_requests_total[7d])[30d:] offset 30d)" | jq -r '.data.result[0].value[1]')
GROWTH=$(echo "scale=2; ($TRAFFIC_NOW - $TRAFFIC_30D) / $TRAFFIC_30D * 100" | bc)
echo "Traffic: ${TRAFFIC_30D} req/s -> ${TRAFFIC_NOW} req/s (Growth: ${GROWTH}%)"

# Forecast next 3 months
echo ""
echo "=== 3-Month Forecast ==="
for resource in cpu memory disk traffic; do
  GROWTH_RATE=$(echo "scale=4; ($NOW - $BEFORE) / $BEFORE" | bc)
  MONTH_1=$(echo "scale=2; $NOW * (1 + $GROWTH_RATE)" | bc)
  MONTH_2=$(echo "scale=2; $MONTH_1 * (1 + $GROWTH_RATE)" | bc)
  MONTH_3=$(echo "scale=2; $MONTH_2 * (1 + $GROWTH_RATE)" | bc)
  echo "$resource: Month +1: $MONTH_1%, Month +2: $MONTH_2%, Month +3: $MONTH_3%"
done
```

**Capacity Forecast:**
- [ ] CPU forecast (3 months): ____%
- [ ] Memory forecast (3 months): ____%
- [ ] Disk forecast (3 months): ____%
- [ ] Traffic growth rate: ____%
- [ ] Scaling needed: Yes/No - When: ________

**Action Items:**
- If any resource forecast > 80%, plan scaling
- Update capacity planning spreadsheet
- Create tickets for infrastructure changes

---

#### Step 3: Security Review

```bash
# Security audit
echo "=== Monthly Security Review ==="

# Certificate expiry check
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host certificate ==="
  ssh $host "openssl x509 -in /etc/ssl/certs/spacetime-api.crt -noout -dates"
done

# Expected: Certificates valid for > 30 days

# Access log review
echo "=== Access Patterns ==="
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '30 days ago' | grep -E 'authentication|authorization' | wc -l"

# Failed authentication attempts
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '30 days ago' | grep -i 'authentication failed' | wc -l"

# Expected: < 100 failed attempts (may indicate brute force)

# Vulnerability scan
echo "=== Vulnerability Scan ==="
ssh prod-api-01 "cd /opt/spacetime/production && safety check --json" | jq '.vulnerabilities | length'

# Expected: 0 vulnerabilities

# Review API token usage
echo "=== API Token Review ==="
# Query token usage from authentication logs
ssh prod-api-01 "sudo journalctl -u godot-spacetime --since '30 days ago' | grep 'API token' | awk '{print \$NF}' | sort | uniq -c | sort -rn | head -10"

# Identify unused tokens for rotation
```

**Security Status:**
- [ ] Certificates expiring < 30 days: ____ (should be 0)
- [ ] Failed auth attempts: ____ (< 100)
- [ ] Vulnerabilities found: ____ (should be 0)
- [ ] Unused tokens identified: ____
- [ ] Security incidents: ____

**Action Items:**
- Renew certificates expiring soon
- Rotate API tokens (monthly rotation policy)
- Patch vulnerabilities
- Investigate suspicious access patterns

---

#### Step 4: Backup and DR Verification

```bash
# Verify backup retention
echo "=== Backup Verification ==="
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host backups ==="
  ssh $host "ls -lh /opt/spacetime/backups/*.tar.gz | wc -l"
  ssh $host "du -sh /opt/spacetime/backups/"
done

# Expected:
# - 7 daily backups
# - 4 weekly backups
# - 3 monthly backups

# Test backup restoration
echo "=== Backup Restoration Test ==="
ssh prod-api-01 "cd /tmp && tar -tzf /opt/spacetime/backups/production_$(date +%Y%m%d)*.tar.gz | head -10"

# Expected: File list from backup (verifies backup integrity)

# DR drill (if scheduled for this month)
# Follow DR runbook for quarterly drill
```

**Backup Status:**
- [ ] Daily backups: ____ (expected: 7)
- [ ] Weekly backups: ____ (expected: 4)
- [ ] Monthly backups: ____ (expected: 3)
- [ ] Backup integrity verified: Yes/No
- [ ] Backup size reasonable: Yes/No
- [ ] DR drill completed: Yes/No (if scheduled)

**Action Items:**
- Adjust retention policy if needed
- Investigate missing backups
- Update DR documentation based on drill results

---

#### Step 5: Dependency Updates

```bash
# Check for dependency updates
echo "=== Dependency Updates ==="

# Godot version
CURRENT_VERSION=$(ssh prod-api-01 "godot --version" | awk '{print $1}')
LATEST_VERSION=$(curl -s https://api.github.com/repos/godotengine/godot/releases/latest | jq -r '.tag_name')
echo "Godot: Current=$CURRENT_VERSION, Latest=$LATEST_VERSION"

# Python dependencies
ssh prod-api-01 "cd /opt/spacetime/production && pip3 list --outdated --format=json" | jq -r '.[] | "\(.name): \(.version) -> \(.latest_version)"'

# System packages
for host in prod-api-01 prod-api-02 prod-api-03; do
  echo "=== $host updates ==="
  ssh $host "apt list --upgradable 2>/dev/null | wc -l"
done
```

**Update Status:**
- [ ] Godot updates available: Yes/No - Version: ________
- [ ] Python packages outdated: ____ packages
- [ ] System packages: ____ updates available
- [ ] Critical updates: ____ (must apply)

**Action Items:**
- Schedule maintenance window for updates
- Test updates in staging first
- Create rollback plan before applying

---

### Certificate Renewal (Monthly Check)

**Duration:** 15 minutes

```bash
# Check all certificates
echo "=== Certificate Expiry Check ==="

for cert in api telemetry monitoring; do
  echo "=== $cert certificate ==="
  EXPIRY=$(openssl s_client -connect ${cert}.company.com:443 -servername ${cert}.company.com </dev/null 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
  EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
  NOW_EPOCH=$(date +%s)
  DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
  echo "Expires: $EXPIRY ($DAYS_LEFT days)"

  if [ $DAYS_LEFT -lt 30 ]; then
    echo "⚠️  WARNING: Certificate expires in $DAYS_LEFT days"
  fi
done

# Auto-renewal status (if using Let's Encrypt)
systemctl status certbot.timer

# Expected: active (running)
```

**Certificate Status:**
- [ ] API certificate: ____ days remaining
- [ ] Telemetry certificate: ____ days remaining
- [ ] Monitoring certificate: ____ days remaining
- [ ] Auto-renewal enabled: Yes/No
- [ ] Renewal needed: Yes/No

**Action Items:**
- If < 30 days, schedule renewal
- Verify auto-renewal working
- Test renewed certificates in staging

---

## Quarterly Operations

### First Week of Quarter - Quarterly Review

**Duration:** 4 hours

#### Step 1: Comprehensive Service Review

Generate and analyze quarterly metrics:
- SLO compliance over 3 months
- Cost analysis and optimization
- Architecture review
- Performance optimization opportunities

#### Step 2: Disaster Recovery Drill

Execute full DR drill following RUNBOOK_BACKUP.md:
- Simulate complete system failure
- Execute recovery procedures
- Measure RTO/RPO compliance
- Document lessons learned

#### Step 3: Security Audit

Comprehensive security review:
- External security scan
- Penetration testing (if scheduled)
- Access control audit
- Compliance verification

#### Step 4: Architecture Review

Evaluate system architecture:
- Identify technical debt
- Review scalability
- Assess technology stack
- Plan architecture improvements

---

## On-Call Procedures

### On-Call Responsibilities

**Primary On-Call:**
- Respond to all alerts within 15 minutes
- Investigate and resolve incidents
- Escalate when necessary
- Document all incidents

**Secondary On-Call:**
- Backup for primary
- Respond if primary unavailable
- Assist with complex incidents

### Handoff Procedure

**Beginning of Shift:**
```bash
# Review current status
curl https://spacetime-api.company.com/status

# Check active incidents
# Log in to PagerDuty

# Review recent alerts
# Check Slack #spacetime-alerts

# Read handoff notes from previous on-call
# Review on-call runbook updates
```

**Handoff Checklist:**
- [ ] Review active incidents
- [ ] Check alert history
- [ ] Read handoff notes
- [ ] Verify access to all systems
- [ ] Test alert notification
- [ ] Review escalation contacts

**End of Shift:**
- Document all incidents
- Update handoff notes
- Brief next on-call
- Ensure smooth transition

---

## Capacity Planning

### Growth Tracking

**Monthly Review:**
- Track resource utilization trends
- Monitor traffic growth
- Analyze cost trends
- Update capacity forecast

**Thresholds for Scaling:**

**Scale Up When:**
- CPU > 70% consistently for 7 days
- Memory > 80% consistently for 7 days
- Disk > 85% (immediate action)
- Error rate increases due to resource constraints
- Response times degraded due to load

**Scale Down When:**
- CPU < 30% consistently for 30 days
- Memory < 50% consistently for 30 days
- Cost optimization opportunity identified
- Over-provisioned resources confirmed

**Scaling Procedures:**

**Horizontal Scaling:**
```bash
# Add new host to cluster
# 1. Provision new instance
# 2. Deploy application
# 3. Run health checks
# 4. Add to load balancer
# 5. Monitor for 24 hours
# 6. Update documentation
```

**Vertical Scaling:**
```bash
# Increase resources on existing hosts
# 1. Schedule maintenance window
# 2. Remove host from load balancer
# 3. Stop service
# 4. Resize instance
# 5. Start service
# 6. Run health checks
# 7. Add back to load balancer
# 8. Repeat for other hosts
```

---

## Appendix

### Monthly Operations Calendar

**Week 1:**
- Monthly review
- Capacity planning update
- Security audit
- Backup verification

**Week 2:**
- Dependency updates
- Performance optimization
- Documentation update

**Week 3:**
- Mid-month check
- Cost review
- Tool maintenance

**Week 4:**
- End-of-month reporting
- Next month planning
- Training updates

### Useful Queries

**Prometheus Queries:**
```promql
# Uptime percentage
avg_over_time(up[30d])

# 95th percentile response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[24h]))

# Error rate
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])

# Request rate
rate(http_requests_total[5m])

# CPU usage
100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

---

## Runbook Maintenance

- **Review Frequency:** Monthly
- **Last Reviewed:** 2025-12-02
- **Next Review:** 2026-01-02
- **Owner:** DevOps Team
- **Approver:** Engineering Manager
