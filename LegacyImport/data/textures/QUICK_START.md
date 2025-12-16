# Texture Assets Quick Start Guide

## Immediate Actions (30 minutes)

This guide gets you started with texture assets quickly. Follow these steps to have working textures in under 30 minutes.

## Step 1: Download Free Textures (10 minutes)

### Visit Poly Haven

1. Go to https://polyhaven.com/textures
2. Download these essential textures (4K resolution, all maps):

#### For Spacecraft Hull

- Search: "metal scratched"
- Download: "Metal Scratched 01" or similar
- Get: All maps (Albedo, Normal, Roughness, Displacement, AO)
- Save to: `data/textures/spacecraft/hull/`

#### For Cockpit Interior

- Search: "metal brushed"
- Download: "Brushed Metal 01" or similar
- Get: All maps
- Save to: `data/textures/spacecraft/cockpit/`

#### For Rocky Planets

- Search: "rock ground"
- Download: "Rock Ground 01" or similar
- Get: All maps
- Save to: `data/textures/planets/terrestrial/`

#### For Ice Planets

- Search: "ice"
- Download: "Ice Surface 01" or similar
- Get: All maps
- Save to: `data/textures/planets/ice/`

#### For Desert Planets

- Search: "sand"
- Download: "Sand Dunes 01" or similar
- Get: All maps
- Save to: `data/textures/planets/desert/`

### Naming Convention

Rename downloaded files to match our convention:

- `metal_scratched_01_diff_4k.png` → `spacecraft_hull_albedo.png`
- `metal_scratched_01_nor_gl_4k.png` → `spacecraft_hull_normal.png`
- `metal_scratched_01_rough_4k.png` → `spacecraft_hull_roughness.png`
- `metal_scratched_01_disp_4k.png` → `spacecraft_hull_height.png`
- `metal_scratched_01_ao_4k.png` → `spacecraft_hull_ao.png`

Create metallic map (all white for metal):

- Copy any texture, fill with white (RGB 255,255,255)
- Save as: `spacecraft_hull_metallic.png`

## Step 2: Import into Godot (5 minutes)

### Configure Import Settings

1. Open Godot project
2. Navigate to `data/textures/spacecraft/hull/` in FileSystem
3. For each texture:

#### Albedo Texture

- Select `spacecraft_hull_albedo.png`
- Click "Import" tab
- Set:
  - Compress: VRAM Compressed
  - Mipmaps: Generate
  - Filter: Linear
  - Anisotropic: 16x
  - sRGB: **Enabled**
- Click "Reimport"

#### Normal Texture

- Select `spacecraft_hull_normal.png`
- Click "Import" tab
- Set:
  - Compress: VRAM Compressed
  - Mipmaps: Generate
  - Filter: Linear
  - Anisotropic: 16x
  - sRGB: **Disabled**
  - Normal Map: **Enabled**
- Click "Reimport"

#### Roughness/Metallic/AO/Height Textures

- Select each texture
- Click "Import" tab
- Set:
  - Compress: VRAM Compressed
  - Mipmaps: Generate
  - Filter: Linear
  - Anisotropic: 16x
  - sRGB: **Disabled**
- Click "Reimport"

## Step 3: Create Test Material (5 minutes)

### Create Test Scene

1. Create new 3D scene
2. Add Node3D as root
3. Add MeshInstance3D as child
4. Set mesh to SphereMesh
5. Increase sphere radius to 2.0

### Create Material

1. In Inspector, expand "Material"
2. Click "Material Override" dropdown
3. Select "New StandardMaterial3D"
4. Click the material to edit

### Assign Textures

1. **Albedo**:

   - Expand "Albedo" section
   - Click texture slot
   - Select "Load"
   - Navigate to `spacecraft_hull_albedo.png`

2. **Normal Map**:

   - Expand "Normal Map" section
   - Enable "Normal Map"
   - Click texture slot
   - Load `spacecraft_hull_normal.png`

3. **Roughness**:

   - Expand "Roughness" section
   - Click texture slot
   - Load `spacecraft_hull_roughness.png`

4. **Metallic**:

   - Expand "Metallic" section
   - Set Metallic value to 0.9
   - Click texture slot
   - Load `spacecraft_hull_metallic.png`

5. **Ambient Occlusion**:

   - Expand "Ambient Occlusion" section
   - Enable "Ambient Occlusion"
   - Click texture slot
   - Load `spacecraft_hull_ao.png`

6. **Height Map**:
   - Expand "Height Map" section
   - Enable "Height Map"
   - Click texture slot
   - Load `spacecraft_hull_height.png`
   - Set Scale to 0.05

### Add Lighting

1. Add DirectionalLight3D to scene
2. Rotate to illuminate sphere
3. Set Energy to 1.0

### Test

1. Press F6 to run scene
2. Rotate camera to view material
3. Verify textures are visible and correct

## Step 4: Apply to Spacecraft (10 minutes)

### Update Spacecraft Exterior

1. Open `scripts/player/spacecraft_exterior.gd`
2. Find the hull material creation code
3. Replace procedural material with textured material:

```gdscript
func _create_hull_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()

    # Load textures
    var albedo = load("res://data/textures/spacecraft/hull/spacecraft_hull_albedo.png")
    var normal = load("res://data/textures/spacecraft/hull/spacecraft_hull_normal.png")
    var roughness = load("res://data/textures/spacecraft/hull/spacecraft_hull_roughness.png")
    var metallic = load("res://data/textures/spacecraft/hull/spacecraft_hull_metallic.png")
    var ao = load("res://data/textures/spacecraft/hull/spacecraft_hull_ao.png")
    var height = load("res://data/textures/spacecraft/hull/spacecraft_hull_height.png")

    # Assign textures
    mat.albedo_texture = albedo
    mat.normal_enabled = true
    mat.normal_texture = normal
    mat.roughness_texture = roughness
    mat.metallic = 0.9
    mat.metallic_texture = metallic
    mat.ao_enabled = true
    mat.ao_texture = ao
    mat.ao_light_affect = 0.5
    mat.heightmap_enabled = true
    mat.heightmap_texture = height
    mat.heightmap_scale = 0.05

    # PBR settings
    mat.metallic_specular = 1.0
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

    return mat
```

### Update Cockpit Interior

1. Open `scripts/ui/cockpit_model.gd`
2. Find the dashboard material creation code
3. Replace with textured material:

```gdscript
func _create_dashboard_material() -> StandardMaterial3D:
    var mat = StandardMaterial3D.new()

    # Load textures
    var albedo = load("res://data/textures/spacecraft/cockpit/cockpit_dashboard_albedo.png")
    var normal = load("res://data/textures/spacecraft/cockpit/cockpit_dashboard_normal.png")
    var roughness = load("res://data/textures/spacecraft/cockpit/cockpit_dashboard_roughness.png")
    var metallic = load("res://data/textures/spacecraft/cockpit/cockpit_dashboard_metallic.png")

    # Assign textures
    mat.albedo_texture = albedo
    mat.normal_enabled = true
    mat.normal_texture = normal
    mat.roughness_texture = roughness
    mat.metallic = 0.85
    mat.metallic_texture = metallic

    return mat
```

### Test in VR

1. Run VR scene (`vr_main.tscn`)
2. Verify textures are visible in cockpit
3. Check performance (should maintain 90 FPS)
4. Adjust quality if needed

## Step 5: Document Attributions (5 minutes)

### Update ATTRIBUTIONS.md

1. Open `data/textures/ATTRIBUTIONS.md`
2. Fill in details for downloaded textures:

```markdown
## Spacecraft Textures

### Hull Exterior

- **spacecraft_hull_albedo.png**

  - Source: Poly Haven
  - Original: "Metal Scratched 01"
  - License: CC0 (Public Domain)
  - URL: https://polyhaven.com/a/metal_scratched_01
  - Notes: Renamed from metal_scratched_01_diff_4k.png

- **spacecraft_hull_normal.png**
  - Source: Poly Haven
  - Original: "Metal Scratched 01"
  - License: CC0 (Public Domain)
  - URL: https://polyhaven.com/a/metal_scratched_01
  - Notes: Renamed from metal_scratched_01_nor_gl_4k.png

[Continue for all textures...]
```

## Verification Checklist

After completing these steps, verify:

- [ ] Textures downloaded from Poly Haven
- [ ] Files renamed to project convention
- [ ] Files placed in correct directories
- [ ] Godot import settings configured
- [ ] Test material created and working
- [ ] Spacecraft materials updated
- [ ] VR performance maintained (90 FPS)
- [ ] Attributions documented

## Next Steps

### Immediate (Today)

1. Download additional planetary textures
2. Apply to procedural planet generator
3. Test in VR

### Short Term (This Week)

1. Create custom spacecraft detail textures
2. Add emission maps for cockpit displays
3. Create glass canopy textures
4. Add particle effect textures

### Long Term (This Month)

1. Create volumetric nebula textures
2. Generate star field cubemaps
3. Create UI icon textures
4. Optimize texture streaming

## Troubleshooting

### Textures Look Washed Out

**Problem**: Colors look faded or incorrect
**Solution**:

- Check sRGB setting (enabled for albedo, disabled for others)
- Verify in Import tab
- Reimport texture

### Normal Maps Look Wrong

**Problem**: Bumps appear inverted
**Solution**:

- Poly Haven uses OpenGL format (+Y up)
- Godot expects OpenGL format
- If inverted, check "Invert Y" in import settings

### Poor Performance

**Problem**: FPS drops below 90
**Solution**:

- Reduce texture resolution to 2K
- Disable height maps temporarily
- Check VRAM usage in profiler

### Textures Not Loading

**Problem**: Pink/magenta material or missing textures
**Solution**:

- Check file paths are correct
- Verify files are in correct directories
- Check console for import errors
- Reimport textures

## Support Resources

### Documentation

- Full guide: `data/textures/README.md`
- Sourcing guide: `data/textures/TEXTURE_SOURCING_GUIDE.md`
- Attributions: `data/textures/ATTRIBUTIONS.md`

### External Resources

- Poly Haven: https://polyhaven.com
- Godot Docs: https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html
- PBR Guide: https://learnopengl.com/PBR/Theory

### Community

- Godot Discord: https://discord.gg/godotengine
- Godot Forums: https://forum.godotengine.org

## Conclusion

You now have working 4K PBR textures in your project! The spacecraft should look significantly more detailed and realistic. Continue adding textures for other assets as time permits.
