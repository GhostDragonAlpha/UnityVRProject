# Rendering System Documentation

## Overview

Comprehensive documentation for SpaceTime's rendering pipeline, covering 9 interconnected systems optimized for VR performance (90 FPS target).

## Documentation Files

### 1. [RENDERING_ARCHITECTURE.md](RENDERING_ARCHITECTURE.md)
**Main architectural overview** - Start here for system understanding.

**Contents:**
- System component diagram
- Initialization dependencies
- Rendering pipeline flow
- Performance budgets
- Quality level settings
- Best practices and troubleshooting

**Key Topics:**
- PBR pipeline configuration
- Inter-system communication
- Frame budget breakdown (11.11ms total)
- Requirements implementation (16.1-16.5, 28.1-28.5, etc.)

---

### 2. [LOD_SYSTEM.md](LOD_SYSTEM.md)
**LOD Manager deep-dive** - Distance-based detail reduction.

**Contents:**
- LOD level concepts and thresholds
- Complete API reference
- Registration patterns (manual, auto, priority-based)
- Visibility culling with `VisibleOnScreenNotifier3D`
- Performance tuning
- Integration with other systems

**Key Features:**
- 5 LOD levels (0-4) with configurable distances
- LOD bias for quality scaling (0.25-1.5)
- Per-object custom distances and priorities
- Automatic visibility culling

**Use When:**
- Objects have multiple detail levels
- Distance-based optimization needed
- VR performance critical

---

### 3. [QUANTUM_RENDERING.md](QUANTUM_RENDERING.md)
**Quantum Render system** - Observation-based rendering.

**Contents:**
- Quantum state model (OBSERVED, UNOBSERVED, COLLAPSING, DECOHERING)
- Probability cloud generation with `GPUParticles3D`
- Collision simplification (detailed → sphere)
- 0.1 second collapse transitions
- Thematic integration with gameplay

**Key Features:**
- View frustum detection
- Automatic particle cloud rendering
- 80% vertex reduction for unobserved objects
- 90% collision detection speedup

**Use When:**
- Objects frequently off-screen
- Thematic quantum mechanics desired
- Memory/performance optimization needed

---

### 4. [SHADER_SYSTEM.md](SHADER_SYSTEM.md)
**Shader Manager guide** - Centralized shader loading and hot-reload.

**Contents:**
- Shader loading and caching
- Hot-reload workflow (live shader editing)
- Material management
- Fallback handling
- Post-processing pipeline setup
- Performance considerations

**Key Features:**
- Load `.gdshader` files with caching
- 1-second hot-reload interval (configurable)
- Named material instances
- Graceful fallback for missing shaders

**Use When:**
- Loading custom shaders
- Need hot-reload for iteration
- Managing multiple material variants
- Building post-processing pipelines

---

## Quick Reference

### System Selection Guide

| Need | Use System | Documentation |
|------|-----------|---------------|
| Distance-based LOD | LODManager | [LOD_SYSTEM.md](LOD_SYSTEM.md) |
| Off-screen optimization | QuantumRender | [QUANTUM_RENDERING.md](QUANTUM_RENDERING.md) |
| Custom shaders | ShaderManager | [SHADER_SYSTEM.md](SHADER_SYSTEM.md) |
| PBR materials | PBRMaterialFactory | [RENDERING_ARCHITECTURE.md](RENDERING_ARCHITECTURE.md#material-library) |
| Post-processing | PostProcessing | [RENDERING_ARCHITECTURE.md](RENDERING_ARCHITECTURE.md#requirements-131-135-entropy-based-post-processing) |
| Performance tuning | PerformanceOptimizer | [RENDERING_ARCHITECTURE.md](RENDERING_ARCHITECTURE.md#performance-budgets) |
| Atmosphere effects | AtmosphereSystem | See `C:/godot/scripts/rendering/atmosphere_system.gd` |
| Lattice visualization | LatticeRenderer | See `C:/godot/scripts/rendering/lattice_renderer.gd` |
| Core pipeline | RenderingSystem | [RENDERING_ARCHITECTURE.md](RENDERING_ARCHITECTURE.md#core-rendering-pipeline) |

### Common Workflows

#### 1. Setting Up a New Object with LOD

```gdscript
# Load high, medium, low detail meshes
var lod_levels: Array[Node3D] = [high_mesh, medium_mesh, low_mesh]

# Register with LOD manager
lod_manager.register_object("my_object", root_node, lod_levels)

# Optional: Set priority for important objects
lod_manager.set_object_priority("my_object", 2.0)
```

**Documentation:** [LOD_SYSTEM.md § Registration](LOD_SYSTEM.md#registering-objects)

#### 2. Adding Quantum Rendering to Objects

```gdscript
# Register object with quantum system
quantum_render.register_object(
    "my_object",
    root_node,
    solid_mesh_instance,
    collision_shape  # Optional
)

# Update visibility bounds for accurate culling
var mesh_aabb = solid_mesh_instance.get_aabb()
quantum_render.set_object_bounds("my_object", mesh_aabb)
```

**Documentation:** [QUANTUM_RENDERING.md § Registering Objects](QUANTUM_RENDERING.md#registering-objects)

#### 3. Loading a Custom Shader

```gdscript
# Load shader file
var shader = shader_manager.load_shader("my_shader", "my_shader.gdshader")

# Create material
var material = shader_manager.create_shader_material("my_shader", "my_material")

# Set parameters
shader_manager.set_shader_parameter("my_material", "intensity", 1.0)

# Apply to mesh
mesh_instance.material_override = material

# Enable hot-reload for development
if OS.is_debug_build():
    shader_manager.enable_hot_reload()
```

**Documentation:** [SHADER_SYSTEM.md § Usage Patterns](SHADER_SYSTEM.md#usage-patterns)

#### 4. Creating PBR Materials

```gdscript
# Get material factory from rendering system
var factory = rendering_system.get_material_factory()

# Use preset for common materials
var hull = factory.create_spacecraft_hull_material()
var glass = factory.create_spacecraft_glass_material()

# Or create custom PBR material
var custom = factory.create_material(
    Color(0.8, 0.8, 0.9),  # Albedo
    0.4,                   # Roughness
    0.7,                   # Metallic
    Color.BLACK,           # Emission
    0.0                    # Emission energy
)
```

**Documentation:** [RENDERING_ARCHITECTURE.md § Material Library](RENDERING_ARCHITECTURE.md#material-library)

#### 5. Setting Up Post-Processing

```gdscript
# Initialize post-processing
post_processing.initialize(canvas_layer)

# Set entropy level (0.0 = healthy, 1.0 = corrupted)
post_processing.set_entropy(0.3)  # Triggers chromatic aberration and noise

# Individual effect control
post_processing.set_chromatic_aberration_strength(1.5)
post_processing.set_scanline_strength(0.8)
post_processing.set_pixelation_strength(0.5)
```

**Documentation:** [RENDERING_ARCHITECTURE.md § Requirements 13.1-13.5](RENDERING_ARCHITECTURE.md#requirements-131-135-entropy-based-post-processing)

---

## Performance Optimization

### Frame Budget (90 FPS = 11.11ms)

| Component | Budget | Percentage |
|-----------|--------|------------|
| Physics | 3.0 ms | 27% |
| Rendering | 5.0 ms | 45% |
| Shaders | 2.0 ms | 18% |
| Game Logic | 0.5 ms | 5% |
| Post-Processing | 0.3 ms | 3% |
| Buffer | 0.3 ms | 2% |

### Quality Presets

| Setting | Ultra | High | Medium | Low | Minimum |
|---------|-------|------|--------|-----|---------|
| **Target FPS** | 120+ | 90+ | 90 | 90 | 90 |
| **LOD Bias** | 1.5 | 1.0 | 0.75 | 0.5 | 0.25 |
| **MSAA** | 4x | 2x | 2x | Off | Off |
| **TAA** | On | On | Off | Off | Off |
| **SDFGI** | On | On | Half-res | Off | Off |
| **Shadow Splits** | 4 | 4 | 2 | 2 | 2 |

**Automatic quality adjustment** via `PerformanceOptimizer` when FPS drops below 80.

### Optimization Checklist

- [ ] **LOD registered for all distant objects** (>100 units)
- [ ] **Quantum rendering for off-screen objects**
- [ ] **Occlusion culling enabled** for large opaque geometry
- [ ] **Shader hot-reload disabled** in production
- [ ] **LOD update frequency** set to 30 Hz (not every frame)
- [ ] **Visibility notifier AABBs** match object bounds
- [ ] **Material caching** enabled for reused materials
- [ ] **Post-processing** only enabled when needed (entropy-based)

---

## System Integration

### ResonanceEngine Phase 3 - VR and Rendering

```gdscript
# Initialization order (managed by ResonanceEngine)
1. VRManager
2. VRComfortSystem
3. HapticManager
4. RenderingSystem  ← Initializes child systems
   ├─ ShaderManager
   ├─ PBRMaterialFactory
   ├─ LODManager
   ├─ QuantumRender
   ├─ PostProcessing
   ├─ LatticeRenderer
   └─ AtmosphereSystem
```

### Accessing Rendering Systems

```gdscript
# Via ResonanceEngine (recommended)
var rendering_system = ResonanceEngine.get_subsystem("RenderingSystem")
var lod_manager = rendering_system.get_lod_manager()
var shader_manager = rendering_system.get_shader_manager()

# Direct access (for testing only)
var lod_manager = LODManager.new()
lod_manager.initialize(camera)
```

---

## Troubleshooting

### Issue: Low FPS (< 90)

**Check:**
1. `performance_optimizer.get_current_fps()` - Actual FPS
2. `performance_optimizer.get_performance_report()` - Detailed stats
3. `lod_manager.get_statistics()` - LOD switches per frame

**Solutions:**
- Enable automatic quality adjustment
- Reduce LOD bias
- Lower update frequencies (LOD, Quantum)
- Disable SDFGI

**Documentation:** [RENDERING_ARCHITECTURE.md § Performance Budgets](RENDERING_ARCHITECTURE.md#performance-budgets)

### Issue: LOD flickering at thresholds

**Check:**
- LOD distance thresholds
- Update frequency

**Solutions:**
- Add distance buffer (10-20%)
- Reduce update frequency to 30 Hz
- Use custom per-object distances

**Documentation:** [LOD_SYSTEM.md § Troubleshooting](LOD_SYSTEM.md#troubleshooting)

### Issue: Quantum objects not transitioning

**Check:**
- Visibility notifier AABB size
- Camera reference set
- Update frequency

**Solutions:**
- Update bounds: `quantum_render.set_object_bounds(id, mesh.get_aabb())`
- Set camera: `quantum_render.set_camera(camera)`
- Increase update rate: `quantum_render.set_update_frequency(60.0)`

**Documentation:** [QUANTUM_RENDERING.md § Troubleshooting](QUANTUM_RENDERING.md#troubleshooting)

### Issue: Shader hot-reload not working

**Check:**
- Hot-reload enabled
- File modification time changes
- Check interval

**Solutions:**
- Enable: `shader_manager.enable_hot_reload()`
- Reduce interval: `shader_manager.set_hot_reload_interval(0.5)`
- Manual reload: `shader_manager.reload_shader("shader_name")`

**Documentation:** [SHADER_SYSTEM.md § Hot-Reload Technical Details](SHADER_SYSTEM.md#hot-reload-technical-details)

---

## Requirements Coverage

This rendering system implements the following requirements:

### Core Rendering (1.x, 16.x)
- **1.3:** Built-in PBR pipeline → `RenderingSystem`
- **16.1:** Inverse square law lighting → `calculate_inverse_square_intensity()`
- **16.2:** Shadow volumes → DirectionalLight3D configuration
- **16.3:** Near-zero ambient in shadow → Environment settings
- **16.4:** PBR materials → `PBRMaterialFactory`
- **16.5:** Penumbra/umbra → `light_angular_distance`

### VR Performance (2.x)
- **2.1:** 90 FPS minimum → `PerformanceOptimizer`
- **2.2:** Stereoscopic rendering → Godot XR system
- **2.3:** LOD adjustments → `LODManager`
- **2.5:** Performance warnings → `fps_below_target` signal

### Post-Processing (13.x)
- **13.1:** Entropy-based effects → `PostProcessing`
- **13.2:** Pixelation (UV snapping) → Post shader
- **13.3:** Static noise → Random injection
- **13.4:** Chromatic aberration → RGB separation
- **13.5:** Scanlines → Horizontal line effect

### Quantum Rendering (28.x)
- **28.1:** Frustum culling → `VisibleOnScreenNotifier3D`
- **28.2:** Probability clouds → `GPUParticles3D`
- **28.3:** Collapse on observation → State transitions
- **28.4:** Particle systems → Particle materials
- **28.5:** Simplified collision → SphereShape3D

### Shader Management (30.x)
- **30.1:** Vertex displacement shaders → Separated shader files
- **30.2:** Grid rendering shaders → `lattice.gdshader`
- **30.3:** Post-processing shaders → Separate `.gdshader` files
- **30.4:** Hot-reload support → `ShaderManager` file monitoring
- **30.5:** Rendering pipeline order → Composited effects

---

## Related Documentation

### Project-Wide
- **[C:/godot/CLAUDE.md](../../CLAUDE.md)** - Main project documentation
- **[C:/godot/docs/DEVELOPMENT_WORKFLOW.md](../DEVELOPMENT_WORKFLOW.md)** - Development workflow
- **[C:/godot/docs/VR_OPTIMIZATION.md](../VR_OPTIMIZATION.md)** - VR-specific optimizations

### Performance
- **[C:/godot/docs/performance/](../performance/)** - Performance monitoring and tuning

### Architecture
- **[C:/godot/docs/architecture/SYSTEM_INTEGRATION.md](../architecture/SYSTEM_INTEGRATION.md)** - Overall system integration

---

## Source Files

| System | File Path |
|--------|-----------|
| RenderingSystem | `C:/godot/scripts/rendering/rendering_system.gd` |
| LODManager | `C:/godot/scripts/rendering/lod_manager.gd` |
| QuantumRender | `C:/godot/scripts/rendering/quantum_render.gd` |
| ShaderManager | `C:/godot/scripts/rendering/shader_manager.gd` |
| PostProcessing | `C:/godot/scripts/rendering/post_process.gd` |
| PBRMaterialFactory | `C:/godot/scripts/rendering/pbr_material_factory.gd` |
| LatticeRenderer | `C:/godot/scripts/rendering/lattice_renderer.gd` |
| AtmosphereSystem | `C:/godot/scripts/rendering/atmosphere_system.gd` |
| PerformanceOptimizer | `C:/godot/scripts/rendering/performance_optimizer.gd` |

---

## Version History

- **v1.0** (2025-12-03) - Initial rendering documentation suite
  - RENDERING_ARCHITECTURE.md: Overall system architecture
  - LOD_SYSTEM.md: LOD manager deep-dive
  - QUANTUM_RENDERING.md: Quantum rendering technical guide
  - SHADER_SYSTEM.md: Shader management guide

---

## Contributing

When adding new rendering features:

1. **Update Architecture:** Add system to `RENDERING_ARCHITECTURE.md` diagram
2. **Document API:** Create/update dedicated `.md` file with API reference
3. **Add Examples:** Include usage patterns and code samples
4. **Performance Notes:** Document frame budget impact
5. **Integration Guide:** Explain how system connects to others
6. **Troubleshooting:** Add common issues and solutions

---

## Contact

For questions or issues:
- **Project:** SpaceTime VR (Godot 4.5+)
- **Documentation Date:** December 3, 2025
- **Documentation Version:** 1.0
