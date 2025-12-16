# Conflict Resolution System - Quick Reference

## Quick Start

### Enable Debug UI

Press **F3** in VR mode to toggle conflict visualization.

```gdscript
# In your input handler
if event.keycode == KEY_F3:
    var debug_ui = get_node("/root/ConflictDebugUI")
    if debug_ui:
        debug_ui.toggle_visibility()
```

### Check If Item Is Claimed

```gdscript
if network_sync.is_item_claimed(item_id):
    var claimer = network_sync.get_item_claimer(item_id)
    print("Item already claimed by player %d" % claimer)
    return
```

### Resolve Item Pickup

```gdscript
var competing_players: Array[int] = [1, 2, 3]
var winner_id = network_sync.resolve_item_pickup_conflict(item_id, competing_players)
```

### Record Resource Contribution

```gdscript
network_sync.record_resource_contribution(resource_node_id, player_id, damage_dealt)
```

### Distribute Resource Fragments

```gdscript
var distribution = network_sync.distribute_resource_fragments(resource_node_id, total_fragments)
# Returns: {player_id: fragment_count, ...}
```

### Create Rollback Point

```gdscript
var state = {"position": entity.position, "health": entity.health}
network_sync.create_rollback_state(entity_id, state)

# Later, if operation fails:
network_sync.rollback_entity(entity_id)
```

---

## Common Patterns

### Pattern 1: Item Pickup with Conflict Resolution

```gdscript
func pickup_item(item_id: int, player_id: int) -> bool:
    if not network_sync.is_host:
        return false

    # Check if already claimed
    if network_sync.is_item_claimed(item_id):
        return false

    # Record attempt
    network_sync._player_action_history[player_id].append({
        "type": "item_pickup",
        "timestamp": Time.get_ticks_msec(),
        "data": {"item_id": item_id}
    })

    # Resolve conflict
    var nearby_players = get_nearby_players(item_id)
    var winner = network_sync.resolve_item_pickup_conflict(item_id, nearby_players)

    return winner == player_id
```

### Pattern 2: Structure Placement with Validation

```gdscript
func place_structure(player_id: int, position: Vector3, type: int) -> bool:
    if not network_sync.is_host:
        return false

    # Validate action
    var action_data = {"position": position, "structure_type": type}
    if not network_sync._validate_player_action(player_id, "structure_place", action_data):
        return false

    # Collect pending placements
    var placements = [{
        "player_id": player_id,
        "position": position,
        "timestamp": Time.get_ticks_msec(),
        "structure_type": type
    }]

    # Resolve conflicts
    var resolved = network_sync.resolve_placement_conflict(placements)
    return resolved.has(player_id)
```

### Pattern 3: Resource Node Destruction

```gdscript
func on_resource_node_depleted(node_id: int, total_fragments: int):
    if not network_sync.is_host:
        return

    # Distribute fragments based on contribution
    var distribution = network_sync.distribute_resource_fragments(node_id, total_fragments)

    # Award fragments to players
    for player_id in distribution.keys():
        var fragments = distribution[player_id]
        award_fragments_to_player(player_id, fragments)
```

---

## Debugging

### View Conflict Log

```gdscript
var conflicts = network_sync.get_conflict_log()
for conflict in conflicts:
    print("Conflict: %s at %d" % [conflict["type"], conflict["timestamp"]])
```

### Clear Conflict Log

```gdscript
network_sync.clear_conflict_log()
```

### Check Validation Status

```gdscript
# Check action history for player
var actions = network_sync._player_action_history.get(player_id, [])
print("Player %d has %d recent actions" % [player_id, actions.size()])
```

---

## Testing

### Run Unit Tests

```bash
# From Godot editor with GUI (required)
# Use GdUnit4 panel at bottom of editor
# OR manually:
godot -s tests/unit/test_conflict_resolution.gd
```

### Run Property Tests

```bash
cd tests/property
python -m pytest test_item_pickup_conflict.py -v
```

Expected output:
```
test_item_pickup_exactly_one_winner PASSED [ 25%]
test_item_pickup_no_duplication PASSED     [ 50%]
test_item_pickup_timestamp_ordering PASSED [ 75%]
test_item_pickup_fairness PASSED           [100%]

4 passed in 0.62s
```

---

## Performance Tips

1. **Use Spatial Partitioning**: Don't check all players for conflicts, only nearby ones
2. **Batch Resolutions**: Resolve multiple conflicts in a single frame
3. **Clean Up Claims**: Auto-expire old claimed items (default: 10s)
4. **Limit Log Size**: Default 1000 entries (auto-FIFO eviction)
5. **Cache Validation Results**: For 1-second window per player

---

## Common Issues

### Issue: Items being duplicated
**Solution**: Ensure `is_item_claimed()` is checked before awarding items

### Issue: Spam detection triggering incorrectly
**Solution**: Adjust `_action_validation_window` or rate limits in `_validate_player_action()`

### Issue: Rollback not working
**Solution**: Ensure `create_rollback_state()` is called BEFORE risky operations

### Issue: Resource distribution unfair
**Solution**: Verify contributions are being recorded correctly with `record_resource_contribution()`

### Issue: Clients not receiving notifications
**Solution**: Check message queue priority and network connection status

---

## API Quick Reference

| Function | Purpose | Host Only |
|----------|---------|-----------|
| `resolve_item_pickup_conflict()` | Award item to first player | ✅ |
| `is_item_claimed()` | Check if item already claimed | ❌ |
| `get_item_claimer()` | Get player who claimed item | ❌ |
| `resolve_placement_conflict()` | Resolve structure placement | ✅ |
| `distribute_resource_fragments()` | Distribute fragments fairly | ✅ |
| `record_resource_contribution()` | Track player damage | ✅ |
| `create_rollback_state()` | Create rollback point | ✅ |
| `rollback_entity()` | Revert entity to previous state | ✅ |
| `_validate_player_action()` | Validate player action | ✅ |
| `get_conflict_log()` | Retrieve conflict log | ❌ |
| `clear_conflict_log()` | Clear conflict log | ✅ |

---

## Configuration

### Validation Settings

```gdscript
# In NetworkSyncSystem
_action_validation_window: float = 1.0  # seconds

# Rate limits (in _validate_player_action)
structure_place_limit: int = 10  # per second
terrain_modify_limit: int = 20   # per second
item_pickup_range: float = 10.0  # meters
```

### Rollback Settings

```gdscript
max_rollback_states: int = 100  # LRU eviction
```

### Logging Settings

```gdscript
MAX_CONFLICT_LOG_SIZE: int = 1000  # FIFO eviction
```

### Claim Expiration

```gdscript
claim_expiration_time: int = 10000  # milliseconds
```

---

## Resources

- **Full Documentation**: `docs/TASK_35_CONFLICT_RESOLUTION_REPORT.md`
- **Completion Summary**: `docs/TASK_35_COMPLETION_SUMMARY.md`
- **Implementation**: `scripts/planetary_survival/systems/network_sync_system.gd`
- **Unit Tests**: `tests/unit/test_conflict_resolution.gd`
- **Property Tests**: `tests/property/test_item_pickup_conflict.py`
- **Debug UI**: `scripts/planetary_survival/ui/conflict_debug_ui.gd`

---

**Version**: 1.0
**Date**: 2025-12-02
**Status**: Production Ready ✅
