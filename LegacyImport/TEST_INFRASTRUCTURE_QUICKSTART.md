# Test Infrastructure Quick Start Guide

**Created:** 2025-12-09
**Phase:** Phase 0 Day 4
**Status:** Ready for Testing

---

## Quick Test Commands

### 1. Run Automated Tests (Headless)

```bash
cd C:/Ignotus
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/Ignotus" --headless --script tests/test_runner.gd --quit-after 5
```

**Expected:** All tests pass, exit code 0

---

### 2. Test VR Tracking (In Godot Editor)

1. Open Godot editor
2. Open scene: `scenes/features/vr_tracking_test.tscn`
3. Press F6 to run
4. Put on VR headset
5. Move controllers - should see red/blue boxes
6. Press F12 to exit

**Expected:** Smooth tracking, 90 FPS, no errors

---

### 3. Test Without VR (Fallback Mode)

1. Disconnect VR headset or stop SteamVR
2. Open scene: `scenes/features/vr_tracking_test.tscn`
3. Press F6 to run
4. Should see desktop camera view
5. Press F12 to exit

**Expected:** Scene loads without errors, fallback camera active

---

## File Locations

| What | Where |
|------|-------|
| Feature Template | `scripts/templates/feature_template.gd` |
| Test Runner | `tests/test_runner.gd` |
| VR Test Scene | `scenes/features/vr_tracking_test.tscn` |
| VR Test Script | `scenes/features/vr_tracking_test.gd` |
| Full Documentation | `PHASE_0_DAY_4_COMPLETION.md` |

---

## Quick Reference

### Creating New Feature Scenes

1. New Scene → 3D Scene
2. Attach script: `scripts/templates/feature_template.gd`
3. Override `_init_feature()` for custom logic
4. F12 exits to main menu

### Running Tests Before Commit

```bash
# Automated tests
./run_tests.sh  # or use command above

# Manual checks
# 1. Open editor - check for 0 errors
# 2. F5 - run main scene, no crashes
# 3. curl http://127.0.0.1:8080/health - API responds
```

---

## What Was Created

✅ **4 new directories:**
- `scenes/features/` - Feature test scenes
- `scenes/production/` - Production scenes
- `scenes/test/unit/` - Unit test scenes
- `scripts/templates/` - Reusable templates

✅ **4 new files:**
- Feature template script
- Automated test runner
- VR tracking test scene
- VR tracking test script

✅ **2 documentation files:**
- This quick start guide
- Complete implementation report

---

## Next Steps

See **PHASE_0_DAY_4_COMPLETION.md** for:
- Detailed testing instructions
- Troubleshooting guide
- Integration checklist
- Day 5 preparation

---

**Everything is ready for manual testing!**
