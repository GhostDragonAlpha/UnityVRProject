# VR Tracking Failure - Root Cause Analysis

**Date:** 2025-12-10
**Status:** ✅ RESOLVED - Physics override bug fixed
**Hardware:** BigScreen Beyond + Valve Index Controllers, RTX 4090
**Software:** Godot 4.5.1, SteamVR 2.14.4, OpenXR

---

## Problem Statement

**User sees:** Gray screen in VR headset, no visible geometry
**Initial Symptom:** XROrigin3D.global_position stuck at (0, 0, 0) - VR tracking NOT updating position
**Root Cause:** Manual position override in VR Player Mode physics (introduced during RL/ML agent implementation)
**Resolution:** Removed `player_body.global_position = xr_origin.global_position` from VR Player Mode function

---

## What We Know (CONFIRMED)

### ✅ What IS Working:
1. **SteamVR Runtime:** vrserver.exe (PID 2244) is running
2. **OpenXR Initialization:** "OpenXR initialized successfully" in console
3. **Camera Switching:** XRCamera3D is now correctly set as active camera
4. **Scene Loading:** vr_main.tscn loads without errors
5. **Viewport XR:** `get_viewport().use_xr = true` is set
6. **Code Execution:** All camera switching prints now appear in console

### ❌ What IS NOT Working:
1. **VR Tracking Data:** XROrigin3D.global_position remains at (0, 0, 0)
2. **Head Movement:** Moving headset doesn't update XROrigin3D position
3. **Visible Geometry:** User sees gray screen (camera at origin sees nothing)

---

## Console Output (Latest Test)

```
[VRMain] OpenXR initialized successfully
[VRMain] Viewport marked for XR rendering
[VRMain] Fallback camera disabled
[VRMain] CAMERA FIX START: About to switch cameras...
[VRMain] XRCamera3D is now active
WARNING: Object picking can't be used when stereo rendering, this will be turned off!
[VRMain] Physics movement disabled - VR tracking only mode
[VRMain] VR PLAYER MODE | XROrigin pos: (0.0, 0.0, 0.0) | CharBody pos: (0.0, -0.002148, 0.0)
```

**Analysis:**
- XROrigin3D position NEVER changes from (0, 0, 0)
- CharacterBody3D has slight physics movement (gravity) but XROrigin3D doesn't move
- This means OpenXR is NOT feeding tracking data to Godot's XROrigin3D node

---

## Hypothesis: Why Tracking Isn't Working

### Possibility 1: XROrigin3D Node Not Receiving Tracking Data
**Evidence:**
- OpenXR initializes successfully
- Viewport is set to XR mode
- But XROrigin3D position never updates

**Possible Causes:**
1. XROrigin3D node might not be configured correctly in scene
2. OpenXR tracking might not be bound to XROrigin3D node
3. XRServer might not be updating XROrigin3D transform

### Possibility 2: Headset Not Tracking in SteamVR
**Evidence:**
- SteamVR is running
- OpenXR connects successfully
- But we haven't confirmed headset shows "green" (tracked) in SteamVR status

**Possible Causes:**
1. Headset powered off or asleep
2. Base stations not tracking
3. SteamVR shows headset as "gray" (not tracked)

### Possibility 3: OpenXR Runtime Mismatch
**Evidence:**
- SteamVR is the active OpenXR runtime
- Godot reports "SteamVR/OpenXR 2.14.4"

**Possible Causes:**
1. SteamVR OpenXR runtime not properly configured
2. Multiple OpenXR runtimes conflict

---

## Next Debugging Steps

### Step 1: Check XRCamera3D Position
**Goal:** Verify if XRCamera3D global position updates when user moves head

**Implementation:** Add debug output for XRCamera3D.global_position every 60 frames

**Expected Result if tracking works:**
- XRCamera3D.global_position should change when user moves head
- XROrigin3D.global_position should also update (it's the parent transform)

**Expected Result if tracking doesn't work:**
- XRCamera3D.global_position stays at (0, 1.7, 0) - the fixed transform
- This would confirm OpenXR isn't sending tracking data to Godot

### Step 2: Check Headset Tracking in SteamVR
**Goal:** Verify headset is actually being tracked by SteamVR

**Manual Check:**
1. Put on headset
2. Check SteamVR status window
3. Verify headset icon is GREEN (not gray)
4. Move head and verify tracking updates in SteamVR

**If headset is gray:** SteamVR isn't tracking the headset
**If headset is green:** SteamVR IS tracking, problem is Godot not receiving data

### Step 3: Test minimal_vr_test.tscn
**Goal:** Eliminate scene complexity as a variable

**Scene:** `scenes/features/minimal_vr_test.tscn` has:
- XROrigin3D at (0, 0, 0)
- Red glowing cube at (0, 1.7, -2)
- User should see red cube 2 meters in front of them

**Expected:** If tracking works, user sees red cube when looking forward

### Step 4: Check XRServer Direct API
**Goal:** Query XRServer directly for tracking data

**Implementation:** Add code to check XRServer.get_tracker() and XRServer.get_pose()

---

## Scene Configuration (vr_main.tscn)

```gdscript
[node name="XROrigin3D" type="XROrigin3D" parent="."]
# No transform override - should default to (0,0,0)

[node name="XRCamera3D" type="XRCamera3D" parent="XROrigin3D"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.7, 0)
# Fixed at 1.7m height (eye level)

[node name="FallbackCamera" type="Camera3D" parent="XROrigin3D"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.7, 0)
current = true  # ← WAS THE PROBLEM (now fixed in code)
```

**Fix Applied:** vr_main.gd now explicitly disables FallbackCamera and enables XRCamera3D in `_ready()`

---

## Comparison: What Works in Other Scenes?

**minimal_vr_test.tscn:**
- ❌ Also shows gray screen
- Same XROrigin3D stuck at (0, 0, 0) issue

This confirms the problem is NOT specific to vr_main.tscn complexity.

---

## Root Cause Analysis - RESOLVED

**Timeline of Bug Introduction:**

1. **Before RL Implementation:** VR tracking worked correctly
2. **During RL/ML Agent Implementation:** Added physics-based character control
3. **Bug Introduced:** Added `player_body.global_position = xr_origin.global_position` to VR Player Mode
4. **Result:** VR tracking stopped working (gray screen, stuck at 0,0,0)

**Root Cause Identified:**

The line `player_body.global_position = xr_origin.global_position` in `_vr_player_mode_physics()` was creating a feedback loop that prevented OpenXR from updating XROrigin3D's transform.

**Why This Broke VR Tracking:**

Since CharacterBody3D is a **child** of XROrigin3D in the scene tree:
1. Children automatically inherit parent's global_transform
2. Manually setting child's global_position fights with parent transform system
3. This creates a conflict that prevents OpenXR from updating XROrigin3D

**The Fix:**

Removed manual position override from VR Player Mode. CharacterBody3D now follows XROrigin3D naturally through scene tree hierarchy.

**Code Change (vr_main.gd:148-166):**

```gdscript
# BEFORE (BROKEN):
func _vr_player_mode_physics(delta: float) -> void:
	player_body.global_position = xr_origin.global_position  # ← BUG!
	# ... rest of physics code

# AFTER (FIXED):
func _vr_player_mode_physics(delta: float) -> void:
	# DON'T manually set position - CharacterBody3D is child of XROrigin3D
	# It automatically follows parent transform
	# Manual position setting was breaking XR tracking!

	# Physics only for collisions:
	player_body.velocity = Vector3(0, velocity.y, 0)
	player_body.move_and_slide()
```

**The Correct Data Flow:**
```
SteamVR Headset Tracking
  ↓
OpenXR Runtime (SteamVR 2.14.4)
  ↓
Godot OpenXR Interface (initialized ✅)
  ↓
XRServer (working ✅)
  ↓
XROrigin3D Node (updates via OpenXR ✅)
  ↓
CharacterBody3D (follows parent via scene tree ✅)
```

---

## Questions for User

1. **Do you see anything in the VR headset?**
   - Gray screen only?
   - Can you see the SteamVR overlay/dashboard?

2. **Is the headset tracking in SteamVR?**
   - Check SteamVR status window
   - Is headset icon green?
   - Does position update when you move your head in SteamVR dashboard?

3. **When you move your head in VR, does anything change?**
   - Does gray screen rotate?
   - Any visual feedback at all?

---

## Files Modified

1. **vr_main.gd:60** - Added camera activation fix
2. **vr_main.gd:169-172** - Added XRCamera3D position debug output

---

## Next Actions

1. **Restart Godot** with updated debug output (shows XRCamera3D position)
2. **Ask user** to check SteamVR status and report headset tracking state
3. **Check XRCamera3D position** - if it updates, tracking works but XROrigin3D doesn't
4. **If XRCamera3D doesn't update** - OpenXR not sending data to Godot at all

---

## Resolution Summary

**Status:** ✅ VR tracking now works correctly
**User Confirmation:** "ok it is working now"

**Lessons Learned:**
1. Manual position overrides break VR tracking when applied to children of XROrigin3D
2. CharacterBody3D should follow XROrigin3D via scene tree hierarchy in VR Player Mode
3. Different physics patterns needed for VR Player Mode vs AI Training Mode
4. Console output shows OpenXR initialization, but doesn't confirm tracking is updating

**Prevention for Future:**
- Never set `player_body.global_position` in VR Player Mode
- Always test VR features in headset, not just console output
- Document mode-specific physics behavior
- Consider mode-specific code paths when implementing new features

**Related Documentation:**
- `docs/current/guides/VR_ARCHITECTURE.md` - Complete VR + RL/AI architecture
- `vr_main.gd:148-206` - Implementation reference
- `CLAUDE.md` - Updated with VR tracking troubleshooting

**Last Updated:** 2025-12-10 06:45 UTC
