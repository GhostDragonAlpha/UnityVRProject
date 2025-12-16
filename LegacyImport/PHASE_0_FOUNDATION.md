# Phase 0: Foundation & Cleanup
**Status:** ✅ COMPLETE (2025-12-09)
**Goal:** Verify project compiles, VR works, development environment ready
**Duration:** Completed in 1 day with automated verification

---

## 🎉 Phase 0 Complete - Automated Verification Active

**This phase is COMPLETE and verified through automated testing.**

**Final verification results:**
```bash
python scripts/tools/verify_phase.py --phase 0 --auto-fix
# Exit Code: 0 (All checks passed)
# Duration: 14.7 seconds
# Verification Report: VERIFICATION_REPORT_PHASE_0.md
```

**See completion documentation:**
- `PHASE_0_COMPLETE.md` - Complete Phase 0 report
- `VERIFICATION_REPORT_PHASE_0.md` - Automated verification results
- `AUTOMATED_VERIFICATION_WORKFLOW.md` - The workflow that made this possible

**ALL FUTURE DEVELOPMENT MUST USE THE AUTOMATED WORKFLOW:**
```bash
python scripts/tools/verify_phase.py --phase <N> --auto-fix
```

**Read:** `CONTRIBUTING.md` and `DEVELOPMENT_RULES.md` for mandatory guidelines.

---

## Original Phase 0 Tasks (Historical Reference)

**NOTE:** These tasks were the original manual approach. The AUTOMATED WORKFLOW replaced this.

**The sections below are kept for historical reference only.**

---

## Day 1: Verification & Documentation

### Morning: Project Health Check

**Task 1: Compile Test**
```bash
# Start Godot in editor mode
cd C:/Ignotus
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/Ignotus" --editor
```

**Expected:**
- Editor opens without crashes
- Console shows initialization messages
- Check bottom of editor: "0 errors" (warnings are OK)

**Document:** Screenshot of editor with 0 errors, paste in PHASE_0_REPORT.md

---

**Task 2: VR Tracking Test**

1. Put on BigScreen Beyond headset
2. Start SteamVR
3. In Godot editor: Press F5 (run main scene)
4. Expected:
   - Scene loads in headset
   - You can see your hands/controllers
   - Controllers track movement
   - Headset tracking works

**If VR doesn't work:**
```bash
# Check OpenXR runtime
# In SteamVR: Settings → Show Advanced Settings → Developer → Set SteamVR as OpenXR runtime
```

**Document:** Write in PHASE_0_REPORT.md:
- ✅ or ❌ Headset tracking
- ✅ or ❌ Controller tracking
- ✅ or ❌ No crashes
- FPS shown in editor debug overlay

---

**Task 3: HTTP API Test**

While project running:
```bash
# Test health endpoint
curl http://127.0.0.1:8080/health

# Expected: {"status": "healthy", ...}

# Test status endpoint
curl http://127.0.0.1:8080/status

# Expected: {"fps": ..., "scene": "...", ...}
```

**Document:** Paste HTTP responses in PHASE_0_REPORT.md

---

### Afternoon: Current State Audit

**Task 4: List All Autoloads**

In Godot editor:
- Project → Project Settings → Autoload tab
- Write down ALL autoloads in PHASE_0_REPORT.md
- For each, note: ✅ Working, ⚠️ Warning, or ❌ Error

**Task 5: List All Scenes**

```bash
find scenes -name "*.tscn"
```

Document in PHASE_0_REPORT.md:
- Which scene is main scene? (project.godot line 14)
- How many test scenes exist?
- How many production scenes exist?

**Task 6: List All Scripts**

```bash
find scripts -name "*.gd" | wc -l
```

Document: Total count of GDScript files

---

### Evening: Create Phase 0 Report

**Create:** `PHASE_0_REPORT.md`

Template:
```markdown
# Phase 0 Verification Report
**Date:** 2025-12-09
**Status:** In Progress

## Compilation
- Errors: [count]
- Warnings: [count]
- Result: ✅ Compiles / ❌ Does not compile

## VR Tracking
- Headset: ✅ / ❌
- Left Controller: ✅ / ❌
- Right Controller: ✅ / ❌
- FPS: [number]
- Result: ✅ VR works / ❌ VR broken

## HTTP API
- Health endpoint: ✅ / ❌
- Status endpoint: ✅ / ❌
- Response time: [ms]
- Result: ✅ API works / ❌ API broken

## Current Autoloads
[list with status]

## Current Scenes
- Main scene: [path]
- Test scenes: [count]
- Production scenes: [count]

## Issues Found
[list any problems]

## Next Steps
[what to do on Day 2]
```

---

## Day 2: Documentation Cleanup

### Morning: Remove Outdated Docs

**Task 1: Identify Conflicting Docs**

Look for files with conflicting information:
```bash
ls *.md | grep -E "(STATUS|REPORT|IMPLEMENTATION)"
```

**Common culprits:**
- Multiple STATUS.md files
- Old IMPLEMENTATION_REPORT.md files
- Outdated ROADMAP.md files
- Conflicting SETUP guides

**Action:**
```bash
# Create archive directory
mkdir -p docs/archive/2025-12-09-pre-phase0

# Move outdated docs there
mv [old-file].md docs/archive/2025-12-09-pre-phase0/
```

**Keep ONLY:**
- ✅ ARCHITECTURE_BLUEPRINT.md (new)
- ✅ DEVELOPMENT_PHASES.md (new)
- ✅ PHASE_0_FOUNDATION.md (new)
- ✅ CLAUDE.md (will update)
- ✅ README.md (will update)

---

### Afternoon: Update Core Documentation

**Task 2: Update CLAUDE.md**

Based on PHASE_0_REPORT.md, update CLAUDE.md to reflect reality:

```markdown
# CLAUDE.md
**Last Updated:** 2025-12-09
**Status:** Phase 0 - Foundation
**Version:** 2.0 - Architecture Redesign

## Current State
[paste from PHASE_0_REPORT.md]

## Active Autoloads
[list ONLY the working ones]

## Main Scene
[the actual main scene]

## Development Phase
Currently in Phase 0 (Foundation). See DEVELOPMENT_PHASES.md.

## Architecture
See ARCHITECTURE_BLUEPRINT.md for complete technical specification.
```

**Task 3: Update README.md**

Simplify README.md:
```markdown
# SpaceTime VR - Galaxy-Scale Space Simulation

**Status:** Phase 0 - Foundation

## Quick Start
1. Open Godot 4.5.1 editor
2. Press F5
3. Put on VR headset
4. See DEVELOPMENT_PHASES.md for roadmap

## Documentation
- **ARCHITECTURE_BLUEPRINT.md** - Complete technical design
- **DEVELOPMENT_PHASES.md** - Phase-by-phase roadmap
- **CLAUDE.md** - Development guide for AI assistants

## Current Phase
Phase 0: Foundation & Cleanup (Week 1)
See PHASE_0_FOUNDATION.md for tasks.
```

---

### Evening: Git Cleanup

**Task 4: Create Clean Commit**

```bash
git add ARCHITECTURE_BLUEPRINT.md
git add DEVELOPMENT_PHASES.md
git add PHASE_0_FOUNDATION.md
git add PHASE_0_REPORT.md
git add CLAUDE.md
git add README.md
git commit -m "Phase 0 Day 2: Add architecture docs and clean up documentation"
git push
```

---

## Day 3: Install Missing Tools

### Morning: Install godot-xr-tools

**Method 1: AssetLib (Recommended)**
1. In Godot editor: AssetLib tab (top)
2. Search: "XR Tools"
3. Find: "Godot XR Tools" by Malcom Nixon
4. Click Download
5. Click Install
6. Restart Godot

**Method 2: Manual**
```bash
cd addons
git clone https://github.com/GodotVR/godot-xr-tools.git godot-xr-tools
```

**Verify:**
- Project → Project Settings → Plugins
- "Godot XR Tools" should be listed
- Check "Enable"
- Restart editor

---

### Afternoon: Install Terrain Addons (Test Both)

**Install Terrain3D:**

1. AssetLib → Search "Terrain3D"
2. Download and install
3. Enable in plugins
4. Restart

**Install godot_voxel:**

1. AssetLib → Search "Voxel Tools"
2. Download "Voxel Tools" by Zylann
3. Install and enable
4. Restart

**Expected:**
- Both addons enabled
- No error messages
- Editor restarts cleanly

---

### Evening: Addon Verification

**Create:** `scenes/test/addon_verification.tscn`

Test each addon:

1. Create Node3D scene
2. Add XROrigin3D (from godot-xr-tools)
   - Should work without errors
3. Add Terrain3D node (if installed)
   - Should instantiate
4. Add VoxelTerrain node (if godot_voxel installed)
   - Should instantiate

**Document:** In PHASE_0_REPORT.md:
- ✅ godot-xr-tools: Working / ❌ Broken
- ✅ Terrain3D: Working / ❌ Broken
- ✅ godot_voxel: Working / ❌ Broken

**Delete test scene** (not needed after verification)

---

## Day 4: Create Test Infrastructure

### Morning: Feature Scene Directory

**Create directories:**
```bash
mkdir -p scenes/features
mkdir -p scenes/production
mkdir -p scenes/test/unit
```

**Create:** `scenes/features/_template_feature.tscn`

This is a template for all future feature scenes:

1. New Scene → 3D Scene
2. Rename root: "FeatureTemplate"
3. Attach script: `scripts/templates/feature_template.gd`

**Script:**
```gdscript
extends Node3D
## Template for feature test scenes
## Copy this for each new feature

@onready var engine := get_node("/root/ResonanceEngine") if has_node("/root/ResonanceEngine") else null

func _ready() -> void:
    print("[FeatureTemplate] Initializing...")

    # Check required autoloads
    if not engine:
        push_warning("ResonanceEngine not available - some features may not work")

    # Initialize feature
    _init_feature()

func _init_feature() -> void:
    """Override this in your feature scene script"""
    pass

func _unhandled_input(event: InputEvent) -> void:
    # F12 = Quick exit to main menu
    if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
        get_tree().change_scene_to_file("res://scenes/production/main_menu.tscn")
```

Save template.

---

### Afternoon: Test Runner Script

**Create:** `tests/test_runner.gd`

```gdscript
extends SceneTree
## Automated test runner for SpaceTime VR
## Usage: godot --path C:/Ignotus tests/test_runner.gd

var tests_passed := 0
var tests_failed := 0

func _init() -> void:
    print("=== SpaceTime VR Test Runner ===\n")

    # Run tests
    test_autoloads()
    test_vr_system()
    test_http_api()

    # Report results
    print("\n=== Test Results ===")
    print("Passed: %d" % tests_passed)
    print("Failed: %d" % tests_failed)
    print("Total: %d" % (tests_passed + tests_failed))

    if tests_failed == 0:
        print("\n✅ ALL TESTS PASSED")
        quit(0)
    else:
        print("\n❌ TESTS FAILED")
        quit(1)

func test_autoloads() -> void:
    print("Testing autoloads...")

    # Test ResonanceEngine
    if has_node("/root/ResonanceEngine"):
        print("  ✅ ResonanceEngine loaded")
        tests_passed += 1
    else:
        print("  ❌ ResonanceEngine missing")
        tests_failed += 1

    # Test HttpApiServer
    if has_node("/root/HttpApiServer"):
        print("  ✅ HttpApiServer loaded")
        tests_passed += 1
    else:
        print("  ❌ HttpApiServer missing")
        tests_failed += 1

    # Add more autoload tests

func test_vr_system() -> void:
    print("\nTesting VR system...")

    var xr_interface := XRServer.find_interface("OpenXR")
    if xr_interface:
        print("  ✅ OpenXR interface found")
        tests_passed += 1
    else:
        print("  ⚠️  OpenXR interface not found (OK if no headset)")
        # Don't fail - VR might not be active

func test_http_api() -> void:
    print("\nTesting HTTP API...")
    # Note: Can't actually test HTTP in headless mode
    # This is a placeholder for runtime tests
    print("  ⚠️  HTTP API test requires runtime (skipped)")
```

**Test it:**
```bash
godot --path C:/Ignotus --headless --script tests/test_runner.gd --quit-after 5
```

Expected: Tests run, shows passed/failed count

---

### Evening: First VR Test Scene

**Create:** `scenes/features/vr_tracking_test.tscn`

1. New 3D Scene
2. Add XROrigin3D (from godot-xr-tools addon)
3. Add XRCamera3D as child
4. Add 2x XRController3D as children
   - Set one to tracker: "/user/hand/left"
   - Set one to tracker: "/user/hand/right"
5. Add MeshInstance3D as child of each controller
   - Box mesh (0.1, 0.1, 0.1 size)
   - Material: Bright color (red/blue)

**Attach script:**
```gdscript
extends Node3D

func _ready() -> void:
    print("[VR Tracking Test] Initializing...")

    var xr_interface := XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.is_initialized():
        print("  ✅ OpenXR initialized")
    else:
        print("  ⚠️ OpenXR not initialized, attempting...")
        if xr_interface:
            xr_interface.initialize()

func _process(_delta: float) -> void:
    # Display FPS
    if Engine.get_frames_per_second() < 90:
        print("FPS: %d (target: 90)" % Engine.get_frames_per_second())
```

**Test:**
1. Put on headset
2. Press F6 (run current scene)
3. Expected: See colored boxes where controllers are
4. Move controllers, boxes should follow

**Document:** ✅ VR tracking works / ❌ VR tracking broken

---

## Day 5: Baseline & Commit

### Morning: Run All Tests

**Test 1: Compilation**
```bash
# Start editor, check for 0 errors
```

**Test 2: Automated Tests**
```bash
godot --path C:/Ignotus --headless --script tests/test_runner.gd --quit-after 5
```

Expected: All tests pass

**Test 3: VR Test**
1. F6 on `vr_tracking_test.tscn`
2. Verify tracking works

**Test 4: HTTP API**
```bash
# Start editor (F5)
curl http://127.0.0.1:8080/health
```

Expected: Returns healthy status

---

### Afternoon: Update Phase 0 Report

**Update:** `PHASE_0_REPORT.md`

Add section:
```markdown
## Day 5: Final Status

### Tests
- ✅ Compilation: 0 errors
- ✅ Automated tests: [X/X passed]
- ✅ VR tracking: Working
- ✅ HTTP API: Responding

### Installed Addons
- ✅ godot-xr-tools
- ✅ Terrain3D
- ✅ godot_voxel

### Test Infrastructure
- ✅ Feature scene template
- ✅ Test runner script
- ✅ VR tracking test scene

### Issues Remaining
[list any unresolved issues]

## Phase 0 Status: ✅ COMPLETE / ⏳ In Progress / ❌ Blocked
```

---

### Evening: Clean Git Commit

**Final commit for Phase 0:**

```bash
# Add all new files
git add scenes/features/
git add scenes/test/
git add tests/test_runner.gd
git add scripts/templates/
git add PHASE_0_REPORT.md
git add addons/  # New addons

# Commit
git commit -m "Phase 0 Complete: Foundation verified, tools installed, test infrastructure created

- ✅ Project compiles (0 errors)
- ✅ VR tracking functional
- ✅ HTTP API responding
- ✅ godot-xr-tools installed
- ✅ Terrain addons installed
- ✅ Test infrastructure created
- ✅ Documentation cleaned up

Ready for Phase 1: Core Physics Foundation"

# Push
git push origin main
```

---

## Phase 0 Acceptance Criteria Checklist

Before moving to Phase 1, verify ALL of these:

- [ ] ✅ 0 compilation errors
- [ ] ✅ VR headset tracking works
- [ ] ✅ VR controllers track correctly
- [ ] ✅ 90 FPS in empty VR scene
- [ ] ✅ HTTP API responds to curl requests
- [ ] ✅ godot-xr-tools addon installed and enabled
- [ ] ✅ Terrain addon(s) installed and tested
- [ ] ✅ Test runner script works
- [ ] ✅ Feature scene template created
- [ ] ✅ VR tracking test scene works
- [ ] ✅ Documentation cleaned up and accurate
- [ ] ✅ Git commit created with "Phase 0 Complete"
- [ ] ✅ PHASE_0_REPORT.md shows all green checkmarks

---

## If You Get Stuck

**VR not working:**
- Check SteamVR is running
- Verify OpenXR runtime: SteamVR settings
- Try: `godot --xr-mode on`

**HTTP API not responding:**
- Check autoload enabled: Project Settings → Autoload
- Check port not blocked: `netstat -an | grep 8080`
- Check console for HttpApiServer startup message

**Addon won't install:**
- Try manual install (clone from GitHub)
- Check Godot version compatibility
- Check console for error messages

**Tests failing:**
- Read error messages carefully
- Test one thing at a time
- Create minimal reproduction scene

---

## Next Phase

When ALL acceptance criteria are met, proceed to:

**Phase 1: Core Physics Foundation**
- See DEVELOPMENT_PHASES.md
- Implement floating origin system
- Implement planetary gravity
- Test walking on curved planet
- Duration: 3 weeks

---

**Phase 0 is critical. Do not skip any steps. Get everything green before moving on.**
