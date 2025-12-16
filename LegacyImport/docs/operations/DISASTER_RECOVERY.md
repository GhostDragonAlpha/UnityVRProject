# Disaster Recovery Runbook - Planetary Survival VR

## Overview

This runbook provides step-by-step procedures for disaster recovery scenarios in production.

**Recovery Objectives:**
- **RTO (Recovery Time Objective):** <15 minutes
- **RPO (Recovery Point Objective):** <5 minutes

**Last Updated:** 2025-12-02
**Version:** 1.0
**Owner:** DevOps Team

---

## Table of Contents

1. [Pre-Disaster Preparation](#pre-disaster-preparation)
2. [Disaster Scenarios](#disaster-scenarios)
3. [Recovery Procedures](#recovery-procedures)
4. [Verification Steps](#verification-steps)
5. [Rollback Procedures](#rollback-procedures)
6. [Post-Recovery Actions](#post-recovery-actions)
7. [Contact Information](#contact-information)

---

## Pre-Disaster Preparation

### Prerequisites

Ensure the following are in place BEFORE a disaster:

- [ ] Backup automation is running (daily full, hourly incremental)
- [ ] Transaction log shipping is configured and active
- [ ] All backup storage locations are accessible (S3, Azure, GCS)
- [ ] Encryption keys are securely stored and accessible
- [ ] DR team has access credentials to all systems
- [ ] Monitoring alerts are configured and tested
- [ ] DR testing has been performed in the last 30 days

### Required Access

You will need:

1. **AWS Access:**
   - S3 bucket: `planetary-survival-backups-primary`
   - IAM role: `backup-restore-role`

2. **Azure Access:**
   - Storage account: `planetarysurvivalbackups`
   - Container: `planetary-survival-backups`

3. **GCP Access:**
   - Project: `planetary-survival-dr`
   - Bucket: `planetary-survival-backups-dr`

4. **Database Access:**
   - CockroachDB admin credentials
   - Redis admin credentials

5. **Kubernetes Access:**
   - kubectl configured for production cluster
   - Namespace: `spacetime`

---

## Disaster Scenarios

### Scenario 1: Database Corruption or Failure

**Symptoms:**
- Database connection errors
- Data inconsistency detected
- CockroachDB pod crash looping
- Replication lag exceeds 5 minutes

**Impact:** HIGH - Game servers cannot save/load player data

### Scenario 2: Complete Datacenter Failure

**Symptoms:**
- All services unreachable
- Kubernetes cluster down
- Network connectivity lost to primary region

**Impact:** CRITICAL - Complete service outage

### Scenario 3: Redis State Loss

**Symptoms:**
- Redis pod crash
- Active session data lost
- Player disconnect storms

**Impact:** MEDIUM - Active players disconnected, but data recoverable

### Scenario 4: Corrupted Backup

**Symptoms:**
- Backup verification fails
- Restore test unsuccessful
- Checksum mismatch

**Impact:** HIGH - Cannot recover from backup

### Scenario 5: Kubernetes Cluster Failure

**Symptoms:**
- Multiple node failures
- Control plane unreachable
- Pods not scheduling

**Impact:** CRITICAL - All services affected

---

## Recovery Procedures

### Procedure 1: Database Recovery (RTO Target: 10 minutes)

**When to use:** Database corruption, data loss, or database cluster failure

**Steps:**

1. **Assess the Situation (1 minute)**
   ```bash
   # Check database status
   kubectl get pods -n spacetime -l app=cockroachdb

   # Check recent errors
   kubectl logs -n spacetime cockroachdb-0 --tail=100

   # Verify backup availability
   aws s3 ls s3://planetary-survival-backups-primary/backups/primary/database/ | tail -5
   ```

2. **Stop Affected Services (1 minute)**
   ```bash
   # Scale down game servers to prevent further writes
   kubectl scale deployment spacetime-godot -n spacetime --replicas=0

   # Verify scaled down
   kubectl get pods -n spacetime -l app=spacetime-godot
   ```

3. **Identify Latest Backup (1 minute)**
   ```bash
   # Find most recent successful backup
   aws s3 ls s3://planetary-survival-backups-primary/backups/primary/database/ --recursive | sort | tail -1

   # Download backup metadata
   aws s3 cp s3://planetary-survival-backups-primary/backups/metadata/latest.json /tmp/backup_metadata.json

   # Verify backup integrity
   cat /tmp/backup_metadata.json | jq '.components.database'
   ```

4. **Restore Database (5-7 minutes)**
   ```bash
   # Get backup ID from metadata
   BACKUP_ID=$(cat /tmp/backup_metadata.json | jq -r '.backup_id')

   # Run restore script
   cd /c/godot/scripts/operations/restore
   python3 restore_manager.py "$BACKUP_ID" s3

   # Monitor restore progress
   tail -f /var/log/spacetime/restore.log
   ```

5. **Verify Database Integrity (1 minute)**
   ```bash
   # Connect to database
   kubectl exec -it cockroachdb-0 -n spacetime -- cockroach sql --insecure

   # Run verification queries
   SHOW TABLES FROM planetary_survival;
   SELECT COUNT(*) FROM planetary_survival.players;
   SELECT COUNT(*) FROM planetary_survival.saves;

   # Check replication status
   SHOW RANGES FROM DATABASE planetary_survival;
   ```

6. **Restore Services (1 minute)**
   ```bash
   # Scale up game servers
   kubectl scale deployment spacetime-godot -n spacetime --replicas=3

   # Wait for healthy status
   kubectl wait --for=condition=Ready pod -l app=spacetime-godot -n spacetime --timeout=120s

   # Verify service endpoints
   curl -f https://api.planetary-survival.com/health
   ```

7. **Monitor for Issues (continuous)**
   ```bash
   # Watch pod status
   kubectl get pods -n spacetime -w

   # Monitor error logs
   kubectl logs -f -n spacetime -l app=spacetime-godot

   # Check Grafana dashboard
   open http://grafana.planetary-survival.com/d/backup_health
   ```

**Expected RTO:** 10-12 minutes
**Expected RPO:** <5 minutes (from last incremental backup)

---

### Procedure 2: Complete Datacenter Failover (RTO Target: 15 minutes)

**When to use:** Complete datacenter/region failure, network outage, natural disaster

**Steps:**

1. **Declare Disaster (Immediate)**
   ```bash
   # Alert team via incident management
   curl -X POST $PAGERDUTY_WEBHOOK \
     -d '{"event_type": "trigger", "title": "DATACENTER FAILURE - Initiating DR", "severity": "critical"}'

   # Document start time
   echo "DR Start: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /var/log/spacetime/dr.log
   ```

2. **Activate Secondary Region (2 minutes)**
   ```bash
   # Switch to DR Kubernetes cluster
   kubectl config use-context gke_planetary-survival-dr_europe-west1_dr-cluster

   # Verify cluster accessibility
   kubectl get nodes

   # Check namespace exists
   kubectl get namespace spacetime || kubectl create namespace spacetime
   ```

3. **Deploy Infrastructure (3 minutes)**
   ```bash
   # Apply Kubernetes manifests
   cd /c/godot/kubernetes
   kubectl apply -f namespace.yaml
   kubectl apply -f configmap.yaml
   kubectl apply -f secret.yaml
   kubectl apply -f pvc.yaml
   kubectl apply -f statefulset.yaml
   kubectl apply -f deployment.yaml
   kubectl apply -f service.yaml
   kubectl apply -f ingress.yaml

   # Wait for PVCs
   kubectl wait --for=condition=Bound pvc --all -n spacetime --timeout=180s
   ```

4. **Restore from Tertiary Backup (5-8 minutes)**
   ```bash
   # Find latest backup in GCS
   gsutil ls gs://planetary-survival-backups-dr/backups/tertiary/database/ | sort | tail -1

   # Get backup ID
   BACKUP_ID=$(gsutil cat gs://planetary-survival-backups-dr/backups/metadata/latest.json | jq -r '.backup_id')

   # Execute restore
   cd /c/godot/scripts/operations/restore
   python3 restore_manager.py "$BACKUP_ID" gcs
   ```

5. **Update DNS (2 minutes)**
   ```bash
   # Update DNS to point to DR region
   # Option A: Route53
   aws route53 change-resource-record-sets \
     --hosted-zone-id $HOSTED_ZONE_ID \
     --change-batch file://dns-failover.json

   # Option B: Cloudflare API
   curl -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -d '{"type":"A","name":"api.planetary-survival.com","content":"$DR_IP","ttl":60}'

   # Verify DNS propagation
   dig api.planetary-survival.com +short
   ```

6. **Verify All Services (2 minutes)**
   ```bash
   # Check pod health
   kubectl get pods -n spacetime

   # Test API endpoint
   curl -f https://api.planetary-survival.com/health

   # Test WebSocket
   wscat -c wss://api.planetary-survival.com/ws/telemetry

   # Verify database connectivity
   kubectl exec -it cockroachdb-0 -n spacetime -- cockroach sql --insecure -e "SELECT 1;"
   ```

7. **Enable Monitoring (1 minute)**
   ```bash
   # Deploy monitoring stack
   kubectl apply -f /c/godot/kubernetes/monitoring/

   # Verify Prometheus
   kubectl port-forward -n spacetime svc/prometheus 9090:9090 &
   open http://localhost:9090

   # Verify Grafana
   kubectl port-forward -n spacetime svc/grafana 3000:3000 &
   open http://localhost:3000
   ```

**Expected RTO:** 12-15 minutes
**Expected RPO:** <10 minutes (transaction log replay from GCS)

---

### Procedure 3: Redis Recovery (RTO Target: 5 minutes)

**When to use:** Redis pod failure, data corruption, memory issues

**Steps:**

1. **Stop Dependent Services (30 seconds)**
   ```bash
   # Scale down game servers temporarily
   kubectl scale deployment spacetime-godot -n spacetime --replicas=0
   ```

2. **Restore Redis from Backup (2 minutes)**
   ```bash
   # Get latest Redis backup
   BACKUP_ID=$(aws s3 ls s3://planetary-survival-backups-primary/backups/primary/redis/ | sort | tail -1 | awk '{print $NF}')

   # Download backup
   aws s3 sync "s3://planetary-survival-backups-primary/backups/primary/redis/$BACKUP_ID" /tmp/redis_restore/

   # Stop Redis
   kubectl delete pod -n spacetime spacetime-redis-0

   # Copy backup files
   kubectl cp /tmp/redis_restore/dump.rdb spacetime/spacetime-redis-0:/data/dump.rdb
   kubectl cp /tmp/redis_restore/appendonly.aof spacetime/spacetime-redis-0:/data/appendonly.aof
   ```

3. **Restart Redis (1 minute)**
   ```bash
   # Redis will auto-restart from StatefulSet
   kubectl wait --for=condition=Ready pod -l app=spacetime-redis -n spacetime --timeout=120s

   # Verify Redis
   kubectl exec -it spacetime-redis-0 -n spacetime -- redis-cli PING
   ```

4. **Restore Services (1 minute)**
   ```bash
   # Scale up game servers
   kubectl scale deployment spacetime-godot -n spacetime --replicas=3

   # Verify
   kubectl get pods -n spacetime
   ```

**Expected RTO:** 4-5 minutes
**Expected RPO:** <1 hour (from last Redis snapshot)

---

### Procedure 4: Corrupted Backup Recovery (RTO Target: 20 minutes)

**When to use:** Primary backup verification fails, restore test unsuccessful

**Steps:**

1. **Identify Corruption (2 minutes)**
   ```bash
   # Run backup verification
   cd /c/godot/scripts/operations
   python3 verify_backup.py $BACKUP_ID

   # Check verification report
   cat /var/log/spacetime/backup_verification/$BACKUP_ID.json
   ```

2. **Locate Alternative Backup (3 minutes)**
   ```bash
   # Try secondary storage (Azure)
   az storage blob list \
     --account-name planetarysurvivalbackups \
     --container-name planetary-survival-backups \
     --prefix "backups/secondary/database/" \
     --output table | tail -10

   # If secondary also corrupted, try tertiary (GCS)
   gsutil ls gs://planetary-survival-backups-dr/backups/tertiary/database/ | tail -10
   ```

3. **Download and Verify Alternative (5 minutes)**
   ```bash
   # Download from alternative location
   BACKUP_ID=$(gsutil ls gs://planetary-survival-backups-dr/backups/tertiary/database/ | sort | tail -1)

   # Download backup
   gsutil -m rsync -r "$BACKUP_ID" /tmp/backup_restore/

   # Verify checksum
   cd /tmp/backup_restore
   sha256sum -c checksums.sha256
   ```

4. **Restore from Alternative (10 minutes)**
   ```bash
   # Use standard restore procedure with alternative backup
   cd /c/godot/scripts/operations/restore
   python3 restore_manager.py "$BACKUP_ID" gcs
   ```

**Expected RTO:** 18-20 minutes
**Expected RPO:** Depends on alternative backup age (typically <1 hour)

---

## Verification Steps

After any recovery, perform the following verification:

### Database Verification

```bash
# Connect to database
kubectl exec -it cockroachdb-0 -n spacetime -- cockroach sql --insecure

# Verify table counts
SELECT 'players' as table, COUNT(*) as count FROM planetary_survival.players
UNION ALL
SELECT 'saves', COUNT(*) FROM planetary_survival.saves
UNION ALL
SELECT 'sessions', COUNT(*) FROM planetary_survival.sessions;

# Check data integrity
SELECT * FROM planetary_survival.players ORDER BY last_login DESC LIMIT 10;

# Verify replication
SHOW RANGES FROM DATABASE planetary_survival;
```

### Service Health Verification

```bash
# Check all pods
kubectl get pods -n spacetime -o wide

# Test API endpoints
curl -f https://api.planetary-survival.com/health
curl -f https://api.planetary-survival.com/status

# Test WebSocket
wscat -c wss://api.planetary-survival.com/ws/telemetry

# Test VR connection
curl -X POST https://api.planetary-survival.com/vr/connect \
  -H "Authorization: Bearer $API_TOKEN"
```

### Player Experience Verification

```bash
# Create test player
curl -X POST https://api.planetary-survival.com/players \
  -H "Content-Type: application/json" \
  -d '{"username": "dr_test_user", "email": "test@example.com"}'

# Load test save
curl https://api.planetary-survival.com/saves/test_save_id \
  -H "Authorization: Bearer $TEST_TOKEN"

# Verify game server connection
nc -zv api.planetary-survival.com 8080
```

### Monitoring Verification

```bash
# Check Prometheus targets
curl https://prometheus.planetary-survival.com/api/v1/targets | jq '.data.activeTargets[] | {job: .job, health: .health}'

# Check Grafana dashboards
curl -f https://grafana.planetary-survival.com/api/health

# Verify alerts
curl https://prometheus.planetary-survival.com/api/v1/alerts | jq '.data.alerts[] | select(.state=="firing")'
```

---

## Rollback Procedures

If recovery fails or causes issues:

### Rollback Database Restore

```bash
# Stop services
kubectl scale deployment spacetime-godot -n spacetime --replicas=0

# Restore previous backup
PREVIOUS_BACKUP_ID="20250201_120000"  # Use previous known-good backup
cd /c/godot/scripts/operations/restore
python3 restore_manager.py "$PREVIOUS_BACKUP_ID" s3

# Restart services
kubectl scale deployment spacetime-godot -n spacetime --replicas=3
```

### Rollback Datacenter Failover

```bash
# Switch DNS back to primary
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch file://dns-failback.json

# Scale down DR cluster
kubectl config use-context gke_planetary-survival-dr_europe-west1_dr-cluster
kubectl scale deployment --all -n spacetime --replicas=0

# Resume primary cluster
kubectl config use-context gke_planetary-survival_us-east1_prod-cluster
kubectl scale deployment spacetime-godot -n spacetime --replicas=3
```

---

## Post-Recovery Actions

After successful recovery:

1. **Document the Incident**
   ```bash
   # Create incident report
   cat > /var/log/spacetime/incidents/$(date +%Y%m%d)_recovery.md <<EOF
   # Incident Report - $(date)

   ## Summary
   [Describe what happened]

   ## Timeline
   - Detection: [time]
   - Response: [time]
   - Recovery: [time]

   ## RTO Achieved: [X] minutes
   ## RPO Achieved: [X] minutes

   ## Root Cause
   [Analysis]

   ## Action Items
   - [ ] [Action 1]
   - [ ] [Action 2]
   EOF
   ```

2. **Notify Stakeholders**
   - Send recovery notification to team
   - Update status page
   - Notify affected players if necessary

3. **Restore Full Backup Schedule**
   ```bash
   # Verify backup cron jobs
   crontab -l | grep backup

   # Test backup immediately
   /c/godot/scripts/operations/backup/scheduled_backup.sh full
   ```

4. **Schedule Post-Mortem**
   - Within 24 hours
   - Include all team members
   - Document lessons learned

5. **Update DR Plan**
   - Document any deviations from plan
   - Update procedures based on lessons learned
   - Update contact information if needed

6. **Test Recovery Again**
   - Schedule validation test within 7 days
   - Verify improvements made

---

## Contact Information

### Primary Contacts

| Role | Name | Phone | Email | Backup |
|------|------|-------|-------|--------|
| Incident Commander | [Name] | [Phone] | [Email] | [Backup] |
| Database Lead | [Name] | [Phone] | [Email] | [Backup] |
| Infrastructure Lead | [Name] | [Phone] | [Email] | [Backup] |
| DevOps Lead | [Name] | [Phone] | [Email] | [Backup] |

### Escalation Path

1. Level 1: On-call Engineer (Response: <5 minutes)
2. Level 2: Team Lead (Response: <15 minutes)
3. Level 3: Director of Engineering (Response: <30 minutes)
4. Level 4: CTO (Response: <1 hour)

### External Contacts

- **AWS Support:** [Premium Support Number]
- **Azure Support:** [Support Number]
- **GCP Support:** [Support Number]
- **DNS Provider:** [Support Contact]

### Communication Channels

- **Incident Slack:** #incident-response
- **Status Page:** https://status.planetary-survival.com
- **PagerDuty:** [Service URL]

---

## Appendix

### Backup Storage Locations

| Type | Primary (S3) | Secondary (Azure) | Tertiary (GCS) |
|------|-------------|-------------------|----------------|
| Database | s3://planetary-survival-backups-primary/backups/primary/database/ | planetarysurvivalbackups/planetary-survival-backups/backups/secondary/database/ | gs://planetary-survival-backups-dr/backups/tertiary/database/ |
| Redis | s3://planetary-survival-backups-primary/backups/primary/redis/ | planetarysurvivalbackups/planetary-survival-backups/backups/secondary/redis/ | gs://planetary-survival-backups-dr/backups/tertiary/redis/ |
| Player Saves | s3://planetary-survival-backups-primary/backups/primary/saves/ | planetarysurvivalbackups/planetary-survival-backups/backups/secondary/saves/ | gs://planetary-survival-backups-dr/backups/tertiary/saves/ |
| Configuration | s3://planetary-survival-backups-primary/backups/primary/config/ | planetarysurvivalbackups/planetary-survival-backups/backups/secondary/config/ | gs://planetary-survival-backups-dr/backups/tertiary/config/ |

### Testing Schedule

- **Weekly:** Backup restoration test (automated)
- **Monthly:** Partial DR drill (database only)
- **Quarterly:** Full DR drill (complete datacenter failover)
- **Annually:** DR plan review and update

---

**Document Control:**
- Created: 2025-12-02
- Last Review: 2025-12-02
- Next Review: 2026-03-02
- Version: 1.0
