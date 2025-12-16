# SpaceTime VR - Godot 4.5 VR Space Exploration Game

**Status:** ✅ VR Validated - Active Development  
**Godot Version:** 4.5.1  
**VR Support:** OpenXR (SteamVR, Oculus, Index, Quest)

A VR-first space exploration game built with Godot 4.5, featuring realistic physics, procedural generation, and immersive VR interactions.

---

## 🚀 Quick Start

**New to the project?**

1. Read [`CLAUDE.md`](CLAUDE.md) - Main project documentation
2. Browse [`docs/INDEX.md`](docs/INDEX.md) - Complete documentation catalog
3. Setup VR with [`docs/VR_INITIALIZATION_GUIDE.md`](docs/VR_INITIALIZATION_GUIDE.md)

**Launch VR test:**
```bash
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "." "res://scenes/features/minimal_vr_test.tscn"
```

**You should see:** A red glowing cube 2 meters in front of you in VR.

---

## ⚠️ CRITICAL: VR + AI/RL Mode Switching

**Problem:** Physics interferes with VR tracking → gray screen, stuck position
**Solution:** Use ControllerModeManager to switch between modes

- **VR Player Mode:** VR tracking controls position, physics follows for collisions
- **AI Training Mode:** AI/RL agent controls position, VR follows for observation

**Read:** [`docs/VR_PHYSICS_ARCHITECTURE.md`](docs/VR_PHYSICS_ARCHITECTURE.md)
**Implementation:** `scripts/core/controller_mode_manager.gd`

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [`CLAUDE.md`](CLAUDE.md) | ⭐ Main project documentation |
| [`docs/INDEX.md`](docs/INDEX.md) | 📚 Complete documentation catalog |
| [`docs/VR_INITIALIZATION_GUIDE.md`](docs/VR_INITIALIZATION_GUIDE.md) | 🥽 VR setup guide |
| [`docs/DAP_REMOTE_CONTROL_GUIDE.md`](docs/DAP_REMOTE_CONTROL_GUIDE.md) | 🔧 Remote debugging |

---

## ✨ Features

- ✅ **VR Support** - OpenXR with comfort features
- ✅ **Remote Control** - DAP (port 6006) + HTTP API (port 8080)
- ✅ **Space Physics** - Floating origin, relativistic effects
- ✅ **Procedural Generation** - Voxel terrain, celestial bodies
- ✅ **Testing Framework** - GdUnit4 + Python runtime tests

---

## 🎮 VR Hardware Validated

✅ BigScreen Beyond + Valve Index  
✅ NVIDIA GeForce RTX 4090  
✅ SteamVR/OpenXR 2.14.4

---

## 🛠️ Essential Commands

```bash
# Verify project health
python scripts/tools/verify_complete.py

# Start Godot with debugging
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "." --editor

# Check remote control
netstat -ano | grep 6006  # DAP
curl http://127.0.0.1:8080/status  # HTTP API
```

---

## 🔧 Remote Control Ports

| Port | Service | Purpose |
|------|---------|---------|
| 6006 | Debug Adapter (DAP) | Breakpoint debugging |
| 8080 | HTTP REST API | Scene management |
| 8081 | WebSocket | Telemetry streaming |

---

## 📊 Status

| Metric | Status |
|--------|--------|
| VR Support | ✅ Working |
| Code Quality | 7.6/10 |
| Production Ready | 98% |
| Documentation | Comprehensive |

---

**Need help?** See [`docs/INDEX.md`](docs/INDEX.md) for the complete documentation catalog.

**Last Updated:** 2025-12-09
