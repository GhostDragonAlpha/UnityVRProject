# Security Monitoring Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Metrics Reference](#metrics-reference)
4. [Dashboard Guide](#dashboard-guide)
5. [Alert Response Procedures](#alert-response-procedures)
6. [SLA Definitions](#sla-definitions)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

---

## Overview

The SpaceTime VR security monitoring system provides comprehensive real-time visibility into security events, threats, and authentication activities. It uses Prometheus for metrics collection, Grafana for visualization, and AlertManager for incident notification.

### Key Features
- **Real-time Threat Detection**: Monitor active threats with sub-second latency
- **Authentication Monitoring**: Track login attempts, token lifecycle, and failures
- **Intrusion Detection**: Identify attack patterns and malicious behavior
- **Rate Limiting**: Monitor and respond to abuse and DoS attempts
- **Input Validation**: Detect injection attacks (SQL, XSS, command injection)
- **Performance Impact**: <1% overhead from security metrics collection
- **SLA Tracking**: Ensure security systems meet performance targets

### System Requirements
- Godot 4.5+
- Prometheus 2.40+
- Grafana 9.0+
- AlertManager 0.25+ (optional, for alerting)

---

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Godot HTTP API                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              Security Components                          │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐  │  │
│  │  │ TokenManager│  │SecurityConfig│  │  AuditLogger    │  │  │
│  │  │(Instrumented)│  │(Instrumented)│  │ (Instrumented)  │  │  │
│  │  └──────┬──────┘  └──────┬───────┘  └────────┬────────┘  │  │
│  │         │                 │                    │           │  │
│  │         └─────────────────┴────────────────────┘           │  │
│  │                           │                                │  │
│  │                           ▼                                │  │
│  │                ┌──────────────────────┐                   │  │
│  │                │ SecurityMetrics      │                   │  │
│  │                │ Exporter             │                   │  │
│  │                └──────────┬───────────┘                   │  │
│  └───────────────────────────┼───────────────────────────────┘  │
└────────────────────────────────┼─────────────────────────────────┘
                                 │
                                 ▼ (HTTP /metrics endpoint)
                    ┌────────────────────────┐
                    │      Prometheus        │
                    │  (Metrics Collection)  │
                    └────────┬───────────────┘
                             │
                    ┌────────┴───────────┐
                    │                    │
                    ▼                    ▼
          ┌─────────────────┐   ┌──────────────┐
          │    Grafana      │   │ AlertManager │
          │  (Dashboards)   │   │  (Alerts)    │
          └─────────────────┘   └──────────────┘
```

### Data Flow

1. **Security Events**: Security components (TokenManager, SecurityConfig, AuditLogger) generate events
2. **Metric Recording**: Instrumented wrappers call SecurityMetricsExporter methods
3. **Metric Storage**: SecurityMetricsExporter stores metrics in memory with efficient data structures
4. **Metric Export**: Prometheus scrapes `/metrics` endpoint (default: every 15s)
5. **Visualization**: Grafana queries Prometheus and displays dashboards
6. **Alerting**: Prometheus evaluates alert rules and sends to AlertManager

---

## Metrics Reference

### Authentication Metrics

#### `authentication_attempts_total{result}`
**Type**: Counter
**Labels**: `result` (success, failure, invalid_token, expired_token, revoked_token, missing_token)
**Description**: Total authentication attempts by result
**Usage**: Monitor authentication success rate and detect brute force attacks

```promql
# Authentication success rate
rate(authentication_attempts_total{result="success"}[5m]) /
rate(authentication_attempts_total[5m]) * 100

# Failed authentication rate
rate(authentication_attempts_total{result!="success"}[5m])
```

#### `authentication_token_operations_total{operation}`
**Type**: Counter
**Labels**: `operation` (validation, generation, rotation, revocation)
**Description**: Total token operations by type
**Usage**: Track token lifecycle and security hygiene

```promql
# Token rotation rate (healthy security practice)
rate(authentication_token_operations_total{operation="rotation"}[1h])

# Token revocations (potential compromise)
increase(authentication_token_operations_total{operation="revocation"}[24h])
```

#### `authentication_active_tokens`
**Type**: Gauge
**Description**: Current number of active (valid, non-expired) tokens
**Usage**: Monitor token population and detect token accumulation

```promql
# Active tokens trend
authentication_active_tokens

# Token growth rate
deriv(authentication_active_tokens[1h])
```

---

### Authorization Metrics

#### `authorization_checks_total{result}`
**Type**: Counter
**Labels**: `result` (allowed, denied)
**Description**: Total authorization checks by result
**Usage**: Monitor access control effectiveness and detect unauthorized access attempts

```promql
# Authorization denial rate
rate(authorization_checks_total{result="denied"}[5m]) /
rate(authorization_checks_total[5m])

# Denied access spike
increase(authorization_checks_total{result="denied"}[10m]) > 50
```

#### `authorization_denials_by_role{role}`
**Type**: Counter
**Labels**: `role` (admin, user, guest, etc.)
**Description**: Authorization denials by role
**Usage**: Identify roles with access issues or unauthorized access patterns

```promql
# Top denied roles
topk(5, increase(authorization_denials_by_role[1h]))
```

#### `authorization_privilege_escalation_attempts`
**Type**: Counter
**Description**: Total privilege escalation attempts
**Usage**: Critical security metric - any non-zero value requires immediate investigation

```promql
# Privilege escalation alert
increase(authorization_privilege_escalation_attempts[5m]) > 0
```

---

### Rate Limiting Metrics

#### `rate_limit_violations_total{endpoint}`
**Type**: Counter
**Labels**: `endpoint` (API endpoint path)
**Description**: Total rate limit violations by endpoint
**Usage**: Identify attacked endpoints and potential DoS attempts

```promql
# Top rate-limited endpoints
topk(10, rate(rate_limit_violations_total[5m]))

# Endpoint-specific violation rate
rate(rate_limit_violations_total{endpoint="/api/auth"}[1m])
```

#### `rate_limit_bans_total`
**Type**: Counter
**Description**: Total IP bans issued
**Usage**: Track ban frequency and effectiveness

```promql
# Ban rate
rate(rate_limit_bans_total[1h])

# Daily bans
increase(rate_limit_bans_total[24h])
```

#### `rate_limit_active_bans`
**Type**: Gauge
**Description**: Current number of active IP bans
**Usage**: Monitor ban population and detect distributed attacks

```promql
# Active bans
rate_limit_active_bans

# High ban count (distributed attack indicator)
rate_limit_active_bans > 10
```

#### `rate_limit_requests_throttled_total`
**Type**: Counter
**Description**: Total requests throttled
**Usage**: Measure rate limiting effectiveness

---

### Input Validation Metrics

#### `input_validation_failures_total{type}`
**Type**: Counter
**Labels**: `type` (sql_injection, xss, path_traversal, command_injection, size_exceeded, malformed_json, invalid_characters)
**Description**: Input validation failures by type
**Usage**: Detect injection attacks and input-based exploits

```promql
# SQL injection attempts
increase(input_validation_failures_total{type="sql_injection"}[1h])

# XSS attempts
increase(input_validation_failures_total{type="xss"}[1h])

# Total validation failures
sum(rate(input_validation_failures_total[5m]))
```

#### `input_validation_requests_rejected_total`
**Type**: Counter
**Description**: Total requests rejected due to validation failures
**Usage**: Measure validation effectiveness and attack volume

#### `input_validation_suspicious_patterns{pattern}`
**Type**: Counter
**Labels**: `pattern` (pattern type)
**Description**: Suspicious patterns detected
**Usage**: Early detection of reconnaissance or probing

---

### Security Events Metrics

#### `security_events_total{severity,type}`
**Type**: Counter
**Labels**: `severity` (critical, high, medium, low), `type` (event type)
**Description**: Security events by severity and type
**Usage**: Track security incidents and trends

```promql
# Critical events
rate(security_events_total{severity="critical"}[5m])

# Event breakdown by type
sum by(type) (rate(security_events_total[1h]))

# High severity events in last hour
increase(security_events_total{severity=~"critical|high"}[1h])
```

#### `security_incidents_total`
**Type**: Counter
**Description**: Total security incidents (high/critical events)
**Usage**: Track serious security events requiring investigation

```promql
# Incident rate
rate(security_incidents_total[1h])

# Daily incidents
increase(security_incidents_total[24h])
```

#### `security_anomalies_detected`
**Type**: Counter
**Description**: Total security anomalies detected
**Usage**: Identify unusual patterns and behaviors

---

### Intrusion Detection Metrics

#### `intrusion_threat_score{ip}`
**Type**: Gauge
**Labels**: `ip` (IP address)
**Description**: Threat score by IP address (0-100)
**Usage**: Identify malicious IPs and track threat levels

```promql
# High threat IPs (score >= 80)
intrusion_threat_score > 80

# Top 20 threats
topk(20, intrusion_threat_score)

# Threat score distribution
histogram_quantile(0.95, intrusion_threat_score)
```

**Threat Score Calculation**:
- SQL Injection attempt: +10 points
- XSS attempt: +10 points
- Command Injection attempt: +10 points
- Attack pattern detected: +20 points
- Rate limit violation: +5 points
- Path traversal: +10 points
- Suspicious pattern: +3 points
- Validation failure: +2 points

#### `intrusion_active_threats`
**Type**: Gauge
**Description**: Current number of active threats (IPs with score >= 50)
**Usage**: Monitor active attack volume

```promql
# Active threats
intrusion_active_threats

# Active threats alert
intrusion_active_threats > 5
```

#### `intrusion_blocked_ips_total`
**Type**: Counter
**Description**: Total IPs blocked
**Usage**: Track blocking effectiveness

#### `intrusion_attack_patterns_detected{pattern}`
**Type**: Counter
**Labels**: `pattern` (attack pattern name)
**Description**: Attack patterns detected by type
**Usage**: Identify attack methodologies

```promql
# Top attack patterns
topk(10, increase(intrusion_attack_patterns_detected[1h]))
```

#### `blocked_ips_by_reason{reason}`
**Type**: Counter
**Labels**: `reason` (block reason)
**Description**: Blocked IPs by reason
**Usage**: Analyze why IPs are being blocked

---

### Performance Metrics

#### `security_check_duration_ms{quantile}`
**Type**: Gauge
**Labels**: `quantile` (0.50, 0.90, 0.95, 0.99)
**Description**: Security check duration percentiles in milliseconds
**Usage**: Monitor performance impact of security checks

```promql
# P95 latency
security_check_duration_ms{quantile="0.95"}

# P99 latency
security_check_duration_ms{quantile="0.99"}

# Performance SLA violation (P95 > 25ms)
security_check_duration_ms{quantile="0.95"} > 25
```

**Performance Targets**:
- P50: < 5ms
- P95: < 25ms
- P99: < 50ms
- Maximum overhead: < 1% of total request time

---

### Geographic Metrics

#### `requests_by_country{country}`
**Type**: Counter
**Labels**: `country` (ISO country code)
**Description**: Total requests by country
**Usage**: Geographic traffic analysis

#### `requests_by_ip{ip}`
**Type**: Counter
**Labels**: `ip` (IP address, top 100 only)
**Description**: Total requests by IP address
**Usage**: Identify high-volume sources

---

## Dashboard Guide

### Security Overview Dashboard

**UID**: `security-overview`
**Refresh**: 5 seconds
**Time Range**: Last 1 hour

#### Panels

1. **Authentication Success Rate (%)**: Gauge showing authentication health
   - Green: >= 95%
   - Yellow: 80-95%
   - Red: < 80%

2. **Active Threats**: Current number of high-threat IPs
   - Green: 0-2
   - Yellow: 3-10
   - Red: > 10

3. **Active Bans**: Current IP bans in effect
   - Green: 0-3
   - Yellow: 4-10
   - Red: > 10

4. **Security Incidents (1h)**: Recent high-severity events
   - Green: 0-10
   - Yellow: 11-50
   - Red: > 50

5. **Authentication Attempts Over Time**: Line chart showing auth rate by result

6. **Security Events by Severity**: Stacked area chart of events

7. **Top Attacked Endpoints**: Pie chart of rate limit violations

8. **Input Validation Failures (1h)**: Bar chart by failure type

9. **Top Threat IPs**: Table with threat scores (color-coded)

10. **Security Gauges Over Time**: Trend lines for tokens, bans, threats

11. **Security Check Performance**: Latency percentiles

#### Usage

**Normal Operations**:
- Authentication success rate: > 95%
- Active threats: 0-2
- Active bans: 0-5
- Incidents: 0-10/hour

**Under Attack**:
- Authentication success rate: < 80%
- Active threats: > 10
- Active bans: > 15
- Incidents: > 50/hour

**Actions**:
1. Check "Top Threat IPs" table for high-scoring IPs
2. Review "Top Attacked Endpoints" for targeted services
3. Monitor "Input Validation Failures" for attack types
4. Drill down to Authentication or Threat Intelligence dashboards

---

### Authentication Dashboard

**UID**: `security-authentication`
**Refresh**: 5 seconds
**Time Range**: Last 1 hour

#### Panels

1. **Success Rate**: Gauge with SLA thresholds
2. **Total Attempts (1h)**: Authentication volume
3. **Failed Attempts (1h)**: Failed authentication count
4. **Active Tokens**: Current valid tokens
5. **Token Rotations (1h)**: Security hygiene metric
6. **Token Revocations (24h)**: Potential compromise indicator
7. **Authentication Rate by Result**: Time series by result type
8. **Failed Authentication Heatmap**: Temporal pattern visualization
9. **Top IPs by Auth Failures (1h)**: Brute force detection
10. **Token Operations (Hourly)**: Operation breakdown
11. **Token Lifecycle**: Token population trends

#### Usage

**Detecting Brute Force Attacks**:
1. Check "Failed Attempts (1h)" - sudden spike indicates attack
2. Review "Top IPs by Auth Failures" - identify attacking sources
3. Check "Failed Authentication Heatmap" - look for temporal patterns
4. Monitor "Success Rate" - should remain > 95% despite attacks

**Token Security**:
1. "Active Tokens" should grow linearly with users
2. "Token Rotations (1h)" should be steady (indicates good hygiene)
3. "Token Revocations (24h)" spike may indicate compromise
4. "Token Lifecycle" should show balanced creation/revocation

**Alert Conditions**:
- Success rate < 95% for 15 minutes
- Failed attempts > 100 in 1 hour from single IP
- Token revocations > 10 in 1 hour
- Active tokens growth rate > 2x expected

---

### Threat Intelligence Dashboard

**UID**: `security-threat-intelligence`
**Refresh**: 10 seconds
**Time Range**: Last 6 hours

#### Panels

1. **Active Threats**: Current high-threat IPs (score >= 50)
2. **Active Bans**: Current IP bans
3. **IPs Blocked (24h)**: Recent blocking activity
4. **Privilege Escalation (24h)**: Critical security events
5. **IP Reputation Scores**: Table of threat scores
6. **High Severity Security Events**: Time series of critical/high events
7. **Attack Patterns (1h)**: Pie chart of detected patterns
8. **Input Validation Failures by Type**: Bar chart (hourly)
9. **Block Reasons (24h)**: Why IPs are being blocked
10. **Top Rate Limited Endpoints**: Most attacked services
11. **Threat Trends**: Long-term threat evolution
12. **Security Event Heatmap**: Temporal event distribution

#### Usage

**Identifying Attacks**:
1. Check "Active Threats" - any value > 5 indicates attack
2. Review "IP Reputation Scores" - scores > 80 are critical
3. Check "Attack Patterns" - shows attack methodology
4. Monitor "High Severity Security Events" - incident timeline

**Responding to Attacks**:
1. Identify high-threat IPs in reputation table
2. Review "Attack Patterns" to understand attack type
3. Check "Input Validation Failures" for injection attempts
4. Use "Block Reasons" to verify automatic responses
5. Monitor "Threat Trends" for escalation

**Attack Pattern Interpretation**:
- `sql_injection`: Database compromise attempt
- `xss`: Client-side code injection
- `command_injection`: System compromise attempt
- `path_traversal`: File system access attempt
- `brute_force`: Credential guessing

**Threat Score Thresholds**:
- 0-20: Low threat (monitoring only)
- 21-49: Medium threat (increased monitoring)
- 50-79: High threat (automatic restrictions)
- 80-100: Critical threat (automatic blocking)

---

## Alert Response Procedures

### Critical Alerts

#### BruteForceAttackDetected

**Trigger**: > 10 failed auth attempts/second for 2 minutes

**Impact**: High risk of unauthorized access

**Response Procedure**:
1. **Immediate** (< 2 minutes):
   - Open Threat Intelligence dashboard
   - Identify attacking IPs in "IP Reputation Scores"
   - Verify threat scores are elevated

2. **Investigation** (< 5 minutes):
   - Check Authentication dashboard for failure patterns
   - Review audit logs: `tail -f user://logs/http_api_audit.log | grep AUTH_FAILURE`
   - Identify if single source or distributed

3. **Mitigation** (< 10 minutes):
   - Single source: Verify automatic ban is in effect
   - Distributed: Consider lowering rate limits temporarily
   - Escalate to security team if attack persists
   - Enable additional MFA if available

4. **Documentation**:
   - Record incident in security log
   - Note attacking IPs and patterns
   - Document mitigation steps taken

#### PrivilegeEscalationAttempt

**Trigger**: Any privilege escalation attempt (> 0 in 5 minutes)

**Impact**: Potential unauthorized access to privileged functions

**Response Procedure**:
1. **Immediate** (< 1 minute):
   - Alert security team immediately
   - Do NOT wait to investigate before alerting

2. **Investigation** (< 3 minutes):
   - Review audit logs for escalation details
   - Identify source IP and attempted escalation path
   - Check Security Overview for related events
   - Verify role assignments and permissions

3. **Mitigation** (< 5 minutes):
   - Block source IP immediately (manual if needed)
   - Audit recent authorization changes
   - Review all activity from source IP
   - Verify no successful escalations occurred

4. **Post-Incident** (< 1 hour):
   - Full security audit of RBAC system
   - Review all role assignments
   - Check for any privilege creep
   - Update detection rules if needed

#### SQLInjectionAttempt / CommandInjectionAttempt

**Trigger**: Any injection attempt detected

**Impact**: Potential database/system compromise

**Response Procedure**:
1. **Immediate** (< 1 minute):
   - Block source IP immediately
   - Alert security and engineering teams

2. **Investigation** (< 5 minutes):
   - Review exact injection attempt from logs
   - Identify targeted endpoint
   - Check if attempt succeeded (monitor database/system logs)
   - Verify input sanitization is in place

3. **Mitigation** (< 15 minutes):
   - Verify parameterized queries/safe execution
   - Review recent code changes to targeted endpoint
   - Add additional input validation if needed
   - Consider temporary endpoint shutdown if critical

4. **Post-Incident** (< 24 hours):
   - Full code review of input handling
   - Audit all database queries
   - Penetration test affected endpoints
   - Update WAF rules if applicable

#### HighThreatScoreDetected

**Trigger**: IP threat score > 80 for 5 minutes

**Impact**: Active malicious activity from this IP

**Response Procedure**:
1. **Immediate** (< 2 minutes):
   - Verify automatic blocking is active
   - Check if manual block needed
   - Review all recent activity from this IP

2. **Investigation** (< 5 minutes):
   - Check Threat Intelligence dashboard for IP details
   - Review attack patterns from this IP
   - Identify which security events contributed to score
   - Check for related IPs (same subnet/ASN)

3. **Mitigation** (< 10 minutes):
   - Ensure IP is blocked
   - Add to permanent blocklist if repeated offender
   - Update threat intelligence feeds
   - Check for successful exploits

4. **Documentation**:
   - Record IP and threat details
   - Note attack patterns used
   - Update threat intelligence database

---

### High Alerts

#### HighRateLimitViolations

**Trigger**: > 5 rate limit violations/second for 5 minutes

**Impact**: Potential DoS attack or misconfigured client

**Response Procedure**:
1. **Investigation** (< 5 minutes):
   - Check if single IP or distributed
   - Review endpoint being targeted
   - Verify rate limits are appropriate for endpoint

2. **Mitigation** (< 10 minutes):
   - Single IP: Verify automatic ban
   - Distributed: Consider temporary rate limit reduction
   - Check for legitimate traffic spike (new deployment, marketing campaign)

3. **Follow-up**:
   - If legitimate: Adjust rate limits
   - If attack: Monitor for escalation
   - Document pattern for future detection

#### XSSAttemptDetected / PathTraversalAttempt

**Trigger**: Multiple XSS/path traversal attempts in 10 minutes

**Impact**: Potential XSS injection or unauthorized file access

**Response Procedure**:
1. **Immediate** (< 2 minutes):
   - Check if attempts succeeded
   - Verify input sanitization is working
   - Review output encoding (for XSS)

2. **Mitigation** (< 10 minutes):
   - Block attacking IP
   - Verify CSP headers (for XSS)
   - Check file access controls (for path traversal)
   - Add additional validation if needed

3. **Post-Incident**:
   - Code review of affected endpoints
   - Update validation rules
   - Consider WAF deployment

#### HighAuthenticationFailureRate

**Trigger**: Auth failure rate > 50% for 10 minutes

**Impact**: Potential credential stuffing or authentication system issue

**Response Procedure**:
1. **Immediate** (< 2 minutes):
   - Check if attack or system issue
   - Review Authentication dashboard

2. **Investigation** (< 5 minutes):
   - If attack: Follow brute force procedures
   - If system: Check token validation system
   - Verify database connectivity
   - Check for authentication service degradation

3. **Mitigation**:
   - Attack: Implement CAPTCHA or additional challenges
   - System: Fix underlying issue
   - Monitor for recovery

---

### Medium Alerts

#### NewIPBan / UnusualAccessPattern / ValidationFailuresIncreasing

These are informational alerts requiring monitoring but not immediate action.

**Response Procedure**:
1. **Monitor** (< 15 minutes):
   - Review relevant dashboard
   - Check for escalation
   - Document pattern

2. **Investigate** (< 1 hour):
   - Analyze root cause
   - Determine if action needed
   - Update detection rules if false positive

3. **Follow-up**:
   - Adjust thresholds if needed
   - Document for trend analysis

---

## SLA Definitions

### Authentication SLA

**Target**: 95% authentication success rate

**Measurement**:
```promql
rate(authentication_attempts_total{result="success"}[5m]) /
rate(authentication_attempts_total[5m]) >= 0.95
```

**Violation Conditions**:
- < 95% for 15 consecutive minutes: SLA violation
- < 90% for 5 minutes: Critical SLA violation

**Actions on Violation**:
1. Alert security team
2. Investigate authentication system health
3. Check for attacks (brute force, credential stuffing)
4. Review token validation system
5. Verify database connectivity

**Recovery**:
- Restore > 95% success rate for 30 minutes
- Document root cause and resolution

---

### Security Performance SLA

**Target**: P95 security check duration < 25ms

**Measurement**:
```promql
security_check_duration_ms{quantile="0.95"} < 25
```

**Violation Conditions**:
- P95 > 25ms for 30 minutes: SLA violation
- P95 > 50ms for 10 minutes: Critical SLA violation
- P99 > 100ms for 5 minutes: Critical SLA violation

**Actions on Violation**:
1. Profile security check functions
2. Identify performance bottlenecks
3. Review recent security changes
4. Consider caching or optimization
5. Verify no resource exhaustion

**Recovery**:
- Restore P95 < 25ms for 1 hour
- Document optimizations made

---

### Threat Response SLA

**Target**: Critical threats blocked within 5 minutes

**Measurement**: Manual tracking via incident logs

**Violation Conditions**:
- Threat score > 80 not blocked within 5 minutes
- SQL/Command injection not blocked within 2 minutes
- Privilege escalation not investigated within 3 minutes

**Actions on Violation**:
1. Review automatic blocking systems
2. Verify alert routing
3. Check security team response time
4. Update runbooks if procedures unclear

---

## Troubleshooting

### Metrics Not Appearing in Prometheus

**Symptoms**:
- Dashboards show "No data"
- Metrics missing from Prometheus targets page

**Diagnosis**:
1. Check if security metrics exporter is initialized:
   ```gdscript
   # In GodotBridge or initialization code
   if security_metrics_exporter == null:
       print("ERROR: Security metrics exporter not initialized")
   ```

2. Verify `/metrics` endpoint returns security metrics:
   ```bash
   curl http://localhost:8080/metrics | grep -i security
   ```

3. Check Prometheus scrape config:
   ```yaml
   # prometheus.yml
   scrape_configs:
     - job_name: 'godot_security'
       static_configs:
         - targets: ['localhost:8080']
   ```

4. Verify Prometheus can reach endpoint:
   ```bash
   curl http://localhost:9090/targets
   ```

**Solutions**:
- Initialize SecurityMetricsExporter in GodotBridge `_ready()`
- Connect exporter to instrumented security components
- Verify Godot HTTP server is running
- Check firewall rules for port 8080

---

### High Security Check Latency

**Symptoms**:
- `security_check_duration_ms{quantile="0.95"}` > 50ms
- Slow request processing
- Performance alerts firing

**Diagnosis**:
1. Check which security checks are slow:
   ```gdscript
   # Add timing to specific checks
   var start = Time.get_ticks_msec()
   var result = validate_auth(headers, client_ip)
   var duration = Time.get_ticks_msec() - start
   print("Auth check took: ", duration, "ms")
   ```

2. Review recent security changes:
   - New validation rules?
   - Additional injection checks?
   - Threat score calculations?

3. Check for O(n²) algorithms or inefficient lookups

**Solutions**:
- Cache validation results (with TTL)
- Use hash tables for lookups instead of arrays
- Optimize regex patterns in validation
- Consider async security checks for non-critical paths
- Profile hot paths and optimize

---

### False Positive Alerts

**Symptoms**:
- Alerts firing for legitimate traffic
- High-threat scores for known-good IPs
- Rate limiting internal services

**Diagnosis**:
1. Review alerting thresholds in `security_alerts.yml`
2. Check threat score calculation logic
3. Verify validation rules aren't too strict
4. Review rate limit configuration

**Solutions**:
- Whitelist internal IPs from threat scoring
- Adjust alert thresholds based on baseline
- Add exceptions for legitimate patterns
- Implement IP reputation allowlists
- Tune rate limits per endpoint

---

### Missing Security Events

**Symptoms**:
- Expected security events not showing in dashboards
- Audit logs have events but Prometheus doesn't

**Diagnosis**:
1. Verify instrumented wrappers are being used:
   ```gdscript
   # Should use instrumented versions:
   HttpApiSecurityConfigInstrumented.validate_auth(...)
   # NOT:
   HttpApiSecurityConfig.validate_auth(...)
   ```

2. Check if metrics exporter is connected:
   ```gdscript
   if HttpApiSecurityConfigInstrumented.security_metrics_exporter == null:
       print("ERROR: Exporter not connected to SecurityConfig")
   ```

3. Verify event recording calls:
   ```gdscript
   security_metrics_exporter.record_security_event("high", "test_event", {})
   ```

**Solutions**:
- Use instrumented versions of all security components
- Connect SecurityMetricsExporter during initialization
- Verify all security paths call instrumented wrappers
- Add logging to metric recording for debugging

---

## Best Practices

### 1. Regular Dashboard Review

**Daily**:
- Check Security Overview dashboard for trends
- Review Authentication success rate
- Monitor active threats and bans

**Weekly**:
- Analyze threat trends over 7 days
- Review top attacked endpoints
- Audit authentication failures by IP
- Check security check performance

**Monthly**:
- Full security metrics review
- Trend analysis and capacity planning
- SLA compliance reporting
- Update alert thresholds based on baselines

---

### 2. Alert Tuning

**Baseline Establishment**:
- Run system for 2 weeks to establish baselines
- Calculate P95, P99 for all metrics
- Document normal operating ranges
- Set alert thresholds at 2-3 standard deviations

**Threshold Adjustment**:
- Review alert frequency weekly
- Tune thresholds to minimize false positives
- Ensure critical alerts have < 5% false positive rate
- Document all threshold changes

**Alert Fatigue Prevention**:
- Consolidate related alerts
- Use severity levels appropriately
- Implement alert suppression for known issues
- Route alerts to correct teams

---

### 3. Incident Documentation

**For Every Security Incident**:
1. Record in security log
2. Document timeline
3. Note root cause
4. List mitigation steps
5. Identify lessons learned
6. Update runbooks

**Incident Log Format**:
```markdown
## Incident: [Brief Description]
- **Date**: YYYY-MM-DD HH:MM:SS
- **Severity**: Critical/High/Medium/Low
- **Detected By**: Alert name or manual discovery
- **Duration**: [Detection time to resolution]
- **Impact**: [User impact, if any]
- **Root Cause**: [What caused the incident]
- **Mitigation**: [Steps taken to resolve]
- **Prevention**: [Steps to prevent recurrence]
- **Follow-up**: [Action items and owners]
```

---

### 4. Security Hygiene

**Token Management**:
- Rotate tokens every 24 hours automatically
- Revoke tokens on logout
- Monitor for token accumulation
- Clean up expired tokens daily

**IP Reputation**:
- Decay threat scores over time (e.g., -1 per hour)
- Review and reset scores weekly
- Maintain IP allowlist for internal services
- Update GeoIP database monthly

**Rate Limiting**:
- Review limits quarterly
- Adjust based on legitimate usage patterns
- Separate limits for authenticated vs. unauthenticated
- Document all limit changes

**Validation Rules**:
- Review injection patterns quarterly
- Update based on new attack vectors
- Test validation rules regularly
- Document all rule changes

---

### 5. Performance Optimization

**Target Overhead**: < 1% of total request time

**Optimization Strategies**:
1. **Caching**:
   - Cache validation results (5-minute TTL)
   - Cache threat scores (1-minute TTL)
   - Cache rate limit buckets in memory

2. **Efficient Data Structures**:
   - Use hash tables for O(1) lookups
   - Avoid linear scans of large datasets
   - Limit stored metrics to top-N items

3. **Sampling**:
   - Sample low-priority metrics (e.g., geographic data)
   - Full metrics for critical security events
   - Adaptive sampling based on load

4. **Asynchronous Processing**:
   - Non-critical security checks can be async
   - Critical path must be synchronous
   - Background threat score updates

---

### 6. Compliance and Auditing

**Audit Log Retention**:
- Keep audit logs for 90 days minimum
- Archive critical security events for 1 year
- Implement log rotation and compression
- Secure log storage with access controls

**Metrics Retention**:
- Prometheus raw metrics: 30 days
- Aggregated metrics: 1 year
- Critical security incidents: Permanent

**Access Control**:
- Restrict dashboard access to authorized personnel
- Implement role-based access for Grafana
- Audit dashboard views and changes
- Secure Prometheus/AlertManager with authentication

---

### 7. Disaster Recovery

**Backup Strategy**:
- Daily backups of Prometheus data
- Weekly backups of Grafana dashboards
- Version control for alert rules
- Document restore procedures

**Recovery Procedures**:
1. Prometheus data loss:
   - Restore from most recent backup
   - Verify metrics are flowing
   - Check dashboard functionality

2. Grafana dashboard loss:
   - Restore from JSON exports
   - Verify data sources are connected
   - Test all panels and queries

3. Alert rule loss:
   - Restore from version control
   - Reload Prometheus configuration
   - Verify alerts are firing

**Testing**:
- Test restore procedures quarterly
- Document restore time objectives
- Verify backups are accessible

---

## Appendix

### Useful PromQL Queries

```promql
# Top 10 threat IPs in last hour
topk(10, increase(intrusion_threat_score[1h]))

# Authentication failure rate by hour
rate(authentication_attempts_total{result!="success"}[1h])

# Attacks by type (last 24h)
sum by(type) (increase(input_validation_failures_total[24h]))

# Security check performance (P95, P99)
security_check_duration_ms{quantile=~"0.95|0.99"}

# Active security issues
(intrusion_active_threats > 0) or
(rate_limit_active_bans > 10) or
(rate(security_incidents_total[5m]) > 0)

# Geographic attack distribution
topk(20, sum by(country) (increase(requests_by_country[24h])))
where intrusion_threat_score{country} > 50

# Token security health
(
  rate(authentication_token_operations_total{operation="rotation"}[24h]) /
  rate(authentication_token_operations_total{operation="generation"}[24h])
) >= 0.8  # 80% of tokens should be rotated
```

### Security Metrics Export Format

Metrics are exported in Prometheus text format:

```
# HELP authentication_attempts_total Total authentication attempts by result
# TYPE authentication_attempts_total counter
authentication_attempts_total{result="success"} 1523
authentication_attempts_total{result="failure"} 42
authentication_attempts_total{result="invalid_token"} 15

# HELP intrusion_threat_score Threat score by IP address (0-100)
# TYPE intrusion_threat_score gauge
intrusion_threat_score{ip="192.168.1.100"} 85.00
intrusion_threat_score{ip="10.0.0.50"} 23.50
```

### Integration with External Systems

**Slack Notifications**:
```yaml
# alertmanager.yml
receivers:
  - name: 'security-team'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#security-alerts'
        title: '{{ .GroupLabels.severity | toUpper }}: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}\n{{ .Annotations.action }}{{ end }}'
```

**PagerDuty Integration**:
```yaml
receivers:
  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_KEY'
        severity: '{{ .GroupLabels.severity }}'
```

---

## Support and Contact

For questions or issues with security monitoring:

1. **Documentation**: Refer to this guide and inline code comments
2. **Dashboards**: Check relevant Grafana dashboards
3. **Logs**: Review audit logs at `user://logs/http_api_audit.log`
4. **Metrics**: Query Prometheus directly at `http://localhost:9090`
5. **Security Team**: Contact via configured alert channels

---

**Document Version**: 1.0
**Last Updated**: 2025-12-02
**Maintained By**: SpaceTime VR Security Team
