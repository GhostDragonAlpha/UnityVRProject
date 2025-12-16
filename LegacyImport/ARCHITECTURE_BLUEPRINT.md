# SpaceTime VR - Complete Architecture Blueprint
**Created:** 2025-12-09
**Status:** MASTER ARCHITECTURE SPECIFICATION
**Purpose:** Complete technical architecture to build a galaxy-scale VR MMO correctly the FIRST time

---

## Executive Summary

**Vision:** A galaxy-scale VR space simulation with real physics, supporting thousands of players through distributed mesh networking and smart instancing.

**Core Philosophy:** Real physics foundation, layer everything else on top.

**First Milestone:** Walk on a planet → board a spaceship → fly to another planet → land successfully.

**Headset:** BigScreen Beyond (OpenXR via SteamVR)
**Target:** RTX 3070+ GPU, 90 FPS in VR
**Timeline:** Build it right, no deadline pressure

---

## Part 1: Technology Stack

### 1.1 Core Engine
- **Engine:** Godot 4.5.1-stable ✅
- **Language:** GDScript (primary), C# (optional for performance-critical)
- **VR Runtime:** OpenXR via SteamVR ✅
- **Rendering:** Forward+ with MSAA 2x ✅
- **Physics Tick:** 90 Hz (matches VR refresh rate) ✅

### 1.2 Physics Architecture (CRITICAL DECISION)

**Hybrid Physics Model:**

```
┌─────────────────────────────────────────────┐
│         PHYSICS ARCHITECTURE                │
├─────────────────────────────────────────────┤
│                                             │
│  VR/Local Physics (Godot Built-in)         │
│  ├─ Player walking/standing                │
│  ├─ VR controller interactions             │
│  ├─ Object grabbing/throwing               │
│  ├─ Ship interior physics                  │
│  └─ Collision detection                    │
│                                             │
│  Orbital Mechanics (Custom GDScript)       │
│  ├─ N-body gravity simulation              │
│  ├─ Orbital trajectories                   │
│  ├─ Gravitational assists                  │
│  ├─ Lagrange points                        │
│  └─ Relativistic effects (future)          │
│                                             │
│  Flight Physics (Custom + Godot)           │
│  ├─ Thrust vectoring (6DOF)                │
│  ├─ Rotational dynamics                    │
│  ├─ Atmospheric drag (on planets)          │
│  └─ Stabilization systems                  │
│                                             │
└─────────────────────────────────────────────┘
```

**Why Hybrid:**
- ✅ Godot physics excellent for VR interactions
- ✅ Custom orbital mechanics for realism
- ✅ No external physics engine (Jolt unnecessary)
- ✅ Clean separation of concerns

### 1.3 Coordinate System (Floating Origin)

**Problem:** Float precision breaks at astronomical distances
**Solution:** Player always at origin, universe shifts

```gdscript
# FloatingOriginSystem (autoload)
extends Node
class_name FloatingOriginSystem

const SHIFT_THRESHOLD := 10000.0  # 10km - shift when exceeded

var origin_offset := Vector3.ZERO  # Total universe offset
var tracked_objects: Array[Node3D] = []

func _physics_process(_delta: float) -> void:
    var player_pos := get_player_position()

    if player_pos.length() > SHIFT_THRESHOLD:
        shift_universe(-player_pos)

func shift_universe(offset: Vector3) -> void:
    origin_offset += offset

    # Move all spatial objects
    for obj in tracked_objects:
        if is_instance_valid(obj):
            obj.global_position += offset

    # Update celestial body positions (database-driven)
    update_celestial_positions(offset)
```

**All spatial objects MUST register with FloatingOriginSystem.**

### 1.4 Terrain System

**Dual Terrain Architecture:**

**Type A: Voxel Terrain (Interactive Planets)**
- Addon: Try both `Terrain3D` and `godot_voxel`, pick best performer
- Use for: Rocky planets, moons (can mine/dig)
- Features: Deformable, collision, LOD
- Performance: Aggressive LOD (90 FPS requirement)

**Type B: Pre-made Terrain (Decorative)**
- Standard Godot meshes with LOD
- Use for: Gas giants, stars, black holes, asteroids
- Features: Visual only, no interaction
- Performance: Instanced rendering, GPU occlusion

### 1.5 Essential Addons

**Required:**
1. ✅ `godottpd` - HTTP server (already installed)
2. ✅ `gdUnit4` - Testing framework (already installed)
3. ➕ `godot-xr-tools` - VR interactions (INSTALL THIS)

**Optional/Test:**
4. ⚠️ `Terrain3D` OR `godot_voxel` - Voxel terrain (test both)
5. ⚠️ `godot_rl_agents` - AI training (Phase 3+)

**DO NOT INSTALL:**
- ❌ Jolt Physics (unnecessary)
- ❌ Custom physics engines
- ❌ Python-based systems for runtime

---

## Part 2: Multiplayer Architecture

### 2.1 Hybrid Scalable Networking

**Layer 1: Persistent Universe (Database)**
```
PostgreSQL or SQLite + Networking
├─ Player positions (all players, updated every 5-30s)
├─ Ship inventory/stats
├─ Faction standings
├─ Base locations
└─ Market data

Handles: Thousands of players
Cost: $20-50/month
```

**Layer 2: Dynamic Instancing**

```
Player Count │ Mode          │ Authority      │ Cost
─────────────┼───────────────┼────────────────┼──────────
1-4          │ Solo/P2P      │ Player host    │ FREE
5-16         │ P2P Mesh      │ Distributed    │ FREE
17-50        │ P2P Host      │ Strongest PC   │ FREE
51-150       │ Dedicated     │ Cloud server   │ $0.50-2/hr
151-1000+    │ Multi-Battle  │ Multiple zones │ $5-20/hr
```

**Layer 3: Distributed Authority Mesh (Future)**

```
100 players in battle:
├─ Players 1-10: Authority for ships 1-100
├─ Players 11-20: Authority for ships 101-200
├─ Players 21-30: Projectile/explosion authority
├─ Players 31-40: Validators (anti-cheat consensus)
└─ Dynamic reassignment on player dropout

Consensus: 2-3 validators per zone
Physics: Deterministic (same inputs = same outputs)
Cheat detection: Validator disagreement = cheater flagged
```

### 2.2 Network Protocol Design

**State Synchronization:**
```gdscript
# Compressed ship state (72 bits total)
class_name ShipNetworkState

var position_delta: Vector3  # 24 bits (compressed from last frame)
var rotation_compressed: int # 32 bits (compressed quaternion)
var velocity_quantized: Vector3 # 16 bits (reduced precision)

func compress_state(ship: Ship, last_state: ShipNetworkState) -> PackedByteArray:
    # Delta compression
    var delta_pos = ship.position - last_state.position
    # Quantize and pack
    return pack_state(delta_pos, ship.rotation, ship.velocity)
```

**Interest Management:**
```gdscript
# Only sync relevant ships to each client
const CRITICAL_RANGE := 1000.0   # 1km - full physics, 20 Hz
const IMPORTANT_RANGE := 10000.0 # 10km - simplified, 5 Hz
const AWARE_RANGE := 100000.0    # 100km - position only, 1 Hz

func get_relevant_ships(player_pos: Vector3) -> Array:
    var critical := []  # Max 20 ships
    var important := [] # Max 50 ships
    var aware := []     # Max 100 ships
    # Filter by distance and priority
    return [critical, important, aware]
```

### 2.3 Phase Implementation

**Phase 1 (Milestone 1):** Solo + Simple P2P
- Design: Built for future networking
- Implementation: 1-4 players, basic sync
- Test: VR physics work in multiplayer

**Phase 2:** P2P Mesh + Database
- 16-32 players per battle
- Persistent universe tracking
- Interest management

**Phase 3:** Dedicated Servers
- 50-100 players per instance
- On-demand cloud servers
- Multi-instance battles

**Phase 4:** Distributed Authority Mesh
- 100+ players with distributed compute
- Anti-cheat consensus
- Dynamic zone assignment

---

## Part 3: VR Architecture

### 3.1 VR Scene Structure

```
XROrigin3D (VR Root)
├─ XRCamera3D (Headset)
│  ├─ Vignette (comfort, fades on movement)
│  └─ HUD (3D world-space panels)
├─ LeftController (XRController3D)
│  ├─ HandModel (3D hand mesh)
│  ├─ RayCast3D (pointer for UI)
│  ├─ GrabArea (Area3D for grabbing)
│  └─ HapticFeedback (audio/vibration)
├─ RightController (XRController3D)
│  ├─ HandModel
│  ├─ RayCast3D
│  ├─ GrabArea
│  └─ RadialMenu (thumbstick-activated)
└─ PlayerBody (CharacterBody3D)
   ├─ CollisionShape (capsule)
   ├─ GravityComponent
   └─ LocomotionSystem
```

### 3.2 Dual Camera System

**Cockpit View (VR Comfort - Primary)**
```gdscript
# XRCamera parented to ship cockpit
# Ship moves, camera moves with it
# Reference frame = cockpit interior
# Result: Minimal motion sickness
```

**Third-Person View (Optional)**
```gdscript
# XRCamera at fixed offset from ship
# Ship rotates, camera orbits
# Add: Grid floor, reference objects
# Warning: Can cause nausea - add vignette
```

**Transition:**
```gdscript
func toggle_camera_mode() -> void:
    if mode == CameraMode.COCKPIT:
        # Fade to black
        await fade_screen(0.3)
        # Switch to third person
        reparent_camera_to_orbit()
        # Fade in
        await fade_screen(0.3)
        mode = CameraMode.THIRD_PERSON
```

### 3.3 VR Comfort System (CRITICAL)

**Required Comfort Features:**

1. **Vignette on Movement**
```gdscript
extends ColorRect
class_name VignetteComfort

func _process(_delta: float) -> void:
    var speed := get_player_velocity().length()
    # Darken edges based on speed
    modulate.a = clamp(speed / 10.0, 0.0, 0.7)
```

2. **Snap Turning**
```gdscript
func handle_turn_input(input: float) -> void:
    if abs(input) > 0.7 and not turn_cooldown:
        var angle := 30.0 if input > 0 else -30.0
        xr_origin.rotate_y(deg_to_rad(angle))
        turn_cooldown = true
        await get_tree().create_timer(0.3).timeout
        turn_cooldown = false
```

3. **Framerate Stability**
- 90 FPS minimum (11.11ms budget)
- Consistent frame time > high average FPS
- Monitor: Godot profiler every session

### 3.4 VR Interaction Patterns

**Pointing (Ray-based)**
```gdscript
func _physics_process(_delta: float) -> void:
    var from := controller.global_position
    var to := from + controller.global_transform.basis.z * -10.0

    var result := space_state.intersect_ray(from, to)
    if result:
        highlight_object(result.collider)
        if trigger_pressed:
            interact(result.collider)
```

**Grabbing (Collision-based)**
```gdscript
func _on_grab_area_body_entered(body: Node3D) -> void:
    if body is Pickable and not held_object:
        grabbable_objects.append(body)

func _on_trigger_pressed() -> void:
    if grabbable_objects.size() > 0:
        grab(grabbable_objects[0])
```

**Throwing (Velocity inheritance)**
```gdscript
func release_object() -> void:
    held_object.linear_velocity = controller.velocity
    held_object.angular_velocity = controller.angular_velocity
    held_object = null
```

---

## Part 4: Autoload Architecture

### 4.1 Coordinator Pattern (ResonanceEngine)

**7-Phase Initialization Sequence:**

```gdscript
extends Node
class_name ResonanceEngine

enum Phase {
    CORE = 0,           # Time, Settings
    SPATIAL = 1,        # FloatingOrigin, Coordinates
    VR = 2,             # VRManager, Comfort, Haptics
    PERFORMANCE = 3,    # PerformanceOptimizer
    AUDIO = 4,          # AudioManager (depends on VR)
    ADVANCED = 5,       # AI, Capture systems
    PERSISTENCE = 6     # SaveSystem, Database
}

var subsystems := {
    Phase.CORE: [],
    Phase.SPATIAL: [],
    Phase.VR: [],
    Phase.PERFORMANCE: [],
    Phase.AUDIO: [],
    Phase.ADVANCED: [],
    Phase.PERSISTENCE: []
}

func _ready() -> void:
    # Initialize in strict phase order
    for phase in Phase.values():
        for subsystem in subsystems[phase]:
            await initialize_subsystem(subsystem)
```

**Critical Rules:**
1. Phase order is MANDATORY (no reordering)
2. Subsystem must complete init before next starts
3. Failure in one subsystem doesn't block others (graceful degradation)
4. All subsystems are hot-reloadable (can be freed and recreated)

### 4.2 Current Autoloads (Cleanup Required)

**KEEP:**
- ✅ ResonanceEngine (coordinator)
- ✅ SettingsManager (core)
- ✅ HttpApiServer (dev tools)
- ✅ RuntimeVerifier (testing)

**AUDIT/SIMPLIFY:**
- ⚠️ VoxelPerformanceMonitor (merge into general PerformanceOptimizer?)
- ⚠️ WebhookManager (needed for dev workflow?)
- ⚠️ JobQueue (needed for dev workflow?)
- ⚠️ SceneLoadMonitor (useful for HTTP API)

**ADD (as we build):**
- ➕ FloatingOriginSystem (Phase 1)
- ➕ VRManager (Phase 1)
- ➕ VRComfortSystem (Phase 1)
- ➕ NetworkManager (Phase 2)

### 4.3 Subsystem Template

```gdscript
extends Node
class_name BaseSubsystem

signal initialized
signal shutdown_complete
signal error_occurred(error_msg: String)

var is_initialized := false
var is_shutting_down := false

func initialize() -> Error:
    """Override this in subclasses"""
    is_initialized = true
    initialized.emit()
    return OK

func shutdown() -> void:
    """Override this in subclasses"""
    is_shutting_down = true
    # Cleanup
    shutdown_complete.emit()

func _ready() -> void:
    # Subsystems don't auto-initialize
    # ResonanceEngine calls initialize() at appropriate time
    pass
```

---

## Part 5: Scene Architecture

### 5.1 Feature-Based Development

**Directory Structure:**
```
scenes/
├── production/              # Final game scenes
│   ├── main_menu.tscn
│   ├── solar_system.tscn   # MAIN PRODUCTION SCENE
│   └── galaxy_map.tscn
│
├── features/               # DEVELOPMENT/TEST SCENES
│   ├── physics_lab.tscn           # Test orbital mechanics
│   ├── vr_controls_test.tscn      # Test VR interactions
│   ├── ship_flight_test.tscn      # Test 6DOF flight
│   ├── planetary_landing_test.tscn # Test gravity transitions
│   ├── voxel_terrain_test.tscn    # Test mining/digging
│   ├── multiplayer_sync_test.tscn # Test networking
│   └── _template_feature.tscn     # Template for new tests
│
└── test/                   # AUTOMATED TEST SCENES
    └── unit/
        ├── test_floating_origin.tscn
        ├── test_orbital_mechanics.tscn
        └── test_network_sync.tscn
```

**Development Loop:**
1. Create feature scene (loads in 1-2 seconds)
2. Implement and test (F6 in editor)
3. Iterate rapidly (< 5 second cycle)
4. Write automated test
5. Instance into production scene

**Production scene INSTANCES features, never copies them.**

### 5.2 Solar System Scene Structure

```
SolarSystem (Node3D)
├─ Sun (CelestialBody)
│  └─ DirectionalLight3D
├─ Mercury (CelestialBody)
├─ Venus (CelestialBody)
├─ Earth (CelestialBody)
│  ├─ TerrainInstance (voxel)
│  ├─ Atmosphere (shader)
│  └─ Moon (CelestialBody)
├─ Mars (CelestialBody)
├─ ... (other planets)
├─ AsteroidBelt (particle systems + LOD instances)
├─ Player (INSTANCED from features/vr_controls_test.tscn)
└─ OrbitalMechanicsManager
```

---

## Part 6: Testing Strategy

### 6.1 Multi-Layer Testing

**Layer 1: Static Analysis (Editor)**
- GDScript syntax validation (built-in)
- Scene dependency checker
- No external tools

**Layer 2: Unit Tests (GdUnit4)**
```gdscript
extends GutTest

func test_floating_origin_shift():
    var fo := FloatingOriginSystem.new()
    add_child_autofree(fo)

    var ship := Node3D.new()
    add_child_autofree(ship)
    fo.register_object(ship)

    ship.position = Vector3(15000, 0, 0)  # Beyond threshold
    fo._physics_process(0.016)

    # Ship should be shifted back near origin
    assert_lt(ship.position.length(), 1000.0)
```

**Layer 3: Runtime Tests (VR-Specific)**
- Manual testing in headset
- Automated via HTTP API
- Recording/playback of VR sessions

**Layer 4: Integration Tests**
- Full scene loading
- System interactions
- Network sync tests

### 6.2 Automated Test Runner

```bash
# Morning routine
godot --path C:/Ignotus tests/test_runner.gd

# Expected output:
# ✓ Floating origin: PASS
# ✓ Orbital mechanics: PASS
# ✓ VR tracking: PASS
# ✓ Network sync: PASS
# Total: 24/24 tests passed (0 failed)
```

**Tests run on:**
- ✅ Editor startup (optional)
- ✅ Before commit (mandatory)
- ✅ After scene reload (via HTTP API)

---

## Part 7: Performance Targets

### 7.1 VR Performance Requirements

**Non-Negotiable:**
- 90 FPS minimum (11.11ms frame budget)
- 72 FPS absolute floor (13.89ms budget)
- < 60 FPS = unacceptable (motion sickness)

**Frame Budget Breakdown:**
```
5.0ms - Rendering (GPU)
3.0ms - Physics simulation
2.0ms - Game logic (GDScript)
0.5ms - Audio
0.5ms - Networking
= 11.0ms total (0.11ms safety margin)
```

### 7.2 Optimization Strategies

**LOD (Level of Detail):**
```gdscript
# Planetary LOD example
func update_lod(distance: float) -> void:
    if distance < 1000:      # < 1km
        detail_level = LOD.ULTRA
        chunk_size = 16
    elif distance < 10000:   # < 10km
        detail_level = LOD.HIGH
        chunk_size = 32
    elif distance < 100000:  # < 100km
        detail_level = LOD.MEDIUM
        chunk_size = 64
    else:
        detail_level = LOD.LOW
        chunk_size = 128
```

**Occlusion Culling:**
- Use Godot's built-in occlusion
- Don't render far side of planets
- Frustum culling for space objects

**GPU Instancing:**
- Asteroid fields
- Star particles
- Debris fields

**Profiling:**
- Monitor EVERY session
- Record frame time spikes
- Identify bottlenecks immediately

### 7.3 Voxel Performance

**Targets:**
- Chunk generation: < 5ms
- Collision mesh: < 3ms
- Active chunks: < 512 simultaneous
- Memory: < 2GB for voxel system

**If targets not met:**
1. Increase chunk size (16→32→64)
2. Reduce LOD levels
3. Simplify collision (box approximations)
4. Consider pre-baked terrain for non-interactive planets

---

## Part 8: Orbital Mechanics Implementation

### 8.1 N-Body Gravity Simulation

```gdscript
extends Node
class_name OrbitalMechanicsManager

const G := 6.67430e-11  # Gravitational constant

var celestial_bodies: Array[CelestialBody] = []

func _physics_process(delta: float) -> void:
    # Calculate gravitational forces
    for i in range(celestial_bodies.size()):
        var body1 := celestial_bodies[i]
        var net_force := Vector3.ZERO

        for j in range(celestial_bodies.size()):
            if i == j:
                continue

            var body2 := celestial_bodies[j]
            var force := calculate_gravity(body1, body2)
            net_force += force

        # Apply force
        body1.apply_force(net_force, delta)

func calculate_gravity(body1: CelestialBody, body2: CelestialBody) -> Vector3:
    var direction := (body2.global_position - body1.global_position)
    var distance := direction.length()

    if distance < 0.001:  # Prevent division by zero
        return Vector3.ZERO

    var force_magnitude := G * body1.mass * body2.mass / (distance * distance)
    return direction.normalized() * force_magnitude
```

### 8.2 Deterministic Physics (For Networking)

**CRITICAL: Physics must be deterministic for distributed mesh**

```gdscript
# BAD - Non-deterministic
var random_offset := randf() * 10.0  # Different on each client!

# GOOD - Deterministic
var seed_value := hash(ship_id)
var rng := RandomNumberGenerator.new()
rng.seed = seed_value
var random_offset := rng.randf() * 10.0  # Same on all clients
```

**Validation:**
```gdscript
func validate_physics_determinism() -> bool:
    # Run same physics 100 times with same inputs
    # Results should be IDENTICAL every time
    var results := []
    for i in range(100):
        results.append(simulate_frame(fixed_input))

    # Check all results match
    for i in range(1, 100):
        if not results[i].is_equal_approx(results[0]):
            push_error("Physics is non-deterministic!")
            return false
    return true
```

---

## Part 9: What to Keep vs Remove

### 9.1 KEEP (Current Project)

✅ **Project structure** (autoloads, scenes, scripts)
✅ **project.godot** (physics/rendering config)
✅ **GdUnit4 addon** (testing)
✅ **godottpd addon** (HTTP API)
✅ **Core scripts** (engine.gd, settings_manager.gd)

### 9.2 REMOVE/ARCHIVE

**Outdated Documentation:**
- ❌ Remove: Conflicting status files
- ❌ Archive: Old implementation reports
- ✅ Keep: CLAUDE.md (update it)

**Unused Scripts:**
```bash
# Search for unused scripts
find scripts -name "*.gd" -exec grep -l "class_name" {} \;
# Cross-reference with actual usage in scenes
```

**Legacy Systems:**
- ⚠️ Audit: WebhookManager (needed?)
- ⚠️ Audit: JobQueue (needed?)
- ⚠️ Consider: Merge VoxelPerformanceMonitor into general PerformanceOptimizer

### 9.3 ADD

**Missing Essentials:**
1. ➕ godot-xr-tools addon (VR interactions)
2. ➕ FloatingOriginSystem script
3. ➕ OrbitalMechanicsManager script
4. ➕ NetworkManager script (Phase 2)
5. ➕ Feature test scenes

---

## Part 10: Development Phases

**Phase 0: Foundation (Week 1)**
- Verify project compiles (0 errors)
- Install godot-xr-tools
- Create minimal VR scene
- Test VR tracking works

**Phase 1: Core Physics (Weeks 2-4)**
- FloatingOriginSystem
- Basic orbital mechanics
- Walk on planet with correct gravity
- Board ship (transition)

**Phase 2: Flight & Landing (Weeks 5-8)**
- 6DOF flight controls
- Fly between planets
- Landing sequence
- Gravity transitions

**Phase 3: Multiplayer Foundation (Weeks 9-12)**
- Simple P2P (2-4 players)
- Basic state sync
- Test multiplayer flight

**Phase 4: Terrain & Interaction (Weeks 13-16)**
- Voxel terrain on planets
- Mining/digging
- Resource collection
- Building (if in scope)

**Phase 5: Scale & Optimization (Weeks 17-20)**
- Full solar system
- LOD optimization
- 90 FPS in VR achieved
- Network scaling (16-32 players)

**Phase 6: Advanced Features (Weeks 21+)**
- AI NPCs (RL training)
- Farming systems
- Economy/trading
- Distributed mesh networking

---

## Part 11: Milestone Criteria

**Milestone 1: Foundation Complete**
- ✅ 0 compilation errors
- ✅ VR tracking works (headset + controllers)
- ✅ 90 FPS in empty scene
- ✅ HTTP API responds
- ✅ Test suite passes (all green)

**Milestone 2: Core Physics Complete**
- ✅ Floating origin functional
- ✅ Walk on planet (gravity correct)
- ✅ Board ship (enter/exit)
- ✅ Ship interior physics
- ✅ Multiplayer-ready (designed for networking)

**Milestone 3: Flight Complete**
- ✅ 6DOF flight controls work
- ✅ Fly from planet to orbit
- ✅ Travel to another planet
- ✅ Land successfully
- ✅ 90 FPS maintained

**Milestone 4: Multiplayer Working**
- ✅ 2-4 players can see each other
- ✅ Ship movement syncs
- ✅ VR interactions sync
- ✅ No desyncs or glitches

**Milestone 5: Production Ready**
- ✅ Full solar system functional
- ✅ Voxel terrain on planets
- ✅ 16-32 players per instance
- ✅ Database persistence
- ✅ 90 FPS with 20+ players

---

## Part 12: Anti-Rewrite Guarantees

**This architecture prevents rewrites because:**

1. ✅ **Physics decided upfront** (hybrid Godot + custom)
2. ✅ **Multiplayer designed from day 1** (not bolted on)
3. ✅ **Floating origin from start** (scales to galaxy)
4. ✅ **Feature isolation** (test independently)
5. ✅ **Performance targets defined** (90 FPS VR)
6. ✅ **Phased implementation** (build in layers)
7. ✅ **Deterministic physics** (networking-ready)
8. ✅ **Testing at every step** (catch bugs early)

**If you follow this blueprint step-by-step, you will not need to rewrite.**

---

## Appendix: Quick Reference

**Tech Stack:**
- Engine: Godot 4.5.1
- VR: OpenXR (BigScreen Beyond)
- Physics: Hybrid (Godot + custom orbital)
- Networking: Phased (P2P → servers → mesh)
- Terrain: Terrain3D or godot_voxel (test both)
- Testing: GdUnit4 + runtime tests

**Performance:**
- 90 FPS VR (11.11ms budget)
- 90 Hz physics tick
- Floating origin (galaxy-scale)
- Aggressive LOD (optimization)

**Multiplayer:**
- Phase 1: 2-4 players (P2P)
- Phase 2: 16-32 players (P2P mesh)
- Phase 3: 50-100 players (servers)
- Phase 4: 1000+ players (distributed mesh + instancing)

**Next Steps:**
1. Read DEVELOPMENT_PHASES.md
2. Read PHASE_1_FOUNDATION.md
3. Start building

---

**This is the complete architecture. Follow it, and build your galaxy.**
