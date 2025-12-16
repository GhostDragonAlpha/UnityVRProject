# VR Setup Guide for SpaceTime

## Quick Start

To run SpaceTime in VR with proper debug and telemetry support:

```bash
# 1. Start Godot with Python server (REQUIRED)
python godot_editor_server.py --port 8090

# 2. In another terminal, monitor telemetry
python telemetry_client.py

# 3. In Godot editor (running via Python server), press F5 to play
# Put on your VR headset!
```

**DO NOT start Godot directly.** The Python server provides the required wrapper for full VR functionality.

## Overview

SpaceTime supports VR using OpenXR, which works with most modern VR headsets including:

- Meta Quest 2/3/Pro
- Valve Index
- HTC Vive
- Windows Mixed Reality headsets
- And more!

## Prerequisites

### 1. VR Headset Setup

- Ensure your VR headset is properly connected and set up
- Install the appropriate runtime for your headset:
  - **Meta Quest**: Install Meta Quest Link or use Air Link
  - **SteamVR headsets**: Install SteamVR
  - **Windows Mixed Reality**: Windows should handle this automatically

### 2. OpenXR Runtime

- Make sure you have an OpenXR runtime installed
- For SteamVR: Set SteamVR as the active OpenXR runtime in SteamVR settings
- For Meta Quest: Set Oculus as the active OpenXR runtime

### 3. Python Server (MANDATORY)

The Python server wrapper is required for:
- GUI mode initialization
- VR subsystem loading
- Telemetry streaming
- Debug connection support

```bash
python godot_editor_server.py --port 8090
```

## Project Configuration

The project has been configured with:

1. **OpenXR enabled** in project settings
2. **Main VR scene** (`vr_main.tscn`) set as the startup scene
3. **XR shaders** enabled for proper rendering
4. **Python server integration** for lifecycle management

## Scene Structure

The VR scene includes:

- **XROrigin3D**: The root of the VR tracking space
- **XRCamera3D**: The VR headset camera (positioned at average eye height: 1.7m)
- **Left/Right Controllers**: VR controller tracking with button input
- **Environment**: Lighting and reference objects
- **Test Cube**: A cube to test depth perception and scale

## Running in VR

### Method 1: From Godot Editor (Recommended for Development)

1. Start Godot via Python server: `python godot_editor_server.py --port 8090`
2. Open the project in Godot (should happen automatically)
3. Make sure your VR headset is connected and running
4. Press F5 or click the "Play" button
5. Put on your headset

### Method 2: Exported Build

1. Build the project: `godot --headless --export-release "Windows Desktop" "build/SpaceTime.exe"`
2. Run the exported executable: `./build/SpaceTime.exe`
3. The application will automatically detect and use your VR headset

## Testing Without VR (Desktop Fallback)

If you don't have a VR headset connected, the application automatically falls back to desktop mode. You can add desktop camera controls by modifying `vr_setup.gd`.

## Telemetry Integration with VR

The VR system is fully integrated with the telemetry system. When running via Python server:

```bash
python telemetry_client.py
```

You'll see real-time VR tracking data:

```
[12:34:57.234] FPS: 90.0 | Frame: 11.1ms | Physics: 2.5ms

[12:34:57.334] VR Tracking:
  Headset: pos(0.00, 1.70, 0.00) rot(0.0°, 0.0°, 0.0°)
  Left Controller [OK]: pos(-0.50, 1.00, -0.50) buttons: trigger=0.8
  Right Controller [OK]: pos(0.50, 1.00, -0.50) buttons: grip=0.0
```

For more details, see TELEMETRY_GUIDE.md.

## Troubleshooting

### "OpenXR not initialized!" message

**Possible causes:**

1. VR headset not connected or not detected
2. OpenXR runtime not installed
3. Wrong OpenXR runtime selected
4. Not running via Python server

**Solutions:**

- Check that your headset is properly connected
- Verify the OpenXR runtime is installed
- For SteamVR users: Open SteamVR settings → OpenXR → Set SteamVR as active runtime
- For Quest users: Open Oculus app → Settings → General → OpenXR Runtime
- Always start Godot via: `python godot_editor_server.py --port 8090`

### Black screen in headset

**Possible causes:**

1. Viewport not properly configured
2. Rendering scale too high
3. Graphics driver issues
4. Python server not running

**Solutions:**

- Check that `viewport.use_xr = true` is set in vr_setup.gd
- Lower the render scale in `vr_setup.gd`
- Update your graphics drivers
- Ensure Python server is running and Godot is started through it

### Controllers not showing

**Possible causes:**

1. Controllers not paired
2. Controller tracking lost
3. Controller meshes not visible
4. Python server issue

**Solutions:**

- Pair your controllers through your VR runtime
- Ensure controllers are in tracking range
- Check that controller nodes are enabled in vr_main.tscn
- Restart Python server and Godot if controllers were paired after startup

### Performance issues (FPS below 90)

**Solutions:**

1. Lower the render resolution in project settings
2. Reduce shadow quality
3. Optimize scene complexity
4. Use Forward+ rendering (already enabled)
5. Monitor with telemetry: `python telemetry_client.py`

## Customization

### Adjusting Player Height

Edit the XRCamera3D transform in `vr_main.tscn`:

```gdscript
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.7, 0)
# Change 1.7 to your preferred height in meters
```

### Adding Controller Models

Replace the simple MeshInstance3D nodes with proper controller models:

1. Import your controller 3D models
2. Replace LeftHand and RightHand nodes with your models
3. Adjust transforms as needed

### Adding Interaction

Add scripts to the controller nodes to handle VR input:

```gdscript
extends XRController3D

func _process(_delta):
    if is_button_pressed("trigger_click"):
        print("Trigger pressed!")
    if get_float("trigger") > 0.5:
        print(f"Trigger analog: {get_float('trigger')}")
```

## Logging Custom VR Events

Log VR interactions to telemetry:

```gdscript
# Log player actions
TelemetryServer.log_event("player_teleported", {
    "from": old_position,
    "to": new_position
})

# Log interactions
TelemetryServer.log_event("object_grabbed", {
    "object": object.name,
    "controller": "left"
})

# Log errors
TelemetryServer.log_error("Physics glitch detected", {
    "velocity": rigidbody.linear_velocity
})
```

## Next Steps

1. **Add locomotion**: Implement teleportation or smooth movement
2. **Add hand models**: Replace simple meshes with proper hand/controller models
3. **Add interactions**: Implement grabbing, pointing, and UI interaction
4. **Add comfort options**: Implement vignette, snap turning, etc.
5. **Optimize performance**: Profile and optimize for your target headset

## Debug Connection in VR

The GodotBridge debug connection system works in VR mode! You can:

- Connect to the debug adapter while in VR
- Set breakpoints and inspect variables
- Use the LSP for code completion
- Stream telemetry data to external clients

All through the HTTP API on port 8081 (or 8083-8085 if ports are in use).

This allows you to develop and debug VR experiences with AI assistance!

## Resources

- [Godot XR Documentation](https://docs.godotengine.org/en/stable/tutorials/xr/index.html)
- [OpenXR Documentation](https://www.khronos.org/openxr/)
- [Godot XR Tools](https://github.com/GodotVR/godot-xr-tools) - Community toolkit for VR development
- TELEMETRY_GUIDE.md - Real-time data streaming guide
- CLAUDE.md - Project architecture and development workflow
