# Universal Session Start Prompt

Copy-paste this at the start of every session:

---

```
PROJECT: SpaceTime - VR-first space exploration game
ENGINE: Godot 4.5.1
LOCATION: C:/Ignotus
PLATFORM: Windows (MINGW64_NT-10.0-26200)

HARDWARE:
- VR: BigScreen Beyond + Valve Index controllers
- GPU: NVIDIA GeForce RTX 4090
- Runtime: SteamVR/OpenXR 2.14.4

VR WORKFLOW (CRITICAL):
1. Never mark VR work complete without user confirming what they see in headset
2. Console "VR initialized" means NOTHING - only user confirmation counts
3. Always ask "What do you see in your headset?" and WAIT for response
4. Gray/black screen = broken, needs fixing
5. Only mark complete when user describes expected geometry

GODOT COMMANDS:
# Launch VR scene
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "." "res://scenes/[scene].tscn"

# Launch editor
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "." --editor

# Restart Godot with debug
./restart_godot_with_debug.bat

# Kill Godot processes
taskkill //F //IM Godot_v4.5.1-stable_win64_console.exe

VERIFICATION COMMANDS:
# Complete verification (static + runtime)
python scripts/tools/verify_complete.py

# Phase-specific verification
python scripts/tools/verify_phase.py --phase 0

# Check Godot errors
python scripts/tools/check_godot_errors.py

# Godot management
python scripts/tools/godot_manager.py --restart --capture
python scripts/tools/godot_manager.py --kill

TESTING COMMANDS:
# GdUnit4 tests (requires GUI mode)
# Use GdUnit4 panel in Godot editor

# Python runtime tests
python tests/test_bug_fixes_runtime.py --verbose

# Run all tests
python run_all_tests.py --verbose

# Voxel tests
run_voxel_tests.bat

REMOTE CONTROL:
# Check DAP (port 6006)
netstat -ano | grep 6006

# Connect via DAP
python scripts/tools/dap_controller.py

# Check HTTP API (port 8080)
curl http://127.0.0.1:8080/status

# Scene management via HTTP
curl -X POST http://localhost:8080/scene -H "Content-Type: application/json" -d '{"scene_path": "res://[scene].tscn"}'
curl http://localhost:8080/scene
curl -X POST http://localhost:8080/scene/reload

GIT COMMANDS:
# Check status
git status

# Create commit
git add .
git commit -m "message

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# Check branch
git branch

PORTS:
- 6006: DAP (Debug Adapter Protocol)
- 8080: HTTP REST API
- 8081: WebSocket telemetry
- 8087: UDP service discovery

PROJECT STRUCTURE:
- scripts/core/engine.gd - ResonanceEngine (main coordinator)
- scripts/http_api/http_api_server.gd - HTTP API (port 8080)
- scripts/vr/ - VR systems
- scenes/features/minimal_vr_test.tscn - Validated VR test scene
- addons/godot-xr-tools/ - VR toolkit
- addons/gdUnit4/ - Unit testing
- tests/ - Test suite

KEY SCENES:
- minimal_vr_test.tscn - Simple VR test (RED CUBE, validated working)
- vr_main.tscn - Main VR scene (solar system)
- vr_locomotion_test.tscn - VR flight movement test

AUTOLOADS (project.godot):
- XRToolsUserSettings
- XRToolsRumbleManager
- AstronomicalCoordinateSystem
- FloatingOriginSystem
- GravityManager

DOCUMENTATION:
1. CLAUDE.md - Main project doc
2. docs/INDEX.md - Complete documentation catalog
3. docs/VR_TESTING_WORKFLOW.md - VR testing (MANDATORY)
4. docs/VR_INITIALIZATION_GUIDE.md - VR setup patterns
5. docs/DAP_REMOTE_CONTROL_GUIDE.md - Remote control guide
6. README.md - Quick start

VR INITIALIZATION PATTERN (CRITICAL):
var xr_interface = XRServer.find_interface("OpenXR")
if xr_interface and xr_interface.initialize():
    get_viewport().use_xr = true  # THE CRITICAL LINE
    $XROrigin3D/XRCamera3D.current = true

WORKFLOW:
1. Use TodoWrite for multi-step tasks
2. DECIDE → IMPLEMENT → VERIFY → FIX → COMPLETE
3. For VR: Add user confirmation before marking complete
4. Read docs before starting
5. Zero errors is mandatory (exit code 0)

CURRENT STATE:
- VR validated working (BigScreen Beyond)
- Working test scene: minimal_vr_test.tscn
- DAP remote control on port 6006
- HTTP API on port 8080
- Phase 2 Week 5 complete
- Code quality: 7.6/10
- Production ready: 98%
Update this file as needed for evolving workflow methodology that is successful
Start working.
```
