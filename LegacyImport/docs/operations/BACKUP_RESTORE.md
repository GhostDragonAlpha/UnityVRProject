# Backup and Restore Operations Guide

## Overview

The SpaceTime backup system provides comprehensive disaster recovery capabilities with:
- **Multi-component backups** (database, Redis, player saves, configuration, application)
- **Multi-region cloud storage** (S3, Azure, Google Cloud)
- **Encryption and compression** for security and efficiency
- **Recovery Time Objective (RTO)**: <15 minutes
- **Recovery Point Objective (RPO)**: <5 minutes

## System Architecture

### Components

#### Backup Manager (`backup_manager.py`)
- Orchestrates full backups of all system components
- Encrypts and compresses backup artifacts
- Uploads to cloud storage (S3, Azure, GCS)
- Generates backup metadata and checksums

**Location**: `C:/godot/scripts/operations/backup/backup_manager.py`

#### Backup Monitoring (`backup_monitoring.py`)
- Exports Prometheus metrics for backup health
- Monitors backup status and integrity
- Tracks storage replication across regions
- Measures transaction log lag

**Location**: `C:/godot/scripts/operations/backup/backup_monitoring.py`

#### Scheduled Backup Script (`scheduled_backup.sh`)
- Orchestrates daily full and hourly incremental backups
- Manages backup cleanup and retention policies
- Uploads to cloud storage
- Sends alerts on success/failure

**Location**: `C:/godot/scripts/operations/backup/scheduled_backup.sh`

#### Restore Manager (`restore_manager.py`)
- Restores system from backups
- Downloads backups from cloud storage
- Decrypts and extracts backup artifacts
- Verifies component restoration

**Location**: `C:/godot/scripts/operations/restore/restore_manager.py`

## Environment Setup

### Required Services

All backup operations require these services running:

```bash
# CockroachDB (database)
cockroach start

# Redis (caching)
redis-server

# AWS CLI (S3 uploads)
aws s3 ls  # Test connection

# Azure CLI (Azure uploads)
az account show  # Test connection

# Google Cloud SDK (GCS uploads)
gsutil ls gs://your-bucket  # Test connection
```

### Environment Variables

Configure before running backup/restore operations:

```bash
# Database Configuration
export DB_HOST=localhost
export DB_PORT=26257
export DB_NAME=planetary_survival
export DB_USER=backup_user

# Redis Configuration
export REDIS_HOST=localhost
export REDIS_PORT=6379
export REDIS_PASSWORD=your-redis-password

# AWS S3 Configuration
export BACKUP_S3_BUCKET=planetary-survival-backups-primary
export BACKUP_S3_REGION=us-east-1
export AWS_ACCESS_KEY_ID=your-aws-key
export AWS_SECRET_ACCESS_KEY=your-aws-secret

# Azure Configuration
export BACKUP_AZURE_CONTAINER=planetary-survival-backups
export BACKUP_AZURE_ACCOUNT=your-azure-account
export AZURE_STORAGE_CONNECTION_STRING=your-connection-string

# Google Cloud Configuration
export BACKUP_GCS_BUCKET=planetary-survival-backups-dr
export BACKUP_GCS_PROJECT=your-gcp-project
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json

# Encryption Configuration
export BACKUP_ENCRYPTION_KEY=/etc/spacetime/backup.key

# Alerting (Optional)
export BACKUP_ALERT_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

## Backup Operations

### Full Backup

Backs up all system components.

**Usage**:
```bash
python scripts/operations/backup/backup_manager.py full
```

**What's included**:
1. **Database** - Full CockroachDB backup with revision history
2. **Redis** - RDB dump and AOF file
3. **Player Saves** - All user save files (compressed tar.gz)
4. **Configuration** - Server config, Kubernetes manifests, Terraform code
5. **Application** - Build artifacts, addons, scripts

**Example Output**:
```json
{
  "backup_id": "20240103_142530",
  "start_time": "2024-01-03T14:25:30.123456",
  "end_time": "2024-01-03T14:35:45.654321",
  "components": {
    "database": {
      "type": "full",
      "size_bytes": 5368709120,
      "duration_seconds": 245.5,
      "success": true
    },
    "redis": {
      "type": "redis",
      "files": ["dump.rdb", "appendonly.aof"],
      "size_bytes": 2147483648,
      "success": true
    },
    "player_saves": {
      "type": "player_saves",
      "size_bytes": 1073741824,
      "file_count": 15234,
      "duration_seconds": 120.3,
      "success": true
    },
    "configuration": {
      "type": "configuration",
      "size_bytes": 104857600,
      "files": 342,
      "success": true
    },
    "application": {
      "type": "application",
      "size_bytes": 2684354560,
      "duration_seconds": 89.7,
      "success": true
    }
  },
  "overall_success": true
}
```

**Backup Locations**:
- Local: `/var/backups/{database,redis,player_saves,config,application}/{backup_id}/`
- S3: `s3://planetary-survival-backups-primary/backups/primary/{type}/{backup_id}/`
- Azure: `planetary-survival-backups/backups/secondary/{type}/{backup_id}/`
- GCS: `gs://planetary-survival-backups-dr/backups/tertiary/{type}/{backup_id}/`

### Scheduled Backups

Automate backup scheduling using cron or Windows Task Scheduler.

**Cron Setup (Linux)**:
```bash
# Edit crontab
crontab -e

# Add entries
0 2 * * *  /path/to/scripts/operations/backup/scheduled_backup.sh full      # Daily 2 AM
0 * * * *  /path/to/scripts/operations/backup/scheduled_backup.sh incremental # Hourly

# Monitor logs
tail -f /var/log/spacetime/scheduled_backup.log
```

**Windows Task Scheduler Setup**:
1. Open Task Scheduler
2. Create Basic Task
3. Name: "SpaceTime Daily Backup"
4. Trigger: Daily at 2:00 AM
5. Action: Run script with full path
6. Program: `C:\python.exe`
7. Arguments: `C:\godot\scripts\operations\backup\backup_manager.py full`

### Incremental Backup

Backs up only changes since last full backup (faster, smaller).

**Usage**:
```bash
python scripts/operations/backup/backup_manager.py incremental <last_backup_path>
```

**Example**:
```bash
python scripts/operations/backup/backup_manager.py incremental /var/backups/db/20240103_142530
```

**Benefits**:
- 5-10x faster than full backup
- 50-80% smaller size
- Good for hourly backups

## Restore Operations

### Full System Restore

Restores entire system from backup.

**Usage**:
```bash
python scripts/operations/restore/restore_manager.py <backup_id> [restore_location]
```

**Example - Restore from local backup**:
```bash
python scripts/operations/restore/restore_manager.py 20240103_142530 local
```

**Example - Restore from S3 (remote)**:
```bash
python scripts/operations/restore/restore_manager.py 20240103_142530 s3
```

**Example - Restore from Azure (remote)**:
```bash
python scripts/operations/restore/restore_manager.py 20240103_142530 azure
```

**Restore Locations**:
- `local` - Restore from `/var/backups/`
- `s3` - Download from S3, then restore
- `azure` - Download from Azure, then restore
- `gcs` - Download from GCS, then restore

**Restore Process**:
1. **Configuration** (restored first - needed by other services)
2. **Database** - Full RESTORE from CockroachDB backup
3. **Redis** - Copy RDB/AOF files, restart Redis
4. **Player Saves** - Extract tar.gz archive
5. **Verification** - Verify each component after restore

**Example Output**:
```json
{
  "backup_id": "20240103_142530",
  "start_time": "2024-01-03T15:42:10.123456",
  "end_time": "2024-01-03T15:55:45.654321",
  "restore_location": "local",
  "rto_seconds": 815.531265,
  "components": {
    "configuration": {
      "success": true
    },
    "database": {
      "success": true,
      "duration_seconds": 412.3
    },
    "redis": {
      "success": true
    },
    "player_saves": {
      "success": true
    }
  },
  "overall_success": true
}
```

### Component-Specific Restore

Restore individual components if needed:

**Database Only**:
```python
from restore_manager import RestoreManager

manager = RestoreManager("20240103_142530", "local")
success = manager.restore_database("/var/backups/db/20240103_142530")
```

**Redis Only**:
```python
manager.restore_redis("/var/backups/redis/20240103_142530")
```

**Player Saves Only**:
```python
manager.restore_player_saves("/var/backups/player_saves/20240103_142530")
```

## Backup Monitoring

### Real-Time Metrics

Start the backup monitoring service:

```bash
python scripts/operations/backup/backup_monitoring.py
```

**Prometheus Metrics Exposed** (port 9091):

```
# Backup Success Tracking
backup_last_success_timestamp_seconds{component="database",type="full"}
backup_completed_total{component="database",status="success",type="full"}

# Performance Metrics
backup_duration_seconds{component="database",type="full"}
backup_size_bytes{component="database"}

# Storage Replication
backup_storage_replication_status{location="s3_primary"}
backup_storage_replication_status{location="azure_secondary"}
backup_storage_replication_status{location="gcs_tertiary"}

# Recovery Metrics
backup_restore_duration_seconds
transaction_log_lag_seconds
dr_test_completed_total{scenario="failover",status="success"}

# System Info
backup_system_info{version="1.0",target_rto="900",target_rpo="300"}
```

### Prometheus Configuration

Add to `prometheus.yml`:

```yaml
global:
  scrape_interval: 30s

scrape_configs:
  - job_name: 'spacetime-backup'
    static_configs:
      - targets: ['localhost:9091']
```

### Grafana Dashboard

Create dashboard with panels:

1. **Backup Status** - Last successful backup timestamp per component
2. **Backup Duration** - Time taken for each backup type
3. **Backup Size** - Storage used by each component
4. **Replication Status** - S3, Azure, GCS availability
5. **RTO/RPO Compliance** - Actual vs target recovery times

## Retention Policy

Backup retention automatically managed by `scheduled_backup.sh`:

```
Daily Backups:   Keep 7 days
Weekly Backups:  Keep 4 weeks
Monthly Backups: Keep 12 months
Yearly Backups:  Keep 3 years

Incremental:     Keep 1 day (linked to daily full backups)
```

### Manual Cleanup

If manual cleanup needed:

```bash
# Clean database backups older than 7 days
find /var/backups/db -maxdepth 1 -type d -name "20*" -mtime +7 ! -name "*_incremental" -exec rm -rf {} \;

# Clean S3 (requires lifecycle policy - see AWS docs)
aws s3 ls s3://planetary-survival-backups-primary/ --recursive | \
  awk '{if ($1 < "'$(date -d '7 days ago' +%Y-%m-%d)'") print $4}' | \
  xargs -I {} aws s3 rm s3://planetary-survival-backups-primary/{}
```

## Disaster Recovery Scenarios

### Scenario 1: Database Corruption

**Problem**: Database reports corruption
**Solution**:
```bash
# 1. Find latest good backup
ls -lt /var/backups/db/

# 2. Restore database only
python scripts/operations/restore/restore_manager.py 20240103_142530 local

# 3. Verify restored database
cockroach sql --insecure -e "SELECT COUNT(*) FROM information_schema.tables;"

# 4. Restart application
systemctl restart spacetime-api
```

### Scenario 2: Data Center Failure

**Problem**: Entire data center unavailable
**Solution**:
```bash
# 1. Spin up new infrastructure in another region
# 2. Download backup from alternative storage (Azure or GCS)
python scripts/operations/restore/restore_manager.py 20240103_142530 azure

# 3. Verify all components restored
python tests/health_monitor.py

# 4. Update DNS/load balancer to new region
# 5. Monitor metrics during transition
```

### Scenario 3: Player Data Loss

**Problem**: Player saves corrupted
**Solution**:
```bash
# 1. Restore only player saves
from restore_manager import RestoreManager
manager = RestoreManager("20240103_142530", "s3")
manager.restore_player_saves("/var/backups/player_saves/20240103_142530")

# 2. Notify affected players
# 3. Provide rollback window for progression
```

## Troubleshooting

### Issue: Backup Fails with "Database connection refused"
**Solution**:
1. Verify database is running: `cockroach status`
2. Check credentials in env vars
3. Verify network connectivity: `telnet localhost 26257`

### Issue: S3 Upload Fails
**Solution**:
1. Verify AWS credentials: `aws sts get-caller-identity`
2. Check bucket exists: `aws s3 ls | grep planetary-survival`
3. Verify IAM permissions for s3:PutObject
4. Check bucket policy allows uploads

### Issue: Restore Takes Too Long
**Solution**:
1. Monitor progress: `tail -f /var/log/spacetime/restore.log`
2. Check available disk space: `df -h`
3. Monitor network: `iftop` or `nethogs`
4. Consider parallel downloads from cloud storage

### Issue: Encryption Key Not Found
**Solution**:
1. Generate encryption key: `openssl rand -hex 32 > /etc/spacetime/backup.key`
2. Set permissions: `chmod 600 /etc/spacetime/backup.key`
3. Export env var: `export BACKUP_ENCRYPTION_KEY=/etc/spacetime/backup.key`

### Issue: Backup Metadata Missing
**Solution**:
1. Check metadata location: `ls -la /var/backups/metadata/`
2. Verify backup completed successfully
3. Check disk space didn't fill during backup
4. Manually create metadata from backup contents

## Best Practices

1. **Test restores regularly**:
```bash
# Monthly restore test
python scripts/operations/restore/restore_manager.py $(date +%Y%m%d_%H%M%S | sed 's/_/%/g') local
```

2. **Monitor backup metrics**:
- Set up alerts for failed backups
- Track RTO/RPO compliance
- Monitor storage growth

3. **Secure encryption keys**:
- Store keys in secret management (Vault, AWS Secrets Manager)
- Rotate keys quarterly
- Never commit keys to version control

4. **Document recovery procedures**:
- Keep runbooks updated
- Train team on restore procedures
- Conduct regular DR drills

5. **Multi-region redundancy**:
- Keep backups in 3+ regions
- Test cross-region restores
- Have failover procedures documented

## Performance Tuning

### Speed Up Backups

```bash
# Increase parallel uploads
export AWS_PARALLEL_JOBS=8
export AZURE_PARALLEL_JOBS=8

# Use faster storage locally
# Mount SSD for /var/backups

# Compress before upload
# Use gzip -9 for maximum compression
```

### Reduce Backup Size

```bash
# Exclude non-essential files in backup_manager.py:
shutil.ignore_patterns('*.pyc', '__pycache__', '.git')

# Use incremental backups (much smaller)
scheduled_backup.sh incremental

# Archive old backups to tape/cold storage
```

## Related Documentation

- **PERFORMANCE_PROFILING.md** - Monitor backup performance
- **VALIDATION_TOOLS.md** - Validate restore integrity
- **COMPREHENSIVE_SYSTEM_HEALTH_REPORT.md** - Overall system health

## Support

For backup/restore issues:
1. Check log files at `/var/log/spacetime/backup.log` and `/var/log/spacetime/restore.log`
2. Verify environment variables are set
3. Test cloud storage connectivity
4. Run health checks with `python tests/health_monitor.py`
