# Current Iteration Prompt: "Planetary Landing System"

**Role:** You are a **Space Exploration Engineer & Planetary Systems Specialist**.
**Context:** The solar system initializer and planet generator exist separately. The player can fly in space and walk on moon terrain, but **cannot land on procedurally generated planets in the solar system**.
**The Problem:** The two systems (solar system + planet generation) are not connected. Players can't experience landing on dynamically generated planets.

---

## Your Mission (The "Fun Gap")
**Enable players to spawn on and walk across procedurally generated planets within the dynamic solar system.**

### Core Requirements:

1. **Solar System Scene Integration**:
   - Create/modify a solar system scene that initializes the 8 planets + Sun
   - Position player spacecraft in orbit around Earth or Mars  
   - Ensure VR camera and controls work in solar system environment

2. **Planet Surface Generation**:
   - When player approaches a planet (distance < threshold), generate surface terrain
   - Use `PlanetGenerator` to create voxel terrain with planet's seed
   - Generate walkable collision surfaces
   - Apply appropriate gravity for the planet

3. **Landing Transition**:
   - Detect when spacecraft contacts planet surface (landing event)
   - Transition player from spacecraft controls to walking mode
   - Spawn player on solid terrain with correct orientation (feet down)
   - Maintain VR perspective throughout transition

4. **Target Planet**:
   - **Primary:** Earth or Mars (familiar, safe starting point)
   - **Bonus:** Allow selection of any planet from solar system
   - Each planet should have unique procedural terrain based on its seed

---

## Implementation Hints

### Key Files:
- `scripts/celestial/solar_system_initializer.gd` - Initializes planets
- `scripts/procedural/planet_generator.gd` - Has `create_voxel_terrain()` method
- `scenes/celestial/solar_system.tscn` - Solar system scene
- `scripts/player/walking_controller.gd` - Walking mechanics
- `scripts/player/spacecraft.gd` - Spacecraft flight controls

### Success Criteria:
- [ ] Solar system scene loads with all planets
- [ ] Player spawns in spacecraft near target planet
- [ ] Voxel terrain generates when approaching planet
- [ ] Landing transition works (spacecraft → walking)
- [ ] Player can walk on procedural planet surface
- [ ] Planet gravity applies correctly
- [ ] No crashes or black screens
- [ ] VR mode works throughout entire sequence

---

## Final Handoff (Mandatory)
```bash
cd C:/godot
taskkill /F /IM Godot_v4.5.1-stable_win64.exe
"Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" --path . solar_system_landing.tscn --vr --fullscreen
```

**Leave it running** so the user can fly toward Earth/Mars, see terrain generate, land on the surface, and walk around.
