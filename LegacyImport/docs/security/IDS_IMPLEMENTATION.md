# Intrusion Detection System (IDS) Implementation

**Version:** 1.0.0
**Last Updated:** 2025-12-02
**Status:** Production Ready

## Overview

The SpaceTime Intrusion Detection System (IDS) provides comprehensive, real-time threat detection and automated response capabilities. The system monitors all HTTP API activity, detects malicious patterns, and automatically responds to threats through IP banning, session termination, rate limiting, and multi-channel alerting.

## Architecture

### Core Components

1. **IntrusionDetectionSystem** (`scripts/security/intrusion_detection.gd`)
   - Pattern-based threat detection
   - Anomaly detection using statistical baselines
   - IP reputation tracking
   - Threat intelligence integration
   - Performance-optimized batch analysis

2. **ThreatResponder** (`scripts/security/threat_responder.gd`)
   - Automated threat responses
   - IP banning (temporary and permanent)
   - Session termination and quarantine mode
   - Rate limit adjustment
   - Multi-channel alerting (Email, Slack, PagerDuty)

3. **SecurityMonitor** (`monitoring/security/security_monitor.gd`)
   - Real-time security event monitoring
   - Suspicious activity tracking
   - Security metric collection
   - Alert generation

4. **Detection Rules** (`config/ids_rules.json`)
   - Comprehensive rule configuration
   - Customizable detection thresholds
   - Response action configuration
   - Threat intelligence settings

## Detection Capabilities

### 1. Authentication Attacks

#### Failed Login Threshold
- **Rule:** `authentication.failed_login_threshold`
- **Detection:** 5 failed logins in 60 seconds from single IP
- **Severity:** HIGH
- **Score:** 10 points per failure
- **Response:** Temporary ban after threshold exceeded

#### Credential Stuffing
- **Rule:** `authentication.credential_stuffing`
- **Detection:** 10+ unique usernames tried from same IP in 120 seconds
- **Severity:** CRITICAL
- **Score:** 15 points per unique username
- **Response:** Permanent ban

#### Distributed Brute Force
- **Rule:** `authentication.distributed_brute_force`
- **Detection:** 20+ failed logins from 5+ different IPs in 300 seconds
- **Severity:** HIGH
- **Score:** 5 points per attempt
- **Response:** Temporary ban for all attacking IPs

### 2. Rate Limiting Violations

#### Rapid Requests
- **Rule:** `rate_limiting.rapid_requests`
- **Detection:** 100+ requests in 10 seconds from single IP
- **Severity:** MEDIUM
- **Score:** Request count / 10
- **Response:** Rate limit tightening (50% reduction)

#### Sustained High Rate
- **Rule:** `rate_limiting.sustained_high_rate`
- **Detection:** 500+ requests in 60 seconds
- **Severity:** HIGH
- **Score:** Request count / 5
- **Response:** Temporary ban

#### Endpoint Flooding
- **Rule:** `rate_limiting.endpoint_flooding`
- **Detection:** 50+ requests to single endpoint in 30 seconds
- **Severity:** MEDIUM
- **Score:** Request count / 5
- **Response:** Rate limit tightening

### 3. Injection Attacks

#### SQL Injection
- **Rule:** `injection_attacks.sql_injection`
- **Severity:** CRITICAL
- **Score:** 100 points
- **Response:** Immediate permanent ban

**Detection Patterns:**
```regex
- \b(union|select|insert|update|delete|drop|create|alter)\b.*\b(from|where|table|database)\b
- --|#|/\*|\*/|xp_|sp_
- ';|'\s+or\s+'|'\s+and\s+'
- \bexec\b|\bexecute\b
- 0x[0-9a-f]+
- char\(|concat\(|load_file\(
- into\s+(outfile|dumpfile)
```

#### Command Injection
- **Rule:** `injection_attacks.command_injection`
- **Severity:** CRITICAL
- **Score:** 100 points
- **Response:** Immediate permanent ban

**Detection Patterns:**
```regex
- [;&|`$]\s*(cat|ls|dir|type|wget|curl|nc|bash|sh|cmd|powershell)
- \$\(.*\)
- `.*`
- \|\|.*\||&&.*&
```

#### Script Injection (XSS)
- **Rule:** `injection_attacks.script_injection`
- **Severity:** HIGH
- **Score:** 50 points
- **Response:** Session termination + temporary ban

**Detection Patterns:**
```regex
- <script[^>]*>.*</script>
- javascript:
- onerror\s*=|onload\s*=
- eval\(|setTimeout\(|setInterval\(
- document\.cookie|document\.write
```

### 4. Path Traversal

#### Directory Traversal
- **Rule:** `path_traversal.directory_traversal`
- **Severity:** CRITICAL
- **Score:** 80 points
- **Response:** Permanent ban

**Detection Patterns:**
```regex
- \.\./|\.\.\/
- %2e%2e/|%2e%2e\\
- \.\.\\
- /etc/passwd|/etc/shadow
- c:\\windows|c:/windows
- /proc/|/sys/
```

#### Sensitive File Access
- **Rule:** `path_traversal.file_access`
- **Severity:** HIGH
- **Score:** 60 points
- **Response:** Temporary ban + alert

**Detection Patterns:**
```regex
- \.php$|\.asp$|\.jsp$
- \.exe$|\.dll$|\.so$
- \.sh$|\.bat$|\.cmd$
- web\.config|httpd\.conf|nginx\.conf
```

### 5. Privilege Escalation

#### Unauthorized Admin Access
- **Rule:** `privilege_escalation.unauthorized_admin_access`
- **Severity:** CRITICAL
- **Score:** 150 points
- **Protected Endpoints:** `/admin`, `/api/admin`, `/system`, `/config`, `/debug`
- **Response:** Session termination + permanent ban

#### Session Hijacking
- **Rule:** `privilege_escalation.session_hijacking`
- **Detection:** Session IP changes 2+ times in 300 seconds
- **Severity:** CRITICAL
- **Score:** 200 points
- **Response:** All sessions terminated + permanent ban

### 6. Behavioral Anomalies

#### Rapid Session Creation
- **Rule:** `behavioral_anomalies.rapid_session_creation`
- **Detection:** 10+ sessions created in 60 seconds
- **Severity:** MEDIUM
- **Score:** 3 points per session
- **Response:** Rate limit tightening

#### Suspicious User Agent
- **Rule:** `behavioral_anomalies.unusual_user_agent`
- **Severity:** LOW
- **Score:** 3 points
- **Suspicious Patterns:** `bot`, `crawler`, `spider`, `scraper`, `curl`, `wget`, `python-requests`

#### Parameter Fuzzing
- **Rule:** `behavioral_anomalies.parameter_fuzzing`
- **Detection:** 20+ unique parameter combinations in 60 seconds
- **Severity:** MEDIUM
- **Score:** 30 points
- **Response:** Rate limit tightening

### 7. Temporal Anomalies

#### Off-Hours Access
- **Rule:** `temporal_anomalies.off_hours_access`
- **Default Business Hours:** 08:00-18:00 UTC, Monday-Friday
- **Severity:** LOW
- **Score:** 2 points
- **Response:** Logging only (configurable)

#### Unusual Access Pattern
- **Rule:** `temporal_anomalies.unusual_access_pattern`
- **Detection:** Statistical deviation > 3σ from 7-day baseline
- **Severity:** MEDIUM
- **Score:** Variable based on deviation
- **Response:** Alert generation

## Automated Response System

### Response Actions

#### 1. Temporary IP Ban
- **Trigger:** Threat score ≥ 100
- **Default Duration:** 3600 seconds (1 hour)
- **Configurable:** Yes (`response_actions.temporary_ban`)
- **Implementation:**
  ```gdscript
  responder.ban_ip_temporary(ip, duration, reason)
  ```

#### 2. Permanent IP Ban
- **Trigger:** Threat score ≥ 300 OR critical threat (SQL injection, command injection)
- **Configurable:** Yes (`response_actions.permanent_ban`)
- **Implementation:**
  ```gdscript
  responder.ban_ip_permanent(ip, reason)
  ```

#### 3. Session Termination
- **Trigger:** Threat score ≥ 150
- **Action:** Terminates all sessions from attacking IP
- **Configurable:** Yes (`response_actions.session_termination`)

#### 4. Quarantine Mode
- **Trigger:** Threat score ≥ 200
- **Action:** Places IP in read-only mode (can view but not modify)
- **Duration:** Until manual review
- **Configurable:** Yes (`response_actions.quarantine_mode`)

#### 5. Rate Limit Tightening
- **Trigger:** Threat score ≥ 50
- **Action:** Reduces rate limits by 50% (configurable)
- **Duration:** Until threat score decays
- **Configurable:** Yes (`response_actions.rate_limit_tightening`)

### Alert Channels

#### Email Alerts
- **Triggers:** CRITICAL and HIGH severity threats
- **Configuration:** `response_actions.alert_critical`, `alert_high`
- **Integration Point:** `_send_email_alert()` in `threat_responder.gd`
- **Example Integration:**
  ```gdscript
  var email_service = EmailService.new()
  email_service.send({
      "to": "security@example.com",
      "subject": "[Security Alert] CRITICAL",
      "body": alert_message
  })
  ```

#### Slack Alerts
- **Triggers:** CRITICAL, HIGH, and MEDIUM severity threats
- **Configuration:** `response_actions.alert_*`
- **Integration Point:** `_send_slack_alert()` in `threat_responder.gd`
- **Webhook Example:**
  ```gdscript
  var webhook_url = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  var payload = {
      "text": message,
      "attachments": [{
          "color": severity_color,
          "fields": [
              {"title": "IP", "value": ip, "short": true},
              {"title": "Score", "value": score, "short": true}
          ]
      }]
  }
  ```

#### PagerDuty Alerts
- **Triggers:** CRITICAL severity threats only
- **Configuration:** `response_actions.alert_critical`
- **Integration Point:** `_send_pagerduty_alert()` in `threat_responder.gd`
- **API Example:**
  ```gdscript
  var payload = {
      "routing_key": "YOUR_ROUTING_KEY",
      "event_action": "trigger",
      "payload": {
          "summary": message,
          "severity": "critical",
          "source": "IDS"
      }
  }
  ```

## Threat Scoring System

### Score Calculation

Each security event adds points to an IP's threat score:

| Event Type | Base Score |
|------------|-----------|
| SQL Injection | 100 |
| Command Injection | 100 |
| Path Traversal | 80 |
| XSS Attempt | 50 |
| Privilege Escalation | 150 |
| Session Hijacking | 200 |
| Failed Auth | 10 |
| Rate Limit Violation | 5 |
| Unauthorized Access | 30 |
| Off-Hours Access | 2 |
| Unusual Location | 5 |
| Suspicious User Agent | 3 |

### Reputation Tiers

| Tier | Score Range | Status |
|------|-------------|--------|
| Trusted | 0 | Whitelisted IPs |
| Clean | 1-24 | Normal activity |
| Suspicious | 25-99 | Elevated monitoring |
| Malicious | 100-299 | Automated responses active |
| Blocked | 300+ | Permanent ban |

### Score Decay

- **Enabled:** Yes (configurable)
- **Decay Rate:** 10 points per 60 seconds
- **Purpose:** Prevents permanent scoring for transient issues
- **Implementation:** Runs in `_decay_suspicion_scores()` timer

## Configuration

### Loading Configuration

The IDS loads configuration from `res://config/ids_rules.json` on startup:

```gdscript
func load_rules_config() -> void:
    var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
    var json = JSON.new()
    json.parse(file.get_as_text())
    rules_config = json.data
```

### Configuration Structure

```json
{
  "version": "1.0.0",
  "detection_rules": {
    "authentication": { /* ... */ },
    "rate_limiting": { /* ... */ },
    "injection_attacks": { /* ... */ },
    "path_traversal": { /* ... */ }
  },
  "response_actions": {
    "temporary_ban": {
      "enabled": true,
      "duration_seconds": 3600,
      "threshold_score": 100
    }
  },
  "scoring": {
    "event_scores": { /* ... */ },
    "decay_rate": { /* ... */ }
  }
}
```

### Whitelisting

#### Trusted IPs
- **Configuration:** `whitelists.trusted_ips`
- **Effect:** Bypass ALL detection rules
- **Default:** `127.0.0.1`, `::1`
- **Use Case:** Internal monitoring, health checks

#### Internal Networks
- **Configuration:** `whitelists.internal_networks`
- **Effect:** Reduced scrutiny, higher thresholds
- **Default:** `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`
- **Use Case:** Corporate networks, VPNs

## Integration Points

### 1. HTTP API Integration

Connect IDS to HTTP request processing:

```gdscript
# In your HTTP request handler
func _handle_request(request: HTTPRequest):
    var client_ip = request.get_remote_address()

    # Check if IP is banned
    if threat_responder.is_ip_banned(client_ip):
        return _return_403_banned()

    # Check if quarantined
    if threat_responder.is_ip_quarantined(client_ip):
        if request.method != "GET":
            return _return_403_quarantined()

    # Log request for analysis
    var event_data = {
        "ip": client_ip,
        "endpoint": request.path,
        "method": request.method,
        "user_agent": request.headers.get("User-Agent", "")
    }
    ids.analyze_event("request", event_data)

    # Apply rate limit multiplier
    var multiplier = threat_responder.get_rate_limit_multiplier(client_ip)
    var adjusted_limit = base_rate_limit * multiplier
```

### 2. Authentication Integration

Connect IDS to authentication events:

```gdscript
# After authentication attempt
func _on_auth_attempt(username: String, password: String, client_ip: String, success: bool):
    var event_type = "auth_success" if success else "failed_auth"

    var event_data = {
        "ip": client_ip,
        "username": username,
        "endpoint": "/api/auth/login"
    }

    ids.analyze_event(event_type, event_data)

    # Log to audit system
    HttpApiAuditLogger.log_auth_attempt(client_ip, "/api/auth/login", success)
```

### 3. Input Validation Integration

Detect injection attempts in user input:

```gdscript
# In input validation
func _validate_input(input: String, client_ip: String, endpoint: String):
    var event_data = {
        "ip": client_ip,
        "endpoint": endpoint,
        "payload": input
    }

    # Check for SQL injection
    ids.analyze_event("sql_injection", event_data)

    # Check for command injection
    ids.analyze_event("command_injection", event_data)

    # Check for XSS
    ids.analyze_event("script_injection", event_data)
```

### 4. File Access Integration

Monitor file access for path traversal:

```gdscript
# In file access handler
func _access_file(path: String, client_ip: String):
    var event_data = {
        "ip": client_ip,
        "path": path,
        "endpoint": "/api/file"
    }

    ids.analyze_event("path_traversal", event_data)
```

## Monitoring and Metrics

### Grafana Dashboard

The IDS includes a comprehensive Grafana dashboard (`monitoring/grafana/dashboards/intrusion_detection.json`) with:

1. **Threat Level Overview** - Real-time critical/high/medium/low threat counts
2. **Attack Pattern Distribution** - Pie chart of attack types
3. **Top Attacking IPs** - Table of highest threat scores
4. **IP Reputation Map** - Geographic visualization
5. **Attack Timeline** - Hourly threat activity
6. **Response Actions** - Bans, quarantines, alerts
7. **Detection Performance** - Analysis time and throughput
8. **Alert Status** - Multi-channel alert tracking

### Prometheus Metrics

Expected metrics (to be exported by telemetry system):

```prometheus
# Threats detected
ids_threats_detected_total{severity="CRITICAL|HIGH|MEDIUM|LOW", attack_type="..."}

# IP reputation
ids_ip_threat_score{ip="..."}
ids_ip_reputation_score{ip="..."}

# Response actions
ids_temporary_bans_total
ids_permanent_bans_total
ids_banned_ips_total
ids_sessions_terminated_total
ids_quarantines_activated_total
ids_rate_limits_tightened_total

# Alerts
ids_alerts_sent_total{severity="...", channel="..."}

# Performance
ids_analysis_time_avg_ms
ids_events_analyzed_total

# Detection rules
ids_rule_triggered_total{rule_name="..."}

# Anomalies
ids_anomalies_detected_total{type="behavioral|temporal|geographic"}
```

### Real-Time Monitoring

Access real-time IDS status:

```gdscript
# Get current detection statistics
var stats = ids.get_detection_stats()
print("Threats detected: ", stats["threats_detected"])
print("Analysis time: ", stats["analysis_time_avg_ms"], "ms")

# Get threat summary
var summary = ids.get_threat_summary()
print("Threats last hour: ", summary["threats_last_hour"])
print("Active IPs: ", summary["active_ips"])

# Get response statistics
var response_stats = responder.get_response_stats()
print("Temporary bans: ", response_stats["temporary_bans"])
print("Permanent bans: ", response_stats["permanent_bans"])

# Get active bans
var bans = responder.get_active_bans()
for ban in bans:
    print("IP %s banned: %s" % [ban["ip"], ban["reason"]])
```

## Testing

### Running Tests

```bash
# Run GdUnit4 tests (requires GdUnit4 plugin installed)
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/security/test_intrusion_detection.gd
```

### Test Coverage

The test suite (`tests/security/test_intrusion_detection.gd`) covers:

1. **Detection Tests**
   - SQL injection pattern matching
   - Command injection detection
   - Path traversal detection
   - XSS detection
   - Brute force attack detection
   - Credential stuffing detection
   - Rapid request detection
   - Behavioral anomalies

2. **Response Tests**
   - Temporary banning
   - Permanent banning
   - Ban expiration
   - Quarantine mode
   - Rate limit tightening
   - Alert queueing
   - Alert cooldown

3. **Integration Tests**
   - Signal emissions
   - Statistics tracking
   - Data export
   - Configuration loading

4. **Performance Tests**
   - Load testing (1000 events)
   - Analysis time measurement
   - Memory efficiency

### Manual Testing

```gdscript
# Test SQL injection detection
var test_payload = "' OR '1'='1"
var result = ids.analyze_event("sql_injection", {
    "ip": "192.168.1.100",
    "payload": test_payload,
    "endpoint": "/api/test"
})

# Test alert system
responder.test_alert("CRITICAL", "slack")

# Test ban functionality
responder.admin_ban_ip("10.0.0.1", false, 300.0, "Test ban")
print("Is banned: ", responder.is_ip_banned("10.0.0.1"))
```

## Performance Considerations

### Batch Analysis

The IDS uses batch processing to optimize performance:

- **Batch Size:** 100 events per analysis cycle
- **Analysis Interval:** 5 seconds (configurable)
- **Queue Management:** Events queued for batch processing
- **Immediate Analysis:** Critical events (SQL injection, etc.) analyzed immediately

### Caching

- **IP Reputation Cache:** 24-hour TTL
- **Detection Cache:** Quick lookup for pattern matching
- **Event History:** Limited to 10,000 recent events

### Resource Limits

- **Max Event History:** 10,000 events
- **Threat Cache Size:** 10,000 entries
- **Analysis Threads:** 4 (configurable)
- **Event Retention:** 24 hours

### Optimization Tips

1. **Adjust Analysis Interval:** Increase interval for lower CPU usage
2. **Reduce Pattern Complexity:** Simplify regex patterns for faster matching
3. **Tune Batch Size:** Larger batches reduce overhead but increase latency
4. **Enable Parallel Analysis:** Use multi-threading for high-traffic scenarios

## Security Best Practices

### 1. Configuration Security

- Store `ids_rules.json` outside web root
- Use environment variables for sensitive settings
- Regularly review and update detection rules
- Test rule changes in staging environment

### 2. Alert Management

- Configure multiple alert channels for redundancy
- Set appropriate severity thresholds
- Implement alert fatigue prevention (cooldowns)
- Regularly review false positive rates

### 3. Ban Management

- Review permanent bans regularly
- Implement unban procedures for false positives
- Log all ban/unban actions
- Consider geographic context for bans

### 4. Monitoring

- Monitor IDS performance metrics
- Track false positive/negative rates
- Review threat intelligence feeds
- Conduct regular security audits

### 5. Incident Response

- Document incident response procedures
- Establish escalation paths for critical threats
- Maintain runbooks for common scenarios
- Conduct post-incident reviews

## Troubleshooting

### High False Positive Rate

**Symptoms:** Legitimate users being banned

**Solutions:**
1. Review detection patterns in `ids_rules.json`
2. Adjust scoring thresholds
3. Add IPs/networks to whitelist
4. Increase cooldown periods
5. Review user agent patterns

### Missed Threats

**Symptoms:** Known attacks not detected

**Solutions:**
1. Add new patterns to detection rules
2. Lower detection thresholds
3. Enable additional rule categories
4. Update threat intelligence feeds
5. Review audit logs for missed patterns

### Performance Issues

**Symptoms:** High CPU usage, slow response times

**Solutions:**
1. Increase analysis interval
2. Reduce batch size
3. Optimize regex patterns
4. Enable caching
5. Increase event retention cleanup frequency

### Alert Overload

**Symptoms:** Too many alerts, alert fatigue

**Solutions:**
1. Increase alert cooldowns
2. Raise severity thresholds
3. Group similar alerts
4. Implement alert suppression rules
5. Use alert aggregation

## Future Enhancements

### Planned Features

1. **Machine Learning Integration**
   - Behavioral profiling
   - Anomaly detection with ML models
   - Adaptive threshold tuning

2. **External Threat Intelligence**
   - AbuseIPDB integration
   - Spamhaus blocklist
   - Project Honey Pot
   - Tor exit node detection

3. **Geographic Intelligence**
   - IP geolocation
   - Impossible travel detection
   - Country-based blocking
   - ASN reputation

4. **Advanced Analytics**
   - Attack campaign correlation
   - Threat actor profiling
   - Predictive threat modeling
   - Risk scoring

5. **Enhanced Response**
   - CAPTCHA challenges
   - Progressive rate limiting
   - Honeypot deployment
   - Automated forensics

## Support and Maintenance

### Updating Detection Rules

1. Edit `config/ids_rules.json`
2. Test changes in development environment
3. Monitor false positive rate after deployment
4. Document rule changes in version control

### Adding New Detection Rules

```json
{
  "detection_rules": {
    "new_category": {
      "new_rule": {
        "enabled": true,
        "severity": "HIGH",
        "threshold": 10,
        "window_seconds": 60,
        "description": "Rule description"
      }
    }
  },
  "scoring": {
    "event_scores": {
      "new_event_type": 50
    }
  }
}
```

Then implement detection in `intrusion_detection.gd`:

```gdscript
func _analyze_new_category(events: Array, rule: Dictionary) -> void:
    # Implementation
    pass
```

### Maintenance Tasks

- **Daily:** Review critical alerts
- **Weekly:** Review banned IPs, analyze trends
- **Monthly:** Update detection rules, review false positives
- **Quarterly:** Security audit, performance review

## Conclusion

The SpaceTime IDS provides enterprise-grade intrusion detection and automated response capabilities. The system is designed to be:

- **Proactive:** Detects threats in real-time
- **Adaptive:** Learns from patterns and adjusts responses
- **Comprehensive:** Covers all major attack vectors
- **Performant:** Optimized for high-traffic scenarios
- **Extensible:** Easy to add new rules and responses
- **Observable:** Rich monitoring and alerting

For additional support, refer to the main security documentation or contact the security team.

---

**Document Version:** 1.0.0
**Last Reviewed:** 2025-12-02
**Next Review:** 2026-03-02
