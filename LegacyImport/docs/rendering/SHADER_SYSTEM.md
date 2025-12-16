# Shader Management System

## Overview

The Shader Management system (`ShaderManager`) provides centralized shader loading, caching, hot-reload capabilities, and material management for the SpaceTime project. This system enables rapid shader iteration during development and ensures consistent shader usage across the codebase.

**File:** `C:/godot/scripts/rendering/shader_manager.gd`

**Requirements:** 30.1-30.5

## Core Features

### 1. Shader Loading and Caching

Load `.gdshader` files once, reuse everywhere:

```gdscript
var shader = shader_manager.load_shader("lattice", "lattice.gdshader")
# Cached - subsequent calls return same instance
```

### 2. Hot-Reload

Live shader editing without restarting application:

```gdscript
shader_manager.enable_hot_reload()
# Edit shader file → Auto-reload → Materials update automatically
```

### 3. Material Management

Create and cache ShaderMaterial instances:

```gdscript
var material = shader_manager.create_shader_material("lattice", "my_lattice_mat")
# Cached with name "my_lattice_mat" for reuse
```

### 4. Fallback Handling

Graceful degradation when shaders fail to load:

```gdscript
# If shader file missing, uses fallback (magenta unlit)
var shader = shader_manager.load_shader("missing", "nonexistent.gdshader")
# Returns fallback shader instead of null
```

## API Reference

### Initialization

```gdscript
var shader_manager = ShaderManager.new()
add_child(shader_manager)

# Ready to use immediately (no explicit initialization)
```

**Signals:**
```gdscript
signal shader_loaded(shader_name: String)
signal shader_load_failed(shader_name: String, error: String)
signal shader_reloaded(shader_name: String)
signal shader_parameter_changed(shader_name: String, param_name: String, value: Variant)
```

### Loading Shaders

#### Single Shader

```gdscript
# Load shader by name and path
var shader = shader_manager.load_shader(
    "lattice",                     # Shader name (for caching)
    "res://shaders/lattice.gdshader"  # Path to .gdshader file
)

# Short path (prepends "res://shaders/" automatically)
var shader = shader_manager.load_shader("post_glitch", "post_glitch.gdshader")
```

#### Batch Loading

```gdscript
# Load multiple shaders at once
var shader_definitions = {
    "lattice": "lattice.gdshader",
    "post_glitch": "post_glitch.gdshader",
    "atmosphere": "atmosphere.gdshader",
    "planet_surface": "planet_surface.gdshader"
}

var loaded_count = shader_manager.load_shaders(shader_definitions)
print("Loaded %d shaders" % loaded_count)
```

#### Pipeline Preload

```gdscript
# Load standard rendering pipeline shaders
shader_manager.preload_pipeline_shaders()
# Attempts to load: lattice, post_glitch, post_chromatic, post_scanlines,
#                   planet_surface, atmosphere, volumetric
```

#### From Code

```gdscript
# Create shader programmatically
var shader_code = """
shader_type spatial;
void fragment() {
    ALBEDO = vec3(1.0, 0.0, 0.0);
}
"""

var shader = shader_manager.create_shader_from_code("red_shader", shader_code)
```

### Creating Materials

```gdscript
# Create material from loaded shader
var material = shader_manager.create_shader_material(
    "lattice",          # Shader name (must be loaded first)
    "lattice_mat_01"    # Optional: Material name for caching
)

# Create unnamed material (not cached)
var material = shader_manager.create_shader_material("lattice")
```

### Setting Shader Parameters

#### On Cached Materials

```gdscript
# Set parameter on cached material
shader_manager.set_shader_parameter(
    "lattice_mat_01",  # Material name
    "time",            # Parameter name
    10.5               # Value
)
```

#### On Material Instance

```gdscript
# Set parameter on any ShaderMaterial
shader_manager.set_material_parameter(my_material, "intensity", 0.8)
```

#### Get Parameter

```gdscript
var value = shader_manager.get_shader_parameter("lattice_mat_01", "time")
```

### Hot-Reload

#### Enable/Disable

```gdscript
# Enable hot-reload (check files every 1 second by default)
shader_manager.enable_hot_reload()

# Set custom check interval
shader_manager.set_hot_reload_interval(2.0)  # Check every 2 seconds

# Disable hot-reload
shader_manager.disable_hot_reload()

# Check status
if shader_manager.is_hot_reload_enabled():
    print("Hot-reload active")
```

#### Manual Reload

```gdscript
# Reload specific shader
if shader_manager.reload_shader("lattice"):
    print("Lattice shader reloaded successfully")

# Reload all shaders
var reloaded_count = shader_manager.reload_all_shaders()
print("Reloaded %d shaders" % reloaded_count)
```

### Querying

```gdscript
# Check if shader is loaded
if shader_manager.has_shader("lattice"):
    print("Lattice shader available")

# Check if material exists
if shader_manager.has_material("lattice_mat_01"):
    print("Material cached")

# Get shader reference
var shader = shader_manager.get_shader("lattice")

# Get material reference
var material = shader_manager.get_material("lattice_mat_01")

# Get fallback shader (for testing)
var fallback = shader_manager.get_fallback_shader()

# List loaded shaders
var shader_names = shader_manager.get_loaded_shader_names()
print("Loaded shaders: ", shader_names)

# List cached materials
var material_names = shader_manager.get_cached_material_names()
print("Cached materials: ", material_names)
```

### Validation

```gdscript
# Check if shader is valid (not fallback, has code)
if shader_manager.validate_shader("lattice"):
    print("Lattice shader is valid and usable")

# Get error message if invalid
var error = shader_manager.get_shader_errors("lattice")
if not error.is_empty():
    print("Shader error: ", error)
```

### Cache Management

```gdscript
# Unload specific shader
shader_manager.unload_shader("old_shader")

# Clear all cached shaders and materials
shader_manager.clear_cache()

# Get statistics
var stats = shader_manager.get_stats()
print("Loaded shaders: ", stats.loaded_shaders)
print("Cached materials: ", stats.cached_materials)
print("Hot-reload enabled: ", stats.hot_reload_enabled)
```

### Cleanup

```gdscript
# Shutdown and cleanup
shader_manager.shutdown()
```

## Usage Patterns

### Pattern 1: Loading Shader for MeshInstance

```gdscript
func setup_lattice_renderer():
    # Load shader
    var shader = shader_manager.load_shader("lattice", "lattice.gdshader")

    # Create material
    var material = shader_manager.create_shader_material("lattice", "lattice_main")

    # Set parameters
    shader_manager.set_shader_parameter("lattice_main", "base_color", Vector3(0, 1, 1))
    shader_manager.set_shader_parameter("lattice_main", "glow_intensity", 2.0)

    # Apply to mesh
    mesh_instance.material_override = material
```

### Pattern 2: Hot-Reload Workflow

```gdscript
func _ready():
    # Enable hot-reload in debug builds
    if OS.is_debug_build():
        shader_manager.enable_hot_reload()
        shader_manager.set_hot_reload_interval(1.0)

        # Connect to reload signal
        shader_manager.shader_reloaded.connect(_on_shader_reloaded)

func _on_shader_reloaded(shader_name: String):
    print("Shader '%s' was reloaded" % shader_name)
    # Re-apply materials if needed
    if shader_name == "lattice":
        _update_lattice_materials()
```

### Pattern 3: Post-Processing Pipeline

```gdscript
# Requirements 30.3, 30.5: Separate post-processing effects in defined order
func setup_post_processing_pipeline():
    # Load all post-processing shaders
    var post_shaders = {
        "post_pixelation": "post_pixelation.gdshader",
        "post_chromatic": "post_chromatic.gdshader",
        "post_noise": "post_noise.gdshader",
        "post_scanlines": "post_scanlines.gdshader",
        "post_datamosh": "post_datamosh.gdshader"
    }

    shader_manager.load_shaders(post_shaders)

    # Create materials in pipeline order
    var pipeline_order = [
        "post_pixelation",   # 1. UV snapping
        "post_chromatic",    # 2. RGB separation
        "post_noise",        # 3. Static injection
        "post_scanlines",    # 4. Horizontal lines
        "post_datamosh"      # 5. Block displacement
    ]

    for i in range(pipeline_order.size()):
        var shader_name = pipeline_order[i]
        var material_name = "post_stage_%d" % i
        shader_manager.create_shader_material(shader_name, material_name)
```

### Pattern 4: Material Variants

```gdscript
# Create multiple material variants from same shader
func create_planet_materials():
    # Load planet shader once
    shader_manager.load_shader("planet", "planet_surface.gdshader")

    # Create variants for different planet types
    var variants = ["rocky", "icy", "volcanic", "gas_giant"]

    for variant in variants:
        var mat_name = "planet_%s" % variant
        var material = shader_manager.create_shader_material("planet", mat_name)

        # Set variant-specific parameters
        match variant:
            "rocky":
                shader_manager.set_shader_parameter(mat_name, "base_color", Vector3(0.4, 0.35, 0.3))
                shader_manager.set_shader_parameter(mat_name, "roughness", 0.9)
            "icy":
                shader_manager.set_shader_parameter(mat_name, "base_color", Vector3(0.8, 0.9, 1.0))
                shader_manager.set_shader_parameter(mat_name, "roughness", 0.2)
            # ... etc
```

### Pattern 5: Shader Parameter Animation

```gdscript
var _time: float = 0.0

func _process(delta: float):
    _time += delta

    # Animate shader parameters
    shader_manager.set_shader_parameter("lattice_main", "time", _time)
    shader_manager.set_shader_parameter("lattice_main", "pulse_phase", sin(_time * TAU))

    # Update post-processing based on game state
    var entropy = player.get_entropy_level()
    shader_manager.set_shader_parameter("post_stage_0", "entropy", entropy)
```

### Pattern 6: Conditional Shader Loading

```gdscript
# Only load shaders if files exist (avoid spam during development)
func safe_load_shader(name: String, path: String):
    var full_path = "res://shaders/" + path
    if FileAccess.file_exists(full_path):
        shader_manager.load_shader(name, path)
        return true
    else:
        print("Shader not found: ", full_path, " (will be created later)")
        return false
```

### Pattern 7: Performance-Based Shader Switching

```gdscript
# Switch shader complexity based on performance
performance_optimizer.quality_level_changed.connect(func(old_level, new_level):
    match new_level:
        PerformanceOptimizer.QualityLevel.ULTRA:
            shader_manager.load_shader("planet", "planet_surface_ultra.gdshader")
        PerformanceOptimizer.QualityLevel.HIGH:
            shader_manager.load_shader("planet", "planet_surface_high.gdshader")
        PerformanceOptimizer.QualityLevel.LOW:
            shader_manager.load_shader("planet", "planet_surface_simple.gdshader")

    # Reload materials with new shader
    shader_manager.reload_shader("planet")
)
```

## Shader File Structure

### Recommended Directory Layout

```
res://shaders/
├── core/
│   ├── lattice.gdshader          # 3D grid rendering
│   ├── atmosphere.gdshader        # Atmospheric scattering
│   └── volumetric.gdshader        # Volumetric effects
├── post_processing/
│   ├── post_glitch.gdshader       # All-in-one glitch shader
│   ├── post_pixelation.gdshader   # UV snapping
│   ├── post_chromatic.gdshader    # Chromatic aberration
│   ├── post_noise.gdshader        # Static noise
│   ├── post_scanlines.gdshader    # Scanlines
│   └── post_datamosh.gdshader     # Block displacement
├── surfaces/
│   ├── planet_surface.gdshader    # Generic planet shader
│   ├── rocky_surface.gdshader     # Rocky terrain
│   ├── ice_surface.gdshader       # Ice with subsurface scattering
│   └── gas_surface.gdshader       # Gas giant shader
└── effects/
    ├── engine_exhaust.gdshader    # Thrust particles
    ├── warp_distortion.gdshader   # FTL effects
    └── quantum_cloud.gdshader     # Probability cloud particles
```

### Shader Naming Convention

```gdscript
# Pattern: <category>_<purpose>_<variant>.gdshader

# Core rendering
"lattice.gdshader"           # Main lattice grid
"atmosphere.gdshader"        # Atmospheric effects

# Post-processing (prefix: post_)
"post_glitch.gdshader"       # Combined glitch effects
"post_chromatic.gdshader"    # Chromatic aberration only

# Surfaces (suffix: _surface)
"planet_surface.gdshader"    # Generic planet
"rocky_surface.gdshader"     # Rocky variant
"ice_surface.gdshader"       # Ice variant

# Effects
"engine_exhaust.gdshader"    # Thrust effect
"warp_distortion.gdshader"   # FTL effect
```

## Hot-Reload Technical Details

### How It Works

1. **File Modification Tracking:**
   ```gdscript
   # Store modification times
   _file_mod_times[shader_name] = FileAccess.get_modified_time(path)
   ```

2. **Periodic Checking:**
   ```gdscript
   # Every N seconds (default 1.0)
   func _process(delta):
       if _hot_reload_enabled:
           _time_since_check += delta
           if _time_since_check >= _hot_reload_interval:
               _check_for_shader_changes()
   ```

3. **Change Detection:**
   ```gdscript
   # Compare current vs stored mod time
   var current_mod_time = FileAccess.get_modified_time(path)
   if current_mod_time > stored_mod_time:
       reload_shader(shader_name)
   ```

4. **Material Update:**
   ```gdscript
   # Update all materials using reloaded shader
   func _update_materials_with_shader(shader_name, new_shader):
       for material in _material_cache.values():
           if material.shader == old_shader:
               material.shader = new_shader
   ```

### Limitations

- **Scene instance materials** not automatically updated
- **Resource files** (.tres materials) not tracked
- **Includes/imports** not detected (shader must be top-level file)

### Workarounds

For scene materials:
```gdscript
shader_manager.shader_reloaded.connect(func(shader_name):
    # Manually update scene materials
    for node in get_tree().get_nodes_in_group("uses_lattice_shader"):
        if node is MeshInstance3D:
            node.material_override = shader_manager.get_material("lattice_main")
)
```

## Fallback Shader

When shader loading fails, the fallback shader is used:

```glsl
shader_type spatial;
render_mode unshaded;

void fragment() {
    ALBEDO = vec3(1.0, 0.0, 1.0);  // Magenta for visibility
}
```

**Purpose:** Makes shader errors obvious (bright magenta) without breaking rendering.

## Performance Considerations

### Memory Usage

```
Per shader:
- Shader resource: ~10-50 KB (depends on code complexity)
- ShaderMaterial: ~5 KB

1000 materials using same shader:
- 1 shader: 30 KB
- 1000 materials: 5 MB
Total: ~5 MB (shader shared)
```

### Hot-Reload Cost

- **Check interval:** 1.0s default (configurable)
- **Check cost:** ~0.1ms per shader (file stat only)
- **Reload cost:** ~10-50ms (recompile + update materials)

**Recommendation:** Disable hot-reload in production builds.

### Shader Compilation

Shaders are compiled by GPU driver:
- **First use:** 10-100ms (compilation)
- **Subsequent uses:** <1ms (cached)

**Best practice:** Preload shaders at startup to avoid hitches.

## Integration with Other Systems

### With RenderingSystem

```gdscript
# RenderingSystem loads shaders via ShaderManager
rendering_system.initialize(scene_root)
shader_manager = rendering_system.shader_manager  # Access via rendering system
```

### With LatticeRenderer

```gdscript
# LatticeRenderer uses ShaderManager for shader loading
lattice_renderer.initialize(shader_manager)
# Lattice automatically loads "lattice.gdshader" via ShaderManager
```

### With PostProcessing

```gdscript
# PostProcessing system uses inline shaders or ShaderManager
post_processing.initialize(canvas_layer)
# Can optionally use ShaderManager for shader loading
```

### With PerformanceOptimizer

```gdscript
# Shader complexity hints for quality levels
var complexity = performance_optimizer.get_shader_complexity()
# 0 = minimal, 1 = low, 2 = medium, 3 = high

# Use to select appropriate shader variant
if complexity <= 1:
    shader_manager.load_shader("planet", "planet_simple.gdshader")
else:
    shader_manager.load_shader("planet", "planet_detailed.gdshader")
```

## Debugging and Profiling

### Shader Validation

```gdscript
# Validate all loaded shaders
for shader_name in shader_manager.get_loaded_shader_names():
    if not shader_manager.validate_shader(shader_name):
        var error = shader_manager.get_shader_errors(shader_name)
        print("Shader '%s' invalid: %s" % [shader_name, error])
```

### Statistics

```gdscript
# Get comprehensive stats
var stats = shader_manager.get_stats()
print("=== Shader Manager Stats ===")
print("Loaded shaders: ", stats.loaded_shaders)
print("Cached materials: ", stats.cached_materials)
print("Hot-reload enabled: ", stats.hot_reload_enabled)
print("Shader names: ", stats.shader_names)
print("Material names: ", stats.material_names)
```

### Signal Monitoring

```gdscript
# Monitor all shader events
shader_manager.shader_loaded.connect(func(name):
    print("[ShaderManager] Loaded: ", name)
)

shader_manager.shader_load_failed.connect(func(name, error):
    push_error("[ShaderManager] Failed to load '%s': %s" % [name, error])
)

shader_manager.shader_reloaded.connect(func(name):
    print("[ShaderManager] Reloaded: ", name)
)

shader_manager.shader_parameter_changed.connect(func(material_name, param_name, value):
    print("[ShaderManager] Set %s.%s = %s" % [material_name, param_name, value])
)
```

## Common Issues and Solutions

### Issue: Shader not loading

**Symptom:** `load_shader()` returns fallback (magenta) shader

**Diagnosis:**
```gdscript
var error = shader_manager.get_shader_errors("my_shader")
print(error)  # "Shader not found" or "Using fallback shader"
```

**Solutions:**
1. Check file path: `res://shaders/my_shader.gdshader`
2. Verify file exists: `FileAccess.file_exists("res://shaders/my_shader.gdshader")`
3. Check for syntax errors in shader code

### Issue: Hot-reload not working

**Symptom:** Edit shader file, no reload happens

**Diagnosis:**
```gdscript
print("Hot-reload enabled: ", shader_manager.is_hot_reload_enabled())
print("Update interval: ", shader_manager._hot_reload_interval)
```

**Solutions:**
1. Ensure hot-reload is enabled: `shader_manager.enable_hot_reload()`
2. Reduce check interval: `shader_manager.set_hot_reload_interval(0.5)`
3. Save file (ensure modification time changes)
4. Manually reload: `shader_manager.reload_shader("my_shader")`

### Issue: Material parameters not updating

**Symptom:** `set_shader_parameter()` has no visual effect

**Diagnosis:**
```gdscript
# Check if material exists
if not shader_manager.has_material("my_material"):
    print("Material not cached")

# Check parameter value
var value = shader_manager.get_shader_parameter("my_material", "intensity")
print("Current value: ", value)

# Check shader uniform name
# (Must match shader code: uniform float intensity;)
```

**Solutions:**
1. Verify material is cached: Use `create_shader_material()` with name
2. Check shader uniform name matches exactly
3. Ensure shader has the uniform: `uniform float intensity = 0.0;`
4. Use `set_material_parameter()` for direct material access

### Issue: Multiple materials not updating after reload

**Symptom:** Some materials update, others don't

**Cause:** Materials not tracked by ShaderManager (created directly)

**Solution:** Always create materials via ShaderManager:
```gdscript
# ✅ CORRECT - Tracked by ShaderManager
var material = shader_manager.create_shader_material("lattice", "mat_01")

# ❌ INCORRECT - Not tracked
var material = ShaderMaterial.new()
material.shader = shader_manager.get_shader("lattice")
```

## Best Practices

### 1. Preload Shaders at Startup

```gdscript
func _ready():
    # Load all shaders before gameplay
    shader_manager.preload_pipeline_shaders()
    # Avoid mid-game compilation hitches
```

### 2. Use Named Materials for Reuse

```gdscript
# ✅ CORRECT - Named and cached
var material = shader_manager.create_shader_material("lattice", "lattice_main")

# ❌ SUBOPTIMAL - Unnamed, not cached
var material = shader_manager.create_shader_material("lattice")
```

### 3. Enable Hot-Reload Only in Debug

```gdscript
if OS.is_debug_build():
    shader_manager.enable_hot_reload()
```

### 4. Validate Shaders After Loading

```gdscript
shader_manager.load_shader("my_shader", "my_shader.gdshader")
if not shader_manager.validate_shader("my_shader"):
    push_error("Shader failed to load properly")
```

### 5. Centralize Shader Parameter Updates

```gdscript
# Single source of truth for shader parameters
func update_all_shaders(time: float, entropy: float):
    # Update lattice shader
    shader_manager.set_shader_parameter("lattice_main", "time", time)

    # Update post-processing
    shader_manager.set_shader_parameter("post_stage_0", "entropy", entropy)
    shader_manager.set_shader_parameter("post_stage_1", "time", time)
```

### 6. Use Descriptive Shader Names

```gdscript
# ✅ CORRECT - Clear purpose
shader_manager.load_shader("planet_rocky_terrain", "rocky_surface.gdshader")

# ❌ UNCLEAR - What does this shader do?
shader_manager.load_shader("shader1", "s1.gdshader")
```

## Related Documentation

- **[RENDERING_ARCHITECTURE.md](RENDERING_ARCHITECTURE.md)** - Overall rendering system
- **[LOD_SYSTEM.md](LOD_SYSTEM.md)** - LOD management
- **[QUANTUM_RENDERING.md](QUANTUM_RENDERING.md)** - Quantum particle shaders
- **Godot Shading Language:** https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/index.html

## Version History

- **v1.0** (2025-12-03) - Initial shader system documentation
