# Persistence System Usage Guide

## Quick Start

### Basic Setup

```gdscript
# Initialize persistence system
var persistence := PersistenceSystem.new()
persistence.set_voxel_terrain(voxel_terrain)
persistence.set_base_building_system(base_building)
persistence.set_creature_system(creature_system)
persistence.initialize(planet_seed)

# Get save system reference
var save_system := get_node("/root/SaveSystem")
```

### Saving a Game

```gdscript
# Simple save
save_system.save_game(0)  # Save to slot 0

# Save with custom name
save_system.save_game(1, "My Epic Base")

# Connect to save signals
save_system.save_started.connect(_on_save_started)
save_system.save_completed.connect(_on_save_completed)
save_system.save_progress.connect(_on_save_progress)

func _on_save_started(slot: int):
    print("Starting save to slot ", slot)
    # Show loading screen

func _on_save_progress(stage: String, progress: float):
    print("Saving ", stage, ": ", progress * 100, "%")
    # Update progress bar

func _on_save_completed(slot: int, success: bool):
    if success:
        print("Save completed successfully!")
    else:
        print("Save failed!")
    # Hide loading screen
```

### Loading a Game

```gdscript
# Check if save exists
if save_system.has_save(0):
    # Load game
    save_system.load_game(0)

# Get save metadata before loading
var metadata := save_system.get_save_metadata(0)
print("Save name: ", metadata.get("save_name", "Unknown"))
print("Play time: ", metadata.get("game_time", 0.0), " seconds")
print("Structures: ", metadata.get("structure_count", 0))

# Connect to load signals
save_system.load_started.connect(_on_load_started)
save_system.load_completed.connect(_on_load_completed)
```

### VR Save/Load Menu

```gdscript
# In your VR scene
var save_menu := VRSaveLoadMenu.new()
add_child(save_menu)

# Set controller references
save_menu.set_controllers(left_controller, right_controller)

# Connect signals
save_menu.save_requested.connect(_on_save_requested)
save_menu.load_requested.connect(_on_load_requested)
save_menu.menu_closed.connect(_on_menu_closed)

# Show save menu
func _on_save_button_pressed():
    save_menu.show_save_menu()

# Show load menu
func _on_load_button_pressed():
    save_menu.show_load_menu()

# Handle save request
func _on_save_requested(slot: int, save_name: String):
    save_system.save_game(slot, save_name)
    save_menu.hide_menu()

# Handle load request
func _on_load_requested(slot: int):
    save_system.load_game(slot)
    save_menu.hide_menu()
```

## Advanced Usage

### Manual Chunk Tracking

```gdscript
# Track terrain modifications manually
func excavate_custom_shape(position: Vector3, shape_data: Array):
    var chunk_pos := voxel_terrain.world_to_chunk(position)

    # Collect all voxel changes
    var changes: Array = []
    for voxel_data in shape_data:
        changes.append({
            "local_pos": voxel_data["local_pos"],
            "density": voxel_data["new_density"]
        })

    # Track in persistence system
    persistence.track_chunk_modification(chunk_pos, changes)
```

### Managing Multiple Bases

```gdscript
# Create bases at different locations
var main_base_id := persistence.create_base(Vector3(0, 0, 0), "Main Base")
var mining_base_id := persistence.create_base(Vector3(1000, 0, 1000), "Mining Outpost")
var research_base_id := persistence.create_base(Vector3(-500, 0, 500), "Research Station")

# Update base visited timestamp when player enters
func _on_player_entered_base(base_id: int):
    persistence.update_base_visited(base_id)

# Get all bases for UI display
var bases := persistence.get_all_bases()
for base in bases:
    print("Base: ", base.name, " at ", base.position)
    print("  Created: ", base.created_timestamp)
    print("  Last visited: ", base.last_visited_timestamp)
    print("  Structures: ", base.structure_ids.size())
```

### Structure Tracking

```gdscript
# Track structure placement from BaseBuildingSystem
func _on_module_placed(module: BaseModule):
    var properties := {
        "health": module.health,
        "max_health": module.max_health,
        "power_production": module.power_production,
        "oxygen_production": module.oxygen_production
    }

    var structure_id := persistence.track_structure_placement(
        BaseModule.ModuleType.keys()[module.module_type],
        module.global_position,
        module.quaternion,
        properties
    )

    # Store structure_id on module for later removal
    module.set_meta("persistence_id", structure_id)

# Track structure removal
func _on_module_removed(module: BaseModule):
    if module.has_meta("persistence_id"):
        var structure_id: int = module.get_meta("persistence_id")
        persistence.track_structure_removal(structure_id)
```

### Creature Tracking

```gdscript
# Track tamed creature
func _on_creature_tamed(creature: Creature):
    var creature_id := persistence.track_tamed_creature(
        creature.species,
        creature.global_position,
        creature.stats
    )

    creature.set_meta("persistence_id", creature_id)

# Update creature state periodically
func _on_save_creature_state(creature: Creature):
    if creature.has_meta("persistence_id"):
        var creature_id: int = creature.get_meta("persistence_id")
        persistence.update_creature_state(
            creature_id,
            creature.global_position,
            creature.stats
        )

# Remove creature when killed/released
func _on_creature_died(creature: Creature):
    if creature.has_meta("persistence_id"):
        var creature_id: int = creature.get_meta("persistence_id")
        persistence.remove_tamed_creature(creature_id)
```

### Compression Management

```gdscript
# Manual compression trigger
persistence.compress_old_chunks()

# Limit total tracked chunks
persistence.limit_chunk_modifications()

# Check if chunk is compressed
var delta := persistence.get_chunk_delta(chunk_pos)
if delta and delta.is_compressed:
    # Decompress before modifying
    delta.decompress()
    # Modify...
    delta.add_voxel_change(local_pos, new_density)
```

### Progressive Loading

```gdscript
# Load world in regions around player
func load_nearby_regions(player_position: Vector3):
    var player_region := _position_to_region(player_position)

    # Load 3x3x3 region grid around player
    for x in range(-1, 2):
        for y in range(-1, 2):
            for z in range(-1, 2):
                var region := player_region + Vector3i(x, y, z)
                load_region(region)

func load_region(region: Vector3i):
    # Load all chunks in region
    var region_size := 16  # 16x16x16 chunks per region
    for x in range(region.x * region_size, (region.x + 1) * region_size):
        for y in range(region.y * region_size, (region.y + 1) * region_size):
            for z in range(region.z * region_size, (region.z + 1) * region_size):
                var chunk_pos := Vector3i(x, y, z)

                # Check if chunk has modifications
                if persistence.has_chunk_modifications(chunk_pos):
                    var delta := persistence.get_chunk_delta(chunk_pos)
                    if delta.is_compressed:
                        delta.decompress()

                    # Apply delta to terrain
                    _apply_chunk_delta(chunk_pos, delta)
                else:
                    # Generate procedurally
                    _generate_procedural_chunk(chunk_pos)

func _position_to_region(position: Vector3) -> Vector3i:
    var chunk_size := 32
    var region_size := 16
    var chunk_pos := Vector3i(
        int(floor(position.x / chunk_size)),
        int(floor(position.y / chunk_size)),
        int(floor(position.z / chunk_size))
    )
    return Vector3i(
        int(floor(float(chunk_pos.x) / region_size)),
        int(floor(float(chunk_pos.y) / region_size)),
        int(floor(float(chunk_pos.z) / region_size))
    )
```

## Best Practices

### 1. Track Modifications Immediately

```gdscript
# Good: Track immediately after modification
func excavate_terrain(position: Vector3, radius: float):
    var changes := voxel_terrain.excavate_sphere(position, radius)
    persistence.track_chunk_modification(chunk_pos, changes)

# Bad: Track later or forget
func excavate_terrain(position: Vector3, radius: float):
    voxel_terrain.excavate_sphere(position, radius)
    # Oops, forgot to track!
```

### 2. Save Regularly

```gdscript
# Auto-save every 5 minutes
var auto_save_timer: float = 0.0
const AUTO_SAVE_INTERVAL: float = 300.0

func _process(delta: float):
    auto_save_timer += delta
    if auto_save_timer >= AUTO_SAVE_INTERVAL:
        auto_save_timer = 0.0
        save_system.save_game(0, "Auto Save")
```

### 3. Handle Save Failures

```gdscript
func save_with_retry(slot: int, max_retries: int = 3):
    for attempt in range(max_retries):
        if save_system.save_game(slot):
            print("Save successful on attempt ", attempt + 1)
            return true
        else:
            print("Save failed, retrying... (", attempt + 1, "/", max_retries, ")")
            await get_tree().create_timer(1.0).timeout

    push_error("Save failed after ", max_retries, " attempts!")
    return false
```

### 4. Validate Save Data

```gdscript
func load_with_validation(slot: int) -> bool:
    # Get metadata first
    var metadata := save_system.get_save_metadata(slot)

    if metadata.is_empty():
        push_error("Invalid save metadata")
        return false

    # Check version compatibility
    if metadata.get("version", 0) != PersistenceSystem.SAVE_VERSION:
        push_warning("Save version mismatch, may have issues")

    # Load
    return save_system.load_game(slot)
```

### 5. Show Progress Feedback

```gdscript
var progress_bar: ProgressBar

func _ready():
    save_system.save_progress.connect(_update_progress)
    save_system.load_progress.connect(_update_progress)

func _update_progress(stage: String, progress: float):
    progress_bar.value = progress
    progress_bar.get_node("Label").text = "Loading %s..." % stage
```

## Troubleshooting

### Save File Too Large

```gdscript
# Enable compression for all data
const COMPRESS_THRESHOLD := 512  # Lower threshold

# Or manually compress chunks
persistence.compress_old_chunks()
persistence.limit_chunk_modifications()
```

### Slow Load Times

```gdscript
# Use progressive loading
func load_game_progressive(slot: int):
    # Load basic data first
    var save_data := _read_save_file_header(slot)

    # Load world in chunks
    for region in _get_visible_regions():
        load_region(region)
        await get_tree().process_frame  # Yield to prevent freezing
```

### Corrupted Save Files

```gdscript
# Validate before loading
func validate_save_file(slot: int) -> bool:
    if not FileAccess.file_exists(_get_save_path(slot)):
        return false

    var file := FileAccess.open(_get_save_path(slot), FileAccess.READ)
    if not file:
        return false

    # Check header
    var compression_flag := file.get_8()
    var original_size := file.get_32()

    if compression_flag > 1 or original_size <= 0:
        return false

    return true
```

### Memory Leaks

```gdscript
# Always free loaded data when done
func switch_worlds():
    # Clear current world
    persistence.initialize(new_seed)
    voxel_terrain.clear_all_chunks()
    creature_system.clear_all_creatures()

    # Load new world
    load_game(slot)
```

## Performance Tips

1. **Batch Modifications**: Group multiple voxel changes into single `track_chunk_modification()` call
2. **Compress Old Data**: Run `compress_old_chunks()` periodically
3. **Limit Tracked Chunks**: Use `limit_chunk_modifications()` to prevent unbounded growth
4. **Progressive Loading**: Load world in regions, not all at once
5. **Async Operations**: Use `await` for long operations to prevent freezing

## API Reference

See `PERSISTENCE_IMPLEMENTATION_REPORT.md` for complete API documentation.

## Examples

See `examples/persistence/` directory for complete example scenes:
- `example_basic_save_load.tscn` - Basic save/load
- `example_vr_menu.tscn` - VR menu integration
- `example_progressive_loading.tscn` - Progressive world loading
- `example_multi_base.tscn` - Multiple base management

---

For more information, see:
- `PERSISTENCE_IMPLEMENTATION_REPORT.md` - Complete technical report
- `scripts/planetary_survival/systems/persistence_system.gd` - Source code
- `tests/planetary_survival/test_persistence_system.gd` - Test suite
