# Production Hardening Guide

Complete guide for hardening SpaceTime VR for production deployment.

## Table of Contents

- [Overview](#overview)
- [Pre-Deployment Checklist](#pre-deployment-checklist)
- [Security Hardening](#security-hardening)
- [Network Security](#network-security)
- [Authentication & Authorization](#authentication--authorization)
- [Encryption & TLS](#encryption--tls)
- [Input Validation](#input-validation)
- [Rate Limiting & DDoS Protection](#rate-limiting--ddos-protection)
- [Intrusion Detection](#intrusion-detection)
- [Logging & Auditing](#logging--auditing)
- [Secrets Management](#secrets-management)
- [Performance Optimization](#performance-optimization)
- [Monitoring & Alerting](#monitoring--alerting)
- [Backup & Disaster Recovery](#backup--disaster-recovery)
- [Compliance & Privacy](#compliance--privacy)
- [Incident Response](#incident-response)
- [Post-Deployment Verification](#post-deployment-verification)

---

## Overview

This guide provides comprehensive steps for hardening SpaceTime VR for production deployment. Follow all sections to ensure maximum security, reliability, and performance.

**Target Audience:** DevOps engineers, security engineers, system administrators

**Prerequisites:**
- SpaceTime VR installed and configured
- Access to production environment
- SSL/TLS certificates
- Secrets management solution (Vault, AWS Secrets Manager, etc.)

---

## Pre-Deployment Checklist

Before deploying to production, ensure:

### Configuration

- [ ] Production configuration file created (`config/production.json`)
- [ ] Security hardening profile applied (`config/security_production.json`)
- [ ] All environment variables defined in `.env` (not committed to git)
- [ ] Configuration validated: `python scripts/validate_config.py production --strict`
- [ ] No hardcoded secrets in configuration files
- [ ] Scene whitelist contains only production scenes

### Security

- [ ] TLS/SSL certificates installed and valid
- [ ] Authentication enabled with strong tokens
- [ ] Token rotation configured
- [ ] Rate limiting enabled
- [ ] Intrusion detection enabled
- [ ] Audit logging enabled
- [ ] Security headers configured
- [ ] CORS properly restricted
- [ ] Debug endpoints disabled

### Infrastructure

- [ ] Database configured with connection pooling
- [ ] Redis cache configured and secured
- [ ] Load balancer configured (if HA enabled)
- [ ] Firewall rules configured
- [ ] Network segmentation in place
- [ ] Backups configured and tested
- [ ] Monitoring configured
- [ ] Alerting configured with escalation

### Testing

- [ ] Staging environment tested
- [ ] Load testing completed
- [ ] Security scanning completed
- [ ] Penetration testing completed
- [ ] Disaster recovery tested
- [ ] Rollback procedure documented

---

## Security Hardening

### 1. Minimal Attack Surface

**Disable Unnecessary Services:**

```json
{
  "networking": {
    "dap": {
      "enabled": false
    },
    "lsp": {
      "enabled": false
    },
    "discovery": {
      "enabled": false
    }
  }
}
```

**Minimal Scene Whitelist:**

```json
{
  "security": {
    "scene_validation": {
      "whitelist_enabled": true,
      "environment": "production",
      "allow_test_scenes": false,
      "allow_component_scenes": false
    }
  }
}
```

Edit `config/scene_whitelist.json`:

```json
{
  "environments": {
    "production": {
      "scenes": [
        "res://vr_main.tscn"
      ],
      "directories": [],
      "wildcards": []
    }
  }
}
```

### 2. Security Headers

Enable all security headers:

```json
{
  "security": {
    "headers": {
      "enable_security_headers": true,
      "enable_cors": false,
      "enable_csp": true,
      "enable_hsts": true,
      "hsts_max_age_seconds": 31536000,
      "hsts_include_subdomains": true,
      "hsts_preload": true,
      "x_frame_options": "DENY",
      "x_content_type_options": "nosniff",
      "x_xss_protection": "1; mode=block",
      "referrer_policy": "strict-origin-when-cross-origin"
    }
  }
}
```

### 3. Input Validation

Strict input validation:

```json
{
  "security": {
    "input_validation": {
      "max_request_size_bytes": 524288,
      "max_scene_path_length": 128,
      "max_header_size_bytes": 8192,
      "max_query_params": 20,
      "max_json_depth": 5,
      "sanitize_inputs": true,
      "validate_json_schema": true,
      "reject_malformed_requests": true,
      "normalize_unicode": true,
      "strip_null_bytes": true,
      "validate_content_type": true,
      "allowed_content_types": [
        "application/json",
        "text/plain"
      ]
    }
  }
}
```

---

## Network Security

### 1. Firewall Configuration

**Inbound Rules:**

```bash
# Allow HTTPS only
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Allow HTTP (redirect to HTTPS)
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Allow WebSocket (TLS)
iptables -A INPUT -p tcp --dport 8081 -j ACCEPT

# Allow health checks from load balancer
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 8080 -j ACCEPT

# Drop all other inbound
iptables -A INPUT -j DROP
```

**Outbound Rules:**

```bash
# Allow DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

# Allow HTTPS
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# Allow database
iptables -A OUTPUT -p tcp --dport 5432 -j ACCEPT

# Allow Redis
iptables -A OUTPUT -p tcp --dport 6379 -j ACCEPT

# Drop all other outbound
iptables -A OUTPUT -j DROP
```

### 2. Network Segmentation

Separate networks for different components:

```
Production Network (172.20.0.0/24)
├── Application Servers (172.20.0.10-50)
├── Load Balancers (172.20.0.51-60)
└── Monitoring (172.20.0.61-70)

Database Network (172.21.0.0/24)
├── PostgreSQL Primary (172.21.0.10)
├── PostgreSQL Replica (172.21.0.11)
└── Redis (172.21.0.20)

Management Network (172.22.0.0/24)
├── Bastion Hosts (172.22.0.10)
└── Monitoring/Logging (172.22.0.20-30)
```

### 3. DDoS Protection

Enable DDoS protection:

```json
{
  "network_security": {
    "ddos_protection": {
      "enabled": true,
      "connection_limit_per_ip": 10,
      "new_connection_rate_limit": 5,
      "syn_flood_protection": true,
      "slowloris_protection": true,
      "http_flood_threshold": 100
    }
  }
}
```

**External DDoS Protection:**
- Use Cloudflare, AWS Shield, or similar
- Enable rate limiting at CDN/edge
- Geographic restrictions if applicable

---

## Authentication & Authorization

### 1. Strong Token Generation

Generate cryptographically secure tokens:

```bash
# 256-bit random token
openssl rand -base64 32

# Store in secrets manager
vault kv put secret/spacetime/production/api-token value="$(openssl rand -base64 32)"
```

### 2. Token Rotation

Enable automatic token rotation:

```json
{
  "security": {
    "authentication": {
      "token_rotation_enabled": true,
      "token_rotation_interval_hours": 24,
      "token_refresh_enabled": true,
      "token_refresh_window_hours": 2
    }
  }
}
```

**Rotation Schedule:**
- Production: Every 24-72 hours
- Staging: Every 7 days
- Development: Disabled

### 3. RBAC Configuration

Assign minimal required roles:

```json
{
  "security": {
    "authorization": {
      "rbac_enabled": true,
      "default_role": "readonly",
      "enforce_permissions": true,
      "deny_by_default": true,
      "escalation_detection_enabled": true
    }
  }
}
```

**Role Assignment Best Practices:**
- Monitoring tools → `readonly`
- External APIs → `api_client`
- CI/CD pipelines → `developer` (staging only)
- Administrators → `admin` (audit all actions)

### 4. Session Management

Secure session configuration:

```json
{
  "security": {
    "authentication": {
      "session_timeout_minutes": 30,
      "max_concurrent_sessions": 1,
      "enforce_unique_tokens": true
    }
  }
}
```

---

## Encryption & TLS

### 1. TLS Configuration

**Minimum TLS 1.3:**

```json
{
  "security": {
    "encryption": {
      "tls_enabled": true,
      "tls_version_min": "1.3",
      "tls_ciphers": [
        "TLS_AES_256_GCM_SHA384",
        "TLS_CHACHA20_POLY1305_SHA256",
        "TLS_AES_128_GCM_SHA256"
      ],
      "websocket_tls_enabled": true
    }
  }
}
```

### 2. Certificate Management

**Generate Certificate:**

```bash
# Self-signed (testing only)
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout key.pem -out cert.pem \
  -subj "/CN=spacetime.example.com"

# Production: Use Let's Encrypt or commercial CA
certbot certonly --standalone -d spacetime.example.com
```

**Certificate Renewal:**

```bash
# Automatic renewal with certbot
certbot renew --deploy-hook "systemctl reload nginx"

# Add to crontab
0 0 * * * certbot renew --quiet
```

### 3. HTTPS Enforcement

**Nginx Configuration:**

```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name spacetime.example.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name spacetime.example.com;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/spacetime.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/spacetime.example.com/privkey.pem;
    ssl_protocols TLSv1.3;
    ssl_ciphers 'TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256';
    ssl_prefer_server_ciphers on;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## Input Validation

### 1. Request Size Limits

Strict size limits to prevent abuse:

```json
{
  "security": {
    "input_validation": {
      "max_request_size_bytes": 524288,
      "max_scene_path_length": 128,
      "max_header_size_bytes": 8192
    }
  }
}
```

### 2. Content Type Validation

Only allow expected content types:

```json
{
  "security": {
    "input_validation": {
      "validate_content_type": true,
      "allowed_content_types": [
        "application/json",
        "text/plain"
      ]
    }
  }
}
```

### 3. Path Traversal Prevention

Enable path validation:

```json
{
  "security": {
    "scene_validation": {
      "require_path_validation": true,
      "check_file_exists": true,
      "validate_scene_integrity": true
    }
  }
}
```

---

## Rate Limiting & DDoS Protection

### 1. Global Rate Limits

Conservative limits for production:

```json
{
  "security": {
    "rate_limiting": {
      "enabled": true,
      "global_requests_per_minute": 100,
      "burst_multiplier": 1.0,
      "ban_duration_minutes": 120
    }
  }
}
```

### 2. Endpoint-Specific Limits

Protect expensive endpoints:

```json
{
  "security": {
    "rate_limiting": {
      "per_endpoint_limits": {
        "/scene": 5,
        "/scene/reload": 2,
        "/scene/load": 5,
        "/admin": 3,
        "/admin/security": 1,
        "/debug": 0,
        "/execute": 0
      }
    }
  }
}
```

### 3. Progressive Banning

Escalate bans for repeat offenders:

```json
{
  "security": {
    "rate_limiting": {
      "progressive_ban_enabled": true,
      "ban_escalation_multiplier": 2.0,
      "max_ban_duration_hours": 24
    }
  }
}
```

**Ban Schedule:**
1. First offense: 1 hour
2. Second offense: 2 hours
3. Third offense: 4 hours
4. Fourth offense: 8 hours
5. Fifth+ offense: 24 hours

---

## Intrusion Detection

### 1. Enable IDS

Full IDS configuration:

```json
{
  "security": {
    "intrusion_detection": {
      "enabled": true,
      "threat_score_threshold": 50,
      "auto_ban_enabled": true,
      "alert_enabled": true,
      "monitoring_mode_only": false
    }
  }
}
```

### 2. Detection Rules

Configure detection rules in `config/ids_rules.json`. Key rules to enable:

- SQL injection detection
- Command injection detection
- Path traversal detection
- XSS attempt detection
- Brute force detection
- Session hijacking detection
- Privilege escalation detection

### 3. Threat Intelligence

Enable threat intelligence feeds:

```json
{
  "threat_intelligence": {
    "ip_reputation_enabled": true,
    "tor_exit_node_blocking": true,
    "vpn_detection_enabled": true,
    "known_bot_blocking": true,
    "update_interval_hours": 6
  }
}
```

### 4. Behavioral Analysis

Enable anomaly detection:

```json
{
  "behavioral_analysis": {
    "enabled": true,
    "baseline_learning_days": 7,
    "anomaly_threshold": 2.5,
    "detect_unusual_hours": true,
    "detect_unusual_locations": true
  }
}
```

---

## Logging & Auditing

### 1. Production Logging

Minimal, structured logging:

```json
{
  "logging": {
    "level": "warn",
    "format": "json",
    "output": ["file"],
    "file_path": "/var/log/spacetime/production.log",
    "max_file_size_mb": 100,
    "max_files": 30,
    "rotation_strategy": "time",
    "log_performance_metrics": true,
    "log_security_events": true,
    "log_api_requests": false,
    "log_api_responses": false
  }
}
```

**Important:** Never log:
- Passwords or tokens
- PII (personally identifiable information)
- Full request/response bodies
- Sensitive user data

### 2. Audit Logging

Comprehensive audit logging:

```json
{
  "logging": {
    "audit_log_enabled": true,
    "audit_log_path": "/var/log/spacetime/audit_production.log"
  },
  "security": {
    "audit": {
      "enabled": true,
      "log_all_requests": true,
      "log_authentication_events": true,
      "log_authorization_failures": true,
      "log_security_events": true,
      "log_admin_actions": true,
      "log_configuration_changes": true,
      "retention_days": 365,
      "tamper_protection": true,
      "encrypt_audit_logs": true,
      "forward_to_siem": true
    }
  }
}
```

### 3. Log Forwarding

Forward logs to centralized SIEM:

```bash
# Filebeat configuration
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/spacetime/*.log
  fields:
    service: spacetime
    environment: production

output.logstash:
  hosts: ["logstash.example.com:5044"]
  ssl.certificate_authorities: ["/etc/pki/tls/certs/ca.pem"]
```

---

## Secrets Management

### 1. HashiCorp Vault Integration

Store all secrets in Vault:

```bash
# Initialize Vault
vault kv put secret/spacetime/production/database \
  host="db.example.com" \
  username="spacetime" \
  password="$(openssl rand -base64 32)"

vault kv put secret/spacetime/production/redis \
  host="redis.example.com" \
  password="$(openssl rand -base64 32)"

vault kv put secret/spacetime/production/api \
  token="$(openssl rand -base64 32)"
```

### 2. Configuration

Enable Vault in configuration:

```json
{
  "security": {
    "secrets_management": {
      "use_vault": true,
      "vault_address": "${VAULT_ADDR}",
      "vault_namespace": "spacetime",
      "auto_rotation_enabled": true,
      "rotation_interval_days": 30
    }
  }
}
```

### 3. Environment Variables

Never commit `.env` files. Generate at deploy time:

```bash
#!/bin/bash
# deploy_secrets.sh

# Fetch from Vault
export DB_HOST=$(vault kv get -field=host secret/spacetime/production/database)
export DB_USER=$(vault kv get -field=username secret/spacetime/production/database)
export DB_PASSWORD=$(vault kv get -field=password secret/spacetime/production/database)
export API_TOKEN=$(vault kv get -field=token secret/spacetime/production/api)

# Write to .env (ephemeral, not committed)
cat > .env <<EOF
DB_HOST=$DB_HOST
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
API_TOKEN=$API_TOKEN
EOF

# Set restrictive permissions
chmod 600 .env
```

---

## Performance Optimization

### 1. Use Performance Profile

Load performance-optimized configuration:

```json
{
  "$schema": "./config_schema.json",
  "extends": ["production.json", "performance_production.json"]
}
```

### 2. Caching Strategy

Aggressive caching:

```json
{
  "cache": {
    "enabled": true,
    "type": "redis",
    "ttl_seconds": 3600,
    "max_size_mb": 1024,
    "eviction_policy": "lru"
  },
  "performance": {
    "caching": {
      "shader_cache_enabled": true,
      "mesh_cache_enabled": true,
      "texture_cache_enabled": true,
      "scene_cache_enabled": true,
      "aggressive_preloading": true
    }
  }
}
```

### 3. Connection Pooling

Optimize database connections:

```json
{
  "database": {
    "pool_size": 50,
    "connection_pool_overflow": 20,
    "connection_pool_timeout_seconds": 30,
    "statement_cache_size": 1000,
    "prepared_statement_cache_enabled": true
  }
}
```

### 4. Worker Threads

Scale workers based on CPU cores:

```json
{
  "performance": {
    "worker_threads": {
      "http_workers": 16,
      "background_tasks": 8,
      "physics_threads": 4
    }
  }
}
```

**Formula:**
- HTTP workers: CPU cores × 2
- Background tasks: CPU cores
- Physics threads: CPU cores / 2

---

## Monitoring & Alerting

### 1. Prometheus Metrics

Enable comprehensive metrics:

```json
{
  "monitoring": {
    "metrics": {
      "enabled": true,
      "prometheus_enabled": true,
      "scrape_interval_seconds": 15,
      "retention_days": 30
    }
  }
}
```

### 2. Health Checks

Configure health checks for load balancer:

```json
{
  "monitoring": {
    "health_checks": {
      "enabled": true,
      "interval_seconds": 10,
      "timeout_seconds": 5,
      "failure_threshold": 3
    }
  },
  "high_availability": {
    "health_check_path": "/health",
    "health_check_interval_seconds": 10
  }
}
```

### 3. Alerting Rules

Critical alerts with escalation:

```json
{
  "monitoring": {
    "alerts": {
      "enabled": true,
      "channels": ["pagerduty", "slack", "email"],
      "error_threshold": 10,
      "warning_threshold": 50,
      "alert_cooldown_minutes": 5
    }
  }
}
```

**Alert Escalation:**

1. **Critical** → PagerDuty + Slack + Email (immediate)
2. **High** → Slack + Email (within 5 minutes)
3. **Medium** → Slack (within 15 minutes)
4. **Low** → Daily digest email

### 4. Key Metrics to Monitor

**Performance:**
- FPS (target: 90)
- Frame time (target: <11ms)
- Memory usage (alert: >90%)
- CPU usage (alert: >85%)

**Security:**
- Failed authentication attempts
- Rate limit violations
- IDS threat score
- Banned IPs count

**Availability:**
- Uptime percentage (target: 99.9%)
- Request success rate (target: >99%)
- Average response time (target: <100ms)
- Error rate (alert: >1%)

**Resources:**
- Database connection pool usage
- Cache hit rate (target: >80%)
- Queue depth
- Active connections

---

## Backup & Disaster Recovery

### 1. Backup Configuration

Daily automated backups:

```json
{
  "backup": {
    "enabled": true,
    "schedule_cron": "0 1 * * *",
    "retention_days": 30,
    "backup_path": "/var/backups/spacetime/",
    "compress_backups": true,
    "include_logs": true,
    "include_database": true
  }
}
```

### 2. Backup Strategy

**3-2-1 Rule:**
- 3 copies of data
- 2 different media types
- 1 offsite backup

**Implementation:**

```bash
#!/bin/bash
# backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/spacetime"
S3_BUCKET="s3://spacetime-backups"

# Database backup
pg_dump -h $DB_HOST -U $DB_USER spacetime_production | gzip > "$BACKUP_DIR/db_$DATE.sql.gz"

# Configuration backup
tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" /etc/spacetime/

# Logs backup
tar -czf "$BACKUP_DIR/logs_$DATE.tar.gz" /var/log/spacetime/

# Upload to S3 (offsite)
aws s3 sync $BACKUP_DIR $S3_BUCKET --sse AES256

# Cleanup old backups (keep 30 days)
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete
```

### 3. Disaster Recovery Plan

**RTO (Recovery Time Objective):** 4 hours
**RPO (Recovery Point Objective):** 24 hours

**Recovery Steps:**

1. **Assess Damage**
   - Identify failed components
   - Determine data loss extent
   - Notify stakeholders

2. **Restore Infrastructure**
   - Provision new servers
   - Restore network configuration
   - Configure load balancers

3. **Restore Data**
   ```bash
   # Restore database from backup
   gunzip -c db_20251202_010000.sql.gz | psql -h $DB_HOST -U $DB_USER spacetime_production

   # Restore configuration
   tar -xzf config_20251202_010000.tar.gz -C /etc/spacetime/
   ```

4. **Validate**
   - Run health checks
   - Verify data integrity
   - Test critical paths

5. **Resume Service**
   - Update DNS
   - Enable traffic
   - Monitor closely

### 4. Testing DR Plan

Test quarterly:

```bash
# DR test script
./test_disaster_recovery.sh

# Validates:
# - Backup restoration works
# - Services start correctly
# - Data integrity maintained
# - Performance acceptable
```

---

## Compliance & Privacy

### 1. GDPR Compliance

Enable GDPR mode:

```json
{
  "security": {
    "compliance": {
      "gdpr_mode": true,
      "data_residency_region": "EU",
      "pii_encryption_required": true,
      "data_retention_days": 90,
      "right_to_erasure_enabled": true,
      "consent_tracking_enabled": true
    }
  }
}
```

### 2. Data Classification

Classify data by sensitivity:

- **Public** - VR scenes, public assets
- **Internal** - Telemetry, performance metrics
- **Confidential** - User data, API tokens
- **Restricted** - PII, audit logs

### 3. Data Retention

Implement retention policies:

```json
{
  "logging": {
    "audit_log_enabled": true,
    "retention_days": 365
  },
  "security": {
    "compliance": {
      "data_retention_days": 90
    }
  }
}
```

### 4. Right to Erasure

Provide data deletion endpoints:

```bash
# Delete user data
curl -X DELETE https://api.spacetime.example.com/api/v2/user/123/data \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Verify deletion in audit log
grep "user_data_deleted" /var/log/spacetime/audit_production.log
```

---

## Incident Response

### 1. Incident Response Plan

**Phase 1: Detection (0-5 minutes)**
- Alert received via PagerDuty/Slack
- Incident commander assigned
- War room established (Slack channel)

**Phase 2: Assessment (5-15 minutes)**
- Determine severity (P1/P2/P3/P4)
- Identify affected systems
- Assess user impact

**Phase 3: Containment (15-60 minutes)**
- Isolate affected systems
- Block malicious IPs
- Disable compromised accounts

**Phase 4: Eradication (1-4 hours)**
- Remove threat
- Patch vulnerabilities
- Restore from clean backups

**Phase 5: Recovery (4-24 hours)**
- Restore services
- Verify functionality
- Monitor for recurrence

**Phase 6: Post-Mortem (1-7 days)**
- Document timeline
- Root cause analysis
- Preventive measures
- Update runbooks

### 2. Security Incident Categories

**P1 - Critical**
- Data breach
- Service down >30 minutes
- Security compromise

**P2 - High**
- Service degraded
- Security vulnerability discovered
- Unauthorized access attempt

**P3 - Medium**
- Performance issues
- Non-critical bug
- Failed health check

**P4 - Low**
- Configuration issue
- Documentation update needed

### 3. Contact Information

Maintain updated contact list:

```yaml
incident_contacts:
  primary_on_call:
    name: "On-call Engineer"
    pagerduty: "+1-555-0100"
    email: "oncall@example.com"

  security_team:
    name: "Security Team"
    slack: "#security-incidents"
    email: "security@example.com"

  infrastructure_team:
    name: "Infrastructure Team"
    slack: "#infrastructure"
    email: "infrastructure@example.com"

  management:
    name: "CTO"
    phone: "+1-555-0101"
    email: "cto@example.com"
```

---

## Post-Deployment Verification

### 1. Security Verification

Run security checks:

```bash
# Validate configuration
python scripts/validate_config.py production --strict

# Test authentication
curl -H "Authorization: Bearer $API_TOKEN" \
  https://api.spacetime.example.com/status

# Test rate limiting
for i in {1..100}; do
  curl https://api.spacetime.example.com/scene
done
# Should be rate limited

# Test TLS
openssl s_client -connect spacetime.example.com:443 -tls1_3

# Check security headers
curl -I https://spacetime.example.com | grep -E "(Strict-Transport-Security|X-Frame-Options|X-Content-Type)"
```

### 2. Performance Verification

Load testing:

```bash
# Run load test
ab -n 10000 -c 100 https://api.spacetime.example.com/health

# Monitor metrics
curl http://localhost:9090/metrics | grep spacetime_

# Check database performance
psql -h $DB_HOST -U $DB_USER -c "SELECT * FROM pg_stat_activity"
```

### 3. Monitoring Verification

Verify monitoring:

```bash
# Check Prometheus targets
curl http://prometheus:9090/api/v1/targets

# Test alerting
curl -X POST http://alertmanager:9093/api/v2/alerts \
  -d '[{"labels":{"alertname":"TestAlert","severity":"critical"}}]'

# Check Grafana dashboards
curl http://admin:$GRAFANA_PASSWORD@grafana:3000/api/dashboards/home
```

### 4. Backup Verification

Test backup restoration:

```bash
# Restore to test environment
./restore_backup.sh test 20251202_010000

# Verify data integrity
./verify_backup.sh
```

---

## Maintenance Schedule

### Daily

- [ ] Review security alerts
- [ ] Check error logs
- [ ] Monitor performance metrics
- [ ] Verify backups completed

### Weekly

- [ ] Review audit logs
- [ ] Update threat intelligence feeds
- [ ] Check certificate expiry
- [ ] Rotate monitoring dashboard

### Monthly

- [ ] Security patch updates
- [ ] Token rotation (if not automated)
- [ ] Review user access
- [ ] Update documentation

### Quarterly

- [ ] Disaster recovery test
- [ ] Security audit
- [ ] Performance review
- [ ] Capacity planning

### Annually

- [ ] Penetration testing
- [ ] Compliance audit
- [ ] Architecture review
- [ ] Team training

---

## Additional Resources

- [CONFIG_REFERENCE.md](./CONFIG_REFERENCE.md) - Complete configuration reference
- [TLS_SETUP.md](../TLS_SETUP.md) - TLS/SSL setup guide
- [TOKEN_MANAGEMENT.md](../TOKEN_MANAGEMENT.md) - Token management guide
- [MONITORING.md](../MONITORING.md) - Monitoring and alerting setup
- [ROLLBACK_PROCEDURES.md](../ROLLBACK_PROCEDURES.md) - Rollback procedures

---

## Support

For production support:

- **Email:** production-support@example.com
- **Slack:** #spacetime-production
- **PagerDuty:** +1-555-0100
- **Documentation:** https://docs.spacetime.example.com

---

## Version History

- **1.0.0** (2025-12-02) - Initial production hardening guide
