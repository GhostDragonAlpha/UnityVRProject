# Ready for Phase 1 Week 3 Testing

**Date:** 2025-12-09
**Status:** ✅ CODE COMPLETE - Ready for Human Testing
**Command:** `verify_complete.bat 1 3`

---

## Current Status

### ✅ Week 2 (Floating Origin)
- **Status:** COMPLETE ✅
- **Manual Testing:** Done (12/12 tests passed, 0 errors)
- **File:** `MANUAL_TESTING_PHASE_1_WEEK_2.json` exists
- **Verification:** Exit code 0 ✅

### ⏸️ Week 3 (Gravity & Planetary Walking)
- **Status:** CODE COMPLETE - Awaiting Testing ⏸️
- **Manual Testing:** NOT DONE ❌
- **File:** `MANUAL_TESTING_PHASE_1_WEEK_3.json` does not exist
- **Verification:** Will pass once testing done

---

## What's Been Built (Week 3)

### 1. GravityManager Autoload ✅
**File:** `scripts/core/gravity_manager.gd` (280 lines)

**Features:**
- Spherical gravity (points to planet center)
- Multiple gravity sources
- Inverse square law: F = G * M / r²
- Surface gravity calculations
- Up direction calculations
- Gravity well detection
- Active/inactive source toggling

**Registered in project.godot:** ✅

### 2. Planetary Gravity Test Scene ✅
**Files:**
- `scenes/features/planetary_gravity_test.tscn`
- `scenes/features/planetary_gravity_test.gd` (240 lines)

**Features:**
- Small test planet (100m radius, Earth mass)
- Player spawns above planet
- Falls due to gravity
- Can walk on curved surface (WASD)
- Player orientation follows surface normal
- Jump (Space), Reset (R), Stats (P)
- Real-time UI showing gravity data

### 3. Unit Tests ✅
**File:** `tests/unit/test_gravity_manager.gd` (280 lines, 18 tests)

**Test Coverage:**
- Gravity direction (always toward center)
- Inverse square law verification
- Multiple gravity sources
- Surface distance calculations
- Up direction calculations
- Gravity well detection
- Source activation/deactivation

### 4. Verification Scripts Updated ✅
- `check_phase1_autoloads.py` - Now checks GravityManager
- `check_phase1_scenes.py` - Now checks planetary scene (4 files total)
- `manual_testing_protocol.py` - Added 12 Week 3 tests

---

## How To Test Week 3

### Quick Start: ONE Command

```bash
verify_complete.bat 1 3
```

This will:
1. ✅ Run automated verification (already passing)
2. ❓ Ask if Godot is running
3. 📋 Launch 12-test interactive checklist
4. ⏱️ Guide you through ~20-30 minutes of testing
5. 💾 Save results to `MANUAL_TESTING_PHASE_1_WEEK_3.json`
6. ✅ Generate completion report

### Manual Testing Checklist (12 Tests)

**Test 1: Godot Editor Started**
- Start Godot
- Check console for "GravityManager Initialized"
- Verify no errors

**Test 2: Planetary Gravity Scene Loads**
- Open `scenes/features/planetary_gravity_test.tscn`
- Verify Player, Planet, UI nodes present
- Check for scene errors

**Test 3: Scene Runs Without Errors**
- Press F6 to run scene
- Verify UI appears with gravity stats
- Check console for errors

**Test 4: Player Spawns Above Planet**
- Verify player position above planet
- Not intersecting geometry
- Clear view of planet below

**Test 5: Gravity Pulls Player Toward Center**
- Player falls toward planet
- Accelerates smoothly
- Direction is toward center

**Test 6: Player Lands on Surface**
- Lands smoothly without bouncing
- Stays on surface (not falling through)
- Oriented perpendicular to surface
- No jitter

**Test 7: WASD Movement Works**
- W - Forward along surface
- S - Backward along surface
- A - Strafe left
- D - Strafe right
- Player stays on curved surface

**Test 8: Player Orientation Correct**
- Walk around planet
- Player "up" always points away from center
- Smooth rotation transitions
- Camera maintains upright view

**Test 9: Walk 360° Around Planet**
- Hold W to walk forward
- Walk complete circle
- Return to starting point
- No glitches or jumps
- Stable performance

**Test 10: Jump Works**
- Press Space to jump
- Player lifts off surface
- Arc follows gravity
- Lands smoothly
- Can jump while moving

**Test 11: Reset Works**
- Walk to different location
- Press R key
- Returns to spawn position
- Falls again due to gravity

**Test 12: Unit Tests Pass**
- Open GdUnit4 panel
- Navigate to `tests/unit/test_gravity_manager.gd`
- Click "Run Tests"
- All 18 tests pass (green checkmarks)

---

## Expected Results

### During Testing

**In Godot Console:**
```
[GravityManager] Initialized
[GravityManager] Gravitational constant: 10.00
[PlanetaryGravityTest] Scene ready
[PlanetaryGravityTest] Planet registered with GravityManager
[PlanetaryGravityTest] Planet radius: 100.0 m
[PlanetaryGravityTest] Planet mass: 5.97e+24 kg
[PlanetaryGravityTest] Surface gravity: XX.XX m/s²
```

**In Scene View:**
- Player spawns above spherical planet
- Player falls toward planet smoothly
- Player lands and stays on surface
- WASD movement works on curved surface
- Player orientation rotates to follow surface
- Can walk full circle around planet
- Jump and reset functions work

**In UI:**
```
Planetary Gravity Test
Distance to surface: XX.XX m
Gravity strength: XX.XX m/s²
In gravity well: Yes
On surface: Yes
Surface gravity: XX.XX m/s²

Controls:
  WASD: Move, Space: Jump
  R: Reset, P: Print stats
```

### After Testing Complete

**Terminal Output:**
```
✅ ALL MANUAL TESTS PASSED!

Summary:
  Tests Completed: 12
  Tests Failed: 0
  Tests Skipped: 0

Results saved to: MANUAL_TESTING_PHASE_1_WEEK_3.json
```

**File Created:**
```json
{
  "phase": 1,
  "week": 3,
  "timestamp": "2025-12-09T...",
  "tests_completed": [
    "godot_start_week3",
    "scene_load_week3",
    "run_scene_week3",
    "player_spawn",
    "gravity_pull",
    "player_landing",
    "wasd_movement",
    "surface_orientation",
    "full_circle_walk",
    "jump_test",
    "reset_function_week3",
    "unit_tests_week3"
  ],
  "tests_failed": [],
  "notes": []
}
```

### After Re-running Verification

```bash
python scripts/tools/verify_phase.py --phase 1 --auto-fix

# Output:
✅ Phase 1 Autoloads Present - PASSED
✅ Phase 1 Test Scenes Present - PASSED
✅ Manual Testing Protocol Completion - PASSED

Exit Code: 0 ✅
```

**Completion Report Generated:**
- `COMPLETION_REPORT_PHASE_1_WEEK_3.md`

---

## Key Features to Verify

### Gravity System

**Should observe:**
- ✅ Gravity always points toward planet center
- ✅ Strength decreases with distance (inverse square)
- ✅ Player falls naturally when not supported
- ✅ Player stays grounded when on surface

**Should NOT observe:**
- ❌ Gravity pointing in wrong direction
- ❌ Player floating off planet
- ❌ Sudden jumps or discontinuities
- ❌ Jitter or stuttering

### Walking System

**Should observe:**
- ✅ Smooth movement in all directions (WASD)
- ✅ Player orientation rotates to follow surface
- ✅ Can walk full 360° circle
- ✅ Camera stays upright
- ✅ Jump arc follows gravity correctly

**Should NOT observe:**
- ❌ Player sliding off planet
- ❌ Incorrect orientation (sideways/upside-down)
- ❌ Camera flipping or rolling
- ❌ Movement stuttering
- ❌ Unable to complete full circle

---

## Technical Notes

### Gravity Calculation

Formula: **F = G * M / r²**

Test Planet Values:
- G = 10.0 (gravitational constant)
- M = 5.972e24 kg (Earth mass)
- R = 100m (planet radius)

Surface Gravity:
- g = (10.0 * 5.972e24) / (100²)
- g = 5.972e21 m/s²

### Player Orientation Algorithm

1. Get gravity vector at player position
2. Calculate "up" = opposite of gravity
3. Interpolate player basis toward target up
4. Maintain forward direction
5. Recalculate right and forward for orthogonality

### Integration with Week 2

Both systems work together:
- FloatingOriginSystem: Handles large distances
- GravityManager: Handles planetary gravity
- Both registered with same objects
- No conflicts or interference

---

## Troubleshooting

### If Player Falls Through Planet

**Cause:** Collision mesh not generated
**Fix:** Check Planet has CollisionShape3D in scene tree

### If Gravity Wrong Direction

**Cause:** Planet not at origin, or mass/radius incorrect
**Fix:** Check planet position is (0,0,0), verify registration

### If Player Orientation Wrong

**Cause:** Gravity alignment speed too high/low
**Fix:** Adjust GRAVITY_ALIGN_SPEED constant (default: 5.0)

### If Movement Feels Sluggish

**Cause:** MOVE_SPEED too low
**Fix:** Increase MOVE_SPEED constant (default: 5.0 m/s)

### If Jump Too Weak/Strong

**Cause:** JUMP_FORCE incorrect
**Fix:** Adjust JUMP_FORCE constant (default: 10.0 m/s)

---

## After Testing Complete

**When all 12 tests pass:**

1. ✅ `MANUAL_TESTING_PHASE_1_WEEK_3.json` created
2. ✅ Re-run verification: `python scripts/tools/verify_phase.py --phase 1 --auto-fix`
3. ✅ Exit code 0
4. ✅ `COMPLETION_REPORT_PHASE_1_WEEK_3.md` generated
5. ✅ Week 3 officially complete!
6. ✅ Ready for Week 4 (VR Comfort & Polish)

---

## Ready To Begin?

**Run this command:**

```bash
verify_complete.bat 1 3
```

**Duration:** 20-30 minutes

**What you'll do:**
- Start Godot editor
- Load test scene
- Test features visually
- Answer yes/no for each test
- Verify everything works

**What the system will do:**
- Guide you through each test
- Record your answers
- Generate completion report
- Verify everything passed

---

**Status:** ✅ Ready for testing
**Command:** `verify_complete.bat 1 3`
**Estimated Time:** 20-30 minutes
**Next:** Phase 1 Week 4 (VR Comfort & Polish)
