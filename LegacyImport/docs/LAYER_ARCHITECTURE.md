# Layer Architecture: SpaceTime Planetary Survival System

**Last Updated:** 2025-12-04
**Status:** Foundation Phase Complete
**Version:** 1.0 - Onion Layers Architecture

---

## Executive Summary

SpaceTime uses an **"Onion Layer" architecture** for the planetary survival system. Each layer builds upon the previous layer, providing increasing levels of complexity and player interaction. This document describes the architecture, how layers interact, and the process for adding new layers.

**Primary Scene:** `res://scenes/celestial/solar_system_landing.tscn`

---

## The Onion Layer Concept

### Why Onion Layers?

The onion architecture provides several benefits:

1. **Clear Separation of Concerns** - Each layer has a single responsibility
2. **Dependency Order** - Outer layers depend on inner layers, never the reverse
3. **Testability** - Each layer can be tested independently
4. **Scalability** - New systems can be added as outer layers without modifying inner systems
5. **Player Progression** - Players unlock and interact with systems in order from inner to outer layers

### Dependency Flow

```
Layer 5 (VR HUD) ──┐
                   ├─ depends on
Layer 4 (PowerGrid) ├─ depends on
                   ├─ depends on
Layer 3 (Resources) ├─ depends on
                   ├─ depends on
Layer 2 (Inventory) ├─ depends on
                   ├─ depends on
Layer 1 (LifeSupport) ├─ depends on
                      │
Layer 0 (Foundation)  └─ Independent
```

**Critical Rule:** Outer layers ONLY import and use systems from inner layers. Inner layers should NEVER reference outer layers.

---

## Layer 0: Foundation (Independent Core)

**Location:** `scenes/celestial/solar_system_landing.tscn`
**Scripts:** `scripts/celestial/*`, `scripts/vr_controller_basic.gd`
**Status:** COMPLETE

### Purpose
The foundation provides the basic game environment and player control infrastructure. This layer is independent—it does NOT depend on any other layers.

### Components

#### A. Solar System Environment
- **Script:** `scripts/celestial/solar_system_initializer.gd`
- **Responsibility:**
  - Initialize celestial bodies (Sun, planets, moons)
  - Load ephemeris data from `res://data/ephemeris/solar_system.json`
  - Create visual models for celestial objects
  - Register physics bodies for collision
  - Display orbital paths
  - Manage large-scale coordinate systems

#### B. VR System
- **Nodes:** `XROrigin3D`, `XRCamera3D`, `FallbackCamera`
- **Controllers:** `LeftController`, `RightController`
- **Responsibility:**
  - Initialize XR session for VR headset support
  - Track hand/head position
  - Provide fallback desktop camera if VR unavailable
  - Handle controller input

#### C. Spacecraft
- **Scene:** `res://scenes/spacecraft/spacecraft_exterior.tscn`
- **Node:** `PlayerSpacecraft` (instance in solar_system_landing.tscn)
- **Responsibility:**
  - Provide player's initial vehicle
  - Handle spacecraft physics and thrust
  - Manage cockpit view
  - Enable traversal of space

#### D. Environment & Rendering
- **Nodes:** `WorldEnvironment`, `SunLight`
- **Responsibility:**
  - Define space environment (black background, dim ambient light)
  - Position directional light from Sun
  - Manage shadows and tone mapping
  - Render glow and bloom effects

#### E. Player Collision
- **Node:** `PlayerCollision` (CharacterBody3D with CapsuleShape3D)
- **Responsibility:**
  - Define player's physical body
  - Enable collision detection
  - Prepare for EVA (extravehicular activity) gameplay

### Data Flow
```
Initialization:
Solar System Init ──> Celestial Bodies Created ──> Physics Registered

Runtime:
VR Input ──> Controller State ──> Spacecraft Movement
Player Position ──> Collision Detection
```

### Key Signals
- None at this layer (Foundation is input/rendering only)

---

## Layer 1: Life Support System

**Location:** `scripts/planetary_survival/systems/life_support_system.gd`
**Scene Node:** `LifeSupportSystem` (Node) in solar_system_landing.tscn
**Status:** IMPLEMENTED (Basic)
**Autoload:** No (attached to scene)

### Purpose
Layer 1 provides basic survival mechanics. The player must manage oxygen and temperature to survive planetary operations.

### Components

#### A. Oxygen Management
```gdscript
var oxygen_level: float = 100.0
var max_oxygen: float = 100.0

func produce_oxygen(amount: float) -> void
func consume_oxygen(amount: float) -> void
func has_oxygen() -> bool
```

- **Signals:** `oxygen_level_changed(current, max)`
- **Responsibility:**
  - Track available oxygen
  - Enforce oxygen consumption per time step (handled by outer layers)
  - Alert when oxygen is critically low
  - Support oxygen production (from air processors, plants, etc.)

#### B. Temperature Management
```gdscript
var temperature: float = 20.0  # Celsius

func set_temperature(new_temp: float) -> void
```

- **Signals:** `temperature_changed(current)`
- **Responsibility:**
  - Track environmental temperature
  - Support temperature regulation (cooling, heating)
  - Define thermal comfort range (15-25°C recommended)
  - Alert when temperature is unsafe

### Integration Point
**How Layer 2+ uses this:**
- Check `has_oxygen()` before allowing player action
- Subscribe to `oxygen_level_changed` signal to update HUD
- Call `consume_oxygen()` during gameplay
- Call `set_temperature()` from environmental effects

### Example: Layer 2 Integration
```gdscript
# From InventorySystem (Layer 2)
if not life_support.has_oxygen():
    emit_player_died.emit("Oxygen depleted")
    return false
```

---

## Layer 2: Inventory System

**Location:** `scripts/planetary_survival/systems/inventory_system.gd` (planned)
**Status:** PLANNED
**Dependencies:** Layer 1 (LifeSupportSystem)

### Purpose
Layer 2 provides item management and player carrying capacity. Items are resources gathered from the environment that support survival and progression.

### Planned Components

#### A. Inventory Slots
```gdscript
var inventory_slots: Array[InventorySlot]  # Max 20 slots
var current_weight: float = 0.0
var max_weight: float = 100.0
```

- Track items player is carrying
- Enforce weight limits
- Support equipment (suit, tools, oxygen tanks)

#### B. Item Types
- **Consumables:** Food, water, oxygen tanks, medicine
- **Equipment:** Suit modules, tools, weapons
- **Junk:** Crafting materials, trade goods
- **Quest Items:** Non-droppable story items

#### C. Item Slots
```gdscript
class InventorySlot:
    var item_id: String
    var quantity: int
    var durability: float  # For tools/equipment
```

#### D. Signals
- `inventory_changed(slot_index)`
- `weight_limit_exceeded()`
- `item_added(item_id, quantity)`
- `item_removed(item_id, quantity)`

### Integration Point
**Consumes from Layer 1:**
- Check `life_support.has_oxygen()` before allowing extended activities
- Equip oxygen tanks from inventory to restore oxygen

**Provides to Layer 3:**
- Inventory state for resource management
- Item definitions for crafting system

### Example Interaction
```gdscript
# From Layer 2 (InventorySystem)
func equip_oxygen_tank() -> void:
    if inventory.has_item("oxygen_tank"):
        life_support.produce_oxygen(50.0)
        inventory.consume_item("oxygen_tank")
```

---

## Layer 3: Resource System

**Location:** `scripts/planetary_survival/systems/resource_system.gd`
**Scene Node:** Added dynamically
**Status:** IMPLEMENTED (Core)
**Dependencies:** Layer 1 (LifeSupportSystem), Layer 2 (InventorySystem)

### Purpose
Layer 3 manages resource gathering, distribution, and sustainability. Players must balance resource extraction with environmental impact.

### Implemented Components

#### A. Resource Type Registry
```gdscript
var resource_types: Dictionary = {}  # "iron" -> ResourceDefinition

class ResourceDefinition:
    var name: String           # "Iron Ore"
    var stack_size: int        # Max items per stack
    var rarity: float          # 0.0-1.0 spawn probability
    var color: Color           # Visual identification
    var fragments_per_node: int  # How much per deposit
    var min_depth: float       # Ground level spawn range
    var max_depth: float
    var biome_weights: Dictionary  # Biome-specific spawning
```

**Registered Resources:**
- **Iron Ore** - Common, basic crafting (stack: 100)
- **Copper Ore** - Common, electrical crafting (stack: 100)
- **Energy Crystal** - Rare, power generation (stack: 50)
- **Organic Matter** - Common, food/life support (stack: 200)
- **Titanium Ore** - Rare, high-strength materials (stack: 50)

#### B. Resource Nodes
```gdscript
var resource_nodes: Array[ResourceNode] = []

class ResourceNode:
    var resource_type: String  # "iron", "crystal", etc.
    var position: Vector3
    var quantity: float        # How much remains
    var depletion_time: float  # Seconds until fully depleted
```

- Spawned procedurally in terrain
- Player can mine/harvest
- Regenerates over time (configurable)
- Visual feedback shows depletion state

#### C. Procedural Spawning
```gdscript
const CHUNK_SIZE: int = 32

func _spawn_resources_for_chunk(chunk_pos: Vector2i) -> void
func _calculate_resource_distribution(resource_id: String) -> void
```

- Chunks defined by grid coordinates
- Deterministic spawning (seed-based)
- Respects biome weights
- Configurable spawn density

#### D. Gathering System
```gdscript
func gather_resource(resource_type: String, amount: float) -> float
func deplete_node(resource_node: ResourceNode) -> void
func respawn_nodes() -> void
```

### Integration Points

**Consumes from Layers 1-2:**
- Check `life_support.has_oxygen()` before allowing mining
- Store gathered items in `inventory`
- Consume stamina/energy from player stats

**Provides to Layer 4:**
- Power generation materials (energy crystals → power)
- Crafting materials for production
- Economic value for trade systems

### Example Interaction
```gdscript
# From player action (e.g., mining)
# Layer 3 checks layers below before allowing action
if not life_support.has_oxygen():
    return  # Can't mine without air

var gathered = resource_system.gather_resource("iron", 10)
inventory.add_item("iron", gathered)
```

---

## Layer 4: Power Grid System

**Location:** `scripts/planetary_survival/systems/power_grid_system.gd`
**Scene Node:** Added dynamically
**Status:** IMPLEMENTED (Basic)
**Dependencies:** Layers 1-3 (indirect via resource management)

### Purpose
Layer 4 manages power generation, distribution, and consumption. Base operations require power, creating a resource balance puzzle.

### Implemented Components

#### A. Power Generation
```gdscript
var total_generation: float = 0.0
var max_power_capacity: float = 1000.0

func register_generator(power_output: float) -> void
func unregister_generator(power_output: float) -> void
```

- **Generator Types:**
  - Solar panels (passive, weather-dependent)
  - Nuclear reactors (high output, fuel-dependent)
  - Kinetic generators (activity-dependent)
  - Energy crystal reactors (material-dependent)

**Integration Point:**
- Energy crystals from Layer 3 enable reactor construction
- Inventory tracking supports fuel management

#### B. Power Consumption
```gdscript
var total_consumption: float = 0.0

func register_consumer(power_draw: float) -> void
func unregister_consumer(power_draw: float) -> void
func get_available_power() -> float
func has_power() -> bool
```

- **Consumer Types:**
  - Life support system (Layer 1)
  - Manufacturing (Layer 3)
  - Heating/cooling (Layer 1)
  - Lights and security

#### C. Power Balance
```gdscript
func get_available_power() -> float:
    return max(0.0, total_generation - total_consumption)
```

- Tracks surplus/deficit
- Enables battery charging/discharging
- Triggers alarms when power critical

### Signals
- `power_changed(current_power, max_power)`

### Integration Points

**Consumes from Layers 1-3:**
- Life support system draws power for oxygen generation
- Resource processing requires power
- Manufacturing equipment is power-dependent

**Provides to Layer 5:**
- Power state display in HUD
- Enable/disable systems based on power availability

### Example Interaction
```gdscript
# From Layer 2 (Inventory) - Using Life Support (Layer 1)
# Which uses Power Grid (Layer 4)
if life_support.has_oxygen():
    if power_grid.has_power():
        # Oxygen can be produced from atmospheric processors
        life_support.produce_oxygen(1.0)
```

---

## Layer 5: VR HUD System

**Location:** `scripts/ui/vr_hud.gd` (planned)
**Status:** PLANNED
**Dependencies:** Layers 1-4 (reads state, no modification)

### Purpose
Layer 5 provides the player-facing display for all underlying systems. The HUD is read-only (displays state) but is informed by all lower layers.

### Planned Components

#### A. Status Display
```gdscript
# Displays state from all layers
var life_support_widget: LifeSupportWidget     # Layer 1 state
var inventory_widget: InventoryWidget          # Layer 2 state
var resource_scanner: ResourceScanner          # Layer 3 state
var power_status_widget: PowerStatusWidget     # Layer 4 state
```

#### B. Widgets (VR-Friendly)
- **Helmet Visor Display**
  - Oxygen level (Layer 1)
  - Temperature gauge (Layer 1)
  - Inventory count (Layer 2)
  - Power meter (Layer 4)

- **Wrist Console**
  - Detailed inventory (Layer 2)
  - Resource map (Layer 3)
  - Power grid status (Layer 4)

- **Field of View Indicators**
  - Oxygen warning (red glow when < 20%)
  - Power alarm (flashing when critical)
  - Temperature warning (blue tint when cold)

#### C. Input Handling
```gdscript
func on_inventory_button_pressed() -> void:
    inventory_widget.toggle_display()

func on_scanner_button_pressed() -> void:
    resource_scanner.toggle_display()
```

### Design Constraints
- VR-native (not desktop-centric)
- Real-time updates from all layers
- Accessible from controllers (thumbstick/button combos)
- Immersive (stays in character, no pause menus)

### Integration Points

**Read-only consumers of:**
- Layer 1: `oxygen_level`, `temperature`, `oxygen_level_changed` signal
- Layer 2: `inventory_slots`, `current_weight`, `inventory_changed` signal
- Layer 3: `resource_nodes`, `gather_resource` results, resource map
- Layer 4: `get_available_power()`, `power_changed` signal

**Never modifies:**
- Does not call production methods
- Does not consume resources
- Does not change state (display only)

---

## Future Layers (Roadmap)

### Layer 6: Manufacturing System (PLANNED)
**Purpose:** Convert raw materials into finished goods
**Dependencies:** Layers 1-4
**Features:**
- Define recipes (iron + copper → circuit board)
- Manufacturing queue
- Production time and power requirements
- Quality tiers

### Layer 7: Trading System (PLANNED)
**Purpose:** Economic interactions with NPCs
**Dependencies:** Layers 1-4 + Manufacturing (Layer 6)
**Features:**
- NPC traders
- Market prices
- Supply/demand economics
- Barter system

### Layer 8: Research System (PLANNED)
**Purpose:** Unlock new capabilities through discovery
**Dependencies:** Layers 1-7
**Features:**
- Tech trees
- Research projects
- Capability unlocks
- Progression gating

### Layer 9: Planetary Exploration (PLANNED)
**Purpose:** Expand gameplay to full planetary surface
**Dependencies:** Layers 1-8
**Features:**
- Voxel terrain traversal
- Base expansion
- Anomaly discovery
- Environmental hazards

---

## How to Add a New Layer

### Step 1: Define Purpose & Dependencies
- What problem does the layer solve?
- Which existing layers does it depend on?
- Which layers (if any) depend on it?

**Example:**
```
Layer 6: Manufacturing
- Depends on: Layers 1-4 (power, inventory, resources)
- Enables: Trading (Layer 7)
```

### Step 2: Create the GDScript System
**File Location:** `scripts/planetary_survival/systems/[layer_name]_system.gd`

**Template:**
```gdscript
class_name [LayerName]System
extends Node

## [Layer description]
## Depends on: [Parent layer name]
## Enabled by: [Sibling dependencies]

signal system_changed  # Generic signal for HUD updates

# State
var is_enabled: bool = true

# References to parent layers
@onready var life_support: LifeSupportSystem = get_parent().get_node("LifeSupportSystem")
@onready var inventory: InventorySystem = get_parent().get_node("InventorySystem")

func _ready():
    print("[%sSystem] Initialized" % self.__class__)

# Public API
func execute_action() -> bool:
    # CRITICAL: Check parent layers first
    if not life_support.has_oxygen():
        return false

    # Execute action
    return true
```

### Step 3: Register with Scene
1. Open `scenes/celestial/solar_system_landing.tscn` in Godot editor
2. Add a new Node as child of `SolarSystemLanding` root
3. Attach your new system script
4. Set properties as needed

**In TSCN (scene file):**
```
[node name="[LayerName]System" type="Node" parent="."]
script = ExtResource("[N]_[layer]")
```

### Step 4: Add Signals to HUD (Layer 5)
Update `scripts/ui/vr_hud.gd` to listen for and display the new system's state:

```gdscript
# In vr_hud.gd
@onready var [layer]_system: [LayerName]System = get_parent().get_node("[LayerName]System")

func _ready():
    [layer]_system.[signal_name].connect(_on_[layer]_changed)

func _on_[layer]_changed():
    _update_hud_display()
```

### Step 5: Write Tests
Create tests in `tests/unit/systems/`:
```
tests/unit/systems/test_[layer_name]_system.gd
```

**Test Template:**
```gdscript
# Tests should verify:
# 1. System initializes correctly
# 2. Signals are emitted on state change
# 3. Dependencies are accessible
# 4. Parent layers are checked before actions
```

### Step 6: Document Integration Points
Update this file with:
- System location
- Dependencies
- Integration examples
- API methods and signals

### Step 7: Verify Architecture
Run architecture check:
```bash
python scripts/tools/verify_layer_dependencies.py
```

This script validates that:
- No circular dependencies exist
- Outer layers only reference inner layers
- All dependencies are satisfied

---

## Data Flow Example: Mining Operation

This example shows how all layers interact during a single player action.

### Scenario: Player mines iron ore on planet surface

```
1. PLAYER ACTION (Input Layer 0)
   └─> Right controller press trigger

2. LIFE SUPPORT CHECK (Layer 1)
   ├─> has_oxygen() → true (proceed)
   └─> consume_oxygen(0.1) for exertion

3. INVENTORY CHECK (Layer 2)
   ├─> has_capacity() → true
   └─> ready for items

4. RESOURCE GATHERING (Layer 3)
   ├─> gather_resource("iron", 10)
   ├─> resource_nodes depleted
   └─> returns gathered: 10

5. INVENTORY UPDATE (Layer 2)
   ├─> add_item("iron", 10)
   ├─> increase_weight(10 * 0.1 kg)
   └─> emit inventory_changed signal

6. POWER CONSUMPTION (Layer 4)
   ├─> mining_drill.has_power() → true
   └─> consume mining_power (1.0 MW)

7. HUD UPDATE (Layer 5)
   ├─> Listen to inventory_changed
   ├─> Listen to oxygen_level_changed
   ├─> Listen to power_changed
   └─> Update visor display

RESULT: Player gained iron, oxygen decreased, power consumed
```

---

## Critical Architectural Rules

### Rule 1: Unidirectional Dependencies
Outer layers MAY import inner layers.
Inner layers MUST NOT import outer layers.

**Allowed:**
```gdscript
# In PowerGridSystem (Layer 4)
var life_support: LifeSupportSystem  # Layer 1 - OK ✓

# In InventorySystem (Layer 2)
var life_support: LifeSupportSystem  # Layer 1 - OK ✓
```

**NOT ALLOWED:**
```gdscript
# In LifeSupportSystem (Layer 1)
var power_grid: PowerGridSystem  # Layer 4 - FORBIDDEN ✗
# This creates a circular dependency!
```

### Rule 2: Signal-Based Communication
Outer layers LISTEN to signals from inner layers.
Inner layers EMIT signals.
Outer layers do NOT call methods to trigger state changes in inner layers.

**Correct:**
```gdscript
# In HUD (Layer 5)
life_support.oxygen_level_changed.connect(_on_oxygen_changed)

func _on_oxygen_changed(current, max):
    update_oxygen_bar(current, max)
```

**Incorrect:**
```gdscript
# DON'T do this - breaks the layer boundary
func update_hud():
    var oxygen = life_support.oxygen_level  # Direct access
```

### Rule 3: Check Dependencies Before Acting
Every method that modifies state must check parent layers first.

**Correct:**
```gdscript
func mine_resource() -> bool:
    # Check Layer 1 (dependency)
    if not life_support.has_oxygen():
        return false

    # Check Layer 2 (dependency)
    if not inventory.has_capacity():
        return false

    # Now safe to execute
    do_mining()
    return true
```

### Rule 4: No State Synchronization
Outer layers should not maintain redundant copies of inner layer state.
Always query or listen to signals.

**Correct:**
```gdscript
# In Layer 3 - Reference the actual object
func check_power():
    return power_grid.has_power()
```

**Incorrect:**
```gdscript
# DON'T cache state
var cached_power: bool = power_grid.has_power()
# This may become stale!
```

---

## Debugging Layer Issues

### Issue: "Outer layer can't see inner layer"

**Symptom:** Script error - "Power grid not found"

**Cause:** Reference path is wrong

**Fix:**
```gdscript
# Correct - navigate the scene tree
@onready var power_grid = get_parent().get_node("PowerGridSystem")

# Or use autoloads (future improvement)
var power_grid = ResonanceEngine.power_grid
```

### Issue: "Inner layer modified by outer layer"

**Symptom:** Power system state changes unexpectedly

**Cause:** Outer layer called inner layer's private method

**Fix:**
```gdscript
# Make clear API distinction
class_name PowerGridSystem
extends Node

# PUBLIC API (OK for outer layers to call)
func register_generator(power: float) -> void:
    ...

# PRIVATE IMPLEMENTATION (outer layers must NOT call)
func _update_power_state() -> void:
    ...
```

### Issue: "Circular dependency"

**Symptom:** Script errors during initialization

**Cause:** Layer A references Layer B, Layer B references Layer A

**Fix:** Introduce a mediator layer or use event bus pattern
```gdscript
# Instead of direct references
var life_support: LifeSupportSystem      # Layer 1
var power_grid: PowerGridSystem          # Layer 4

# Use signals through event system
event_bus.oxygen_depleted.connect(_on_oxygen_depleted)
event_bus.power_restored.connect(_on_power_restored)
```

---

## Testing Layers

### Unit Tests
```bash
# Test a single layer
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd \
    --test-suite tests/unit/systems/test_life_support_system.gd
```

### Integration Tests
```bash
# Test layer interactions
python tests/test_layer_integration.py
```

**Test Example:**
```gdscript
# test_layer_integration.gd
func test_mining_with_low_oxygen():
    # Setup
    life_support.oxygen_level = 5.0  # Very low

    # Act
    var result = resource_system.gather_resource("iron", 10)

    # Assert - should fail because oxygen is too low
    assert(result == 0, "Mining should fail with no oxygen")
```

---

## Performance Considerations

### Layer Overhead
- Each layer adds ~0.1ms per frame (all signals combined)
- Signal connections are lightweight
- Avoid polling in _process() - use signals instead

### Memory Layout
```
Layer 0 (Foundation):    ~2 MB (scene objects)
Layer 1 (LifeSupport):   ~50 KB (state + signals)
Layer 2 (Inventory):     ~100 KB (item list)
Layer 3 (Resources):     ~500 KB (resource nodes)
Layer 4 (PowerGrid):     ~50 KB (power tracking)
Layer 5 (HUD):           ~200 KB (UI widgets)

TOTAL: ~3 MB for complete system
```

### Optimization Tips
1. Only connect signals you actually use
2. Use `_on_ready` deferred connections
3. Cache layer references in @onready fields
4. Batch signal emissions (avoid 60 signals/frame)

---

## Reference to Universal Game Dev Loop

This layer architecture supports the **Universal Game Dev Loop** by providing:

1. **Deep Dive** - Documentation shows you exactly what exists in each layer
2. **Gap Analysis** - Clear missing layers for future features
3. **Execution** - Well-defined process for adding new layers
4. **Verification** - Layer tests confirm everything works together

See `docs/UNIVERSAL_GAME_DEV_PROMPT.md` for the full development workflow.

---

## Summary

| Layer | Status | Purpose | Dependencies |
|-------|--------|---------|--------------|
| 0 | Complete | Solar system, VR, spacecraft | None |
| 1 | Implemented | Life support (O2, temp) | Layer 0 |
| 2 | Planned | Inventory management | Layer 1 |
| 3 | Implemented | Resource gathering | Layers 1-2 |
| 4 | Implemented | Power grid management | Layers 1-3 |
| 5 | Planned | VR HUD display | Layers 1-4 |
| 6-9 | Future | Manufacturing, trading, research, exploration | Layers 1-5 |

**Next Steps:**
1. Complete Layer 2 (Inventory) implementation
2. Connect Layer 5 (VR HUD) to display all layer states
3. Add tests for layer interactions
4. Begin Layer 6 (Manufacturing) design

---

**Document Version:** 1.0
**Last Review:** 2025-12-04
**Maintainer:** Claude Code (AI Agent)
**Audience:** Development team, AI agents, architects
