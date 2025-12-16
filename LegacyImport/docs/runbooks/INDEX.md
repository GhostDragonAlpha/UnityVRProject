# Production Runbooks - Index

**SpaceTime HTTP Scene Management API v2.5.0**
**Last Updated:** 2025-12-02
**Maintained By:** DevOps Team

---

## Overview

This comprehensive runbook package provides complete operational procedures for the SpaceTime HTTP Scene Management API in production environments. The runbooks are designed for DevOps engineers, on-call personnel, and operations staff.

**Total Documentation:** 7 runbooks, 4 checklists, 4 quick reference cards

---

## Main Runbooks

### 1. Deployment Runbook
**File:** `RUNBOOK_DEPLOYMENT.md`
**Purpose:** Step-by-step deployment procedures
**Use When:** Deploying new versions, hotfixes, or updates

**Key Sections:**
- Pre-deployment checklist
- Deployment procedure (10 steps)
- Post-deployment validation
- Rollback procedures
- Common deployment issues

**Estimated Time:** 45-60 minutes (standard deployment)

**Quick Start:**
```bash
# Pre-deployment
1. Review checklist: checklists/deployment_checklist.md
2. Create backup
3. Lower DNS TTL

# Deploy
4. Follow RUNBOOK_DEPLOYMENT.md steps 1-10

# Verify
5. Run health checks
6. Monitor for 30 minutes
```

---

### 2. Operations Runbook
**File:** `RUNBOOK_OPERATIONS.md`
**Purpose:** Daily, weekly, and monthly operational procedures
**Use When:** Regular operations and maintenance

**Key Sections:**
- Daily operations (morning health check, log review)
- Weekly operations (metrics review, capacity planning)
- Monthly operations (SLO review, security audit)
- Quarterly operations (DR drill)
- On-call procedures

**Estimated Time:**
- Daily: 15-30 minutes
- Weekly: 30-60 minutes
- Monthly: 2-4 hours

**Quick Start:**
```bash
# Daily morning check
1. Review overnight alerts
2. Check service health
3. Review performance metrics
4. Check resource utilization
5. Review logs for errors
```

---

### 3. Incident Response Runbook
**File:** `RUNBOOK_INCIDENTS.md`
**Purpose:** Incident response procedures and common incident resolutions
**Use When:** Responding to alerts and incidents

**Key Sections:**
- Severity levels (P0-P4)
- Escalation procedures
- Common incidents (7 types with full resolution procedures)
- Incident response process (7 phases)
- Post-incident review

**Estimated Time:**
- P0: < 1 hour target resolution
- P1: < 4 hours target resolution
- P2: < 24 hours target resolution

**Common Incidents Covered:**
1. API Completely Unresponsive
2. High Error Rate
3. Slow Response Times
4. Authentication Failures
5. Scene Loading Failures
6. Memory Leak
7. Disk Space Exhaustion

**Quick Start:**
```bash
# When alert fires
1. Acknowledge alert (< 5 min)
2. Assess severity
3. Create incident channel
4. Follow incident-specific procedure
5. Resolve and document
```

---

### 4. Backup and Recovery Runbook
**File:** `RUNBOOK_BACKUP.md`
**Purpose:** Backup, recovery, and disaster recovery procedures
**Use When:** Creating backups, recovering data, executing DR

**Key Sections:**
- Backup strategy (RPO: 1 hour, RTO: 15 minutes)
- Backup procedures (daily, incremental, configuration)
- Recovery procedures (full, point-in-time, partial)
- Disaster recovery plan
- Testing and verification

**Estimated Time:**
- Daily backup: 10-15 minutes
- Full recovery: 30-45 minutes
- DR failover: 15-30 minutes

**Backup Schedule:**
- Hourly: Incremental backups
- Daily: Full backups (2:00 AM UTC)
- Weekly: Long-retention backups
- Monthly: Archive backups

**Quick Start:**
```bash
# Create backup
sudo /opt/spacetime/scripts/backup_full.sh

# Verify backup
ls -lh /opt/spacetime/backups/production_full_*.tar.gz | tail -1

# Test restore (to staging)
sudo /opt/spacetime/scripts/restore_backup.sh <backup_file>
```

---

### 5. Monitoring and Alerting Runbook
**File:** `RUNBOOK_MONITORING.md`
**Purpose:** Alert response procedures and monitoring tools
**Use When:** Responding to alerts, monitoring system health

**Key Sections:**
- Alert response procedures
- Alert catalog (12 critical alerts with full procedures)
- On-call procedures (shift start/end checklists)
- Monitoring tools (Prometheus, Grafana, logs)
- False positive handling

**Critical Alerts:**
- API_DOWN
- HIGH_ERROR_RATE
- SLOW_RESPONSE_TIME
- HIGH_MEMORY_USAGE
- HIGH_CPU_USAGE
- DISK_SPACE_LOW
- AUTHENTICATION_FAILURES
- CERTIFICATE_EXPIRING
- GODOT_FPS_LOW
- BACKUP_FAILED

**Quick Start:**
```bash
# On-call shift start
1. Test alert notification
2. Check system status
3. Review active incidents
4. Read handoff notes
5. Verify access to all systems

# Alert response
1. Acknowledge (< 5 min)
2. Verify alert validity
3. Create incident channel (if P0/P1)
4. Follow alert-specific procedure
5. Resolve and document
```

---

### 6. Maintenance Runbook
**File:** `RUNBOOK_MAINTENANCE.md`
**Purpose:** Planned and emergency maintenance procedures
**Use When:** Performing system maintenance, updates, patches

**Key Sections:**
- Planned maintenance windows
- Maintenance procedures (rolling updates, certificate renewal, etc.)
- Emergency maintenance
- Maintenance checklists

**Maintenance Types:**
- Rolling updates
- Certificate renewal
- Log rotation
- Dependency updates
- Security patches
- Database migrations

**Estimated Time:**
- Rolling update: 60-90 minutes
- Certificate renewal: 15-30 minutes
- Security patch: 30-60 minutes

**Quick Start:**
```bash
# Schedule maintenance
1. Create maintenance request (T-2 weeks)
2. Test in staging (T-1 week)
3. Notify team (T-24 hours)
4. Execute: checklists/maintenance_checklist.md
5. Verify and document
```

---

### 7. Troubleshooting Guide
**File:** `RUNBOOK_TROUBLESHOOTING.md`
**Purpose:** Systematic troubleshooting approach and common solutions
**Use When:** Diagnosing and resolving issues

**Key Sections:**
- Systematic troubleshooting approach
- Common error messages (10+ with solutions)
- Debug information collection
- Performance profiling (CPU, memory, disk, network)
- When to escalate

**Troubleshooting Methodology:**
1. Observe and define problem
2. Quick health check
3. Review recent changes
4. Collect diagnostic data
5. Analyze patterns
6. Form hypothesis
7. Test and resolve
8. Document

**Quick Start:**
```bash
# Troubleshooting workflow
1. Define the problem clearly
2. Quick checks: service, API, resources
3. Review recent changes (deployments, configs)
4. Collect logs and metrics
5. Analyze error patterns
6. Follow specific error resolution
7. Escalate if needed (see guide)
```

---

## Checklists

### 1. Deployment Checklist
**File:** `checklists/deployment_checklist.md`
**Use For:** All deployments to production

**Sections:**
- Pre-deployment (T-2 weeks, T-1 week, T-24 hours)
- Deployment execution
- Post-deployment validation
- Rollback (if needed)
- Sign-off

**Time Investment:** 15 minutes to complete

---

### 2. Incident Response Checklist
**File:** `checklists/incident_response_checklist.md`
**Use For:** All production incidents

**Sections:**
- Initial response (0-5 minutes)
- Investigation (5-30 minutes)
- Resolution (10-60 minutes)
- Communication updates
- Escalation (if required)
- Post-incident follow-up

**Time Investment:** Complete during incident

---

### 3. Maintenance Checklist
**File:** `checklists/maintenance_checklist.md`
**Use For:** All planned maintenance

**Sections:**
- Pre-maintenance (T-2 weeks, T-1 week, T-24 hours)
- Maintenance execution
- Verification
- Completion
- Rollback (if needed)

**Time Investment:** 10-15 minutes to complete

---

### 4. Security Review Checklist
**File:** `checklists/security_review_checklist.md`
**Use For:** Monthly/quarterly security reviews

**Sections:**
- Certificate management
- Access control
- Vulnerability management
- Network security
- Data security
- Logging and monitoring
- Compliance
- Application security

**Time Investment:** 2-4 hours (comprehensive review)

---

## Quick Reference Cards

### 1. Common Commands
**File:** `quick_reference/common_commands.md`
**Use For:** Quick command lookups

**Sections:**
- Service management
- Health checks
- Log management
- Resource monitoring
- Network debugging
- API testing
- File operations
- Process management
- Git operations
- Backup operations
- Performance analysis
- Emergency procedures

**Printable reference card included**

---

### 2. API Endpoints
**File:** `quick_reference/api_endpoints.md`
**Use For:** Quick API reference

**Sections:**
- Connection management (/status, /connect, /disconnect)
- Debug Adapter Protocol (DAP) endpoints
- Language Server Protocol (LSP) endpoints
- Scene management
- Resonance system
- Code execution
- WebSocket telemetry
- Error responses
- Rate limits

**Includes curl examples for all endpoints**

---

### 3. Log Locations
**File:** `quick_reference/log_locations.md`
**Use For:** Finding and analyzing logs

**Sections:**
- Primary log locations (journald, application, deployment)
- Log categories (error, warning, info, debug)
- Component-specific logs
- System logs
- Access logs
- Audit logs
- Log rotation
- Log analysis commands

**Printable reference card included**

---

### 4. Alert Summary
**File:** `quick_reference/alert_summary.md`
**Use For:** Quick alert response

**Sections:**
- Alert severity levels
- Critical alerts (P0/P1) with quick responses
- Alert response matrix
- Alert response procedures
- Common alert patterns
- Alert channels
- Silencing alerts
- On-call quick reference

**Printable reference card included**

---

## Supporting Documents

### Incident Postmortem Template
**File:** `templates/incident_postmortem.md`
**Use For:** Creating post-incident reviews

**Sections:**
- Incident summary
- Timeline
- Root cause analysis
- Impact assessment
- What went well / What went wrong
- Action items
- Lessons learned
- Prevention measures

---

### Runbook Maintenance Schedule
**File:** `MAINTENANCE_SCHEDULE.md`
**Use For:** Keeping runbooks current

**Review Frequency:**
- Monthly: All runbooks
- Quarterly: Checklists
- After major incidents: Related runbooks
- After major deployments: Deployment runbook
- Annual: Complete audit

---

### Feedback and Improvement
**File:** `FEEDBACK_FORM.md`
**Use For:** Collecting runbook improvement suggestions

**Questions:**
- Was the runbook helpful?
- What information was missing?
- What was confusing?
- Suggestions for improvement?

---

## Usage Guide

### For New Team Members

**Week 1:**
- Read INDEX.md (this file)
- Review RUNBOOK_OPERATIONS.md (daily operations)
- Familiarize with quick_reference/common_commands.md

**Week 2:**
- Read RUNBOOK_INCIDENTS.md
- Review quick_reference/alert_summary.md
- Shadow on-call engineer

**Week 3:**
- Read RUNBOOK_DEPLOYMENT.md
- Review checklists
- Practice in staging environment

**Week 4:**
- Read RUNBOOK_TROUBLESHOOTING.md
- Complete security review checklist
- Ready for on-call rotation

---

### For On-Call Engineers

**Before Shift:**
- Review RUNBOOK_MONITORING.md (on-call procedures)
- Check quick_reference/alert_summary.md
- Verify access to all systems

**During Shift:**
- Use RUNBOOK_INCIDENTS.md for incident response
- Use RUNBOOK_TROUBLESHOOTING.md for investigation
- Document all actions

**After Shift:**
- Complete handoff notes
- Update runbooks if needed
- Submit feedback if issues found

---

### For Deployment Engineers

**Before Deployment:**
- Review RUNBOOK_DEPLOYMENT.md thoroughly
- Complete checklists/deployment_checklist.md
- Test in staging environment

**During Deployment:**
- Follow RUNBOOK_DEPLOYMENT.md step-by-step
- Document any deviations
- Verify each step before proceeding

**After Deployment:**
- Complete post-deployment checklist
- Monitor for issues
- Update runbook with lessons learned

---

## Runbook Statistics

**Total Pages:** ~200 pages
**Total Words:** ~50,000 words
**Total Commands:** ~300 command examples
**Total Procedures:** ~50 documented procedures
**Coverage:**
- 7 major operational areas
- 12 critical alerts
- 7 common incidents
- 10+ common error messages
- 6 maintenance types

**Maintenance:**
- Review cycle: Monthly
- Last updated: 2025-12-02
- Next review: 2026-01-02
- Owner: DevOps Team
- Approver: Engineering Manager

---

## Document Conventions

### File Naming
- Main runbooks: `RUNBOOK_*.md`
- Checklists: `checklists/*.md`
- Quick reference: `quick_reference/*.md`
- Templates: `templates/*.md`

### Formatting
- **Bold:** Important information
- `Code`: Commands, file paths
- [ ] Checklist items
- > Quotes: Important notes
- ⚠️ Warnings
- ✓ Success indicators
- ✗ Failure indicators

### Code Blocks
```bash
# Comments explain what the command does
command --with-arguments

# Expected output shown below
# Output: Expected result
```

---

## Getting Help

### Runbook Issues
- **Missing information:** Submit via FEEDBACK_FORM.md
- **Errors in runbook:** Create ticket in JIRA
- **Unclear procedures:** Ask in #spacetime-operations

### Technical Issues
- **On-call:** Page via PagerDuty
- **Urgent:** #spacetime-incidents
- **Non-urgent:** #spacetime-support

### Documentation Requests
- **New runbook:** Submit request to DevOps team
- **Updates:** Create pull request with changes
- **Suggestions:** Submit via FEEDBACK_FORM.md

---

## Version History

**v2.5.0 (2025-12-02)**
- Initial comprehensive runbook package
- 7 main runbooks created
- 4 checklists created
- 4 quick reference cards created
- Supporting templates added

**Future Versions:**
- Runbooks updated monthly
- Major revisions with version bumps
- Change log maintained in each runbook

---

## Quick Start by Role

### DevOps Engineer
**Primary Documents:**
1. RUNBOOK_OPERATIONS.md (daily use)
2. RUNBOOK_DEPLOYMENT.md (weekly)
3. RUNBOOK_MONITORING.md (daily)
4. quick_reference/common_commands.md (daily)

### On-Call Engineer
**Primary Documents:**
1. RUNBOOK_INCIDENTS.md (as needed)
2. RUNBOOK_MONITORING.md (shift start/end)
3. RUNBOOK_TROUBLESHOOTING.md (as needed)
4. quick_reference/alert_summary.md (daily)

### Release Engineer
**Primary Documents:**
1. RUNBOOK_DEPLOYMENT.md (always)
2. checklists/deployment_checklist.md (always)
3. RUNBOOK_BACKUP.md (before deploys)

### Security Engineer
**Primary Documents:**
1. checklists/security_review_checklist.md (monthly)
2. RUNBOOK_OPERATIONS.md (security sections)
3. RUNBOOK_MONITORING.md (auth alerts)

---

## Contact Information

**Runbook Maintainer:** DevOps Team
**Email:** devops@company.com
**Slack:** #spacetime-operations

**On-Call:** Check PagerDuty schedule
**Escalation:** See RUNBOOK_INCIDENTS.md

**Emergency Contacts:**
- PagerDuty: spacetime-oncall
- Slack: #spacetime-incidents
- Phone: +1-555-0123 (24/7 hotline)

---

## License and Usage

**Internal Use Only**
- These runbooks are confidential
- Do not share outside organization
- Contains sensitive operational details

**Updates:**
- Submit improvements via pull request
- All changes reviewed by DevOps team
- Major changes require manager approval

---

## Appendix

### Related Documentation
- `addons/godot_debug_connection/HTTP_API.md` - API reference
- `addons/godot_debug_connection/DEPLOYMENT_GUIDE.md` - Deployment details
- `CLAUDE.md` - Project overview
- `DEVELOPMENT_WORKFLOW.md` - Development processes

### External Resources
- Godot Engine Docs: https://docs.godotengine.org/
- Prometheus Docs: https://prometheus.io/docs/
- PagerDuty Docs: https://support.pagerduty.com/

---

**Last Updated:** 2025-12-02
**Next Review:** 2026-01-02
**Version:** 2.5.0
