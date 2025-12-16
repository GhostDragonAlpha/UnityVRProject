# Power Grid HUD - Quick Reference Card

## Installation (1 minute)

```gdscript
// 1. Add to godot_bridge.gd _route_request():
elif path.begins_with("/powergrid/"):
    var PowerGridAPI = load("res://addons/godot_debug_connection/power_grid_api.gd")
    PowerGridAPI.handle_powergrid_endpoint(self, client, method, path, body)

// 2. Add to your scene:
var hud = preload("res://scenes/ui/power_grid_panel.tscn").instantiate()
add_child(hud)

// 3. Update it:
hud.set_grid_data({"production": 150, "consumption": 100, "storage_percent": 75})
```

## Basic Usage

```gdscript
# Simple update
power_grid_hud.set_grid_data({
    "production": 150.0,
    "consumption": 100.0,
    "storage_percent": 75.0,
    "efficiency": 0.95
})

# With 3D network
power_grid_hud.set_grid_data({
    "production": 200.0,
    "nodes": {
        "solar_1": {"position": Vector3(10, 0, 10), "power": 100, "type": "producer"}
    },
    "connections": [{"from": "solar_1", "to": "habitat", "power_flow": 50}]
})

# Testing
power_grid_hud.simulate_power_surge(-50.0)  # -50 kW
power_grid_hud.simulate_storage_drain(-20.0)  # -20%
power_grid_hud.reset_to_defaults()
```

## HTTP API

```bash
# Status
curl http://127.0.0.1:8080/powergrid/status

# Update
curl -X POST http://127.0.0.1:8080/powergrid/update \
  -H "Content-Type: application/json" \
  -d '{"production": 150, "consumption": 100, "storage_percent": 75}'

# Test surge
curl -X POST http://127.0.0.1:8080/powergrid/simulate/surge \
  -d '{"power_delta": 50}'

# Test drain
curl -X POST http://127.0.0.1:8080/powergrid/simulate/drain \
  -d '{"percent_delta": -20}'

# Reset
curl -X POST http://127.0.0.1:8080/powergrid/reset
```

## Python Client

```python
from examples.power_grid_test_client import PowerGridTestClient

client = PowerGridTestClient()

# Get status
status = client.get_status()

# Update
client.update_grid_data({"production": 200, "consumption": 150})

# Simulate
client.simulate_surge(50.0)
client.simulate_drain(-20.0)

# Reset
client.reset()
```

## Data Structure

```gdscript
{
    "production": 150.0,          # kW
    "consumption": 100.0,         # kW
    "storage_percent": 75.0,      # %
    "efficiency": 0.95,           # 0.0-1.0
    "nodes": {                    # Optional
        "node_id": {
            "position": Vector3(x, y, z),
            "power": 50.0,        # +/- kW
            "type": "producer"    # or "consumer", "storage"
        }
    },
    "connections": [              # Optional
        {"from": "id1", "to": "id2", "power_flow": 50.0}
    ]
}
```

## Thresholds

```gdscript
CRITICAL_STORAGE: 20%   # Red + flash + audio
LOW_STORAGE: 40%        # Orange + static
MAX_POWER: 1000 kW      # Progress bar max
```

## Colors

- **Green** (0.2, 0.8, 0.2) = Production/healthy
- **Red** (0.8, 0.2, 0.2) = Consumption/deficit
- **Blue** (0.2, 0.6, 0.8) = Balanced
- **Orange** (0.9, 0.6, 0.1) = Warning
- **Bright Red** (0.9, 0.1, 0.1) = Critical

## Testing

```bash
# Test scene
Open: scenes/ui/test_power_grid_hud.tscn
Press: F5

# Python tests
python examples/power_grid_test_client.py

# Usage example
See: examples/power_grid_usage_example.gd
```

## Files

```
scripts/ui/power_grid_hud.gd          # Main controller
scenes/ui/power_grid_panel.tscn       # UI scene
addons/../power_grid_api.gd           # HTTP API
examples/power_grid_test_client.py    # Test client
```

## Docs

- **Full docs:** POWER_GRID_HUD.md
- **Integration:** POWER_GRID_HUD_INTEGRATION.md
- **Summary:** POWER_GRID_HUD_SUMMARY.md

## Troubleshooting

**HUD not visible?**
- Check scene is added to tree
- Verify z-index ordering

**No API?**
- Add routing to godot_bridge.gd
- Restart Godot

**Warnings not working?**
- Check storage_percent is set
- Verify threshold values

**3D blank?**
- Check node positions valid
- Verify SubViewport rendering

---

**Ready to use!** See full docs for details.
