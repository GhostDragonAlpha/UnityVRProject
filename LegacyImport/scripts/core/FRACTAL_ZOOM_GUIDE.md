# Fractal Zoom System Guide

## Overview

The Fractal Zoom System enables scale-invariant navigation through the universe, allowing players to zoom between atomic and galactic scales while maintaining geometric patterns. The system uses the Golden Ratio (φ ≈ 1.618) as the scale factor between levels, creating a mathematically harmonious fractal structure.

## Requirements Implemented

- **26.1**: Scale player size relative to environment
- **26.2**: Reveal nested lattice structures at smaller scales
- **26.3**: Apply Golden Ratio scale factors between levels
- **26.4**: Maintain geometric patterns across scales
- **26.5**: Complete zoom transitions smoothly using Tween (2 second duration)

## Architecture

### Core Components

1. **FractalZoomSystem** (`scripts/core/fractal_zoom_system.gd`)

   - Manages scale transitions
   - Calculates Golden Ratio scale factors
   - Animates smooth transitions using Tween
   - Updates lattice density to reveal nested structures

2. **Engine Integration** (`scripts/core/engine.gd`)
   - Initializes FractalZoomSystem as a subsystem
   - Provides helper methods for zoom control
   - Manages lifecycle (initialization, update, shutdown)

## Scale Levels

The system supports 21 discrete scale levels from -10 to +10:

| Level     | Scale Factor | Description           |
| --------- | ------------ | --------------------- |
| -10 to -8 | ~0.00001     | Subatomic Scale       |
| -7 to -5  | ~0.0001      | Molecular Scale       |
| -4 to -2  | ~0.01        | Microscopic Scale     |
| -1        | ~0.618       | Millimeter Scale      |
| 0         | 1.0          | Human Scale (default) |
| 1         | ~1.618       | Building Scale        |
| 2 to 3    | ~4.236       | City Scale            |
| 4 to 5    | ~11.09       | Continental Scale     |
| 6 to 7    | ~29.03       | Planetary Scale       |
| 8 to 9    | ~76.01       | Solar System Scale    |
| 10        | ~199.0       | Galactic Scale        |

### Scale Factor Formula

```gdscript
scale_factor = φ^level
```

Where φ (phi) = 1.618033988749 (Golden Ratio)

## Usage

### Initialization

```gdscript
# In your game initialization code
var fractal_zoom = ResonanceEngine.fractal_zoom

# Set the player node and optional environment root
ResonanceEngine.set_fractal_zoom_player(player_node, environment_root)
```

### Zooming

```gdscript
# Zoom in (to smaller scales)
fractal_zoom.zoom(FractalZoomSystem.ZoomDirection.IN)

# Zoom out (to larger scales)
fractal_zoom.zoom(FractalZoomSystem.ZoomDirection.OUT)

# Zoom to a specific level
fractal_zoom.zoom_to_level(5)  # Zoom to continental scale

# Reset to human scale
fractal_zoom.reset_to_human_scale()
```

### Querying State

```gdscript
# Get current scale level
var level = fractal_zoom.get_current_scale_level()

# Get current scale factor
var factor = fractal_zoom.get_current_scale_factor()

# Check if zooming
if fractal_zoom.is_zooming():
    print("Zoom in progress...")

# Get scale description for UI
var description = fractal_zoom.get_scale_description()
# Returns: "Human Scale", "Planetary Scale", etc.

# Get relative size description
var size = fractal_zoom.get_relative_size_description()
# Returns: "Normal size", "Giant", "Microscopic", etc.
```

### Signals

```gdscript
# Connect to zoom events
fractal_zoom.zoom_started.connect(_on_zoom_started)
fractal_zoom.zoom_completed.connect(_on_zoom_completed)
fractal_zoom.zoom_cancelled.connect(_on_zoom_cancelled)

func _on_zoom_started(direction: ZoomDirection, target_scale: float):
    print("Zooming to scale: ", target_scale)

func _on_zoom_completed(new_scale: float):
    print("Zoom complete at scale: ", new_scale)

func _on_zoom_cancelled():
    print("Zoom was cancelled")
```

## How It Works

### 1. Player Scaling

When zooming, the player node's scale is adjusted relative to the environment:

```gdscript
player.scale = original_scale * scale_factor
```

### 2. Environment Inverse Scaling

If an environment root is provided, it's scaled inversely to maintain relative sizes:

```gdscript
environment.scale = Vector3.ONE / scale_factor
```

This creates the illusion that the player is changing size while the world remains constant.

### 3. Lattice Density Updates

The lattice grid density is updated to reveal nested structures:

```gdscript
lattice_density = base_density * φ^(-level)
```

- Zooming in (negative levels) increases density, revealing finer detail
- Zooming out (positive levels) decreases density, showing larger patterns

### 4. Smooth Transitions

All changes are animated using Godot's Tween system:

- Duration: 2.0 seconds
- Easing: Cubic in-out
- Parallel tweening of player scale, environment scale, and lattice density

## Integration with Other Systems

### Lattice Renderer

The fractal zoom system automatically finds and updates the LatticeRenderer to adjust grid density during zoom transitions. This reveals nested lattice structures at different scales.

### Floating Origin System

The fractal zoom system works seamlessly with the floating origin system. Coordinate rebasing continues to function correctly at all scale levels.

### VR Integration

The system works in both VR and desktop modes. In VR, the player's XRCamera3D is scaled, maintaining proper stereoscopic rendering.

## Testing

### Manual Testing

Run the test scene:

```bash
godot --path "C:/path/to/SpaceTime" tests/test_fractal_zoom.tscn
```

Controls:

- **Q**: Zoom in (smaller scale)
- **E**: Zoom out (larger scale)
- **R**: Reset to human scale
- **ESC**: Quit

### Automated Testing

Unit tests can verify:

- Scale factor calculation accuracy
- Golden Ratio application
- Transition completion
- Bounds checking (min/max levels)

## Performance Considerations

### Optimization

1. **Tween Reuse**: Only one tween is active at a time
2. **Lazy Lattice Lookup**: Lattice renderer is found once during initialization
3. **Parallel Tweening**: All properties animate simultaneously for efficiency

### Memory Usage

- Minimal memory footprint (~1KB per instance)
- No texture or mesh allocations
- Tween is created/destroyed as needed

## Future Enhancements

Potential improvements for future phases:

1. **Fractal Geometry Generation**: Generate different geometry at each scale level
2. **Scale-Specific Physics**: Adjust physics parameters based on scale
3. **Quantum Effects**: Add quantum uncertainty at subatomic scales
4. **Relativistic Effects**: Integrate with relativity system at cosmic scales
5. **Audio Scaling**: Pitch-shift audio based on scale level

## Troubleshooting

### Zoom Not Working

- Ensure player node is set via `initialize()` or `set_fractal_zoom_player()`
- Check that zoom is not already in progress
- Verify scale level is within bounds [-10, 10]

### Lattice Not Updating

- Verify LatticeRenderer exists in scene tree
- Check that LatticeRenderer has `set_grid_density()` method
- Ensure LatticeRenderer is properly initialized

### Jerky Transitions

- Check frame rate is stable (90 FPS target)
- Verify no other systems are blocking the main thread
- Ensure Tween is using appropriate easing function

## API Reference

### Methods

- `initialize(player: Node3D, environment: Node3D = null) -> bool`
- `zoom(direction: ZoomDirection) -> bool`
- `zoom_to_level(target_level: int) -> bool`
- `cancel_zoom() -> void`
- `reset_to_human_scale() -> bool`
- `get_current_scale_level() -> int`
- `get_current_scale_factor() -> float`
- `is_zooming() -> bool`
- `get_scale_description() -> String`
- `get_relative_size_description() -> String`
- `shutdown() -> void`

### Signals

- `zoom_started(direction: ZoomDirection, target_scale: float)`
- `zoom_completed(new_scale: float)`
- `zoom_cancelled()`

### Constants

- `GOLDEN_RATIO = 1.618033988749`
- `ZOOM_DURATION = 2.0` (seconds)
- `MIN_SCALE_LEVEL = -10`
- `MAX_SCALE_LEVEL = 10`

### Enums

```gdscript
enum ZoomDirection {
    IN,   # Zoom to smaller scales
    OUT   # Zoom to larger scales
}
```

## Mathematical Background

### The Golden Ratio

The Golden Ratio (φ) is chosen as the scale factor because:

1. **Self-Similarity**: φ appears naturally in fractal patterns
2. **Aesthetic Harmony**: Creates visually pleasing proportions
3. **Mathematical Properties**: φ² = φ + 1, creating recursive relationships
4. **Natural Occurrence**: Found in spiral galaxies, atomic structures, and biological forms

### Scale Invariance

The system maintains scale invariance by ensuring that geometric patterns repeat at each level. This is achieved through:

1. **Consistent Scaling**: Using φ as the constant ratio between levels
2. **Lattice Density Adjustment**: Revealing finer or coarser grid patterns
3. **Smooth Transitions**: Preventing visual discontinuities

## Conclusion

The Fractal Zoom System provides a mathematically elegant solution for navigating between vastly different scales in the universe. By leveraging the Golden Ratio and smooth Tween animations, it creates an immersive experience that reveals the fractal nature of spacetime itself.
