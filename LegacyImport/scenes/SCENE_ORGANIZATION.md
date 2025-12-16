# Scene Organization Guide

**Last Updated:** 2025-12-04
**Status:** Reorganized for better project structure

This document describes the organization of all scene files in the SpaceTime VR project. All scenes are now properly organized into subdirectories instead of scattered in the root folder.

## Directory Structure

```
scenes/
├── audio/                    # Audio-related scenes
│   └── resonance_audio_controller.tscn
├── celestial/                # Celestial objects and space environments
│   ├── day_night_test.tscn
│   ├── moon_landing.tscn              # Main moon landing scene
│   ├── solar_system.tscn              # Basic solar system scene
│   └── solar_system_landing.tscn      # Planetary landing system (NEW)
├── player/                   # Player controllers and input
│   ├── resonance_input_controller.tscn
│   └── walking_controller.tscn
├── spacecraft/               # Spacecraft models and cockpit
│   ├── cockpit_model.tscn
│   └── spacecraft_exterior.tscn
├── ui/                       # User interface panels and HUD
│   ├── inventory_panel.tscn
│   ├── power_grid_panel.tscn
│   └── test_power_grid_hud.tscn
├── test/                     # Test and development scenes
│   ├── collision_validation.tscn
│   ├── minimal_test.tscn
│   ├── node_3d.tscn
│   ├── print_token_scene.tscn
│   ├── test_planet_terrain.tscn
│   └── voxel/                # Voxel terrain test scenes
│       ├── test_voxel_generator_procedural.tscn
│       ├── test_voxel_instantiation.tscn
│       ├── voxel_terrain_test.tscn
│       └── voxel_test_terrain.tscn
├── creature_test.tscn        # Creature AI testing
└── vr_main.tscn              # Main VR scene (original entry point)
```

## Main Scenes (Playable)

### Production Scenes

**vr_main.tscn** (`scenes/vr_main.tscn`)
- Original main VR scene
- Basic VR environment with XROrigin3D and controllers
- General-purpose VR testing ground
- **Entry Point:** Was original main scene in project.godot

**moon_landing.tscn** (`scenes/celestial/moon_landing.tscn`)
- Complete moon landing experience
- Features procedurally generated lunar terrain
- Includes spacecraft landing mechanics
- VR-enabled with walking controller
- **Status:** Fully functional with visual effects

**solar_system_landing.tscn** (`scenes/celestial/solar_system_landing.tscn`)
- NEW planetary landing system
- Connects solar system simulation with planet generation
- Enables landing on any planet in the solar system
- Target planets: Earth and Mars
- **Status:** Technical implementation complete, visual scale needs adjustment
- **Debug Hotkeys:**
  - F1: Toggle debug display
  - F2: Print planet distances
  - F3: Force generate Earth terrain
  - F4: Force generate Mars terrain

### Test Scenes

**minimal_test.tscn** (`scenes/test/minimal_test.tscn`)
- Minimal test environment
- Current main scene in project.godot (line 14)
- Used for quick testing and debugging

**Voxel Test Scenes** (`scenes/test/voxel/`)
- `voxel_test_terrain.tscn` - Basic voxel terrain testing
- `test_voxel_instantiation.tscn` - Voxel node instantiation tests
- `test_voxel_generator_procedural.tscn` - Procedural generation tests
- `voxel_terrain_test.tscn` - Comprehensive voxel system tests

## Scene Categories

### 1. Celestial Scenes (`scenes/celestial/`)
Scenes featuring space environments, planets, and celestial mechanics.

**Purpose:** Primary gameplay scenes for space exploration and planetary landing.

**Key Features:**
- Solar system initialization with orbital mechanics
- Procedural planet generation
- VR spacecraft controls
- Landing transition systems

### 2. Player Scenes (`scenes/player/`)
Player-specific scenes including controllers and input handlers.

**Purpose:** Reusable player components that can be instanced into other scenes.

**Key Components:**
- Walking controller for surface movement
- Input mapping and controller handling
- VR hand models and interactions

### 3. Spacecraft Scenes (`scenes/spacecraft/`)
Spacecraft models and interior/exterior components.

**Purpose:** Spacecraft assets for piloting and landing mechanics.

**Key Components:**
- Exterior spacecraft model (RigidBody3D)
- Cockpit interior with pilot position
- Thrust and flight controls

### 4. UI Scenes (`scenes/ui/`)
User interface panels and HUD elements.

**Purpose:** VR-compatible 3D UI elements for game systems.

**Key Components:**
- Power grid management panel
- Inventory system UI
- HUD testing scenes

### 5. Test Scenes (`scenes/test/`)
Development and testing scenes not meant for production.

**Purpose:** Isolated testing of specific features and systems.

**Subdirectories:**
- `voxel/` - Voxel terrain testing scenes

### 6. Audio Scenes (`scenes/audio/`)
Audio controllers and spatial audio systems.

**Purpose:** Audio management and spatial sound in VR.

## Main Scene Layer Architecture

The `solar_system_landing.tscn` scene uses a layered "onion" architecture:

### Layer 0: Foundation
- SolarSystemInitializer
- XROrigin3D (VR)
- PlayerSpacecraft
- Environment

### Layer 1: Life Support
- LifeSupportSystem (oxygen, temperature)

### Layer 2: Inventory
- InventorySystem (resource storage)

### Layer 3: Resources
- ResourceSystem (resource management)

### Layer 4: Power
- PowerGridSystem (power distribution)

### Layer 5: UI (Planned)
- VR HUD for displaying stats

## Accessing Layers from Code

To access specific layers from GDScript:

```gdscript
# Get the root scene
var root = get_tree().current_scene

# Access Foundation layer (Layer 0)
var solar_system_init = root.get_node("SolarSystemInitializer")
var xr_origin = root.get_node("XROrigin3D")

# Access Life Support layer (Layer 1)
var life_support = root.get_node("LifeSupportSystem")

# Access Inventory layer (Layer 2)
var inventory = root.get_node("InventorySystem")

# Access Resources layer (Layer 3)
var resources = root.get_node("ResourceSystem")

# Access Power layer (Layer 4)
var power_grid = root.get_node("PowerGridSystem")
```

This layered architecture allows independent system testing and hot-reloading of individual subsystems without affecting the entire scene hierarchy.

## How to Open Scenes in Godot

### Method 1: Via FileSystem Panel
1. Open Godot editor
2. Look at the FileSystem panel (bottom-left by default)
3. Navigate to `res://scenes/[category]/`
4. Double-click the scene you want to open

### Method 2: Via Quick Open (Fastest)
1. Press `Ctrl+Shift+O` (or `Cmd+Shift+O` on Mac)
2. Type part of the scene name
3. Press Enter to open

### Method 3: Via Scene Menu
1. Click "Scene" in the top menu
2. Select "Open Scene..."
3. Navigate to the scene folder
4. Select the .tscn file

## Running Scenes

### From Godot Editor
- **Current Scene:** Press `F6` to run the currently open scene
- **Main Scene:** Press `F5` to run the main scene (minimal_test.tscn)
- **Specific Scene:** Press `F6` after opening desired scene

### From Command Line
```bash
# Run a specific scene
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/godot" "res://scenes/celestial/moon_landing.tscn"

# Run in VR mode
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path "C:/godot" "res://scenes/celestial/solar_system_landing.tscn" --vr --fullscreen
```

## Scene Dependencies

### Common Dependencies
Most scenes depend on these autoload singletons (defined in project.godot):
- `ResonanceEngine` - Core engine coordinator
- `HttpApiServer` - HTTP REST API server
- `SettingsManager` - Settings management
- `VoxelPerformanceMonitor` - Voxel terrain monitoring

### Scene-Specific Dependencies

**solar_system_landing.tscn:**
- `scripts/celestial/solar_system_initializer.gd`
- `scripts/celestial/solar_system_landing_controller.gd`
- `scripts/celestial/planetary_terrain_manager.gd`
- `scripts/player/planet_surface_spawner.gd`
- `scenes/spacecraft/spacecraft_exterior.tscn` (instanced)
- `data/ephemeris/solar_system.json` (planet data)

**moon_landing.tscn:**
- `scripts/player/walking_controller.gd`
- `scripts/voxel_terrain_generator.gd`
- VR controller scripts

## Current Issues and Known Limitations

### Solar System Landing Scene
**Issue:** Player sees only darkness on initial load
**Cause:** Player spawns at 20 million km from planets, which are rendered too small (radius_display_scale = 100.0)
**Workaround:** Use F3 (Earth) or F4 (Mars) hotkeys to force terrain generation
**Fix Needed:** Either increase radius_display_scale or reposition player closer to target planet

### Voxel Test Scenes
**Status:** Some scenes may reference old paths due to reorganization
**Fix:** May need to update scene paths in project.godot if referenced as autorun scenes

## Migration Notes

### Scenes Moved from Root
The following scenes were moved from the root directory:
- `solar_system_landing.tscn` → `scenes/celestial/`
- `moon_landing.tscn` → `scenes/celestial/`
- `vr_main.tscn` → `scenes/`
- `voxel_test_terrain.tscn` → `scenes/test/voxel/`
- `test_voxel_instantiation.tscn` → `scenes/test/voxel/`
- `test_voxel_generator_procedural.tscn` → `scenes/test/voxel/`
- `voxel_terrain_test.tscn` → `scenes/test/voxel/`
- `test_planet_terrain.tscn` → `scenes/test/`
- `minimal_test.tscn` → `scenes/test/`
- `print_token_scene.tscn` → `scenes/test/`
- `node_3d.tscn` → `scenes/test/`

### Path Updates Required
If you have any scripts or configurations that hardcode scene paths, update them:
```gdscript
# OLD (will not work)
var scene = load("res://moon_landing.tscn")

# NEW (correct)
var scene = load("res://scenes/celestial/moon_landing.tscn")
```

## Best Practices

### Creating New Scenes
1. **Choose the right category:**
   - Gameplay scenes → `scenes/celestial/` or `scenes/spacecraft/`
   - Player components → `scenes/player/`
   - UI elements → `scenes/ui/`
   - Test/debug → `scenes/test/`

2. **Use descriptive names:**
   - ✅ `planet_surface_walkable.tscn`
   - ❌ `test123.tscn`

3. **Keep test scenes separate:**
   - Never put test scenes in production categories
   - Use `scenes/test/` for all experimental work

### Scene Naming Conventions
- Use snake_case (lowercase with underscores)
- Be specific: `moon_landing.tscn` not `landing.tscn`
- Include system name for subsystems: `voxel_terrain_test.tscn`

## Advanced: Scene Preloading

For frequently used scenes, consider preloading at file scope:

```gdscript
# At top of script file
const WalkingController = preload("res://scenes/player/walking_controller.tscn")
const SpacecraftExterior = preload("res://scenes/spacecraft/spacecraft_exterior.tscn")

# Later in code
func spawn_spacecraft() -> void:
    var spacecraft = SpacecraftExterior.instantiate()
    add_child(spacecraft)
```

This is more efficient than `load()` at runtime.

## Troubleshooting

### "Scene not found" errors
- Check that you're using `res://scenes/[category]/[scene_name].tscn`
- Verify the scene exists in FileSystem panel
- Use Quick Open (`Ctrl+Shift+O`) to verify scene path

### Scene opens but is broken
- Check Output panel for missing dependency errors
- Verify all external resources (scripts, textures) exist
- Check if scene depends on autoloads that are disabled

### VR scenes don't initialize
- Ensure `--vr` flag is used when launching from command line
- Check that OpenXR plugin is enabled in Project Settings
- Verify XROrigin3D and XRCamera3D are in the scene

## Future Organization

As the project grows, consider these additional categories:
- `scenes/environments/` - Reusable environment presets
- `scenes/effects/` - VFX and particle scenes
- `scenes/creatures/` - NPC and creature scenes (currently `creature_test.tscn` in scenes/)
- `scenes/missions/` - Mission-specific scenes

## See Also

- `CLAUDE.md` - Main project documentation
- `docs/CURRENT_ITERATION_PROMPT.md` - Current development focus
- `project.godot` - Project configuration and autoloads
