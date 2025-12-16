# Known Issues

**Project:** Planetary Survival VR
**Last Updated:** 2025-12-02

---

## Critical Issues

### ISSUE-001: PlanetarySurvivalCoordinator Disabled

**Status:** 🔴 BLOCKING
**Priority:** Critical
**Component:** Core Integration
**Discovered:** 2025-12-02

**Description:**
The main `PlanetarySurvivalCoordinator` autoload is disabled in `project.godot` due to reported parse errors:

```gdscript
# Line 26 in project.godot
# PlanetarySurvivalCoordinator="*res://scripts/planetary_survival/planetary_survival_coordinator.gd"  # DISABLED: Parse errors blocking HTTP server initialization
```

**Impact:**
- Planetary Survival systems are not being initialized
- No integration between systems at runtime
- Cannot test end-to-end workflows
- HTTP API may conflict with system initialization

**Root Cause:**
Unknown - coordinator code appears valid. May be:
1. Missing dependencies in initialization order
2. Conflict with HTTP server initialization
3. Circular dependency issue

**Workaround:**
None - systems must be manually instantiated for testing

**Fix Required:**
1. Identify actual parse error (check Godot console)
2. Fix dependency issues
3. Test HTTP server compatibility
4. Re-enable autoload
5. Validate system initialization

**Assigned To:** TBD
**Target:** Before final release

---

### ISSUE-002: VR Performance Not Validated

**Status:** 🟡 NEEDS TESTING
**Priority:** Critical
**Component:** VR Performance
**Discovered:** 2025-12-02

**Description:**
No VR performance profiling has been conducted with all Planetary Survival systems active. Unknown if 90 FPS target is achievable.

**Impact:**
- May cause motion sickness if FPS too low
- VR comfort not validated
- Performance bottlenecks unknown
- Optimization targets unclear

**Workaround:**
None - testing required

**Testing Needed:**
1. Profile with all systems active
2. Identify bottlenecks
3. Measure frame time budget
4. Test with VR headset

**Acceptance Criteria:**
- Stable 90 FPS in VR
- Frame time <11.1ms
- Frame variance <2ms
- No dropped frames

**Assigned To:** TBD
**Target:** Before VR release

---

### ISSUE-003: Multiplayer End-to-End Not Tested

**Status:** 🟡 NEEDS TESTING
**Priority:** High
**Component:** Multiplayer Networking
**Discovered:** 2025-12-02

**Description:**
Individual multiplayer sync systems are implemented but not tested end-to-end with real players.

**Impact:**
- Unknown integration issues
- Conflict resolution untested
- Player experience unvalidated
- Network bandwidth unknown

**Workaround:**
Single-player testing only

**Testing Needed:**
1. Test with 2 VR players
2. Test with 4-8 VR players
3. Test all sync systems together
4. Validate conflict resolution
5. Measure network bandwidth

**Acceptance Criteria:**
- 2-8 players can play together
- Terrain sync works correctly
- Structure placement syncs
- No item duplication bugs
- Bandwidth <256 KB/s per player

**Assigned To:** TBD
**Target:** Before multiplayer release

---

### ISSUE-004: Server Meshing Not Load Tested

**Status:** 🟡 NEEDS TESTING
**Priority:** High
**Component:** Server Meshing
**Discovered:** 2025-12-02

**Description:**
Server meshing architecture implemented but not tested with realistic player loads.

**Impact:**
- Authority transfer performance unknown
- Load balancing behavior untested
- Horizontal scaling unvalidated
- Failover reliability unknown

**Workaround:**
Single-server multiplayer only

**Testing Needed:**
1. Test with 100 simulated players
2. Test with 1000 simulated players
3. Measure authority transfer times
4. Test server failover scenarios
5. Validate load balancing

**Acceptance Criteria:**
- Authority transfer <100ms
- Failover recovery <5s
- Linear scaling to 1000 players
- Load balanced across servers

**Assigned To:** TBD
**Target:** Before massive multiplayer release

---

## High Priority Issues

### ISSUE-005: Persistence System Not End-to-End Tested

**Status:** 🟡 NEEDS TESTING
**Priority:** High
**Component:** Save/Load System
**Discovered:** 2025-12-02

**Description:**
`PersistenceSystem` and `WorldSaveSystem` implemented but not fully tested.

**Impact:**
- Save/load may be broken
- World state may not persist correctly
- Multiplayer saves untested
- Data corruption possible

**Testing Needed:**
1. Save/load single-player world
2. Save/load multiplayer world
3. Test procedural-to-persistent conversion
4. Validate data integrity
5. Test large world saves

**Acceptance Criteria:**
- All game state saves correctly
- Loads restore exact state
- No data corruption
- Multiplayer saves work

**Assigned To:** TBD
**Target:** Before beta release

---

## Medium Priority Issues

### ISSUE-006: Property Tests Incomplete

**Status:** 🟡 PARTIAL
**Priority:** Medium
**Component:** Testing
**Discovered:** 2025-12-02

**Description:**
Many property tests marked in tasks.md but not all implemented:

Missing tests (from tasks.md):
- Property 8: Tunnel geometry persistence (task 1.1)
- Property 18: Automated mining extraction (task 14.3)
- Property 22-25: Creature taming/commands (tasks 15.3, 15.4, 15.8)
- Property 26-27: Breeding and stat inheritance (tasks 17.2, 17.4)
- Property 29: Crop growth progression (task 18.2)
- Property 33: Structure damage calculation (task 19.2)
- Property 31: Container destruction item drop (task 12.8)
- Property 34-35: Deterministic generation (tasks 30.2, 30.4)
- Property 37-49: Network and server meshing properties (tasks 31.3, 31.5, 33.2, 34.4, 35.3, 37.3, 38.2, 39.2, 39.4, 41.2, 42.3, 43.3, 46.2)

**Impact:**
- Incomplete test coverage
- Invariants not validated
- Edge cases may be missed

**Workaround:**
Manual testing

**Fix Required:**
Implement missing property tests

**Assigned To:** TBD
**Target:** Before v1.0 release

---

### ISSUE-007: Base Defense Not Fully Implemented

**Status:** 🟡 PARTIAL
**Priority:** Medium
**Component:** Gameplay
**Discovered:** 2025-12-02

**Description:**
Base defense system (Task 19 in tasks.md) marked incomplete:
- Task 19.1: Hostile creature AI - NOT DONE
- Task 19.2: Structure damage property test - NOT DONE
- Task 19.3: Automated turrets - NOT DONE
- Task 19.4: Creature defense commands - NOT DONE

**Impact:**
- No base attacks
- No defense mechanics
- Turrets not functional
- Gameplay loop incomplete

**Workaround:**
None - feature missing

**Fix Required:**
Complete Task 19 implementation

**Assigned To:** TBD
**Target:** Before v1.0 release

---

## Low Priority Issues

### ISSUE-008: Farming System Not Fully Tested

**Status:** 🟡 NEEDS TESTING
**Priority:** Low
**Component:** Farming
**Discovered:** 2025-12-02

**Description:**
FarmingSystem implemented but missing property test (Task 18.2):
- Property 29: Crop growth progression

**Impact:**
- Crop growth behavior not validated
- Edge cases untested

**Workaround:**
Manual testing

**Fix Required:**
Implement property test for crop growth

**Assigned To:** TBD
**Target:** Before v1.0 release

---

### ISSUE-009: Monitoring and Observability Not Implemented

**Status:** 🔴 NOT STARTED
**Priority:** Low
**Component:** DevOps
**Discovered:** 2025-12-02

**Description:**
Task 45 (Monitoring and Observability) not started:
- Task 45.1: Prometheus metrics - NOT DONE
- Task 45.2: Alerting system - NOT DONE
- Task 45.3: Distributed tracing - NOT DONE
- Task 45.4: Grafana dashboards - NOT DONE

**Impact:**
- No production monitoring
- No alerting for issues
- Hard to debug distributed systems
- No performance visibility

**Workaround:**
Manual log analysis

**Fix Required:**
Implement monitoring stack

**Assigned To:** TBD
**Target:** Before production deployment

---

### ISSUE-010: Deployment Infrastructure Not Set Up

**Status:** 🔴 NOT STARTED
**Priority:** Low
**Component:** DevOps
**Discovered:** 2025-12-02

**Description:**
Task 47.3 (Deployment infrastructure) not started:
- Kubernetes cluster setup
- Auto-scaling policies
- Monitoring stack deployment

**Impact:**
- Cannot deploy to production
- No horizontal scaling
- Manual deployment required

**Workaround:**
Local testing only

**Fix Required:**
Set up Kubernetes cluster and deployment pipeline

**Assigned To:** TBD
**Target:** Before production deployment

---

## Performance Concerns

### PERF-001: Voxel Terrain LOD Not Optimized

**Status:** ⚠️ CONCERN
**Priority:** Medium
**Component:** Rendering
**Discovered:** 2025-12-02

**Description:**
VoxelTerrainOptimizer.gd exists but LOD implementation may not be fully optimized for VR.

**Concern:**
- Distant terrain may render at full detail
- Mesh generation may block main thread
- Occlusion culling may not be effective

**Investigation Needed:**
1. Profile mesh generation time
2. Measure render time for distant chunks
3. Test occlusion culling effectiveness
4. Benchmark against 90 FPS target

**Mitigation:**
See VR_OPTIMIZATION.md for strategies

---

### PERF-002: Creature AI May Not Scale

**Status:** ⚠️ CONCERN
**Priority:** Medium
**Component:** Gameplay
**Discovered:** 2025-12-02

**Description:**
CreatureSystem implemented but AI update strategy may not scale to 100+ creatures.

**Concern:**
- All creatures may update every frame
- Pathfinding may be expensive
- Distant creatures may consume CPU

**Investigation Needed:**
1. Profile AI update time
2. Measure pathfinding cost
3. Test with 100 creatures

**Mitigation:**
Implement staggered updates and distance-based AI quality (see VR_OPTIMIZATION.md)

---

### PERF-003: Network Bandwidth Unknown

**Status:** ⚠️ CONCERN
**Priority:** High
**Component:** Networking
**Discovered:** 2025-12-02

**Description:**
Network bandwidth usage not measured. May exceed acceptable limits for VR hand tracking.

**Concern:**
- VR hand tracking may use excessive bandwidth
- Terrain sync may cause spikes
- Player count may be limited by bandwidth

**Investigation Needed:**
1. Measure baseline bandwidth per player
2. Profile VR hand tracking bandwidth
3. Test bandwidth with 8 players

**Mitigation:**
Implement compression and update rate optimization (see VR_OPTIMIZATION.md)

---

## Documentation Gaps

### DOC-001: API Documentation Incomplete

**Status:** 🟡 PARTIAL
**Priority:** Low
**Component:** Documentation
**Discovered:** 2025-12-02

**Description:**
Many systems lack comprehensive API documentation.

**Impact:**
- Hard to use systems programmatically
- Integration difficult
- Examples missing

**Fix Required:**
Document public APIs for all systems

**Assigned To:** TBD
**Target:** Before v1.0 release

---

## Resolved Issues

### ISSUE-RESOLVED-001: HTTP API Server Parse Errors

**Status:** ✅ RESOLVED
**Resolved:** 2025-11-XX
**Component:** HTTP API

**Description:**
HTTP API server had parse errors blocking initialization.

**Resolution:**
Fixed parse errors in http_api_server.gd. Verified working with curl tests.

---

## Issue Tracking Process

### Reporting New Issues

1. **Check existing issues** - Avoid duplicates
2. **Reproduce reliably** - Document steps
3. **Add to this document** - Use template below
4. **Notify team** - For critical issues
5. **Create task** - If fix needed soon

### Issue Template

```markdown
### ISSUE-XXX: Short Title

**Status:** 🔴 CRITICAL / 🟡 NEEDS TESTING / ⚠️ CONCERN
**Priority:** Critical / High / Medium / Low
**Component:** System Name
**Discovered:** YYYY-MM-DD

**Description:**
Clear description of the issue

**Impact:**
What breaks / What's affected

**Workaround:**
Temporary solution (if any)

**Fix Required:**
Steps to resolve

**Assigned To:** Name / TBD
**Target:** Release milestone
```

---

## Priority Definitions

- **Critical:** Blocks release, must fix immediately
- **High:** Impacts major functionality, fix before release
- **Medium:** Impacts minor functionality, fix if time permits
- **Low:** Nice to have, can defer to future release

---

**Document Version:** 1.0
**Last Updated:** 2025-12-02
**Maintained By:** Planetary Survival Team
**Review Frequency:** Weekly during development, monthly after release
