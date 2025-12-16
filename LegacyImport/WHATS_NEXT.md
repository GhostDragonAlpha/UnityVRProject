# What's Next - Phase 1: Core Physics Foundation

**Date:** 2025-12-09
**Phase 0 Status:** ✅ COMPLETE (95%)
**Next Phase:** Phase 1: Core Physics Foundation
**Duration:** 3 weeks (Weeks 2-4)

---

## 🎉 Phase 0 Complete!

**What We Accomplished:**
- ✅ Project configuration validated
- ✅ All required addons installed and verified
- ✅ Automated verification system operational
- ✅ TDD/self-healing framework working
- ✅ Godot starts cleanly (4.3 seconds)
- ✅ Zero critical blockers
- ✅ Documentation enforces mandatory workflow

**Verification Results:**
```bash
python scripts/tools/verify_phase.py --phase 0 --auto-fix
# Exit Code: 0
# Duration: 14.7s
# Result: ALL CHECKS PASSED ✅
```

---

## 🚀 Phase 1: Core Physics Foundation

**Goal:** Implement floating origin and basic gravity so player can walk on a planet.

**Timeline:** Weeks 2-4 (3 weeks)

**Estimated Effort:** ~60-80 hours of development

---

## Week 2: Floating Origin System ✅ COMPLETE

**Status:** ✅ COMPLETE (2025-12-09)
**Verification:** ✅ PASS (exit code 0)
**Manual Testing:** ✅ COMPLETE (0 errors)
**Human Verification:** ✅ CONFIRMED
**Documentation:** See COMPLETION_REPORT_PHASE_1_WEEK_2.md

**Purpose:** Enable large-scale universe without floating-point precision errors

### Tasks

**1. Create FloatingOriginSystem (Autoload)**
- [x] File: `scripts/core/floating_origin_system.gd`
- [x] Implement object registration system
- [x] Implement universe shifting (threshold: 10km)
- [x] Track player position globally
- [x] Shift all tracked objects when threshold exceeded

**2. Create Test Scene**
- [x] File: `scenes/features/floating_origin_test.tscn`
- [x] Simple plane to walk on
- [x] Distance counter (shows actual distance traveled)
- [x] Grid markers every 2km (updated from 10km)
- [x] VR teleport to move long distances quickly

**3. Write Unit Tests**
- [x] File: `tests/unit/test_floating_origin.gd`
- [x] Test: Registration/unregistration
- [x] Test: Universe shift at 10km threshold
- [x] Test: Multiple objects shift together
- [x] Test: No jitter after shift
- [x] 20+ comprehensive unit tests written

**4. Verification**
```bash
# Automated verification - PASSED
python scripts/tools/verify_phase.py --phase 1 --auto-fix
# Exit Code: 0 ✅
```

**Acceptance:**
- ✅ Can walk 20km+ without floating-point jitter
- ✅ All registered objects shift together
- ✅ No stuttering during universe shift
- ✅ All automated verification passing

---

## Week 3: Gravity & Planetary Walking

**Purpose:** Enable walking on curved planet surfaces with correct gravity

### Tasks

**1. Create GravityManager (Autoload)**
- [ ] File: `scripts/core/gravity_manager.gd`
- [ ] Implement spherical gravity (points to planet center)
- [ ] Support multiple gravity sources
- [ ] Implement gravity falloff (inverse square law)
- [ ] Calculate gravity strength based on mass/distance

**2. Create Test Planet**
- [ ] File: `scenes/features/test_planet.tscn`
- [ ] Procedural sphere mesh (small - 100m radius)
- [ ] Apply gravity to player
- [ ] Collision mesh
- [ ] Visual grid for orientation

**3. Implement Gravity Transitions**
- [ ] Smooth falloff as you move away from planet
- [ ] Support entering/leaving gravity wells
- [ ] Handle multiple overlapping gravity sources

**4. Test Walking on Curved Surface**
- [ ] File: `scenes/features/planetary_gravity_test.tscn`
- [ ] Walk completely around small planet
- [ ] Verify orientation follows surface normal
- [ ] Test jumping (falls back to surface)

**5. Write Unit Tests**
- [ ] File: `tests/unit/test_gravity_manager.gd`
- [ ] Test: Gravity direction points to center
- [ ] Test: Gravity strength decreases with distance
- [ ] Test: Multiple gravity sources combine correctly

**Acceptance:**
- ✅ Can walk on spherical planet surface
- ✅ Gravity direction always correct
- ✅ Can walk 360° around planet
- ✅ Jumping works correctly
- ✅ All tests passing

---

## Week 4: VR Comfort & Polish

**Purpose:** Ensure VR experience is comfortable and prevents motion sickness

### Tasks

**1. Create VRComfortSystem (Autoload)**
- [ ] File: `scripts/vr/vr_comfort_system.gd`
- [ ] Implement vignette effect (darkens edges during movement)
- [ ] Implement snap turning (30° increments)
- [ ] Implement comfort mode toggle
- [ ] Add haptic feedback on footsteps

**2. Implement Vignette**
- [ ] Fades in when player moves
- [ ] Intensity based on movement speed
- [ ] Configurable radius and darkness
- [ ] Test: Reduces motion sickness

**3. Implement Snap Turning**
- [ ] Rotate by 30° increments (configurable)
- [ ] Button binding (controller thumbstick)
- [ ] Visual indicator during turn
- [ ] Option for smooth turning (for advanced users)

**4. Add Haptic Feedback**
- [ ] Pulse on footsteps
- [ ] Pulse on landing from jump
- [ ] Pulse when entering gravity well
- [ ] Configurable intensity

**5. VR Testing Session**
- [ ] 30 minute VR session
- [ ] Walk around planet
- [ ] Test all comfort features
- [ ] Document any motion sickness
- [ ] Adjust settings as needed

**6. Performance Optimization**
- [ ] Profile frame time
- [ ] Target: 90 FPS in VR
- [ ] Optimize rendering (LOD, culling)
- [ ] Optimize physics (spatial partitioning)

**7. Create Test Scene**
- [ ] File: `scenes/features/vr_comfort_test.tscn`
- [ ] Planet to walk on
- [ ] Toggle buttons for comfort features
- [ ] FPS display
- [ ] Movement speed indicator

**Acceptance:**
- ✅ 90 FPS maintained in VR
- ✅ No motion sickness in 30 min session
- ✅ Vignette reduces discomfort
- ✅ Snap turning feels natural
- ✅ Haptics add immersion
- ✅ All tests passing

---

## Phase 1 Acceptance Criteria

**Before marking Phase 1 complete, ALL must be true:**

### Functional
- ✅ Walk on spherical planet (gravity correct)
- ✅ Walk 100km without jitter (floating origin works)
- ✅ Gravity direction always points to planet center
- ✅ Can walk 360° around planet
- ✅ Jump and land correctly

### Performance
- ✅ 90 FPS maintained in VR
- ✅ No stuttering during universe shifts
- ✅ Smooth gravity transitions

### Comfort
- ✅ No motion sickness in 30 min VR test
- ✅ Vignette effect feels natural
- ✅ Snap turning works correctly
- ✅ Haptics add to experience

### Quality
- ✅ All unit tests pass
- ✅ Automated verification passes (exit code 0)
- ✅ No compilation errors
- ✅ All scenes load correctly

### Verification Command
```bash
# Must return exit code 0
python scripts/tools/verify_phase.py --phase 1 --auto-fix
```

---

## Phase 1 Feature Test Scenes

**Create these scenes during Phase 1:**

1. **`scenes/features/floating_origin_test.tscn`**
   - Test walking long distances
   - Distance counter
   - Grid markers every 10km

2. **`scenes/features/planetary_gravity_test.tscn`**
   - Small test planet (100m radius)
   - Walk completely around
   - Test jumping

3. **`scenes/features/vr_comfort_test.tscn`**
   - Test vignette effect
   - Test snap turning
   - Toggle comfort features
   - FPS display

4. **`scenes/production/planet_walk_demo.tscn`**
   - Polished demo scene
   - Larger planet
   - Visual landmarks
   - Performance optimized

---

## Required Autoloads for Phase 1

**Add to project.godot:**

```gdscript
[autoload]

# Phase 0 (existing)
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"

# Phase 1 (new)
FloatingOriginSystem="*res://scripts/core/floating_origin_system.gd"
GravityManager="*res://scripts/core/gravity_manager.gd"
VRComfortSystem="*res://scripts/vr/vr_comfort_system.gd"
```

---

## Unit Tests to Create

**Phase 1 test suite:**

1. **`tests/unit/test_floating_origin.gd`**
   - Test registration
   - Test universe shifting
   - Test no jitter after shift
   - Test multiple objects

2. **`tests/unit/test_gravity_manager.gd`**
   - Test spherical gravity
   - Test gravity falloff
   - Test multiple sources
   - Test gravity transitions

3. **`tests/unit/test_vr_comfort.gd`**
   - Test vignette activation
   - Test snap turning
   - Test haptic feedback
   - Test comfort settings

---

## Update Automated Verification for Phase 1

**Extend `scripts/tools/verify_phase.py`:**

Add Phase 1 verification checks:
```python
def verify_phase_1(self):
    """Verify Phase 1 requirements"""

    # Check autoloads exist
    self.run_check(
        "Phase 1 Autoloads Present",
        ["python", "scripts/tools/check_phase1_autoloads.py"],
        required=True
    )

    # Check test scenes exist
    self.run_check(
        "Phase 1 Test Scenes Present",
        ["python", "scripts/tools/check_phase1_scenes.py"],
        required=True
    )

    # Run Phase 1 unit tests
    self.run_check(
        "Phase 1 Unit Tests",
        ["python", "scripts/tools/run_tests.py", "tests/unit/test_floating_origin.gd"],
        required=True
    )

    # Check VR performance (if VR available)
    self.run_check(
        "VR Performance Check",
        ["python", "scripts/tools/check_vr_performance.py"],
        required=False  # Non-blocking (needs VR hardware)
    )
```

---

## Commit Strategy for Phase 1

**Week 2 Commit:**
```bash
git add .
python scripts/tools/verify_phase.py --phase 1
git commit -m "Phase 1 Week 2: Floating origin system implemented

- Created FloatingOriginSystem autoload
- Implemented universe shifting at 10km threshold
- Added floating_origin_test.tscn
- Tests: Can walk 20km without jitter
- Verification: PASS (exit code 0)"
```

**Week 3 Commit:**
```bash
git commit -m "Phase 1 Week 3: Planetary gravity implemented

- Created GravityManager autoload
- Implemented spherical gravity
- Added planetary_gravity_test.tscn
- Tests: Can walk on curved surface
- Verification: PASS (exit code 0)"
```

**Week 4 Commit:**
```bash
git commit -m "Phase 1 Week 4: VR comfort features complete

- Created VRComfortSystem autoload
- Implemented vignette and snap turning
- Added vr_comfort_test.tscn
- Tests: 30 min VR session comfortable
- Performance: 90 FPS maintained
- Verification: PASS (exit code 0)"
```

**Phase 1 Complete:**
```bash
git commit -m "Phase 1 COMPLETE: Core physics foundation ready

Acceptance Criteria:
✅ Walk on spherical planet (gravity correct)
✅ Walk 100km without jitter (floating origin works)
✅ 90 FPS maintained in VR
✅ No motion sickness in 30 min test
✅ All unit tests pass
✅ Automated verification pass (exit code 0)

Ready for Phase 2: Spacecraft & Flight"
```

---

## Estimated Timeline

| Week | Tasks | Hours | End Date |
|------|-------|-------|----------|
| Week 2 | Floating Origin | 20-25h | Day 14 |
| Week 3 | Gravity & Walking | 20-25h | Day 21 |
| Week 4 | VR Comfort & Polish | 20-30h | Day 28 |
| **Total** | **Phase 1 Complete** | **60-80h** | **~Day 28** |

**Assumptions:**
- 4-5 hours per day development
- Includes testing and iteration
- Includes VR testing sessions
- Includes documentation updates

---

## Ready to Begin?

**Start Phase 1 with:**

```bash
# Create branch
git checkout -b phase-1-core-physics

# Create directory structure
mkdir -p scenes/features
mkdir -p scripts/core
mkdir -p scripts/vr
mkdir -p tests/unit

# Begin Week 2: Floating Origin
# First task: Create FloatingOriginSystem.gd
```

**After each change:**
```bash
python scripts/tools/verify_phase.py --phase 1 --auto-fix
```

**When Phase 1 complete:**
```bash
python scripts/tools/verify_phase.py --phase 1
# Exit code must be 0

git merge phase-1-core-physics
git push
```

---

## Questions?

**Before starting Phase 1:**
- Review `DEVELOPMENT_PHASES.md` for complete roadmap
- Review `CONTRIBUTING.md` for development workflow
- Ensure Phase 0 verification passes: `python scripts/tools/verify_phase.py --phase 0`

**Ready to build a game!** 🚀

---

**Next Phase After This:** Phase 2: Spacecraft & Flight (Weeks 5-8)
