# Power Grid HUD System

Professional power management interface for SpaceTime VR with real-time monitoring, 3D visualization, and HTTP API integration.

## Overview

The Power Grid HUD provides comprehensive monitoring and control of the base power system, featuring:

- **Real-time statistics display** - Production, consumption, balance, storage, and efficiency
- **Visual progress bars** - Color-coded power distribution visualization
- **Warning system** - Automated alerts for critical power conditions
- **3D network visualization** - Interactive grid topology with power flow animation
- **HTTP API integration** - Remote control and testing capabilities
- **VR-optimized UI** - Designed for comfortable viewing in VR headsets

## File Structure

```
C:/godot/
├── scripts/ui/
│   └── power_grid_hud.gd                    # Main HUD controller
├── scenes/ui/
│   └── power_grid_panel.tscn                # UI scene definition
├── addons/godot_debug_connection/
│   └── power_grid_api.gd                    # HTTP API endpoints
└── examples/
    └── power_grid_test_client.py            # Python test client
```

## Components

### 1. Power Statistics Panel

Displays real-time power metrics with color-coded indicators:

```gdscript
# Update statistics
func update_stats(grid_data: Dictionary):
    production_label.text = "Production: %.1f kW" % grid_data.production
    consumption_label.text = "Consumption: %.1f kW" % grid_data.consumption
    balance_label.text = "Balance: %+.1f kW" % (production - consumption)
    storage_label.text = "Storage: %.1f%%" % grid_data.storage_percent
    efficiency_label.text = "Efficiency: %.1f%%" % (grid_data.efficiency * 100)
```

**Metrics:**
- **Production** - Total power generation (kW)
- **Consumption** - Total power usage (kW)
- **Balance** - Net power (+surplus / -deficit)
- **Storage** - Battery capacity remaining (%)
- **Efficiency** - System efficiency rating (%)

### 2. Visual Progress Bars

Color-coded bars with dynamic scaling:

```gdscript
func update_progress_bars(grid_data: Dictionary):
    # Production bar - green to yellow gradient
    production_bar.value = min(production, MAX_POWER_DISPLAY)
    production_bar.modulate = COLOR_PRODUCTION.lerp(COLOR_WARNING, production_ratio)

    # Consumption bar - red intensity based on load
    consumption_bar.value = min(consumption, MAX_POWER_DISPLAY)
    consumption_bar.modulate = COLOR_CONSUMPTION.lerp(COLOR_CRITICAL, consumption_ratio)

    # Storage bar - critical threshold with pulse effect
    storage_bar.value = storage_percent
    if storage_percent < CRITICAL_STORAGE_THRESHOLD:
        storage_bar.modulate = COLOR_CRITICAL
        # Pulse animation when critically low
```

**Color Codes:**
- **Green** (0.2, 0.8, 0.2) - Production/healthy state
- **Red** (0.8, 0.2, 0.2) - Consumption/deficit
- **Blue** (0.2, 0.6, 0.8) - Balanced/storage
- **Orange** (0.9, 0.6, 0.1) - Warning state
- **Bright Red** (0.9, 0.1, 0.1) - Critical state

### 3. Warning System

Multi-level warning system with audio feedback:

```gdscript
# Critical power shortage
func show_power_shortage_warning(deficit: float):
    warning_label.text = "⚠ POWER SHORTAGE: %.1f kW DEFICIT" % deficit
    warning_sound.play()
    # Flash animation activated

# Critical storage
func show_critical_storage_warning(storage_percent: float):
    warning_label.text = "⚠ CRITICAL STORAGE: %.1f%% REMAINING" % storage_percent
    warning_sound.play()
    # Flash animation activated

# Low storage
func show_low_storage_warning(storage_percent: float):
    warning_label.text = "⚠ LOW STORAGE: %.1f%%" % storage_percent
    # Solid display, no flash
```

**Warning Thresholds:**
- **Critical Storage**: < 20%
- **Low Storage**: < 40%
- **Power Shortage**: Negative balance + critical storage

### 4. 3D Network Visualization

Interactive grid topology with real-time power flow:

```gdscript
func update_3d_visualization(grid_data: Dictionary):
    # Update grid nodes (producers, consumers, storage)
    _update_grid_nodes(grid_data.nodes)

    # Update power line connections
    _update_power_lines(grid_data.connections)

    # Update power flow particle effects
    _update_power_flow_particles(grid_data.connections)
```

**Node Visualization:**
- **Sphere meshes** with emission materials
- **Color-coded** by type (producer/consumer/storage)
- **Scaled** by power rating
- **Positioned** in 3D space

**Connection Visualization:**
- **Cylindrical meshes** connecting nodes
- **Color-coded** by flow direction (green=positive, red=reverse)
- **Brightness** scaled by power flow magnitude
- **Particle effects** for active connections

**Camera Setup:**
```gdscript
# Isometric view for grid overview
network_camera.position = Vector3(0, 50, 50)
network_camera.look_at(Vector3.ZERO)
```

## API Methods

### Public Methods

```gdscript
# Set grid data from external source
func set_grid_data(data: Dictionary) -> void

# Get current grid data
func get_grid_data() -> Dictionary

# Simulate power surge or deficit
func simulate_power_surge(power_delta: float) -> void

# Simulate storage drain
func simulate_storage_drain(percent_delta: float) -> void

# Reset to default state
func reset_to_defaults() -> void

# Trigger 3D visualization update
func visualize_grid_connections(grid_data: Dictionary) -> void
```

### Data Structure

```gdscript
{
    "production": 150.0,        # kW
    "consumption": 100.0,       # kW
    "storage": 75.0,            # kWh
    "storage_capacity": 100.0,  # kWh
    "storage_percent": 75.0,    # %
    "efficiency": 0.95,         # 0.0 - 1.0
    "connections": [
        {
            "from": "node_id_1",
            "to": "node_id_2",
            "power_flow": 50.0  # kW (+ or -)
        }
    ],
    "nodes": {
        "node_id_1": {
            "position": [10.0, 0.0, 10.0],  # Vector3
            "power": 75.0,                   # kW
            "type": "producer"               # or "consumer", "storage"
        }
    }
}
```

## HTTP API Integration

### Enable Power Grid Endpoints

Add to `godot_bridge.gd` routing:

```gdscript
# In _route_request function
elif path.begins_with("/powergrid/"):
    var PowerGridAPI = load("res://addons/godot_debug_connection/power_grid_api.gd")
    PowerGridAPI.handle_powergrid_endpoint(self, client, method, path, body)
```

### Available Endpoints

#### GET /powergrid/status
Get current power grid status.

**Response:**
```json
{
    "status": "success",
    "grid_data": { ... },
    "timestamp": 1234567890
}
```

#### POST /powergrid/update
Update power grid data.

**Request:**
```json
{
    "production": 150.0,
    "consumption": 100.0,
    "storage_percent": 75.0,
    "efficiency": 0.95
}
```

#### POST /powergrid/simulate/surge
Simulate power surge or deficit.

**Request:**
```json
{
    "power_delta": 50.0  // Can be negative for deficit
}
```

#### POST /powergrid/simulate/drain
Simulate storage drain.

**Request:**
```json
{
    "percent_delta": -15.0  // Negative to drain, positive to charge
}
```

#### POST /powergrid/reset
Reset HUD to default state.

#### POST /powergrid/visualize
Update 3D grid visualization.

**Request (optional):**
```json
{
    "grid_data": {
        "nodes": { ... },
        "connections": [ ... ]
    }
}
```

## Usage Examples

### Basic Setup

```gdscript
# In your main scene
var power_grid_hud = preload("res://scenes/ui/power_grid_panel.tscn").instantiate()
add_child(power_grid_hud)

# Update with base building system data
func _on_power_system_updated(power_data: Dictionary):
    power_grid_hud.set_grid_data(power_data)
```

### Integration with Base Building System

```gdscript
# In BaseBuildingSystem
signal power_grid_updated(grid_data: Dictionary)

func _update_power_grid():
    var grid_data = {
        "production": _calculate_total_production(),
        "consumption": _calculate_total_consumption(),
        "storage": _calculate_storage(),
        "storage_capacity": _get_storage_capacity(),
        "storage_percent": _get_storage_percent(),
        "efficiency": _calculate_efficiency(),
        "connections": _get_power_connections(),
        "nodes": _get_power_nodes()
    }
    power_grid_updated.emit(grid_data)
```

### Python Testing

```python
from examples.power_grid_test_client import PowerGridTestClient

client = PowerGridTestClient()

# Get status
status = client.get_status()
print(status)

# Update grid data
client.update_grid_data({
    "production": 200.0,
    "consumption": 150.0,
    "storage_percent": 80.0
})

# Simulate power surge
client.simulate_surge(50.0)

# Simulate storage drain
client.simulate_drain(-20.0)

# Reset to defaults
client.reset()
```

### Test Client Usage

```bash
# Run interactive tests
python examples/power_grid_test_client.py

# Available tests:
# - Basic functionality
# - Warning conditions
# - Power surge simulation
# - Storage drain simulation
# - 3D network visualization
# - Stress scenarios
# - Continuous monitoring
```

## Configuration

### Update Intervals

```gdscript
const UPDATE_INTERVAL: float = 0.1           # HUD update rate (100ms)
const WARNING_FLASH_INTERVAL: float = 0.5    # Warning flash rate (500ms)
```

### Thresholds

```gdscript
const CRITICAL_STORAGE_THRESHOLD: float = 20.0  # Critical at 20%
const LOW_STORAGE_THRESHOLD: float = 40.0       # Low at 40%
const MAX_POWER_DISPLAY: float = 1000.0         # Max power for bars (kW)
```

### Colors

```gdscript
const COLOR_PRODUCTION: Color = Color(0.2, 0.8, 0.2)   # Green
const COLOR_CONSUMPTION: Color = Color(0.8, 0.2, 0.2)  # Red
const COLOR_BALANCED: Color = Color(0.2, 0.6, 0.8)     # Blue
const COLOR_WARNING: Color = Color(0.9, 0.6, 0.1)      # Orange
const COLOR_CRITICAL: Color = Color(0.9, 0.1, 0.1)     # Bright Red
const COLOR_POWER_FLOW: Color = Color(0.3, 0.7, 1.0)   # Cyan
```

## Performance Optimization

### Update Strategy

The HUD uses a delta-time accumulator pattern for efficient updates:

```gdscript
var update_timer: float = 0.0

func _process(delta: float):
    update_timer += delta
    if update_timer >= UPDATE_INTERVAL:
        update_display(current_grid_data)
        update_timer = 0.0
```

### 3D Visualization

- **Viewport rendering** - Separate SubViewport for 3D scene
- **Update on change** - Only updates when grid topology changes
- **Efficient mesh reuse** - Reuses existing meshes where possible
- **LOD considerations** - Simple geometry for performance

### Memory Management

```gdscript
# Clear old visualizations
for line in power_lines:
    line.queue_free()
power_lines.clear()

for particles in power_flow_particles:
    particles.queue_free()
power_flow_particles.clear()
```

## VR Considerations

### Positioning

- **Bottom-left corner** of screen by default
- **Anchored layout** for consistent positioning
- **Readable at distance** - Large fonts and clear colors

### Comfort

- **High contrast** - Easy to read in any lighting
- **No rapid flashing** - Warning flashes are slow (500ms)
- **Smooth animations** - No jarring transitions
- **Optional positioning** - Can be repositioned for user comfort

### Performance

- **Lightweight UI** - Minimal impact on frame rate
- **Efficient updates** - Only 10 updates per second
- **Static layout** - No complex UI animations

## Testing

### Unit Tests

Create `tests/unit/test_power_grid_hud.gd`:

```gdscript
extends GdUnitTestSuite

var hud: PowerGridHUD

func before_test():
    hud = PowerGridHUD.new()
    add_child(hud)

func test_initial_state():
    var data = hud.get_grid_data()
    assert_float(data.production).is_equal(0.0)
    assert_float(data.storage_percent).is_equal(0.0)

func test_update_statistics():
    hud.set_grid_data({
        "production": 100.0,
        "consumption": 75.0
    })
    var data = hud.get_grid_data()
    assert_float(data.production).is_equal(100.0)
    assert_float(data.consumption).is_equal(75.0)

func test_warning_activation():
    hud.set_grid_data({"storage_percent": 15.0})
    await get_tree().create_timer(0.2).timeout
    assert_bool(hud.warning_active).is_true()
```

### Integration Tests

```python
# tests/integration/test_power_grid_api.py
import pytest
from examples.power_grid_test_client import PowerGridTestClient

@pytest.fixture
def client():
    return PowerGridTestClient()

def test_get_status(client):
    status = client.get_status()
    assert status is not None
    assert "grid_data" in status

def test_update_grid_data(client):
    result = client.update_grid_data({
        "production": 100.0,
        "consumption": 80.0
    })
    assert result["status"] == "success"
    assert result["grid_data"]["production"] == 100.0

def test_simulate_surge(client):
    result = client.simulate_surge(50.0)
    assert result["status"] == "success"
    assert result["power_delta"] == 50.0
```

### Manual Testing

1. **Start Godot with debug services:**
   ```bash
   godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
   ```

2. **Open test scene:**
   - Load `test_power_grid_hud.tscn`
   - Press F5 to run

3. **Run Python test client:**
   ```bash
   python examples/power_grid_test_client.py
   ```

4. **Verify:**
   - HUD displays correctly
   - Statistics update in real-time
   - Warnings activate at thresholds
   - 3D visualization shows connections
   - Colors are correct
   - Audio plays for warnings

## Troubleshooting

### HUD Not Visible

**Issue:** Power grid HUD doesn't appear in scene.

**Solutions:**
1. Check that `power_grid_panel.tscn` is instantiated
2. Verify scene is added to the tree
3. Check z-index ordering with other UI elements
4. Ensure visibility is set to true

### No Data Updates

**Issue:** Statistics don't update when grid changes.

**Solutions:**
1. Verify `set_grid_data()` is being called
2. Check UPDATE_INTERVAL isn't too long
3. Ensure node references (@onready) are valid
4. Check for errors in console

### API Not Working

**Issue:** HTTP endpoints return 503 or 404.

**Solutions:**
1. Verify PowerGridHUD is in scene tree
2. Check endpoint routing is added to godot_bridge.gd
3. Ensure power_grid_api.gd is loaded correctly
4. Test with curl: `curl http://127.0.0.1:8080/powergrid/status`

### 3D Visualization Issues

**Issue:** Network visualization doesn't show or looks wrong.

**Solutions:**
1. Check SubViewport is properly configured
2. Verify Camera3D is positioned correctly
3. Ensure WorldEnvironment provides lighting
4. Check node positions are reasonable (not too far apart)
5. Verify mesh materials have emission enabled

### Warning System Not Activating

**Issue:** Warnings don't show at low storage.

**Solutions:**
1. Verify storage_percent is being set correctly
2. Check CRITICAL_STORAGE_THRESHOLD value
3. Ensure warning_panel visibility is toggling
4. Check audio stream is assigned to warning_sound

## Future Enhancements

### Planned Features

1. **Historical graphs** - Power trends over time
2. **Efficiency breakdown** - Per-module efficiency stats
3. **Predictive analytics** - Estimate time to depletion
4. **Module details** - Click nodes for detailed info
5. **Power routing controls** - Manual connection management
6. **Alarm configuration** - User-defined thresholds
7. **Export reports** - JSON/CSV power logs
8. **Mobile companion app** - Monitor from tablet/phone

### Integration Opportunities

- **Tutorial system** - Teach power management
- **Mission objectives** - Power-based challenges
- **Procedural events** - Solar flares, equipment failures
- **Resource gathering** - Connect to mining/production
- **Research system** - Unlock efficiency upgrades
- **Multiplayer** - Shared grid management

## Related Systems

- **Base Building System** (`base_building_system.gd`)
- **Resource Management** (`resource_manager.gd`)
- **Tutorial System** (`tutorial_system.gd`)
- **Mission System** (`mission_system.gd`)
- **Telemetry Server** (`telemetry_server.gd`)

## References

- [HTTP API Documentation](addons/godot_debug_connection/HTTP_API.md)
- [Base Building Documentation](BASE_BUILDING_SYSTEM.md)
- [Development Workflow](DEVELOPMENT_WORKFLOW.md)
- [Tasks List](tasks.md)

## Credits

Implemented as part of the SpaceTime VR project power management system.
- Design: Task 11.8 - Power Grid HUD Display
- Integration: HTTP API, Base Building System
- Testing: Python test client, GdUnit4 tests

---

**Version:** 1.0.0
**Last Updated:** 2025-12-02
**Status:** Complete and ready for integration
