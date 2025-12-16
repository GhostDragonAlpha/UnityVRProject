# Power Grid HUD - Quick Integration Guide

## Installation

### 1. Add HTTP API Routing

Edit `C:/godot/addons/godot_debug_connection/godot_bridge.gd`:

```gdscript
# Find the _route_request function (around line 225)
# Add this BEFORE the final 'else' clause:

	# Power grid HUD endpoints
	elif path.begins_with("/powergrid/"):
		var PowerGridAPI = load("res://addons/godot_debug_connection/power_grid_api.gd")
		PowerGridAPI.handle_powergrid_endpoint(self, client, method, path, body)
```

### 2. Add to Your Main Scene

Option A - Direct instantiation:
```gdscript
# In your main scene script
var power_grid_hud = preload("res://scenes/ui/power_grid_panel.tscn").instantiate()

func _ready():
    add_child(power_grid_hud)
```

Option B - Add via editor:
1. Open your main scene in Godot editor
2. Add Node > User Interface > Control
3. Instance Child Scene > Select `power_grid_panel.tscn`
4. Position as desired (default is bottom-left)

### 3. Connect to Base Building System

```gdscript
# In your BaseBuildingSystem or PowerManager
signal power_grid_updated(grid_data: Dictionary)

func _update_power_statistics():
    var grid_data = {
        "production": _calculate_total_production(),
        "consumption": _calculate_total_consumption(),
        "storage": battery_current_charge,
        "storage_capacity": battery_max_capacity,
        "storage_percent": (battery_current_charge / battery_max_capacity) * 100.0,
        "efficiency": _calculate_system_efficiency(),
        "connections": _get_active_connections(),
        "nodes": _get_grid_nodes()
    }
    power_grid_updated.emit(grid_data)

# In your main scene or controller
func _on_power_grid_updated(grid_data: Dictionary):
    power_grid_hud.set_grid_data(grid_data)
```

## Quick Test

### Test in Godot Editor

1. Open `scenes/ui/test_power_grid_hud.tscn`
2. Press F5 to run scene
3. Use sliders to adjust values
4. Click preset buttons for scenarios
5. Observe HUD updates in real-time

### Test via Python

```bash
# Make sure Godot is running with debug services
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005

# Run test client
python examples/power_grid_test_client.py
```

### Test via HTTP

```bash
# Get status
curl http://127.0.0.1:8080/powergrid/status

# Update grid data
curl -X POST http://127.0.0.1:8080/powergrid/update \
  -H "Content-Type: application/json" \
  -d '{"production": 150, "consumption": 100, "storage_percent": 75}'

# Simulate power surge
curl -X POST http://127.0.0.1:8080/powergrid/simulate/surge \
  -H "Content-Type: application/json" \
  -d '{"power_delta": 50}'

# Reset
curl -X POST http://127.0.0.1:8080/powergrid/reset
```

## Usage Examples

### Basic Update

```gdscript
# Simple update
power_grid_hud.set_grid_data({
    "production": 150.0,
    "consumption": 100.0,
    "storage_percent": 75.0,
    "efficiency": 0.95
})
```

### With Network Visualization

```gdscript
# Update with 3D grid network
power_grid_hud.set_grid_data({
    "production": 200.0,
    "consumption": 150.0,
    "storage_percent": 80.0,
    "efficiency": 0.95,
    "nodes": {
        "solar_panel_1": {
            "position": Vector3(10, 0, 10),
            "power": 100.0,
            "type": "producer"
        },
        "habitat_module": {
            "position": Vector3(0, 0, 0),
            "power": -50.0,
            "type": "consumer"
        }
    },
    "connections": [
        {
            "from": "solar_panel_1",
            "to": "habitat_module",
            "power_flow": 50.0
        }
    ]
})
```

### Testing Scenarios

```gdscript
# Test power shortage warning
power_grid_hud.simulate_power_surge(-80.0)  # Remove 80 kW

# Test storage drain
power_grid_hud.simulate_storage_drain(-30.0)  # Drain 30%

# Reset to clean state
power_grid_hud.reset_to_defaults()
```

## Configuration

### Customize Thresholds

Edit `scripts/ui/power_grid_hud.gd`:

```gdscript
# Line 30-32
const CRITICAL_STORAGE_THRESHOLD: float = 20.0  # Change to 15.0 for stricter
const LOW_STORAGE_THRESHOLD: float = 40.0       # Change to 50.0 for earlier warning
const MAX_POWER_DISPLAY: float = 1000.0         # Increase if you have higher power
```

### Customize Colors

```gdscript
# Line 52-57
const COLOR_PRODUCTION: Color = Color(0.2, 0.8, 0.2)   # Green
const COLOR_CONSUMPTION: Color = Color(0.8, 0.2, 0.2)  # Red
const COLOR_BALANCED: Color = Color(0.2, 0.6, 0.8)     # Blue
const COLOR_WARNING: Color = Color(0.9, 0.6, 0.1)      # Orange
const COLOR_CRITICAL: Color = Color(0.9, 0.1, 0.1)     # Bright Red
```

### Adjust Update Rate

```gdscript
# Line 27-28
const UPDATE_INTERVAL: float = 0.1           # Update every 100ms (increase for less frequent)
const WARNING_FLASH_INTERVAL: float = 0.5    # Flash every 500ms
```

## Troubleshooting

### HUD doesn't show
- Verify scene is added as child to a CanvasLayer or Control node
- Check z-index if other UI elements overlap
- Ensure visibility is enabled

### No HTTP endpoints
- Add routing code to godot_bridge.gd (see step 1)
- Restart Godot after adding routing
- Verify with: `curl http://127.0.0.1:8080/powergrid/status`

### 3D visualization blank
- Check that node positions are reasonable (not too far apart)
- Verify connections reference valid node IDs
- Ensure SubViewport is rendering (check render_target_update_mode)

### Warnings don't trigger
- Verify storage_percent is being set (not just storage)
- Check threshold constants match your expected values
- Ensure warning_panel node reference is valid

## Next Steps

1. **Integrate with base building** - Connect to your power system
2. **Add historical data** - Track power trends over time
3. **Tutorial integration** - Teach players power management
4. **Mission objectives** - Create power-based challenges
5. **Multiplayer support** - Share grid between players

## Files Created

```
C:/godot/
├── scripts/ui/
│   └── power_grid_hud.gd                    # Main HUD controller (544 lines)
├── scenes/ui/
│   ├── power_grid_panel.tscn                # UI scene definition
│   ├── test_power_grid_hud.tscn             # Test scene
│   └── test_power_grid_controller.gd        # Test controller (186 lines)
├── addons/godot_debug_connection/
│   └── power_grid_api.gd                    # HTTP API endpoints (186 lines)
├── examples/
│   └── power_grid_test_client.py            # Python test client (437 lines)
├── POWER_GRID_HUD.md                        # Full documentation
└── POWER_GRID_HUD_INTEGRATION.md            # This file
```

## API Reference

### Methods

```gdscript
# Set grid data
func set_grid_data(data: Dictionary) -> void

# Get current data
func get_grid_data() -> Dictionary

# Simulate conditions
func simulate_power_surge(power_delta: float) -> void
func simulate_storage_drain(percent_delta: float) -> void

# Reset
func reset_to_defaults() -> void

# Visualization
func visualize_grid_connections(grid_data: Dictionary) -> void
```

### HTTP Endpoints

- `GET /powergrid/status` - Get current status
- `POST /powergrid/update` - Update grid data
- `POST /powergrid/simulate/surge` - Simulate power change
- `POST /powergrid/simulate/drain` - Simulate storage drain
- `POST /powergrid/reset` - Reset to defaults
- `POST /powergrid/visualize` - Update visualization

## Support

For issues or questions:
1. Check `POWER_GRID_HUD.md` for detailed documentation
2. Review test scene for usage examples
3. Run test client for API validation
4. Check console for error messages

---

**Status:** Ready for integration
**Version:** 1.0.0
**Last Updated:** 2025-12-02
