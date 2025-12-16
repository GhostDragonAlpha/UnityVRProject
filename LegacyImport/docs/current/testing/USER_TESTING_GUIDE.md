# VR User Testing Guide
**Date**: 2025-12-01
**Version**: 1.0
**Status**: Ready for Testing

---

## Quick Start

### 1. Launch the VR Experience

```bash
# Start Godot and run the project (F5)
# OR use the restart script:
restart_godot_with_debug.bat
```

Then press **F5** in the Godot editor to launch the VR scene.

### 2. Put on Your VR Headset

The game will automatically detect your VR headset and controllers.

---

## VR Controls

### Controller Layout

#### Teleport Movement (Both Controllers)
- **Trigger Button**: Point controller at ground and press trigger
  - A blue ray will appear showing where you'll teleport
  - A green circle shows the target location
  - Release trigger to teleport to that spot

#### Grab Objects (Both Controllers)
- **Grip/Squeeze Button**: Grab nearby objects
  - Point controller at an orange cube
  - Press and hold grip button to grab
  - Move controller while holding to move the object
  - Release grip to drop/throw the object

---

## What to Test

### Movement System
1. **Teleportation**
   - Try teleporting to different locations on the ground
   - Test teleporting short and long distances (max 5 meters)
   - Try teleporting while turning your body

   **What to Notice**:
   - Does the teleport feel smooth?
   - Is the target indicator clear?
   - Can you easily reach all areas?

### Interaction System
2. **Grabbing Objects**
   - Grab the three orange cubes scattered in front of you
   - Try throwing them by releasing while moving your hand
   - Try grabbing with left and right controllers

   **What to Notice**:
   - Do objects feel natural to grab?
   - Is the grab range comfortable?
   - Do physics feel realistic?

### Visual Quality
3. **Graphics and Performance**
   - Look around the environment
   - Check hand representation (small blue boxes on controllers)
   - Notice lighting and shadows

   **What to Notice**:
   - Is the frame rate smooth? (Target: ~77 FPS)
   - Are there any visual glitches?
   - Is the environment comfortable to look at?

### Comfort
4. **VR Comfort**
   - Spend 5-10 minutes in VR
   - Try different movement patterns
   - Test looking up, down, and all around

   **What to Notice**:
   - Any motion sickness?
   - Eye strain or discomfort?
   - Controller tracking quality?

---

## Known Issues

### Minor Issues (Non-Critical)
- **Mesh errors on startup**: You'll see 2 error messages when the game starts. These are harmless and don't affect gameplay.
- **FPS slightly below target**: Running at ~77.5 FPS instead of ideal 90 FPS. Still very playable.
- **Simple placeholder graphics**: Controllers show as simple boxes - this is intentional for testing.

### What's Working
✅ VR headset detection and initialization
✅ Controller tracking (both hands)
✅ Teleport movement system
✅ Object grabbing and physics
✅ Clean console output (no spam)
✅ Stable performance

---

## Feedback to Provide

Please note:

### Movement
- Is teleportation intuitive?
- Do you prefer trigger for teleport?
- Teleport distance comfortable?

### Interaction
- Is grabbing responsive?
- Do objects feel "right" when held?
- Throw mechanics satisfying?

### Comfort
- Any VR sickness?
- Frame rate acceptable?
- Visual quality sufficient?

### General
- What feels good?
- What needs improvement?
- Any bugs or crashes?

---

## Technical Info

### System Specs in Use
- **GPU**: NVIDIA RTX 4090
- **VR Runtime**: SteamVR/OpenXR 2.14.3
- **Engine**: Godot 4.5.1
- **Render Mode**: Forward+ with Vulkan 1.4

### Performance Stats
- **Target FPS**: 90 (VR standard)
- **Actual FPS**: ~77.5 (acceptable for testing)
- **Render Features**: Optimized for performance
  - SDFGI: Disabled
  - SSR: Disabled
  - SSAO: Disabled
  - SSIL: Disabled
  - GI: Disabled

### Scene Contents
- Ground plane (20x20 meters)
- 1 static test cube (reference object)
- 3 grabbable physics cubes (orange)
- Directional sun light
- Simple ambient lighting

---

## Troubleshooting

### VR Headset Not Detected
1. Make sure SteamVR is running
2. Check headset is powered on
3. Restart Godot and try again

### Controllers Not Working
1. Check SteamVR shows controllers as connected
2. Make sure controllers have battery
3. Re-pair controllers if needed

### Performance Issues
- Close other applications
- Check GPU drivers are updated
- Verify headset refresh rate settings

### Game Won't Start
1. Check Godot console for errors
2. Ensure ports 8081-8080 are not in use
3. Restart with: `restart_godot_with_debug.bat`

---

## Next Steps

After testing, the following improvements are planned:
1. Better controller models (replace placeholder boxes)
2. More interactive objects and environment
3. Additional locomotion options (smooth movement)
4. Performance optimization to reach full 90 FPS
5. Sound effects and haptic feedback
6. UI/HUD elements
7. Tutorial system

---

## Support

If you encounter any issues:
1. Check the Godot console output
2. Note the exact steps to reproduce
3. Document any error messages
4. Check `test-reports/latest.json` for system status

---

## Summary

You now have a basic but functional VR testing environment with:
- ✅ Teleport movement
- ✅ Object interaction
- ✅ Stable performance (~77 FPS)
- ✅ Clean, spam-free experience

**Ready for user testing!**

Enjoy exploring the VR space!
