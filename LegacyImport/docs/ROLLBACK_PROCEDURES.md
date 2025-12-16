# Rollback Procedures

Comprehensive guide for rolling back failed deployments in SpaceTime VR.

## Table of Contents

- [Overview](#overview)
- [When to Rollback](#when-to-rollback)
- [Automatic Rollback](#automatic-rollback)
- [Manual Rollback Methods](#manual-rollback-methods)
- [Rollback Verification](#rollback-verification)
- [Post-Rollback Actions](#post-rollback-actions)
- [Emergency Procedures](#emergency-procedures)

## Overview

SpaceTime VR implements multiple rollback mechanisms to ensure quick recovery from failed deployments:

1. **Automatic Rollback**: Triggered by failed health checks or smoke tests
2. **Manual Quick Rollback**: One-command rollback to previous version
3. **Targeted Rollback**: Rollback to specific deployment version
4. **Container Rollback**: Direct Docker container manipulation
5. **Blue-Green Rollback**: Switch back to blue environment

**Recovery Time Objective (RTO)**: < 3 minutes
**Recovery Point Objective (RPO)**: Last successful deployment

## When to Rollback

### Automatic Rollback Triggers

The system automatically rolls back when:

- ❌ Container fails to start
- ❌ Health checks fail after 5 minutes
- ❌ Smoke tests fail
- ❌ Error rate exceeds 10% for 1 minute
- ❌ Response time exceeds 5 seconds for 1 minute
- ❌ Memory usage exceeds 95%
- ❌ Critical service crashes

### Manual Rollback Indicators

Consider manual rollback when:

- 🔴 **Critical**: Service completely down
- 🔴 **Critical**: Data corruption detected
- 🔴 **Critical**: Security breach discovered
- 🟠 **High**: Error rate > 5% sustained
- 🟠 **High**: Response time > 2s sustained
- 🟠 **High**: Customer complaints spike
- 🟡 **Medium**: Memory leak detected
- 🟡 **Medium**: Performance degradation

### Decision Matrix

```
┌─────────────────────┬──────────────┬─────────────────────┐
│ Issue Severity      │ Duration     │ Action              │
├─────────────────────┼──────────────┼─────────────────────┤
│ Critical            │ Any          │ ROLLBACK NOW        │
│ High                │ > 5 minutes  │ ROLLBACK            │
│ High                │ < 5 minutes  │ Monitor closely     │
│ Medium              │ > 15 minutes │ Consider rollback   │
│ Medium              │ < 15 minutes │ Monitor             │
│ Low                 │ Any          │ Monitor, log issue  │
└─────────────────────┴──────────────┴─────────────────────┘
```

## Automatic Rollback

### How It Works

1. **Detection**: Health checks or smoke tests fail
2. **Alert**: Notifications sent to ops team
3. **Rollback**: Previous version automatically restored
4. **Verification**: Health checks confirm rollback success
5. **Notification**: Rollback completion alert

### Automatic Rollback Flow

```
Deployment Failed
       │
       ▼
   Alert Sent
       │
       ▼
Stop New Version
       │
       ▼
Restore Previous Config
       │
       ▼
Start Previous Version
       │
       ▼
Health Check Wait (2 min)
       │
       ├─ Success ─→ Rollback Complete ✅
       │
       └─ Failed ──→ Emergency Procedure 🚨
```

### Monitoring Automatic Rollback

```bash
# Watch CI/CD workflow
gh run watch

# Check deployment logs
docker-compose logs --tail=100

# Verify service status
curl https://spacetime.example.com/status
```

## Manual Rollback Methods

### Method 1: Quick Rollback Script (Recommended)

**Use Case**: Fastest rollback to previous version

```bash
# SSH to production server
ssh production-server

# Navigate to deployment directory
cd /opt/spacetime/production

# Execute quick rollback
bash deploy/rollback.sh --quick
```

**Output:**
```
╔════════════════════════════════════════════════════════════╗
║         SpaceTime VR - Automated Rollback                 ║
╚════════════════════════════════════════════════════════════╝

[INFO] Quick rollback to latest backup...
[INFO] Latest backup: 20251202-143022
[INFO] Rolling back to: 20251202-143022
[INFO] Stopping current containers...
[SUCCESS] Old containers stopped
[INFO] Restoring configuration...
[SUCCESS] Configuration restored
[INFO] Starting containers with previous configuration...
[SUCCESS] Containers started
[INFO] Waiting for services to be healthy...
Attempt 15/30: 4/4 services healthy
[SUCCESS] Rollback complete! Services are healthy.
[SUCCESS] Rollback procedure completed

Verify the rollback:
  docker-compose ps
  docker-compose logs -f
```

**Duration**: ~2 minutes

### Method 2: Interactive Rollback

**Use Case**: Choose specific version to rollback to

```bash
# Run interactive rollback
bash deploy/rollback.sh
```

**Output:**
```
[INFO] Available backups:

     1  20251202-150045
     2  20251202-143022
     3  20251201-160034
     4  20251201-120015

Enter backup number to rollback to (or 'q' to quit): 2

Rollback to 20251202-143022? (yes/no): yes

[INFO] Rolling back to: 20251202-143022
[... rollback proceeds ...]
```

### Method 3: Specific Version Rollback

**Use Case**: Rollback to known good version

```bash
# Rollback to specific deployment ID
bash deploy/rollback.sh 20251202-143022
```

### Method 4: GitHub Actions Workflow

**Use Case**: Trigger rollback from anywhere

```bash
# Trigger rollback workflow
gh workflow run rollback.yml \
  -f deployment_id=20251202-143022 \
  -f environment=production
```

### Method 5: Container Rollback

**Use Case**: Direct container manipulation when script fails

```bash
# Stop current containers
docker-compose down

# Set previous image tag
export IMAGE_TAG=v2.4.9

# Start with previous version
docker-compose up -d

# Wait for health
sleep 30

# Verify health
docker-compose ps
docker-compose logs --tail=50
```

### Method 6: Blue-Green Rollback

**Use Case**: During blue-green deployment, switch back to blue

```bash
# If green failed, switch traffic back to blue
cd /opt/spacetime/production

# Stop green environment
docker-compose -p spacetime-green down

# Ensure blue is running
docker-compose -p spacetime-blue ps

# Update nginx to point to blue
docker exec spacetime-nginx nginx -s reload

# Verify
curl https://spacetime.example.com/status
```

## Rollback Verification

### Health Check Verification

```bash
# 1. Check container status
docker-compose ps

# Expected output:
# NAME              STATUS              HEALTH
# spacetime-godot   Up 2 minutes        healthy
# spacetime-nginx   Up 2 minutes        healthy
# ...

# 2. Run smoke tests
bash deploy/smoke_tests.sh

# Expected: All 13 tests pass

# 3. Check HTTP API
curl https://spacetime.example.com/status | jq
# Expected: {"overall_ready": true, ...}

# 4. Check error logs
docker-compose logs --tail=100 | grep -i error
# Expected: No critical errors

# 5. Monitor for 5 minutes
watch -n 5 'docker-compose ps'
```

### Metrics Verification

```bash
# Check Prometheus metrics
curl -G 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=up{job="godot"}' | jq

# Expected: All targets up

# Check error rate
curl -G 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=rate(http_requests_total{status=~"5.."}[5m])' | jq

# Expected: Near zero error rate

# Check response time
curl -G 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))' | jq

# Expected: < 1 second
```

### User Impact Verification

```bash
# Run end-to-end test
cd tests
python test_runner.py --quick

# Check Grafana dashboards
open https://spacetime.example.com/grafana

# Review request rate and error rate
# Should return to normal levels
```

## Post-Rollback Actions

### Immediate Actions (0-15 minutes)

1. **Confirm Rollback Success**
   ```bash
   bash deploy/smoke_tests.sh
   ```

2. **Monitor System**
   ```bash
   # Watch metrics for 15 minutes
   python tests/health_monitor.py --host spacetime.example.com --duration 900
   ```

3. **Notify Stakeholders**
   - Send status update
   - Explain what happened
   - Provide ETA for fix

4. **Create Incident Report**
   ```bash
   gh issue create \
     --title "Production Rollback: [Reason]" \
     --label incident \
     --body "Deployment rolled back due to [reason]..."
   ```

### Short-term Actions (15-60 minutes)

5. **Analyze Failure**
   ```bash
   # Review deployment logs
   cat /opt/spacetime/production/logs/deployment-20251202-150045.log

   # Check error logs
   docker-compose logs --since 1h | grep -i error

   # Review metrics
   # Check Grafana for anomalies
   ```

6. **Identify Root Cause**
   - Review code changes
   - Check configuration changes
   - Verify infrastructure
   - Examine dependencies

7. **Test Fix in Staging**
   ```bash
   # Deploy fix to staging
   gh workflow run deploy-staging.yml -f image_tag=fix-branch-abc123

   # Run comprehensive tests
   python tests/test_runner.py

   # Monitor staging for 2+ hours
   ```

### Long-term Actions (1+ hours)

8. **Develop Permanent Fix**
   - Create fix branch
   - Add regression tests
   - Update documentation
   - Submit PR with review

9. **Update Runbooks**
   - Document what went wrong
   - Add to known issues
   - Update rollback procedures if needed

10. **Post-Mortem**
    - Schedule post-mortem meeting
    - Document timeline of events
    - Identify action items
    - Update processes to prevent recurrence

## Emergency Procedures

### Complete Service Outage

**Symptom**: All services down, rollback script failing

```bash
# 1. Check if containers are running at all
docker ps -a

# 2. If nothing running, start with known good version
export IMAGE_TAG=v2.4.9  # Last known good
docker-compose up -d

# 3. If containers won't start, check disk space
df -h

# 4. If disk full, emergency cleanup
docker system prune -af --volumes

# 5. Restart Docker daemon if needed
sudo systemctl restart docker

# 6. Try starting again
docker-compose up -d

# 7. If still failing, restore from backup
# [Contact senior ops for backup restoration]
```

### Data Corruption Detected

**Symptom**: Data inconsistencies, corruption errors

```bash
# 1. STOP ALL SERVICES IMMEDIATELY
docker-compose down

# 2. Create snapshot of current state
EMERGENCY_BACKUP="/opt/spacetime/emergency-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$EMERGENCY_BACKUP"
docker run --rm -v spacetime_godot-data:/data -v "$EMERGENCY_BACKUP":/backup alpine tar czf /backup/data.tar.gz /data

# 3. Restore from last good backup
LAST_GOOD_BACKUP="/opt/spacetime/backups/20251201-160034"  # VERIFY THIS DATE
docker run --rm -v spacetime_godot-data:/data -v "$LAST_GOOD_BACKUP":/backup alpine sh -c "rm -rf /data/* && tar xzf /backup/data.tar.gz -C /"

# 4. Start with previous version
export IMAGE_TAG=v2.4.9
docker-compose up -d

# 5. Verify data integrity
# [Run data integrity checks]

# 6. If data cannot be restored, escalate immediately
# [Contact database admin / senior ops]
```

### Security Breach Discovered

**Symptom**: Unauthorized access, suspicious activity

```bash
# 1. ISOLATE IMMEDIATELY
docker-compose down

# 2. Block external access
sudo iptables -A INPUT -p tcp --dport 80 -j DROP
sudo iptables -A INPUT -p tcp --dport 443 -j DROP

# 3. Collect evidence
docker-compose logs > /tmp/incident-logs-$(date +%Y%m%d-%H%M%S).log

# 4. Take system snapshot
# [Document all actions for investigation]

# 5. Deploy clean version in isolated environment
# [Follow security incident response plan]

# 6. DO NOT start services until security team approves
```

### Rollback Failed

**Symptom**: Rollback script completed but services unhealthy

```bash
# 1. Gather information
docker-compose ps
docker-compose logs --tail=200

# 2. Check resources
docker stats --no-stream
df -h
free -h

# 3. Try force restart
docker-compose down --timeout 60
docker-compose up -d --force-recreate

# 4. If still failing, try older version
bash deploy/rollback.sh --list
# Select older backup (e.g., 2 versions back)
bash deploy/rollback.sh [older-deployment-id]

# 5. If all rollbacks fail, restore from infrastructure backup
# [Contact infrastructure team]
```

## Rollback Checklist

Use this checklist during rollback:

```
PRE-ROLLBACK:
[ ] Incident logged
[ ] Stakeholders notified
[ ] Rollback version identified
[ ] Backup of current state created

ROLLBACK EXECUTION:
[ ] Rollback initiated
[ ] Progress monitored
[ ] No errors during rollback
[ ] Services restarted

POST-ROLLBACK VERIFICATION:
[ ] All containers healthy
[ ] Smoke tests pass
[ ] HTTP API responding
[ ] Error rate normalized
[ ] Response time normal
[ ] No data loss
[ ] Metrics look good

POST-ROLLBACK ACTIONS:
[ ] Stakeholders updated
[ ] Incident report created
[ ] Root cause analysis started
[ ] Fix tested in staging
[ ] Runbooks updated
[ ] Post-mortem scheduled
```

## Contact Information

### Emergency Contacts

- **On-Call Engineer**: [phone/pager]
- **Infrastructure Team**: [contact]
- **Security Team**: [contact]
- **Management**: [contact]

### Escalation Path

1. **Level 1**: On-call engineer attempts rollback
2. **Level 2**: Senior ops team if rollback fails
3. **Level 3**: Infrastructure team for system-level issues
4. **Level 4**: CTO/VP Engineering for critical incidents

### Communication Channels

- **Incident Slack**: #incidents
- **Status Page**: status.spacetime.example.com
- **Customer Support**: support@spacetime.example.com

## Additional Resources

- [CI/CD Guide](../CI_CD_GUIDE.md)
- [Deployment Procedures](../CI_CD_GUIDE.md#deployment-process)
- [Monitoring Guide](../CI_CD_GUIDE.md#monitoring-and-alerts)
- [Architecture Documentation](../CLAUDE.md#architecture)
- [Example Workflow Logs](EXAMPLE_WORKFLOW_LOGS.md)
