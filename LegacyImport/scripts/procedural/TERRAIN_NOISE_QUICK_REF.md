# TerrainNoiseGenerator Quick Reference

## Basic Setup

```gdscript
var noise_gen = TerrainNoiseGenerator.new()
add_child(noise_gen)
noise_gen.set_seed(42)
```

## Common Usage Patterns

### 1. Get Height at Position
```gdscript
# Basic height
var h = noise_gen.get_height(x, z)

# With biome variation
var h = noise_gen.get_height(x, z, "volcanic")

# Normalized (0-1)
var h_norm = noise_gen.get_normalized_height(x, z)
```

### 2. Generate Heightmap
```gdscript
# Standard heightmap
var heightmap = noise_gen.generate_heightmap(256, 256)

# With offset and biome
var heightmap = noise_gen.generate_heightmap(256, 256, 1000.0, 500.0, "desert")

# With custom scale
var heightmap = noise_gen.generate_heightmap_scaled(256, 256, 2.0)
```

### 3. Apply Presets
```gdscript
# Quick terrain types
noise_gen.apply_preset(TerrainNoiseGenerator.NoisePreset.SMOOTH_HILLS)
noise_gen.apply_preset(TerrainNoiseGenerator.NoisePreset.ROUGH_MOUNTAINS)
noise_gen.apply_preset(TerrainNoiseGenerator.NoisePreset.CANYON_RIDGES)
```

### 4. Manual Configuration
```gdscript
# Set individual parameters
noise_gen.base_frequency = 0.006
noise_gen.octaves = 6
noise_gen.amplitude = 100.0
noise_gen.enable_erosion = true

# Bulk configuration
noise_gen.configure({
    "base_frequency": 0.006,
    "octaves": 6,
    "amplitude": 100.0
})
```

### 5. Adjust Layer Weights
```gdscript
# Increase detail influence
noise_gen.set_layer_weight(TerrainNoiseGenerator.NoiseLayer.DETAIL, 0.5)

# Reduce feature influence
noise_gen.set_layer_weight(TerrainNoiseGenerator.NoiseLayer.FEATURES, 0.2)

# Enable caves with strong carving
noise_gen.enable_caves = true
noise_gen.set_layer_weight(TerrainNoiseGenerator.NoiseLayer.CAVES, -0.7)
```

## Available Biomes
- "ice"
- "desert"
- "forest"
- "ocean"
- "volcanic"
- "barren"
- "toxic"

## Noise Layers
- `NoiseLayer.BASE` - Primary terrain (weight: 1.0)
- `NoiseLayer.DETAIL` - Fine details (weight: 0.3)
- `NoiseLayer.FEATURES` - Specific features (weight: 0.4)
- `NoiseLayer.EROSION` - Weathering (weight: 0.2)
- `NoiseLayer.CAVES` - Underground (weight: -0.5)

## Parameter Ranges
- `base_frequency`: 0.0001 - 1.0 (default: 0.005)
- `detail_frequency`: 0.001 - 1.0 (default: 0.02)
- `feature_frequency`: 0.001 - 1.0 (default: 0.01)
- `octaves`: 1 - 10 (default: 4)
- `amplitude`: >0.1 (default: 50.0)

## Utility Methods
```gdscript
# Get current config
var config = noise_gen.get_configuration()

# Validate determinism
var is_deterministic = noise_gen.validate_determinism(100)

# Get region statistics
var stats = noise_gen.get_region_statistics(256, 256)
print(stats.min_height, stats.max_height, stats.mean_height)
```

## Performance Tips
1. Cache enabled by default (1000 entries)
2. Increase cache for repeated queries: `noise_gen.set_cache_size(5000)`
3. Use normalized heights for blend calculations
4. Disable unused layers: `noise_gen.enable_erosion = false`
5. Lower octaves for distant terrain
