# Backup and Recovery Runbook

**Version:** 2.5.0
**Last Updated:** 2025-12-02
**Maintained By:** DevOps Team
**Review Cycle:** Monthly

## Table of Contents

1. [Overview](#overview)
2. [Backup Strategy](#backup-strategy)
3. [Backup Procedures](#backup-procedures)
4. [Recovery Procedures](#recovery-procedures)
5. [Disaster Recovery](#disaster-recovery)
6. [Testing and Verification](#testing-and-verification)

---

## Overview

### Backup Objectives

**Recovery Point Objective (RPO):** 1 hour
- Maximum acceptable data loss: 1 hour of data

**Recovery Time Objective (RTO):** 15 minutes
- Maximum acceptable downtime: 15 minutes

### What We Backup

1. **Application Code**
   - Production codebase
   - Configuration files
   - Scene files (*.tscn)
   - Scripts (*.gd)

2. **Configuration**
   - Environment variables (.env)
   - Project settings (project.godot)
   - Service configurations (systemd units)
   - SSL/TLS certificates

3. **Data**
   - Audit logs
   - API access logs
   - Telemetry data (if persisted)
   - User data (if applicable)

4. **Security Assets**
   - API tokens (encrypted)
   - Certificates and keys
   - Authentication configurations

---

## Backup Strategy

### Backup Types

#### 1. Full Backup
- **Frequency:** Daily at 2:00 AM UTC
- **Retention:** 7 days
- **Size:** ~10-15 GB
- **Duration:** 10-15 minutes

#### 2. Incremental Backup
- **Frequency:** Hourly
- **Retention:** 24 hours
- **Size:** ~500 MB - 1 GB
- **Duration:** 2-5 minutes

#### 3. Configuration Snapshot
- **Frequency:** Before/after each deployment
- **Retention:** 30 days
- **Size:** ~10 MB
- **Duration:** < 1 minute

#### 4. Database Backup (if applicable)
- **Frequency:** Every 6 hours
- **Retention:** 14 days
- **Size:** Varies
- **Duration:** Varies

---

### Backup Schedule

```
Daily:
02:00 UTC - Full backup
03:00 UTC - Backup verification
04:00 UTC - Off-site replication

Hourly:
:15 - Incremental backup (15 minutes past each hour)

On-Demand:
- Before deployment
- After deployment
- Before major configuration change
- After incident resolution

Weekly:
Sunday 04:00 UTC - Weekly full backup (long retention)

Monthly:
First Sunday 05:00 UTC - Monthly archive backup
```

---

### Retention Policy

| Backup Type | Retention | Storage Location |
|-------------|-----------|------------------|
| Hourly Incremental | 24 hours | Local |
| Daily Full | 7 days | Local + S3 |
| Weekly Full | 4 weeks | S3 |
| Monthly Archive | 3 months | S3 Glacier |
| Configuration Snapshot | 30 days | Local + S3 |
| Pre-Deployment Snapshot | 30 days | Local |

---

## Backup Procedures

### Daily Full Backup

**Automated Script:** `/opt/spacetime/scripts/backup_full.sh`

```bash
#!/bin/bash
# Full backup script
set -e

BACKUP_DIR="/opt/spacetime/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="production_full_${TIMESTAMP}"
S3_BUCKET="s3://company-backups/spacetime/production"

echo "Starting full backup at $(date)"

# 1. Create backup directory
mkdir -p ${BACKUP_DIR}/${BACKUP_NAME}

# 2. Backup application code
echo "Backing up application code..."
rsync -av --exclude='*.log' --exclude='backups/' \
  /opt/spacetime/production/ \
  ${BACKUP_DIR}/${BACKUP_NAME}/production/

# 3. Backup configuration
echo "Backing up configuration..."
cp /opt/spacetime/production/.env ${BACKUP_DIR}/${BACKUP_NAME}/
cp /opt/spacetime/production/project.godot ${BACKUP_DIR}/${BACKUP_NAME}/
cp /etc/systemd/system/godot-spacetime.service ${BACKUP_DIR}/${BACKUP_NAME}/

# 4. Backup certificates
echo "Backing up certificates..."
mkdir -p ${BACKUP_DIR}/${BACKUP_NAME}/certs
cp -r /etc/ssl/certs/spacetime-* ${BACKUP_DIR}/${BACKUP_NAME}/certs/

# 5. Backup logs (last 7 days)
echo "Backing up logs..."
find /opt/spacetime/logs -name "*.log*" -mtime -7 -exec cp {} ${BACKUP_DIR}/${BACKUP_NAME}/logs/ \;

# 6. Create backup metadata
cat > ${BACKUP_DIR}/${BACKUP_NAME}/metadata.json << EOF
{
  "backup_type": "full",
  "timestamp": "${TIMESTAMP}",
  "date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": "$(hostname)",
  "version": "$(cd /opt/spacetime/production && git describe --tags)",
  "commit": "$(cd /opt/spacetime/production && git rev-parse HEAD)"
}
EOF

# 7. Compress backup
echo "Compressing backup..."
cd ${BACKUP_DIR}
tar -czf ${BACKUP_NAME}.tar.gz ${BACKUP_NAME}/
rm -rf ${BACKUP_NAME}/

# 8. Calculate checksum
sha256sum ${BACKUP_NAME}.tar.gz > ${BACKUP_NAME}.tar.gz.sha256

# 9. Upload to S3
echo "Uploading to S3..."
aws s3 cp ${BACKUP_NAME}.tar.gz ${S3_BUCKET}/daily/
aws s3 cp ${BACKUP_NAME}.tar.gz.sha256 ${S3_BUCKET}/daily/

# 10. Cleanup old local backups (keep 7 days)
find ${BACKUP_DIR} -name "production_full_*.tar.gz" -mtime +7 -delete
find ${BACKUP_DIR} -name "production_full_*.tar.gz.sha256" -mtime +7 -delete

# 11. Verify backup
echo "Verifying backup integrity..."
sha256sum -c ${BACKUP_NAME}.tar.gz.sha256

echo "Full backup completed successfully at $(date)"
echo "Backup file: ${BACKUP_NAME}.tar.gz"
echo "Size: $(du -h ${BACKUP_NAME}.tar.gz | cut -f1)"

# 12. Send notification
curl -X POST "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"✅ Full backup completed: ${BACKUP_NAME}.tar.gz\"}"

exit 0
```

**Manual Execution:**
```bash
# Run full backup manually
sudo /opt/spacetime/scripts/backup_full.sh

# Verify backup created
ls -lh /opt/spacetime/backups/production_full_*.tar.gz | tail -1
```

---

### Hourly Incremental Backup

**Automated Script:** `/opt/spacetime/scripts/backup_incremental.sh`

```bash
#!/bin/bash
# Incremental backup script
set -e

BACKUP_DIR="/opt/spacetime/backups/incremental"
TIMESTAMP=$(date +%Y%m%d_%H%M)
BACKUP_NAME="production_inc_${TIMESTAMP}"
LAST_BACKUP=$(find ${BACKUP_DIR} -name "production_inc_*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2)

echo "Starting incremental backup at $(date)"

mkdir -p ${BACKUP_DIR}

# Backup only changed files since last backup
if [ -n "$LAST_BACKUP" ]; then
  echo "Last backup: $LAST_BACKUP"
  LAST_BACKUP_TIME=$(stat -c %Y $LAST_BACKUP)
  find /opt/spacetime/production -type f -newer $LAST_BACKUP | \
    tar -czf ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz -T -
else
  echo "No previous backup found, creating initial incremental"
  tar -czf ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz /opt/spacetime/production
fi

# Cleanup old incremental backups (keep 24 hours)
find ${BACKUP_DIR} -name "production_inc_*.tar.gz" -mtime +1 -delete

echo "Incremental backup completed: ${BACKUP_NAME}.tar.gz"
exit 0
```

**Cron Setup:**
```bash
# Add to crontab
crontab -e

# Add lines:
0 2 * * * /opt/spacetime/scripts/backup_full.sh >> /var/log/spacetime-backup.log 2>&1
15 * * * * /opt/spacetime/scripts/backup_incremental.sh >> /var/log/spacetime-backup.log 2>&1
```

---

### Pre-Deployment Snapshot

```bash
#!/bin/bash
# Pre-deployment snapshot
# Run this before any deployment

BACKUP_DIR="/opt/spacetime/backups/deployments"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="pre_deploy_${TIMESTAMP}"

mkdir -p ${BACKUP_DIR}

# Snapshot current production
tar -czf ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz \
  /opt/spacetime/production/ \
  /opt/spacetime/production/.env \
  /opt/spacetime/production/project.godot

# Create symlink to latest
ln -sfn ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz ${BACKUP_DIR}/latest_pre_deploy.tar.gz

echo "Pre-deployment snapshot created: ${BACKUP_NAME}.tar.gz"
```

---

### Configuration Backup

```bash
#!/bin/bash
# Configuration backup script

BACKUP_DIR="/opt/spacetime/backups/config"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p ${BACKUP_DIR}

# Backup all configuration files
tar -czf ${BACKUP_DIR}/config_${TIMESTAMP}.tar.gz \
  /opt/spacetime/production/.env \
  /opt/spacetime/production/project.godot \
  /etc/systemd/system/godot-spacetime.service \
  /etc/nginx/sites-available/spacetime-api \
  /etc/ssl/certs/spacetime-* \
  /etc/security/limits.conf \
  /etc/sysctl.d/99-spacetime.conf

# Cleanup old config backups (keep 30 days)
find ${BACKUP_DIR} -name "config_*.tar.gz" -mtime +30 -delete

echo "Configuration backup created: config_${TIMESTAMP}.tar.gz"
```

---

### Database Backup (if applicable)

```bash
#!/bin/bash
# Database backup script

BACKUP_DIR="/opt/spacetime/backups/database"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_NAME="spacetime_db"
S3_BUCKET="s3://company-backups/spacetime/database"

mkdir -p ${BACKUP_DIR}

# PostgreSQL backup
pg_dump -U spacetime -d ${DB_NAME} \
  --format=custom \
  --compress=9 \
  --file=${BACKUP_DIR}/db_${TIMESTAMP}.dump

# Create plaintext backup for easy inspection
pg_dump -U spacetime -d ${DB_NAME} \
  --format=plain \
  --file=${BACKUP_DIR}/db_${TIMESTAMP}.sql

# Compress plaintext
gzip ${BACKUP_DIR}/db_${TIMESTAMP}.sql

# Upload to S3
aws s3 cp ${BACKUP_DIR}/db_${TIMESTAMP}.dump ${S3_BUCKET}/

# Cleanup old backups (keep 14 days local, 90 days S3)
find ${BACKUP_DIR} -name "db_*.dump" -mtime +14 -delete
aws s3 ls ${S3_BUCKET}/ | awk '{print $4}' | \
  xargs -I {} bash -c 'if [ $(date -d "$(aws s3 ls '${S3_BUCKET}'/{} | awk \"{print \$1, \$2}\")" +%s) -lt $(date -d "90 days ago" +%s) ]; then aws s3 rm '${S3_BUCKET}'{}; fi'

echo "Database backup completed: db_${TIMESTAMP}.dump"
```

---

## Recovery Procedures

### Full System Recovery

**Use Case:** Complete system failure, rebuild from scratch

**Duration:** 30-45 minutes

```bash
#!/bin/bash
# Full system recovery procedure

set -e

# 1. Identify backup to restore
echo "Available backups:"
aws s3 ls s3://company-backups/spacetime/production/daily/ | tail -10

read -p "Enter backup filename to restore: " BACKUP_FILE
read -p "Are you sure you want to restore $BACKUP_FILE? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Recovery cancelled"
  exit 1
fi

# 2. Download backup from S3
echo "Downloading backup from S3..."
aws s3 cp s3://company-backups/spacetime/production/daily/${BACKUP_FILE} /tmp/
aws s3 cp s3://company-backups/spacetime/production/daily/${BACKUP_FILE}.sha256 /tmp/

# 3. Verify backup integrity
echo "Verifying backup integrity..."
cd /tmp
sha256sum -c ${BACKUP_FILE}.sha256

if [ $? -ne 0 ]; then
  echo "ERROR: Backup checksum verification failed!"
  exit 1
fi

# 4. Stop current service
echo "Stopping Godot service..."
systemctl stop godot-spacetime

# 5. Backup current state (just in case)
if [ -d /opt/spacetime/production ]; then
  echo "Backing up current state..."
  mv /opt/spacetime/production /opt/spacetime/production.before_restore_$(date +%Y%m%d_%H%M%S)
fi

# 6. Extract backup
echo "Extracting backup..."
mkdir -p /opt/spacetime
cd /opt/spacetime
tar -xzf /tmp/${BACKUP_FILE}

# Find the extracted directory
EXTRACTED_DIR=$(tar -tzf /tmp/${BACKUP_FILE} | head -1 | cut -f1 -d"/")

# Move to production directory
mv ${EXTRACTED_DIR}/production /opt/spacetime/production
mv ${EXTRACTED_DIR}/.env /opt/spacetime/production/
mv ${EXTRACTED_DIR}/project.godot /opt/spacetime/production/

# 7. Restore configuration files
if [ -f ${EXTRACTED_DIR}/godot-spacetime.service ]; then
  cp ${EXTRACTED_DIR}/godot-spacetime.service /etc/systemd/system/
  systemctl daemon-reload
fi

# 8. Restore certificates
if [ -d ${EXTRACTED_DIR}/certs ]; then
  cp ${EXTRACTED_DIR}/certs/* /etc/ssl/certs/
fi

# 9. Set correct permissions
chown -R spacetime-app:spacetime-app /opt/spacetime/production
chmod -R 755 /opt/spacetime/production
chmod 600 /opt/spacetime/production/.env

# 10. Start service
echo "Starting Godot service..."
systemctl start godot-spacetime

# 11. Wait for startup
echo "Waiting for service to start..."
sleep 30

# 12. Verify service health
echo "Verifying service health..."
curl -s http://localhost:8080/status | jq .overall_ready

if [ $? -eq 0 ]; then
  echo "✅ Recovery completed successfully!"
  echo "Restored from: $BACKUP_FILE"
  echo "Service is operational"
else
  echo "❌ Recovery verification failed!"
  echo "Service may not be healthy"
  exit 1
fi

# 13. Cleanup
rm -rf /tmp/${BACKUP_FILE} /tmp/${BACKUP_FILE}.sha256 /opt/spacetime/${EXTRACTED_DIR}

echo "Recovery procedure completed"
exit 0
```

---

### Point-in-Time Recovery

**Use Case:** Restore to specific date/time

```bash
#!/bin/bash
# Point-in-time recovery

TARGET_DATE="$1"  # Format: YYYYMMDD

if [ -z "$TARGET_DATE" ]; then
  echo "Usage: $0 YYYYMMDD"
  exit 1
fi

echo "Finding backup closest to $TARGET_DATE..."

# Find backup closest to target date
BACKUP_FILE=$(aws s3 ls s3://company-backups/spacetime/production/daily/ | \
  grep "production_full_${TARGET_DATE}" | \
  tail -1 | \
  awk '{print $4}')

if [ -z "$BACKUP_FILE" ]; then
  echo "No backup found for date $TARGET_DATE"
  echo "Available backups:"
  aws s3 ls s3://company-backups/spacetime/production/daily/ | grep production_full
  exit 1
fi

echo "Found backup: $BACKUP_FILE"
echo "Proceeding with recovery..."

# Use full recovery procedure
/opt/spacetime/scripts/full_recovery.sh $BACKUP_FILE
```

---

### Configuration Rollback

**Use Case:** Rollback configuration after bad change

```bash
#!/bin/bash
# Configuration rollback

BACKUP_DIR="/opt/spacetime/backups/config"

# List available configuration backups
echo "Available configuration backups:"
ls -lt ${BACKUP_DIR}/config_*.tar.gz | head -10 | awk '{print NR, $9}'

read -p "Enter backup number to restore: " BACKUP_NUM
BACKUP_FILE=$(ls -lt ${BACKUP_DIR}/config_*.tar.gz | head -10 | awk -v n=$BACKUP_NUM 'NR==n {print $9}')

if [ -z "$BACKUP_FILE" ]; then
  echo "Invalid selection"
  exit 1
fi

echo "Restoring configuration from: $BACKUP_FILE"

# Stop service
systemctl stop godot-spacetime

# Extract and restore
cd /tmp
tar -xzf $BACKUP_FILE

# Restore configuration files
if [ -f opt/spacetime/production/.env ]; then
  cp opt/spacetime/production/.env /opt/spacetime/production/
fi

if [ -f opt/spacetime/production/project.godot ]; then
  cp opt/spacetime/production/project.godot /opt/spacetime/production/
fi

if [ -f etc/systemd/system/godot-spacetime.service ]; then
  cp etc/systemd/system/godot-spacetime.service /etc/systemd/system/
  systemctl daemon-reload
fi

# Start service
systemctl start godot-spacetime

# Verify
sleep 10
curl -s http://localhost:8080/status | jq .overall_ready

echo "Configuration rollback completed"
```

---

### Partial Recovery - Specific Files

**Use Case:** Recover specific files without full restore

```bash
#!/bin/bash
# Recover specific files from backup

BACKUP_FILE="$1"
shift
FILES_TO_RESTORE="$@"

if [ -z "$BACKUP_FILE" ] || [ -z "$FILES_TO_RESTORE" ]; then
  echo "Usage: $0 <backup_file> <file1> <file2> ..."
  exit 1
fi

# Download backup if S3 URL
if [[ $BACKUP_FILE == s3://* ]]; then
  echo "Downloading from S3..."
  LOCAL_BACKUP="/tmp/$(basename $BACKUP_FILE)"
  aws s3 cp $BACKUP_FILE $LOCAL_BACKUP
  BACKUP_FILE=$LOCAL_BACKUP
fi

# Extract specific files
echo "Extracting files from backup..."
cd /tmp
mkdir -p restore_tmp
cd restore_tmp

for FILE in $FILES_TO_RESTORE; do
  echo "Extracting: $FILE"
  tar -xzf $BACKUP_FILE --wildcards "*/$FILE" || echo "Warning: $FILE not found in backup"
done

# Show extracted files
echo "Extracted files:"
find . -type f

echo "Files extracted to: /tmp/restore_tmp"
echo "Review and manually copy to desired location"
```

---

## Disaster Recovery

### Disaster Recovery Plan

**Scenarios Covered:**
1. Complete data center failure
2. Region-wide outage
3. Catastrophic data loss
4. Security breach requiring rebuild

### DR Procedure - Region Failure

**Objective:** Bring up service in alternate region within 30 minutes

```bash
#!/bin/bash
# Disaster Recovery - Regional Failover

set -e

DR_REGION="us-west-2"  # Alternate region
PRIMARY_REGION="us-east-1"

echo "=== DISASTER RECOVERY PROCEDURE ==="
echo "Primary Region: $PRIMARY_REGION"
echo "DR Region: $DR_REGION"
echo ""

read -p "Are you declaring a disaster and failing over to $DR_REGION? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "DR procedure cancelled"
  exit 1
fi

# 1. Update DNS to point to DR region
echo "Step 1: Updating DNS..."
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "spacetime-api.company.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z0987654321XYZ",
          "DNSName": "dr-lb-'$DR_REGION'.amazonaws.com",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }'

echo "DNS updated. TTL is 60 seconds."

# 2. Verify DR instances are running
echo "Step 2: Verifying DR instances..."
aws ec2 describe-instances \
  --region $DR_REGION \
  --filters "Name=tag:Environment,Values=dr-spacetime" \
  --query 'Reservations[].Instances[].State.Name'

# 3. Start DR services if not running
echo "Step 3: Starting DR services..."
DR_INSTANCES=$(aws ec2 describe-instances \
  --region $DR_REGION \
  --filters "Name=tag:Environment,Values=dr-spacetime" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

for INSTANCE in $DR_INSTANCES; do
  aws ec2 start-instances --region $DR_REGION --instance-ids $INSTANCE
done

# Wait for instances to be running
echo "Waiting for instances to start..."
aws ec2 wait instance-running --region $DR_REGION --instance-ids $DR_INSTANCES

# 4. Restore latest backup to DR environment
echo "Step 4: Restoring latest backup..."
LATEST_BACKUP=$(aws s3 ls s3://company-backups/spacetime/production/daily/ | \
  tail -1 | awk '{print $4}')

echo "Latest backup: $LATEST_BACKUP"

# SSH to DR instance and restore
DR_HOST=$(aws ec2 describe-instances \
  --region $DR_REGION \
  --instance-ids $DR_INSTANCES \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

ssh -i ~/.ssh/dr-key.pem ubuntu@$DR_HOST << EOF
  aws s3 cp s3://company-backups/spacetime/production/daily/$LATEST_BACKUP /tmp/
  cd /opt/spacetime
  sudo systemctl stop godot-spacetime
  sudo tar -xzf /tmp/$LATEST_BACKUP
  sudo chown -R spacetime-app:spacetime-app production
  sudo systemctl start godot-spacetime
EOF

# 5. Verify DR service health
echo "Step 5: Verifying DR service health..."
sleep 30

curl -s http://$DR_HOST:8080/status | jq .overall_ready

# 6. Update monitoring
echo "Step 6: Updating monitoring..."
# Update Grafana dashboards to point to DR region
# Update PagerDuty service endpoints
# Update status page

# 7. Notify team
echo "Step 7: Notifying team..."
curl -X POST "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "🚨 DISASTER RECOVERY ACTIVATED",
    "attachments": [{
      "color": "danger",
      "fields": [
        {"title": "Primary Region", "value": "'$PRIMARY_REGION'", "short": true},
        {"title": "DR Region", "value": "'$DR_REGION'", "short": true},
        {"title": "Status", "value": "FAILOVER COMPLETE", "short": false}
      ]
    }]
  }'

echo "=== DISASTER RECOVERY COMPLETE ==="
echo "Service now running in: $DR_REGION"
echo "DR Host: $DR_HOST"
echo "Monitor service for 1 hour to ensure stability"
```

---

### DR Failback Procedure

**Use Case:** Return to primary region after disaster recovery

```bash
#!/bin/bash
# Failback to primary region

PRIMARY_REGION="us-east-1"
DR_REGION="us-west-2"

echo "=== FAILBACK TO PRIMARY REGION ==="

read -p "Primary region restored and ready for failback? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Failback cancelled"
  exit 1
fi

# 1. Sync current data from DR to primary
echo "Step 1: Syncing data from DR to primary..."
aws s3 sync \
  s3://company-backups-$DR_REGION/spacetime/ \
  s3://company-backups-$PRIMARY_REGION/spacetime/

# 2. Restore to primary region
echo "Step 2: Restoring to primary region..."
# Use latest backup from DR
# SSH to primary and restore

# 3. Verify primary health
echo "Step 3: Verifying primary region health..."
# Run health checks

# 4. Update DNS back to primary
echo "Step 4: Updating DNS to primary region..."
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "spacetime-api.company.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z1234567890ABC",
          "DNSName": "primary-lb-'$PRIMARY_REGION'.amazonaws.com",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }'

# 5. Monitor for issues
echo "Step 5: Monitoring primary region..."
# Monitor for 1 hour

# 6. Shutdown DR instances
echo "Step 6: Shutting down DR instances..."
# Stop DR instances to save costs

echo "=== FAILBACK COMPLETE ==="
```

---

## Testing and Verification

### Monthly Backup Verification

```bash
#!/bin/bash
# Monthly backup verification test

echo "=== BACKUP VERIFICATION TEST ==="
DATE=$(date +%Y-%m-%d)

# 1. List recent backups
echo "Recent backups:"
aws s3 ls s3://company-backups/spacetime/production/daily/ | tail -5

# 2. Download latest backup
LATEST_BACKUP=$(aws s3 ls s3://company-backups/spacetime/production/daily/ | \
  tail -1 | awk '{print $4}')

echo "Testing backup: $LATEST_BACKUP"
aws s3 cp s3://company-backups/spacetime/production/daily/$LATEST_BACKUP /tmp/
aws s3 cp s3://company-backups/spacetime/production/daily/$LATEST_BACKUP.sha256 /tmp/

# 3. Verify checksum
cd /tmp
sha256sum -c $LATEST_BACKUP.sha256

if [ $? -ne 0 ]; then
  echo "❌ FAILED: Checksum verification failed"
  exit 1
fi

# 4. Test extraction
echo "Testing extraction..."
tar -tzf $LATEST_BACKUP > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "❌ FAILED: Extraction failed"
  exit 1
fi

# 5. Verify backup contents
echo "Verifying backup contents..."
EXPECTED_FILES=(
  "production/project.godot"
  "production/.env"
  "production/vr_main.tscn"
  ".env"
  "metadata.json"
)

for FILE in "${EXPECTED_FILES[@]}"; do
  tar -tzf $LATEST_BACKUP | grep -q "$FILE"
  if [ $? -ne 0 ]; then
    echo "❌ FAILED: Missing file: $FILE"
    exit 1
  fi
done

# 6. Verify metadata
tar -xzf $LATEST_BACKUP --wildcards "*/metadata.json" -O > /tmp/metadata.json
VERSION=$(jq -r .version /tmp/metadata.json)
COMMIT=$(jq -r .commit /tmp/metadata.json)

echo "Backup metadata:"
echo "  Version: $VERSION"
echo "  Commit: $COMMIT"

# 7. Test partial restoration
echo "Testing partial restoration..."
mkdir -p /tmp/restore_test
cd /tmp/restore_test
tar -xzf /tmp/$LATEST_BACKUP --wildcards "*/project.godot"

if [ ! -f */project.godot ]; then
  echo "❌ FAILED: Partial restoration failed"
  exit 1
fi

# 8. Cleanup
rm -rf /tmp/$LATEST_BACKUP /tmp/$LATEST_BACKUP.sha256 /tmp/restore_test /tmp/metadata.json

echo "✅ PASSED: All backup verification tests passed"
echo "Backup Date: $DATE"
echo "Backup File: $LATEST_BACKUP"

# 9. Record results
echo "$DATE,PASSED,$LATEST_BACKUP" >> /var/log/backup-verification.log

# 10. Notify team
curl -X POST "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"✅ Monthly backup verification passed for $DATE\"}"

exit 0
```

---

### Quarterly DR Drill

**Schedule:** First Saturday of each quarter at 10:00 UTC

**Checklist:**
```markdown
# Quarterly DR Drill Checklist

Date: __________
Participants: __________

## Pre-Drill
- [ ] Schedule DR drill (2 weeks notice)
- [ ] Notify team and stakeholders
- [ ] Review DR procedures
- [ ] Verify DR environment ready
- [ ] Update DNS TTL to 60 seconds (24 hours before)

## Drill Execution
- [ ] Start time: __________
- [ ] Simulate primary region failure
- [ ] Execute DR failover procedure
- [ ] Verify service in DR region
- [ ] Test all critical endpoints
- [ ] Run smoke tests
- [ ] Document any issues

## Verification
- [ ] Service accessible in DR region: Yes/No
- [ ] All endpoints functional: Yes/No
- [ ] Data integrity verified: Yes/No
- [ ] Performance acceptable: Yes/No
- [ ] Monitoring updated: Yes/No

## Failback
- [ ] Execute failback procedure
- [ ] Verify service in primary region
- [ ] Update DNS back to primary
- [ ] Shutdown DR instances

## Metrics
- [ ] Time to detect: __________
- [ ] Time to failover: __________
- [ ] Time to verify: __________
- [ ] Total duration: __________
- [ ] RTO achieved: Yes/No (target: 30 min)

## Post-Drill
- [ ] Document lessons learned
- [ ] Update DR procedures
- [ ] Create improvement tickets
- [ ] Share report with stakeholders
- [ ] Schedule next drill

## Issues Encountered
1. __________
2. __________
3. __________

## Improvements Identified
1. __________
2. __________
3. __________

## Sign-off
DR Coordinator: __________
Engineering Manager: __________
```

---

## Appendix

### Backup Storage Locations

**Primary Backup Storage:**
- Local: `/opt/spacetime/backups/`
- S3: `s3://company-backups/spacetime/production/`
- Glacier: `s3://company-archive/spacetime/`

**DR Backup Storage:**
- S3 DR Region: `s3://company-backups-dr/spacetime/`

### Backup Size Estimates

| Backup Type | Typical Size | Maximum Size |
|-------------|--------------|--------------|
| Full Backup | 10-15 GB | 25 GB |
| Incremental | 500 MB - 1 GB | 2 GB |
| Configuration | 5-10 MB | 20 MB |
| Database | Varies | 50 GB |
| Logs (7 days) | 2-5 GB | 10 GB |

### Recovery Time Estimates

| Recovery Type | Expected Time | Maximum Time |
|---------------|---------------|--------------|
| Full Recovery | 30 minutes | 60 minutes |
| Point-in-Time | 20 minutes | 45 minutes |
| Configuration Rollback | 5 minutes | 15 minutes |
| Partial File Recovery | 10 minutes | 20 minutes |
| DR Failover | 15 minutes | 30 minutes |
| DR Failback | 30 minutes | 60 minutes |

### Contact Information

**Backup Administrator:** backup-admin@company.com
**DR Coordinator:** dr-coordinator@company.com
**24/7 Support:** +1-555-0123
**PagerDuty:** spacetime-backup-alerts

---

## Runbook Maintenance

- **Review Frequency:** Monthly, after each DR drill
- **Last Reviewed:** 2025-12-02
- **Next Review:** 2026-01-02
- **Owner:** DevOps Team
- **Approver:** Engineering Manager

**Change Log:**
- 2025-12-02: Initial version for v2.5.0
