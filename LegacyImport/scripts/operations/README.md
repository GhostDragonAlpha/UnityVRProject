# Operations Scripts - Backup & Disaster Recovery

Comprehensive backup and disaster recovery system for Planetary Survival VR production environment.

## Overview

This directory contains all scripts and tools for:
- Automated backups (full, incremental, transaction logs)
- Disaster recovery procedures
- Backup verification and integrity checking
- DR test automation
- Monitoring and alerting

**Recovery Objectives:**
- **RTO (Recovery Time Objective):** <15 minutes
- **RPO (Recovery Point Objective):** <5 minutes

## Directory Structure

```
operations/
├── backup/
│   ├── backup_manager.py          # Main backup orchestrator
│   ├── scheduled_backup.sh        # Cron-based backup automation
│   ├── backup_monitoring.py       # Prometheus metrics exporter
│   └── requirements.txt           # Python dependencies
├── restore/
│   └── restore_manager.py         # Disaster recovery restore tool
├── verify_backup.py               # Backup integrity verification
└── dr_test_automation.py          # Automated DR testing
```

## Quick Start

### 1. Install Dependencies

```bash
# Install Python dependencies
cd /c/godot/scripts/operations/backup
pip install -r requirements.txt

# Install system dependencies (Ubuntu/Debian)
apt-get install -y \
    cockroach \
    redis-tools \
    awscli \
    azure-cli \
    google-cloud-sdk \
    jq \
    curl

# Configure cloud credentials
aws configure
az login
gcloud auth login
```

### 2. Configure Environment

Create `/etc/spacetime/backup.env`:

```bash
# Database
DB_HOST=localhost
DB_PORT=26257
DB_NAME=planetary_survival
DB_USER=backup_user
DB_PASSWORD=<secure_password>

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=<secure_password>

# AWS S3 (Primary)
BACKUP_S3_BUCKET=planetary-survival-backups-primary
BACKUP_S3_REGION=us-east-1
AWS_ACCESS_KEY_ID=<key_id>
AWS_SECRET_ACCESS_KEY=<secret_key>

# Azure Blob Storage (Secondary)
BACKUP_AZURE_ACCOUNT=planetarysurvivalbackups
BACKUP_AZURE_CONTAINER=planetary-survival-backups
AZURE_STORAGE_CONNECTION_STRING=<connection_string>

# Google Cloud Storage (Tertiary)
BACKUP_GCS_BUCKET=planetary-survival-backups-dr
BACKUP_GCS_PROJECT=planetary-survival-dr
GOOGLE_APPLICATION_CREDENTIALS=/etc/spacetime/gcp-credentials.json

# Encryption
BACKUP_ENCRYPTION_KEY=/etc/spacetime/backup.key

# Alerting
BACKUP_ALERT_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### 3. Generate Encryption Key

```bash
# Generate 256-bit encryption key
openssl rand -base64 32 > /etc/spacetime/backup.key
chmod 600 /etc/spacetime/backup.key
```

### 4. Setup Cron Jobs

```bash
# Edit crontab
crontab -e

# Add backup schedules
# Daily full backup at 2 AM
0 2 * * * /c/godot/scripts/operations/backup/scheduled_backup.sh full >> /var/log/spacetime/backup_cron.log 2>&1

# Hourly incremental backup
0 * * * * /c/godot/scripts/operations/backup/scheduled_backup.sh incremental >> /var/log/spacetime/backup_cron.log 2>&1

# Weekly verification on Sunday at 4 AM
0 4 * * 0 python3 /c/godot/scripts/operations/verify_backup.py $(cat /var/backups/metadata/latest_backup_id.txt) >> /var/log/spacetime/verify_cron.log 2>&1

# Monthly cleanup on 1st at 3 AM
0 3 1 * * /c/godot/scripts/operations/backup/scheduled_backup.sh cleanup >> /var/log/spacetime/cleanup_cron.log 2>&1
```

### 5. Start Monitoring Service

```bash
# Start backup monitoring (exports Prometheus metrics)
python3 /c/godot/scripts/operations/backup/backup_monitoring.py &

# Verify metrics endpoint
curl http://localhost:9091/metrics
```

## Usage

### Manual Backup

#### Full Backup

```bash
cd /c/godot/scripts/operations/backup
python3 backup_manager.py full
```

#### Incremental Backup

```bash
# Automatic detection of last full backup
./scheduled_backup.sh incremental
```

#### Component-Specific Backup

```bash
# Backup only Redis
python3 backup_manager.py redis

# Backup only configuration
python3 backup_manager.py configuration
```

### Restore Operations

#### Full System Restore

```bash
cd /c/godot/scripts/operations/restore

# Restore from local backup
python3 restore_manager.py <backup_id> local

# Restore from S3
python3 restore_manager.py <backup_id> s3

# Restore from Azure
python3 restore_manager.py <backup_id> azure

# Restore from GCS (DR scenario)
python3 restore_manager.py <backup_id> gcs
```

#### Component-Specific Restore

```bash
# Restore only database
python3 restore_manager.py <backup_id> local --component=database

# Restore only Redis
python3 restore_manager.py <backup_id> local --component=redis
```

### Backup Verification

```bash
cd /c/godot/scripts/operations

# Verify specific backup
python3 verify_backup.py <backup_id>

# Verify latest backup
python3 verify_backup.py $(cat /var/backups/metadata/latest_backup_id.txt)
```

### Disaster Recovery Testing

```bash
cd /c/godot/scripts/operations

# Test database recovery
python3 dr_test_automation.py database

# Test complete datacenter failover
python3 dr_test_automation.py datacenter

# Test Redis recovery
python3 dr_test_automation.py redis

# Test corrupted backup scenario
python3 dr_test_automation.py corrupted_backup

# Run all DR tests
python3 dr_test_automation.py full
```

## Kubernetes Deployment

### Deploy Backup CronJobs

```bash
# Apply backup configurations
kubectl apply -f /c/godot/kubernetes/backup/backup-cronjob.yaml

# Verify CronJobs
kubectl get cronjobs -n spacetime

# Check backup job history
kubectl get jobs -n spacetime -l app=spacetime-backup

# View backup logs
kubectl logs -n spacetime -l app=spacetime-backup --tail=100
```

### Manual Backup Job

```bash
# Trigger manual full backup
kubectl create job -n spacetime \
  --from=cronjob/spacetime-backup-full \
  manual-backup-$(date +%Y%m%d-%H%M%S)

# Monitor job progress
kubectl get jobs -n spacetime -w
kubectl logs -n spacetime -f job/manual-backup-<timestamp>
```

## Monitoring & Alerting

### Grafana Dashboard

Access the backup health dashboard:
```
https://grafana.planetary-survival.com/d/backup_health
```

Key metrics monitored:
- Backup success rate
- Last successful backup timestamp
- Backup duration and size
- RPO and RTO metrics
- Storage replication status
- Verification success rate

### Prometheus Queries

```promql
# Backup success rate (last 24h)
rate(backup_completed_total{status="success"}[24h]) / rate(backup_completed_total[24h]) * 100

# Time since last backup (minutes)
(time() - backup_last_success_timestamp_seconds) / 60

# Current RPO
(time() - backup_last_success_timestamp_seconds) / 60 < 5

# Current RTO
backup_restore_duration_seconds / 60 < 15

# Storage replication health
sum(backup_storage_replication_status) >= 2
```

### Alerts

Configured alerts:
- **Backup Failed:** Triggered when backup success rate < 95%
- **Backup Age:** Triggered when last backup > 2 hours old
- **RPO Exceeded:** Triggered when RPO > 5 minutes
- **RTO Exceeded:** Triggered when restore time > 15 minutes
- **Storage Unavailable:** Triggered when < 2 storage locations available
- **Verification Failed:** Triggered when verification success rate < 95%

## Disaster Recovery Runbook

For detailed disaster recovery procedures, see:
```
/c/godot/docs/operations/DISASTER_RECOVERY.md
```

Key scenarios covered:
1. Database corruption/failure
2. Complete datacenter failure
3. Redis state loss
4. Corrupted backup recovery
5. Kubernetes cluster failure

## Backup Retention Policy

| Backup Type | Retention | Storage Tier |
|-------------|-----------|--------------|
| Incremental | 24 hours | Standard |
| Daily | 7 days | Standard-IA |
| Weekly | 4 weeks | Standard-IA |
| Monthly | 12 months | Glacier |
| Yearly | 3 years | Deep Archive |

## Storage Architecture

### Primary Storage (S3 - us-east-1)
- Real-time replication
- Standard-IA for cost optimization
- Versioning enabled
- Lifecycle policies configured

### Secondary Storage (Azure - westus2)
- Asynchronous replication
- Different cloud provider for diversity
- Hot tier for recent backups
- Cool tier for older backups

### Tertiary Storage (GCS - europe-west1)
- DR location in different continent
- Complete geographic isolation
- Nearline storage class
- Cross-region replication

## Security

### Encryption
- **At Rest:** AES-256 encryption for all backups
- **In Transit:** TLS 1.3 for all transfers
- **Key Management:** Separate encryption keys per environment

### Access Control
- IAM roles with least privilege
- Service accounts for automation
- MFA required for manual restores
- Audit logging enabled

### Compliance
- GDPR compliant (data residency)
- SOC 2 Type II controls
- Regular security audits
- Encrypted backup verification

## Troubleshooting

### Common Issues

#### Backup Fails with "Connection Timeout"

```bash
# Check database connectivity
kubectl exec -it cockroachdb-0 -n spacetime -- cockroach sql --insecure -e "SELECT 1;"

# Check network policies
kubectl get networkpolicies -n spacetime

# Verify service endpoints
kubectl get svc -n spacetime
```

#### Restore Takes Too Long

```bash
# Check backup size
aws s3 ls s3://planetary-survival-backups-primary/backups/primary/database/<backup_id>/ --recursive --human-readable --summarize

# Monitor restore progress
tail -f /var/log/spacetime/restore.log

# Check disk I/O
iostat -x 5
```

#### Verification Fails

```bash
# Check backup integrity
python3 verify_backup.py <backup_id> --verbose

# Re-download from alternative storage
python3 restore_manager.py <backup_id> azure --verify-only

# Test restore in isolated environment
python3 dr_test_automation.py verification
```

#### Storage Full

```bash
# Check disk usage
df -h /var/backups

# Run cleanup
/c/godot/scripts/operations/backup/scheduled_backup.sh cleanup

# Adjust retention policy
# Edit /etc/spacetime/backup.env
BACKUP_RETENTION_DAILY=5  # Reduce from 7
```

## Performance Tuning

### Optimize Backup Speed

```bash
# Increase parallelism
export BACKUP_PARALLEL_THREADS=8

# Use compression
export BACKUP_COMPRESSION=gzip

# Exclude unnecessary files
export BACKUP_EXCLUDE_PATTERNS="*.log,*.tmp,cache/*"
```

### Optimize Restore Speed

```bash
# Use local restore for faster recovery
python3 restore_manager.py <backup_id> local

# Pre-download backups during off-peak
aws s3 sync s3://planetary-survival-backups-primary/backups/primary/ /var/backups/cache/

# Use SSD storage for restore operations
mount -t tmpfs -o size=20G tmpfs /tmp/restore_cache
```

## Testing Schedule

- **Daily:** Backup verification (automated)
- **Weekly:** Restore test (automated)
- **Monthly:** Partial DR drill (database recovery)
- **Quarterly:** Full DR drill (datacenter failover)
- **Annually:** DR plan review and tabletop exercise

## Support

For assistance with backup and disaster recovery:
- **Documentation:** `/c/godot/docs/operations/DISASTER_RECOVERY.md`
- **Logs:** `/var/log/spacetime/backup.log`, `/var/log/spacetime/restore.log`
- **Monitoring:** https://grafana.planetary-survival.com/d/backup_health
- **Incident Response:** #incident-response (Slack)

## Contributing

When modifying backup/DR scripts:
1. Test in development environment first
2. Update documentation
3. Run DR test suite: `python3 dr_test_automation.py full`
4. Update runbook if procedures change
5. Notify team of changes

## License

Internal use only - Planetary Survival VR Production System
