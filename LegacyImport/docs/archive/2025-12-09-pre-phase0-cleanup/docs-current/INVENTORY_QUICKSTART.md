# Inventory UI System - Quick Start Guide

## 30-Second Setup

### 1. Add to Your Scene
```gdscript
# In your VR main scene (e.g., vr_main.gd)
@onready var inventory_ui = preload("res://scenes/ui/inventory_panel.tscn").instantiate()

func _ready():
    add_child(inventory_ui)

    # Get player and inventory references
    var player = $XROrigin3D
    var inventory = Inventory.new()  # Or get existing inventory

    # Initialize
    inventory_ui.initialize(player, inventory)
```

### 2. Integrate HTTP API
Add to `addons/godot_debug_connection/godot_bridge.gd`:

```gdscript
# At top of file
const InventoryEndpoints = preload("res://addons/godot_debug_connection/inventory_endpoints.gd")

# In _route_request() function (around line 280)
elif path.begins_with("/inventory/"):
    InventoryEndpoints.handle_inventory_endpoint(self, client, method, path, body)
```

### 3. Test It
```bash
# Open inventory
curl -X POST http://127.0.0.1:8080/inventory/open

# Add items
curl -X POST http://127.0.0.1:8080/inventory/add \
  -H "Content-Type: application/json" \
  -d '{"item_id": "iron_ore", "quantity": 10}'

# Check state
curl http://127.0.0.1:8080/inventory/state
```

## VR Controls

| Action | Controller Input |
|--------|-----------------|
| Open/Close | Menu button (configured in your input map) |
| Grab Item | Trigger/Grip while hovering |
| Move Item | Hold trigger and move to target slot |
| Sort | Circular gesture while holding item |
| Quick Stack | Pinch gesture while holding item |

## Files Created

```
C:/godot/
├── scripts/ui/
│   └── inventory_3d_ui.gd          # Main system (790 lines)
├── scenes/ui/
│   └── inventory_panel.tscn         # Scene file
├── addons/godot_debug_connection/
│   ├── inventory_endpoints.gd       # HTTP API (280 lines)
│   └── INVENTORY_INTEGRATION.md     # Integration guide
├── examples/
│   └── inventory_demo.py            # Python demo script
├── tests/
│   └── test_inventory_ui_integration.py  # Integration tests
├── INVENTORY_UI_SYSTEM.md           # Full documentation
└── INVENTORY_QUICKSTART.md          # This file
```

## Common Use Cases

### Open Inventory via Code
```gdscript
inventory_ui.open_inventory()
```

### Add Items Programmatically
```gdscript
# Via inventory system directly
inventory.add_item("iron_ore", 25)

# Via HTTP API
curl -X POST http://127.0.0.1:8080/inventory/add \
  -d '{"item_id": "iron_ore", "quantity": 25}'
```

### Listen for Inventory Events
```gdscript
inventory_ui.item_moved.connect(_on_item_moved)
inventory_ui.gesture_recognized.connect(_on_gesture)

func _on_item_moved(from_slot: int, to_slot: int):
    print("Item moved from %d to %d" % [from_slot, to_slot])
```

### Run Python Demo
```bash
python examples/inventory_demo.py
```

### Run Integration Tests
```bash
pip install pytest
pytest tests/test_inventory_ui_integration.py -v
```

## Configuration

Edit `scenes/ui/inventory_panel.tscn` or modify in code:

```gdscript
inventory_ui.grid_size = Vector2i(12, 6)  # Bigger grid
inventory_ui.slot_size = 0.15             # Larger slots
inventory_ui.distance_from_player = 1.5   # Further from player
inventory_ui.panel_color = Color(0.2, 0.1, 0.3, 0.95)  # Purple tint
```

## Troubleshooting

**Inventory not visible?**
- Ensure `inventory_ui.initialize(player, inventory)` was called
- Check `distance_from_player` (default 1.0m)
- Verify player reference is valid

**Can't grab items?**
- VRManager must be initialized first
- Controllers must be connected
- Check collision layer (should be layer 1)

**HTTP API not working?**
- Verify GodotBridge integration (see step 2)
- Check Godot is running with debug flags
- Test with: `curl http://127.0.0.1:8080/status`

## Next Steps

1. Read full documentation: `INVENTORY_UI_SYSTEM.md`
2. Customize visuals in `inventory_item_slot.gd`
3. Add custom item models/icons
4. Implement item tooltips
5. Add sound effects and haptic feedback

## Support

See full documentation for:
- Complete API reference
- Gesture system details
- Performance optimization
- Testing strategies
- Future enhancements

---

**Implementation:** Task 6.5 - VR Inventory Management System
**Files:** 7 new files created, fully documented
**Lines of Code:** ~1500 lines total
