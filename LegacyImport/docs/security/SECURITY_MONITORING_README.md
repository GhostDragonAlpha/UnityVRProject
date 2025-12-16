# Security Monitoring - Quick Start

## Overview

Complete Prometheus/Grafana monitoring integration for SpaceTime VR security systems.

## Features

- **Real-time Security Metrics**: Sub-second latency for threat detection
- **Comprehensive Dashboards**: 3 specialized Grafana dashboards
- **Intelligent Alerting**: 20+ critical security alerts with runbooks
- **<1% Overhead**: Minimal performance impact
- **Production-Ready**: Full SLA definitions and incident procedures

## Quick Start

### 1. Initialize Security Metrics

```gdscript
# In GodotBridge or main autoload _ready()
extends Node

var security_metrics_exporter: SecurityMetricsExporter

func _ready():
    # Create security metrics exporter
    security_metrics_exporter = SecurityMetricsExporter.new()

    # Connect to instrumented security components
    HttpApiSecurityConfigInstrumented.set_metrics_exporter(security_metrics_exporter)
    HttpApiAuditLoggerInstrumented.set_metrics_exporter(security_metrics_exporter)

    # For TokenManager (if using instrumented version)
    var token_manager = HttpApiTokenManagerInstrumented.new()
    token_manager.set_metrics_exporter(security_metrics_exporter)

    print("[Security] Metrics exporter initialized")
```

### 2. Add Metrics Endpoint

```gdscript
# In your HTTP API handler
func handle_metrics_request() -> Dictionary:
    var metrics_output = ""

    # Add general HTTP metrics
    if metrics_exporter:
        metrics_output += metrics_exporter.export_metrics()

    # Add security metrics
    if security_metrics_exporter:
        metrics_output += security_metrics_exporter.export_metrics()

    return {
        "status": 200,
        "headers": {"Content-Type": "text/plain; version=0.0.4"},
        "body": metrics_output
    }
```

### 3. Configure Prometheus

```yaml
# monitoring/prometheus/prometheus.yml
scrape_configs:
  - job_name: 'godot_security'
    scrape_interval: 15s
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
```

### 4. Load Alert Rules

```yaml
# monitoring/prometheus/prometheus.yml
rule_files:
  - 'prometheus_alerts.yml'
  - 'security_alerts.yml'  # New security alerts
```

### 5. Import Grafana Dashboards

1. Open Grafana (http://localhost:3000)
2. Go to Dashboards → Import
3. Import each dashboard JSON:
   - `monitoring/grafana/dashboards/security_overview.json`
   - `monitoring/grafana/dashboards/authentication.json`
   - `monitoring/grafana/dashboards/threat_intelligence.json`

### 6. Verify Setup

```bash
# Test metrics endpoint
curl http://localhost:8080/metrics | grep security

# Expected output:
# authentication_attempts_total{result="success"} 123
# intrusion_threat_score{ip="127.0.0.1"} 0.00
# security_check_duration_ms{quantile="0.95"} 2.50
```

## File Structure

```
C:/godot/
├── scripts/security/
│   ├── security_metrics_exporter.gd       # Core metrics collector
│   ├── token_manager_instrumented.gd      # Instrumented TokenManager
│   ├── security_config_instrumented.gd    # Instrumented SecurityConfig
│   └── audit_logger_instrumented.gd       # Instrumented AuditLogger
│
├── monitoring/
│   ├── grafana/dashboards/
│   │   ├── security_overview.json         # Main security dashboard
│   │   ├── authentication.json            # Auth & token dashboard
│   │   └── threat_intelligence.json       # Threat & attack dashboard
│   │
│   └── prometheus/
│       └── security_alerts.yml            # Security alert rules
│
└── docs/security/
    ├── SECURITY_MONITORING_GUIDE.md       # Complete guide (40+ pages)
    └── SECURITY_MONITORING_README.md      # This file
```

## Key Metrics

### Authentication
- `authentication_attempts_total{result}` - Auth attempts by result
- `authentication_active_tokens` - Current active tokens
- `authentication_token_operations_total{operation}` - Token lifecycle events

### Threats
- `intrusion_threat_score{ip}` - IP threat scores (0-100)
- `intrusion_active_threats` - High-threat IPs (score >= 50)
- `intrusion_attack_patterns_detected{pattern}` - Attack types

### Rate Limiting
- `rate_limit_violations_total{endpoint}` - Violations by endpoint
- `rate_limit_active_bans` - Currently banned IPs
- `rate_limit_bans_total` - Total bans issued

### Validation
- `input_validation_failures_total{type}` - Injection attempts by type
- `security_events_total{severity,type}` - Security events
- `security_incidents_total` - High-severity incidents

### Performance
- `security_check_duration_ms{quantile}` - Latency percentiles

## Dashboards

### Security Overview
**UID**: `security-overview`
**Purpose**: High-level security health and incidents
**Refresh**: 5 seconds
**Key Panels**:
- Authentication success rate
- Active threats and bans
- Top attacked endpoints
- Security event timeline
- Threat IP table

### Authentication
**UID**: `security-authentication`
**Purpose**: Authentication and token lifecycle
**Refresh**: 5 seconds
**Key Panels**:
- Auth success rate gauge
- Failed auth attempts
- Token operations
- Top failing IPs
- Token lifecycle trends

### Threat Intelligence
**UID**: `security-threat-intelligence`
**Purpose**: Threat detection and attack analysis
**Refresh**: 10 seconds
**Key Panels**:
- IP reputation scores
- Attack patterns
- Validation failures
- Block reasons
- Threat trends

## Alerts

### Critical (Immediate Response)
- `BruteForceAttackDetected` - > 10 failed auth/sec
- `PrivilegeEscalationAttempt` - Any privilege escalation
- `SQLInjectionAttempt` - SQL injection detected
- `CommandInjectionAttempt` - Command injection detected
- `HighThreatScoreDetected` - IP score > 80
- `SecurityIncidentSpike` - Incident rate spike

### High (Urgent Response)
- `HighRateLimitViolations` - Excessive rate limiting
- `XSSAttemptDetected` - XSS injection attempts
- `PathTraversalAttempt` - Path traversal detected
- `HighAuthenticationFailureRate` - Auth failure > 50%
- `MultipleActiveThreats` - > 5 active threats

### Medium (Monitor)
- `NewIPBan` - IP ban issued
- `UnusualAccessPattern` - Anomalies detected
- `TokenRevocationSpike` - Many tokens revoked
- `ValidationFailuresIncreasing` - Rising validation failures

## Common Tasks

### Record Authentication Attempt
```gdscript
HttpApiSecurityConfigInstrumented.validate_auth(headers, client_ip)
# Automatically records authentication_attempts_total
```

### Record Security Event
```gdscript
security_metrics_exporter.record_security_event(
    "critical",                    # Severity
    "sql_injection_attempt",       # Event type
    {                              # Details
        "endpoint": "/api/users",
        "pattern": "' OR '1'='1"
    }
)
```

### Update Threat Score
```gdscript
security_metrics_exporter.set_threat_score(client_ip, 75.0)
# Updates intrusion_threat_score{ip="..."}
```

### Record Rate Limit Violation
```gdscript
HttpApiSecurityConfigInstrumented.check_rate_limit(client_ip, endpoint)
# Automatically records rate_limit_violations_total
```

### Record Input Validation Failure
```gdscript
HttpApiSecurityConfigInstrumented.check_sql_injection(input, client_ip)
# Automatically records input_validation_failures_total{type="sql_injection"}
```

## Performance

### Overhead Targets
- Metric recording: < 0.1ms per event
- Security check overhead: < 1% total request time
- Memory footprint: < 10MB for metrics storage
- P95 security check latency: < 25ms
- P99 security check latency: < 50ms

### Optimization
- Metrics stored in efficient hash tables
- Top-N limiting for IP-based metrics
- Automatic sampling for geographic data
- Periodic cleanup of old threat scores

## SLA Compliance

### Authentication SLA
- **Target**: 95% success rate
- **Measurement**: 5-minute rolling window
- **Violation**: < 95% for 15 minutes

### Performance SLA
- **Target**: P95 < 25ms for security checks
- **Measurement**: Real-time percentile calculation
- **Violation**: > 25ms for 30 minutes

### Threat Response SLA
- **Target**: Critical threats blocked in < 5 minutes
- **Measurement**: Manual incident tracking
- **Violation**: > 5 minutes to block

## Troubleshooting

### No Metrics in Prometheus
```bash
# Check metrics endpoint
curl http://localhost:8080/metrics | grep authentication

# Verify exporter is initialized
# Should see in Godot console:
# [Security] Metrics exporter initialized
# [SecurityConfigInstrumented] Metrics exporter connected
```

### High Latency
```bash
# Check P95 latency
curl -s http://localhost:9090/api/v1/query?query=security_check_duration_ms{quantile=\"0.95\"}

# Profile security checks
# Add timing logs to hot paths
```

### False Positive Alerts
- Review `security_alerts.yml` thresholds
- Adjust based on baseline metrics
- Whitelist internal IPs
- Tune validation rules

## Documentation

- **Full Guide**: `docs/security/SECURITY_MONITORING_GUIDE.md` (40+ pages)
  - Complete metric reference
  - Dashboard usage guide
  - Alert response procedures
  - SLA definitions
  - Troubleshooting

- **API Reference**: See inline code documentation in:
  - `scripts/security/security_metrics_exporter.gd`
  - `scripts/security/*_instrumented.gd`

## Support

For issues or questions:
1. Check the full guide: `SECURITY_MONITORING_GUIDE.md`
2. Review dashboard panels and queries
3. Check Prometheus metrics directly
4. Review audit logs: `user://logs/http_api_audit.log`

## Version

- **Version**: 1.0
- **Date**: 2025-12-02
- **Compatibility**: Godot 4.5+, Prometheus 2.40+, Grafana 9.0+
