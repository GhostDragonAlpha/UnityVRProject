# Security Monitoring System

This directory contains security monitoring and alerting components for the Godot VR Game HTTP API.

## Components

### SecurityMonitor (`security_monitor.gd`)

Real-time security monitoring and threat detection system that:
- Tracks security events (failed auth, rate limit violations, path traversal attempts)
- Maintains IP reputation scores
- Generates alerts for suspicious activity
- Provides security metrics and reporting
- Implements automatic IP banning for severe threats

### Integration

Add SecurityMonitor to your project:

```gdscript
# In godot_bridge.gd or autoload
var security_monitor: SecurityMonitor

func _ready() -> void:
    security_monitor = SecurityMonitor.new()
    add_child(security_monitor)

    # Connect to alert signals
    security_monitor.security_alert.connect(_on_security_alert)
    security_monitor.suspicious_activity_detected.connect(_on_suspicious_activity)
    security_monitor.ip_banned.connect(_on_ip_banned)

# Record security events
func _check_auth(client: StreamPeerTCP, headers: Dictionary, required_role: String) -> Dictionary:
    var auth_result = # ... authentication logic ...

    if not auth_result["authorized"]:
        # Record failed authentication
        security_monitor.record_event("failed_auth", {
            "ip": _get_client_ip(client),
            "user": "unknown",
            "reason": auth_result["error"]
        })
    else:
        # Record successful authentication
        security_monitor.record_event("auth_success", {
            "ip": _get_client_ip(client),
            "user": auth_result["user"]
        })

    return auth_result

# Handle alerts
func _on_security_alert(severity: String, message: String, details: Dictionary) -> void:
    print("[ALERT] %s: %s" % [severity, message])

    # Send notifications (implement based on your needs)
    if severity == "CRITICAL":
        _send_emergency_notification(message, details)

    # Log to audit system
    if audit_logger:
        audit_logger.log_security_event("security_alert", {
            "severity": severity,
            "message": message,
            "details": details
        })
```

## Event Types

The security monitor tracks these event types:

- **failed_auth** - Failed authentication attempts (10 points)
- **auth_success** - Successful authentication (0 points)
- **rate_limit_violations** - Rate limit exceeded (5 points)
- **path_traversal_attempts** - Path traversal detected (50 points - very suspicious)
- **invalid_input** - Invalid input detected (2 points)
- **unauthorized_access** - Authorization failure (20 points)
- **suspicious_activity** - General suspicious behavior (varies)

## Suspicion Scoring

IPs accumulate suspicion points based on their behavior:

- **0-99 points:** Normal activity
- **100-199 points:** Suspicious - monitoring increased
- **200+ points:** Automatic ban

Scores decay by 10 points every 10 seconds to allow recovery from temporary issues.

## Alert Severities

- **CRITICAL:** Immediate action required (path traversal, bans)
- **HIGH:** Urgent attention needed (brute force, repeated unauthorized access)
- **MEDIUM:** Monitor closely (high request rates, anomalies)
- **LOW:** Informational (first-time suspicious activity)

## Metrics Tracked

- Total requests
- Failed requests
- Requests per minute
- Active sessions
- Banned IPs count
- Failure rate
- Event counters per type

## API

### Recording Events

```gdscript
security_monitor.record_event(event_type: String, details: Dictionary)
```

### Getting Status

```gdscript
var status = security_monitor.get_security_status()
# Returns: {
#   "event_counters": {...},
#   "metrics": {...},
#   "suspicious_ips": count,
#   "recent_alerts": count,
#   "is_under_attack": bool
# }
```

### Getting Recent Alerts

```gdscript
var alerts = security_monitor.get_recent_alerts(10)  # Get last 10 alerts
```

### Exporting Security Report

```gdscript
var report = security_monitor.export_security_report()
# Returns comprehensive security status including:
# - Event counters
# - Metrics
# - Top suspicious IPs
# - Recent alerts
# - Attack status
```

### Resetting Counters

```gdscript
security_monitor.reset_counters()  # Call hourly or daily
```

## Signals

### security_alert
Emitted when a security alert is generated.

**Parameters:**
- `severity: String` - Alert severity (CRITICAL, HIGH, MEDIUM, LOW)
- `message: String` - Alert message
- `details: Dictionary` - Alert details

### suspicious_activity_detected
Emitted when an IP crosses the suspicion threshold.

**Parameters:**
- `ip: String` - Suspicious IP address
- `score: int` - Current suspicion score
- `events: Array` - Recent events from this IP

### ip_banned
Emitted when an IP is automatically banned.

**Parameters:**
- `ip: String` - Banned IP address
- `reason: String` - Ban reason

## Example: Complete Integration

```gdscript
# In godot_bridge.gd

var security_monitor: SecurityMonitor

func _ready() -> void:
    # Initialize security monitor
    security_monitor = SecurityMonitor.new()
    add_child(security_monitor)

    # Connect signals
    security_monitor.security_alert.connect(_on_security_alert)
    security_monitor.ip_banned.connect(_on_ip_banned)

func _handle_http_request(client: StreamPeerTCP, request_data: PackedByteArray) -> void:
    var client_ip = _get_client_ip(client)

    # Check if IP is banned
    if _is_ip_banned(client_ip):
        _send_error_response(client, 403, "Forbidden", "IP banned")
        client.disconnect_from_host()
        return

    # Record request
    security_monitor.record_event("request", {"ip": client_ip})

    # Check rate limit
    var rate_check = rate_limiter.check_rate_limit(client_ip)
    if not rate_check["allowed"]:
        security_monitor.record_event("rate_limit_violations", {
            "ip": client_ip,
            "reason": rate_check["reason"]
        })
        _send_rate_limit_response(client, rate_check["reason"], rate_check["retry_after"])
        return

    # Continue with request processing...
    # ... existing code ...

func _check_auth(client: StreamPeerTCP, headers: Dictionary, required_role: String) -> Dictionary:
    var client_ip = _get_client_ip(client)

    # ... authentication logic ...

    if not validation["valid"]:
        # Record failed authentication
        security_monitor.record_event("failed_auth", {
            "ip": client_ip,
            "error": validation["error"]
        })
        return {"authorized": false, "error": validation["error"], "status": 401}

    # Record successful authentication
    security_monitor.record_event("auth_success", {
        "ip": client_ip,
        "user": validation["user"]
    })

    # Check authorization
    if not authorized:
        security_monitor.record_event("unauthorized_access", {
            "ip": client_ip,
            "user": validation["user"],
            "required_role": required_role,
            "user_role": user_role
        })
        return {"authorized": false, ...}

    return {"authorized": true, ...}

func _handle_scene_load(client: StreamPeerTCP, request_data: Dictionary) -> void:
    var scene_path = request_data.get("scene_path", "")
    var client_ip = _get_client_ip(client)

    # Check for path traversal
    if "../" in scene_path or "..\\" in scene_path:
        security_monitor.record_event("path_traversal_attempts", {
            "ip": client_ip,
            "path": scene_path,
            "endpoint": "/scene/load"
        })
        _send_error_response(client, 400, "Bad Request", "Path traversal detected")
        return

    # ... rest of scene loading logic ...

func _on_security_alert(severity: String, message: String, details: Dictionary) -> void:
    print("[SECURITY ALERT] [%s] %s" % [severity, message])

    # Log to audit system
    if audit_logger:
        audit_logger.log_security_event("alert", {
            "severity": severity,
            "message": message,
            "details": details
        })

    # Send notifications for critical alerts
    if severity == "CRITICAL":
        _send_critical_alert_notification(message, details)

func _on_ip_banned(ip: String, reason: String) -> void:
    print("IP BANNED: %s - %s" % [ip, reason])

    # Add to banned IPs list
    banned_ips[ip] = {
        "timestamp": Time.get_unix_time_from_system(),
        "reason": reason
    }

    # Log to audit system
    if audit_logger:
        audit_logger.log_security_event("ip_ban", {
            "ip": ip,
            "reason": reason
        })

    # Notify administrators
    _send_ban_notification(ip, reason)
```

## Dashboard Integration

The security monitor can be integrated with a monitoring dashboard:

```gdscript
# Create HTTP endpoint for security dashboard
func _handle_security_dashboard(client: StreamPeerTCP) -> void:
    var report = security_monitor.export_security_report()

    _send_json_response(client, 200, {
        "status": "ok",
        "security": report,
        "generated_at": Time.get_datetime_string_from_system()
    })
```

## Maintenance

### Daily Tasks
- Review security alerts
- Check suspicious IP list
- Verify ban list is appropriate

### Weekly Tasks
- Export and archive security reports
- Reset counters for fresh weekly stats
- Review alert thresholds

### Monthly Tasks
- Analyze security trends
- Adjust suspicion scoring if needed
- Update alert rules based on new threats
- Clear old banned IPs (if appropriate)

## Testing

Test the security monitor with simulated attacks:

```python
#!/usr/bin/env python3
# test_security_monitor.py

import requests
import time

BASE_URL = "http://127.0.0.1:8080"

def test_failed_auth_detection():
    """Test that failed auth attempts are detected"""
    for i in range(15):
        requests.get(BASE_URL + "/status")  # No auth header
        time.sleep(0.1)

    # Should trigger alert after 10 failures

def test_rate_limit_detection():
    """Test rate limit violation detection"""
    for i in range(100):
        requests.get(BASE_URL + "/status")

    # Should trigger rate limit violation

def test_path_traversal_detection():
    """Test path traversal attempt detection"""
    requests.post(
        BASE_URL + "/scene/load",
        json={"scene_path": "res://../../etc/passwd"}
    )

    # Should trigger immediate critical alert

if __name__ == "__main__":
    test_failed_auth_detection()
    test_rate_limit_detection()
    test_path_traversal_detection()
```

## Troubleshooting

### High False Positive Rate
- Adjust suspicion point values
- Increase alert thresholds
- Review legitimate traffic patterns

### Missing Alerts
- Verify events are being recorded
- Check signal connections
- Verify alert cooldown periods

### Performance Issues
- Limit event history size (currently 1000)
- Adjust CHECK_INTERVAL (currently 10s)
- Optimize suspicious IP tracking

## Future Enhancements

- Machine learning for anomaly detection
- Integration with external SIEM systems
- Geolocation-based risk scoring
- Behavioral analysis and user profiling
- Automated response actions
- Security analytics and trending

---

**See SECURITY_AUDIT_REPORT.md for complete security assessment**
