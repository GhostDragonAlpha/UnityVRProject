# Production Readiness Quick Start Guide

**For teams who need to validate production readiness ASAP**

---

## TL;DR - 3 Commands to Validate

```bash
# 1. Run automated validation (2 hours)
cd C:/godot/tests/production_readiness
python automated_validation.py --verbose

# 2. Check the results
cat validation-reports/latest.json | grep "decision"

# 3. Review issues
cat C:/godot/docs/production_readiness/KNOWN_ISSUES.md
```

**If decision is "GO" and 0 critical issues → You're ready**
**If decision is "NO-GO" → Fix blocking issues and re-run**

---

## 5-Minute Setup

### 1. Prerequisites

- ✅ Godot running with debug services
- ✅ Python 3.8+ installed
- ✅ Virtual environment activated (optional)
- ✅ VR headset available (for VR tests)

### 2. Start Godot with Debug Services

```bash
cd C:/godot
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

**IMPORTANT:** Must run in GUI mode, NOT headless!

### 3. Verify Services Running

```bash
curl http://127.0.0.1:8080/status
```

Expected: `{"overall_ready": true, ...}`

### 4. Install Python Dependencies

```bash
cd tests
pip install -r requirements.txt
```

---

## 30-Minute Quick Validation

### Step 1: Run Critical Checks Only (10 min)

```bash
cd tests/production_readiness
python automated_validation.py --critical-only
```

**What it checks:**
- Core engine systems
- Security vulnerabilities
- VR performance (basic)
- Authentication
- Database connectivity

**Pass criteria:** 100% critical checks must pass

---

### Step 2: Manual Security Check (10 min)

Try to break security (you should fail):

```bash
# Try accessing protected endpoint without auth
curl -X POST http://127.0.0.1:8080/execute/reload

# Expected: 401 Unauthorized or 403 Forbidden

# Try SQL injection (should be blocked)
curl -X POST http://127.0.0.1:8080/test -d '{"input": "1\' OR \'1\'=\'1"}'

# Expected: Input validation error

# Try rate limiting bypass
for i in {1..200}; do curl http://127.0.0.1:8080/status; done

# Expected: 429 Too Many Requests after ~100-150 requests
```

**Pass criteria:** All attacks fail

---

### Step 3: Quick VR Performance Test (10 min)

**Requires VR headset!**

1. Put on headset
2. Run for 10 minutes
3. Check FPS display (should show 90+)
4. Watch for dropped frames (should be 0)

**Pass criteria:** Consistent 90+ FPS, no drops

---

## 2-Hour Full Validation

### Phase 1: Automated (90 min)

```bash
python automated_validation.py --verbose --report-dir ./validation-reports
```

Checks 240+ items across:
- Functionality (50 checks)
- Security (60 checks)
- Performance (30 checks)
- Reliability (40 checks)
- Operations (35 checks)
- Compliance (25 checks)

### Phase 2: Review Results (30 min)

```bash
# View latest report
cat validation-reports/latest.json

# Check decision
cat validation-reports/latest.json | grep -A5 "go_no_go"

# View failures
cat validation-reports/latest.json | grep -B2 "\"status\": \"fail\""
```

---

## Understanding Results

### Report Structure

```json
{
  "timestamp": "2025-12-02T10:00:00",
  "summary": {
    "total_checks": 240,
    "passed": 220,
    "failed": 5,
    "warned": 10,
    "skipped": 5,
    "pass_rate": 91.7
  },
  "go_no_go": {
    "decision": "GO / NO-GO / CONDITIONAL GO",
    "criteria": {
      "critical": {"required": "100%", "actual": "100%", "met": true},
      "high": {"required": "90%+", "actual": "95%", "met": true},
      "medium": {"required": "80%+", "actual": "85%", "met": true}
    },
    "blocking_issues": []
  }
}
```

### Decision Interpretation

**"GO"** → All criteria met, ready for production
**"NO-GO"** → Blocking issues exist, must fix
**"CONDITIONAL GO"** → Minor issues, deploy with mitigations

---

## Common Quick Fixes

### Issue: Services not connecting

```bash
# Restart Godot with debug flags
./restart_godot_with_debug.bat  # Windows
```

### Issue: VR not initializing

```bash
# Check OpenXR runtime
curl http://127.0.0.1:8080/vr/status
```

### Issue: Rate limiting not working

- Check if RateLimiter system initialized
- Verify configuration in project settings
- Test manually with rapid requests

---

## Critical Checks Summary

**MUST PASS (0 failures allowed):**

| Check | How to Verify | Fix If Failed |
|-------|---------------|---------------|
| Engine initialized | `curl /status` shows ready | Restart Godot |
| Auth enforced | `/reload` without token = 401 | Check TokenManager |
| VR 90+ FPS | Headset display shows FPS | See VR_OPTIMIZATION.md |
| No security vulns | All 35 vulns fixed | See VULNERABILITIES.md |
| Database connected | `curl /health` shows DB ok | Check connection string |
| Backup working | Run manual backup test | Fix backup config |
| DR tested | Run DR drill | Update DR plan |
| Load tested | 10K concurrent users | Scale infrastructure |

---

## When to Skip Validation

**NEVER skip for:**
- Production deployment
- Public beta release
- Major version release

**Can skip for:**
- Development builds
- Internal testing
- Prototype demos

---

## Emergency Fast-Track (When You're Out of Time)

**Absolute minimum for production:**

1. ✅ All 35 security vulnerabilities fixed
2. ✅ Authentication enforced
3. ✅ VR maintains 90+ FPS
4. ✅ Backup system working
5. ✅ No critical known issues

**If these 5 pass:** Conditional GO possible
**If any fail:** NO-GO, no exceptions

---

## Next Steps After Validation

### If GO

1. Complete PRODUCTION_READINESS_REPORT.md
2. Get sign-offs from all leads
3. Schedule deployment
4. Prepare monitoring
5. Brief oncall team

### If NO-GO

1. Document all failures in KNOWN_ISSUES.md
2. Assign owners to each issue
3. Set remediation timeline
4. Schedule re-validation
5. Communicate delay

### If Conditional GO

1. Document mitigations for each issue
2. Get approval from CTO
3. Deploy with rollback plan ready
4. 24/7 monitoring first week
5. Fix issues in Sprint 1

---

## Help & Support

**Validation fails and you don't know why?**

1. Check logs: `cat validation-reports/latest.json`
2. Search for specific check ID (e.g., "FUNC-001")
3. Review error message and details
4. Consult relevant documentation:
   - Security: `docs/security/`
   - VR: `docs/VR_OPTIMIZATION.md`
   - Performance: `docs/performance/`

**Still stuck?**

Contact:
- Engineering Lead (technical issues)
- Security Lead (security issues)
- QA Lead (validation process)

---

## Cheat Sheet

```bash
# Quick critical validation
python automated_validation.py --critical-only

# Full validation
python automated_validation.py --verbose

# Check results
cat validation-reports/latest.json | jq '.go_no_go.decision'

# View failures only
cat validation-reports/latest.json | jq '.checks[] | select(.status == "fail")'

# Count by status
cat validation-reports/latest.json | jq '.summary'

# View blocking issues
cat validation-reports/latest.json | jq '.go_no_go.blocking_issues'
```

---

**Time to Production:** 2-4 weeks recommended
**Minimum Time:** 1 week (if everything passes first try)
**Realistic Time:** 4-8 weeks (first production deployment)

---

**Remember:** Better to delay launch than deploy broken code.
**Security and VR performance are non-negotiable.**

---

**Document Version:** 1.0
**Last Updated:** 2025-12-02
**For:** Engineering, QA, Security Teams
