# Runtime Verification Added to Workflow

**Date:** 2025-12-09
**Status:** ✅ COMPLETE - Runtime verification integrated
**Version:** 2.0

---

## What Was Added

Added **runtime verification** to the mandatory testing workflow.

**Before:** Only static verification (Godot opens with zero errors)
**After:** Static + Runtime verification (Godot opens + GdUnit4 tests + scenes run)

---

## New Verification Scripts

### 1. verify_runtime.py (NEW)
**Purpose:** Run runtime tests (GdUnit4 + test scenes)

**What it does:**
- Runs GdUnit4 unit tests in headless mode
- Runs test scenes for 10+ seconds each
- Monitors for runtime errors during execution
- Reports pass/fail for each test type

**Exit codes:**
- 0: All runtime tests passed
- 1: Runtime errors detected
- 2: Verification could not run

### 2. verify_complete.py (NEW)
**Purpose:** Run both static and runtime verification

**What it does:**
- Step 1: Runs static verification (verify_godot_zero_errors.py)
- Step 2: Runs runtime verification (verify_runtime.py)
- Reports overall pass/fail

**Exit codes:**
- 0: Both static and runtime passed
- 1: Either static or runtime failed
- 2: Verification could not run

---

## Updated Command

**Old workflow:**
```bash
python scripts/tools/verify_godot_zero_errors.py
```

**New workflow (RECOMMENDED):**
```bash
python scripts/tools/verify_complete.py
```

**Step-by-step (for debugging):**
```bash
# Step 1: Static
python scripts/tools/verify_godot_zero_errors.py

# Step 2: Runtime
python scripts/tools/verify_runtime.py
```

---

## What Runtime Verification Checks

### GdUnit4 Unit Tests
- Runs all unit tests in tests/ directory
- Executes in headless mode
- Timeout: 60 seconds
- Reports pass/fail counts

### Test Scene Execution
- Finds all test scenes (floating_origin_test.tscn, planetary_gravity_test.tscn)
- Runs each scene for 10+ seconds
- Monitors console for runtime errors
- Checks for crashes/hangs

---

## Files Updated

**Core Workflow:**
1. ✅ UNIVERSAL_MANDATORY_TESTING_PROMPT.md - Updated Phase 3 (VERIFY)
2. ✅ WORKFLOW_QUICK_START.md - Updated verification commands
3. ✅ MANDATORY_AI_CHECKLIST.md - Updated verification checklist

**Tool-Specific:**
4. ✅ CLAUDE.md - Updated verification command
5. ✅ .cursorrules - Updated verification command
6. ✅ .aider.conf.yml - Updated verification command
7. ✅ .ai-instructions - Updated verification command
8. ✅ AI_AGENTS_README.md - Updated verification section

**New Scripts:**
9. ✅ scripts/tools/verify_runtime.py - Runtime verification
10. ✅ scripts/tools/verify_complete.py - Combined verification

---

## Current Test Results

**Static Verification:** ✅ PASSED
- Godot opens with 0 errors
- No parse errors
- All dependencies present

**Runtime Verification:** ❌ FAILED (4 errors)
- GdUnit4 tests: PASSED
- Test scenes: FAILED (4 runtime errors in 2 scenes)

**Overall:** Exit code 1 (FAILED)

**Errors to fix:**
1. floating_origin_test.gd - Type inference error
2. floating_origin_test.gd - Script load failure
3. planetary_gravity_test.gd - Format character error
4. planetary_gravity_test.gd - Script load failure

---

## Impact on Workflow

**Phase 3 (VERIFY) now includes:**
- Static verification (parse errors, missing files)
- Runtime verification (unit tests, scene execution)

**Both must pass for exit code 0**

**Agents must:**
- Run complete verification after implementing
- Fix ALL errors (static + runtime)
- Achieve exit code 0 before completing

---

## Next Steps

1. Fix the 4 runtime errors in test scenes
2. Re-run complete verification
3. Achieve exit code 0
4. Then proceed with Phase 5 (COMPLETE)

---

**Documentation solidified. Runtime verification integrated into mandatory workflow.**

**Version:** 2.0
**Last Updated:** 2025-12-09
**Status:** Documentation complete, test scenes need fixes
