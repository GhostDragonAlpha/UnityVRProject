# Complete Project Overview

## The Game: Project Resonance + Planetary Survival

This is **ONE integrated VR game** combining two gameplay layers:
- **Space Layer**: Project Resonance (space flight, orbital mechanics, resonance physics)
- **Surface Layer**: Planetary Survival (terrain manipulation, automation, creature taming)

Players seamlessly transition between flying spacecraft in space and surviving/building on planet surfaces.

---

## Specifications Location

Both specs are in `.kiro/specs/`:

```
.kiro/specs/
├── project-resonance/          ← Space layer (85% complete)
│   ├── requirements.md
│   ├── design.md
│   └── tasks.md
└── planetary-survival/         ← Surface layer (18% complete)
    ├── requirements.md
    ├── design.md
    └── tasks.md
```

---

## Part 1: Project Resonance (Space Layer)

### What It Is
VR space simulation where the universe is modeled as a fractal harmonic lattice.

### Core Systems (85% Complete)
1. ✅ **Core Engine**: VR support, floating origin, relativity, physics
2. ✅ **Rendering**: Lattice visualization, LOD, post-processing, shaders
3. ✅ **Celestial Mechanics**: Orbital calculations, solar system, star catalog
4. ✅ **Procedural Generation**: Universe/planet generation, biomes
5. ✅ **Player Systems**: Spacecraft physics, VR controls, SNR/health, inventory
6. ✅ **Gameplay**: Missions, tutorial, resonance mechanics, hazards
7. ✅ **UI**: HUD, cockpit, trajectory, warnings, menus
8. 🔄 **Planetary Systems**: Space-to-surface transitions, walking, atmospheric entry

### Key Features
- **Lattice Physics**: Universe is a harmonic lattice that distorts with gravity
- **Resonance Mechanics**: Match frequencies to interact with objects
- **SNR as Health**: Signal-to-noise ratio represents ship integrity
- **Time Dilation**: Relativistic effects near massive objects
- **Procedural Universe**: Deterministic generation from seeds

### Current Status
- **Completion**: ~85% (Phases 1-8 of 15)
- **State**: Fully functional space simulation
- **Integration Point**: Transitions to surface (Task 40-42 complete)
- **See**: `PROJECT_STATUS.md` for detailed status

---

## Part 2: Planetary Survival (Surface Layer)

### What It Is
VR survival/automation game on planet surfaces, combining:
- **Astroneer**: Voxel terrain manipulation
- **Satisfactory**: Factory automation
- **Ark**: Creature taming and breeding

### Core Systems (18% Complete)
1. ✅ **Voxel Terrain**: Chunk management, deformation, floating origin
2. ✅ **Terrain Tool**: VR excavate/elevate/flatten, canisters, augments
3. ✅ **Resources**: Nodes, gathering, scanner
4. ✅ **Crafting**: Recipes, tech tree, inventory
5. ✅ **Base Building**: Modules, connections, structural integrity
6. ✅ **Life Support**: Oxygen/hunger/thirst, pressurization, hazards
7. ✅ **Power**: Grids, generators, batteries, distribution
8. ✅ **Automation**: Conveyors, pipes, machines, production
9. ✅ **Creatures**: Taming, commands, gathering (partial)
10. ⏳ **Breeding**: (Phase 6 - not started)
11. ⏳ **Farming**: (Phase 6 - not started)
12. ⏳ **Defense**: (Phase 5 - not started)
13. ⏳ **Multiplayer**: (Phase 7-11 - not started)
14. ⏳ **Persistence**: (Phase 8 - not started)

### Key Features
- **Voxel Terrain**: Fully deformable with marching cubes
- **Soil Physics**: Excavated soil stored in canisters for elevation
- **Power Grids**: Auto-forming networks with production/consumption
- **Automation**: Conveyor/pipe networks, backpressure, machines
- **Creatures**: Tame, breed, command for gathering/combat
- **Tech Tree**: Unlock advanced automation and technologies

### Current Status
- **Completion**: ~18% (Phase 1 at 75%)
- **State**: Core mechanics implemented, testing infrastructure needed
- **Current Focus**: VR automated playtesting for Phase 1
- **See**: `PLANETARY_SURVIVAL_STATUS.md` for detailed status

---

## Integration: How They Work Together

### Gameplay Flow

1. **Start in Space (Resonance)**
   - Player spawns in spacecraft
   - Navigate using VR controllers
   - Use resonance mechanics to interact
   - Scan for planets with resources

2. **Land on Planet (Transition)**
   - Approach planet surface
   - Atmospheric entry effects
   - Land spacecraft at chosen location
   - **Switch from Resonance → Survival mode**

3. **Play on Surface (Survival)**
   - Exit spacecraft (EVA)
   - Use terrain tool to dig/build
   - Gather resources from nodes
   - Build base and automation
   - Tame creatures for help
   - Craft items and tech

4. **Return to Space (Transition)**
   - Enter spacecraft
   - Take off from planet
   - **Switch from Survival → Resonance mode**
   - Fly to next planet/mission

### Technical Integration Points

**Shared Systems**:
- ✅ ResonanceEngine (coordinates both)
- ✅ VRManager (works in space and surface)
- ✅ FloatingOriginSystem (handles large distances)
- ✅ TimeManager (time dilation affects both)
- ✅ SaveSystem (saves both space and surface state)

**Transition System** (Task 40-42, complete):
- Seamless mode switching
- Persistent player inventory
- Coordinate transformation
- State preservation

**Resource Flow**:
- Resources gathered on surface
- Craft items for spacecraft upgrades
- Use spacecraft to reach new planets
- Find rare resources on dangerous planets

---

## Development Status

### Project Resonance: 85% Complete
**Phases Complete**: 1-8 of 15
**Remaining Work**:
- Phase 9: Audio systems
- Phase 10: Advanced features (quantum observation, fractal zoom)
- Phase 11: Save/load and persistence
- Phase 12: Polish and optimization
- Phase 13: Content and assets
- Phase 14: Testing and bug fixing
- Phase 15: Documentation and deployment

**See**: `PROJECT_STATUS.md`

### Planetary Survival: 18% Complete
**Phases Complete**: 0 (Phase 1 at 75%)
**Remaining Work**:
- Phase 1: Complete VR automated testing (6-8 hours)
- Phases 2-12: See `DEVELOPMENT_WORKFLOW.md`

**See**: `PLANETARY_SURVIVAL_STATUS.md`

---

## Current Development Focus

### Immediate (Next 6-8 hours)
**Complete Planetary Survival Phase 1**:
1. Add input injection endpoints to `godot_bridge.gd`
2. Add state query endpoints to `godot_bridge.gd`
3. Write Phase 1 automated VR playtests
4. Manual VR validation
5. Mark Phase 1 complete

**See**: `NEXT_STEPS.md` for detailed instructions

### Short Term (Next 2-4 weeks)
**Planetary Survival Phases 2-4**:
- Phase 2: Base foundation (oxygen, power, safety)
- Phase 3: Automation loop (first factory)
- Phase 4: Progression & exploration (tech tree, scanner)

**See**: `DEVELOPMENT_WORKFLOW.md`

### Medium Term (2-6 months)
**Planetary Survival Phases 5-12**:
- Creatures, defense, breeding, farming
- Multiplayer foundation
- Persistence and advanced automation
- Environmental complexity
- Vehicles and exploration
- Server meshing
- Polish and optimization

### Long Term (6-12 months)
**Project Resonance Completion**:
- Audio systems
- Advanced features
- Content creation
- Final polish
- Deployment

---

## File Structure

```
C:\godot\
│
├── Specifications (What to Build)
│   └── .kiro\specs\
│       ├── project-resonance\          ← Space layer specs
│       │   ├── requirements.md         (72 requirements)
│       │   ├── design.md              (architecture)
│       │   └── tasks.md               (75 tasks, 39 done)
│       └── planetary-survival\         ← Surface layer specs
│           ├── requirements.md         (68 requirements)
│           ├── design.md              (architecture)
│           └── tasks.md               (48 tasks, 9 done)
│
├── Status & Planning (Current State)
│   ├── FULL_PROJECT_OVERVIEW.md        ← This file
│   ├── PROJECT_STATUS.md               ← Resonance status
│   ├── PLANETARY_SURVIVAL_STATUS.md    ← Survival status
│   ├── DEVELOPMENT_WORKFLOW.md         ← 12-phase workflow
│   ├── NEXT_STEPS.md                   ← Exact next actions
│   └── QUICK_START.md                  ← Getting started
│
├── Documentation
│   ├── CLAUDE.md                       ← Architecture reference
│   ├── WORKFLOW_COMPLETE.md            ← Workflow summary
│   └── .claude\agents\
│       └── vr-playtest-developer.md    ← Agent instructions
│
├── Implementation (Game Code)
│   ├── addons\godot_debug_connection\  ← HTTP API, telemetry
│   ├── scripts\                        ← Game systems
│   │   ├── core\                       ← Engine, VR, physics
│   │   ├── celestial\                  ← Planets, orbits
│   │   ├── player\                     ← Spacecraft, walking
│   │   ├── gameplay\                   ← Resonance, missions
│   │   ├── ui\                         ← HUD, menus
│   │   ├── rendering\                  ← Shaders, post-FX
│   │   ├── audio\                      ← Spatial audio
│   │   └── procedural\                 ← Generation
│   ├── scenes\                         ← Scene files
│   └── shaders\                        ← GLSL shaders
│
└── Testing & Tools
    ├── tests\                          ← Test suite
    │   ├── vr_playtest_framework.py    ← VR testing
    │   ├── test_runner.py              ← Full suite
    │   └── property\                   ← Property tests
    ├── check_progress.py                ← Progress tracker
    ├── start_dev_session.bat            ← One-click startup
    └── telemetry_client.py              ← Monitoring
```

---

## Architecture Integration

### Resonance Engine Subsystems

The `ResonanceEngine` autoload coordinates ALL systems for both layers:

**Phase 1 - Core** (shared by both):
- TimeManager - Time dilation, physics timestep
- RelativityManager - Relativistic physics

**Phase 2 - Dependent** (shared):
- FloatingOriginSystem - Coordinate management
- PhysicsEngine - Custom physics

**Phase 3 - VR** (shared):
- VRManager - OpenXR for both space and surface
- VRComfortSystem - Comfort features
- HapticManager - Controller feedback
- RenderingSystem - Rendering pipeline

**Phase 4 - Performance** (shared):
- PerformanceOptimizer - Dynamic quality

**Phase 5 - Audio** (shared):
- AudioManager - Spatial audio

**Phase 6 - Advanced** (shared):
- FractalZoomSystem - Multi-scale zoom
- CaptureEventSystem - Event recording

**Phase 7 - Persistence** (shared):
- SettingsManager - Configuration
- SaveSystem - Game state

**Survival-Specific**:
- VoxelTerrainSystem
- ResourceSystem
- CraftingSystem
- AutomationSystem
- CreatureSystem
- BaseBuildingSystem
- LifeSupportSystem
- PowerGridSystem

---

## API Services (Shared)

Both layers use the same debug/telemetry infrastructure:

| Service | Port | Purpose | Used By |
|---------|------|---------|---------|
| HTTP API | 8081 | Remote control, testing | Both |
| Telemetry | 8081 | Real-time data streaming | Both |
| DAP | 6006 | Debug Adapter Protocol | Both |
| LSP | 6005 | Language Server Protocol | Both |
| Discovery | 8087 | Service discovery | Both |

**Start All Services**:
```bash
./restart_godot_with_debug.bat
```

---

## Testing Strategy

### Project Resonance Tests
- ✅ Property-based tests (16/16 passing)
- ✅ Integration tests (most passing)
- ⚠️ UI validation (needs update)
- **Location**: `tests/integration/`, `tests/property/`

### Planetary Survival Tests
- ✅ VR Playtest Framework (complete)
- ⏳ Phase 1 checkpoint tests (to write)
- ⏳ Property tests (to write)
- **Location**: `tests/phase1_checkpoint_tests.py` (todo)

### Combined Tests
- Transition tests (space → surface → space)
- Integration tests (resource flow, persistence)
- Performance tests (90 FPS in both modes)

---

## Performance Targets

### Resonance (Space)
- **Target**: 90 FPS in VR
- **Current**: Stable (needs load testing)
- **Bottlenecks**: Lattice rendering, N-body physics

### Survival (Surface)
- **Target**: 90 FPS in VR
- **Current**: Unknown (needs testing)
- **Bottlenecks**: Voxel mesh generation, automation updates

### Transition
- **Target**: No frame drops during transition
- **Current**: Unknown (needs testing)

---

## Next Agent Instructions

When picking up this project:

1. **Read files in order**:
   - `FULL_PROJECT_OVERVIEW.md` (this file) - Understand both specs
   - `PLANETARY_SURVIVAL_STATUS.md` - Current status
   - `NEXT_STEPS.md` - What to do
   - `.claude/agents/vr-playtest-developer.md` - How to work

2. **Check progress**:
   ```bash
   python check_progress.py
   ```

3. **Start dev session**:
   ```bash
   start_dev_session.bat
   ```

4. **Execute next steps**:
   - Follow `NEXT_STEPS.md` exactly
   - Complete Phase 1 of Planetary Survival
   - Then move to Phase 2

---

## Key Insight

**This is ONE game with TWO integrated layers:**
- You FLY in space (Resonance)
- You LAND on planets
- You SURVIVE and BUILD (Survival)
- You TAKE OFF and fly to next planet
- Resources from surface upgrade spacecraft
- Spacecraft enables reaching new planets

Both specs combine into a seamless VR experience.

---

**Status**: Resonance 85% done, Survival 18% done
**Focus**: Complete Survival Phase 1 (VR automated testing)
**See**: `NEXT_STEPS.md` for immediate actions
