# VR UI Implementation Best Practices in Godot

## Problem Case Study: Vignette Positioning Bug

This document details the vignette positioning issue and provides guidance for implementing VR UI overlays correctly.

### The Bug

**File:** `C:/godot/scripts/core/vr_comfort_system.gd` (fixed on 2025-12-03)

The vignette comfort feature for VR motion sickness prevention was positioned incorrectly, causing it to rotate with the player's head instead of staying fixed on the viewport.

### Root Cause

Attempting to parent a `CanvasLayer` (2D UI node) to an `XRCamera3D` (3D tracking node) breaks Godot's rendering pipeline for 2D elements.

```
WRONG:
SceneRoot
├── XROrigin3D
│   ├── XRCamera3D
│   │   └── CanvasLayer (WRONG PARENT!)
│   │       └── ColorRect (vignette)
│   └── Spacecraft
```

```
CORRECT:
SceneRoot
├── XROrigin3D
│   ├── XRCamera3D (3D tracking)
│   └── Spacecraft (3D gameplay)
├── CanvasLayer (2D viewport layer) ← CORRECT PARENT
│   └── ColorRect (vignette)
└── Other 2D UI
```

### Why This Matters for VR

In VR, the player has two synchronized cameras (left eye, right eye). UI elements must:

1. **Appear identical to both eyes** - Ensures proper stereoscopic rendering
2. **Move with viewport, not world** - UI shouldn't drift in 3D space as player moves
3. **Remain fixed on screen** - Overlay elements should feel "attached to the headset"
4. **Not inherit 3D transforms** - Vignette shouldn't rotate with head turns

CanvasLayer at the scene root handles all this automatically through Godot's rendering pipeline.

### The Fix

Replace any conditional parent searching with direct scene-root attachment:

```gdscript
# Create UI overlay layer
var canvas_layer = CanvasLayer.new()
canvas_layer.name = "VignetteCanvasLayer"
canvas_layer.layer = 100  # Render above game content

# Attach to scene root, not 3D nodes
var scene_root = get_tree().root
scene_root.add_child(canvas_layer)
canvas_layer.add_child(vignette_rect)
```

### Godot's Rendering Architecture

**Key Insight:** CanvasLayer is not a 2D Control node. It's a special viewport-space renderer.

- **CanvasLayer at SceneRoot:** Renders in viewport coordinates, bypasses 3D transform hierarchy
- **CanvasLayer as 3D child:** Inherits 3D transforms, breaks viewport-space rendering
- **Control/UI at CanvasLayer:** Properly scales with viewport, supports anchoring

### Implementation Pattern for VR UI

```gdscript
# For any VR UI overlay (HUD, warnings, notifications, vignettes):

func _setup_ui_overlay() -> void:
	# Create overlay container
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "UIOverlay"
	canvas_layer.layer = 100  # Adjust based on layering needs
	
	# Create UI element
	var ui_element = Control.new()  # or ColorRect, Panel, etc.
	ui_element.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Attach to scene root
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(ui_element)
	
	# Optional: Set ownership for scene serialization
	canvas_layer.owner = get_tree().root
	ui_element.owner = canvas_layer
```

### Common Mistakes to Avoid

1. **Parenting CanvasLayer to XRCamera3D** (THE BUG)
   - Breaks viewport-space rendering
   - Makes UI rotate with head
   - Causes stereo rendering issues

2. **Attaching UI directly to 3D nodes**
   - Control nodes as children of 3D nodes don't render properly
   - Won't appear in both VR eye views
   - Layout breaks with head rotation

3. **Using CanvasLayer.layer = 0 for UI**
   - Game content typically renders at layer 0
   - UI overlays should use layer 100+
   - Use negative layers (-1, -2) for backgrounds

4. **Forgetting ownership relationships**
   - Doesn't break functionality but breaks scene serialization
   - If you instance the scene, UI elements won't save/load properly

### VR-Specific Considerations

**Stereo Rendering:**
- Godot automatically renders each eye from the proper XRCamera3D view
- CanvasLayer at SceneRoot is rendered identically for both eyes
- This is why hierarchy matters: viewport-space (CanvasLayer) vs world-space (3D)

**Head Tracking:**
- XRCamera3D position/rotation is constantly updated by the VR runtime
- Child nodes of XRCamera3D inherit these transforms
- CanvasLayer children at SceneRoot do NOT inherit these transforms
- This is the design you want for fixed UI

**Performance:**
- CanvasLayer rendering is very efficient
- Multiple CanvasLayers with different layers is fine
- Minimize draw calls in each CanvasLayer

### Testing Checklist

When implementing VR UI, verify:

- [ ] UI appears on both eyes in VR
- [ ] UI doesn't shift when player moves forward/backward
- [ ] UI doesn't rotate when player turns head
- [ ] UI renders above 3D content (if intended)
- [ ] UI anchors/margins work correctly
- [ ] Performance at 90 FPS on target VR headset
- [ ] Works in both desktop and VR mode

### Related Issues

This bug pattern commonly occurs with:
- HUD elements (ammo, health, radar)
- Warning overlays
- Menu screens
- Crosshairs and targeting reticles
- Comfort features (vignettes, frame rate displays)

### References

- Godot CanvasLayer: https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html
- XRCamera3D: https://docs.godotengine.org/en/stable/classes/class_xrcamera3d.html
- Viewport-space vs world-space rendering

### Version Info

- **Fix Applied:** 2025-12-03
- **File:** C:/godot/scripts/core/vr_comfort_system.gd
- **Godot Version:** 4.5+
- **VR Framework:** OpenXR

