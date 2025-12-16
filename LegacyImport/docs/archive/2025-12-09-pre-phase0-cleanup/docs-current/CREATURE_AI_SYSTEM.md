# Creature AI System Documentation

## Overview

The Creature AI System provides a flexible, behavior-tree-based AI framework for creating intelligent creatures in SpaceTime. The system includes creature data management, behavior trees, and HTTP API integration for remote control and testing.

## Architecture

### Core Components

1. **CreatureData** (`scripts/gameplay/creature_data.gd`)
   - Resource class defining creature stats and behavior
   - Supports 4 creature types: PASSIVE, NEUTRAL, AGGRESSIVE, TAMEABLE
   - Configurable health, movement, attack, and detection parameters

2. **BehaviorTree** (`scripts/gameplay/behavior_tree.gd`)
   - Composable behavior tree system
   - Node types: SEQUENCE, SELECTOR, CONDITION, ACTION
   - Provides predefined common behaviors

3. **CreatureAI** (`scripts/gameplay/creature_ai.gd`)
   - CharacterBody3D-based AI controller
   - Executes behavior tree each frame
   - Handles movement, combat, detection, state management

## Creature Types

### PASSIVE (Type 0)
- **Behavior**: Always flees from player
- **Example**: Space Rabbit
- **Use Case**: Harmless ambient creatures

### NEUTRAL (Type 1)
- **Behavior**: Ignores player unless attacked
- **Example**: Crystal Crawler
- **Use Case**: Defensive creatures

### AGGRESSIVE (Type 2)
- **Behavior**: Actively detects and attacks player
- **Example**: Alien Predator
- **Use Case**: Hostile enemies

### TAMEABLE (Type 3)
- **Behavior**: Similar to neutral, but can be tamed (future feature)
- **Use Case**: Companion creatures

## Behavior Tree System

### Node Types

**SEQUENCE**: Execute children in order, fail if any fails
```gdscript
var sequence = BehaviorTree.create_sequence("AttackSequence")
sequence.add_child(target_in_range_condition)
sequence.add_child(can_attack_condition)
sequence.add_child(attack_action)
```

**SELECTOR**: Try children until one succeeds
```gdscript
var selector = BehaviorTree.create_selector("RootBehavior")
selector.add_child(dead_behavior)
selector.add_child(flee_behavior)
selector.add_child(attack_behavior)
selector.add_child(wander_action)
```

**CONDITION**: Boolean check
```gdscript
var condition = BehaviorTree.create_condition(
    func(c): return c.current_health < 30,
    "LowHealth"
)
```

**ACTION**: Execute action
```gdscript
var action = BehaviorTree.create_action(
    func(c): c.perform_attack(),
    "Attack"
)
```

### Predefined Behaviors

**Conditions:**
- `is_dead_condition()` - Check if creature is dead
- `target_in_range_condition(range_type)` - Check if target in range
- `health_below_threshold_condition(threshold)` - Check health percentage
- `can_attack_condition()` - Check if attack cooldown ready

**Actions:**
- `do_nothing_action()` - Idle (for dead state)
- `attack_action()` - Perform attack on target
- `chase_action()` - Move towards target
- `flee_action()` - Run away from target
- `wander_action()` - Random movement
- `detect_player_action()` - Scan for player

## AI State Machine

### States

1. **IDLE** - Standing still, no target
2. **WANDER** - Random movement
3. **CHASE** - Pursuing target
4. **ATTACK** - Attacking target
5. **FLEE** - Running from target
6. **DEAD** - Creature defeated

### State Transitions

Behavior tree determines state transitions each frame:
- Dead creatures do nothing
- Low health triggers flee (aggressive types)
- Target in attack range triggers attack
- Target detected triggers chase
- No target triggers wander

## Core AI Methods

### Detection

```gdscript
func detect_player() -> bool
```
- Checks distance within `detection_range`
- Performs line-of-sight raycast
- Sets `current_target` if player visible

### Movement

```gdscript
func move_towards_target(target: Node3D)
```
- Calculates direction to target
- Applies movement with `movement_speed`
- Rotates to face target

```gdscript
func flee_from_target(target: Node3D)
```
- Moves away from target at 1.5x speed

```gdscript
func wander()
```
- Random direction changes every 1-3 seconds
- Moves at 0.5x speed

### Combat

```gdscript
func perform_attack()
```
- Deals `attack_damage` to target
- Applies `attack_cooldown`
- Emits `creature_attacked` signal

```gdscript
func take_damage(amount: float, source: Node3D)
```
- Reduces health
- Neutral creatures become aggressive when attacked
- Triggers death at 0 health
- Emits `creature_damaged` signal

```gdscript
func die()
```
- Sets state to DEAD
- Disables collision
- Emits `creature_died` signal
- Removes after 5 seconds

## HTTP API Integration

The creature system integrates with GodotBridge HTTP API for remote control and testing.

### Endpoints

#### POST /creatures/spawn
Spawn a creature at a specific position.

**Request:**
```json
{
  "creature_type": "space_rabbit",
  "position": [10.0, 2.0, 5.0]
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Creature spawned successfully",
  "creature_id": "space_rabbit_1234567890",
  "creature_type": "space_rabbit",
  "position": [10.0, 2.0, 5.0],
  "stats": {
    "name": "Space Rabbit",
    "health": 50.0,
    "max_health": 50.0,
    "state": "IDLE",
    ...
  }
}
```

#### GET /creatures/list
List all active creatures in the scene.

**Response:**
```json
{
  "status": "success",
  "count": 3,
  "creatures": [
    {
      "creature_id": "space_rabbit_1234567890",
      "creature_type": "Space Rabbit",
      "position": [10.0, 2.0, 5.0],
      "state": "WANDER",
      "health": 50.0,
      "max_health": 50.0,
      "health_percent": 100.0,
      "has_target": false
    },
    ...
  ]
}
```

#### POST /creatures/damage
Apply damage to a creature.

**Request:**
```json
{
  "creature_id": "space_rabbit_1234567890",
  "damage": 25.0
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Damage applied",
  "creature_id": "space_rabbit_1234567890",
  "damage": 25.0,
  "remaining_health": 25.0,
  "is_dead": false
}
```

#### GET /creatures/ai_state
Get detailed AI state for creatures.

**Query Parameters:**
- `creature_id` (optional) - Specific creature ID

**Response (single creature):**
```json
{
  "status": "success",
  "creature": {
    "name": "Space Rabbit",
    "health": 50.0,
    "max_health": 50.0,
    "health_percent": 100.0,
    "state": "CHASE",
    "has_target": true,
    "position": {"x": 10.0, "y": 2.0, "z": 5.0},
    "velocity": {"x": 2.5, "y": 0.0, "z": 1.5}
  }
}
```

**Response (all creatures):**
```json
{
  "status": "success",
  "count": 2,
  "creatures": [...]
}
```

#### POST /creatures/despawn
Remove a creature from the scene.

**Request:**
```json
{
  "creature_id": "space_rabbit_1234567890"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Creature despawned",
  "creature_id": "space_rabbit_1234567890"
}
```

## Creating Custom Creatures

### Step 1: Create Creature Data Resource

Create a new `.tres` file in `data/creatures/`:

```gdscript
[gd_resource type="Resource" script_class="CreatureData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/gameplay/creature_data.gd" id="1"]

[resource]
script = ExtResource("1")
creature_name = "My Creature"
creature_type = 2  # AGGRESSIVE
max_health = 100.0
movement_speed = 3.5
attack_damage = 20.0
detection_range = 15.0
attack_range = 2.0
attack_cooldown = 1.0
spawn_biomes = ["desert", "plains"]
model_scale = 1.2
xp_reward = 20
loot_items = ["item1", "item2"]
```

### Step 2: Create Custom Behavior Tree (Optional)

Override `create_behavior_tree()` in a custom subclass:

```gdscript
extends CreatureAI
class_name MyCustomCreature

func create_behavior_tree() -> BehaviorTree:
    var tree = BehaviorTree.new()
    var root = BehaviorTree.create_selector("Root")

    # Custom behavior logic
    root.add_child(my_custom_behavior())
    root.add_child(BehaviorTree.wander_action())

    tree.root = root
    return tree
```

### Step 3: Spawn via API or Scene

**Via HTTP API:**
```bash
curl -X POST http://127.0.0.1:8080/creatures/spawn \
  -H "Content-Type: application/json" \
  -d '{"creature_type": "my_creature", "position": [0, 2, 0]}'
```

**Via Scene:**
```gdscript
var creature = CreatureAI.new()
creature.creature_data = preload("res://data/creatures/my_creature.tres")
creature.global_position = Vector3(0, 2, 0)
add_child(creature)
```

## Example Creatures

### Space Rabbit (PASSIVE)
- **Stats**: 50 HP, 5 damage, 5 m/s
- **Behavior**: Flees from player
- **Spawns**: Grassland, plains, forest
- **File**: `data/creatures/space_rabbit.tres`

### Crystal Crawler (NEUTRAL)
- **Stats**: 80 HP, 15 damage, 2.5 m/s
- **Behavior**: Neutral until attacked
- **Spawns**: Crystal caves, mountains
- **File**: `data/creatures/crystal_crawler.tres`

### Alien Predator (AGGRESSIVE)
- **Stats**: 150 HP, 25 damage, 4 m/s
- **Behavior**: Actively hunts player
- **Spawns**: Mountains, caves, desert
- **File**: `data/creatures/alien_predator.tres`

## Testing

### Test Scene

Load the test scene at `scenes/creature_test.tscn`:
- Includes ground platform
- Spawns a Space Rabbit
- Camera positioned for observation

### Manual Testing

1. Start Godot with debug services:
```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

2. Spawn creatures via API:
```bash
curl -X POST http://127.0.0.1:8080/creatures/spawn \
  -H "Content-Type: application/json" \
  -d '{"creature_type": "alien_predator", "position": [5, 2, 0]}'
```

3. Monitor creature state:
```bash
curl http://127.0.0.1:8080/creatures/list
```

4. Test damage:
```bash
curl -X POST http://127.0.0.1:8080/creatures/damage \
  -H "Content-Type: application/json" \
  -d '{"creature_id": "alien_predator_1234567890", "damage": 50}'
```

### Automated Testing

Use the telemetry client to monitor creature events:
```bash
python telemetry_client.py
```

Look for `creature_update` events with real-time stats.

## Signals

### creature_died
Emitted when creature health reaches 0.

```gdscript
creature.creature_died.connect(func(c): print("%s died" % c.name))
```

### creature_attacked
Emitted when creature attacks a target.

```gdscript
creature.creature_attacked.connect(func(target, damage):
    print("Attacked %s for %d damage" % [target.name, damage])
)
```

### creature_damaged
Emitted when creature takes damage.

```gdscript
creature.creature_damaged.connect(func(damage, source):
    print("Took %d damage from %s" % [damage, source.name if source else "unknown"])
)
```

## Performance Considerations

### Telemetry Updates
- Creatures send telemetry every 1 second
- Batched to avoid spam
- Includes position, velocity, health, state

### Behavior Tree Optimization
- Evaluated once per physics frame (90 FPS)
- Early-exit sequences and selectors
- Minimal memory allocation

### Detection Optimization
- Raycast only when needed
- Distance check before expensive LOS test
- Cached player reference

## Future Enhancements

1. **Taming System** - Implement TAMEABLE creature interactions
2. **Pack Behavior** - Group coordination for pack creatures
3. **Animation Integration** - Connect to AnimationTree
4. **Loot System** - Drop items on death
5. **Spawning System** - Biome-based procedural spawning
6. **AI Debug Visualization** - Gizmos for detection range, paths
7. **Pathfinding** - A* navigation for complex terrain
8. **Sound Effects** - Audio feedback for actions
9. **Modding Support** - JSON-based creature definitions

## Troubleshooting

### Creature Not Spawning
- Check creature_data resource exists at path
- Verify scene root is accessible
- Check console for error messages

### Creature Not Moving
- Verify ground collision layer/mask
- Check creature_data.movement_speed > 0
- Ensure behavior tree is created

### No Target Detection
- Check player is in "player" group
- Verify detection_range is sufficient
- Check for obstacles blocking LOS

### Attack Not Working
- Verify target has `take_damage(amount, source)` method
- Check attack_range and attack_cooldown
- Ensure creature is in ATTACK state

## API Reference

See also:
- `scripts/gameplay/creature_data.gd` - CreatureData resource
- `scripts/gameplay/behavior_tree.gd` - BehaviorTree system
- `scripts/gameplay/creature_ai.gd` - CreatureAI controller
- `addons/godot_debug_connection/godot_bridge.gd` - HTTP endpoints

## Contributing

When adding new features:
1. Update CreatureData with new parameters
2. Add behavior tree nodes if needed
3. Document in this file
4. Add HTTP API endpoints
5. Create test cases
6. Update telemetry events
