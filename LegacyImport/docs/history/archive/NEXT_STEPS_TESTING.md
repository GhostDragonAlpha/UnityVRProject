# Next Steps: Testing & Verification

**Current Status:** All code changes and integrations complete. Testing phase ready to begin.

---

## Immediate Actions Required

### 1. Restart Godot to Load Changes
**Why:** Code modifications made to:
- `walking_controller.gd` (bug fixes)
- `godot_bridge.gd` (+682 lines of API endpoints)

**Command:**
```bash
# Kill any existing Godot instances
taskkill /F /IM Godot_v4.5.1-stable_win64.exe

# Start Godot with debug services
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe" --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

**Expected:** Godot loads with HTTP API on port 8080

---

## Test Suite Execution Plan

### Phase 1: Critical Bug Fixes (15 minutes)

#### Test 1: WASD Movement Speed Fix
**Expected Result:** Player moves at 3.0 m/s (walk) / 6.0 m/s (sprint)
**Previous Result:** 0.22 m/s (14x too slow)

**Test Command:**
```bash
python test_wasd_movement.py
```

**Success Criteria:**
- Walk speed: 2.5-3.5 m/s (target: 3.0 m/s)
- Sprint speed: 5.5-6.5 m/s (target: 6.0 m/s)
- Player on ground (not airborne)
- Movement responsive to WASD input

**If Fails:**
- Check Godot console for `[WalkingController DEBUG]` messages
- Verify `walking_controller.gd` changes loaded
- Check player spawn location

---

#### Test 2: Jetpack Fuel Consumption Fix
**Expected Result:** Fuel decreases from 100% → ~80% after 2s use
**Previous Result:** Fuel stayed at 100%

**Test Command:**
```bash
python quick_jetpack_test.py
```

**Success Criteria:**
- Thrust works (altitude gain >0.5m)
- Fuel consumption: 15-25% after 2s (target: 20%)
- Debug logs show fuel changes

**Debug Logs to Check:**
```
[Jetpack DEBUG] FUEL CONSUMPTION: 100.0 -> 98.5 (delta=0.016)
[Jetpack DEBUG] RELEASED at altitude 0.58m, grounded=false
```

**If Fails:**
- Check for `[WalkingController DEBUG] INACTIVE` messages (controller not active)
- Verify walking controller is the active player mode
- Check `current_fuel` variable updates in logs

---

### Phase 2: Integrated HTTP Endpoints (30 minutes)

#### Test 3: Mission System Endpoints
**Status:** Integrated (lines 1509-1858 in godot_bridge.gd)
**Expected:** 7/7 endpoints functional

**Test Command:**
```bash
python test_mission_system.py
```

**Endpoints to Verify:**
- GET /missions/active
- POST /missions/register
- POST /missions/activate
- POST /missions/update_objective
- POST /missions/complete

**Success Criteria:**
- HTTP 200 for all valid requests
- JSON responses with correct structure
- Mission workflow: register → activate → update → complete

**Expected Issues:**
- May return HTTP 404 if MissionSystem not initialized
- Check for `MissionSystem` node in ResonanceEngine
- Verify mission_data.gd, objective_data.gd loaded

---

#### Test 4: Base Building Endpoints
**Status:** Integrated (lines 1878-2198 in godot_bridge.gd)
**Expected:** 8/8 endpoints functional

**Test Command:**
```bash
python test_base_building.py
```

**Endpoints to Verify:**
- POST /base/place_structure
- GET /base/structures
- POST /base/structures/nearby
- DELETE /base/remove_structure
- POST /base/module
- GET /base/networks
- POST /base/integrity
- POST /base/stress_visualization

**Success Criteria:**
- HTTP 200 for all valid requests
- Structure placement validated
- Resource costs checked
- Collision detection working

**Expected Issues:**
- Requires PlanetarySurvivalCoordinator node
- May fail if base_building_system not initialized
- Check for 500 errors indicating coordinator not found

---

#### Test 5: Terrain Endpoints
**Status:** Already implemented and documented
**Expected:** 2/2 working endpoints

**Test Command:**
```bash
python test_terrain_working.py
```

**Endpoints to Verify:**
- POST /terrain/excavate
- POST /terrain/elevate

**Success Criteria:**
- Excavate removes terrain, returns soil volume
- Elevate adds terrain, consumes soil
- Proper error handling (400, 500)

---

### Phase 3: Previously Tested Systems (10 minutes)

#### Test 6: Resource Gathering (KNOWN WORKING)
**Status:** 4/4 endpoints confirmed working

**Quick Verification:**
```bash
curl http://127.0.0.1:8080/resources/inventory
```

**Expected:** JSON with 7 resource types

---

#### Test 7: Spacecraft System (NEEDS SCENE INTEGRATION)
**Status:** 100% validated, needs vr_main.tscn integration

**Action Required:**
1. Open `vr_main.tscn` in Godot Editor
2. Add RigidBody3D node
3. Attach `scripts/player/spacecraft.gd` script
4. Configure physics properties
5. Test controls with WASD/Space/QE

**Skip for now - requires manual scene editing**

---

#### Test 8: Orbital Mechanics (NO HTTP API)
**Status:** 100% backend validated, HTTP API not implemented

**Skip for now - backend only, no REST endpoints**

---

#### Test 9: VR Controller Tracking (VERIFIED)
**Status:** Implementation confirmed in scene inspector

**Quick Test:**
```bash
curl -s http://127.0.0.1:8080/state/scene | grep "controller"
```

**Expected:** `"left_controller": {"found": false, ...}` (when VR not active)

---

## Test Results Documentation

### Create Test Results File
After running tests, document results in:
```
C:/godot/TEST_RESULTS_2025-12-02.md
```

**Template:**
```markdown
# Test Results - 2025-12-02

## Critical Bug Fixes
- [ ] WASD Movement: _____ m/s (target: 3.0 m/s)
- [ ] Jetpack Fuel: ___% consumed (target: ~20%)

## Integrated Endpoints
- [ ] Mission System: __/7 passing
- [ ] Base Building: __/8 passing
- [ ] Terrain: __/2 passing

## Issues Found
1. [Issue description]
   - Error: [error message]
   - Fix: [proposed solution]

## Next Actions
[List any follow-up work needed]
```

---

## Expected Outcomes

### Best Case Scenario
✓ All bug fixes working
✓ All integrated endpoints functional
✓ Ready for Checkpoint 4 completion

### Most Likely Scenario
✓ Bug fixes working (movement, fuel)
✓ Resource endpoints working (already confirmed)
✓ Terrain endpoints working (already confirmed)
⚠️ Mission endpoints need MissionSystem initialization
⚠️ Base building endpoints need coordinator setup
→ **Result:** 60-70% success rate, clear tasks for completion

### Worst Case Scenario
✗ Godot fails to load due to syntax errors
→ **Action:** Review godot_bridge.gd for typos
→ **Fix:** Use backup files, re-apply changes carefully

---

## Debugging Resources

### If Tests Fail

**Check Godot Console:**
- Look for parse errors
- Check for missing nodes
- Verify autoload systems loaded

**Check HTTP API Status:**
```bash
curl -s http://127.0.0.1:8080/status | python -m json.tool
```

**Verify File Changes:**
```bash
# Check if walking_controller.gd has fixes
grep "length_squared" scripts/player/walking_controller.gd

# Check if godot_bridge.gd has new endpoints
grep "missions/" addons/godot_debug_connection/godot_bridge.gd
grep "base/" addons/godot_debug_connection/godot_bridge.gd
```

---

## Time Estimates

| Phase | Estimated Time | Cumulative |
|-------|---------------|------------|
| Restart Godot | 2 min | 2 min |
| Test Movement Fix | 5 min | 7 min |
| Test Fuel Fix | 5 min | 12 min |
| Test Mission Endpoints | 10 min | 22 min |
| Test Base Endpoints | 10 min | 32 min |
| Test Terrain Endpoints | 5 min | 37 min |
| Document Results | 10 min | 47 min |
| **Total** | **~50 minutes** | |

---

## Success Metrics

**Critical (Must Pass):**
- Movement speed fixed (3.0 m/s)
- At least 1 integrated endpoint working

**Important (Should Pass):**
- Fuel consumption working
- 50%+ of integrated endpoints working

**Nice to Have:**
- All integrated endpoints working
- All tests passing

---

## Related Documentation

- `SESSION_COMPLETE_SUMMARY.md` - Full session overview
- `FEATURE_TEST_SUMMARY.md` - Previous test results
- `WALKING_SPEED_BUG_FIX.md` - Movement bug details
- `JETPACK_BUG_REPORT.md` - Fuel bug details
- Test scripts in `C:/godot/test_*.py`

---

## Contact Points for Issues

**If Movement Still Broken:**
- Review `walking_controller.gd:348-388`
- Check `calculate_movement_direction()` function
- Verify vector normalization safety checks

**If Fuel Still Broken:**
- Review debug logs for fuel consumption
- Check if controller is active
- Verify recharge logic moved after `move_and_slide()`

**If Endpoints 404:**
- Verify routing added to `_route_request()`
- Check handler functions copied correctly
- Ensure proper indentation in godot_bridge.gd

**If Endpoints 500:**
- Check for missing dependencies (coordinators, managers)
- Verify autoload nodes initialized
- Check Godot console for error messages

---

**Status:** Ready to begin testing phase
**Next Action:** Restart Godot and run test suite
**Expected Duration:** ~50 minutes
**Documentation:** Update TEST_RESULTS_2025-12-02.md with findings
