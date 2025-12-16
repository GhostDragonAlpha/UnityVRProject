# Development Rules - NO EXCEPTIONS

**Last Updated:** 2025-12-09
**Status:** MANDATORY - ENFORCED - ABSOLUTE

---

## The One Rule

**There is only ONE rule in this project:**

```
EVERY CHANGE MUST PASS AUTOMATED VERIFICATION BEFORE COMMIT
```

**Everything else follows from this rule.**

---

## What "Automated Verification" Means

**Step 1: Automated Checks**
```bash
python scripts/tools/verify_phase.py --phase <current_phase> --auto-fix
```

**Step 2: Manual Testing Protocol (REQUIRED)**
```bash
python scripts/tools/manual_testing_protocol.py --phase <current_phase> --week <week>
```

**BOTH steps are MANDATORY. Automated verification will FAIL if manual testing not completed.**

**Success Criteria:**
- Automated checks exit code: 0
- Manual testing: ALL tests passed
- No failures in reports
- Manual testing results file present
- Total duration: <60 seconds (automated) + manual testing time

**Failure Criteria:**
- Any automated check: FAIL
- Manual testing: INCOMPLETE or ANY test failed
- Any test: FAIL
- Any error: CRITICAL
- Missing manual testing results file

---

## Consequences of Breaking Rules

### If You Skip Verification

**Your changes WILL BE:**
1. Detected by CI/CD
2. Failed in PR review
3. Reverted immediately
4. Flagged as problematic

**You WILL BE:**
1. Asked to re-do the work
2. Required to run verification
3. Blocked from merging
4. Reminded of this document

### If You Commit Without Verification

**The commit WILL BE:**
1. Identified by pre-commit hook (if installed)
2. Rejected by CI/CD pipeline
3. Reverted by maintainers
4. Marked as invalid

**You WILL NEED TO:**
1. Revert the commit
2. Run verification
3. Fix all issues
4. Re-commit with verification

### If You Try To Work Around The System

**Examples of "working around":**
- Commenting out failing tests
- Skipping verification checks
- Manually editing verification reports
- Committing directly to main
- Force-pushing without verification

**Result:**
- **IMMEDIATE REVERT**
- **PR REJECTED**
- **ACCESS REVIEW**

---

## Acceptable Practices

### ✅ GOOD: Standard Workflow

```bash
# 1. Make changes
vim some_file.gd

# 2. Run verification
python scripts/tools/verify_phase.py --phase 0 --auto-fix

# 3. Check exit code
echo $?  # Should be 0

# 4. Commit
git add .
git commit -m "Change description"
```

### ✅ GOOD: Fix-Verify Loop

```bash
# 1. Make changes
# 2. Run verification → FAIL
# 3. Read error report
# 4. Fix issues
# 5. Run verification → PASS
# 6. Commit
```

### ✅ GOOD: Auto-Fix Usage

```bash
# Use auto-fix to resolve common issues
python scripts/tools/verify_phase.py --phase 0 --auto-fix

# Then verify fixes worked
python scripts/tools/verify_phase.py --phase 0
```

### ✅ GOOD: Iterative Development

```bash
# Develop → Verify → Fix → Verify → Commit
while [ exit_code != 0 ]; do
    # Fix issues
    python scripts/tools/verify_phase.py --phase 0
done
git commit
```

---

## Unacceptable Practices

### ❌ BAD: Skip Verification

```bash
# Making changes without verification
vim some_file.gd
git commit -m "Quick fix"  # NO! Missing verification!
```

**Why bad:** Breaks quality assurance, introduces regressions

### ❌ BAD: Commit Failing Tests

```bash
# Committing even though verification failed
python scripts/tools/verify_phase.py --phase 0  # EXIT CODE 1
git commit -m "WIP: will fix later"  # NO!
```

**Why bad:** Breaks main branch, blocks other developers

### ❌ BAD: Comment Out Tests

```gdscript
# Disabling failing test
# func test_feature():
#     assert_true(feature_works())  # NO! Fix the test!
```

**Why bad:** Hides problems, defeats purpose of tests

### ❌ BAD: Manual Report Editing

```bash
# Faking verification results
vim VERIFICATION_REPORT_PHASE_0.md
# Change "FAIL" to "PASS"  # NO! This is fraud!
git commit
```

**Why bad:** Fraud, destroys trust, defeats entire system

### ❌ BAD: Force Push

```bash
# Pushing without verification
git push --force origin main  # NO! NEVER!
```

**Why bad:** Bypasses all checks, breaks everything

---

## Enforcement Mechanisms

### Pre-Commit Hook

**Automatically installed (recommended):**
```bash
# .git/hooks/pre-commit
python scripts/tools/verify_phase.py --phase 0 || exit 1
```

**Prevents commits if verification fails.**

### CI/CD Pipeline

**GitHub Actions runs verification on every PR:**
```yaml
- name: Run Verification
  run: python scripts/tools/verify_phase.py --phase 0

- name: Check Exit Code
  run: exit $?  # Fails if verification failed
```

**PR cannot merge if CI/CD fails.**

### Code Review

**Maintainers check:**
- Verification report included?
- All checks passed?
- Exit code is 0?
- No suspicious changes?

**PR rejected if any answer is "no".**

### Automated Revert

**If bad commit reaches main:**
- CI/CD detects failure
- Automated revert triggered
- Notification sent to author
- Branch protection enforced

---

## Phase-Specific Rules

### Phase 0 (Foundation)

**Required checks:**
- Project config valid
- Addon structure correct
- Godot starts cleanly
- No critical errors

**Command:**
```bash
python scripts/tools/verify_phase.py --phase 0 --auto-fix
```

### Phase 1+ (Future)

**Additional checks (will be added):**
- VR tracking functional
- HTTP API responding
- Performance benchmarks met
- Integration tests passing

**Command:**
```bash
python scripts/tools/verify_phase.py --phase <N> --auto-fix
```

---

## Exception Handling

### "What if verification is broken?"

**If verification tools have bugs:**
1. Fix the verification tools FIRST
2. Verify the fix to verification tools
3. Then continue with your work

**Do NOT skip verification just because it's broken.**

### "What if tests are flaky?"

**If tests fail randomly:**
1. Fix the flaky tests FIRST
2. Make tests deterministic
3. Verify tests are stable
4. Then continue with your work

**Do NOT ignore flaky tests.**

### "What if I need to commit urgently?"

**There is NO urgency that justifies skipping verification:**
- Critical bug? → Fix it, verify it, commit it
- Deadline pressure? → Verify faster, don't skip
- Emergency? → Verification takes 30 seconds

**30 seconds of verification prevents hours of debugging.**

### "What if I'm just experimenting?"

**Use a feature branch:**
```bash
# Experiment on branch
git checkout -b experiment/my-idea

# Make changes, no verification needed YET
# ... experiment ...

# When ready to merge:
python scripts/tools/verify_phase.py --phase 0 --auto-fix

# Only merge if verification passes
git checkout main
git merge experiment/my-idea
```

**Main branch MUST ALWAYS pass verification.**

---

## Red Flags

**Watch for these red flags in PRs:**

🚩 **"Quick fix"** - Usually means unverified
🚩 **"WIP"** - Work in progress shouldn't be in PR
🚩 **"Will fix tests later"** - No, fix tests NOW
🚩 **"Tests are broken anyway"** - Then fix tests FIRST
🚩 **"Just trust me"** - No, we trust verification
🚩 **"Emergency commit"** - 30 seconds isn't too long
🚩 **"Small change"** - Small changes still need verification

**If you see these phrases, REJECT THE PR.**

---

## Quality Metrics

**Project quality is measured by:**

| Metric | Target | Current |
|--------|--------|---------|
| Verification Pass Rate | 100% | TBD |
| Test Coverage | >80% | TBD |
| Critical Errors | 0 | 0 ✅ |
| Broken Main Branch | Never | Never ✅ |
| Reverted Commits | 0 | 0 ✅ |

**These metrics are PUBLIC and TRACKED.**

---

## Developer Accountability

### Good Developer Behavior

**Signs of good developer:**
- ✅ Always runs verification
- ✅ Fixes issues before committing
- ✅ Includes verification reports
- ✅ Writes tests for new features
- ✅ Fixes flaky tests immediately
- ✅ Respects the workflow

**Result:** Trusted, fast PR approvals, respected

### Bad Developer Behavior

**Signs of bad developer:**
- ❌ Skips verification
- ❌ Commits failing tests
- ❌ Ignores CI/CD failures
- ❌ Force pushes
- ❌ Makes excuses
- ❌ Tries to work around system

**Result:** PRs rejected, delayed reviews, untrusted

---

## Philosophy

### Why These Rules Exist

**The automated verification workflow ensures:**
1. **Quality** - Code works before it's committed
2. **Confidence** - Tests prove correctness
3. **Speed** - Fast feedback (30 seconds)
4. **Accountability** - Clear pass/fail criteria
5. **Automation** - No manual checking needed
6. **Scalability** - System grows with project

### The Cost of Skipping Verification

**One unverified commit can:**
- Break the build for everyone
- Block other developers
- Introduce hard-to-find bugs
- Waste hours of debugging time
- Damage team trust
- Delay releases

**30 seconds of verification prevents all of this.**

### The Recursive Advantage

**This system builds on itself:**
- Add feature → Add test → Verification ensures it works
- Add test → Auto-fixer learns from it
- Add check → Future changes validated against it
- System gets SMARTER over time

**This is why we enforce it strictly.**

---

## Summary

**ONE RULE:**
```
EVERY CHANGE MUST PASS AUTOMATED VERIFICATION
```

**ONE COMMAND:**
```bash
python scripts/tools/verify_phase.py --phase <N> --auto-fix
```

**ONE REQUIREMENT:**
```
Exit code: 0
```

**ZERO EXCEPTIONS.**

---

## Acknowledgment

**By contributing to this project, you agree to:**
1. Follow these rules without exception
2. Run verification before every commit
3. Fix all issues before merging
4. Include verification reports in PRs
5. Respect the workflow

**If you cannot agree to these terms, please do not contribute.**

---

**These rules exist for the benefit of everyone.**

**Thank you for maintaining project quality.**

---

**Last Updated:** 2025-12-09
**Enforced:** ALWAYS
**Exceptions:** NEVER
