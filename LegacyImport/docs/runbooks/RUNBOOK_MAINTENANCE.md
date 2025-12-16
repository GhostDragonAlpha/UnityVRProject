# Maintenance Procedures Runbook

**Version:** 2.5.0
**Last Updated:** 2025-12-02
**Maintained By:** DevOps Team
**Review Cycle:** Monthly

## Table of Contents

1. [Overview](#overview)
2. [Planned Maintenance Windows](#planned-maintenance-windows)
3. [Maintenance Procedures](#maintenance-procedures)
4. [Emergency Maintenance](#emergency-maintenance)

---

## Overview

### Maintenance Philosophy

All maintenance activities should:
- Be scheduled during low-traffic periods
- Have rollback plans ready
- Include comprehensive testing
- Minimize user impact
- Be properly communicated

### Maintenance Windows

**Standard Maintenance:** Tuesday/Thursday 02:00-04:00 UTC
**Emergency Maintenance:** As needed with 2-hour notice minimum
**Blackout Periods:** December 20 - January 5, major product launches

---

## Planned Maintenance Windows

### Scheduling Maintenance

**2 Weeks Before:**
```bash
# 1. Create maintenance request
# Include: purpose, duration, impact, rollback plan

# 2. Get approval from engineering manager

# 3. Schedule maintenance window
# Use calendar: maintenance@company.com

# 4. Post in #announcements
"📅 Scheduled Maintenance
Date: Tuesday, Dec 10, 2025
Time: 02:00-04:00 UTC
Purpose: System updates and patches
Expected Impact: Brief API interruptions
Status Page: https://status.company.com"
```

**1 Week Before:**
```bash
# 1. Send reminder in #announcements

# 2. Update status page with scheduled maintenance

# 3. Prepare runbook and checklist

# 4. Test procedure in staging

# 5. Prepare rollback scripts
```

**1 Day Before:**
```bash
# 1. Final reminder to team

# 2. Verify backup completion

# 3. Lower DNS TTL to 60 seconds

# 4. Verify on-call coverage

# 5. Test rollback procedure in staging
```

---

## Maintenance Procedures

### Rolling Update Procedure

**Use Case:** Deploy updates without downtime

**Duration:** 60-90 minutes

```bash
#!/bin/bash
# Rolling update across cluster

set -e

HOSTS=("prod-api-01" "prod-api-02" "prod-api-03")
NEW_VERSION="v2.5.1"

echo "Starting rolling update to $NEW_VERSION"

for HOST in "${HOSTS[@]}"; do
  echo "=== Updating $HOST ==="

  # 1. Remove from load balancer
  echo "Removing $HOST from load balancer..."
  aws elbv2 deregister-targets \
    --target-group-arn $TG_ARN \
    --targets Id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$HOST" --query 'Reservations[0].Instances[0].InstanceId' --output text)

  # Wait for connections to drain (60 seconds)
  sleep 60

  # 2. Stop service
  echo "Stopping service on $HOST..."
  ssh $HOST "sudo systemctl stop godot-spacetime"

  # 3. Backup current version
  echo "Backing up current version..."
  ssh $HOST "cd /opt/spacetime && sudo tar -czf backups/pre_update_$(date +%Y%m%d_%H%M%S).tar.gz production/"

  # 4. Deploy new version
  echo "Deploying $NEW_VERSION..."
  ssh $HOST "cd /opt/spacetime && sudo rm -rf production-new && sudo git clone -b $NEW_VERSION https://github.com/company/spacetime.git production-new"

  # 5. Switch symlink
  ssh $HOST "cd /opt/spacetime && sudo ln -sfn production-new production"

  # 6. Start service
  echo "Starting service on $HOST..."
  ssh $HOST "sudo systemctl start godot-spacetime"

  # 7. Wait for service to be healthy
  echo "Waiting for service health..."
  sleep 30

  # 8. Verify health
  HEALTH=$(ssh $HOST "curl -s http://localhost:8080/status | jq -r .overall_ready")
  if [ "$HEALTH" != "true" ]; then
    echo "ERROR: Service not healthy on $HOST"
    echo "Rolling back..."
    ssh $HOST "sudo systemctl stop godot-spacetime"
    ssh $HOST "cd /opt/spacetime && sudo ln -sfn production-old production"
    ssh $HOST "sudo systemctl start godot-spacetime"
    exit 1
  fi

  # 9. Add back to load balancer
  echo "Adding $HOST back to load balancer..."
  aws elbv2 register-targets \
    --target-group-arn $TG_ARN \
    --targets Id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$HOST" --query 'Reservations[0].Instances[0].InstanceId' --output text)

  # 10. Wait for load balancer health check
  sleep 30

  # 11. Verify target healthy
  TARGET_HEALTH=$(aws elbv2 describe-target-health --target-group-arn $TG_ARN --targets Id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$HOST" --query 'Reservations[0].Instances[0].InstanceId' --output text) --query 'TargetHealthDescriptions[0].TargetHealth.State' --output text)

  if [ "$TARGET_HEALTH" != "healthy" ]; then
    echo "WARNING: $HOST not healthy in load balancer after 30 seconds"
    echo "Check manually before continuing"
    read -p "Continue to next host? (yes/no): " CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
      exit 1
    fi
  fi

  echo "✓ $HOST updated successfully"
  echo "Waiting 2 minutes before next host..."
  sleep 120
done

echo "=== Rolling update complete ==="
echo "All hosts updated to $NEW_VERSION"
```

---

### Certificate Renewal Procedure

**Frequency:** Every 60 days (Let's Encrypt), 1 year (commercial certs)

**Duration:** 15-30 minutes

```bash
#!/bin/bash
# Certificate renewal procedure

set -e

DOMAIN="spacetime-api.company.com"

echo "Starting certificate renewal for $DOMAIN"

# 1. Backup current certificate
echo "Backing up current certificate..."
sudo cp /etc/ssl/certs/spacetime-api.crt /etc/ssl/certs/spacetime-api.crt.backup.$(date +%Y%m%d)
sudo cp /etc/ssl/private/spacetime-api.key /etc/ssl/private/spacetime-api.key.backup.$(date +%Y%m%d)

# 2. Check current certificate expiry
echo "Current certificate expiry:"
openssl x509 -in /etc/ssl/certs/spacetime-api.crt -noout -dates

# 3. Renew certificate (Let's Encrypt example)
echo "Renewing certificate..."
sudo certbot renew --cert-name $DOMAIN --deploy-hook "systemctl reload nginx"

# 4. Verify new certificate
echo "Verifying new certificate..."
openssl x509 -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem -noout -dates

# 5. Test certificate
echo "Testing certificate..."
openssl s_client -connect $DOMAIN:443 -servername $DOMAIN </dev/null 2>/dev/null | openssl x509 -noout -dates

# 6. Reload services
echo "Reloading services..."
sudo systemctl reload nginx
# Godot service doesn't need reload if using nginx proxy

# 7. Verify HTTPS works
echo "Verifying HTTPS endpoint..."
curl -s https://$DOMAIN/status | jq .overall_ready

echo "✓ Certificate renewal complete"

# 8. Update monitoring
# Reset certificate expiry alert

# 9. Document renewal
echo "$(date): Certificate renewed for $DOMAIN" >> /var/log/cert-renewals.log
```

---

### Log Rotation Procedure

**Frequency:** Daily (automated via logrotate)

**Manual Trigger:**

```bash
#!/bin/bash
# Manual log rotation

sudo logrotate -f /etc/logrotate.d/spacetime

# Verify rotation worked
ls -lh /opt/spacetime/logs/
```

**Logrotate Configuration:**

```bash
# /etc/logrotate.d/spacetime
/opt/spacetime/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 spacetime-app spacetime-app
    sharedscripts
    postrotate
        /bin/systemctl reload godot-spacetime > /dev/null 2>&1 || true
    endscript
}
```

---

### Dependency Update Procedure

**Frequency:** Monthly for minor updates, quarterly for major updates

**Duration:** 30-60 minutes per environment

```bash
#!/bin/bash
# Update dependencies

set -e

echo "=== Dependency Update Procedure ==="

# 1. Check current versions
echo "Current versions:"
echo "Godot: $(godot --version)"
echo "Python: $(python3 --version)"

# 2. Check for available updates
echo "Checking for system updates..."
sudo apt update
sudo apt list --upgradable | grep -E "godot|python"

# 3. Test updates in staging first
echo "Deploy to staging first and test for 24 hours before production"

read -p "Updates tested in staging? (yes/no): " TESTED
if [ "$TESTED" != "yes" ]; then
  echo "Please test in staging first"
  exit 1
fi

# 4. Create backup
echo "Creating pre-update backup..."
sudo /opt/spacetime/scripts/backup_full.sh

# 5. Apply updates
echo "Applying updates..."
sudo apt upgrade -y

# 6. Update Python packages
echo "Updating Python packages..."
pip3 list --outdated --format=json | jq -r '.[] | .name' | xargs -n1 pip3 install -U

# 7. Restart service
echo "Restarting service..."
sudo systemctl restart godot-spacetime

# 8. Verify service health
sleep 30
curl -s http://localhost:8080/status | jq .overall_ready

# 9. Run smoke tests
echo "Running smoke tests..."
cd /opt/spacetime/production/tests
python3 health_monitor.py

echo "✓ Dependency update complete"
```

---

### Security Patch Procedure

**Priority:** Critical patches within 24 hours, high within 1 week, medium within 1 month

```bash
#!/bin/bash
# Apply security patches

set -e

PATCH_SEVERITY="$1"  # critical, high, medium, low

if [ -z "$PATCH_SEVERITY" ]; then
  echo "Usage: $0 <critical|high|medium|low>"
  exit 1
fi

echo "=== Security Patch Procedure ==="
echo "Severity: $PATCH_SEVERITY"

# 1. Review security advisories
echo "Review:"
echo "- CVE details"
echo "- Affected versions"
echo "- Patch availability"
echo "- Workarounds"

read -p "Continue with patching? (yes/no): " CONTINUE
if [ "$CONTINUE" != "yes" ]; then
  exit 1
fi

# 2. Notify team
curl -X POST "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"🔒 Applying $PATCH_SEVERITY security patches to SpaceTime API\"}"

# 3. Test patches in staging
echo "Test in staging environment first"

read -p "Patches tested in staging? (yes/no): " TESTED
if [ "$TESTED" != "yes" ]; then
  echo "Test in staging first"
  exit 1
fi

# 4. Schedule maintenance window
# For critical: immediate
# For high: within next maintenance window
# For medium/low: next regular update cycle

# 5. Apply patches
if [ "$PATCH_SEVERITY" == "critical" ]; then
  echo "Critical patch - applying immediately with rolling restart"
  # Use rolling update procedure
else
  echo "Scheduling patch for next maintenance window"
  # Add to maintenance checklist
fi

# 6. Verify patch applied
echo "Verifying patch..."
# Check version numbers
# Run security scan

# 7. Document patch
echo "$(date): $PATCH_SEVERITY security patch applied" >> /var/log/security-patches.log

echo "✓ Security patch procedure complete"
```

---

### Database Migration Procedure

**Use Case:** Schema changes, data migrations (if database used)

```bash
#!/bin/bash
# Database migration procedure

set -e

MIGRATION_NAME="$1"

if [ -z "$MIGRATION_NAME" ]; then
  echo "Usage: $0 <migration_name>"
  exit 1
fi

echo "=== Database Migration: $MIGRATION_NAME ==="

# 1. Backup database
echo "Backing up database..."
pg_dump -U spacetime -d spacetime_db --format=custom --file=/opt/spacetime/backups/db_pre_migration_$(date +%Y%m%d_%H%M%S).dump

# 2. Set application to read-only mode (if supported)
echo "Setting to read-only mode..."
# curl -X POST http://localhost:8080/admin/readonly

# 3. Run migration script
echo "Running migration..."
psql -U spacetime -d spacetime_db -f /opt/spacetime/migrations/${MIGRATION_NAME}.sql

# 4. Verify migration
echo "Verifying migration..."
psql -U spacetime -d spacetime_db -c "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1;"

# 5. Test application
echo "Testing application..."
# Run integration tests

# 6. Re-enable writes
echo "Re-enabling writes..."
# curl -X POST http://localhost:8080/admin/readwrite

# 7. Monitor for errors
echo "Monitor for 1 hour for any migration-related errors"

echo "✓ Database migration complete"
```

---

## Emergency Maintenance

### Emergency Patch Procedure

**Trigger:** Critical security vulnerability or production-breaking bug

```bash
#!/bin/bash
# Emergency patch deployment

set -e

echo "=== EMERGENCY MAINTENANCE ==="

# 1. Verify emergency status
read -p "Is this truly an emergency requiring immediate action? (yes/no): " EMERGENCY
if [ "$EMERGENCY" != "yes" ]; then
  echo "Use standard deployment procedure for non-emergencies"
  exit 1
fi

# 2. Get manager approval
echo "Emergency maintenance requires manager approval"
read -p "Manager approval received? (yes/no): " APPROVED
if [ "$APPROVED" != "yes" ]; then
  echo "Cannot proceed without approval"
  exit 1
fi

# 3. Immediate notification
curl -X POST "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "🚨 EMERGENCY MAINTENANCE IN PROGRESS",
    "attachments": [{
      "color": "danger",
      "fields": [
        {"title": "Reason", "value": "Critical security patch", "short": false},
        {"title": "Expected Duration", "value": "30 minutes", "short": true},
        {"title": "Impact", "value": "Brief service interruption", "short": true}
      ]
    }]
  }'

# 4. Update status page
# Mark as under maintenance

# 5. Quick backup
echo "Creating emergency backup..."
cd /opt/spacetime
tar -czf backups/emergency_backup_$(date +%Y%m%d_%H%M%S).tar.gz production/

# 6. Apply patch
echo "Applying emergency patch..."
# Deploy using fastest method (may skip some safety checks)

# 7. Restart service
sudo systemctl restart godot-spacetime

# 8. Quick verification
sleep 30
curl -s http://localhost:8080/status | jq .overall_ready

# 9. Update status
curl -X POST "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" \
  -H "Content-Type: application/json" \
  -d '{"text": "✅ Emergency maintenance complete. Service operational."}'

# 10. Post-mortem required
echo "Create post-mortem document within 24 hours"

echo "✓ Emergency maintenance complete"
```

---

## Maintenance Checklists

### Pre-Maintenance Checklist

```markdown
# Pre-Maintenance Checklist

Maintenance Date: __________
Type: __________
Engineer: __________

## Preparation (T-2 weeks)
- [ ] Maintenance request created and approved
- [ ] Maintenance window scheduled
- [ ] Team notified via Slack
- [ ] Status page updated
- [ ] Runbook prepared
- [ ] Rollback plan documented

## Testing (T-1 week)
- [ ] Procedure tested in staging
- [ ] Smoke tests prepared
- [ ] Performance tests prepared
- [ ] Rollback tested in staging

## Final Preparation (T-24 hours)
- [ ] Team reminder sent
- [ ] On-call coverage verified
- [ ] Backup completed and verified
- [ ] DNS TTL lowered to 60 seconds
- [ ] Monitoring alerts configured
- [ ] Communication templates prepared

## Ready to Execute
- [ ] All checks passed
- [ ] Engineer ready
- [ ] Manager aware
- [ ] Emergency contacts available
```

---

### Maintenance Execution Checklist

```markdown
# Maintenance Execution Checklist

Date: __________
Start Time: __________

## Pre-Maintenance (T-15 min)
- [ ] Post "maintenance starting in 15 minutes" notification
- [ ] Final backup verification
- [ ] Verify rollback procedure ready
- [ ] Open monitoring dashboards

## Maintenance Start (T-0)
- [ ] Post "maintenance started" notification
- [ ] Enable maintenance mode (if applicable)
- [ ] Begin procedure following runbook

## During Maintenance
- [ ] Document each step completed
- [ ] Note any deviations from plan
- [ ] Monitor error rates and logs
- [ ] Provide status updates every 15 minutes

## Verification
- [ ] Service health check passed
- [ ] Smoke tests passed
- [ ] Performance tests passed
- [ ] No errors in logs
- [ ] Monitoring shows normal metrics

## Maintenance Complete
- [ ] Disable maintenance mode
- [ ] Post "maintenance complete" notification
- [ ] Update status page
- [ ] Monitor for 30 minutes
- [ ] Document completion time

## Post-Maintenance (T+30 min)
- [ ] Verify system stability
- [ ] Check for any issues
- [ ] Final status update
- [ ] Schedule post-maintenance review (if needed)

## Sign-off
Engineer: __________
Manager: __________
Completion Time: __________
```

---

## Appendix

### Maintenance Communication Templates

**Pre-Maintenance Announcement (1 week before):**
```
📅 Scheduled Maintenance Notification

Date: Tuesday, December 10, 2025
Time: 02:00-04:00 UTC (9:00 PM - 11:00 PM EST)
Duration: Up to 2 hours
Impact: Brief API interruptions during rolling restart

Purpose:
- Apply security patches
- Update to Godot 4.5.2
- Performance optimizations

What to Expect:
- Brief connection interruptions (< 30 seconds each)
- No data loss
- Improved performance after completion

Status Page: https://status.company.com
Questions: #spacetime-support
```

**Maintenance Start:**
```
🔧 Maintenance has started

Expected completion: 04:00 UTC
Current status: Applying updates to first server
Next update: 02:30 UTC

Follow progress: https://status.company.com
```

**Maintenance Complete:**
```
✅ Maintenance completed successfully

Duration: 1 hour 45 minutes
Outcome: All updates applied, service operational
Performance: All metrics normal

Thank you for your patience!
```

---

## Runbook Maintenance

- **Review Frequency:** Quarterly, after each major maintenance
- **Last Reviewed:** 2025-12-02
- **Next Review:** 2026-03-02
- **Owner:** DevOps Team
- **Approver:** Engineering Manager
