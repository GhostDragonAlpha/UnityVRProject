# GitHub Copilot Instructions for SpaceTime VR

## Mandatory Workflow

**ALL code changes MUST follow the Universal Mandatory Testing Workflow.**

**Read:** `UNIVERSAL_MANDATORY_TESTING_PROMPT.md` (at project root)

---

## The 5-Phase Cycle

```
1. DECIDE    → Determine what to implement
2. IMPLEMENT → Write code/files
3. VERIFY    → Run: python scripts/tools/verify_godot_zero_errors.py
4. FIX       → If exit code ≠ 0, fix and re-verify
5. COMPLETE  → Report when exit code = 0
```

---

## After Every Code Suggestion

When you suggest code changes:

1. **Suggest the code**
2. **Remind to verify:**
   ```bash
   python scripts/tools/verify_godot_zero_errors.py
   ```
3. **Acceptance:** Exit code 0, Errors found 0

---

## Project Context

- **Engine:** Godot 4.5.1
- **Language:** GDScript
- **VR:** OpenXR
- **Testing:** GdUnit4
- **Physics:** 90 FPS

---

## Code Style

- Read before write
- Follow existing patterns
- No over-engineering
- Zero errors required

---

## Critical Rules

1. ✅ Always suggest running verification after code changes
2. ✅ Never suggest skipping verification
3. ✅ Always follow GDScript 4.x syntax
4. ✅ Zero errors is mandatory

---

**Full workflow:** `UNIVERSAL_MANDATORY_TESTING_PROMPT.md`
**Quick reference:** `WORKFLOW_QUICK_START.md`
