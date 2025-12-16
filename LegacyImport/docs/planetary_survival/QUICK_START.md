# Planetary Survival Coordinator - Quick Start Guide

## What is the PlanetarySurvivalCoordinator?

The `PlanetarySurvivalCoordinator` is the central hub for all planetary survival game systems. It's an autoload singleton that initializes and manages 13 different subsystems in the correct dependency order.

## Quick Access from Any Script

```gdscript
# Access the coordinator (available everywhere as autoload)
var coordinator = get_node("/root/PlanetarySurvivalCoordinator")

# Or use the autoload name directly (if referenced in your script)
var coordinator = PlanetarySurvivalCoordinator
```

## Get Any System

```gdscript
# Method 1: Direct getter methods (type-safe)
var terrain = PlanetarySurvivalCoordinator.get_terrain_system()
var resources = PlanetarySurvivalCoordinator.get_resource_system()
var crafting = PlanetarySurvivalCoordinator.get_crafting_system()
var automation = PlanetarySurvivalCoordinator.get_automation_system()

# Method 2: String-based lookup (dynamic)
var system = PlanetarySurvivalCoordinator.get_system("VoxelTerrain")
```

## Available Systems

| Getter Method | System Name | Purpose |
|---------------|-------------|---------|
| `get_terrain_system()` | VoxelTerrain | Voxel-based terrain |
| `get_resource_system()` | ResourceSystem | Resource gathering |
| `get_crafting_system()` | CraftingSystem | Crafting & recipes |
| `get_automation_system()` | AutomationSystem | Automated production |
| `get_creature_system()` | CreatureSystem | Wildlife & farming |
| `get_base_building_system()` | BaseBuildingSystem | Base construction |
| `get_life_support_system()` | LifeSupportSystem | Oxygen & environment |
| `get_power_grid_system()` | PowerGridSystem | Power management |
| `get_solar_system_generator()` | SolarSystemGenerator | Procedural planets |
| `get_player_spawn_system()` | PlayerSpawnSystem | Spawn management |

## Example Usage

### Example 1: Mining Resources

```gdscript
extends Node3D

func mine_resource_at_position(pos: Vector3) -> void:
    var resource_system = PlanetarySurvivalCoordinator.get_resource_system()
    var terrain = PlanetarySurvivalCoordinator.get_terrain_system()

    # Destroy voxel
    terrain.destroy_voxel(pos)

    # Collect resource
    var resource = resource_system.collect_resource_at(pos)
    if resource:
        print("Collected: ", resource.resource_type, " x", resource.amount)
```

### Example 2: Crafting an Item

```gdscript
extends Node

func craft_item(recipe_id: String) -> void:
    var crafting_system = PlanetarySurvivalCoordinator.get_crafting_system()

    if crafting_system.can_craft(recipe_id):
        var item = crafting_system.craft(recipe_id)
        print("Crafted: ", item.name)
    else:
        print("Insufficient resources")
```

### Example 3: Building a Base Module

```gdscript
extends Node3D

func place_module(module_type: String, position: Vector3) -> void:
    var base_building = PlanetarySurvivalCoordinator.get_base_building_system()
    var power_grid = PlanetarySurvivalCoordinator.get_power_grid_system()

    # Place the module
    var module = base_building.place_module(module_type, position)

    # Connect to power grid
    if module and module.needs_power:
        power_grid.connect_module(module)
```

### Example 4: Wait for Systems to Initialize

```gdscript
extends Node

func _ready() -> void:
    # If you need to wait for systems to finish initializing
    if not PlanetarySurvivalCoordinator.is_initialized:
        await PlanetarySurvivalCoordinator.systems_initialized

    # Now all systems are ready
    setup_gameplay()

func setup_gameplay() -> void:
    var terrain = PlanetarySurvivalCoordinator.get_terrain_system()
    var spawner = PlanetarySurvivalCoordinator.get_player_spawn_system()

    # Setup game...
```

### Example 5: Enable Multiplayer

```gdscript
extends Node

func start_multiplayer_server() -> void:
    # Enable networking systems
    PlanetarySurvivalCoordinator.enable_multiplayer()

    # Now networking systems are available
    var network = PlanetarySurvivalCoordinator.get_network_sync_system()
    var server_mesh = PlanetarySurvivalCoordinator.get_server_mesh_coordinator()
    var load_balancer = PlanetarySurvivalCoordinator.get_load_balancer()

    # Configure multiplayer...
```

## Signals

Listen to coordinator lifecycle events:

```gdscript
func _ready() -> void:
    PlanetarySurvivalCoordinator.systems_initialized.connect(_on_systems_ready)
    PlanetarySurvivalCoordinator.system_error.connect(_on_system_error)

func _on_systems_ready() -> void:
    print("All systems initialized successfully!")

func _on_system_error(system_name: String, error_message: String) -> void:
    print("System error in ", system_name, ": ", error_message)
```

## Save/Load Game State

```gdscript
# Save all system states
func save_game() -> void:
    var save_data = PlanetarySurvivalCoordinator.save_game()

    # Write to file
    var file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
    file.store_var(save_data)
    file.close()

# Load all system states
func load_game() -> void:
    var file = FileAccess.open("user://savegame.dat", FileAccess.READ)
    var save_data = file.get_var()
    file.close()

    var success = PlanetarySurvivalCoordinator.load_game(save_data)
    if success:
        print("Game loaded successfully")
```

## Common Patterns

### Pattern 1: System Integration

When creating a new script that needs multiple systems:

```gdscript
extends Node

# Cache system references
var terrain: VoxelTerrain
var resources: ResourceSystem
var crafting: CraftingSystem

func _ready() -> void:
    # Cache references in _ready
    terrain = PlanetarySurvivalCoordinator.get_terrain_system()
    resources = PlanetarySurvivalCoordinator.get_resource_system()
    crafting = PlanetarySurvivalCoordinator.get_crafting_system()

    # Use cached references throughout your script
    setup_gameplay()
```

### Pattern 2: Dependency Checking

Always check if systems exist before using them:

```gdscript
func use_automation() -> void:
    var automation = PlanetarySurvivalCoordinator.get_automation_system()

    if automation:
        automation.start_production_chain()
    else:
        push_error("AutomationSystem not initialized")
```

### Pattern 3: Networking Systems (Optional)

Networking systems are only available if multiplayer is enabled:

```gdscript
func setup_multiplayer() -> void:
    # Networking systems are null by default
    var network = PlanetarySurvivalCoordinator.get_network_sync_system()

    if not network:
        # Enable multiplayer first
        PlanetarySurvivalCoordinator.enable_multiplayer()
        await get_tree().process_frame  # Wait one frame
        network = PlanetarySurvivalCoordinator.get_network_sync_system()

    # Now network is available
    network.start_server()
```

## Testing

Run the initialization test:

```bash
# From Godot editor: Open GdUnit4 panel at bottom
# Select: tests/planetary_survival/test_coordinator_initialization.gd
# Click "Run Test"

# OR via command line:
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test tests/planetary_survival/test_coordinator_initialization.gd
```

## Troubleshooting

### "PlanetarySurvivalCoordinator not found"

**Cause:** Autoload is disabled in `project.godot`

**Fix:** Ensure this line is uncommented in `project.godot`:
```ini
PlanetarySurvivalCoordinator="*res://scripts/planetary_survival/planetary_survival_coordinator.gd"
```

### System is null when accessed

**Cause 1:** Accessing system before it initializes

**Fix:** Wait for initialization:
```gdscript
await PlanetarySurvivalCoordinator.systems_initialized
```

**Cause 2:** System has parse errors

**Fix:** Check Godot console for script errors

### Networking systems are null

**Cause:** Multiplayer is disabled by default

**Fix:** Call `enable_multiplayer()` first

## Performance Tips

1. **Cache System References:** Get systems once in `_ready()`, store in variables
2. **Avoid Frequent Lookups:** Don't call `get_system()` every frame
3. **Lazy Initialize:** Only enable multiplayer when actually needed

## See Also

- Full documentation: `docs/planetary_survival/COORDINATOR_INITIALIZATION.md`
- Test suite: `tests/planetary_survival/test_coordinator_initialization.gd`
- Source code: `scripts/planetary_survival/planetary_survival_coordinator.gd`
