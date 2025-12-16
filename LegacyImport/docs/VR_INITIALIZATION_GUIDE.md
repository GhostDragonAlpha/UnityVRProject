# VR Initialization Guide - Complete Reference

**Last Updated:** 2025-12-09
**Status:** Production Ready - Validated with BigScreen Beyond + Valve Index
**Version:** 1.0

---

## Table of Contents
1. [Critical VR Initialization Pattern](#critical-vr-initialization-pattern)
2. [Common Mistakes and Fixes](#common-mistakes-and-fixes)
3. [Complete Working Example](#complete-working-example)
4. [Testing VR from Command Line](#testing-vr-from-command-line)
5. [Troubleshooting Guide](#troubleshooting-guide)
6. [Remote Control via DAP](#remote-control-via-dap)

---

## Critical VR Initialization Pattern

### The Essential 4-Step Pattern

**This pattern is REQUIRED for VR to render properly in Godot 4.5+**

```gdscript
func _ready() -> void:
    # STEP 1: Find the OpenXR interface
    var xr_interface = XRServer.find_interface("OpenXR")
    if not xr_interface:
        print("ERROR: OpenXR interface not found")
        return

    # STEP 2: Initialize the interface (CRITICAL - must happen before use_xr)
    if not xr_interface.initialize():
        print("ERROR: OpenXR initialization failed")
        return

    # STEP 3: Mark viewport for XR rendering (THE CRITICAL LINE)
    get_viewport().use_xr = true

    # STEP 4: Activate the XR camera
    $XROrigin3D/XRCamera3D.current = true

    print("✅ VR initialized successfully")
```

### Why Each Step Matters

**Step 1 - Find Interface:**
- Searches for the OpenXR runtime (SteamVR, Oculus, etc.)
- Returns null if no VR runtime is available
- Must check for null before proceeding

**Step 2 - Initialize (MOST IMPORTANT):**
- Connects to the VR runtime
- Allocates GPU resources for stereo rendering
- **MUST be called before setting use_xr = true**
- Returns false if initialization fails

**Step 3 - Mark Viewport:**
- `get_viewport().use_xr = true` tells Godot to render in stereo
- **Without this line, headset displays black/gray screen**
- Must be set AFTER interface is initialized

**Step 4 - Activate Camera:**
- Makes XRCamera3D the active camera
- XRCamera3D automatically tracks headset position/rotation
- Regular Camera3D nodes won't work for VR

---

## Common Mistakes and Fixes

### Mistake #1: Checking is_initialized() Before Calling initialize()

❌ **WRONG:**
```gdscript
var xr_interface = XRServer.find_interface("OpenXR")
if xr_interface and xr_interface.is_initialized():  # ❌ Will always be false!
    get_viewport().use_xr = true
```

**Problem:** Interface is not initialized yet at _ready() time. Checking is_initialized() before calling initialize() will always fail.

✅ **CORRECT:**
```gdscript
var xr_interface = XRServer.find_interface("OpenXR")
if xr_interface and xr_interface.initialize():  # ✅ Initialize first, then check
    get_viewport().use_xr = true
```

---

### Mistake #2: Forgetting to Set use_xr = true

❌ **WRONG:**
```gdscript
var xr_interface = XRServer.find_interface("OpenXR")
xr_interface.initialize()
# Missing: get_viewport().use_xr = true  ❌
$XROrigin3D/XRCamera3D.current = true
```

**Problem:** Without marking the viewport for XR, Godot renders normal 2D output. Headset shows black or gray screen.

**Symptom:** Console shows "OpenXR: No viewport was marked with use_xr, there is no rendered output!"

✅ **CORRECT:**
```gdscript
var xr_interface = XRServer.find_interface("OpenXR")
if xr_interface.initialize():
    get_viewport().use_xr = true  # ✅ CRITICAL LINE
    $XROrigin3D/XRCamera3D.current = true
```

---

### Mistake #3: Using Regular Camera3D Instead of XRCamera3D

❌ **WRONG Scene Structure:**
```
Node3D
├─ Camera3D  ❌ Regular camera doesn't track VR headset
```

✅ **CORRECT Scene Structure:**
```
Node3D
├─ XROrigin3D  ✅ VR tracking space root
   ├─ XRCamera3D  ✅ Tracks headset
   ├─ LeftController (XRController3D)
   └─ RightController (XRController3D)
```

---

### Mistake #4: No Visible Geometry in Scene

❌ **PROBLEM:**
```gdscript
# Scene has XROrigin3D + XRCamera3D but no MeshInstance3D nodes
# Result: Gray screen (VR works but nothing to see)
```

**Symptom:** VR initializes correctly, console shows success, but headset shows only gray.

✅ **SOLUTION:** Add visible geometry:
```gdscript
[node name="ReferenceCube" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.7, -2)
mesh = SubResource("BoxMesh_cube")
surface_material_override/0 = SubResource("Material_red")  # Bright emissive material
```

---

## Complete Working Example

### Minimal VR Test Scene (Guaranteed to Work)

**File: `scenes/features/minimal_vr_test.tscn`**

```gdscript
[gd_scene load_steps=7 format=3]

[ext_resource type="Script" path="res://scenes/features/minimal_vr_test.gd" id="1"]

[sub_resource type="BoxMesh" id="BoxMesh_cube"]
size = Vector3(1, 1, 1)

[sub_resource type="StandardMaterial3D" id="Material_red"]
albedo_color = Color(1, 0, 0, 1)
emission_enabled = true
emission = Color(1, 0, 0, 1)
emission_energy_multiplier = 2.0

[sub_resource type="BoxMesh" id="BoxMesh_floor"]
size = Vector3(20, 0.2, 20)

[sub_resource type="StandardMaterial3D" id="Material_floor"]
albedo_color = Color(0.4, 0.4, 0.4, 1)

[sub_resource type="Environment" id="Environment_bright"]
background_mode = 1
background_color = Color(0.5, 0.7, 1.0, 1)
ambient_light_source = 2
ambient_light_color = Color(1, 1, 1, 1)
ambient_light_energy = 2.0

[node name="MinimalVRTest" type="Node3D"]
script = ExtResource("1")

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment_bright")

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0.707107, 0.707107, 0, -0.707107, 0.707107, 0, 10, 0)
light_energy = 3.0
shadow_enabled = true

[node name="ReferenceCube" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.7, -2)
mesh = SubResource("BoxMesh_cube")
surface_material_override/0 = SubResource("Material_red")

[node name="Floor" type="MeshInstance3D" parent="."]
mesh = SubResource("BoxMesh_floor")
surface_material_override/0 = SubResource("Material_floor")

[node name="XROrigin3D" type="XROrigin3D" parent="."]

[node name="XRCamera3D" type="XRCamera3D" parent="XROrigin3D"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.7, 0)

[node name="LeftController" type="XRController3D" parent="XROrigin3D"]
tracker = &"left_hand"

[node name="RightController" type="XRController3D" parent="XROrigin3D"]
tracker = &"right_hand"
```

**File: `scenes/features/minimal_vr_test.gd`**

```gdscript
extends Node3D
## Minimal VR Test Scene
## Simple scene to verify VR is working with visible geometry

func _ready() -> void:
	print("[MinimalVRTest] Scene ready")

	# Initialize OpenXR
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface:
		print("[MinimalVRTest] Found OpenXR interface")

		if xr_interface.initialize():
			print("[MinimalVRTest] OpenXR initialized successfully")

			# CRITICAL: Mark viewport for XR rendering
			get_viewport().use_xr = true
			print("[MinimalVRTest] Viewport marked for XR rendering")

			# Activate XR camera
			$XROrigin3D/XRCamera3D.current = true
			print("[MinimalVRTest] XR Camera activated")

			print("[MinimalVRTest] VR READY - You should see a red cube 2m in front")
		else:
			print("[MinimalVRTest] ERROR: OpenXR initialization failed")
	else:
		print("[MinimalVRTest] ERROR: OpenXR interface not found")
```

**Expected Output in Headset:**
- Red glowing cube 2 meters in front at eye level (1.7m height)
- Gray floor beneath you
- Blue sky background
- Bright lighting with shadows

---

## Testing VR from Command Line

### Method 1: Launch Specific VR Scene

```bash
# Windows
cd "C:/Ignotus"
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "." "res://scenes/features/minimal_vr_test.tscn"

# Linux/Mac
cd /path/to/project
godot --path "." "res://scenes/features/minimal_vr_test.tscn"
```

### Method 2: Set as Main Scene and Press F5

**Edit `project.godot`:**
```ini
[application]
run/main_scene="res://scenes/features/minimal_vr_test.tscn"
```

Then press **F5** in Godot editor.

### Method 3: Launch from Python Script

```python
import subprocess

godot_path = "C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe"
project_path = "C:/Ignotus"
scene_path = "res://scenes/features/minimal_vr_test.tscn"

subprocess.Popen([
    godot_path,
    "--path", project_path,
    scene_path
])
```

---

## Troubleshooting Guide

### Problem: Black Screen in Headset

**Possible Causes:**

1. **Viewport not marked for XR**
   - **Symptom:** Console shows "OpenXR: No viewport was marked with use_xr"
   - **Fix:** Add `get_viewport().use_xr = true` after initializing OpenXR

2. **Interface not initialized**
   - **Symptom:** No OpenXR error messages in console
   - **Fix:** Call `xr_interface.initialize()` before setting use_xr

3. **XRCamera3D not active**
   - **Symptom:** VR initialized but shows desktop camera view
   - **Fix:** Set `$XROrigin3D/XRCamera3D.current = true`

### Problem: Gray Screen in Headset

**Possible Causes:**

1. **No visible geometry**
   - **Symptom:** VR initialized correctly, console shows success, but nothing visible
   - **Fix:** Add MeshInstance3D nodes with bright materials

2. **Camera inside geometry**
   - **Symptom:** Only see gray wall
   - **Fix:** Move camera/geometry apart, check positions

3. **No lighting**
   - **Symptom:** Scene is too dark to see
   - **Fix:** Add DirectionalLight3D with light_energy = 2.0+

### Problem: SteamVR Not Connecting

**Check SteamVR Status:**
```bash
# Verify SteamVR is running
tasklist | grep -i vrserver

# Check Godot can find OpenXR
# Console should show: "OpenXR: Running on OpenXR runtime: SteamVR/OpenXR 2.14.4"
```

**Common Fixes:**
- Start SteamVR before launching Godot
- Check VR headset is connected and powered on
- Verify SteamVR shows green status indicators

### Problem: Scene Loads But VR Doesn't Initialize

**Debug Steps:**

1. **Check console output for:**
   ```
   [SceneName] Found OpenXR interface  ← Should see this
   [SceneName] OpenXR initialized successfully  ← Should see this
   [SceneName] Viewport marked for XR rendering  ← CRITICAL
   ```

2. **If missing "Found OpenXR interface":**
   - SteamVR not running
   - OpenXR runtime not installed

3. **If missing "OpenXR initialized successfully":**
   - Check headset is powered on
   - Check USB/DisplayPort connections
   - Restart SteamVR

4. **If missing "Viewport marked for XR rendering":**
   - Bug in scene script - missing `get_viewport().use_xr = true` line

---

## Remote Control via DAP

### Connecting to Debug Adapter Protocol (Port 6006)

**Check if DAP is available:**
```bash
netstat -ano | grep 6006
# Should show: TCP    127.0.0.1:6006    0.0.0.0:0    LISTENING
```

**Connect with Python:**
```python
from scripts.tools.dap_controller import GodotDAPController

controller = GodotDAPController()
if controller.connect():
    threads = controller.get_threads()
    frames = controller.get_stack_trace()
    controller.disconnect()
```

**What DAP Can Do:**
- ✅ Inspect scene tree structure
- ✅ Read variable values when paused at breakpoint
- ✅ Monitor thread states
- ❌ Cannot execute arbitrary GDScript (designed for debugging, not REPL)

**For Runtime Control:** Use HTTP API on port 8080 instead (requires main scene running).

---

## Console Output Reference

### Successful VR Initialization

```
Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org
OpenXR: Running on OpenXR runtime:  SteamVR/OpenXR   2.14.4
OpenXR: XrGraphicsRequirementsVulkan2KHR:
 - minApiVersionSupported:  1.0.0
 - maxApiVersionSupported:  1.2.0
Vulkan 1.4.312 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 4090

[MinimalVRTest] Scene ready
[MinimalVRTest] Found OpenXR interface
[MinimalVRTest] OpenXR initialized successfully
[MinimalVRTest] Viewport marked for XR rendering
[MinimalVRTest] XR Camera activated
[MinimalVRTest] VR READY - You should see a red cube 2m in front
```

**Key Indicators:**
- ✅ "OpenXR: Running on OpenXR runtime: SteamVR/OpenXR"
- ✅ "OpenXR initialized successfully"
- ✅ "Viewport marked for XR rendering"
- ✅ "XR Camera activated"

### Failed VR Initialization

```
Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org
OpenXR: Running on OpenXR runtime:  SteamVR/OpenXR   2.14.4
[...]
[VRMain] Scene loaded successfully
[VRMain] OpenXR initialized  ❌ Missing "successfully"
[VRMain] Switching to XR Camera...  ❌ Missing viewport line
OpenXR: No viewport was marked with use_xr, there is no rendered output!  ❌ ERROR
OpenXR: No viewport was marked with use_xr, there is no rendered output!  ❌ ERROR
```

**Problem Indicators:**
- ❌ Missing "Viewport marked for XR rendering" message
- ❌ Repeated "No viewport was marked with use_xr" errors
- ❌ "OpenXR initialized" without "successfully"

---

## VR Testing Checklist

Before declaring VR "working", verify all of these:

- [ ] SteamVR shows green status (headset tracked)
- [ ] Godot console shows "OpenXR initialized successfully"
- [ ] Godot console shows "Viewport marked for XR rendering"
- [ ] No "No viewport was marked with use_xr" errors
- [ ] User can see visible geometry in headset (not black/gray)
- [ ] Head tracking works (scene moves when looking around)
- [ ] Geometry appears at correct distance and scale
- [ ] Lighting is visible and bright enough

---

## Production Checklist

When deploying VR features to production:

- [ ] Test with multiple headset types (if possible)
- [ ] Verify VR initialization on cold start (after system reboot)
- [ ] Test VR re-initialization after SteamVR restart
- [ ] Add fallback to desktop mode if VR unavailable
- [ ] Log all VR initialization steps for debugging
- [ ] Include clear error messages for users
- [ ] Test performance (90 FPS target for most headsets)
- [ ] Verify comfort features (vignette, smooth movement)

---

## Related Documentation

- **`docs/DAP_REMOTE_CONTROL_GUIDE.md`** - Debug Adapter Protocol usage
- **`CLAUDE.md`** - Project overview and development commands
- **`docs/PHASE2_WEEK5_VR_SESSION_REPORT.md`** - VR testing session report
- **`docs/VR_TESTING_PROTOCOL_WEEK5.md`** - Detailed VR test cases

---

## Hardware Tested

This guide has been validated with:
- **Headset:** BigScreen Beyond
- **Controllers:** Valve Index controllers
- **GPU:** NVIDIA GeForce RTX 4090
- **VR Runtime:** SteamVR/OpenXR 2.14.4
- **Godot Version:** 4.5.1.stable.official

---

**Last Validated:** 2025-12-09
**Status:** Production Ready ✅
