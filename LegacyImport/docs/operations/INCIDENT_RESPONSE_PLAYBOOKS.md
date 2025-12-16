# Incident Response Playbooks

**SpaceTime VR Project - Security Incident Response**
**Version:** 1.0.0
**Last Updated:** 2025-12-02
**Owner:** Security Incident Response Team

## Table of Contents

1. [Overview](#overview)
2. [Incident Response Framework](#incident-response-framework)
3. [Playbook 1: Brute Force Attack](#playbook-1-brute-force-attack)
4. [Playbook 2: SQL Injection Attack](#playbook-2-sql-injection-attack)
5. [Playbook 3: Privilege Escalation Attempt](#playbook-3-privilege-escalation-attempt)
6. [Playbook 4: DDoS Attack](#playbook-4-ddos-attack)
7. [Playbook 5: Compromised Credentials](#playbook-5-compromised-credentials)
8. [Playbook 6: System Breach (Suspected)](#playbook-6-system-breach-suspected)
9. [Playbook 7: Data Exfiltration Attempt](#playbook-7-data-exfiltration-attempt)
10. [Playbook 8: Insider Threat](#playbook-8-insider-threat)

---

## Overview

### Purpose

This document provides detailed, step-by-step playbooks for responding to common security incidents in the SpaceTime VR system. Each playbook follows the NIST Incident Response lifecycle: Prepare, Detect, Contain, Eradicate, Recover, Lessons Learned.

### When to Use These Playbooks

- Security alert fired in monitoring system
- Suspicious activity detected in audit logs
- User report of security concern
- Automated threat detection triggered
- External notification of vulnerability

### Incident Response Team Roles

| Role | Responsibilities | Contact |
|------|-----------------|---------|
| **Incident Commander** | Overall coordination, decisions, communications | PagerDuty: Security Lead |
| **Technical Lead** | Technical investigation, containment actions | On-call Engineer |
| **Communications Lead** | Stakeholder updates, external communications | Engineering Manager |
| **Scribe** | Document timeline, decisions, actions | Rotation |

---

## Incident Response Framework

### General Response Process

```
┌─────────────────────────────────────────────────────────┐
│                    DETECT & ASSESS                       │
│  • Alert fires or suspicious activity reported          │
│  • Classify severity (P0-P3)                           │
│  • Assemble response team                              │
│  • Open incident ticket                                │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│                       CONTAIN                            │
│  • Stop active attack                                   │
│  • Ban malicious IPs                                    │
│  • Revoke compromised credentials                       │
│  • Isolate affected systems                            │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│                      INVESTIGATE                         │
│  • Determine attack vector                              │
│  • Identify scope of compromise                         │
│  • Collect evidence                                     │
│  • Build attack timeline                               │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│                      ERADICATE                           │
│  • Remove attacker access                               │
│  • Patch vulnerabilities                                │
│  • Update security controls                             │
│  • Verify no backdoors remain                          │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│                       RECOVER                            │
│  • Restore normal operations                            │
│  • Monitor for recurrence                               │
│  • Validate security controls                           │
│  • Return to business as usual                         │
└────────────────────┬────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  LESSONS LEARNED                         │
│  • Post-incident review meeting                         │
│  • Document findings                                    │
│  • Update procedures                                    │
│  • Implement preventive measures                       │
└─────────────────────────────────────────────────────────┘
```

### Severity Classification

| Level | Response Time | Impact | Examples |
|-------|---------------|---------|----------|
| **P0** | <5 min | Critical - Active breach, data loss | System compromise, ransomware |
| **P1** | <15 min | High - Attack in progress, potential breach | SQL injection, privilege escalation |
| **P2** | <1 hour | Medium - Suspicious activity, no breach | Brute force, rate violations |
| **P3** | <4 hours | Low - Informational, minimal risk | Policy violations, audit findings |

---

## Playbook 1: Brute Force Attack

### Overview

**Attack Type:** Authentication brute force
**Severity:** P2 (Medium) - Can escalate to P1 if successful
**MITRE ATT&CK:** T1110.001 (Brute Force: Password Guessing)
**Common Indicators:**
- Multiple failed login attempts from single IP
- Failed authentication alerts firing
- High authentication failure rate in metrics

### Detection

**Automated Alerts:**
```
Alert: Failed Login Threshold Exceeded
Source IP: 203.0.113.42
Failed Attempts: 15 in 60 seconds
Alert ID: ALT-BF-20240115-001
```

**Manual Detection:**
```bash
# Check authentication failure rate
curl http://127.0.0.1:8080/metrics | grep auth_failure

# Query recent failed authentications
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{"event_type": "authentication", "result": "failure", "limit": 100}'
```

### Response Steps

#### Phase 1: ASSESS (0-2 minutes)

**Objective:** Understand scope and severity

1. **Acknowledge alert** in PagerDuty/AlertManager
   ```bash
   # Alert acknowledged by: [Your Name]
   # Time: [Timestamp]
   ```

2. **Check attack scope**
   ```bash
   # Get brute force attack details
   curl http://127.0.0.1:8080/admin/security/threats/by_type?type=brute_force_attack

   # Check number of attacking IPs
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{"event_type": "authentication", "result": "failure", "limit": 1000}' | \
     jq -r '.[] | .details.ip' | sort -u | wc -l
   ```

3. **Determine if attack is successful**
   ```bash
   # Check if any authentications succeeded from attacking IPs
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{"event_type": "authentication", "result": "success", "ip": "203.0.113.42"}'
   ```

4. **Classify severity**
   - Single IP, no success → P2 (Medium)
   - Multiple IPs (distributed) → P1 (High)
   - Any successful authentication → P1 (High)
   - Ongoing with high rate → P1 (High)

#### Phase 2: CONTAIN (2-5 minutes)

**Objective:** Stop the attack immediately

1. **Ban attacking IP(s)**
   ```bash
   # For single IP attack
   curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
     -H "Content-Type: application/json" \
     -d '{
       "ip": "203.0.113.42",
       "permanent": false,
       "duration_seconds": 7200,
       "reason": "Brute force attack - INC-BF-001"
     }'

   # For multiple IPs (distributed attack)
   # Extract attacking IPs
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{"event_type": "authentication", "result": "failure", "limit": 1000}' | \
     jq -r '.[] | .details.ip' | sort -u > attacking_ips.txt

   # Ban each IP
   while read ip; do
     curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
       -H "Content-Type: application/json" \
       -d "{
         \"ip\": \"$ip\",
         \"permanent\": false,
         \"duration_seconds\": 7200,
         \"reason\": \"Distributed brute force - INC-BF-001\"
       }"
   done < attacking_ips.txt
   ```

2. **Verify attack has stopped**
   ```bash
   # Monitor authentication attempts
   watch -n 5 'curl -s http://127.0.0.1:8080/metrics | grep auth_failure'

   # Should see failure rate drop to near zero
   ```

3. **If attack continues (IPs changing)**
   ```bash
   # Enable aggressive rate limiting
   curl -X POST http://127.0.0.1:8080/admin/security/rate_limits/tighten \
     -H "Content-Type: application/json" \
     -d '{"factor": 0.3, "duration_seconds": 3600}'

   # If severe, consider temporary lockdown
   curl -X POST http://127.0.0.1:8080/admin/security/emergency_lockdown \
     -H "Content-Type: application/json" \
     -d '{
       "reason": "Severe distributed brute force attack",
       "initiated_by": "oncall_engineer@example.com"
     }'
   ```

#### Phase 3: INVESTIGATE (5-20 minutes)

**Objective:** Understand attack characteristics and check for success

1. **Build attack timeline**
   ```bash
   # Export all authentication events during attack
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{
       "event_type": "authentication",
       "start_time": 1234560000,
       "end_time": 1234567890,
       "limit": 10000
     }' > attack_timeline.json

   # Analyze attack pattern
   jq -r '.[] | [.timestamp, .details.ip, .result] | @csv' attack_timeline.json | \
     column -t -s,
   ```

2. **Check for successful authentications**
   ```bash
   # Any successes during attack window?
   jq '.[] | select(.result == "success")' attack_timeline.json

   # If any found → ESCALATE TO P1 - Potential compromise
   ```

3. **Identify targeted accounts**
   ```bash
   # Extract attempted usernames (if available in logs)
   jq -r '.[] | .details.username // "unknown"' attack_timeline.json | \
     sort | uniq -c | sort -rn

   # Common patterns:
   # - Generic names (admin, root, test) → Automated attack
   # - Specific usernames → Targeted attack (more concerning)
   ```

4. **Check attacker IP reputation**
   ```bash
   # For each attacking IP
   curl http://127.0.0.1:8080/admin/security/ip_reputation?ip=203.0.113.42

   # Check if known attacker, VPN, Tor exit node
   ```

5. **Determine attack sophistication**
   - Constant rate → Simple script
   - Varying rate → Evasion attempt
   - Multiple IPs with coordination → Botnet
   - Valid username enumeration → Reconnaissance phase

#### Phase 4: ERADICATE (20-45 minutes)

**Objective:** Ensure no persistent access or compromised credentials

1. **If any authentications succeeded:**
   ```bash
   # Extract tokens generated during attack
   jq -r '.[] | select(.result == "success") | .details.token_id' attack_timeline.json

   # Revoke all tokens
   while read token_id; do
     curl -X POST http://127.0.0.1:8080/admin/tokens/revoke \
       -H "Content-Type: application/json" \
       -d "{
         \"token_id\": \"$token_id\",
         \"reason\": \"Generated during brute force attack - INC-BF-001\"
       }"
   done

   # Force password reset for affected accounts
   # (Manual process - contact account owners)
   ```

2. **Review and strengthen authentication controls**
   ```bash
   # Check current IDS rules
   cat C:/godot/config/ids_rules.json | jq '.detection_rules.authentication'

   # Consider reducing threshold if too permissive
   # Example: 5 failures → 3 failures in 60 seconds
   ```

3. **Verify no backdoors created**
   ```bash
   # Check for any new tokens created during attack
   curl http://127.0.0.1:8080/admin/tokens/list | \
     jq '.[] | select(.created_at >= 1234560000 and .created_at <= 1234567890)'

   # Check for any role escalations
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{
       "event_type": "role_assignment",
       "start_time": 1234560000,
       "end_time": 1234567890
     }'
   ```

#### Phase 5: RECOVER (45-60 minutes)

**Objective:** Return to normal operations and monitor

1. **Remove temporary restrictions** (if applied)
   ```bash
   # If emergency lockdown was activated
   curl -X POST http://127.0.0.1:8080/admin/security/deactivate_lockdown \
     -H "Content-Type: application/json" \
     -d '{
       "reason": "Attack contained, normal operations resumed",
       "authorized_by": "security_lead@example.com"
     }'

   # If rate limits were tightened
   curl -X POST http://127.0.0.1:8080/admin/security/rate_limits/reset
   ```

2. **Monitor for recurrence**
   ```bash
   # Watch authentication metrics for 1 hour
   watch -n 60 'curl -s http://127.0.0.1:8080/metrics | grep auth_failure'

   # Set up alert for next 24 hours
   # Alert if >10 failures/minute
   ```

3. **Verify system health**
   ```bash
   curl http://127.0.0.1:8080/admin/security/status
   curl http://127.0.0.1:8080/status
   python tests/health_monitor.py
   ```

#### Phase 6: LESSONS LEARNED (Within 48 hours)

**Objective:** Document and improve

1. **Document incident**
   - Use POST_INCIDENT_REVIEW_TEMPLATE.md
   - Include timeline, actions, findings
   - Attach exported audit logs

2. **Update procedures**
   - Were any steps missing?
   - What could be automated?
   - Update this playbook

3. **Preventive measures**
   - Implement stricter rate limiting?
   - Add IP reputation checking?
   - Enable additional monitoring?

### Success Criteria

- [ ] Attack stopped (auth failure rate < 1/minute)
- [ ] All attacking IPs banned
- [ ] No successful authentications from attackers
- [ ] No compromised credentials found
- [ ] System returned to normal operations
- [ ] Incident documented
- [ ] Post-incident review scheduled

### Escalation Triggers

Escalate to P1 if:
- Any authentication succeeded from attacking IP
- Attack rate exceeds 100 failures/second
- Targeted attack against known admin accounts
- Coordinated with other attack types

---

## Playbook 2: SQL Injection Attack

### Overview

**Attack Type:** SQL Injection
**Severity:** P0 (Critical) - Immediate response required
**MITRE ATT&CK:** T1190 (Exploit Public-Facing Application)
**Common Indicators:**
- IDS SQL injection pattern detected
- Database error in application logs
- Unusual database queries
- Data exfiltration alerts

### Detection

**Automated Alerts:**
```
Alert: SQL Injection Attempt Detected
Source IP: 203.0.113.66
Payload: ' OR '1'='1' --
Endpoint: /api/scene/load
Alert ID: ALT-SQLi-20240115-001
Severity: CRITICAL
```

**Manual Detection:**
```bash
# Query SQL injection detections
curl http://127.0.0.1:8080/admin/security/threats/by_type?type=sql_injection

# Check validation failures
curl http://127.0.0.1:8080/admin/audit/query \
  -H "Content-Type: application/json" \
  -d '{"event_type": "validation_failure", "severity": "critical"}'
```

### Response Steps

#### Phase 1: ASSESS (0-3 minutes)

⚠️ **CRITICAL:** SQL injection can lead to complete database compromise

1. **Acknowledge alert and escalate immediately**
   ```bash
   # Page Security Lead immediately (P0 incident)
   # This is NOT a drill
   ```

2. **Check if injection succeeded**
   ```bash
   # Get injection attempt details
   curl http://127.0.0.1:8080/admin/security/threats/details?threat_type=sql_injection

   # Check for database errors in application logs
   tail -n 500 logs/godot_*.log | grep -i "database\|sql\|query"

   # Look for signs of success:
   # - "syntax error" → Unsuccessful (good)
   # - "query executed" → Potential success (bad)
   # - No error → May have been blocked or succeeded silently
   ```

3. **Determine potential data exposure**
   ```bash
   # What endpoint was targeted?
   # What data does that endpoint access?
   # Could attacker read sensitive data?
   # Could attacker modify/delete data?
   ```

4. **Classification:**
   - All SQL injection attempts are P0 until proven unsuccessful

#### Phase 2: CONTAIN (3-8 minutes)

**Objective:** Stop attacker immediately and prevent further attempts

1. **PERMANENT BAN of attacking IP** (no temporary ban for SQL injection)
   ```bash
   curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
     -H "Content-Type: application/json" \
     -d '{
       "ip": "203.0.113.66",
       "permanent": true,
       "reason": "CRITICAL: SQL injection attempt - INC-SQLi-001"
     }'
   ```

2. **Revoke any tokens from attacking IP**
   ```bash
   # Get tokens used from this IP
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{"ip": "203.0.113.66", "limit": 100}' | \
     jq -r '.[] | .token_id' | sort -u > tokens_to_revoke.txt

   # Revoke each token
   while read token_id; do
     curl -X POST http://127.0.0.1:8080/admin/tokens/revoke \
       -H "Content-Type: application/json" \
       -d "{
         \"token_id\": \"$token_id\",
         \"reason\": \"CRITICAL: Associated with SQL injection - INC-SQLi-001\"
       }"
   done < tokens_to_revoke.txt
   ```

3. **Consider emergency lockdown**
   ```bash
   # If multiple injection attempts or unclear if successful
   curl -X POST http://127.0.0.1:8080/admin/security/emergency_lockdown \
     -H "Content-Type: application/json" \
     -d '{
       "reason": "CRITICAL: SQL injection investigation in progress",
       "initiated_by": "incident_commander@example.com"
     }'
   ```

4. **Notify stakeholders immediately**
   - Security team (all hands)
   - Engineering leadership
   - Legal/Compliance (potential data breach)
   - Prepare for possible public disclosure

#### Phase 3: INVESTIGATE (8-30 minutes)

**Objective:** Determine if injection succeeded and what data was accessed

1. **Analyze injection payload**
   ```bash
   # Get full injection attempt details
   curl http://127.0.0.1:8080/admin/security/threats/details?threat_type=sql_injection \
     > injection_details.json

   # Review payload
   jq -r '.[] | .payload' injection_details.json

   # Common injection types:
   # - ' OR '1'='1' → Authentication bypass
   # - UNION SELECT → Data extraction
   # - DROP TABLE → Data destruction
   # - xp_cmdshell → Command execution (SQL Server)
   ```

2. **Check database logs for suspicious queries**
   ```bash
   # SpaceTime uses JSON storage, check for unusual file access
   ls -ltr C:/godot/data/*.json

   # Check for new files or recently modified files
   find C:/godot/data -type f -name "*.json" -mmin -60

   # Review Godot debug logs for database operations
   grep -i "load\|save\|query" logs/godot_*.log | tail -n 100
   ```

3. **Identify affected data**
   ```bash
   # What endpoint was targeted?
   # Example: /api/scene/load → scene files accessed

   # Check if any data was modified
   git diff --stat C:/godot/data/  # If using version control

   # Check file modification times
   stat C:/godot/data/scenes/*.json
   ```

4. **Build evidence package**
   ```bash
   # Export all security events from attacker
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{"ip": "203.0.113.66", "limit": 10000}' > evidence_attacker_activity.json

   # Export injection threat details
   cp injection_details.json evidence_injection_attempts.json

   # Copy relevant application logs
   cp logs/godot_*.log evidence_application_logs.txt

   # Create evidence package
   tar -czf evidence_INC-SQLi-001_$(date +%Y%m%d_%H%M%S).tar.gz evidence_*
   ```

5. **Determine breach scope**
   - **Data read:** What tables/files could attacker see?
   - **Data modified:** Any CREATE/UPDATE/DELETE operations?
   - **Data exfiltrated:** Large response sizes?
   - **Privilege escalation:** Admin access gained?

#### Phase 4: ERADICATE (30-90 minutes)

**Objective:** Remove vulnerability and any attacker persistence

1. **Identify vulnerable code**
   ```bash
   # Search for SQL-like operations in codebase
   grep -r "query\|execute\|load.*json" scripts/ addons/

   # Focus on user input handling
   grep -r "get_param\|request.*data\|user.*input" scripts/http_api/
   ```

2. **Verify input validation in place**
   ```bash
   # Check if InputValidator is used
   grep -r "InputValidator" scripts/http_api/

   # Verify scene whitelist active
   curl http://127.0.0.1:8080/admin/config | jq '.scene_validation'
   ```

3. **Apply immediate patch**
   ```bash
   # If vulnerability found, apply code fix
   # Example: Add input validation to vulnerable endpoint

   # Test fix
   python tests/security/test_input_validation.py

   # Deploy patched version
   # (Follow deployment procedures)
   ```

4. **Check for backdoors**
   ```bash
   # Check for new admin tokens
   curl http://127.0.0.1:8080/admin/tokens/list | \
     jq '.[] | select(.created_at >= 1234560000)'

   # Check for new role assignments
   curl http://127.0.0.1:8080/admin/rbac/list_assignments | \
     jq '.[] | select(.assigned_at >= 1234560000)'

   # Check for unauthorized scene files
   find C:/godot/data -type f -name "*.json" -newermt "2024-01-15 10:00"
   ```

5. **Data integrity check**
   ```bash
   # Verify critical data integrity
   python scripts/data_integrity_check.py

   # If data corruption found, restore from backup
   # (See SECURITY_RUNBOOKS.md - Backup and Recovery)
   ```

#### Phase 5: RECOVER (90-120 minutes)

**Objective:** Return to normal operations with enhanced security

1. **Deploy security enhancements**
   ```bash
   # Strengthen input validation
   # Update IDS rules for SQL injection
   nano C:/godot/config/ids_rules.json

   # Add additional patterns if attack used novel technique

   # Reload IDS configuration
   curl -X POST http://127.0.0.1:8080/admin/security/ids/reload_config
   ```

2. **Restore data if needed**
   ```bash
   # If data corruption found
   # Restore from last known good backup
   # (Document which data was restored)
   ```

3. **Lift emergency lockdown** (if applied)
   ```bash
   # Only after:
   # - Vulnerability patched
   # - No ongoing injection attempts
   # - Security team approves

   curl -X POST http://127.0.0.1:8080/admin/security/deactivate_lockdown \
     -H "Content-Type: application/json" \
     -d '{
       "reason": "SQL injection vulnerability patched and verified",
       "authorized_by": "security_lead@example.com"
     }'
   ```

4. **Enhanced monitoring**
   ```bash
   # Monitor for 72 hours post-incident
   watch -n 300 'curl -s http://127.0.0.1:8080/admin/security/threats/summary'

   # Set up alerts for any SQL injection attempts
   ```

#### Phase 6: LESSONS LEARNED (Within 24 hours)

**Objective:** Mandatory post-incident review for all SQL injection incidents

1. **Root cause analysis**
   - How did input validation fail?
   - Why wasn't this caught in testing?
   - What security controls were bypassed?

2. **Legal/Compliance requirements**
   - Was personal data accessed? → Data breach notification may be required
   - Document for compliance report
   - Consult with legal team

3. **Security improvements**
   - [ ] Add database activity monitoring
   - [ ] Implement prepared statements (if applicable)
   - [ ] Enhanced input validation
   - [ ] Additional security testing
   - [ ] Code review of all input handlers

### Success Criteria

- [ ] Attacker IP permanently banned
- [ ] All attacker tokens revoked
- [ ] No successful data extraction confirmed
- [ ] Vulnerability identified and patched
- [ ] No backdoors found
- [ ] Data integrity verified
- [ ] Legal/compliance notified
- [ ] Incident fully documented

### Escalation Triggers

Automatic escalation:
- All SQL injection attempts are P0
- Immediate notification to Security Lead, CTO
- Legal team notified if data breach suspected

---

## Playbook 3: Privilege Escalation Attempt

### Overview

**Attack Type:** Privilege Escalation
**Severity:** P1 (High) - Urgent response required
**MITRE ATT&CK:** T1068 (Exploitation for Privilege Escalation)
**Common Indicators:**
- Authorization failures for admin endpoints
- Non-admin token attempting privileged operations
- Role manipulation attempts
- Token tampering detected

### Detection

**Automated Alerts:**
```
Alert: Unauthorized Admin Access Attempt
Token ID: tok_readonly_123
Requested Permission: ADMIN_TOKENS
Endpoint: /admin/tokens/list
Source IP: 192.168.1.100
Alert ID: ALT-PrivEsc-20240115-001
```

### Response Steps

#### Phase 1: ASSESS (0-5 minutes)

1. **Review privilege escalation attempt**
   ```bash
   # Get authorization failure details
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{
       "event_type": "authorization",
       "result": "failure",
       "limit": 100
     }' | jq '.[] | select(.details.permission | contains("ADMIN"))'

   # Extract: token_id, IP, attempted permissions, frequency
   ```

2. **Identify the token and its current role**
   ```bash
   # Get token details
   TOKEN_ID="tok_readonly_123"
   curl http://127.0.0.1:8080/admin/rbac/get_role?token_id=$TOKEN_ID

   # Get token information
   curl http://127.0.0.1:8080/admin/tokens/info?token_id=$TOKEN_ID
   ```

3. **Determine if token is compromised or misconfigured**
   ```bash
   # Check token usage history
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d "{\"token_id\": \"$TOKEN_ID\", \"limit\": 500}" > token_history.json

   # Analyze patterns:
   # - Normal activity + sudden privilege attempts → Compromised
   # - Consistent privilege attempts → Configuration error or malicious
   # - First use is privilege attempt → Stolen/leaked token
   ```

4. **Classify severity**
   - Legitimate service with wrong role → P2 (misconfiguration)
   - Unknown source attempting admin access → P1 (attack)
   - Multiple tokens from same IP → P1 (coordinated attack)
   - Token manipulation detected → P0 (critical)

#### Phase 2: CONTAIN (5-10 minutes)

1. **Revoke suspicious token immediately**
   ```bash
   curl -X POST http://127.0.0.1:8080/admin/tokens/revoke \
     -H "Content-Type: application/json" \
     -d "{
       \"token_id\": \"$TOKEN_ID\",
       \"reason\": \"Unauthorized privilege escalation attempt - INC-PrivEsc-001\"
     }"
   ```

2. **Ban source IP**
   ```bash
   SOURCE_IP="192.168.1.100"
   curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
     -H "Content-Type: application/json" \
     -d "{
       \"ip\": \"$SOURCE_IP\",
       \"permanent\": false,
       \"duration_seconds\": 7200,
       \"reason\": \"Privilege escalation attempt - INC-PrivEsc-001\"
     }"
   ```

3. **Check for other tokens from same source**
   ```bash
   # Find all tokens used from this IP
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d "{\"ip\": \"$SOURCE_IP\", \"limit\": 1000}" | \
     jq -r '.[] | .token_id' | sort -u

   # Consider revoking all if attack is confirmed
   ```

#### Phase 3: INVESTIGATE (10-30 minutes)

1. **Determine how token was obtained**
   ```bash
   # When was token created?
   curl http://127.0.0.1:8080/admin/tokens/info?token_id=$TOKEN_ID | jq '.created_at'

   # Who created it? (check audit logs)
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{"event_type": "token_generated", "limit": 100}' | \
     jq ".[] | select(.details.token_id == \"$TOKEN_ID\")"
   ```

2. **Check for successful privilege escalations**
   ```bash
   # Were any admin operations successful?
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d "{
       \"token_id\": \"$TOKEN_ID\",
       \"result\": \"success\",
       \"limit\": 500
     }" | jq '.[] | select(.details.permission | contains("ADMIN"))'

   # If ANY found → ESCALATE TO P0
   ```

3. **Check for role manipulation**
   ```bash
   # Check if attacker tried to modify roles
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{"event_type": "role_assignment", "limit": 100}' | \
     jq ".[] | select(.ip == \"$SOURCE_IP\")"

   # Check for suspicious role assignments around same time
   ```

4. **Analyze attack technique**
   ```bash
   # Check endpoints attempted
   jq -r '.[] | .endpoint' token_history.json | sort | uniq -c | sort -rn

   # Common patterns:
   # - /admin/tokens/* → Trying to generate new admin tokens
   # - /admin/rbac/* → Trying to assign admin role
   # - /admin/security/* → Trying to unban IPs or disable security
   ```

#### Phase 4: ERADICATE (30-60 minutes)

1. **Verify RBAC is functioning correctly**
   ```bash
   # Test RBAC with different roles
   python tests/security/test_rbac.py

   # Check for authorization bypass vulnerabilities
   ```

2. **Review all active tokens and roles**
   ```bash
   # List all admin tokens
   curl http://127.0.0.1:8080/admin/rbac/list_assignments | \
     jq '.[] | select(.role_name == "admin")'

   # Verify each admin token is legitimate
   # Revoke any suspicious tokens
   ```

3. **Check for backdoors**
   ```bash
   # New admin tokens created recently?
   curl http://127.0.0.1:8080/admin/tokens/list | \
     jq '.[] | select(.created_at >= 1234560000)' | \
     jq 'select(.role_name == "admin")'

   # Unauthorized role escalations?
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{"event_type": "role_assignment", "limit": 200}'
   ```

4. **Strengthen authorization controls**
   ```bash
   # Review RBAC permission mappings
   # Ensure least privilege principle
   # Document all admin token purposes
   ```

#### Phase 5: RECOVER (60-90 minutes)

1. **Regenerate token if legitimate service**
   ```bash
   # If this was a misconfigured legitimate service:

   # Generate new token with correct role
   curl -X POST http://127.0.0.1:8080/admin/tokens/generate | \
     jq -r '.token.token_secret'

   # Assign appropriate role (e.g., developer, not admin)
   curl -X POST http://127.0.0.1:8080/admin/rbac/assign_role \
     -H "Content-Type: application/json" \
     -d '{
       "token_id": "<new_token_id>",
       "role_name": "developer",
       "assigned_by": "security_team@example.com"
     }'

   # Provide to service owner
   # Document in token inventory
   ```

2. **Monitor for additional attempts**
   ```bash
   # Watch authorization failures
   watch -n 60 'curl -s http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d "{\"event_type\": \"authorization\", \"result\": \"failure\", \"limit\": 20}"'
   ```

3. **Update alerting rules**
   ```bash
   # Lower threshold for privilege escalation alerts if needed
   # Add specific alerts for admin endpoint access from non-admin tokens
   ```

#### Phase 6: LESSONS LEARNED

1. **Document incident**
   - How was token obtained/compromised?
   - What permissions were attempted?
   - Any successful escalations?
   - Response effectiveness?

2. **Preventive measures**
   - [ ] Implement token lifecycle management
   - [ ] Regular token audits (monthly)
   - [ ] Least privilege by default
   - [ ] Additional logging for privileged operations
   - [ ] Alert on all admin endpoint access

### Success Criteria

- [ ] Malicious token revoked
- [ ] Source IP banned
- [ ] No successful privilege escalations
- [ ] RBAC functioning correctly
- [ ] No backdoors found
- [ ] Token inventory updated
- [ ] Incident documented

---

## Playbook 4: DDoS Attack

### Overview

**Attack Type:** Distributed Denial of Service
**Severity:** P1 (High) - Service impact
**MITRE ATT&CK:** T1499 (Endpoint Denial of Service)
**Common Indicators:**
- Massive spike in request rate
- Multiple IPs sending rapid requests
- Service degradation or outage
- High CPU/memory usage

### Detection

**Automated Alerts:**
```
Alert: Sustained High Request Rate
Current Rate: 5000 req/sec (baseline: 50 req/sec)
Unique IPs: 150
Alert ID: ALT-DDoS-20240115-001
```

### Response Steps

#### Phase 1: ASSESS (0-3 minutes)

1. **Confirm DDoS attack**
   ```bash
   # Check current request rate
   curl http://127.0.0.1:8080/metrics | grep request_rate

   # Get threat summary
   curl http://127.0.0.1:8080/admin/security/threats/summary

   # Check number of attacking IPs
   curl http://127.0.0.1:8080/admin/security/threats/by_type?type=rapid_requests | \
     jq -r '.[] | .ip' | sort -u | wc -l
   ```

2. **Assess service impact**
   ```bash
   # Check system health
   curl http://127.0.0.1:8080/status

   # Check response times
   curl http://127.0.0.1:8080/metrics | grep response_time

   # Check if service is responding
   # Timeout indicates service degradation
   timeout 5 curl http://127.0.0.1:8080/health
   ```

3. **Determine attack pattern**
   - **Volume attack:** High bandwidth consumption
   - **Protocol attack:** SYN floods, fragmented packets
   - **Application layer:** HTTP floods, API abuse

#### Phase 2: CONTAIN (3-15 minutes)

**Objective:** Restore service availability immediately

1. **Enable aggressive rate limiting**
   ```bash
   # Reduce rate limits by 70%
   curl -X POST http://127.0.0.1:8080/admin/security/rate_limits/tighten \
     -H "Content-Type: application/json" \
     -d '{"factor": 0.3, "duration_seconds": 3600}'
   ```

2. **Ban attacking IPs (bulk operation)**
   ```bash
   # Extract attacking IPs
   curl http://127.0.0.1:8080/admin/security/threats/by_type?type=rapid_requests | \
     jq -r '.[] | .ip' | sort -u > ddos_ips.txt

   # Ban top 100 attackers
   head -100 ddos_ips.txt | while read ip; do
     curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
       -H "Content-Type: application/json" \
       -d "{
         \"ip\": \"$ip\",
         \"permanent\": false,
         \"duration_seconds\": 14400,
         \"reason\": \"DDoS attack participant - INC-DDoS-001\"
       }"
   done &
   ```

3. **Enable DDoS protection mode** (if available)
   ```bash
   curl -X POST http://127.0.0.1:8080/admin/security/ddos_protection \
     -H "Content-Type: application/json" \
     -d '{"enabled": true, "strictness": "high"}'
   ```

4. **Coordinate with infrastructure team**
   ```
   Actions needed:
   - Enable CDN DDoS protection (Cloudflare, AWS Shield)
   - Increase rate limits at load balancer
   - Scale up infrastructure (if cloud-based)
   - Enable geo-blocking if attack from specific regions
   ```

5. **If service remains degraded - Emergency lockdown**
   ```bash
   curl -X POST http://127.0.0.1:8080/admin/security/emergency_lockdown \
     -H "Content-Type: application/json" \
     -d '{
       "reason": "CRITICAL: DDoS attack causing service outage",
       "initiated_by": "incident_commander@example.com"
     }'
   ```

#### Phase 3: INVESTIGATE (Concurrent with containment)

1. **Analyze attack characteristics**
   ```bash
   # Get attacking IP distribution
   curl http://127.0.0.1:8080/admin/security/threats/by_type?type=rapid_requests | \
     jq -r '.[] | .ip' | cut -d. -f1-2 | sort | uniq -c | sort -rn

   # Check geographic distribution (if available)

   # Check user agents
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{"limit": 1000}' | jq -r '.[] | .details.user_agent' | \
     sort | uniq -c | sort -rn | head -20
   ```

2. **Identify attack type**
   - All IPs hit same endpoint → Targeted attack
   - Distributed across endpoints → Generic DDoS
   - Legitimate-looking requests → Application-layer attack
   - Malformed requests → Protocol attack

3. **Check for secondary objectives**
   ```bash
   # Is DDoS a distraction?
   # Check for simultaneous attacks:
   curl http://127.0.0.1:8080/admin/security/threats/summary

   # Look for SQL injection, privilege escalation during DDoS
   ```

#### Phase 4: ERADICATE (15-45 minutes)

1. **Continue banning attacking IPs**
   ```bash
   # Automated ban loop
   while true; do
     curl http://127.0.0.1:8080/admin/security/threats/by_type?type=rapid_requests | \
       jq -r '.[] | .ip' | sort -u | while read ip; do
         curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
           -H "Content-Type: application/json" \
           -d "{\"ip\": \"$ip\", \"permanent\": false, \"duration_seconds\": 7200}"
       done
     sleep 60
   done &

   BAN_LOOP_PID=$!
   # Kill when attack stops: kill $BAN_LOOP_PID
   ```

2. **Implement permanent mitigations**
   ```bash
   # Add IP ranges to permanent blocklist if botnet identified
   # Example: Known botnet ranges

   # Update IDS rules to detect this attack pattern in future
   nano C:/godot/config/ids_rules.json
   ```

3. **Scale infrastructure** (if needed)
   ```bash
   # Increase server capacity
   # Add more API instances
   # Enable auto-scaling
   ```

#### Phase 5: RECOVER (45-90 minutes)

1. **Gradually restore normal operations**
   ```bash
   # Monitor request rate
   watch -n 30 'curl -s http://127.0.0.1:8080/metrics | grep request_rate'

   # When rate returns to normal:
   # - Lift emergency lockdown (if activated)
   # - Restore normal rate limits
   # - Start unbanning IPs after 2 hours
   ```

2. **Remove temporary restrictions**
   ```bash
   # Reset rate limits to normal
   curl -X POST http://127.0.0.1:8080/admin/security/rate_limits/reset

   # Lift lockdown
   curl -X POST http://127.0.0.1:8080/admin/security/deactivate_lockdown \
     -H "Content-Type: application/json" \
     -d '{
       "reason": "DDoS attack mitigated, service restored",
       "authorized_by": "security_lead@example.com"
     }'
   ```

3. **Monitor for recurrence**
   ```bash
   # Enhanced monitoring for 24 hours
   # Alert on request rate >200% baseline
   ```

#### Phase 6: LESSONS LEARNED

1. **Evaluate response effectiveness**
   - Time to detection?
   - Time to mitigation?
   - Service downtime duration?
   - Customer impact?

2. **Infrastructure improvements**
   - [ ] CDN/DDoS protection service
   - [ ] Auto-scaling configuration
   - [ ] Rate limiting at load balancer
   - [ ] Geographic restrictions

### Success Criteria

- [ ] Service restored to normal operations
- [ ] Request rate returned to baseline
- [ ] Attacking IPs banned
- [ ] No service degradation
- [ ] DDoS protection measures implemented

---

## Playbook 5: Compromised Credentials

### Overview

**Attack Type:** Credential Compromise
**Severity:** P1 (High) - Immediate access revocation required
**MITRE ATT&CK:** T1078 (Valid Accounts)
**Common Indicators:**
- Token used from unusual location
- Token used with unusual pattern
- Token leaked in logs or public repository
- User reports suspicious activity

### Detection

**Automated Alerts:**
```
Alert: Suspicious Token Usage Pattern
Token ID: tok_api_service_123
New IP: 203.0.113.77 (Previous: 192.168.1.50)
Geographic Change: US → Russia
Alert ID: ALT-CompCred-20240115-001
```

### Response Steps

#### Phase 1: ASSESS (0-5 minutes)

1. **Verify credential compromise**
   ```bash
   # Get token usage history
   TOKEN_ID="tok_api_service_123"
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d "{\"token_id\": \"$TOKEN_ID\", \"limit\": 1000}" > token_usage.json

   # Analyze for anomalies:
   # - New IPs
   # - Geographic changes
   # - Unusual times
   # - Different user agents
   # - Permission changes
   ```

2. **Determine compromise source**
   ```bash
   # Check if token was leaked in logs
   grep -r "$TOKEN_SECRET" logs/

   # Check if token committed to git
   git log --all --full-history -- "*token*" "*secret*"

   # Check public repositories (GitHub, GitLab)
   # Search for: project name + "token" or "secret"
   ```

3. **Assess potential damage**
   ```bash
   # What permissions does token have?
   curl http://127.0.0.1:8080/admin/rbac/get_role?token_id=$TOKEN_ID

   # What operations were performed?
   jq '.[] | select(.result == "success") | .endpoint' token_usage.json | \
     sort | uniq -c

   # Was sensitive data accessed?
   # Were configuration changes made?
   # Were new tokens created?
   ```

#### Phase 2: CONTAIN (5-10 minutes)

**Objective:** Revoke access immediately

1. **Revoke compromised token**
   ```bash
   curl -X POST http://127.0.0.1:8080/admin/tokens/revoke \
     -H "Content-Type: application/json" \
     -d "{
       \"token_id\": \"$TOKEN_ID\",
       \"reason\": \"URGENT: Credential compromise detected - INC-CompCred-001\"
     }"
   ```

2. **Ban suspicious IPs**
   ```bash
   # Extract IPs from suspicious usage
   jq -r '.[] | select(.ip != "192.168.1.50") | .ip' token_usage.json | \
     sort -u | while read ip; do
       curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
         -H "Content-Type: application/json" \
         -d "{
           \"ip\": \"$ip\",
           \"permanent\": true,
           \"reason\": \"Compromised credential usage - INC-CompCred-001\"
         }"
     done
   ```

3. **Check for related compromised tokens**
   ```bash
   # If token was leaked in git, all tokens in that commit are compromised
   # If token in config file, entire config may be compromised

   # List tokens created around same time
   curl http://127.0.0.1:8080/admin/tokens/list | \
     jq ".[] | select(.created_at >= ($TOKEN_CREATED - 86400) and .created_at <= ($TOKEN_CREATED + 86400))"

   # Consider revoking related tokens
   ```

#### Phase 3: INVESTIGATE (10-30 minutes)

1. **Build timeline of compromise**
   ```bash
   # First suspicious usage?
   jq '.[] | select(.ip != "192.168.1.50") | .timestamp' token_usage.json | \
     sort -n | head -1

   # All actions taken after compromise
   jq ".[] | select(.timestamp >= $COMPROMISE_TIME)" token_usage.json
   ```

2. **Identify what attacker did**
   ```bash
   # Successful operations
   jq '.[] | select(.result == "success" and .ip != "192.168.1.50")' token_usage.json

   # Check for:
   # - Data exfiltration (large responses)
   # - Configuration changes
   # - New token generation
   # - Role manipulations
   # - Scene modifications
   ```

3. **Check for persistence mechanisms**
   ```bash
   # Did attacker create new tokens?
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{"event_type": "token_generated", "limit": 100}' | \
     jq ".[] | select(.token_id == \"$TOKEN_ID\")"

   # Did attacker escalate privileges?
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{"event_type": "role_assignment", "limit": 100}' | \
     jq ".[] | select(.token_id == \"$TOKEN_ID\")"

   # Check for backdoors in scene files or scripts
   ```

#### Phase 4: ERADICATE (30-60 minutes)

1. **Remove token from all locations**
   ```bash
   # Remove from git history if committed
   # (Use git-filter-repo or BFG Repo-Cleaner)

   # Remove from configuration files
   # Replace with placeholder

   # Remove from logs
   # Rotate logs if token in plaintext
   ```

2. **Revoke tokens created by attacker**
   ```bash
   # Get all tokens created during compromise
   # Review and revoke suspicious tokens
   ```

3. **Remove any backdoors**
   ```bash
   # Check for unauthorized code changes
   git diff <before_compromise> <after_compromise>

   # Review scene files for malicious modifications
   # Check for unauthorized admin accounts
   ```

4. **Rotate related secrets**
   ```bash
   # If token was in config file with other secrets:
   # - Rotate database passwords
   # - Rotate API keys
   # - Rotate encryption keys
   ```

#### Phase 5: RECOVER (60-90 minutes)

1. **Generate replacement token**
   ```bash
   # Generate new token for legitimate service
   curl -X POST http://127.0.0.1:8080/admin/tokens/generate \
     -H "Content-Type: application/json" \
     -d '{"lifetime_hours": 720}' > new_token.json

   # Assign appropriate role
   NEW_TOKEN_ID=$(jq -r '.token.token_id' new_token.json)
   curl -X POST http://127.0.0.1:8080/admin/rbac/assign_role \
     -H "Content-Type: application/json" \
     -d "{
       \"token_id\": \"$NEW_TOKEN_ID\",
       \"role_name\": \"api_client\",
       \"assigned_by\": \"security_team@example.com\"
     }"
   ```

2. **Update service configuration**
   ```bash
   # Securely provide new token to service owner
   # Use encrypted channel (1Password, Vault, etc.)
   # Do NOT email or Slack token in plaintext

   # Update service configuration
   # Test service functionality
   ```

3. **Monitor for additional compromise indicators**
   ```bash
   # Watch for suspicious activity from same IPs
   # Monitor new token for unusual patterns
   # Check for attempts to access old token
   ```

#### Phase 6: LESSONS LEARNED

1. **Root cause**
   - How was token compromised?
   - Git commit? Log exposure? MITM?
   - What can prevent this in future?

2. **Preventive measures**
   - [ ] Scan git history for secrets
   - [ ] Implement secret scanning (GitHub Advanced Security)
   - [ ] Use environment variables, not config files
   - [ ] Implement token rotation schedule
   - [ ] Secret management system (Vault, AWS Secrets Manager)
   - [ ] Log sanitization (remove tokens from logs)

### Success Criteria

- [ ] Compromised token revoked
- [ ] Attacker IPs banned
- [ ] All attacker-created resources removed
- [ ] Replacement token generated and deployed
- [ ] Service functioning normally
- [ ] No persistent access confirmed
- [ ] Secrets rotation completed

---

## Playbook 6: System Breach (Suspected)

### Overview

**Attack Type:** System Compromise / Breach
**Severity:** P0 (Critical) - All hands on deck
**MITRE ATT&CK:** Multiple tactics (Full kill chain)
**Common Indicators:**
- Unexplained system changes
- Unauthorized admin access
- Data exfiltration detected
- Multiple simultaneous alerts
- Insider report of suspicious activity

### Detection

**Multiple Alerts or Indicators:**
```
CRITICAL: Multiple security events detected
- Unauthorized admin access
- Data exfiltration attempt
- New admin token created
- Suspicious file modifications
Alert ID: ALT-Breach-20240115-001
```

### Response Steps

#### Phase 1: ASSESS (0-10 minutes)

⚠️ **CRITICAL: System breach - Activate incident response team immediately**

1. **Convene incident response team**
   ```
   IMMEDIATELY:
   - Page Security Lead (PagerDuty P0)
   - Page CTO
   - Page Engineering Leadership
   - Open war room (Zoom + Slack #incident-20240115-breach)
   - Assign roles:
     - Incident Commander
     - Technical Leads (2-3)
     - Communications Lead
     - Scribe
     - Legal/Compliance liaison
   ```

2. **Initial assessment**
   ```bash
   # Get comprehensive security status
   curl http://127.0.0.1:8080/admin/security/status > status_snapshot.json

   # Get all recent alerts
   curl http://127.0.0.1:8080/admin/security/threats/summary > threats_snapshot.json

   # Export audit logs immediately
   curl http://127.0.0.1:8080/admin/audit/export > breach_audit_$(date +%Y%m%d_%H%M%S).jsonl
   ```

3. **Determine breach scope**
   ```bash
   # Check all indicators:
   # - Unauthorized access?
   # - Data exfiltration?
   # - System modifications?
   # - Privilege escalation?
   # - Backdoors installed?
   # - Multiple attack vectors?
   ```

4. **Assess business impact**
   ```
   Questions to answer:
   - Is service currently operational?
   - Is customer data at risk?
   - Is intellectual property compromised?
   - Are financial systems affected?
   - Is this a ransomware attack?
   ```

#### Phase 2: CONTAIN (10-30 minutes)

**Objective:** Stop attacker access and prevent further damage

**DECISION POINT:** Full lockdown vs. monitored containment

**Option A: Emergency Lockdown** (Recommended for active breach)
```bash
# 1. Activate emergency lockdown
curl -X POST http://127.0.0.1:8080/admin/security/emergency_lockdown \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "P0: Suspected system breach in progress",
    "initiated_by": "incident_commander@example.com"
  }'

# 2. Revoke ALL tokens
curl -X POST http://127.0.0.1:8080/admin/tokens/revoke_all \
  -H "Content-Type: application/json" \
  -d '{
    "confirmation": "REVOKE_ALL",
    "reason": "P0: System breach - INC-Breach-001"
  }'

# 3. Ban all suspicious IPs
# (Extract from audit logs and ban)

# 4. Consider shutting down service entirely
# (Requires executive approval)
```

**Option B: Monitored Containment** (If attacker access understood)
```bash
# 1. Revoke specific compromised credentials only
# 2. Ban known attacker IPs
# 3. Close identified attack vectors
# 4. Monitor attacker actions (honeypot)
```

#### Phase 3: INVESTIGATE (30 minutes - 4 hours)

**Objective:** Full forensic analysis - DO NOT RUSH THIS PHASE

1. **Preserve evidence**
   ```bash
   # Create forensic snapshot
   mkdir -p evidence/INC-Breach-001_$(date +%Y%m%d_%H%M%S)
   cd evidence/INC-Breach-001_*

   # Export all logs
   curl http://127.0.0.1:8080/admin/audit/export > audit_full.jsonl
   cp -r /path/to/godot/logs/* ./logs_snapshot/

   # Export security state
   curl http://127.0.0.1:8080/admin/security/threats/export > threats.json
   curl http://127.0.0.1:8080/admin/tokens/export > tokens.json
   curl http://127.0.0.1:8080/admin/rbac/export > rbac.json

   # System snapshot
   tar -czf system_snapshot.tar.gz C:/godot/config/ C:/godot/data/

   # Create chain of custody document
   echo "Evidence collected: $(date)" > chain_of_custody.txt
   echo "Collected by: $(whoami)" >> chain_of_custody.txt
   shasum -a 256 * >> chain_of_custody.txt
   ```

2. **Build complete attack timeline**
   ```bash
   # Analyze audit logs chronologically
   jq -r '.[] | [.timestamp, .event_type, .ip, .result] | @csv' audit_full.jsonl | \
     sort -n > timeline.csv

   # Identify:
   # - Initial compromise time
   # - Attack progression
   # - Pivot points
   # - Data accessed
   # - Systems affected
   ```

3. **Identify patient zero**
   ```bash
   # How did attacker gain initial access?
   # - Compromised credentials?
   # - Vulnerability exploitation?
   # - Social engineering?
   # - Insider threat?
   # - Supply chain attack?
   ```

4. **Map attack kill chain**
   ```
   MITRE ATT&CK Mapping:
   1. Initial Access: T1078 (Valid Accounts)
   2. Execution: ?
   3. Persistence: ?
   4. Privilege Escalation: ?
   5. Defense Evasion: ?
   6. Credential Access: ?
   7. Discovery: ?
   8. Lateral Movement: ?
   9. Collection: ?
   10. Exfiltration: ?
   11. Impact: ?
   ```

5. **Determine data breach scope**
   ```bash
   # What data was accessed?
   jq '.[] | select(.result == "success") | .endpoint' audit_full.jsonl | \
     sort | uniq -c | sort -rn

   # Check for data exfiltration
   jq '.[] | select(.response_size > 1000000)' audit_full.jsonl

   # Identify compromised data categories:
   # - Personal data (PII)
   # - Financial data
   # - Health data
   # - Intellectual property
   # - Authentication credentials
   ```

6. **Identify backdoors and persistence**
   ```bash
   # Check for new tokens
   jq '.[] | select(.event_type == "token_generated")' audit_full.jsonl

   # Check for role escalations
   jq '.[] | select(.event_type == "role_assignment")' audit_full.jsonl

   # Check for file modifications
   find C:/godot -type f -mtime -7 -ls

   # Check for suspicious processes
   # Check for network connections
   # Check for scheduled tasks
   ```

#### Phase 4: ERADICATE (2-8 hours)

**Objective:** Remove all attacker access and restore to known-good state

**DECISION POINT:** Restore from backup vs. remediate in place

**Option A: Restore from Backup** (Cleanest approach)
```bash
# 1. Identify last known-good backup (before compromise)
# 2. Verify backup integrity
# 3. Restore system from backup
# 4. Apply security patches
# 5. Regenerate all secrets
# 6. Verify no compromise in backup
```

**Option B: Remediate in Place** (Faster but riskier)
```bash
# 1. Revoke all attacker-created tokens
# 2. Remove unauthorized code changes
# 3. Remove backdoors
# 4. Patch vulnerabilities
# 5. Rotate all secrets
# 6. Rebuild compromised components
```

**Detailed Steps:**

1. **Remove all attacker access**
   ```bash
   # Revoke every token used by attacker
   # Ban all attacker IPs (permanent)
   # Remove SSH keys (if applicable)
   # Reset passwords for compromised accounts
   ```

2. **Remove backdoors**
   ```bash
   # Check for unauthorized code
   git diff <before_breach> <after_breach>

   # Remove malicious files
   # Remove unauthorized scheduled tasks
   # Close unauthorized ports
   # Remove unauthorized user accounts
   ```

3. **Patch vulnerabilities**
   ```bash
   # How did attacker gain access?
   # Apply security patches
   # Update dependencies
   # Fix code vulnerabilities
   # Strengthen security controls
   ```

4. **Rotate ALL secrets**
   ```bash
   # Generate new tokens for all services
   # Rotate API keys
   # Rotate database passwords
   # Rotate encryption keys
   # Rotate signing keys
   ```

5. **Verify clean state**
   ```bash
   # Run security scans
   # Check for IOCs (Indicators of Compromise)
   # Verify no unauthorized access remains
   # Test security controls
   ```

#### Phase 5: RECOVER (4-24 hours)

**Objective:** Return to normal operations with enhanced security

1. **Gradual service restoration**
   ```bash
   # Start with minimal services
   # Test thoroughly
   # Monitor closely
   # Gradually add functionality
   ```

2. **Regenerate all credentials**
   ```bash
   # Generate new tokens for all services
   # Update service configurations
   # Provide to service owners securely
   # Document in inventory
   ```

3. **Enhanced monitoring**
   ```bash
   # 24/7 monitoring for 2 weeks
   # Lower alert thresholds
   # Additional logging
   # Behavioral analysis
   ```

4. **Communications**
   ```
   Internal:
   - All-hands meeting
   - Incident summary
   - Lessons learned

   External (if required):
   - Customer notification
   - Regulatory reporting
   - Public disclosure
   - Press statement
   ```

5. **Legal/Compliance actions**
   ```
   - Data breach notification (if required)
   - Regulatory reporting (GDPR, HIPAA, etc.)
   - Law enforcement notification (if criminal)
   - Insurance claim (if cyber insurance)
   ```

#### Phase 6: LESSONS LEARNED (Within 1 week)

**Mandatory for all P0 incidents**

1. **Full post-incident review**
   - Timeline reconstruction
   - Root cause analysis
   - Response effectiveness
   - What worked / what didn't

2. **Comprehensive remediation plan**
   - [ ] Security architecture changes
   - [ ] New security controls
   - [ ] Enhanced monitoring
   - [ ] Staff training
   - [ ] Policy updates
   - [ ] Technology investments

3. **External audit**
   - Consider third-party security assessment
   - Penetration testing
   - Compliance audit

### Success Criteria

- [ ] Attacker access completely removed
- [ ] All backdoors eliminated
- [ ] Vulnerabilities patched
- [ ] All secrets rotated
- [ ] Service restored securely
- [ ] Enhanced monitoring in place
- [ ] Legal/compliance requirements met
- [ ] Post-incident review completed
- [ ] Remediation plan implemented

### Critical Reminders

- **Preserve evidence** - Do not destroy logs or data
- **Chain of custody** - Document all evidence handling
- **Legal approval** - Consult legal before external communications
- **Do not rush** - Thorough investigation critical
- **Assume worst case** - Until proven otherwise

---

## Playbook 7: Data Exfiltration Attempt

### Overview

**Attack Type:** Data Exfiltration
**Severity:** P0 (Critical) - Potential data breach
**MITRE ATT&CK:** T1041 (Exfiltration Over C2 Channel)
**Common Indicators:**
- Unusually large response sizes
- Bulk data access patterns
- Suspicious file downloads
- Database dump attempts

### Detection

**Automated Alerts:**
```
Alert: Potential Data Exfiltration
Token ID: tok_suspicious_123
Response Size: 50 MB (avg: 10 KB)
Endpoint: /api/data/export
Alert ID: ALT-Exfil-20240115-001
```

### Response Steps

#### Phase 1: ASSESS (0-5 minutes)

1. **Confirm data exfiltration attempt**
   ```bash
   # Check for large responses
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d '{"limit": 1000}' | \
     jq '.[] | select(.response_size > 10000000)' > large_responses.json

   # Analyze pattern
   jq -r '.[] | [.timestamp, .ip, .endpoint, .response_size] | @csv' large_responses.json
   ```

2. **Identify what data was accessed**
   ```bash
   # What endpoints were hit?
   jq -r '.[] | .endpoint' large_responses.json | sort | uniq -c

   # What data types:
   # - Scene files?
   # - Configuration?
   # - User data?
   # - Database dumps?
   ```

3. **Determine exfiltration volume**
   ```bash
   # Total data transferred
   jq '[.[] | .response_size] | add' large_responses.json

   # Over what time period?
   ```

#### Phase 2: CONTAIN (5-10 minutes)

1. **Stop exfiltration immediately**
   ```bash
   # Revoke token
   TOKEN_ID=$(jq -r '.[0].token_id' large_responses.json)
   curl -X POST http://127.0.0.1:8080/admin/tokens/revoke \
     -H "Content-Type: application/json" \
     -d "{
       \"token_id\": \"$TOKEN_ID\",
       \"reason\": \"CRITICAL: Data exfiltration detected - INC-Exfil-001\"
     }"

   # Ban source IP
   SOURCE_IP=$(jq -r '.[0].ip' large_responses.json)
   curl -X POST http://127.0.0.1:8080/admin/security/ban_ip \
     -H "Content-Type: application/json" \
     -d "{
       \"ip\": \"$SOURCE_IP\",
       \"permanent\": true,
       \"reason\": \"CRITICAL: Data exfiltration attempt\"
     }"
   ```

2. **Check for ongoing exfiltration**
   ```bash
   # Monitor for additional attempts
   watch -n 5 'curl -s http://127.0.0.1:8080/metrics | grep response_size'
   ```

#### Phase 3: INVESTIGATE (10-60 minutes)

1. **Determine what data was stolen**
   ```bash
   # Build complete list of accessed resources
   jq -r '.[] | .endpoint' large_responses.json | sort | uniq > accessed_endpoints.txt

   # For each endpoint, determine data type and sensitivity
   # Example:
   # /api/scene/list → Scene names (low sensitivity)
   # /api/config/export → Configuration (high sensitivity, may contain secrets)
   # /api/user/list → User data (PII, high sensitivity)
   ```

2. **Check for data breach**
   ```bash
   # Was personal data accessed? → GDPR breach notification required
   # Was financial data accessed? → PCI-DSS requirements
   # Was health data accessed? → HIPAA requirements
   ```

3. **Identify exfiltration method**
   ```bash
   # How was data extracted?
   # - API calls?
   # - Database queries?
   # - File downloads?
   # - Screenshot/screen scraping?
   ```

4. **Build attacker profile**
   ```bash
   # Full activity timeline
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d "{\"token_id\": \"$TOKEN_ID\", \"limit\": 10000}" > attacker_full_activity.json

   # IP geolocation
   # User agent analysis
   # Access patterns
   ```

#### Phase 4: ERADICATE (60-120 minutes)

1. **Close exfiltration vectors**
   ```bash
   # Add rate limiting to bulk export endpoints
   # Add size limits to responses
   # Require additional authentication for sensitive data
   # Implement data access monitoring
   ```

2. **Revoke compromised credentials**
   ```bash
   # How did attacker get token?
   # Rotate related credentials
   ```

3. **Review and strengthen access controls**
   ```bash
   # Apply least privilege
   # Add data classification
   # Implement DLP (Data Loss Prevention)
   ```

#### Phase 5: RECOVER (2-4 hours)

1. **Assess damage**
   ```
   - What data was stolen?
   - What is the business impact?
   - Are customers affected?
   - Is competitive advantage lost?
   ```

2. **Legal/Regulatory compliance**
   ```
   REQUIRED ACTIONS if personal data breached:
   - Notify data protection authority (72 hours under GDPR)
   - Notify affected individuals
   - Document breach in register
   - Assess need for public disclosure
   ```

3. **Enhanced monitoring**
   ```bash
   # Monitor for:
   # - Data appearing on dark web
   # - Ransom demands
   # - Additional exfiltration attempts
   # - Use of stolen data
   ```

#### Phase 6: LESSONS LEARNED

1. **Root cause**
   - How was exfiltration possible?
   - What controls failed?

2. **Preventive measures**
   - [ ] Data Loss Prevention (DLP) system
   - [ ] Response size limits
   - [ ] Rate limiting on bulk operations
   - [ ] Data classification
   - [ ] Access monitoring and alerting
   - [ ] Anomaly detection

### Success Criteria

- [ ] Exfiltration stopped
- [ ] Attacker access revoked
- [ ] Data breach scope determined
- [ ] Legal/regulatory requirements met
- [ ] Enhanced controls implemented
- [ ] Monitoring in place

---

## Playbook 8: Insider Threat

### Overview

**Attack Type:** Insider Threat
**Severity:** P1-P0 (Depends on actions)
**MITRE ATT&CK:** T1078 (Valid Accounts)
**Common Indicators:**
- Unusual data access by employee
- Access outside normal working hours
- Large data downloads
- Accessing unauthorized systems
- Behavioral changes reported by colleagues

### Detection

**Report or Alert:**
```
Report: Suspicious Employee Activity
Employee: john.doe@company.com
Token ID: tok_johndoe_dev
Actions: Downloaded all scene files, exported configuration
Time: 2:00 AM (outside normal hours)
Alert ID: ALT-Insider-20240115-001
```

### Response Steps

#### Phase 1: ASSESS (0-30 minutes)

⚠️ **SENSITIVE:** Handle with extreme discretion

1. **Verify insider threat indicators**
   ```bash
   # Review employee's token activity
   EMPLOYEE_TOKEN="tok_johndoe_dev"
   curl http://127.0.0.1:8080/admin/audit/query \
     -H "Content-Type: application/json" \
     -d "{\"token_id\": \"$EMPLOYEE_TOKEN\", \"limit\": 5000}" > employee_activity.json

   # Analyze for suspicious patterns:
   # - Off-hours access (nights, weekends)
   # - Bulk data access
   # - Accessing systems outside role
   # - Unusual endpoints
   # - Geographic anomalies
   ```

2. **Determine severity**
   ```bash
   # What data was accessed?
   jq -r '.[] | .endpoint' employee_activity.json | sort | uniq -c | sort -rn

   # Was sensitive data accessed?
   # Was data exported?
   # Were security controls disabled?
   # Were other accounts accessed?
   ```

3. **Consult HR and Legal**
   ```
   BEFORE TAKING ACTION:
   - Inform HR
   - Inform Legal
   - Discuss evidence
   - Plan coordinated response
   - Consider employment law implications
   ```

4. **Classification:**
   - Unintentional policy violation → Handle through HR (not security incident)
   - Suspicious but ambiguous → Continued monitoring
   - Clear malicious intent → P1 incident response
   - Active data theft → P0 incident response

#### Phase 2: CONTAIN (30-60 minutes)

**DECISION: Overt vs. Covert Response**

**Overt Response:** (Employee knows access is revoked)
```bash
# 1. Revoke employee's tokens
curl -X POST http://127.0.0.1:8080/admin/tokens/revoke \
  -H "Content-Type: application/json" \
  -d "{
    \"token_id\": \"$EMPLOYEE_TOKEN\",
    \"reason\": \"Security investigation in progress\"
  }"

# 2. Disable other access:
# - Email access
# - VPN access
# - Building access
# - Cloud services

# 3. Immediate meeting with employee and HR
```

**Covert Response:** (Continue monitoring to gather evidence)
```bash
# 1. Do NOT revoke access yet
# 2. Enable enhanced logging for employee
# 3. Monitor all activity closely
# 4. Build evidence package
# 5. Coordinate with legal on timing
```

#### Phase 3: INVESTIGATE (1-4 hours)

**Objective:** Build comprehensive evidence while respecting privacy and employment law

1. **Build complete activity timeline**
   ```bash
   # All actions by employee
   jq -r '.[] | [.timestamp, .endpoint, .ip, .result, .response_size] | @csv' \
     employee_activity.json | sort -n > insider_timeline.csv

   # Identify:
   # - When did suspicious activity start?
   # - What data was accessed?
   # - How much data was downloaded?
   # - Any attempts to cover tracks?
   ```

2. **Determine motivation** (with HR input)
   ```
   Possible motivations:
   - Financial gain (selling data)
   - Revenge (disgruntled employee)
   - Competitive advantage (moving to competitor)
   - Espionage (foreign actor)
   - Unintentional (policy misunderstanding)
   ```

3. **Assess damage**
   ```bash
   # What was stolen?
   # What is the value?
   # Intellectual property loss?
   # Competitive advantage lost?
   # Regulatory implications?
   ```

4. **Check for accomplices**
   ```bash
   # Are other employees involved?
   # Check for coordinated activities
   # Check for shared resources
   ```

5. **Gather evidence**
   ```bash
   # Export all employee activity
   curl http://127.0.0.1:8080/admin/audit/export > insider_evidence.jsonl

   # Create evidence package
   mkdir evidence/INC-Insider-001
   cp employee_activity.json evidence/INC-Insider-001/
   cp insider_timeline.csv evidence/INC-Insider-001/
   # Include: screenshots, logs, emails (with legal approval)

   # Chain of custody documentation
   ```

#### Phase 4: ERADICATE (Coordinated with HR/Legal)

**Objective:** Remove access while preserving evidence and following employment law

1. **Employment action** (HR leads this)
   ```
   Options:
   - Termination (for cause)
   - Suspension (pending investigation)
   - Written warning
   - Retraining
   ```

2. **Revoke all access**
   ```bash
   # Revoke tokens
   curl -X POST http://127.0.0.1:8080/admin/tokens/revoke \
     -H "Content-Type: application/json" \
     -d "{
       \"token_id\": \"$EMPLOYEE_TOKEN\",
       \"reason\": \"Employment terminated\"
     }"

   # Coordinate with IT:
   # - Disable email
   # - Disable VPN
   # - Disable badge access
   # - Remote wipe laptop
   # - Disable cloud access
   ```

3. **Secure employee workstation**
   ```
   - Image hard drive (for forensics)
   - Collect physical devices
   - Review browser history
   - Check external media
   ```

4. **Legal actions** (if warranted)
   ```
   - Cease and desist letter
   - Lawsuit for breach of contract
   - Report to law enforcement (if criminal)
   - Notification to new employer
   ```

#### Phase 5: RECOVER (1-5 days)

1. **Damage control**
   ```
   - What competitive advantage was lost?
   - Can we mitigate impact?
   - Accelerate product release?
   - Change strategic plans?
   ```

2. **Organizational changes**
   ```
   - Review access controls
   - Implement enhanced monitoring
   - Revise employee policies
   - Additional training
   - Background checks
   ```

3. **Morale management**
   ```
   - All-hands meeting (carefully worded)
   - Reassure remaining employees
   - Address security without fear-mongering
   ```

#### Phase 6: LESSONS LEARNED

1. **Preventive measures**
   - [ ] Behavioral analytics for anomaly detection
   - [ ] Data Loss Prevention (DLP)
   - [ ] Privileged access management
   - [ ] Enhanced background checks
   - [ ] Employee monitoring policy
   - [ ] Non-compete agreements
   - [ ] Exit interviews with access review

2. **Policy updates**
   - [ ] Acceptable use policy
   - [ ] Data handling policy
   - [ ] Security awareness training
   - [ ] Insider threat program

### Success Criteria

- [ ] Threat contained (access revoked)
- [ ] Evidence preserved
- [ ] Employment action taken (per HR/Legal)
- [ ] Data loss assessed
- [ ] Legal actions initiated (if warranted)
- [ ] Enhanced controls implemented
- [ ] Team morale addressed

### Special Considerations

- **Privacy:** Balance security with employee privacy rights
- **Employment Law:** Follow local laws regarding monitoring and termination
- **Evidence:** Maintain chain of custody for potential legal action
- **Discretion:** Limit knowledge of investigation to need-to-know
- **HR/Legal:** Always coordinate with HR and Legal departments

---

## Appendices

### Appendix A: Communication Templates

#### Internal Notification (P0 Incident)

```
Subject: [P0] Security Incident - Immediate Action Required

Team,

We are experiencing a critical security incident (P0).

What happened:
[Brief description]

Current status:
- Incident response team activated
- Service [operational/degraded/offline]
- Customer impact: [description]

Actions required:
- Do not discuss externally
- Join war room: #incident-YYYYMMDD
- Await further instructions

Incident Commander: [Name]
Next update: [Time]

[Name]
Security Team
```

#### Customer Notification (Data Breach)

```
Subject: Important Security Notice - [Company Name]

Dear [Customer],

We are writing to inform you of a security incident that may have affected your data.

What happened:
On [date], we discovered that an unauthorized party gained access to [system].
The following data may have been affected: [list data types].

What we're doing:
- Immediately revoked attacker access
- Engaged cybersecurity firm for forensic analysis
- Enhanced security controls
- Notified law enforcement

What you should do:
- Change your password immediately
- Enable two-factor authentication
- Monitor your accounts for suspicious activity
- [Additional recommendations]

We take your security seriously and apologize for this incident.

For questions: security@company.com

[Name]
Security Team
```

### Appendix B: Evidence Collection Checklist

- [ ] Export all audit logs
- [ ] Screenshot security alerts
- [ ] Collect system logs
- [ ] Capture network traffic
- [ ] Image compromised systems
- [ ] Document timeline
- [ ] Record witness statements
- [ ] Preserve email communications
- [ ] Collect attacker artifacts
- [ ] Create chain of custody document
- [ ] Calculate evidence hash values
- [ ] Secure evidence storage

### Appendix C: Post-Incident Review Agenda

1. **Incident Summary** (5 min)
   - What happened
   - Timeline
   - Impact

2. **Detection** (10 min)
   - How was it detected?
   - Time to detection?
   - Alerting effectiveness?

3. **Response** (20 min)
   - Actions taken
   - What worked well?
   - What didn't work?
   - Gaps identified?

4. **Technical Analysis** (15 min)
   - Root cause
   - Attack vector
   - Vulnerabilities exploited

5. **Business Impact** (10 min)
   - Financial cost
   - Reputational damage
   - Customer impact

6. **Action Items** (15 min)
   - Short-term fixes
   - Long-term improvements
   - Owners and timelines

7. **Lessons Learned** (10 min)
   - Key takeaways
   - Runbook updates
   - Training needs

### Appendix D: Useful Commands Quick Reference

```bash
# Emergency lockdown
curl -X POST http://127.0.0.1:8080/admin/security/emergency_lockdown

# Revoke token
curl -X POST http://127.0.0.1:8080/admin/tokens/revoke -d '{"token_id":"xxx"}'

# Ban IP
curl -X POST http://127.0.0.1:8080/admin/security/ban_ip -d '{"ip":"1.2.3.4","permanent":true}'

# Export audit logs
curl http://127.0.0.1:8080/admin/audit/export > audit_$(date +%Y%m%d).jsonl

# View active threats
curl http://127.0.0.1:8080/admin/security/threats/summary

# Security status
curl http://127.0.0.1:8080/admin/security/status
```

---

## Document Maintenance

**Last Updated:** 2025-12-02
**Next Review:** 2025-03-02 (or after any P0/P1 incident)
**Owner:** Security Incident Response Team

**Post-Incident Updates:**
After each P0 or P1 incident, update relevant playbook with:
- New techniques observed
- Response improvements
- Additional detection methods
- Lessons learned

**Feedback:** security-incidents@spacetime-vr.com
