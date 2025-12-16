# Backup & DR Quick Reference Card

**Print this page and keep it accessible for emergencies**

---

## Emergency Contacts

| Role | Name | Phone | Email |
|------|------|-------|-------|
| Incident Commander | [Name] | [Phone] | [Email] |
| Database Lead | [Name] | [Phone] | [Email] |
| DevOps Lead | [Name] | [Phone] | [Email] |
| On-Call Engineer | PagerDuty | [Number] | oncall@company.com |

---

## Critical Information

**RTO Target:** <15 minutes
**RPO Target:** <5 minutes

**Primary Backup Location:** s3://planetary-survival-backups-primary
**Secondary Backup:** Azure/planetarysurvivalbackups
**Tertiary Backup (DR):** gs://planetary-survival-backups-dr

---

## Quick Commands

### Check Backup Status
```bash
# View latest backup
aws s3 ls s3://planetary-survival-backups-primary/backups/primary/ | tail -5

# Check Grafana dashboard
open https://grafana.planetary-survival.com/d/backup_health

# View metrics
curl http://backup-monitoring.spacetime.svc.cluster.local:9091/metrics | grep backup_last_success
```

### Emergency Restore
```bash
# 1. Get latest backup ID
BACKUP_ID=$(aws s3 ls s3://planetary-survival-backups-primary/backups/metadata/ | grep latest | tail -1 | awk '{print $NF}')

# 2. Execute restore
cd /c/godot/scripts/operations/restore
python3 restore_manager.py $BACKUP_ID s3

# 3. Verify
kubectl get pods -n spacetime
curl https://api.planetary-survival.com/health
```

### Manual Backup
```bash
# Trigger immediate backup
cd /c/godot/scripts/operations/backup
python3 backup_manager.py full

# Or via Kubernetes
kubectl create job -n spacetime \
  --from=cronjob/spacetime-backup-full \
  emergency-backup-$(date +%Y%m%d-%H%M%S)
```

---

## Disaster Scenarios

### Database Failure
**Estimated RTO:** 10 minutes

```bash
# 1. Stop services
kubectl scale deployment spacetime-godot -n spacetime --replicas=0

# 2. Restore database
python3 /c/godot/scripts/operations/restore/restore_manager.py <backup_id> s3

# 3. Verify and restart
kubectl scale deployment spacetime-godot -n spacetime --replicas=3
```

**Full Procedure:** See `/c/godot/docs/operations/DISASTER_RECOVERY.md` Section: Procedure 1

---

### Complete Datacenter Failure
**Estimated RTO:** 15 minutes

```bash
# 1. Switch to DR cluster
kubectl config use-context gke_planetary-survival-dr_europe-west1_dr-cluster

# 2. Deploy infrastructure
kubectl apply -f /c/godot/kubernetes/ -n spacetime

# 3. Restore from GCS
python3 /c/godot/scripts/operations/restore/restore_manager.py <backup_id> gcs

# 4. Update DNS
aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file://dns-failover.json
```

**Full Procedure:** See `/c/godot/docs/operations/DISASTER_RECOVERY.md` Section: Procedure 2

---

### Redis Failure
**Estimated RTO:** 5 minutes

```bash
# 1. Scale down services
kubectl scale deployment spacetime-godot -n spacetime --replicas=0

# 2. Delete Redis pod (will restart with backup)
kubectl delete pod spacetime-redis-0 -n spacetime

# 3. Wait for recovery (auto-loads from RDB/AOF)
kubectl wait --for=condition=Ready pod/spacetime-redis-0 -n spacetime

# 4. Restore services
kubectl scale deployment spacetime-godot -n spacetime --replicas=3
```

**Full Procedure:** See `/c/godot/docs/operations/DISASTER_RECOVERY.md` Section: Procedure 3

---

## Verification Steps

### After Any Restore
```bash
# 1. Check all pods running
kubectl get pods -n spacetime

# 2. Verify database
kubectl exec -it cockroachdb-0 -n spacetime -- cockroach sql --insecure -e "SELECT COUNT(*) FROM planetary_survival.players;"

# 3. Test API
curl -f https://api.planetary-survival.com/health
curl -f https://api.planetary-survival.com/status

# 4. Check player data
curl https://api.planetary-survival.com/saves/test_save_id

# 5. Monitor error rate
kubectl logs -n spacetime -l app=spacetime-godot --tail=50 | grep ERROR
```

---

## Common Issues

### "Backup Not Found"
- **Check:** All 3 storage locations (S3, Azure, GCS)
- **Action:** Use most recent available backup
- **Command:** `aws s3 ls s3://planetary-survival-backups-primary/backups/primary/database/ | sort -r`

### "Restore Timeout"
- **Check:** Network connectivity to storage
- **Action:** Try alternative storage location
- **Command:** `python3 restore_manager.py <backup_id> azure`

### "Database Won't Start After Restore"
- **Check:** Disk space, logs
- **Action:** Check logs, verify backup integrity
- **Command:** `kubectl logs -n spacetime cockroachdb-0 --tail=100`

### "Services Not Reconnecting"
- **Check:** Service health, DNS
- **Action:** Restart services, check network policies
- **Command:** `kubectl rollout restart deployment spacetime-godot -n spacetime`

---

## Monitoring URLs

- **Grafana Dashboard:** https://grafana.planetary-survival.com/d/backup_health
- **Prometheus:** http://prometheus.spacetime.svc.cluster.local:9090
- **Backup Metrics:** http://backup-monitoring.spacetime.svc.cluster.local:9091/metrics
- **Status Page:** https://status.planetary-survival.com

---

## Key Metrics to Watch

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| Last Backup Age | < 1 hour | 1-2 hours | > 2 hours |
| Backup Success Rate | > 99% | 95-99% | < 95% |
| RPO (Current) | < 5 min | 5-10 min | > 10 min |
| RTO (Last Test) | < 15 min | 15-20 min | > 20 min |
| Storage Locations Available | 3 | 2 | < 2 |

---

## Escalation Path

1. **On-Call Engineer** → Response: <5 minutes
2. **Team Lead** → Response: <15 minutes
3. **Director of Engineering** → Response: <30 minutes
4. **CTO** → Response: <1 hour

**PagerDuty:** [Phone Number]
**Slack:** #incident-response

---

## Backup Schedule

| Backup Type | Schedule | Retention |
|-------------|----------|-----------|
| Full Database | Daily 2 AM UTC | 7 days |
| Incremental | Every hour | 24 hours |
| Redis | Every hour | 7 days |
| Player Saves | Daily 2 AM UTC | 7 days |
| Configuration | On change + Daily | 30 days |
| Transaction Logs | Continuous | 7 days |

---

## Storage Locations

### Primary (S3 - us-east-1)
- **Bucket:** planetary-survival-backups-primary
- **Latency:** 12ms average
- **Use For:** All restores (fastest)

### Secondary (Azure - westus2)
- **Account:** planetarysurvivalbackups
- **Latency:** 25ms average
- **Use For:** S3 unavailable

### Tertiary (GCS - europe-west1)
- **Bucket:** planetary-survival-backups-dr
- **Latency:** 45ms average
- **Use For:** DR scenarios only

---

## Pre-Flight Checklist

Before executing disaster recovery:

- [ ] Identify the failure (database, datacenter, etc.)
- [ ] Alert team via #incident-response
- [ ] Confirm backup ID to restore
- [ ] Verify backup exists in at least 2 locations
- [ ] Notify stakeholders of upcoming downtime
- [ ] Document start time for RTO calculation
- [ ] Have rollback plan ready

---

## Post-Recovery Checklist

After successful recovery:

- [ ] Verify all services healthy
- [ ] Check data integrity
- [ ] Monitor error rates for 1 hour
- [ ] Document actual RTO/RPO achieved
- [ ] Create incident report
- [ ] Schedule post-mortem (within 24h)
- [ ] Update runbook with lessons learned
- [ ] Test backup immediately after restore

---

## Documentation Locations

- **Full DR Runbook:** `/c/godot/docs/operations/DISASTER_RECOVERY.md`
- **Operations Guide:** `/c/godot/scripts/operations/README.md`
- **Deployment Guide:** `/c/godot/docs/operations/BACKUP_DEPLOYMENT_GUIDE.md`
- **System Summary:** `/c/godot/docs/operations/BACKUP_SYSTEM_SUMMARY.md`
- **Test Reports:** `/c/godot/docs/operations/DR_TEST_REPORTS/`

---

## Important Notes

⚠️ **Never** skip verification steps after restore
⚠️ **Always** use encryption for backups
⚠️ **Document** every disaster recovery execution
⚠️ **Test** recovery procedures regularly
⚠️ **Update** this card if procedures change

---

**Last Updated:** 2025-12-02
**Version:** 1.0
**Review Schedule:** Monthly
