# Addon Verification TDD Guide
**Status:** Production Ready
**Last Updated:** 2025-12-09
**Purpose:** Self-validating, recursive addon installation verification

---

## The Problem We Solved

**Before:** You manually enabled godot-xr-tools in Godot editor and got cryptic errors:
```
Can't add Autoload:
res://addons/godot-xr-tools/rumble/rumble_manager.gd is an invalid path. File does not exist.
```

**Root Cause:** The cloned repository had nested structure:
```
addons/godot-xr-tools/addons/godot-xr-tools/rumble/rumble_manager.gd  ❌ Wrong!
```

Should be:
```
addons/godot-xr-tools/rumble/rumble_manager.gd  ✅ Correct!
```

---

## The TDD Solution (Recursive & Self-Healing)

### 1. GdUnit4 Test Suite (The RED)

**File:** `tests/unit/test_addon_installation.gd`

This test suite defines what "correctly installed" means:

```gdscript
func test_godot_xr_tools_directory_structure():
    var addon_path = "res://addons/godot-xr-tools/"
    var required_files = [
        "rumble/rumble_manager.gd",
        "functions/function_pointer.gd",
        "hands/hand.gd",
        "player/player_body.gd",
        "plugin.cfg"
    ]

    for file in required_files:
        assert_file_exists(addon_path + file)
```

**Test Features:**
- ✅ Verifies correct directory structure
- ✅ Checks plugin.cfg validity
- ✅ Detects nested structures
- ✅ Validates autoload paths
- ✅ Smoke tests critical scripts

### 2. Python Auto-Fixer (The GREEN)

**File:** `scripts/tools/fix_addon_structure.py`

Automatically fixes issues found by tests:

```bash
# Fix all addons
python scripts/tools/fix_addon_structure.py --all

# Fix specific addon
python scripts/tools/fix_addon_structure.py godot-xr-tools

# Verify only (no fixes)
python scripts/tools/fix_addon_structure.py --verify-only
```

**Auto-Fixer Features:**
- ✅ Detects nested addon directories
- ✅ Automatically flattens structure
- ✅ Verifies plugin.cfg exists
- ✅ Reports issues clearly
- ✅ Returns proper exit codes for CI/CD

### 3. Recursive Workflow (The REFACTOR)

**The self-healing loop:**

```
1. Clone addon (might have wrong structure)
   ↓
2. Run GdUnit4 tests → FAIL (RED)
   ↓
3. Tests show exact issue + fix command
   ↓
4. Run auto-fixer → Fixes issue
   ↓
5. Re-run tests → PASS (GREEN)
   ↓
6. Godot editor loads addon successfully
   ↓
7. Commit working setup
```

---

## How to Use This System

### Initial Setup (First Time)

```bash
# 1. Clone an addon (e.g., godot-xr-tools)
cd C:/Ignotus/addons
git clone https://github.com/GodotVR/godot-xr-tools.git

# 2. Run auto-fixer to detect/fix issues
python ../scripts/tools/fix_addon_structure.py --all

# 3. Open Godot editor
# Project → Project Settings → Plugins → Enable addon

# 4. If errors appear, run verification tests
# In Godot: Bottom panel → GdUnit4 → Run tests/unit/test_addon_installation.gd

# 5. Tests will show exactly what's wrong and how to fix
```

### Daily Workflow (Automated)

**Add to git pre-commit hook:**

```bash
# .git/hooks/pre-commit
#!/bin/bash

# Verify addon structure before commit
python scripts/tools/fix_addon_structure.py --verify-only

if [ $? -ne 0 ]; then
    echo "ERROR: Addon structure issues detected"
    echo "Run: python scripts/tools/fix_addon_structure.py --all"
    exit 1
fi
```

---

## What The Tests Verify

### 1. Directory Structure
```gdscript
test_godot_xr_tools_directory_structure()
test_no_nested_addon_directories()
```
- No nested `addons/*/addons/*/` structures
- Required files exist at correct paths

### 2. Plugin Configuration
```gdscript
test_godot_xr_tools_plugin_cfg()
test_all_enabled_plugins_have_valid_config()
```
- plugin.cfg exists and is valid
- Has required fields (name, version, script)
- Script file exists

### 3. Autoload Paths
```gdscript
test_godot_xr_tools_autoload_paths()
```
- Autoload scripts exist at expected paths
- No broken path references

### 4. Script Validity
```gdscript
test_can_load_addon_scripts()
```
- Critical scripts can be loaded
- No syntax errors in key files

### 5. Multi-Addon Support
```gdscript
test_gdunit4_installed()
test_godottpd_installed()
test_voxel_addon_installed()
```
- All project addons verified
- Consistent structure across all

---

## Error Messages Guide

### Error: "Has nested structure"

**Test Output:**
```
WARNING godot-xr-tools: Has nested structure (addons/godot-xr-tools/addons/godot-xr-tools)
Run: python scripts/tools/fix_addon_structure.py godot-xr-tools
```

**Fix:**
```bash
python scripts/tools/fix_addon_structure.py godot-xr-tools
```

### Error: "Missing plugin.cfg"

**Cause:** Addon incomplete or wrong directory

**Fix:**
1. Check if you cloned the right repository
2. Verify you're in the addon's root directory
3. Re-clone if necessary

### Error: "Can't load script"

**Cause:** GDScript syntax errors or missing dependencies

**Fix:**
1. Check Godot console for detailed error
2. Verify Godot version compatibility
3. Check addon documentation for requirements

---

## Integration with Phase 0

**Updated Phase 0 Day 3 Checklist:**

```markdown
### Day 3: Install Addons (WITH TDD VERIFICATION)

1. Clone godot-xr-tools
   git clone https://github.com/GodotVR/godot-xr-tools.git addons/godot-xr-tools

2. Run auto-verification
   python scripts/tools/fix_addon_structure.py --all

3. Run GdUnit4 tests (in Godot editor)
   GdUnit4 panel → Run tests/unit/test_addon_installation.gd

4. All tests pass → ✅ Proceed to enable plugin

5. If tests fail → Read error message → Run suggested fix → Re-test
```

---

## Benefits of This Approach

### 1. Self-Documenting
- Tests show exactly what's required
- Error messages include fix commands
- No ambiguity about "correct" structure

### 2. Automated Verification
- No manual checking required
- CI/CD friendly (exit codes)
- Catches issues immediately

### 3. Recursive/Self-Healing
- Tests detect issues
- Auto-fixer resolves issues
- Re-run tests to verify fix
- System validates itself

### 4. Prevents Rewrites
- Catches structural issues before they cause problems
- Validates before committing
- Documents expected state

### 5. Scales Infinitely
- Add new addon? Add new test
- New requirement? Add assertion
- Builds on itself recursively

---

## Future Enhancements

### Phase 1 Extensions:
```gdscript
// Test VR functionality
func test_xr_interface_available():
    var xr = XRServer.find_interface("OpenXR")
    assert_object(xr).is_not_null()

// Test addon integration
func test_xr_tools_autoloads_registered():
    assert_true(has_node("/root/XRTools"))
```

### Phase 2 Extensions:
```gdscript
// Test addon feature functionality
func test_xr_hand_tracking_works():
    var hand = XRTools.Hand.new()
    assert_object(hand).is_not_null()
```

### CI/CD Integration:
```yaml
# .github/workflows/verify-addons.yml
- name: Verify Addon Structure
  run: python scripts/tools/fix_addon_structure.py --verify-only

- name: Run GdUnit4 Addon Tests
  run: godot --headless --script tests/test_runner.gd
```

---

## Troubleshooting

### "Tests don't run in Godot"

1. Verify GdUnit4 is enabled:
   Project → Project Settings → Plugins → GdUnit4 ✅

2. Check GdUnit4 panel exists:
   Bottom of editor should show "GdUnit4" tab

3. Restart Godot editor

### "Auto-fixer doesn't work"

1. Check Python is installed: `python --version`
2. Run with full path: `python C:/Ignotus/scripts/tools/fix_addon_structure.py --all`
3. Check file permissions

### "Tests pass but Godot still shows errors"

1. Restart Godot editor (clear cache)
2. Check project.godot for old addon references
3. Manually remove addon and re-add

---

## Summary

**This system provides:**
- ✅ **RED**: Tests define correct structure
- ✅ **GREEN**: Auto-fixer makes tests pass
- ✅ **REFACTOR**: Tests verify fixes worked
- ✅ **RECURSIVE**: System validates itself
- ✅ **SCALABLE**: Add more tests as needed
- ✅ **AUTOMATED**: No manual checking
- ✅ **SELF-HEALING**: Fixes own issues

**Result:** Never manually debug addon installation again.

---

**Next:** See `PHASE_0_REPORT.md` for integration into Phase 0 workflow.
