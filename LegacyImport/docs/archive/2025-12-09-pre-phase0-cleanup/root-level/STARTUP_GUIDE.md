# Godot HttpApiServer - Quick Start Guide

## Current Status (Phase 2A Complete)

✅ **0 GDScript compilation errors**
✅ **Phase 1**: Disabled problematic subsystems (tests, security, validation)
✅ **Phase 2A**: Re-enabled foundation systems
  - VR Menu System (1 file)
  - Inventory & Storage (3 files)
  - Resource Management (2 files)
  - Support classes: ResourceNode, VoxelTerrain stubs (2 files)
✅ **Clean editor startup**: Godot opens without crashes
✅ **Files removed**: vr_setup.gd, power_grid_hud.gd (per requirements)
✅ **Minimal scene script**: vr_main.gd created for basic VR initialization

## One-Command Startup

```cmd
start_godot_api.bat
```

This script:
1. Kills any existing Godot/Python processes
2. Clears Godot cache (.godot/)
3. Starts Godot editor with environment variables set
4. Waits 30 seconds for initialization
5. Checks if HttpApiServer is running

## Manual Startup (if needed)

```cmd
# Set environment variables
set GODOT_ENABLE_HTTP_API=1
set GODOT_ENV=development

# Start Godot
"C:\godot\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe" --path "C:\godot" --editor
```

## Running the Project (Required for HttpApiServer)

**Important**: Autoloads (including HttpApiServer) only initialize when you RUN the project, not just open the editor.

1. Open Godot editor (via start_godot_api.bat or manually)
2. Press **F5** or click the ▶ "Play" button
3. HttpApiServer will now start and open port 8080

## Verifying HttpApiServer

```cmd
# Check if port 8080 is listening
netstat -an | findstr ":8080.*LISTEN"

# Test the API
curl http://127.0.0.1:8080/health
```

## Project Structure

```
C:/godot/
├── start_godot_api.bat          # One-command startup
├── vr_main.tscn                 # Main VR scene
├── vr_main.gd                   # Minimal VR initialization script
├── scripts/
│   ├── core/                    # Core engine systems
│   │   └── engine.gd           # ResonanceEngine autoload
│   └── http_api/               # HTTP API system (port 8080)
│       └── http_api_server.gd  # HttpApiServer autoload
└── project.godot               # Project configuration

Disabled (moved to parent directory):
../godot_planetary_survival_disabled/  # 38 files, 564 errors
../godot_tests_disabled/              # 50 test files
../godot_security_disabled/           # Security subsystem
../godot_validation_disabled/         # Validation subsystem
```

## Autoloads (in order)

1. **ResonanceEngine** - Core engine coordinator
2. **HttpApiServer** - HTTP REST API (port 8080)
3. **SceneLoadMonitor** - Scene loading state tracker
4. **SettingsManager** - Configuration management

## Common Issues

### "Port 8080 not open"
- HttpApiServer only runs when project is running (F5), not in editor mode
- Press F5 in Godot editor to run the project

### "Godot crashes on startup"
- Run: `start_godot_api.bat` (includes cache clearing)
- Check: `godot_output.log` for errors

### "Compilation errors"
- Phase 1 is complete - should be 0 errors
- If errors appear, they're likely in re-enabled subsystems

## Next Steps (Phase 2+)

**Not yet started** - waiting for Phase 1 verification:

1. Fix planetary_survival/core files (11 files)
2. Fix planetary_survival/systems files (22 files)
3. Fix planetary_survival/ui files (5 files)
4. Re-enable and verify each subsystem
5. Re-enable tests and verify they pass

## Environment Variables

- `GODOT_ENABLE_HTTP_API=1` - Enables HttpApiServer in debug builds
- `GODOT_ENV=development` - Sets development environment mode

## Port Reference

| Port | Service | Status |
|------|---------|--------|
| 8080 | HttpApiServer | Active (when project runs) |
| 8081 | Telemetry WebSocket | Inactive (part of disabled subsystem) |
| 8087 | Service Discovery UDP | Inactive |
| 8090 | Python Server (optional) | Not needed for basic usage |
| 6005 | LSP | Available (Godot built-in) |
| 6006 | DAP | Available (Godot built-in) |

## Files Deleted (Per Requirements)

- `vr_setup.gd` - Player spawning (not needed, replaced with vr_main.gd)
- `power_grid_hud.gd` - Will be redesigned as part of menu system

## Logs

- `godot_output.log` - Most recent Godot console output
- `godot_*.log` - Various startup attempt logs (can be deleted)
