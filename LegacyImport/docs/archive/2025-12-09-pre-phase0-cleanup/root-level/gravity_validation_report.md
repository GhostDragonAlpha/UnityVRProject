# Gravity Validation Report - SpaceTime VR Project

## Executive Summary

**CRITICAL ISSUE FOUND:** The gravitational constant G is **incorrect by a factor of 1 million (10^6)**.

- **Current G:** 6.674e-23
- **Correct G:** 6.674e-29
- **Impact:** Gravity is 1 million times too strong, causing unrealistic physics

---

## 1. Coordinate System

The project uses a scaled coordinate system:
- **1 game unit = 1 million meters = 1,000 km**

This is documented in multiple files:
- `vr_main.gd` (line 25-26)
- `physics_engine.gd` (line 26-29)
- `celestial_body.gd` (line 36-38)
- `solar_system_initializer.gd` (line 27-39)

---

## 2. Constants from Solar System Data

From `C:/godot/data/ephemeris/solar_system.json`:

```json
"earth": {
  "mass": 5.972e24,      // kg
  "radius": 6371.0,      // km
  "rotation_period": 0.99726968,
  "axial_tilt": 23.4393
}
```

**Conversions:**
- Earth mass: 5.972×10^24 kg
- Earth radius: 6,371 km = 6.371 game units
- Player mass: 70 kg (from `vr_main.gd`)

---

## 3. Surface Gravity Calculation

### Formula
```
g = G × M / r²
```

Where:
- g = gravitational acceleration
- G = gravitational constant
- M = mass of Earth
- r = radius of Earth

### With CURRENT (WRONG) G = 6.674e-23

```
g = 6.674e-23 × 5.972e24 / (6.371)²
g = 9.819532 game_units/s²
```

Converting to m/s²:
```
g = 9.819532 game_units/s² × 1,000,000 m/game_unit
g = 9,819,532 m/s²
```

**This is 1 million times stronger than Earth's actual gravity (9.82 m/s²)!**

### With CORRECT G = 6.674e-29

```
g = 6.674e-29 × 5.972e24 / (6.371)²
g = 9.819532e-06 game_units/s²
```

Converting to m/s²:
```
g = 9.819532e-06 game_units/s² × 1,000,000 m/game_unit
g = 9.82 m/s²
```

**This matches Earth's actual surface gravity!**

---

## 4. Why the Error Occurred

The derivation in the code comments is INCORRECT:

**Current (wrong) derivation in code:**
```
G_real = 6.674e-11 m³/(kg·s²)
Scale: 1 unit = 10^6 meters
In formula a = G·M/r², distance appears squared
G_scaled = G_real / (scale²) = 6.674e-11 / (10^6)² = 6.674e-23
```

**This is wrong!** The formula doesn't account for the fact that **acceleration also needs to be scaled**.

**CORRECT derivation:**

When converting units, we need to scale both position AND acceleration:
- Position: `r_game = r_real / 10^6` (game units)
- Acceleration: `a_game = a_real / 10^6` (game units/s²)

Starting from:
```
a_real = G_real × M / r_real²
```

Substituting `r_real = r_game × 10^6`:
```
a_real = G_real × M / (r_game × 10^6)²
a_real = G_real × M / (r_game² × 10^12)
```

We want `a_game = a_real / 10^6`:
```
a_game = (G_real × M / (r_game² × 10^12)) / 10^6
a_game = (G_real / 10^18) × M / r_game²
```

Therefore:
```
G_game = G_real / 10^18
G_game = 6.674e-11 / 10^18
G_game = 6.674e-29
```

---

## 5. Player Spawn Scenario Analysis

### Current Spawn Position
- **Position:** y = 1.7 game units
- **Altitude:** 1,700 km above origin (well into space!)
- **Ground plane:** y = -0.5 game units

### Gravity at Player Altitude (1,700 km above Earth center)

Distance from Earth center:
```
d = 6.371 + 1.7 = 8.071 game units
```

**With WRONG G (6.674e-23):**
```
g = 6.674e-23 × 5.972e24 / (8.071)²
g = 6.118589e+00 game_units/s²
g = 6,118,589 m/s² (absurdly high!)
```

**With CORRECT G (6.674e-29):**
```
g = 6.674e-29 × 5.972e24 / (8.071)²
g = 6.118589e-06 game_units/s²
g = 6.12 m/s² (62.3% of surface gravity - realistic for this altitude!)
```

---

## 6. Fall Time Calculation

Player falling from y=1.7 to y=0 (distance = 1.7 game units = 1,700 km):

Using kinematic equation: `t = sqrt(2d/g)`

**With WRONG G:**
```
t = sqrt(2 × 1.7 / 6.118589)
t = 0.74 seconds (falling 1,700 km in less than 1 second!)
Final velocity = 4.53 million m/s (1.5% speed of light!)
```

**With CORRECT G:**
```
t = sqrt(2 × 1.7 / 6.118589e-06)
t = 745 seconds = 12.4 minutes (realistic for free fall from this altitude)
Final velocity = 4,560 m/s (realistic orbital decay speed)
```

---

## 7. Other Celestial Bodies in Scene

The scene includes a full solar system from `scenes/celestial/solar_system.tscn`:
- Sun (centered at origin)
- 8 planets (Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune)
- Major moons (Moon, Io, Europa, Ganymede, Callisto, Titan, Enceladus, Triton, etc.)

**All bodies are affected by the same incorrect G constant.**

At the player's spawn position (y=1.7 units), multiple gravitational forces apply:
- Earth gravity (if Earth is at origin)
- Sun gravity (if Sun is at origin)
- Other planetary bodies

With the wrong G, all these forces are 1 million times too strong.

---

## 8. Files Requiring Correction

All occurrences of `G = 6.674e-23` need to be changed to `G = 6.674e-29`:

1. **C:/godot/vr_main.gd** (line 26)
   ```gdscript
   const G: float = 6.674e-23  # WRONG
   const G: float = 6.674e-29  # CORRECT
   ```

2. **C:/godot/scripts/core/physics_engine.gd** (line 29)
   ```gdscript
   const G: float = 6.674e-23  # WRONG
   const G: float = 6.674e-29  # CORRECT
   ```

3. **C:/godot/scripts/celestial/celestial_body.gd** (line 38)
   ```gdscript
   const G: float = 6.674e-23  # WRONG
   const G: float = 6.674e-29  # CORRECT
   ```

4. **C:/godot/scripts/celestial/solar_system_initializer.gd** (line 39)
   ```gdscript
   const G_SCALED := 6.674e-23  # WRONG
   const G_SCALED := 6.674e-29  # CORRECT
   ```

Additionally, update the derivation comments to reflect the correct calculation.

---

## 9. Expected vs Actual Values (After Fix)

### Surface Gravity
- **Expected:** 9.82 m/s²
- **Actual (with fix):** 9.82 m/s²
- **Accuracy:** 100%

### Gravity at 1,700 km Altitude
- **Expected:** ~6.1 m/s² (62% of surface gravity)
- **Actual (with fix):** 6.12 m/s²
- **Accuracy:** 99.7%

### Fall Time from 1,700 km
- **Expected:** ~12-13 minutes (assuming average gravity during fall)
- **Actual (with fix):** 12.4 minutes
- **Realistic:** Yes

---

## 10. Validation Test Plan

After applying the fix, verify:

1. **Surface gravity test:**
   - Place player at Earth surface (r = 6.371 units)
   - Measure acceleration over 1 second
   - Should be ~9.82e-06 game_units/s² = 9.82 m/s²

2. **Orbital mechanics test:**
   - Check if spacecraft can achieve stable orbit
   - Low Earth orbit (400 km altitude) requires ~7,700 m/s velocity
   - With correct G, orbital mechanics should work realistically

3. **Multi-body gravity test:**
   - Verify Sun's gravity at Earth's distance (1 AU)
   - Should produce orbital velocity of ~30 km/s
   - Test Earth-Moon system (Moon should orbit correctly)

4. **Fall test:**
   - Drop player from y=1.7 (1,700 km altitude)
   - Should take ~12 minutes to fall to surface
   - Final impact velocity should be realistic (~4-5 km/s)

---

## 11. Conclusion

The gravitational constant is currently **off by 6 orders of magnitude** (factor of 1,000,000).

**Root cause:** Incorrect unit scaling derivation. The code divided G by scale², but forgot to account for acceleration also being in scaled units.

**Fix:** Change all instances of `6.674e-23` to `6.674e-29`.

**Impact:** This will make gravity realistic and allow proper orbital mechanics, realistic free fall, and correct multi-body gravitational interactions.
