# MenuSystem Implementation Guide

## Overview

The MenuSystem manages all menu interfaces including main menu, settings, save/load, pause menu, and performance metrics display. It provides a centralized system for menu navigation and settings management.

## Requirements Validated

- **Requirement 38.1-38.5**: Save/load functionality with metadata display
- **Requirement 50.1-50.5**: Performance options and real-time metrics

## Architecture

### Menu States

```gdscript
enum MenuState {
    MAIN_MENU,      # Initial menu with New Game, Load, Settings, Quit
    SETTINGS,       # Graphics, audio, and control settings
    SAVE_LOAD,      # Save/load interface with slot metadata
    PAUSE,          # In-game pause menu
    PERFORMANCE     # Real-time performance metrics
}
```

### Key Components

1. **Main Menu**: Entry point with game start options
2. **Settings Menu**: Graphics quality presets and individual controls
3. **Save/Load Menu**: 10 save slots with metadata display
4. **Pause Menu**: In-game menu with save/resume options
5. **Performance Display**: Real-time FPS, frame time, memory usage

## Usage

### Basic Setup

```gdscript
# Add to scene
var menu_system = MenuSystem.new()
add_child(menu_system)

# Connect signals
menu_system.menu_action.connect(_on_menu_action)
menu_system.settings_changed.connect(_on_settings_changed)
menu_system.save_selected.connect(_on_save_selected)
menu_system.load_selected.connect(_on_load_selected)
```

### Handling Menu Actions

```gdscript
func _on_menu_action(action: String) -> void:
    match action:
        "new_game":
            start_new_game()
        "pause":
            handle_pause()
        "resume":
            handle_resume()
        "quit":
            cleanup_and_quit()
```

### Handling Settings Changes

```gdscript
func _on_settings_changed(setting_name: String, value: Variant) -> void:
    match setting_name:
        "lattice_density":
            lattice_renderer.set_grid_density(value)
        "lod_distance":
            lod_manager.set_lod_distances([value * 0.1, value, value * 10])
        "audio_volume":
            AudioServer.set_bus_volume_db(0, linear_to_db(value))
```

## Graphics Quality Presets

### Low

- Lattice Density: 5.0
- LOD Distance: 500.0
- Shadow Quality: 0 (disabled)

### Medium

- Lattice Density: 8.0
- LOD Distance: 1000.0
- Shadow Quality: 1 (low)

### High (Default)

- Lattice Density: 10.0
- LOD Distance: 2000.0
- Shadow Quality: 2 (medium)

### Ultra

- Lattice Density: 15.0
- LOD Distance: 5000.0
- Shadow Quality: 3 (high)

## Save/Load System

### Save File Format

```json
{
    "version": "1.0",
    "timestamp": 1234567890.0,
    "player_position": [x, y, z],
    "player_velocity": [x, y, z],
    "simulation_time": 12345.0,
    "signal_strength": 85.0,
    "entropy": 0.15
}
```

### Save Slots

- 10 save slots available
- Metadata displayed: position, simulation time, save date
- Empty slots clearly marked
- Automatic metadata refresh on menu open

## Performance Metrics

### Monitored Values

1. **FPS**: Frames per second (Engine.get_frames_per_second())
2. **Frame Time**: Process time in milliseconds
3. **Memory**: Static memory usage in MB
4. **GPU Usage**: (Future implementation)

### Display Toggle

```gdscript
# Toggle with F3 or custom key
if Input.is_action_just_pressed("toggle_performance"):
    menu_system.toggle_performance_display()
```

## Input Handling

### Pause/Resume

- ESC key toggles pause menu
- Pauses game tree when active
- Resumes on ESC or Resume button

### Navigation

- Mouse/keyboard for desktop
- VR controller support (future)
- Gamepad support (future)

## Settings Persistence

Settings are saved to `user://settings.cfg` using ConfigFile:

```ini
[graphics]
quality="High"

[audio]
volume=1.0
```

## Integration with Other Systems

### With Engine Coordinator

```gdscript
# In engine.gd
var menu_system: MenuSystem

func _ready():
    menu_system = get_node("/root/MenuSystem")
    menu_system.settings_changed.connect(_on_settings_changed)
```

### With Save System

```gdscript
func save_game(slot: int) -> void:
    var save_data = {
        "version": "1.0",
        "timestamp": Time.get_unix_time_from_system(),
        "player_position": spacecraft.global_position,
        "simulation_time": time_manager.current_time
    }

    var json_string = JSON.stringify(save_data)
    var file = FileAccess.open("user://save_%d.json" % slot, FileAccess.WRITE)
    file.store_string(json_string)
    file.close()
```

## Testing

Unit tests cover:

- Menu navigation and state transitions
- Settings save/load persistence
- Graphics preset application
- Save slot metadata loading
- Signal emissions
- Pause/resume functionality

## Future Enhancements

1. VR-specific menu interactions
2. Gamepad navigation
3. Localization support
4. Custom control remapping UI
5. Advanced graphics settings (ray tracing, DLSS)
6. Cloud save support
7. Achievement display
8. Statistics tracking

## Performance Considerations

- Performance display updates only when visible
- Save metadata loaded on-demand
- Settings applied immediately without restart
- Minimal overhead when menus hidden
