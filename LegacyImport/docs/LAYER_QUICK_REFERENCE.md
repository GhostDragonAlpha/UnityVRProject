# Layer Systems Quick Reference

**Version:** 1.0
**Last Updated:** 2025-12-04
**Status:** Production Ready

Quick reference guide for SpaceTime's layer systems. These are core gameplay subsystems that manage planetary survival mechanics.

---

## System Overview

The Layer Systems are five interconnected subsystems that manage base survival, resource management, and structure building:

| System | Purpose | Location |
|--------|---------|----------|
| **Life Support** | Oxygen and temperature management | `scripts/planetary_survival/systems/life_support_system.gd` |
| **Power Grid** | Energy generation and distribution | `scripts/planetary_survival/systems/power_grid_system.gd` |
| **Resource** | Resource types, spawning, gathering | `scripts/planetary_survival/systems/resource_system.gd` |
| **Base Building** | Structure placement, connections, integrity | `scripts/planetary_survival/systems/base_building_system.gd` |
| **Base Customization** | Decorations, painting, lighting, materials | `scripts/planetary_survival/systems/base_customization_system.gd` |

---

## 1. Life Support System

**Class:** `LifeSupportSystem`
**Location:** `scripts/planetary_survival/systems/life_support_system.gd`
**Extends:** `Node`

### Purpose
Tracks and manages oxygen production/consumption and temperature control for habitable spaces.

### Signals
```gdscript
signal oxygen_level_changed(current: float, max: float)
signal temperature_changed(current: float)
```

### Key Properties
```gdscript
var oxygen_level: float = 100.0
var max_oxygen: float = 100.0
var temperature: float = 20.0  # Celsius
```

### Main Methods

#### Oxygen Management
```gdscript
# Produce oxygen (increase level)
life_support.produce_oxygen(amount: float) -> void

# Consume oxygen (decrease level)
life_support.consume_oxygen(amount: float) -> void

# Check if oxygen available
var has_oxygen: bool = life_support.has_oxygen() -> bool
```

#### Temperature Management
```gdscript
# Set temperature
life_support.set_temperature(new_temp: float) -> void
```

### Usage Example
```gdscript
# In another script
var life_support = get_node("LifeSupportSystem")

# Connect to changes
life_support.oxygen_level_changed.connect(_on_oxygen_changed)
life_support.temperature_changed.connect(_on_temperature_changed)

# Produce oxygen
life_support.produce_oxygen(10.0)

# Consume oxygen
life_support.consume_oxygen(5.0)

# Check status
if life_support.has_oxygen():
    print("Base has oxygen")
```

---

## 2. Power Grid System

**Class:** `PowerGridSystem`
**Location:** `scripts/planetary_survival/systems/power_grid_system.gd`
**Extends:** `Node`

### Purpose
Manages power generation, consumption, and distribution across the base.

### Signals
```gdscript
signal power_changed(current_power: float, max_power: float)
```

### Key Properties
```gdscript
var total_generation: float = 0.0
var total_consumption: float = 0.0
var max_power_capacity: float = 1000.0
```

### Main Methods

#### Generator Management
```gdscript
# Register a power generator
power_grid.register_generator(power_output: float) -> void

# Unregister a power generator
power_grid.unregister_generator(power_output: float) -> void
```

#### Consumer Management
```gdscript
# Register a power consumer (device)
power_grid.register_consumer(power_draw: float) -> void

# Unregister a power consumer
power_grid.unregister_consumer(power_draw: float) -> void
```

#### Status Checks
```gdscript
# Get available power (generation - consumption)
var available: float = power_grid.get_available_power() -> float

# Check if power available
var has_power: bool = power_grid.has_power() -> bool
```

### Usage Example
```gdscript
var power_grid = get_node("PowerGridSystem")

# Register a generator (100W output)
power_grid.register_generator(100.0)

# Register a consumer (50W consumption)
power_grid.register_consumer(50.0)

# Check available power
var available = power_grid.get_available_power()  # Returns 50.0
print("Available power: %f W" % available)

# Connect to power changes
power_grid.power_changed.connect(_on_power_changed)
```

---

## 3. Resource System

**Class:** `ResourceSystem`
**Location:** `scripts/planetary_survival/systems/resource_system.gd`
**Extends:** `Node`

### Purpose
Manages resource types (ores, crystals, organic matter), spawning, and gathering.

### Key Properties
```gdscript
var voxel_terrain: StubVoxelTerrain = null
var resource_types: Dictionary = {}  # id -> definition
var resource_nodes: Array[ResourceNode] = []
var world_seed: int = 0
const CHUNK_SIZE: int = 32
```

### Default Resources Registered
- **Iron Ore** - Common ore, stack 100, rarity 0.3
- **Copper Ore** - Common ore, stack 100, rarity 0.4
- **Energy Crystal** - Rare resource, stack 50, rarity 0.1
- **Organic Matter** - Biological resource, stack 200, rarity 0.5
- **Titanium Ore** - Rare metal, stack 50, rarity 0.15
- **Uranium Ore** - Radioactive, stack 25, rarity 0.05

### Resource Definition Structure
```gdscript
{
    "name": "Resource Name",
    "stack_size": 100,
    "rarity": 0.3,
    "color": Color(0.5, 0.5, 0.5),
    "fragments_per_node": 10,
    "min_depth": 0.0,
    "max_depth": 1000.0,
    "biome_weights": {"default": 1.0, "cave": 2.0}
}
```

### Main Methods

#### Resource Type Management
```gdscript
# Register a custom resource type
resource_system.register_resource_type(id: String, definition: Dictionary) -> void
```

#### Spawning and Generation
```gdscript
# Spawn a resource node at position
var node = resource_system.spawn_resource_node(position: Vector3, type: String, quantity: int) -> ResourceNode

# Generate resources procedurally for a chunk
var nodes = resource_system.generate_resources_for_chunk(chunk_pos: Vector3i, biome: String = "default") -> Array[ResourceNode]
```

#### Gathering
```gdscript
# Gather resources from a node
var result = resource_system.gather_resource(node: ResourceNode, amount: int) -> Dictionary

# Scan for resources in radius
var signatures = resource_system.scan_for_resources(center: Vector3, radius: float) -> Array
```

#### Inventory Management
```gdscript
# Add resources to inventory
resource_system.add_to_inventory(inventory: Dictionary, resource: String, amount: int) -> bool

# Remove resources from inventory
resource_system.remove_from_inventory(inventory: Dictionary, resource: String, amount: int) -> bool

# Get count of resource
var count = resource_system.get_inventory_count(inventory: Dictionary, resource: String) -> int
```

#### Persistence
```gdscript
# Save state
var state = resource_system.save_state() -> Dictionary

# Load state
resource_system.load_state(data: Dictionary) -> void
```

### Usage Example
```gdscript
var resource_system = get_node("ResourceSystem")

# Generate resources for a chunk
var generated = resource_system.generate_resources_for_chunk(Vector3i(0, 0, 0), "cave")
print("Generated %d resource nodes" % generated.size())

# Scan for nearby resources
var nearby = resource_system.scan_for_resources(player_position, 50.0)
for signature in nearby:
    print("Found %s at %v (qty: %d)" % [signature["type"], signature["position"], signature["quantity"]])

# Gather from a node
if nearby.size() > 0:
    var result = resource_system.gather_resource(nearby[0], 10)
    print("Gathered: %s x %d" % [result["type"], result["amount"]])

# Manage inventory
var inventory = {}
resource_system.add_to_inventory(inventory, "iron", 50)
resource_system.add_to_inventory(inventory, "copper", 30)
var iron_count = resource_system.get_inventory_count(inventory, "iron")  # Returns 50
```

---

## 4. Base Building System

**Class:** `BaseBuildingSystem`
**Location:** `scripts/planetary_survival/systems/base_building_system.gd`
**Extends:** `Node`

### Purpose
Handles modular structure placement, network connections (power/oxygen/data), and structural integrity checks.

### Signals
```gdscript
signal module_placed(module: BaseModule)
signal module_removed(module: BaseModule)
signal placement_invalid(reason: String)
signal network_updated()
signal structural_collapse(modules: Array[BaseModule])
signal structural_warning(module: BaseModule, integrity: float)
```

### Module Types
```gdscript
enum ModuleType {
    HABITAT,      # Living quarters
    STORAGE,      # Resource storage
    FABRICATOR,   # Crafting facility
    GENERATOR,    # Power generation
    OXYGEN,       # Oxygen production
    AIRLOCK       # Pressurized entrance
}
```

### Key Properties
```gdscript
var placed_structures: Array[BaseModule] = []
var structure_networks: Array[Dictionary] = []
var next_module_id: int = 0
var placement_snap_distance: float = 0.5
var connection_distance: float = 5.0
var min_placement_distance: float = 1.0
var collapse_threshold: float = 0.3  # Collapse below 30% integrity
var warning_threshold: float = 0.5   # Warn below 50% integrity
```

### Module Resource Costs
```gdscript
module_costs = {
    HABITAT:   {"metal": 50,  "plastic": 30},
    STORAGE:   {"metal": 30,  "plastic": 20},
    FABRICATOR: {"metal": 40, "electronics": 20},
    GENERATOR: {"metal": 60,  "electronics": 30},
    OXYGEN:    {"metal": 40,  "electronics": 25},
    AIRLOCK:   {"metal": 35,  "plastic": 25}
}
```

### Placement Methods

#### Direct Placement
```gdscript
# Place a structure directly (primary API)
var module = building_system.place_structure(
    structure_type: BaseModule.ModuleType,
    position: Vector3,
    rotation: Quaternion = Quaternion.IDENTITY
) -> BaseModule

# Removes structure
var success = building_system.remove_structure(structure: BaseModule) -> bool
```

#### Preview-Based Placement
```gdscript
# Start placement preview
var preview = building_system.start_placement(module_type: BaseModule.ModuleType) -> BaseModule

# Update preview position and validate
var valid = building_system.update_placement_preview(
    position: Vector3,
    rotation: Quaternion
) -> bool

# Confirm or cancel
var module = building_system.confirm_placement() -> BaseModule
building_system.cancel_placement() -> void
```

#### Validation
```gdscript
# Validate if placement is allowed
var is_valid = building_system.validate_placement(
    module: BaseModule,
    position: Vector3
) -> bool
```

### Module Management
```gdscript
# Get all placed structures
var all = building_system.get_placed_structures() -> Array[BaseModule]

# Find nearby structures
var nearby = building_system.get_nearby_structures(
    position: Vector3,
    radius: float
) -> Array[BaseModule]

# Get module by ID
var module = building_system.get_module_by_id(module_id: int) -> BaseModule

# Get modules in radius
var modules = building_system.get_modules_in_radius(
    position: Vector3,
    radius: float
) -> Array[BaseModule]
```

### Network Management
```gdscript
# Get network containing a module
var network = building_system.get_network_for_module(module: BaseModule) -> Dictionary

# Get all networks
var all_networks = building_system.get_all_networks() -> Array[Dictionary]
```

### Structural Integrity
```gdscript
# Calculate integrity for a module (0.0 to 1.0)
var integrity = building_system.calculate_structural_integrity(module: BaseModule) -> float

# Get cached integrity
var cached = building_system.get_module_integrity(module: BaseModule) -> float

# Get stress visualization data
var stress_data = building_system.get_stress_visualization_data() -> Array[Dictionary]

# Enable/disable stress visualization
building_system.enable_stress_visualization(enabled: bool) -> void
```

### Persistence
```gdscript
# Save system state
var state = building_system.save_state() -> Dictionary

# Load system state
building_system.load_state(data: Dictionary) -> void
```

### Usage Example
```gdscript
var building_system = get_node("BaseBuildingSystem")

# Connect to signals
building_system.module_placed.connect(_on_module_placed)
building_system.placement_invalid.connect(_on_placement_invalid)

# Place a habitat module
var habitat = building_system.place_structure(
    BaseModule.ModuleType.HABITAT,
    Vector3(10, 5, 0)
)

if habitat:
    print("Habitat placed at: %v" % habitat.global_position)

# Place a generator nearby for auto-connection
var generator = building_system.place_structure(
    BaseModule.ModuleType.GENERATOR,
    Vector3(12, 5, 0)  # Within 5 units, auto-connects
)

# Get all connected modules
var all_modules = building_system.get_placed_structures()
for module in all_modules:
    var integrity = building_system.get_module_integrity(module)
    print("Module %d: %d%% integrity" % [module.module_id, int(integrity * 100)])

# Find structures near player
var nearby = building_system.get_nearby_structures(player_position, 25.0)
```

---

## 5. Base Customization System

**Class:** `BaseCustomizationSystem`
**Location:** `scripts/planetary_survival/systems/base_customization_system.gd`
**Extends:** `Node`

### Purpose
Allows decorative item placement, surface painting, dynamic lighting, and material customization with VR optimization.

### Signals
```gdscript
signal decorative_item_placed(item: DecorativeItem, position: Vector3)
signal surface_painted(target: Node3D, color: Color)
signal lighting_updated(light: Light3D)
signal material_changed(target: Node3D, material_type: String)
```

### Key Properties
```gdscript
var decorative_items: Dictionary = {}  # int -> DecorativeItem
var next_item_id: int = 0
var painted_surfaces: Dictionary = {}  # Node3D -> Color
var current_paint_color: Color = Color.WHITE
var paint_brush_size: float = 1.0
var placed_lights: Array[Light3D] = []
var max_lights_per_area: int = 8  # VR limit
var shadow_quality: int = 1  # 0=off, 1=low, 2=medium, 3=high
var active_decorations: int = 0
var max_decorations: int = 500  # VR limit
var material_library: Dictionary = {}  # Material registry
```

### Available Materials
**Metal Materials:**
- `metal_smooth` - Smooth metal (roughness 0.1, metallic 0.9)
- `metal_rough` - Rough metal (roughness 0.8, metallic 0.3)
- `metal_brushed` - Brushed metal (roughness 0.4, metallic 0.6)

**Stone Materials:**
- `stone_smooth` - Smooth stone (roughness 0.2)
- `stone_rough` - Rough stone (roughness 0.8)
- `stone_polished` - Polished stone (roughness 0.05)

**Composite Materials:**
- `composite_matte` - Matte finish (roughness 0.7)
- `composite_glossy` - Glossy finish (roughness 0.2)

**Glass Materials:**
- `glass_clear` - Clear glass (transparency 0.95)
- `glass_frosted` - Frosted glass (transparency 0.5)

### Decorations

#### Placement
```gdscript
# Place a decorative item
var item = customization.place_decorative_item(
    item_type: String,
    position: Vector3,
    rotation: Quaternion
) -> DecorativeItem

# Remove decorative item
var success = customization.remove_decorative_item(item_id: int) -> bool
```

#### Status
```gdscript
# Get decoration count
var count = customization.get_decoration_count() -> int

# Set maximum decorations limit
customization.set_max_decorations(limit: int) -> void
```

### Painting System

#### Surface Painting
```gdscript
# Paint a surface with color
var success = customization.paint_surface(
    target: Node3D,
    color: Color,
    brush_size: float = 1.0
) -> bool

# Get color of surface
var color = customization.get_surface_color(target: Node3D) -> Color
```

#### Color Management
```gdscript
# Set current paint color
customization.set_paint_color(color: Color) -> void

# Set brush size (0.1 to 10.0)
customization.set_brush_size(size: float) -> void
```

### Lighting System

#### Light Placement
```gdscript
# Place a light source
var light = customization.place_light(
    light_type: String,  # "omni", "spot", or "directional"
    position: Vector3,
    color: Color = Color.WHITE,
    energy: float = 1.0
) -> Light3D

# Remove a light
var success = customization.remove_light(light: Light3D) -> bool
```

#### Shadow Management
```gdscript
# Set shadow quality (0-3: off, low, medium, high)
customization.set_shadow_quality(quality: int) -> void

# Get current shadow quality
var quality = customization.get_shadow_quality() -> int
```

#### Status
```gdscript
# Get light count
var count = customization.get_light_count() -> int
```

### Material System

#### Applying Materials
```gdscript
# Apply material to target
var success = customization.apply_material(
    target: Node3D,
    material_type: String,
    variation_index: int = 0
) -> bool
```

#### Material Info
```gdscript
# Get all available material types
var types = customization.get_material_types() -> Array[String]

# Get number of variations for a material type
var count = customization.get_material_variations(material_type: String) -> int
```

### Cleanup
```gdscript
# Clear all customizations
customization.clear_all_customizations() -> void

# Shutdown system
customization.shutdown() -> void
```

### DecorativeItem Class
```gdscript
class DecorativeItem:
    var item_id: int = -1
    var item_type: String = ""
    var position: Vector3 = Vector3.ZERO
    var rotation: Quaternion = Quaternion.IDENTITY
    var scale: Vector3 = Vector3.ONE
    var custom_data: Dictionary = {}
```

### Usage Example
```gdscript
var customization = get_node("BaseCustomizationSystem")

# Connect to signals
customization.decorative_item_placed.connect(_on_item_placed)
customization.lighting_updated.connect(_on_light_updated)

# Place a decorative item
var item = customization.place_decorative_item(
    "plant_pot",
    Vector3(5, 0, 5),
    Quaternion.IDENTITY
)

# Paint a surface (MeshInstance3D)
customization.set_paint_color(Color.RED)
customization.paint_surface(wall_mesh, Color.RED, 1.0)

# Place a light
var light = customization.place_light(
    "omni",
    Vector3(10, 3, 10),
    Color.WHITE,
    1.5
)

# Apply a material
customization.apply_material(wall_mesh, "metal_brushed", 0)

# Check performance
print("Decorations: %d/%d" % [customization.get_decoration_count(), 500])
print("Lights: %d" % customization.get_light_count())
```

---

## Inventory System

**Class:** `SurvivalInventory`
**Location:** `scripts/planetary_survival/core/inventory.gd`
**Extends:** `RefCounted`

### Purpose
Simple item storage and tracking system for managing collected resources.

### Key Properties
```gdscript
var items: Dictionary = {}  # item_type -> amount
var max_slots: int = 100    # Max unique item types
```

### Methods
```gdscript
# Check if inventory has item
var has = inventory.has_item(item_type: String, amount: int) -> bool

# Add item to inventory
var success = inventory.add_item(item_type: String, amount: int) -> bool

# Remove item from inventory
var success = inventory.remove_item(item_type: String, amount: int) -> bool

# Get item count
var count = inventory.get_item_count(item_type: String) -> int

# Clear all items
inventory.clear() -> void

# Serialize/deserialize
var data = inventory.to_dict() -> Dictionary
var inv = SurvivalInventory.from_dict(data) -> SurvivalInventory
```

### Usage Example
```gdscript
var inventory = SurvivalInventory.new()

# Add resources
inventory.add_item("iron", 50)
inventory.add_item("copper", 30)
inventory.add_item("crystal", 5)

# Check what we have
if inventory.has_item("iron", 40):
    print("Have enough iron!")
    inventory.remove_item("iron", 40)

# Get count
var iron_count = inventory.get_item_count("iron")
```

---

## Crafting System

**Class:** `CraftingSystem`
**Location:** `scripts/planetary_survival/crafting/crafting_system.gd`
**Extends:** `Node`

### Purpose
Manages crafting recipes and handles fabrication operations.

### Key Properties
```gdscript
var recipes: Dictionary = {}  # {recipe_id: CraftingRecipe}
```

### Methods
```gdscript
# Register a crafting recipe
crafting.register_recipe(recipe: CraftingRecipe) -> void

# Get a recipe by ID
var recipe = crafting.get_recipe(recipe_id: String) -> CraftingRecipe

# Check if recipe can be crafted
var can = crafting.can_craft(recipe_id: String, available_resources: Dictionary) -> bool

# Craft an item
var result = crafting.craft(
    recipe_id: String,
    available_resources: Dictionary
) -> Dictionary
```

### CraftingRecipe Structure
```gdscript
class CraftingRecipe:
    var recipe_id: String
    var output_item: String
    var output_quantity: int
    var input_resources: Dictionary  # resource_type -> quantity
```

### Usage Example
```gdscript
var crafting = get_node("CraftingSystem")

# Create and register a recipe
var recipe = CraftingRecipe.new()
recipe.recipe_id = "iron_plate"
recipe.output_item = "iron_plate"
recipe.output_quantity = 1
recipe.input_resources = {"iron": 5}
crafting.register_recipe(recipe)

# Check if we can craft
var available = {"iron": 20, "copper": 10}
if crafting.can_craft("iron_plate", available):
    var result = crafting.craft("iron_plate", available)
    if result["success"]:
        print("Crafted: %s x%d" % [result["output_item"], result["output_quantity"]])
```

---

## How to Access from Code

### Getting References in GDScript

#### Method 1: Direct Node Access
```gdscript
var life_support = get_node("LifeSupportSystem")
var power_grid = get_node("PowerGridSystem")
```

#### Method 2: From Parent Node
```gdscript
# If systems are children of a base manager node
var systems = get_parent()
var life_support = systems.get_node("LifeSupportSystem")
```

#### Method 3: Via Autoload (if configured)
```gdscript
# If systems are autoloads, access globally
var life_support = ResonanceEngine.life_support_system
```

### Common Integration Patterns

#### Life Support Integration
```gdscript
func _process(delta: float) -> void:
    var life_support = get_node("LifeSupportSystem")

    # Habitat modules produce oxygen
    if is_powered:
        life_support.produce_oxygen(0.5 * delta)

    # All modules consume oxygen if inhabited
    if has_inhabitants:
        life_support.consume_oxygen(0.1 * delta)
```

#### Power Grid Integration
```gdscript
func _ready() -> void:
    var power_grid = get_node("PowerGridSystem")

    match module_type:
        BaseModule.ModuleType.GENERATOR:
            power_grid.register_generator(100.0)
        BaseModule.ModuleType.HABITAT:
            power_grid.register_consumer(25.0)
```

#### Resource Gathering Integration
```gdscript
func gather_resources() -> void:
    var resource_system = get_node("ResourceSystem")
    var inventory = SurvivalInventory.new()

    # Find nearby resources
    var nearby = resource_system.scan_for_resources(position, 50.0)

    for signature in nearby:
        var gathered = resource_system.gather_resource(
            signature["node"],
            10
        )
        inventory.add_item(gathered["type"], gathered["amount"])
```

#### Base Building Integration
```gdscript
func place_base_structure(type: BaseModule.ModuleType, pos: Vector3) -> void:
    var building_system = get_node("BaseBuildingSystem")

    var structure = building_system.place_structure(type, pos)
    if structure:
        print("Structure placed successfully")

        # Auto-connect to power grid if generator
        if type == BaseModule.ModuleType.GENERATOR:
            var power_grid = get_node("PowerGridSystem")
            power_grid.register_generator(100.0)
```

---

## Signal Reference

### Life Support System Signals
```gdscript
# Emitted when oxygen level changes
life_support.oxygen_level_changed.connect(func(current, max):
    print("Oxygen: %d/%d" % [current, max])
)

# Emitted when temperature changes
life_support.temperature_changed.connect(func(temp):
    print("Temperature: %d°C" % temp)
)
```

### Power Grid System Signals
```gdscript
# Emitted when power generation or consumption changes
power_grid.power_changed.connect(func(current, max):
    print("Power: %d/%d W" % [current, max])
)
```

### Base Building System Signals
```gdscript
# Module placement/removal
building_system.module_placed.connect(func(module):
    print("Module %d placed" % module.module_id)
)

building_system.module_removed.connect(func(module):
    print("Module %d removed" % module.module_id)
)

# Placement validation
building_system.placement_invalid.connect(func(reason):
    print("Cannot place: %s" % reason)
)

# Network changes
building_system.network_updated.connect(func():
    print("Module networks updated")
)

# Structural integrity
building_system.structural_warning.connect(func(module, integrity):
    print("Module %d warning: %.1f%% integrity" % [module.module_id, integrity * 100])
)

building_system.structural_collapse.connect(func(modules):
    print("Collapse: %d modules destroyed" % modules.size())
)
```

### Base Customization System Signals
```gdscript
# Decoration placement
customization.decorative_item_placed.connect(func(item, position):
    print("Item %s placed at %v" % [item.item_type, position])
)

# Surface painting
customization.surface_painted.connect(func(target, color):
    print("Surface painted: RGB(%d, %d, %d)" % [
        int(color.r * 255),
        int(color.g * 255),
        int(color.b * 255)
    ])
)

# Lighting updates
customization.lighting_updated.connect(func(light):
    print("Light updated at %v" % light.position)
)

# Material changes
customization.material_changed.connect(func(target, material_type):
    print("Material changed to: %s" % material_type)
)
```

---

## Performance Considerations

### VR Optimization
- **Max decorations:** 500 items (VR limit)
- **Max lights per area:** 8 lights per 10-unit radius
- **Shadow quality:** Dynamically adjusts to maintain 90 FPS
- **LOD distances:** [10, 25, 50] units for decoration levels

### Physics/Performance Targets
- **Frame time budget:** 11.11ms for 90 FPS VR
- **Structural integrity checks:** Every 1.0 second
- **Shadow quality update:** Every 0.1 seconds

### Resource Limits
- **Max chunks:** 512 active voxel chunks
- **Max modules:** Limited by memory/performance
- **Inventory slots:** 100 unique item types per inventory

---

## Troubleshooting

### System Not Found
**Error:** `Invalid node name 'LifeSupportSystem'`
**Solution:** Verify systems are instantiated as children or configure as autoloads

### Signals Not Connecting
**Error:** `Unable to connect signal 'power_changed'`
**Solution:** Ensure system exists before connecting signals (use `_ready()` or `await get_tree().process_frame`)

### Module Placement Failing
**Error:** `placement_invalid: "Invalid placement location"`
**Causes:**
- Module overlaps existing structure
- Position is inside terrain
- Insufficient resources in inventory
- Placement distance too close (min 1.0 unit)

### Structural Collapse
**Causes:**
- Module integrity below 30%
- No ground support path
- Too many modules relying on support
- Load bearing exceeded
**Solution:** Reinforce with additional support structures or add generators/oxygen producers

### Performance Issues
- Reduce shadow quality: `customization.set_shadow_quality(0)`
- Reduce decoration count: `customization.set_max_decorations(250)`
- Reduce lights: Remove unused lights with `customization.remove_light()`

---

## Save/Load Pattern

### Saving System State
```gdscript
func save_base_state() -> Dictionary:
    var life_support = get_node("LifeSupportSystem")
    var power_grid = get_node("PowerGridSystem")
    var building_system = get_node("BaseBuildingSystem")
    var resource_system = get_node("ResourceSystem")

    return {
        "building": building_system.save_state(),
        "resources": resource_system.save_state(),
        "oxygen": life_support.oxygen_level,
        "temperature": life_support.temperature,
        "generation": power_grid.total_generation,
        "consumption": power_grid.total_consumption
    }
```

### Loading System State
```gdscript
func load_base_state(data: Dictionary) -> void:
    var building_system = get_node("BaseBuildingSystem")
    var resource_system = get_node("ResourceSystem")
    var life_support = get_node("LifeSupportSystem")
    var power_grid = get_node("PowerGridSystem")

    building_system.load_state(data.get("building", {}))
    resource_system.load_state(data.get("resources", {}))
    life_support.oxygen_level = data.get("oxygen", 100.0)
    life_support.set_temperature(data.get("temperature", 20.0))
```

---

## Quick Links

- **API Server Endpoints:** See `ROUTER_ACTIVATION_PLAN.md` for HTTP API documentation
- **Full Architecture:** See `CLAUDE.md` for complete system overview
- **Code Quality Report:** See `CODE_QUALITY_REPORT.md` for known issues and fixes
- **Development Guide:** See `docs/current/guides/DEVELOPMENT_WORKFLOW.md` for workflow

---

**This guide is maintained as part of the SpaceTime VR project documentation.**
