# Rollback Procedures - SpaceTime VR

Comprehensive guide for multi-level rollback and recovery procedures in production environments.

## Table of Contents

- [Overview](#overview)
- [Rollback Decision Tree](#rollback-decision-tree)
- [Level 1: Quick Rollback](#level-1-quick-rollback)
- [Level 2: Full Rollback](#level-2-full-rollback)
- [Level 3: Point-in-Time Recovery](#level-3-point-in-time-recovery)
- [Safety Mechanisms](#safety-mechanisms)
- [Validation Procedures](#validation-procedures)
- [Emergency Procedures](#emergency-procedures)
- [Post-Rollback Actions](#post-rollback-actions)
- [Common Issues](#common-issues)
- [Rollback History](#rollback-history)

## Overview

SpaceTime VR implements a three-level rollback strategy designed to provide rapid recovery from production issues while maintaining data integrity and minimizing downtime.

### Recovery Time Objectives (RTO)

| Level | RTO | Use Case | Data Changes |
|-------|-----|----------|--------------|
| Level 1 | < 5 min | Application crashes, critical bugs | None |
| Level 2 | < 15 min | Major issues, configuration errors | Migration rollback |
| Level 3 | < 30 min | Data corruption, security breach | Full restore |

### Recovery Point Objectives (RPO)

- **Level 1**: Current state (no data loss)
- **Level 2**: Last deployment (possible minor data loss)
- **Level 3**: Last backup point (configurable data loss window)

### Rollback Strategy Overview

```
Issue Detected
      │
      ▼
┌─────────────────────────────────────┐
│   Assess Severity & Impact          │
│   - Service availability             │
│   - Data integrity                   │
│   - User impact                      │
│   - Security implications            │
└──────────────┬──────────────────────┘
               │
               ▼
      ┌────────────────┐
      │ Select Level   │
      └────────────────┘
               │
       ┌───────┴───────┬──────────────┐
       │               │              │
       ▼               ▼              ▼
   Level 1         Level 2        Level 3
 Quick Switch    Full Rollback   Point-in-Time
   < 5 min         < 15 min        < 30 min
```

## Rollback Decision Tree

### When to Rollback

Use this decision tree to determine if and when to rollback:

```
┌─────────────────────────────────────┐
│     Is the service down?            │
└──────────┬──────────────────────────┘
           │
     YES ──┴── NO
      │         │
      │         ▼
      │   ┌─────────────────────────────┐
      │   │ Error rate > 10%?           │
      │   └──────┬──────────────────────┘
      │          │
      │    YES ──┴── NO
      │     │         │
      │     │         ▼
      │     │   ┌─────────────────────────┐
      │     │   │ Response time > 5s?     │
      │     │   └──────┬──────────────────┘
      │     │          │
      │     │    YES ──┴── NO
      │     │     │         │
      │     │     │         ▼
      │     │     │   ┌─────────────────────┐
      │     │     │   │ Data corruption?    │
      │     │     │   └──────┬──────────────┘
      │     │     │          │
      │     │     │    YES ──┴── NO
      │     │     │     │         │
      │     │     │     │         ▼
      ▼     ▼     ▼     ▼   ┌─────────────┐
┌─────────────────────────┐ │   Monitor   │
│   ROLLBACK IMMEDIATELY  │ │  Continue   │
└─────────────────────────┘ └─────────────┘
```

### Severity Classification

**CRITICAL (Rollback immediately):**
- Complete service outage
- Data corruption detected
- Security breach discovered
- Error rate > 50%
- Database failure

**HIGH (Rollback if not resolved in 5 minutes):**
- Partial service degradation
- Error rate 10-50%
- Response time > 5s sustained
- Memory leak detected
- Failed health checks

**MEDIUM (Consider rollback if not resolved in 15 minutes):**
- Minor performance degradation
- Error rate 5-10%
- Response time 2-5s sustained
- Non-critical feature failures

**LOW (Monitor, log issue):**
- Isolated errors
- Error rate < 5%
- Minor UI issues
- Non-user-facing issues

## Level 1: Quick Rollback

**Target Time:** < 5 minutes
**Use Case:** Application crashes, critical bugs, immediate traffic switch
**Data Impact:** None (no data changes)

### How It Works

Level 1 rollback uses blue-green deployment pattern to instantly switch traffic back to the previous stable version without any data changes.

```
Current State:
┌──────────┐      Traffic      ┌──────────┐
│  Green   │ ◄──────────────── │   Load   │
│ (Failed) │                   │ Balancer │
└──────────┘                   └─────┬────┘
                                     │
┌──────────┐                         │
│   Blue   │ ────────────────────────┘
│ (Stable) │    (No Traffic)
└──────────┘

After Level 1 Rollback:
┌──────────┐                   ┌──────────┐
│  Green   │                   │   Load   │
│(Stopped) │                   │ Balancer │
└──────────┘                   └─────┬────┘
                                     │
┌──────────┐      Traffic      ┌────▼────┐
│   Blue   │ ◄──────────────── │         │
│ (Active) │                   └─────────┘
└──────────┘
```

### Execution Steps

#### Step 1: Assess Situation (30 seconds)

```bash
# Check current deployment status
docker-compose ps

# Check which environment is active
curl http://localhost/health | jq .environment

# Check error logs
docker-compose logs --tail=100 | grep ERROR
```

**Decision Point:** If errors are critical and affecting users, proceed to Step 2.

#### Step 2: Verify Previous Environment (1 minute)

```bash
# Check if previous (blue) environment is healthy
docker-compose -p spacetime-blue ps

# Verify blue environment health
curl http://localhost:8080/status | jq

# Expected: overall_ready should be true
```

**Decision Point:** If previous environment is healthy, proceed to Step 3. If not, skip to Level 2.

#### Step 3: Execute Quick Rollback (2 minutes)

```bash
# Run quick rollback script
cd /opt/spacetime/production
bash deploy/rollback/rollback.sh --quick

# Alternative: Manual quick rollback
bash deploy/rollback/rollback.sh --level 1 --auto-confirm
```

**What happens:**
1. Traffic switches from green to blue (< 10 seconds)
2. Health checks verify blue environment (30 seconds)
3. Green environment gracefully stops (1 minute)
4. Final validation (30 seconds)

#### Step 4: Validation (1.5 minutes)

```bash
# Verify rollback success
bash deploy/rollback/validate_rollback.sh

# Check service health
curl http://localhost/status | jq

# Monitor for 2 minutes
watch -n 5 'curl -s http://localhost/health | jq'
```

### Level 1 Success Criteria

- ✅ Traffic switched in < 10 seconds
- ✅ Previous environment healthy
- ✅ All health checks passing
- ✅ Error rate returned to normal (< 1%)
- ✅ Response time < 500ms
- ✅ Total rollback time < 5 minutes

### When Level 1 Fails

If Level 1 rollback fails (previous environment unhealthy), immediately escalate to **Level 2**.

```bash
# Escalate to Level 2
bash deploy/rollback/rollback.sh --level 2 --target <backup-id>
```

## Level 2: Full Rollback

**Target Time:** < 15 minutes
**Use Case:** Major issues, data corruption, failed Level 1
**Data Impact:** Database migration rollback (possible data loss)

### How It Works

Level 2 performs a complete rollback including:
- Application deployment
- Database schema migrations
- Configuration files
- Environment variables

```
┌────────────────────────────────────────┐
│  Current State (Failed)                │
│  - Application v2.5.0                  │
│  - Database schema v105                │
│  - Config version 2024-12-02           │
└────────────────────────────────────────┘
                  │
                  ▼ Level 2 Rollback
                  │
┌────────────────────────────────────────┐
│  Restored State                        │
│  - Application v2.4.9                  │
│  - Database schema v104                │
│  - Config version 2024-12-01           │
└────────────────────────────────────────┘
```

### Execution Steps

#### Step 1: Preparation (2 minutes)

```bash
# Identify rollback target
cd /opt/spacetime/production
bash deploy/rollback/rollback.sh --list

# Example output:
#   1  20251202-150045  (current - failed)
#   2  20251202-143022  (previous - stable) ← Target
#   3  20251201-160034
#   4  20251201-120015

# Set rollback target
ROLLBACK_TARGET="20251202-143022"
```

**Decision Point:** Confirm target is the last known good deployment.

#### Step 2: Safety Backup (2 minutes)

```bash
# Automatic safety backup is created by rollback script
# Manual safety backup (if needed):
bash deploy/backup_current_state.sh
```

**What's backed up:**
- Current container states
- Current configuration files
- Current data volumes (light snapshot)
- Current database schema version

#### Step 3: Execute Full Rollback (8 minutes)

```bash
# Run Level 2 rollback
bash deploy/rollback/rollback.sh \
  --level 2 \
  --target $ROLLBACK_TARGET

# This executes:
# 1. Stops current deployment (1 min)
# 2. Rolls back database migrations (3 min)
# 3. Restores configuration (1 min)
# 4. Deploys previous version (2 min)
# 5. Waits for health (1 min)
```

**Detailed substeps:**

**2.1 - Stop Current Deployment**
```bash
# Graceful shutdown (30s timeout)
docker-compose down --timeout 30
```

**2.2 - Rollback Database Migrations**
```bash
# Executed automatically by rollback script
bash deploy/rollback/rollback_database.sh $ROLLBACK_TARGET

# What happens:
# - Identifies migrations to rollback
# - Creates database safety backup
# - Executes migration rollback scripts
# - Verifies database integrity
```

**2.3 - Restore Configuration**
```bash
# Executed automatically by rollback script
bash deploy/rollback/rollback_config.sh $ROLLBACK_TARGET

# What happens:
# - Restores docker-compose.yml
# - Restores .env file
# - Restores nginx configuration
# - Restores monitoring configuration
# - Reloads services
```

**2.4 - Deploy Previous Version**
```bash
# Load previous image tag
export IMAGE_TAG=$(cat backups/$ROLLBACK_TARGET/images.txt | grep spacetime | cut -d: -f2)

# Start services with previous configuration
docker-compose -f backups/$ROLLBACK_TARGET/docker-compose.yml up -d
```

**2.5 - Wait for Health**
```bash
# Automatic health monitoring (max 5 minutes)
# Checks every 5 seconds for:
# - Container status
# - Health checks
# - HTTP API availability
```

#### Step 4: Validation (3 minutes)

```bash
# Run comprehensive validation
bash deploy/rollback/validate_rollback.sh --thorough

# Manual validation
docker-compose ps                    # All containers running
curl http://localhost/status | jq   # overall_ready: true
bash deploy/smoke_tests.sh          # All tests pass
```

### Level 2 Success Criteria

- ✅ Database rollback completed successfully
- ✅ All containers healthy
- ✅ HTTP API responding correctly
- ✅ Database queries working
- ✅ No data corruption markers
- ✅ All smoke tests passing
- ✅ Total rollback time < 15 minutes

### Database Migration Rollback

Level 2 includes automatic database migration rollback:

**Method 1: Migration Rollback Scripts (Preferred)**

```sql
-- Example: Migration 105 -> 104 rollback script
-- File: migrations/rollback/105_add_user_preferences_down.sql

BEGIN;

-- Remove new columns
ALTER TABLE users DROP COLUMN IF EXISTS preferences;

-- Restore old structure
-- (if needed)

-- Update schema version
DELETE FROM schema_migrations WHERE version = 105;

COMMIT;
```

**Method 2: Database Restore (Fallback)**

If migration rollback scripts fail:
1. Database is restored from backup
2. Data since backup is lost (RPO applies)
3. Transaction logs may be replayed if available

### When Level 2 Fails

If Level 2 rollback fails (database corruption, schema conflicts), immediately escalate to **Level 3**.

```bash
# Escalate to Level 3
bash deploy/rollback/rollback.sh --level 3 --target <backup-id>
```

## Level 3: Point-in-Time Recovery

**Target Time:** < 30 minutes
**Use Case:** Data corruption, security breach, failed Level 2
**Data Impact:** Restore to backup point (RPO data loss)

### How It Works

Level 3 is a complete system restore from backup:
- Full data volume restoration
- Database restore from dump
- Transaction log replay (if available)
- Complete configuration restoration
- Comprehensive data integrity validation

```
┌─────────────────────────────────────────┐
│  Corrupted State                        │
│  - Data corruption detected             │
│  - Database inconsistencies             │
│  - Unrecoverable state                  │
└─────────────────────────────────────────┘
                    │
                    ▼ Level 3 Recovery
                    │
┌─────────────────────────────────────────┐
│  Backup Point (20251202-120000)         │
│  - Data volumes restored                │
│  - Database restored from dump          │
│  - Transaction logs replayed            │
│  - Data integrity verified              │
└─────────────────────────────────────────┘
```

### Execution Steps

#### Step 1: Emergency Assessment (3 minutes)

```bash
# Assess damage
docker-compose exec godot ls -la /data/
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "SELECT COUNT(*) FROM users"

# Check for corruption markers
docker-compose exec godot cat /data/corruption_detected

# Identify recovery point
ls -lt /opt/spacetime/backups/

# Decision: Select last known good backup
RECOVERY_POINT="20251202-120000"
```

**Critical Decision:** Confirm recovery point with stakeholders if possible (data loss implications).

#### Step 2: Complete Shutdown (2 minutes)

```bash
# Immediate shutdown of all services
docker-compose down --volumes --timeout 60

# Verify all stopped
docker ps | grep spacetime
# Should return nothing
```

#### Step 3: Data Volume Restoration (10 minutes)

```bash
# Executed automatically by rollback script
# Manual process shown for reference:

# Remove corrupted volumes
docker volume rm spacetime_godot-data

# Create fresh volume
docker volume create spacetime_godot-data

# Restore from backup
docker run --rm \
  -v spacetime_godot-data:/data \
  -v /opt/spacetime/backups/$RECOVERY_POINT:/backup \
  alpine sh -c "cd /data && tar xzf /backup/data.tar.gz --strip-components=1"

# Verify restoration
docker run --rm -v spacetime_godot-data:/data alpine ls -la /data
```

#### Step 4: Database Restoration (8 minutes)

```bash
# Start database container only
docker-compose up -d postgres
sleep 10

# Drop corrupted database
docker-compose exec postgres psql -U spacetime -d postgres \
  -c "DROP DATABASE IF EXISTS spacetime_db"

# Recreate database
docker-compose exec postgres psql -U spacetime -d postgres \
  -c "CREATE DATABASE spacetime_db"

# Restore from backup dump
gunzip -c /opt/spacetime/backups/$RECOVERY_POINT/database.sql.gz | \
  docker-compose exec -T postgres psql -U spacetime -d spacetime_db

# Verify table count
docker-compose exec postgres psql -U spacetime -d spacetime_db \
  -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'"
```

#### Step 5: Transaction Log Replay (3 minutes)

```bash
# If available, replay WAL logs for minimal data loss
if [ -f /opt/spacetime/backups/$RECOVERY_POINT/transaction_logs.tar.gz ]; then
  echo "Replaying transaction logs..."

  # Extract WAL files
  gunzip -c /opt/spacetime/backups/$RECOVERY_POINT/transaction_logs.tar.gz | \
    docker-compose exec -T postgres sh -c "tar x -C /var/lib/postgresql/data/pg_wal"

  # PostgreSQL will automatically replay on startup
  docker-compose restart postgres
  sleep 20
fi
```

#### Step 6: Configuration Restoration (2 minutes)

```bash
# Restore all configuration files
bash deploy/rollback/rollback_config.sh $RECOVERY_POINT
```

#### Step 7: Service Startup (3 minutes)

```bash
# Load correct image version
export IMAGE_TAG=$(cat /opt/spacetime/backups/$RECOVERY_POINT/images.txt | grep spacetime | cut -d: -f2)

# Start all services
docker-compose up -d

# Wait for health
timeout 180 bash -c '
  until curl -sf http://localhost:8080/status | jq -e ".overall_ready == true" > /dev/null; do
    echo "Waiting for services..."
    sleep 5
  done
'
```

#### Step 8: Data Integrity Verification (5 minutes)

```bash
# Comprehensive data integrity checks
bash deploy/rollback/validate_rollback.sh --thorough

# Additional manual checks:

# Check database integrity
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "
  SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
  FROM pg_tables
  WHERE schemaname = 'public'
  ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
"

# Verify no corruption markers
docker-compose exec godot test ! -f /data/corruption_detected
echo "Corruption check: $?"  # Should be 0 (success)

# Check critical data
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "
  SELECT
    (SELECT COUNT(*) FROM users) as user_count,
    (SELECT COUNT(*) FROM sessions) as session_count,
    (SELECT COUNT(*) FROM game_state) as game_state_count
"
```

#### Step 9: Comprehensive Validation (4 minutes)

```bash
# Run full validation suite
bash deploy/rollback/validate_rollback.sh --thorough

# Run smoke tests
bash deploy/smoke_tests.sh

# Monitor system for 5 minutes
python tests/health_monitor.py --duration 300
```

### Level 3 Success Criteria

- ✅ Data volumes fully restored
- ✅ Database fully restored
- ✅ Transaction logs replayed (if available)
- ✅ No data corruption detected
- ✅ All database tables present
- ✅ Critical data verified
- ✅ All containers healthy
- ✅ All health checks passing
- ✅ Smoke tests passing
- ✅ Total recovery time < 30 minutes

### Data Loss Assessment

After Level 3 recovery, assess data loss:

```bash
# Compare backup timestamp with current time
BACKUP_TIME=$(cat /opt/spacetime/backups/$RECOVERY_POINT/timestamp.txt)
CURRENT_TIME=$(date +%s)
DATA_LOSS_SECONDS=$((CURRENT_TIME - BACKUP_TIME))
DATA_LOSS_MINUTES=$((DATA_LOSS_SECONDS / 60))

echo "Potential data loss window: $DATA_LOSS_MINUTES minutes"

# Check transaction logs
if [ -f /opt/spacetime/backups/$RECOVERY_POINT/transaction_logs.tar.gz ]; then
  echo "Transaction logs available - data loss minimized"
else
  echo "No transaction logs - full RPO data loss possible"
fi
```

**Communication:** Immediately inform stakeholders of data loss window and impact.

## Safety Mechanisms

All rollback levels include built-in safety mechanisms:

### Pre-Rollback Safety Checks

```bash
# Automatically executed by rollback script:
1. Verify running as appropriate user
2. Check required tools available (docker, curl, jq, etc.)
3. Verify Docker is running
4. Check backup directory exists
5. Detect ongoing critical operations
6. Require user confirmation
```

### Safety Backup

Before any rollback, a safety backup is automatically created:

```bash
# Safety backup includes:
- Current container states (JSON)
- Current configuration files
- Current image tags
- Current data snapshot (light)

# Location:
/opt/spacetime/backups/rollback-safety-YYYYMMDD-HHMMSS/

# Referenced in:
/opt/spacetime/state/last_safety_backup
```

### Rollback Target Validation

```bash
# Before rollback:
1. Verify target backup exists
2. Verify configuration files present
3. Check database version information
4. Verify data backup integrity (Level 3)
5. Validate checksums if available
6. Check for data dependencies
```

### Confirmation Requirements

```bash
# Interactive mode:
Type 'ROLLBACK' to confirm: _

# Displays:
- Rollback level
- Target version
- Environment
- Expected actions
- Estimated time

# Can be skipped with --auto-confirm for automation
```

### Circuit Breakers

```bash
# Rollback automatically fails if:
- Backup target doesn't exist
- Configuration files missing
- Database backup corrupted (Level 3)
- Checksum validation fails (Level 3)
- Pre-rollback checks fail
- Docker not running
```

## Validation Procedures

Post-rollback validation is critical. The validation script checks:

### Quick Validation (Default)

```bash
bash deploy/rollback/validate_rollback.sh

# Checks:
✓ Container status (all running)
✓ Container health (all healthy)
✓ HTTP API (/status, /health)
✓ Telemetry server
✓ Database connection
✓ Data integrity
✓ Network connectivity
✓ Resource usage
✓ Log errors
✓ Performance metrics
```

### Thorough Validation (--thorough)

```bash
bash deploy/rollback/validate_rollback.sh --thorough

# Additional checks:
✓ VR functionality
✓ Debug services (DAP, LSP)
✓ Full smoke test suite
✓ Extended monitoring
```

### Manual Validation Checklist

```bash
# 1. Container Health
docker-compose ps
# Expected: All containers "Up" and "healthy"

# 2. HTTP API
curl http://localhost:8080/status | jq
# Expected: overall_ready: true

# 3. Database
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "SELECT 1"
# Expected: Success

# 4. Data Integrity
docker-compose exec godot test ! -f /data/corruption_detected
# Expected: Exit code 0

# 5. Error Rate
curl 'http://localhost:9090/api/v1/query?query=rate(http_requests_total{status=~"5.."}[5m])'
# Expected: Near zero

# 6. Response Time
curl 'http://localhost:9090/api/v1/query?query=histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))'
# Expected: < 1 second

# 7. Smoke Tests
bash deploy/smoke_tests.sh
# Expected: All tests pass

# 8. Monitoring
python tests/health_monitor.py --duration 300
# Expected: No alerts for 5 minutes
```

## Emergency Procedures

### Complete Service Outage

**Symptom:** All services down, containers won't start

```bash
# 1. Check Docker
systemctl status docker
sudo systemctl restart docker

# 2. Check disk space
df -h
# If disk full:
docker system prune -af --volumes

# 3. Try with last known good version
export IMAGE_TAG=v2.4.9
docker-compose up -d

# 4. If still failing, restore from infrastructure backup
# Contact: Infrastructure team
```

### Database Corruption

**Symptom:** Database errors, data inconsistencies

```bash
# 1. IMMEDIATE SHUTDOWN
docker-compose down

# 2. Create emergency snapshot
docker run --rm \
  -v spacetime_godot-data:/data \
  -v /tmp:/backup \
  alpine tar czf /backup/emergency-$(date +%Y%m%d-%H%M%S).tar.gz /data

# 3. Execute Level 3 recovery
bash deploy/rollback/rollback.sh --level 3 --target <last-good-backup>

# 4. If Level 3 fails, contact database administrator
```

### Security Breach

**Symptom:** Unauthorized access, suspicious activity, security alerts

```bash
# 1. IMMEDIATE ISOLATION
docker-compose down

# 2. Block external access
sudo iptables -A INPUT -p tcp --dport 80 -j DROP
sudo iptables -A INPUT -p tcp --dport 443 -j DROP

# 3. Collect evidence
docker-compose logs > /tmp/incident-logs-$(date +%Y%m%d-%H%M%S).log
tar czf /tmp/evidence-$(date +%Y%m%d-%H%M%S).tar.gz /opt/spacetime/production/

# 4. Preserve forensic data
docker commit spacetime-godot spacetime-forensic:$(date +%Y%m%d-%H%M%S)

# 5. DO NOT RESTART until security team approves

# 6. Contact: Security team immediately
# 7. Follow: Security Incident Response Plan
```

### Rollback Failed

**Symptom:** Rollback script completed but services unhealthy

```bash
# 1. Gather diagnostics
docker-compose ps
docker-compose logs --tail=200
docker stats --no-stream
df -h

# 2. Try escalation
# If Level 1 failed, try Level 2:
bash deploy/rollback/rollback.sh --level 2 --target <backup-id>

# If Level 2 failed, try Level 3:
bash deploy/rollback/rollback.sh --level 3 --target <backup-id>

# 3. Try older backup
bash deploy/rollback/rollback.sh --list
# Select backup from 2+ versions ago
bash deploy/rollback/rollback.sh --level 3 --target <older-backup-id>

# 4. If all rollbacks fail:
# Contact: Senior operations team
# Escalate: Infrastructure team
# Last resort: Rebuild from infrastructure automation
```

### Network Issues

**Symptom:** Containers running but not accessible

```bash
# 1. Check container networking
docker network ls
docker network inspect spacetime_default

# 2. Check port bindings
docker-compose ps
netstat -tulpn | grep -E "(8080|8081|6006|6005)"

# 3. Check nginx configuration
docker-compose exec nginx nginx -t
docker-compose exec nginx nginx -s reload

# 4. Restart networking
docker-compose down
docker network prune -f
docker-compose up -d

# 5. Check firewall
sudo iptables -L -n
```

## Post-Rollback Actions

### Immediate Actions (0-15 minutes)

#### 1. Confirm Rollback Success

```bash
# Run validation
bash deploy/rollback/validate_rollback.sh

# Check all systems
docker-compose ps
curl http://localhost:8080/status | jq
bash deploy/smoke_tests.sh
```

#### 2. Monitor System

```bash
# Monitor for 15 minutes
python tests/health_monitor.py --duration 900 --host localhost

# Watch metrics
watch -n 10 'curl -s http://localhost:8080/status | jq'

# Monitor logs
docker-compose logs -f --tail=100
```

#### 3. Notify Stakeholders

**Internal Notification:**
```
Subject: Production Rollback - [Service Name]

Severity: [Critical/High/Medium]
Status: Rollback completed successfully
Environment: Production
Rollback Level: [1/2/3]
Target Version: [version]
Downtime: [X] minutes
Data Loss: [None/Minimal/Details]

Actions Taken:
- [List actions]

Current Status:
- All services healthy
- Error rate normal
- Response time normal

Next Steps:
- Continued monitoring for [X] hours
- Root cause analysis
- Fix in development

Contact: [On-call engineer]
```

**Customer Communication** (if applicable):
```
We experienced a brief service disruption between [start time] and [end time].
The issue has been resolved and all services are now operating normally.
We apologize for any inconvenience.
```

#### 4. Create Incident Report

```bash
# Create GitHub issue
gh issue create \
  --title "Production Rollback: [Brief Description]" \
  --label "incident,production,rollback" \
  --body "
## Incident Summary

**Date:** $(date)
**Severity:** [Critical/High/Medium]
**Duration:** [X] minutes
**Rollback Level:** [1/2/3]

## Timeline

- **[Time]:** Issue detected
- **[Time]:** Rollback initiated
- **[Time]:** Rollback completed
- **[Time]:** Services verified healthy

## Impact

- **Users Affected:** [Estimate]
- **Services Affected:** [List]
- **Data Loss:** [None/Details]

## Root Cause

[To be determined - will update after analysis]

## Resolution

Rolled back to version [X] using Level [1/2/3] rollback procedure.

## Next Steps

- [ ] Root cause analysis
- [ ] Fix implementation
- [ ] Testing in staging
- [ ] Post-mortem meeting
"
```

### Short-term Actions (15-60 minutes)

#### 5. Analyze Failure

```bash
# Review deployment logs
cat /opt/spacetime/production/logs/deployment-*.log

# Analyze error patterns
docker-compose logs --since 1h | grep -i error | sort | uniq -c

# Check metrics
# Open Grafana: http://localhost:3000
# Review: Error rate, response time, resource usage

# Compare configurations
diff /opt/spacetime/backups/[failed-version]/docker-compose.yml \
     /opt/spacetime/backups/[stable-version]/docker-compose.yml
```

#### 6. Identify Root Cause

**Common root causes:**

- **Code changes:** Review git diff between versions
- **Configuration changes:** Compare .env and config files
- **Database migrations:** Check migration scripts
- **Dependency updates:** Review package changes
- **Infrastructure changes:** Check for recent infra modifications
- **External dependencies:** Verify third-party service status

```bash
# Git diff between versions
git diff [stable-tag] [failed-tag]

# Check for risky changes
git diff [stable-tag] [failed-tag] -- \
  '*.sql' \
  'migrations/*' \
  'docker-compose.yml' \
  '.env*'
```

#### 7. Test Fix in Staging

```bash
# Create fix branch
git checkout -b fix/rollback-issue-[issue-number]

# Make fixes
# ...

# Test locally
docker-compose build
docker-compose up -d
bash deploy/smoke_tests.sh

# Deploy to staging
gh workflow run deploy-staging.yml \
  -f image_tag=$(git rev-parse --short HEAD)

# Run comprehensive tests in staging
ssh staging-server
cd /opt/spacetime/staging
python tests/test_runner.py --comprehensive

# Monitor staging for 2+ hours
python tests/health_monitor.py --duration 7200
```

### Long-term Actions (1+ hours)

#### 8. Develop Permanent Fix

```bash
# 1. Create detailed fix
# - Add regression tests
# - Update documentation
# - Add monitoring/alerting if needed

# 2. Code review
git push origin fix/rollback-issue-[issue-number]
gh pr create \
  --title "Fix: [Issue that caused rollback]" \
  --body "[Detailed description, root cause, solution]"

# 3. Get approval from team

# 4. Merge after approval
gh pr merge --squash
```

#### 9. Update Runbooks

```bash
# Update documentation
vim docs/operations/ROLLBACK_PROCEDURES.md

# Add to known issues
vim docs/KNOWN_ISSUES.md

# Update rollback procedures if needed
vim deploy/rollback/rollback.sh

# Commit changes
git add docs/ deploy/
git commit -m "docs: Update rollback procedures based on [incident]"
git push
```

#### 10. Post-Mortem

**Schedule post-mortem meeting (within 24-48 hours):**

```
Attendees:
- On-call engineer
- Development team lead
- Operations lead
- Product owner (if user-facing impact)

Agenda:
1. Timeline review
2. Root cause analysis
3. Impact assessment
4. What went well
5. What could be improved
6. Action items

Outputs:
- Post-mortem document
- Action items with owners
- Process improvements
- Documentation updates
```

**Post-mortem template:**

```markdown
# Post-Mortem: [Incident Title]

## Metadata
- **Date:** [Date]
- **Duration:** [X] minutes
- **Severity:** [Critical/High/Medium]
- **Services Affected:** [List]

## Executive Summary
[2-3 sentence summary of what happened]

## Timeline
- **[Time]:** [Event]
- **[Time]:** [Event]
[...]

## Root Cause
[Detailed explanation of what caused the issue]

## Impact
- **Users Affected:** [Number/percentage]
- **Revenue Impact:** [If applicable]
- **Data Loss:** [Details]

## Resolution
[How it was resolved]

## What Went Well
- [List things that worked well]

## What Could Be Improved
- [List areas for improvement]

## Action Items
- [ ] [Action 1] - Owner: [Name] - Due: [Date]
- [ ] [Action 2] - Owner: [Name] - Due: [Date]

## Lessons Learned
[Key takeaways]
```

## Common Issues

### Issue: Rollback Script Can't Find Backup

**Symptoms:**
```
[ERROR] Backup not found: 20251202-143022
```

**Solution:**
```bash
# List available backups
ls -la /opt/spacetime/backups/

# Verify backup path in script
echo $BACKUP_DIR

# If backup directory wrong, set correct path
export BACKUP_DIR=/correct/path/to/backups
bash deploy/rollback/rollback.sh --level 1 --target <backup-id>
```

### Issue: Docker Compose Not Found

**Symptoms:**
```
[ERROR] Required tool not found: docker-compose
```

**Solution:**
```bash
# Install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Issue: Containers Fail Health Checks

**Symptoms:**
```
[ERROR] Services did not become healthy in time
```

**Solution:**
```bash
# Check container logs
docker-compose logs godot

# Common causes:
# 1. Port already in use
netstat -tulpn | grep 8080
# Kill process using port if needed

# 2. Database not ready
docker-compose logs postgres
# Wait longer or increase timeout

# 3. Configuration error
docker-compose config
# Fix any validation errors

# Retry rollback with longer timeout
# (modify LEVEL1_TIMEOUT in rollback.sh)
```

### Issue: Database Migration Rollback Fails

**Symptoms:**
```
[DB-ROLLBACK] ERROR: Rollback script failed
```

**Solution:**
```bash
# Check migration rollback logs
cat /tmp/migration_rollback.log

# Common causes:
# 1. No rollback script exists
# Solution: Use full database restore (automatic fallback)

# 2. Schema conflict
# Solution: Manual intervention required
docker-compose exec postgres psql -U spacetime -d spacetime_db
# Manually fix schema issue

# 3. Data constraint violation
# Solution: May need Level 3 recovery
bash deploy/rollback/rollback.sh --level 3 --target <backup-id>
```

### Issue: Network Timeout During Rollback

**Symptoms:**
```
[ERROR] Health check timeout
curl: (28) Connection timed out
```

**Solution:**
```bash
# Check network connectivity
docker network inspect spacetime_default

# Restart Docker networking
docker-compose down
docker network prune -f
docker-compose up -d

# Check firewall
sudo iptables -L -n

# If internal network issue
docker-compose exec godot ping postgres
# Should succeed
```

### Issue: Disk Space Full

**Symptoms:**
```
Error: No space left on device
```

**Solution:**
```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -af --volumes

# Remove old backups (keep last 7 days)
find /opt/spacetime/backups -type d -mtime +7 -exec rm -rf {} \;

# Remove old images
docker images | grep spacetime | grep -v latest | awk '{print $3}' | xargs docker rmi

# Retry rollback
bash deploy/rollback/rollback.sh --level 1
```

## Rollback History

Track all production rollbacks in a central log:

```bash
# Location: /opt/spacetime/rollback_history.log

# Format:
[YYYY-MM-DD HH:MM:SS] LEVEL=[1/2/3] FROM=[version] TO=[version] DURATION=[seconds] STATUS=[success/failed] REASON=[reason]

# Example entries:
[2025-12-02 15:30:45] LEVEL=1 FROM=v2.5.0 TO=v2.4.9 DURATION=245 STATUS=success REASON="Application crash due to null pointer"
[2025-12-01 14:20:15] LEVEL=2 FROM=v2.4.8 TO=v2.4.7 DURATION=780 STATUS=success REASON="Database migration failure"
```

**Generate rollback report:**

```bash
# View rollback history
cat /opt/spacetime/rollback_history.log

# Count rollbacks by level
grep -o "LEVEL=[0-9]" /opt/spacetime/rollback_history.log | sort | uniq -c

# Average rollback duration
grep -o "DURATION=[0-9]*" /opt/spacetime/rollback_history.log | \
  cut -d= -f2 | awk '{sum+=$1} END {print "Average:", sum/NR, "seconds"}'

# Success rate
total=$(wc -l < /opt/spacetime/rollback_history.log)
success=$(grep "STATUS=success" /opt/spacetime/rollback_history.log | wc -l)
echo "Success rate: $((success * 100 / total))%"
```

## Additional Resources

- **CI/CD Guide:** [../CI_CD_GUIDE.md](../CI_CD_GUIDE.md)
- **Deployment Procedures:** [../CI_CD_GUIDE.md#deployment-process](../CI_CD_GUIDE.md#deployment-process)
- **Monitoring Guide:** [MONITORING_DEPLOYMENT.md](MONITORING_DEPLOYMENT.md)
- **Backup System:** [BACKUP_DEPLOYMENT_GUIDE.md](BACKUP_DEPLOYMENT_GUIDE.md)
- **Recovery Runbook:** [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md)
- **Alert Runbook:** [ALERT_RUNBOOK.md](ALERT_RUNBOOK.md)
- **Example Workflow Logs:** [../EXAMPLE_WORKFLOW_LOGS.md](../EXAMPLE_WORKFLOW_LOGS.md)

## Contact Information

### Emergency Contacts

**Production Issues:**
- On-Call Engineer: [Pager/Phone]
- Backup On-Call: [Pager/Phone]

**Escalation Path:**
1. On-call engineer (attempt rollback)
2. Senior operations team (if rollback fails)
3. Infrastructure team (for system-level issues)
4. VP Engineering / CTO (for critical incidents)

**Specialized Teams:**
- Database Team: [Contact] (for complex database issues)
- Security Team: [Contact] (for security breaches)
- Infrastructure Team: [Contact] (for cloud/infrastructure issues)

### Communication Channels

- **Incident Slack:** #incidents
- **Operations Slack:** #operations
- **Status Page:** status.spacetime.example.com
- **Customer Support:** support@spacetime.example.com

### Support Resources

- **Runbooks:** `/opt/spacetime/docs/runbooks/`
- **Playbooks:** `/opt/spacetime/docs/playbooks/`
- **Wiki:** https://wiki.spacetime.example.com
- **Monitoring:** https://grafana.spacetime.example.com

---

**Document Version:** 2.0
**Last Updated:** 2025-12-02
**Maintained By:** Operations Team
**Review Schedule:** Monthly
