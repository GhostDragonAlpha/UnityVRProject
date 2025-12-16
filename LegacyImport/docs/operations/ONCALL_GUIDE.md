# On-Call Security Engineer Guide

**SpaceTime VR Project - Security On-Call Procedures**
**Version:** 1.0.0
**Last Updated:** 2025-12-02
**Owner:** Security Operations Team

## Table of Contents

1. [Overview](#overview)
2. [On-Call Responsibilities](#on-call-responsibilities)
3. [On-Call Schedule](#on-call-schedule)
4. [Handoff Procedures](#handoff-procedures)
5. [Alert Response](#alert-response)
6. [Escalation Procedures](#escalation-procedures)
7. [Communication Protocols](#communication-protocols)
8. [Tools and Access](#tools-and-access)
9. [Common Scenarios](#common-scenarios)
10. [Post-Incident Actions](#post-incident-actions)

---

## Overview

### Purpose

This guide provides comprehensive procedures for security engineers on on-call duty. It covers responsibilities, alert response, escalation, and communication protocols.

### On-Call Commitment

When on-call, you are the first line of defense for security incidents. You commit to:

- **Availability:** Respond within defined SLAs
- **Preparedness:** Have all tools and access ready
- **Responsibility:** Own incidents from detection to resolution
- **Communication:** Keep stakeholders informed
- **Escalation:** Know when and how to escalate

### Response Time SLAs

| Severity | Acknowledgment | Initial Response | Target Resolution |
|----------|----------------|------------------|-------------------|
| **P0 - Critical** | 5 minutes | 10 minutes | 4 hours |
| **P1 - High** | 15 minutes | 30 minutes | 8 hours |
| **P2 - Medium** | 1 hour | 2 hours | 24 hours |
| **P3 - Low** | 4 hours | Next business day | 1 week |

---

## On-Call Responsibilities

### Before Your On-Call Shift

**24 hours before:**

1. **Review open incidents**
   ```bash
   # Check current security status
   curl http://127.0.0.1:8080/admin/security/status

   # Review active threats
   curl http://127.0.0.1:8080/admin/security/threats/active

   # Check for ongoing investigations
   ```

2. **Verify access and tools**
   - [ ] PagerDuty app working
   - [ ] VPN access functional
   - [ ] AWS/Cloud console access
   - [ ] Production system access
   - [ ] Grafana dashboards accessible
   - [ ] Slack notifications enabled
   - [ ] Phone/laptop charged

3. **Review recent changes**
   ```bash
   # Check recent deployments
   git log --since="1 week ago" --oneline

   # Review recent security incidents
   # Check #security-incidents Slack channel
   ```

4. **Read handoff notes**
   - Review outgoing engineer's notes
   - Ask clarifying questions
   - Understand ongoing issues

5. **Update contact information**
   - Verify phone number in PagerDuty
   - Update Slack status: "On-Call (Security)"
   - Inform team you're starting shift

### During Your On-Call Shift

**Continuous:**

1. **Monitor alerts**
   - PagerDuty notifications
   - Slack #security-alerts channel
   - Grafana dashboards
   - Email alerts

2. **Be available**
   - Within cell phone reception
   - Near computer access
   - Able to respond within SLA

3. **Maintain situational awareness**
   - Check security dashboard 3x daily (morning, afternoon, evening)
   - Review threat summary
   - Monitor trending metrics

4. **Document everything**
   - Log all incidents
   - Document actions taken
   - Record decisions and rationale
   - Update runbooks with learnings

### After Your On-Call Shift

**Within 2 hours of shift end:**

1. **Conduct handoff**
   - Brief incoming engineer (30-minute call)
   - Share open incidents
   - Document ongoing issues

2. **Update documentation**
   - Finalize incident notes
   - Update runbooks if needed
   - File any bugs or improvement requests

3. **Submit on-call report**
   - Incidents handled
   - Response times
   - Issues encountered
   - Improvement suggestions

---

## On-Call Schedule

### Rotation Schedule

**Primary On-Call:**
- **Duration:** 1 week (Monday 9am - Monday 9am)
- **Rotation:** Weekly rotation through security team
- **Compensation:** On-call pay + overtime for actual incidents

**Secondary On-Call:**
- **Purpose:** Backup if primary unavailable
- **Duration:** Same week as primary
- **Role:** Respond if primary doesn't acknowledge within SLA

**Schedule:**

| Week | Primary | Secondary | Security Lead |
|------|---------|-----------|---------------|
| Jan 1-7 | Alice | Bob | Carol |
| Jan 8-14 | Bob | Charlie | Carol |
| Jan 15-21 | Charlie | Alice | Carol |
| Jan 22-28 | Alice | Bob | Carol |

### Schedule Management

**Viewing Schedule:**
```bash
# PagerDuty web interface
https://spacetime-vr.pagerduty.com/schedules

# PagerDuty CLI
pd schedule:show --schedule-id=SECURITY_ONCALL
```

**Override Procedures:**

If you need coverage:
1. Find replacement in #security-oncall Slack channel
2. Create override in PagerDuty
3. Notify security lead
4. Document reason

**Vacation Planning:**
- Submit coverage requests 2 weeks in advance
- Team coordinates coverage
- Update PagerDuty schedule

---

## Handoff Procedures

### Handoff Meeting

**Timing:** First hour of new on-call shift

**Agenda (30 minutes):**

1. **Open Incidents** (10 min)
   - Active security incidents
   - Status and next steps
   - Who is involved
   - Expected timeline

2. **Ongoing Investigations** (5 min)
   - Current investigations
   - Evidence collected
   - Next actions needed

3. **Known Issues** (5 min)
   - Recurring alerts (false positives?)
   - System issues affecting security
   - Workarounds in place

4. **Recent Changes** (5 min)
   - Recent deployments
   - Configuration changes
   - New security controls

5. **Context** (5 min)
   - Anything unusual
   - Trends observed
   - Heads up on potential issues

### Handoff Template

```markdown
# On-Call Handoff - [Date]
From: [Outgoing Engineer]
To: [Incoming Engineer]

## Open Incidents
- INC-001: [Brief description, current status, next steps]
- INC-002: [Brief description, current status, next steps]

## Ongoing Investigations
- Investigation into [description]
  - Status: [where it stands]
  - Next: [what needs to be done]

## Known Issues
- [Issue 1]: [workaround if applicable]
- [Issue 2]: [workaround if applicable]

## Recent Changes
- Deployed [feature] on [date] - watch for [potential issues]
- Updated IDS rules on [date]

## Heads Up
- Expecting high traffic this week due to [event]
- [Team] is doing pen test on [date]

## Contact Info
If you have questions: [phone/Slack]

## Dashboard Links
- Security Overview: [URL]
- Threat Intelligence: [URL]
```

---

## Alert Response

### When an Alert Fires

**Step-by-step response:**

```
ALERT RECEIVED
     ↓
1. ACKNOWLEDGE (within SLA)
   - Click acknowledge in PagerDuty
   - Or: Call acknowledge hotline
   - Or: Reply to SMS with "ack"
     ↓
2. ASSESS SEVERITY
   - Read alert details
   - Check dashboard
   - Determine if severity is correct
     ↓
3. INITIAL RESPONSE
   - Follow appropriate playbook
   - Document actions in incident ticket
   - Update Slack #security-incidents
     ↓
4. ESCALATE IF NEEDED
   - P0 → Escalate immediately
   - P1 → Escalate if can't resolve in 1 hour
   - P2 → Page if out of depth
     ↓
5. RESOLVE OR HAND OFF
   - Resolve incident
   - Or: Ensure proper handoff
   - Document everything
```

### Alert Triage

**Questions to answer:**

1. **Is this a real incident?**
   - Check if false positive
   - Review similar past alerts
   - Verify with data

2. **What is the severity?**
   - P0: Active breach, data loss
   - P1: Attack in progress
   - P2: Suspicious activity
   - P3: Informational

3. **What is the scope?**
   - Single IP or multiple?
   - One endpoint or system-wide?
   - Known issue or new threat?

4. **What is the impact?**
   - Service degradation?
   - Data at risk?
   - User impact?

5. **Can I handle this alone?**
   - Do I have the skills?
   - Is it within my authority?
   - Do I need backup?

### Alert Response Checklist

For every alert:

- [ ] Acknowledge alert within SLA
- [ ] Create incident ticket
- [ ] Post in #security-incidents
- [ ] Review alert details in dashboard
- [ ] Follow appropriate playbook
- [ ] Document all actions taken
- [ ] Communicate status updates
- [ ] Escalate if needed
- [ ] Resolve or hand off properly
- [ ] Update documentation

---

## Escalation Procedures

### When to Escalate

**Automatic Escalation:**
- All P0 incidents → Immediate escalation to Security Lead
- P1 incidents >1 hour → Escalate to Security Lead
- Any data breach suspected → Escalate to Security Lead + Legal
- Ransomware detected → Escalate to Security Lead + CTO + Legal

**Judgment Call Escalation:**
- Out of your depth technically
- Need additional permissions/authority
- Require cross-team coordination
- Potential business impact
- Media/PR implications

### Escalation Path

```
On-Call Engineer (Primary)
          ↓
Secondary On-Call (if primary unavailable)
          ↓
Security Lead (P0 immediate, P1 >1hr)
          ↓
Engineering Manager (major incidents)
          ↓
Director of Engineering (business impact)
          ↓
CTO (critical incidents, data breach)
          ↓
CEO (public disclosure, legal action)

PARALLEL ESCALATION:
- Legal team (for any data breach)
- HR (for insider threats)
- PR/Communications (for public incidents)
```

### How to Escalate

**Via PagerDuty:**
```bash
# Escalate current incident
# PagerDuty web interface → Escalate button
# Or: PagerDuty mobile app → Escalate

# Creates alert for next escalation level
```

**Via Phone:**
```
Security Lead: [Phone number in PagerDuty]
After hours: [Emergency contact list]
```

**Via Slack:**
```
#security-incidents
@security-lead [Brief description] - Escalating [Incident ID]
```

**What to communicate:**
1. Incident ID and severity
2. What happened (brief)
3. Current status
4. Why you're escalating
5. What you need

**Example escalation message:**
```
@security-lead

Escalating INC-BF-20240115-001 (P1)

What: Brute force attack from 50+ IPs targeting admin accounts
Status: Banned 50 IPs, attack ongoing from new IPs
Escalating: Need approval for emergency lockdown
Need: Decision on full service lockdown vs. continued mitigation

Dashboard: [link]
Incident ticket: [link]
```

---

## Communication Protocols

### Internal Communication

**Slack Channels:**

- **#security-incidents:** Active incident coordination (public within company)
- **#security-oncall:** On-call coordination, schedule, handoffs
- **#security-alerts:** Automated alert feed
- **#security-team:** General security team discussion
- **#incident-YYYYMMDD-[name]:** Per-incident war room (for P0/P1)

**Incident Updates:**

Post updates in #security-incidents for all P0/P1:
- Initial response (within 15 min)
- Hourly updates for P0
- Every 2 hours for P1
- Major milestones
- Resolution

**Update template:**
```
[P0] INC-001 Update #3 - 14:30 UTC

Status: CONTAINED
Summary: SQL injection attack blocked, attacker IP banned permanently
Impact: No data breach, service running normally
Next: Forensic analysis, root cause investigation
ETA: 2 hours for full incident report

Incident Commander: @alice
Technical Lead: @bob
```

### External Communication

**IMPORTANT:** Do not communicate externally without approval

**Who can communicate:**
- **Customers:** Communications/PR team only
- **Media:** PR team only
- **Regulators:** Legal team only
- **Partners:** Partnerships team + Security Lead

**If you're contacted:**
1. Do not provide information
2. Take contact details
3. Escalate to appropriate team immediately
4. Document the inquiry

### Status Page Updates

**When to update:**
- P0 incidents affecting service availability
- P1 incidents with customer impact
- Any user-visible security measures

**Who updates:**
- Communications team
- Or: Incident Commander with approval

**Template:**
```
[Investigating] We're investigating reports of service issues.
[Update 14:30] Identified security issue, implementing fix.
[Resolved 15:00] Issue resolved, service fully operational.
```

---

## Tools and Access

### Essential Tools

**Monitoring & Alerting:**
- **PagerDuty:** https://spacetime-vr.pagerduty.com
- **Grafana:** http://localhost:3000
- **Prometheus:** http://localhost:9090
- **AlertManager:** http://localhost:9093

**Security Tools:**
- **Security Dashboard:** http://localhost:3000/d/security-overview
- **Threat Intelligence:** http://localhost:3000/d/threat-intelligence
- **API Status:** http://127.0.0.1:8080/status

**Communication:**
- **Slack:** Desktop + mobile app
- **Zoom:** For war rooms
- **Email:** security-team@spacetime-vr.com

**Documentation:**
- **Runbooks:** C:/godot/docs/operations/SECURITY_RUNBOOKS.md
- **Playbooks:** C:/godot/docs/operations/INCIDENT_RESPONSE_PLAYBOOKS.md
- **Confluence:** Internal documentation
- **GitHub:** Code and runbooks

### Quick Access Commands

**Check system status:**
```bash
# Overall security status
curl http://127.0.0.1:8080/admin/security/status | jq

# Active threats
curl http://127.0.0.1:8080/admin/security/threats/active

# Recent incidents
curl http://127.0.0.1:8080/admin/security/incidents?days=1
```

**View metrics:**
```bash
# Authentication metrics
curl http://127.0.0.1:8080/metrics | grep auth

# Threat count
curl http://127.0.0.1:8080/metrics | grep threat
```

**Export data:**
```bash
# Export audit logs
curl http://127.0.0.1:8080/admin/audit/export > audit_$(date +%Y%m%d).jsonl

# Export threat data
curl http://127.0.0.1:8080/admin/security/threats/export > threats_$(date +%Y%m%d).json
```

### Access Verification Checklist

Before your on-call shift:

- [ ] Can access PagerDuty (web + mobile)
- [ ] Can access Grafana dashboards
- [ ] Can SSH/RDP to production systems
- [ ] Can access AWS console
- [ ] Can run admin API commands
- [ ] Can access on-call documentation
- [ ] Can create incidents in ticketing system
- [ ] Can post in Slack channels
- [ ] Have phone charged and with you
- [ ] Have laptop accessible

---

## Common Scenarios

### Scenario 1: False Positive Alert

**Situation:** Alert fires but investigation shows it's not a real threat

**Actions:**
1. Document why it's false positive
2. Silence alert temporarily (with expiration)
3. Create ticket to tune alert
4. Update alerting rules if pattern is clear
5. Communicate in #security-alerts

### Scenario 2: Can't Reproduce Issue

**Situation:** Alert fired but can't see the problem

**Actions:**
1. Check if issue resolved itself
2. Review historical data
3. Check for intermittent issues
4. Document observations
5. Monitor for recurrence
6. Create ticket for investigation

### Scenario 3: Multiple Alerts at Once

**Situation:** Several alerts fire simultaneously

**Actions:**
1. Acknowledge all within SLA
2. Triage by severity (P0 first)
3. Look for common root cause
4. May indicate larger incident
5. Escalate if overwhelmed
6. Request backup from secondary on-call

### Scenario 4: Off-Hours Emergency

**Situation:** Paged at 2am

**Actions:**
1. Wake up, grab coffee
2. Acknowledge alert
3. Remote into VPN
4. Assess severity
5. If P0 and complex → Escalate immediately
6. If manageable → Follow playbook
7. Document everything (your memory at 2am is unreliable)
8. Take comp time next day

### Scenario 5: Uncertain How to Proceed

**Situation:** Not sure what to do next

**Actions:**
1. Don't panic
2. Review playbook again
3. Check similar past incidents
4. Ask in #security-team
5. Call secondary on-call for advice
6. Escalate to Security Lead if stuck >30 min
7. Document your uncertainty (it's okay!)

### Scenario 6: Personal Emergency

**Situation:** Need to hand off during active incident

**Actions:**
1. Notify secondary on-call immediately
2. Brief them on current status
3. Ensure clean handoff
4. Update incident ticket
5. Notify Security Lead
6. Take care of personal matter

---

## Post-Incident Actions

### Immediately After Resolution

**Within 1 hour:**

1. **Update incident ticket**
   - Mark as resolved
   - Document final actions
   - Link to relevant data

2. **Communicate resolution**
   ```
   [RESOLVED] INC-001

   Issue: [Brief description]
   Resolved: [How it was fixed]
   Root cause: [If known]
   Duration: [Time from detection to resolution]
   Impact: [What was affected]

   Full post-mortem: [Link when available]
   ```

3. **Create immediate follow-up tasks**
   - Any urgent fixes needed
   - Temporary workarounds to remove
   - Monitoring to add

### Within 24 Hours

1. **Draft incident summary**
   - Timeline
   - Actions taken
   - Impact assessment
   - Immediate lessons learned

2. **Schedule post-incident review**
   - If P0/P1 → Within 48 hours
   - If P2 → Within 1 week
   - If P3 → Optional

3. **Update runbooks**
   - Did playbook work?
   - What was missing?
   - What would have helped?

### Post-Incident Review (PIR)

**For all P0/P1 incidents:**

Use POST_INCIDENT_REVIEW_TEMPLATE.md

**Invite:**
- On-call engineer (you!)
- Security Lead
- Anyone who responded
- Relevant team leads

**Agenda:**
1. Timeline review (what happened)
2. What went well
3. What didn't go well
4. Action items
5. Runbook updates

**Output:**
- PIR document
- Action item tickets
- Runbook updates
- Training needs identified

---

## Self-Care and Wellness

### Managing On-Call Stress

**It's okay to:**
- Not know everything
- Ask for help
- Escalate when needed
- Take breaks between incidents
- Feel stressed

**It's not okay to:**
- Suffer in silence
- Skip sleep for days
- Ignore SLAs
- Make risky changes without review
- Burn out

### Burnout Prevention

**Signs of burnout:**
- Dreading alerts
- Fatigue even with sleep
- Irritability
- Decreased performance
- Physical symptoms

**If you're burning out:**
1. Talk to manager
2. Request break from rotation
3. Consider therapy/counseling
4. Team can help with coverage

### After Rough On-Call Week

**Recovery:**
- Take comp time
- Don't check Slack obsessively
- Decompress with team
- Share war stories
- Document lessons learned

**Support:**
- Team debriefs
- Manager 1-on-1
- Peer support
- Professional resources

---

## On-Call Best Practices

### Do's

1. **Do acknowledge alerts within SLA**
   - Even if just to say "I see this, investigating"

2. **Do document everything**
   - Your future self will thank you
   - Team needs to know what you did

3. **Do communicate proactively**
   - Status updates
   - When you need help
   - When escalating

4. **Do follow playbooks**
   - They exist for a reason
   - Deviate if needed, but document why

5. **Do ask questions**
   - Better to ask than guess
   - Team is here to help

6. **Do take care of yourself**
   - Sleep
   - Eat
   - Take breaks

### Don'ts

1. **Don't ignore alerts**
   - Acknowledge them
   - Even if false positive

2. **Don't make risky changes alone**
   - Get review for significant changes
   - Especially at 3am

3. **Don't suffer in silence**
   - Ask for help
   - Escalate when needed

4. **Don't skip documentation**
   - Future you needs it
   - Team needs it
   - Legal may need it

5. **Don't panic**
   - Take a breath
   - Review the playbook
   - You've got this

6. **Don't sacrifice health**
   - It's just a job
   - Your health matters more

---

## Appendices

### Appendix A: Contact List

**Primary Contacts:**
- Security Lead: [Phone] [Slack: @security-lead]
- Engineering Manager: [Phone] [Slack: @eng-manager]
- Director Engineering: [Phone] [Slack: @director-eng]
- CTO: [Phone] [PagerDuty escalation only]

**Specialized Contacts:**
- Legal: [Phone] (data breach, compliance)
- HR: [Phone] (insider threats)
- PR/Comms: [Phone] (media, public disclosure)
- IT: [Phone] (infrastructure, access)

**External:**
- Security Vendor: [Support number]
- Cloud Provider: [Support number]
- Law Enforcement: [Non-emergency contact]

### Appendix B: On-Call Survival Kit

**Keep accessible:**
- Laptop (charged)
- Phone (charged)
- VPN credentials
- Password manager
- Backup authentication device
- Coffee/snacks
- This guide (bookmark it!)

### Appendix C: Common Alert Resolution Times

**Historical data** (for planning):

| Alert Type | Typical Resolution | Notes |
|------------|-------------------|-------|
| False positive auth failures | 10 min | Whitelist IP |
| Real brute force | 30 min | Ban IPs, investigate |
| Rate limit violations | 15 min | Usually temporary |
| SQL injection attempt | 2 hours | Full investigation required |
| Privilege escalation | 1 hour | Revoke access, investigate |
| System breach | 4-24 hours | Major incident |

### Appendix D: On-Call Report Template

```markdown
# On-Call Report - [Week Of]
Engineer: [Name]
Duration: [Start] to [End]

## Summary
- Total incidents: X
- P0: X, P1: X, P2: X, P3: X
- Total response time: X hours
- Escalations: X

## Incidents Handled
1. INC-001: [Brief description] - [Resolution time]
2. INC-002: [Brief description] - [Resolution time]

## Trends Observed
- [Any patterns or recurring issues]

## Improvements Suggested
- [Alert tuning needed?]
- [Runbook updates?]
- [Tool improvements?]

## Kudos
- [Anyone who helped during your shift]

## Notes for Next On-Call
- [Anything to be aware of]
```

---

## Document Maintenance

**Last Updated:** 2025-12-02
**Next Review:** 2025-03-02
**Owner:** Security Operations Team

**Feedback:** After each on-call rotation, suggest improvements to this guide.

**Contact:** security-oncall@spacetime-vr.com

---

## You've Got This!

Remember:
- The team has your back
- Playbooks are your friend
- It's okay to escalate
- Document everything
- Ask questions
- Take care of yourself

**Welcome to on-call!**
