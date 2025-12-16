# Contributing to SpaceTime

**Last Updated:** 2025-12-09
**Status:** MANDATORY GUIDELINES - NO EXCEPTIONS

---

## 🚨 READ THIS FIRST 🚨

**This project has STRICT development rules. You MUST follow them.**

There is **ONE WAY** to develop in this project:
1. Make changes
2. Run automated verification
3. Fix any issues
4. Repeat until verification passes
5. Commit ONLY after verification passes

**If you don't follow this workflow, your pull request WILL BE REJECTED.**

---

## The ONLY Development Workflow

### After EVERY Change

**You MUST run:**
```bash
python scripts/tools/verify_phase.py --phase <current_phase> --auto-fix
```

**Replace `<current_phase>` with:**
- `0` - If working on Phase 0 (Foundation)
- `1` - If working on Phase 1 (VR Foundation)
- `2` - If working on Phase 2 (Physics)
- etc.

**Example:**
```bash
# Phase 0 (current)
python scripts/tools/verify_phase.py --phase 0 --auto-fix
```

### What This Does

The verification tool:
1. ✅ Validates project.godot configuration
2. ✅ Verifies all addon structures
3. ✅ Restarts Godot with output capture
4. ✅ Checks for compilation/runtime errors
5. ✅ Runs all GdUnit4 tests
6. ✅ Auto-fixes common issues
7. ✅ Generates comprehensive report

**Duration:** 15-30 seconds

### Exit Codes

| Code | Meaning | What To Do |
|------|---------|------------|
| 0 | All checks passed | ✅ Proceed with commit |
| 1 | Failures detected | ❌ Fix issues, re-run verification |
| 2 | Auto-fixes applied | ⚠️ Re-run verification to confirm |

### Success Criteria

**You may ONLY commit when:**
- ✅ Verification returns exit code 0
- ✅ All checks show PASS in report
- ✅ `VERIFICATION_REPORT_PHASE_<N>.md` shows no failures
- ✅ No critical errors in Godot logs

---

## Pull Request Requirements

### Before Submitting PR

**Your PR MUST include:**
1. ✅ Verification report: `VERIFICATION_REPORT_PHASE_<N>.md`
2. ✅ JSON results: `verification_results_phase_<N>.json`
3. ✅ All checks passing (exit code 0)
4. ✅ No compilation errors
5. ✅ All tests passing

**Your PR will be AUTOMATICALLY REJECTED if:**
- ❌ No verification report included
- ❌ Any checks failing
- ❌ Tests not passing
- ❌ Verification not run

### PR Template

**Use this template for your PR description:**

```markdown
## Summary
[Brief description of changes]

## Verification Results
- **Phase:** [0/1/2/etc.]
- **Exit Code:** [0/1/2]
- **Duration:** [XX seconds]
- **All Checks:** [PASS/FAIL]

## Verification Report
[Paste content of VERIFICATION_REPORT_PHASE_<N>.md]

## Changes Made
- [List changes]

## Tests Added/Modified
- [List tests]

## Checklist
- [ ] Ran automated verification
- [ ] All checks passing (exit code 0)
- [ ] Verification report included
- [ ] Tests added for new features
- [ ] Documentation updated
```

---

## Development Rules

### Rule 1: ALWAYS Verify Before Commit

**NO EXCEPTIONS.**

```bash
# Before git commit
python scripts/tools/verify_phase.py --phase 0 --auto-fix

# Only commit if exit code is 0
git add .
git commit -m "Your message"
```

### Rule 2: NEVER Skip Tests

**If a test fails, you MUST fix it.**

- ❌ Don't comment out failing tests
- ❌ Don't skip test execution
- ❌ Don't commit with failing tests
- ✅ Fix the code or fix the test

### Rule 3: ALWAYS Auto-Fix When Possible

**Use `--auto-fix` flag:**
```bash
python scripts/tools/verify_phase.py --phase 0 --auto-fix
```

**Common auto-fixes:**
- Nested addon structure → Flattened automatically
- Invalid autoloads → Removed automatically
- Missing plugin.cfg → Reported with fix instructions

### Rule 4: ALWAYS Include Verification Report

**Every commit/PR MUST have:**
- Verification report showing all checks passed
- JSON results for machine parsing
- Clear exit code (must be 0)

### Rule 5: NEVER Commit Unverified Changes

**Unverified changes WILL BE REVERTED.**

**No valid excuses:**
- ❌ "It's just a small change" - Still verify
- ❌ "I'll fix it later" - Fix it NOW
- ❌ "Tests are broken" - Fix tests FIRST
- ❌ "I don't have time" - MAKE time

---

## Setting Up Development Environment

### 1. Clone Repository

```bash
git clone <repository-url>
cd C:/Ignotus
```

### 2. Install Dependencies

**Python dependencies:**
```bash
pip install psutil  # For process management
```

**Godot setup:**
- Download Godot 4.5.1 (console version)
- Place at: `C:/godot/Godot_v4.5.1-stable_win64.exe/`

### 3. Verify Setup

```bash
# Run verification to confirm setup
python scripts/tools/verify_phase.py --phase 0

# Should see all checks passing
```

### 4. Install Pre-Commit Hook (Recommended)

**Create `.git/hooks/pre-commit`:**
```bash
#!/bin/bash

echo "Running automated verification..."
python scripts/tools/verify_phase.py --phase 0

if [ $? -ne 0 ]; then
    echo "❌ Verification failed - cannot commit"
    echo "Fix issues and try again"
    exit 1
fi

echo "✅ Verification passed"
```

**Make executable:**
```bash
chmod +x .git/hooks/pre-commit  # Linux/Mac
# Windows: Right-click → Properties → Set as executable
```

---

## Workflow Examples

### Example 1: Adding New Feature

```bash
# 1. Create feature branch
git checkout -b feature/new-teleport-system

# 2. Make changes to code
# ... edit files ...

# 3. Run verification
python scripts/tools/verify_phase.py --phase 1 --auto-fix

# 4. Check results
# - Exit code 0? → Good, proceed
# - Exit code 1? → Fix issues, goto step 3
# - Exit code 2? → Auto-fixes applied, goto step 3

# 5. Commit when exit code is 0
git add .
git commit -m "Add teleportation system

Verification Results:
- Phase: 1
- Exit Code: 0
- Duration: 18.3s
- All Checks: PASS"

# 6. Push and create PR
git push origin feature/new-teleport-system
```

### Example 2: Fixing Bug

```bash
# 1. Reproduce bug
# 2. Write test that fails (RED)
# 3. Fix bug (GREEN)

# 4. Verify fix
python scripts/tools/verify_phase.py --phase 0 --auto-fix

# 5. Confirm test now passes
# Check VERIFICATION_REPORT_PHASE_0.md

# 6. Commit
git add .
git commit -m "Fix: XR controller tracking bug

- Added test: test_xr_controller_tracking
- Fixed: Controller position update logic
- Verification: All checks PASS"
```

### Example 3: Adding New Addon

```bash
# 1. Clone addon to addons/
cd addons
git clone https://github.com/author/addon-name.git

# 2. Run verification (will detect issues)
python scripts/tools/verify_phase.py --phase 0 --auto-fix

# 3. Auto-fixer will fix nested structure if needed
# 4. Add addon tests to tests/unit/test_addon_installation.gd

# 5. Re-verify
python scripts/tools/verify_phase.py --phase 0

# 6. Commit when passing
git add .
git commit -m "Add addon: addon-name

Verification:
- Structure: VALID
- Tests: PASS
- Autoloads: REGISTERED"
```

---

## Debugging Failed Verification

### Check 1: Read Verification Report

```bash
# After failed verification, check:
cat VERIFICATION_REPORT_PHASE_<N>.md
```

**Look for:**
- Which checks failed
- Error messages
- Fix recommendations

### Check 2: Review Detailed Logs

```bash
# Check Godot console output
cat godot_console.log

# Check error analysis
cat GODOT_ERROR_REPORT.md
```

### Check 3: Run Individual Tools

```bash
# Check project config
python scripts/tools/check_project_config.py

# Check addon structure
python scripts/tools/fix_addon_structure.py --verify-only

# Check for errors
python scripts/tools/check_godot_errors.py
```

### Check 4: Apply Auto-Fixes

```bash
# Let auto-fixer resolve common issues
python scripts/tools/fix_addon_structure.py --all

# Then re-verify
python scripts/tools/verify_phase.py --phase 0
```

---

## Common Issues

### Issue: "Addon structure invalid"

**Fix:**
```bash
python scripts/tools/fix_addon_structure.py --all
```

### Issue: "Tests failing"

**Fix:**
1. Check test output: `cat test_output.log`
2. Fix the failing test
3. Re-run verification

### Issue: "Godot won't start"

**Fix:**
```bash
# Kill existing Godot
python scripts/tools/godot_manager.py --kill

# Restart with fresh logs
python scripts/tools/godot_manager.py --restart --capture
```

### Issue: "Verification times out"

**Fix:**
```bash
# Check Godot status
python scripts/tools/godot_manager.py --status

# If hung, kill and retry
python scripts/tools/godot_manager.py --kill
python scripts/tools/verify_phase.py --phase 0
```

---

## Documentation

**Read these documents before contributing:**
- `AUTOMATED_VERIFICATION_WORKFLOW.md` - Complete workflow design
- `HOW_TO_USE_AUTOMATED_WORKFLOW.md` - Quick start guide
- `DEVELOPMENT_RULES.md` - Strict development rules
- `CLAUDE.md` - AI agent instructions (includes workflow)
- `PHASE_0_FOUNDATION.md` - Phase 0 requirements
- `PHASE_0_COMPLETE.md` - Phase 0 results

---

## Questions?

**If you have questions:**
1. Read the documentation above
2. Check existing verification reports
3. Run verification and read error messages
4. Create issue if still unclear

**DO NOT:**
- ❌ Skip verification "just this once"
- ❌ Commit without verification
- ❌ Ignore test failures
- ❌ Work around the workflow

---

## Summary

**The workflow is simple:**
1. Make changes
2. Run: `python scripts/tools/verify_phase.py --phase <N> --auto-fix`
3. Fix any issues
4. Repeat until exit code 0
5. Commit

**That's it. Follow this. No exceptions.**

**Your cooperation ensures project quality and prevents regressions.**

---

**Thank you for contributing to SpaceTime!**

**Remember: Verification is MANDATORY, not optional.**
