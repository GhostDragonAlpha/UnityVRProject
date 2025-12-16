# Maintenance Checklist

**Maintenance Type:** [ ] Scheduled [ ] Emergency
**Date:** __________
**Window:** __________ to __________
**Engineer:** __________

---

## Pre-Maintenance (T-2 weeks)

### Planning
- [ ] Maintenance request created
- [ ] Ticket number: __________
- [ ] Maintenance type:
  - [ ] System updates
  - [ ] Security patches
  - [ ] Certificate renewal
  - [ ] Database migration
  - [ ] Performance optimization
  - [ ] Other: __________
- [ ] Business justification documented
- [ ] Manager approval received

### Scheduling
- [ ] Maintenance window scheduled
- [ ] Calendar invite sent
- [ ] Low-traffic time confirmed
- [ ] No conflicting events
- [ ] Team availability verified

---

## Pre-Maintenance (T-1 week)

### Testing
- [ ] Procedure tested in staging
- [ ] Test results documented
- [ ] Performance impact measured
- [ ] Rollback procedure tested
- [ ] Edge cases identified

### Documentation
- [ ] Runbook created/updated
- [ ] Step-by-step procedure documented
- [ ] Rollback steps documented
- [ ] Known risks identified
- [ ] Mitigation strategies planned

### Communication
- [ ] Team notification sent (#announcements)
- [ ] Status page updated
- [ ] Customer communication (if needed)
- [ ] On-call schedule confirmed

---

## Pre-Maintenance (T-24 hours)

### Final Preparation
- [ ] Reminder sent to team
- [ ] Runbook reviewed
- [ ] Tools verified (scripts, commands)
- [ ] Access verified (SSH, AWS, etc.)
- [ ] Emergency contacts confirmed

### System Verification
- [ ] System currently healthy
- [ ] No active incidents
- [ ] Backups current (< 24 hours)
- [ ] Monitoring dashboards ready
- [ ] DNS TTL lowered (if needed)

### Backup
- [ ] Full backup completed
- [ ] Backup verified
- [ ] Configuration snapshot created
- [ ] Database backup (if applicable)
- [ ] Rollback package ready

---

## Maintenance Day (T-2 hours)

### Pre-Start
- [ ] System health check passed
- [ ] No new incidents
- [ ] Team ready and available
- [ ] Communication channels open
- [ ] Monitoring dashboards open

---

## Maintenance Execution (T-0)

### Start
- [ ] Posted "Maintenance starting" notification
- [ ] Start time recorded: __________
- [ ] Maintenance mode enabled (if applicable)

### Execution Steps

**Step 1:** __________
- [ ] Completed
- [ ] Verified
- [ ] Notes: __________

**Step 2:** __________
- [ ] Completed
- [ ] Verified
- [ ] Notes: __________

**Step 3:** __________
- [ ] Completed
- [ ] Verified
- [ ] Notes: __________

**Step 4:** __________
- [ ] Completed
- [ ] Verified
- [ ] Notes: __________

**Step 5:** __________
- [ ] Completed
- [ ] Verified
- [ ] Notes: __________

### Health Checks
- [ ] Service restarted successfully
- [ ] Health endpoint responding
- [ ] No errors in startup logs
- [ ] All subsystems initialized

---

## Verification (T+15 min)

### Functional Testing
- [ ] Smoke tests passed
- [ ] Critical endpoints tested
- [ ] Authentication working
- [ ] Key features functional
- [ ] No user-reported issues

### Performance Testing
- [ ] Response times acceptable
- [ ] Error rate < 1%
- [ ] CPU usage normal (< 50%)
- [ ] Memory usage normal (< 60%)
- [ ] Disk I/O normal

### Monitoring
- [ ] All metrics green
- [ ] No alerts triggered
- [ ] Telemetry flowing
- [ ] Logs clean (no errors)
- [ ] FPS stable (if applicable)

---

## Completion (T+30 min)

### Finalization
- [ ] Maintenance mode disabled
- [ ] DNS TTL restored (if changed)
- [ ] Temporary changes reverted
- [ ] Cleanup completed

### Communication
- [ ] Posted "Maintenance complete" notification
- [ ] Status page updated
- [ ] End time recorded: __________
- [ ] Total duration: __________
- [ ] Team debriefed

---

## Post-Maintenance (T+1 hour)

### Extended Monitoring
- [ ] System stable for 1 hour
- [ ] No performance degradation
- [ ] No increased error rates
- [ ] Resource usage stable
- [ ] No user complaints

### Documentation
- [ ] Maintenance notes documented
- [ ] Issues encountered: __________
- [ ] Deviations from plan: __________
- [ ] Lessons learned: __________
- [ ] Runbook updates needed: __________

---

## Post-Maintenance (T+24 hours)

### Review
- [ ] 24-hour metrics reviewed
- [ ] No issues detected
- [ ] SLO compliance verified
- [ ] User feedback reviewed
- [ ] Maintenance ticket closed

---

## Rollback (If Needed)

### Rollback Decision
- [ ] Rollback criteria met
- [ ] Manager informed
- [ ] Rollback approved

### Rollback Execution
- [ ] Rollback procedure started
- [ ] Previous state restored
- [ ] Service restarted
- [ ] Health verified
- [ ] Team notified

### Post-Rollback
- [ ] Rollback reason documented
- [ ] Issue analysis scheduled
- [ ] Rescheduling planned

---

## Maintenance Types

### System Updates
- [ ] OS packages updated
- [ ] Godot version updated
- [ ] Python packages updated
- [ ] System libraries updated
- [ ] Service restarted
- [ ] Version verified

### Security Patches
- [ ] Security advisories reviewed
- [ ] CVE numbers: __________
- [ ] Patches applied
- [ ] Vulnerability scan passed
- [ ] Patch documented

### Certificate Renewal
- [ ] Current certificate backed up
- [ ] New certificate obtained
- [ ] Certificate installed
- [ ] Service reloaded
- [ ] HTTPS verified
- [ ] Expiry date confirmed: __________

### Database Migration
- [ ] Database backed up
- [ ] Schema changes applied
- [ ] Data migrated
- [ ] Integrity verified
- [ ] Performance tested
- [ ] Migration logged

### Performance Optimization
- [ ] Baseline metrics captured
- [ ] Optimization applied
- [ ] Performance improvement measured
- [ ] No functionality regression
- [ ] Results documented

---

## Emergency Maintenance

### Emergency Justification
- [ ] Critical security vulnerability
- [ ] Production-breaking bug
- [ ] Data loss risk
- [ ] SLA breach prevention
- [ ] Other: __________

### Emergency Approval
- [ ] Manager approval: __________
- [ ] Reason documented: __________
- [ ] Risk assessment completed
- [ ] Emergency notification sent

### Emergency Execution
- [ ] Immediate backup created
- [ ] Emergency patch applied
- [ ] Quick verification
- [ ] Team notified
- [ ] Post-mortem scheduled

---

## Maintenance Metrics

**Timing:**
- Planned start: __________
- Actual start: __________
- Planned end: __________
- Actual end: __________
- Duration: __________ (target: ≤ planned)

**Impact:**
- Downtime: __________ minutes
- Users affected: __________
- Requests failed: __________
- SLA impact: Yes/No

**Success:**
- Objectives met: Yes/No
- Rollback required: Yes/No
- Issues encountered: __________
- Follow-up needed: Yes/No

---

## Sign-Off

**Maintenance Engineer:** __________
**Completion Time:** __________

**Manager Approval:** __________
**Date:** __________

**Maintenance Status:**
- [ ] Successful - No issues
- [ ] Successful - Minor issues (documented)
- [ ] Failed - Rolled back
- [ ] Partial - Requires follow-up

**Post-Maintenance Review Required:** Yes / No

**Notes:**
_________________________________________________
_________________________________________________
_________________________________________________
