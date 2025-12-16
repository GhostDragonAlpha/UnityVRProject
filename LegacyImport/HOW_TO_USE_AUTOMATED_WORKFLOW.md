# How to Use the Automated Verification Workflow
**Created:** 2025-12-09
**Purpose:** Quick start guide for using automated verification

---

## Quick Start

### For AI Agents (Most Common)

**After making any changes, run:**
```bash
cd C:/Ignotus
python scripts/tools/verify_phase.py --phase 0 --auto-fix
```

**This single command:**
1. Checks project.godot configuration
2. Verifies addon structure (auto-fixes if needed)
3. Restarts Godot with output capture
4. Checks for errors in logs
5. Runs all GdUnit4 tests
6. Generates detailed report
7. Returns exit code (0 = success, 1 = fail, 2 = auto-fixed)

**Duration:** ~30 seconds

**Output:** `VERIFICATION_REPORT_PHASE_0.md` + `verification_results_phase_0.json`

---

## Individual Tools

### 1. Check Project Configuration

```bash
python scripts/tools/check_project_config.py
```

**Verifies:**
- project.godot exists and is valid
- Main scene exists
- All autoloads exist
- All enabled plugins exist

**Exit Code:**
- 0 = All checks passed
- 1 = Errors found

---

### 2. Check/Fix Addon Structure

**Verify only:**
```bash
python scripts/tools/fix_addon_structure.py --verify-only
```

**Auto-fix:**
```bash
python scripts/tools/fix_addon_structure.py --all
```

**Specific addon:**
```bash
python scripts/tools/fix_addon_structure.py godot-xr-tools
```

**Exit Code:**
- 0 = All addons valid
- 1 = Issues found/fixed

---

### 3. Manage Godot Process

**Check if running:**
```bash
python scripts/tools/godot_manager.py --status
```

**Kill Godot:**
```bash
python scripts/tools/godot_manager.py --kill
```

**Start Godot with output capture:**
```bash
python scripts/tools/godot_manager.py --start --capture
```

**Restart Godot:**
```bash
python scripts/tools/godot_manager.py --restart --capture
```

**Console output saved to:** `godot_console.log`

---

### 4. Check Godot Errors

```bash
python scripts/tools/check_godot_errors.py
```

**Generates report:**
```bash
python scripts/tools/check_godot_errors.py --report
```

**Report saved to:** `GODOT_ERROR_REPORT.md`

**Exit Code:**
- 0 = No errors
- 1 = Errors found

---

### 5. Run Tests

**Run all tests:**
```bash
python scripts/tools/run_tests.py
```

**Run specific test:**
```bash
python scripts/tools/run_tests.py tests/unit/test_addon_installation.gd
```

**With report:**
```bash
python scripts/tools/run_tests.py --report
```

**Report saved to:** `TEST_RESULTS.md`

**Exit Code:**
- 0 = All tests passed
- 1 = Test failures

---

## AI Agent Workflow

**After making changes to code/scenes:**

```python
# 1. Run automated verification
import subprocess

result = subprocess.run(
    ["python", "scripts/tools/verify_phase.py", "--phase", "0", "--auto-fix"],
    capture_output=True,
    text=True
)

# 2. Check result
if result.returncode == 0:
    print("✅ All verification passed - ready to commit")
    # Proceed with commit
elif result.returncode == 2:
    print("⚠️ Auto-fixes applied - re-verify")
    # Re-run verification
else:
    print("❌ Verification failed")
    # Analyze errors and fix
```

**Full development loop:**
```
1. Read task
2. Make changes (Edit/Write tools)
3. Run: python scripts/tools/verify_phase.py --phase 0 --auto-fix
4. Wait 30 seconds for result
5. Parse exit code:
   - 0 → Commit changes, mark complete
   - 2 → Re-verify (fixes applied)
   - 1 → Analyze errors, fix, goto 3
```

---

## Exit Codes Summary

| Tool | Code 0 | Code 1 | Code 2 |
|------|--------|--------|--------|
| verify_phase.py | All passed | Failed | Auto-fixed |
| check_project_config.py | Valid | Errors | - |
| fix_addon_structure.py | Valid | Issues | - |
| check_godot_errors.py | No errors | Errors | - |
| run_tests.py | All passed | Failures | - |
| godot_manager.py | Success | Failed | - |

---

## Reports Generated

**After verification, check these files:**

1. `VERIFICATION_REPORT_PHASE_X.md` - Human-readable summary
2. `verification_results_phase_X.json` - Machine-readable results
3. `GODOT_ERROR_REPORT.md` - Godot error analysis
4. `TEST_RESULTS.md` - Test execution results
5. `godot_console.log` - Raw Godot console output
6. `test_output.log` - Raw test output

---

## Common Scenarios

### Scenario 1: I made changes and want to verify everything

```bash
python scripts/tools/verify_phase.py --phase 0 --auto-fix
```

**Duration:** ~30 seconds
**Output:** Comprehensive report

---

### Scenario 2: I added a new addon

```bash
# Verify structure
python scripts/tools/fix_addon_structure.py --all

# Run verification
python scripts/tools/verify_phase.py --phase 0
```

---

### Scenario 3: Godot is acting weird

```bash
# Restart Godot with fresh logs
python scripts/tools/godot_manager.py --restart --capture

# Wait for startup
sleep 10

# Check for errors
python scripts/tools/check_godot_errors.py --report
```

---

### Scenario 4: Tests are failing

```bash
# Run tests with detailed output
python scripts/tools/run_tests.py --report

# Check test_output.log for details
cat test_output.log
```

---

### Scenario 5: Quick sanity check

```bash
# Check project config
python scripts/tools/check_project_config.py

# Check addon structure
python scripts/tools/fix_addon_structure.py --verify-only

# Done (< 5 seconds)
```

---

## Troubleshooting

### "Could not find Godot executable"

**Solution:**
```bash
python scripts/tools/godot_manager.py --godot-path "C:/path/to/godot.exe" --status
```

### "Tests timed out"

**Solution:**
```bash
# Increase timeout
python scripts/tools/run_tests.py --timeout 300
```

### "Permission denied" when killing Godot

**Solution:**
- Close Godot editor manually first
- Or run terminal as administrator

### "Addon structure invalid"

**Solution:**
```bash
# Auto-fix it
python scripts/tools/fix_addon_structure.py --all
```

---

## Integration with Git

**Pre-commit hook example:**

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash

echo "Running automated verification..."
python scripts/tools/verify_phase.py --phase 0

if [ $? -ne 0 ]; then
    echo "❌ Verification failed - cannot commit"
    echo "Run: python scripts/tools/verify_phase.py --phase 0 --auto-fix"
    exit 1
fi

echo "✅ Verification passed"
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

## Benefits of Automated Workflow

**For AI Agents:**
✅ Full autonomy - no user interaction needed
✅ Fast feedback - 30 second verification
✅ Auto-fixes - common issues resolved automatically
✅ Clear reports - know exactly what failed
✅ Exit codes - machine-readable results

**For Users:**
✅ Hands-off - AI handles verification
✅ Always tested - every change verified
✅ Quality assured - catch issues immediately
✅ Fast iteration - no manual checks
✅ Documentation - reports generated automatically

**For Project:**
✅ Regression prevention - tests run constantly
✅ Quality metrics - track pass/fail rates
✅ Reproducibility - same process every time
✅ Scalability - add more checks as needed
✅ CI/CD ready - exit codes for automation

---

## Next Steps

**Phase 0 Complete:**
After verification passes:
```bash
git add .
git commit -m "Phase 0 complete - all verification passed"
git push
```

**Phase 1 Begin:**
Update verify_phase.py to add Phase 1 checks:
- VR tracking verification
- HTTP API endpoint tests
- Performance benchmarks
- etc.

---

## Questions?

**See full documentation:**
- `AUTOMATED_VERIFICATION_WORKFLOW.md` - Complete workflow design
- `ADDON_VERIFICATION_TDD_GUIDE.md` - TDD addon verification
- `PHASE_0_STATUS_UPDATE.md` - Current status

**Check status:**
```bash
python scripts/tools/verify_phase.py --phase 0
cat VERIFICATION_REPORT_PHASE_0.md
```

---

**The automated workflow is ready to use.** 🚀
