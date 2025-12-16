# MANDATORY AI CHECKLIST - READ BEFORE MARKING ANYTHING COMPLETE

**This file MUST be consulted before declaring any task, feature, or phase complete.**

---

## 🚨 CRITICAL RULE FOR AI AGENTS 🚨

**ALL AI AGENTS must follow the Universal Mandatory Testing Workflow.**

**Read:** `UNIVERSAL_MANDATORY_TESTING_PROMPT.md`
**Quick Reference:** `WORKFLOW_QUICK_START.md`

---

## THE MANDATORY 5-PHASE WORKFLOW

**BEFORE you say "complete" or "done" or "ready", you MUST complete all 5 phases:**

### Phase 1: DECIDE
- Analyze status files (PHASE_1_STATUS.md, WHATS_NEXT.md, etc.)
- Determine next logical task
- State clearly what you will work on and why

**Checklist:**
- [ ] Reviewed current project status
- [ ] Identified next logical task
- [ ] Stated what will be implemented

---

### Phase 2: IMPLEMENT
- Write code/files following existing patterns
- Read files before modifying them
- Don't over-engineer or add unrequested features
- Update documentation as you go

**For complex tasks:**
- Spawn sub-agents using Task tool
- Pass them: "Follow UNIVERSAL_MANDATORY_TESTING_PROMPT.md workflow"
- Each sub-agent must also verify before completing

**Checklist:**
- [ ] Code written/modified
- [ ] Files follow existing patterns
- [ ] Documentation updated
- [ ] Sub-agents spawned with workflow instructions (if applicable)

---

### Phase 3: VERIFY (MANDATORY - NO EXCEPTIONS)

**Run automated zero-errors verification:**

```bash
python scripts/tools/verify_godot_zero_errors.py
```

**This command:**
1. Kills existing Godot processes
2. Starts Godot editor with console capture
3. Waits for startup (30s timeout)
4. Parses console log for ERROR lines
5. Reports: 0 errors = PASS (exit code 0), >0 errors = FAIL (exit code 1)

**Required Output:**
```
[PASS] GODOT OPENED WITH ZERO ERRORS
Errors found: 0
Exit Code: 0
```

**Checklist:**
- [ ] Ran complete verification command
- [ ] Exit code: 0
- [ ] Static verification: PASSED (0 errors)
- [ ] Runtime verification: PASSED (GdUnit4 + scenes)
- [ ] Log files show no errors

**If verification FAILS (exit code 1):**
→ Go to Phase 4 (FIX)

**If verification PASSES (exit code 0):**
→ Go to Phase 5 (COMPLETE)

---

### Phase 4: FIX (If verification fails)

**When exit code ≠ 0:**

1. **Read the error log:**
   ```bash
   cat godot_startup.log | grep -i "error"
   ```

2. **Identify errors:**
   - Parse errors in GDScript
   - Missing files/resources
   - Autoload conflicts
   - Addon loading errors
   - class_name conflicts

3. **Fix the errors:**
   - Make targeted fixes
   - Don't skip or ignore errors
   - Fix ALL errors, not just first one

4. **Re-run verification:**
   ```bash
   python scripts/tools/verify_godot_zero_errors.py
   ```

5. **Repeat until exit code 0**

**Common Fixes:**
- Remove `class_name` declarations that conflict with autoloads
- Fix missing file paths in scripts
- Remove incomplete/broken addons
- Fix typos in GDScript
- Add missing dependencies

**Checklist:**
- [ ] Read error log
- [ ] Identified root causes
- [ ] Fixed ALL errors
- [ ] Re-ran verification
- [ ] Achieved exit code 0

**DO NOT PROCEED until exit code = 0**

---

### Phase 5: COMPLETE (Only when verification passes)

**When exit code = 0:**

1. **Update status files:**
   - Mark task/week/feature as COMPLETE ✅
   - Update progress percentages
   - Document verification results
   - Add to completion reports

2. **Create completion report:**
   ```markdown
   TASK COMPLETE: [Task Name]

   What Was Built:
   - [Feature] ([file path], [lines])

   Verification:
   ✅ Exit Code: 0
   ✅ Godot opens with ZERO ERRORS
   ✅ Errors found: 0

   Next Logical Task:
   [Next task]
   ```

3. **Report to user:**
   - Summary of what was built
   - Verification status (PASSED with 0 errors)
   - What's next in sequence

**Checklist:**
- [ ] Updated PHASE_N_STATUS.md (or similar)
- [ ] Created completion report
- [ ] Reported results to user
- [ ] Suggested next logical task
- [ ] Exit code: 0 confirmed

---

## RECURSIVE SUB-AGENT WORKFLOW

**When spawning sub-agents using Task tool:**

Include this in task description:
```
Follow UNIVERSAL_MANDATORY_TESTING_PROMPT.md workflow

Your workflow:
1. DECIDE - Determine what to implement
2. IMPLEMENT - Write the code/files
3. VERIFY - Run: python scripts/tools/verify_godot_zero_errors.py
4. FIX - If exit code ≠ 0, fix and re-verify
5. COMPLETE - Report when exit code = 0

MANDATORY: Verification must pass (exit code 0) before completing.

If you spawn sub-agents, pass these same instructions.
```

**Each sub-agent must:**
- [ ] Follow all 5 phases
- [ ] Run verification (exit code 0)
- [ ] Pass workflow to their sub-agents (if any)
- [ ] Report verification results

---

## PARALLEL EXECUTION

**For independent tasks:**

1. **Spawn multiple sub-agents in ONE message**
   - Multiple Task tool calls in single message
   - Each gets workflow instructions
   - Each works independently

2. **Each agent verifies independently**
   - Agent A: exit code 0 ✅
   - Agent B: exit code 0 ✅
   - Agent C: exit code 0 ✅

3. **Final consolidated verification**
   - Run verification on combined changes
   - Must achieve exit code 0
   - Report aggregate results

**Example:**
```
User: "Implement X, Y, and Z"

Main Agent:
1. DECIDE: Three independent features
2. IMPLEMENT: Spawn 3 agents in parallel
   - Each follows 5-phase workflow
   - Each verifies independently
3. VERIFY: Run final verification on all changes
4. COMPLETE: Report when all pass with exit code 0
```

**Checklist for parallel execution:**
- [ ] Spawned all agents in ONE message
- [ ] Each agent follows 5-phase workflow
- [ ] All agents achieved exit code 0
- [ ] Ran final consolidated verification
- [ ] Final exit code: 0

---

## ERROR TOLERANCE: ZERO

**The ONLY acceptable verification result:**
- Exit code: 0
- Errors found: 0
- Godot status: Running

**Unacceptable results:**
- ❌ Exit code: 1 (has errors)
- ❌ Errors found: N (where N > 0)
- ❌ Godot crashes on startup
- ❌ "Minor errors we can fix later"
- ❌ "It works on my machine"
- ❌ "We can skip verification this time"

**If you see ANY errors:**
→ Immediately go to Phase 4 (FIX)
→ Do not proceed
→ Do not mark complete
→ Do not ignore

**Zero errors is mandatory. No exceptions.**

---

## FINAL CHECKLIST BEFORE DECLARING COMPLETE

**Before you type "complete" or "done", verify:**

### All 5 Phases Completed:
- [ ] Phase 1 (DECIDE): Determined what to work on
- [ ] Phase 2 (IMPLEMENT): Wrote code/files
- [ ] Phase 3 (VERIFY): Ran verification command
- [ ] Phase 4 (FIX): Fixed errors if any (repeated until exit code 0)
- [ ] Phase 5 (COMPLETE): Updated status and reported

### Verification Requirements:
- [ ] Ran: `python scripts/tools/verify_godot_zero_errors.py`
- [ ] Exit code: 0
- [ ] Errors found: 0
- [ ] Godot opened successfully
- [ ] Log file shows zero errors

### Documentation Requirements:
- [ ] Status files updated (PHASE_N_STATUS.md, etc.)
- [ ] Completion report created (if applicable)
- [ ] User notified with results
- [ ] Next logical task suggested

### Sub-Agent Requirements (if applicable):
- [ ] All sub-agents spawned with workflow instructions
- [ ] All sub-agents achieved exit code 0
- [ ] Final consolidated verification passed

**If ALL checkboxes are checked:** ✅ You may declare the work COMPLETE

**If ANY checkbox is unchecked:** ❌ DO NOT declare complete

---

## COMMON MISTAKES TO AVOID

### ❌ WRONG: "I wrote the code, it must work"
✅ **CORRECT:** "I wrote code AND verified exit code 0"

### ❌ WRONG: "The code looks right, no need to verify"
✅ **CORRECT:** "I ran verification and got exit code 0"

### ❌ WRONG: "There are only 2 minor errors, good enough"
✅ **CORRECT:** "I fixed ALL errors and achieved zero errors"

### ❌ WRONG: "I'll skip verification to save time"
✅ **CORRECT:** "I ran verification (15-30 seconds) to ensure quality"

### ❌ WRONG: "I'll mark it complete now and fix errors later"
✅ **CORRECT:** "I'll fix errors NOW in Phase 4, then complete"

### ❌ WRONG: "My sub-agent said it works, so we're done"
✅ **CORRECT:** "My sub-agent verified with exit code 0, and I ran final verification"

### ❌ WRONG: "Verification failed but code works in my head"
✅ **CORRECT:** "Verification is truth. Exit code 1 means fix errors."

---

## VERIFICATION COMMAND REFERENCE

**Main verification command:**
```bash
python scripts/tools/verify_godot_zero_errors.py
```

**What it checks:**
- GDScript parse errors
- Missing dependencies
- Autoload conflicts
- Addon loading errors
- Scene loading errors
- Script compilation errors

**What it does NOT check:**
- Runtime behavior (requires manual testing)
- Gameplay functionality (requires human verification)
- VR comfort (requires 30-min VR test)
- Performance targets (requires profiling)

**Pass criteria:**
```
[PASS] GODOT OPENED WITH ZERO ERRORS
Errors found: 0
Exit Code: 0
```

**Fail criteria:**
```
[FAIL] GODOT HAS N ERROR(S)
Errors found: N
Exit Code: 1
```

**Log file location:** `C:\Ignotus\godot_startup.log`

---

## ENFORCEMENT

**This workflow is MANDATORY for:**
- ALL code changes
- ALL feature implementations
- ALL phase/week completions
- ALL bug fixes
- ALL sub-agent tasks
- ALL parallel agent tasks

**This workflow applies to:**
- Main agents (you)
- Sub-agents spawned by you
- Sub-sub-agents spawned by sub-agents
- All agents at all levels (recursive)

**Consequences of skipping:**
- Work is NOT complete
- Verification will fail
- Errors discovered later
- Work must be redone
- User loses trust in agent

**Zero errors is the law. Exit code 0 is mandatory.**

---

## QUICK REFERENCE CARD

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ MANDATORY 5-PHASE WORKFLOW                          ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│                                                      │
│ 1. DECIDE    → What to work on next                 │
│ 2. IMPLEMENT → Write code/files                     │
│ 3. VERIFY    → python verify_godot_zero_errors.py   │
│ 4. FIX       → If exit code ≠ 0, fix and re-verify  │
│ 5. COMPLETE  → Report when exit code = 0            │
│                                                      │
│ Pass to sub-agents: UNIVERSAL_MANDATORY_TESTING     │
│                     _PROMPT.md workflow             │
│                                                      │
│ Acceptance: Exit code 0, Errors 0                   │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

**REMEMBER: This checklist exists to ensure quality and prevent broken code from being marked complete.**

**Date Updated:** 2025-12-09
**Purpose:** Enforce zero-errors verification workflow
**Status:** MANDATORY - MUST BE FOLLOWED
**Version:** 2.0 - Universal Mandatory Testing Workflow
