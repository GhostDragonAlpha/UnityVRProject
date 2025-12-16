# Security Audit Logging - Quick Reference Card

**Version:** 1.0 | **Date:** 2025-12-02

---

## Setup (One-Time)

### 1. Register Autoload
**Project Settings → Autoload:**
- Name: `AuditHelper`
- Path: `res://scripts/security/audit_helper.gd`
- Enable: ✅

### 2. Get Reference in Router
```gdscript
var audit_helper: Node

func _init():
    audit_helper = get_node_or_null("/root/AuditHelper")
```

---

## Common Patterns

### Authentication Success
```gdscript
if SecurityConfig.validate_auth(request.headers):
    if audit_helper:
        audit_helper.log_auth_success(request, "/endpoint")
```

### Authentication Failure
```gdscript
if not SecurityConfig.validate_auth(request.headers):
    if audit_helper:
        audit_helper.log_auth_failure(request, "Invalid token", "/endpoint")
    response.send(401, ...)
    return
```

### Authorization Failure
```gdscript
# User lacks required role
if audit_helper:
    audit_helper.log_authz_failure(request, "admin", "readonly", "/admin")
response.send(403, ...)
```

### Input Validation Failure
```gdscript
if not is_valid_input(scene_path):
    if audit_helper:
        audit_helper.log_validation_failure(
            request,
            "scene_path",
            "Path traversal detected",
            scene_path,
            "/scene"
        )
    response.send(400, ...)
```

### Rate Limit Violation
```gdscript
var rate_check = SecurityConfig.check_rate_limit(ip, endpoint)
if not rate_check["allowed"]:
    if audit_helper:
        audit_helper.log_rate_limit(
            request,
            rate_check["limit"],
            rate_check["retry_after"],
            endpoint
        )
    response.send(429, ...)
```

### Security Violation (Path Traversal)
```gdscript
if "../" in scene_path:
    if audit_helper:
        audit_helper.log_security_violation(
            request,
            "path_traversal",
            {"attempted_path": scene_path, "blocked": true},
            "/scene"
        )
    response.send(403, ...)
```

### Scene Load
```gdscript
# Success
if audit_helper:
    audit_helper.log_scene_load(request, scene_path, true, "Loaded successfully")

# Failure
if audit_helper:
    audit_helper.log_scene_load(request, scene_path, false, "Scene not found")
```

### Configuration Change
```gdscript
if audit_helper:
    audit_helper.log_config_change(
        request,
        "rate_limit",
        str(old_limit),
        str(new_limit)
    )
```

---

## Analyzer Commands

### View Recent Events
```bash
# Last hour
python audit_log_analyzer.py --last 1h

# Last 30 minutes
python audit_log_analyzer.py --last 30m

# Last 7 days
python audit_log_analyzer.py --days 7
```

### Filter Events
```bash
# By type
python audit_log_analyzer.py --event-type authentication_failure

# By severity
python audit_log_analyzer.py --severity critical

# By IP
python audit_log_analyzer.py --ip 192.168.1.100

# By user
python audit_log_analyzer.py --user test_user

# By endpoint
python audit_log_analyzer.py --endpoint /scene
```

### Analysis
```bash
# Detect patterns
python audit_log_analyzer.py --analyze-patterns

# Generate report
python audit_log_analyzer.py --report --output report.html

# Export to CSV
python audit_log_analyzer.py --format csv --output export.csv
```

### Search
```bash
# Text search
python audit_log_analyzer.py --search "path traversal"

# Regex search
python audit_log_analyzer.py --search "192\.168\.1\.\d+" --regex
```

---

## Monitoring

### Grafana Dashboard
**URL:** http://localhost:3000/d/security-audit

**Key Panels:**
- Total Audit Events
- Security Events Rate
- Authentication Failures
- Security Violations (CRITICAL)
- Log File Usage

### Prometheus Metrics
**Endpoint:** http://localhost:8080/metrics

**Key Metrics:**
```prometheus
audit_log_events_total
audit_log_events_by_type_total{type="..."}
audit_log_rotations_total
audit_log_current_size_bytes
```

### Get Metrics in Code
```gdscript
# Dictionary format
var metrics = audit_helper.get_metrics()
print("Total events: ", metrics["total_events_logged"])

# Prometheus format
var prometheus = audit_helper.get_prometheus_metrics()
print(prometheus)
```

---

## Event Types

| Event Type | When to Log |
|-----------|-------------|
| `authentication_success` | Valid token accepted |
| `authentication_failure` | Invalid/missing token |
| `authorization_failure` | User lacks required role |
| `validation_failure` | Invalid input data |
| `rate_limit_violation` | Rate limit exceeded |
| `security_violation` | Path traversal, injection, etc. |
| `scene_load` | Scene loading operation |
| `configuration_change` | System config modified |

---

## Log Location

**Directory:** `user://logs/security/`

**Full Path:**
- Windows: `%APPDATA%\Godot\app_userdata\[project]\logs\security\`
- Linux/Mac: `~/.local/share/godot/app_userdata/[project]/logs/security/`

**Files:**
- `audit_2025-12-02.jsonl` (current day)
- `audit_2025-12-02.jsonl.1701518400` (rotated)
- `.signing_key` (HMAC key - DO NOT DELETE)

---

## Troubleshooting

### No Logs Being Written

**Check:**
```gdscript
var audit_helper = get_node_or_null("/root/AuditHelper")
if audit_helper:
    print("✅ Audit logging enabled")
    print(audit_helper.get_metrics())
else:
    print("❌ AuditHelper not found!")
```

**Fix:** Register AuditHelper in Project Settings → Autoload

### Can't Find Logs

```bash
# Find actual location
cd ~/.local/share/godot/app_userdata/*/logs/security/
# Or on Windows:
cd %APPDATA%\Godot\app_userdata\*\logs\security\

ls -la
```

### Grafana Not Showing Data

**Check Prometheus endpoint:**
```bash
curl http://localhost:8080/metrics | grep audit_log
```

**Should see:**
```
audit_log_events_total 123
audit_log_events_by_type_total{type="..."} ...
```

---

## Best Practices

### ✅ DO
- ✅ Log all authentication attempts
- ✅ Log authorization failures
- ✅ Log security violations immediately
- ✅ Include relevant context in details
- ✅ Log both success and failure for critical ops
- ✅ Check `if audit_helper:` before logging

### ❌ DON'T
- ❌ Log passwords or tokens in clear text
- ❌ Log excessive PII (personal information)
- ❌ Forget to log security-critical events
- ❌ Block requests while logging (it's async)
- ❌ Delete the `.signing_key` file

---

## Testing

### Run Tests
```bash
# GDScript tests
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/security/

# Python tests
cd tests/security
python -m pytest test_audit_analyzer.py -v
```

### Verify Logging in Development
```gdscript
func test_logging():
    audit_helper.log_authentication("test_user", "127.0.0.1", "/test", true)

    # Check metrics
    var metrics = audit_helper.get_metrics()
    print("Events logged: ", metrics["total_events_logged"])
```

---

## Integration Checklist

When adding audit logging to a new router:

- [ ] Add `audit_helper` reference in `_init()`
- [ ] Log authentication attempts (success/failure)
- [ ] Log authorization checks
- [ ] Log input validation failures
- [ ] Log rate limit violations
- [ ] Log security violations (path traversal, injection)
- [ ] Log critical operations (scene loads, config changes)
- [ ] Test logging with sample requests
- [ ] Verify logs appear in Grafana

---

## Quick Metrics Dashboard (Terminal)

```bash
# Watch logs in real-time
tail -f ~/.local/share/godot/app_userdata/*/logs/security/audit_*.jsonl

# Count events by type
grep "event_type" audit_*.jsonl | sort | uniq -c

# Show last 10 security violations
grep "security_violation" audit_*.jsonl | tail -10

# Count failures per IP
grep "authentication_failure" audit_*.jsonl | \
  grep -o '"ip_address":"[^"]*"' | sort | uniq -c
```

---

## Support

**Full Documentation:** `docs/security/AUDIT_LOGGING_IMPLEMENTATION.md`

**Tools:**
- Analyzer: `scripts/security/audit_log_analyzer.py`
- Dashboard: `monitoring/grafana/dashboards/security_audit.json`

**Tests:**
- GDScript: `tests/security/test_audit_logging.gd`
- Python: `tests/security/test_audit_analyzer.py`

**Questions?** Check the implementation guide or review `scene_router_with_audit.gd` for a complete example.

---

**END OF QUICK REFERENCE**
