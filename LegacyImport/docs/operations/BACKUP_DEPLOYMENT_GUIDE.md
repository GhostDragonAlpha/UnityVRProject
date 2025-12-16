# Backup & Disaster Recovery Deployment Guide

Complete step-by-step guide for deploying the backup and disaster recovery system in production.

## Prerequisites

- Kubernetes cluster (v1.24+)
- CockroachDB database cluster
- Redis instance
- AWS account with S3 access
- Azure account with Blob Storage
- Google Cloud account with Cloud Storage
- kubectl configured for production cluster
- Sufficient storage (500GB+ for local backups)

## Deployment Steps

### Phase 1: Infrastructure Setup (Day 1)

#### 1.1 Create Storage Buckets

**AWS S3 (Primary):**
```bash
# Create S3 bucket
aws s3 mb s3://planetary-survival-backups-primary --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket planetary-survival-backups-primary \
  --versioning-configuration Status=Enabled

# Configure lifecycle policy
cat > s3-lifecycle.json <<EOF
{
  "Rules": [
    {
      "Id": "TransitionOldBackups",
      "Status": "Enabled",
      "Transitions": [
        {
          "Days": 7,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 30,
          "StorageClass": "GLACIER"
        },
        {
          "Days": 90,
          "StorageClass": "DEEP_ARCHIVE"
        }
      ],
      "Expiration": {
        "Days": 1095
      }
    }
  ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
  --bucket planetary-survival-backups-primary \
  --lifecycle-configuration file://s3-lifecycle.json

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket planetary-survival-backups-primary \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

**Azure Blob Storage (Secondary):**
```bash
# Create resource group
az group create \
  --name planetary-survival-backups-rg \
  --location westus2

# Create storage account
az storage account create \
  --name planetarysurvivalbackups \
  --resource-group planetary-survival-backups-rg \
  --location westus2 \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name planetary-survival-backups \
  --account-name planetarysurvivalbackups \
  --public-access off

# Configure lifecycle management
cat > azure-lifecycle.json <<EOF
{
  "rules": [
    {
      "enabled": true,
      "name": "MoveToArchive",
      "type": "Lifecycle",
      "definition": {
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 7
            },
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 30
            },
            "delete": {
              "daysAfterModificationGreaterThan": 1095
            }
          }
        },
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["backups/"]
        }
      }
    }
  ]
}
EOF

az storage account management-policy create \
  --account-name planetarysurvivalbackups \
  --resource-group planetary-survival-backups-rg \
  --policy @azure-lifecycle.json
```

**Google Cloud Storage (Tertiary/DR):**
```bash
# Create GCS bucket
gsutil mb -l europe-west1 -c NEARLINE gs://planetary-survival-backups-dr

# Enable versioning
gsutil versioning set on gs://planetary-survival-backups-dr

# Configure lifecycle
cat > gcs-lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "COLDLINE"
        },
        "condition": {
          "age": 30
        }
      },
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "ARCHIVE"
        },
        "condition": {
          "age": 90
        }
      },
      {
        "action": {
          "type": "Delete"
        },
        "condition": {
          "age": 1095
        }
      }
    ]
  }
}
EOF

gsutil lifecycle set gcs-lifecycle.json gs://planetary-survival-backups-dr
```

#### 1.2 Create Kubernetes Namespace and Secrets

```bash
# Create namespace
kubectl create namespace spacetime

# Create AWS credentials secret
kubectl create secret generic aws-credentials -n spacetime \
  --from-literal=access_key_id=<AWS_ACCESS_KEY_ID> \
  --from-literal=secret_access_key=<AWS_SECRET_ACCESS_KEY>

# Create Azure credentials secret
kubectl create secret generic azure-credentials -n spacetime \
  --from-literal=connection_string=<AZURE_CONNECTION_STRING>

# Create GCP credentials secret
kubectl create secret generic gcp-credentials -n spacetime \
  --from-file=credentials.json=<path-to-gcp-service-account-key>

# Create backup encryption key
openssl rand -base64 32 > backup-encryption.key
kubectl create secret generic backup-encryption-key -n spacetime \
  --from-file=key=backup-encryption.key
rm backup-encryption.key

# Create database backup user credentials
kubectl create secret generic db-backup-credentials -n spacetime \
  --from-literal=DB_BACKUP_USER=backup_user \
  --from-literal=DB_BACKUP_PASSWORD=<secure_password>

# Create alert webhook secret
kubectl create secret generic alert-webhook -n spacetime \
  --from-literal=ALERT_WEBHOOK=<slack_or_pagerduty_webhook_url>
```

#### 1.3 Deploy Backup System

```bash
# Deploy backup configurations
kubectl apply -f /c/godot/kubernetes/backup/backup-cronjob.yaml

# Verify CronJobs
kubectl get cronjobs -n spacetime
kubectl describe cronjob spacetime-backup-full -n spacetime

# Verify service account and RBAC
kubectl get serviceaccount backup-service-account -n spacetime
kubectl get role backup-role -n spacetime
kubectl get rolebinding backup-rolebinding -n spacetime
```

### Phase 2: Initial Backup (Day 1-2)

#### 2.1 Trigger First Manual Backup

```bash
# Trigger manual full backup
kubectl create job -n spacetime \
  --from=cronjob/spacetime-backup-full \
  initial-backup-$(date +%Y%m%d)

# Monitor backup progress
kubectl logs -n spacetime -f job/initial-backup-<date>

# Wait for completion (may take 1-2 hours for initial backup)
kubectl wait --for=condition=complete -n spacetime job/initial-backup-<date> --timeout=2h
```

#### 2.2 Verify First Backup

```bash
# Get backup ID from job logs
BACKUP_ID=$(kubectl logs -n spacetime job/initial-backup-<date> | grep "backup_id" | head -1 | cut -d'"' -f4)

# Verify backup in S3
aws s3 ls s3://planetary-survival-backups-primary/backups/primary/database/$BACKUP_ID/

# Verify backup in Azure
az storage blob list \
  --account-name planetarysurvivalbackups \
  --container-name planetary-survival-backups \
  --prefix "backups/secondary/database/$BACKUP_ID"

# Verify backup in GCS
gsutil ls gs://planetary-survival-backups-dr/backups/tertiary/database/$BACKUP_ID/

# Run verification
kubectl create job -n spacetime \
  --from=cronjob/spacetime-backup-verification \
  verify-initial-backup

kubectl logs -n spacetime -f job/verify-initial-backup
```

### Phase 3: Monitoring Setup (Day 2)

#### 3.1 Deploy Backup Monitoring

```bash
# Create ConfigMap for monitoring script
kubectl create configmap backup-monitoring-script -n spacetime \
  --from-file=/c/godot/scripts/operations/backup/backup_monitoring.py

# Deploy monitoring pod
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backup-monitoring
  namespace: spacetime
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backup-monitoring
  template:
    metadata:
      labels:
        app: backup-monitoring
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9091"
    spec:
      containers:
      - name: monitoring
        image: python:3.11-slim
        command: ["python3", "/scripts/backup_monitoring.py"]
        ports:
        - containerPort: 9091
          name: metrics
        volumeMounts:
        - name: scripts
          mountPath: /scripts
        - name: backup-storage
          mountPath: /var/backups
          readOnly: true
        env:
        - name: METRICS_PORT
          value: "9091"
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
      volumes:
      - name: scripts
        configMap:
          name: backup-monitoring-script
      - name: backup-storage
        persistentVolumeClaim:
          claimName: backup-storage
---
apiVersion: v1
kind: Service
metadata:
  name: backup-monitoring
  namespace: spacetime
spec:
  selector:
    app: backup-monitoring
  ports:
  - port: 9091
    targetPort: 9091
    name: metrics
EOF

# Verify monitoring is running
kubectl get pods -n spacetime -l app=backup-monitoring
kubectl logs -n spacetime -l app=backup-monitoring

# Test metrics endpoint
kubectl port-forward -n spacetime svc/backup-monitoring 9091:9091 &
curl http://localhost:9091/metrics | grep backup_
```

#### 3.2 Configure Prometheus Scraping

```bash
# Add backup monitoring to Prometheus targets
cat <<EOF >> /c/godot/monitoring/prometheus.yml

  - job_name: 'backup-monitoring'
    static_configs:
      - targets: ['backup-monitoring.spacetime.svc.cluster.local:9091']
    scrape_interval: 30s
EOF

# Reload Prometheus configuration
kubectl exec -n spacetime prometheus-0 -- kill -HUP 1

# Verify scrape target
kubectl port-forward -n spacetime svc/prometheus 9090:9090 &
open http://localhost:9090/targets
```

#### 3.3 Import Grafana Dashboard

```bash
# Import backup health dashboard
kubectl create configmap grafana-backup-dashboard -n spacetime \
  --from-file=/c/godot/monitoring/grafana/dashboards/backup_health.json

# Restart Grafana to load dashboard
kubectl rollout restart deployment spacetime-grafana -n spacetime

# Access dashboard
kubectl port-forward -n spacetime svc/grafana 3000:3000 &
open http://localhost:3000/d/backup_health
```

### Phase 4: DR Testing (Day 3)

#### 4.1 Schedule First DR Test

```bash
# Run database recovery test
kubectl run dr-test-database -n spacetime \
  --image=python:3.11 \
  --restart=Never \
  --rm -it \
  --command -- python3 /scripts/dr_test_automation.py database

# Run Redis recovery test
kubectl run dr-test-redis -n spacetime \
  --image=python:3.11 \
  --restart=Never \
  --rm -it \
  --command -- python3 /scripts/dr_test_automation.py redis

# Run backup verification test
kubectl run dr-test-verification -n spacetime \
  --image=python:3.11 \
  --restart=Never \
  --rm -it \
  --command -- python3 /scripts/dr_test_automation.py verification
```

#### 4.2 Review DR Test Results

```bash
# Check test reports
ls -lh /c/godot/docs/operations/DR_TEST_REPORTS/

# Review latest report
cat /c/godot/docs/operations/DR_TEST_REPORTS/$(ls -t /c/godot/docs/operations/DR_TEST_REPORTS/ | head -1)
```

### Phase 5: Finalization (Day 3-4)

#### 5.1 Configure Alerting

```bash
# Configure Prometheus alerts
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-alerts
  namespace: spacetime
data:
  backup-alerts.yml: |
    groups:
    - name: backup_alerts
      interval: 1m
      rules:
      - alert: BackupFailed
        expr: rate(backup_completed_total{status="failed"}[1h]) > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Backup failure detected"
          description: "Backup has failed for {{ \$labels.component }}"

      - alert: BackupTooOld
        expr: (time() - backup_last_success_timestamp_seconds) / 60 > 120
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Backup is too old"
          description: "Last backup is {{ \$value }} minutes old"

      - alert: RPOExceeded
        expr: (time() - backup_last_success_timestamp_seconds) / 60 > 5
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "RPO exceeded"
          description: "Recovery Point Objective exceeded: {{ \$value }} minutes"

      - alert: StorageReplicationFailed
        expr: sum(backup_storage_replication_status) < 2
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "Backup replication failed"
          description: "Only {{ \$value }} storage locations available"
EOF

# Reload Prometheus alerts
kubectl exec -n spacetime prometheus-0 -- kill -HUP 1
```

#### 5.2 Document Procedures

```bash
# Create incident response procedures
cat > /c/godot/docs/operations/BACKUP_INCIDENT_RESPONSE.md <<EOF
# Backup & DR Incident Response

## Backup Failure Response

1. Check backup logs: \`kubectl logs -n spacetime -l app=spacetime-backup --tail=100\`
2. Verify connectivity to database
3. Check disk space
4. Retry backup manually
5. Escalate if manual backup fails

## Restore Required Response

1. Identify backup to restore: \`aws s3 ls s3://planetary-survival-backups-primary/backups/\`
2. Notify team via incident channel
3. Follow DR runbook: /c/godot/docs/operations/DISASTER_RECOVERY.md
4. Execute restore
5. Verify integrity
6. Document incident

## Storage Outage Response

1. Verify which storage location is affected
2. Use alternative storage location
3. Contact cloud provider support
4. Monitor for resolution
5. Re-replicate backups after resolution
EOF
```

#### 5.3 Team Training

```bash
# Schedule DR drill
# Create calendar invite for team DR training session
# Topics to cover:
# - Backup system architecture
# - DR runbook walkthrough
# - Hands-on restore practice
# - Troubleshooting common issues
# - Q&A
```

### Phase 6: Production Cutover (Day 5)

#### 6.1 Pre-Production Checklist

```bash
# Verify all components
echo "✓ Backup CronJobs deployed and scheduled"
kubectl get cronjobs -n spacetime | grep backup

echo "✓ Initial backup completed and verified"
aws s3 ls s3://planetary-survival-backups-primary/backups/primary/database/ | wc -l

echo "✓ Monitoring operational"
curl -f http://backup-monitoring.spacetime.svc.cluster.local:9091/metrics

echo "✓ Grafana dashboard accessible"
kubectl port-forward -n spacetime svc/grafana 3000:3000 &

echo "✓ Alerts configured"
kubectl get configmap prometheus-alerts -n spacetime

echo "✓ DR tests passed"
ls /c/godot/docs/operations/DR_TEST_REPORTS/*.json | wc -l

echo "✓ Documentation complete"
ls /c/godot/docs/operations/DISASTER_RECOVERY.md
ls /c/godot/scripts/operations/README.md

echo "✓ Team trained"
# Confirm training completion

echo "✓ Incident response procedures documented"
ls /c/godot/docs/operations/BACKUP_INCIDENT_RESPONSE.md
```

#### 6.2 Enable Production Backups

```bash
# Enable CronJobs (if suspended)
kubectl patch cronjob spacetime-backup-full -n spacetime -p '{"spec":{"suspend":false}}'
kubectl patch cronjob spacetime-backup-incremental -n spacetime -p '{"spec":{"suspend":false}}'
kubectl patch cronjob spacetime-backup-verification -n spacetime -p '{"spec":{"suspend":false}}'

# Verify next scheduled run
kubectl get cronjobs -n spacetime -o wide

# Monitor first production backup
kubectl get jobs -n spacetime -w
```

#### 6.3 Post-Production Verification

```bash
# Wait for first scheduled backup
# Verify backup success
kubectl logs -n spacetime -l app=spacetime-backup --tail=50

# Check metrics
curl http://backup-monitoring.spacetime.svc.cluster.local:9091/metrics | grep backup_completed_total

# Verify all storage locations
aws s3 ls s3://planetary-survival-backups-primary/backups/primary/database/
az storage blob list --account-name planetarysurvivalbackups --container-name planetary-survival-backups --prefix backups/secondary/database/
gsutil ls gs://planetary-survival-backups-dr/backups/tertiary/database/

# Check Grafana dashboard
open https://grafana.planetary-survival.com/d/backup_health
```

## Post-Deployment

### Week 1: Monitoring Period

- [ ] Monitor backup success rate daily
- [ ] Review backup sizes and durations
- [ ] Verify storage costs are within budget
- [ ] Check for any errors or warnings
- [ ] Confirm team can access monitoring

### Week 2: Optimization

- [ ] Adjust backup schedules if needed
- [ ] Optimize compression settings
- [ ] Fine-tune retention policies
- [ ] Update documentation with lessons learned

### Week 3: First Scheduled DR Test

- [ ] Execute monthly DR drill
- [ ] Measure actual RTO and RPO
- [ ] Document any issues
- [ ] Update runbook with improvements

### Month 1: Review

- [ ] Review backup success rate (target: >99%)
- [ ] Verify RTO/RPO metrics
- [ ] Calculate storage costs
- [ ] Conduct team retrospective
- [ ] Plan improvements for Month 2

## Troubleshooting

### Backup Job Fails to Start

```bash
# Check CronJob status
kubectl describe cronjob spacetime-backup-full -n spacetime

# Check service account permissions
kubectl auth can-i list pods -n spacetime --as=system:serviceaccount:spacetime:backup-service-account

# Check PVC availability
kubectl get pvc -n spacetime backup-storage
```

### Backup Completes but Verification Fails

```bash
# Check verification logs
kubectl logs -n spacetime -l app=spacetime-backup,type=verification

# Manually verify backup
python3 /c/godot/scripts/operations/verify_backup.py <backup_id>

# Check backup metadata
cat /var/backups/metadata/<backup_id>.json
```

### Storage Upload Fails

```bash
# Test AWS credentials
aws s3 ls s3://planetary-survival-backups-primary/

# Test Azure credentials
az storage blob list --account-name planetarysurvivalbackups --container-name planetary-survival-backups

# Test GCP credentials
gsutil ls gs://planetary-survival-backups-dr/

# Check network connectivity
kubectl run -it --rm debug -n spacetime --image=curlimages/curl -- curl -I https://s3.amazonaws.com
```

## Support

- **Documentation:** `/c/godot/docs/operations/DISASTER_RECOVERY.md`
- **Issues:** GitHub Issues or Internal Ticket System
- **Monitoring:** https://grafana.planetary-survival.com/d/backup_health
- **On-Call:** PagerDuty rotation

## Success Criteria

- ✓ RTO < 15 minutes
- ✓ RPO < 5 minutes
- ✓ Backup success rate > 99%
- ✓ 3 storage locations operational
- ✓ DR tests passing weekly
- ✓ Team trained and confident

---

**Deployment Completed:** [Date]
**Deployed By:** [Name]
**Reviewed By:** [Name]
**Next Review:** [Date + 30 days]
