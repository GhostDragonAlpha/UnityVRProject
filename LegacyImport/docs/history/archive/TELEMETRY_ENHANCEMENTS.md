# Scene Inspector Telemetry Enhancements

## Overview
Enhanced the scene inspector with comprehensive telemetry for better debugging. Added detailed player metrics, physics reports, and input state tracking.

## Changes Made

### 1. godot_bridge.gd - Enhanced Scene Inspector

#### New Player Telemetry Fields (in `/state/scene` endpoint)

Added to the player report:
- **rotation**: Player orientation as Euler angles (basis.get_euler())
- **speed**: Player velocity magnitude in m/s
- **distance_to_planet_center**: Distance from player to planet center
- **current_chunk_position**: Current voxel terrain chunk position (if applicable)
- **physics_state**: Current physics state (sleeping/active/character_body/static)
- **input_state**: Dictionary of currently pressed input actions
- **nearby_objects_10m**: Count of physics objects within 10m radius

#### New Endpoint: POST /state/physics

Provides detailed physics report including:
- **fps**: Current frames per second
- **physics_tick_rate**: Physics simulation tick rate
- **physics_space_exists**: Whether physics world is initialized
- **gravity_at_player**: Gravity vector at player position
- **rigidbodies**: Array of all RigidBody3D objects with:
  - name, position, velocity, speed, angular_velocity, mass, is_sleeping
- **character_bodies**: Array of all CharacterBody3D objects with:
  - name, position, velocity, speed, is_on_floor, is_on_wall, is_on_ceiling
- **active_collision_shapes**: Total count of active collision shapes
- **rigidbody_count**: Total RigidBody3D count
- **character_body_count**: Total CharacterBody3D count

#### New Helper Functions

1. **_get_player_physics_state(player: Node) -> String**
   - Returns physics state: "sleeping", "active", "character_body", "static", or "unknown"

2. **_get_current_input_state() -> Dictionary**
   - Checks these input actions: move_forward, move_backward, move_left, move_right, jump, sprint, interact, trigger_click, grip_click, menu, pause
   - Returns dictionary with action names as keys and pressed state as values

3. **_count_nearby_objects(from_node: Node3D, radius: float) -> int**
   - Counts physics objects within specified radius of player
   - Uses fallback method if "physics_objects" group is empty

4. **_find_all_nodes_of_type(node_type) -> Array**
   - Recursively finds all nodes of a specific type in the scene tree
   - Used to collect RigidBody3D and CharacterBody3D nodes for physics report

### 2. quick_diagnostic.py - Enhanced Diagnostic Display

#### New Display Fields

Scene report now displays:
- **Speed**: Velocity magnitude in m/s (formatted to 2 decimals)
- **Rotation (Euler)**: Player rotation angles
- **Distance to Planet Center**: Distance in meters
- **Current Chunk Position**: Voxel terrain chunk coordinates
- **Physics State**: Current physics body state
- **Nearby Objects (10m radius)**: Count of nearby physics objects
- **Active Inputs**: List of currently pressed input actions

#### New Physics Report Display

Added separate physics report section showing:
- Physics tick rate and gravity
- List of active RigidBody3D objects (first 5) with speed and sleeping state
- List of active CharacterBody3D objects (first 5) with speed and floor contact
- Total active collision shapes

#### New Function: get_physics_report()

Fetches physics telemetry from `/state/physics` endpoint with timeout handling.

#### New Function: print_physics_report()

Formats and displays physics report with organized sections.

## Usage

### Fetch Enhanced Scene Data
```bash
curl http://127.0.0.1:8080/state/scene
```

### Fetch Physics Report
```bash
curl http://127.0.0.1:8080/state/physics
```

### Run Diagnostic with Enhanced Display
```bash
python quick_diagnostic.py
```

## API Response Examples

### /state/scene Response (Player Section)
```json
{
  "player": {
    "found": true,
    "name": "Player",
    "type": "CharacterBody3D",
    "position": [100.0, 50.0, 200.0],
    "velocity": [5.0, 0.0, 3.0],
    "speed": 5.83,
    "rotation": [0.0, 1.57, 0.0],
    "on_floor": true,
    "gravity": 9.8,
    "gravity_dir": [0.0, -1.0, 0.0],
    "current_planet": "Earth",
    "distance_to_planet_center": 6371000.0,
    "current_chunk_position": [10, 5, 8],
    "physics_state": "active",
    "jetpack_fuel": 75.5,
    "input_state": {
      "move_forward": true,
      "move_backward": false,
      "jump": false,
      "sprint": true
    },
    "nearby_objects_10m": 3
  }
}
```

### /state/physics Response
```json
{
  "timestamp": 1234567890,
  "fps": 90,
  "physics_tick_rate": 90,
  "physics_space_exists": true,
  "gravity_at_player": [0.0, -9.8, 0.0],
  "rigidbodies": [
    {
      "name": "Rock",
      "position": [105.0, 40.0, 205.0],
      "velocity": [0.0, 0.0, 0.0],
      "speed": 0.0,
      "angular_velocity": [0.0, 0.0, 0.0],
      "mass": 5.0,
      "is_sleeping": true
    }
  ],
  "character_bodies": [
    {
      "name": "Player",
      "position": [100.0, 50.0, 200.0],
      "velocity": [5.0, 0.0, 3.0],
      "speed": 5.83,
      "is_on_floor": true,
      "is_on_wall": false,
      "is_on_ceiling": false
    }
  ],
  "active_collision_shapes": 12,
  "rigidbody_count": 5,
  "character_body_count": 1
}
```

## Implementation Details

### Backward Compatibility
- All enhancements are additive - existing API responses are unchanged
- New fields are only added when data is available
- Helper functions only execute if needed by the telemetry queries

### Performance Considerations
- Physics report uses cached node lookups with fallback searching
- Input state only checks InputMap actions that exist
- Nearby object counting uses distance-based filtering
- Physics data collection only iterates active scene nodes

### Error Handling
- Missing properties default to "N/A" in displays
- Null/invalid physics objects are skipped
- Gravity calculation handles both Vector3 and numeric values
- All helper functions include safe type checking

## Files Modified
1. `C:/godot/addons/godot_debug_connection/godot_bridge.gd` - Main telemetry implementation
2. `C:/godot/quick_diagnostic.py` - Enhanced diagnostic display

## Testing
Run the diagnostic to verify:
```bash
python quick_diagnostic.py
```

Both scene and physics reports should display with all new fields visible.
