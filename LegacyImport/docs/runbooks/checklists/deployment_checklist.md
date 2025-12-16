# Deployment Checklist

**Version:** 2.5.0
**Date:** __________
**Engineer:** __________
**Deployment Type:** [ ] Standard [ ] Hotfix [ ] Emergency

---

## Pre-Deployment (T-2 weeks)

### Planning
- [ ] Deployment request created and approved
- [ ] Change ticket number: __________
- [ ] Deployment window scheduled: __________
- [ ] Release notes reviewed
- [ ] Breaking changes identified: Yes/No
- [ ] Rollback plan documented
- [ ] Team notified via Slack #deployments

### Code Preparation
- [ ] Code merged to main branch
- [ ] Git tag created: __________
- [ ] Commit hash: __________
- [ ] All tests passing in CI/CD
- [ ] Code review completed
- [ ] Security scan passed

---

## Pre-Deployment (T-1 week)

### Testing
- [ ] Deployed to staging environment
- [ ] Integration tests passed
- [ ] Load tests passed
- [ ] Performance tests passed
- [ ] Smoke tests passed
- [ ] No errors in staging logs

### Documentation
- [ ] Deployment runbook reviewed
- [ ] RUNBOOK_DEPLOYMENT.md followed
- [ ] Known issues documented
- [ ] Team training completed (if needed)

---

## Pre-Deployment (T-24 hours)

### Infrastructure
- [ ] Server resources verified (CPU, Memory, Disk)
- [ ] Disk space >= 20GB free
- [ ] Memory >= 8GB available
- [ ] Load average acceptable
- [ ] Firewall rules verified
- [ ] Ports 6005, 6006, 8081, 8080 available
- [ ] DNS TTL lowered to 60 seconds

### Backup
- [ ] Latest backup verified (< 24 hours old)
- [ ] Backup restoration tested
- [ ] Pre-deployment snapshot created
- [ ] Configuration backed up
- [ ] Database backed up (if applicable)

### Communication
- [ ] Final team notification sent
- [ ] Status page updated with scheduled maintenance
- [ ] On-call engineer identified: __________
- [ ] Manager aware of deployment
- [ ] Emergency contacts verified

---

## Deployment Day (T-2 hours)

### Final Preparation
- [ ] Morning health check completed
- [ ] No active incidents
- [ ] System metrics normal
- [ ] Deployment scripts tested
- [ ] Rollback scripts ready
- [ ] Monitoring dashboards open
- [ ] Communication channels ready

### Verification
- [ ] Production environment verified
- [ ] Service currently healthy
- [ ] No scheduled conflicts
- [ ] Team members available
- [ ] All access verified (SSH, AWS, etc.)

---

## Deployment Execution (T-0)

### Pre-Deployment Steps
- [ ] Posted "Deployment starting" in #deployments
- [ ] Maintenance mode enabled (if applicable)
- [ ] Final backup created: __________
- [ ] Start time recorded: __________

### Deployment Steps
- [ ] Step 1: Service stopped cleanly
- [ ] Step 2: New code deployed
- [ ] Step 3: Configuration updated
- [ ] Step 4: Database migrated (if applicable)
- [ ] Step 5: Service started
- [ ] Step 6: Health check passed
- [ ] Step 7: Smoke tests passed
- [ ] Step 8: Load balancer updated

### Verification Steps
- [ ] API health check: overall_ready = true
- [ ] All endpoints responding
- [ ] Error rate < 1%
- [ ] Response times acceptable (< 200ms P95)
- [ ] No errors in logs (last 5 minutes)
- [ ] Telemetry flowing correctly
- [ ] FPS stable at 90

---

## Post-Deployment (T+30 min)

### Immediate Monitoring
- [ ] Error rate stable
- [ ] Response times normal
- [ ] CPU usage < 50%
- [ ] Memory usage < 60%
- [ ] No alerts triggered
- [ ] User reports reviewed (if any)

### Communication
- [ ] Maintenance mode disabled
- [ ] Posted "Deployment complete" in #deployments
- [ ] Status page updated
- [ ] Completion time recorded: __________
- [ ] Total duration: __________

---

## Post-Deployment (T+2 hours)

### Extended Monitoring
- [ ] Performance metrics stable
- [ ] No error rate increase
- [ ] Resource usage normal
- [ ] No memory leaks detected
- [ ] Logs reviewed (no unexpected errors)

### Documentation
- [ ] Deployment notes documented
- [ ] Any issues encountered: __________
- [ ] Lessons learned: __________
- [ ] Runbook updates needed: __________

---

## Post-Deployment (T+24 hours)

### Health Verification
- [ ] 24-hour metrics reviewed
- [ ] SLO compliance verified
- [ ] No incidents related to deployment
- [ ] User feedback reviewed
- [ ] All systems stable

### Cleanup
- [ ] Old backups cleaned up (retention policy)
- [ ] Temporary files removed
- [ ] DNS TTL restored to normal
- [ ] Deployment ticket closed
- [ ] Team debrief scheduled (if issues)

---

## Rollback (If Needed)

### Rollback Decision
- [ ] Rollback criteria met: __________
- [ ] Manager approval received (for P0/P1)
- [ ] Rollback procedure: RUNBOOK_DEPLOYMENT.md

### Rollback Execution
- [ ] Service stopped
- [ ] Previous version restored
- [ ] Configuration restored
- [ ] Service restarted
- [ ] Health check passed
- [ ] Team notified of rollback

### Post-Rollback
- [ ] Rollback reason documented
- [ ] Incident ticket created
- [ ] Post-mortem scheduled
- [ ] Fix planned for next deployment

---

## Sign-Off

**Deployment Engineer:** __________
**Sign-Off Time:** __________

**Manager Approval:** __________
**Date:** __________

**Deployment Status:**
- [ ] Successful - No issues
- [ ] Successful - Minor issues (documented)
- [ ] Failed - Rolled back
- [ ] Partial - Requires follow-up

**Notes:**
_________________________________________________
_________________________________________________
_________________________________________________

**Post-Deployment Review Required:** Yes / No
**Post-Mortem Required:** Yes / No
