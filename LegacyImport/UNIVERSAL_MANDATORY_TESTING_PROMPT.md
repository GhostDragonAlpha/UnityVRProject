# UNIVERSAL MANDATORY TESTING PROMPT

**Version:** 1.0
**Date:** 2025-12-09
**Status:** PRODUCTION - Use for all development tasks

---

## AGENT INSTRUCTIONS - READ THIS FIRST

You are working on the SpaceTime VR project. This prompt defines the **MANDATORY** workflow you must follow for ANY task you work on.

**CRITICAL:** You must pass these same instructions to ALL sub-agents you spawn using the Task tool.

---

## THE MANDATORY WORKFLOW CYCLE

Every task you work on MUST follow this cycle:

```
1. DECIDE → 2. IMPLEMENT → 3. VERIFY → 4. FIX → 5. COMPLETE
                              ↓ FAIL
                              └─────→ GOTO 4
```

### Phase 1: DECIDE (What to work on next)

**Determine the next logical task by analyzing:**
- Project status files (PHASE_1_STATUS.md, WHATS_NEXT.md, etc.)
- Incomplete features or weeks
- User's explicit request (if provided)
- Logical dependency order (don't skip prerequisites)

**Choose ONE task to work on** - Do not split focus.

**Output:** Clear statement of what you will work on and why it's the next logical step.

---

### Phase 2: IMPLEMENT (Do the work)

**Execute the task following these rules:**

1. **Read before writing:** Always read existing files before modifying them
2. **Small, focused changes:** Don't over-engineer or add unrequested features
3. **Follow existing patterns:** Match the codebase style and architecture
4. **Document as you go:** Update status files and create completion reports

**For complex tasks:**
- Use Task tool to spawn sub-agents
- **CRITICAL:** Pass THIS ENTIRE PROMPT to sub-agents in their task description
- Tell sub-agents: "Follow UNIVERSAL_MANDATORY_TESTING_PROMPT.md workflow"

**Output:** Completed code, scenes, and documentation.

---

### Phase 3: VERIFY (Mandatory testing - Static + Runtime)

**MANDATORY - NO EXCEPTIONS:**

After implementing ANY code changes, you MUST run complete verification:

**OPTION 1: Complete Verification (Recommended)**
```bash
python scripts/tools/verify_complete.py
```
Runs both static AND runtime verification in sequence.

**OPTION 2: Step-by-step (for debugging)**
```bash
# Step 1: Static verification (Godot opens with zero errors)
python scripts/tools/verify_godot_zero_errors.py

# Step 2: Runtime verification (Test scenes run without errors)
python scripts/tools/verify_runtime.py
```

**Acceptance Criteria:**
- Exit code: 0 (zero errors)
- Static verification: Godot opens successfully
- Runtime verification: Test scenes run without errors
- No ERROR lines in console output

**What this verifies:**

**Static Verification (verify_godot_zero_errors.py):**
- No parse errors in GDScript
- No missing dependencies
- No autoload conflicts
- No addon loading errors
- Project loads cleanly

**Runtime Verification (verify_runtime.py):**
- GdUnit4 unit tests execute and pass
- Test scenes actually run
- No runtime errors during execution
- Scenes run for 10+ seconds without crashes
- Functionality works as expected

**DO NOT PROCEED** if either verification fails (exit code 1).

---

### Phase 4: FIX (If verification fails)

**If verification returns exit code 1:**

1. **Read the error log:** Check `godot_startup.log` for specific errors
2. **Identify root cause:** Parse errors, missing files, conflicts, etc.
3. **Fix the error:** Make targeted fixes to resolve the issue
4. **Re-run verification:** `python scripts/tools/verify_godot_zero_errors.py`
5. **Repeat until exit code 0**

**DO NOT:**
- Skip errors and move on
- Mark tasks as complete with failing verification
- Defer error fixing to "later"

**Common fixes:**
- Remove `class_name` declarations that conflict with autoloads
- Fix missing file paths
- Remove incomplete/broken addons
- Fix typos in scripts

---

### Phase 5: COMPLETE (Mark task done and report)

**Only when verification passes (exit code 0):**

1. **Update status files:**
   - Mark task/week as COMPLETE in status files
   - Update progress percentages
   - Document verification results

2. **Create completion report:**
   - What was built (features, files, line counts)
   - Verification results (exit code, error count)
   - Next recommended task

3. **Report to user:**
   - Summary of what was accomplished
   - Verification status (PASSED with 0 errors)
   - What's next in the logical sequence

**Output format:**
```
TASK COMPLETE: [Task Name]

What Was Built:
- [Feature 1] ([file path], [lines])
- [Feature 2] ([file path], [lines])

Verification:
✅ Exit Code: 0
✅ Godot opens with ZERO ERRORS
✅ Runtime verification: PASSED

Next Logical Task:
[Next task description]
```

---

## RECURSIVE SUB-AGENT INSTRUCTIONS

**When you spawn sub-agents using the Task tool:**

Include this in the task description:

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

**This creates a recursive testing hierarchy:**
- Main agent follows workflow
- Sub-agent 1 follows workflow
- Sub-agent 2 (spawned by sub-agent 1) follows workflow
- All agents verify with zero errors before completing

---

## PARALLEL EXECUTION

**For independent tasks, run in parallel:**

When multiple tasks are independent (no dependencies between them):

1. **Spawn multiple sub-agents in ONE message:**
   - Use multiple Task tool calls in a single message
   - Each agent gets the mandatory testing instructions
   - Each agent works independently

2. **Each agent runs verification:**
   - Agent A verifies its changes (exit code 0)
   - Agent B verifies its changes (exit code 0)
   - Agent C verifies its changes (exit code 0)

3. **Consolidate results:**
   - Wait for all agents to complete
   - Run final verification on combined changes
   - Report aggregate results

**Example:**
```
User: "Implement features X, Y, and Z"

Main Agent:
1. Spawns 3 sub-agents in parallel (one message, multiple Task calls)
2. Each gets: "Follow UNIVERSAL_MANDATORY_TESTING_PROMPT.md"
3. Each implements + verifies independently
4. Main agent runs final verification
5. Reports: All 3 features complete, exit code 0
```

---

## ERROR TOLERANCE: ZERO

**The only acceptable verification result is:**
- Exit code: 0
- Errors found: 0
- Godot status: Running

**If you see:**
- Exit code: 1 → FIX immediately (Phase 4)
- Errors found: N (where N > 0) → FIX immediately (Phase 4)
- Godot crashes → FIX immediately (Phase 4)

**DO NOT:**
- Skip verification
- Ignore errors
- Mark tasks complete with errors
- Say "there are minor errors we can fix later"

**MANDATORY:** Zero errors is the only acceptable state.

---

## WORKFLOW EXAMPLES

### Example 1: Simple Task

```
User: "Add jump cooldown to player"

Agent:
1. DECIDE - "Next logical task: Add jump cooldown to planetary_gravity_test.gd"
2. IMPLEMENT - Add cooldown timer and check
3. VERIFY - Run verify_godot_zero_errors.py → Exit code 0 ✅
4. COMPLETE - Report: "Jump cooldown added, verification passed"
```

### Example 2: Complex Task with Sub-Agent

```
User: "Implement Week 4 features"

Main Agent:
1. DECIDE - "Next logical task: Week 4 (VR Comfort System)"
2. IMPLEMENT - Spawn sub-agent with:
   "Implement VRComfortSystem following UNIVERSAL_MANDATORY_TESTING_PROMPT.md"

Sub-Agent:
1. DECIDE - "Implement VRComfortSystem.gd"
2. IMPLEMENT - Write VRComfortSystem script
3. VERIFY - Run verify_godot_zero_errors.py → Exit code 1 ❌
4. FIX - Fix parse error, re-verify → Exit code 0 ✅
5. COMPLETE - Report to main agent: "VRComfortSystem complete, verified"

Main Agent:
3. VERIFY - Run verify_godot_zero_errors.py on complete project → Exit code 0 ✅
4. COMPLETE - Report: "Week 4 complete, all features verified"
```

### Example 3: Parallel Tasks

```
User: "Implement snap turning, vignette effect, and haptic feedback"

Main Agent:
1. DECIDE - "Three independent features, run in parallel"
2. IMPLEMENT - Spawn 3 sub-agents in ONE message:
   - Agent A: Snap turning + mandatory testing
   - Agent B: Vignette effect + mandatory testing
   - Agent C: Haptic feedback + mandatory testing

Each Sub-Agent:
1. DECIDE - What to implement
2. IMPLEMENT - Write code
3. VERIFY - verify_godot_zero_errors.py → Exit code 0 ✅
4. COMPLETE - Report results

Main Agent:
3. VERIFY - Final verification on all changes → Exit code 0 ✅
4. COMPLETE - Report: "All 3 features complete and verified"
```

---

## VERIFICATION COMMAND REFERENCE

**Main verification command:**
```bash
python scripts/tools/verify_godot_zero_errors.py
```

**What it does:**
1. Kills existing Godot processes
2. Starts Godot editor with console capture
3. Waits for startup (30s timeout)
4. Parses log for ERROR lines
5. Returns exit code 0 (pass) or 1 (fail)

**Success output:**
```
[PASS] GODOT OPENED WITH ZERO ERRORS
Errors found: 0
Exit Code: 0
```

**Failure output:**
```
[FAIL] GODOT HAS 3 ERROR(S)
Errors found:
  Line 42: ERROR: Parse error in script.gd
Exit Code: 1
```

**Log file location:** `C:\Ignotus\godot_startup.log`

---

## INSTRUCTIONS FOR MAIN AGENT

**When you receive a new task from the user:**

1. **Acknowledge the workflow:**
   ```
   "I will follow the mandatory testing workflow:
   1. DECIDE what to work on
   2. IMPLEMENT the feature
   3. VERIFY with zero-errors check
   4. FIX any errors found
   5. COMPLETE when verification passes"
   ```

2. **Execute Phase 1 (DECIDE):**
   - State what you will work on
   - Explain why it's the next logical task

3. **Execute Phase 2 (IMPLEMENT):**
   - Do the work
   - If spawning sub-agents, pass this workflow to them

4. **Execute Phase 3 (VERIFY):**
   - Run `python scripts/tools/verify_godot_zero_errors.py`
   - Check exit code

5. **Execute Phase 4 (FIX) if needed:**
   - Fix errors if exit code ≠ 0
   - Re-verify until exit code = 0

6. **Execute Phase 5 (COMPLETE):**
   - Update status files
   - Report results
   - Suggest next logical task

---

## INSTRUCTIONS FOR SUB-AGENTS

**When a main agent spawns you:**

You will receive instructions like:
```
"Implement [feature]. Follow UNIVERSAL_MANDATORY_TESTING_PROMPT.md workflow."
```

**Your response:**

1. **Read this file:** Understand the 5-phase workflow
2. **Execute all 5 phases:** DECIDE → IMPLEMENT → VERIFY → FIX → COMPLETE
3. **Run verification:** `python scripts/tools/verify_godot_zero_errors.py`
4. **Fix until exit code 0:** Do not complete with errors
5. **Report to parent agent:** Include verification status

**If you spawn your own sub-agents:**
- Pass the same instructions to them
- They must also follow the 5-phase workflow
- They must also run verification

---

## STATUS FILE UPDATES

**After completing a task, update:**

1. **PHASE_1_STATUS.md** (or relevant phase file)
   - Mark week/task as COMPLETE ✅
   - Update progress percentages
   - Add verification results

2. **WHATS_NEXT.md** (if exists)
   - Update recommended next steps
   - Mark completed tasks

3. **Create completion report:**
   - `COMPLETION_REPORT_[TASK].md`
   - Include verification results
   - Document what was built

---

## CRITICAL RULES - NO EXCEPTIONS

1. ✅ **ALWAYS verify after implementing code**
2. ✅ **NEVER skip verification to "save time"**
3. ✅ **NEVER mark tasks complete with errors**
4. ✅ **ALWAYS fix errors immediately (Phase 4)**
5. ✅ **ALWAYS pass this workflow to sub-agents**
6. ✅ **ALWAYS run verification until exit code 0**
7. ✅ **NEVER defer error fixing to "later"**

**Zero errors is mandatory. Exit code 0 is the only acceptable result.**

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
│ Acceptance: Exit code 0, Errors found 0             │
│ Sub-agents: Must follow same workflow               │
│ Parallel: Spawn multiple agents in one message      │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

**END OF UNIVERSAL MANDATORY TESTING PROMPT**

**Version:** 1.0
**Effective:** Immediately
**Applies to:** All agents working on SpaceTime VR project
**Enforcement:** Mandatory, zero exceptions
