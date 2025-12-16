# SpaceTime VR Project - Documentation Index

**Last Updated:** 2025-12-09
**Project Status:** VR Validated - Development Active
**Godot Version:** 4.5.1

---

## Quick Start

**New to the project?** Start here:
1. [`CLAUDE.md`](../CLAUDE.md) - Main project overview and commands
2. [`VR_INITIALIZATION_GUIDE.md`](VR_INITIALIZATION_GUIDE.md) - Get VR working
3. [`DEVELOPMENT_WORKFLOW.md`](current/guides/DEVELOPMENT_WORKFLOW.md) - Development process

---

## Core Documentation

### Project Overview
- **[`CLAUDE.md`](../CLAUDE.md)** - Main project documentation (READ THIS FIRST)
  - Project architecture
  - Development commands
  - API ports and services
  - Mandatory testing workflow
  - Quick reference for all features

### Getting Started
- **[`PROJECT_START.md`](../PROJECT_START.md)** - Initial project setup
- **[`TDD_WORKFLOW.md`](../TDD_WORKFLOW.md)** - Test-driven development workflow
- **[`WORKFLOW_QUICK_START.md`](../WORKFLOW_QUICK_START.md)** - Quick development workflow reference

---

## VR Development (✨ NEW)

### VR Initialization & Testing
- **[`VR_INITIALIZATION_GUIDE.md`](VR_INITIALIZATION_GUIDE.md)** ⭐ **ESSENTIAL**
  - Complete VR setup guide
  - Critical initialization pattern (4 steps)
  - Common mistakes and fixes
  - Working code examples
  - Troubleshooting guide
  - Command-line testing methods
  - Console output reference
  - Validated with BigScreen Beyond + Valve Index

### VR Testing & Validation
- **[`VR_TESTING_WORKFLOW.md`](VR_TESTING_WORKFLOW.md)** ⭐ **MANDATORY for VR debugging**
  - Step-by-step VR debugging workflow
  - Console output analysis guide
  - Gray screen troubleshooting
  - Common error patterns and fixes
  - Scene launch methods
  - SteamVR status checking
- **[`VR_TESTING_PROTOCOL_WEEK5.md`](VR_TESTING_PROTOCOL_WEEK5.md)** - Comprehensive VR test cases
- **[`VR_QUICK_START_WEEK5.md`](VR_QUICK_START_WEEK5.md)** - Quick VR testing guide
- **[`PHASE2_WEEK5_VR_SESSION_REPORT.md`](PHASE2_WEEK5_VR_SESSION_REPORT.md)** - VR validation session report

### VR + AI/RL Controller Mode Switching
- **[`VR_PHYSICS_ARCHITECTURE.md`](VR_PHYSICS_ARCHITECTURE.md)** ⭐ **CRITICAL ARCHITECTURE**
  - Why physics interferes with VR tracking
  - VR Player Mode vs AI Training Mode
  - Correct architecture patterns
  - CharacterBody3D vs XROrigin3D relationship
  - Implementation checklist
- **`scripts/core/controller_mode_manager.gd`** - Controller mode switching system
  - Switch between VR Player and AI Training modes
  - Prevents physics from overriding VR tracking
  - Enables RL agent control when needed

---

## Remote Control & Debugging

### Debug Adapter Protocol (DAP)
- **[`DAP_REMOTE_CONTROL_GUIDE.md`](DAP_REMOTE_CONTROL_GUIDE.md)** ⭐ **ESSENTIAL**
  - Connect to Godot on port 6006
  - Inspect scene state remotely
  - Python tools for DAP control
  - Capabilities and limitations
  - When to use DAP vs HTTP API

### HTTP API
- **[`HTTP_API_ROUTER_STATUS.md`](../HTTP_API_ROUTER_STATUS.md)** - HTTP API endpoints (port 8080)
- **[`ROUTER_ACTIVATION_PLAN.md`](../ROUTER_ACTIVATION_PLAN.md)** - API activation roadmap

---

## Development Guides

### Workflow & Process
- **[`DEVELOPMENT_WORKFLOW.md`](current/guides/DEVELOPMENT_WORKFLOW.md)** - Player-centric feature roadmap
- **[`UNIVERSAL_GAME_DEV_PROMPT.md`](../UNIVERSAL_GAME_DEV_PROMPT.md)** - 9-phase universal game dev loop
- **[`UNIVERSAL_MANDATORY_TESTING_PROMPT.md`](../UNIVERSAL_MANDATORY_TESTING_PROMPT.md)** - Mandatory testing workflow

### Deployment
- **[`DEPLOYMENT_GUIDE.md`](current/guides/DEPLOYMENT_GUIDE.md)** - Production deployment guide
- **[`PRODUCTION_READINESS_CHECKLIST.md`](../PRODUCTION_READINESS_CHECKLIST.md)** - Pre-deployment checklist

---

## Code Quality & Testing

### Quality Assurance
- **[`CODE_QUALITY_REPORT.md`](../CODE_QUALITY_REPORT.md)** - Code quality analysis (7.6/10)
- **[`TEST_INFRASTRUCTURE_STATUS.md`](../TEST_INFRASTRUCTURE_STATUS.md)** - Testing infrastructure status

### Testing Tools
- `scripts/tools/verify_complete.py` - Complete verification (static + runtime)
- `scripts/tools/verify_phase.py` - Phase-specific verification
- `scripts/tools/godot_manager.py` - Godot process management
- `scripts/tools/check_godot_errors.py` - Error checking tool
n### AI-Powered Testing
- **[`RL_AGENTS_INTEGRATION_GUIDE.md`](RL_AGENTS_INTEGRATION_GUIDE.md)** ⭐ **NEW**
  - Godot RL Agents integration for automated playtesting
  - VR locomotion testing scenarios
  - Spacecraft landing automation
  - Voxel terrain stress testing
  - CI/CD integration for regression detection
  - Performance optimization strategies
  - Complete implementation examples

---

## Architecture & Systems

### Core Systems
- **ResonanceEngine** - Central coordinator (`scripts/core/engine.gd`)
  - Phase-based subsystem initialization
  - Autoload management
  - Dependency ordering

### Key Subsystems
- **VR System** - OpenXR integration, comfort features
- **HTTP API** - REST API on port 8080 (scene management, control)
- **DAP Integration** - Debug adapter on port 6006 (inspection, debugging)
- **Floating Origin** - Large-scale coordinate management
- **Gravity Manager** - Custom gravity system
- **Voxel Terrain** - Procedural terrain generation

---

## Tools & Utilities

### Python Tools (scripts/tools/)
- **DAP Control:**
  - `dap_inspector.py` - Basic DAP connection and inspection
  - `dap_controller.py` - Enhanced DAP controller
  - `godot_remote_control.py` - Full remote control interface

- **Verification:**
  - `verify_complete.py` - Complete verification suite
  - `verify_phase.py` - Phase-specific verification
  - `verify_godot_zero_errors.py` - Zero-error enforcement
  - `check_godot_errors.py` - Error analysis

- **Godot Management:**
  - `godot_manager.py` - Start/stop/restart Godot
  - `manual_testing_protocol.py` - Manual testing workflows

### Batch Scripts (Windows)
- `launch_vr_test.bat` - Launch VR test scene
- `run_voxel_tests.bat` - Run voxel terrain tests
- `restart_godot_with_debug.bat` - Restart Godot with debugging

---

## Scene Files

### VR Scenes
- **`scenes/features/minimal_vr_test.tscn`** ⭐ **WORKING VR TEST**
  - Minimal VR scene with red cube
  - Guaranteed to work (validated)
  - Use as VR reference implementation

- `scenes/vr_main.tscn` - Main VR scene (solar system)
- `scenes/features/vr_tracking_test.tscn` - VR tracking test

### Test Scenes
- `minimal_test.tscn` - Simple desktop test (cube + platform)
- `scenes/features/ship_interaction_test_vr.tscn` - Ship interaction (WIP)

---

## Project Structure

```
C:\Ignotus\
├── scripts/
│   ├── core/                 # Core engine systems
│   │   ├── engine.gd         # ResonanceEngine (main coordinator)
│   │   ├── voxel_performance_monitor.gd
│   │   └── settings_manager.gd
│   ├── http_api/            # HTTP REST API (port 8080)
│   │   ├── http_api_server.gd
│   │   └── scene_load_monitor.gd
│   ├── tools/               # Python development tools
│   │   ├── dap_*.py         # DAP remote control
│   │   ├── verify_*.py      # Verification tools
│   │   └── godot_manager.py # Godot management
│   ├── vr/                  # VR systems
│   ├── celestial/           # Space physics
│   └── player/              # Player controls
├── scenes/
│   ├── features/            # Feature test scenes
│   │   └── minimal_vr_test.tscn  # ⭐ Working VR test
│   ├── vr_main.tscn         # Main VR scene
│   └── spacecraft/          # Ship scenes
├── docs/                    # Documentation
│   ├── INDEX.md             # This file
│   ├── VR_INITIALIZATION_GUIDE.md  # ⭐ VR setup guide
│   ├── DAP_REMOTE_CONTROL_GUIDE.md # ⭐ Remote control guide
│   └── current/guides/      # Development guides
├── addons/
│   ├── godottpd/            # HTTP server library
│   ├── gdUnit4/             # Unit testing framework
│   └── godot-xr-tools/      # VR toolkit
├── tests/                   # Test suite
│   ├── unit/                # GDScript unit tests
│   └── test_*.py            # Python runtime tests
├── project.godot            # Godot project config
├── CLAUDE.md                # ⭐ Main documentation
└── vr_main.gd               # VR main scene script
```

---

## Port Reference

| Port | Protocol | Service | Status | Purpose |
|------|----------|---------|--------|---------|
| 6006 | TCP (DAP) | Debug Adapter | ✅ Active | Breakpoint debugging, scene inspection |
| 8080 | HTTP | REST API | ⏸️ Requires main scene | Scene management, runtime control |
| 8081 | WebSocket | Telemetry | ⏸️ Requires main scene | Real-time performance metrics |
| 8087 | UDP | Discovery | ⏸️ Requires main scene | Service discovery broadcast |

**Note:** HTTP API and related services only activate when main scene runs (initializes autoloads).

---

## Development Commands Quick Reference

### Start Godot
```bash
# Windows (with console output)
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/Ignotus" --editor

# Launch specific VR scene
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/Ignotus" "res://scenes/features/minimal_vr_test.tscn"
```

### Verification
```bash
# Complete verification (static + runtime)
python scripts/tools/verify_complete.py

# Phase-specific verification
python scripts/tools/verify_phase.py --phase 0

# Check for Godot errors
python scripts/tools/check_godot_errors.py
```

### Godot Management
```bash
# Restart Godot with debug capture
python scripts/tools/godot_manager.py --restart --capture

# Kill Godot processes
python scripts/tools/godot_manager.py --kill
```

### Remote Control
```bash
# Check DAP connection (port 6006)
netstat -ano | grep 6006

# Connect via Python
python scripts/tools/dap_controller.py

# Check HTTP API (port 8080)
curl http://127.0.0.1:8080/status
```

---

## Hardware Validated

**VR System Tested:**
- **Headset:** BigScreen Beyond
- **Controllers:** Valve Index controllers
- **GPU:** NVIDIA GeForce RTX 4090
- **VR Runtime:** SteamVR/OpenXR 2.14.4
- **OS:** Windows (MINGW64_NT-10.0-26200)

---

## Critical Files for AI Agents

When continuing development, these files are essential:

1. **`CLAUDE.md`** - Project overview, commands, architecture
2. **`VR_INITIALIZATION_GUIDE.md`** - VR setup and troubleshooting
3. **`DAP_REMOTE_CONTROL_GUIDE.md`** - Remote control capabilities
4. **`CODE_QUALITY_REPORT.md`** - Known issues and improvements
5. **`PRODUCTION_READINESS_CHECKLIST.md`** - Deployment requirements

---

## Status Summary

| System | Status | Notes |
|--------|--------|-------|
| VR Support | ✅ Working | Validated with BigScreen Beyond |
| DAP Remote Control | ✅ Active | Port 6006 for debugging |
| HTTP API | ✅ Implemented | Port 8080 (requires scene running) |
| Code Quality | 7.6/10 | Good - see CODE_QUALITY_REPORT.md |
| Production Ready | 98% | See PRODUCTION_READINESS_CHECKLIST.md |
| Test Coverage | Partial | GdUnit4 + Python runtime tests |

---

## Recent Updates (2025-12-09)

### Major Achievements
- ✅ **VR Validation Complete** - Tested with real hardware (BigScreen Beyond)
- ✅ **DAP Remote Control** - Established connection on port 6006
- ✅ **VR Initialization Fixed** - Critical `use_xr = true` pattern documented
- ✅ **Comprehensive Documentation** - VR guide and DAP guide created
- ✅ **Working Test Scene** - `minimal_vr_test.tscn` validated

### Files Created
- `docs/VR_INITIALIZATION_GUIDE.md` - Complete VR setup guide
- `docs/DAP_REMOTE_CONTROL_GUIDE.md` - Remote control guide
- `docs/PHASE2_WEEK5_VR_SESSION_REPORT.md` - Session report
- `scenes/features/minimal_vr_test.tscn` - Working VR test scene
- `scenes/features/minimal_vr_test.gd` - VR test script
- `scripts/tools/dap_inspector.py` - DAP connection tool
- `scripts/tools/dap_controller.py` - DAP enhanced controller
- `scripts/tools/godot_remote_control.py` - Full remote control

### Files Modified
- `vr_main.gd` - Fixed VR initialization (added `xr_interface.initialize()`)
- `project.godot` - Set main scene to `minimal_vr_test.tscn`
- `CLAUDE.md` - Added DAP documentation section
- `scenes/spacecraft/simple_ship_interior.tscn` - Fixed collision shape syntax

---

## Next Steps

### Immediate Priorities
1. Complete Phase 2 Week 5 ship interaction testing
2. Implement VR locomotion (Phase 2 Week 6)
3. Add VR comfort features validation
4. Performance profiling (90 FPS target)

### Future Development
- Phase 3: Advanced VR interactions
- Phase 4: Multiplayer VR
- Phase 5: Planetary survival with VR

---

## Support & Resources

### External Documentation
- **Godot XR Documentation:** https://docs.godotengine.org/en/stable/tutorials/xr/
- **OpenXR Specification:** https://www.khronos.org/openxr/
- **GdUnit4 Documentation:** https://mikeschulze.github.io/gdUnit4/

### Internal Resources
- GitHub Issues: https://github.com/anthropics/claude-code/issues
- Project Repository: (Add your repo URL here)

---

**Last Updated:** 2025-12-09
**Maintainer:** Claude Code AI Assistant
**Project Version:** 1.0.0 - VR Validated Edition
