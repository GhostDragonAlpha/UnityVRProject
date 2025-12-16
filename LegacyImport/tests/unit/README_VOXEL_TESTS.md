# Voxel Terrain Test Suite

**Test File:** `C:/godot/tests/unit/test_voxel_terrain.gd`
**Framework:** GdUnit4
**Created:** 2025-12-03

## Overview

This test suite validates the voxel terrain integration in the SpaceTime project. It tests the godot_voxel GDExtension functionality including terrain instantiation, generator setup, collision generation, chunk loading, and player spawn positioning.

## Test Coverage

### Test 1: `test_voxel_terrain_instantiation()`
**Purpose:** Verify VoxelTerrain class can be instantiated

**What it tests:**
- VoxelTerrain class exists (GDExtension loaded)
- VoxelTerrain can be instantiated via ClassDB
- Instance is a valid Node3D
- Essential methods exist (set_stream, set_generate_collisions)

**Expected outcome:** VoxelTerrain instantiates successfully with all core methods available

---

### Test 2: `test_voxel_generator_setup()`
**Purpose:** Verify voxel generators can be created and assigned

**What it tests:**
- VoxelGeneratorFlat can be instantiated
- Generator has configuration methods (set_height)
- VoxelStreamScripted can be created
- Generator can be assigned to stream
- Stream can be assigned to terrain
- Stream assignment persists (get_stream returns correct object)

**Expected outcome:** Complete generator pipeline works from creation to terrain assignment

---

### Test 3: `test_collision_generation()`
**Purpose:** Verify collision shapes are generated for terrain

**What it tests:**
- Collision generation can be enabled
- Collision setting persists when retrieved
- Terrain can be added to scene tree (required for collision)
- Generator configuration works with collision enabled
- Collision system waits for chunk generation

**Expected outcome:** Collision generation capability is verified and functional

---

### Test 4: `test_terrain_loading()`
**Purpose:** Verify terrain chunks load within view distance

**What it tests:**
- View distance can be configured
- View distance setting persists
- Generator configuration for chunk loading
- Viewer position can be set
- Chunks generate within timeout period
- Statistics or child nodes indicate loaded terrain

**Expected outcome:** Terrain chunks load around viewer position within configured view distance

---

### Test 5: `test_player_spawns_on_surface()`
**Purpose:** Verify player spawn height is correct on terrain surface

**What it tests:**
- Voxel test scene loads successfully
- VoxelTerrain exists in scene or can be added
- Flat generator creates surface at y=0
- Player spawn height is above terrain surface (>= -0.5 threshold)
- Player spawn height is reasonable (< 100.0)
- Multiple spawn positions are valid

**Expected outcome:** Player spawns at appropriate height above terrain surface across multiple test positions

---

## Running the Tests

### Option 1: Via Godot Editor (Recommended)

1. Open Godot editor with the project
2. Open the GdUnit4 panel (bottom of editor)
3. Navigate to `tests/unit/test_voxel_terrain.gd`
4. Click "Run All Tests" or run individual tests

### Option 2: Via Command Line

```bash
# Run all tests in the suite
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/test_voxel_terrain.gd

# Run a specific test
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-case test_voxel_terrain_instantiation
```

### Option 3: Via Python Test Runner

```bash
cd tests
python test_runner.py --filter voxel
```

## Prerequisites

1. **GdUnit4 must be installed:**
   ```bash
   cd addons
   git clone https://github.com/MikeSchulze/gdUnit4.git gdUnit4
   ```
   OR install via Godot Editor AssetLib

2. **godot_voxel GDExtension must be loaded:**
   - Located in `addons/zylann.voxel/`
   - Enabled in project.godot
   - Check: Project Settings > Plugins > godot_voxel (enabled)

3. **Voxel test scene must exist:**
   - `voxel_test_terrain.tscn` in project root
   - Contains VoxelTerrain node or script to create one

## Test Configuration

Key constants defined in the test suite:

```gdscript
const VOXEL_TEST_SCENE = "res://voxel_test_terrain.tscn"
const SPAWN_HEIGHT_THRESHOLD = 0.5  # Minimum spawn height above terrain
const VIEW_DISTANCE = 128            # Chunk loading view distance
const CHUNK_LOAD_TIMEOUT = 5.0       # Seconds to wait for chunk generation
```

## Interpreting Results

### Success Output

```
[TEST 1] Testing VoxelTerrain instantiation...
    ✓ VoxelTerrain instantiated successfully
    ✓ Type: VoxelTerrain
    ✓ Essential methods verified

[TEST 2] Testing voxel generator setup...
    ✓ VoxelGeneratorFlat created
    ✓ Generator height set to 0.0
    ✓ Generator assigned to stream
    ✓ Stream assigned to terrain
    ✓ Generator setup complete
...
```

### Common Failures

**"VoxelTerrain class not found"**
- **Cause:** godot_voxel GDExtension not loaded
- **Fix:** Enable plugin in Project Settings > Plugins

**"Failed to create VoxelGeneratorFlat"**
- **Cause:** Outdated or incompatible voxel plugin version
- **Fix:** Update godot_voxel to compatible version for Godot 4.5+

**"Player spawn height too low"**
- **Cause:** Terrain positioning or generator configuration issue
- **Fix:** Check voxel_test_terrain.tscn terrain position and generator settings

**"Chunk loading timeout"**
- **Cause:** Slow system or viewer not configured
- **Fix:** Increase CHUNK_LOAD_TIMEOUT or verify viewer setup

## Integration with CI/CD

This test suite is designed to run in automated pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run Voxel Tests
  run: |
    godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd \
      --test-suite tests/unit/test_voxel_terrain.gd \
      --report-html reports/voxel_tests.html
```

**Note:** Some tests require GUI mode due to VoxelTerrain's rendering dependencies. Use console mode instead of headless if tests fail.

## Troubleshooting

### Tests hang or timeout
- Increase CHUNK_LOAD_TIMEOUT constant
- Check Godot console for error messages
- Verify GPU drivers are up to date (voxel meshing uses compute)

### Assertion failures
- Check test output for specific failure message
- Verify godot_voxel version compatibility
- Ensure voxel_test_terrain.tscn is not corrupted

### Tests skip or are ignored
- Verify test function names start with `test_`
- Check GdUnit4 plugin is enabled
- Ensure test file extends GdUnitTestSuite

## Future Enhancements

Potential additions to this test suite:

1. **Terrain deformation tests** - Modify voxels and verify changes
2. **Multi-scale terrain tests** - Test LOD system and large distances
3. **Performance benchmarks** - Measure chunk generation speed
4. **Collision raycast tests** - Verify collision shapes work correctly
5. **Networked terrain tests** - Verify multiplayer terrain synchronization

## References

- [GdUnit4 Documentation](https://mikeschulze.github.io/gdUnit4/)
- [godot_voxel Documentation](https://voxel-tools.readthedocs.io/)
- [Project CLAUDE.md](../../CLAUDE.md) - Project overview and testing strategy
- [VOXEL_INTEGRATION.md](../../docs/VOXEL_INTEGRATION.md) - Voxel integration details
