# Testing Guide

Comprehensive guide to testing the SpaceTime VR project.

## Table of Contents

- [Overview](#overview)
- [Test Types](#test-types)
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [CI/CD Integration](#cicd-integration)
- [Troubleshooting](#troubleshooting)

---

## Overview

SpaceTime uses a multi-layered testing approach:

1. **GdUnit4 Tests** - GDScript unit tests for game logic
2. **Property-Based Tests** - Hypothesis tests for edge cases
3. **API Integration Tests** - HTTP/WebSocket endpoint validation
4. **Performance Tests** - Benchmarks and load testing
5. **Health Checks** - Service availability monitoring

### Test Infrastructure

```
tests/
├── unit/              # GdUnit4 unit tests (.gd files)
├── property/          # Hypothesis property tests (.py files)
├── integration/       # Integration test suites
├── performance/       # Performance benchmarks
├── health_monitor.py  # Health check system
├── test_runner.py     # Legacy test runner
└── run_gdunit.py      # GdUnit4 wrapper

Root level:
├── run_all_tests.py   # Comprehensive test orchestrator
└── test_*.py          # API endpoint tests
```

---

## Test Types

### 1. GdUnit4 Unit Tests

**Location:** `tests/unit/test_*.gd`

**Framework:** [GdUnit4](https://github.com/MikeSchulze/gdUnit4)

**Purpose:** Test individual GDScript classes and functions in isolation.

**Example:**

```gdscript
extends GdUnitTestSuite

func test_player_movement():
    var player = auto_free(Player.new())
    player.velocity = Vector3(1, 0, 0)
    player.move(0.016)  # One frame at 60 FPS
    assert_that(player.position.x).is_greater(0)
```

**Running:**

```bash
# Via run_all_tests.py
python run_all_tests.py --filter unit

# Via dedicated runner
python tests/run_gdunit.py tests/unit

# From Godot editor
# Use GdUnit4 panel at bottom of editor
```

### 2. Property-Based Tests

**Location:** `tests/property/test_*.py`

**Framework:** [Hypothesis](https://hypothesis.readthedocs.io/)

**Purpose:** Test properties that should hold for all inputs, discover edge cases.

**Example:**

```python
from hypothesis import given, strategies as st

@given(st.floats(min_value=0, max_value=100))
def test_battery_never_exceeds_capacity(charge_amount):
    battery = Battery(capacity=100)
    battery.charge(charge_amount)
    assert battery.current_charge <= battery.capacity
```

**Running:**

```bash
# Via run_all_tests.py
python run_all_tests.py --filter property

# Via pytest directly
cd tests/property
pytest -v
```

### 3. API Integration Tests

**Location:** `test_*.py` (root level)

**Framework:** pytest with aiohttp

**Purpose:** Test HTTP API endpoints and WebSocket connections.

**Example:**

```python
import pytest
import aiohttp

@pytest.mark.asyncio
async def test_status_endpoint():
    async with aiohttp.ClientSession() as session:
        async with session.get("http://127.0.0.1:8080/status") as resp:
            assert resp.status == 200
            data = await resp.json()
            assert "overall_ready" in data
```

**Running:**

```bash
# Via run_all_tests.py
python run_all_tests.py --filter api

# Individual test file
pytest test_mandatory_debug.py -v
```

### 4. Performance Tests

**Location:** `tests/performance_benchmarks.py`, `tests/load_testing.py`

**Framework:** Custom async benchmarks

**Purpose:** Measure response times, throughput, memory usage.

**Running:**

```bash
# Via run_all_tests.py (skipped with --quick)
python run_all_tests.py --filter perf

# Direct execution
python tests/performance_benchmarks.py
```

### 5. Health Checks

**Location:** `tests/health_monitor.py`

**Purpose:** Verify all debug services (DAP, LSP, HTTP API, Telemetry) are running.

**Running:**

```bash
# Continuous monitoring
python tests/health_monitor.py --interval 30

# Single check (used by run_all_tests.py)
python run_all_tests.py --filter health
```

---

## Running Tests

### Quick Start

```bash
# Run all tests
python run_all_tests.py

# Run with verbose output
python run_all_tests.py -v

# Run specific test type
python run_all_tests.py --filter unit
python run_all_tests.py --filter property
python run_all_tests.py --filter api

# Quick mode (skip slow tests)
python run_all_tests.py --quick

# Generate coverage
python run_all_tests.py --coverage
```

### Comprehensive Test Runner

The `run_all_tests.py` script is the main test orchestrator:

**Features:**
- Automatic test discovery
- Parallel execution support
- Multiple report formats (JSON, Markdown, HTML)
- Coverage reporting
- Exit codes for CI/CD

**Usage:**

```bash
python run_all_tests.py [OPTIONS]

Options:
  -v, --verbose         Show detailed output
  --filter PATTERN      Run only tests matching pattern
  --coverage            Generate code coverage reports
  --quick               Skip slow/long-running tests
  --parallel            Run tests in parallel (planned)
  --format FORMAT       Report format: json|markdown|html|all
  --output DIR          Output directory (default: ./test-reports)
  --timeout SECONDS     Global timeout (default: 1800)
  --no-report           Skip report generation
  --ci                  CI mode: strict exit codes
```

**Examples:**

```bash
# Full test suite with all reports
python run_all_tests.py

# Quick validation before commit
python run_all_tests.py --quick --filter unit

# CI pipeline mode
python run_all_tests.py --ci --format json --output build/test-reports

# Debug failing tests
python run_all_tests.py --verbose --filter api
```

### Report Formats

#### JSON Report

**Location:** `test-reports/test-report-YYYYMMDD_HHMMSS.json`

**Structure:**

```json
{
  "timestamp": "2025-12-02T12:00:00",
  "test_run_id": "20251202_120000",
  "summary": {
    "total_tests": 150,
    "total_passed": 145,
    "total_failed": 5,
    "success_rate": 96.7
  },
  "suites": {
    "GdUnit4": { ... },
    "Property": { ... }
  }
}
```

#### Markdown Report

**Location:** `test-reports/TEST_REPORT_YYYYMMDD_HHMMSS.md`

**Example:**

```markdown
# Test Report - 2025-12-02 12:00:00

## Summary
- **Total Tests**: 150
- **Passed**: 145 (96.7%)
- **Failed**: 5

## Test Suites
### ✅ GdUnit4
- **Total**: 80
- **Passed**: 78
...
```

#### HTML Dashboard

**Location:** `test-reports/test-report-YYYYMMDD_HHMMSS.html`

Interactive HTML dashboard with:
- Visual progress bars
- Color-coded results
- Expandable test details
- Summary metrics

Open in browser: `file:///path/to/test-reports/test-report-latest.html`

---

## Writing Tests

### Writing GdUnit4 Tests

**1. Create test file:**

```bash
# tests/unit/test_my_feature.gd
```

**2. Extend GdUnitTestSuite:**

```gdscript
extends GdUnitTestSuite

# Runs before each test
func before_test():
    pass

# Runs after each test
func after_test():
    pass

# Test functions must start with "test_"
func test_feature_works():
    var obj = MyFeature.new()
    assert_that(obj).is_not_null()
    assert_that(obj.calculate(5)).is_equal(10)
```

**3. Common Assertions:**

```gdscript
# Equality
assert_that(value).is_equal(expected)
assert_that(value).is_not_equal(unexpected)

# Comparisons
assert_that(value).is_greater(5)
assert_that(value).is_less(10)

# Nullability
assert_that(obj).is_not_null()
assert_that(obj).is_null()

# Booleans
assert_that(condition).is_true()
assert_that(condition).is_false()

# Strings
assert_that(text).contains("substring")
assert_that(text).starts_with("prefix")

# Arrays
assert_that(array).has_size(5)
assert_that(array).contains([1, 2, 3])
```

**4. Memory Management:**

```gdscript
# Auto-free objects after test
var obj = auto_free(MyClass.new())

# Queue free for nodes
var node = auto_queue_free(Node3D.new())
```

### Writing Property-Based Tests

**1. Create test file:**

```bash
# tests/property/test_my_properties.py
```

**2. Import Hypothesis:**

```python
from hypothesis import given, strategies as st, settings
import pytest

@given(st.integers(min_value=0, max_value=100))
@settings(max_examples=100)
def test_property_holds_for_all_inputs(value):
    result = my_function(value)
    assert result >= 0  # Property: result is always non-negative
```

**3. Custom Strategies:**

```python
# Define reusable input generators
@st.composite
def battery_state(draw):
    capacity = draw(st.floats(min_value=10, max_value=1000))
    charge = draw(st.floats(min_value=0, max_value=capacity))
    return {"capacity": capacity, "charge": charge}

@given(battery_state())
def test_battery_discharge(state):
    battery = Battery(state["capacity"])
    battery.current_charge = state["charge"]
    battery.discharge(10)
    assert battery.current_charge >= 0
```

**4. Settings:**

```python
from hypothesis import settings

@settings(
    max_examples=1000,      # Number of test cases
    deadline=1000,          # Timeout per example (ms)
    suppress_health_check=[...],
)
```

### Writing API Tests

**1. Create test file:**

```bash
# test_my_api.py (root level)
```

**2. Use pytest with async:**

```python
import pytest
import aiohttp

@pytest.mark.asyncio
async def test_endpoint():
    async with aiohttp.ClientSession() as session:
        async with session.post(
            "http://127.0.0.1:8080/my/endpoint",
            json={"param": "value"}
        ) as resp:
            assert resp.status == 200
            data = await resp.json()
            assert data["success"] is True
```

**3. Test Setup/Teardown:**

```python
@pytest.fixture
async def http_session():
    session = aiohttp.ClientSession()
    yield session
    await session.close()

@pytest.mark.asyncio
async def test_with_fixture(http_session):
    async with http_session.get("http://...") as resp:
        assert resp.status == 200
```

---

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/tests.yml`:

```yaml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: windows-latest

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'

    - name: Install Python dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r tests/requirements.txt
        pip install -r tests/property/requirements.txt

    - name: Install Godot
      run: |
        # Download and install Godot 4.5+
        # Set up GdUnit4 addon

    - name: Start Godot with debug services
      run: |
        start godot --path . --dap-port 6006 --lsp-port 6005
        timeout /t 10

    - name: Run tests
      run: |
        python run_all_tests.py --ci --format json --output test-reports

    - name: Upload test results
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: test-reports
        path: test-reports/

    - name: Publish test summary
      if: always()
      run: |
        # Parse JSON report and create GitHub summary
        python .github/scripts/publish_summary.py
```

### Exit Codes

`run_all_tests.py` follows standard exit code conventions:

- **0** - All tests passed
- **1** - One or more tests failed
- **2** - Test discovery failed
- **3** - Test execution error

**CI Integration:**

```bash
# Run tests and check exit code
python run_all_tests.py --ci
if [ $? -eq 0 ]; then
    echo "Tests passed!"
else
    echo "Tests failed!"
    exit 1
fi
```

### Pre-commit Hooks

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash

echo "Running quick tests before commit..."
python run_all_tests.py --quick --filter unit

if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi

echo "All tests passed!"
```

Make executable:

```bash
chmod +x .git/hooks/pre-commit
```

---

## Troubleshooting

### Common Issues

#### 1. Godot Not Found

**Error:**

```
FileNotFoundError: godot executable not found
```

**Solution:**

Add Godot to PATH or update `run_gdunit.py`:

```python
def find_godot_executable(project_root):
    possible_paths = [
        "godot",
        "C:/your/custom/path/godot.exe",  # Add your path
    ]
```

#### 2. GdUnit4 Not Installed

**Error:**

```
Script 'addons/gdUnit4/bin/GdUnitCmdTool.gd' not found
```

**Solution:**

```bash
cd addons
git clone https://github.com/MikeSchulze/gdUnit4.git gdUnit4
```

Or install via Godot AssetLib.

#### 3. Debug Services Not Running

**Error:**

```
Connection refused to 127.0.0.1:8080
```

**Solution:**

Start Godot with debug flags:

```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

Wait 10-15 seconds for services to initialize.

#### 4. Python Dependencies Missing

**Error:**

```
ModuleNotFoundError: No module named 'hypothesis'
```

**Solution:**

```bash
# Install test dependencies
pip install -r tests/requirements.txt
pip install -r tests/property/requirements.txt
```

#### 5. Tests Timeout

**Error:**

```
Tests exceeded timeout of 300s
```

**Solution:**

Increase timeout:

```bash
python run_all_tests.py --timeout 600
```

Or skip slow tests:

```bash
python run_all_tests.py --quick
```

### Debug Mode

Run tests with verbose output:

```bash
python run_all_tests.py -v --filter unit
```

This shows:
- Detailed test output
- Error stack traces
- Timing information
- Test discovery details

### Manual Test Execution

For debugging specific tests:

**GdUnit4:**

```bash
# Run specific test file from Godot editor
# Or use command line:
godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd \
    -a tests/unit/test_my_feature.gd \
    --ignoreHeadlessMode
```

**Pytest:**

```bash
# Run specific test file
pytest test_my_api.py -v

# Run specific test function
pytest test_my_api.py::test_status_endpoint -v

# Run with debugger
pytest test_my_api.py --pdb
```

---

## Test Coverage

### Generating Coverage Reports

```bash
# Full coverage report
python run_all_tests.py --coverage

# Coverage reports generated:
# - htmlcov/index.html (HTML report)
# - coverage.json (JSON data)
```

### Viewing Coverage

Open HTML report:

```bash
# Windows
start htmlcov/index.html

# Linux/Mac
open htmlcov/index.html
```

### Coverage Targets

- **Unit Tests**: Aim for 80%+ coverage of core systems
- **Integration Tests**: Cover all critical user paths
- **API Tests**: 100% endpoint coverage

---

## Best Practices

### 1. Test Naming

**GdUnit4:**

```gdscript
# ✅ Good
func test_player_takes_damage_when_hit():

# ❌ Bad
func test1():
```

**Pytest:**

```python
# ✅ Good
def test_battery_depletes_during_usage():

# ❌ Bad
def test_battery():
```

### 2. Test Organization

Group related tests:

```gdscript
# Test suite for spacecraft systems
extends GdUnitTestSuite

func test_thrust_increases_velocity():
    pass

func test_rotation_changes_orientation():
    pass

func test_fuel_depletes_during_burn():
    pass
```

### 3. Test Independence

Each test should be self-contained:

```gdscript
# ✅ Good - creates own data
func test_feature():
    var obj = MyClass.new()
    obj.setup()
    assert_that(obj.value).is_equal(0)

# ❌ Bad - depends on previous test state
var shared_obj = MyClass.new()

func test_first():
    shared_obj.value = 5

func test_second():
    assert_that(shared_obj.value).is_equal(5)  # Fragile!
```

### 4. Meaningful Assertions

```gdscript
# ✅ Good - clear what's being tested
assert_that(player.health).is_equal(100, "Player should start with full health")

# ❌ Bad - unclear
assert_that(player.health).is_equal(100)
```

### 5. Test Speed

- Keep unit tests fast (<100ms each)
- Use mocks for slow dependencies
- Mark slow tests for skipping with `--quick`

---

## Resources

- [GdUnit4 Documentation](https://github.com/MikeSchulze/gdUnit4)
- [Hypothesis Documentation](https://hypothesis.readthedocs.io/)
- [Pytest Documentation](https://docs.pytest.org/)
- [Godot Testing Best Practices](https://docs.godotengine.org/en/stable/contributing/development/core_and_modules/unit_testing.html)

---

## FAQ

**Q: How do I run tests without Godot GUI?**

A: Use headless mode for GdUnit4:

```bash
godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd \
    -a tests/unit --ignoreHeadlessMode
```

**Q: Can I run tests in parallel?**

A: Planned feature. Currently, test suites run sequentially. Use `--parallel` flag once implemented.

**Q: How do I skip specific tests?**

A: GdUnit4: Rename file to `test_*.gd.disabled`

Pytest: Use `@pytest.mark.skip` decorator

**Q: How long should the full test suite take?**

A: Target: <5 minutes for full suite, <30 seconds for quick mode.

**Q: How do I add a new test type?**

A:
1. Create test files in appropriate directory
2. Update `TestDiscovery` in `run_all_tests.py`
3. Add executor if needed
4. Update this guide

---

**Last Updated:** 2025-12-02
