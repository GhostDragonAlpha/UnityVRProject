# VoxelTerrain Integration Steps

## Overview
This document provides step-by-step instructions for integrating VoxelTerrain into the SpaceTime VR project alongside the existing Ground CSGBox3D node. This integration will enable infinite terrain generation while maintaining compatibility with existing systems.

## Prerequisites

- Godot 4.5+ editor running
- Voxel Tools addon installed and enabled in Project Settings > Plugins
- VR scene (vr_main.tscn) accessible
- Existing Ground CSGBox3D node present in scene

## Step 1: Add VoxelTerrain Node to Scene

### Using Godot Editor:

1. **Open the VR scene:**
   - Navigate to `res://vr_main.tscn` in the FileSystem dock
   - Double-click to open in the editor

2. **Locate the Ground node:**
   - In the Scene tree, find the existing `Ground` (CSGBox3D) node
   - Note its position in the hierarchy (likely under XROrigin3D or root)

3. **Add VoxelTerrain as sibling:**
   - Right-click on the parent node of Ground
   - Select "Add Child Node"
   - Search for "VoxelTerrain"
   - Click "Create"

4. **Rename and position:**
   - Rename the new node to "VoxelGround" (for clarity)
   - Set Transform > Position to (0, 0, 0) in Inspector
   - This should place it at world origin, same level as Ground

### Expected Scene Hierarchy:
```
VRMain (Node3D)
├── XROrigin3D
│   ├── XRCamera3D
│   ├── LeftController (XRController3D)
│   └── RightController (XRController3D)
├── Ground (CSGBox3D) [existing]
└── VoxelGround (VoxelTerrain) [new]
```

## Step 2: Configure VoxelTerrain Properties

### Basic Configuration (Inspector Panel):

1. **View Distance Settings:**
   ```
   view_distance: 128
   ```
   - Controls how far terrain generates around the player
   - Start conservative (128m) for testing
   - Can increase to 256-512 for production based on performance

2. **LOD (Level of Detail) Settings:**
   ```
   lod_count: 4
   lod_distance: 64.0
   ```
   - lod_count: Number of detail levels (4 is good balance)
   - lod_distance: Distance between LOD transitions
   - Higher values = smoother performance, lower visual detail at distance

3. **Collision Settings:**
   ```
   generate_collisions: true
   collision_lod_count: 2
   collision_layer: 1
   collision_mask: 1
   ```
   - generate_collisions: MUST be true for walking
   - collision_lod_count: Use fewer LODs for collisions (performance)
   - Ensure collision_layer matches player's collision_mask

4. **Material Settings:**
   ```
   material_override: [Create new StandardMaterial3D]
   ```
   - Click material_override dropdown
   - Select "New StandardMaterial3D"
   - Configure:
     - Albedo > Color: RGB(0.4, 0.3, 0.2) [brown terrain color]
     - Roughness: 0.8
     - Optional: Add normal map for detail

## Step 3: Create and Configure VoxelStream

### VoxelStreamNoise Setup:

1. **Add Stream to VoxelTerrain:**
   - Select VoxelGround node
   - In Inspector, find "stream" property
   - Click dropdown > "New VoxelStreamNoise"

2. **Configure Noise Parameters:**
   ```
   channel: 0 (SDF channel)
   noise > type: "FastNoiseLite"
   noise > frequency: 0.01
   noise > fractal_octaves: 3
   noise > fractal_lacunarity: 2.0
   noise > fractal_gain: 0.5
   ```

3. **Set Terrain Height:**
   ```
   noise > amplitude: 20.0
   noise > offset: -10.0
   ```
   - amplitude: Controls hill height variation
   - offset: Controls base terrain height (negative = below origin)

## Step 4: Create and Configure VoxelGenerator

### VoxelGeneratorFlat Setup:

1. **Add Generator to VoxelTerrain:**
   - Select VoxelGround node
   - In Inspector, find "generator" property
   - Click dropdown > "New VoxelGeneratorFlat"

2. **Configure Flat Generator:**
   ```
   channel: 0 (SDF channel)
   height: 0.0
   voxel_size: 0.25
   iso_scale: 1.0
   ```
   - height: Y-coordinate of flat plane (0.0 = world origin)
   - voxel_size: Resolution of voxels (smaller = more detail, slower)
   - Start with 0.25, can optimize later

3. **Alternative: Use noise generator instead:**
   - For more interesting terrain, use VoxelStreamNoise (Step 3) instead
   - VoxelGeneratorFlat is simpler but less visually interesting
   - For testing, VoxelGeneratorFlat is recommended first

## Step 5: Configure Mesher

### VoxelMesherTransvoxel Setup:

1. **Add Mesher to VoxelTerrain:**
   - Select VoxelGround node
   - In Inspector, find "mesher" property
   - Click dropdown > "New VoxelMesherTransvoxel"

2. **Configure Mesher Settings:**
   ```
   texture_mode: "Textures Blend" (if using textures)
   mesh_mode: "Regular" (smooth terrain)
   ```
   - VoxelMesherTransvoxel creates smooth, marching-cubes-style terrain
   - Best for organic landscapes

## Step 6: Testing Checklist

### Initial Verification:

- [ ] **Scene loads without errors:**
  ```bash
  curl http://127.0.0.1:8080/state/scene
  ```
  Should return `"current_scene": "res://vr_main.tscn"`

- [ ] **VoxelGround node exists in scene tree:**
  - Open Scene tree in Godot editor
  - Verify VoxelGround is present and active

- [ ] **Terrain generates visually:**
  - Press Play (F5) in Godot editor
  - Look around in VR/desktop view
  - Verify flat or noisy terrain appears

- [ ] **Collision works:**
  - In play mode, drop player onto terrain
  - Verify player doesn't fall through
  - Test walking on terrain surface

### Performance Testing:

- [ ] **Monitor FPS in VR mode:**
  ```bash
  python telemetry_client.py
  ```
  - Target: 90 FPS minimum for VR
  - Watch for frame drops during movement

- [ ] **Check memory usage:**
  - Monitor in Godot Debugger > Monitor tab
  - Look at "Static Memory" and "Dynamic Memory"
  - Terrain should not cause memory spikes

- [ ] **Test view distance scaling:**
  - Increase view_distance from 128 to 256
  - Measure FPS impact
  - Find optimal balance

### Integration Testing:

- [ ] **Ground CSGBox3D still functional:**
  - Verify both nodes coexist
  - No collision conflicts
  - Can disable Ground later if VoxelGround works well

- [ ] **Player spawns correctly:**
  ```bash
  curl http://127.0.0.1:8080/state/player
  ```
  Should return player node information

- [ ] **VR controllers work:**
  - Test movement with VR controllers
  - Verify no performance degradation
  - Check haptic feedback still functions

- [ ] **Telemetry streams correctly:**
  - Connect telemetry client
  - Verify terrain data appears in streams
  - No WebSocket disconnections

## Step 7: Performance Monitoring

### Real-time Monitoring:

1. **Start telemetry client:**
   ```bash
   python telemetry_client.py
   ```

2. **Key metrics to watch:**
   - **FPS**: Should stay at 90 (VR) or 60 (desktop)
   - **Frame time**: <11ms for 90 FPS VR
   - **Memory**: Check for leaks during long play sessions
   - **Mesh updates**: Watch for excessive remeshing

3. **HTTP API health check:**
   ```bash
   curl http://127.0.0.1:8080/status
   ```
   Check `system_status.performance` section

### Optimization Steps (if needed):

1. **Reduce view_distance:**
   - Start: 128m
   - If FPS <90: Try 96m or 64m

2. **Reduce LOD count:**
   - Start: 4 LODs
   - If FPS <90: Try 3 LODs

3. **Increase voxel_size:**
   - Start: 0.25
   - If FPS <90: Try 0.5 (less detail, better performance)

4. **Reduce collision_lod_count:**
   - Start: 2
   - If FPS <90: Try 1 (only highest detail for collision)

5. **Disable Ground CSGBox3D:**
   - Once VoxelGround works, hide/remove old Ground node
   - Reduces draw calls and collision checks

## Step 8: Advanced Configuration (Optional)

### Adding Texture Support:

1. **Create VoxelLibrary:**
   - Right-click in FileSystem > New Resource > VoxelLibrary
   - Save as `res://voxel_library.tres`

2. **Add Voxel Types:**
   - Add grass, dirt, stone voxel definitions
   - Assign textures to each type

3. **Update VoxelTerrain:**
   - Set `library` property to `res://voxel_library.tres`
   - Update mesher to use textures

### Stream to Disk (for persistence):

1. **Create VoxelStreamRegionFiles:**
   - In stream property, select "New VoxelStreamRegionFiles"
   - Set directory path: `user://voxel_data/`

2. **Enable saving:**
   - Terrain modifications will persist
   - Useful for destructible environments

## Troubleshooting

### Terrain not appearing:

- Check generator/stream is assigned and configured
- Verify mesher is set (VoxelMesherTransvoxel)
- Ensure view_distance > 0
- Check camera is within view_distance of terrain

### Player falls through terrain:

- Verify `generate_collisions: true`
- Check collision_layer/mask match player settings
- Ensure collision_lod_count > 0
- Wait a few seconds for collision mesh generation

### Performance issues:

- Reduce view_distance (128 -> 64)
- Reduce lod_count (4 -> 3)
- Increase voxel_size (0.25 -> 0.5)
- Reduce collision_lod_count (2 -> 1)

### Errors in console:

- Check Voxel Tools addon is enabled
- Verify Godot version is 4.5+
- Look for missing dependencies in Output panel
- Check for conflicting collision layers

## Next Steps After Integration

1. **Disable/Remove Ground CSGBox3D:**
   - Once VoxelGround is stable, remove old ground
   - Reduces scene complexity

2. **Implement terrain modification:**
   - Add scripts for digging/building
   - Use VoxelTool for runtime editing

3. **Add biomes and variation:**
   - Create multiple VoxelStreamNoise configurations
   - Blend different noise patterns

4. **Optimize for VR:**
   - Profile with VR headset
   - Fine-tune LOD distances for 90 FPS
   - Add comfort features (reduce motion blur)

5. **Add multiplayer synchronization:**
   - Stream terrain edits to other players
   - Use VoxelStreamRegionFiles for persistence

## Reference

- **Voxel Tools Documentation**: https://voxel-tools.readthedocs.io/
- **SpaceTime HTTP API**: Port 8080 (`curl http://127.0.0.1:8080/status`)
- **Telemetry WebSocket**: Port 8081 (`python telemetry_client.py`)
- **Scene file**: `C:/godot/vr_main.tscn`

## Support

If issues arise:
1. Check Godot console output for errors
2. Run health monitor: `python tests/health_monitor.py`
3. Verify scene state: `curl http://127.0.0.1:8080/state/scene`
4. Check player state: `curl http://127.0.0.1:8080/state/player`
5. Review telemetry for performance metrics
