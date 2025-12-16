# Post-Incident Review (PIR) Template

**SpaceTime VR Project - Security Incident Post-Mortem**

---

## Incident Metadata

**Incident ID:** INC-[TYPE]-[DATE]-[NUMBER]
**Incident Title:** [Descriptive title]
**Severity:** P0 / P1 / P2 / P3
**Date/Time:** [YYYY-MM-DD HH:MM UTC]
**Duration:** [X hours Y minutes]
**Status:** [Resolved / Ongoing / Recurring]

**Report Author:** [Name]
**Report Date:** [YYYY-MM-DD]
**Review Date:** [YYYY-MM-DD] (PIR meeting)
**Distribution:** [Internal / Security Team / Leadership / Public]

---

## Executive Summary

**Purpose:** 2-3 paragraph summary for leadership (non-technical)

[Explain what happened, why it matters, what we did, and what we're doing to prevent it]

**Key Points:**
- **What happened:** [One sentence]
- **Impact:** [Business impact in plain language]
- **Root cause:** [Why it happened]
- **Resolution:** [How it was fixed]
- **Prevention:** [What we're doing to prevent recurrence]

**Metrics:**
- Time to Detection: [X minutes]
- Time to Acknowledgment: [X minutes]
- Time to Containment: [X minutes]
- Time to Resolution: [X hours]
- Customer Impact: [None / Low / Medium / High]
- Data Breach: [Yes / No / Under Investigation]

---

## Incident Timeline

**Note:** All times in UTC

### Detection Phase

| Time | Event | Actor | Details |
|------|-------|-------|---------|
| YYYY-MM-DD HH:MM | Alert fired | System | [Alert name, trigger condition] |
| HH:MM | Alert acknowledged | [Name] | [How acknowledged] |
| HH:MM | Initial assessment | [Name] | [First observations] |

### Response Phase

| Time | Event | Actor | Details |
|------|-------|-------|---------|
| HH:MM | Containment action | [Name] | [What was done] |
| HH:MM | Escalation | [Name] | [Who was paged, why] |
| HH:MM | Additional response | [Name] | [Action taken] |
| HH:MM | War room opened | Team | [Participants] |

### Investigation Phase

| Time | Event | Actor | Details |
|------|-------|-------|---------|
| HH:MM | Evidence collected | [Name] | [What data gathered] |
| HH:MM | Root cause identified | [Name] | [Finding] |
| HH:MM | Scope determined | [Name] | [Impact assessment] |

### Resolution Phase

| Time | Event | Actor | Details |
|------|-------|-------|---------|
| HH:MM | Fix implemented | [Name] | [What was fixed] |
| HH:MM | Fix verified | [Name] | [How verified] |
| HH:MM | Monitoring enabled | [Name] | [What monitoring] |
| HH:MM | Incident closed | [Name] | [Final status] |

### Communication Timeline

| Time | Event | Audience | Channel |
|------|-------|----------|---------|
| HH:MM | Initial notification | Security team | Slack #security-incidents |
| HH:MM | Escalation notice | Leadership | PagerDuty + Phone |
| HH:MM | Status update #1 | Internal | Slack + Email |
| HH:MM | Customer notice | Customers | Email / Status page |
| HH:MM | Resolution notice | All | Slack + Email |

---

## Incident Details

### What Happened

[Detailed technical explanation of the incident]

**Incident Type:** [Brute force / SQL injection / Data breach / System compromise / etc.]

**Attack Vector:** [How did attacker gain access or how did failure occur?]

**Affected Systems:**
- System 1: [Description of impact]
- System 2: [Description of impact]
- System 3: [Description of impact]

**Attacker Profile** (if applicable):
- IP Addresses: [List]
- Geographic Origin: [Country/region]
- Attack Sophistication: [Low / Medium / High]
- Indicators of Compromise: [List IOCs]
- Attribution: [Known group / Unknown / N/A]

### Impact Assessment

**Technical Impact:**
- Systems affected: [List]
- Data accessed: [What data types]
- Data modified: [Yes/No, details]
- Data exfiltrated: [Yes/No/Unknown, volume]
- Service availability: [Uptime percentage during incident]
- System integrity: [Compromised / Intact]

**Business Impact:**
- Customer impact: [Number affected, how affected]
- Revenue impact: [Lost revenue if applicable]
- Reputational impact: [Media coverage, customer perception]
- Compliance impact: [Regulatory requirements triggered]
- Competitive impact: [IP or strategic data lost]

**Severity Justification:**
[Why was this classified as P0/P1/P2/P3?]

---

## Root Cause Analysis

### Five Whys Analysis

1. **Why did the incident occur?**
   [First-level cause]

2. **Why did that happen?**
   [Second-level cause]

3. **Why did that happen?**
   [Third-level cause]

4. **Why did that happen?**
   [Fourth-level cause]

5. **Why did that happen?**
   [Root cause - the fundamental issue]

### Contributing Factors

**Technical Factors:**
- [Factor 1: e.g., Missing input validation]
- [Factor 2: e.g., Weak password policy]
- [Factor 3: e.g., Insufficient monitoring]

**Process Factors:**
- [Factor 1: e.g., No security review in deployment process]
- [Factor 2: e.g., Outdated runbooks]
- [Factor 3: e.g., Unclear escalation path]

**Human Factors:**
- [Factor 1: e.g., Alert fatigue led to delayed response]
- [Factor 2: e.g., Inadequate training]
- [Factor 3: e.g., Communication gaps]

### Detection and Response Analysis

**Detection:**
- **How was it detected?** [Automated alert / User report / Routine check / External notification]
- **Time to detection:** [X minutes from initial attack]
- **Could it have been detected sooner?** [Yes/No, how?]

**Response:**
- **Time to acknowledgment:** [X minutes]
- **Within SLA?** [Yes/No]
- **Time to containment:** [X minutes]
- **Time to resolution:** [X hours]

**Effectiveness:**
- **What worked well?** [List]
- **What didn't work?** [List]
- **What was missing?** [List]

---

## Response Evaluation

### What Went Well

**List positive aspects of the response:**

1. **[Positive aspect 1]**
   - Detail: [What specifically worked well]
   - Why it helped: [Impact on incident resolution]
   - Continue doing: [How to maintain this]

2. **[Positive aspect 2]**
   - Detail: [What specifically worked well]
   - Why it helped: [Impact on incident resolution]
   - Continue doing: [How to maintain this]

3. **[Positive aspect 3]**
   - Detail: [What specifically worked well]
   - Why it helped: [Impact on incident resolution]
   - Continue doing: [How to maintain this]

### What Didn't Go Well

**List areas for improvement:**

1. **[Problem 1]**
   - Detail: [What went wrong]
   - Impact: [How it affected response]
   - Root cause: [Why it went wrong]
   - Action item: [PIR-XXX - Specific fix]

2. **[Problem 2]**
   - Detail: [What went wrong]
   - Impact: [How it affected response]
   - Root cause: [Why it went wrong]
   - Action item: [PIR-XXX - Specific fix]

3. **[Problem 3]**
   - Detail: [What went wrong]
   - Impact: [How it affected response]
   - Root cause: [Why it went wrong]
   - Action item: [PIR-XXX - Specific fix]

### Where We Got Lucky

**List things that could have gone worse:**

1. [Lucky break 1 - e.g., Attacker didn't discover admin credentials]
2. [Lucky break 2 - e.g., Backup was recent and intact]
3. [Lucky break 3 - e.g., Attack occurred during business hours]

**For each lucky break:** What would have happened without it? How do we prevent relying on luck?

---

## Action Items

### Immediate Actions (Completed)

| Action | Owner | Completed | Verification |
|--------|-------|-----------|--------------|
| [Action 1] | [Name] | [Date] | [How verified] |
| [Action 2] | [Name] | [Date] | [How verified] |
| [Action 3] | [Name] | [Date] | [How verified] |

### Short-Term Actions (1-2 weeks)

| ID | Action | Owner | Due Date | Priority | Status |
|----|--------|-------|----------|----------|--------|
| PIR-001 | [Specific action] | [Name] | [Date] | P0 | In Progress |
| PIR-002 | [Specific action] | [Name] | [Date] | P1 | Not Started |
| PIR-003 | [Specific action] | [Name] | [Date] | P1 | Not Started |

### Medium-Term Actions (1-3 months)

| ID | Action | Owner | Due Date | Priority | Status |
|----|--------|-------|----------|----------|--------|
| PIR-004 | [Specific action] | [Name] | [Date] | P2 | Not Started |
| PIR-005 | [Specific action] | [Name] | [Date] | P2 | Not Started |
| PIR-006 | [Specific action] | [Name] | [Date] | P2 | Not Started |

### Long-Term Actions (3+ months)

| ID | Action | Owner | Due Date | Priority | Status |
|----|--------|-------|----------|----------|--------|
| PIR-007 | [Strategic improvement] | [Name] | [Date] | P3 | Not Started |
| PIR-008 | [Infrastructure upgrade] | [Name] | [Date] | P3 | Not Started |
| PIR-009 | [Policy development] | [Name] | [Date] | P3 | Not Started |

---

## Preventive Measures

### Technical Improvements

**Security Controls:**
- [ ] [Control 1: e.g., Add input validation to all API endpoints]
- [ ] [Control 2: e.g., Implement rate limiting on authentication]
- [ ] [Control 3: e.g., Enable audit logging for admin operations]

**Monitoring & Alerting:**
- [ ] [Enhancement 1: e.g., Add alert for unusual data access patterns]
- [ ] [Enhancement 2: e.g., Improve IDS rule for SQL injection]
- [ ] [Enhancement 3: e.g., Dashboard for threat intelligence]

**Infrastructure:**
- [ ] [Change 1: e.g., Enable WAF with OWASP ruleset]
- [ ] [Change 2: e.g., Implement network segmentation]
- [ ] [Change 3: e.g., Deploy DLP solution]

### Process Improvements

**Incident Response:**
- [ ] [Improvement 1: e.g., Update escalation procedure]
- [ ] [Improvement 2: e.g., Add SQL injection playbook section]
- [ ] [Improvement 3: e.g., Create war room checklist]

**Change Management:**
- [ ] [Improvement 1: e.g., Mandatory security review for all changes]
- [ ] [Improvement 2: e.g., Automated security testing in CI/CD]
- [ ] [Improvement 3: e.g., Deployment checklist with security gates]

**Communication:**
- [ ] [Improvement 1: e.g., Clearer notification templates]
- [ ] [Improvement 2: e.g., Defined communication cadence]
- [ ] [Improvement 3: e.g., Stakeholder mapping]

### Training & Awareness

**Security Team:**
- [ ] [Training 1: e.g., Advanced threat hunting techniques]
- [ ] [Training 2: e.g., Forensics and evidence collection]
- [ ] [Training 3: e.g., Incident command training]

**Engineering Team:**
- [ ] [Training 1: e.g., Secure coding workshop]
- [ ] [Training 2: e.g., OWASP Top 10 review]
- [ ] [Training 3: e.g., Threat modeling training]

**All Staff:**
- [ ] [Training 1: e.g., Phishing awareness]
- [ ] [Training 2: e.g., Incident reporting procedures]
- [ ] [Training 3: e.g., Data handling best practices]

---

## Lessons Learned

### Key Takeaways

1. **[Lesson 1]**
   - What we learned: [Detailed explanation]
   - How to apply: [Practical application]
   - Measurable outcome: [How we'll know it worked]

2. **[Lesson 2]**
   - What we learned: [Detailed explanation]
   - How to apply: [Practical application]
   - Measurable outcome: [How we'll know it worked]

3. **[Lesson 3]**
   - What we learned: [Detailed explanation]
   - How to apply: [Practical application]
   - Measurable outcome: [How we'll know it worked]

### Industry Best Practices Applicable

- [Best practice 1 from this incident]
- [Best practice 2 from this incident]
- [Best practice 3 from this incident]

### Runbook Updates

**Documents to update:**
- [ ] SECURITY_RUNBOOKS.md - Section: [specific section]
- [ ] INCIDENT_RESPONSE_PLAYBOOKS.md - Playbook: [specific playbook]
- [ ] ONCALL_GUIDE.md - Section: [specific section]
- [ ] IDS rules configuration
- [ ] Alerting thresholds

**Changes made:** [Link to commits or detailed list]

---

## Evidence and Artifacts

### Evidence Collected

**Logs:**
- Audit logs: [Path/link to exported logs]
- Application logs: [Path/link]
- System logs: [Path/link]
- Network logs: [Path/link]

**Forensic Data:**
- Memory dumps: [Location]
- Disk images: [Location]
- Network captures: [Location]
- Screenshots: [Location]

**Chain of Custody:**
- Collected by: [Name]
- Stored at: [Secure location]
- Access: [Who has access]
- Integrity: [Hash values]

### Supporting Documents

- Incident ticket: [Link]
- Slack transcript: [Export file]
- Email communications: [Export file]
- Customer communications: [Copies]
- Legal notifications: [Copies]

### Indicators of Compromise (IOCs)

**IP Addresses:**
```
203.0.113.42 (Primary attacker)
203.0.113.43 (Secondary)
203.0.113.44 (Secondary)
```

**Domains:**
```
evil.example.com
attacker-c2.bad
```

**File Hashes:**
```
SHA256: [hash value] - [file description]
SHA256: [hash value] - [file description]
```

**Attack Signatures:**
```
[Regex or pattern for IDS]
[Payload sample]
```

**IOC Sharing:**
- [ ] Shared with threat intelligence platforms
- [ ] Added to internal blocklist
- [ ] Reported to law enforcement (if applicable)

---

## Compliance and Legal

### Regulatory Requirements

**Data Breach Notification:**
- Required: [Yes / No / Under review]
- Regulations: [GDPR / HIPAA / CCPA / etc.]
- Notification deadline: [Date]
- Status: [Completed / In progress / Not required]

**Notifications Made:**
- Data Protection Authority: [Yes/No, Date]
- Affected individuals: [Yes/No, Date, Count]
- Law enforcement: [Yes/No, Date, Agency]
- Cyber insurance: [Yes/No, Date]

### Legal Review

- Legal counsel consulted: [Yes/No, Date]
- Litigation risk: [Low / Medium / High]
- Insurance claim filed: [Yes/No, Date]
- External audit required: [Yes/No]

---

## Customer Impact

### Affected Customers

- Total customers affected: [Number]
- Percentage of customer base: [X%]
- Geographic distribution: [Regions]
- Customer segments affected: [Enterprise / SMB / Individual]

### Customer Communication

**Communication sent:**
- Date: [Date]
- Method: [Email / Status page / Direct call]
- Recipients: [All customers / Affected customers]
- Message: [Summary or link]

**Customer response:**
- Inquiries received: [Number]
- Complaints: [Number]
- Churn risk: [Low / Medium / High]
- Compensation offered: [If any]

### Customer Remediation

- [ ] Password reset required
- [ ] Two-factor authentication enabled
- [ ] Credit monitoring offered (if applicable)
- [ ] Service credit provided
- [ ] Enhanced support provided

---

## Financial Impact

### Direct Costs

| Category | Amount | Notes |
|----------|--------|-------|
| Incident response labor | $[amount] | [Hours × rate] |
| External consultants | $[amount] | [Forensics, legal, etc.] |
| System recovery | $[amount] | [Infrastructure, data restore] |
| Customer compensation | $[amount] | [Credits, refunds] |
| Legal fees | $[amount] | [Counsel, compliance] |
| Notification costs | $[amount] | [Mailings, credit monitoring] |
| **Total Direct Costs** | **$[total]** | |

### Indirect Costs

| Category | Estimated Amount | Notes |
|----------|------------------|-------|
| Lost productivity | $[amount] | [Engineering time] |
| Opportunity cost | $[amount] | [Delayed features] |
| Reputational damage | $[amount] | [Estimated] |
| Customer churn | $[amount] | [Projected] |
| **Total Indirect Costs** | **$[total]** | |

### Revenue Impact

- Revenue lost during outage: $[amount]
- Projected customer churn: $[amount over time]
- Sales impact: $[amount from delayed deals]

### Prevention Investment

- Required security improvements: $[amount]
- Training and awareness: $[amount]
- Insurance premium increase: $[amount annually]

---

## Post-Incident Review Meeting

### Attendees

**Required:**
- Incident Commander: [Name]
- Technical Lead: [Name]
- Security Lead: [Name]
- Engineering Manager: [Name]

**Optional:**
- CTO: [Name]
- Legal: [Name]
- HR: [Name] (if insider threat)
- PR: [Name] (if public incident)

### Meeting Notes

**Date:** [YYYY-MM-DD]
**Duration:** [X hours]
**Facilitator:** [Name]
**Note taker:** [Name]

**Discussion highlights:**
- [Key point 1]
- [Key point 2]
- [Key point 3]

**Decisions made:**
- [Decision 1]
- [Decision 2]
- [Decision 3]

**Disagreements/Open questions:**
- [Issue 1 - resolution pending]
- [Issue 2 - resolution pending]

---

## Follow-Up

### 30-Day Review

**Date:** [YYYY-MM-DD]
**Reviewer:** [Name]

**Action items progress:**
- Completed: [X of Y]
- In progress: [X of Y]
- Blocked: [X of Y, reasons]

**Recurring incident check:**
- Similar incidents since: [Yes/No, details]
- Preventive measures effective: [Yes/No/Partial]
- Additional actions needed: [List]

### 90-Day Review

**Date:** [YYYY-MM-DD]
**Reviewer:** [Name]

**Long-term effectiveness:**
- All action items completed: [Yes/No]
- Metrics improved: [Yes/No, details]
- Similar incidents prevented: [Yes/No]
- Culture changes observed: [Yes/No, details]

**Lessons integrated:**
- Runbooks updated: [Yes/No]
- Training completed: [Yes/No]
- Processes changed: [Yes/No]

---

## Approvals

**Reviewed and approved by:**

| Name | Role | Signature | Date |
|------|------|-----------|------|
| [Name] | Incident Commander | | |
| [Name] | Security Lead | | |
| [Name] | Engineering Manager | | |
| [Name] | CTO (if P0/P1) | | |
| [Name] | Legal (if breach) | | |

---

## Appendices

### Appendix A: Detailed Technical Analysis

[Attach detailed technical write-up, code analysis, forensic reports]

### Appendix B: Communication Transcripts

[Attach Slack exports, email threads, customer communications]

### Appendix C: Evidence Files

[List all evidence files, their locations, and access procedures]

### Appendix D: External Reports

[Attach vendor reports, consultant findings, audit results]

---

## Document Control

**Classification:** [Public / Internal / Confidential / Restricted]
**Retention:** [X years per data retention policy]
**Storage:** [Secure repository location]
**Access:** [Who can access this document]

**Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | [Date] | [Name] | Initial draft |
| 1.1 | [Date] | [Name] | Incorporated PIR feedback |
| 2.0 | [Date] | [Name] | Final version |

---

## Contact Information

**For questions about this incident:**
- Incident Commander: [Email]
- Security Lead: [Email]
- Security Team: security-team@spacetime-vr.com

**For related incidents or concerns:**
- Report new incident: security-incidents@spacetime-vr.com
- PagerDuty: https://spacetime-vr.pagerduty.com

---

**END OF POST-INCIDENT REVIEW**

---

## Notes for PIR Author

### Completing This Template

1. **Be thorough but concise** - Provide enough detail for understanding, not a novel
2. **Be honest** - Document what really happened, not what we wish happened
3. **Be blameless** - Focus on systems and processes, not individuals
4. **Be specific** - "Improve monitoring" is not actionable; "Add alert for X with threshold Y" is
5. **Be timely** - Complete within 48 hours of incident resolution

### Blameless Culture

**Remember:**
- Incidents happen because of system failures, not human failures
- Focus on "what" happened, not "who" caused it
- Ask "how did our systems allow this?" not "who messed up?"
- Document learning opportunities, not performance issues
- Support responders, don't criticize them

### Quality Checklist

Before publishing:
- [ ] All sections completed
- [ ] Timeline accurate and complete
- [ ] Root cause clearly identified
- [ ] Action items are specific and assigned
- [ ] Technical accuracy reviewed
- [ ] Legal implications considered
- [ ] Approvals obtained
- [ ] Stored in secure location
- [ ] Access controls set appropriately

---

**Document Last Updated:** 2025-12-02
**Template Owner:** Security Operations Team
**Feedback:** security-ops@spacetime-vr.com
