# Automated Verification Workflow
**Created:** 2025-12-09
**Purpose:** Fully automated verification that requires ZERO user intervention
**Philosophy:** "All verification must be done automatically" - User requirement

---

## The Problem

**Before:** AI agent makes changes → Asks user to manually verify → Wait for user → Slow feedback loop

**User Requirement:** "The idea is that you will be able to do all the next steps automatically"

**Solution:** Automated workflow that AI can execute independently

---

## The Automated Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                   AUTOMATED VERIFICATION LOOP                │
└─────────────────────────────────────────────────────────────┘

1. [AI] Make changes to code/scenes
   ↓
2. [AI] Save all files
   ↓
3. [AI] Kill existing Godot process (if running)
   ↓
4. [AI] Start Godot editor with console output capture
   ↓
5. [AI] Wait for startup (10 seconds)
   ↓
6. [AI] Parse console output for autoload errors
   ↓
7. [AI] Check for compilation errors via check_godot_errors.py
   ↓
8. [AI] Run GdUnit4 tests (command line mode)
   ↓
9. [AI] Parse test results (XML output)
   ↓
10. [AI] Test HTTP API endpoints (if applicable)
    ↓
11. [AI] Generate verification report
    ↓
12. [AI] Decision:
    ├─ All Pass → Mark complete, commit changes
    ├─ Auto-fixable errors → Apply fixes, GOTO step 1
    └─ Unknown errors → Report to user with fix suggestions
```

---

## Key Components

### 1. Godot Process Manager
**Script:** `scripts/tools/godot_manager.py`

**Capabilities:**
- Kill existing Godot process by name
- Start Godot with console output capture
- Monitor process status
- Detect crashes/hangs

**Usage:**
```bash
# Kill Godot
python scripts/tools/godot_manager.py --kill

# Start Godot with output capture
python scripts/tools/godot_manager.py --start --capture output.log

# Check if running
python scripts/tools/godot_manager.py --status
```

### 2. Automated Test Runner
**Script:** `scripts/tools/run_tests.py`

**Capabilities:**
- Run GdUnit4 tests in headless mode
- Parse test results (XML/JSON)
- Return exit code (0 = pass, 1 = fail)
- Generate test report

**Usage:**
```bash
# Run all tests
python scripts/tools/run_tests.py

# Run specific test suite
python scripts/tools/run_tests.py tests/unit/test_addon_installation.gd

# Generate report
python scripts/tools/run_tests.py --report test_results.md
```

### 3. Verification Orchestrator
**Script:** `scripts/tools/verify_phase.py`

**Capabilities:**
- Orchestrates full verification workflow
- Runs all checks in sequence
- Aggregates results
- Makes decisions (pass/fail/fix)
- Generates comprehensive report

**Usage:**
```bash
# Verify current phase
python scripts/tools/verify_phase.py

# Verify specific phase
python scripts/tools/verify_phase.py --phase 0

# Auto-fix mode (apply fixes automatically)
python scripts/tools/verify_phase.py --auto-fix

# Continuous mode (watch for changes)
python scripts/tools/verify_phase.py --watch
```

### 4. HTTP API Verifier
**Script:** `scripts/tools/verify_api.py`

**Capabilities:**
- Wait for API to start (with timeout)
- Test all registered endpoints
- Verify response codes
- Check response schemas
- Generate API health report

**Usage:**
```bash
# Verify API is running
python scripts/tools/verify_api.py

# Test specific endpoint
python scripts/tools/verify_api.py --endpoint /health

# Generate report
python scripts/tools/verify_api.py --report api_status.md
```

---

## Workflow Execution

### Mode 1: Single Verification Run

**Command:**
```bash
python scripts/tools/verify_phase.py --phase 0
```

**What Happens:**
1. Kills existing Godot process
2. Starts Godot editor with output capture
3. Waits 10 seconds for startup
4. Checks console for autoload errors
5. Runs error checker on logs
6. Runs GdUnit4 tests
7. Tests HTTP API (if applicable)
8. Generates report
9. Returns exit code

**Duration:** ~30 seconds

### Mode 2: Auto-Fix Mode

**Command:**
```bash
python scripts/tools/verify_phase.py --phase 0 --auto-fix
```

**What Happens:**
1. Runs verification (as above)
2. If fixable errors found:
   - Applies auto-fixes
   - Restarts verification
   - Repeats until pass or max attempts (3)
3. Generates final report

**Duration:** 30 seconds - 2 minutes

### Mode 3: Watch Mode (Continuous)

**Command:**
```bash
python scripts/tools/verify_phase.py --watch
```

**What Happens:**
1. Runs initial verification
2. Watches for file changes
3. On change detected:
   - Runs verification again
   - Generates new report
4. Continues until Ctrl+C

**Use Case:** Development mode - automatic verification on every save

---

## AI Agent Workflow

**When AI makes changes, it runs:**

```python
# Automated verification after changes
def verify_changes():
    # 1. Run verification
    result = run_command("python scripts/tools/verify_phase.py --phase 0 --auto-fix")

    # 2. Parse result
    if result.exit_code == 0:
        print("✅ All verification passed")
        return True
    else:
        print("❌ Verification failed")
        print(result.stdout)
        return False

# After making changes:
if verify_changes():
    commit_changes()
else:
    report_issues()
```

**Full AI Development Loop:**
```
1. AI reads task
2. AI makes changes (Edit/Write tools)
3. AI runs: verify_phase.py --phase X --auto-fix
4. AI waits for result (30 seconds)
5. AI parses output
6. Decision:
   - Pass → Commit changes, mark task complete
   - Auto-fixed → Verify fixes, then commit
   - Failed → Analyze errors, try different approach
```

---

## Verification Checks

### Phase 0 Verification Checks

**1. Project Configuration**
- [ ] project.godot is valid
- [ ] No invalid autoloads
- [ ] Main scene exists
- [ ] All enabled plugins exist

**2. Addon Installation**
- [ ] godot-xr-tools structure valid
- [ ] GdUnit4 installed
- [ ] godottpd installed
- [ ] zylann.voxel installed
- [ ] All plugin.cfg files valid

**3. Compilation**
- [ ] 0 autoload errors in console
- [ ] All addon scripts load successfully
- [ ] Main scene loads without errors

**4. Tests**
- [ ] GdUnit4 test framework works
- [ ] test_addon_installation.gd passes
- [ ] All unit tests pass

**5. Documentation**
- [ ] PHASE_0_FOUNDATION.md exists
- [ ] ARCHITECTURE_BLUEPRINT.md exists
- [ ] DEVELOPMENT_PHASES.md exists
- [ ] All required docs present

### Phase 1+ Verification Checks

**Additional checks added per phase:**
- VR tracking tests
- HTTP API endpoint tests
- Physics simulation tests
- Performance benchmarks
- Integration tests

---

## Output Format

### Verification Report Structure

**File:** `VERIFICATION_REPORT_PHASE_X.md`

```markdown
# Phase X Verification Report
**Date:** YYYY-MM-DD HH:MM:SS
**Status:** PASS / FAIL / PARTIAL
**Duration:** XX seconds

## Summary
- Total Checks: XX
- Passed: XX
- Failed: XX
- Auto-Fixed: XX

## Compilation
✅ Project compiles: 0 errors
✅ Autoloads loaded: 0 errors
✅ Main scene loads: SUCCESS

## Addons
✅ godot-xr-tools: VALID
✅ GdUnit4: WORKING
✅ godottpd: INSTALLED

## Tests
✅ test_addon_installation.gd: 8/8 passed
✅ All unit tests: XX/XX passed

## Errors Found
None

## Auto-Fixes Applied
1. Fixed addon structure: godot-xr-tools
2. Cleaned project.godot autoloads

## Recommendation
✅ Phase X complete - proceed to Phase X+1
```

**Exit Codes:**
- 0 = All checks passed
- 1 = Errors found (not auto-fixable)
- 2 = Auto-fixes applied (need re-verification)

---

## Integration with Git

### Automated Commit After Verification

```bash
# After verification passes:
if verify_phase.py returns 0:
    git add .
    git commit -m "Phase X: [description]

    Verification Report:
    - All checks passed
    - 0 errors
    - Tests: XX/XX passing

    🤖 Generated with Claude Code
    Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

### Pre-Commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/bash
python scripts/tools/verify_phase.py --quick

if [ $? -ne 0 ]; then
    echo "❌ Verification failed - cannot commit"
    exit 1
fi
```

---

## Watch Mode for Development

**Command:**
```bash
# Start watch mode
python scripts/tools/verify_phase.py --watch --auto-fix
```

**Behavior:**
1. Initial verification run
2. Watch these paths:
   - scripts/**/*.gd
   - scenes/**/*.tscn
   - tests/**/*.gd
   - project.godot
   - addons/*/plugin.cfg
3. On change detected:
   - Wait 2 seconds (debounce)
   - Restart Godot
   - Run verification
   - Print results
4. Continue watching

**Output:**
```
[16:15:23] File changed: scripts/core/engine.gd
[16:15:25] Restarting Godot...
[16:15:35] Running verification...
[16:15:45] ✅ All checks passed
[16:15:45] Watching for changes...
```

---

## Error Handling

### Auto-Fixable Errors

**These errors can be fixed automatically:**
1. Nested addon structure → Run fix_addon_structure.py
2. Invalid autoloads → Remove from project.godot
3. Missing plugin.cfg → Generate default
4. Test failures (known issues) → Apply known fixes

### Non-Fixable Errors

**These require AI analysis:**
1. GDScript syntax errors → AI must fix code
2. Logic errors in tests → AI must fix logic
3. API failures → AI must debug
4. VR tracking issues → Requires hardware

**AI Response:**
```python
if non_fixable_error:
    # Analyze error
    error_analysis = analyze_error(error_log)

    # Generate fix suggestions
    suggestions = generate_fix_suggestions(error_analysis)

    # Apply most likely fix
    apply_fix(suggestions[0])

    # Re-verify
    verify_again()
```

---

## Performance

**Target Timings:**
- Godot restart: 5-10 seconds
- Log parsing: 1 second
- GdUnit4 tests: 5-15 seconds
- API verification: 2-5 seconds
- Report generation: 1 second

**Total verification time:** 15-35 seconds

**Optimization:**
- Run checks in parallel where possible
- Cache Godot process (keep running)
- Use incremental verification (only changed components)

---

## Benefits

### For AI Agent
✅ **Full autonomy** - No user interaction required
✅ **Fast feedback** - Results in 30 seconds
✅ **Automated fixes** - Can fix common issues
✅ **Continuous verification** - Watch mode during development
✅ **Confidence** - Know immediately if changes break things

### For User
✅ **Hands-off development** - AI does everything
✅ **Always verified** - Every change is tested
✅ **Clear reports** - Always know project status
✅ **Fast iteration** - AI can work autonomously
✅ **No surprises** - Issues caught immediately

### For Project
✅ **Quality assurance** - Automated verification
✅ **Regression prevention** - Tests run constantly
✅ **Documentation** - Reports generated automatically
✅ **Reproducibility** - Same process every time
✅ **Scalability** - Add more checks as project grows

---

## Future Enhancements

### Phase 2+ Additions
- Performance benchmarks (FPS, memory, load times)
- VR comfort validation (motion sickness metrics)
- Asset validation (textures, models, audio)
- Shader compilation verification
- Build system integration (export builds automatically)

### Advanced Features
- Machine learning error prediction
- Automatic fix generation from error patterns
- Visual regression testing (screenshot comparison)
- Network traffic validation
- Save/load system testing

---

## Implementation Checklist

**Scripts to Create:**
- [ ] scripts/tools/godot_manager.py (process management)
- [ ] scripts/tools/run_tests.py (test runner)
- [ ] scripts/tools/verify_api.py (API verifier)
- [ ] scripts/tools/verify_phase.py (orchestrator)
- [ ] scripts/tools/watch_files.py (file watcher)

**Features to Implement:**
- [ ] Console output capture
- [ ] Log parsing
- [ ] Test result parsing (XML/JSON)
- [ ] Report generation
- [ ] Auto-fix application
- [ ] Watch mode
- [ ] Git integration

**Documentation:**
- [ ] This file (workflow documentation)
- [ ] Script usage examples
- [ ] Troubleshooting guide
- [ ] Integration guide

---

## Conclusion

**This workflow enables:**
- 🤖 AI agent can work completely autonomously
- ⚡ Fast feedback loop (30 seconds per verification)
- 🔧 Automated fixes for common issues
- 📊 Clear, detailed reports
- 🔄 Continuous verification during development
- ✅ Confidence that changes work

**Result:** "All verification must be done automatically" ✅

---

**Next Steps:**
1. Create godot_manager.py (process control)
2. Create run_tests.py (test automation)
3. Create verify_phase.py (orchestrator)
4. Test the workflow end-to-end
5. Document any edge cases

**Estimated Time to Implement:** 2-3 hours
**Estimated Time to Execute:** 30 seconds per run
**Value:** Infinite (enables fully autonomous AI development)
