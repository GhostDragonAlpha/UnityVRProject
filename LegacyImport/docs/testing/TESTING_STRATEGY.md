# Testing Strategy - SpaceTime VR Project

**Project:** SpaceTime - AI-Assisted VR Development
**Version:** 1.0
**Date:** 2025-12-03
**Purpose:** Comprehensive testing strategy for SpaceTime VR project with focus on AI-assisted development

---

## Table of Contents

1. [Testing Philosophy](#testing-philosophy)
2. [Test Types Overview](#test-types-overview)
3. [When to Use Each Test Type](#when-to-use-each-test-type)
4. [Coverage Goals](#coverage-goals)
5. [Test Pyramid Structure](#test-pyramid-structure)
6. [Testing Workflow](#testing-workflow)
7. [Continuous Testing](#continuous-testing)
8. [Quality Gates](#quality-gates)

---

## Testing Philosophy

### Core Principles

1. **Test What Matters**: Focus on functionality, edge cases, and system integration over 100% line coverage
2. **Fast Feedback**: Unit tests run in <5s, integration tests in <30s, full suite in <5 minutes
3. **AI-Observable**: All tests produce structured telemetry for AI agent consumption
4. **VR-Aware**: Tests account for VR-specific requirements (90 FPS, comfort, 3D interactions)
5. **Fail-Fast**: Tests detect problems early in development cycle
6. **Maintainable**: Tests are clear, focused, and resistant to refactoring

### Testing Goals

- **Reliability**: Catch bugs before they reach production
- **Confidence**: Enable rapid iteration without fear of breaking existing functionality
- **Documentation**: Tests serve as executable specifications
- **Performance**: Ensure VR frame rate requirements (90 FPS) are met
- **Integration**: Verify complex subsystem interactions work correctly

---

## Test Types Overview

### 1. Unit Tests (GdUnit4)

**Technology**: GdUnit4 (GDScript testing framework)
**Scope**: Individual classes and methods in isolation
**Speed**: Fast (milliseconds per test)
**When**: Test pure logic, calculations, state management

**Characteristics**:
- Test single responsibility units
- Mock external dependencies
- No file I/O, network, or scene tree dependencies
- Deterministic and repeatable
- High throughput (hundreds of tests per second)

**Example Systems**:
- `TimeManager` - Time dilation calculations
- `RelativityManager` - Physics formulas
- `SettingsManager` - Configuration validation
- `CoordinateSystem` - Coordinate transformations

### 2. Integration Tests (GdUnit4)

**Technology**: GdUnit4 with scene instantiation
**Scope**: Multiple systems working together
**Speed**: Medium (100ms-1s per test)
**When**: Test subsystem interactions, scene behavior

**Characteristics**:
- Test 2-4 systems interacting
- May instantiate minimal scene tree
- Validate data flow between systems
- Test autoload interactions
- May use real implementations with limited scope

**Example Systems**:
- VR Manager + Comfort System
- Floating Origin + Physics Engine
- Resonance System + Audio Feedback
- Spacecraft + Transition System

### 3. Property-Based Tests (Python + Hypothesis)

**Technology**: Python, Hypothesis framework, HTTP API
**Scope**: Mathematical properties and invariants
**Speed**: Medium (10-100 examples per property)
**When**: Test universal truths that should hold for all inputs

**Characteristics**:
- Generate random test inputs
- Verify invariants across input space
- Excellent for catching edge cases
- Test mathematical correctness
- Validate API contracts

**Example Properties**:
- Constructive interference always increases amplitude
- Destructive interference always decreases amplitude
- Frequency match quality is proportional to effect
- Orbital calculations conserve energy
- Floating origin maintains relative positions

### 4. HTTP API Tests (Python + pytest)

**Technology**: Python, pytest, requests library
**Scope**: Remote control API endpoints
**Speed**: Medium (100ms-500ms per test)
**When**: Test AI agent control interface

**Characteristics**:
- Test all REST API endpoints
- Verify request/response contracts
- Test authentication and authorization
- Validate error handling
- Check performance thresholds

**Example Endpoints**:
- `/connect` - Initialize debug connections
- `/scene` - Scene management
- `/execute/reload` - Hot-reload scripts
- `/resonance/*` - Game logic commands
- `/telemetry/*` - Metrics and monitoring

### 5. End-to-End Tests (Manual + Automated)

**Technology**: GDScript integration tests, manual VR testing
**Scope**: Complete user workflows
**Speed**: Slow (10s-60s per scenario)
**When**: Validate critical user paths and VR experiences

**Characteristics**:
- Test full gameplay scenarios
- Require VR headset for complete validation
- Include human evaluation (comfort, usability)
- May be partially automated
- Focus on high-value user journeys

**Example Scenarios**:
- Player spawn → VR calibration → movement → interaction
- Spacecraft piloting → atmospheric entry → walking mode
- Resonance puzzle → frequency matching → object manipulation
- Tutorial flow → mission completion → save/load

### 6. Performance Tests (Python + Telemetry)

**Technology**: Python, WebSocket telemetry, metrics collection
**Scope**: Frame rate, memory, latency
**Speed**: Medium to slow (15s-60s per test)
**When**: Validate VR performance requirements

**Characteristics**:
- Monitor real-time telemetry
- Verify 90 FPS minimum in VR
- Check memory usage patterns
- Measure API response times
- Test load scenarios

**Example Tests**:
- Frame rate during scene transitions
- Memory usage with procedural generation
- API latency under load
- Physics simulation performance
- Rendering pipeline optimization

---

## When to Use Each Test Type

### Decision Matrix

| Scenario | Recommended Test Type | Rationale |
|----------|----------------------|-----------|
| Pure calculation (physics, math) | Unit Test | Fast, deterministic, isolated |
| Subsystem interaction | Integration Test | Validates contracts between systems |
| Mathematical invariants | Property-Based Test | Explores edge cases automatically |
| API endpoint behavior | HTTP API Test | Validates remote control interface |
| User workflow | End-to-End Test | Validates complete experience |
| VR frame rate | Performance Test | Ensures VR comfort requirements |
| Edge case discovery | Property-Based Test | Hypothesis generates unusual inputs |
| Regression prevention | Unit + Integration | Fast feedback on changes |
| New feature validation | Integration + E2E | Validates feature works end-to-end |
| Performance regression | Performance Test | Catches performance degradation |

### System Type Guidelines

#### Core Engine Systems
**Coverage Goal**: 80%+ unit tests, 60%+ integration tests

Systems: `ResonanceEngine`, `TimeManager`, `RelativityManager`, `FloatingOriginSystem`, `PhysicsEngine`

**Recommended Tests**:
- Unit tests for all calculations and state management
- Integration tests for initialization sequence
- Property tests for physics invariants
- Performance tests for frame rate impact

#### VR Systems
**Coverage Goal**: 70%+ unit tests, 80%+ integration tests, mandatory E2E testing

Systems: `VRManager`, `VRComfortSystem`, `HapticManager`, `XROrigin3D`

**Recommended Tests**:
- Unit tests for comfort calculations (vignette, snap turn)
- Integration tests for VR manager + comfort system
- E2E tests for VR experience (manual, in-headset)
- Performance tests for 90 FPS validation

#### Gameplay Systems
**Coverage Goal**: 70%+ unit tests, 60%+ integration tests, 40%+ property tests

Systems: `ResonanceSystem`, `MissionSystem`, `HazardSystem`, `TutorialSystem`

**Recommended Tests**:
- Unit tests for game logic and rules
- Property tests for mathematical correctness (resonance physics)
- Integration tests for gameplay flow
- HTTP API tests for remote control

#### UI Systems
**Coverage Goal**: 50%+ unit tests, 60%+ integration tests

Systems: `HUD`, `MenuSystem`, `WarningSystem`, `TrajectoryDisplay`

**Recommended Tests**:
- Unit tests for UI state management
- Integration tests for UI + game state
- E2E tests for UI workflows
- Accessibility tests (font size, contrast, readability)

#### Procedural Generation
**Coverage Goal**: 60%+ unit tests, 40%+ property tests

Systems: `UniverseGenerator`, `PlanetGenerator`, `BiomeSystem`, `StarCatalog`

**Recommended Tests**:
- Unit tests for generation algorithms
- Property tests for determinism (same seed = same output)
- Property tests for constraints (valid orbital parameters)
- Performance tests for generation time

#### AI Debug Connection
**Coverage Goal**: 80%+ unit tests, 70%+ integration tests, 90%+ HTTP API tests

Systems: `GodotBridge`, `DAPAdapter`, `LSPAdapter`, `TelemetryServer`, `ConnectionManager`

**Recommended Tests**:
- Unit tests for protocol parsing
- Integration tests for DAP + LSP integration
- HTTP API tests for all endpoints
- Property tests for connection state management
- Performance tests for telemetry throughput

---

## Coverage Goals

### Minimum Coverage Targets

| Category | Unit Test Coverage | Integration Test Coverage | Property Test Coverage |
|----------|-------------------|---------------------------|------------------------|
| **Critical Systems** | 80%+ | 60%+ | 40%+ |
| **Core Engine** | 75%+ | 60%+ | 30%+ |
| **VR Systems** | 70%+ | 80%+ | 20%+ |
| **Gameplay** | 70%+ | 60%+ | 40%+ |
| **UI Systems** | 50%+ | 60%+ | 10%+ |
| **Utilities** | 60%+ | 30%+ | 20%+ |
| **Overall Project** | 65%+ | 55%+ | 25%+ |

### Coverage Quality Over Quantity

- **Focus on Edge Cases**: Tests should cover boundary conditions, not just happy paths
- **Test Failure Modes**: Include tests for error handling and recovery
- **Integration Points**: Heavy coverage on system boundaries
- **Performance-Critical Paths**: 90%+ coverage on render loop, physics loop, input processing

### Acceptable Lower Coverage

Some systems naturally have lower test coverage:
- **Visual Systems**: Shader code, rendering pipeline (validated manually in VR)
- **One-Time Setup**: Initialization code with minimal logic
- **Error Handlers**: Defensive code that rarely executes
- **Debug/Development Tools**: Non-production utilities

---

## Test Pyramid Structure

### Ideal Distribution (by count and execution time)

```
                 ▲
               /   \
             /  E2E  \      ← 5% (slowest, most fragile)
           /  (10-20) \
         /--------------\
       /                  \
     /    Integration      \  ← 20% (medium speed)
   /      (100-200)         \
 /---------------------------\
/                             \
/         Unit Tests           \  ← 75% (fastest, most stable)
/          (400-800)            \
/________________________________\
```

### Current Project Status

**Unit Tests**: ~120 tests (target: 400-800)
**Integration Tests**: ~40 tests (target: 100-200)
**Property Tests**: ~60 tests (target: 80-150)
**HTTP API Tests**: ~40 tests (target: 60-100)
**E2E Tests**: ~15 scenarios (target: 20-30)

### Priority Expansion Areas

1. **Core Engine**: Add more unit tests for physics calculations
2. **VR Systems**: Expand integration tests for comfort features
3. **Procedural Generation**: Add property tests for determinism
4. **Gameplay**: Expand property tests for resonance mechanics
5. **AI Connection**: Maintain high HTTP API test coverage

---

## Testing Workflow

### Development Cycle

**1. Before Writing Code (TDD Approach)**
```bash
# Write failing test first
# Define expected behavior
# Implement feature to make test pass
```

**2. During Development**
```bash
# Run relevant unit tests frequently
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/test_<system>.gd

# Use hot-reload for rapid iteration
curl -X POST http://127.0.0.1:8080/execute/reload -d '{"file_path":"res://scripts/..."}'
```

**3. Before Committing**
```bash
# Run full test suite
python tests/test_runner.py

# Check for failures
# Fix any broken tests
# Ensure new code has test coverage
```

**4. After Committing**
```bash
# Run health checks
python tests/health_monitor.py

# Verify telemetry
python telemetry_client.py

# Test in VR (for VR-related changes)
# Launch in headset, validate comfort and performance
```

### Test-Driven Development (TDD)

**Red-Green-Refactor Cycle**:

1. **Red**: Write a failing test that defines desired behavior
2. **Green**: Write minimal code to make the test pass
3. **Refactor**: Improve code quality while keeping tests green

**Example - Adding Time Dilation Feature**:

```gdscript
# Step 1: Write failing test
func test_time_dilation_affects_physics_delta():
    time_manager.set_time_scale(0.5)
    var delta = time_manager.get_physics_delta(0.016)
    assert_that(delta).is_equal(0.008)  # FAILS - not implemented

# Step 2: Implement feature
func get_physics_delta(base_delta: float) -> float:
    return base_delta * time_scale

# Step 3: Test passes, refactor if needed
```

### Continuous Testing

**During Development Session**:
- Run unit tests after each significant change (every 5-10 minutes)
- Run integration tests every 30 minutes
- Monitor telemetry continuously

**Pre-Commit**:
- Full test suite must pass
- No new warnings or errors
- Performance benchmarks within thresholds

**Post-Commit**:
- Health monitor validates all services
- Telemetry confirms system stability
- VR validation for VR-related changes

---

## Quality Gates

### Pre-Commit Quality Gate

**Required Checks**:
- ✅ All unit tests pass
- ✅ All integration tests pass
- ✅ Property tests pass (or known failures documented)
- ✅ HTTP API tests pass
- ✅ No new GDScript warnings/errors
- ✅ Code follows project style guide

**Optional Checks** (for VR/performance changes):
- ⚠️ Frame rate ≥ 90 FPS in VR
- ⚠️ No motion sickness triggers
- ⚠️ API response times < 100ms (critical endpoints)

### Pre-Merge Quality Gate

**Required Checks**:
- ✅ All pre-commit checks pass
- ✅ Full test suite passes
- ✅ Performance tests show no regression
- ✅ E2E tests pass for affected features
- ✅ Documentation updated

**VR-Specific Checks**:
- ✅ Tested in VR headset (for VR changes)
- ✅ Comfort validation passed
- ✅ No frame rate drops

### Release Quality Gate

**Required Checks**:
- ✅ 100% of critical tests pass
- ✅ 95%+ of all tests pass
- ✅ Performance benchmarks meet targets
- ✅ All E2E scenarios validated
- ✅ VR comfort validation complete
- ✅ Load testing passed
- ✅ Security tests passed (HTTP API)

**Metrics Targets**:
- Unit test coverage: ≥ 65%
- Integration test coverage: ≥ 55%
- Frame rate (VR): ≥ 90 FPS sustained
- API latency: < 50ms (p95)
- Memory usage: < 4GB (typical gameplay)

---

## Continuous Testing

### Automated Test Execution

**On File Save** (via IDE/editor):
- Run affected unit tests
- Lint GDScript files

**On Commit** (via Git hooks):
- Run full unit test suite
- Run fast integration tests
- Check code formatting

**On Push** (via CI/CD - if configured):
- Run complete test suite
- Generate coverage reports
- Run performance benchmarks
- Deploy to staging environment

### Monitoring and Telemetry

**Real-Time Monitoring**:
```bash
# Monitor system health
python tests/health_monitor.py

# Watch telemetry stream
python telemetry_client.py

# Check API status
curl http://127.0.0.1:8080/status
```

**Periodic Validation**:
- Run health checks every 5 minutes during development
- Run full test suite before breaks/end of day
- Run performance tests daily
- Run complete E2E validation weekly

### Test Report Generation

**Automated Reports**:
- Test results saved to `test-reports/` directory
- JSON format for AI agent consumption
- Latest results symlinked to `test-reports/latest.json`

**Report Contents**:
- Pass/fail status per test
- Execution time per test
- Coverage metrics
- Performance metrics
- Error details and stack traces

---

## Testing Best Practices

### General Guidelines

1. **Arrange-Act-Assert**: Structure tests clearly
2. **One Assertion Per Test**: Keep tests focused (or related assertions)
3. **Descriptive Names**: Test names should explain what they validate
4. **Independent Tests**: No dependencies between tests
5. **Fast Execution**: Optimize test speed without sacrificing coverage
6. **Maintainable**: Tests should be easy to update when requirements change

### GDScript Testing

```gdscript
# Good: Clear test name, focused assertion
func test_time_dilation_slows_physics_simulation():
    time_manager.set_time_scale(0.5)
    var delta = time_manager.get_physics_delta(1.0)
    assert_that(delta).is_equal(0.5)

# Bad: Unclear name, multiple unrelated assertions
func test_time_stuff():
    time_manager.set_time_scale(0.5)
    assert_that(time_manager.time_scale).is_equal(0.5)
    assert_that(time_manager.is_paused()).is_false()
    assert_that(time_manager.get_frame_count()).is_greater(0)
```

### Property-Based Testing

```python
# Good: Tests universal property with clear documentation
@given(
    frequency=st.floats(min_value=100.0, max_value=1000.0),
    amplitude=st.floats(min_value=0.1, max_value=100.0)
)
def test_constructive_interference_increases_amplitude(frequency, amplitude):
    """
    Property: Constructive interference ALWAYS increases amplitude.
    This should hold for any valid frequency and amplitude.
    """
    result = apply_interference(frequency, amplitude, interference="constructive")
    assert result.final_amplitude > amplitude

# Bad: No documentation, arbitrary constraints
@given(st.floats(), st.floats())
def test_thing(f, a):
    result = do_thing(f, a)
    assert result > 0  # Why? Under what conditions?
```

### HTTP API Testing

```python
# Good: Clear test purpose, validates specific contract
def test_scene_endpoint_returns_current_scene_info(auth_client, base_url):
    """GET /scene should return current scene name and path."""
    response = auth_client.get(f"{base_url}/scene")

    assert response.status_code == 200
    data = response.json()
    assert "scene_name" in data
    assert "scene_path" in data
    assert data["scene_path"].startswith("res://")

# Bad: Testing too many things, unclear purpose
def test_scene_stuff(auth_client, base_url):
    r1 = auth_client.get(f"{base_url}/scene")
    r2 = auth_client.post(f"{base_url}/scene", json={...})
    assert r1.status_code == 200 and r2.status_code == 200
```

---

## Summary

### Key Takeaways

1. **Diverse Testing Strategy**: Use multiple test types for comprehensive coverage
2. **Fast Feedback Loops**: Prioritize fast unit tests for rapid iteration
3. **VR-Specific Validation**: Always validate VR comfort and performance
4. **AI-Observable**: Tests produce structured data for AI agent consumption
5. **Continuous Improvement**: Regularly expand test coverage in priority areas

### Next Steps

1. Review [WRITING_TESTS_GUIDE.md](./WRITING_TESTS_GUIDE.md) for detailed test authoring instructions
2. Check [TEST_COVERAGE_REPORT.md](./TEST_COVERAGE_REPORT.md) for current coverage status
3. Run `python tests/test_runner.py` to validate current system state
4. Set up continuous testing in your development workflow
5. Contribute new tests to priority expansion areas

---

**Document Version**: 1.0
**Last Updated**: 2025-12-03
**Next Review**: 2025-12-10
