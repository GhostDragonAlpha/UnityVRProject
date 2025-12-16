# Texture Sourcing Guide

## Overview

This guide provides detailed instructions for sourcing, creating, and implementing high-resolution 4K PBR textures for Project Resonance. All textures must meet quality standards while maintaining VR performance at 90 FPS.

## Quick Start

### Immediate Actions

1. **Download Free PBR Textures**

   - Visit Poly Haven (polyhaven.com) - CC0 license
   - Download 4K PBR texture sets
   - Focus on metal, rock, ice, and sand materials

2. **Set Up Godot Import**

   - Configure import presets for sRGB and Linear textures
   - Enable VRAM compression
   - Generate mipmaps

3. **Test in VR**
   - Import textures into test scene
   - Verify 90 FPS performance
   - Adjust quality if needed

## Recommended Free Sources

### 1. Poly Haven (polyhaven.com)

**License**: CC0 (Public Domain)
**Quality**: Excellent
**Formats**: PNG, EXR
**Resolutions**: Up to 8K

**Recommended Downloads**:

#### Spacecraft Materials

- "Scratched Metal" - For hull exterior
- "Brushed Metal" - For cockpit panels
- "Worn Metal" - For aged surfaces
- "Glass Clean" - For canopy

#### Planetary Surfaces

- "Rocky Ground" series - For terrestrial planets
- "Ice Surface" series - For ice worlds
- "Sand Dunes" series - For desert planets
- "Volcanic Rock" series - For volcanic worlds

**Download Instructions**:

1. Visit polyhaven.com/textures
2. Search for material type
3. Select 4K resolution
4. Download "All Maps" (includes albedo, normal, roughness, displacement)
5. Extract to appropriate `data/textures/` subdirectory

### 2. NASA Image Library (images.nasa.gov)

**License**: Public Domain (with attribution)
**Quality**: Excellent (real space imagery)
**Formats**: JPEG, TIFF, PNG

**Recommended Downloads**:

#### Planetary Surfaces

- Mars surface imagery (HiRISE)
- Moon surface imagery (LRO)
- Europa ice imagery (Galileo)
- Titan surface imagery (Cassini)

#### Space Environment

- Nebula imagery (Hubble, Spitzer)
- Star field imagery
- Galaxy imagery

**Download Instructions**:

1. Visit images.nasa.gov
2. Search for desired subject
3. Filter by "High Resolution"
4. Download largest available size
5. Process into tileable textures (see Processing section)

### 3. ESA/Hubble (esahubble.org)

**License**: CC BY 4.0 (requires attribution)
**Quality**: Excellent
**Formats**: JPEG, TIFF

**Recommended Downloads**:

#### Space Environment

- Nebula imagery (Orion, Carina, Eagle)
- Star cluster imagery
- Galaxy imagery

**Attribution Required**: "Credit: ESA/Hubble"

### 4. USGS Earth Explorer (earthexplorer.usgs.gov)

**License**: Public Domain
**Quality**: Excellent (satellite imagery)
**Formats**: GeoTIFF

**Recommended Downloads**:

#### Planetary Surface Reference

- Desert terrain (Sahara, Mojave)
- Ice terrain (Antarctica, Greenland)
- Volcanic terrain (Hawaii, Iceland)
- Ocean imagery

**Download Instructions**:

1. Create free account
2. Search by location
3. Select Landsat 8 or Sentinel-2
4. Download highest resolution
5. Process into tileable textures

### 5. Textures.com (textures.com)

**License**: Commercial (requires subscription)
**Quality**: Excellent
**Formats**: PNG, JPEG
**Cost**: ~$10-50/month

**Recommended Downloads**:

- Metal textures (scratched, brushed, worn)
- Rock textures (various types)
- Ice and snow textures
- Sand and desert textures

**Note**: Only use if budget allows. Free sources are sufficient.

### 6. Quixel Megascans (quixel.com/megascans)

**License**: Free with Epic Games account
**Quality**: Excellent (photogrammetry)
**Formats**: PNG, EXR
**Resolutions**: Up to 8K

**Recommended Downloads**:

- Metal surfaces
- Rock surfaces
- Ground surfaces

**Note**: Requires Epic Games account and Quixel Bridge software.

## Procedural Generation Tools

### 1. Material Maker (Free, Open Source)

**Website**: github.com/RodZill4/material-maker
**Platform**: Windows, Linux, macOS
**License**: MIT

**Use Cases**:

- Create custom PBR materials
- Generate tileable textures
- Create normal maps from height
- Export all PBR maps

**Workflow**:

1. Download and install Material Maker
2. Create new material graph
3. Add noise and pattern nodes
4. Configure PBR outputs
5. Export 4K textures

**Recommended for**:

- Spacecraft hull details
- Cockpit panel textures
- Custom planetary surfaces

### 2. Substance Designer (Commercial)

**Website**: substance3d.adobe.com
**Platform**: Windows, macOS
**License**: Subscription (~$20/month)

**Use Cases**:

- Professional PBR material creation
- Complex procedural textures
- Industry-standard workflow

**Note**: Only use if budget allows. Material Maker is sufficient.

### 3. Blender (Free, Open Source)

**Website**: blender.org
**Platform**: Windows, Linux, macOS
**License**: GPL

**Use Cases**:

- Bake textures from 3D models
- Create normal maps
- Generate AO maps
- UV unwrapping

**Workflow**:

1. Create or import 3D model
2. UV unwrap
3. Bake textures (normal, AO, etc.)
4. Export as PNG

## AI Generation Tools

### 1. Stable Diffusion (Free, Open Source)

**Use Cases**:

- Generate concept textures
- Create unique planetary surfaces
- Generate nebula imagery

**Workflow**:

1. Install Stable Diffusion (AUTOMATIC1111 WebUI)
2. Use prompts like "4K PBR texture, metal surface, scratched, worn"
3. Generate multiple variations
4. Post-process to make tileable
5. Create PBR maps from generated albedo

**Recommended Models**:

- Stable Diffusion XL
- Realistic Vision
- DreamShaper

### 2. DALL-E / Midjourney (Commercial)

**Use Cases**:

- Quick concept generation
- Reference imagery
- Unique textures

**Note**: Generated images may need significant post-processing.

## Texture Processing Workflow

### Making Textures Tileable

Many source images are not tileable. Use these techniques:

#### Method 1: Offset and Blend (Photoshop/GIMP)

1. Open texture in image editor
2. Filter > Other > Offset (50% width, 50% height)
3. Use Clone Stamp tool to blend seams
4. Verify tiling by duplicating 2x2

#### Method 2: Seamless Texture Generator

1. Use online tool: seamless-texture-generator.com
2. Upload texture
3. Adjust blend settings
4. Download seamless result

### Creating Normal Maps

#### From Height Map (Recommended)

1. Create or obtain height map (grayscale)
2. Use tool:
   - **GIMP**: Filters > Generic > Normal Map
   - **Photoshop**: NVIDIA Normal Map Plugin
   - **Online**: cpetry.github.io/NormalMap-Online
3. Adjust strength (typically 5-10)
4. Export as PNG (Linear color space)

#### From Albedo (Quick Method)

1. Convert albedo to grayscale
2. Apply high-pass filter
3. Generate normal map from result
4. Adjust strength

### Creating Roughness Maps

#### From Albedo

1. Convert albedo to grayscale
2. Invert if needed (dark = smooth, light = rough)
3. Adjust contrast
4. Export as PNG (Linear color space)

#### Manual Painting

1. Create new grayscale image
2. Paint rough areas white
3. Paint smooth areas black
4. Blur slightly for smooth transitions

### Creating Metallic Maps

#### Binary Method (Simple)

1. Create new grayscale image
2. Paint metallic areas white (1.0)
3. Paint non-metallic areas black (0.0)
4. No blur needed (sharp transitions)

#### Gradient Method (Advanced)

1. Create grayscale image
2. Paint fully metallic areas white
3. Paint partially metallic areas gray
4. Paint non-metallic areas black

### Creating AO Maps

#### Baking in Blender

1. Create or import 3D model
2. Add Ambient Occlusion node in shader
3. Bake to texture
4. Export as PNG

#### From Height Map

1. Use height map as input
2. Apply cavity detection filter
3. Adjust strength
4. Export as PNG

## Godot Import Configuration

### Import Preset: Albedo/Emission (sRGB)

Create import preset file: `.godot/import_presets/albedo.preset`

```
[preset.0]

name="Albedo"
platform="Windows"
runnable=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path=""
encryption_include_filter=""
encryption_exclude_filter=""
encrypt_pck=false
encrypt_directory=false

[preset.0.options]

compress/mode=2
compress/high_quality=true
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=true
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
```

### Import Preset: Normal/Roughness/Metallic (Linear)

Create import preset file: `.godot/import_presets/linear.preset`

```
[preset.1]

name="Linear"
# ... (similar to above but with)

[preset.1.options]

compress/mode=2
compress/high_quality=true
compress/normal_map=1  # Enable for normal maps
mipmaps/generate=true
process/hdr_as_srgb=false  # Linear color space
```

### Manual Import Settings

For each texture, configure in Godot:

1. Select texture in FileSystem
2. Click "Import" tab
3. Configure settings:
   - **Compress**: VRAM Compressed
   - **Mipmaps**: Generate
   - **Filter**: Linear
   - **Anisotropic**: 16x
   - **sRGB**: Enabled (albedo/emission) or Disabled (others)
4. Click "Reimport"

## Texture Optimization

### Compression

Use VRAM compression for all textures:

- **BC7** (BPTC): Color textures (albedo, emission)
- **BC5** (RGTC): Normal maps (2-channel)
- **BC4** (RGTC): Single-channel (roughness, metallic, AO)

### Resolution Guidelines

| Distance | Resolution | Use Case                            |
| -------- | ---------- | ----------------------------------- |
| < 1m     | 4096x4096  | Cockpit interior, close-up details  |
| 1-10m    | 2048x2048  | Spacecraft exterior, nearby objects |
| 10-100m  | 1024x1024  | Distant spacecraft, terrain         |
| > 100m   | 512x512    | Very distant objects                |

### Mipmap Generation

Always generate mipmaps:

- Reduces aliasing at distance
- Improves performance
- Automatic LOD

### Texture Streaming

For large planetary surfaces:

1. Split into tiles (e.g., 16x16 grid)
2. Load tiles based on camera distance
3. Unload distant tiles
4. Use virtual texturing (future enhancement)

## Quality Assurance

### Checklist for Each Texture

- [ ] Resolution: 4096x4096 (or appropriate for use case)
- [ ] Format: PNG (lossless)
- [ ] Color Space: Correct (sRGB or Linear)
- [ ] Tileable: Yes (if required)
- [ ] No visible seams
- [ ] Appropriate detail level
- [ ] PBR maps complete (albedo, normal, roughness, metallic, AO)
- [ ] File size reasonable (< 50 MB per texture)
- [ ] Godot import settings configured
- [ ] Tested in-engine
- [ ] Tested in VR
- [ ] Performance acceptable (90 FPS maintained)
- [ ] Attribution documented (if required)

### Testing Procedure

1. **Import Test**

   - Import texture into Godot
   - Verify no import errors
   - Check texture preview

2. **Material Test**

   - Create StandardMaterial3D
   - Assign all PBR maps
   - Apply to test mesh (sphere or plane)

3. **Lighting Test**

   - Test with DirectionalLight3D
   - Test with OmniLight3D
   - Verify PBR response

4. **VR Test**

   - View in VR headset
   - Check for aliasing
   - Verify readability
   - Test at various distances

5. **Performance Test**
   - Monitor FPS
   - Check VRAM usage
   - Verify 90 FPS maintained

## Attribution Management

### Attribution File

Create `data/textures/ATTRIBUTIONS.md`:

```markdown
# Texture Attributions

## Spacecraft Hull

- **spacecraft_hull_albedo.png**
  - Source: Poly Haven
  - Original: "Scratched Metal 01"
  - License: CC0
  - URL: polyhaven.com/a/scratched_metal_01

## Planetary Surfaces

- **planet_ice_albedo.png**
  - Source: NASA/JPL
  - Original: Europa surface imagery
  - License: Public Domain
  - Credit: NASA/JPL-Caltech
  - URL: photojournal.jpl.nasa.gov/catalog/PIA19048

## Space Environment

- **nebula_blue_volumetric.png**
  - Source: ESA/Hubble
  - Original: Orion Nebula
  - License: CC BY 4.0
  - Credit: ESA/Hubble & NASA
  - URL: esahubble.org/images/heic0601a/
```

### In-Game Credits

Include texture credits in game credits screen:

```
TEXTURE ASSETS

Spacecraft Materials: Poly Haven (CC0)
Planetary Imagery: NASA/JPL (Public Domain)
Nebula Imagery: ESA/Hubble (CC BY 4.0)
Additional Textures: [Your Studio Name]
```

## Spacecraft Texture Specifications

### Hull Exterior

**Required Textures**:

1. `spacecraft_hull_albedo.png` (4096x4096, sRGB)

   - Base color: Dark gray-blue (0.2, 0.22, 0.25)
   - Panel lines: 2-5cm wide
   - Rivets: 1cm diameter, 10cm spacing
   - Wear patterns: Scratches, scuffs

2. `spacecraft_hull_normal.png` (4096x4096, Linear)

   - Panel depth: 0.5-1cm
   - Rivet height: 0.2cm
   - Surface detail: Micro-scratches

3. `spacecraft_hull_roughness.png` (4096x4096, Linear)

   - Base roughness: 0.3 (smooth metal)
   - Worn areas: 0.5-0.7
   - Scratches: 0.8

4. `spacecraft_hull_metallic.png` (4096x4096, Linear)

   - Uniform: 0.9 (highly metallic)

5. `spacecraft_hull_ao.png` (4096x4096, Linear)

   - Panel gaps: Dark
   - Rivet cavities: Dark
   - Flat surfaces: Light

6. `spacecraft_hull_height.png` (4096x4096, Linear, 16-bit)
   - Panel depth: -0.5cm to 0cm
   - Rivet height: 0cm to +0.2cm

**Sourcing**:

- Base: Poly Haven "Scratched Metal"
- Details: Add in Material Maker or Substance Designer
- Weathering: Paint manually in Photoshop/GIMP

### Glass Canopy

**Required Textures**:

1. `spacecraft_glass_albedo.png` (2048x2048, sRGB)

   - Base color: Tinted blue-green (0.3, 0.5, 0.6, 0.2)
   - Subtle tint variation

2. `spacecraft_glass_normal.png` (2048x2048, Linear)

   - Very subtle surface imperfections
   - Micro-scratches

3. `spacecraft_glass_roughness.png` (2048x2048, Linear)

   - Base: 0.02 (very smooth)
   - Slight variation: 0.01-0.05

4. `spacecraft_glass_opacity.png` (2048x2048, Linear)
   - Base: 0.8 (80% transparent)
   - Edge tinting: 0.6 (thicker glass)

**Sourcing**:

- Base: Poly Haven "Glass Clean"
- Tinting: Add in image editor
- Imperfections: Paint manually

### Cockpit Interior

**Required Textures**:

1. `cockpit_dashboard_albedo.png` (4096x4096, sRGB)

   - Base color: Dark gray (0.15, 0.15, 0.18)
   - Button labels and markings
   - Panel seams

2. `cockpit_dashboard_normal.png` (4096x4096, Linear)

   - Button details
   - Panel lines
   - Surface texture

3. `cockpit_dashboard_roughness.png` (4096x4096, Linear)

   - Base: 0.25 (smooth metal)
   - Worn areas: 0.4-0.6
   - Buttons: 0.3

4. `cockpit_dashboard_metallic.png` (4096x4096, Linear)

   - Metal areas: 0.85
   - Plastic buttons: 0.1

5. `cockpit_dashboard_emission.png` (4096x4096, sRGB)
   - Button backlighting
   - Display glow
   - Indicator lights

**Sourcing**:

- Base: Poly Haven "Brushed Metal"
- Details: Create in Material Maker
- Labels: Design in vector editor, rasterize

## Planetary Texture Specifications

### Terrestrial (Rocky)

**Required Textures**:

1. `planet_terrestrial_albedo.png` (4096x4096, sRGB)

   - Colors: Browns, grays, reds
   - Rock detail
   - Dirt and dust

2. `planet_terrestrial_normal.png` (4096x4096, Linear)

   - Rock surface detail
   - Crater rims
   - Cracks and fissures

3. `planet_terrestrial_roughness.png` (4096x4096, Linear)

   - Varied: 0.6-0.9
   - Smooth rocks: 0.6
   - Rough dirt: 0.9

4. `planet_terrestrial_height.png` (4096x4096, Linear, 16-bit)
   - Terrain elevation
   - Rock protrusions
   - Crater depth

**Sourcing**:

- Base: NASA Mars imagery (HiRISE)
- Processing: Make tileable
- Enhancement: Add detail in Material Maker

### Ice World

**Required Textures**:

1. `planet_ice_albedo.png` (4096x4096, sRGB)

   - Colors: White, light blue
   - Ice crystal detail
   - Snow accumulation

2. `planet_ice_normal.png` (4096x4096, Linear)

   - Ice cracks
   - Crystal structure
   - Surface roughness

3. `planet_ice_roughness.png` (4096x4096, Linear)

   - Smooth ice: 0.1
   - Rough snow: 0.8
   - Varied

4. `planet_ice_height.png` (4096x4096, Linear, 16-bit)
   - Ice formations
   - Crevasses
   - Snow drifts

**Sourcing**:

- Base: NASA Europa imagery
- Alternative: USGS Antarctica imagery
- Processing: Make tileable, adjust colors

### Desert World

**Required Textures**:

1. `planet_desert_albedo.png` (4096x4096, sRGB)

   - Colors: Yellows, oranges, tans
   - Sand texture
   - Rock outcroppings

2. `planet_desert_normal.png` (4096x4096, Linear)

   - Sand ripples
   - Dune shapes
   - Rock texture

3. `planet_desert_roughness.png` (4096x4096, Linear)

   - Fine sand: 0.7
   - Rocks: 0.6

4. `planet_desert_height.png` (4096x4096, Linear, 16-bit)
   - Dune shapes
   - Sand ripples

**Sourcing**:

- Base: USGS Sahara imagery
- Alternative: Poly Haven sand textures
- Processing: Make tileable

### Volcanic World

**Required Textures**:

1. `planet_volcanic_albedo.png` (4096x4096, sRGB)

   - Colors: Dark grays, blacks
   - Lava rock texture
   - Ash deposits

2. `planet_volcanic_normal.png` (4096x4096, Linear)

   - Rough lava texture
   - Cracks
   - Volcanic features

3. `planet_volcanic_roughness.png` (4096x4096, Linear)

   - Very rough: 0.9

4. `planet_volcanic_emission.png` (4096x4096, sRGB)

   - Glowing lava cracks
   - Hot spots

5. `planet_volcanic_height.png` (4096x4096, Linear, 16-bit)
   - Lava flows
   - Volcanic cones

**Sourcing**:

- Base: USGS Hawaii imagery
- Alternative: Iceland volcanic imagery
- Emission: Paint manually (glowing cracks)

## Space Environment Specifications

### Nebulae

**Required Textures**:

1. `nebula_blue_volumetric.png` (512x512x512, RGBA)

   - 3D volumetric texture
   - Blue emission
   - Density variation

2. `nebula_red_volumetric.png` (512x512x512, RGBA)

   - Red emission
   - Wispy structure

3. `nebula_purple_volumetric.png` (512x512x512, RGBA)
   - Purple reflection
   - Dense regions

**Sourcing**:

- Base: Hubble nebula imagery
- Processing: Convert to 3D volumetric
- Tool: Use Blender or custom script

### Star Fields

**Required Textures**:

1. `starfield_milkyway_*.png` (6 faces, 4096x4096 each, sRGB)
   - Cubemap format
   - Milky Way galactic plane
   - Accurate star positions

**Sourcing**:

- Base: Stellarium (open source planetarium)
- Export: Cubemap from Stellarium
- Processing: Adjust brightness/contrast

## Implementation Examples

### Applying Textures in Godot

```gdscript
# Create PBR material
var material = StandardMaterial3D.new()

# Load textures
var albedo = load("res://data/textures/spacecraft/hull/spacecraft_hull_albedo.png")
var normal = load("res://data/textures/spacecraft/hull/spacecraft_hull_normal.png")
var roughness = load("res://data/textures/spacecraft/hull/spacecraft_hull_roughness.png")
var metallic = load("res://data/textures/spacecraft/hull/spacecraft_hull_metallic.png")
var ao = load("res://data/textures/spacecraft/hull/spacecraft_hull_ao.png")
var height = load("res://data/textures/spacecraft/hull/spacecraft_hull_height.png")

# Assign textures
material.albedo_texture = albedo
material.normal_enabled = true
material.normal_texture = normal
material.roughness_texture = roughness
material.metallic_texture = metallic
material.ao_enabled = true
material.ao_texture = ao
material.heightmap_enabled = true
material.heightmap_texture = height
material.heightmap_scale = 0.05  # 5cm max displacement

# Configure material
material.metallic = 0.9
material.roughness = 0.3
material.ao_light_affect = 0.5

# Apply to mesh
mesh_instance.material_override = material
```

### Texture Streaming Example

```gdscript
# Texture streaming for planetary surfaces
class_name TextureStreamer extends Node

var loaded_textures: Dictionary = {}
var texture_queue: Array = []
var max_loaded: int = 16  # Maximum textures in memory

func request_texture(path: String, priority: float) -> void:
    if path in loaded_textures:
        return  # Already loaded

    texture_queue.append({"path": path, "priority": priority})
    texture_queue.sort_custom(func(a, b): return a.priority > b.priority)

    _process_queue()

func _process_queue() -> void:
    while texture_queue.size() > 0 and loaded_textures.size() < max_loaded:
        var item = texture_queue.pop_front()
        _load_texture(item.path)

func _load_texture(path: String) -> void:
    var texture = load(path)
    loaded_textures[path] = texture

    # Unload oldest if over limit
    if loaded_textures.size() > max_loaded:
        var oldest_key = loaded_textures.keys()[0]
        loaded_textures.erase(oldest_key)
```

## Troubleshooting

### Common Issues

**Issue**: Textures look washed out

- **Solution**: Verify sRGB setting (enabled for albedo, disabled for others)

**Issue**: Normal maps look inverted

- **Solution**: Check normal map format (OpenGL vs DirectX)
- **Solution**: Invert Y channel if needed

**Issue**: Textures are blurry

- **Solution**: Verify mipmaps are generated
- **Solution**: Increase anisotropic filtering

**Issue**: Seams visible on tiled textures

- **Solution**: Verify texture is properly tileable
- **Solution**: Use offset and blend technique

**Issue**: Poor performance

- **Solution**: Reduce texture resolution
- **Solution**: Enable VRAM compression
- **Solution**: Implement texture streaming

**Issue**: Textures not loading

- **Solution**: Check file paths
- **Solution**: Verify import settings
- **Solution**: Check console for errors

## Next Steps

1. **Download Initial Textures**

   - Visit Poly Haven
   - Download metal and rock textures
   - Import into Godot

2. **Configure Import Settings**

   - Set up import presets
   - Configure sRGB/Linear correctly
   - Enable compression and mipmaps

3. **Test in VR**

   - Apply textures to test objects
   - Verify 90 FPS performance
   - Adjust quality as needed

4. **Create Custom Textures**

   - Install Material Maker
   - Create spacecraft-specific textures
   - Export PBR maps

5. **Document Attributions**
   - Create ATTRIBUTIONS.md
   - List all sources
   - Include required credits

## Conclusion

This guide provides comprehensive instructions for sourcing, creating, and implementing high-quality 4K PBR textures for Project Resonance. By following these guidelines, you can achieve photorealistic visuals while maintaining VR performance targets.
