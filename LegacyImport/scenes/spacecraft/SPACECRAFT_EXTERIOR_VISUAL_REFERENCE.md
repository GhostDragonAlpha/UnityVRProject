# Spacecraft Exterior Visual Reference

## Overview

This document provides a visual description and design reference for the spacecraft exterior model. The design follows a sleek, futuristic aesthetic that complements the cockpit interior while maintaining the game's harmonic lattice theme.

## Design Philosophy

### Core Concept

The spacecraft represents a fusion of:

- **Advanced Technology**: Sleek, aerodynamic form with metallic surfaces
- **Functionality**: Clear purpose-driven design elements
- **Harmony**: Blue-tinted accents matching the lattice visualization
- **Scale**: Human-scale vessel (8m long) for single pilot

### Visual Language

- **Form**: Elongated capsule with swept wings
- **Materials**: Metallic hull with glass canopy
- **Color Palette**: Dark gray-blue hull, blue-green glass, blue engine glow
- **Details**: Panel accents, surface variations, geometric patterns

## Component Breakdown

### Main Hull

```
     Front                                    Rear
       ↓                                        ↓
    [Canopy]═══════════════════════════════[Engines]
       ╱ ╲                                    ║ ║
      ╱   ╲                                   ║ ║
     ╱     ╲                                  ║ ║
    ╱       ╲                                 ║ ║
   ╱_________╲________________________________║_║
  ╱           ╲                              ╱   ╲
 ╱             ╲                            ╱     ╲
╱_______________╲__________________________╱_______╲
```

**Dimensions**:

- Length: 8.0 meters
- Width (at widest): 3.0 meters
- Height: 3.0 meters

**Material**: Dark gray-blue metallic

- Albedo: (0.2, 0.22, 0.25)
- Metallic: 0.9
- Roughness: 0.3

**Shape**: Elongated capsule (CapsuleMesh)

- Radius: 1.5 meters
- Height: 8.0 meters
- Oriented forward (rotated 90°)

### Cockpit Canopy

```
     ╱╲
    ╱  ╲
   ╱    ╲
  ╱      ╲
 ╱________╲
 │  GLASS │
 │        │
 └────────┘
```

**Position**: Front of spacecraft (0, 0.5, -3.0)

**Dimensions**:

- Radius: 1.2 meters
- Height: 2.4 meters

**Material**: Tinted glass

- Albedo: (0.3, 0.5, 0.6) with 20% transparency
- Metallic: 0.95 (very reflective)
- Roughness: 0.02 (extremely smooth)
- Refraction: Enabled (scale 0.05)

**Shape**: Sphere (SphereMesh)

- Provides 180° forward visibility
- Matches interior cockpit view

### Wings

```
Left Wing                    Right Wing
    ╱                            ╲
   ╱                              ╲
  ╱________________________________╲
 ╱                                  ╲
╱____________________________________╲
        ║                    ║
        ║                    ║
    [Engine]              [Engine]
```

**Dimensions**:

- Length: 4.0 meters each
- Width: 2.0 meters
- Thickness: 0.2 meters

**Position**:

- Left: (-2.5, 0, 0)
- Right: (2.5, 0, 0)

**Material**: Same as hull (dark gray-blue metallic)

**Shape**: Flat boxes (BoxMesh)

- Swept back design
- Provides aerodynamic profile

### Engine Nacelles

```
    ┌─────┐
    │     │
    │     │  ← Engine Housing
    │     │
    └─────┘
      ║║║    ← Exhaust Nozzle
      ╚╩╝    ← Blue Glow
```

**Dimensions**:

- Top Radius: 0.5 meters
- Bottom Radius: 0.6 meters (flared)
- Height: 3.0 meters

**Position**:

- Left: (-2.5, 0, 2.5)
- Right: (2.5, 0, 2.5)

**Material**: Detail material (medium gray)

- Albedo: (0.35, 0.35, 0.4)
- Metallic: 0.7
- Roughness: 0.5

**Shape**: Cylinders (CylinderMesh)

- Oriented backward (rotated 90°)
- Attached to wing tips

### Engine Glow

```
    ┌─────┐
    │     │
    │     │
    │     │
    └─────┘
      ║║║
    ╔═══╗  ← Glowing Exhaust
    ║ ░ ║     (Blue emission)
    ╚═══╝
```

**Dimensions**:

- Top Radius: 0.4 meters
- Bottom Radius: 0.5 meters
- Height: 0.5 meters

**Position**:

- Left: (-2.5, 0, 4.2)
- Right: (2.5, 0, 4.2)

**Material**: Engine material (emissive)

- Albedo: (0.1, 0.1, 0.15)
- Emission: (0.2, 0.5, 1.0) - Blue glow
- Emission Energy: 2.0 (adjustable with throttle)

**Lighting**: OmniLight3D at each engine

- Color: Blue (0.2, 0.5, 1.0)
- Energy: 2.0
- Range: 5.0 meters

### Detail Panels

```
Hull Top View:
┌─────────────────────────────────┐
│  [▪]     [▪]     [▪]     [▪]   │
│                                 │
│  [▪]     [▪]     [▪]     [▪]   │
└─────────────────────────────────┘
```

**Count**: 8 panels (4 pairs)

**Dimensions**:

- Width: 0.8 meters
- Height: 0.05 meters (raised)
- Depth: 1.0 meters

**Position**: Along top of hull

- Spacing: 1.5 meters apart
- Offset: ±0.6 meters from centerline

**Material**: Detail material (medium gray)

**Purpose**: Visual interest and surface variation

## Color Palette

### Primary Colors

1. **Hull**: Dark Gray-Blue

   - RGB: (51, 56, 64)
   - Hex: #333840
   - Use: Main spacecraft body

2. **Glass**: Blue-Green Tint

   - RGB: (77, 128, 153)
   - Hex: #4D8099
   - Use: Cockpit canopy (with transparency)

3. **Engine Glow**: Bright Blue

   - RGB: (51, 128, 255)
   - Hex: #3380FF
   - Use: Engine exhaust and lights

4. **Detail Panels**: Medium Gray
   - RGB: (89, 89, 102)
   - Hex: #595966
   - Use: Accent panels and details

### Material Properties

All colors use PBR (Physically Based Rendering) with:

- Accurate metallic values (0.7-0.95)
- Realistic roughness values (0.02-0.5)
- Proper Fresnel reflections
- Emission for glowing elements

## Lighting

### Engine Lights

**Type**: OmniLight3D (point lights)

**Configuration**:

- Color: Blue (0.2, 0.5, 1.0)
- Energy: 2.0 (adjustable)
- Range: 5.0 meters
- Attenuation: Inverse square law

**Position**:

- Left: (-2.5, 0, 4.5)
- Right: (2.5, 0, 4.5)

**Behavior**:

- Intensity scales with throttle
- Provides blue glow around engines
- Illuminates nearby surfaces

### Ambient Lighting

The spacecraft is designed to look good under various lighting conditions:

1. **Space (Dark)**: Engine glow provides primary lighting
2. **Sunlight**: Metallic surfaces reflect strongly
3. **Planetary Surface**: Ambient light reveals details
4. **Atmospheric Entry**: Heat effects overlay on hull

## LOD Visualization

### LOD 0 - Highest Detail (< 10m)

```
     ╱╲
    ╱  ╲ ← Glass canopy
   ╱ ▪▪ ╲
  ╱______╲
 ╱        ╲
╱__________╲
│  [▪][▪]  │ ← Detail panels
│          │
│  [▪][▪]  │
└──────────┘
 ╲        ╱
  ╲______╱
   ║    ║ ← Engine nacelles
   ╚════╝ ← Blue glow
```

**Features**:

- Full detail hull with 32 segments
- Detailed canopy with 24 segments
- Individual wings
- Detailed engine nacelles
- 8 detail panels
- Engine glow meshes

### LOD 1 - Medium Detail (10-50m)

```
     ╱╲
    ╱  ╲
   ╱____╲
  ╱      ╲
 ╱________╲
╱__________╲
│          │
└──────────┘
 ╲        ╱
  ╲______╱
   ║    ║
   ╚════╝
```

**Features**:

- Simplified hull (16 segments)
- Simplified canopy (12 segments)
- Wings present
- Simplified engines (8 segments)
- No detail panels

### LOD 2 - Low Detail (50-200m)

```
     ╱╲
    ╱  ╲
   ╱____╲
  ╱______╲
 ╱________╲
╱__________╲
└──────────┘
   ╚════╝
```

**Features**:

- Very simplified hull (8 segments)
- Combined wing structure
- Single engine representation
- Minimal geometry

### LOD 3 - Minimal Detail (200-1000m)

```
   ┌────┐
   │    │
   │    │
   └────┘
    ╚══╝
```

**Features**:

- Single box for hull
- Single emissive box for engines
- Absolute minimum geometry
- Maintains visibility at distance

## Viewing Angles

### Front View

```
       ╱╲
      ╱  ╲
     ╱ ▪▪ ╲
    ╱______╲
   ╱        ╲
  ╱__________╲
 ╱            ╲
╱______________╲
```

**Key Features**:

- Glass canopy prominent
- Symmetrical design
- Wings visible from sides

### Side View

```
    ╱╲
   ╱  ╲═══════════════╗
  ╱____╲              ║
 ╱      ╲             ║
╱________╲____________║
          ╲___________║
           ╲          ║
            ╲_________║
                 ║    ║
                 ╚════╝
```

**Key Features**:

- Elongated profile
- Wing sweep visible
- Engine nacelle position
- Aerodynamic shape

### Top View

```
       ╱╲
      ╱  ╲
     ╱____╲
    ╱      ╲
   ╱________╲
  ╱__________╲
 ╱____________╲
╱______________╲
│   [▪]  [▪]   │
│              │
│   [▪]  [▪]   │
└──────────────┘
 ╲            ╱
  ╲__________╱
   ║        ║
   ╚════════╝
```

**Key Features**:

- Symmetrical layout
- Detail panels visible
- Wing span clear
- Engine positions

### Rear View

```
   ╲          ╱
    ╲________╱
     ╲______╱
      ╲____╱
       ║  ║
       ║  ║
     ╔═══╗╔═══╗
     ║ ░ ║║ ░ ║ ← Blue glow
     ╚═══╝╚═══╝
```

**Key Features**:

- Twin engines prominent
- Blue glow visible
- Symmetrical exhaust
- Tapered hull

## Scale Reference

### Compared to Human

```
Human (1.8m)     Spacecraft (8m)
    │                 ╱╲
    │                ╱  ╲
    │               ╱____╲
    │              ╱      ╲
    │             ╱________╲
    │            ╱__________╲
    │           │            │
    ○           └────────────┘
   ╱│╲           ╲          ╱
   ╱ ╲            ╚════════╝
```

**Proportions**:

- Spacecraft is ~4.5x human height
- Cockpit fits single pilot comfortably
- Wings extend ~5.5x human height
- Engines are human-scale diameter

## Integration with Cockpit

### Interior-Exterior Consistency

The exterior model is designed to match the interior cockpit:

1. **Canopy Position**: Matches cockpit camera viewpoint
2. **Scale**: Cockpit interior fits within exterior hull
3. **Materials**: Glass canopy matches cockpit windows
4. **Orientation**: Forward direction aligns with cockpit view

### Visibility

From cockpit interior, player sees:

- Forward through glass canopy
- Wing tips in peripheral vision
- Engine glow reflected on canopy
- Hull panels in extreme peripheral

## Animation Potential

### Current State

The model is static but designed for future animation:

1. **Landing Gear**: Space for retractable gear
2. **Control Surfaces**: Wing flaps could animate
3. **Engine Nozzles**: Could gimbal for thrust vectoring
4. **Canopy**: Could open/close for entry/exit

### Engine Effects

Currently animated:

- Engine glow intensity (scales with throttle)
- Engine light brightness (scales with throttle)

Future potential:

- Engine exhaust particles
- Heat distortion
- Thrust vectoring animation

## Conclusion

The spacecraft exterior model provides a cohesive, visually appealing design that:

- Matches the game's aesthetic (harmonic lattice theme)
- Complements the cockpit interior
- Maintains performance through LOD system
- Supports future enhancements and animations
- Provides clear visual identity for the player's vessel

The design balances realism with stylization, creating a spacecraft that feels both functional and futuristic while maintaining the 90 FPS VR performance target.
