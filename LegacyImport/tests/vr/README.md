# VR Testing Infrastructure

Automated VR testing infrastructure for CI/CD integration.

## Overview

This directory contains automated tests for VR initialization patterns across all VR scenes in the SpaceTime project.

## Test Files

- `test_vr_initialization.gd` - GdUnit4 test suite for VR initialization
- `../test_vr_suite.py` - Python wrapper for CI/CD integration

## What is Tested

### VR Initialization Pattern
- OpenXR interface detection and initialization
- Viewport XR flag (`get_viewport().use_xr = true`)
- XROrigin3D + XRCamera3D structure exists
- XRCamera3D is set as current camera
- Controller nodes present (LeftController, RightController)

### VR Scenes Tested
- `res://scenes/vr_main.tscn` - Main VR scene
- `res://scenes/features/minimal_vr_test.tscn` - Minimal VR test
- `res://scenes/features/vr_locomotion_test.tscn` - Locomotion test
- `res://scenes/features/vr_tracking_test.tscn` - Tracking test
- `res://scenes/features/ship_interaction_test_vr.tscn` - Ship interaction (if exists)

### Fallback Behavior
- Desktop mode fallback when headset unavailable
- Graceful degradation without errors

## Running Tests

### Option 1: Python Wrapper (Recommended for CI/CD)

```bash
# Run all VR tests
python tests/test_vr_suite.py

# Run with verbose output
python tests/test_vr_suite.py --verbose

# Run with custom timeout
python tests/test_vr_suite.py --timeout 300

# Run with custom Godot path
python tests/test_vr_suite.py --godot-path "C:/godot/Godot.exe"
```

### Option 2: GdUnit4 CLI

```bash
# Run via GdUnit4 command line tool
godot --headless --path "C:/Ignotus" -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite res://tests/vr/test_vr_initialization.gd
```

### Option 3: Godot Editor

1. Open project in Godot editor
2. Open GdUnit4 panel (bottom of editor)
3. Navigate to `tests/vr/test_vr_initialization.gd`
4. Click "Run Tests" button

## CI/CD Integration

### Exit Codes

The Python wrapper (`test_vr_suite.py`) returns standard exit codes for CI/CD:

- `0` - All tests passed
- `1` - Test failures detected
- `2` - Godot not found or startup failed
- `3` - Test execution timeout

### GitHub Actions Example

```yaml
name: VR Tests

on: [push, pull_request]

jobs:
  vr-tests:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Godot
        run: |
          # Download and install Godot 4.5+
          # ...

      - name: Run VR Tests
        run: python tests/test_vr_suite.py --timeout 300
```

### GitLab CI Example

```yaml
vr-tests:
  stage: test
  script:
    - python tests/test_vr_suite.py --timeout 300
  artifacts:
    when: always
    reports:
      junit: test-results.xml
```

## Test Structure

### GdUnit4 Test Suite

The test suite (`test_vr_initialization.gd`) extends `GdUnitTestSuite` and follows these patterns:

```gdscript
## Test individual scene
func test_minimal_vr_test_initialization():
    var scene = _load_and_add_scene("res://scenes/features/minimal_vr_test.tscn")
    _verify_vr_initialization(scene, "MinimalVRTest")

## Helper: Load and verify
func _verify_vr_initialization(scene: Node, scene_name: String):
    # Wait for _ready()
    await get_tree().process_frame

    # Verify XROrigin3D
    var xr_origin = scene.find_child("XROrigin3D", true, false)
    assert_object(xr_origin).is_not_null()

    # Verify viewport.use_xr flag
    assert_bool(scene.get_viewport().use_xr).is_true()
```

### Cleanup Pattern

Tests properly clean up resources to prevent memory leaks:

```gdscript
func before_test():
    # Clean up previous instance
    if _scene_instance:
        _scene_instance.queue_free()
        _scene_instance = null

func after_test():
    # Clean up scene and XR interface
    if _scene_instance:
        _scene_instance.queue_free()

    var xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.is_initialized():
        xr_interface.uninitialize()
```

## Prerequisites

### Required
- Godot 4.5+ (with console version for better test output)
- GdUnit4 addon installed in `addons/gdUnit4/`
- Python 3.8+ (for Python wrapper)

### Installation

```bash
# Install GdUnit4
cd addons
git clone https://github.com/MikeSchulze/gdUnit4.git

# Or via Godot Editor AssetLib:
# 1. Open AssetLib
# 2. Search "GdUnit4"
# 3. Download and install
# 4. Enable in Project Settings > Plugins
```

## Troubleshooting

### Test Failures

**Symptom:** Tests fail with "XROrigin3D not found"
**Solution:** Verify scene structure has XROrigin3D node at root level

**Symptom:** Tests fail with "viewport.use_xr is false"
**Solution:** Ensure scene's `_ready()` function calls `get_viewport().use_xr = true`

**Symptom:** Tests timeout
**Solution:** Increase timeout with `--timeout 600` or check Godot console for errors

### OpenXR Not Available

Tests are designed to gracefully handle missing OpenXR:
- Basic structure tests still run (XROrigin3D, XRCamera3D)
- VR-specific tests are skipped with info messages
- Tests pass if structure is correct

### Godot Not Found

**Symptom:** Python wrapper exits with code 2
**Solution:** Specify Godot path with `--godot-path` argument

```bash
python tests/test_vr_suite.py --godot-path "C:/godot/Godot_v4.5.1-stable_win64.exe"
```

## Test Coverage

Current test coverage:

- ✅ VR initialization pattern verification
- ✅ Scene structure validation (XROrigin3D + XRCamera3D)
- ✅ Viewport XR flag verification
- ✅ Controller presence validation
- ✅ Fallback mode detection
- ✅ Idempotent initialization
- ✅ Scene loadability checks

## Future Enhancements

Potential additions to the test suite:

- [ ] Performance benchmarks (frame time, load time)
- [ ] Controller input simulation
- [ ] Haptic feedback verification
- [ ] Multi-scene transition tests
- [ ] Memory leak detection
- [ ] VR comfort system tests
- [ ] Integration with HTTP API tests

## Contributing

When adding new VR scenes:

1. Add scene path to `VR_SCENES` constant in `test_vr_initialization.gd`
2. Ensure scene follows VR initialization pattern:
   ```gdscript
   func _ready():
       var xr_interface = XRServer.find_interface("OpenXR")
       if xr_interface and xr_interface.initialize():
           get_viewport().use_xr = true
           $XROrigin3D/XRCamera3D.current = true
   ```
3. Run tests to verify: `python tests/test_vr_suite.py`

## References

- [GdUnit4 Documentation](https://github.com/MikeSchulze/gdUnit4)
- [Godot XR Documentation](https://docs.godotengine.org/en/stable/tutorials/xr/index.html)
- [OpenXR Specification](https://www.khronos.org/openxr/)
- [SpaceTime VR Main Scene](../../scenes/vr_main.tscn)
