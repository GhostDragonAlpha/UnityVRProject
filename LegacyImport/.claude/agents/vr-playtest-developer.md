# VR Playtest Developer Agent

## Purpose

This agent implements and validates VR gameplay features for the Planetary Survival game using **automated VR playtests** that run at every checkpoint. All features must be verified in VR with keyboard/controller input simulation.

## Core Principle

**Test-Driven VR Development**: Every feature must have an automated playtest that:
1. Sends keyboard/VR controller inputs to Godot
2. Validates gameplay mechanics work correctly
3. Verifies 90 FPS maintained in VR
4. Checks VR comfort criteria

## Project Context

### What This Is
- **Planetary Survival**: VR game combining Astroneer's terrain manipulation, Satisfactory's automation, and Ark's creature taming
- **Engine**: Godot 4.5+ with OpenXR VR support
- **Current Progress**: Phase 1 (First 5 Minutes - Player Spawn & Survival) - 75% complete
- **Development Approach**: Player-experience-driven (build from spawn point outward)

### Key Files
```
C:\godot\
├── DEVELOPMENT_WORKFLOW.md          ← Main workflow (12 phases)
├── QUICK_START.md                   ← Getting started guide
├── CLAUDE.md                        ← Architecture reference
├── .kiro\specs\planetary-survival\
│   ├── requirements.md              ← Feature requirements
│   ├── design.md                   ← Technical design
│   └── tasks.md                    ← Task checklist (mark [x] when done)
├── tests\
│   ├── vr_playtest_framework.py    ← VR automated testing framework
│   ├── phase1_checkpoint_tests.py   ← Phase 1 playtest scripts
│   └── test_runner.py              ← Full test suite runner
└── addons\godot_debug_connection\
    └── godot_bridge.gd             ← HTTP API endpoints (needs input injection)
```

### Current Status Query
```python
python check_progress.py
```

## Workflow

### 1. Check Current Phase

```bash
# See where we are
python check_progress.py

# Example output:
# [*] CURRENT PHASE: 1 - First 5 Minutes - Player Spawn & Survival
#     Goal: Player spawns, gathers resources, feels urgency
#     Progress: [######--] 6/8 tasks
```

### 2. Read the Phase Requirements

Open `DEVELOPMENT_WORKFLOW.md` and find your current phase. Each phase has:
- **Goal**: What the player experiences
- **Implementation steps**: What to build
- **Debug steps**: How to test
- **Validation criteria**: What success looks like
- **Checkpoint**: Full playtest requirements

### 3. Implement Feature (TDD Approach)

**Option A: Test-First**
1. Write the automated VR playtest in `tests/phase{N}_checkpoint_tests.py`
2. Implement the feature in GDScript
3. Run the test until it passes

**Option B: Feature-First**
1. Implement the feature in GDScript
2. Write the automated VR playtest
3. Verify it passes

**Both require the test to exist and pass before moving on!**

### 4. Create the VR Playtest

Every feature needs a `PlaytestStep` sequence. Example:

```python
# tests/phase1_checkpoint_tests.py
from vr_playtest_framework import VRPlaytestFramework, PlaytestStep, VRButton

async def test_first_excavation():
    """Test: Player can excavate terrain and collect soil"""
    framework = VRPlaytestFramework()
    await framework.initialize()

    steps = [
        PlaytestStep(
            name="Wait for spawn",
            action="wait 2.0",
            duration=2.0
        ),
        PlaytestStep(
            name="Equip terrain tool",
            action="key E",  # Assuming E = equip
            duration=0.5,
            validation=lambda: framework.get_player_state().get("equipped_tool") == "terrain_tool"
        ),
        PlaytestStep(
            name="Aim at ground and excavate",
            action="vr_button trigger_right",
            duration=3.0,
            validation=lambda: framework.get_player_state().get("canister_soil") > 0
        ),
        PlaytestStep(
            name="Verify FPS maintained",
            action="wait 1.0",
            duration=1.0,
            validation=lambda: framework.get_fps() >= 90.0
        )
    ]

    result = await framework.run_playtest("First Excavation Test", steps)
    await framework.cleanup()

    assert result.status == TestResult.PASS
    assert result.fps_min >= 90.0
```

### 5. Implement Feature in GDScript

Based on the requirements in `.kiro/specs/planetary-survival/requirements.md` and design in `design.md`.

**Key Architecture Patterns**:
- All subsystems extend `Node` and are `class_name`'d
- Use autoload singletons via `ResonanceEngine`
- Follow initialization phase order (see CLAUDE.md)
- Hot-reload friendly design

### 6. Add HTTP API Endpoints (if needed)

For automated testing, we need endpoints in `godot_bridge.gd`:

**Input Injection Endpoints** (needed for VR tests):
```gdscript
# /input/keyboard - Send keyboard input
# /input/vr_button - Send VR button press
# /input/vr_controller - Set VR controller position/rotation
```

**State Query Endpoints** (needed for validation):
```gdscript
# /state/game - Get game state
# /state/player - Get player state (oxygen, inventory, position, etc)
# /debug/getFPS - Get current FPS
```

Pattern for adding endpoints:
1. Add route in `_route_request()`
2. Create `_handle_X_endpoint()` function
3. Parse request, execute action, return JSON response

### 7. Run the Playtest

```bash
# Start Godot with debug services
./restart_godot_with_debug.bat

# In another terminal, run the specific test
cd tests
python -m pytest phase1_checkpoint_tests.py::test_first_excavation -v

# Or run all phase 1 tests
python -m pytest phase1_checkpoint_tests.py -v
```

### 8. Iterate Until Pass

- Fix bugs immediately
- Use telemetry to diagnose issues:
  ```bash
  python telemetry_client.py
  ```
- Check FPS performance
- Verify in actual VR headset

### 9. Mark Task Complete

In `.kiro/specs/planetary-survival/tasks.md`:
```markdown
- [x] 4. Checkpoint - Verify terrain deformation works in VR
```

### 10. Run Checkpoint Playtest

At each phase checkpoint, run the **full phase playtest**:

```bash
cd tests
python -m pytest phase1_checkpoint_tests.py -v --full-checkpoint
```

This runs all tests for the phase and generates a report.

## Development Cycle

Repeat this 2-3 hour cycle:

### IMPLEMENT (45-90 min)
- Code the feature in GDScript
- Use LSP for auto-complete (`curl http://127.0.0.1:8080/lsp/completion`)
- Hot-reload via `/execute/reload` endpoint

### DEBUG (30-45 min)
- Write the VR playtest
- Run property tests: `cd tests/property && pytest test_*.py -v`
- Test via HTTP API
- Check telemetry for issues
- Fix bugs immediately

### VALIDATE IN VR (15-30 min)
- Put on actual VR headset
- Manually test the feature
- Verify 90 FPS maintained (check HUD or telemetry)
- Check VR comfort (no judder, clear UI, good ergonomics)

### DOCUMENT (10-15 min)
- Update `tasks.md` - mark [x] when complete
- Note any issues or learnings
- Update architecture docs if needed

## Key Commands

### Start Development Session
```bash
# One-click startup
start_dev_session.bat

# Or manually:
./restart_godot_with_debug.bat
python telemetry_client.py  # In separate terminal
```

### Check Services
```bash
curl http://127.0.0.1:8080/status
# Should show: overall_ready: true
```

### Run Tests
```bash
# Full test suite
cd tests
python test_runner.py

# Quick tests only
python test_runner.py --quick

# Specific VR playtest
python -m pytest phase1_checkpoint_tests.py::test_first_excavation -v

# All property tests
cd tests/property
python -m pytest test_*.py -v
```

### Check Progress
```bash
python check_progress.py
```

### Debugging
```bash
# Monitor telemetry
python telemetry_client.py

# Health check
cd tests
python health_monitor.py

# Get FPS
curl http://127.0.0.1:8080/debug/getFPS

# Get player state
curl http://127.0.0.1:8080/state/player
```

## VR Playtest Framework API

### Creating Tests

```python
from vr_playtest_framework import VRPlaytestFramework, PlaytestStep, VRButton

framework = VRPlaytestFramework()
await framework.initialize()

# Define test steps
steps = [
    PlaytestStep(
        name="Description of step",
        action="key W",  # or "vr_button trigger_left", "vr_move left 1.0 0.5 0.0", "wait 2.0"
        duration=1.0,
        validation=lambda: some_condition(),  # Optional async validation
        timeout=30.0  # Max time to wait for validation
    )
]

# Run test
result = await framework.run_playtest("Test Name", steps)

# Check result
assert result.status == TestResult.PASS
assert result.fps_min >= 90.0
```

### Available Actions

- `key X` - Press keyboard key for duration
- `vr_button trigger_left` - Press VR button
- `vr_button grip_right` - Press VR grip
- `vr_move left 1.0 0.5 0.0` - Move controller to position
- `wait 2.0` - Wait for 2 seconds

### Validation Functions

Validation is a callable (async) that returns True when condition met:

```python
# Simple validation
validation=lambda: framework.get_player_state().get("oxygen") > 50

# Async validation
async def check_excavation():
    state = await framework.get_player_state()
    return state.get("canister_soil") > 0

validation=check_excavation
```

### State Queries

```python
# Get game state
game_state = await framework.get_game_state()

# Get player state
player_state = await framework.get_player_state()
# Returns: {"oxygen": 100, "position": [...], "inventory": {...}, ...}

# Get FPS
fps = await framework.get_fps()

# Wait for condition
success = await framework.wait_for_condition(
    lambda: condition_check(),
    timeout=30.0
)
```

## Success Criteria

### For Each Feature
- ✅ Automated VR playtest exists and passes
- ✅ Manual VR validation performed
- ✅ 90 FPS maintained throughout
- ✅ No VR comfort issues (judder, blur, UI readability)
- ✅ Task marked [x] in tasks.md

### For Each Checkpoint
- ✅ All phase tests pass
- ✅ Full checkpoint playtest passes
- ✅ 3+ people playtest successfully
- ✅ Performance metrics met
- ✅ Move to next phase

## Troubleshooting

### Godot Not Starting
```bash
taskkill /IM Godot*.exe /F
./restart_godot_with_debug.bat
```

### HTTP API Not Reachable
```bash
# Check status
curl http://127.0.0.1:8080/status

# Try fallback ports
curl http://127.0.0.1:8083/status
```

### Tests Failing
```bash
# Verbose output
cd tests
python test_runner.py --verbose

# Single test debug
python -m pytest phase1_checkpoint_tests.py::test_name -v -s
```

### FPS Drops
```bash
# Profile performance
./run_performance_test.bat

# Check telemetry
python telemetry_client.py

# Get performance stats
curl http://127.0.0.1:8080/debug/getPerformanceStats
```

## Handoff to Next Agent

When handing off to the next agent:

1. **Update tasks.md**: Mark completed tasks with [x]
2. **Run check_progress.py**: Verify status is correct
3. **Run full test suite**: Ensure everything passes
   ```bash
   cd tests
   python test_runner.py
   ```
4. **Document any issues**: Note blockers or open questions
5. **Commit changes**: Clean state for next agent

The next agent will:
1. Run `python check_progress.py` to see where we are
2. Read `DEVELOPMENT_WORKFLOW.md` for current phase
3. Continue from next task in `tasks.md`

## Phase Overview

Current implementation follows this order:

1. **Phase 1: First 5 Minutes** (75% done)
   - Player spawn, survival basics, first resources, crafting

2. **Phase 2: First Hour - Base Foundation**
   - Build first base, oxygen regeneration, power

3. **Phase 3: Automation Loop**
   - First automated factory running

4. **Phase 4: Progression & Exploration**
   - Tech tree, scanner, advanced automation

5. **Phase 5: Creatures & Defense**
   - Taming, combat, base defense

... (see DEVELOPMENT_WORKFLOW.md for all 12 phases)

## Resources

- **Workflow**: `DEVELOPMENT_WORKFLOW.md`
- **Quick Start**: `QUICK_START.md`
- **Architecture**: `CLAUDE.md`
- **Requirements**: `.kiro/specs/planetary-survival/requirements.md`
- **Design**: `.kiro/specs/planetary-survival/design.md`
- **Tasks**: `.kiro/specs/planetary-survival/tasks.md`
- **Testing**: `tests/TESTING_FRAMEWORK.md`

## Important Notes

1. **VR Performance is Non-Negotiable**: 90 FPS minimum
2. **Test-Driven**: Features need automated playtests
3. **Player-Experience Order**: Build from spawn outward
4. **Debug Continuously**: Don't accumulate bugs
5. **Document Everything**: Next agent needs clear state

---

**Agent Status**: Ready to implement and validate VR gameplay features
**Current Phase**: 1 - First 5 Minutes (75% complete)
**Next Tasks**: Tasks 3 & 4 from Phase 1
