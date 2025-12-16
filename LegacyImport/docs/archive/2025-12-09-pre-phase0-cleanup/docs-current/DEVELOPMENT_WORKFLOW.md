# Development Workflow: Player Start → Outward Expansion

This workflow builds the game from the **player spawn experience** outward, implementing features in the order players encounter them. Each phase includes implementation + debugging/testing.

## Workflow Principles

1. **Player-Centric Order**: Features are implemented in the order players experience them
2. **Incremental Building**: Small, testable increments with immediate validation
3. **Debug as You Build**: Every feature includes testing and validation before moving on
4. **Playtest-Driven**: Regular VR playtesting to validate experience
5. **Fail Fast**: Issues are caught immediately at each checkpoint

## Phase 1: First 5 Minutes - Player Spawn & Survival Loop

**Goal**: Player spawns, understands controls, gathers first resources, feels urgency

### 1.1 Player Spawn System
- **Implement**:
  - Spawn point selection on planet surface
  - Initial player loadout (Terrain Tool, empty canisters, basic suit)
  - Tutorial HUD overlay for VR controls
  - Spawn in "safe zone" with nearby resources

- **Debug**:
  ```bash
  # Start Godot with debug services
  ./restart_godot_with_debug.bat

  # Monitor telemetry in separate terminal
  python telemetry_client.py

  # Test via HTTP API
  curl -X POST http://127.0.0.1:8080/connect
  python examples/test_player_spawn.py
  ```

- **Validation**:
  - [ ] Player spawns in VR with correct orientation
  - [ ] Terrain Tool is equipped and responsive
  - [ ] Tutorial overlay appears and is readable in VR
  - [ ] Life support HUD displays oxygen/hunger/thirst
  - [ ] No performance drops (maintain 90 FPS in VR)

### 1.2 Basic Life Support Warning
- **Implement** (from Task 9.1):
  - Oxygen meter visible in HUD
  - Warning at 50%, critical at 25%
  - Audio warnings that work in VR
  - Oxygen depletion rate (slower to start for tutorial)

- **Debug**:
  ```python
  # Via HTTP API - simulate oxygen depletion
  curl -X POST http://127.0.0.1:8080/execute/setPlayerOxygen -d '{"value": 30}'
  # Verify warning appears in HUD
  ```

- **Validation**:
  - [ ] Oxygen depletes at expected rate
  - [ ] Warnings trigger at correct thresholds
  - [ ] Audio is spatially positioned correctly
  - [ ] Warning is visible but not intrusive in VR

### 1.3 First Terrain Deformation
- **Implement** (Tasks 1-3 already done, verify):
  - Excavate tutorial prompt
  - Resource node in first tunnel
  - Canister fills with soil
  - Resource fragments collect

- **Debug**:
  ```bash
  # Run property tests
  cd tests/property
  python -m pytest test_terrain_deformation.py -v

  # Monitor FPS during excavation
  python tests/health_monitor.py
  ```

- **Validation**:
  - [ ] Excavation feels responsive in VR
  - [ ] Visual feedback is clear (debris, effects)
  - [ ] Haptic feedback on controllers
  - [ ] Canister fill UI updates in real-time
  - [ ] First resource fragments vacuum correctly

### 1.4 First Crafting Experience
- **Implement** (Task 8 extension):
  - Portable Fabricator item (craft from inventory)
  - Simple "craft oxygen canister" recipe
  - Tutorial: craft → refill oxygen
  - Success feedback

- **Debug**:
  ```python
  # Test crafting via API
  curl -X POST http://127.0.0.1:8080/execute/testCrafting -d '{
    "recipe": "oxygen_canister",
    "resources": {"iron": 2, "crystal": 1}
  }'
  ```

- **Validation**:
  - [ ] Crafting UI is usable in VR (hand-based)
  - [ ] Recipe requirements are clear
  - [ ] Crafting progress is visible
  - [ ] Item appears in inventory correctly
  - [ ] Oxygen refill works and feels impactful

**CHECKPOINT 1**: Player can spawn, mine first resources, craft oxygen, survive for 10 minutes
- Run full test suite: `python tests/test_runner.py --quick`
- VR playtest: 3 people complete "first 10 minutes" without confusion
- Performance: Maintain 90 FPS throughout

---

## Phase 2: First Hour - Base Foundation

**Goal**: Player builds first small base, establishes power, creates safety zone

### 2.1 Starter Base Module Placement
- **Implement** (Task 8 verified):
  - Habitat module (small, 1 room)
  - Airlock module
  - Holographic placement preview
  - Green/red valid/invalid feedback
  - Tutorial: "build your first safe room"

- **Debug**:
  ```bash
  # Test placement validation
  python tests/test_base_placement.py

  # Monitor structural integrity calculations
  curl http://127.0.0.1:8080/debug/getStructuralIntegrity
  ```

- **Validation**:
  - [ ] Placement preview is clear in VR
  - [ ] Snap points work intuitively
  - [ ] Red/green feedback is obvious
  - [ ] Modules connect properly
  - [ ] No placement exploits (clipping, floating)

### 2.2 Pressurization & Oxygen Regeneration
- **Implement** (Task 9.3 verified):
  - Sealed room detection
  - Oxygen stops depleting indoors
  - Slow regeneration when in base
  - Airlock transition (depressurization warning)
  - Audio: pressurization hiss

- **Debug**:
  ```python
  # Property test for sealed environments
  cd tests/property
  python -m pytest test_life_support.py::test_pressurized_environment -v
  ```

- **Validation**:
  - [ ] Oxygen stops depleting correctly
  - [ ] Airlock creates brief exposure
  - [ ] Visual/audio feedback is satisfying
  - [ ] No bugs with partial structures

### 2.3 First Power System
- **Implement** (Task 11.1-11.3):
  - Small biomass generator (burns plants)
  - Power cable (simple, single connection)
  - Oxygen generator module
  - Tutorial: gather biomass → power → oxygen

- **Debug**:
  ```bash
  # Test power grid formation
  python tests/test_power_grid.py

  # Monitor power balance
  curl http://127.0.0.1:8080/status/powerGrid
  ```

- **Validation**:
  - [ ] Generator consumes fuel correctly
  - [ ] Power cables connect intuitively
  - [ ] Oxygen generator activates when powered
  - [ ] HUD shows power production/consumption
  - [ ] Clear feedback when power insufficient

**CHECKPOINT 2**: Player has functioning base with oxygen regeneration
- Playtest: Build base start-to-finish in <20 minutes
- Test: Leave base, return, oxygen regenerates
- Performance: No FPS drops with 5+ modules

---

## Phase 3: Automation Loop - First Factory

**Goal**: Player automates first resource gathering, feels progression

### 3.1 Automated Miner Placement
- **Implement** (Task 14.2 verified):
  - Miner machine (place on resource node)
  - Power requirement (low, from biomass gen)
  - Resource extraction rate visible
  - Tutorial: "automate your first mine"

- **Debug**:
  ```python
  # Property test for automated mining
  cd tests/property
  python -m pytest test_automation.py::test_miner_extraction -v
  ```

- **Validation**:
  - [ ] Miner placement is clear
  - [ ] Resource node detection works
  - [ ] Extraction rate is visible
  - [ ] Extracted items appear correctly

### 3.2 First Conveyor Belt
- **Implement** (Task 12.1 verified):
  - Conveyor belt placement
  - Snapping to miner output
  - Snapping to storage container
  - Item transport visualization

- **Debug**:
  ```bash
  # Test conveyor transport
  python tests/test_conveyor_transport.py

  # Monitor item positions via telemetry
  python telemetry_client.py --filter conveyor_items
  ```

- **Validation**:
  - [ ] Belt snapping works smoothly
  - [ ] Items move at correct speed
  - [ ] Multiple items don't collide
  - [ ] Visual is clear and satisfying

### 3.3 Storage Container & Collection
- **Implement** (Task 12.6 verified):
  - Basic storage container
  - Conveyor → storage connection
  - Storage UI (open container, see items)
  - Full storage backpressure

- **Debug**:
  ```python
  # Test backpressure
  cd tests/property
  python -m pytest test_automation.py::test_backpressure -v
  ```

- **Validation**:
  - [ ] Items fill storage correctly
  - [ ] UI is readable in VR
  - [ ] Backpressure stops miner
  - [ ] No item duplication/loss

### 3.4 Smelter Integration
- **Implement** (Task 14.4 verified):
  - Smelter machine
  - Conveyor belt → smelter input
  - Smelter → storage output
  - Tutorial: "build your first production line"

- **Debug**:
  ```bash
  # Test full production chain
  python tests/test_production_chain.py

  # Monitor throughput
  curl http://127.0.0.1:8080/status/productionStats
  ```

- **Validation**:
  - [ ] Full chain: miner → belt → smelter → belt → storage
  - [ ] Power requirement is manageable
  - [ ] Bottlenecks are visible
  - [ ] Feels rewarding to watch

**CHECKPOINT 3**: Player has first automated factory running
- Playtest: Build automation from scratch in <30 minutes
- Test: Leave base, return, storage filled with refined metal
- Performance: 10+ machines, belts, still 90 FPS

---

## Phase 4: Progression & Exploration

**Goal**: Player expands base, explores for new resources, unlocks tech

### 4.1 Resource Scanner
- **Implement** (Task 5.5 verified):
  - Handheld scanner device
  - Power consumption from suit battery
  - Resource signature display in HUD
  - Distance and type indicators

### 4.2 Tech Tree UI
- **Implement** (Task 6.3-6.4):
  - VR-friendly tech tree interface
  - Research point display
  - Technology unlock paths
  - Tutorial: unlock first automation tech

### 4.3 Advanced Automation
- **Implement** (Tasks 14.5-14.6):
  - Constructor machine
  - Assembler machine (multi-input)
  - Component crafting recipes

### 4.4 Base Expansion
- **Implement**:
  - Additional module types (storage, workshop, garage)
  - Multi-room bases
  - Power distribution expansion

**CHECKPOINT 4**: Player has expanded base with advanced automation
- Multiple production chains running
- Tech tree partially unlocked
- Base with 15+ modules

---

## Phase 5: Creatures & Defense

**Goal**: Introduce living world, threats, taming mechanics

### 5.1 First Creature Encounter
- **Implement** (Task 15.1):
  - Passive creature spawning
  - Basic creature AI
  - Creature approach/flee behavior

### 5.2 Creature Taming
- **Implement** (Task 15.2-15.5):
  - Knockout mechanics
  - Feeding and taming
  - Basic commands
  - First gathering creature

### 5.3 Hostile Creatures & Defense
- **Implement** (Task 19.1-19.4):
  - Hostile creature spawns (night)
  - Base attack mechanics
  - Turret defense
  - Creature defense commands

**CHECKPOINT 5**: Creatures, taming, and defense working
- Creatures add life to world
- Taming feels rewarding
- Defense is engaging not frustrating

---

## Phase 6: Breeding & Farming

**Goal**: Long-term progression, sustainable resources

### 6.1 Creature Breeding
- **Implement** (Task 17.1-17.5):
  - Mate selection
  - Egg/birth mechanics
  - Stat inheritance
  - Imprinting

### 6.2 Crop Growing
- **Implement** (Task 18.1-18.3):
  - Crop plot placement
  - Seed planting
  - Growth stages
  - Harvesting

**CHECKPOINT 6**: Self-sustaining base with breeding/farming

---

## Phase 7: Multiplayer Foundation

**Goal**: Friends can join, collaborate on base

### 7.1 Basic Multiplayer
- **Implement** (Task 31.1-31.6):
  - Session hosting/joining
  - Player sync
  - Terrain sync
  - Structure sync

### 7.2 Collaborative Building
- **Implement**:
  - Shared base ownership
  - Multi-player crafting
  - Trade between players

**CHECKPOINT 7**: 2-4 players can build together

---

## Phase 8: Persistence & Advanced Features

**Goal**: Long-term worlds, advanced tech

### 8.1 Save/Load System
- **Implement** (Task 21.1-21.4):
  - Terrain modification persistence
  - Base state saving
  - Creature persistence
  - Delta-based saves

### 8.2 Advanced Tech
- **Implement** (Tasks 22-23):
  - Blueprint system
  - Drone automation
  - Rail transport
  - Teleportation

**CHECKPOINT 8**: Complete game loop with persistence

---

## Phase 9: Environmental Complexity

**Goal**: Dynamic world, caves, weather

### 9.1 Weather System
- **Implement** (Task 25.1):
  - Weather patterns
  - Storms
  - Gameplay impact

### 9.2 Cave Systems
- **Implement** (Task 25.3-25.4):
  - Procedural caves
  - Depth progression
  - Elevator system

**CHECKPOINT 9**: Rich environmental variety

---

## Phase 10: Vehicles & Exploration

**Goal**: Surface travel, multiple bases

### 10.1 Surface Vehicles
- **Implement** (Task 26.1):
  - Vehicle crafting
  - Driving controls
  - Cargo transport

### 10.2 Remote Bases
- **Implement** (Task 26.2):
  - Mining outposts
  - Remote power
  - Collection logistics

**CHECKPOINT 10**: Multi-base operations

---

## Phase 11: Server Meshing & Scale

**Goal**: Massive multiplayer, seamless worlds

### 11.1 Solar System Generation
- **Implement** (Task 30.1-30.5):
  - Deterministic planet generation
  - Multiple biomes per planet
  - Moon and asteroid generation

### 11.2 Region Partitioning
- **Implement** (Task 38.1-38.4):
  - Server mesh coordinator
  - Region assignment
  - Inter-server communication

### 11.3 Authority Transfer
- **Implement** (Task 39.1-39.5):
  - Boundary crossing detection
  - Seamless handoff
  - Failure recovery

**CHECKPOINT 11**: Server meshing operational

---

## Phase 12: Polish & Optimization

**Goal**: Production-ready experience

### 12.1 Performance Optimization
- **Implement** (Task 28.3):
  - LOD systems
  - Occlusion culling
  - Profiling and optimization

### 12.2 Advanced Features
- **Implement** (Tasks remaining):
  - Boss encounters
  - Alien artifacts
  - Underwater bases
  - Customization

**CHECKPOINT 12**: Complete, polished game

---

## Daily Development Workflow

### Morning: Plan & Setup
1. Review yesterday's progress in CLAUDE.md
2. Select next feature from phase plan
3. Start Godot with debug services:
   ```bash
   ./restart_godot_with_debug.bat
   ```
4. Start telemetry monitor:
   ```bash
   python telemetry_client.py
   ```

### Development Cycle (repeat 3-4 times/day)
1. **Implement** (45-90 min):
   - Code the feature in GDScript
   - Use LSP for code intelligence
   - Hot-reload via `/execute/reload`

2. **Debug** (30-45 min):
   - Run property tests if available
   - Test via HTTP API
   - Monitor telemetry for issues
   - Fix bugs immediately

3. **Validate in VR** (15-30 min):
   - Put on headset
   - Test feature in actual gameplay
   - Check comfort, usability
   - Verify 90 FPS maintained

4. **Document** (10-15 min):
   - Update task status in `.kiro/specs/planetary-survival/tasks.md`
   - Note any issues in debug log
   - Update CLAUDE.md if architecture changed

### Evening: Test & Commit
1. Run full test suite:
   ```bash
   cd tests
   python test_runner.py
   ```
2. Review health monitor results:
   ```bash
   python health_monitor.py
   ```
3. If all green, commit:
   ```bash
   git add .
   git commit -m "feat: [feature name] - Task [number]"
   ```

---

## Debug Tools Quick Reference

### Start Services
```bash
# Windows
./restart_godot_with_debug.bat

# Verify all services
curl http://127.0.0.1:8080/status
```

### Monitor Performance
```bash
# Real-time telemetry
python telemetry_client.py

# Health checks
cd tests
python health_monitor.py

# Performance benchmark
./run_performance_test.bat
```

### Test Features
```bash
# Property tests
cd tests/property
python -m pytest test_*.py -v

# Integration tests
cd tests
python test_runner.py --verbose

# Specific feature
python tests/feature_validator.py --feature terrain_deformation
```

### Debug via HTTP API
```python
# Connect to services
curl -X POST http://127.0.0.1:8080/connect

# Check game state
curl http://127.0.0.1:8080/status

# Execute test command
curl -X POST http://127.0.0.1:8080/execute/testFeature \
  -H "Content-Type: application/json" \
  -d '{"feature": "terrain_tool", "params": {...}}'
```

---

## VR Playtest Protocol

### Before Each Playtest
- [ ] Godot running with debug services
- [ ] Telemetry monitor active
- [ ] Target feature clearly defined
- [ ] Test scenario written down

### During Playtest
- [ ] Tester wears headset
- [ ] Observer watches monitor + telemetry
- [ ] Observer notes any confusion/issues
- [ ] FPS counter visible
- [ ] Test lasts minimum 15 minutes

### After Playtest
- [ ] Review telemetry logs
- [ ] Document any discomfort (VR sickness)
- [ ] List bugs found
- [ ] Rate experience 1-10
- [ ] Decide: ship it or fix it

---

## Troubleshooting Development Issues

### Godot Not Responding
```bash
# Kill and restart
taskkill /IM Godot*.exe /F
./restart_godot_with_debug.bat
```

### HTTP API Not Reachable
```bash
# Check status
curl http://127.0.0.1:8080/status

# Try fallback ports
curl http://127.0.0.1:8083/status
curl http://127.0.0.1:8084/status
```

### Tests Failing
```bash
# Run with verbose output
cd tests
python test_runner.py --verbose

# Check specific test
python -m pytest tests/property/test_terrain.py -v -s

# Check GdUnit4 tests in editor
# Open Godot → GdUnit4 panel → Run All
```

### Performance Issues
```bash
# Profile
./run_performance_test.bat

# Check specific system
python examples/debug_session_example.py

# Monitor FPS
curl http://127.0.0.1:8080/debug/getFPS
```

---

## Success Metrics Per Phase

### Phase 1: First 5 Minutes
- ✅ 3/3 playtesters complete tutorial without help
- ✅ Average oxygen at 60% after 5 minutes
- ✅ All collect first resource
- ✅ 90 FPS maintained throughout

### Phase 2: First Hour
- ✅ 3/3 playtesters build functioning base
- ✅ Base provides oxygen regeneration
- ✅ No VR sickness reported
- ✅ 90 FPS with 10+ modules

### Phase 3: Automation Loop
- ✅ 2/3 playtesters build factory without help
- ✅ Factory runs unattended for 10 minutes
- ✅ Production visible and satisfying
- ✅ 90 FPS with 20+ automation objects

### (Continue for each phase...)

---

## Notes
- This workflow prioritizes **player experience** over technical implementation order
- Each checkpoint is a **playable vertical slice**
- Debug/test happens **continuously**, not at end
- VR comfort and performance are **non-negotiable**
- When in doubt, **playtest early and often**
