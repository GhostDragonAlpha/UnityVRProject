# SpaceTime VR - Quick Reference

**Version:** 2.5.0 | **Last Updated:** 2025-12-02

## Essential Commands

### Development Server
```bash
# Start development environment
python godot_editor_server.py --port 8090

# Quick restart (Windows)
./restart_godot_with_debug.bat

# Check system status
curl http://localhost:8080/status | jq

# Monitor telemetry
python telemetry_client.py
```

### Testing
```bash
# Run all tests
python tests/test_runner.py

# Quick smoke tests
python tests/test_runner.py --quick

# Property-based tests
cd tests/property && python -m pytest

# GDScript tests (in Godot Editor)
# Use GdUnit4 panel at bottom of editor
```

### Deployment
```bash
# Deploy to staging
gh workflow run deploy-staging.yml

# Deploy to production
gh workflow run deploy-production.yml

# Quick rollback
ssh production-server "bash /opt/spacetime/production/deploy/rollback.sh --quick"
```

---

## API Endpoints

### Connection
```bash
POST /connect          # Initialize DAP/LSP
POST /disconnect       # Disconnect services
GET  /status          # System status
GET  /health          # Health check
```

### Scene Management
```bash
POST /scene/load      # Load scene
GET  /scene/current   # Current scene info
POST /scene/reload    # Reload scene
GET  /scene/history   # Scene history
POST /scene/validate  # Validate scene
```

### Player
```bash
POST /player/spawn      # Spawn player
GET  /player/position   # Get position
POST /player/teleport   # Teleport player
POST /player/mode       # Change mode
```

### Terrain
```bash
POST /terrain/deform   # Deform terrain
GET  /terrain/info     # Get terrain info
POST /terrain/sync     # Sync changes
```

### VR
```bash
GET  /vr/tracking      # Get tracking data
POST /vr/recenter      # Recenter tracking
```

### Debug (DAP)
```bash
POST /debug/launch         # Launch debug session
POST /debug/setBreakpoints # Set breakpoints
POST /debug/continue       # Continue execution
POST /debug/evaluate       # Evaluate expression
```

### Monitoring
```bash
GET /metrics           # Prometheus metrics
```

**Full API Reference:** [API_REFERENCE.md](api/API_REFERENCE.md)

---

## WebSocket Telemetry

### Connection
```
ws://localhost:8081
wss://spacetime.example.com/telemetry
```

### Events
- `fps` - Performance metrics (every 0.5s)
- `vr_tracking` - VR headset/controller tracking (every 0.1s)
- `player_position` - Player position updates
- `terrain_modified` - Terrain changes
- `error` - Error events

### Commands
```json
{"type": "subscribe", "events": ["fps", "vr_tracking"]}
{"type": "get_snapshot"}
{"type": "ping"}
```

---

## Database Schema (Quick Reference)

### Main Tables
- **users** - User accounts
- **worlds** - World/save files
- **players** - Player characters
- **structures** - Placed buildings
- **creatures** - Creature instances
- **terrain_chunks** - Modified terrain
- **sessions** - User sessions

**Connection:**
```bash
postgresql://spacetime:password@localhost:5432/spacetime
```

---

## Redis Keys

### Patterns
```
session:{token}                           # User sessions
ratelimit:{ip}:{endpoint}                 # Rate limiting
player:position:{player_id}               # Player positions
active_players:{world_id}                 # Active player sets
server:health:{server_id}                 # Server health
world:state:{world_id}                    # World state cache
terrain:chunk:{world_id}:{x}:{y}:{z}      # Terrain chunks
leaderboard:{world_id}:{metric}           # Leaderboards
```

---

## Environment Variables

### Development
```bash
HTTP_API_PORT=8080
TELEMETRY_PORT=8081
DAP_PORT=6006
LSP_PORT=6005
LOG_LEVEL=DEBUG
```

### Production
```bash
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
API_TOKEN_SECRET=...
TLS_CERT_FILE=/path/to/cert.pem
TLS_KEY_FILE=/path/to/key.pem
```

---

## Godot Shortcuts

### Essential
- **F5** - Run project
- **F6** - Run current scene
- **F7** - Step into (debugger)
- **F8** - Toggle breakpoint
- **Ctrl+S** - Save
- **Ctrl+D** - Duplicate
- **Ctrl+Shift+F** - Search in files

### Scene Editor
- **W** - Move mode
- **E** - Rotate mode
- **R** - Scale mode
- **Q** - Select mode
- **F** - Focus on selected node

### Script Editor
- **Ctrl+Space** - Autocomplete
- **Ctrl+Click** - Go to definition
- **Ctrl+K** - Comment/uncomment
- **Ctrl+Shift+K** - Delete line

---

## GDScript Patterns

### Node Access
```gdscript
# Get node by path
var node = get_node("Path/To/Node")
var node = $Path/To/Node

# Get typed node
var player: Player = $Player

# Find node in group
var enemies = get_tree().get_nodes_in_group("enemies")
```

### Signals
```gdscript
# Define signal
signal health_changed(new_value: int)

# Emit signal
health_changed.emit(health)

# Connect signal
health_changed.connect(_on_health_changed)

func _on_health_changed(new_value: int):
    print("Health: ", new_value)
```

### Multiplayer RPC
```gdscript
# Define RPC
@rpc("any_peer", "reliable")
func player_moved(pos: Vector3):
    position = pos

# Call RPC
player_moved.rpc(new_position)

# Call RPC on specific peer
player_moved.rpc_id(peer_id, new_position)
```

### Resource Loading
```gdscript
# Load scene
var scene = load("res://scenes/enemy.tscn")
var instance = scene.instantiate()
add_child(instance)

# Preload (compile-time)
const Enemy = preload("res://scenes/enemy.tscn")
```

---

## Testing Patterns

### GDScript Unit Test
```gdscript
extends GdUnitTestSuite

func test_player_health():
    var player = Player.new()
    add_child(player)

    player.take_damage(10)

    assert_that(player.health).is_equal(90)
```

### Python Integration Test
```python
import requests

def test_player_spawn():
    response = requests.post(
        "http://localhost:8080/player/spawn",
        json={"position": {"x": 0, "y": 100, "z": 0}},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    assert response.json()["status"] == "success"
```

---

## Docker Commands

### Development
```bash
# Build image
docker-compose build

# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Production
```bash
# Pull images
docker-compose -f docker-compose.production.yml pull

# Start blue-green
docker-compose -p spacetime-green up -d

# Check health
docker-compose ps
```

---

## Monitoring

### Prometheus Queries
```promql
# Service uptime
up{job="godot"}

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# Response time (95th percentile)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Memory usage
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes
```

### Grafana Dashboards
- **System Overview** - Overall health
- **API Performance** - Request metrics
- **Player Metrics** - Player activity
- **Infrastructure** - Server resources

**Access:** `https://spacetime.example.com/grafana`

---

## Incident Response

### Severity Levels
- **P0 (Critical)** - Complete outage, < 15 min response
- **P1 (High)** - Major issue, < 1 hour response
- **P2 (Medium)** - Degraded service, < 4 hours response
- **P3 (Low)** - Minor issue, < 24 hours response

### Quick Actions
```bash
# Check service status
curl https://spacetime.example.com/status

# Check all services
for server in server1 server2 server3; do
  ssh $server "docker-compose ps"
done

# Quick rollback
bash deploy/rollback.sh --quick

# Restart services
docker-compose restart

# Check logs for errors
docker-compose logs --tail=200 | grep -i error
```

---

## File Locations

### Configuration
```
project.godot              # Godot project config
.env                       # Environment variables
.env.production           # Production config
docker-compose.yml        # Docker compose config
prometheus.yml            # Prometheus config
```

### Logs
```
~/.local/share/godot/app_userdata/SpaceTime/logs/  # Godot logs (Linux)
%APPDATA%\Godot\app_userdata\SpaceTime\logs\       # Godot logs (Windows)
/var/log/spacetime/                                # Production logs
```

### Backups
```
/opt/spacetime/production/backups/                 # Production backups
s3://spacetime-backups/                           # S3 backups
```

---

## Rate Limits

### Per IP
- General endpoints: 100 req/min
- Write operations: 10 req/min
- Expensive operations: 1 req/sec

### Per User
- General: 1000 req/min
- Write: 100 req/min

### Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1733145060
```

---

## HTTP Status Codes

- **200** OK - Success
- **201** Created - Resource created
- **204** No Content - Success, no response
- **400** Bad Request - Invalid parameters
- **401** Unauthorized - Missing/invalid auth
- **403** Forbidden - Not authorized
- **404** Not Found - Resource not found
- **429** Too Many Requests - Rate limited
- **500** Internal Error - Server error
- **503** Service Unavailable - Service down

---

## Authentication

### Obtain Token
```bash
curl -X POST https://spacetime.example.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "user", "password": "pass"}'
```

### Use Token
```bash
curl https://spacetime.example.com/api/endpoint \
  -H "Authorization: Bearer <token>"
```

### Refresh Token
```bash
curl -X POST https://spacetime.example.com/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "<refresh_token>"}'
```

---

## Common Issues

### Godot Won't Start
```bash
# Check if already running
taskkill /F /IM godot.exe  # Windows
killall godot               # Linux/Mac

# Verify Godot in PATH
godot --version

# Check ports available
python check_ports.py
```

### API Not Responding
```bash
# Try fallback port
curl http://localhost:8083/status

# Check if service running
docker-compose ps

# Restart service
docker-compose restart godot-server
```

### VR Not Working
1. Ensure SteamVR/Oculus running
2. Check headset connected
3. Verify OpenXR runtime set
4. Restart Godot

### Tests Failing
```bash
# Update dependencies
pip install -r requirements.txt --upgrade

# Clear cache
rm -rf .pytest_cache __pycache__

# Check Python environment
which python  # Should be in .venv
```

---

## Additional Resources

### Documentation
- [API Reference](api/API_REFERENCE.md)
- [Game Systems](architecture/GAME_SYSTEMS.md)
- [Operational Runbooks](operations/RUNBOOKS.md)
- [Getting Started](development/GETTING_STARTED.md)

### External Links
- [Godot Docs](https://docs.godotengine.org/)
- [OpenXR Spec](https://www.khronos.org/openxr/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Redis Docs](https://redis.io/docs/)

### Support
- **Discord:** [Join Server](https://discord.gg/spacetime)
- **GitHub:** [Issues](https://github.com/your-org/spacetime-vr/issues)
- **Email:** support@spacetime.example.com

---

**Print this page for quick reference at your desk!**

**Last Updated:** 2025-12-02 | **Version:** 2.5.0
