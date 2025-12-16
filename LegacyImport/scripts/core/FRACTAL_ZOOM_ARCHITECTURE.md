# Fractal Zoom System Architecture

## System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    ResonanceEngine                           │
│                  (Engine Coordinator)                        │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         FractalZoomSystem Subsystem                │    │
│  │                                                     │    │
│  │  • Golden Ratio Scale Calculations                 │    │
│  │  • Tween-based Smooth Transitions                  │    │
│  │  • Player & Environment Scaling                    │    │
│  │  • Lattice Density Updates                         │    │
│  │  • Signal-based Events                             │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  Helper Methods:                                             │
│  • set_fractal_zoom_player(player, environment)             │
│  • initiate_fractal_zoom(direction)                         │
│  • get_current_scale_level()                                │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ integrates with
                            ▼
        ┌───────────────────────────────────────┐
        │         Scene Components              │
        ├───────────────────────────────────────┤
        │  • Player Node (XRCamera3D)           │
        │  • Environment Root (Node3D)          │
        │  • Lattice Renderer (optional)        │
        └───────────────────────────────────────┘
```

## Zoom Transition Flow

```
User Input (Zoom In/Out)
         │
         ▼
┌─────────────────────┐
│  zoom(direction)    │
│  or                 │
│  zoom_to_level(n)   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────┐
│  Calculate Target Level     │
│  • Check bounds [-10, 10]   │
│  • Calculate scale factor   │
│  • φ^level                  │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  Emit zoom_started Signal   │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  Create Tween (2.0 sec)     │
│  • Player scale             │
│  • Environment scale        │
│  • Lattice density          │
└──────────┬──────────────────┘
           │
           ▼ (parallel animation)
┌─────────────────────────────┐
│  Animate Properties         │
│  • Cubic ease in-out        │
│  • Smooth interpolation     │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  Transition Complete        │
│  • Update current level     │
│  • Update scale factor      │
│  • Emit zoom_completed      │
└─────────────────────────────┘
```

## Scale Level Hierarchy

```
Level +10 ═══════════════════════════════════ Galactic Scale
          ║                                   (φ^10 ≈ 199.0)
Level +9  ╠═══════════════════════════════ Solar System Scale
Level +8  ║                                   (φ^8 ≈ 76.0)
          ║
Level +7  ╠═══════════════════════════════ Planetary Scale
Level +6  ║                                   (φ^6 ≈ 29.0)
          ║
Level +5  ╠═══════════════════════════════ Continental Scale
Level +4  ║                                   (φ^4 ≈ 11.1)
          ║
Level +3  ╠═══════════════════════════════ City Scale
Level +2  ║                                   (φ^2 ≈ 4.2)
          ║
Level +1  ╠═══════════════════════════════ Building Scale
          ║                                   (φ^1 ≈ 1.6)
          ║
Level  0  ╬═══════════════════════════════ HUMAN SCALE (DEFAULT)
          ║                                   (φ^0 = 1.0)
          ║
Level -1  ╠═══════════════════════════════ Millimeter Scale
          ║                                   (φ^-1 ≈ 0.618)
          ║
Level -2  ╠═══════════════════════════════ Microscopic Scale
Level -3  ║                                   (φ^-3 ≈ 0.236)
Level -4  ║
          ║
Level -5  ╠═══════════════════════════════ Molecular Scale
Level -6  ║                                   (φ^-6 ≈ 0.034)
Level -7  ║
          ║
Level -8  ╠═══════════════════════════════ Subatomic Scale
Level -9  ║                                   (φ^-9 ≈ 0.013)
Level -10 ═══════════════════════════════════ (φ^-10 ≈ 0.005)
```

## Golden Ratio Scaling Visualization

```
Each level is φ times the previous level:

Level -2: ●
          │
          │ × φ (1.618)
          ▼
Level -1: ●━━●
          │
          │ × φ (1.618)
          ▼
Level  0: ●━━━━━●
          │
          │ × φ (1.618)
          ▼
Level +1: ●━━━━━━━━━●
          │
          │ × φ (1.618)
          ▼
Level +2: ●━━━━━━━━━━━━━━●

This creates a self-similar fractal pattern
where each level maintains the same proportions.
```

## Component Interactions

```
┌──────────────────┐
│  Player Node     │
│  (XRCamera3D)    │
└────────┬─────────┘
         │ scale = original * φ^level
         │
         ▼
┌──────────────────┐         ┌──────────────────┐
│ FractalZoomSystem│◄───────►│ Environment Root │
│                  │         │  (Node3D)        │
└────────┬─────────┘         └──────────────────┘
         │                    scale = 1 / φ^level
         │
         │ set_grid_density()
         ▼
┌──────────────────┐
│ Lattice Renderer │
│                  │
└──────────────────┘
 density = base * φ^(-level)
```

## Signal Flow

```
User Action
    │
    ▼
┌─────────────────────┐
│ zoom() called       │
└──────────┬──────────┘
           │
           ▼
    zoom_started ────────────► Listeners
    (direction, target)        • UI updates
           │                   • Audio cues
           │                   • Visual effects
           ▼
    [Tween Animation]
    (2.0 seconds)
           │
           ▼
    zoom_completed ───────────► Listeners
    (new_scale)                • UI updates
                               • State saves
                               • Achievement checks
```

## Data Flow

```
Input: Zoom Direction (IN/OUT)
   │
   ▼
Calculate: target_level = current_level ± 1
   │
   ▼
Calculate: scale_factor = φ^target_level
   │
   ▼
Animate: {
   player.scale → original_scale * scale_factor
   environment.scale → Vector3.ONE / scale_factor
   lattice.density → base_density * φ^(-target_level)
}
   │
   ▼
Update: {
   current_scale_level = target_level
   current_scale_factor = scale_factor
}
   │
   ▼
Output: zoom_completed signal
```

## State Machine

```
┌─────────────┐
│ Initialized │
│ (level = 0) │
└──────┬──────┘
       │
       │ zoom() called
       ▼
┌─────────────┐
│  Zooming    │◄──────┐
│ (is_zooming │       │
│   = true)   │       │
└──────┬──────┘       │
       │              │
       │ tween        │ cancel_zoom()
       │ complete     │
       ▼              │
┌─────────────┐       │
│   Idle      │───────┘
│ (is_zooming │
│   = false)  │
└──────┬──────┘
       │
       │ zoom() called
       └──────► (repeat)
```

## Memory Layout

```
FractalZoomSystem Instance
├── Constants (compile-time)
│   ├── GOLDEN_RATIO: 1.618033988749
│   ├── ZOOM_DURATION: 2.0
│   ├── MIN_SCALE_LEVEL: -10
│   └── MAX_SCALE_LEVEL: 10
│
├── State Variables (~64 bytes)
│   ├── current_scale_level: int (4 bytes)
│   ├── current_scale_factor: float (4 bytes)
│   ├── _is_zooming: bool (1 byte)
│   └── _original_player_scale: Vector3 (12 bytes)
│
├── References (~32 bytes)
│   ├── player_node: Node3D* (8 bytes)
│   ├── lattice_renderer: Node* (8 bytes)
│   ├── _environment_root: Node3D* (8 bytes)
│   └── _zoom_tween: Tween* (8 bytes)
│
└── Total: ~128 bytes per instance
```

## Performance Profile

```
Operation              | Time Complexity | Space Complexity
-----------------------|-----------------|------------------
zoom()                 | O(1)            | O(1)
zoom_to_level()        | O(1)            | O(1)
_calculate_scale_factor| O(1)            | O(1)
Tween animation        | O(n) per frame  | O(1)
Signal emission        | O(m) listeners  | O(1)

Where:
  n = number of frames in transition (~180 at 90 FPS)
  m = number of connected signal listeners
```

## Integration Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Game Scene Tree                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  XROrigin3D                                              │
│  ├── XRCamera3D ◄──────────────┐                        │
│  │   └── [Player Components]   │ scale                  │
│  │                              │                        │
│  └── XRController3D (Left)      │                        │
│      └── XRController3D (Right) │                        │
│                                  │                        │
│  Environment                     │                        │
│  ├── Celestial Bodies ◄─────────┤ inverse scale         │
│  ├── Lattice Grid ◄─────────────┤ density update        │
│  └── [Other Objects]            │                        │
│                                  │                        │
│  ResonanceEngine (Autoload)     │                        │
│  └── FractalZoomSystem ─────────┘                        │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Conclusion

The Fractal Zoom System uses a clean, modular architecture that integrates seamlessly with the engine coordinator while maintaining independence from other systems. The Golden Ratio-based scaling creates mathematically harmonious transitions, and the Tween-based animation ensures smooth visual feedback. The system is performant, memory-efficient, and extensible for future enhancements.
