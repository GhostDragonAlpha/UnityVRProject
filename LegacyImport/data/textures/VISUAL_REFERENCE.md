# Texture Visual Reference Guide

## Overview

This document provides visual descriptions and reference guidelines for creating or sourcing textures for Project Resonance. Use these descriptions when searching for textures or creating them procedurally.

## Spacecraft Textures

### Hull Exterior

**Visual Style**: Industrial sci-fi, worn but functional, space-weathered

**Color Palette**:

- Base: Dark gray-blue (#333A40)
- Highlights: Lighter gray (#4A5158)
- Shadows: Very dark blue-gray (#1A1D20)
- Accents: Subtle blue tint

**Surface Details**:

- Panel lines: 2-5cm wide, recessed 0.5-1cm
- Rivets: 1cm diameter, 10cm spacing, raised 0.2cm
- Scratches: Random, various lengths, concentrated on edges
- Scuffs: Lighter areas where paint is worn
- Micro-dents: Small impact marks from space debris
- Weathering: Subtle color variation, darker in crevices

**Material Properties**:

- Metallic: 0.9 (highly metallic)
- Roughness: 0.3 base, 0.5-0.7 in worn areas
- Reflectivity: High, with Fresnel falloff

**Reference Images**:

- SpaceX Starship exterior
- ISS module exteriors
- Sci-fi spacecraft from "The Expanse"
- Industrial metal panels

### Glass Canopy

**Visual Style**: Futuristic, slightly tinted, crystal clear

**Color Palette**:

- Base: Transparent with blue-green tint (#4D8099, 20% opacity)
- Edge tint: Stronger at thick edges (60% opacity)
- Reflections: Sky blue highlights

**Surface Details**:

- Very subtle scratches (barely visible)
- Occasional smudges (fingerprints, dust)
- Edge thickness variation
- Internal lamination lines (very subtle)

**Material Properties**:

- Metallic: 0.95 (very reflective)
- Roughness: 0.02 (extremely smooth)
- Transparency: 80% base, 40% at edges
- Refraction: Subtle (IOR 1.5)

**Reference Images**:

- Fighter jet canopies (F-22, F-35)
- Helicopter windscreens
- High-end automotive glass
- Architectural glass facades

### Cockpit Interior

**Visual Style**: High-tech military, functional, well-maintained

**Color Palette**:

- Base: Dark gray (#262629)
- Panels: Medium gray (#3A3A40)
- Buttons: Various (red, green, blue emissive)
- Labels: White or cyan text

**Surface Details**:

- Button labels and icons
- Panel seams (1-2mm wide)
- Fastener heads (screws, bolts)
- Wear on frequently-touched areas
- Subtle brushed metal texture
- Display bezels

**Material Properties**:

- Metallic: 0.85 (highly metallic)
- Roughness: 0.25 base, 0.4-0.6 on worn areas
- Emission: Buttons and displays glow

**Reference Images**:

- Fighter jet cockpits (F-16, F-18)
- Spacecraft interiors (SpaceX Dragon, Boeing Starliner)
- High-tech control rooms
- Sci-fi cockpits from "Elite Dangerous"

## Planetary Surface Textures

### Terrestrial (Rocky) Planets

**Visual Style**: Mars-like, varied terrain, ancient

**Color Palette**:

- Primary: Rust red (#A0522D)
- Secondary: Dark brown (#654321)
- Tertiary: Gray (#808080)
- Highlights: Light tan (#D2B48C)

**Surface Details**:

- Rock formations (various sizes)
- Crater impacts (circular depressions)
- Dust and fine regolith
- Cracks and fissures
- Layered sediment
- Boulder fields

**Material Properties**:

- Metallic: 0.0 (non-metallic)
- Roughness: 0.6-0.9 (very rough)
- Height variation: 0-50cm

**Reference Images**:

- Mars surface (HiRISE imagery)
- Moon surface (Apollo missions)
- Desert rock formations (Utah, Arizona)
- Volcanic rock fields

### Ice Worlds

**Visual Style**: Europa-like, frozen, cracked

**Color Palette**:

- Primary: White (#FFFFFF)
- Secondary: Light blue (#B0E0E6)
- Tertiary: Pale cyan (#E0FFFF)
- Shadows: Blue-gray (#708090)

**Surface Details**:

- Ice cracks (chaotic patterns)
- Pressure ridges
- Smooth ice plains
- Rough ice chunks
- Snow accumulation
- Subsurface color variation

**Material Properties**:

- Metallic: 0.0 (non-metallic)
- Roughness: 0.1 (smooth ice) to 0.8 (rough snow)
- Height variation: 0-30cm
- Subsurface scattering: Yes (shader-based)

**Reference Images**:

- Europa surface (Galileo mission)
- Antarctica ice sheets
- Greenland glaciers
- Arctic sea ice

### Desert Worlds

**Visual Style**: Dune-like, sandy, windswept

**Color Palette**:

- Primary: Sand yellow (#EDC9AF)
- Secondary: Light orange (#FFB347)
- Tertiary: Tan (#D2B48C)
- Shadows: Dark brown (#8B4513)

**Surface Details**:

- Sand dunes (large wave patterns)
- Wind ripples (small parallel lines)
- Rock outcroppings
- Dust accumulation
- Occasional vegetation (dead)
- Erosion patterns

**Material Properties**:

- Metallic: 0.0 (non-metallic)
- Roughness: 0.7 (fine sand)
- Height variation: 0-100cm (dunes)

**Reference Images**:

- Sahara Desert
- Arabian Desert
- Mars sand dunes
- Death Valley

### Volcanic Worlds

**Visual Style**: Io-like, active, dramatic

**Color Palette**:

- Primary: Dark gray/black (#2F4F4F)
- Secondary: Charcoal (#36454F)
- Emission: Orange-red lava (#FF4500)
- Highlights: Sulfur yellow (#FFFF00)

**Surface Details**:

- Cooled lava flows (ropy texture)
- Glowing lava cracks
- Volcanic cones
- Ash deposits
- Rough basalt
- Steam vents

**Material Properties**:

- Metallic: 0.0 (non-metallic)
- Roughness: 0.9 (very rough)
- Emission: Glowing cracks (orange-red)
- Height variation: 0-200cm

**Reference Images**:

- Io surface (Voyager, Galileo)
- Hawaii lava fields
- Iceland volcanic terrain
- Mount Etna

### Ocean Worlds

**Visual Style**: Earth-like, dynamic, alive

**Color Palette**:

- Primary: Deep blue (#000080)
- Secondary: Cyan (#00FFFF)
- Tertiary: Turquoise (#40E0D0)
- Foam: White (#FFFFFF)

**Surface Details**:

- Wave patterns (animated)
- Foam and whitecaps
- Underwater visibility (gradient)
- Caustics (light patterns)
- Ripples and disturbances
- Depth variation (color)

**Material Properties**:

- Metallic: 0.0 (non-metallic)
- Roughness: 0.1 (smooth water)
- Transparency: Varies with depth
- Refraction: Yes (IOR 1.33)

**Reference Images**:

- Ocean surface photography
- Underwater scenes
- Wave simulations
- Tropical waters

### Gas Giants

**Visual Style**: Jupiter-like, banded, stormy

**Color Palette**:

- Bands: Alternating light and dark
- Jupiter-style: Tan, brown, white, red
- Saturn-style: Pale yellow, cream
- Neptune-style: Deep blue, cyan

**Surface Details**:

- Atmospheric bands (horizontal)
- Storm systems (circular, oval)
- Turbulent boundaries
- Cloud layers (depth)
- Lightning (emission)
- Vortices and eddies

**Material Properties**:

- Metallic: 0.0 (non-metallic)
- Roughness: 0.3 (smooth clouds)
- Emission: Lightning flashes
- Animated: Yes (shader-based)

**Reference Images**:

- Jupiter (Juno mission)
- Saturn (Cassini mission)
- Neptune (Voyager 2)
- Uranus (Voyager 2)

## Space Environment Textures

### Nebulae

**Visual Style**: Ethereal, colorful, wispy

**Color Palette**:

- Blue emission: Oxygen (#0080FF)
- Red emission: Hydrogen (#FF0040)
- Purple reflection: Mixed (#8000FF)
- Green planetary: Oxygen (#00FF40)

**Structure**:

- Wispy tendrils
- Dense cores
- Transparent edges
- Layered depth
- Star formation regions
- Dark dust lanes

**Material Properties**:

- Volumetric: 3D density field
- Emission: Self-illuminating
- Transparency: Varies with density
- Scattering: Light interaction

**Reference Images**:

- Orion Nebula (Hubble)
- Carina Nebula (Hubble)
- Eagle Nebula (Hubble)
- Helix Nebula (Hubble)

### Star Fields

**Visual Style**: Realistic, accurate, immersive

**Color Palette**:

- Star colors: Blue, white, yellow, orange, red
- Milky Way: Pale blue-white band
- Background: Black (#000000)

**Structure**:

- Point stars (various sizes)
- Accurate positions (Hipparcos/Gaia)
- Magnitude variation
- Color variation (spectral types)
- Milky Way galactic plane
- Star clusters

**Material Properties**:

- Emission: Self-illuminating
- Bloom: Bright stars glow
- Cubemap: 360° coverage

**Reference Images**:

- Stellarium screenshots
- Astrophotography
- Hubble deep field
- Milky Way panoramas

### Lattice Grid

**Visual Style**: Sci-fi, glowing, geometric

**Color Palette**:

- Primary: Cyan (#00FFFF)
- Secondary: Magenta (#FF00FF)
- Glow: Bright white core
- Background: Transparent

**Structure**:

- Regular grid pattern
- Glowing lines
- Intersection points
- Pulse animation
- Gravity well distortion
- Doppler shift coloring

**Material Properties**:

- Emission: Self-illuminating
- Transparency: Lines only, rest transparent
- Animated: Pulse and flow

**Reference Images**:

- Tron grid
- Wireframe visualizations
- Holographic displays
- Sci-fi UI grids

## UI and Effect Textures

### Icons

**Visual Style**: Clean, high-contrast, readable in VR

**Design Guidelines**:

- Simple shapes
- Bold outlines
- High contrast (white on dark or vice versa)
- No fine details
- Recognizable at small sizes
- Consistent style

**Color Palette**:

- Primary: White (#FFFFFF)
- Background: Dark gray (#202020)
- Accents: Cyan (#00FFFF) or orange (#FF8000)

**Reference Images**:

- Material Design icons
- iOS system icons
- VR interface icons
- Sci-fi game UIs

### Particle Textures

**Visual Style**: Varied based on effect type

**Smoke/Exhaust**:

- Wispy, organic shapes
- Grayscale with alpha
- Soft edges
- Varied density

**Sparks**:

- Bright streaks
- Sharp edges
- Orange-yellow glow
- Motion blur

**Glow**:

- Radial gradient
- Soft falloff
- Bright center
- Transparent edges

**Dust**:

- Small particles
- Irregular shapes
- Low opacity
- Varied sizes

## Texture Creation Tips

### Making Textures Tileable

1. Use offset method (50% width/height)
2. Clone stamp seams
3. Verify by tiling 2x2
4. Check at distance (mipmaps)

### Creating Normal Maps

1. Start with height map
2. Use normal map generator
3. Adjust strength (5-10 typical)
4. Verify lighting response

### Creating Roughness Maps

1. Convert albedo to grayscale
2. Adjust contrast
3. Paint smooth/rough areas
4. Blur slightly for transitions

### Creating Metallic Maps

1. Binary approach (0 or 1)
2. Paint metallic areas white
3. Paint non-metallic black
4. Sharp transitions OK

## Quality Checklist

For each texture, verify:

- [ ] Correct resolution (4K for close-up)
- [ ] Proper color space (sRGB or Linear)
- [ ] Tileable (if required)
- [ ] No visible seams
- [ ] Appropriate detail level
- [ ] Realistic material properties
- [ ] Good contrast and readability
- [ ] Optimized file size
- [ ] Tested in-engine
- [ ] Tested in VR

## Conclusion

Use these visual references as guidelines when sourcing or creating textures. The goal is photorealistic quality while maintaining VR performance. When in doubt, reference real-world imagery and adjust for the sci-fi aesthetic.
