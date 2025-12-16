# Spacecraft Cockpit Visual Reference

## Overview

This document provides a visual reference for the spacecraft cockpit model, describing the layout, materials, and interactive elements.

## Cockpit Layout (Top View)

```
                    [Canopy Glass]
                         |||
                         |||
    ┌────────────────────────────────────────┐
    │                                        │
    │  [Emergency]              [Landing]    │
    │   Button                   Gear        │
    │                                        │
    │  ┌──────────────────────────────────┐ │
    │  │                                  │ │
    │  │     [Left Display]               │ │
    │  │      Navigation                  │ │
    │  │                                  │ │
    │  │  ┌────────────────────────┐     │ │
    │  │  │                        │     │ │
    │  │  │   [Main Display]       │     │ │
    │  │  │   Telemetry            │     │ │
    │  │  │                        │     │ │
    │  │  └────────────────────────┘     │ │
    │  │                                  │ │
    │  │     [Right Display]              │ │
    │  │      Systems                     │ │
    │  │                                  │ │
    │  └──────────────────────────────────┘ │
    │                                        │
    │  [Throttle]  [Power]  [Nav Mode]      │
    │    Lever     Button    Switch         │
    │                                        │
    │  [Time Dial] [Signal Boost]           │
    │                                        │
    │         [Center Console]               │
    │                                        │
    │            [Seat]                      │
    │                                        │
    └────────────────────────────────────────┘
```

## Control Panel Layout (Front View)

```
        ┌─────────────────────────────────┐
        │      [Main Display]             │
        │   ┌─────────────────────┐       │
        │   │  SPACECRAFT         │       │
        │   │  TELEMETRY          │       │
        │   │                     │       │
        │   │  Time: 2451545.0    │       │
        │   │  Speed: 125.3 u/s   │       │
        │   │  Light: 0.04%       │       │
        │   └─────────────────────┘       │
        └─────────────────────────────────┘
                     ▲
                     │ Blue glow

┌──────────────┐                  ┌──────────────┐
│ [Left Disp]  │                  │ [Right Disp] │
│ NAVIGATION   │                  │ SIGNAL       │
│              │                  │ STATUS       │
│ Pos: X Y Z   │                  │ SNR: 95.2%   │
│ Vel: X Y Z   │                  │ Entropy: 0.1 │
└──────────────┘                  └──────────────┘
      ▲                                  ▲
      │ Blue glow                        │ Blue glow

─────────────────────────────────────────────────
              [Dashboard Surface]
─────────────────────────────────────────────────

  ⚫        ⚫        ⚫
[Throttle] [Power]  [Nav]
  Lever    Button   Switch
  (Gray)   (Green)  (Blue)

    ⭕          ⚫
 [Time Dial] [Signal]
 (Rotary)    Button
             (Red)
```

## Material Specifications

### Dashboard (Main Surface)

```
Color:     ███ Dark Gray (0.15, 0.15, 0.18)
Metallic:  ████████░░ 0.85
Roughness: ██░░░░░░░░ 0.25
Finish:    Smooth brushed metal
```

### Glass Canopy

```
Color:     ░░░ Tinted Blue-Green (0.3, 0.5, 0.6, 0.15)
Metallic:  █████████░ 0.9
Roughness: █░░░░░░░░░ 0.05
Finish:    Transparent glass with refraction
```

### Displays

```
Color:     ███ Very Dark Blue (0.05, 0.05, 0.1)
Metallic:  █░░░░░░░░░ 0.1
Roughness: █████████░ 0.9
Emission:  ░░█ Blue (0.2, 0.4, 0.8) @ 1.5x
Finish:    Matte screen with blue glow
```

### Controls (Levers, Dials)

```
Color:     ███ Medium Gray (0.25, 0.25, 0.28)
Metallic:  ███████░░░ 0.7
Roughness: ████░░░░░░ 0.4
Finish:    Semi-gloss metal
```

### Buttons (Power - Green)

```
Color:     ░█░ Green (0.1, 0.8, 0.2)
Metallic:  ██████░░░░ 0.6
Roughness: ███░░░░░░░ 0.3
Emission:  ░█░ Green (0.0, 0.5, 0.1) @ 0.5x
Finish:    Glossy with green glow
```

### Buttons (Emergency/Signal - Red)

```
Color:     █░░ Red (0.8, 0.1, 0.1)
Metallic:  ██████░░░░ 0.6
Roughness: ███░░░░░░░ 0.3
Emission:  █░░ Red (0.5, 0.0, 0.0) @ 0.5x
Finish:    Glossy with red glow
```

### Buttons (Nav/Landing - Blue)

```
Color:     ░░█ Blue (0.1, 0.4, 0.9)
Metallic:  ██████░░░░ 0.6
Roughness: ███░░░░░░░ 0.3
Emission:  ░░█ Blue (0.0, 0.2, 0.6) @ 0.5x
Finish:    Glossy with blue glow
```

## Lighting Setup

### Display Lights (OmniLight3D)

```
Position: Above each display
Color:    ░░█ Blue-White (0.3, 0.6, 1.0)
Energy:   ████░░░░░░ 0.4-0.5
Range:    ████░░░░░░ 0.25-0.3m
Purpose:  Illuminate displays, create glow effect
```

### Control Lights (SpotLight3D)

```
Position: Above control areas
Color:    ███ Cool White (0.9, 0.9, 1.0)
Energy:   ███░░░░░░░ 0.3
Range:    █████░░░░░ 0.5m
Angle:    ███░░░░░░░ 30°
Purpose:  Highlight interactive controls
```

### Ambient Light (OmniLight3D)

```
Position: Center ceiling
Color:    ███ Soft White (0.8, 0.85, 0.9)
Energy:   ███░░░░░░░ 0.3
Range:    ██████████ 2.0m
Purpose:  General cockpit illumination
```

## Interactive Controls

### 1. Throttle Lever

```
Type:     CapsuleMesh (vertical lever)
Position: Left side of dashboard
Size:     0.02m radius, 0.18m height
Material: Gray metallic
Function: Engine thrust control (0-100%)
Animation: Moves up/down with value
Range:    15cm interaction distance
```

### 2. Power Button

```
Type:     CylinderMesh (push button)
Position: Center of dashboard
Size:     0.04m radius, 0.025m height
Material: Green emissive
Function: Main power toggle
Animation: Presses down on activation
Range:    15cm interaction distance
```

### 3. Navigation Mode Switch

```
Type:     CylinderMesh (toggle button)
Position: Right of center
Size:     0.04m radius, 0.025m height
Material: Blue emissive
Function: Toggle navigation modes
Animation: Toggle state change
Range:    15cm interaction distance
```

### 4. Time Acceleration Dial

```
Type:     TorusMesh (rotary dial)
Position: Left-center of dashboard
Size:     0.03m inner, 0.05m outer radius
Material: Gray metallic
Function: Control simulation time speed
Animation: Rotates 0-360° with value
Range:    15cm interaction distance
```

### 5. Signal Boost Button

```
Type:     CylinderMesh (push button)
Position: Right-center of dashboard
Size:     0.04m radius, 0.025m height
Material: Red emissive
Function: Boost signal strength
Animation: Presses down on activation
Range:    15cm interaction distance
```

### 6. Emergency Button

```
Type:     CylinderMesh (push button)
Position: Far left panel
Size:     0.04m radius, 0.025m height
Material: Red emissive
Function: Emergency stop/reset
Animation: Presses down on activation
Range:    15cm interaction distance
```

### 7. Landing Gear Button

```
Type:     CylinderMesh (push button)
Position: Far right panel
Size:     0.04m radius, 0.025m height
Material: Blue emissive
Function: Deploy/retract landing gear
Animation: Presses down on activation
Range:    15cm interaction distance
```

## Display Content Examples

### Main Display (Center)

```
┌─────────────────────────────┐
│ SPACECRAFT TELEMETRY        │
│                             │
│ Time: 2451545.0 J2000       │
│ Time Scale: 1.0x            │
│                             │
│ Speed: 125.3 u/s            │
│ Light Speed: 0.04%          │
└─────────────────────────────┘
```

### Left Display (Navigation)

```
┌─────────────────────────────┐
│ NAVIGATION                  │
│                             │
│ Position:                   │
│ X: 1234.5                   │
│ Y: 6789.0                   │
│ Z: -456.7                   │
│                             │
│ Velocity:                   │
│ X: 12.3                     │
│ Y: 45.6                     │
│ Z: -7.8                     │
└─────────────────────────────┘
```

### Right Display (Systems)

```
┌─────────────────────────────┐
│ SIGNAL STATUS               │
│                             │
│ SNR: 95.2%                  │
│ Entropy: 0.15               │
│                             │
│ Status: OPTIMAL             │
└─────────────────────────────┘
```

## Dimensions and Scale

### Overall Cockpit

- Width: 2.5m (dashboard)
- Depth: 1.2m (front to back)
- Height: 1.8m (floor to canopy)
- Seat Height: 0.4m
- Pilot Eye Level: 1.6m (seated)

### Dashboard

- Width: 2.5m
- Depth: 1.2m
- Thickness: 0.08m
- Angle: Slight tilt toward pilot

### Displays

- Main: 0.4m × 0.3m
- Side: 0.25m × 0.2m
- Distance from pilot: ~0.5m
- Viewing angle: ~30° down

### Controls

- Button diameter: 0.08m
- Lever height: 0.18m
- Dial diameter: 0.10m
- Spacing: 0.15-0.25m between controls

## Color Palette

### Primary Colors

```
Dashboard:     #262629 (Dark Gray)
Frame:         #4D4D52 (Light Gray)
Glass:         #4D8099 (Blue-Green, transparent)
Seat:          #333338 (Dark Gray)
```

### Display Colors

```
Background:    #0D0D1A (Very Dark Blue)
Text:          #4DCCFF (Cyan)
Emission:      #3366CC (Blue)
```

### Button Colors

```
Power:         #1ACC33 (Green)
Emergency:     #CC1A1A (Red)
Signal:        #CC1A1A (Red)
Navigation:    #1A66E6 (Blue)
Landing:       #1A66E6 (Blue)
```

### Lighting Colors

```
Display Light: #4D99FF (Blue-White)
Control Light: #E6E6FF (Cool White)
Ambient Light: #CCD9E6 (Soft White)
```

## VR Interaction Zones

### Interaction Range

```
     [VR Controller]
           |
           | 15cm max
           ▼
      [Control Area]
     ┌─────────────┐
     │  BoxShape3D │
     │  0.1×0.1×0.1│
     └─────────────┘
```

### Collision Configuration

- Layer: 0 (no layer)
- Mask: 1 (detects layer 1)
- Shape: Box (10cm cube)
- Trigger: On controller overlap

## Performance Metrics

### Polygon Count

```
Dashboard:     200 tris
Panels:        600 tris (3 panels)
Console:       200 tris
Seat:          200 tris
Displays:      600 tris (3 displays)
Controls:      1,400 tris (7 controls)
Canopy:        200 tris
Lights:        0 tris (light sources)
Areas:         0 tris (collision only)
─────────────────────────
Total:         ~5,000 tris
```

### Draw Calls

```
Dashboard:     1 call
Panels:        3 calls
Displays:      3 calls
Controls:      7 calls
Canopy:        1 call
Lights:        6 calls (no geometry)
─────────────────────────
Total:         15-20 calls
```

### Memory Usage

```
Mesh Data:     ~200 KB
Materials:     ~50 KB
Textures:      0 KB (procedural)
─────────────────────────
Total:         ~250 KB
```

## Animation States

### Throttle Lever

```
Value 0.0:  ▼ (down)
Value 0.5:  ─ (middle)
Value 1.0:  ▲ (up)
```

### Time Dial

```
Value 0.0:  ○ (0°)
Value 0.25: ◔ (90°)
Value 0.5:  ◑ (180°)
Value 0.75: ◕ (270°)
Value 1.0:  ○ (360°)
```

### Buttons

```
Idle:       ⚫ (normal)
Hovered:    ⚪ (highlighted)
Pressed:    ⚫ (pressed down)
```

## Conclusion

This visual reference provides a comprehensive overview of the spacecraft cockpit model's layout, materials, controls, and specifications. The cockpit is designed for comfortable VR interaction with clear visual hierarchy and intuitive control placement.
