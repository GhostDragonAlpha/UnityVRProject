# Creature AI Quick Start Guide

## 5-Minute Setup

### 1. Start Godot with Debug Services
```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

### 2. Test HTTP API Connection
```bash
curl http://127.0.0.1:8080/status
```

### 3. Spawn Your First Creature
```bash
curl -X POST http://127.0.0.1:8080/creatures/spawn \
  -H "Content-Type: application/json" \
  -d '{"creature_type": "space_rabbit", "position": [0, 2, 0]}'
```

### 4. List All Creatures
```bash
curl http://127.0.0.1:8080/creatures/list
```

### 5. Monitor AI State
```bash
curl "http://127.0.0.1:8080/creatures/ai_state?creature_id=space_rabbit_123"
```

## Available Creatures

| Creature | Type | Health | Damage | Speed | Behavior |
|----------|------|--------|--------|-------|----------|
| space_rabbit | PASSIVE | 50 | 5 | 5.0 | Flees from player |
| crystal_crawler | NEUTRAL | 80 | 15 | 2.5 | Defensive |
| alien_predator | AGGRESSIVE | 150 | 25 | 4.0 | Hunts player |

## Python Example

```python
import requests

# Spawn creature
response = requests.post("http://127.0.0.1:8080/creatures/spawn", json={
    "creature_type": "alien_predator",
    "position": [10, 2, 5]
})
creature_id = response.json()["creature_id"]

# Apply damage
requests.post("http://127.0.0.1:8080/creatures/damage", json={
    "creature_id": creature_id,
    "damage": 50
})

# Check state
response = requests.get(f"http://127.0.0.1:8080/creatures/ai_state?creature_id={creature_id}")
print(response.json())
```

## Full API Reference

See `CREATURE_AI_SYSTEM.md` for complete documentation.

## Common Issues

**Creature not found**: Check creature type spelling and data file exists
**No movement**: Verify ground collision and behavior tree setup
**API connection failed**: Ensure Godot running with debug ports

## Next Steps

1. Run Python demo: `python examples/creature_api_example.py`
2. Load test scene: `scenes/creature_test.tscn`
3. Create custom creatures: Edit `.tres` files in `data/creatures/`
4. Read full docs: `CREATURE_AI_SYSTEM.md`
