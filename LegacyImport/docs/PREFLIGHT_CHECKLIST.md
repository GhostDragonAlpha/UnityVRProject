# Evolving Preflight Checklist & Knowledge Base
**Status:** Living Document (Agents must update this)

## 1. VR & Display (The "Presence" Check)
- [ ] **Viewport XR**: `get_viewport().use_xr = true` must be called.
- [ ] **Camera**: A `Camera3D` must exist and be `current = true`.
    *   **Conflict Check**: Ensure NO OTHER cameras have `current = true` (Debug/Spectator cams steal focus).
    *   **VR Priority**: The `XRCamera3D` must be the active one.
- [ ] **Player Position**: `XROrigin3D` must be at the gameplay spawn point, NOT at `(0,0,0)`.
- [ ] **Black Screen Prevention**: `WorldEnvironment` must exist. At least one Light (`Directional` or `Omni`) must be active (`energy > 0`).
- [ ] **VR Mode Verification**:
    *   **Launch Flag**: You MUST run with `--vr` to force VR mode.
    *   **Log Check**: Must see `"VR mode initialized successfully"`. If `"enabling desktop fallback"`, you FAILED.

## 2. Physics & Interaction (The "Feel" Check)
- [ ] **Collisions**: `CollisionShape3D` nodes must be enabled (not disabled).
- [ ] **Layer Masking**: Ensure objects are on the correct collision layers (e.g., Player vs Enemy).
- [ ] **Tunneling**: Fast-moving projectiles (bullets) should use RayCasting or ShapeCasting, not just small RigidBodies.
- [ ] **Inputs**: Input Map actions (e.g., "thrust_forward") must be defined in `project.godot`.

## 3. Graphics & Visuals (The "Look" Check)
- [ ] **Materials**: Ensure no "Pink" (missing shader) or "Black" (unlit) materials.
- [ ] **Z-Fighting**: Check for overlapping coplanar geometry (flickering textures).
- [ ] **Particles**: `emitting` must be true. `one_shot` particles need a restart mechanism or auto-free.
- [ ] **Shadows**: DirectionalLight should have shadows enabled for depth perception.

## 4. UI & HUD (The "Feedback" Check)
- [ ] **3D UI**: In VR, UI *must* be on a `Sprite3D` or `MeshInstance3D` (CanvasLayer does not work in VR).
- [ ] **Anchors**: Ensure UI elements are anchored correctly so they don't clip off-screen or float away.
- [ ] **Readability**: Text size must be large enough for VR resolution.

## 5. Audio (The "Immersion" Check)
- [ ] **Manager**: `MoonAudioManager` (or equivalent) must be present.
- [ ] **Listeners**: `AudioListener3D` must be active (usually on the Camera).
- [ ] **Buses**: Ensure sounds are routed to "SFX" or "Music" buses, not just "Master".
- [ ] **Spatial**: 3D sounds must have `max_distance` set appropriately (don't let engine noise cover the whole map).

## 6. Agent Self-Correction (Add your own findings below)
- [ ] *[Example]*: Don't forget to set `emitting = true` on Particles.
- [x] **Camera Conflicts**: CRITICAL - Check for multiple Camera3D nodes with `current = true`. Desktop debug cameras will override XRCamera3D and break first-person VR view. Set debug cameras to `current = false`.
- [x] **AudioListener3D Required**: CRITICAL - Godot 4.5+ requires an AudioListener3D node for ANY audio playback (2D or 3D). Add as child of XRCamera3D. Without it, all audio will be silent even if MoonAudioManager is working.
- [x] **OpenXR Direct Initialization**: CRITICAL - When VRManager autoload is unavailable, scene VR controllers must implement fallback OpenXR initialization. Pattern: (1) Set `get_viewport().use_xr = true` FIRST, (2) Find interface via `XRServer.find_interface("OpenXR")`, (3) Call `xr_interface.initialize()` if not already initialized. See `moon_landing_vr_controller.gd:75-101` for reference implementation.

## 7. Verification & Tooling (The "Sanity" Check)
- [ ] **Editor Sanity**: Run `godot --headless --editor --quit` and check for errors.
- [ ] **API Availability**: Ensure `curl http://localhost:8080/status` returns 200 OK.
- [ ] **Strict FPS**: VR MUST run at >30 FPS (Critical) and target 90 FPS.
- [ ] **Screenshots**: Ensure `/debug/screenshot` is working for visual proof.
