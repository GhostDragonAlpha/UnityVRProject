# VR Optimization Guide

**Project:** Planetary Survival VR
**Target:** Stable 90 FPS in VR
**Date:** 2025-12-02

---

## Performance Requirements

### Frame Rate Targets

| Priority | System | Target FPS | Critical? |
|----------|--------|------------|-----------|
| **CRITICAL** | VR Headset | 90 FPS | YES - Motion sickness |
| High | Desktop Fallback | 60 FPS | NO |

### Frame Time Budget

- **Total Frame Time:** 11.11ms (90 FPS)
- **Physics Tick:** 11.11ms (90 Hz, matching VR refresh)
- **Network Update:** 50ms (20 Hz position sync)

**Frame Time Breakdown (Target):**
```
Physics:     4.0ms  (36%)  - Voxel collision, creature AI
Rendering:   4.0ms  (36%)  - Mesh generation, lighting
Networking:  1.0ms  (9%)   - State sync, compression
Gameplay:    1.5ms  (13%)  - Systems update, automation
Buffer:      0.6ms  (6%)   - Safety margin
TOTAL:      11.1ms  (100%)
```

---

## Optimization Strategy

### Phase 1: Measurement (Current Status)

**Tools:**
- Godot Profiler (Performance Monitor)
- VR Compositor Frame Time
- TelemetryServer (real-time metrics)
- Custom performance markers

**Key Metrics to Track:**
```gdscript
# In PerformanceOptimizer.gd
var frame_metrics = {
    "physics_time": 0.0,
    "render_time": 0.0,
    "network_time": 0.0,
    "voxel_mesh_gen_time": 0.0,
    "creature_ai_time": 0.0,
    "automation_time": 0.0
}
```

### Phase 2: Rendering Optimization

#### 2.1 Voxel Terrain LOD

**Current Implementation:** `voxel_terrain_optimizer.gd`

**Optimizations:**
1. **Distance-Based LOD:**
   - 0-50m: Full detail (1m³ voxels)
   - 50-200m: Medium detail (2m³ voxels)
   - 200-500m: Low detail (4m³ voxels)
   - 500m+: Imposters/billboards

2. **Marching Cubes Mesh Generation:**
   - Generate meshes in background thread
   - Cache generated meshes
   - Update only modified chunks
   - Use mesh pooling to reduce allocations

3. **Occlusion Culling:**
   - Cull underground chunks when above ground
   - Use portal culling for cave systems
   - Implement frustum culling for distant chunks

**Code Example:**
```gdscript
# In VoxelTerrainOptimizer.gd
func update_lod_for_player(player_position: Vector3) -> void:
    for chunk in active_chunks:
        var distance = chunk.global_position.distance_to(player_position)
        var target_lod = _calculate_lod_level(distance)

        if chunk.current_lod != target_lod:
            _schedule_lod_transition(chunk, target_lod)

func _calculate_lod_level(distance: float) -> int:
    if distance < 50.0: return 0  # Full detail
    if distance < 200.0: return 1  # Medium
    if distance < 500.0: return 2  # Low
    return 3  # Imposter
```

#### 2.2 Lighting Optimization

**Issues:**
- Real-time shadows expensive in VR
- Many base modules with dynamic lights

**Solutions:**
1. **Baked Lighting:**
   - Use LightmapGI for static base modules
   - Bake shadows for placed structures
   - Update lightmaps when structures change

2. **Dynamic Light Budget:**
   - Maximum 8 dynamic lights per scene
   - Prioritize nearest lights to player
   - Use lower shadow quality for distant lights

3. **Shadow Optimization:**
   - Reduce DirectionalLight shadow distance: 100m
   - Use PCF5 instead of PCF13 for shadows
   - Disable shadows for small point lights

**Settings:**
```gdscript
# In RenderingSystem or VRManager
DirectionalLight3D:
    shadow_enabled: true
    directional_shadow_max_distance: 100.0
    directional_shadow_mode: ORTHOGONAL
    directional_shadow_split_1: 0.1
    shadow_filter: PCF5

PointLight3D (base modules):
    shadow_enabled: false  # Too expensive
    omni_range: 10.0  # Limit range
```

#### 2.3 Particle and Effect Optimization

**Issues:**
- Terrain tool effects
- Weather particle systems
- Explosion effects

**Solutions:**
1. **Particle Budget:**
   - Max 500 particles total
   - Reduce particle count based on distance
   - Disable particles when FPS < 80

2. **GPU Particles:**
   - Use GPUParticles3D instead of CPUParticles3D
   - Batch similar effects
   - Use texture atlases

### Phase 3: Physics Optimization

#### 3.1 Voxel Collision

**Issues:**
- Modified terrain creates complex collision shapes
- Frequent terrain deformation updates

**Solutions:**
1. **Collision Simplification:**
   ```gdscript
   # Simplify collision mesh for modified terrain
   func generate_simplified_collision(voxel_data: PackedByteArray) -> ConvexPolygonShape3D:
       # Use convex decomposition instead of exact mesh
       var convex_shapes = ConvexDecomposition.decompose(mesh, max_hulls=4)
       return convex_shapes
   ```

2. **Lazy Collision Updates:**
   - Batch collision updates (max 5 per frame)
   - Update collision only when player nearby
   - Cache collision shapes

3. **Spatial Partitioning:**
   - Use octree for collision detection
   - Only check collisions in nearby chunks

#### 3.2 Creature AI Optimization

**Issues:**
- Pathfinding expensive for many creatures
- AI updates for all creatures every frame

**Solutions:**
1. **Staggered Updates:**
   ```gdscript
   # Update 10% of creatures per frame
   func _physics_process(delta: float) -> void:
       var creatures_to_update = total_creatures / 10
       var start_idx = (Engine.get_physics_frames() % 10) * creatures_to_update

       for i in range(start_idx, start_idx + creatures_to_update):
           creatures[i].update_ai(delta * 10.0)  # Compensate for update rate
   ```

2. **Distance-Based AI Quality:**
   - 0-30m: Full AI (pathfinding, behaviors)
   - 30-100m: Simple AI (move toward target)
   - 100m+: Frozen (no AI updates)

3. **Pathfinding Optimization:**
   - Cache paths for 5 seconds
   - Use A* with limited nodes (max 1000)
   - Async pathfinding in background thread

### Phase 4: Networking Optimization

#### 4.1 Bandwidth Reduction

**Current Bandwidth:** Unknown - NEEDS PROFILING

**Target Bandwidth:** <256 KB/s per player

**Strategies:**

1. **VR Hand Tracking Compression:**
   ```gdscript
   # Compress hand transforms
   func compress_hand_transform(transform: Transform3D) -> PackedByteArray:
       var buffer = PackedByteArray()
       # Quantize position to 16-bit (0.01m precision)
       buffer.append_array(Vector3_to_int16(transform.origin, 0.01))
       # Quantize rotation to quaternion with 16-bit components
       buffer.append_array(Quaternion_to_int16(transform.basis.get_rotation_quaternion()))
       return buffer  # 14 bytes instead of 48 bytes
   ```

2. **Delta Encoding:**
   - Send only changes since last update
   - Use delta compression for transforms
   - Batch small updates together

3. **Update Prioritization:**
   - Nearby players: 20 Hz
   - Medium distance: 10 Hz
   - Distant players: 2 Hz
   - Out of view: 0.5 Hz

4. **Spatial Interest Management:**
   ```gdscript
   # Only sync entities within interest radius
   func get_entities_for_player(player: Player) -> Array:
       var interest_radius = 200.0  # meters
       return spatial_grid.query_sphere(player.position, interest_radius)
   ```

#### 4.2 Terrain Sync Optimization

**Issues:**
- Large voxel modifications = lots of data
- Frequent terrain changes in multiplayer

**Solutions:**

1. **Modification Batching:**
   - Batch terrain mods into 1-second windows
   - Compress using run-length encoding
   - Send deltas, not full chunks

2. **Compression:**
   ```gdscript
   func compress_voxel_modification(mod_data: Dictionary) -> PackedByteArray:
       var json = JSON.stringify(mod_data)
       return json.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
       # Typical: 80% size reduction
   ```

3. **Lazy Synchronization:**
   - Don't sync terrain until player nearby
   - Sync only visible/interactable chunks
   - Use interest management

### Phase 5: Gameplay System Optimization

#### 5.1 Automation System

**Issues:**
- Conveyor belts with 100+ items
- Machine processing updates

**Solutions:**

1. **Item Batching:**
   ```gdscript
   # Represent multiple items as single stack
   class ConveyorStack:
       var item_type: String
       var count: int
       var position: float
   ```

2. **Update Budgeting:**
   - Process max 50 machines per frame
   - Stagger machine updates
   - Skip updates when power off

3. **Visualization Culling:**
   - Don't render distant conveyor items
   - Use simplified models for distant machines

#### 5.2 Base Building

**Issues:**
- Many placed modules
- Structural integrity calculations

**Solutions:**

1. **Integrity Caching:**
   ```gdscript
   # Recalculate only when structures change
   var integrity_cache: Dictionary = {}

   func get_structural_integrity(module: BaseModule) -> float:
       if not integrity_dirty:
           return integrity_cache.get(module, 1.0)
       _recalculate_integrity()
       return integrity_cache[module]
   ```

2. **Module Instancing:**
   - Use MultiMeshInstance3D for identical modules
   - Reduce draw calls dramatically

---

## Optimization Checklist

### Rendering
- [ ] Implement 4-level LOD for voxel terrain
- [ ] Enable occlusion culling for underground areas
- [ ] Reduce DirectionalLight shadow distance to 100m
- [ ] Use PCF5 shadow filter quality
- [ ] Disable shadows on PointLights
- [ ] Limit dynamic lights to 8 per scene
- [ ] Use GPUParticles3D, max 500 particles
- [ ] Profile: Target 4ms render time

### Physics
- [ ] Simplify voxel collision meshes (convex hulls)
- [ ] Batch collision updates (max 5/frame)
- [ ] Implement spatial partitioning (octree)
- [ ] Stagger creature AI updates (10% per frame)
- [ ] Add distance-based AI quality levels
- [ ] Cache pathfinding results (5s)
- [ ] Profile: Target 4ms physics time

### Networking
- [ ] Compress VR hand transforms (16-bit quantization)
- [ ] Implement delta encoding for all transforms
- [ ] Add spatial interest management (200m radius)
- [ ] Use distance-based update rates (20Hz→0.5Hz)
- [ ] Batch terrain modifications (1s windows)
- [ ] Compress voxel data (GZIP)
- [ ] Profile: Target <256 KB/s bandwidth, <1ms frame time

### Gameplay Systems
- [ ] Batch conveyor belt items into stacks
- [ ] Stagger machine updates (max 50/frame)
- [ ] Cache structural integrity calculations
- [ ] Use MultiMeshInstance3D for identical modules
- [ ] Implement visualization culling for distant objects
- [ ] Profile: Target 1.5ms gameplay time

### VR Comfort
- [ ] Maintain 90 FPS minimum (no dropped frames)
- [ ] Keep frame time variance <2ms
- [ ] Implement asynchronous spacewarp fallback
- [ ] Add performance warning when FPS <85

---

## Performance Testing Protocol

### Test Scenarios

**Scenario 1: Terrain Deformation**
- Excavate large tunnel system (100m)
- Measure frame time during excavation
- Measure frame time after excavation
- Target: <11ms frame time

**Scenario 2: Base Building**
- Place 50 base modules with connections
- Activate 20 machines
- Run automation with 200 items on belts
- Target: <11ms frame time

**Scenario 3: Creature Load**
- Spawn 50 creatures in view
- Spawn 100 creatures nearby but out of view
- Measure AI update time
- Target: <2ms AI time

**Scenario 4: Multiplayer**
- 4 VR players in same area
- Each player using terrain tool
- Building bases simultaneously
- Measure network time and bandwidth
- Target: <11ms frame time, <256 KB/s bandwidth

**Scenario 5: Stress Test**
- 1000 entities total
- 500 voxel chunks loaded
- 10 VR players
- All systems active
- Target: Graceful degradation, maintain 60+ FPS

### Profiling Tools

**Godot Built-in:**
```gdscript
# Enable in-game profiler
Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
Performance.get_monitor(Performance.TIME_PROCESS)
Performance.get_monitor(Performance.RENDER_OBJECTS_IN_FRAME)
Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)
```

**Custom Telemetry:**
```gdscript
# Send to TelemetryServer for real-time monitoring
TelemetryServer.send_metric("voxel_chunks_loaded", active_chunks.size())
TelemetryServer.send_metric("frame_time_ms", delta * 1000.0)
TelemetryServer.send_metric("creatures_active", creature_count)
```

**VR Compositor:**
- Use SteamVR frame timing graph
- Monitor reprojection ratio
- Check dropped frames

---

## Fallback Strategies

### Dynamic Quality Adjustment

**Performance Optimizer Integration:**
```gdscript
# PerformanceOptimizer.gd already exists
# Enhance with VR-specific targets

func _process(delta: float) -> void:
    var current_fps = 1.0 / delta

    if current_fps < 85.0:  # Below comfortable VR threshold
        degrade_quality()
    elif current_fps > 100.0:  # Headroom available
        improve_quality()

func degrade_quality() -> void:
    # Reduce LOD distances
    voxel_terrain_optimizer.reduce_lod_distance(0.8)
    # Reduce particle count
    particle_budget *= 0.5
    # Reduce shadow quality
    shadow_quality = QUALITY_LOW
    # Reduce AI update rate
    creature_ai_update_rate *= 0.5

func improve_quality() -> void:
    # Restore quality settings
    ...
```

### Asynchronous Spacewarp (ASW)

**Last Resort:** If 90 FPS cannot be maintained, enable ASW/motion smoothing:
- Generates intermediate frames
- Reduces motion sickness from dropped frames
- NOT IDEAL - aim for native 90 FPS

---

## Performance Targets Summary

| Metric | Target | Critical |
|--------|--------|----------|
| **Frame Rate** | 90 FPS | YES |
| **Frame Time** | 11.1ms | YES |
| **Frame Variance** | <2ms | YES |
| **Physics Time** | <4ms | NO |
| **Render Time** | <4ms | NO |
| **Network Bandwidth** | <256 KB/s | NO |
| **Network Frame Time** | <1ms | NO |
| **Voxel Chunks Active** | <500 | NO |
| **Creatures Active** | <200 | NO |
| **Dynamic Lights** | <8 | YES |
| **Particles** | <500 | NO |

---

## Next Steps

1. **Enable PlanetarySurvivalCoordinator** - Activate systems
2. **Run Performance Baseline** - Measure current performance
3. **Identify Bottlenecks** - Profile each system
4. **Apply Optimizations** - Start with biggest wins
5. **Test in VR** - Validate with real headset
6. **Iterate** - Repeat until 90 FPS achieved

---

**Document Version:** 1.0
**Last Updated:** 2025-12-02
**Maintained By:** Planetary Survival Team
