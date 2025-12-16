# Texture Assets Guide

## Overview

This directory contains high-resolution 4K PBR (Physically Based Rendering) texture sets for Project Resonance. All textures are optimized for VR rendering at 90 FPS while maintaining photorealistic quality on RTX 4090 hardware.

## Directory Structure

```
data/textures/
├── spacecraft/          # Spacecraft hull and cockpit textures
│   ├── hull/           # Exterior hull materials
│   ├── cockpit/        # Interior cockpit materials
│   └── glass/          # Canopy and window materials
├── planets/            # Planetary surface textures
│   ├── terrestrial/    # Rocky planet surfaces
│   ├── ice/            # Ice world surfaces
│   ├── desert/         # Desert planet surfaces
│   ├── volcanic/       # Volcanic surfaces
│   ├── ocean/          # Ocean world surfaces
│   └── gas_giant/      # Gas giant atmospheres
├── space/              # Space environment textures
│   ├── nebulae/        # Nebula volumetric textures
│   ├── stars/          # Star field backgrounds
│   └── lattice/        # Lattice grid textures
├── ui/                 # UI and HUD textures
│   ├── icons/          # Interface icons
│   └── displays/       # Cockpit display textures
└── effects/            # Visual effect textures
    ├── particles/      # Particle system textures
    └── post/           # Post-processing textures
```

## PBR Texture Sets

Each material uses a complete PBR texture set with the following maps:

### Standard PBR Maps

1. **Albedo (Base Color)** - `*_albedo.png`

   - Resolution: 4096x4096
   - Format: PNG, sRGB color space
   - Channels: RGB (no alpha unless transparency needed)
   - Content: Surface color without lighting information

2. **Normal Map** - `*_normal.png`

   - Resolution: 4096x4096
   - Format: PNG, Linear color space
   - Channels: RGB (OpenGL format: +Y up)
   - Content: Surface detail and micro-geometry

3. **Roughness Map** - `*_roughness.png`

   - Resolution: 4096x4096
   - Format: PNG, Linear color space
   - Channels: Grayscale (R channel used)
   - Content: Surface smoothness (0=smooth, 1=rough)

4. **Metallic Map** - `*_metallic.png`

   - Resolution: 4096x4096
   - Format: PNG, Linear color space
   - Channels: Grayscale (R channel used)
   - Content: Metallic vs dielectric (0=dielectric, 1=metal)

5. **Ambient Occlusion (AO)** - `*_ao.png`

   - Resolution: 4096x4096
   - Format: PNG, Linear color space
   - Channels: Grayscale
   - Content: Cavity and crevice darkening

6. **Displacement/Height Map** - `*_height.png`
   - Resolution: 4096x4096
   - Format: PNG, Linear color space
   - Channels: Grayscale (16-bit preferred)
   - Content: Surface height information for parallax/tessellation

### Optional Maps

7. **Emission Map** - `*_emission.png`

   - For glowing surfaces (displays, engines, etc.)
   - Format: PNG, sRGB color space
   - Channels: RGB

8. **Opacity Map** - `*_opacity.png`
   - For transparent materials (glass, etc.)
   - Format: PNG, Linear color space
   - Channels: Grayscale

## Texture Naming Convention

Format: `<category>_<material>_<map_type>.png`

Examples:

- `spacecraft_hull_albedo.png`
- `spacecraft_hull_normal.png`
- `spacecraft_hull_roughness.png`
- `planet_ice_albedo.png`
- `nebula_blue_volumetric.png`

## Godot Import Settings

### For Albedo/Emission (sRGB)

```
Import Mode: Texture
Compress Mode: VRAM Compressed
Mipmaps: Enabled
Filter: Linear
Anisotropic: 16x
sRGB: Enabled
```

### For Normal/Roughness/Metallic/AO (Linear)

```
Import Mode: Texture
Compress Mode: VRAM Compressed
Mipmaps: Enabled
Filter: Linear
Anisotropic: 16x
sRGB: Disabled
Normal Map: Enabled (for normal maps only)
```

### For Height/Displacement

```
Import Mode: Texture
Compress Mode: VRAM Compressed
Mipmaps: Enabled
Filter: Linear
Anisotropic: 16x
sRGB: Disabled
```

## Memory Budget

Total texture memory budget: 8 GB (out of 24 GB VRAM)

### Allocation

- Spacecraft textures: 500 MB
- Planetary surfaces: 4 GB (streaming)
- Space environment: 2 GB
- UI and effects: 500 MB
- Reserve: 1 GB

### Optimization Techniques

1. **Texture Streaming**: Load/unload textures based on distance
2. **Mipmap Generation**: Automatic LOD for distant objects
3. **Compression**: Use VRAM compression (BC7 for color, BC5 for normals)
4. **Texture Atlases**: Combine small textures to reduce draw calls
5. **Virtual Texturing**: For large planetary surfaces (future)

## Texture Sources

### Recommended Sources

1. **Procedural Generation**

   - Substance Designer
   - Quixel Mixer
   - Material Maker (open source)

2. **Photo Sources**

   - NASA Image Library (public domain)
   - ESA/Hubble (CC BY 4.0)
   - USGS Earth Explorer (public domain)
   - Textures.com (commercial)
   - Poly Haven (CC0)

3. **AI Generation**
   - Stable Diffusion (texture synthesis)
   - DALL-E (concept textures)
   - Midjourney (reference images)

### Licensing Requirements

- All textures must be:

  - Public domain, OR
  - CC0 (Creative Commons Zero), OR
  - CC BY (with attribution), OR
  - Commercially licensed, OR
  - Created in-house

- Attribution file: `data/textures/ATTRIBUTIONS.md`

## Spacecraft Textures

### Hull Material

**Purpose**: Exterior spacecraft hull
**Style**: Metallic, worn, space-weathered

**Texture Set**:

- `spacecraft_hull_albedo.png` - Dark gray-blue base (0.2, 0.22, 0.25)
- `spacecraft_hull_normal.png` - Panel lines, rivets, surface detail
- `spacecraft_hull_roughness.png` - Smooth metal (0.3) with wear variation
- `spacecraft_hull_metallic.png` - Fully metallic (0.9)
- `spacecraft_hull_ao.png` - Panel gaps and crevices
- `spacecraft_hull_height.png` - Panel depth, rivet height

**Details**:

- Panel lines: 2-5cm wide
- Rivets: 1cm diameter, 10cm spacing
- Wear patterns: Scratches, scuffs, micro-dents
- Weathering: Space dust impacts, thermal stress

### Glass Material

**Purpose**: Cockpit canopy and windows
**Style**: Transparent, slightly tinted, reflective

**Texture Set**:

- `spacecraft_glass_albedo.png` - Tinted blue-green (0.3, 0.5, 0.6, 0.2)
- `spacecraft_glass_normal.png` - Subtle surface imperfections
- `spacecraft_glass_roughness.png` - Very smooth (0.02) with slight variation
- `spacecraft_glass_opacity.png` - 80% transparent

**Details**:

- Subtle scratches and smudges
- Edge tinting (thicker glass = more tint)
- Fresnel reflections (handled by shader)

### Cockpit Interior

**Purpose**: Dashboard, panels, controls
**Style**: Functional, high-tech, worn from use

**Texture Set**:

- `cockpit_dashboard_albedo.png` - Dark gray (0.15, 0.15, 0.18)
- `cockpit_dashboard_normal.png` - Button details, panel lines
- `cockpit_dashboard_roughness.png` - Smooth metal (0.25) with wear
- `cockpit_dashboard_metallic.png` - Highly metallic (0.85)
- `cockpit_dashboard_emission.png` - Button backlighting, display glow

**Details**:

- Button labels and markings
- Wear patterns on frequently-touched areas
- Panel seams and fasteners
- Display bezels

## Planetary Textures

### Terrestrial (Rocky) Planets

**Purpose**: Earth-like rocky surfaces
**Style**: Varied terrain with rocks, dirt, craters

**Texture Set**:

- `planet_terrestrial_albedo.png` - Browns, grays, reds
- `planet_terrestrial_normal.png` - Rock detail, crater rims
- `planet_terrestrial_roughness.png` - Varied (0.6-0.9)
- `planet_terrestrial_height.png` - Terrain elevation

**Variations**:

- `planet_terrestrial_01` - Desert-like
- `planet_terrestrial_02` - Rocky highlands
- `planet_terrestrial_03` - Dusty plains
- `planet_terrestrial_04` - Crater-heavy

### Ice Worlds

**Purpose**: Frozen planet surfaces
**Style**: Ice, snow, frozen terrain

**Texture Set**:

- `planet_ice_albedo.png` - White, light blue tints
- `planet_ice_normal.png` - Ice crystal detail, cracks
- `planet_ice_roughness.png` - Smooth ice (0.1) to rough snow (0.8)
- `planet_ice_height.png` - Ice formations, crevasses

**Details**:

- Ice cracks and fractures
- Snow accumulation
- Frozen water features
- Subsurface scattering (shader-based)

### Desert Worlds

**Purpose**: Arid, sandy planets
**Style**: Sand dunes, rock formations

**Texture Set**:

- `planet_desert_albedo.png` - Yellows, oranges, tans
- `planet_desert_normal.png` - Sand ripples, rock texture
- `planet_desert_roughness.png` - Fine sand (0.7)
- `planet_desert_height.png` - Dune shapes

**Details**:

- Wind-blown sand patterns
- Rock outcroppings
- Dust accumulation
- Heat shimmer (shader-based)

### Volcanic Worlds

**Purpose**: Active volcanic surfaces
**Style**: Lava, cooled rock, ash

**Texture Set**:

- `planet_volcanic_albedo.png` - Dark grays, blacks, glowing orange
- `planet_volcanic_normal.png` - Rough lava texture
- `planet_volcanic_roughness.png` - Very rough (0.9)
- `planet_volcanic_emission.png` - Glowing lava cracks
- `planet_volcanic_height.png` - Lava flows, volcanic features

**Details**:

- Cooled lava flows
- Glowing lava cracks
- Ash deposits
- Volcanic rock texture

### Ocean Worlds

**Purpose**: Water-covered planets
**Style**: Water surface, underwater terrain

**Texture Set**:

- `planet_ocean_albedo.png` - Blues, greens
- `planet_ocean_normal.png` - Wave patterns
- `planet_ocean_roughness.png` - Smooth water (0.1)
- `planet_ocean_height.png` - Wave displacement

**Details**:

- Wave patterns (animated via shader)
- Foam and whitecaps
- Underwater visibility
- Caustics (shader-based)

### Gas Giants

**Purpose**: Atmospheric bands and storms
**Style**: Swirling clouds, atmospheric features

**Texture Set**:

- `planet_gas_albedo.png` - Varied colors (Jupiter-like, Saturn-like)
- `planet_gas_normal.png` - Cloud detail
- `planet_gas_emission.png` - Lightning in storms

**Details**:

- Atmospheric bands
- Storm systems (Great Red Spot style)
- Cloud layers
- Animated via shader

## Space Environment Textures

### Nebulae

**Purpose**: Volumetric space clouds
**Style**: Colorful, wispy, ethereal

**Texture Set**:

- `nebula_blue_volumetric.png` - Blue emission nebula
- `nebula_red_volumetric.png` - Red emission nebula
- `nebula_purple_volumetric.png` - Purple reflection nebula
- `nebula_green_volumetric.png` - Green planetary nebula

**Format**:

- 3D volumetric textures (512x512x512)
- RGBA format (color + density)
- Used with ray-marching shader

### Star Fields

**Purpose**: Background stars
**Style**: Realistic star distribution

**Texture Set**:

- `starfield_milkyway.png` - Milky Way galactic plane
- `starfield_dense.png` - Dense star regions
- `starfield_sparse.png` - Sparse star regions

**Format**:

- Cubemap format (6 faces, 4096x4096 each)
- Point stars with accurate colors
- Based on Hipparcos/Gaia catalog

### Lattice Grid

**Purpose**: Spacetime lattice visualization
**Style**: Glowing grid lines

**Texture Set**:

- `lattice_grid.png` - Grid line pattern
- `lattice_glow.png` - Glow gradient

**Format**:

- Tileable textures
- Used with custom lattice shader
- Animated via shader parameters

## UI Textures

### Icons

**Purpose**: Interface icons and symbols
**Style**: Clean, high-contrast, VR-readable

**Texture Set**:

- `icon_velocity.png` - Velocity indicator
- `icon_gravity.png` - Gravity well indicator
- `icon_signal.png` - Signal strength indicator
- `icon_warning.png` - Warning symbol
- `icon_objective.png` - Objective marker

**Format**:

- 512x512 per icon
- Alpha channel for transparency
- High contrast for VR readability

### Display Textures

**Purpose**: Cockpit display backgrounds
**Style**: High-tech, readable

**Texture Set**:

- `display_background.png` - Display panel background
- `display_grid.png` - Grid overlay
- `display_scanlines.png` - Scanline effect

**Format**:

- 1024x1024
- Tileable where appropriate
- Used with SubViewport rendering

## Effect Textures

### Particles

**Purpose**: Particle system textures
**Style**: Varied based on effect type

**Texture Set**:

- `particle_smoke.png` - Smoke/exhaust
- `particle_spark.png` - Sparks and debris
- `particle_glow.png` - Glowing particles
- `particle_dust.png` - Space dust

**Format**:

- 256x256 or 512x512
- Alpha channel for shape
- Grayscale or colored

### Post-Processing

**Purpose**: Screen-space effects
**Style**: Subtle, enhancing

**Texture Set**:

- `noise_grain.png` - Film grain
- `noise_static.png` - Static/glitch effect
- `lens_dirt.png` - Lens dirt/smudges
- `vignette.png` - Vignette gradient

**Format**:

- 1024x1024 or 2048x2048
- Tileable where appropriate
- Used in post-processing shaders

## Texture Creation Workflow

### 1. Concept and Reference

- Gather reference images
- Define material properties
- Sketch texture layout

### 2. Base Creation

- Create base albedo in Substance Designer or Photoshop
- Establish color palette
- Define major features

### 3. Detail Pass

- Add surface detail (scratches, wear, etc.)
- Create variation and interest
- Ensure tileable if needed

### 4. PBR Maps

- Generate normal map from height
- Create roughness map
- Create metallic map
- Generate AO map

### 5. Testing

- Import into Godot
- Test with proper lighting
- Verify in VR
- Adjust as needed

### 6. Optimization

- Compress textures
- Generate mipmaps
- Test performance
- Adjust resolution if needed

## Performance Considerations

### Texture Compression

- Use VRAM compression for all textures
- BC7 for color textures (albedo, emission)
- BC5 for normal maps
- BC4 for single-channel (roughness, metallic, AO)

### Mipmap Generation

- Always generate mipmaps
- Use high-quality mipmap filtering
- Test mipmap transitions

### Streaming

- Implement texture streaming for planetary surfaces
- Load high-res textures only when needed
- Unload distant textures

### Batching

- Use texture atlases for small textures
- Combine UI icons into single atlas
- Reduce draw calls

## Quality Levels

### Ultra (Default for RTX 4090)

- 4K textures (4096x4096)
- Full PBR workflow
- All maps enabled
- 16x anisotropic filtering

### High

- 2K textures (2048x2048)
- Full PBR workflow
- All maps enabled
- 8x anisotropic filtering

### Medium

- 1K textures (1024x1024)
- Simplified PBR (combined roughness/metallic)
- AO baked into albedo
- 4x anisotropic filtering

### Low

- 512x512 textures
- Albedo and normal only
- 2x anisotropic filtering

## Validation Checklist

For each texture set, verify:

- [ ] All required maps present (albedo, normal, roughness, metallic)
- [ ] Correct resolution (4096x4096 for Ultra)
- [ ] Correct format (PNG)
- [ ] Correct color space (sRGB for albedo, Linear for others)
- [ ] Proper naming convention
- [ ] Tileable if required
- [ ] No visible seams
- [ ] Appropriate level of detail
- [ ] Optimized file size
- [ ] Godot import settings configured
- [ ] Tested in-engine
- [ ] Tested in VR
- [ ] Performance acceptable (90 FPS)
- [ ] Attribution documented (if applicable)

## Requirements Validation

### ✅ Requirement 61.4: High-Resolution Textures

- 4K textures (4096x4096) for all materials
- Full PBR workflow with all maps

### ✅ Requirement 62.1: Tessellation Support

- High-resolution displacement maps
- Height maps for terrain detail

### ✅ Requirement 62.2: Displacement Maps

- 4K height maps for realistic features
- 16-bit depth for precision

### ✅ Requirement 62.3: Physically Accurate Shaders

- Complete PBR texture sets
- Proper metallic/roughness values

### ✅ Requirement 62.4: Ambient Occlusion

- AO maps for all materials
- Contact shadows in crevices

### ✅ Requirement 63.1: Volumetric Nebulae

- 3D volumetric textures
- RGBA format with density

### ✅ Requirement 63.2: Volumetric Clouds

- Cloud density textures
- Light scattering support

## Conclusion

This texture asset system provides high-quality, VR-optimized textures for all visual elements in Project Resonance. The combination of 4K PBR textures, proper compression, and streaming ensures photorealistic visuals while maintaining 90 FPS performance on RTX 4090 hardware.
