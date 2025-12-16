# SpaceTime VR - Operational Runbooks

**Version:** 2.5.0
**Last Updated:** 2025-12-02
**Audience:** DevOps, SRE, Operations Teams

This document contains comprehensive operational runbooks for production deployment, scaling, monitoring, and incident response.

## Table of Contents

1. [Deployment Procedures](#deployment-procedures)
2. [Scaling Procedures](#scaling-procedures)
3. [Rollback Procedures](#rollback-procedures)
4. [Database Operations](#database-operations)
5. [Monitoring and Alerting](#monitoring-and-alerting)
6. [Incident Response](#incident-response)
7. [Maintenance Windows](#maintenance-windows)
8. [Disaster Recovery](#disaster-recovery)

---

## Deployment Procedures

### Pre-Deployment Checklist

```
PRE-DEPLOYMENT CHECKLIST:
[ ] Code changes reviewed and approved
[ ] All tests passing in CI/CD
[ ] Staging deployment successful
[ ] Database migrations tested
[ ] Rollback plan prepared
[ ] Stakeholders notified
[ ] Maintenance window scheduled (if needed)
[ ] Backup completed
[ ] Monitoring alerts configured
[ ] Documentation updated
```

### Standard Deployment

**Use Case:** Deploy new version to production with zero downtime

**Prerequisites:**
- CI/CD pipeline passing
- Docker images built and tagged
- Database migrations prepared (if any)

**Duration:** 15-20 minutes

**Steps:**

1. **Pre-Deployment Backup**
   ```bash
   # SSH to production server
   ssh production-server

   # Navigate to deployment directory
   cd /opt/spacetime/production

   # Create backup
   bash deploy/backup.sh --full

   # Verify backup
   ls -lh backups/
   # Should show new backup with timestamp
   ```

2. **Pull Latest Images**
   ```bash
   # Set environment variables
   export IMAGE_TAG=v2.5.0
   export ENVIRONMENT=production

   # Pull images
   docker-compose pull

   # Verify images pulled
   docker images | grep spacetime
   ```

3. **Database Migration (if needed)**
   ```bash
   # Run migrations in dry-run mode first
   docker-compose run --rm godot-api python manage.py migrate --plan

   # If safe, run migrations
   docker-compose run --rm godot-api python manage.py migrate

   # Verify migrations
   docker-compose run --rm godot-api python manage.py showmigrations
   ```

4. **Blue-Green Deployment**
   ```bash
   # Start green environment
   docker-compose -f docker-compose.production.yml \
     -p spacetime-green up -d

   # Wait for health checks
   for i in {1..30}; do
     curl -f http://localhost:8083/health && break
     sleep 10
   done

   # Run smoke tests
   bash deploy/smoke_tests.sh http://localhost:8083

   # If all pass, switch traffic
   docker exec spacetime-nginx nginx -s reload

   # Monitor for 5 minutes
   bash deploy/monitor.sh --duration 300

   # If stable, stop blue environment
   docker-compose -f docker-compose.production.yml \
     -p spacetime-blue down
   ```

5. **Post-Deployment Verification**
   ```bash
   # Check all services healthy
   docker-compose ps

   # Verify API endpoints
   curl https://spacetime.example.com/status | jq

   # Check error logs
   docker-compose logs --tail=100 | grep -i error

   # Verify metrics
   curl https://spacetime.example.com/metrics

   # Test key features
   python tests/test_runner.py --critical-only
   ```

6. **Cleanup**
   ```bash
   # Remove old images
   docker image prune -f --filter "until=72h"

   # Clean up old logs
   find logs/ -name "*.log" -mtime +7 -delete

   # Update deployment record
   echo "v2.5.0 deployed at $(date)" >> deployments.log
   ```

### Hotfix Deployment

**Use Case:** Deploy critical fix with minimal testing

**Prerequisites:**
- Critical bug identified
- Fix developed and minimally tested
- Rollback plan ready

**Duration:** 5-10 minutes

**Steps:**

1. **Emergency Backup**
   ```bash
   ssh production-server
   cd /opt/spacetime/production
   bash deploy/backup.sh --quick
   ```

2. **Deploy Hotfix**
   ```bash
   # Pull hotfix image
   export IMAGE_TAG=v2.5.1-hotfix
   docker-compose pull

   # Restart services with new image
   docker-compose up -d --no-deps godot-server

   # Wait for health check
   sleep 30
   docker-compose ps
   ```

3. **Verify Fix**
   ```bash
   # Test specific fix
   python tests/test_hotfix.py

   # Monitor for 15 minutes
   bash deploy/monitor.sh --duration 900
   ```

4. **Document**
   ```bash
   # Create incident report
   gh issue create \
     --title "Hotfix Deployed: v2.5.1-hotfix" \
     --label hotfix \
     --body "Critical fix for [issue]. Deployed at $(date)."
   ```

### CI/CD Automated Deployment

**Use Case:** Automatic deployment via GitHub Actions

**Trigger:** Push to `main` branch or manual workflow dispatch

**Configuration:** `.github/workflows/deploy-production.yml`

**Steps:**

1. **Monitor Workflow**
   ```bash
   # Watch workflow progress
   gh run watch

   # View logs
   gh run view --log
   ```

2. **Manual Approval (if configured)**
   ```bash
   # Approve deployment
   gh run approve [run_id]
   ```

3. **Post-Deployment Check**
   ```bash
   # Wait for workflow completion
   gh run watch

   # Verify deployment
   curl https://spacetime.example.com/status | jq
   ```

---

## Scaling Procedures

### Horizontal Scaling

#### Scale Up (Add Servers)

**Use Case:** Increase capacity to handle more players

**Steps:**

1. **Provision New Server**
   ```bash
   # Using infrastructure as code (Terraform)
   cd infrastructure/terraform

   # Plan scaling
   terraform plan -var="server_count=5"

   # Apply changes
   terraform apply -var="server_count=5"

   # Note new server IPs
   terraform output server_ips
   ```

2. **Configure New Server**
   ```bash
   # SSH to new server
   ssh new-server-ip

   # Run provisioning script
   bash /opt/spacetime/scripts/provision_server.sh

   # Join server mesh
   bash /opt/spacetime/scripts/join_mesh.sh \
     --coordinator coordinator.spacetime.internal:9090
   ```

3. **Add to Load Balancer**
   ```bash
   # Update nginx upstream
   ssh load-balancer

   # Edit config
   sudo vi /etc/nginx/conf.d/spacetime.conf

   # Add server to upstream block:
   # upstream spacetime_backend {
   #   server 10.0.1.4:8081;
   #   server 10.0.1.5:8081;  # NEW SERVER
   # }

   # Test config
   sudo nginx -t

   # Reload
   sudo nginx -s reload
   ```

4. **Verify New Server**
   ```bash
   # Check health
   curl http://new-server-ip:8080/health

   # Monitor metrics
   curl http://new-server-ip:8080/metrics

   # Watch logs
   ssh new-server-ip
   docker-compose logs -f
   ```

#### Scale Down (Remove Servers)

**Use Case:** Reduce capacity during low traffic periods

**Steps:**

1. **Drain Server**
   ```bash
   # SSH to server to remove
   ssh server-to-remove

   # Gracefully drain players
   curl -X POST http://localhost:8080/admin/drain \
     -H "Authorization: Bearer $ADMIN_TOKEN" \
     -d '{"target_server": "10.0.1.5:8080"}'

   # Wait for player count to reach zero
   watch 'curl -s http://localhost:8080/status | jq .player_count'
   ```

2. **Remove from Load Balancer**
   ```bash
   # SSH to load balancer
   ssh load-balancer

   # Edit config to comment out server
   sudo vi /etc/nginx/conf.d/spacetime.conf

   # Test and reload
   sudo nginx -t && sudo nginx -s reload
   ```

3. **Stop Server**
   ```bash
   # SSH to server
   ssh server-to-remove

   # Stop services
   docker-compose down

   # Backup data
   bash /opt/spacetime/scripts/backup_server.sh
   ```

4. **Deprovision**
   ```bash
   # Update infrastructure
   cd infrastructure/terraform
   terraform plan -var="server_count=4"
   terraform apply -var="server_count=4"
   ```

### Vertical Scaling

#### Increase Server Resources

**Use Case:** Increase CPU/RAM for existing servers

**Downtime:** 5-10 minutes per server (use rolling restart)

**Steps:**

1. **Update Instance Type**
   ```bash
   # Using cloud provider CLI (AWS example)
   aws ec2 modify-instance-attribute \
     --instance-id i-1234567890abcdef0 \
     --instance-type t3.xlarge

   # Stop instance
   aws ec2 stop-instances --instance-ids i-1234567890abcdef0

   # Wait for stopped state
   aws ec2 wait instance-stopped --instance-ids i-1234567890abcdef0

   # Start instance
   aws ec2 start-instances --instance-ids i-1234567890abcdef0

   # Wait for running state
   aws ec2 wait instance-running --instance-ids i-1234567890abcdef0
   ```

2. **Verify Resources**
   ```bash
   # SSH to server
   ssh server-ip

   # Check CPU/RAM
   nproc
   free -h

   # Restart services
   cd /opt/spacetime/production
   docker-compose restart
   ```

3. **Update Monitoring**
   ```bash
   # Update resource thresholds in Prometheus
   vi /etc/prometheus/alerts.yml

   # Reload Prometheus
   curl -X POST http://prometheus:9090/-/reload
   ```

### Database Scaling

#### Add Read Replicas

**Use Case:** Improve read performance

**Steps:**

1. **Create Replica**
   ```bash
   # Using PostgreSQL replication
   ssh db-primary

   # Create replication slot
   psql -U postgres -d spacetime -c \
     "SELECT pg_create_physical_replication_slot('replica_1');"

   # On replica server
   ssh db-replica-1

   # Configure replication
   cat >> /var/lib/postgresql/data/postgresql.conf <<EOF
   primary_conninfo = 'host=db-primary port=5432 user=replicator'
   primary_slot_name = 'replica_1'
   EOF

   # Start replica
   sudo systemctl start postgresql
   ```

2. **Update Application Config**
   ```bash
   # Update database connection pool
   vi /opt/spacetime/production/.env

   # Add read replica
   # DATABASE_READ_URL=postgresql://spacetime:password@db-replica-1:5432/spacetime

   # Restart services
   docker-compose restart
   ```

3. **Verify Replication**
   ```bash
   # On primary
   psql -U postgres -d spacetime -c \
     "SELECT * FROM pg_stat_replication;"

   # On replica
   psql -U postgres -d spacetime -c \
     "SELECT pg_is_in_recovery();"
   # Should return 't' (true)
   ```

#### Scale Database Vertically

**Use Case:** Increase database server resources

**Downtime:** 10-15 minutes

**Steps:**

1. **Backup Database**
   ```bash
   ssh db-primary
   sudo -u postgres pg_dump spacetime > /backup/spacetime_pre_scale.sql
   ```

2. **Resize Instance**
   ```bash
   # Stop application servers
   for server in server1 server2 server3; do
     ssh $server "cd /opt/spacetime/production && docker-compose stop"
   done

   # Stop database
   ssh db-primary
   sudo systemctl stop postgresql

   # Resize instance (cloud provider specific)
   # AWS example:
   aws rds modify-db-instance \
     --db-instance-identifier spacetime-db \
     --db-instance-class db.m5.2xlarge \
     --apply-immediately

   # Wait for available state
   aws rds wait db-instance-available \
     --db-instance-identifier spacetime-db
   ```

3. **Restart Services**
   ```bash
   # Verify database
   ssh db-primary
   sudo systemctl status postgresql

   # Restart application servers
   for server in server1 server2 server3; do
     ssh $server "cd /opt/spacetime/production && docker-compose start"
   done
   ```

---

## Rollback Procedures

See [ROLLBACK_PROCEDURES.md](../ROLLBACK_PROCEDURES.md) for complete rollback documentation.

### Quick Rollback

**Use Case:** Immediately revert to previous version

**Duration:** 2-3 minutes

```bash
# SSH to production
ssh production-server
cd /opt/spacetime/production

# Execute quick rollback
bash deploy/rollback.sh --quick

# Verify
docker-compose ps
bash deploy/smoke_tests.sh
```

### Database Rollback

**Use Case:** Revert database migrations

**Duration:** 5-10 minutes

```bash
# Identify migration to rollback to
docker-compose run --rm godot-api python manage.py showmigrations

# Rollback to specific migration
docker-compose run --rm godot-api python manage.py migrate app_name 0042_previous_migration

# Verify
docker-compose run --rm godot-api python manage.py showmigrations
```

---

## Database Operations

### Daily Backup

**Schedule:** Every day at 2:00 AM UTC

**Automation:** Cron job + backup script

**Steps:**

1. **Manual Backup**
   ```bash
   ssh db-primary

   # Create backup
   sudo -u postgres pg_dump spacetime | gzip > \
     /backup/spacetime_$(date +%Y%m%d_%H%M%S).sql.gz

   # Verify backup
   ls -lh /backup/
   gunzip -t /backup/spacetime_*.sql.gz
   ```

2. **Automated Backup (Cron)**
   ```bash
   # Edit crontab
   sudo crontab -e -u postgres

   # Add line:
   # 0 2 * * * /opt/spacetime/scripts/backup_database.sh
   ```

3. **Backup Script** (`/opt/spacetime/scripts/backup_database.sh`):
   ```bash
   #!/bin/bash
   BACKUP_DIR="/backup/database"
   TIMESTAMP=$(date +%Y%m%d_%H%M%S)
   FILENAME="spacetime_${TIMESTAMP}.sql.gz"

   # Create backup
   pg_dump spacetime | gzip > "${BACKUP_DIR}/${FILENAME}"

   # Upload to S3
   aws s3 cp "${BACKUP_DIR}/${FILENAME}" \
     s3://spacetime-backups/database/

   # Delete local backups older than 7 days
   find "${BACKUP_DIR}" -name "spacetime_*.sql.gz" -mtime +7 -delete

   # Delete S3 backups older than 30 days
   aws s3 ls s3://spacetime-backups/database/ | \
     awk '{print $4}' | \
     while read file; do
       # Check file age and delete if older than 30 days
     done
   ```

### Restore from Backup

**Use Case:** Restore database after corruption or data loss

**Downtime:** 15-30 minutes

**Steps:**

1. **Stop Application**
   ```bash
   # Stop all application servers
   for server in server1 server2 server3; do
     ssh $server "cd /opt/spacetime/production && docker-compose down"
   done
   ```

2. **Download Backup**
   ```bash
   ssh db-primary

   # List available backups
   aws s3 ls s3://spacetime-backups/database/

   # Download specific backup
   aws s3 cp s3://spacetime-backups/database/spacetime_20251202_020000.sql.gz \
     /restore/

   # Extract
   gunzip /restore/spacetime_20251202_020000.sql.gz
   ```

3. **Restore Database**
   ```bash
   # Drop existing database (CAUTION!)
   sudo -u postgres psql -c "DROP DATABASE spacetime;"

   # Create fresh database
   sudo -u postgres psql -c "CREATE DATABASE spacetime OWNER spacetime;"

   # Restore from backup
   sudo -u postgres psql spacetime < /restore/spacetime_20251202_020000.sql

   # Verify
   sudo -u postgres psql spacetime -c "SELECT COUNT(*) FROM users;"
   ```

4. **Restart Application**
   ```bash
   # Restart application servers
   for server in server1 server2 server3; do
     ssh $server "cd /opt/spacetime/production && docker-compose up -d"
   done

   # Verify
   curl https://spacetime.example.com/status
   ```

### Database Maintenance

#### Vacuum and Analyze

**Schedule:** Weekly on Sundays at 3:00 AM UTC

**Duration:** 30-60 minutes

```bash
ssh db-primary

# Full vacuum (during maintenance window)
sudo -u postgres vacuumdb --all --full --analyze --verbose

# Or regular vacuum (no downtime)
sudo -u postgres vacuumdb --all --analyze --verbose
```

#### Reindex

**Use Case:** Improve query performance

**Duration:** 20-40 minutes

```bash
ssh db-primary

# Reindex database
sudo -u postgres reindexdb spacetime --verbose

# Or specific table
sudo -u postgres psql spacetime -c "REINDEX TABLE users;"
```

#### Update Statistics

**Frequency:** Daily

```bash
ssh db-primary

# Update statistics
sudo -u postgres psql spacetime -c "ANALYZE VERBOSE;"
```

---

## Monitoring and Alerting

### Health Check Monitoring

**Tool:** Prometheus + Grafana

**Endpoints:**
- `https://spacetime.example.com/health` - Application health
- `https://spacetime.example.com/metrics` - Prometheus metrics

**Critical Metrics:**

1. **Service Availability**
   ```promql
   up{job="godot"} == 0
   ```
   **Alert:** Service down for 1 minute

2. **Error Rate**
   ```promql
   rate(http_requests_total{status=~"5.."}[5m]) > 0.05
   ```
   **Alert:** Error rate > 5% for 5 minutes

3. **Response Time**
   ```promql
   histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
   ```
   **Alert:** 95th percentile > 2 seconds for 5 minutes

4. **Memory Usage**
   ```promql
   (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.90
   ```
   **Alert:** Memory usage > 90%

5. **Disk Usage**
   ```promql
   (node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes > 0.85
   ```
   **Alert:** Disk usage > 85%

### Alert Configuration

**File:** `/etc/prometheus/alerts.yml`

```yaml
groups:
  - name: spacetime_alerts
    interval: 30s
    rules:
      - alert: ServiceDown
        expr: up{job="godot"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "SpaceTime service is down"
          description: "Service {{ $labels.instance }} has been down for more than 1 minute"

      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }} over the last 5 minutes"

      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High response time detected"
          description: "95th percentile response time is {{ $value }}s"

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.90
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"

      - alert: HighDiskUsage
        expr: (node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes > 0.85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High disk usage"
          description: "Disk usage is {{ $value | humanizePercentage }} on {{ $labels.instance }}"
```

### Notification Channels

**Slack:**
```yaml
# alertmanager.yml
receivers:
  - name: 'slack-alerts'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#alerts'
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

**Email:**
```yaml
receivers:
  - name: 'email-alerts'
    email_configs:
      - to: 'ops-team@spacetime.example.com'
        from: 'alerts@spacetime.example.com'
        smarthost: 'smtp.example.com:587'
        auth_username: 'alerts@spacetime.example.com'
        auth_password: 'password'
```

**PagerDuty:**
```yaml
receivers:
  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_KEY'
        description: '{{ .GroupLabels.alertname }}'
```

### Dashboard Access

**Grafana:** `https://spacetime.example.com/grafana`

**Default Dashboards:**
- System Overview
- API Performance
- Player Metrics
- Infrastructure Health
- Database Performance

---

## Incident Response

### Incident Severity Levels

| Level | Response Time | Description | Examples |
|-------|---------------|-------------|----------|
| P0 - Critical | < 15 minutes | Complete service outage | All servers down |
| P1 - High | < 1 hour | Major functionality broken | Login failing |
| P2 - Medium | < 4 hours | Degraded performance | Slow response times |
| P3 - Low | < 24 hours | Minor issues | Cosmetic bugs |

### Incident Response Process

#### 1. Detection

**Alerts triggered via:**
- Prometheus alerts
- User reports
- Automated monitoring

#### 2. Assessment

```bash
# Quick assessment checklist
1. What is the impact?
   - Number of affected users
   - Critical functionality impacted

2. What is the scope?
   - Single server or all servers
   - Specific feature or entire service

3. What changed recently?
   - Recent deployments
   - Configuration changes
   - Infrastructure changes
```

#### 3. Response

**P0/P1 Response:**

1. **Acknowledge Alert**
   ```bash
   # Via PagerDuty, Slack, or monitoring tool
   ```

2. **Create Incident Channel**
   ```bash
   # Slack
   /incident create "Production down - investigating"
   ```

3. **Notify Stakeholders**
   ```bash
   # Update status page
   curl -X POST https://status.spacetime.example.com/api/incidents \
     -H "Authorization: Bearer $STATUS_TOKEN" \
     -d '{
       "name": "Service Degradation",
       "status": "investigating",
       "message": "We are investigating connectivity issues."
     }'
   ```

4. **Investigate**
   ```bash
   # Check service status
   for server in server1 server2 server3; do
     echo "=== $server ==="
     ssh $server "docker-compose ps"
   done

   # Check logs
   for server in server1 server2 server3; do
     echo "=== $server logs ==="
     ssh $server "docker-compose logs --tail=50 | grep -i error"
   done

   # Check metrics
   curl https://spacetime.example.com/metrics

   # Check database
   ssh db-primary "sudo -u postgres psql -c 'SELECT 1;'"
   ```

5. **Mitigate**
   ```bash
   # If deployment caused issue - rollback
   bash deploy/rollback.sh --quick

   # If server issue - restart
   docker-compose restart

   # If database issue - check connections
   sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"
   ```

6. **Verify Resolution**
   ```bash
   # Run smoke tests
   bash deploy/smoke_tests.sh

   # Check metrics normalized
   curl https://spacetime.example.com/metrics

   # Verify user reports
   ```

7. **Close Incident**
   ```bash
   # Update status page
   curl -X PATCH https://status.spacetime.example.com/api/incidents/$INCIDENT_ID \
     -H "Authorization: Bearer $STATUS_TOKEN" \
     -d '{
       "status": "resolved",
       "message": "Issue has been resolved. All systems operational."
     }'
   ```

#### 4. Post-Mortem

**Within 48 hours of resolution:**

1. **Schedule Post-Mortem Meeting**
   - Invite all involved parties
   - Review timeline
   - Identify root cause

2. **Document Incident**
   ```bash
   # Create post-mortem document
   gh issue create \
     --title "Post-Mortem: [Incident Name]" \
     --label postmortem \
     --body "$(cat postmortem_template.md)"
   ```

3. **Action Items**
   - Preventive measures
   - Monitoring improvements
   - Process updates
   - Documentation updates

### Common Incident Playbooks

#### Playbook: Service Down

**Symptoms:** Health checks failing, 503 errors

**Steps:**
```bash
# 1. Check if containers running
ssh production-server
docker-compose ps

# 2. If containers down, check logs
docker-compose logs --tail=200

# 3. Try restart
docker-compose restart

# 4. If still down, check resources
df -h  # Disk space
free -h  # Memory
docker stats --no-stream  # Container resources

# 5. If resource issue, scale down or add resources
# 6. If code issue, rollback deployment
```

#### Playbook: Database Connection Issues

**Symptoms:** Database connection errors, timeouts

**Steps:**
```bash
# 1. Check database status
ssh db-primary
sudo systemctl status postgresql

# 2. Check connections
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"

# 3. Check connection limits
sudo -u postgres psql -c "SHOW max_connections;"

# 4. Kill idle connections if needed
sudo -u postgres psql -c "
  SELECT pg_terminate_backend(pid)
  FROM pg_stat_activity
  WHERE state = 'idle'
  AND state_change < now() - interval '30 minutes';"

# 5. Restart application connection pools
docker-compose restart godot-api
```

#### Playbook: High Error Rate

**Symptoms:** 500 errors, exceptions in logs

**Steps:**
```bash
# 1. Check error logs
docker-compose logs --tail=500 | grep -i "error\|exception\|traceback"

# 2. Identify common error pattern
docker-compose logs --tail=1000 | grep "Error:" | sort | uniq -c | sort -rn

# 3. Check recent changes
git log --oneline --since="2 hours ago"

# 4. If from recent deployment, rollback
bash deploy/rollback.sh --quick

# 5. If from external dependency, check third-party status
# 6. If from load, scale up resources
```

#### Playbook: Memory Leak

**Symptoms:** Increasing memory usage, OOM kills

**Steps:**
```bash
# 1. Monitor memory over time
watch -n 5 'docker stats --no-stream'

# 2. Identify leaking container
docker stats --format "table {{.Name}}\t{{.MemUsage}}" --no-stream | sort -k2 -h

# 3. Restart leaking container
docker-compose restart [container_name]

# 4. Monitor for recurrence
# 5. If recurring, enable memory profiling
# 6. Analyze heap dump
# 7. Fix code and deploy patch
```

---

## Maintenance Windows

### Scheduled Maintenance

**Standard Window:** Sundays 2:00 AM - 5:00 AM UTC (low traffic period)

**Notification:** 7 days advance notice

**Process:**

1. **Pre-Maintenance (7 days before)**
   ```bash
   # Schedule maintenance window
   gh issue create \
     --title "Scheduled Maintenance: [Date]" \
     --label maintenance \
     --body "Planned maintenance window on [date] from 2:00-5:00 UTC."

   # Update status page
   curl -X POST https://status.spacetime.example.com/api/maintenances \
     -H "Authorization: Bearer $STATUS_TOKEN" \
     -d '{
       "name": "Scheduled Maintenance",
       "scheduled_for": "2025-12-09T02:00:00Z",
       "scheduled_until": "2025-12-09T05:00:00Z",
       "message": "We will be performing database maintenance."
     }'
   ```

2. **During Maintenance**
   ```bash
   # Start maintenance mode
   docker-compose stop

   # Perform maintenance tasks
   # - Database migrations
   # - Server upgrades
   # - Configuration changes

   # Test changes
   docker-compose up -d
   bash deploy/smoke_tests.sh

   # If issues, rollback
   bash deploy/rollback.sh
   ```

3. **Post-Maintenance**
   ```bash
   # Verify all systems operational
   curl https://spacetime.example.com/status

   # Update status page
   curl -X PATCH https://status.spacetime.example.com/api/maintenances/$MAINTENANCE_ID \
     -H "Authorization: Bearer $STATUS_TOKEN" \
     -d '{"status": "completed"}'

   # Document work completed
   gh issue comment [maintenance_issue] \
     --body "Maintenance completed successfully. All systems operational."
   ```

### Emergency Maintenance

**Use Case:** Critical security patch or infrastructure issue

**Process:**

1. **Assess Urgency**
   - Can it wait for scheduled window?
   - Is there a workaround?
   - What is the risk of delay?

2. **Notify Immediately**
   ```bash
   # Update status page
   curl -X POST https://status.spacetime.example.com/api/maintenances \
     -H "Authorization: Bearer $STATUS_TOKEN" \
     -d '{
       "name": "Emergency Maintenance",
       "scheduled_for": "now",
       "scheduled_until": "30 minutes from now",
       "message": "Emergency maintenance to address critical security issue."
     }'
   ```

3. **Execute Quickly**
   ```bash
   # Use hotfix deployment process
   # Minimize downtime
   # Have rollback ready
   ```

---

## Disaster Recovery

### Recovery Time Objective (RTO)

**Target:** < 4 hours to restore service

### Recovery Point Objective (RPO)

**Target:** < 1 hour of data loss

### Disaster Scenarios

#### Scenario 1: Complete Data Center Failure

**Recovery Steps:**

1. **Failover to Secondary Region**
   ```bash
   # Update DNS to point to DR site
   aws route53 change-resource-record-sets \
     --hosted-zone-id Z123456ABCDEFG \
     --change-batch file://failover-dns-change.json

   # Verify DNS propagation
   dig spacetime.example.com
   ```

2. **Restore Latest Backup**
   ```bash
   # SSH to DR database server
   ssh dr-db-primary

   # Download latest backup from S3
   aws s3 cp s3://spacetime-backups/database/latest.sql.gz /restore/

   # Restore database
   gunzip /restore/latest.sql.gz
   sudo -u postgres psql spacetime < /restore/latest.sql
   ```

3. **Start Application Servers**
   ```bash
   # Start all DR servers
   for server in dr-server1 dr-server2 dr-server3; do
     ssh $server "cd /opt/spacetime/production && docker-compose up -d"
   done
   ```

4. **Verify Service**
   ```bash
   # Run smoke tests
   bash deploy/smoke_tests.sh https://dr.spacetime.example.com

   # Monitor metrics
   watch curl https://dr.spacetime.example.com/metrics
   ```

#### Scenario 2: Database Corruption

**Recovery Steps:**

1. **Stop Application**
   ```bash
   for server in server1 server2 server3; do
     ssh $server "cd /opt/spacetime/production && docker-compose stop"
   done
   ```

2. **Assess Corruption**
   ```bash
   ssh db-primary

   # Run integrity check
   sudo -u postgres pg_checksums --check --pgdata=/var/lib/postgresql/data

   # Check for corrupted tables
   sudo -u postgres psql spacetime -c "
     SELECT tablename
     FROM pg_tables
     WHERE schemaname = 'public';"
   ```

3. **Restore from Backup**
   ```bash
   # Find last good backup
   aws s3 ls s3://spacetime-backups/database/ --recursive | sort

   # Download and restore
   aws s3 cp s3://spacetime-backups/database/spacetime_20251202_020000.sql.gz /restore/
   gunzip /restore/spacetime_20251202_020000.sql.gz

   sudo -u postgres psql spacetime < /restore/spacetime_20251202_020000.sql
   ```

4. **Verify and Restart**
   ```bash
   # Verify data integrity
   sudo -u postgres psql spacetime -c "SELECT COUNT(*) FROM users;"

   # Restart application
   for server in server1 server2 server3; do
     ssh $server "cd /opt/spacetime/production && docker-compose start"
   done
   ```

#### Scenario 3: Ransomware Attack

**Recovery Steps:**

1. **Isolate Immediately**
   ```bash
   # Disconnect from network
   for server in server1 server2 server3 db-primary; do
     ssh $server "sudo iptables -A INPUT -j DROP; sudo iptables -A OUTPUT -j DROP"
   done
   ```

2. **Assess Damage**
   ```bash
   # Check for encrypted files
   find /opt/spacetime -name "*.encrypted" -o -name "*.locked"

   # Check ransom notes
   find /opt/spacetime -name "README.*" -o -name "DECRYPT_INSTRUCTIONS.*"
   ```

3. **Restore from Clean Backup**
   ```bash
   # Use oldest confirmed clean backup
   # NOT the most recent (may be encrypted)

   # Provision new servers
   # Do NOT reuse potentially compromised servers

   # Restore from verified clean backup
   aws s3 cp s3://spacetime-backups/database/spacetime_20251201_020000.sql.gz /restore/
   ```

4. **Security Audit**
   ```bash
   # Scan for malware
   # Change all credentials
   # Review access logs
   # Engage security team
   ```

### Backup Testing

**Frequency:** Quarterly

**Process:**

1. **Schedule DR Test**
   - Pick low-traffic day
   - Notify team
   - Document test plan

2. **Execute Test**
   ```bash
   # Restore backup to DR environment
   # Verify data integrity
   # Test application functionality
   # Measure recovery time
   ```

3. **Document Results**
   - RTO achieved
   - RPO achieved
   - Issues encountered
   - Improvements needed

---

## Contact Information

### On-Call Rotation

- **Primary On-Call:** [Phone/Pager]
- **Secondary On-Call:** [Phone/Pager]
- **Manager On-Call:** [Phone/Pager]

### Escalation Path

1. **Level 1:** On-call engineer (response: 15 min)
2. **Level 2:** Senior SRE (response: 30 min)
3. **Level 3:** Engineering Manager (response: 1 hour)
4. **Level 4:** VP Engineering (response: 2 hours)

### External Contacts

- **Cloud Provider Support:** [Contact]
- **Database Support:** [Contact]
- **Security Team:** [Contact]
- **Legal:** [Contact]

### Communication Channels

- **Incidents:** Slack #incidents
- **Status Page:** status.spacetime.example.com
- **Customer Support:** support@spacetime.example.com

---

## Additional Resources

- [CI/CD Guide](../CI_CD_GUIDE.md)
- [Monitoring Guide](../MONITORING.md)
- [Security Documentation](../current/security/)
- [API Reference](../api/API_REFERENCE.md)
- [Rollback Procedures](../ROLLBACK_PROCEDURES.md)

---

**Last Updated:** 2025-12-02
**Version:** 2.5.0
**Status:** Production-Ready
