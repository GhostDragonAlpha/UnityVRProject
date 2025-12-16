# RBAC Quick Reference

Quick reference guide for Role-Based Access Control (RBAC) system.

---

## Roles

| Role | Use Case | Inherits From |
|------|----------|---------------|
| `readonly` | Monitoring, dashboards | None (default) |
| `api_client` | External integrations | readonly |
| `developer` | Development, testing | api_client |
| `admin` | System administration | developer |

---

## Common Operations

### Assign Role to Token

```bash
curl -X POST http://127.0.0.1:8080/admin/roles/assign \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"token_id": "<token_id>", "role_name": "developer"}'
```

### List All Roles

```bash
curl http://127.0.0.1:8080/admin/roles \
  -H "Authorization: Bearer <admin_token>"
```

### View Role Assignments

```bash
curl http://127.0.0.1:8080/admin/roles/assignments \
  -H "Authorization: Bearer <admin_token>"
```

### View Audit Log

```bash
curl http://127.0.0.1:8080/admin/security/audit \
  -H "Authorization: Bearer <admin_token>"
```

### Remove Role Assignment

```bash
curl -X POST http://127.0.0.1:8080/admin/roles/revoke \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"token_id": "<token_id>"}'
```

---

## Adding Authorization to Routers

```gdscript
const AuthMiddleware = preload("res://scripts/security/authorization_middleware.gd")

func handler(request, response):
	# Check authorization
	var authz = AuthMiddleware.authorize_request(
		request,
		HttpApiRBAC.Permission.SCENE_LOAD
	)

	if not authz.authorized:
		response.send(authz.status, JSON.stringify(authz.body))
		return true

	# Continue with logic...
	var token_id = authz.token_id
```

---

## Key Permissions

### Read Permissions (readonly role)
- `scene.read`, `config.read`, `debug.read`, `creature.read`, `performance.read`

### Scene Management (api_client+ roles)
- `scene.load`, `scene.validate`, `scene.reload`, `scene.history`

### Debug Operations (developer+ roles)
- `debug.execute` ⚠️

### Admin Operations (admin role only)
- `admin.roles` ⚠️ - Manage roles
- `admin.tokens` ⚠️ - Manage tokens
- `admin.security` ⚠️ - Security settings
- `config.write` ⚠️ - Modify config

⚠️ = High-risk operations

---

## HTTP Status Codes

- `200 OK` - Authorized
- `401 Unauthorized` - Invalid/missing token
- `403 Forbidden` - Valid token, insufficient permissions

---

## Security Best Practices

1. ✅ Assign minimal required role
2. ✅ Rotate elevated tokens regularly
3. ✅ Monitor audit logs for privilege escalation
4. ✅ Never commit admin tokens to version control
5. ✅ Regular role assignment audits

---

## Troubleshooting

**403 on all requests?**
→ Your token has readonly role. Request role assignment from admin.

**Cannot assign roles?**
→ Only admin role can assign roles. Contact administrator.

**All requests return 401?**
→ Token expired or invalid. Rotate or refresh token.

---

See [RBAC_IMPLEMENTATION.md](./RBAC_IMPLEMENTATION.md) for full documentation.
