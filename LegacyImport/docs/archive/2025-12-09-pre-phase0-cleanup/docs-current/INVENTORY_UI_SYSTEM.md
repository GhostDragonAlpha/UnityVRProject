# Inventory UI System Documentation

## Overview
The VR-friendly 3D Inventory Management System provides an immersive inventory interface for the SpaceTime VR project. The system features a 3D grid-based layout with VR controller interaction, gesture recognition, and HTTP API integration for external control and testing.

## Architecture

### Components

#### 1. Inventory3DUI (`scripts/ui/inventory_3d_ui.gd`)
The main inventory UI controller that manages the 3D grid display, VR interactions, and user input.

**Key Features:**
- 10x5 grid layout (50 slots) positioned 1m in front of player
- VR controller raycast-based interaction
- Drag-and-drop item movement with visual feedback
- Gesture recognition for quick actions
- Integration with core Inventory system
- HTTP API support for remote control

**Configuration:**
```gdscript
@export var grid_size: Vector2i = Vector2i(10, 5)
@export var slot_size: float = 0.1  # 10cm per slot
@export var slot_spacing: float = 0.01  # 1cm spacing
@export var distance_from_player: float = 1.0  # 1m from player
@export var panel_color: Color = Color(0.1, 0.1, 0.15, 0.9)
```

#### 2. InventoryItemSlot (`scripts/ui/inventory_item_slot.gd`)
Individual slot visualization with support for:
- 3D item models/icons
- Quantity badges
- Durability bars
- Rarity borders with emission effects
- Hover and grab states with visual feedback

#### 3. GestureTracker (Inner class in Inventory3DUI)
Recognizes VR controller gestures:
- **Circular motion** → Sort inventory
- **Horizontal swipe** → Quick transfer
- **Pinch motion** → Quick stack

#### 4. InventoryEndpoints (`addons/godot_debug_connection/inventory_endpoints.gd`)
HTTP API endpoint handlers for external control and automated testing.

## VR Interaction

### Controller Raycasting
Each VR controller has a raycast (10m range) that detects inventory slots:
- Hover detection with visual highlighting
- Collision on Layer 1 (inventory UI layer)
- Real-time position tracking for gesture recognition

### Interaction Flow

1. **Hover Slot**
   - Raycast hits slot collision body
   - Slot highlight activates (cyan glow + pulse animation)
   - Tooltip displayed (future enhancement)

2. **Grab Item**
   - Press trigger/grip button while hovering
   - Item becomes semi-transparent
   - Gesture tracking starts
   - Visual feedback on source slot

3. **Move Item**
   - Move controller while holding trigger
   - Gesture tracker analyzes motion pattern
   - Target slot highlights when hovered

4. **Release Item**
   - Release trigger over target slot
   - Item moves/swaps/stacks based on target
   - Visual feedback and sound (future)
   - Gesture tracking stops

### Gesture Recognition

#### Sort Gesture (Circular Motion)
- **Pattern:** Circular controller movement
- **Detection:** Low radius variance, minimum 20 position samples
- **Action:** Sorts inventory alphabetically
- **Minimum radius:** 0.1m

#### Quick Transfer Gesture (Horizontal Swipe)
- **Pattern:** Fast horizontal controller movement
- **Detection:** Horizontal distance > 0.3m, horizontal > 2x vertical
- **Action:** Transfers item to external container (placeholder)

#### Quick Stack Gesture (Pinch Motion)
- **Pattern:** Inward compression movement
- **Detection:** Movement range decreases over time (late range < 50% early range)
- **Action:** Stacks all matching items together

## Item Management

### Item Data Structure
```gdscript
{
    "item_id": "iron_ore",
    "quantity": 42,
    "durability": 0.85,  # Optional, 0.0-1.0
    "rarity": "rare"     # Optional: common/uncommon/rare/epic/legendary
}
```

### Slot Operations

#### Move Item
Moves item from one empty slot to another:
```gdscript
_move_item(from_index: int, to_index: int)
```

#### Swap Items
Exchanges items between two occupied slots:
```gdscript
_swap_items(slot_a_index: int, slot_b_index: int)
```

#### Stack Items
Combines matching items (same item_id):
```gdscript
_stack_items(from_index: int, to_index: int)
```

### Automatic Stacking
When releasing an item onto a slot with the same item type:
- Quantities automatically combine
- Source slot clears
- Target slot updates with total quantity

## Visual Feedback

### Slot States

| State | Visual | Description |
|-------|--------|-------------|
| Empty | Transparent blue | Default empty slot |
| Occupied | Green tint | Contains item |
| Hovered | Cyan glow + pulse | Controller pointing at slot |
| Grabbed | Semi-transparent | Item being moved |
| Disabled | Gray, low opacity | Slot not available |

### Rarity Colors
- **Common:** White
- **Uncommon:** Green
- **Rare:** Blue
- **Epic:** Purple
- **Legendary:** Orange

Rarity borders have emission effects for enhanced visibility in VR.

### Durability Bar
- **Green:** > 50% durability
- **Yellow:** 25-50% durability
- **Red:** < 25% durability

Positioned at bottom of slot, scales horizontally based on durability percentage.

## Integration

### Scene Setup

1. **Add to VR Main Scene:**
```gdscript
# In vr_main.tscn or equivalent
var inventory_scene = preload("res://scenes/ui/inventory_panel.tscn")
var inventory_ui = inventory_scene.instantiate()
add_child(inventory_ui)
```

2. **Initialize System:**
```gdscript
# Get player and inventory references
var player = $XROrigin3D
var inventory = $Player/Inventory  # Or wherever Inventory is located

# Initialize
inventory_ui.initialize(player, inventory)
```

3. **Open/Close Inventory:**
```gdscript
# Via button press
func _on_menu_button_pressed():
    inventory_ui.toggle_inventory()

# Or programmatically
inventory_ui.open_inventory()
inventory_ui.close_inventory()
```

### VR Controller Setup
The system automatically connects to VR controllers from `VRManager`:
- Searches for `/root/ResonanceEngine/VRManager`
- Gets left/right controller references
- Creates raycasts on each controller
- Connects button signals

### Inventory System Connection
Requires a `Inventory` instance (from `scripts/player/inventory.gd`):
```gdscript
var inventory = Inventory.new()
inventory.max_total_capacity = 1000
inventory.max_per_item_capacity = 100
inventory_ui.initialize(player, inventory)
```

## HTTP API

### Integration
See `addons/godot_debug_connection/INVENTORY_INTEGRATION.md` for complete integration instructions.

**Quick Setup:**
1. Add import to `godot_bridge.gd`:
   ```gdscript
   const InventoryEndpoints = preload("res://addons/godot_debug_connection/inventory_endpoints.gd")
   ```

2. Add route handler:
   ```gdscript
   elif path.begins_with("/inventory/"):
       InventoryEndpoints.handle_inventory_endpoint(self, client, method, path, body)
   ```

### Available Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/inventory/state` | Get inventory state |
| POST | `/inventory/open` | Open inventory UI |
| POST | `/inventory/close` | Close inventory UI |
| POST | `/inventory/toggle` | Toggle inventory |
| POST | `/inventory/sort` | Sort items alphabetically |
| POST | `/inventory/quick_stack` | Stack matching items |
| POST | `/inventory/add` | Add item (requires `item_id`, optional `quantity`) |
| POST | `/inventory/remove` | Remove item (requires `item_id`, optional `quantity`) |
| POST | `/inventory/move` | Move item (requires `from_slot`, `to_slot`) |

### Example Usage

```bash
# Get current inventory state
curl http://127.0.0.1:8080/inventory/state

# Open inventory
curl -X POST http://127.0.0.1:8080/inventory/open

# Add 10 iron ore
curl -X POST http://127.0.0.1:8080/inventory/add \
  -H "Content-Type: application/json" \
  -d '{"item_id": "iron_ore", "quantity": 10}'

# Sort inventory
curl -X POST http://127.0.0.1:8080/inventory/sort

# Move item from slot 0 to slot 5
curl -X POST http://127.0.0.1:8080/inventory/move \
  -H "Content-Type: application/json" \
  -d '{"from_slot": 0, "to_slot": 5}'
```

## Performance Considerations

### Optimization Strategies
1. **Slot Pooling:** Slots are created once at startup, reused for different items
2. **Raycast Culling:** Raycasts disabled when inventory closed
3. **Gesture Sampling:** Limited to 30 position samples (0.5 sec at 60fps)
4. **Material Reuse:** Standard materials shared across similar slots
5. **Update on Demand:** Slots only refresh when inventory changes

### VR Performance
- Target: 90 FPS on VR headsets
- Tested grid size: 10x5 (50 slots)
- Mesh instances: ~150 total (background, slots, items)
- Collision bodies: 50 (one per slot)

## Signals

### Inventory3DUI Signals
```gdscript
signal inventory_opened
signal inventory_closed
signal item_selected(item_data: Dictionary)
signal item_moved(from_slot: int, to_slot: int)
signal item_dropped(item_data: Dictionary)
signal gesture_recognized(gesture_type: String)
```

### Usage Example
```gdscript
inventory_ui.inventory_opened.connect(_on_inventory_opened)
inventory_ui.item_moved.connect(_on_item_moved)
inventory_ui.gesture_recognized.connect(_on_gesture)

func _on_item_moved(from_slot: int, to_slot: int):
    print("Item moved from slot %d to slot %d" % [from_slot, to_slot])

func _on_gesture(gesture_type: String):
    print("Gesture recognized: %s" % gesture_type)
```

## Testing

### Manual Testing in VR
1. Start Godot with debug flags:
   ```bash
   godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
   ```

2. Put on VR headset and launch scene

3. Open inventory (via button or HTTP API)

4. Test interactions:
   - Point at slots to verify hover detection
   - Grab items with trigger button
   - Move items between slots
   - Perform gestures (circular, swipe, pinch)

### Automated Testing via HTTP API
```python
import requests

base_url = "http://127.0.0.1:8080"

# Test inventory state
response = requests.get(f"{base_url}/inventory/state")
print(response.json())

# Add test items
for i in range(5):
    requests.post(f"{base_url}/inventory/add",
                  json={"item_id": f"item_{i}", "quantity": 10})

# Sort
requests.post(f"{base_url}/inventory/sort")

# Verify state
response = requests.get(f"{base_url}/inventory/state")
state = response.json()
assert len(state["items"]) == 5
```

### Unit Testing (GDScript)
Create test script in `tests/unit/test_inventory_3d_ui.gd`:
```gdscript
extends GdUnitTestSuite

func test_slot_creation():
    var inventory_ui = Inventory3DUI.new()
    add_child(inventory_ui)

    assert_that(inventory_ui.slot_grid.size()).is_equal(50)

func test_item_move():
    var inventory_ui = Inventory3DUI.new()
    add_child(inventory_ui)

    # Set up test data
    var item_data = {"item_id": "test_item", "quantity": 1}
    inventory_ui.slot_grid[0].set_item(item_data)

    # Move item
    inventory_ui._move_item(0, 5)

    # Verify
    assert_that(inventory_ui.slot_grid[0].is_empty()).is_true()
    assert_that(inventory_ui.slot_grid[5].is_empty()).is_false()
```

## Troubleshooting

### Common Issues

#### Inventory UI Not Appearing
**Problem:** Inventory3DUI not visible in VR
**Solutions:**
- Verify `visible = true` after opening
- Check `distance_from_player` (should be 1.0m)
- Ensure player reference is set correctly
- Verify scene is added to scene tree

#### Controller Raycasts Not Working
**Problem:** Cannot select slots with controllers
**Solutions:**
- Verify VRManager is initialized
- Check collision layers (UI on layer 1)
- Enable raycasts when inventory opens
- Verify controller references are valid

#### Items Not Stacking
**Problem:** Items with same ID don't combine
**Solutions:**
- Verify `item_id` matches exactly (case-sensitive)
- Check that target slot has same item
- Ensure both items have `quantity` field

#### Gestures Not Recognized
**Problem:** Gesture tracking not detecting motions
**Solutions:**
- Verify gesture tracker is created
- Check minimum position samples (need 10-30)
- Perform gestures more deliberately
- Check gesture thresholds in code

### Debug Logging
Enable debug logging to diagnose issues:
```gdscript
# In ResonanceEngine
ResonanceEngine.set_log_level(LogLevel.DEBUG)

# Check inventory UI logs
# Logs appear with [Inventory3DUI] prefix
```

## Future Enhancements

### Planned Features
1. **Item Tooltips:** Hover to see detailed item information
2. **Sound Effects:** Audio feedback for grab/release/sort
3. **Haptic Feedback:** Controller vibration for interactions
4. **Item Categories:** Filter/sort by category
5. **Quick Transfer:** Transfer to external containers (chests, etc.)
6. **Item Icons:** Load custom 3D models per item type
7. **Multi-select:** Select multiple items with two-handed gesture
8. **Voice Commands:** "Sort inventory", "Stack items"
9. **Customizable Grid:** Variable grid size per player preference
10. **Item Comparison:** Compare two items side-by-side

### Performance Improvements
1. **LOD System:** Reduce detail when inventory far from player
2. **Occlusion Culling:** Hide slots behind other geometry
3. **Lazy Loading:** Create slots on-demand instead of all at startup
4. **Mesh Batching:** Combine slot meshes into fewer draw calls

## File Locations

```
C:/godot/
├── scripts/ui/
│   ├── inventory_3d_ui.gd          # Main inventory UI system
│   └── inventory_item_slot.gd       # Individual slot component
├── scenes/ui/
│   └── inventory_panel.tscn         # Inventory scene file
├── addons/godot_debug_connection/
│   ├── inventory_endpoints.gd       # HTTP API handlers
│   └── INVENTORY_INTEGRATION.md     # API integration guide
└── INVENTORY_UI_SYSTEM.md           # This documentation
```

## Credits
Implemented as part of the SpaceTime VR project's player interaction systems (Task 6.5).

## License
Part of the SpaceTime VR project. See main project LICENSE for details.
