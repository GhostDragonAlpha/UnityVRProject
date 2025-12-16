# AI Agents - Universal Mandatory Testing Workflow

**Last Updated:** 2025-12-09
**Status:** ACTIVE - All AI agents must follow this workflow
**Version:** 1.0

---

## Overview

This project enforces a **Universal Mandatory Testing Workflow** for all AI agents.

**The Rule:** After ANY code change, you MUST run automated verification and achieve zero errors.

---

## Files for Different AI Tools

### Main Workflow Documents (Read These First)

| File | Purpose | Audience |
|------|---------|----------|
| `UNIVERSAL_MANDATORY_TESTING_PROMPT.md` | Complete 5-phase workflow | All AI agents |
| `WORKFLOW_QUICK_START.md` | Quick reference guide | All AI agents |
| `MANDATORY_AI_CHECKLIST.md` | Detailed checklist | All AI agents |
| `PARALLEL_TESTING_EXAMPLE.md` | Examples of parallel execution | Multi-agent systems |

### AI Tool-Specific Instructions

| AI Tool | Configuration File | Location |
|---------|-------------------|----------|
| **Claude Code** | `CLAUDE.md` | Project root |
| **Cursor** | `.cursorrules` | Project root |
| **Aider** | `.aider.conf.yml` | Project root |
| **GitHub Copilot** | `copilot-instructions.md` | `.github/` |
| **Generic AI** | `.ai-instructions` | Project root |
| **Legacy Prompt** | `This tells AI to stop being a little bitch and get to work.txt` | `prompts/` |

---

## The Universal Workflow (Summary)

**Every AI agent follows this 5-phase cycle:**

```
1. DECIDE    → Analyze status, determine next task
2. IMPLEMENT → Write code/files
3. VERIFY    → Run: python scripts/tools/verify_godot_zero_errors.py
4. FIX       → If exit code ≠ 0, fix ALL errors and loop back
5. COMPLETE  → Report when exit code = 0
```

---

## Verification Command

**Complete Verification (Static + Runtime):**
```bash
python scripts/tools/verify_complete.py
```

**What it does:**
1. Static: Godot opens with zero parse errors
2. Runtime: Runs GdUnit4 unit tests
3. Runtime: Runs test scenes for 10+ seconds
4. Returns exit code 0 (all pass) or 1 (any fail)

**Pass criteria:**
```
[PASS] COMPLETE VERIFICATION PASSED
Static verification: PASSED
Runtime verification: PASSED
Exit Code: 0
```

**Fail criteria:**
```
[FAIL] VERIFICATION FAILED
Static/Runtime errors detected
Exit Code: 1
```

---

## For Multi-Agent Systems

**If your AI tool supports spawning multiple agents:**

1. **Spawn agents in parallel** (for independent tasks)
2. **Pass workflow to each agent:**
   ```
   Follow UNIVERSAL_MANDATORY_TESTING_PROMPT.md workflow
   MANDATORY: Verify with exit code 0 before completing
   ```
3. **Each agent verifies independently**
4. **Final verification on combined changes**

**Example:** See `PARALLEL_TESTING_EXAMPLE.md`

---

## Critical Rules (NO EXCEPTIONS)

1. ✅ **ALWAYS verify** after implementing code
2. ✅ **NEVER skip** verification to "save time"
3. ✅ **NEVER mark complete** with errors
4. ✅ **ALWAYS fix** ALL errors immediately (Phase 4)
5. ✅ **ALWAYS pass** workflow to sub-agents
6. ✅ **ZERO errors** is the only acceptable state

---

## Error Tolerance: ZERO

**Acceptable results:**
- Exit code: 0
- Errors found: 0
- Godot running

**Unacceptable results:**
- Exit code: 1
- Any errors found
- "Minor errors we'll fix later"
- Skipping verification

**If verification fails:** Immediately go to Phase 4 (FIX)

---

## Project Information

**Tech Stack:**
- Engine: Godot 4.5.1
- Language: GDScript
- VR: OpenXR
- Testing: GdUnit4
- API: HTTP on port 8080

**Project Root:** `C:/Ignotus/`

**Verification Log:** `C:/Ignotus/godot_startup.log`

---

## Quick Setup for Your AI Tool

### Claude Code
- Reads `CLAUDE.md` automatically
- Follow `UNIVERSAL_MANDATORY_TESTING_PROMPT.md`

### Cursor
- Reads `.cursorrules` automatically
- Contains condensed workflow

### Aider
- Reads `.aider.conf.yml` automatically
- Contains workflow instructions

### GitHub Copilot
- Place instructions in `.github/copilot-instructions.md`
- GitHub Copilot reads this file

### Other AI Tools
- Read `.ai-instructions` file
- Contains generic workflow applicable to any AI

---

## Workflow in Action

**Example 1: Single Feature**
```
User: "Add jump cooldown"
AI:
1. DECIDE - Implement jump cooldown in player script
2. IMPLEMENT - Add cooldown timer and check
3. VERIFY - Run verify_godot_zero_errors.py → Exit 0 ✅
5. COMPLETE - Report: "Jump cooldown added, verified"
```

**Example 2: Multiple Features (Parallel)**
```
User: "Implement snap turning, vignette, and haptics"
AI:
1. DECIDE - Three independent features
2. IMPLEMENT - Spawn 3 sub-agents in parallel
   Sub-A: Snap turning → Verify → Exit 0 ✅
   Sub-B: Vignette → Verify → Exit 0 ✅
   Sub-C: Haptics → Verify → Exit 0 ✅
3. VERIFY - Final verification → Exit 0 ✅
5. COMPLETE - Report all complete
```

---

## Common Errors & Quick Fixes

| Error | Quick Fix |
|-------|-----------|
| `class_name` conflicts with autoload | Remove `class_name` declaration |
| Missing file/resource | Verify path is correct |
| Parse error in GDScript | Check syntax, fix typos |
| Addon loading failed | Remove broken addon folder |
| Extension load error | Clean `.godot/extension_list.cfg` |

**After fixing:** Re-run verification until exit code 0

---

## Files You Should Update After Completing Work

- `PHASE_N_STATUS.md` - Current phase status
- Completion reports (create new)
- `WHATS_NEXT.md` (if exists)

---

## Documentation Hierarchy

```
UNIVERSAL_MANDATORY_TESTING_PROMPT.md  ← Most comprehensive
    ↓
WORKFLOW_QUICK_START.md                ← Quick reference
    ↓
MANDATORY_AI_CHECKLIST.md              ← Detailed checklist
    ↓
Tool-specific files (.cursorrules, etc.) ← Condensed for each tool
```

**Start with:** `UNIVERSAL_MANDATORY_TESTING_PROMPT.md`

---

## Enforcement

**This workflow is MANDATORY for:**
- All code changes
- All feature implementations
- All bug fixes
- All refactoring
- All testing
- All sub-agent tasks

**Applies to:**
- Main agents
- Sub-agents
- Sub-sub-agents
- All levels (recursive)

**Consequences of skipping:**
- Work is NOT complete
- Errors will be discovered
- Work must be redone
- Trust is lost

---

## Quick Reference Card

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
│ Acceptance: Exit code 0, Errors 0                   │
│ Zero errors is mandatory                            │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## Getting Started

**New AI Agent? Start here:**

1. Read `UNIVERSAL_MANDATORY_TESTING_PROMPT.md` (comprehensive)
2. Read `WORKFLOW_QUICK_START.md` (quick reference)
3. Check tool-specific file for your AI tool
4. Follow the 5-phase workflow
5. Run verification after every change
6. Achieve exit code 0 before completing

**Questions?** See `MANDATORY_AI_CHECKLIST.md` for detailed guidance.

---

**Zero errors is the law. Exit code 0 is mandatory.**

**Version:** 1.0
**Last Updated:** 2025-12-09
**Status:** ACTIVE - All AI agents must follow
