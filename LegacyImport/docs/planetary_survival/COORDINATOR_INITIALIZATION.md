# PlanetarySurvivalCoordinator Initialization Sequence

## Overview

The `PlanetarySurvivalCoordinator` is the central autoload singleton that manages all planetary survival game systems. It initializes subsystems in strict dependency order across five phases.

**Location:** `scripts/planetary_survival/planetary_survival_coordinator.gd`

**Autoload Configuration:** Registered in `project.godot` as `PlanetarySurvivalCoordinator`

## Critical Information

### Autoload Status
The coordinator MUST be enabled in `project.godot` for the game to function:

```ini
[autoload]
PlanetarySurvivalCoordinator="*res://scripts/planetary_survival/planetary_survival_coordinator.gd"
```

**IMPORTANT:** If this line is commented out, NO planetary survival systems will initialize, causing complete game failure.

### Initialization Trigger
Systems initialize automatically in `_ready()` when the autoload is instantiated at game startup.

## Initialization Phases

The coordinator initializes systems across 5 phases, respecting dependency order:

### Phase 1: Core Data Systems (No Dependencies)

These systems have no dependencies and can initialize first:

1. **PowerGridSystem**
   - Purpose: Manages electrical power generation, storage, and distribution
   - Dependencies: None
   - Script: `scripts/planetary_survival/systems/power_grid_system.gd`

2. **SolarSystemGenerator**
   - Purpose: Generates procedural solar systems with planets and moons
   - Dependencies: None
   - Script: `scripts/planetary_survival/systems/solar_system_generator.gd`

### Phase 2: Terrain and Resources

Systems that manage the world and resource placement:

3. **VoxelTerrain**
   - Purpose: Voxel-based destructible terrain system
   - Dependencies: None
   - Script: `scripts/planetary_survival/systems/voxel_terrain.gd`

4. **ResourceSystem**
   - Purpose: Manages resource nodes, gathering, and inventory
   - Dependencies: `VoxelTerrain` (requires terrain reference)
   - Script: `scripts/planetary_survival/systems/resource_system.gd`
   - **Dependency Injection:** `resource_system.voxel_terrain = voxel_terrain`

### Phase 3: Gameplay Systems

Core gameplay mechanics that depend on Phase 1 and 2 systems:

5. **CraftingSystem**
   - Purpose: Handles item crafting, recipes, and fabrication
   - Dependencies: `ResourceSystem` (needs resources for crafting)
   - Script: `scripts/planetary_survival/systems/crafting_system.gd`
   - **Dependency Injection:** `crafting_system.resource_system = resource_system`

6. **LifeSupportSystem**
   - Purpose: Manages oxygen, temperature, and environmental hazards
   - Dependencies: None
   - Script: `scripts/planetary_survival/systems/life_support_system.gd`

7. **CreatureSystem**
   - Purpose: Manages creatures, wildlife, farming, and breeding
   - Dependencies: `ResourceSystem` (creatures can drop resources)
   - Script: `scripts/planetary_survival/systems/creature_system.gd`
   - **Dependency Injection:** `creature_system.resource_system = resource_system`

8. **PlayerSpawnSystem**
   - Purpose: Handles player spawn points and respawning
   - Dependencies: None
   - Script: `scripts/planetary_survival/systems/player_spawn_system.gd`

### Phase 4: Advanced Systems

Complex systems that depend on multiple Phase 1-3 systems:

9. **AutomationSystem**
   - Purpose: Manages automated production chains, conveyors, and logistics
   - Dependencies: `PowerGridSystem`, `ResourceSystem`
   - Script: `scripts/planetary_survival/systems/automation_system.gd`
   - **Dependency Injection:**
     - `automation_system.power_grid_system = power_grid_system`
     - `automation_system.resource_system = resource_system`

10. **BaseBuildingSystem**
    - Purpose: Manages base construction, module placement, and habitat systems
    - Dependencies: `VoxelTerrain`, `PowerGridSystem`, `LifeSupportSystem`
    - Script: `scripts/planetary_survival/systems/base_building_system.gd`
    - **Dependency Injection:**
      - `base_building_system.voxel_terrain = voxel_terrain`
      - `base_building_system.power_grid_system = power_grid_system`
      - `base_building_system.life_support_system = life_support_system`

### Phase 5: Networking (Optional - Disabled by Default)

Multiplayer systems only initialize if `is_multiplayer_enabled = true`:

11. **NetworkSyncSystem**
    - Purpose: Synchronizes game state across network
    - Dependencies: None
    - Script: `scripts/planetary_survival/systems/network_sync_system.gd`
    - **Status:** Only initialized if multiplayer is enabled

12. **ServerMeshCoordinator**
    - Purpose: Coordinates multiple server instances for massive multiplayer
    - Dependencies: None
    - Script: `scripts/planetary_survival/systems/server_mesh_coordinator.gd`
    - **Status:** Only initialized if multiplayer is enabled

13. **LoadBalancer**
    - Purpose: Balances player load across server mesh
    - Dependencies: `ServerMeshCoordinator`
    - Script: `scripts/planetary_survival/systems/load_balancer.gd`
    - **Dependency Injection:** `load_balancer.server_mesh_coordinator = server_mesh_coordinator`
    - **Status:** Only initialized if multiplayer is enabled

## Dependency Graph

```
Phase 1 (No Dependencies):
  PowerGridSystem ────────────────┐
  SolarSystemGenerator            │
                                  │
Phase 2 (Terrain):                │
  VoxelTerrain ──────┬────────────┤
                     │            │
  ResourceSystem <───┘            │
       │                          │
Phase 3 (Gameplay):  │            │
  CraftingSystem <───┤            │
  LifeSupportSystem ─┼────────────┤
  CreatureSystem <───┤            │
  PlayerSpawnSystem  │            │
                     │            │
Phase 4 (Advanced):  │            │
  AutomationSystem <─┴────────────┤
       │                          │
  BaseBuildingSystem <────────────┴──<VoxelTerrain, LifeSupportSystem>

Phase 5 (Networking - Optional):
  NetworkSyncSystem
  ServerMeshCoordinator ──┐
  LoadBalancer <──────────┘
```

## Critical Dependencies Summary

| System | Depends On | Reason |
|--------|-----------|--------|
| ResourceSystem | VoxelTerrain | Needs terrain to place resource nodes |
| CraftingSystem | ResourceSystem | Uses resources for crafting recipes |
| CreatureSystem | ResourceSystem | Creatures can drop resources |
| AutomationSystem | PowerGridSystem, ResourceSystem | Machines need power and produce/consume resources |
| BaseBuildingSystem | VoxelTerrain, PowerGridSystem, LifeSupportSystem | Buildings modify terrain, need power, provide life support |
| LoadBalancer | ServerMeshCoordinator | Needs coordinator to balance load |

## Signals

The coordinator emits signals to notify other systems of lifecycle events:

- **systems_initialized()**: Emitted after all systems finish initialization
- **system_error(system_name: String, error_message: String)**: Emitted if a system fails to initialize

## Public API

### System Access Methods

```gdscript
# Get individual systems
get_terrain_system() -> VoxelTerrain
get_resource_system() -> ResourceSystem
get_crafting_system() -> CraftingSystem
get_automation_system() -> AutomationSystem
get_creature_system() -> CreatureSystem
get_base_building_system() -> BaseBuildingSystem
get_life_support_system() -> LifeSupportSystem
get_power_grid_system() -> PowerGridSystem
get_solar_system_generator() -> SolarSystemGenerator
get_player_spawn_system() -> PlayerSpawnSystem
get_network_sync_system() -> NetworkSyncSystem
get_server_mesh_coordinator() -> ServerMeshCoordinator
get_load_balancer() -> LoadBalancer

# Get system by name (string-based lookup)
get_system(system_name: String) -> Node
```

### Multiplayer Control

```gdscript
# Enable multiplayer mode (initializes Phase 5 networking systems)
enable_multiplayer() -> void
```

### Persistence

```gdscript
# Save all system states
save_game() -> Dictionary

# Load all system states
load_game(save_data: Dictionary) -> bool

# Shutdown all systems (cleanup)
shutdown() -> void
```

## Testing

### Automated Tests

Test suite location: `tests/planetary_survival/test_coordinator_initialization.gd`

Run tests with GdUnit4:
```bash
# From Godot editor: Use GdUnit4 panel at bottom
# OR via command line:
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test tests/planetary_survival/test_coordinator_initialization.gd
```

### Test Coverage

The test suite verifies:

1. Coordinator autoload exists
2. Coordinator initializes successfully
3. All Phase 1 systems initialize (PowerGridSystem, SolarSystemGenerator)
4. All Phase 2 systems initialize (VoxelTerrain, ResourceSystem)
5. Phase 2 dependencies are correctly linked (ResourceSystem -> VoxelTerrain)
6. All Phase 3 systems initialize (CraftingSystem, LifeSupportSystem, CreatureSystem, PlayerSpawnSystem)
7. Phase 3 dependencies are correctly linked (CraftingSystem -> ResourceSystem, CreatureSystem -> ResourceSystem)
8. All Phase 4 systems initialize (AutomationSystem, BaseBuildingSystem)
9. Phase 4 dependencies are correctly linked (AutomationSystem -> PowerGridSystem/ResourceSystem, BaseBuildingSystem -> VoxelTerrain/PowerGridSystem/LifeSupportSystem)
10. Phase 5 networking systems are NOT initialized by default
11. All systems are added as children of coordinator
12. `get_system()` method works correctly
13. Signals exist
14. Save/load methods exist and work

## Integration with Existing Systems

The planetary survival coordinator runs alongside the SpaceTime engine systems:

### Existing Autoloads (from project.godot)
- `ResonanceEngine` - SpaceTime VR core engine
- `HttpApiServer` - HTTP API for external control
- `SceneLoadMonitor` - Scene loading monitoring
- `GodotBridge` - Debug connection bridge
- `TelemetryServer` - Telemetry streaming
- `SettingsManager` - Settings management
- **`PlanetarySurvivalCoordinator`** - Planetary survival game coordinator (NEW)

### Initialization Order

Godot initializes autoloads in the order they appear in `project.godot`. The coordinator initializes AFTER the core SpaceTime systems, allowing it to potentially integrate with them.

## Troubleshooting

### Coordinator Not Initializing

**Symptom:** Systems are null when accessed

**Causes:**
1. Autoload is commented out in `project.godot`
2. Script has parse errors preventing loading
3. Required class scripts are missing

**Solutions:**
1. Verify `PlanetarySurvivalCoordinator` line is uncommented in `project.godot`
2. Check Godot console for parse errors
3. Verify all system scripts exist in `scripts/planetary_survival/systems/`

### Dependency Errors

**Symptom:** System references are null even though the system exists

**Causes:**
1. Initialization order is wrong
2. Dependency injection not happening
3. System created but not added as child

**Solutions:**
1. Check phase order in `initialize_systems()`
2. Verify dependency injection lines in phase methods
3. Ensure `add_child()` is called for each system

### Multiplayer Systems Not Initializing

**Symptom:** NetworkSyncSystem, ServerMeshCoordinator, LoadBalancer are null

**Cause:** This is expected behavior - multiplayer is disabled by default

**Solution:** Call `enable_multiplayer()` to initialize Phase 5 networking systems

## Performance Considerations

- All systems are instantiated at game startup, adding ~100-200ms to load time
- Systems remain in memory for the entire session
- System initialization is synchronous and blocks the main thread
- For production, consider lazy initialization for optional systems

## Future Improvements

Potential enhancements to the coordinator:

1. **Async Initialization:** Use `await` to initialize systems asynchronously
2. **Lazy Loading:** Only initialize systems when first accessed
3. **Hot Reload:** Support reloading individual systems without restarting game
4. **Error Recovery:** Gracefully handle individual system initialization failures
5. **Progress Reporting:** Emit signals with initialization progress percentage
6. **Configuration:** Load initialization order from config file
7. **Module System:** Allow enabling/disabling entire phases via settings

## Related Documentation

- `scripts/planetary_survival/planetary_survival_coordinator.gd` - Source code
- `tests/planetary_survival/test_coordinator_initialization.gd` - Test suite
- `tests/planetary_survival/test_coordinator_initialization.tscn` - Test scene
- `CLAUDE.md` - Project overview and development workflow

## Version History

- **v1.0** (2025-12-02): Initial implementation with 5-phase initialization
  - 10 core systems (Phases 1-4)
  - 3 optional networking systems (Phase 5)
  - Comprehensive test coverage
  - Save/load functionality
