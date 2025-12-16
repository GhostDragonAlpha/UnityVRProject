# Parallel Testing Example

**How to use the Universal Mandatory Testing Workflow with parallel sub-agents**

---

## Example 1: Single Agent Task

**User says:** "Implement snap turning"

**Main Agent responds:**

```
I will follow the mandatory testing workflow from UNIVERSAL_MANDATORY_TESTING_PROMPT.md:

1. DECIDE - Next logical task: Implement snap turning for VR comfort
2. IMPLEMENT - Writing snap turning code
3. VERIFY - Running: python scripts/tools/verify_godot_zero_errors.py
4. FIX - (if needed) Fix errors and re-verify
5. COMPLETE - Report when exit code = 0
```

**Main Agent executes:**
- Phase 1 (DECIDE): "I will implement snap turning in VRComfortSystem.gd"
- Phase 2 (IMPLEMENT): Writes the code
- Phase 3 (VERIFY): Runs verification → Exit code 0 ✅
- Phase 5 (COMPLETE): Reports "Snap turning complete, verified with 0 errors"

---

## Example 2: Multiple Independent Tasks (Parallel)

**User says:** "Implement snap turning, vignette effect, and haptic feedback in parallel"

**Main Agent responds:**

```
I will spawn 3 sub-agents in parallel to implement these independent features.
Each agent will follow UNIVERSAL_MANDATORY_TESTING_PROMPT.md workflow.

Phase 1 (DECIDE): Three independent VR comfort features
Phase 2 (IMPLEMENT): Spawning 3 parallel sub-agents...
```

**Main Agent spawns 3 agents in ONE message:**

**Sub-Agent A Task:**
```
Implement snap turning feature in VRComfortSystem.

Follow UNIVERSAL_MANDATORY_TESTING_PROMPT.md workflow:
1. DECIDE - What to implement
2. IMPLEMENT - Write the code
3. VERIFY - Run: python scripts/tools/verify_godot_zero_errors.py
4. FIX - If exit code ≠ 0, fix and re-verify
5. COMPLETE - Report when exit code = 0

MANDATORY: Verification must pass before completing.
```

**Sub-Agent B Task:**
```
Implement vignette effect feature in VRComfortSystem.

Follow UNIVERSAL_MANDATORY_TESTING_PROMPT.md workflow:
1. DECIDE - What to implement
2. IMPLEMENT - Write the code
3. VERIFY - Run: python scripts/tools/verify_godot_zero_errors.py
4. FIX - If exit code ≠ 0, fix and re-verify
5. COMPLETE - Report when exit code = 0

MANDATORY: Verification must pass before completing.
```

**Sub-Agent C Task:**
```
Implement haptic feedback feature in VRComfortSystem.

Follow UNIVERSAL_MANDATORY_TESTING_PROMPT.md workflow:
1. DECIDE - What to implement
2. IMPLEMENT - Write the code
3. VERIFY - Run: python scripts/tools/verify_godot_zero_errors.py
4. FIX - If exit code ≠ 0, fix and re-verify
5. COMPLETE - Report when exit code = 0

MANDATORY: Verification must pass before completing.
```

**Each Sub-Agent executes independently:**

**Agent A:**
1. DECIDE - Implement snap turning
2. IMPLEMENT - Adds snap_turn() function
3. VERIFY - Exit code 1 (parse error)
4. FIX - Fixes typo, re-verify → Exit code 0 ✅
5. COMPLETE - Reports: "Snap turning complete, verified"

**Agent B:**
1. DECIDE - Implement vignette effect
2. IMPLEMENT - Adds vignette shader
3. VERIFY - Exit code 0 ✅ (first try!)
4. COMPLETE - Reports: "Vignette complete, verified"

**Agent C:**
1. DECIDE - Implement haptic feedback
2. IMPLEMENT - Adds haptic triggers
3. VERIFY - Exit code 1 (missing reference)
4. FIX - Adds HapticManager reference, re-verify → Exit code 0 ✅
5. COMPLETE - Reports: "Haptics complete, verified"

**Main Agent consolidates:**

Phase 3 (VERIFY): Runs final verification on all changes
```bash
python scripts/tools/verify_godot_zero_errors.py
```
Result: Exit code 0 ✅

Phase 5 (COMPLETE): Reports to user:
```
TASK COMPLETE: VR Comfort Features

What Was Built:
- Snap turning (VRComfortSystem.gd, 45 lines)
- Vignette effect (VRComfortSystem.gd, 38 lines)
- Haptic feedback (VRComfortSystem.gd, 52 lines)

Sub-Agent Results:
✅ Agent A: Snap turning - verified (exit code 0)
✅ Agent B: Vignette effect - verified (exit code 0)
✅ Agent C: Haptic feedback - verified (exit code 0)

Final Verification:
✅ Exit Code: 0
✅ Godot opens with ZERO ERRORS
✅ All features integrated successfully

Next Logical Task:
Implement performance optimization (Week 4 continuation)
```

---

## Example 3: Nested Sub-Agents (Recursive)

**User says:** "Implement Week 4 completely"

**Main Agent:**
```
Phase 1 (DECIDE): Week 4 has multiple features, spawn coordinator sub-agent
Phase 2 (IMPLEMENT): Spawning Week 4 coordinator...
```

**Main Agent spawns:** Week4Coordinator sub-agent

**Week4Coordinator receives:**
```
Implement all Week 4 features.

Follow UNIVERSAL_MANDATORY_TESTING_PROMPT.md workflow.

Features to implement:
- VRComfortSystem autoload
- Snap turning
- Vignette effect
- Haptic feedback
- Performance optimization

If you spawn sub-agents, pass them the same workflow instructions.
```

**Week4Coordinator executes:**

Phase 1 (DECIDE): "I will implement VRComfortSystem, then spawn parallel agents for features"

Phase 2 (IMPLEMENT):
- Creates VRComfortSystem.gd base class
- Spawns 4 parallel sub-agents for features

**Week4Coordinator spawns 4 agents:**
- Sub-Agent W4-A: Snap turning + workflow
- Sub-Agent W4-B: Vignette + workflow
- Sub-Agent W4-C: Haptics + workflow
- Sub-Agent W4-D: Performance + workflow

**Each W4 sub-agent:**
1. Implements feature
2. Verifies (exit code 0)
3. Reports back to Week4Coordinator

**Week4Coordinator:**

Phase 3 (VERIFY): Runs verification on integrated Week 4
```bash
python scripts/tools/verify_godot_zero_errors.py
```
Result: Exit code 0 ✅

Phase 5 (COMPLETE): Reports to Main Agent

**Main Agent:**

Phase 3 (VERIFY): Runs final verification
```bash
python scripts/tools/verify_godot_zero_errors.py
```
Result: Exit code 0 ✅

Phase 5 (COMPLETE): Reports to user:
```
TASK COMPLETE: Week 4 Implementation

What Was Built:
- VRComfortSystem autoload (185 lines)
- Snap turning (45 lines)
- Vignette effect (38 lines)
- Haptic feedback (52 lines)
- Performance optimization (67 lines)

Verification Hierarchy:
✅ W4-A verified (exit code 0)
✅ W4-B verified (exit code 0)
✅ W4-C verified (exit code 0)
✅ W4-D verified (exit code 0)
✅ Week4Coordinator verified (exit code 0)
✅ Main Agent final verification (exit code 0)

Result: Week 4 COMPLETE - All features verified with zero errors

Next Logical Task:
Begin Phase 2 planning
```

---

## Key Patterns

### Pattern 1: Single Task
```
Main Agent → Implement → Verify → Complete
```

### Pattern 2: Parallel Tasks
```
Main Agent → Spawn [A, B, C] in parallel
  Agent A → Implement → Verify → Complete
  Agent B → Implement → Verify → Complete
  Agent C → Implement → Verify → Complete
Main Agent → Final Verify → Complete
```

### Pattern 3: Recursive (Nested)
```
Main Agent → Spawn Coordinator
  Coordinator → Spawn [A, B, C, D]
    Agent A → Implement → Verify → Complete
    Agent B → Implement → Verify → Complete
    Agent C → Implement → Verify → Complete
    Agent D → Implement → Verify → Complete
  Coordinator → Verify → Complete
Main Agent → Final Verify → Complete
```

---

## Template for Spawning Parallel Agents

**When you need to spawn multiple parallel agents:**

```
I will spawn [N] sub-agents in parallel (in ONE message with multiple Task calls).

Each agent receives:

"""
Implement [specific feature].

Follow UNIVERSAL_MANDATORY_TESTING_PROMPT.md workflow:
1. DECIDE - What to implement
2. IMPLEMENT - Write the code
3. VERIFY - Run: python scripts/tools/verify_godot_zero_errors.py
4. FIX - If exit code ≠ 0, fix and re-verify
5. COMPLETE - Report when exit code = 0

MANDATORY: Verification must pass (exit code 0) before completing.
"""
```

**Then:**
1. Wait for all agents to complete
2. Run final verification
3. Report consolidated results

---

## Common User Requests → Agent Strategy

| User Request | Agent Strategy | Parallel? |
|--------------|----------------|-----------|
| "Implement feature X" | Single agent | No |
| "Implement X, Y, Z" | 3 parallel agents | Yes |
| "Implement Week N" | Coordinator + parallel feature agents | Yes |
| "Fix bug in X" | Single agent | No |
| "Add tests for X, Y, Z" | 3 parallel test agents | Yes |
| "Optimize performance" | Single agent | No |
| "Implement Phase N" | Phase coordinator + week coordinators + feature agents | Yes |

---

## Error Handling in Parallel

**If one agent fails verification:**

Agent A: Exit code 0 ✅
Agent B: Exit code 1 ❌ (has errors)
Agent C: Exit code 0 ✅

**Agent B executes Phase 4 (FIX):**
- Reads error log
- Fixes errors
- Re-runs verification
- Repeats until exit code 0

**Main agent waits for all agents to reach exit code 0 before proceeding.**

**No agent is allowed to complete with errors. Period.**

---

**END OF PARALLEL TESTING EXAMPLE**

**Reference:** UNIVERSAL_MANDATORY_TESTING_PROMPT.md
**Quick Start:** WORKFLOW_QUICK_START.md
