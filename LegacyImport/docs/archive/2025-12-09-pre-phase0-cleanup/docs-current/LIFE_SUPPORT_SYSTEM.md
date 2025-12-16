# Life Support System

Complete documentation for the SpaceTime VR life support and oxygen depletion system.

## Overview

The Life Support System manages player vitals (oxygen, hunger, thirst) with activity-based depletion rates, environmental hazards, and pressurized area detection.

## Key Features

### 1. Activity-Based Oxygen Depletion

Oxygen depletes at different rates based on player activity:

| Activity | Multiplier | Depletion Rate |
|----------|-----------|----------------|
| Idle     | 1.0x      | 1.0% / second  |
| Walking  | 1.5x      | 1.5% / second  |
| Sprinting| 2.0x      | 2.0% / second  |
| Jetpack  | 3.0x      | 3.0% / second  |

### 2. Warning Thresholds

Multi-level warning system:

- **25% - WARNING**: Initial low oxygen alert
- **20% - LOW**: Increased alert frequency
- **10% - CRITICAL**: Screen vignette effect, urgent warnings
- **0% - SUFFOCATING**: Active health damage (10% SNR/second)

### 3. Pressurized Environments

Oxygen depletion stops and regenerates in pressurized areas:

- **Regeneration Rate**: 5% per second
- **Detection**: Automatic when inside sealed base modules

## HTTP API Endpoints

### GET /life_support/status

Get current life support status and all vitals.

### POST /life_support/set_oxygen

Set oxygen level (for testing). Body: `{"oxygen": 50.0}`

### POST /life_support/set_activity

Set activity multiplier. Body: `{"activity_multiplier": 2.0}`

### POST /life_support/damage

Apply damage to player. Body: `{"damage": 10.0, "damage_type": "suffocation"}`

### POST /life_support/set_pressurized

Set pressurized area status. Body: `{"pressurized": true}`

## Testing

Property-based tests are in `C:/godot/tests/property/test_oxygen_depletion.py`

Run tests:
```bash
cd tests/property
python -m pytest test_oxygen_depletion.py -v
```

## Requirements Met

- 7.1: Oxygen depletion based on activity level
- 7.2: Warning at 25% oxygen
- 7.3: Suffocation damage at 0% oxygen
- 7.4: Halt oxygen depletion in pressurized areas
- 7.5: Oxygen regeneration in pressurized areas
- 9.1: Activity-based depletion rates
- 9.2: Warning system (LOW and CRITICAL)
- 9.3: Suffocation damage effects
- 9.4: HTTP API endpoints

## Files

- `scripts/planetary_survival/systems/life_support_system.gd` - Core system
- `addons/godot_debug_connection/godot_bridge.gd` - HTTP API endpoints
- `tests/property/test_oxygen_depletion.py` - Property tests
