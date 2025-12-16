# Rollback Decision Tree - SpaceTime VR

Quick decision-making guide for determining when and how to rollback production deployments.

## Quick Decision Flowchart

```
╔════════════════════════════════════════════════════════════════════╗
║                    PRODUCTION ISSUE DETECTED                       ║
╚════════════════════════════════════════════════════════════════════╝
                              │
                              ▼
                    ┌─────────────────────┐
                    │   Is service DOWN?  │
                    └─────────┬───────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                   YES                 NO
                    │                   │
                    ▼                   ▼
        ┌───────────────────┐   ┌──────────────────┐
        │ Data corruption?  │   │ Error rate > 10%?│
        └────────┬──────────┘   └────────┬─────────┘
                 │                       │
        ┌────────┴────────┐     ┌────────┴────────┐
       YES               NO     YES               NO
        │                 │      │                 │
        ▼                 ▼      ▼                 ▼
    ╔═══════╗         ╔═══════╗ ╔═══════╗    ┌──────────────┐
    ║LEVEL 3║         ║LEVEL 1║ ║LEVEL 1║    │Response > 5s?│
    ╚═══════╝         ╚═══════╝ ╚═══════╝    └──────┬───────┘
    (< 30min)         (< 5min)  (< 5min)            │
                                              ┌──────┴──────┐
                                             YES           NO
                                              │             │
                                              ▼             ▼
                                          ╔═══════╗    ┌────────┐
                                          ║LEVEL 1║    │Monitor │
                                          ╚═══════╝    │& Watch │
                                          (< 5min)     └────────┘
```

## Decision Matrix

Use this table for quick decisions:

| Condition | Severity | Immediate Action | Rollback Level | Max Time |
|-----------|----------|------------------|----------------|----------|
| **Complete Service Down** | P1 | Rollback NOW | Level 1 or 3 | < 5 min |
| **Data Corruption Detected** | P1 | Stop & Rollback | Level 3 | < 30 min |
| **Security Breach** | P1 | Isolate & Investigate | Level 3 (after security clearance) | Varies |
| **Database Failure** | P1 | Rollback NOW | Level 2 or 3 | < 15 min |
| **Error Rate > 50%** | P1 | Rollback NOW | Level 1 | < 5 min |
| **Error Rate 10-50%** | P2 | Rollback if not fixed in 5min | Level 1 or 2 | < 15 min |
| **Response Time > 5s** | P2 | Investigate then rollback | Level 1 | < 5 min |
| **Cache Failure** | P2-P3 | Restart, then rollback | Level 1 | < 5 min |
| **Error Rate 5-10%** | P3 | Monitor, rollback if worsens | Level 1 | < 5 min |
| **Response Time 2-5s** | P3 | Monitor 15min, then decide | Level 1 | < 5 min |
| **Minor UI Issues** | P4 | Log, fix forward | None | N/A |
| **Non-user-facing errors** | P4 | Monitor, fix forward | None | N/A |

## Detailed Decision Process

### Step 1: Initial Assessment (30 seconds)

Ask yourself these questions:

#### 1.1 Is the service accessible?

```bash
curl -I http://localhost:8080/health
```

- **502/503/504 errors** → Service is DOWN → Go to [Service Down](#service-down-decision)
- **Slow response (>5s)** → Performance issue → Go to [Performance Degradation](#performance-degradation-decision)
- **200 OK** → Service up → Continue to 1.2

#### 1.2 Are users affected?

```bash
# Check error rate
curl 'http://localhost:9090/api/v1/query?query=rate(http_requests_total{status=~"5.."}[5m])'
```

- **Error rate > 10%** → Users significantly affected → Go to [High Error Rate](#high-error-rate-decision)
- **Error rate < 10%** → Limited impact → Continue to 1.3

#### 1.3 Is data integrity at risk?

```bash
# Check for corruption markers
docker-compose exec godot test -f /data/corruption_detected

# Check database integrity
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "SELECT 1"
```

- **Corruption detected** → Data at risk → Go to [Data Corruption](#data-corruption-decision)
- **Database errors** → Data at risk → Go to [Database Issues](#database-issues-decision)
- **No data issues** → Continue to 1.4

#### 1.4 Is this a security issue?

```bash
# Check for security alerts
docker-compose logs | grep -i "security\|breach\|unauthorized\|malicious"
```

- **Security alerts** → Security incident → Go to [Security Breach](#security-breach-decision)
- **No security issues** → Continue to [Performance Degradation](#performance-degradation-decision)

---

## Service Down Decision

**Severity: P1 (Critical)**

### Decision Path

```
Service is DOWN
      │
      ▼
  ┌─────────────────────────┐
  │ When did it go down?    │
  └──────────┬──────────────┘
             │
   ┌─────────┴──────────┐
   │                    │
During              After
Deployment          Deployment
   │                    │
   ▼                    ▼
LEVEL 1            Try restart first
Quick              If fails → LEVEL 2
Rollback           If data corrupt → LEVEL 3
```

### Action Plan

#### If down DURING deployment:

```bash
# Immediate Level 1 rollback
bash deploy/rollback/rollback.sh --quick

# This should take < 5 minutes
```

**Why Level 1?**
- Deployment likely introduced the bug
- Previous version was working
- Quick traffic switch resolves issue

#### If down AFTER deployment (running for a while):

```bash
# Step 1: Try quick restart (1 minute)
docker-compose restart godot

# Step 2: Check if it comes up
sleep 30
curl http://localhost:8080/health

# Step 3: If still down, check why
docker-compose logs --tail=100 godot

# Step 4: Make decision:
# - Simple issue (config, resources) → Fix and restart
# - Complex issue → Level 2 rollback
# - Data corruption → Level 3 rollback
```

### Time-Based Decision

```
Time since down | Action
----------------|------------------------------------------
< 2 minutes     | Try restart, then Level 1 if fails
2-5 minutes     | Level 1 rollback
> 5 minutes     | Level 2 rollback (more investigation needed)
```

---

## High Error Rate Decision

**Severity: P1-P2 (Critical to High)**

### Decision Path

```
Error Rate Detected
      │
      ▼
  ┌──────────────────┐
  │ Error rate > 50%?│
  └────────┬─────────┘
           │
    ┌──────┴──────┐
   YES           NO
    │             │
    ▼             ▼
IMMEDIATE     Monitor for 5 min
Level 1            │
Rollback      ┌────┴────┐
              │         │
         Improving  Stable/Worse
              │         │
              ▼         ▼
          Continue   LEVEL 1
          Monitoring Rollback
```

### Action Plan

#### Error Rate > 50%

```bash
# IMMEDIATE ROLLBACK
bash deploy/rollback/rollback.sh --quick

# Don't wait - users are significantly impacted
```

#### Error Rate 10-50%

```bash
# Set 5-minute timer
echo "Monitoring for 5 minutes..."
START_TIME=$(date +%s)

# Monitor error rate every 30 seconds
while [ $(($(date +%s) - START_TIME)) -lt 300 ]; do
  ERROR_RATE=$(curl -s 'http://localhost:9090/api/v1/query?query=rate(http_requests_total{status=~"5.."}[1m])' | jq -r '.data.result[0].value[1]')
  echo "Error rate: $ERROR_RATE"
  sleep 30
done

# Decision after 5 minutes:
# If error rate decreased → Continue monitoring
# If error rate stable or increased → ROLLBACK
```

#### Error Rate 5-10%

```bash
# Monitor for 15 minutes
# Log issue for investigation
# If rate increases → Prepare for rollback
# If rate decreases → Continue monitoring
# If rate stable → Consider rollback at end of 15min
```

### Error Type Consideration

Not all errors are equal. Check error types:

```bash
# Get error breakdown
docker-compose logs --tail=1000 | grep -i error | sort | uniq -c | sort -rn | head -10
```

**Critical errors (rollback immediately):**
- Database connection failures
- Out of memory errors
- Segmentation faults
- Authentication system down
- Payment processing failures

**Medium errors (monitor then rollback):**
- Timeouts
- Third-party API failures
- Cache misses
- Non-critical feature failures

**Low errors (fix forward):**
- Validation errors (user input)
- Not found errors (expected)
- Rate limiting errors
- Minor UI glitches

---

## Performance Degradation Decision

**Severity: P2-P3 (High to Medium)**

### Decision Path

```
Slow Performance
      │
      ▼
  ┌─────────────────────┐
  │ Response time > 5s? │
  └──────────┬──────────┘
             │
      ┌──────┴──────┐
     YES           NO
      │             │
      ▼             ▼
  Monitor 5min   Monitor 15min
      │             │
  ┌───┴───┐     ┌───┴───┐
Better  Worse Better  Worse
  │       │       │       │
  ▼       ▼       ▼       ▼
Continue LEVEL1 Continue Consider
Monitor Rollback Monitor  Rollback
```

### Action Plan

#### Response Time > 5s (Severe)

```bash
# Check what's slow
docker stats --no-stream

# Check for resource issues
df -h  # Disk
free -h  # Memory

# Decision tree:
if [[ $(df / | tail -1 | awk '{print $5}' | sed 's/%//') -gt 90 ]]; then
  echo "Disk full - cleaning up"
  docker system prune -af
  # Then restart services
elif [[ HIGH_MEMORY_USAGE ]]; then
  echo "Memory issue - restart heavy service"
  docker-compose restart godot
else
  echo "Performance issue from deployment"
  # Monitor for 5 minutes
  # If doesn't improve → Level 1 rollback
fi
```

#### Response Time 2-5s (Moderate)

```bash
# Monitor for 15 minutes
# Check if performance improves (cache warming, etc.)
# If performance doesn't improve → Consider rollback
# If getting worse → Prepare for rollback
```

#### Response Time < 2s (Acceptable)

```bash
# Continue monitoring
# Log for investigation
# Fix in next deployment
```

---

## Data Corruption Decision

**Severity: P1 (Critical)**

### Decision Path

```
Data Corruption Detected
      │
      ▼
STOP ALL SERVICES IMMEDIATELY
      │
      ▼
  ┌──────────────────────────┐
  │ Extent of corruption?    │
  └────────┬─────────────────┘
           │
    ┌──────┴──────┐
   Minor        Major
  (Single      (Multiple
   table)       tables)
    │              │
    ▼              ▼
 LEVEL 2        LEVEL 3
 Full          Point-in-Time
 Rollback      Recovery
```

### Action Plan

```bash
# IMMEDIATE SHUTDOWN
docker-compose down

echo "⚠️  DATA CORRUPTION DETECTED - ALL SERVICES STOPPED"
echo "Do NOT restart until recovery complete"

# Assess extent
docker run --rm -v spacetime_godot-data:/data alpine ls -la /data/

# Create forensic snapshot
docker run --rm \
  -v spacetime_godot-data:/data \
  -v /tmp:/backup \
  alpine tar czf /backup/corrupt-$(date +%Y%m%d-%H%M%S).tar.gz /data

# Decision:
# - Single table/file corrupt → Try Level 2 (database rollback)
# - Multiple tables/files → Level 3 (full restore)
# - Unknown extent → Level 3 (safest)

# Execute appropriate recovery
bash deploy/rollback/rollback.sh --level 3 --target <clean-backup>
```

### Data Loss Considerations

```
Backup Age | Acceptable Data Loss?
-----------|----------------------------------------------------
< 1 hour   | Usually acceptable (recent backup)
1-6 hours  | Check with team - what transactions will be lost?
6-24 hours | Significant loss - notify stakeholders
> 24 hours | Major loss - escalate to management
```

---

## Database Issues Decision

**Severity: P1-P2 (Critical to High)**

### Decision Path

```
Database Issue
      │
      ▼
  ┌─────────────────────┐
  │ Database accessible?│
  └──────────┬──────────┘
             │
      ┌──────┴──────┐
     YES           NO
      │             │
      ▼             ▼
  Slow/Errors   Won't start
      │             │
      ▼             ▼
  Try restart   LEVEL 2 or 3
  Then LEVEL 2  Rollback
```

### Action Plan

#### Database won't start

```bash
# Try restart
docker-compose restart postgres
sleep 30

# Check if started
docker-compose exec postgres pg_isready

# If still not starting:
# → Check logs for corruption
# → If corruption → Level 3
# → If config issue → Level 2
# → If unknown → Level 2 (safer)
```

#### Database slow/errors

```bash
# Check connections
docker-compose exec postgres psql -U spacetime -d spacetime_db -c "
  SELECT COUNT(*) FROM pg_stat_activity
"

# If too many connections → Restart application
# If slow queries → Level 2 rollback (likely new deployment causing issue)
# If errors → Check error type, likely Level 2 rollback
```

---

## Security Breach Decision

**Severity: P1 (Critical)**

### Decision Path

```
Security Breach Detected
      │
      ▼
IMMEDIATE ISOLATION
      │
      ▼
DO NOT ROLLBACK YET
      │
      ▼
  Preserve Evidence
      │
      ▼
  Notify Security Team
      │
      ▼
  Wait for Security Clearance
      │
      ▼
  Clean Recovery (Level 3)
```

### Action Plan

```bash
# STEP 1: ISOLATE (Do this first!)
docker-compose down
sudo iptables -A INPUT -p tcp --dport 80 -j DROP
sudo iptables -A INPUT -p tcp --dport 443 -j DROP

# STEP 2: PRESERVE EVIDENCE
docker commit spacetime-godot forensic-$(date +%Y%m%d-%H%M%S)
docker-compose logs > /tmp/incident-logs-$(date +%Y%m%d-%H%M%S).log

# STEP 3: NOTIFY
# Call security team
# Email security@company.com
# Post in #security-incidents

# STEP 4: DO NOT PROCEED WITHOUT SECURITY TEAM APPROVAL

# STEP 5: After clearance - Clean recovery
bash deploy/rollback/rollback.sh --level 3 --target <pre-breach-backup>
```

**⚠️ CRITICAL: Do NOT rollback immediately - you may destroy forensic evidence!**

---

## Rollback Level Selection

### When to use Level 1 (Quick Rollback)

**Use Level 1 when:**
- ✅ Application crashed or won't start
- ✅ High error rate (> 10%)
- ✅ Performance degradation
- ✅ Issue appeared during/right after deployment
- ✅ Previous version was stable
- ✅ NO data corruption
- ✅ NO database issues

**Time:** < 5 minutes
**Risk:** Very low (just traffic switch)

```bash
bash deploy/rollback/rollback.sh --quick
```

### When to use Level 2 (Full Rollback)

**Use Level 2 when:**
- ✅ Level 1 failed or not applicable
- ✅ Database migration issues
- ✅ Configuration errors
- ✅ Multiple services affected
- ✅ Data consistent but schema issues
- ✅ Need to rollback database

**Time:** < 15 minutes
**Risk:** Low (automated migration rollback)

```bash
bash deploy/rollback/rollback.sh --level 2 --target <backup-id>
```

### When to use Level 3 (Point-in-Time Recovery)

**Use Level 3 when:**
- ✅ Data corruption detected
- ✅ Level 2 failed
- ✅ Database corruption
- ✅ Security breach (after security clearance)
- ✅ Unknown data integrity issues
- ✅ Cascading failures with data impact

**Time:** < 30 minutes
**Risk:** Medium (data loss to backup point)

```bash
bash deploy/rollback/rollback.sh --level 3 --target <clean-backup>
```

---

## Time-Based Decision Rules

### Rule 1: The 2-Minute Rule

If service is down for 2+ minutes and you don't know why:
→ **ROLLBACK (Level 1)**

Don't spend 15 minutes investigating while users are down.
Rollback first, investigate after.

### Rule 2: The 5-Minute Rule

If error rate hasn't improved in 5 minutes:
→ **ROLLBACK (Level 1 or 2)**

If it's not getting better on its own, it won't.

### Rule 3: The 15-Minute Rule

If performance hasn't improved in 15 minutes:
→ **Consider ROLLBACK (Level 1)**

Performance issues rarely resolve themselves.

### Rule 4: The Corruption Rule

If data corruption is **suspected**:
→ **STOP immediately, investigate, then ROLLBACK (Level 3)**

Never risk more data corruption.

### Rule 5: The Security Rule

If security breach is **detected**:
→ **ISOLATE immediately, DO NOT ROLLBACK until security team approves**

Preserve evidence first.

---

## Communication Templates

### For P1 (Critical) Incidents

```
SUBJECT: [P1] Production Down - Rollback in Progress

Status: CRITICAL - Service is DOWN
Action: Rollback Level [1/2/3] initiated at [TIME]
ETA: Service recovery in [X] minutes
Impact: [Brief description]
Next Update: In [X] minutes

Team: [Your name]
```

### For P2 (High) Incidents

```
SUBJECT: [P2] Production Degraded - Monitoring/Rollback

Status: HIGH - Service degraded
Error Rate: [X]%
Response Time: [X]s
Action: [Monitoring for 5min / Rolling back]
Impact: [Brief description]

Team: [Your name]
```

### For Rollback Completion

```
SUBJECT: [RESOLVED] Rollback Complete - Service Restored

Status: RESOLVED
Rollback Level: [1/2/3]
Duration: [X] minutes downtime
Service Status: All systems healthy
Data Loss: [None / Details]

Root Cause: Under investigation
Next Steps: [Brief next steps]

Team: [Your name]
```

---

## Checklist

### Pre-Rollback Checklist

- [ ] Severity assessed (P1/P2/P3/P4)
- [ ] Impact understood (users, data, systems)
- [ ] Rollback level selected (1/2/3)
- [ ] Backup target identified (for Level 2/3)
- [ ] Team notified (for P1/P2)
- [ ] Evidence preserved (for security incidents)
- [ ] Ready to execute

### During Rollback Checklist

- [ ] Rollback command executed
- [ ] Progress monitored
- [ ] No unexpected errors
- [ ] Services starting correctly
- [ ] Health checks passing

### Post-Rollback Checklist

- [ ] Services healthy
- [ ] Smoke tests passing
- [ ] Error rate normal
- [ ] Response time normal
- [ ] Data integrity verified
- [ ] Team notified of completion
- [ ] Monitoring for 15+ minutes
- [ ] Incident report created
- [ ] Post-mortem scheduled

---

## Quick Command Reference

```bash
# Check service health
curl http://localhost:8080/status | jq

# Check error rate
curl 'http://localhost:9090/api/v1/query?query=rate(http_requests_total{status=~"5.."}[5m])'

# Check response time
curl 'http://localhost:9090/api/v1/query?query=histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))'

# Check container status
docker-compose ps

# Check logs
docker-compose logs --tail=100

# Quick rollback
bash deploy/rollback/rollback.sh --quick

# Level 2 rollback
bash deploy/rollback/rollback.sh --level 2 --target <backup-id>

# Level 3 rollback
bash deploy/rollback/rollback.sh --level 3 --target <backup-id>

# List backups
bash deploy/rollback/rollback.sh --list

# Validate rollback
bash deploy/rollback/validate_rollback.sh

# Smoke tests
bash deploy/smoke_tests.sh
```

---

## Decision Tree Summary

```
START
  │
  ├─ Service DOWN? ───YES──→ LEVEL 1 (or LEVEL 3 if data corrupt)
  │                             (< 5 min)
  ├─ Error Rate > 10%? ───YES──→ Monitor 5min → LEVEL 1
  │                                 (< 5 min)
  ├─ Response > 5s? ───YES──→ Monitor 5min → LEVEL 1
  │                               (< 5 min)
  ├─ Data Corrupt? ───YES──→ STOP → LEVEL 3
  │                             (< 30 min)
  ├─ Database Down? ───YES──→ LEVEL 2 or LEVEL 3
  │                              (< 15-30 min)
  ├─ Security Breach? ───YES──→ ISOLATE → Wait for Security → LEVEL 3
  │                                (Varies)
  └─ Minor Issue? ───YES──→ MONITOR & FIX FORWARD
```

**Remember: When in doubt, rollback. It's better to be safe than sorry.**

---

**Document Version:** 1.0
**Last Updated:** 2025-12-02
**Maintained By:** Operations Team
**Review Schedule:** After each incident
