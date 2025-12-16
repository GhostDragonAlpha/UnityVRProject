# Stationary Mode Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      VR COMFORT SYSTEM                          │
│                  (Motion Sickness Prevention)                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Stationary Mode Integration
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  FLOATING ORIGIN SYSTEM                         │
│                  (Coordinate Rebasing)                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Rebase All Objects
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     UNIVERSE OBJECTS                            │
│           (Stars, Planets, Asteroids, etc.)                     │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow: Normal Mode vs Stationary Mode

### Normal Mode (Motion Sickness Risk)

```
Player Input (Thrust)
    │
    ▼
Spacecraft RigidBody3D
    │
    ▼
Apply Force → Linear Velocity Changes
    │
    ▼
Position Updates (Player Moves)
    │
    ▼
VR Headset Sees Movement ───┐
Inner Ear Feels No Movement ─┤→ SENSORY MISMATCH → Motion Sickness
```

### Stationary Mode (Motion Sickness Prevention)

```
Player Input (Thrust)
    │
    ▼
Spacecraft RigidBody3D
    │
    ▼
Apply Force → Linear Velocity Changes
    │
    ▼
Position Updates (Player WOULD Move)
    │
    ▼
_physics_process() Detects Movement
    │
    ▼
Calculate movement_delta
    │
    ▼
FloatingOriginSystem.rebase_coordinates(movement_delta)
    │
    ├─→ Move ALL Universe Objects by -movement_delta
    │
    └─→ Snap Player Back to Locked Position
    │
    ▼
Result: Player Stays Still, Universe Moves
    │
    ▼
VR Headset Sees Movement ───┐
Inner Ear Feels No Movement ─┤→ SENSES MATCH → No Motion Sickness
```

## Component Interaction Diagram

```
┌──────────────────────┐
│   VRComfortSystem    │
│   ┌──────────────┐   │
│   │ Stationary   │   │
│   │ Mode State   │   │
│   │              │   │
│   │ • _active    │   │
│   │ • _position  │   │
│   │ • _velocity  │   │
│   └──────────────┘   │
└──────────┬───────────┘
           │
           │ References
           │
           ▼
┌──────────────────────┐        ┌──────────────────────┐
│ FloatingOriginSystem │◄───────│    Spacecraft        │
│                      │        │   (RigidBody3D)      │
│ • rebase_coords()    │        │                      │
│ • global_offset      │        │ • global_position    │
│ • registered_objects │        │ • linear_velocity    │
└──────────┬───────────┘        └──────────────────────┘
           │                              ▲
           │ Moves                        │ Locks
           │ Inversely                    │ Position
           ▼                              │
┌──────────────────────┐                 │
│  Universe Objects    │                 │
│                      │◄────────────────┘
│ • Stars              │    Every Physics Frame
│ • Planets            │
│ • Asteroids          │
│ • All Node3D objects │
└──────────────────────┘
```

## Execution Timeline (Single Physics Frame)

```
Time │ Event
─────┼──────────────────────────────────────────────────────────
  0  │ _physics_process(delta) called
     │
  1  │ Check: Is stationary mode active? → Yes
     │
  2  │ Check: Is spacecraft valid? → Yes
     │
  3  │ Call _update_stationary_mode(delta)
     │
  4  │ Get current player position: (10, 0, 0)
     │ Get locked position: (0, 0, 0)
     │
  5  │ Calculate movement_delta: (10, 0, 0) - (0, 0, 0) = (10, 0, 0)
     │
  6  │ Check: movement_delta.length() > 0.001? → Yes (10.0 > 0.001)
     │
  7  │ Call floating_origin_system.rebase_coordinates((10, 0, 0))
     │
  8  │ FloatingOriginSystem rebases all objects:
     │   • Star at (1000, 0, 0) → (990, 0, 0)
     │   • Planet at (500, 0, 0) → (490, 0, 0)
     │   • Asteroid at (200, 0, 0) → (190, 0, 0)
     │   • All objects move by (-10, 0, 0)
     │
  9  │ Snap player back: player.global_position = (0, 0, 0)
     │
 10  │ Result:
     │   • Player position: (0, 0, 0) [UNCHANGED]
     │   • Universe moved: -10 units
     │   • Visual appearance: Player moved +10 units
     │   • VR headset: No physical movement
     │
 11  │ Physics velocities preserved automatically
     │ (FloatingOriginSystem handles this)
     │
 12  │ Frame complete
```

## Code Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ initialize(vr_manager, spacecraft)                          │
├─────────────────────────────────────────────────────────────┤
│ 1. Get SettingsManager                                      │
│ 2. Get ResonanceEngine                                      │
│ 3. Get FloatingOriginSystem from ResonanceEngine            │
│ 4. Set up vignetting                                        │
│ 5. Emit comfort_system_initialized                          │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Every Frame
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ _process(delta)                                             │
├─────────────────────────────────────────────────────────────┤
│ • Update snap turn cooldown                                 │
│ • Process snap-turn input                                   │
│ • Update vignetting based on acceleration                   │
│ • Smooth vignette transitions                               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ _physics_process(delta)                                     │
├─────────────────────────────────────────────────────────────┤
│ if stationary_mode_active:                                  │
│     _update_stationary_mode(delta)                          │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ _update_stationary_mode(delta)                              │
├─────────────────────────────────────────────────────────────┤
│ 1. Get current player position                              │
│ 2. Calculate movement_delta                                 │
│ 3. If movement detected:                                    │
│    a) Call floating_origin_system.rebase_coordinates()      │
│    b) Move universe inversely                               │
│    c) Snap player back to locked position                   │
│    d) Preserve physics velocities                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ set_stationary_mode(enabled)                                │
├─────────────────────────────────────────────────────────────┤
│ if enabled:                                                 │
│     • Store player's current position as locked position    │
│     • Store player's current velocity                       │
│     • Verify FloatingOriginSystem available                 │
│     • Emit signal                                           │
│ else:                                                       │
│     • Clear locked position                                 │
│     • Clear stored velocity                                 │
│     • Emit signal                                           │
└─────────────────────────────────────────────────────────────┘
```

## State Machine

```
┌─────────────┐
│   DISABLED  │◄──────────────┐
└──────┬──────┘               │
       │                      │
       │ set_stationary_      │ set_stationary_
       │ mode(true)           │ mode(false)
       │                      │
       ▼                      │
┌─────────────┐               │
│   ENABLED   ├───────────────┘
│             │
│ State:      │
│ • _active   │──────────────────┐
│ • _position │                  │
│ • _velocity │                  │
└──────┬──────┘                  │
       │                         │
       │ Every                   │
       │ Physics                 │
       │ Frame                   │
       │                         │
       ▼                         │
┌─────────────┐                  │
│  UPDATING   │                  │
│             │                  │
│ Actions:    │                  │
│ 1. Detect   │◄─────────────────┘
│    movement │
│ 2. Rebase   │
│    universe │
│ 3. Lock     │
│    player   │
└─────────────┘
```

## Integration Dependencies

```
VRComfortSystem Dependencies:
├── VRManager (required)
│   ├── xr_camera
│   └── get_controller_state()
│
├── SettingsManager (optional, but recommended)
│   ├── get_setting()
│   ├── set_setting()
│   └── setting_changed signal
│
├── FloatingOriginSystem (required for stationary mode)
│   ├── rebase_coordinates()
│   ├── global_offset
│   └── registered_objects
│
└── Spacecraft (required)
    ├── RigidBody3D type
    ├── global_position
    ├── linear_velocity
    └── get_linear_velocity()

FloatingOriginSystem Dependencies:
├── player_node (Node3D)
├── registered_objects (Array[Node3D])
├── registered_physics_bodies (Array[RigidBody3D])
└── PhysicsServer3D (Godot built-in)
```

## Error Handling

```
┌────────────────────────────────┐
│ Potential Error Conditions     │
├────────────────────────────────┤
│                                │
│ 1. FloatingOriginSystem = null │
│    → Warning logged            │
│    → Stationary mode limited   │
│    → Continue without crashing │
│                                │
│ 2. Spacecraft not RigidBody3D  │
│    → Type check fails          │
│    → Skip stationary update    │
│    → Continue normal operation │
│                                │
│ 3. Movement < 0.001 threshold  │
│    → Skip rebasing             │
│    → Prevent micro-jitter      │
│    → Save performance          │
│                                │
│ 4. ResonanceEngine not found   │
│    → Warning logged            │
│    → FloatingOriginSystem null │
│    → Graceful degradation      │
│                                │
└────────────────────────────────┘
```

## Performance Considerations

```
Performance Impact per Frame:
├── Position Check: O(1) - Single vector access
├── Delta Calculation: O(1) - Vector subtraction
├── Length Check: O(1) - Vector magnitude
├── Rebase Call: O(n) - Where n = registered objects
└── Position Snap: O(1) - Single vector assignment

Optimization Strategy:
├── 0.001 threshold prevents micro-rebasing
├── Early return if not active
├── Type check cached (RigidBody3D is)
└── FloatingOriginSystem optimized separately

Expected FPS Impact:
├── < 100 objects: Negligible (<0.1ms)
├── 100-1000 objects: Minimal (~0.5ms)
├── > 1000 objects: Monitor (~2ms)
└── VR Target: Maintain 90 FPS
```

## Testing Scenarios

```
Test 1: Enable/Disable Toggle
├── Enable stationary mode
├── Check _active flag = true
├── Check _position stored
├── Disable stationary mode
└── Check _active flag = false

Test 2: Position Locking
├── Enable stationary mode at (0,0,0)
├── Apply thrust for 5 seconds
├── Check player still at (0,0,0)
└── Check universe objects moved

Test 3: Universe Movement
├── Enable stationary mode
├── Note initial star positions
├── Move player 100 units
├── Check stars moved -100 units
└── Verify inverse relationship

Test 4: Physics Preservation
├── Enable stationary mode
├── Apply constant thrust
├── Check velocity still accumulates
├── Disable stationary mode
└── Check player starts moving

Test 5: VR Motion Sickness
├── Enable stationary mode
├── Move rapidly in all directions
├── Check VR headset position unchanged
└── User comfort survey (no nausea)
```

---

**Files:**
- Implementation: `C:/godot/scripts/core/vr_comfort_system.gd`
- Integration: `C:/godot/scripts/core/floating_origin.gd`
- Documentation: `C:/godot/STATIONARY_MODE_SOLUTION.md`
- Changes: `C:/godot/scripts/core/APPLY_STATIONARY_MODE_CHANGES.txt`
- Patch: `C:/godot/scripts/core/vr_comfort_system_STATIONARY_MODE_PATCH.gd`
