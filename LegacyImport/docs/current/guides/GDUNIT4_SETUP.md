# GdUnit4 Testing Framework Setup

## Quick Setup Summary

GdUnit4 is the unit testing framework for Godot 4.x. This guide covers installation, configuration, and best practices for the SpaceTime project.

## IMPORTANT: Python Server Method Required

All testing **MUST** be performed with Godot running through the Python server wrapper for full functionality:

```bash
python godot_editor_server.py --port 8090
```

This ensures:
- GUI mode is active (required for GdUnit4 panel)
- All autoloads are properly initialized
- Debug connection systems are available
- Test harness can communicate with Godot

**DO NOT start Godot directly** for testing—it won't have the required architecture.

## Installation Instructions

GdUnit4 is a testing framework for Godot 4.x that provides unit testing capabilities.

### Method 1: Asset Library (Recommended)

1. Ensure Godot is running via Python server: `python godot_editor_server.py --port 8090`
2. Open the Godot Editor
3. Go to **AssetLib** tab (top of editor)
4. Search for "GdUnit4"
5. Click **Download** and then **Install**
6. Enable the plugin: **Project > Project Settings > Plugins > GdUnit4 > Enable**
7. Restart Godot (via the Python server script) to activate

### Method 2: Manual Installation via CLI

```bash
cd C:/godot/addons
git clone https://github.com/MikeSchulze/gdUnit4.git gdUnit4
cd ../..
```

Then enable in Godot editor: **Project > Project Settings > Plugins > GdUnit4 > Enable**

## Verification

After installation, you should see:

- `addons/gdUnit4/` directory in your project
- GdUnit4 panel in the bottom dock of the editor (when running via Python server)
- Test tree displaying available test suites

## Running Tests

### Method 1: Interactive GUI (Recommended for Development)

1. Start Godot via Python server: `python godot_editor_server.py --port 8090`
2. Open the GdUnit4 panel (bottom dock of editor)
3. Expand test suites in the panel
4. Click "Run All Tests" or right-click specific test files/methods
5. View results in the GdUnit4 output panel with detailed assertions and errors

### Method 2: Command Line (CI/Automated Testing)

```bash
# From project root with Godot running via Python server
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/
```

Note: CLI tests may require some tests to run in GUI mode. Prefer interactive GUI for full compatibility.

### Method 3: Automated Test Suite

Use the project's test runner for coordinated testing:

```bash
cd tests
python test_runner.py
```

This orchestrates GDScript unit tests, Python property-based tests, and integration tests.

## Writing Tests

Create test files in `tests/unit/` or `tests/integration/` with the naming convention:

- `test_*.gd` for test files
- Extend `GdUnitTestSuite` class
- One test class per system/component

Example:

```gdscript
extends GdUnitTestSuite

func test_time_dilation_calculation() -> void:
    var time_manager = TimeManager.new()
    # Test state after initialization
    assert_that(time_manager.time_dilation).is_equal(1.0)

func test_relativity_velocity_limit() -> void:
    var physics = RelativityManager.new()
    var velocity = physics.calculate_relativistic_velocity(0.9 * 299792458.0)
    # Verify cannot exceed speed of light
    assert_that(velocity).is_less_than(299792458.0)
```

## Testing Subsystems

When testing SpaceTime subsystems (managed by ResonanceEngine):

```gdscript
extends GdUnitTestSuite

var engine: ResonanceEngine

func before_test() -> void:
    engine = ResonanceEngine.new()
    engine.initialize()
    add_child(engine)  # Must be added to tree for autoloads to work

func after_test() -> void:
    engine.queue_free()

func test_vr_initialization() -> void:
    await wait_for_signal(engine.vr_ready, 5.0)
    assert_that(engine.vr_manager).is_not_null()
```

## Integration with CI/CD

For automated testing:

1. Python server runs Godot with test flags
2. GdUnit4 test results are collected
3. Python property-based tests run against the system
4. Health checks verify overall system stability

See `tests/test_runner.py` for complete orchestration.

## Project Structure

```
tests/
├── unit/           # GdUnit4 unit tests
│   ├── test_time_manager.gd
│   ├── test_vr_manager.gd
│   └── test_physics_engine.gd
├── integration/    # Integration tests
│   ├── test_engine_startup.gd
│   └── test_subsystem_interactions.gd
└── property/       # Python property-based tests (Hypothesis)
    ├── test_relativity.py
    ├── test_floating_origin.py
    └── requirements.txt
```

## Common Testing Patterns

### Testing with Dependencies
```gdscript
func test_with_dependency_injection() -> void:
    var mock_time_manager = TimeManager.new()
    var physics = PhysicsEngine.new()
    # Physics depends on TimeManager
    assert_that(physics.get_frame_delta()).is_equal(0.0)
```

### Async Testing
```gdscript
func test_async_operation() -> void:
    var signal_waiter = SignalAwaiter.new()
    some_async_operation()
    await wait_for_signal(operation_complete, 3.0)
    assert_that(result).is_not_null()
```

### VR Testing
```gdscript
func test_vr_tracking_updates() -> void:
    await wait_for_signal(VRManager.tracking_updated, 2.0)
    assert_that(VRManager.headset_position).is_not_equal(Vector3.ZERO)
```

## Troubleshooting

**GdUnit4 panel not visible:**
- Ensure Godot is running via Python server (GUI mode required)
- Check that plugin is enabled in Project Settings
- Try docking the panel: **Window > Docks > GdUnit4 Test Runner**

**Tests failing with "Node not in scene tree":**
- Call `add_child(node)` in `before_test()` for nodes that need scene context
- Use `await wait_for_signals()` for async operations

**Timeout errors:**
- Increase timeout: `await wait_for_signal(signal, 10.0)` for slow operations
- Check that signal is actually being emitted from the system

**Plugin not loading after install:**
- Restart Godot via the Python server
- Verify `addons/gdUnit4/plugin.cfg` exists and is valid
- Check Godot console for any error messages
