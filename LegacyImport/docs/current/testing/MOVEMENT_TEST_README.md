# Movement Test Suite Documentation

## Overview

The `movement_test_suite.py` is a comprehensive automated test suite for validating player movement capabilities in the SpaceTime VR project. It tests all fundamental movement mechanics without requiring manual input.

## Features

### Tests Included

1. **Position Baseline** - Establishes initial player position for comparisons
2. **Walk Forward (W key)** - Tests forward movement
3. **Walk Backward (S key)** - Tests backward movement
4. **Walk Left (A key)** - Tests leftward movement
5. **Walk Right (D key)** - Tests rightward movement
6. **Sprint Movement (Shift + W)** - Validates sprint is faster than walk
7. **Jump (Space key)** - Tests vertical jump mechanics
8. **Collision Detection** - Verifies player stays on ground with low variance
9. **Movement Speed Validation** - Ensures speed is within reasonable range (1-5 m/s)
10. **Input Responsiveness** - Measures latency of input response

### Test Quality Indicators

- **[OK]** - Test passed all criteria
- **[WARNING]** - Test passed but with suboptimal metrics
- **[ERROR]** - Test failed critical validation

### Measurements Provided

- Position deltas (3D vectors in meters)
- Movement speed (m/s)
- Test duration for each test
- Y-axis variance for collision detection
- Input latency measurements

## Prerequisites

1. **Godot Engine** running with debug protocols enabled
2. **HTTP API** accessible at `http://127.0.0.1:8080`
3. **Python 3.8+** with `requests` library installed

## Setup

### 1. Ensure Godot is Running with Debug Support

Start Godot with the required debug flags (from the project root):

```bash
# Windows - Recommended
./restart_godot_with_debug.bat

# Or manually
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

**IMPORTANT**: The editor MUST run in GUI mode (non-headless). Running headless will cause debug servers to stop responding.

### 2. Verify HTTP API Connection

Test that the API is accessible:

```bash
curl http://127.0.0.1:8080/status
```

You should receive a JSON response with `"overall_ready": true`.

### 3. Install Python Dependencies

```bash
# Create/activate virtual environment (recommended)
python -m venv .venv

# Windows
.venv\Scripts\activate

# Linux/Mac
source .venv/bin/activate

# Install requests library
pip install requests
```

## Usage

### Basic Run

```bash
# From project root
python movement_test_suite.py
```

### Example Output

```
======================================================================
SPACETIME MOVEMENT TEST SUITE
======================================================================
Target: http://127.0.0.1:8080
Timeout: 20s

[1.2s] Checking connection to Godot API...
[1.3s] ✓ Walk Forward (W key): Player moved 1.234m forward

... [more tests] ...

======================================================================
TEST RESULTS
======================================================================

[OK] Position Baseline (0.45s)
      Initial position: V3(10.50, 1.80, 5.25)

[OK] Walk Forward (W key) (1.50s)
      Player moved 1.234m forward
      Position delta: V3(0.02, 0.00, 1.23) (magnitude: 1.234m)

[OK] Walk Backward (S key) (1.50s)
      Player moved 0.987m backward
      Position delta: V3(-0.01, 0.00, -0.98) (magnitude: 0.987m)

[OK] Walk Left (A key) (1.50s)
      Player moved 1.100m left
      Position delta: V3(-1.10, 0.00, 0.03) (magnitude: 1.100m)

[OK] Walk Right (D key) (1.50s)
      Player moved 1.150m right
      Position delta: V3(1.15, 0.00, -0.02) (magnitude: 1.150m)

[OK] Sprint Movement (Shift + W) (3.00s)
      Sprint faster than walk (walk: 1.234m, sprint: 2.100m)
      Position delta: V3(0.87, 0.00, 0.87) (magnitude: 1.231m)

[OK] Jump (Space key) (2.80s)
      Jump detected (vertical rise: 0.450m)
      Position delta: V3(0.00, 0.45, 0.00) (magnitude: 0.450m)

[OK] Collision Detection (1.00s)
      Stable ground collision (Y variance: 0.0023m, avg height: 1.80m)

[OK] Movement Speed Validation (1.00s)
      Reasonable movement speed: 1.234 m/s
      Velocity: V3(1.23, 0.00, 0.00)

[OK] Input Responsiveness (1.20s)
      Good input responsiveness (avg: 0.215s, max: 0.350s)

======================================================================
SUMMARY
======================================================================
Passed:   10/10
Warnings: 0/10
Errors:   0/10
Total Time: 15.4s
======================================================================

✓ All critical tests passed!
```

## Exit Codes

- **0** - All tests passed (no errors)
- **1** - One or more tests failed

Use in CI/CD pipelines:

```bash
python movement_test_suite.py
if [ $? -eq 0 ]; then
    echo "All movement tests passed!"
else
    echo "Movement tests failed!"
    exit 1
fi
```

## Troubleshooting

### Connection Refused

```
Error: Cannot connect to Godot API at http://127.0.0.1:8080
```

**Solution:**
- Ensure Godot is running with `--dap-port 6006 --lsp-port 6005` flags
- Verify it's running in GUI mode (not headless)
- Check firewall settings for port 8080
- Wait 5-10 seconds after launching Godot for services to initialize

### Tests Timeout After 20s

The suite auto-terminates after 20 seconds. If tests don't complete:
- Godot may be unresponsive
- Network issues between test suite and API
- Physics engine may not be running

### Position Not Changing

If movement tests show no position delta:
- Player may be in a frozen state
- Walking controller may not be active
- Input system may not be processing keyboard events
- Check that the player is spawned in a valid scene

### Low Movement Speeds

If movement speed seems low:
- Physics timestep may be reduced
- Player may have movement restrictions
- Gravity may be affecting movement (check vertical component)
- Walking speed export variable may be reduced

## Integration with CI/CD

Add to your test pipeline:

```bash
#!/bin/bash

# Start Godot with debug services in background
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005 &
GODOT_PID=$!

# Wait for services to initialize
sleep 10

# Run movement tests
python movement_test_suite.py
TEST_RESULT=$?

# Clean up
kill $GODOT_PID

exit $TEST_RESULT
```

## Test Parameters

Modify test parameters by editing the class initialization:

```python
# Default timeout: 20 seconds
suite = MovementTestSuite(timeout=30.0)

# Custom API host/port
suite = MovementTestSuite(host="127.0.0.1", port=8080)

# Run tests
exit_code = suite.run_all_tests()
```

## Limitations

1. **VR Mode**: Tests use keyboard inputs (desktop mode). VR controller inputs require additional implementation.
2. **Position API**: Position retrieval depends on debug adapter being connected. Fallback methods are implemented.
3. **Scene State**: Tests assume a valid player exists in the scene.
4. **Physics Simulation**: Tests assume physics is running at standard 90 FPS (VR refresh rate).

## Implementation Details

### Vector3 Class
Custom Vector3 implementation for position tracking:
- Distance calculations
- Magnitude/length operations
- Subtraction for delta measurements

### TestResult Dataclass
Structured result storage:
- Status (OK/WARNING/ERROR)
- Message with details
- Duration
- Optional position delta and velocity

### Connection Strategy
1. Connects to HTTP API at port 8080
2. Uses debug/evaluate endpoints to query player position
3. Sends keyboard input via Input system simulation
4. Polls position at intervals to detect movement

## Performance Metrics

Typical test execution times:
- Individual test: 1.0-3.0 seconds
- Full suite: 15-20 seconds
- Total time budget: 20 seconds (auto-terminating)

## Output Format

Each test outputs:
```
[STATUS] Test Name (duration)
      Message with result details
      Position delta: V3(...) (magnitude: ...m)
      Additional metrics as applicable
```

Summary provides:
- Pass/Warning/Error count
- Total execution time
- Overall success status

## Future Enhancements

Possible additions:
- VR controller input simulation
- Mouse movement/rotation testing
- Terrain-specific gravity validation
- Multi-player movement coordination
- Performance profiling during movement
- Frame time stability analysis
- Animation state validation

## Support

For issues or questions:
1. Check CLAUDE.md for project setup requirements
2. Review DEVELOPMENT_WORKFLOW.md for movement system architecture
3. Verify Godot is running with proper debug flags
4. Check telemetry_client.py for real-time monitoring
