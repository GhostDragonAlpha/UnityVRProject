# HTTP API Quick Reference

## At a Glance

| What | Where | How |
|------|-------|-----|
| **Active HTTP API** | Port 8080 | `curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/status` |
| **Deprecated API** | Port 8081 | DO NOT USE - Disabled in autoload |
| **Process Management** | Port 8090 | `curl http://localhost:8090/health` |
| **Telemetry Stream** | Port 8081 | `ws://localhost:8081` |
| **Service Discovery** | Port 8087 | UDP broadcast |

## Remember

1. **Use port 8080** for all new HTTP API calls (HttpApiServer)
2. **Include JWT token** in Authorization header: `-H "Authorization: Bearer <TOKEN>"`
3. **Port 8080 is disabled** - It's from the old GodotBridge (deprecated)
4. **Authentication is required** - All endpoints need the JWT token

## Common Commands

### Get API Token (from Godot logs)
```bash
# Look for: "[HttpApiServer] API TOKEN: <TOKEN>"
# Print from Godot console:
TOKEN=$(grep "API TOKEN:" godot.log | sed 's/.*API TOKEN: //')
```

### Check System Status
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/status
```

### Load a Scene
```bash
curl -X POST http://localhost:8080/scene \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"path": "res://vr_main.tscn"}'
```

### Hot-Reload Scene
```bash
curl -X POST http://localhost:8080/scene/reload \
  -H "Authorization: Bearer $TOKEN"
```

### List Scenes
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/scenes
```

### Get Scene History
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/scene/history
```

## Files to Remember

- **Active API:** `/scripts/http_api/http_api_server.gd` (Port 8080)
- **Deprecated API:** `/addons/godot_debug_connection/godot_bridge.gd` (Port 8080 - DISABLED)
- **Config:** `/project.godot` (autoload configuration)
- **Full Guide:** `/API_MIGRATION_GUIDE.md`
- **Architecture:** `/CLAUDE.md`

## Troubleshooting

**Port 8080 returns "Connection refused"?**
- That's expected. It's disabled. Use 8080 instead.

**Port 8080 returns 401?**
- Missing JWT token. Include `-H "Authorization: Bearer $TOKEN"`

**Port 8080 returns 429?**
- Rate limited. Wait and retry (100 requests/minute default).

**Can't find JWT token?**
- Check Godot editor output/console for "[HttpApiServer] API TOKEN:"

## Migration Checklist

If updating old code using port 8080:

- [ ] Change all `http://localhost:8080` to `http://localhost:8080`
- [ ] Add JWT token header: `-H "Authorization: Bearer $TOKEN"`
- [ ] Replace DAP/LSP operations with REST endpoints
- [ ] Handle HTTP status codes (401, 429, etc.)
- [ ] Test with `curl` before integrating

## Key Endpoints

| Method | Endpoint | Purpose | Auth |
|--------|----------|---------|------|
| GET | `/status` | System status | Required |
| GET | `/scene` | Current scene info | Required |
| GET | `/scenes` | List all scenes | Required |
| POST | `/scene` | Load scene | Required |
| POST | `/scene/reload` | Hot-reload scene | Required |
| GET | `/scene/history` | Load history | Required |
| GET | `/scene/history/{id}` | Specific history entry | Required |

## See Also

- Full API documentation: `/scripts/http_api/HTTP_API.md` (if exists)
- Advanced features: `/scripts/http_api/INTEGRATION_INSTRUCTIONS.md`
- Security config: `/scripts/http_api/security_config.gd`
