# Planetary Survival - Operations Runbook

This runbook contains standard operating procedures, incident response workflows, and maintenance tasks for Planetary Survival production infrastructure.

## Table of Contents

1. [Operational Procedures](#operational-procedures)
2. [Incident Response](#incident-response)
3. [Maintenance Tasks](#maintenance-tasks)
4. [Backup and Restore](#backup-and-restore)
5. [Disaster Recovery](#disaster-recovery)

## Operational Procedures

### Daily Operations

#### Morning Checks (9 AM)

```bash
# 1. Run health checks
./scripts/health-check.sh production

# 2. Review overnight metrics
kubectl port-forward -n planetary-survival svc/grafana 3000:3000
# Open http://localhost:3000 - Review "Daily Overview" dashboard

# 3. Check for alerts
kubectl logs -n planetary-survival -l app=alertmanager --since=24h | grep firing

# 4. Review resource usage
kubectl top nodes
kubectl top pods -n planetary-survival

# 5. Check player count trends
curl -s http://prometheus:9090/api/v1/query?query=sum\(active_players\)
```

#### Evening Checks (5 PM)

```bash
# 1. Review scaling events
kubectl get events -n planetary-survival \
  --field-selector involvedObject.kind=HorizontalPodAutoscaler \
  --sort-by='.lastTimestamp'

# 2. Check for restarts
kubectl get pods -n planetary-survival \
  -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount

# 3. Verify backup completion
kubectl logs -n planetary-survival cronjob/database-backup --tail=50

# 4. Review capacity
# If average CPU > 60% sustained, consider scaling up
```

### Weekly Operations

#### Monday: Capacity Planning

```bash
# 1. Generate weekly report
./scripts/generate-capacity-report.sh

# 2. Review trends
# - Player count growth
# - Resource utilization
# - Database size growth

# 3. Forecast next week
# - Expected player count
# - Required server capacity
# - Cost projections

# 4. Schedule scaling if needed
# Add to calendar: "Scale up on [date] before peak hours"
```

#### Wednesday: Security Audit

```bash
# 1. Check for CVEs
kubectl get vulnerabilityreports -n planetary-survival

# 2. Review security policies
kubectl auth can-i --list --namespace=planetary-survival

# 3. Rotate credentials (monthly)
# See "Credential Rotation" section

# 4. Review access logs
kubectl logs -n planetary-survival -l app=game-server | grep "auth_failure"
```

#### Friday: Maintenance Window

```bash
# 1. Check for pending updates
helm list -n planetary-survival

# 2. Review change requests
# Check tickets scheduled for deployment

# 3. Plan maintenance
# Schedule non-critical updates during low-traffic period

# 4. Prepare rollback plan
# Document current state and rollback procedure
```

### Monthly Operations

#### First Week: Disaster Recovery Test

```bash
# 1. Test backup restoration (on staging)
./scripts/test-restore.sh staging

# 2. Test failover
./scripts/test-failover.sh staging

# 3. Update DR documentation
# Document any issues found

# 4. Review and update runbook
```

#### Second Week: Performance Optimization

```bash
# 1. Analyze slow queries
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    SELECT query, count(*), avg(latency)
    FROM crdb_internal.cluster_queries
    WHERE latency > '100ms'
    GROUP BY query
    ORDER BY avg(latency) DESC
    LIMIT 10"

# 2. Review and optimize
# Add indexes, optimize queries, adjust caching

# 3. Load testing
./scripts/load-test.sh production 2000  # Simulate 2000 players

# 4. Tuning
# Adjust resource limits, connection pools, etc.
```

#### Third Week: Cost Optimization

```bash
# 1. Review cloud costs
# Check cloud provider billing dashboard

# 2. Identify waste
# - Unused PVs
# - Over-provisioned resources
# - Idle servers during off-peak

# 3. Optimize
# - Right-size resources
# - Enable cluster autoscaler
# - Schedule scale-down during off-peak

# 4. Project savings
# Document expected cost reduction
```

#### Fourth Week: Documentation Update

```bash
# 1. Review and update docs
# - DEPLOYMENT.md
# - INFRASTRUCTURE.md
# - TROUBLESHOOTING.md
# - This RUNBOOK.md

# 2. Update architecture diagrams
# Reflect any infrastructure changes

# 3. Update contact information
# On-call rotation, escalation paths

# 4. Review SLOs
# Update based on actual performance
```

## Incident Response

### Severity Levels

| Level | Description | Response Time | Escalation |
|-------|-------------|---------------|------------|
| P0 | Complete outage | Immediate | Page on-call immediately |
| P1 | Critical degradation | 15 minutes | Notify on-call |
| P2 | Moderate degradation | 1 hour | Slack notification |
| P3 | Minor issue | 4 hours | Create ticket |

### P0: Complete Outage

**Definition**: Service completely unavailable, no players can connect

**Response Procedure**:

```bash
# 1. ACKNOWLEDGE (< 1 minute)
# - Acknowledge PagerDuty alert
# - Post in #incident-response Slack channel

# 2. ASSESS (< 3 minutes)
# Check overall health
./scripts/health-check.sh production

# Check recent changes
kubectl rollout history statefulset/game-server -n planetary-survival

# Check alerts
kubectl logs -n planetary-survival -l app=alertmanager --tail=20

# 3. MITIGATE (< 5 minutes)
# If recent deployment, rollback immediately
./scripts/rollback.sh production

# If infrastructure issue, check cloud provider status
# Check load balancer, DNS, networking

# 4. RESTORE SERVICE (< 15 minutes)
# Restart services if needed
kubectl rollout restart statefulset/game-server -n planetary-survival
kubectl rollout restart deployment/mesh-coordinator -n planetary-survival

# Scale if capacity issue
./scripts/scale.sh production 20 game-server

# 5. VERIFY (< 20 minutes)
./scripts/health-check.sh production
# Manual player connection test

# 6. COMMUNICATE
# Post in #general: "Service restored at [time]. We are investigating root cause."

# 7. POST-MORTEM
# Create incident report within 24 hours
# Schedule blameless post-mortem meeting
```

### P1: Critical Degradation

**Definition**: Service severely degraded, high error rate, >20% players affected

**Response Procedure**:

```bash
# 1. ACKNOWLEDGE (< 5 minutes)
# - Acknowledge alert
# - Post in #incident-response

# 2. ASSESS (< 10 minutes)
# Check specific issues
kubectl get pods -n planetary-survival
kubectl top pods -n planetary-survival
kubectl get events -n planetary-survival --sort-by='.lastTimestamp' | head -20

# Check metrics
kubectl port-forward -n planetary-survival svc/prometheus 9090:9090
# Query: rate(http_requests_total{code=~"5.."}[5m])

# 3. IDENTIFY ROOT CAUSE (< 20 minutes)
# Database overload?
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach node status --insecure

# High CPU/Memory?
kubectl top pods -n planetary-survival --sort-by=cpu

# Network issues?
kubectl exec game-server-0 -n planetary-survival -- \
  ping -c 5 game-server-1.game-server-headless

# 4. MITIGATE (< 30 minutes)
# Scale horizontally
./scripts/scale.sh production 30 game-server

# Or optimize vertically
helm upgrade planetary-survival helm/planetary-survival \
  --set gameServer.resources.limits.cpu=6000m \
  --set gameServer.resources.limits.memory=12Gi

# 5. MONITOR (ongoing)
# Watch metrics until stabilized

# 6. DOCUMENT
# Create incident ticket with details
```

### P2: Moderate Degradation

**Definition**: Intermittent issues, <20% players affected, degraded performance

**Response Procedure**:

```bash
# 1. ACKNOWLEDGE (< 30 minutes)
# Post in #ops-alerts

# 2. INVESTIGATE (< 1 hour)
# Collect diagnostics
kubectl cluster-info dump -n planetary-survival > diagnostics.txt
kubectl logs -n planetary-survival -l component=game-server --tail=500 > game-server-logs.txt

# 3. PLAN FIX (< 2 hours)
# Determine if immediate fix needed or can wait for maintenance window

# 4. COMMUNICATE
# If user-facing, post in #player-support

# 5. RESOLVE
# Apply fix during maintenance window
```

### Communication Templates

**P0 Outage - Initial**:
```
🚨 INCIDENT: Planetary Survival is currently unavailable.
Status: Investigating
ETA: Updates every 5 minutes
Last update: [timestamp]
```

**P0 Outage - Resolution**:
```
✅ RESOLVED: Service has been restored.
Duration: [X] minutes
Affected users: [estimate]
Root cause: [brief description]
Next steps: Full post-mortem within 24 hours
```

**P1 Degradation**:
```
⚠️ SERVICE DEGRADATION: Some players may experience [symptoms].
We are actively working to resolve this.
Current status: [description]
ETA: [estimate]
```

## Maintenance Tasks

### Database Maintenance

#### Weekly Database Vacuum

```bash
# Schedule: Sunday 2 AM
# Duration: ~30 minutes

# 1. Check database size before
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    SELECT sum(range_size) FROM crdb_internal.ranges"

# 2. Run vacuum
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    VACUUM ANALYZE planetary_survival"

# 3. Check size after
# Should see reduction in disk usage

# 4. Monitor performance
# Ensure query performance not degraded
```

#### Monthly Index Optimization

```bash
# 1. Identify unused indexes
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    SELECT * FROM crdb_internal.index_usage_statistics
    WHERE total_reads = 0"

# 2. Drop unused indexes (carefully!)
# Only after reviewing with dev team

# 3. Rebuild fragmented indexes
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    REINDEX TABLE player_states"

# 4. Update statistics
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    ANALYZE"
```

### Certificate Renewal

#### Auto-Renewal (cert-manager)

```bash
# Check certificate expiry
kubectl get certificate -n planetary-survival

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Force renewal if needed
kubectl delete certificate planetary-survival-tls -n planetary-survival
# cert-manager will recreate automatically
```

#### Manual Renewal

```bash
# 1. Generate new certificate
openssl req -new -newkey rsa:2048 -nodes \
  -keyout planetary-survival.key \
  -out planetary-survival.csr

# 2. Sign with CA

# 3. Create Kubernetes secret
kubectl create secret tls planetary-survival-tls \
  --cert=planetary-survival.crt \
  --key=planetary-survival.key \
  --namespace=planetary-survival

# 4. Reload ingress
kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx
```

### Credential Rotation

#### Database Credentials

```bash
# 1. Create new user with new password
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    CREATE USER planetary_admin_v2 WITH PASSWORD 'new-secure-password'"

# 2. Grant permissions
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    GRANT ALL ON DATABASE planetary_survival TO planetary_admin_v2"

# 3. Update secret
kubectl patch secret database-credentials -n planetary-survival \
  -p '{"stringData":{"COCKROACHDB_PASSWORD":"new-secure-password","COCKROACHDB_USER":"planetary_admin_v2"}}'

# 4. Restart pods to pick up new credentials
kubectl rollout restart statefulset/game-server -n planetary-survival

# 5. Verify connections working

# 6. Drop old user
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    DROP USER planetary_admin"
```

#### API Keys

```bash
# 1. Generate new key
NEW_API_KEY=$(openssl rand -base64 32)

# 2. Update secret
kubectl patch secret api-keys -n planetary-survival \
  -p "{\"stringData\":{\"API_TOKEN\":\"$NEW_API_KEY\"}}"

# 3. Restart services
kubectl rollout restart statefulset/game-server -n planetary-survival

# 4. Update external consumers
# Coordinate with dev team to update client configurations

# 5. Revoke old key after grace period (7 days)
```

### Log Rotation

```bash
# Automated log rotation via logrotate
# /etc/logrotate.d/planetary-survival

/var/log/planetary-survival/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        kubectl exec -n planetary-survival game-server-0 -- \
            kill -USR1 $(cat /var/run/game-server.pid)
    endscript
}
```

## Backup and Restore

### Automated Backups

#### Daily Incremental Backup

```yaml
# Configured as CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: database-backup
  namespace: planetary-survival
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: cockroachdb/cockroach:v23.1.11
            command:
              - /bin/sh
              - -c
              - |
                /cockroach/cockroach dump planetary_survival \
                  --insecure \
                  --host=cockroachdb-public \
                  | gzip > /backup/planetary-$(date +%Y%m%d-%H%M%S).sql.gz

                # Upload to S3
                aws s3 cp /backup/planetary-*.sql.gz \
                  s3://planetary-survival-backups/daily/

                # Cleanup old local backups
                find /backup -name "planetary-*.sql.gz" -mtime +7 -delete
          restartPolicy: OnFailure
```

#### Weekly Full Backup

```bash
# Larger backup including all data
# Schedule: Sunday 1 AM

# 1. Backup database
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach dump planetary_survival \
  --insecure --host=localhost > backup-weekly-$(date +%Y%m%d).sql

# 2. Backup persistent volumes
for pvc in $(kubectl get pvc -n planetary-survival -o name); do
  kubectl create job backup-$pvc --image=alpine -- \
    tar czf /backup/$(basename $pvc)-$(date +%Y%m%d).tar.gz /data
done

# 3. Upload to off-site storage
aws s3 cp backup-weekly-*.sql s3://planetary-survival-backups/weekly/
aws s3 cp *.tar.gz s3://planetary-survival-backups/weekly/

# 4. Verify backup
aws s3 ls s3://planetary-survival-backups/weekly/ | tail -5

# 5. Cleanup old backups (retain 12 weeks)
aws s3 ls s3://planetary-survival-backups/weekly/ | \
  head -n -12 | awk '{print $4}' | \
  xargs -I {} aws s3 rm s3://planetary-survival-backups/weekly/{}
```

### Manual Backup

```bash
# On-demand backup before major changes

# 1. Create backup
./scripts/create-backup.sh production

# 2. Verify backup
./scripts/verify-backup.sh backup-$(date +%Y%m%d).sql.gz

# 3. Store backup location
echo "Backup: s3://planetary-survival-backups/manual/backup-$(date +%Y%m%d).sql.gz" \
  >> /tmp/backup-log.txt
```

### Restore from Backup

#### Full Database Restore

```bash
# 1. STOP ALL SERVICES (prevents data corruption)
kubectl scale statefulset/game-server -n planetary-survival --replicas=0
kubectl scale deployment/mesh-coordinator -n planetary-survival --replicas=0

# 2. Download backup
aws s3 cp s3://planetary-survival-backups/daily/backup-20231015.sql.gz ./

# 3. Extract backup
gunzip backup-20231015.sql.gz

# 4. Drop existing database (DANGEROUS!)
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    DROP DATABASE IF EXISTS planetary_survival CASCADE"

# 5. Restore database
kubectl exec -i cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure < backup-20231015.sql

# 6. Verify data
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    SELECT count(*) FROM planetary_survival.players"

# 7. Restart services
kubectl scale statefulset/game-server -n planetary-survival --replicas=10
kubectl scale deployment/mesh-coordinator -n planetary-survival --replicas=3

# 8. Verify everything working
./scripts/health-check.sh production
```

#### Partial Restore (Single Table)

```bash
# 1. Extract specific table from backup
zcat backup-20231015.sql.gz | grep "CREATE TABLE player_inventory" -A 1000 > player_inventory.sql

# 2. Restore table
kubectl exec -i cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --database=planetary_survival < player_inventory.sql

# 3. Verify
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    SELECT count(*) FROM planetary_survival.player_inventory"
```

## Disaster Recovery

### DR Scenarios

#### Scenario 1: Primary Region Failure

**Impact**: Complete service outage in primary region

**Recovery Procedure**:

```bash
# 1. Verify region failure
# Check cloud provider status page

# 2. Failover to secondary region
kubectl config use-context dr-cluster

# 3. Restore from latest backup
./scripts/restore-from-backup.sh latest

# 4. Update DNS to point to DR region
# Change A/CNAME records to DR load balancer

# 5. Scale up DR environment
./scripts/scale.sh production 20 game-server

# 6. Verify service
./scripts/health-check.sh production

# 7. Monitor and stabilize

# RTO Target: 15 minutes
# RPO Target: 1 hour
```

#### Scenario 2: Database Corruption

**Impact**: Data loss, service degradation

**Recovery Procedure**:

```bash
# 1. Identify corruption
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach debug check-store --insecure

# 2. Stop writes
kubectl scale statefulset/game-server -n planetary-survival --replicas=0

# 3. Restore from last known good backup
./scripts/restore-from-backup.sh backup-20231015

# 4. Verify data integrity
./scripts/verify-data-integrity.sh

# 5. Resume service
kubectl scale statefulset/game-server -n planetary-survival --replicas=10

# 6. Monitor for issues

# RPO: Up to 24 hours (depending on backup frequency)
```

#### Scenario 3: Kubernetes Cluster Failure

**Impact**: Complete cluster unavailable

**Recovery Procedure**:

```bash
# 1. Spin up new cluster
# Use infrastructure as code (Terraform/Pulumi)

# 2. Deploy application
./scripts/deploy.sh production

# 3. Restore data
./scripts/restore-from-backup.sh latest

# 4. Update DNS
# Point to new cluster load balancer

# 5. Verify and scale
./scripts/health-check.sh production
./scripts/scale.sh production 20 game-server

# RTO Target: 30 minutes
```

### DR Testing Schedule

**Monthly**: Test backup restoration on staging

**Quarterly**: Full DR drill with failover to secondary region

**Annually**: Disaster recovery tabletop exercise

## On-Call Procedures

### On-Call Rotation

- **Rotation**: Weekly (Monday to Monday)
- **Schedule**: Maintained in PagerDuty
- **Primary**: Receives all P0/P1 alerts
- **Secondary**: Escalation after 15 minutes

### On-Call Handoff

```bash
# Outgoing on-call checklist:
# 1. Brief incoming on-call on current state
# 2. Review open incidents and tickets
# 3. Highlight any ongoing issues
# 4. Share any planned maintenance
# 5. Transfer PagerDuty primary on-call
```

### Escalation Path

```
Level 1: On-Call Engineer (0-15 min)
Level 2: Senior On-Call Engineer (15-30 min)
Level 3: Engineering Manager (30-60 min)
Level 4: Director of Engineering (1+ hour)
```

## Contact Information

**Team**:
- Ops Team: #ops-team
- Dev Team: #dev-team
- Management: #management

**External**:
- Cloud Provider Support: [support portal]
- Database Support: [support email]
- Security Team: security@example.com

**Emergency**:
- PagerDuty: https://your-org.pagerduty.com
- Status Page: https://status.planetary-survival.example.com
