# Incident Response Checklist

**Incident ID:** __________
**Date:** __________
**Severity:** [ ] P0 [ ] P1 [ ] P2 [ ] P3 [ ] P4
**On-Call Engineer:** __________

---

## Initial Response (0-5 minutes)

### Alert Acknowledgment
- [ ] Alert acknowledged in PagerDuty
- [ ] Incident ID recorded: __________
- [ ] Start time: __________
- [ ] Initial severity assigned: __________

### Quick Assessment
- [ ] Alert verified (not false positive)
- [ ] Incident type identified: __________
  - [ ] Service down
  - [ ] High error rate
  - [ ] Slow performance
  - [ ] Authentication failure
  - [ ] Other: __________

### Initial Communication
- [ ] Incident channel created: #incident-__________
- [ ] Initial status posted
- [ ] On-call manager notified (if P0/P1)
- [ ] Status page updated (if customer-facing)

---

## Investigation (5-30 minutes)

### Data Collection
- [ ] Service status checked
  ```bash
  systemctl status godot-spacetime
  curl http://localhost:8080/status
  ```
- [ ] Logs collected (last 1 hour)
- [ ] Metrics reviewed in Grafana
- [ ] Recent changes identified
- [ ] Resource usage checked (CPU, Memory, Disk)

### Impact Assessment
- [ ] User impact identified:
  - [ ] All users
  - [ ] Percentage affected: _____%
  - [ ] Specific region/feature
- [ ] Business impact assessed
- [ ] Data loss risk: Yes/No
- [ ] Severity confirmed/adjusted: __________

### Root Cause Analysis
- [ ] Symptoms documented
- [ ] Error messages captured
- [ ] Correlation with metrics
- [ ] Hypothesis formed: __________
- [ ] Root cause identified: __________

---

## Resolution (10-60 minutes)

### Resolution Steps
- [ ] Followed incident runbook: RUNBOOK_INCIDENTS.md
- [ ] Specific incident type: __________
- [ ] Resolution steps taken:
  1. __________
  2. __________
  3. __________

### Testing
- [ ] Fix applied
- [ ] Service health verified
- [ ] Smoke tests passed
- [ ] Error rate reduced
- [ ] Performance restored
- [ ] No side effects observed

### Monitoring
- [ ] Monitored for 15 minutes
- [ ] No recurrence
- [ ] Metrics stable
- [ ] User reports resolved

---

## Communication Updates

### During Incident
- [ ] Update 1 (15 min): __________
- [ ] Update 2 (30 min): __________
- [ ] Update 3 (45 min): __________

### Resolution Communication
- [ ] Incident resolved announcement
- [ ] Status page updated
- [ ] Resolution time: __________
- [ ] Total duration: __________

---

## Escalation (If Required)

### Escalation Decision
- [ ] Escalation needed: Yes/No
- [ ] Escalation reason: __________
- [ ] Escalated to: __________
- [ ] Escalation time: __________

### Handoff
- [ ] Findings shared with escalation engineer
- [ ] Access provided
- [ ] Monitoring dashboards shared
- [ ] Debug package created

---

## Post-Incident (1-48 hours)

### Immediate Follow-Up (1 hour)
- [ ] System fully stable
- [ ] All monitoring green
- [ ] No related alerts
- [ ] Team debriefed

### Documentation (24 hours)
- [ ] Incident timeline documented
- [ ] Root cause documented
- [ ] Resolution documented
- [ ] Lessons learned noted

### Post-Mortem (48 hours)
- [ ] Post-mortem scheduled (if P0/P1)
- [ ] Post-mortem meeting held
- [ ] Post-mortem document created
- [ ] Action items identified

---

## Action Items

### Immediate Actions
1. __________
2. __________
3. __________

### Short-Term Actions (1 week)
1. __________
2. __________
3. __________

### Long-Term Actions (1 month)
1. __________
2. __________
3. __________

---

## Incident Metrics

**Detection:**
- Alert time: __________
- Detection time: __________
- Time to acknowledge: __________ (target: < 5 min)

**Resolution:**
- Time to root cause: __________
- Time to fix: __________
- Time to verify: __________
- Total incident duration: __________ (target: < 1 hour for P1)

**Impact:**
- Users affected: __________
- Requests failed: __________
- Error rate peak: _____%
- Downtime: __________ minutes

---

## Incident Classification

**Type:**
- [ ] Availability (service down)
- [ ] Performance (slow)
- [ ] Errors (high error rate)
- [ ] Security
- [ ] Data integrity
- [ ] Other: __________

**Root Cause Category:**
- [ ] Code bug
- [ ] Configuration error
- [ ] Infrastructure failure
- [ ] Third-party service
- [ ] Human error
- [ ] Unknown
- [ ] Other: __________

**Prevention Category:**
- [ ] Could have been prevented with monitoring
- [ ] Could have been caught in testing
- [ ] Requires code change
- [ ] Requires process change
- [ ] Not preventable

---

## Post-Mortem Template

**Incident Summary:**
_________________________________________________
_________________________________________________

**Timeline:**
| Time | Event |
|------|-------|
| ____ | Alert triggered |
| ____ | Incident acknowledged |
| ____ | Root cause identified |
| ____ | Fix applied |
| ____ | Incident resolved |

**Root Cause:**
_________________________________________________
_________________________________________________

**Impact:**
_________________________________________________
_________________________________________________

**What Went Well:**
_________________________________________________
_________________________________________________

**What Could Be Improved:**
_________________________________________________
_________________________________________________

**Action Items:**
| Action | Owner | Due Date | Priority |
|--------|-------|----------|----------|
| ______ | _____ | ________ | ________ |
| ______ | _____ | ________ | ________ |

---

## Sign-Off

**Incident Commander:** __________
**Resolution Time:** __________
**Status:** [ ] Resolved [ ] Mitigated [ ] Ongoing

**Post-Mortem Required:** Yes / No
**Post-Mortem Scheduled:** __________

**Manager Acknowledgment:** __________
**Date:** __________

**Additional Notes:**
_________________________________________________
_________________________________________________
_________________________________________________
