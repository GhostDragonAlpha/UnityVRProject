# Quick Start Guide - Planetary Survival Development

## Your New Workflow is Ready!

I've set up a **player-experience-driven workflow** that builds your game from the spawn point outward, with continuous debugging.

## What's Been Created

### 1. **DEVELOPMENT_WORKFLOW.md**
   - 12 phases organized by player experience
   - Each phase has implementation + debug + validation steps
   - Detailed checkpoints and success metrics
   - Daily development cycle (implement → debug → test in VR → document)

### 2. **start_dev_session.bat**
   - One-click script to start your dev session
   - Launches Godot with debug services
   - Checks service status
   - Shows your current progress

### 3. **check_progress.py**
   - Shows which phase you're on
   - Displays next tasks
   - Overall completion percentage
   - Phase map overview

### 4. **Updated CLAUDE.md**
   - References the new workflow
   - Includes quick daily workflow
   - Links to all documentation

## Current Status

```
Phase 1: First 5 Minutes - Player Spawn & Survival
Progress: [######--] 6/8 tasks
Overall: 18.8% complete
```

**Next Tasks:**
1. Task 3 - Checkpoint verification
2. Task 4 - Verify terrain deformation in VR

## How to Use This Workflow

### Starting Your Day

1. **Run the dev session starter:**
   ```bash
   start_dev_session.bat
   ```

2. **Open the workflow guide:**
   - Read `DEVELOPMENT_WORKFLOW.md`
   - Find your current phase
   - See what to implement next

3. **Start telemetry monitor** (in new terminal):
   ```bash
   python telemetry_client.py
   ```

### Development Cycle

Follow this 2-3 hour cycle:

1. **IMPLEMENT** (45-90 min)
   - Code the feature from workflow
   - Use LSP for auto-complete
   - Hot-reload via HTTP API

2. **DEBUG** (30-45 min)
   - Run property tests: `cd tests/property && pytest test_*.py -v`
   - Test via HTTP API: `python examples/...`
   - Check telemetry for issues
   - Fix bugs immediately

3. **VALIDATE IN VR** (15-30 min)
   - Put on headset
   - Test the feature
   - Verify 90 FPS maintained
   - Check comfort/usability

4. **DOCUMENT** (10-15 min)
   - Update `.kiro/specs/planetary-survival/tasks.md`
   - Mark tasks as `[x]` when complete
   - Note any issues

### Ending Your Day

```bash
# Run full test suite
cd tests
python test_runner.py

# Check progress
python check_progress.py

# If all green, commit
git add .
git commit -m "feat: [what you built] - Phase [N]"
```

## The 12 Phases

Your game is built in these phases (see DEVELOPMENT_WORKFLOW.md for details):

1. **First 5 Minutes** ← YOU ARE HERE
   - Player spawn, survival basics, first resources

2. **First Hour - Base Foundation**
   - Build first base, oxygen regeneration, power

3. **Automation Loop**
   - First automated factory running

4. **Progression & Exploration**
   - Tech tree, scanner, advanced automation

5. **Creatures & Defense**
   - Taming, combat, base defense

6. **Breeding & Farming**
   - Long-term progression

7. **Multiplayer Foundation**
   - 2-4 players can collaborate

8. **Persistence & Advanced Features**
   - Save/load, blueprints, drones

9. **Environmental Complexity**
   - Weather, caves, dynamic world

10. **Vehicles & Exploration**
    - Surface vehicles, remote bases

11. **Server Meshing & Scale**
    - Massive multiplayer

12. **Polish & Optimization**
    - Production-ready

## Key Commands

### Start Services
```bash
./restart_godot_with_debug.bat      # Start Godot with debug
curl http://127.0.0.1:8080/status   # Check services
python telemetry_client.py          # Monitor telemetry
```

### Testing
```bash
cd tests
python health_monitor.py            # Service health
python test_runner.py               # Full test suite
python test_runner.py --quick       # Quick tests only

cd tests/property
python -m pytest test_*.py -v      # Property tests
```

### Check Progress
```bash
python check_progress.py            # See current phase
```

### Debug via HTTP API
```python
# Connect
curl -X POST http://127.0.0.1:8080/connect

# Test feature
curl -X POST http://127.0.0.1:8080/execute/testFeature \
  -H "Content-Type: application/json" \
  -d '{"feature": "terrain_tool"}'

# Get game state
curl http://127.0.0.1:8080/status
```

## Phase 1: What to Do Next

You're 75% through Phase 1! Here's what's left:

### Task 3: First Terrain Deformation
**Already implemented, just verify:**
- [ ] Put on VR headset
- [ ] Spawn in game world
- [ ] Pick up Terrain Tool
- [ ] Excavate some terrain
- [ ] Check canister fills with soil
- [ ] Mine a resource node
- [ ] Verify fragments vacuum correctly
- [ ] Check FPS stays at 90

**If everything works → mark Task 3 as [x] in tasks.md**

### Task 4: First Crafting Experience
**Need to implement:**
1. Create portable Fabricator item
2. Add "craft oxygen canister" recipe
3. Tutorial prompt: "craft oxygen from resources"
4. Test in VR:
   - Open fabricator
   - See available recipes
   - Craft oxygen canister
   - Use canister to refill oxygen
   - Feel the satisfaction!

**When working → mark Task 4 as [-] in tasks.md**
**When done → mark Task 4 as [x] in tasks.md**

### Checkpoint 1: Playtest
Once Tasks 3 and 4 are [x]:
- Run: `python tests/test_runner.py`
- Put on headset, play for 10 minutes
- Can you: spawn → mine → craft → survive?
- FPS stays at 90?

**If yes → Move to Phase 2!**

## Tips for Success

### 1. **Keep Cycles Short**
   - Don't code for 4 hours straight
   - Implement → Debug → Test in VR every 90 min

### 2. **Debug Continuously**
   - Don't accumulate bugs
   - Fix issues immediately when found
   - Use telemetry to catch performance issues early

### 3. **Playtest Often**
   - VR experience is different from monitor
   - Test comfort, usability, clarity
   - 15 minutes in headset beats 1 hour of guessing

### 4. **Document as You Go**
   - Update tasks.md immediately
   - Future you will thank you
   - Helps track progress

### 5. **Maintain Performance**
   - 90 FPS is non-negotiable for VR
   - If FPS drops, stop and optimize
   - Use performance_optimizer.py

## Getting Help

### If Godot Won't Start
```bash
taskkill /IM Godot*.exe /F
./restart_godot_with_debug.bat
```

### If Services Won't Connect
```bash
# Try fallback ports
curl http://127.0.0.1:8083/status
curl http://127.0.0.1:8084/status
```

### If Tests Fail
```bash
# Run with verbose output
python test_runner.py --verbose

# Check specific test
cd tests/property
python -m pytest test_terrain.py -v -s
```

### If VR Performance Drops
```bash
# Profile performance
./run_performance_test.bat

# Check what's slow
curl http://127.0.0.1:8080/debug/getPerformanceStats
```

## Resources

- **Full Workflow**: DEVELOPMENT_WORKFLOW.md
- **Architecture Guide**: CLAUDE.md
- **Requirements**: .kiro/specs/planetary-survival/requirements.md
- **Design Doc**: .kiro/specs/planetary-survival/design.md
- **Tasks**: .kiro/specs/planetary-survival/tasks.md
- **Testing Guide**: tests/TESTING_FRAMEWORK.md

## Questions?

Read the relevant docs above, or ask specific questions. The workflow is designed to be:
- ✅ Player-experience driven
- ✅ Incremental and testable
- ✅ Debug-as-you-go
- ✅ VR-validated at each step

Good luck building! 🚀
