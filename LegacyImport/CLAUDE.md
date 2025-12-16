# CLAUDE.md

**Last Updated:** 2025-12-10
**Status:** VR Validated + RL/AI Integration Active
**Version:** 3.2 - VR + AI/RL Architecture Documented

This file provides critical guidance to Claude Code when working with this Godot 4.5+ VR project.

**📚 Full Documentation:** [`docs/INDEX.md`](docs/INDEX.md)

---

## 🚨 CRITICAL: VR TRACKING ARCHITECTURE 🚨

**THE BUG:** After RL/ML implementation, VR tracking broke (gray screen, stuck at 0,0,0)
**ROOT CAUSE:** `player_body.global_position = xr_origin.global_position` in VR Player Mode
**THE FIX:** CharacterBody3D must follow XROrigin3D via scene tree, NOT manual position setting

### VR Player Mode vs AI Training Mode

**VR Player Mode** (`physics_movement_enabled = false`):
- XROrigin3D controlled by OpenXR tracking
- CharacterBody3D follows as child (automatic via scene tree)
- Physics ONLY for collisions, NOT position control
- **NEVER** set `player_body.global_position` manually

**AI Training Mode** (`gravity_enabled = true`):
- CharacterBody3D controlled by AI/physics
- XROrigin3D follows CharacterBody3D: `xr_origin.global_position = player_body.global_position`
- VR camera provides observation viewpoint

**CRITICAL DOCUMENTATION:**
- `docs/current/guides/VR_ARCHITECTURE.md` - Complete architecture explanation
- `VR_TRACKING_FAILURE_ROOT_CAUSE.md` - Bug analysis
- `vr_main.gd:148-206` - Implementation reference

**Scene Hierarchy Requirement:**
```
XROrigin3D (parent)
  └── CharacterBody3D (child) ← MUST be child for VR Player Mode!
```

**VR Tracking Troubleshooting:**
1. Check XRCamera3D.current = true, FallbackCamera.current = false
2. Verify OpenXR initialized successfully in console
3. Search for `player_body.global_position =` in VR Player Mode function
4. Confirm CharacterBody3D is child of XROrigin3D in scene tree

---

## 🚨 MANDATORY: ZERO-ERROR WORKFLOW 🚨

**After ANY changes:**
```bash
python scripts/tools/verify_phase.py --phase 0 --auto-fix
```

**Acceptance:** Exit code 0 only. No exceptions.

**VR Testing:** NEVER mark VR work complete without user confirmation of what they see in headset.

**Full Workflow:** `UNIVERSAL_MANDATORY_TESTING_PROMPT.md`

---

## Project Overview

SpaceTime: VR space simulation with OpenXR, HTTP REST API (port 8080), voxel terrain, AI/RL integration

**Main Scene:** `res://minimal_test.tscn`
**VR Scene:** `res://vr_main.tscn`

**Architecture:**
- ResonanceEngine autoload coordinates all subsystems
- HttpApiServer (port 8080) for remote control
- Dual-mode VR system (Player vs AI Training)
- 90 FPS physics tick rate

---

## Development Commands

**Verification (Mandatory):**
```bash
python scripts/tools/verify_phase.py --phase 0 --auto-fix
```

**Start Godot:**
```bash
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/Ignotus" --editor
```

**HTTP API:**
```bash
curl http://127.0.0.1:8080/status
curl -X POST http://localhost:8080/scene -H "Content-Type: application/json" -d '{"scene_path": "res://vr_main.tscn"}'
```

---

## Key Files & Locations

**VR System:**
- `vr_main.gd` - VR initialization and dual-mode physics
- `vr_main.tscn` - Main VR scene
- `scripts/vr_controller_basic.gd` - Controller input

**Core Systems:**
- `scripts/core/engine.gd` - ResonanceEngine coordinator
- `scripts/http_api/http_api_server.gd` - HTTP API server (port 8080)
- `scripts/core/voxel_performance_monitor.gd` - Voxel performance monitoring

**Documentation:**
- `docs/current/guides/VR_ARCHITECTURE.md` - VR + RL/AI architecture (CRITICAL)
- `docs/current/guides/DEPLOYMENT_GUIDE.md` - Production deployment
- `CODE_QUALITY_REPORT.md` - Code quality analysis
- `PRODUCTION_READINESS_CHECKLIST.md` - Pre-deployment checklist

---

## Critical Issues & Lessons

**VR + Physics Interaction:**
- Manual position setting breaks VR tracking
- CharacterBody3D must be child of XROrigin3D
- Different control flow for VR Player Mode vs AI Training Mode

**HTTP API:**
- Disabled by default in release builds (security feature)
- Set `GODOT_ENABLE_HTTP_API=true` for production
- Auto-enabled in editor mode

**Testing:**
- GdUnit4 tests require GUI mode (not headless)
- Verification must achieve exit code 0
- VR features require user headset confirmation

---

## Common Pitfalls

❌ **WRONG:** Setting CharacterBody3D position in VR Player Mode
```gdscript
player_body.global_position = xr_origin.global_position  # BREAKS VR!
```

✅ **CORRECT:** Let scene tree handle position
```gdscript
# CharacterBody3D follows XROrigin3D automatically
player_body.velocity = Vector3(0, velocity.y, 0)
player_body.move_and_slide()
```

❌ **WRONG:** Skipping verification after changes
✅ **CORRECT:** `python scripts/tools/verify_phase.py --phase 0 --auto-fix`

❌ **WRONG:** Marking VR work complete based on console output
✅ **CORRECT:** Ask user: "What do you see in your headset?"

---

## Production Status

**Readiness:** 98%
**Quality Score:** 7.6/10 (Good)
**Critical Pre-Deploy:**
1. Set `GODOT_ENABLE_HTTP_API=true`
2. Generate TLS certificates
3. Configure production whitelist
4. Test exported build with API enabled

**See:** `PRODUCTION_READINESS_CHECKLIST.md`

---

## Quick Reference

**Ports:**
- 8080: HTTP API (REST)
- 8081: WebSocket Telemetry
- 8087: UDP Service Discovery

**Physics:**
- Tick Rate: 90 FPS
- Default Gravity: 0.0 (space)
- VR Refresh: 90 Hz

**Platform:**
- Godot 4.5+
- Python 3.8+ (tooling)
- OpenXR VR headsets
- Windows Desktop (primary)

---

**For detailed information, see full documentation in `docs/` directory.**
