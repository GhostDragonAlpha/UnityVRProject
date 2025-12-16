# Security Operations Runbooks

**SpaceTime VR Project - Security Operations Manual**
**Version:** 2.0.0
**Last Updated:** 2025-12-02
**Owner:** Security Operations Team

## Table of Contents

1. [Overview](#overview)
2. [Quick Reference](#quick-reference)
3. [Authentication Operations](#authentication-operations)
4. [Authorization Operations](#authorization-operations)
5. [Incident Response](#incident-response)
6. [Threat Management](#threat-management)
7. [Audit and Compliance](#audit-and-compliance)
8. [Monitoring and Alerting](#monitoring-and-alerting)
9. [Backup and Recovery](#backup-and-recovery)
10. [Emergency Procedures](#emergency-procedures)

---

## Overview

### Purpose
This runbook provides step-by-step operational procedures for managing the SpaceTime VR security infrastructure in production. All procedures are designed to be executed under pressure during security incidents.

### Security System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Security System Layer                   │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Token      │  │     RBAC     │  │    Audit     │ │
│  │  Manager     │  │   Manager    │  │   Logger     │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Intrusion   │  │   Threat     │  │   Security   │ │
│  │  Detection   │  │  Responder   │  │   Monitor    │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Key Ports and Services

| Service | Port | Purpose |
|---------|------|---------|
| HTTP API | 8080 | REST API and control plane |
| Telemetry | 8081 | Real-time security events |
| DAP | 6006 | Debug adapter protocol |
| LSP | 6005 | Language server protocol |

### Essential URLs

- **Prometheus:** http://localhost:9090
- **Grafana:** http://localhost:3000
- **AlertManager:** http://localhost:9093
- **API Status:** http://127.0.0.1:8080/status

---

## Quick Reference

### Critical Commands

```bash
# Emergency - Stop all security threats
curl -X POST http://127.0.0.1:8080/admin/security/emergency_lockdown

# View security status
curl http://127.0.0.1:8080/admin/security/status

# Ban IP immediately
curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
  -H "Content-Type: application/json" \
  -d '{"ip": "1.2.3.4", "permanent": true, "reason": "Security incident"}'

# Revoke all tokens
curl -X POST http://127.0.0.1:8080/admin/tokens/revoke_all

# View active threats
curl http://127.0.0.1:8080/admin/security/threats/active

# Export audit logs
curl http://127.0.0.1:8080/admin/audit/export > audit_$(date +%Y%m%d_%H%M%S).jsonl
```

### Severity Levels

| Level | Response Time | Examples |
|-------|---------------|----------|
| **P0 - CRITICAL** | <5 minutes | Active breach, data exfiltration, system compromise |
| **P1 - HIGH** | <15 minutes | Brute force attack, SQL injection attempts, privilege escalation |
| **P2 - MEDIUM** | <1 hour | Rate limit violations, suspicious patterns, failed authentications |
| **P3 - LOW** | <4 hours | Off-hours access, unusual user agents, informational alerts |

---

## Authentication Operations

### Token Lifecycle Management

#### 1. Generate New API Token

**When to use:** Onboarding new service, rotating compromised token

**Procedure:**
```bash
# Generate token (default 720 hours / 30 days)
curl -X POST http://127.0.0.1:8080/admin/tokens/generate \
  -H "Content-Type: application/json" \
  -d '{"lifetime_hours": 720}'

# Save response
# {
#   "success": true,
#   "token": {
#     "token_id": "tok_abc123...",
#     "token_secret": "secret_xyz789...",
#     "created_at": 1234567890,
#     "expires_at": 1237159890
#   }
# }
```

**Post-generation steps:**
1. Store `token_secret` in secure vault (1Password, AWS Secrets Manager)
2. Assign appropriate role (see Authorization section)
3. Document token purpose in inventory
4. Set calendar reminder for expiration
5. Provide token to service owner via secure channel

**Security considerations:**
- NEVER store tokens in plain text
- NEVER commit tokens to Git
- Use shortest lifetime appropriate for use case
- Monitor token usage after creation

#### 2. Validate Token

**When to use:** Troubleshooting authentication issues, verifying token status

**Procedure:**
```bash
# Validate token
curl -X POST http://127.0.0.1:8080/admin/tokens/validate \
  -H "Content-Type: application/json" \
  -d '{"token_secret": "secret_xyz789..."}'

# Response for valid token:
# {
#   "valid": true,
#   "token": {
#     "token_id": "tok_abc123...",
#     "created_at": 1234567890,
#     "expires_at": 1237159890,
#     "last_used": 1235000000,
#     "use_count": 42,
#     "revoked": false
#   }
# }

# Response for invalid token:
# {
#   "valid": false,
#   "error": "Token not found or expired"
# }
```

**Troubleshooting:**
- **Token not found:** Token may be revoked or never existed
- **Token expired:** Generate new token and update service
- **Token revoked:** Check audit logs for revocation reason

#### 3. Rotate Token

**When to use:** Regular rotation schedule, suspected compromise, security best practice

**Procedure:**
```bash
# Rotate token (creates new token, marks old as revoked)
curl -X POST http://127.0.0.1:8080/admin/tokens/rotate \
  -H "Content-Type: application/json" \
  -d '{"current_token_secret": "secret_old..."}'

# Response:
# {
#   "success": true,
#   "new_token": {
#     "token_id": "tok_new123...",
#     "token_secret": "secret_new789...",
#     "created_at": 1234567890,
#     "expires_at": 1237159890
#   },
#   "old_token_id": "tok_abc123..."
# }
```

**Rotation workflow:**
1. Execute rotation command
2. Update service configuration with new token
3. Test service functionality with new token
4. Monitor for authentication errors
5. Old token remains valid for 5 minutes grace period
6. Document rotation in change log

**Rollback procedure (if needed within grace period):**
```bash
# The old token remains usable for 5 minutes
# If service fails, revert configuration temporarily
# Generate new token and retry
```

#### 4. Refresh Token Expiration

**When to use:** Extending lifetime of active token without rotation

**Procedure:**
```bash
# Extend token lifetime by 720 hours (30 days)
curl -X POST http://127.0.0.1:8080/admin/tokens/refresh \
  -H "Content-Type: application/json" \
  -d '{"token_secret": "secret_xyz789...", "extension_hours": 720}'

# Response:
# {
#   "success": true,
#   "token": {
#     "token_id": "tok_abc123...",
#     "expires_at": 1240000000  # New expiration
#   }
# }
```

**When NOT to use:**
- Token is compromised → Use revoke + generate instead
- Regular rotation schedule → Use rotate instead
- Token architecture change needed → Generate new token

#### 5. Revoke Token (Emergency)

**When to use:** Token compromise, security incident, immediate access termination

**Procedure:**
```bash
# Revoke single token
curl -X POST http://127.0.0.1:8080/admin/tokens/revoke \
  -H "Content-Type: application/json" \
  -d '{"token_secret": "secret_xyz789...", "reason": "Compromised in security incident INC-12345"}'

# Verify revocation
curl -X POST http://127.0.0.1:8080/admin/tokens/validate \
  -H "Content-Type: application/json" \
  -d '{"token_secret": "secret_xyz789..."}'
# Should return: {"valid": false, "error": "Token has been revoked"}
```

**Post-revocation steps:**
1. Verify service stops functioning
2. Generate replacement token if needed
3. Update security incident documentation
4. Review audit logs for token usage
5. Notify stakeholders
6. Update token inventory

#### 6. Revoke All Tokens (Nuclear Option)

**When to use:** Major security breach, suspected system-wide compromise

⚠️ **WARNING:** This will break ALL integrations and services

**Procedure:**
```bash
# 1. Notify all stakeholders FIRST
# 2. Execute mass revocation
curl -X POST http://127.0.0.1:8080/admin/tokens/revoke_all \
  -H "Content-Type: application/json" \
  -d '{"confirmation": "REVOKE_ALL", "reason": "Security incident INC-12345"}'

# 3. Verify all tokens revoked
curl http://127.0.0.1:8080/admin/tokens/stats
# Should show: active_tokens_count: 0

# 4. Regenerate tokens for critical services
# See Token Generation procedure above
```

**Recovery workflow:**
1. Generate new tokens for production services (priority order)
2. Update service configurations
3. Test each service
4. Generate tokens for development/testing
5. Document incident and recovery
6. Review why mass revocation was necessary

#### 7. Token Inventory and Audit

**Procedure:**
```bash
# List all active tokens
curl http://127.0.0.1:8080/admin/tokens/list

# Get token statistics
curl http://127.0.0.1:8080/admin/tokens/stats
# Returns:
# {
#   "total_tokens_count": 15,
#   "active_tokens_count": 12,
#   "revoked_tokens_count": 3,
#   "expired_tokens_count": 0
# }

# Find tokens expiring soon (within 7 days)
curl http://127.0.0.1:8080/admin/tokens/expiring?days=7

# Get token usage analytics
curl http://127.0.0.1:8080/admin/tokens/usage_report
```

**Regular audit checklist (Monthly):**
- [ ] Review all active tokens
- [ ] Verify each token has documented purpose
- [ ] Check for tokens expiring in next 30 days
- [ ] Identify unused tokens (no usage in 30+ days)
- [ ] Revoke unnecessary tokens
- [ ] Update token inventory spreadsheet
- [ ] Schedule rotations for long-lived tokens

### User Authentication Troubleshooting

#### Failed Authentication Investigation

**Symptoms:** Users reporting login failures, authentication errors in logs

**Diagnostic procedure:**
```bash
# 1. Check authentication metrics
curl http://127.0.0.1:8080/metrics | grep auth_attempts

# 2. Check recent authentication failures
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{"event_type": "authentication", "result": "failure", "limit": 50}'

# 3. Check if IP is banned
curl http://127.0.0.1:8080/admin/security/bans/check?ip=<user_ip>

# 4. Check rate limiting status
curl http://127.0.0.1:8080/admin/security/rate_limits?ip=<user_ip>

# 5. Check token status if using API token
curl -X POST http://127.0.0.1:8080/admin/tokens/validate \
  -H "Content-Type: application/json" \
  -d '{"token_secret": "<token>"}'
```

**Common issues and resolutions:**

| Issue | Cause | Resolution |
|-------|-------|------------|
| Token expired | Token lifetime exceeded | Generate new token |
| Token revoked | Manual revocation or security incident | Generate new token, investigate revocation reason |
| IP banned | Brute force detection | Unban if legitimate, investigate if compromise |
| Rate limited | Too many requests | Wait for rate limit reset, increase limit if legitimate |
| Token not found | Invalid token or typo | Verify token string, generate new if needed |

---

## Authorization Operations

### Role Management

#### Available Roles

| Role | Permissions | Use Case |
|------|-------------|----------|
| **admin** | All permissions | System administrators, security team |
| **developer** | Read/write/debug/reload | Developers, DevOps |
| **api_client** | Read operations, controlled write | External integrations |
| **readonly** | Read-only access | Monitoring, reporting, auditing |

#### 1. Assign Role to Token

**Procedure:**
```bash
# Assign role to token
curl -X POST http://127.0.0.1:8080/admin/rbac/assign_role \
  -H "Content-Type: application/json" \
  -d '{
    "token_id": "tok_abc123...",
    "role_name": "developer",
    "assigned_by": "admin_user@example.com"
  }'

# Verify role assignment
curl http://127.0.0.1:8080/admin/rbac/get_role?token_id=tok_abc123...
# Returns: {"role_name": "developer", "assigned_at": 1234567890, ...}
```

**Role assignment matrix:**

| Service Type | Recommended Role | Justification |
|--------------|-----------------|---------------|
| CI/CD Pipeline | developer | Needs deploy, reload, config write |
| Monitoring System | readonly | Only needs metrics, status |
| Admin Dashboard | admin | Full control required |
| External API Integration | api_client | Limited write, no admin ops |
| Automated Testing | developer | Needs scene load, debug access |

**Security best practices:**
- Assign minimum required role (principle of least privilege)
- Document role assignment justification
- Regular access reviews (quarterly)
- Temporary elevated access for specific tasks, then downgrade

#### 2. Revoke Role / Downgrade Permissions

**Procedure:**
```bash
# Assign readonly role (effectively a downgrade)
curl -X POST http://127.0.0.1:8080/admin/rbac/assign_role \
  -H "Content-Type: application/json" \
  -d '{
    "token_id": "tok_abc123...",
    "role_name": "readonly",
    "assigned_by": "security_team@example.com"
  }'

# Verify downgrade
curl http://127.0.0.1:8080/admin/rbac/get_role?token_id=tok_abc123...
```

**When to downgrade:**
- Service no longer needs elevated permissions
- Security incident involving service
- Routine access review findings
- Service decommissioning preparation

#### 3. Permission Audit

**Procedure:**
```bash
# List all role assignments
curl http://127.0.0.1:8080/admin/rbac/list_assignments

# Get authorization metrics
curl http://127.0.0.1:8080/admin/rbac/metrics
# Returns:
# {
#   "total_roles": 4,
#   "total_role_assignments": 12,
#   "authorization_checks": 45678,
#   "authorization_success_rate": 94.5
# }

# Query authorization failures
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{"event_type": "authorization", "result": "failure", "limit": 100}'
```

**Monthly audit checklist:**
- [ ] Review all role assignments
- [ ] Verify role assignments match documentation
- [ ] Check for excessive admin role usage
- [ ] Identify authorization failures patterns
- [ ] Review and approve any new role assignments
- [ ] Update role assignment documentation

### Privilege Escalation Investigation

**Alert:** Authorization failure spike, admin endpoint access from non-admin token

**Investigation procedure:**

```bash
# 1. Identify source of privilege escalation attempts
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "authorization",
    "result": "failure",
    "limit": 100
  }' | jq '.[] | select(.details.permission | contains("ADMIN"))'

# 2. Get IP and token information
# Extract from audit results: token_id, IP address, endpoint

# 3. Check token role
curl http://127.0.0.1:8080/admin/rbac/get_role?token_id=<suspicious_token>

# 4. Review token usage history
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{
    "token_id": "<suspicious_token>",
    "limit": 500
  }'

# 5. If confirmed malicious, revoke token
curl -X POST http://127.0.0.1:8080/admin/tokens/revoke \
  -H "Content-Type: application/json" \
  -d '{
    "token_id": "<suspicious_token>",
    "reason": "Privilege escalation attempt detected"
  }'

# 6. Ban source IP
curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
  -H "Content-Type: application/json" \
  -d '{
    "ip": "<source_ip>",
    "permanent": true,
    "reason": "Privilege escalation attempt"
  }'
```

**Post-incident:**
1. Document timeline of events
2. Notify security team
3. Review how token was obtained
4. Check for other compromised tokens
5. Update incident response documentation
6. Consider additional security hardening

### RBAC Troubleshooting

#### User Cannot Access Endpoint

**Symptoms:** 403 Forbidden errors, "Insufficient permissions" messages

**Diagnostic steps:**

```bash
# 1. Identify the token being used
# (provided by user or from logs)

# 2. Check current role
curl http://127.0.0.1:8080/admin/rbac/get_role?token_id=<token_id>

# 3. Check required permission for endpoint
# See RBAC_IMPLEMENTATION.md for endpoint → permission mapping

# 4. Check if permission is granted to role
curl http://127.0.0.1:8080/admin/rbac/role_details?role_name=<role_name>

# 5. Check recent authorization attempts
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "authorization",
    "token_id": "<token_id>",
    "limit": 20
  }'
```

**Resolution flowchart:**

```
Is token valid?
  No → Generate new token
  Yes ↓

Does role have required permission?
  No → Assign appropriate role OR request business approval for role elevation
  Yes ↓

Check audit logs for specific error
  - Rate limited? → Wait or increase limits
  - IP banned? → Unban if legitimate
  - System error? → Check system logs
```

---

## Incident Response

### Incident Classification

#### P0 - CRITICAL (Response: <5 minutes)

**Characteristics:**
- Active system breach
- Data exfiltration in progress
- Complete system compromise
- Multiple simultaneous attacks
- Production outage due to security event

**Initial response:**
1. Page on-call security engineer (PagerDuty)
2. Activate incident command structure
3. Execute emergency lockdown if necessary
4. Open war room communication channel

#### P1 - HIGH (Response: <15 minutes)

**Characteristics:**
- Active attack (brute force, SQL injection)
- Privilege escalation attempts
- Suspicious admin access
- Multiple security alerts firing
- Potential data breach

**Initial response:**
1. Alert security team (Slack)
2. Begin investigation
3. Implement containment measures
4. Document actions taken

#### P2 - MEDIUM (Response: <1 hour)

**Characteristics:**
- Rate limit violations
- Suspicious patterns
- Multiple failed authentications
- Off-hours unusual activity
- Configuration issues

**Initial response:**
1. Investigate via dashboards
2. Review audit logs
3. Implement preventive measures
4. Monitor situation

#### P3 - LOW (Response: <4 hours)

**Characteristics:**
- Informational alerts
- Minor policy violations
- Single failed authentication
- Unusual but not malicious activity

**Initial response:**
1. Log for future analysis
2. Update metrics
3. Review during business hours

### Incident Response Workflow

```
┌─────────────────┐
│  Alert Fires    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Acknowledge   │  ← Start timer
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     Assess      │  ← Classify severity (P0-P3)
│   - Scope       │
│   - Impact      │
│   - Root cause  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Contain      │  ← Stop the bleeding
│   - Ban IPs     │
│   - Revoke      │
│   - Isolate     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Investigate   │  ← Root cause analysis
│   - Logs        │
│   - Metrics     │
│   - Timeline    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Resolve      │  ← Permanent fix
│   - Patch       │
│   - Config      │
│   - Deploy      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Document     │  ← Post-incident review
│   - Timeline    │
│   - Actions     │
│   - Lessons     │
└─────────────────┘
```

### Emergency Lockdown Procedure

**When to use:** Active breach, system compromise, immediate threat to production

⚠️ **WARNING:** This will stop all API traffic and services

**Procedure:**

```bash
# 1. Activate lockdown mode
curl -X POST http://127.0.0.1:8080/admin/security/emergency_lockdown \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Security incident INC-12345",
    "initiated_by": "oncall_engineer@example.com"
  }'

# 2. Verify lockdown active
curl http://127.0.0.1:8080/status
# Should return: {"lockdown": true, ...}

# 3. All API requests will now return:
# HTTP 503 Service Unavailable
# {"error": "System in emergency lockdown mode"}

# 4. Perform investigation and containment
# (See incident-specific playbooks)

# 5. When safe, deactivate lockdown
curl -X POST http://127.0.0.1:8080/admin/security/deactivate_lockdown \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Threat contained, security measures implemented",
    "authorized_by": "security_lead@example.com"
  }'
```

**Communication during lockdown:**
1. Notify stakeholders immediately
2. Post status updates every 15 minutes
3. Use #security-incidents Slack channel
4. Update status page
5. Document all actions

---

## Threat Management

### IP Ban Operations

#### 1. Ban IP Address (Temporary)

**When to use:** Brute force attack, rate limit violations, suspicious activity

**Procedure:**
```bash
# Ban IP for 1 hour (3600 seconds)
curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
  -H "Content-Type: application/json" \
  -d '{
    "ip": "203.0.113.42",
    "permanent": false,
    "duration_seconds": 3600,
    "reason": "Brute force attack detected - 50 failed logins"
  }'

# Verify ban
curl http://127.0.0.1:8080/admin/security/bans/check?ip=203.0.113.42
# Returns:
# {
#   "banned": true,
#   "ban_type": "temporary",
#   "expires_at": 1234571490,
#   "remaining_seconds": 3421,
#   "reason": "Brute force attack detected - 50 failed logins"
# }
```

**Default ban durations by violation:**
- Failed authentication: 1 hour (3600s)
- Rate limit violation: 15 minutes (900s)
- Suspicious activity: 30 minutes (1800s)
- Medium threat: 4 hours (14400s)

#### 2. Ban IP Address (Permanent)

**When to use:** Confirmed attacker, repeated violations, malicious behavior

**Procedure:**
```bash
# Permanent ban
curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
  -H "Content-Type: application/json" \
  -d '{
    "ip": "203.0.113.66",
    "permanent": true,
    "reason": "SQL injection attempts - confirmed malicious actor"
  }'

# Document in security incident log
echo "$(date +%Y-%m-%d\ %H:%M:%S) - Permanently banned 203.0.113.66 - SQL injection" \
  >> logs/permanent_bans.log
```

**Permanent ban criteria:**
- SQL injection attempts
- Command injection attempts
- Multiple attack types from same IP
- Known attacker IP (threat intelligence)
- Repeated temporary bans (3+ in 24 hours)

#### 3. Unban IP Address

**When to use:** False positive, legitimate user affected, resolved issue

**Procedure:**
```bash
# Unban IP
curl -X POST http://127.0.0.1:8080/admin/security/unban_ip \
  -H "Content-Type: application/json" \
  -d '{
    "ip": "203.0.113.42",
    "reason": "False positive - legitimate monitoring service",
    "unbanned_by": "security_engineer@example.com"
  }'

# Verify unban
curl http://127.0.0.1:8080/admin/security/bans/check?ip=203.0.113.42
# Returns: {"banned": false}

# Add to whitelist if recurring issue
curl -X POST http://127.0.0.1:8080/admin/security/whitelist/add \
  -H "Content-Type: application/json" \
  -d '{
    "ip": "203.0.113.42",
    "reason": "Corporate monitoring service",
    "added_by": "security_engineer@example.com"
  }'
```

#### 4. List All Active Bans

**Procedure:**
```bash
# Get all active bans
curl http://127.0.0.1:8080/admin/security/bans/list

# Get ban statistics
curl http://127.0.0.1:8080/admin/security/bans/stats
# Returns:
# {
#   "total_bans": 15,
#   "temporary_bans": 12,
#   "permanent_bans": 3,
#   "bans_last_hour": 5,
#   "bans_last_24h": 15
# }
```

#### 5. Bulk Ban Operations

**When to use:** DDoS attack, coordinated attack from multiple IPs

**Procedure:**
```bash
# Ban multiple IPs (bash script)
for ip in 203.0.113.{10..20}; do
  curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
    -H "Content-Type: application/json" \
    -d "{
      \"ip\": \"$ip\",
      \"permanent\": false,
      \"duration_seconds\": 3600,
      \"reason\": \"DDoS attack participant - INC-12345\"
    }"
done

# Or use bulk ban endpoint if available
curl -X POST http://127.0.0.1:8080/admin/security/ban_ips_bulk \
  -H "Content-Type: application/json" \
  -d '{
    "ips": ["203.0.113.10", "203.0.113.11", "203.0.113.12"],
    "permanent": false,
    "duration_seconds": 3600,
    "reason": "DDoS attack participants"
  }'
```

### Threat Investigation

#### 1. Review Active Threats

**Procedure:**
```bash
# Get current threats
curl http://127.0.0.1:8080/admin/security/threats/active

# Get threat summary
curl http://127.0.0.1:8080/admin/security/threats/summary
# Returns:
# {
#   "total_threats": 42,
#   "threats_last_hour": 12,
#   "by_severity": {
#     "CRITICAL": 2,
#     "HIGH": 5,
#     "MEDIUM": 15,
#     "LOW": 20
#   },
#   "active_ips": 8,
#   "known_attackers": 3
# }

# Get detailed threat data
curl http://127.0.0.1:8080/admin/security/threats/details?limit=50
```

#### 2. IP Reputation Check

**Procedure:**
```bash
# Check IP reputation
curl http://127.0.0.1:8080/admin/security/ip_reputation?ip=203.0.113.42
# Returns:
# {
#   "ip": "203.0.113.42",
#   "reputation_score": 75,  # 0-100, higher is worse
#   "is_known_attacker": true,
#   "threat_score": 150,
#   "event_count": 45,
#   "first_seen": 1234560000,
#   "last_seen": 1234567890,
#   "event_types": {
#     "failed_auth": 30,
#     "rate_limit_violation": 15
#   }
# }
```

**Reputation score interpretation:**
- **0-25:** Clean, trusted
- **26-50:** Minor concerns, monitor
- **51-75:** Suspicious, tighten limits
- **76-99:** Malicious, consider temp ban
- **100+:** Confirmed attacker, permanent ban

#### 3. Investigate Attack Pattern

**Procedure:**
```bash
# Get attack patterns
curl http://127.0.0.1:8080/admin/security/attack_patterns

# Query specific attack type
curl http://127.0.0.1:8080/admin/security/threats/by_type?type=brute_force_attack

# Get timeline of attacks
curl http://127.0.0.1:8080/admin/security/threats/timeline?hours=24

# Export threat intelligence
curl http://127.0.0.1:8080/admin/security/threats/export > threats_$(date +%Y%m%d).json
```

### Attack Mitigation Strategies

#### Brute Force Attack

**Detection:** Multiple failed authentication attempts from single IP

**Mitigation:**
```bash
# 1. Identify attacking IPs
curl http://127.0.0.1:8080/admin/security/threats/by_type?type=brute_force_attack

# 2. Ban attacking IPs
curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
  -H "Content-Type: application/json" \
  -d '{
    "ip": "<attacker_ip>",
    "permanent": false,
    "duration_seconds": 7200,
    "reason": "Brute force attack"
  }'

# 3. Tighten rate limits globally if widespread
curl -X POST http://127.0.0.1:8080/admin/security/rate_limits/tighten \
  -H "Content-Type: application/json" \
  -d '{"factor": 0.5, "duration_seconds": 3600}'

# 4. Monitor authentication failure rate
watch -n 5 'curl -s http://127.0.0.1:8080/metrics | grep auth_failure'
```

#### Distributed Denial of Service (DDoS)

**Detection:** Massive request spike from multiple IPs, rapid requests

**Mitigation:**
```bash
# 1. Identify attack pattern
curl http://127.0.0.1:8080/admin/security/threats/summary

# 2. Enable aggressive rate limiting
curl -X POST http://127.0.0.1:8080/admin/security/ddos_protection \
  -H "Content-Type: application/json" \
  -d '{"enabled": true, "strictness": "high"}'

# 3. Ban attacking IP ranges
# (See bulk ban procedure above)

# 4. Consider emergency lockdown if severe
# (See emergency lockdown procedure)

# 5. Coordinate with infrastructure team
# - Enable CDN DDoS protection
# - Increase rate limits at load balancer
# - Scale up infrastructure
```

#### SQL Injection Attempts

**Detection:** IDS detects SQL injection patterns in requests

**Mitigation:**
```bash
# 1. Immediate permanent ban
curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
  -H "Content-Type: application/json" \
  -d '{
    "ip": "<attacker_ip>",
    "permanent": true,
    "reason": "SQL injection attempt - CRITICAL threat"
  }'

# 2. Review attack details
curl http://127.0.0.1:8080/admin/security/threats/by_type?type=sql_injection

# 3. Check if any injection succeeded
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "validation_failure",
    "severity": "critical",
    "limit": 100
  }'

# 4. Alert security team immediately
# 5. Review all database queries in affected timeframe
# 6. Consider emergency lockdown if data breach suspected
```

### False Positive Handling

**Scenario:** Legitimate user or service triggering security alerts

**Investigation procedure:**
```bash
# 1. Verify it's a false positive
# - Check IP ownership (WHOIS)
# - Review user agent
# - Check request patterns
# - Confirm with service owner

# 2. Unban if currently banned
curl -X POST http://127.0.0.1:8080/admin/security/unban_ip \
  -H "Content-Type: application/json" \
  -d '{
    "ip": "<ip>",
    "reason": "False positive - confirmed legitimate service"
  }'

# 3. Add to whitelist
curl -X POST http://127.0.0.1:8080/admin/security/whitelist/add \
  -H "Content-Type: application/json" \
  -d '{
    "ip": "<ip>",
    "reason": "Monitoring service",
    "added_by": "security_engineer@example.com"
  }'

# 4. Adjust detection rules if needed
# Edit: C:/godot/config/ids_rules.json
# Increase thresholds or add exceptions

# 5. Document in false positives log
echo "$(date) - FP: <ip> - Reason: <reason>" >> logs/false_positives.log
```

---

## Audit and Compliance

### Audit Log Management

#### 1. Query Audit Logs

**Procedure:**
```bash
# Query by event type
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "authentication",
    "limit": 100
  }'

# Query by time range
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{
    "start_time": 1234560000,
    "end_time": 1234567890,
    "limit": 1000
  }'

# Query by token ID
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{
    "token_id": "tok_abc123...",
    "limit": 500
  }'

# Query by IP address
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{
    "ip": "203.0.113.42",
    "limit": 200
  }'

# Query failures only
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{
    "result": "failure",
    "limit": 100
  }'
```

#### 2. Export Audit Logs

**Procedure:**
```bash
# Export all logs (JSONL format)
curl http://127.0.0.1:8080/admin/audit/export > audit_$(date +%Y%m%d_%H%M%S).jsonl

# Export specific date range
curl http://127.0.0.1:8080/admin/audit/export?start=2024-01-01&end=2024-01-31 \
  > audit_january_2024.jsonl

# Export and compress
curl http://127.0.0.1:8080/admin/audit/export | gzip > audit_$(date +%Y%m%d).jsonl.gz

# Export to secure backup location
curl http://127.0.0.1:8080/admin/audit/export | \
  aws s3 cp - s3://security-audit-logs/audit_$(date +%Y%m%d).jsonl
```

**Backup schedule:**
- **Daily:** Automated export to S3/backup location
- **Weekly:** Full audit log backup with verification
- **Monthly:** Compliance package generation
- **Quarterly:** Archived to cold storage

#### 3. Audit Log Analysis

**Procedure:**
```bash
# Get audit statistics
curl http://127.0.0.1:8080/admin/audit/stats
# Returns:
# {
#   "total_events": 123456,
#   "events_by_type": {
#     "authentication": 45000,
#     "authorization": 67000,
#     "validation_failure": 234,
#     "rate_limit": 1200
#   },
#   "success_rate": 98.5,
#   "unique_ips": 156,
#   "unique_tokens": 12
# }

# Analyze authentication patterns
curl http://127.0.0.1:8080/admin/audit/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "analysis_type": "authentication_patterns",
    "time_range_hours": 24
  }'

# Identify anomalies
curl http://127.0.0.1:8080/admin/audit/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "analysis_type": "anomaly_detection",
    "time_range_hours": 168
  }'

# Top failed authentication sources
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "authentication",
    "result": "failure",
    "limit": 1000
  }' | jq -r '.[] | .details.ip' | sort | uniq -c | sort -rn | head -20
```

### Compliance Reporting

#### 1. Generate Compliance Report

**Procedure:**
```bash
# Generate monthly compliance report
curl http://127.0.0.1:8080/admin/compliance/report \
  -H "Content-Type: application/json" \
  -d '{
    "report_type": "monthly",
    "month": "2024-01",
    "format": "json"
  }' > compliance_report_2024_01.json

# Generate quarterly report
curl http://127.0.0.1:8080/admin/compliance/report \
  -H "Content-Type: application/json" \
  -d '{
    "report_type": "quarterly",
    "quarter": "Q1-2024",
    "format": "pdf"
  }' > compliance_report_Q1_2024.pdf
```

**Report includes:**
- Total audit events
- Authentication success/failure rates
- Authorization decisions
- Security incidents
- Access patterns
- Privileged operations
- Compliance violations
- Remediation actions

#### 2. Access Review

**Monthly access review checklist:**

```bash
# 1. List all active tokens
curl http://127.0.0.1:8080/admin/tokens/list > active_tokens.json

# 2. List all role assignments
curl http://127.0.0.1:8080/admin/rbac/list_assignments > role_assignments.json

# 3. Identify unused tokens (no activity in 30 days)
curl http://127.0.0.1:8080/admin/tokens/unused?days=30

# 4. Identify tokens with excessive privileges
curl http://127.0.0.1:8080/admin/rbac/list_assignments | \
  jq '.[] | select(.role_name == "admin")'

# 5. Review recent privileged operations
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{
    "permission_level": "admin",
    "limit": 500
  }'
```

**Action items from review:**
- [ ] Revoke unused tokens
- [ ] Downgrade excessive privileges
- [ ] Document justification for admin roles
- [ ] Update token inventory
- [ ] Generate access review report

#### 3. Security Metrics

**Procedure:**
```bash
# Get comprehensive security metrics
curl http://127.0.0.1:8080/admin/security/metrics

# Key metrics to track:
# - Authentication success rate (target: >95%)
# - Authorization success rate (target: >90%)
# - Failed authentication rate (alert: >5%)
# - Active security incidents (alert: >0 critical)
# - Average response time (target: <500ms)
# - Token rotation compliance (target: >90%)
```

**Security KPIs:**

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| Auth Success Rate | >95% | <95% | <90% |
| Auth Response Time | <200ms | >200ms | >500ms |
| Failed Auth Rate | <5% | >5% | >10% |
| Critical Incidents | 0 | 1 | >1 |
| Token Rotation Rate | >90% | <90% | <75% |
| Audit Log Coverage | 100% | <100% | <95% |

### Anomaly Investigation

**Procedure for investigating unusual patterns:**

```bash
# 1. Detect anomalies
curl http://127.0.0.1:8080/admin/security/anomalies/detect

# 2. Get anomaly details
curl http://127.0.0.1:8080/admin/security/anomalies/details?anomaly_id=<id>

# 3. Investigate source
# - Check IP reputation
# - Review audit logs
# - Analyze request patterns
# - Check for correlation with known attacks

# 4. Determine if malicious
# If malicious:
#   - Follow threat mitigation procedures
#   - Ban IP
#   - Revoke tokens if compromised
# If benign:
#   - Update baseline
#   - Document false positive
#   - Adjust detection thresholds

# 5. Document findings
echo "$(date) - Anomaly: <description> - Result: <malicious/benign>" \
  >> logs/anomaly_investigations.log
```

---

## Monitoring and Alerting

### Security Alert Catalog

The intrusion detection system generates 24+ distinct alert types across 7 categories:

#### Authentication Alerts (3 types)

**1. Failed Login Threshold Exceeded**
- **Severity:** HIGH
- **Trigger:** 5 failed logins in 60 seconds from single IP
- **Response:** See "Brute Force Attack" playbook

**2. Credential Stuffing Detected**
- **Severity:** CRITICAL
- **Trigger:** 10+ unique usernames from single IP in 120 seconds
- **Response:** Immediate IP ban, investigate source

**3. Distributed Brute Force**
- **Severity:** HIGH
- **Trigger:** 20+ failures for single username from 5+ IPs in 300 seconds
- **Response:** Alert security team, implement rate limiting

#### Rate Limiting Alerts (3 types)

**4. Rapid Requests**
- **Severity:** MEDIUM
- **Trigger:** 100 requests in 10 seconds from single IP
- **Response:** Temporary ban, investigate

**5. Sustained High Rate**
- **Severity:** HIGH
- **Trigger:** 500 requests in 60 seconds
- **Response:** Tighten rate limits, possible DDoS

**6. Endpoint Flooding**
- **Severity:** MEDIUM
- **Trigger:** 50 requests to single endpoint in 30 seconds
- **Response:** Endpoint-specific rate limiting

#### Injection Attack Alerts (3 types)

**7. SQL Injection Attempt**
- **Severity:** CRITICAL
- **Trigger:** SQL patterns detected in payload
- **Response:** Immediate permanent ban, escalate

**8. Command Injection Attempt**
- **Severity:** CRITICAL
- **Trigger:** Command execution patterns detected
- **Response:** Immediate permanent ban, escalate

**9. Script Injection (XSS)**
- **Severity:** HIGH
- **Trigger:** Script tags or JavaScript in payload
- **Response:** Temporary ban, log for analysis

#### Path Traversal Alerts (2 types)

**10. Directory Traversal Attempt**
- **Severity:** CRITICAL
- **Trigger:** ../ patterns or /etc/passwd access
- **Response:** Immediate permanent ban

**11. Sensitive File Access**
- **Severity:** HIGH
- **Trigger:** Attempts to access .exe, .php, .sh files
- **Response:** Ban IP, investigate

#### Privilege Escalation Alerts (3 types)

**12. Unauthorized Admin Access**
- **Severity:** CRITICAL
- **Trigger:** Non-admin token accessing admin endpoints
- **Response:** Revoke token, investigate

**13. Token Manipulation**
- **Severity:** HIGH
- **Trigger:** Malformed or tampered JWT tokens
- **Response:** Ban IP, audit token security

**14. Session Hijacking**
- **Severity:** CRITICAL
- **Trigger:** Same session from 2+ IPs in 5 minutes
- **Response:** Terminate session, investigate

#### Geographic Alerts (3 types)

**15. Impossible Travel**
- **Severity:** HIGH
- **Trigger:** Logins from locations >500km apart in <1 hour
- **Response:** Require re-authentication

**16. Blacklisted Country**
- **Severity:** MEDIUM
- **Trigger:** Access from blocked countries
- **Response:** Ban IP, log

**17. Unusual Location**
- **Severity:** LOW
- **Trigger:** Access from new geographic location
- **Response:** Log for analysis

#### Behavioral Alerts (4 types)

**18. Rapid Session Creation**
- **Severity:** MEDIUM
- **Trigger:** 10 sessions in 60 seconds
- **Response:** Tighten rate limits

**19. Unusual User Agent**
- **Severity:** LOW
- **Trigger:** Suspicious user agent (bot, scraper)
- **Response:** Log, monitor

**20. Parameter Fuzzing**
- **Severity:** MEDIUM
- **Trigger:** 20+ unique parameters in 60 seconds
- **Response:** Temporary ban

**21. Off-Hours Access**
- **Severity:** LOW
- **Trigger:** Access outside 08:00-18:00 business hours
- **Response:** Log for audit

#### System Alerts (3 types)

**22. High Threat Score**
- **Severity:** varies
- **Trigger:** IP reputation score exceeds thresholds
- **Response:** Escalate based on score

**23. Known Attacker Detected**
- **Severity:** CRITICAL
- **Trigger:** IP matches threat intelligence database
- **Response:** Immediate permanent ban

**24. Alert System Health**
- **Severity:** varies
- **Trigger:** IDS system errors or performance issues
- **Response:** Investigate IDS system

### Alert Response Procedures

#### General Alert Response

```bash
# 1. Acknowledge alert
# (In AlertManager or PagerDuty)

# 2. Get alert details
curl http://127.0.0.1:8080/admin/security/alerts/active

# 3. Get related security events
curl http://127.0.0.1:8080/admin/security/threats/details?alert_id=<alert_id>

# 4. Follow specific playbook
# (See INCIDENT_RESPONSE_PLAYBOOKS.md)

# 5. Document actions taken
curl -X POST http://127.0.0.1:8080/admin/incidents/log \
  -H "Content-Type: application/json" \
  -d '{
    "alert_id": "<alert_id>",
    "actions_taken": "...",
    "outcome": "..."
  }'
```

### Dashboard Interpretation

**Security Overview Dashboard:**

Access: http://localhost:3000/d/security-overview

**Key Metrics:**

1. **Authentication Success Rate**
   - Normal: >95%
   - Warning: 90-95%
   - Critical: <90%

2. **Active Security Incidents**
   - Normal: 0 critical, <3 high
   - Warning: 1 critical or >3 high
   - Critical: >1 critical

3. **Failed Authentication Rate**
   - Normal: <5%
   - Warning: 5-10%
   - Critical: >10%

4. **Banned IPs (24h)**
   - Normal: 0-5
   - Warning: 6-20
   - Critical: >20 (possible DDoS)

5. **Request Rate**
   - Monitor for sudden spikes
   - Compare to baseline
   - Alert on >200% baseline

**Threat Intelligence Dashboard:**

Access: http://localhost:3000/d/threat-intelligence

Shows:
- Active threats by severity
- Top attacking IPs
- Attack patterns over time
- Geographic distribution
- Threat timeline

### Metric Troubleshooting

#### High Failed Authentication Rate

**Investigation:**
```bash
# 1. Identify sources
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{"event_type": "authentication", "result": "failure", "limit": 500}' | \
  jq -r '.[] | .details.ip' | sort | uniq -c | sort -rn | head -10

# 2. Check if known attack
curl http://127.0.0.1:8080/admin/security/threats/by_type?type=brute_force_attack

# 3. Determine if legitimate issues vs attack
# - Check if concentrated in few IPs → Attack
# - Check if distributed → Service issue

# 4. If attack, mitigate
# If service issue, investigate root cause
```

#### Low Authorization Success Rate

**Investigation:**
```bash
# 1. Get authorization failures
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{"event_type": "authorization", "result": "failure", "limit": 200}'

# 2. Group by permission
# Identify most common failures

# 3. Determine cause:
# - Role misconfiguration?
# - Service using wrong token?
# - Permission changes not communicated?

# 4. Resolution:
# - Update role assignments
# - Update service configurations
# - Document permission requirements
```

### Alert Tuning

**Reducing false positives:**

```bash
# 1. Identify frequent false positives
grep "false positive" logs/security/*.log | \
  cut -d':' -f3 | sort | uniq -c | sort -rn

# 2. Edit IDS rules
nano C:/godot/config/ids_rules.json

# 3. Adjust thresholds
# Example: Increase failed login threshold from 5 to 10
# "failed_login_threshold": {
#   "count": 10,  # Was: 5
#   ...
# }

# 4. Add whitelist entries
curl -X POST http://127.0.0.1:8080/admin/security/whitelist/add \
  -H "Content-Type: application/json" \
  -d '{
    "ip": "<legitimate_ip>",
    "reason": "Monitoring service causing false positives"
  }'

# 5. Reload IDS configuration
curl -X POST http://127.0.0.1:8080/admin/security/ids/reload_config

# 6. Monitor for 24 hours to verify improvement
```

---

## Backup and Recovery

### Security Configuration Backup

#### 1. Backup Security Configuration

**Procedure:**
```bash
# Create backup directory
mkdir -p backups/security/$(date +%Y%m%d)

# Backup IDS rules
cp C:/godot/config/ids_rules.json \
   backups/security/$(date +%Y%m%d)/ids_rules.json

# Backup token database
curl http://127.0.0.1:8080/admin/tokens/export > \
  backups/security/$(date +%Y%m%d)/tokens_backup.json

# Backup role assignments
curl http://127.0.0.1:8080/admin/rbac/export > \
  backups/security/$(date +%Y%m%d)/rbac_backup.json

# Backup ban list
curl http://127.0.0.1:8080/admin/security/bans/export > \
  backups/security/$(date +%Y%m%d)/bans_backup.json

# Backup whitelist
curl http://127.0.0.1:8080/admin/security/whitelist/export > \
  backups/security/$(date +%Y%m%d)/whitelist_backup.json

# Create backup manifest
echo "Backup created: $(date)" > backups/security/$(date +%Y%m%d)/manifest.txt
echo "IDS Rules: $(md5sum backups/security/$(date +%Y%m%d)/ids_rules.json)" \
  >> backups/security/$(date +%Y%m%d)/manifest.txt

# Compress backup
tar -czf backups/security/security_backup_$(date +%Y%m%d).tar.gz \
  backups/security/$(date +%Y%m%d)/

# Upload to secure storage
aws s3 cp backups/security/security_backup_$(date +%Y%m%d).tar.gz \
  s3://security-backups/$(date +%Y/%m)/
```

**Backup schedule:**
- **Daily:** Automated via cron at 02:00 UTC
- **Pre-change:** Manual backup before configuration changes
- **Pre-upgrade:** Manual backup before system upgrades
- **Monthly:** Verified backup with test restore

#### 2. Restore Security Configuration

**Procedure:**
```bash
# 1. Download backup from secure storage
aws s3 cp s3://security-backups/2024/01/security_backup_20240115.tar.gz .

# 2. Extract backup
tar -xzf security_backup_20240115.tar.gz

# 3. Verify backup integrity
md5sum -c backups/security/20240115/manifest.txt

# 4. Restore IDS rules
cp backups/security/20240115/ids_rules.json C:/godot/config/ids_rules.json

# 5. Reload IDS configuration
curl -X POST http://127.0.0.1:8080/admin/security/ids/reload_config

# 6. Restore ban list (optional - be careful)
curl -X POST http://127.0.0.1:8080/admin/security/bans/import \
  -H "Content-Type: application/json" \
  -d @backups/security/20240115/bans_backup.json

# 7. Restore whitelist
curl -X POST http://127.0.0.1:8080/admin/security/whitelist/import \
  -H "Content-Type: application/json" \
  -d @backups/security/20240115/whitelist_backup.json

# 8. Verify restoration
curl http://127.0.0.1:8080/admin/security/status

# 9. Document restoration
echo "$(date) - Restored security config from 20240115 backup" \
  >> logs/restoration_log.txt
```

⚠️ **WARNING:** Do NOT restore tokens or role assignments without careful review. These should be regenerated.

### Audit Log Backup

#### 1. Backup Audit Logs

**Procedure:**
```bash
# Export audit logs
curl http://127.0.0.1:8080/admin/audit/export > \
  audit_logs_$(date +%Y%m%d).jsonl

# Compress
gzip audit_logs_$(date +%Y%m%d).jsonl

# Upload to secure archival storage
aws s3 cp audit_logs_$(date +%Y%m%d).jsonl.gz \
  s3://audit-logs-archive/$(date +%Y/%m/%d)/

# Verify upload
aws s3 ls s3://audit-logs-archive/$(date +%Y/%m/%d)/

# Remove local copy after 7 days (automated cleanup)
```

**Retention policy:**
- **Active logs:** 90 days in production
- **Compressed backup:** 1 year in warm storage
- **Long-term archive:** 7 years in cold storage (compliance)

#### 2. Restore Audit Logs

**Procedure:**
```bash
# Download from archive
aws s3 cp s3://audit-logs-archive/2024/01/15/audit_logs_20240115.jsonl.gz .

# Decompress
gunzip audit_logs_20240115.jsonl.gz

# Import into analysis system
curl -X POST http://127.0.0.1:8080/admin/audit/import \
  -H "Content-Type: application/json" \
  -d @audit_logs_20240115.jsonl

# Or analyze locally
jq '.' audit_logs_20240115.jsonl | less
```

### Token Database Backup

⚠️ **CRITICAL:** Token backups contain sensitive secrets

**Procedure:**
```bash
# 1. Export tokens (encrypted)
curl http://127.0.0.1:8080/admin/tokens/export_encrypted > tokens_backup.enc

# 2. Encrypt backup (double encryption)
openssl enc -aes-256-cbc -salt -in tokens_backup.enc -out tokens_backup.enc.aes

# 3. Store encryption key in secure vault
# DO NOT store key with backup

# 4. Upload to highly restricted storage
aws s3 cp tokens_backup.enc.aes s3://tokens-backup-restricted/ \
  --sse aws:kms --sse-kms-key-id <kms-key-id>

# 5. Delete local copies
shred -u tokens_backup.enc tokens_backup.enc.aes

# 6. Document backup location (without key)
echo "$(date) - Token backup uploaded to S3 (KMS encrypted)" \
  >> logs/token_backup_log.txt
```

**Recovery procedure:**
```bash
# 1. Retrieve encryption key from vault
# 2. Download backup
aws s3 cp s3://tokens-backup-restricted/tokens_backup.enc.aes .

# 3. Decrypt
openssl enc -d -aes-256-cbc -in tokens_backup.enc.aes -out tokens_backup.enc

# 4. Import tokens
curl -X POST http://127.0.0.1:8080/admin/tokens/import_encrypted \
  -H "Content-Type: application/octet-stream" \
  --data-binary @tokens_backup.enc

# 5. Verify import
curl http://127.0.0.1:8080/admin/tokens/stats

# 6. Securely delete local files
shred -u tokens_backup.enc.aes tokens_backup.enc
```

### Security System Recovery

**Disaster recovery procedure:**

```bash
# 1. Stop Godot server
pkill -f godot

# 2. Restore security configuration
# (See restore procedures above)

# 3. Verify configuration files
ls -lh C:/godot/config/ids_rules.json
cat C:/godot/config/ids_rules.json | jq '.' > /dev/null && echo "Valid JSON"

# 4. Start server with debug flags
cd C:/godot
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005 &

# 5. Wait for startup (30 seconds)
sleep 30

# 6. Verify security system status
curl http://127.0.0.1:8080/admin/security/status

# 7. Check all components initialized
curl http://127.0.0.1:8080/status | jq '.security'

# 8. Run health checks
python tests/health_monitor.py

# 9. Verify audit logging active
curl http://127.0.0.1:8080/admin/audit/stats

# 10. Test authentication
curl -X POST http://127.0.0.1:8080/admin/tokens/generate | jq '.'

# 11. Monitor for issues
tail -f logs/security/*.log
```

---

## Emergency Procedures

### Emergency Contact Tree

```
Security Incident Detected
         │
         ▼
   On-Call Engineer
   (Primary Responder)
         │
         ├─ P0/P1 Alert ──→ Security Lead (15 min)
         │                      │
         │                      ├─ Continues ──→ Director of Engineering (30 min)
         │                      │                    │
         │                      │                    └─→ CTO (1 hour)
         │                      │
         │                      └─ Data Breach ──→ Legal/Compliance (immediate)
         │
         └─ P2/P3 Alert ──→ Security Team Slack
                               (Next business day review)
```

### Communication Channels

| Severity | Channel | Response Time |
|----------|---------|---------------|
| P0 | PagerDuty → Phone | <5 min |
| P1 | PagerDuty → SMS | <15 min |
| P2 | Slack #security-alerts | <1 hour |
| P3 | Slack #security-events | <4 hours |

**War Room Procedures:**

1. Create dedicated Slack channel: `#incident-YYYYMMDD-summary`
2. Start Zoom war room (link in runbook)
3. Assign roles:
   - Incident Commander
   - Technical Lead
   - Communications Lead
   - Scribe
4. Post status updates every 15 minutes
5. Log all decisions and actions

### Security Incident Escalation

**Escalation criteria:**

**Immediate escalation (P0):**
- Active data breach
- System compromise
- Ransomware detected
- Multiple critical vulnerabilities exploited
- Production outage due to security

**Urgent escalation (P1):**
- Confirmed attack in progress
- Privilege escalation successful
- Sensitive data accessed
- Multiple security systems compromised

**Standard escalation (P2):**
- Attack contained but ongoing
- Security control failure
- Compliance violation
- Repeated incidents from same source

### Post-Incident Actions

**Immediate (within 1 hour):**
- [ ] Contain threat
- [ ] Revoke compromised credentials
- [ ] Ban attacker IPs
- [ ] Document timeline

**Short-term (within 24 hours):**
- [ ] Complete investigation
- [ ] Implement permanent fixes
- [ ] Notify affected parties (if required)
- [ ] Update security controls

**Long-term (within 1 week):**
- [ ] Complete post-incident review
- [ ] Update runbooks
- [ ] Conduct training
- [ ] Implement preventive measures
- [ ] Update threat intelligence

---

## Appendices

### Appendix A: Security Glossary

| Term | Definition |
|------|------------|
| **Token** | API authentication credential (JWT-like) |
| **RBAC** | Role-Based Access Control |
| **IDS** | Intrusion Detection System |
| **IP Ban** | Blocking all traffic from an IP address |
| **Threat Score** | Numeric risk assessment (0-300+) |
| **Audit Log** | Immutable record of security events |
| **Quarantine** | Read-only access mode for suspicious users |

### Appendix B: Common GDScript Snippets

```gdscript
# Check if security system initialized
if HttpApiSecuritySystem.initialized:
    print("Security active")

# Get token manager
var token_manager = HttpApiSecuritySystem.get_token_manager()

# Get RBAC manager
var rbac_manager = HttpApiSecuritySystem.get_rbac_manager()

# Check permission
var has_perm = rbac_manager.check_authorization(
    token_id,
    HttpApiRBAC.Permission.ADMIN_SECURITY
)
```

### Appendix C: Quick Command Reference

```bash
# Status
curl http://127.0.0.1:8080/admin/security/status

# Ban IP
curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
  -d '{"ip":"1.2.3.4","permanent":true}'

# Revoke token
curl -X POST http://127.0.0.1:8080/admin/tokens/revoke \
  -d '{"token_secret":"xxx","reason":"compromised"}'

# View threats
curl http://127.0.0.1:8080/admin/security/threats/summary

# Export audit
curl http://127.0.0.1:8080/admin/audit/export > audit.jsonl

# Emergency lockdown
curl -X POST http://127.0.0.1:8080/admin/security/emergency_lockdown
```

### Appendix D: Log File Locations

```
logs/
├── security/
│   ├── audit_2024-01-15.jsonl          # Audit events
│   ├── ids_2024-01-15.log              # IDS detections
│   ├── threats_2024-01-15.log          # Threat responses
│   └── bans_2024-01-15.log             # IP bans
├── godot_*.log                          # Application logs
└── error_*.log                          # Error logs
```

### Appendix E: Useful Queries

```bash
# Find all admin operations today
curl http://127.0.0.1:8080/admin/audit/query \
  -d '{"permission_level":"admin","start_time":'$(date -d "today 00:00" +%s)'}'

# Top 10 most active tokens
curl http://127.0.0.1:8080/admin/tokens/list | \
  jq -r '.[] | "\(.use_count)\t\(.token_id)"' | sort -rn | head -10

# All security incidents last 7 days
curl http://127.0.0.1:8080/admin/security/incidents?days=7

# Export threat intelligence
curl http://127.0.0.1:8080/admin/security/threats/export > threats.json
```

---

## Document Maintenance

**Last Updated:** 2025-12-02
**Next Review:** 2025-03-02
**Owner:** Security Operations Team
**Reviewers:** Security Lead, DevOps Lead, CTO

**Change Log:**
- 2025-12-02: Initial version 2.0.0 - Comprehensive security runbooks created
- Future: Update after each security incident with lessons learned

**Feedback:** security-ops@spacetime-vr.com
