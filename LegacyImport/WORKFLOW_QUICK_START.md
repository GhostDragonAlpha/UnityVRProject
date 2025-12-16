# Workflow Quick Start

**Use this prompt when starting ANY new development task:**

---

## For Main Agents (You)

```
I will follow the mandatory testing workflow from UNIVERSAL_MANDATORY_TESTING_PROMPT.md:

1. DECIDE - Determine next logical task
2. IMPLEMENT - Write code/files
3. VERIFY - Run: python scripts/tools/verify_godot_zero_errors.py
4. FIX - If exit code ≠ 0, fix errors and re-verify
5. COMPLETE - Report when exit code = 0

MANDATORY: Verification must pass (exit code 0) before completing.
```

---

## For Sub-Agents (Pass this to Task tool)

```
IMPORTANT: Follow the workflow in UNIVERSAL_MANDATORY_TESTING_PROMPT.md

Your workflow:
1. DECIDE - Determine what to implement
2. IMPLEMENT - Write the code/files
3. VERIFY - Run: python scripts/tools/verify_godot_zero_errors.py
4. FIX - If exit code 1, fix errors and re-verify
5. COMPLETE - Report results when exit code 0

MANDATORY: Verification must pass (exit code 0) before completing.

If you spawn sub-agents, pass these same instructions to them.
```

---

## Verification Command

**Complete Verification (Recommended):**
```bash
python scripts/tools/verify_complete.py
```
Runs static (parse errors) + runtime (GdUnit4 + scene tests)

**Individual Steps:**
```bash
# Static: Godot opens with zero errors
python scripts/tools/verify_godot_zero_errors.py

# Runtime: GdUnit4 tests + scene execution
python scripts/tools/verify_runtime.py
```

**Success:** Exit code 0, Zero errors in both static and runtime
**Failure:** Exit code 1, Errors found in static or runtime

---

## Critical Rules

- ✅ Always verify after implementing
- ✅ Never skip verification
- ✅ Never complete with errors
- ✅ Always pass workflow to sub-agents
- ✅ Zero errors is mandatory

**Full details:** See `UNIVERSAL_MANDATORY_TESTING_PROMPT.md`
