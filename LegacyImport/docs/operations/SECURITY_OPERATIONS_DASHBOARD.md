# Security Operations Dashboard Guide

**SpaceTime VR Project - Dashboard Interpretation and Monitoring**
**Version:** 1.0.0
**Last Updated:** 2025-12-02

## Overview

This guide explains how to interpret and use the security operations dashboards for monitoring, alerting, and incident response.

## Dashboard Access

### Primary Dashboards

| Dashboard | URL | Purpose | Update Frequency |
|-----------|-----|---------|------------------|
| Security Overview | http://localhost:3000/d/security-overview | Real-time security status | 10 seconds |
| Threat Intelligence | http://localhost:3000/d/threat-intelligence | Active threats and attacks | 30 seconds |
| Authentication Metrics | http://localhost:3000/d/auth-metrics | Auth success/failure rates | 10 seconds |
| Authorization Audit | http://localhost:3000/d/authz-audit | RBAC and permissions | 1 minute |
| Incident Timeline | http://localhost:3000/d/incidents | Incident history and trends | Real-time |

### Direct API Access

```bash
# Security status JSON
curl http://127.0.0.1:8080/admin/security/status

# Metrics endpoint (Prometheus format)
curl http://127.0.0.1:8080/metrics

# Threat summary
curl http://127.0.0.1:8080/admin/security/threats/summary
```

---

## Security Overview Dashboard

### Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Security Overview Dashboard                    [Last 1h ▼] │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  │
│  │   Overall     │  │    Active     │  │   Security    │  │
│  │    Status     │  │  Incidents    │  │    Score      │  │
│  │    ✓ OK      │  │       2       │  │   85/100      │  │
│  └───────────────┘  └───────────────┘  └───────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  Authentication Rate                                        │
│  [Graph: Success/Failure over time]                        │
├─────────────────────────────────────────────────────────────┤
│  Active Threats by Severity                                │
│  [Pie chart: Critical/High/Medium/Low]                     │
├─────────────────────────────────────────────────────────────┤
│  Top Attacking IPs                                         │
│  [Table: IP, Country, Threat Score, Action]                │
├─────────────────────────────────────────────────────────────┤
│  Recent Security Events                                     │
│  [Timeline: Last 50 events with severity indicators]       │
└─────────────────────────────────────────────────────────────┘
```

### Key Metrics

#### 1. Overall Status Indicator

**Colors:**
- **Green (✓ OK):** All systems normal
- **Yellow (⚠ Warning):** Some alerts, no critical issues
- **Red (✗ Critical):** Active P0/P1 incident

**Drill-down:** Click for detailed status breakdown

#### 2. Active Incidents Counter

**Interpretation:**
- **0:** Normal operations (expected state)
- **1-2:** Typical security monitoring activity
- **3+:** Possible coordinated attack or multiple issues

**Action:** Click number to see incident details

#### 3. Security Score (0-100)

**Calculation:**
```
Score = 100 - (
  (Critical Incidents × 20) +
  (High Incidents × 10) +
  (Medium Incidents × 5) +
  (Low Incidents × 1) +
  (Auth Failure Rate × 10) +
  (Banned IPs / 10)
)
```

**Ranges:**
- **90-100:** Excellent security posture
- **75-89:** Good, minor issues
- **50-74:** Fair, needs attention
- **Below 50:** Poor, immediate action required

### Authentication Metrics Panel

**Graph components:**
- **Green line:** Successful authentications
- **Red line:** Failed authentications
- **Yellow shaded:** Rate limit violations

**Normal baseline:**
- Success rate: >95%
- Failure rate: <5%
- Rate limits: <10/hour

**Alert conditions:**
- Success rate drops below 90%
- Failure rate exceeds 10%
- Sudden spike in either direction

**Common patterns:**

| Pattern | Interpretation | Action |
|---------|----------------|--------|
| Steady green, low red | Normal | Monitor |
| Sudden red spike | Brute force attack | Ban IPs |
| Both lines spike | System issue or load test | Investigate |
| Gradual red increase | Slow attack or config issue | Investigate |

### Active Threats Panel

**Pie chart segments:**
- **Red:** Critical (requires immediate action)
- **Orange:** High (urgent response)
- **Yellow:** Medium (investigate)
- **Blue:** Low (monitor)

**Ideal state:** Mostly blue/yellow, no red

**Alert state:** Any red segments → investigate immediately

**Drill-down:** Click segment to see specific threats

### Top Attacking IPs Table

**Columns:**
- **IP Address:** Attacker source
- **Country:** Geographic origin
- **Threat Score:** 0-100+ (higher = more malicious)
- **Events:** Number of security events
- **Status:** Banned/Quarantined/Monitoring
- **Action:** Quick action buttons

**Threat score interpretation:**
- **0-25:** Low threat, monitoring
- **26-50:** Suspicious, increased scrutiny
- **51-100:** Malicious, temporary ban recommended
- **100+:** Confirmed attacker, permanent ban

**Quick actions:**
- **Ban:** Immediate IP ban
- **Details:** Full threat intelligence
- **Whitelist:** Mark as false positive

### Recent Security Events Timeline

**Event types and colors:**
- **🔴 Critical:** SQL injection, system breach
- **🟠 High:** Brute force, privilege escalation
- **🟡 Medium:** Rate limits, suspicious patterns
- **🔵 Low:** Off-hours access, unusual agents

**Timeline controls:**
- Zoom: Select time range
- Filter: By severity, event type, IP
- Export: Download events as JSON

**Pattern recognition:**
- Clustered events → Coordinated attack
- Repeated single-IP events → Persistent attacker
- Spread events → Normal operations

---

## Threat Intelligence Dashboard

### Threat Map

**Geographic visualization:**
- Red pins: Active attacks
- Orange pins: Suspicious activity
- Size: Threat volume

**Usage:**
- Identify attack origins
- Detect distributed attacks
- Spot geographic patterns

### Attack Timeline

**Horizontal timeline showing:**
- Attack start times
- Attack durations
- Attack types
- Concurrent attacks

**Useful for:**
- Understanding attack sequencing
- Identifying coordinated campaigns
- Post-incident analysis

### Threat Score Trends

**Graph showing:**
- IP threat scores over time
- Score increases (red) and decreases (green)
- Ban/unban events marked

**Interpretation:**
- Upward trends: Increasing threat
- Downward trends: Decreasing activity (or banned)
- Flat line: Consistent behavior

### Known Attackers List

**Table columns:**
- IP address
- First seen / Last seen
- Total events
- Threat types
- Current status

**Management actions:**
- Permanently ban persistent attackers
- Unban false positives
- Export for threat intelligence sharing

---

## Authentication Metrics Dashboard

### Authentication Success Rate

**Primary metric:** Percentage of successful authentications

**Components:**
- Real-time percentage (large number)
- Historical trend graph
- Comparison to baseline

**Thresholds:**
- Target: >95%
- Warning: <95%
- Critical: <90%

### Failed Authentication Analysis

**Breakdown by reason:**
- Invalid token
- Expired token
- Revoked token
- Rate limited
- Other

**Useful for:**
- Identifying configuration issues
- Detecting token lifecycle problems
- Finding integration bugs

### Token Usage Statistics

**Metrics:**
- Total tokens
- Active tokens
- Revoked tokens
- Tokens expiring soon (<7 days)

**Actions:**
- Review tokens expiring soon
- Revoke unused tokens
- Audit token purposes

### Top Tokens by Activity

**Table showing:**
- Token ID
- Role
- Request count
- Last used
- Success rate

**Useful for:**
- Identifying heavy users
- Finding misconfigured tokens
- Auditing access patterns

---

## Authorization Audit Dashboard

### RBAC Overview

**Role distribution pie chart:**
- Admin (should be <10%)
- Developer
- API Client
- Readonly

**Health check:**
- Too many admins? → Security risk
- All readonly? → Services misconfigured

### Authorization Decisions

**Graph showing:**
- Authorized requests (green)
- Denied requests (red)
- Authorization checks (total)

**Success rate target:** >90%

**High denial rate indicates:**
- Misconfigured roles
- Attack attempts
- Integration issues

### Failed Authorization Analysis

**Table of denials:**
- Token ID
- Requested permission
- Endpoint
- Reason for denial
- Count

**Use to identify:**
- Privilege escalation attempts
- Misconfigured services
- Missing permissions

### Permission Usage Heatmap

**Matrix showing:**
- Permissions (rows)
- Roles (columns)
- Usage frequency (color intensity)

**Insights:**
- Unused permissions → Remove?
- Heavily used permissions → Monitor closely
- Unexpected usage → Investigate

---

## Incident Timeline Dashboard

### Incident Status Overview

**Counters:**
- Open incidents (by severity)
- Closed incidents (last 24h)
- Mean Time To Resolve (MTTR)
- Mean Time To Detect (MTTD)

**KPI targets:**
- MTTR P0: <4 hours
- MTTR P1: <8 hours
- MTTD: <15 minutes

### Incident Timeline

**Gantt-style chart:**
- Each incident as horizontal bar
- Color by severity
- Length = duration
- Overlapping incidents visible

**Useful for:**
- Identifying incident clusters
- Capacity planning
- Post-incident review

### Incident Types Breakdown

**Bar chart showing:**
- Incident count by type
- Average resolution time
- Success rate

**Most common types:**
1. Brute force attacks
2. Rate limit violations
3. Suspicious patterns
4. Failed authentications

### Response Time Analysis

**Histogram:**
- Time to acknowledgment
- Time to initial response
- Time to resolution

**Compare to SLAs:**
- Green: Within SLA
- Yellow: Approaching SLA
- Red: SLA violation

---

## Alert Configuration

### Current Alerts (24 types)

**Authentication Alerts:**
1. Failed Login Threshold
2. Credential Stuffing
3. Distributed Brute Force

**Rate Limiting Alerts:**
4. Rapid Requests
5. Sustained High Rate
6. Endpoint Flooding

**Injection Attack Alerts:**
7. SQL Injection
8. Command Injection
9. Script Injection (XSS)

**Path Traversal Alerts:**
10. Directory Traversal
11. Sensitive File Access

**Privilege Escalation Alerts:**
12. Unauthorized Admin Access
13. Token Manipulation
14. Session Hijacking

**Geographic Alerts:**
15. Impossible Travel
16. Blacklisted Country
17. Unusual Location

**Behavioral Alerts:**
18. Rapid Session Creation
19. Unusual User Agent
20. Parameter Fuzzing
21. Off-Hours Access

**System Alerts:**
22. High Threat Score
23. Known Attacker Detected
24. IDS System Health

### Alert Panel

**For each alert:**
- Current status (firing/resolved)
- Last fired time
- Fire count (last 24h)
- Configuration (view/edit)

**Actions:**
- Silence temporarily
- Adjust threshold
- Disable alert
- Test alert

---

## Dashboard Customization

### Creating Custom Views

**Steps:**
1. Click "+" → New Dashboard
2. Add panels from template
3. Configure queries
4. Save and share

**Useful custom views:**
- Executive summary (high-level)
- On-call dashboard (actionable)
- Compliance report (audit-focused)
- Threat hunting (detailed analysis)

### Setting Alert Thresholds

**Navigate to:**
Alert Configuration → [Alert Name] → Edit

**Adjustable parameters:**
- Threshold values
- Time windows
- Severity levels
- Notification channels

**Best practices:**
- Start conservative (lower thresholds)
- Adjust based on false positives
- Document changes
- Review quarterly

### Export and Reporting

**Export options:**
- PDF report (scheduled or on-demand)
- CSV data export
- JSON API
- Grafana snapshots

**Scheduled reports:**
- Daily security summary (email)
- Weekly threat report
- Monthly compliance report

---

## Troubleshooting

### Dashboard Not Loading

**Checks:**
1. Godot server running?
   ```bash
   curl http://127.0.0.1:8080/status
   ```
2. Grafana running?
   ```bash
   curl http://localhost:3000
   ```
3. Prometheus scraping?
   ```bash
   curl http://localhost:9090/targets
   ```

### Metrics Missing

**Possible causes:**
- Prometheus scrape failure
- Metric exporter error
- Database connectivity

**Resolution:**
```bash
# Check metric exporter logs
tail -f logs/metrics_exporter.log

# Verify metrics endpoint
curl http://127.0.0.1:8080/metrics

# Restart metric exporter
systemctl restart metrics-exporter
```

### Stale Data

**Check:**
- Last update timestamp on dashboard
- Prometheus scrape interval
- Network connectivity

**Resolution:**
- Refresh browser
- Check Prometheus targets
- Restart affected services

---

## Best Practices

### Daily Monitoring Routine

**Morning (start of day):**
1. Check Security Overview
2. Review overnight incidents
3. Check authentication metrics
4. Review threat intelligence

**Afternoon (mid-day):**
1. Spot-check key metrics
2. Review any new alerts
3. Check incident progress

**Evening (end of day):**
1. Review day's incidents
2. Check for emerging patterns
3. Plan next day's focus

### Alert Fatigue Management

**Signs of alert fatigue:**
- Ignoring low-priority alerts
- Slow response times
- Missed critical alerts

**Solutions:**
- Tune alert thresholds
- Remove noisy alerts
- Aggregate similar alerts
- Prioritize by severity

### Dashboard Optimization

**Performance tips:**
- Use appropriate time ranges
- Limit data points shown
- Use data aggregation
- Cache frequently accessed data

---

## Quick Reference

### Critical Metrics to Watch

| Metric | Normal | Warning | Critical | Action |
|--------|--------|---------|----------|--------|
| Auth Success Rate | >95% | 90-95% | <90% | Investigate failures |
| Active P0 Incidents | 0 | 1 | >1 | All hands on deck |
| Threat Score Avg | <25 | 26-50 | >50 | Ban/investigate |
| Response Time | <5min | 5-15min | >15min | Review process |

### Dashboard Shortcuts

| Action | Shortcut | Notes |
|--------|----------|-------|
| Refresh | `Ctrl+R` | Force refresh |
| Time range | `t` | Quick time picker |
| Zoom | Click-drag | Select region |
| Reset zoom | Double-click | Reset view |
| Share | `Ctrl+S` | Create snapshot |

### API Quick Commands

```bash
# Get security status
curl -s http://127.0.0.1:8080/admin/security/status | jq

# Get active threats
curl -s http://127.0.0.1:8080/admin/security/threats/active | jq

# Get metrics summary
curl -s http://127.0.0.1:8080/admin/security/metrics | jq

# Export dashboard data
curl -s http://localhost:3000/api/dashboards/uid/security-overview | jq
```

---

## Document Maintenance

**Last Updated:** 2025-12-02
**Next Review:** 2025-03-02
**Owner:** Security Operations Team

**Feedback:** security-ops@spacetime-vr.com
