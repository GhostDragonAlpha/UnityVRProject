# Writing Tests Guide - SpaceTime VR Project

**Project:** SpaceTime - AI-Assisted VR Development
**Version:** 1.0
**Date:** 2025-12-03
**Purpose:** Practical guide for writing effective tests across all test types

---

## Table of Contents

1. [GdUnit4 Test Writing](#gdunit4-test-writing)
2. [Property-Based Testing Patterns](#property-based-testing-patterns)
3. [HTTP API Testing](#http-api-testing)
4. [VR System Testing](#vr-system-testing)
5. [Common Testing Patterns](#common-testing-patterns)
6. [Mocking and Test Doubles](#mocking-and-test-doubles)
7. [Test Organization](#test-organization)
8. [Debugging Tests](#debugging-tests)

---

## GdUnit4 Test Writing

### Basic Test Structure

All GdUnit4 tests inherit from `GdUnitTestSuite`:

```gdscript
extends GdUnitTestSuite

# Optional: Setup before each test
func before_test():
    # Initialize test fixtures
    pass

# Optional: Cleanup after each test
func after_test():
    # Clean up resources
    pass

# Test methods must start with "test_"
func test_example_assertion():
    assert_that("hello world").is_equal("hello world")
    assert_that(42).is_greater(40)
```

### Installation and Setup

**Install GdUnit4**:
```bash
cd C:/godot/addons
git clone https://github.com/MikeSchulze/gdUnit4.git gdUnit4

# Enable in Godot Editor:
# Project > Project Settings > Plugins > GdUnit4 > Enable
```

**Running Tests**:
```bash
# From Godot Editor (RECOMMENDED):
# Open GdUnit4 panel (bottom of editor) > Click "Run All Tests"

# From command line:
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/

# Run specific test file:
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/test_time_manager.gd

# Run with verbose output:
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/ --verbose
```

### GdUnit4 Assertions

**Value Assertions**:
```gdscript
# Equality
assert_that(value).is_equal(expected)
assert_that(value).is_not_equal(other)

# Nullability
assert_that(value).is_null()
assert_that(value).is_not_null()

# Numeric comparisons
assert_that(42).is_greater(40)
assert_that(42).is_greater_equal(42)
assert_that(42).is_less(50)
assert_that(42).is_less_equal(42)

# Floating point (with tolerance)
assert_that(3.14159).is_equal_approx(3.14, 0.01)

# Boolean
assert_that(value).is_true()
assert_that(value).is_false()
```

**String Assertions**:
```gdscript
assert_that("hello world").contains("world")
assert_that("hello world").starts_with("hello")
assert_that("hello world").ends_with("world")
assert_that("hello world").matches("h.* w.*")  # Regex
assert_that("hello").is_empty()  # Empty string
```

**Array/Collection Assertions**:
```gdscript
var array = [1, 2, 3, 4]

assert_that(array).contains([2, 3])
assert_that(array).contains_exactly([1, 2, 3, 4])
assert_that(array).has_size(4)
assert_that(array).is_empty()  # Empty array
```

**Vector/Transform Assertions**:
```gdscript
var v1 = Vector3(1, 2, 3)
var v2 = Vector3(1, 2, 3)

assert_that(v1).is_equal(v2)
assert_that(v1).is_equal_approx(Vector3(1.001, 2.001, 3.001), Vector3(0.01, 0.01, 0.01))
```

### Unit Test Examples

**Example 1: Testing Pure Logic**

```gdscript
# tests/unit/test_time_manager.gd
extends GdUnitTestSuite

var time_manager: Node

func before_test():
    # Create fresh instance for each test
    time_manager = load("res://scripts/core/time_manager.gd").new()

func after_test():
    # Clean up
    if time_manager:
        time_manager.free()
    time_manager = null

func test_time_dilation_affects_physics_delta():
    """Test that time dilation scales physics delta correctly."""
    # Arrange
    time_manager.set_time_scale(0.5)

    # Act
    var scaled_delta = time_manager.get_physics_delta(0.016)

    # Assert
    assert_that(scaled_delta).is_equal_approx(0.008, 0.0001)

func test_time_scale_clamped_to_valid_range():
    """Test that time scale is clamped between 0.0 and 10.0."""
    # Test upper bound
    time_manager.set_time_scale(100.0)
    assert_that(time_manager.get_time_scale()).is_less_equal(10.0)

    # Test lower bound
    time_manager.set_time_scale(-5.0)
    assert_that(time_manager.get_time_scale()).is_greater_equal(0.0)

func test_pause_stops_time_progression():
    """Test that pausing stops time progression."""
    # Arrange
    time_manager.set_paused(false)
    var initial_time = time_manager.get_world_time()

    # Act
    time_manager.set_paused(true)
    time_manager.update(1.0)  # Try to advance time

    # Assert
    assert_that(time_manager.get_world_time()).is_equal(initial_time)
```

**Example 2: Testing with Mock Dependencies**

```gdscript
# tests/unit/test_floating_origin.gd
extends GdUnitTestSuite

var floating_origin: Node
var mock_camera: Node3D

func before_test():
    floating_origin = load("res://scripts/core/floating_origin_system.gd").new()

    # Create mock camera
    mock_camera = Node3D.new()
    mock_camera.position = Vector3.ZERO
    add_child(mock_camera)

func after_test():
    if mock_camera:
        mock_camera.queue_free()
    if floating_origin:
        floating_origin.free()

func test_rebase_when_camera_exceeds_threshold():
    """Test that origin rebases when camera moves beyond threshold."""
    # Arrange
    floating_origin.rebase_threshold = 1000.0
    floating_origin.set_tracked_camera(mock_camera)

    # Act - Move camera beyond threshold
    mock_camera.position = Vector3(1500, 0, 0)
    floating_origin.update(0.016)

    # Assert - Camera should be close to origin after rebase
    assert_that(mock_camera.position.length()).is_less(floating_origin.rebase_threshold)

func test_relative_positions_preserved_during_rebase():
    """Test that relative positions between objects are preserved."""
    # Arrange
    var object_a = Node3D.new()
    var object_b = Node3D.new()
    add_child(object_a)
    add_child(object_b)

    object_a.position = Vector3(100, 0, 0)
    object_b.position = Vector3(200, 0, 0)

    var initial_distance = object_a.position.distance_to(object_b.position)

    floating_origin.register_object(object_a)
    floating_origin.register_object(object_b)

    # Act - Force rebase
    mock_camera.position = Vector3(2000, 0, 0)
    floating_origin.update(0.016)

    # Assert - Distance should be preserved
    var final_distance = object_a.position.distance_to(object_b.position)
    assert_that(final_distance).is_equal_approx(initial_distance, 0.01)

    # Cleanup
    object_a.queue_free()
    object_b.queue_free()
```

### Integration Test Examples

**Example 3: Testing Subsystem Interaction**

```gdscript
# tests/integration/test_vr_comfort_integration.gd
extends GdUnitTestSuite

var vr_manager: Node
var comfort_system: Node
var xr_camera: XRCamera3D

func before_test():
    # Create VR subsystems
    vr_manager = load("res://scripts/core/vr_manager.gd").new()
    comfort_system = load("res://scripts/core/vr_comfort_system.gd").new()

    # Create XR camera for testing
    xr_camera = XRCamera3D.new()
    add_child(xr_camera)

    # Initialize systems
    vr_manager.initialize()
    comfort_system.initialize(vr_manager)

func after_test():
    if xr_camera:
        xr_camera.queue_free()
    if comfort_system:
        comfort_system.free()
    if vr_manager:
        vr_manager.free()

func test_vignette_activates_on_rapid_rotation():
    """Test that comfort vignette activates during rapid camera rotation."""
    # Arrange
    comfort_system.enable_vignette(true)
    var initial_intensity = comfort_system.get_vignette_intensity()

    # Act - Simulate rapid rotation
    for i in range(10):
        xr_camera.rotate_y(deg_to_rad(30))  # Rapid rotation
        comfort_system.update(0.016)

    # Assert - Vignette should increase
    var final_intensity = comfort_system.get_vignette_intensity()
    assert_that(final_intensity).is_greater(initial_intensity)

func test_snap_turn_rotates_in_discrete_increments():
    """Test that snap turning rotates camera in fixed increments."""
    # Arrange
    comfort_system.enable_snap_turn(true)
    comfort_system.set_snap_turn_angle(45.0)
    var initial_rotation = xr_camera.rotation.y

    # Act - Trigger snap turn
    comfort_system.trigger_snap_turn_right()
    comfort_system.update(0.016)

    # Assert - Rotation should be +45 degrees
    var expected_rotation = initial_rotation + deg_to_rad(45.0)
    assert_that(xr_camera.rotation.y).is_equal_approx(expected_rotation, 0.01)
```

---

## Property-Based Testing Patterns

### Setup and Dependencies

**Install Dependencies**:
```bash
# Create virtual environment (if not exists)
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate
# Linux/Mac:
source .venv/bin/activate

# Install requirements
pip install -r tests/property/requirements.txt
```

**Requirements** (`tests/property/requirements.txt`):
```
hypothesis>=6.0.0
pytest>=7.0.0
pytest-timeout>=2.0.0
pytest-xdist>=3.0.0  # Parallel test execution
requests>=2.28.0
```

### Basic Property Test Structure

```python
#!/usr/bin/env python3
"""
Property-based tests for [System Name].
Tests invariants that should hold for all valid inputs.
"""

import pytest
from hypothesis import given, settings, assume, strategies as st

# Define the property test
@given(
    # Define input strategies
    value=st.integers(min_value=0, max_value=100),
    factor=st.floats(min_value=0.1, max_value=10.0)
)
@settings(max_examples=100, deadline=None)
def test_property_multiplication_is_commutative(value, factor):
    """
    Property: Multiplication is commutative (a * b == b * a).
    This should hold for all valid numbers.
    """
    result1 = value * factor
    result2 = factor * value

    assert abs(result1 - result2) < 0.0001, \
        f"Commutativity failed: {value} * {factor} != {factor} * {value}"
```

### Hypothesis Strategies

**Built-in Strategies**:
```python
from hypothesis import strategies as st

# Integers
st.integers()  # Any integer
st.integers(min_value=0, max_value=100)  # Range

# Floats
st.floats()  # Any float
st.floats(min_value=0.0, max_value=1.0)  # Range
st.floats(min_value=0.0, max_value=1.0, exclude_min=True)  # Exclude bounds

# Strings
st.text()  # Any unicode string
st.text(min_size=1, max_size=100)  # Length constraints
st.text(alphabet=st.characters(whitelist_categories=('Lu',)))  # Uppercase only

# Booleans
st.booleans()

# Lists
st.lists(st.integers())  # List of integers
st.lists(st.floats(), min_size=1, max_size=10)  # Size constraints

# Tuples
st.tuples(st.integers(), st.floats())  # (int, float) tuples

# Dictionaries
st.dictionaries(keys=st.text(), values=st.integers())

# Fixed values
st.sampled_from(['option1', 'option2', 'option3'])

# Composite strategies
st.one_of(st.integers(), st.floats())  # Either int or float
```

**Custom Strategies**:
```python
# Custom strategy for valid frequencies (100-1000 Hz)
valid_frequencies = st.floats(min_value=100.0, max_value=1000.0)

# Custom strategy for Vector3
@st.composite
def vector3_strategy(draw):
    x = draw(st.floats(min_value=-100.0, max_value=100.0))
    y = draw(st.floats(min_value=-100.0, max_value=100.0))
    z = draw(st.floats(min_value=-100.0, max_value=100.0))
    return {"x": x, "y": y, "z": z}

# Usage
@given(position=vector3_strategy())
def test_position_property(position):
    assert -100.0 <= position["x"] <= 100.0
```

### Property Test Examples

**Example 1: Mathematical Invariants**

```python
# tests/property/test_resonance_properties.py
import pytest
import asyncio
import aiohttp
from hypothesis import given, settings, strategies as st, assume

HTTP_API_BASE = "http://127.0.0.1:8080"

class ResonancePropertyTests:
    def __init__(self):
        self.session = None

    async def setup(self):
        self.session = aiohttp.ClientSession()

    async def teardown(self):
        if self.session:
            await self.session.close()

    async def call_api(self, endpoint: str, data: dict) -> dict:
        """Call HTTP API endpoint."""
        try:
            async with self.session.post(
                f"{HTTP_API_BASE}/{endpoint}",
                json=data,
                timeout=aiohttp.ClientTimeout(total=5)
            ) as response:
                if response.status == 200:
                    return await response.json()
                return {"error": f"HTTP {response.status}"}
        except Exception as e:
            return {"error": str(e)}

    @given(
        frequency=st.floats(min_value=100.0, max_value=1000.0),
        amplitude=st.floats(min_value=0.1, max_value=100.0),
        delta_t=st.floats(min_value=0.01, max_value=1.0)
    )
    async def test_constructive_interference_increases_amplitude(
        self, frequency: float, amplitude: float, delta_t: float
    ):
        """
        Property: Constructive interference ALWAYS increases amplitude.

        For any valid frequency, amplitude, and time delta:
        - Final amplitude > initial amplitude
        - Increase is proportional to delta_t
        - Increase never exceeds theoretical maximum
        """
        result = await self.call_api("resonance/apply_interference", {
            "object_frequency": frequency,
            "object_amplitude": amplitude,
            "emit_frequency": frequency,  # Perfect match
            "interference_type": "constructive",
            "delta_time": delta_t
        })

        if "error" not in result:
            final_amplitude = result.get("final_amplitude", amplitude)

            # Property 1: Amplitude increases
            assert final_amplitude > amplitude, \
                f"Constructive interference failed to increase amplitude: {amplitude} -> {final_amplitude}"

            # Property 2: Bounded increase
            max_increase = delta_t * 1.0  # INTERFERENCE_STRENGTH = 1.0
            assert final_amplitude <= amplitude + max_increase, \
                f"Amplitude increase exceeds bound: {final_amplitude - amplitude} > {max_increase}"

            # Property 3: Proportional to delta_t
            expected_increase = delta_t * 1.0
            actual_increase = final_amplitude - amplitude
            assert abs(actual_increase - expected_increase) < 0.01, \
                f"Increase not proportional: expected {expected_increase}, got {actual_increase}"

# Test runner helper
def run_async_test(test_method_name, *args):
    """Helper to run async tests synchronously for Hypothesis."""
    async def run_test():
        tests = ResonancePropertyTests()
        await tests.setup()
        try:
            method = getattr(tests, test_method_name)
            await method(*args)
        finally:
            await tests.teardown()

    asyncio.run(run_test())

# Pytest integration
@settings(max_examples=100, deadline=None)
@given(
    frequency=st.floats(min_value=100.0, max_value=1000.0),
    amplitude=st.floats(min_value=0.1, max_value=100.0),
    delta_t=st.floats(min_value=0.01, max_value=1.0)
)
def test_constructive_interference_increases_amplitude(frequency, amplitude, delta_t):
    """Property: Constructive interference increases amplitude."""
    run_async_test(
        "test_constructive_interference_increases_amplitude",
        frequency, amplitude, delta_t
    )
```

**Example 2: Determinism Property**

```python
# tests/property/test_procedural_determinism.py
from hypothesis import given, settings, strategies as st

@given(
    seed=st.integers(min_value=0, max_value=2**31 - 1),
    iterations=st.integers(min_value=1, max_value=10)
)
@settings(max_examples=50)
def test_planet_generation_is_deterministic(seed, iterations):
    """
    Property: Same seed produces same planet.

    For any seed, generating a planet multiple times should
    produce identical results.
    """
    import requests

    results = []
    for i in range(iterations):
        response = requests.post(
            "http://127.0.0.1:8080/procedural/generate_planet",
            json={"seed": seed}
        )

        assert response.status_code == 200
        planet_data = response.json()
        results.append(planet_data)

    # All results should be identical
    first_result = results[0]
    for result in results[1:]:
        assert result == first_result, \
            f"Determinism failed: same seed {seed} produced different planets"
```

**Example 3: Conservation Laws**

```python
# tests/property/test_physics_conservation.py
from hypothesis import given, settings, strategies as st, assume

@given(
    mass=st.floats(min_value=1.0, max_value=1000.0),
    velocity=st.floats(min_value=0.0, max_value=100.0),
    delta_t=st.floats(min_value=0.01, max_value=1.0)
)
@settings(max_examples=100)
def test_energy_conservation_in_orbit(mass, velocity, delta_t):
    """
    Property: Total energy is conserved in orbital mechanics.

    For any object in orbit, kinetic + potential energy
    should remain constant (accounting for numerical errors).
    """
    import requests

    # Calculate initial energy
    initial_response = requests.post(
        "http://127.0.0.1:8080/physics/calculate_orbital_energy",
        json={
            "mass": mass,
            "velocity": velocity,
            "altitude": 1000000.0  # 1000 km
        }
    )

    assert initial_response.status_code == 200
    initial_energy = initial_response.json()["total_energy"]

    # Simulate orbit for delta_t
    simulate_response = requests.post(
        "http://127.0.0.1:8080/physics/simulate_orbit",
        json={
            "mass": mass,
            "velocity": velocity,
            "altitude": 1000000.0,
            "duration": delta_t
        }
    )

    assert simulate_response.status_code == 200
    final_state = simulate_response.json()

    # Calculate final energy
    final_response = requests.post(
        "http://127.0.0.1:8080/physics/calculate_orbital_energy",
        json={
            "mass": mass,
            "velocity": final_state["velocity"],
            "altitude": final_state["altitude"]
        }
    )

    assert final_response.status_code == 200
    final_energy = final_response.json()["total_energy"]

    # Energy should be conserved (within 1% tolerance for numerical errors)
    energy_change_percent = abs(final_energy - initial_energy) / initial_energy * 100
    assert energy_change_percent < 1.0, \
        f"Energy not conserved: {initial_energy} -> {final_energy} ({energy_change_percent:.2f}% change)"
```

### Using `assume()` for Constraints

```python
from hypothesis import given, assume, strategies as st

@given(
    numerator=st.floats(),
    denominator=st.floats()
)
def test_division_property(numerator, denominator):
    """Property: Division by non-zero should always work."""
    # Skip test cases where denominator is zero or very close to zero
    assume(abs(denominator) > 0.001)

    result = numerator / denominator

    # Property: Multiplication should reverse division
    reversed_result = result * denominator
    assert abs(reversed_result - numerator) < 0.0001
```

---

## HTTP API Testing

### Setup

**Dependencies**:
```bash
# Install pytest and requests
pip install pytest requests pytest-timeout
```

**Test Configuration** (`tests/http_api/conftest.py`):
```python
import pytest
import requests
import time

@pytest.fixture(scope="session")
def base_url():
    """Base URL for HTTP API."""
    return "http://127.0.0.1:8080"

@pytest.fixture(scope="session")
def check_server_available(base_url):
    """Verify Godot server is running."""
    try:
        response = requests.get(f"{base_url}/status", timeout=2)
        if response.status_code != 200:
            pytest.skip("Godot server not responding")
    except requests.RequestException:
        pytest.skip("Godot server not available")

@pytest.fixture
def auth_client():
    """HTTP client with authentication (if needed)."""
    session = requests.Session()
    # Add auth headers if required
    return session
```

### HTTP API Test Examples

**Example 1: Endpoint Testing**

```python
# tests/http_api/test_scene_endpoints.py
import pytest
import requests
import time

class TestSceneEndpoints:
    """Test scene management API endpoints."""

    @pytest.mark.fast
    def test_get_current_scene_returns_200(self, base_url, auth_client, check_server_available):
        """GET /scene should return 200 with current scene info."""
        response = auth_client.get(f"{base_url}/scene")

        assert response.status_code == 200
        data = response.json()
        assert "scene_name" in data
        assert "scene_path" in data
        assert "status" in data

    def test_post_scene_loads_scene(self, base_url, auth_client):
        """POST /scene should load specified scene."""
        response = auth_client.post(
            f"{base_url}/scene",
            json={"scene_path": "res://vr_main.tscn"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "loading"
        assert data["scene"] == "res://vr_main.tscn"

        # Wait for scene to load
        time.sleep(2)

        # Verify scene loaded
        verify_response = auth_client.get(f"{base_url}/scene")
        verify_data = verify_response.json()
        assert verify_data["status"] == "loaded"
        assert "vr_main" in verify_data["scene_path"].lower()

    def test_post_scene_with_invalid_path_returns_error(self, base_url, auth_client):
        """POST /scene with invalid path should return error."""
        response = auth_client.post(
            f"{base_url}/scene",
            json={"scene_path": "res://nonexistent_scene.tscn"}
        )

        # Should return error status
        assert response.status_code >= 400
        # Or return 200 with error in JSON
        if response.status_code == 200:
            data = response.json()
            assert "error" in data or data.get("status") == "error"
```

**Example 2: Performance Testing**

```python
# tests/http_api/test_performance.py
import pytest
import requests
import time

class TestAPIPerformance:
    """Test API response time performance."""

    @pytest.mark.performance
    def test_status_endpoint_responds_quickly(self, base_url, auth_client):
        """GET /status should respond in < 100ms."""
        start = time.time()
        response = auth_client.get(f"{base_url}/status")
        elapsed = time.time() - start

        assert response.status_code == 200
        assert elapsed < 0.1, f"Response took {elapsed*1000:.1f}ms, expected <100ms"

    @pytest.mark.performance
    def test_scene_query_performance(self, base_url, auth_client):
        """GET /scene should respond in < 50ms (p95)."""
        response_times = []

        # Make 20 requests
        for _ in range(20):
            start = time.time()
            response = auth_client.get(f"{base_url}/scene")
            elapsed = time.time() - start
            response_times.append(elapsed)

            assert response.status_code == 200

        # Calculate p95
        response_times.sort()
        p95_time = response_times[int(len(response_times) * 0.95)]

        assert p95_time < 0.05, f"p95 response time {p95_time*1000:.1f}ms, expected <50ms"
```

**Example 3: Integration Workflows**

```python
# tests/http_api/test_integration_workflows.py
import pytest
import requests
import time

class TestIntegrationWorkflows:
    """Test complete API workflows."""

    def test_connect_reload_execute_workflow(self, base_url, auth_client):
        """Test typical development workflow: connect -> reload -> execute."""
        # Step 1: Initialize connections
        connect_response = auth_client.post(f"{base_url}/connect")
        assert connect_response.status_code == 200

        time.sleep(1)  # Allow connections to establish

        # Step 2: Check status
        status_response = auth_client.get(f"{base_url}/status")
        assert status_response.status_code == 200
        status_data = status_response.json()
        assert status_data.get("overall_ready") == True

        # Step 3: Reload a script
        reload_response = auth_client.post(
            f"{base_url}/execute/reload",
            json={"file_path": "res://scripts/core/engine.gd"}
        )
        assert reload_response.status_code == 200

        # Step 4: Execute GDScript
        execute_response = auth_client.post(
            f"{base_url}/execute/gdscript",
            json={"code": "print('Integration test successful')"}
        )
        assert execute_response.status_code == 200
```

---

## VR System Testing

### Challenges in VR Testing

1. **Headset Required**: Full VR validation requires physical hardware
2. **Comfort Metrics**: Subjective (motion sickness, discomfort)
3. **Frame Rate**: Must maintain 90 FPS consistently
4. **3D Interactions**: Complex spatial relationships

### VR Testing Strategies

**Strategy 1: Mock VR Components**

```gdscript
# tests/unit/test_vr_comfort_system.gd
extends GdUnitTestSuite

var comfort_system: Node
var mock_camera: Node3D

func before_test():
    comfort_system = load("res://scripts/core/vr_comfort_system.gd").new()
    mock_camera = Node3D.new()
    add_child(mock_camera)

func test_vignette_intensity_increases_with_rotation_speed():
    """Test vignette responds to rotation speed."""
    # Enable vignette
    comfort_system.enable_vignette(true)

    # Simulate slow rotation
    for i in range(5):
        mock_camera.rotate_y(deg_to_rad(5))  # Slow
        comfort_system.update(0.016)
    var slow_intensity = comfort_system.get_vignette_intensity()

    # Reset
    comfort_system.reset_vignette()

    # Simulate fast rotation
    for i in range(5):
        mock_camera.rotate_y(deg_to_rad(30))  # Fast
        comfort_system.update(0.016)
    var fast_intensity = comfort_system.get_vignette_intensity()

    # Fast rotation should produce higher vignette intensity
    assert_that(fast_intensity).is_greater(slow_intensity)
```

**Strategy 2: Performance Monitoring**

```python
# tests/performance/test_vr_frame_rate.py
import pytest
import requests
import time
import asyncio
import websockets
import json

async def monitor_frame_rate(duration_seconds=10):
    """Monitor frame rate via telemetry WebSocket."""
    uri = "ws://127.0.0.1:8081"
    frame_times = []

    async with websockets.connect(uri) as websocket:
        # Send handshake
        await websocket.send(json.dumps({"type": "handshake", "client_id": "test"}))

        start_time = time.time()
        while time.time() - start_time < duration_seconds:
            try:
                message = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                data = json.loads(message)

                if data.get("type") == "binary_telemetry":
                    fps = data.get("fps", 0)
                    frame_times.append(fps)
            except asyncio.TimeoutError:
                continue

    return frame_times

@pytest.mark.vr
@pytest.mark.performance
def test_maintains_90_fps_during_gameplay():
    """Test that VR maintains ≥90 FPS during typical gameplay."""
    # Run frame rate monitoring
    frame_rates = asyncio.run(monitor_frame_rate(duration_seconds=10))

    # Calculate metrics
    avg_fps = sum(frame_rates) / len(frame_rates)
    min_fps = min(frame_rates)
    p1_fps = sorted(frame_rates)[int(len(frame_rates) * 0.01)]  # 1st percentile

    # Assertions
    assert avg_fps >= 90.0, f"Average FPS {avg_fps:.1f} below 90 FPS target"
    assert p1_fps >= 80.0, f"1st percentile FPS {p1_fps:.1f} too low (< 80 FPS)"
    assert min_fps >= 60.0, f"Minimum FPS {min_fps:.1f} critically low (< 60 FPS)"
```

**Strategy 3: Manual VR Validation Checklist**

Create structured manual test procedures:

```python
# tests/vr_playtest_framework.py
"""
Manual VR Testing Checklist

Run this script to guide through manual VR validation.
"""

import time

class VRPlaytestChecklist:
    """Interactive checklist for manual VR testing."""

    def __init__(self):
        self.results = {}

    def test_comfort_no_motion_sickness(self):
        """Test: Motion sickness prevention."""
        print("\n=== VR Comfort Test: Motion Sickness ===")
        print("Instructions:")
        print("1. Put on VR headset")
        print("2. Move through environment for 5 minutes")
        print("3. Perform various actions (walk, turn, interact)")
        print("4. Rate comfort level")

        input("Press Enter when ready to start...")

        print("\n[Timer started - 5 minutes]")
        time.sleep(300)  # 5 minutes

        print("\nTest complete.")
        comfort_rating = input("Comfort rating (1-10, 10=no discomfort): ")

        self.results["motion_sickness"] = {
            "rating": int(comfort_rating),
            "passed": int(comfort_rating) >= 7
        }

        return int(comfort_rating) >= 7

    def test_vignette_activation(self):
        """Test: Vignette activates during rapid movement."""
        print("\n=== VR Comfort Test: Vignette ===")
        print("Instructions:")
        print("1. Enable vignette in settings")
        print("2. Perform rapid turning motion")
        print("3. Observe if vignette (darkening edges) appears")

        input("Press Enter when ready...")

        observed_vignette = input("Did vignette appear during rapid motion? (y/n): ")

        self.results["vignette"] = {
            "observed": observed_vignette.lower() == 'y',
            "passed": observed_vignette.lower() == 'y'
        }

        return observed_vignette.lower() == 'y'

    def run_all_tests(self):
        """Run complete VR playtest checklist."""
        print("=" * 60)
        print("VR PLAYTEST FRAMEWORK")
        print("=" * 60)

        tests = [
            self.test_comfort_no_motion_sickness,
            self.test_vignette_activation,
            # Add more manual tests...
        ]

        for test in tests:
            test()

        # Print summary
        print("\n" + "=" * 60)
        print("TEST SUMMARY")
        print("=" * 60)
        for test_name, result in self.results.items():
            status = "✓ PASS" if result["passed"] else "✗ FAIL"
            print(f"{status} - {test_name}")

if __name__ == "__main__":
    checklist = VRPlaytestChecklist()
    checklist.run_all_tests()
```

---

## Common Testing Patterns

### Pattern 1: Arrange-Act-Assert (AAA)

```gdscript
func test_example():
    # Arrange - Set up test preconditions
    var system = SystemUnderTest.new()
    system.set_initial_value(42)

    # Act - Perform the action being tested
    system.process_update()

    # Assert - Verify the expected outcome
    assert_that(system.get_result()).is_equal(84)
```

### Pattern 2: Test Fixtures

```gdscript
extends GdUnitTestSuite

# Fixture: Reusable test data
const TEST_FREQUENCIES = [100.0, 440.0, 880.0, 1000.0]

var system: Node

func before_test():
    # Setup: Create fresh instance before each test
    system = load("res://scripts/gameplay/resonance_system.gd").new()

func after_test():
    # Teardown: Clean up after each test
    if system:
        system.free()
    system = null

func test_with_fixture():
    for frequency in TEST_FREQUENCIES:
        system.set_frequency(frequency)
        assert_that(system.get_frequency()).is_equal(frequency)
```

### Pattern 3: Parameterized Tests

```gdscript
extends GdUnitTestSuite

func test_time_scale_values(value = test_parameters([
    [0.0, 0.0],    # [input, expected_output]
    [0.5, 0.5],
    [1.0, 1.0],
    [2.0, 2.0],
    [100.0, 10.0]  # Should clamp to max 10.0
])):
    var time_manager = TimeManager.new()
    time_manager.set_time_scale(value[0])
    assert_that(time_manager.get_time_scale()).is_equal(value[1])
    time_manager.free()
```

### Pattern 4: Testing Async Operations

```gdscript
func test_async_scene_load():
    var scene_loader = SceneLoader.new()

    # Start async load
    scene_loader.load_scene_async("res://test_scene.tscn")

    # Wait for completion signal
    await scene_loader.load_completed

    # Verify scene loaded
    assert_that(scene_loader.is_scene_loaded()).is_true()
    assert_that(scene_loader.get_loaded_scene()).is_not_null()
```

---

## Mocking and Test Doubles

### When to Use Mocks

- Isolate unit under test from dependencies
- Avoid expensive operations (file I/O, network, rendering)
- Control test conditions precisely
- Test error scenarios

### Mock Patterns

**Pattern 1: Simple Mock**

```gdscript
# tests/unit/mock_spacecraft.gd
extends Node

var position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO

func apply_thrust(direction: Vector3, magnitude: float):
    velocity += direction * magnitude

func update(delta: float):
    position += velocity * delta
```

**Pattern 2: Mock with Call Tracking**

```gdscript
# tests/unit/mock_audio_manager.gd
extends Node

var play_sound_calls = []

func play_sound(sound_name: String, volume: float = 1.0):
    play_sound_calls.append({
        "sound": sound_name,
        "volume": volume,
        "timestamp": Time.get_ticks_msec()
    })

func was_sound_played(sound_name: String) -> bool:
    return play_sound_calls.any(func(call): return call.sound == sound_name)

func get_play_count(sound_name: String) -> int:
    return play_sound_calls.filter(func(call): return call.sound == sound_name).size()
```

**Pattern 3: Spy (Partial Mock)**

```gdscript
# tests/unit/spy_physics_engine.gd
extends PhysicsEngine  # Inherit from real implementation

var update_calls = []

# Override specific methods
func update(delta: float):
    update_calls.append(delta)
    super.update(delta)  # Call real implementation

func get_update_count() -> int:
    return update_calls.size()
```

---

## Test Organization

### Directory Structure

```
tests/
├── unit/                    # GdUnit4 unit tests
│   ├── test_time_manager.gd
│   ├── test_resonance_system.gd
│   └── mock_*.gd           # Mock objects
├── integration/             # GdUnit4 integration tests
│   ├── test_core_engine_validation.gd
│   ├── test_vr_integration.gd
│   └── test_resonance_full_game.gd
├── property/                # Python property-based tests
│   ├── test_resonance_properties.py
│   ├── test_physics_conservation.py
│   └── generators.py       # Custom Hypothesis strategies
├── http_api/                # Python HTTP API tests
│   ├── test_scene_endpoints.py
│   ├── test_resonance_endpoints.py
│   └── conftest.py         # Pytest configuration
├── performance/             # Performance/load tests
│   ├── test_vr_frame_rate.py
│   └── test_api_latency.py
├── test_runner.py           # Main test orchestrator
├── health_monitor.py        # Service health checks
└── feature_validator.py     # Feature validation suite
```

### Naming Conventions

**GdUnit4 Tests**:
- File: `test_<system_name>.gd`
- Class: `extends GdUnitTestSuite`
- Method: `func test_<what_is_being_tested>():`

**Python Tests**:
- File: `test_<feature>.py`
- Class: `class Test<Feature>:`
- Method: `def test_<what_is_being_tested>(self):`

**Property Tests**:
- File: `test_<system>_properties.py`
- Method: `def test_property_<property_name>():`

---

## Debugging Tests

### GdUnit4 Debugging

**Print Debugging**:
```gdscript
func test_example():
    var result = calculate_something()
    print("Result: ", result)  # Will appear in test output
    assert_that(result).is_equal(expected)
```

**Breakpoint Debugging**:
```gdscript
func test_example():
    var result = calculate_something()
    breakpoint  # Execution pauses here (if debugger attached)
    assert_that(result).is_equal(expected)
```

**Run Single Test**:
```bash
# Run only specific test file
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/test_time_manager.gd
```

### Python Test Debugging

**Print Debugging**:
```python
def test_example():
    result = calculate_something()
    print(f"Debug: result = {result}")  # Use pytest -s to see output
    assert result == expected
```

**Run with Output**:
```bash
# Show print statements
pytest tests/property/test_resonance_properties.py -s

# Verbose output
pytest tests/property/test_resonance_properties.py -v

# Show full error traces
pytest tests/property/test_resonance_properties.py --tb=long
```

**Run Single Test**:
```bash
# Run specific test function
pytest tests/property/test_resonance_properties.py::test_constructive_interference_increases_amplitude
```

**Hypothesis Debugging**:
```python
from hypothesis import given, settings, Verbosity

@settings(verbosity=Verbosity.verbose)  # Shows all generated examples
@given(st.integers())
def test_with_verbose_output(value):
    assert value >= 0  # Will fail, showing failing example
```

---

## Summary

### Quick Reference

| Test Type | Tool | File Location | Run Command |
|-----------|------|---------------|-------------|
| Unit | GdUnit4 | `tests/unit/` | `godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/unit/` |
| Integration | GdUnit4 | `tests/integration/` | `godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/integration/` |
| Property | Hypothesis | `tests/property/` | `pytest tests/property/test_*.py` |
| HTTP API | pytest | `tests/http_api/` | `pytest tests/http_api/` |
| All Tests | test_runner | Root | `python tests/test_runner.py` |

### Best Practices Summary

1. ✅ Write tests for new features before implementation (TDD)
2. ✅ Keep tests focused and independent
3. ✅ Use descriptive test names that explain what is being validated
4. ✅ Mock external dependencies for unit tests
5. ✅ Use property-based tests for mathematical invariants
6. ✅ Validate VR performance with telemetry monitoring
7. ✅ Run tests frequently during development
8. ✅ Maintain high coverage on critical systems

### Next Steps

1. Review [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) for strategic guidance
2. Check [TEST_COVERAGE_REPORT.md](./TEST_COVERAGE_REPORT.md) for priority areas
3. Start writing tests for your current feature
4. Run `python tests/test_runner.py` to validate your changes

---

**Document Version**: 1.0
**Last Updated**: 2025-12-03
**Next Review**: 2025-12-10
