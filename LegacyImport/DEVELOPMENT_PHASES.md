# SpaceTime VR - Development Phases
**Created:** 2025-12-09
**Purpose:** Phase-by-phase roadmap for building the game correctly

---

## How to Use This Document

1. **Complete phases in order** (don't skip ahead)
2. **Each phase must compile cleanly** before moving to next
3. **Write tests for each feature** before marking phase complete
4. **Test in VR frequently** (not just at the end)
5. **Commit after each completed phase**

**Current Phase:** Phase 0 (Foundation)

---

## Phase 0: Foundation & Cleanup (Week 1)

### Goal
Verify project compiles, VR works, and development environment is ready.

### Tasks

**Day 1: Verification**
- [ ] Run project in editor (verify 0 errors)
- [ ] Put on VR headset, verify tracking works
- [ ] Test HTTP API: `curl http://127.0.0.1:8080/health`
- [ ] Document current state (what works vs broken)

**Day 2: Cleanup**
- [ ] Remove conflicting/outdated documentation
- [ ] Archive old implementation reports
- [ ] Audit autoloads (remove unused)
- [ ] Update CLAUDE.md to match reality

**Day 3: Install Missing Tools**
- [ ] Install godot-xr-tools addon (AssetLib)
- [ ] Install Terrain3D addon (test)
- [ ] Install godot_voxel addon (test)
- [ ] Verify all addons load without errors

**Day 4: Create Test Infrastructure**
- [ ] Create `scenes/features/` directory
- [ ] Create feature scene template
- [ ] Create automated test runner script
- [ ] Write first test (verify VR tracking)

**Day 5: Baseline**
- [ ] Run all tests → get to "all green"
- [ ] Create clean git commit: "Phase 0 complete"
- [ ] Merge to main branch
- [ ] Document phase 0 completion

### Acceptance Criteria
- ✅ 0 compilation errors
- ✅ VR tracking visible in headset
- ✅ 90 FPS in empty VR scene
- ✅ HTTP API responds
- ✅ Test infrastructure works
- ✅ Documentation accurate

### Estimated Time
5-7 days (includes learning/setup time)

---

## Phase 1: Core Physics Foundation (Weeks 2-4)

### Goal
Implement floating origin and basic gravity so player can walk on a planet.

### Tasks

**Week 2: Floating Origin System**
- [ ] Create `FloatingOriginSystem.gd` (autoload)
- [ ] Implement registration for tracked objects
- [ ] Implement universe shifting (threshold: 10km)
- [ ] Create test scene: `features/floating_origin_test.tscn`
- [ ] Write unit tests for origin shifting
- [ ] Test: Walk 20km, verify no jitter

**Week 3: Gravity & Walking**
- [ ] Create `GravityManager.gd` (per-planet gravity)
- [ ] Implement spherical gravity (points to planet center)
- [ ] Create test planet (procedural sphere mesh)
- [ ] Test walking on curved surface
- [ ] Implement gravity transitions (smooth falloff)
- [ ] Test in VR (walk around small planet)

**Week 4: VR Comfort & Polish**
- [ ] Create `VRComfortSystem.gd` (autoload)
- [ ] Implement vignette (fades on movement)
- [ ] Implement snap turning (30° increments)
- [ ] Add haptic feedback on footsteps
- [ ] Test for motion sickness (30 min session)
- [ ] Optimize to 90 FPS

### Feature Test Scenes
- `scenes/features/floating_origin_test.tscn` - Walk far distances
- `scenes/features/planetary_gravity_test.tscn` - Walk on sphere
- `scenes/features/vr_comfort_test.tscn` - Test vignette/snap turn

### Acceptance Criteria
- ✅ Walk on spherical planet (gravity correct)
- ✅ Walk 100km without jitter (floating origin works)
- ✅ 90 FPS maintained in VR
- ✅ No motion sickness in 30 min test
- ✅ All unit tests pass

### Commit Message
"Phase 1 complete: Floating origin + planetary gravity working"

### Estimated Time
3 weeks (includes VR testing and iteration)

---

## Phase 2: Spacecraft & Flight (Weeks 5-8)

### Goal
Player can enter a spaceship and fly with 6DOF controls.

### Tasks

**Week 5: Ship Interior**
- [ ] Create simple ship interior scene
- [ ] Implement enter/exit ship interaction
- [ ] Transition: standing → seated in cockpit
- [ ] Test VR comfort during transition
- [ ] Add ship interior physics (separate from planet)

**Week 6: 6DOF Flight Controls**
- [ ] Implement thrust system (forward/back)
- [ ] Implement rotation controls (pitch/yaw/roll)
- [ ] Implement translation controls (strafe)
- [ ] Add stabilization system (hold attitude)
- [ ] Map to VR controllers (radial menu)
- [ ] Test: Fly around planet

**Week 7: Orbital Mechanics**
- [ ] Create `OrbitalMechanicsManager.gd`
- [ ] Implement N-body gravity
- [ ] Calculate orbital trajectories
- [ ] Test: Achieve stable orbit
- [ ] Test: Escape velocity
- [ ] Visualize orbit path (debug)

**Week 8: Landing System**
- [ ] Implement landing gear
- [ ] Detect landing surfaces
- [ ] Transition: flight → landed
- [ ] Lock ship to planet surface
- [ ] Test: Land and walk around ship
- [ ] Polish and optimize

### Feature Test Scenes
- `scenes/features/ship_flight_test.tscn` - Test 6DOF controls
- `scenes/features/orbital_mechanics_test.tscn` - Test orbits
- `scenes/features/landing_test.tscn` - Test landing sequence

### Acceptance Criteria
- ✅ Enter ship from VR (smooth transition)
- ✅ Fly with 6DOF controls (intuitive)
- ✅ Achieve stable orbit around planet
- ✅ Land successfully without crashing
- ✅ Exit ship and walk around
- ✅ 90 FPS maintained
- ✅ All tests pass

### Commit Message
"Phase 2 complete: Spacecraft flight and landing working"

### Estimated Time
4 weeks (flight controls are complex in VR)

---

## Phase 3: Solar System & Travel (Weeks 9-12)

### Goal
Fly from one planet to another in our solar system.

### Tasks

**Week 9: Solar System Setup**
- [ ] Create `solar_system.tscn` (production scene)
- [ ] Add Sun (light source + gravity well)
- [ ] Add Earth and Moon (accurate scale/distance)
- [ ] Add Mars
- [ ] Implement LOD for planets (3 levels)
- [ ] Test: See planets from space

**Week 10: Interplanetary Travel**
- [ ] Implement time acceleration (optional)
- [ ] Test: Fly Earth → Mars (minutes, not hours)
- [ ] Add nav markers (point to planets)
- [ ] Add distance/velocity HUD
- [ ] Test in VR (long flight comfort)

**Week 11: Multi-Planet Physics**
- [ ] Gravitational sphere of influence
- [ ] Smooth transitions between gravity wells
- [ ] Test: Moon → Earth → Mars gravity
- [ ] Verify floating origin at planetary distances
- [ ] Test: No jitter at 1 AU distance

**Week 12: Polish & Optimize**
- [ ] Optimize rendering (frustum culling)
- [ ] Add skybox (stars)
- [ ] Add atmospheric effects (if on planet)
- [ ] Profile and optimize to 90 FPS
- [ ] Full system test (Earth → Mars → land)

### Feature Test Scenes
- `scenes/features/solar_system_scale_test.tscn` - Test distances
- `scenes/features/interplanetary_travel_test.tscn` - Test long flights
- `scenes/features/multi_gravity_test.tscn` - Test gravity transitions

### Acceptance Criteria
- ✅ Fly from Earth to Mars successfully
- ✅ Land on Mars
- ✅ Exit ship and walk on Mars
- ✅ Return to Earth
- ✅ No floating-point jitter at any distance
- ✅ 90 FPS maintained
- ✅ All tests pass

### Commit Message
"Phase 3 complete: Solar system interplanetary travel working"

### Estimated Time
4 weeks

---

## Phase 4: Multiplayer Foundation (Weeks 13-16)

### Goal
2-4 players can see each other and fly together (simple P2P).

### Tasks

**Week 13: Network Architecture**
- [ ] Create `NetworkManager.gd` (autoload)
- [ ] Implement P2P connection (Godot built-in)
- [ ] Design network protocol (state sync)
- [ ] Implement deterministic physics
- [ ] Test: Connect 2 clients locally

**Week 14: Player Sync**
- [ ] Sync player position/rotation
- [ ] Sync ship position/rotation
- [ ] Sync ship velocity (interpolation)
- [ ] Test: See other player walking
- [ ] Test: See other player flying

**Week 15: Interaction Sync**
- [ ] Sync VR hand positions
- [ ] Sync grab/release objects
- [ ] Sync ship enter/exit
- [ ] Test: Watch other player fly ship
- [ ] Test: Both players on same planet

**Week 16: Testing & Debugging**
- [ ] Test with 2 VR headsets
- [ ] Test with 4 players
- [ ] Fix desync issues
- [ ] Add network debug UI
- [ ] Optimize bandwidth

### Feature Test Scenes
- `scenes/features/network_sync_test.tscn` - Test basic sync
- `scenes/features/multiplayer_flight_test.tscn` - Test flying together
- `scenes/features/multiplayer_interaction_test.tscn` - Test interactions

### Acceptance Criteria
- ✅ 2 players can connect (P2P)
- ✅ See each other's ships flying
- ✅ See each other walking
- ✅ See VR hand movements
- ✅ No desync after 10 minutes
- ✅ 90 FPS maintained with 4 players
- ✅ All tests pass

### Commit Message
"Phase 4 complete: Basic multiplayer (2-4 players P2P) working"

### Estimated Time
4 weeks (networking is complex)

---

## Phase 5: Voxel Terrain & Mining (Weeks 17-20)

### Goal
Land on a voxel planet and dig/mine terrain.

### Tasks

**Week 17: Terrain Selection**
- [ ] Test Terrain3D performance in VR
- [ ] Test godot_voxel performance in VR
- [ ] Choose best performer
- [ ] Install chosen addon
- [ ] Create test voxel planet

**Week 18: Integration**
- [ ] Create `VoxelPlanetManager.gd`
- [ ] Generate procedural voxel terrain
- [ ] Implement LOD (5+ levels)
- [ ] Test: Approach from orbit
- [ ] Test: Land on voxel surface
- [ ] Optimize to 90 FPS

**Week 19: Mining System**
- [ ] Implement voxel removal (digging)
- [ ] Add mining tool (VR controller)
- [ ] Add collision updates (digging holes)
- [ ] Test: Dig tunnel in VR
- [ ] Add resources (ore types)
- [ ] Test: Mine resources

**Week 20: Polish**
- [ ] Add particle effects (dust when digging)
- [ ] Add audio (digging sounds)
- [ ] Add haptic feedback
- [ ] Optimize collision mesh generation (< 3ms)
- [ ] Test: Dig for 30 minutes (comfort)

### Feature Test Scenes
- `scenes/features/voxel_terrain_test.tscn` - Test terrain generation
- `scenes/features/mining_test.tscn` - Test digging
- `scenes/features/voxel_lod_test.tscn` - Test LOD transitions

### Acceptance Criteria
- ✅ Voxel planet generates
- ✅ Land on voxel surface
- ✅ Dig with VR controller
- ✅ Collision updates when digging
- ✅ 90 FPS maintained while mining
- ✅ All tests pass

### Commit Message
"Phase 5 complete: Voxel terrain and mining working"

### Estimated Time
4 weeks

---

## Phase 6: Optimization & Scaling (Weeks 21-24)

### Goal
Full solar system at 90 FPS, 16-32 players supported.

### Tasks

**Week 21: Rendering Optimization**
- [ ] Implement aggressive LOD (7+ levels)
- [ ] Implement occlusion culling
- [ ] GPU instancing for asteroids
- [ ] Frustum culling for planets
- [ ] Profile and optimize hotspots

**Week 22: Physics Optimization**
- [ ] Spatial partitioning (quadtree/octree)
- [ ] Sleep inactive objects
- [ ] Simplify collision (distant objects)
- [ ] Optimize gravity calculations
- [ ] Profile and optimize

**Week 23: Network Scaling**
- [ ] Implement interest management
- [ ] Test with 16 players
- [ ] Add P2P mesh (distributed authority)
- [ ] Optimize bandwidth (compression)
- [ ] Test with 32 players

**Week 24: Final Optimization**
- [ ] Full system profiling
- [ ] Fix all frame drops
- [ ] Test full gameplay loop (2 hours)
- [ ] Verify 90 FPS rock-solid
- [ ] Create performance test suite

### Feature Test Scenes
- `scenes/features/performance_stress_test.tscn` - Max load test
- `scenes/features/network_load_test.tscn` - 32 player test
- `scenes/features/lod_test.tscn` - LOD validation

### Acceptance Criteria
- ✅ 90 FPS with full solar system
- ✅ 90 FPS with 16 players
- ✅ 85+ FPS with 32 players
- ✅ No frame drops during gameplay
- ✅ All optimization tests pass

### Commit Message
"Phase 6 complete: Full solar system optimized to 90 FPS, 32 players supported"

### Estimated Time
4 weeks

---

## Phase 7: Persistence & Database (Weeks 25-28)

### Goal
Persistent universe, player progress saves, database integration.

### Tasks

**Week 25: Database Setup**
- [ ] Choose database (PostgreSQL or SQLite)
- [ ] Design schema (players, ships, inventory, positions)
- [ ] Create database connection module
- [ ] Test: Save/load player data
- [ ] Test: Query all players in universe

**Week 26: Save System**
- [ ] Create `SaveSystem.gd` (autoload)
- [ ] Save player position/inventory
- [ ] Save ship state
- [ ] Load on reconnect
- [ ] Test: Disconnect and reconnect

**Week 27: Persistent Universe**
- [ ] Track all players in database (updated every 30s)
- [ ] Query nearby players
- [ ] Spawn players when nearby
- [ ] Despawn players when far
- [ ] Test: 100 players in database

**Week 28: Integration Testing**
- [ ] Full gameplay loop with saves
- [ ] Test: Play, quit, resume
- [ ] Test: Database performance (1000 players)
- [ ] Optimize queries
- [ ] Add backup/restore

### Acceptance Criteria
- ✅ Player progress persists
- ✅ Ship inventory saved
- ✅ Database handles 1000+ players
- ✅ Queries < 50ms
- ✅ No data loss on crash

### Commit Message
"Phase 7 complete: Persistent universe with database working"

### Estimated Time
4 weeks

---

## Phase 8: Advanced Features (Weeks 29-40)

### Goal
AI NPCs, farming, economy, and advanced multiplayer.

### Tasks

**Weeks 29-32: AI NPCs**
- [ ] Set up godot_rl_agents
- [ ] Train AI to fly ships
- [ ] Train AI to walk/interact
- [ ] Add AI NPCs to universe
- [ ] Test: AI flies ship autonomously
- [ ] Add AI behaviors (patrol, trade, attack)

**Weeks 33-36: Farming & Economy**
- [ ] Implement farming system (plant/harvest)
- [ ] Add resource processing
- [ ] Add trading system
- [ ] Add economy simulation
- [ ] Test: Full resource loop

**Weeks 37-40: Distributed Mesh Networking**
- [ ] Implement zone assignment
- [ ] Implement validators (anti-cheat)
- [ ] Implement consensus algorithm
- [ ] Test: 100 player battle
- [ ] Optimize and debug

### Acceptance Criteria
- ✅ AI NPCs functional
- ✅ Farming works
- ✅ Economy balanced
- ✅ 100 players in distributed mesh

### Commit Message
"Phase 8 complete: AI NPCs, farming, economy, and distributed mesh working"

### Estimated Time
12 weeks

---

## Phase 9: Galaxy Expansion (Weeks 41+)

### Goal
Expand to full galaxy with procedural generation.

### Tasks
- [ ] Procedural star generation
- [ ] Procedural planet generation
- [ ] Warp drive implementation
- [ ] Galaxy map UI
- [ ] Test: Travel between star systems
- [ ] Optimize for galaxy scale

### Acceptance Criteria
- ✅ 1000+ star systems
- ✅ Warp drive functional
- ✅ 90 FPS maintained
- ✅ Galaxy-scale floating origin works

### Estimated Time
Ongoing (content expansion)

---

## Critical Success Factors

**After Each Phase:**
1. ✅ All tests must pass (no skipping)
2. ✅ Commit to git with phase complete message
3. ✅ Test in VR headset (manual validation)
4. ✅ Document any issues/learnings
5. ✅ Update CLAUDE.md if architecture changed

**Never Move to Next Phase Until:**
- Current phase compiles cleanly (0 errors)
- All automated tests pass
- Manual VR testing complete
- Performance targets met (90 FPS)
- Git commit created

**If You Get Stuck:**
- Review ARCHITECTURE_BLUEPRINT.md
- Create isolated test scene
- Ask for help (provide error messages)
- Don't hack around the problem (fix root cause)

---

## Current Status Tracking

**Phase 0:** ⏳ In Progress
- [ ] Day 1: Verification
- [ ] Day 2: Cleanup
- [ ] Day 3: Install tools
- [ ] Day 4: Test infrastructure
- [ ] Day 5: Baseline

**Next Phase:** Phase 1 (starts after Phase 0 complete)

---

**Follow these phases in order, and you will build a galaxy-scale VR MMO without rewrites.**
