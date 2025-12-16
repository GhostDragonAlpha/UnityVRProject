# Rendering System Architecture

## Overview

The SpaceTime rendering system is built on Godot 4.5's built-in PBR (Physically Based Rendering) pipeline, optimized for VR at 90 FPS. The architecture consists of 9 interconnected subsystems that handle everything from LOD management to quantum-inspired rendering effects.

## System Components

### Core Rendering Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                    RenderingSystem (Core)                        │
│  - PBR Pipeline Configuration                                    │
│  - Sun/Directional Lighting                                      │
│  - Shadow Volumes (Penumbra/Umbra)                              │
│  - Global Illumination (SDFGI)                                  │
│  - Environment Settings                                          │
└────────────────────┬────────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼────────┐       ┌───────▼────────┐
│  ShaderManager │       │ PBRMaterialFact│
│  - Hot-reload  │       │ - Material Lib  │
│  - Shader Cache│       │ - Presets       │
└───────┬────────┘       └───────┬────────┘
        │                        │
        └────────────┬───────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼────────┐       ┌───────▼────────┐
│  LODManager    │       │ QuantumRender  │
│  - Distance    │       │ - Visibility    │
│  - Visibility  │       │ - Particles     │
└───────┬────────┘       └───────┬────────┘
        │                        │
        └────────────┬───────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼────────┐       ┌───────▼────────┐
│ PostProcessing │       │PerformanceOpt  │
│ - Entropy FX   │       │ - Auto Quality  │
│ - Glitch/Noise │       │ - Profiling     │
└────────────────┘       └────────────────┘
```

### Specialized Rendering

```
┌─────────────────────────────────────────────────────────────────┐
│                     Specialized Renderers                        │
├─────────────────────┬───────────────────┬──────────────────────┤
│  LatticeRenderer    │  AtmosphereSystem │                      │
│  - 3D Grid          │  - Heat Shimmer   │                      │
│  - Gravity Wells    │  - Plasma Effects │                      │
│  - Doppler Shift    │  - Drag Forces    │                      │
└─────────────────────┴───────────────────┴──────────────────────┘
```

## Architecture Principles

### 1. **Initialization Dependencies**

The rendering system follows a strict initialization order managed by `ResonanceEngine`:

**Phase 3 - VR and Rendering:**
1. `VRManager` - OpenXR initialization
2. `VRComfortSystem` - VR comfort features
3. `HapticManager` - Controller feedback
4. **`RenderingSystem`** - Core rendering pipeline

**Phase 4 - Performance Optimization:**
5. **`PerformanceOptimizer`** - Dynamic quality adjustment

### 2. **Subsystem Independence**

Each rendering subsystem can be:
- **Initialized independently** - Useful for testing
- **Hot-reloaded** - ShaderManager enables live shader updates
- **Profiled separately** - PerformanceOptimizer tracks per-system metrics

### 3. **VR-First Design**

All rendering systems target 90 FPS for VR:
- **11.11ms frame budget** enforced by PerformanceOptimizer
- **Automatic quality scaling** when FPS drops below 80
- **Stereoscopic rendering** handled by Godot's XR system

## System Interactions

### Rendering Pipeline Flow

```
Frame Start
    │
    ▼
┌─────────────────────┐
│ PerformanceOptimizer│ ◄─── Profiles frame time
│ Check FPS           │
└──────┬──────────────┘
       │
       ▼ (FPS < 80?)
┌─────────────────────┐
│ Adjust Quality      │ ───► LODManager.set_lod_bias()
│ - Reduce LOD bias   │ ───► Viewport MSAA settings
│ - Disable AA        │ ───► Shader complexity
│ - Simplify physics  │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ LODManager Update   │ ◄─── Distance to camera
│ - Calculate LOD     │ ◄─── Visibility notifiers
│ - Switch meshes     │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ QuantumRender Update│ ◄─── Frustum culling
│ - Check visibility  │ ───► Particle clouds
│ - Collapse/Decohere │ ───► Simplified collision
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Scene Rendering     │
│ - PBR materials     │ ◄─── RenderingSystem environment
│ - Shadows           │ ◄─── Sun light
│ - Lattice overlay   │ ◄─── LatticeRenderer
│ - Atmosphere        │ ◄─── AtmosphereSystem
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Post-Processing     │ ◄─── Entropy level
│ - Glitch effects    │ ◄─── SNR (Signal-to-Noise Ratio)
│ - Chromatic aberr.  │
│ - Scanlines/Pixelat.│
└──────┬──────────────┘
       │
       ▼
    Frame End
```

### Inter-System Communication

**Signals:**
```gdscript
# PerformanceOptimizer → LODManager
fps_below_target.connect(_on_fps_drop)
quality_level_changed.connect(_on_quality_changed)

# LODManager → PerformanceOptimizer
lod_changed.connect(_on_lod_switch)  # Track LOD switches/frame

# QuantumRender → PerformanceOptimizer
object_collapse.connect(_on_quantum_event)  # Track state changes

# RenderingSystem → All
rendering_initialized.connect(_on_rendering_ready)
```

**Direct Method Calls:**
```gdscript
# PerformanceOptimizer controls LODManager
lod_manager.set_lod_bias(0.5)  # Reduce quality
lod_manager.set_update_frequency(30.0)  # Reduce update rate

# RenderingSystem uses ShaderManager
shader_manager.load_shader("lattice", "lattice.gdshader")
material = shader_manager.create_shader_material("lattice")

# PostProcessing reads from player state
post_processing.set_snr(player.get_signal_noise_ratio())
```

## Rendering Requirements Implementation

### Requirement 1.3: Built-in PBR Pipeline

**Implementation:** `RenderingSystem`
- Uses Godot's StandardMaterial3D with PBR parameters
- Configures Environment resource for tonemapping, glow, AO
- No custom rendering backend required

### Requirement 2.1: 90 FPS Minimum

**Implementation:** `PerformanceOptimizer`
- Monitors frame time: `11.11ms budget (1000ms / 90 FPS)`
- Automatic quality reduction when FPS < 80
- Statistics tracking via Performance singleton

### Requirement 2.3: LOD Adjustments

**Implementation:** `LODManager`
- Distance-based LOD switching
- Visibility culling via `VisibleOnScreenNotifier3D`
- LOD bias controls (0.25 - 1.5) for quality scaling

### Requirements 16.1-16.5: Physically Accurate Lighting

**Implementation:** `RenderingSystem`

**16.1 - Inverse Square Law:**
```gdscript
static func calculate_inverse_square_intensity(
    base_intensity: float,
    distance: float,
    reference_distance: float = 1.0
) -> float:
    var ratio := reference_distance / safe_distance
    return base_intensity * ratio * ratio  # I = I₀ * (d₀/d)²
```

**16.2 - Shadow Volumes:**
```gdscript
sun_light.shadow_enabled = true
sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
sun_light.directional_shadow_max_distance = 10000.0
```

**16.3 - Near-Zero Ambient in Shadow:**
```gdscript
environment.ambient_light_energy = 0.1  # Very dark space ambient
environment.ambient_light_color = Color(0.05, 0.05, 0.1)  # Dark blue
```

**16.4 - PBR Materials:**
```gdscript
material.albedo_color = Color(0.7, 0.7, 0.75)  # Base color
material.roughness = 0.3  # 0=mirror, 1=completely rough
material.metallic = 0.9   # 0=dielectric, 1=metal
```

**16.5 - Penumbra/Umbra:**
```gdscript
sun_light.light_angular_distance = 0.5  # Sun's angular size (degrees)
sun_light.directional_shadow_blend_splits = true  # Soft shadow blending
```

### Requirements 13.1-13.5: Entropy-Based Post-Processing

**Implementation:** `PostProcessing`

Progressive effect activation based on entropy level (0.0 = healthy, 1.0 = corrupted):

```
Entropy 0.0 ─────────────────────────► 1.0
        │                              │
        │  0.1: Scanlines start        │
        │  0.2: Chromatic aberration   │
        │  0.3: Static noise           │
        │  0.5: Pixelation             │
        │  0.7: Datamoshing            │
        └──────────────────────────────┘
```

### Requirements 28.1-28.5: Quantum Rendering

**Implementation:** `QuantumRender`

Objects outside the view frustum become "unobserved":
1. **Detection:** `VisibleOnScreenNotifier3D.is_on_screen()`
2. **Unobserved State:** Replace mesh with `GPUParticles3D` probability cloud
3. **Simplified Collision:** Switch from detailed CollisionShape to simple SphereShape
4. **Collapse:** 0.1 second transition back to solid mesh when observed

## Performance Budgets

### Frame Time Budget (11.11ms total)

```
┌─────────────────────────────────────────────┐
│ Physics Processing         │ 3.0 ms  │ 27% │
├────────────────────────────┼─────────┤─────┤
│ Rendering (Draw Calls)     │ 5.0 ms  │ 45% │
├────────────────────────────┼─────────┤─────┤
│ Shader Execution (GPU)     │ 2.0 ms  │ 18% │
├────────────────────────────┼─────────┤─────┤
│ Game Logic (_process)      │ 0.5 ms  │  5% │
├────────────────────────────┼─────────┤─────┤
│ Post-Processing            │ 0.3 ms  │  3% │
├────────────────────────────┼─────────┤─────┤
│ Buffer (safety margin)     │ 0.3 ms  │  2% │
└────────────────────────────┴─────────┴─────┘
```

### Quality Level Settings

| Setting | Ultra | High | Medium | Low | Minimum |
|---------|-------|------|--------|-----|---------|
| MSAA | 4x | 2x | 2x | Off | Off |
| FXAA | On | On | Off | Off | Off |
| TAA | On | On | Off | Off | Off |
| LOD Bias | 1.5 | 1.0 | 0.75 | 0.5 | 0.25 |
| Shader Complexity | 3 | 2 | 1 | 0 | 0 |
| Shadow Splits | 4 | 4 | 2 | 2 | 2 |
| Shadow Distance | 20km | 10km | 5km | 2km | 2km |
| Physics Iterations | 8 | 8 | 6 | 4 | 2 |
| GI (SDFGI) | On | On | Half-res | Off | Off |

## Shader Architecture

### Shader Pipeline Order

Post-processing effects are applied in this order:

```
1. Scene Render
2. Atmosphere Overlay (if in atmosphere)
3. Lattice Grid Overlay (if enabled)
4. Post-Processing Effects:
   a. Pixelation (UV snapping)
   b. Chromatic Aberration (RGB channel separation)
   c. Static Noise (random injection)
   d. Scanlines (horizontal line effect)
   e. Datamoshing (block displacement)
5. Final Output
```

### Shader Hot-Reload

**Implementation:** `ShaderManager`

Enables live shader editing without restarting:
1. Monitor shader files for changes (`FileAccess.get_modified_time()`)
2. Reload shader on modification
3. Update all ShaderMaterial instances
4. Emit `shader_reloaded` signal

**Usage:**
```gdscript
shader_manager.enable_hot_reload()
shader_manager.set_hot_reload_interval(1.0)  # Check every 1 second
```

## Material Library

### PBR Material Presets

**Implementation:** `PBRMaterialFactory`

Pre-configured materials for common use cases:

```gdscript
# Spacecraft hull (metallic, slightly rough)
var hull = material_factory.create_spacecraft_hull_material()
# → albedo: (0.7, 0.7, 0.75), roughness: 0.3, metallic: 0.9

# Spacecraft glass (transparent, smooth, Fresnel)
var glass = material_factory.create_spacecraft_glass_material()
# → transparency: ALPHA, roughness: 0.0, rim_enabled: true

# Rocky planet surface (very rough, non-metallic)
var rock = material_factory.create_rocky_surface_material()
# → roughness: 0.9, metallic: 0.0

# Ice surface (smooth, subsurface scattering)
var ice = material_factory.create_ice_surface_material()
# → roughness: 0.2, subsurf_scatter_enabled: true

# Gas giant atmosphere (completely rough, no specular)
var gas = material_factory.create_gas_giant_material()
# → roughness: 1.0, metallic_specular: 0.0

# Star/sun (emissive, unshaded)
var star = material_factory.create_star_material(Color(1, 0.95, 0.8), 10.0)
# → shading_mode: UNSHADED, emission_energy_multiplier: 10.0

# Lattice grid (emissive, transparent, additive blend)
var lattice = material_factory.create_lattice_material()
# → blend_mode: ADD, transparency: ALPHA

# Engine exhaust (emissive, transparent, additive)
var exhaust = material_factory.create_engine_exhaust_material()
# → blend_mode: ADD, emission_energy_multiplier: 5.0
```

## Occlusion Culling

**Implementation:** `PerformanceOptimizer`

Automatic occluder creation for large meshes:
```gdscript
# Create box occluder from mesh AABB
var occluder = performance_optimizer.create_occluder_for_mesh(mesh_instance)
# → Creates OccluderInstance3D with BoxOccluder3D
```

Occluders prevent rendering of objects behind large opaque geometry.

## Best Practices

### 1. Always Initialize Through ResonanceEngine

```gdscript
# ✅ CORRECT - Managed initialization
var rendering_system = ResonanceEngine.get_subsystem("RenderingSystem")

# ❌ INCORRECT - Direct instantiation
var rendering_system = RenderingSystem.new()
rendering_system.initialize(scene_root)
```

### 2. Use Material Factory for Consistency

```gdscript
# ✅ CORRECT - Cached, consistent materials
var material = material_factory.create_named_material("my_hull")

# ❌ INCORRECT - Manual material creation
var material = StandardMaterial3D.new()
material.albedo_color = Color.WHITE
# ... 20 lines of property setting
```

### 3. Respect Frame Budget

```gdscript
# ✅ CORRECT - Check frame time before expensive operations
if performance_optimizer.get_average_frame_time_ms() < 8.0:
    spawn_particle_effects()

# ❌ INCORRECT - Spawn regardless of performance
spawn_particle_effects()
```

### 4. Use LOD for All Distant Objects

```gdscript
# ✅ CORRECT - Register with LOD manager
lod_manager.register_object("asteroid_001", asteroid_root, lod_levels)

# ❌ INCORRECT - Always render full detail
asteroid.mesh = high_detail_mesh
```

### 5. Enable Hot-Reload in Development

```gdscript
# ✅ CORRECT - Fast iteration
shader_manager.enable_hot_reload()

# ❌ INCORRECT - Restart entire application for shader changes
```

## Debugging and Profiling

### Performance Statistics

```gdscript
# Get comprehensive performance report
var stats = performance_optimizer.get_statistics()
print("FPS: ", stats.fps)
print("Frame Time: ", stats.frame_time_ms, " ms")
print("Objects Rendered: ", stats.objects_rendered)
print("Draw Calls: ", stats.draw_calls)
print("Physics Active: ", stats.physics_3d_active_objects)

# Or get formatted report string
print(performance_optimizer.get_performance_report())
```

### LOD Statistics

```gdscript
var lod_stats = lod_manager.get_statistics()
print("Total Objects: ", lod_stats.total_objects)
print("Visible Objects: ", lod_stats.visible_objects)
print("LOD Distribution: ", lod_stats.lod_distribution)
print("Switches This Frame: ", lod_stats.switches_this_frame)
```

### Quantum Render Statistics

```gdscript
var quantum_stats = quantum_render.get_statistics()
print("Observed Objects: ", quantum_stats.observed_objects)
print("Unobserved Objects: ", quantum_stats.unobserved_objects)
print("Total Collapses: ", quantum_stats.total_collapses)
```

### Post-Processing Debugging

```gdscript
# Disable effects individually for testing
post_processing.set_chromatic_aberration_strength(0.0)
post_processing.set_scanline_strength(0.0)
post_processing.set_pixelation_strength(0.0)
post_processing.set_noise_strength(0.0)

# Or disable entirely
post_processing.set_enabled(false)
```

## Known Issues and Limitations

### 1. SDFGI Disabled for VR Performance

**Issue:** Global Illumination (SDFGI) is disabled by default to maintain 90 FPS in VR.

**Workaround:** Enable for non-VR or high-end systems:
```gdscript
rendering_system.set_gi_enabled(true)
rendering_system.set_gi_mode(RenderingSystem.GIMode.SDFGI)
```

### 2. Shader Hot-Reload Doesn't Update Scene Instances

**Issue:** Hot-reloaded shaders only update cached ShaderMaterial instances.

**Workaround:** Re-apply materials to scene nodes after reload:
```gdscript
shader_manager.shader_reloaded.connect(func(shader_name):
    mesh_instance.material_override = shader_manager.get_material(shader_name)
)
```

### 3. QuantumRender Requires Manual Bounds Setup

**Issue:** `VisibleOnScreenNotifier3D` uses default AABB which may not match mesh size.

**Workaround:** Update bounds after registration:
```gdscript
quantum_render.register_object("obj_id", root, mesh, collision)
quantum_render.set_object_bounds("obj_id", mesh.get_aabb())
```

### 4. LOD Hysteresis Can Cause Flickering

**Issue:** Objects near LOD distance thresholds can rapidly switch levels.

**Workaround:** Reduce update frequency or use custom per-object distances:
```gdscript
lod_manager.set_update_frequency(30.0)  # Update 30 times/second instead of every frame
# OR
lod_manager.set_object_distances("obj_id", [150.0, 600.0, 2500.0])  # Add 50% buffer
```

## Related Documentation

- **[LOD_SYSTEM.md](LOD_SYSTEM.md)** - Detailed LOD manager documentation
- **[QUANTUM_RENDERING.md](QUANTUM_RENDERING.md)** - Quantum render technical guide
- **[SHADER_SYSTEM.md](SHADER_SYSTEM.md)** - Shader management guide
- **[C:/godot/docs/performance/VR_OPTIMIZATION.md](../performance/VR_OPTIMIZATION.md)** - VR-specific optimizations
- **[C:/godot/docs/DEVELOPMENT_WORKFLOW.md](../DEVELOPMENT_WORKFLOW.md)** - Player-experience-driven workflow

## Version History

- **v1.0** (2025-12-03) - Initial comprehensive rendering architecture documentation
