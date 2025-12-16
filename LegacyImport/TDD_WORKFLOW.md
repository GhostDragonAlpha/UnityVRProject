# Test-Driven Development Workflow - SpaceTime VR
**Created:** 2025-12-09
**Purpose:** Complete TDD methodology using GdUnit4 for VR game development

---

## Why TDD is Critical for This Project

**Your situation:**
- 10 previous attempts failed
- Galaxy-scale VR game with real physics
- Multiplayer with deterministic physics required
- AI development partner (me)

**How TDD solves this:**
1. ✅ **Prevents Rewrites** - Tests catch breaking changes immediately
2. ✅ **Ensures Deterministic Physics** - Required for multiplayer networking
3. ✅ **Fast Iteration** - Test in 1 second vs. 30+ seconds loading VR
4. ✅ **Documents Behavior** - Tests show how systems should work
5. ✅ **Catches Bugs Early** - Before VR testing, before integration
6. ✅ **Enables Refactoring** - Change code confidently (tests verify)

---

## TDD Workflow: Red-Green-Refactor-Verify

### The 4-Step Cycle

```
┌──────────────────────────────────────────────┐
│  1. RED: Write Failing Test                 │
│     - Write test for feature that doesn't    │
│       exist yet                              │
│     - Run test → FAILS (expected)            │
│     - Commit: "Test: Add test_feature_name"  │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│  2. GREEN: Write Minimum Code               │
│     - Implement JUST enough to pass test     │
│     - Don't over-engineer                    │
│     - Run test → PASSES                      │
│     - Commit: "Implement: feature_name"      │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│  3. REFACTOR: Improve Code                  │
│     - Clean up code                          │
│     - Remove duplication                     │
│     - Run tests → STILL PASSES               │
│     - Commit: "Refactor: feature_name"       │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│  4. VERIFY: Test in VR (Manual)             │
│     - Put on headset                         │
│     - Test feature works in actual VR        │
│     - If bugs found → write new test (RED)   │
│     - Document in test report                │
└──────────────────────────────────────────────┘
                    ↓
              (Repeat for next feature)
```

---

## GdUnit4 Setup

### Installation (Already Done in Phase 0)

**Verify:**
```gdscript
# In Godot editor
# Project → Project Settings → Plugins
# Should see: "gdUnit4" (enabled)
```

### Test Directory Structure

```
tests/
├── unit/                         # Unit tests (isolated)
│   ├── test_floating_origin.gd
│   ├── test_orbital_mechanics.gd
│   ├── test_gravity_manager.gd
│   └── test_network_sync.gd
│
├── integration/                  # Integration tests
│   ├── test_ship_flight_full.gd
│   ├── test_planetary_landing.gd
│   └── test_multiplayer_sync.gd
│
├── vr/                          # VR-specific tests (require headset)
│   ├── test_controller_tracking.gd
│   ├── test_vr_comfort.gd
│   └── test_haptic_feedback.gd
│
└── runtime/                     # Runtime validation tests
    ├── test_performance.gd
    └── test_network_stress.gd
```

---

## TDD Example: Floating Origin System

### Step 1: RED (Write Failing Test)

**Create:** `tests/unit/test_floating_origin.gd`

```gdscript
extends GutTest
## Test suite for FloatingOriginSystem
## Ensures universe shifts to keep player near origin

var floating_origin: FloatingOriginSystem
var test_ship: Node3D

func before_each():
    """Setup before each test"""
    # Create system
    floating_origin = FloatingOriginSystem.new()
    add_child_autofree(floating_origin)

    # Create test ship
    test_ship = Node3D.new()
    add_child_autofree(test_ship)
    floating_origin.register_object(test_ship)

func after_each():
    """Cleanup after each test"""
    # Automatic cleanup via autofree

func test_shifts_universe_when_player_exceeds_threshold():
    """When player moves >10km from origin, universe should shift"""
    # Arrange
    test_ship.position = Vector3(15000, 0, 0)  # 15km (beyond 10km threshold)

    # Act
    floating_origin._physics_process(0.016)  # Simulate one physics frame

    # Assert
    assert_lt(test_ship.position.length(), 1000.0,
        "Ship should be shifted back near origin (< 1km)")

func test_does_not_shift_within_threshold():
    """When player within 10km, no shift should occur"""
    # Arrange
    test_ship.position = Vector3(5000, 0, 0)  # 5km (within threshold)
    var initial_pos := test_ship.position

    # Act
    floating_origin._physics_process(0.016)

    # Assert
    assert_eq(test_ship.position, initial_pos,
        "Ship position should not change when within threshold")

func test_tracks_total_offset():
    """System should track cumulative universe offset"""
    # Arrange
    test_ship.position = Vector3(15000, 0, 0)

    # Act
    floating_origin._physics_process(0.016)

    # Assert
    assert_true(floating_origin.origin_offset.length() > 0,
        "origin_offset should track total shift")

func test_shifts_all_registered_objects():
    """All registered objects should shift together"""
    # Arrange
    var ship2 := Node3D.new()
    add_child_autofree(ship2)
    floating_origin.register_object(ship2)

    test_ship.position = Vector3(15000, 0, 0)
    ship2.position = Vector3(20000, 0, 0)

    # Act
    floating_origin._physics_process(0.016)

    # Assert
    assert_lt(test_ship.position.length(), 1000.0, "Ship 1 shifted")
    assert_lt(ship2.position.length(), 15000.0, "Ship 2 shifted by same amount")
```

**Run test:**
```bash
# In Godot editor: Bottom panel → GdUnit4 → Run All Tests
# Expected: 4 FAILED (FloatingOriginSystem doesn't exist yet)
```

**Commit:**
```bash
git add tests/unit/test_floating_origin.gd
git commit -m "Test: Add floating origin tests (RED - expected to fail)"
```

---

### Step 2: GREEN (Write Minimum Code)

**Create:** `scripts/core/floating_origin.gd`

```gdscript
extends Node
class_name FloatingOriginSystem
## Keeps player near origin to prevent floating-point precision issues

signal universe_shifted(offset: Vector3)

const SHIFT_THRESHOLD := 10000.0  # 10km

var origin_offset := Vector3.ZERO
var tracked_objects: Array[Node3D] = []

func register_object(obj: Node3D) -> void:
    """Register object to be shifted with universe"""
    if obj not in tracked_objects:
        tracked_objects.append(obj)

func unregister_object(obj: Node3D) -> void:
    """Unregister object from shifting"""
    tracked_objects.erase(obj)

func _physics_process(_delta: float) -> void:
    """Check if shift needed and execute"""
    var player_pos := _get_player_position()

    if player_pos.length() > SHIFT_THRESHOLD:
        shift_universe(-player_pos)

func _get_player_position() -> Vector3:
    """Get position of object to keep centered (usually player/ship)"""
    if tracked_objects.size() > 0:
        return tracked_objects[0].global_position
    return Vector3.ZERO

func shift_universe(offset: Vector3) -> void:
    """Shift all tracked objects by offset"""
    origin_offset += offset

    for obj in tracked_objects:
        if is_instance_valid(obj):
            obj.global_position += offset

    universe_shifted.emit(offset)
```

**Run tests:**
```bash
# GdUnit4 → Run All Tests
# Expected: 4 PASSED
```

**Commit:**
```bash
git add scripts/core/floating_origin.gd
git commit -m "Implement: FloatingOriginSystem (GREEN - tests pass)"
```

---

### Step 3: REFACTOR (Improve Code)

**Improvements:**
```gdscript
# Add input validation
func register_object(obj: Node3D) -> void:
    assert(obj != null, "Cannot register null object")
    if obj not in tracked_objects:
        tracked_objects.append(obj)

# Add performance optimization
func _physics_process(_delta: float) -> void:
    # Only check every 10 frames (not every frame)
    if Engine.get_process_frames() % 10 != 0:
        return

    var player_pos := _get_player_position()
    if player_pos.length() > SHIFT_THRESHOLD:
        shift_universe(-player_pos)

# Add logging
func shift_universe(offset: Vector3) -> void:
    print("[FloatingOrigin] Shifting universe by %v" % offset)
    origin_offset += offset

    for obj in tracked_objects:
        if is_instance_valid(obj):
            obj.global_position += offset

    universe_shifted.emit(offset)
```

**Run tests:**
```bash
# GdUnit4 → Run All Tests
# Expected: 4 PASSED (still passing after refactor)
```

**Commit:**
```bash
git add scripts/core/floating_origin.gd
git commit -m "Refactor: Add validation, optimization, and logging to FloatingOriginSystem"
```

---

### Step 4: VERIFY (Test in VR)

**Create:** `scenes/features/floating_origin_test.tscn`

```gdscript
# Attach to root node
extends Node3D

@onready var floating_origin := get_node("/root/FloatingOriginSystem") if has_node("/root/FloatingOriginSystem") else null
var ship: CharacterBody3D

func _ready() -> void:
    # Create simple ship
    ship = CharacterBody3D.new()
    add_child(ship)

    if floating_origin:
        floating_origin.register_object(ship)

    print("[FloatingOriginTest] Use WASD to move far from origin")
    print("[FloatingOriginTest] Watch position reset when > 10km")

func _physics_process(delta: float) -> void:
    # Simple movement for testing
    var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    ship.velocity = Vector3(input.x, 0, input.y) * 1000.0  # Fast movement for testing
    ship.move_and_slide()

    # Display position
    if Engine.get_process_frames() % 60 == 0:  # Every second
        print("Ship position: %v (distance: %.1f km)" % [ship.position, ship.position.length() / 1000.0])
```

**Manual Test:**
1. Press F6 (run current scene)
2. Hold WASD to move
3. Watch console: position should reset when > 10km
4. Verify no jitter or stuttering

**Document:**
```markdown
# Floating Origin VR Test Report
**Date:** 2025-12-09
**Feature:** FloatingOriginSystem
**Status:** ✅ PASSED

## Tests
- ✅ Unit tests: 4/4 passed
- ✅ Manual VR test: Passed
- ✅ Performance: 90 FPS maintained
- ✅ No jitter observed

## Issues Found
None

## Next Steps
Integrate into main game
```

---

## TDD Guidelines for Each System

### Physics Systems

**Test:**
- Deterministic behavior (same input = same output)
- Edge cases (zero gravity, infinite mass, etc.)
- Performance (< 3ms for physics frame)

**Example:**
```gdscript
func test_orbital_mechanics_deterministic():
    var ship1 = create_test_ship()
    var ship2 = create_test_ship()

    # Same inputs
    ship1.position = Vector3(1000, 0, 0)
    ship2.position = Vector3(1000, 0, 0)

    # Simulate
    simulate_physics(ship1, 1.0)
    simulate_physics(ship2, 1.0)

    # Should have identical results
    assert_eq(ship1.position, ship2.position)
```

### VR Systems

**Test:**
- Controller tracking (mock input)
- Comfort features (vignette intensity)
- Performance (90 FPS requirement)

**Example:**
```gdscript
func test_vignette_increases_with_speed():
    var comfort = VRComfortSystem.new()
    add_child_autofree(comfort)

    # Slow movement
    comfort.update_vignette(1.0)
    var low_intensity = comfort.vignette_intensity

    # Fast movement
    comfort.update_vignette(20.0)
    var high_intensity = comfort.vignette_intensity

    assert_gt(high_intensity, low_intensity)
```

### Networking Systems

**Test:**
- State serialization/deserialization
- Deterministic physics
- Sync accuracy

**Example:**
```gdscript
func test_ship_state_serialization():
    var ship = Ship.new()
    ship.position = Vector3(100, 200, 300)
    ship.velocity = Vector3(10, 20, 30)

    # Serialize
    var packed_data = ship.serialize()

    # Deserialize
    var ship2 = Ship.new()
    ship2.deserialize(packed_data)

    # Should match
    assert_eq(ship2.position, ship.position)
    assert_eq(ship2.velocity, ship.velocity)
```

---

## Daily TDD Workflow

### Morning Routine

1. **Pull latest code**
```bash
git pull origin main
```

2. **Run all tests**
```bash
# In Godot: GdUnit4 → Run All Tests
# Expected: All green before starting work
```

3. **Plan today's feature**
```markdown
Feature: Planetary Landing
Tests needed:
- test_detect_landing_surface()
- test_landing_gear_deployment()
- test_transition_to_landed_state()
```

### Development Cycle (Per Feature)

**For each feature:**

1. **RED: Write test (10 minutes)**
```gdscript
func test_landing_gear_deploys_when_near_surface():
    # Write failing test
    pass
```

2. **Run test → FAIL** (expected)

3. **GREEN: Implement (30-60 minutes)**
```gdscript
# Write minimum code to pass
```

4. **Run test → PASS**

5. **REFACTOR: Clean up (10 minutes)**
```gdscript
# Improve code quality
```

6. **Run tests → STILL PASS**

7. **Commit**
```bash
git add .
git commit -m "Feature: Landing gear deployment (TDD)"
```

8. **VERIFY: Test in VR (5-10 minutes)**
- Put on headset
- Test feature manually
- Document results

### End of Day

1. **Run full test suite**
```bash
# All tests must pass before commit
```

2. **Update test report**
```markdown
## 2025-12-09
- Features added: 3
- Tests written: 8
- Tests passing: 42/42
- VR verification: ✅ All features tested
```

3. **Commit if all green**
```bash
git commit -m "End of day: All tests passing"
git push
```

---

## Test Coverage Goals

**Phase 1: Core Physics**
- Target: 90% coverage
- Critical: Floating origin, gravity, orbital mechanics

**Phase 2: Flight & Landing**
- Target: 85% coverage
- Critical: 6DOF controls, landing detection

**Phase 3: Multiplayer**
- Target: 95% coverage (deterministic physics required!)
- Critical: State sync, network protocol

**Phase 4: Terrain & Interaction**
- Target: 80% coverage
- Critical: Voxel generation, collision updates

**Phase 5: Advanced Features**
- Target: 70% coverage
- Critical: AI behaviors, economy systems

---

## Common TDD Patterns

### Pattern 1: Test Null Guards

```gdscript
func test_handles_null_input():
    var system = MySystem.new()

    # Should not crash
    system.process_object(null)

    # Should have sensible default behavior
    assert_eq(system.last_result, SystemResult.INVALID_INPUT)
```

### Pattern 2: Test Edge Cases

```gdscript
func test_zero_gravity():
    var gravity = GravityManager.new()

    # Zero mass planet
    var force = gravity.calculate_force(player, zero_mass_planet)

    assert_eq(force, Vector3.ZERO)
```

### Pattern 3: Test Performance

```gdscript
func test_chunk_generation_performance():
    var generator = VoxelGenerator.new()

    var start_time = Time.get_ticks_msec()
    generator.generate_chunk(Vector3i(0, 0, 0))
    var duration = Time.get_ticks_msec() - start_time

    assert_lt(duration, 5.0, "Chunk generation must be < 5ms")
```

### Pattern 4: Test Determinism

```gdscript
func test_physics_deterministic():
    var results = []

    # Run same simulation 10 times
    for i in range(10):
        var ship = create_test_ship()
        simulate_physics(ship, 1.0)
        results.append(ship.position)

    # All results should be identical
    for i in range(1, 10):
        assert_eq(results[i], results[0], "Physics must be deterministic")
```

---

## Integration with Phase Development

**Every phase includes TDD:**

1. **Plan feature** → List required tests
2. **Write tests** → RED phase
3. **Implement feature** → GREEN phase
4. **Refactor code** → Tests still pass
5. **Test in VR** → VERIFY phase
6. **Document** → Update test reports
7. **Commit** → All tests passing

**No phase is complete until:**
- ✅ All unit tests pass
- ✅ Integration tests pass
- ✅ VR manual verification complete
- ✅ Test coverage meets target

---

## Benefits You'll See

**Week 1:**
- Tests take seconds vs. minutes to run
- Catch bugs before VR testing

**Week 2-4:**
- Refactor confidently (tests verify nothing breaks)
- Add features faster (tests document behavior)

**Week 5-8:**
- Multiplayer works first try (deterministic physics tested)
- No surprise bugs in integration

**Week 9+:**
- Add features without breaking old ones
- Other developers can contribute (tests document API)

---

## Avoiding Common TDD Mistakes

**DON'T:**
- ❌ Write tests after implementing (defeats the purpose)
- ❌ Test implementation details (test behavior, not internals)
- ❌ Write huge tests (test one thing per test)
- ❌ Skip tests for "simple" features (simple features break too)
- ❌ Ignore failing tests (fix immediately or remove)

**DO:**
- ✅ Write test FIRST (RED)
- ✅ Write minimum code (GREEN)
- ✅ Refactor fearlessly (tests catch breaks)
- ✅ Test in VR after unit tests pass (VERIFY)
- ✅ Commit often (every GREEN state)

---

## TDD Success Metrics

Track these weekly:

```markdown
## Week [N] TDD Report
- Tests written: [count]
- Tests passing: [count]/[total]
- Test coverage: [%]
- Bugs caught by tests: [count]
- Bugs caught in VR: [count]
- Time saved by TDD: [estimate]
```

**Goal:** More bugs caught by tests than in VR manual testing.

---

## Next Steps

1. Read this document completely
2. Complete Phase 0 (sets up GdUnit4)
3. Start Phase 1 with TDD from day 1
4. Write test → implement → verify (repeat)

**With TDD, you won't need to rewrite this game for the 11th time. The tests will catch problems before they become rewrites.**
