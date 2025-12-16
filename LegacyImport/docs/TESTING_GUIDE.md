# Testing Guide - Planetary Survival

**Project:** Planetary Survival VR Multiplayer Game
**Date:** 2025-12-02
**Purpose:** Comprehensive testing procedures for system integration validation

---

## Testing Overview

### Test Categories

1. **Unit Tests** - Individual system components (GdUnit4)
2. **Integration Tests** - System interactions (GdUnit4)
3. **Property Tests** - Invariant validation (Python/Hypothesis)
4. **End-to-End Tests** - Complete gameplay workflows (Manual + Automated)
5. **Performance Tests** - VR frame rate and network bandwidth
6. **Load Tests** - Stress testing with many entities/players
7. **VR Comfort Tests** - Motion sickness prevention

---

## Test Environment Setup

### Prerequisites

1. **Godot 4.5+** installed
2. **GdUnit4** plugin installed and enabled
3. **Python 3.8+** with virtual environment
4. **VR Headset** (OpenXR compatible) for VR tests
5. **Multiple machines** for multiplayer tests

### Python Test Environment

```bash
# Activate virtual environment
cd C:/godot
.venv\Scripts\activate  # Windows

# Install test dependencies
pip install -r tests/property/requirements.txt

# Verify installation
python -m pytest --version
python -c "import hypothesis; print(hypothesis.__version__)"
```

### GdUnit4 Setup

```bash
# Install GdUnit4 (if not already installed)
cd C:/godot/addons
git clone https://github.com/MikeSchulze/gdUnit4.git gdUnit4

# Enable in Godot
# Project > Project Settings > Plugins > GdUnit4 > Enable
```

### Debug Services

```bash
# Start Godot with debug services (REQUIRED)
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005

# Or use quick restart script (Windows)
./restart_godot_with_debug.bat

# Verify services running
curl http://127.0.0.1:8080/status
```

---

## Unit Testing

### Running GdUnit4 Tests

**From Godot Editor (RECOMMENDED):**
1. Open Godot editor
2. Navigate to bottom panel > GdUnit4
3. Click "Run All Tests" or select specific test suites
4. View results in real-time

**From Command Line:**
```bash
# Run all tests
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/

# Run specific test
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/test_voxel_terrain_deformation.gd

# Run with verbose output
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/ --verbose
```

### Unit Test Coverage

| System | Test File | Status |
|--------|-----------|--------|
| VoxelTerrain | `test_voxel_terrain_deformation.gd` | ✅ |
| TerrainTool | `test_terrain_tool.gd` | ✅ |
| TerrainSync | `test_terrain_synchronization.gd` | ✅ |
| VoxelOptimizer | `test_voxel_terrain_optimizer.gd` | ✅ |

---

## Property-Based Testing

### Running Python Property Tests

**Run All Property Tests:**
```bash
cd C:/godot/tests/property
python -m pytest test_*.py -v
```

**Run Specific Property:**
```bash
# Test terrain deformation conservation
python test_terrain_deformation.py::test_excavation_soil_conservation

# Test network synchronization
python test_networking.py::test_terrain_sync_determinism
```

**Run with Coverage:**
```bash
pytest test_*.py --cov=planetary_survival --cov-report=html
```

### Property Test Inventory

| Property | Test File | Validates |
|----------|-----------|-----------|
| **Soil Conservation** | `test_terrain_deformation.py` | Req 1.2, 2.1 |
| **Canister Persistence** | `test_terrain_deformation.py` | Req 2.5 |
| **Resource Accumulation** | `test_resource_gathering.py` | Req 3.3 |
| **Oxygen Depletion** | `test_life_support.py` | Req 7.1 |
| **Power Grid Balance** | `test_power_grid.py` | Req 12.2 |
| **Conveyor Transport** | `test_automation.py` | Req 10.2 |
| **Terrain Regeneration** | `test_terrain_regeneration.py` | Req 53.5 |
| **Network Sync** | `test_networking.py` | Req 55.1 |

### Creating New Property Tests

```python
# tests/property/test_example.py
from hypothesis import given, strategies as st
import pytest

@given(
    voxel_count=st.integers(min_value=1, max_value=1000),
    radius=st.floats(min_value=1.0, max_value=10.0)
)
def test_excavation_volume_proportional(voxel_count, radius):
    """Property: Excavated soil volume proportional to affected voxels"""
    excavated_soil = excavate_terrain(radius)
    expected_volume = voxel_count * VOXEL_SIZE ** 3

    assert abs(excavated_soil - expected_volume) < 0.01, \
        f"Soil mismatch: {excavated_soil} vs {expected_volume}"
```

---

## Integration Testing

### End-to-End Workflow Tests

#### Workflow 1: New Player Experience

**Test:** Player spawns, gathers resources, builds first base

```gdscript
# tests/integration/test_new_player_workflow.gd
extends GdUnitTestSuite

func test_new_player_workflow():
    # 1. Spawn player in procedural solar system
    var player = spawn_test_player()
    assert_that(player.is_alive()).is_true()
    assert_that(player.position).is_not_null()

    # 2. Gather basic resources with terrain tool
    var terrain_tool = player.get_terrain_tool()
    excavate_resource_node(terrain_tool, ResourceType.IRON)

    assert_that(player.inventory.has_resource(ResourceType.IRON)).is_true()
    assert_that(player.inventory.get_resource_count(ResourceType.IRON)).is_greater_equal(10)

    # 3. Craft basic structure
    var crafting_system = get_system("CraftingSystem")
    var recipe = crafting_system.get_recipe("habitat_module_basic")
    crafting_system.craft_item(player, recipe)

    assert_that(player.inventory.has_item("habitat_module_basic")).is_true()

    # 4. Place first base module
    var base_building = get_system("BaseBuildingSystem")
    var placement_pos = player.position + Vector3(5, 0, 0)
    base_building.place_module(player, "habitat_module_basic", placement_pos)

    assert_that(base_building.get_modules_count()).is_equal(1)

    # 5. Verify oxygen generation
    await wait_seconds(5.0)  # Wait for oxygen system to activate
    var life_support = get_system("LifeSupportSystem")
    assert_that(life_support.is_pressurized(placement_pos)).is_true()
```

#### Workflow 2: Base Building

**Test:** Build complete base with power and automation

```gdscript
# tests/integration/test_base_building_workflow.gd
extends GdUnitTestSuite

func test_complete_base_workflow():
    var player = spawn_test_player_with_resources()
    var base_building = get_system("BaseBuildingSystem")
    var power_grid = get_system("PowerGridSystem")

    # 1. Excavate underground chamber
    var terrain_tool = player.get_terrain_tool()
    excavate_chamber(terrain_tool, player.position, radius=20.0)

    # 2. Place habitat module
    var habitat_pos = player.position + Vector3(0, -5, 0)
    base_building.place_module(player, "habitat_module", habitat_pos)

    # 3. Place generator module
    var generator_pos = habitat_pos + Vector3(10, 0, 0)
    base_building.place_module(player, "generator_module_biomass", generator_pos)

    # 4. Verify power grid formation
    await wait_seconds(1.0)
    var grid = power_grid.get_grid_at_position(habitat_pos)
    assert_that(grid).is_not_null()
    assert_that(grid.get_production()).is_greater(0.0)

    # 5. Place powered machine
    var fabricator_pos = habitat_pos + Vector3(5, 0, 0)
    base_building.place_module(player, "fabricator_module", fabricator_pos)

    # 6. Verify machine receives power
    await wait_seconds(1.0)
    var fabricator = base_building.get_module_at(fabricator_pos)
    assert_that(fabricator.is_powered()).is_true()

    # 7. Test automation with conveyor belt
    var automation = get_system("AutomationSystem")
    automation.place_conveyor(fabricator_pos, fabricator_pos + Vector3(5, 0, 0))

    # 8. Verify item transport
    fabricator.start_crafting("iron_plate")
    await wait_seconds(10.0)

    var belt = automation.get_belt_at(fabricator_pos + Vector3(2.5, 0, 0))
    assert_that(belt.get_items_count()).is_greater_equal(1)
```

#### Workflow 3: Multiplayer Collaboration

**Test:** Two players build together

```gdscript
# tests/integration/test_multiplayer_workflow.gd
extends GdUnitTestSuite

func test_multiplayer_building():
    # 1. Start multiplayer session
    start_multiplayer_server()
    var player1 = spawn_test_player("Player1")

    # 2. Join as second player
    var player2 = join_multiplayer_client("Player2")
    await wait_seconds(2.0)  # Wait for sync

    # 3. Player 1 excavates terrain
    var terrain_tool1 = player1.get_terrain_tool()
    excavate_sphere(terrain_tool1, player1.position, 5.0)

    # 4. Verify Player 2 sees terrain modification
    await wait_seconds(1.0)  # Network sync
    var voxel_terrain = get_system("VoxelTerrain")
    assert_that(voxel_terrain.is_excavated(player1.position)).is_true()

    # 5. Player 2 places structure
    var base_building = get_system("BaseBuildingSystem")
    var module_pos = player1.position + Vector3(10, 0, 0)
    base_building.place_module(player2, "habitat_module", module_pos)

    # 6. Verify Player 1 sees structure
    await wait_seconds(1.0)  # Network sync
    assert_that(base_building.has_module_at(module_pos)).is_true()

    # 7. Test resource trading
    player1.inventory.add_resource(ResourceType.IRON, 100)
    trade_resources(player1, player2, ResourceType.IRON, 50)

    assert_that(player1.inventory.get_resource_count(ResourceType.IRON)).is_equal(50)
    assert_that(player2.inventory.get_resource_count(ResourceType.IRON)).is_equal(50)

    # 8. Test conflict resolution (simultaneous pickup)
    var resource_fragment = spawn_resource_fragment(player1.position)
    simultaneously_pickup(player1, player2, resource_fragment)

    # Only one should succeed
    var p1_has = player1.inventory.has_resource(resource_fragment.type)
    var p2_has = player2.inventory.has_resource(resource_fragment.type)
    assert_that(p1_has != p2_has).is_true()  # XOR: exactly one has it
```

#### Workflow 4: Advanced Gameplay

**Test:** Creature taming, breeding, boss encounter

```gdscript
# tests/integration/test_advanced_gameplay_workflow.gd
extends GdUnitTestSuite

func test_creature_taming_and_breeding():
    var player = spawn_test_player_with_resources()
    var creature_system = get_system("CreatureSystem")

    # 1. Spawn creature
    var creature = creature_system.spawn_creature("raptor", player.position + Vector3(20, 0, 0))
    assert_that(creature).is_not_null()
    assert_that(creature.is_wild()).is_true()

    # 2. Knockout with tranquilizer
    creature.apply_tranquilizer(100)
    await wait_until(lambda: creature.is_unconscious())
    assert_that(creature.is_unconscious()).is_true()

    # 3. Tame with food
    feed_creature(player, creature, "raw_meat", count=10)
    await wait_until(lambda: creature.is_tamed())
    assert_that(creature.is_tamed()).is_true()
    assert_that(creature.get_owner()).is_equal(player)

    # 4. Test creature commands
    creature.command_follow(player)
    player.move_to(player.position + Vector3(50, 0, 0))
    await wait_seconds(5.0)
    assert_that(creature.position.distance_to(player.position)).is_less(10.0)

    # 5. Breed creatures
    var mate = tame_another_creature(player, "raptor")
    var egg = creature_system.breed_creatures(creature, mate)
    assert_that(egg).is_not_null()

    # 6. Hatch and imprint
    await wait_until(lambda: egg.is_ready_to_hatch())
    var offspring = egg.hatch()
    offspring.imprint(player)
    assert_that(offspring.get_imprint_bonus()).is_greater(0.0)

func test_boss_encounter():
    var player = spawn_test_player_with_gear()
    var boss_system = get_system("BossEncounterSystem")

    # 1. Find boss chamber
    var boss_chamber = boss_system.generate_boss_chamber()
    assert_that(boss_chamber).is_not_null()

    # 2. Enter chamber and trigger boss
    player.move_to(boss_chamber.entrance_position)
    var boss = boss_system.spawn_boss(boss_chamber)
    assert_that(boss).is_not_null()
    assert_that(boss.health).is_equal(boss.max_health)

    # 3. Combat simulation
    while boss.health > 0:
        player.attack(boss, damage=100)
        await wait_seconds(1.0)

    # 4. Verify loot drops
    assert_that(boss_chamber.has_loot()).is_true()
    var loot = boss_chamber.collect_loot(player)
    assert_that(loot.has("exotic_crystal")).is_true()

    # 5. Verify tech unlock
    var tech_tree = get_system("TechTree")
    assert_that(tech_tree.is_unlocked("particle_accelerator")).is_true()
```

---

## Performance Testing

### VR Frame Rate Tests

**Test Setup:**
```gdscript
# tests/performance/test_vr_framerate.gd
extends GdUnitTestSuite

var performance_monitor: PerformanceMonitor

func before_test():
    performance_monitor = PerformanceMonitor.new()
    performance_monitor.start()

func test_vr_framerate_terrain_deformation():
    var player = spawn_vr_player()
    var terrain_tool = player.get_terrain_tool()

    # Perform intensive terrain modification
    for i in range(10):
        excavate_large_sphere(terrain_tool, radius=10.0)
        await wait_frames(10)

    # Measure performance
    var stats = performance_monitor.get_stats()
    assert_that(stats.min_fps).is_greater_equal(85)  # Allow small drops
    assert_that(stats.avg_fps).is_greater_equal(90)
    assert_that(stats.frame_time_variance).is_less(2.0)  # ms

func test_vr_framerate_multiplayer():
    start_multiplayer_server()
    var players = []

    # Spawn 4 VR players
    for i in range(4):
        players.append(spawn_vr_player("Player" + str(i)))

    # All players use terrain tools simultaneously
    for player in players:
        player.get_terrain_tool().start_excavating()

    await wait_seconds(30.0)

    # Measure performance
    var stats = performance_monitor.get_stats()
    assert_that(stats.min_fps).is_greater_equal(80)
    assert_that(stats.avg_fps).is_greater_equal(90)
```

### Bandwidth Tests

```gdscript
# tests/performance/test_network_bandwidth.gd
extends GdUnitTestSuite

func test_vr_hand_tracking_bandwidth():
    var network_monitor = NetworkBandwidthMonitor.new()
    start_multiplayer_server()

    var player1 = spawn_vr_player("Player1")
    var player2 = spawn_vr_player("Player2")

    # Simulate VR hand movement for 60 seconds
    network_monitor.start()
    for i in range(60 * 20):  # 60 seconds at 20Hz
        player1.update_hand_tracking(random_hand_poses())
        player2.update_hand_tracking(random_hand_poses())
        await wait_frames(3)  # ~20Hz at 60 FPS

    var stats = network_monitor.get_stats()
    var bandwidth_per_player = stats.total_bytes / 60.0 / 1024.0  # KB/s

    assert_that(bandwidth_per_player).is_less(256.0)  # <256 KB/s target
    print("Bandwidth per player: ", bandwidth_per_player, " KB/s")
```

---

## Load Testing

### Entity Stress Test

```bash
# tests/load/test_entity_spawning.gd
extends GdUnitTestSuite

func test_1000_entities():
    var entity_spawner = EntitySpawner.new()
    var performance_monitor = PerformanceMonitor.new()

    performance_monitor.start()

    # Spawn 1000 entities
    for i in range(1000):
        var entity_type = ["creature", "resource", "structure"][i % 3]
        entity_spawner.spawn_entity(entity_type, random_position())

        if i % 100 == 0:
            await wait_frames(10)  # Brief pause every 100

    # Run for 60 seconds
    await wait_seconds(60.0)

    # Measure performance
    var stats = performance_monitor.get_stats()
    assert_that(stats.avg_fps).is_greater_equal(60)  # Accept degraded performance
    print("FPS with 1000 entities: ", stats.avg_fps)
```

### Multiplayer Scaling Test

```gdscript
# tests/load/test_multiplayer_scaling.gd
extends GdUnitTestSuite

func test_8_player_server():
    start_multiplayer_server()
    var players = []

    # Spawn 8 players
    for i in range(8):
        players.append(join_multiplayer_client("Player" + str(i)))
        await wait_seconds(2.0)

    # All players perform actions
    for player in players:
        player.start_building()
        player.start_mining()

    await wait_seconds(300.0)  # 5 minutes

    # Check server still responsive
    assert_that(server.is_responsive()).is_true()
    assert_that(server.get_player_count()).is_equal(8)
```

---

## VR Comfort Testing

### Motion Sickness Prevention

**Manual Test Checklist:**
- [ ] No judder during head movement
- [ ] Consistent 90 FPS (no dropped frames)
- [ ] Teleportation has smooth fade transition
- [ ] Vignette activates during rapid movement
- [ ] No sudden camera movements
- [ ] Snap turning increments feel natural (30°)

**Automated Checks:**
```gdscript
func test_vr_comfort_parameters():
    var vr_comfort = get_system("VRComfortSystem")

    # Verify vignette settings
    assert_that(vr_comfort.vignette_enabled).is_true()
    assert_that(vr_comfort.vignette_intensity).is_greater_equal(0.5)

    # Verify snap turn settings
    assert_that(vr_comfort.snap_turn_angle).is_equal(30.0)

    # Verify smooth locomotion speed limits
    var max_speed = vr_comfort.get_max_locomotion_speed()
    assert_that(max_speed).is_less_equal(5.0)  # m/s
```

---

## Regression Testing

### Automated Test Suite

```bash
# Run complete test suite
cd C:/godot

# 1. Unit tests (GdUnit4)
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/

# 2. Integration tests
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/integration/

# 3. Property tests (Python)
cd tests/property
python -m pytest test_*.py -v

# 4. Performance tests
cd ..
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/performance/

# 5. Generate report
python tests/generate_test_report.py
```

### Continuous Integration

**CI Pipeline (GitHub Actions / GitLab CI):**
```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Godot
        run: |
          wget https://downloads.tuxfamily.org/godotengine/4.5/Godot_v4.5-stable_linux.x86_64.zip
          unzip Godot_v4.5-stable_linux.x86_64.zip

      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.10'

      - name: Install Python Dependencies
        run: |
          cd tests/property
          pip install -r requirements.txt

      - name: Run Unit Tests
        run: |
          ./Godot_v4.5-stable_linux.x86_64 --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/

      - name: Run Property Tests
        run: |
          cd tests/property
          python -m pytest test_*.py -v

      - name: Upload Test Results
        uses: actions/upload-artifact@v2
        with:
          name: test-results
          path: test-results/
```

---

## Test Reporting

### Generate Test Report

```python
# tests/generate_test_report.py
import json
from datetime import datetime

def generate_report():
    report = {
        "timestamp": datetime.now().isoformat(),
        "test_suites": {
            "unit": load_gdunit_results(),
            "property": load_pytest_results(),
            "integration": load_integration_results(),
            "performance": load_performance_results()
        },
        "summary": calculate_summary()
    }

    with open("test-results/report.json", "w") as f:
        json.dump(report, f, indent=2)

    generate_html_report(report)
    print("Test report generated: test-results/report.html")
```

---

## Known Issues

See `KNOWN_ISSUES.md` for current bugs and limitations.

---

## Next Steps

1. **Fix PlanetarySurvivalCoordinator** - Enable in project.godot
2. **Run Baseline Tests** - Establish current test pass rate
3. **Fix Failing Tests** - Address any broken tests
4. **Add Missing Tests** - Fill coverage gaps
5. **Performance Baseline** - Measure current VR performance
6. **Multiplayer Testing** - Test with real VR players

---

**Document Version:** 1.0
**Last Updated:** 2025-12-02
**Maintained By:** Planetary Survival Team
