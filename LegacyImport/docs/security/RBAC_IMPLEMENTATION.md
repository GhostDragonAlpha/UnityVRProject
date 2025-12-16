# RBAC Implementation Guide

**Date:** 2025-12-02
**Status:** ✅ IMPLEMENTED
**Fixes:** VULN-002 (CVSS 9.8 CRITICAL - Missing Authorization)

---

## Executive Summary

This document describes the Role-Based Access Control (RBAC) system implemented to fix **VULN-002: Missing Authorization**. The RBAC system provides comprehensive authorization for all HTTP API endpoints, implementing the principle of least privilege and preventing unauthorized access to sensitive operations.

### Key Features

- **4 Built-in Roles**: readonly, api_client, developer, admin
- **30+ Granular Permissions**: Scene management, debug operations, admin functions
- **Role Inheritance**: Hierarchical permission structure
- **Token-Role Mapping**: Persistent role assignments to authentication tokens
- **Authorization Middleware**: Easy integration with all routers
- **Audit Logging**: Comprehensive logging of authorization events
- **Privilege Escalation Prevention**: Protection against unauthorized role assignments

---

## Architecture Overview

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                     HTTP API Request                         │
└───────────────────────────┬─────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │   Router       │
                    │   Handler      │
                    └───────┬────────┘
                            │
              ┌─────────────▼──────────────┐
              │  Authorization Middleware   │
              │  (AuthorizationMiddleware)  │
              └─────────────┬──────────────┘
                            │
           ┌────────────────┴────────────────┐
           │                                 │
    ┌──────▼─────────┐            ┌─────────▼────────┐
    │ TokenManager   │            │   RBAC Manager   │
    │ (Authentication)│           │  (Authorization) │
    └──────┬─────────┘            └─────────┬────────┘
           │                                 │
           │  Validates Token                │  Checks Permissions
           │                                 │
           └────────────────┬────────────────┘
                            │
                   ┌────────▼────────┐
                   │  Authorization  │
                   │     Result      │
                   │  (Grant/Deny)   │
                   └─────────────────┘
```

### Core Classes

#### 1. `HttpApiRBAC` (C:/godot/scripts/security/rbac.gd)

Main RBAC manager class that handles:
- Role definitions and management
- Permission checking with inheritance
- Token-to-role assignments
- Audit logging
- Metrics tracking

#### 2. `HttpApiAuthorizationMiddleware` (C:/godot/scripts/security/authorization_middleware.gd)

Middleware for routers that:
- Validates authentication (via TokenManager)
- Checks authorization (via RBAC)
- Returns appropriate HTTP status codes (401/403)
- Provides convenient authorization helpers

#### 3. `HttpApiSecuritySystem` (C:/godot/scripts/security/security_system.gd)

Integration layer that:
- Initializes all security components
- Provides unified access to security services
- Manages component lifecycle

---

## Roles and Permissions

### Role Hierarchy

```
readonly (default)
  ├─> api_client (inherits readonly permissions)
  │     ├─> developer (inherits api_client permissions)
  │     │     ├─> admin (inherits developer permissions + all admin permissions)
```

### Role Definitions

#### 1. **readonly** (Default Role)

**Description:** Read-only access to non-sensitive endpoints
**Use Cases:** Monitoring tools, status dashboards, read-only API clients

**Permissions:**
- `scene.read` - View current scene
- `config.read` - Read configuration
- `debug.read` - Read debug information
- `creature.read` - View creatures
- `performance.read` - View performance metrics
- `job.read` - View jobs
- `webhook.read` - View webhooks

#### 2. **api_client**

**Description:** API client with scene and creature access
**Inherits From:** readonly
**Use Cases:** External applications, automated testing, CI/CD pipelines

**Additional Permissions:**
- `scene.load` - Load scenes
- `scene.validate` - Validate scenes
- `scene.history` - View scene history
- `creature.spawn` - Spawn creatures

#### 3. **developer**

**Description:** Developer access for testing and debugging
**Inherits From:** api_client
**Use Cases:** Development team, QA testing, debugging

**Additional Permissions:**
- `scene.reload` - Reload current scene
- `debug.execute` - Execute debug commands ⚠️
- `creature.modify` - Modify creatures
- `creature.delete` - Delete creatures
- `batch.execute` - Execute batch operations
- `job.create` - Create jobs
- `webhook.write` - Create/modify webhooks

#### 4. **admin**

**Description:** Full administrative access
**Inherits From:** developer
**Use Cases:** System administrators, security team

**Additional Permissions:**
- `config.write` - Modify configuration ⚠️
- `admin.metrics` - View system metrics
- `admin.health` - View health status
- `admin.logs` - View logs
- `admin.config` - Modify admin config ⚠️
- `admin.cache_clear` - Clear caches
- `admin.restart` - Restart server ⚠️
- `admin.security` - Manage security
- `admin.audit` - View audit logs
- `admin.tokens` - Manage tokens ⚠️
- `admin.roles` - Manage roles ⚠️
- `webhook.delete` - Delete webhooks
- `job.modify` - Modify jobs
- `job.delete` - Delete jobs

⚠️ = High-risk operations

---

## Implementation Guide

### 1. Initialize Security System

In your HTTP API server initialization:

```gdscript
# C:/godot/scripts/http_api/http_api_server.gd

const SecuritySystem = preload("res://scripts/security/security_system.gd")

func _ready():
	# Initialize security components
	SecuritySystem.initialize()

	# ... rest of server initialization
```

### 2. Add Authorization to Routers

#### Basic Authorization Check

```gdscript
extends "res://addons/godottpd/http_router.gd"

const AuthMiddleware = preload("res://scripts/security/authorization_middleware.gd")

func _init():
	var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Authorization check - requires specific permission
		var authz = AuthMiddleware.authorize_request(request, HttpApiRBAC.Permission.SCENE_LOAD)
		if not authz.authorized:
			response.send(authz.status, JSON.stringify(authz.body))
			return true

		# Continue with handler logic...
		# authz.token_id contains the authenticated token ID

		return true

	super("/scene", {'post': post_handler})
```

#### Multiple Permission Check (ANY)

```gdscript
# Allow if user has ANY of the specified permissions
var permissions = [
	HttpApiRBAC.Permission.SCENE_READ,
	HttpApiRBAC.Permission.SCENE_LOAD
]

var authz = AuthMiddleware.authorize_any(request, permissions)
if not authz.authorized:
	response.send(authz.status, JSON.stringify(authz.body))
	return true
```

#### Multiple Permission Check (ALL)

```gdscript
# Require ALL specified permissions
var permissions = [
	HttpApiRBAC.Permission.CONFIG_READ,
	HttpApiRBAC.Permission.CONFIG_WRITE
]

var authz = AuthMiddleware.authorize_all(request, permissions)
if not authz.authorized:
	response.send(authz.status, JSON.stringify(authz.body))
	return true
```

### 3. Assign Roles to Tokens

#### Via API (Admin Only)

```bash
# Assign developer role to token
curl -X POST http://127.0.0.1:8080/admin/roles/assign \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "token_id": "<token_id>",
    "role_name": "developer"
  }'
```

#### Via Code

```gdscript
const SecuritySystem = preload("res://scripts/security/security_system.gd")

# Assign role
var result = SecuritySystem.assign_role(token_id, "developer", "admin")

if result.success:
	print("Role assigned successfully")
else:
	print("Error: ", result.error)
```

### 4. Check Permissions Programmatically

```gdscript
const SecuritySystem = preload("res://scripts/security/security_system.gd")

# Check if token has specific permission
if SecuritySystem.has_permission(token_id, HttpApiRBAC.Permission.DEBUG_EXECUTE):
	# Allow operation
	pass
else:
	# Deny operation
	pass
```

---

## API Endpoints

### GET /admin/roles

List all available roles with their permissions.

**Authorization:** Requires `admin.roles` permission (admin only)

**Response:**
```json
{
	"success": true,
	"roles": [
		{
			"role_name": "readonly",
			"description": "Read-only access...",
			"inherits_from": "",
			"permissions": ["scene.read", "config.read", ...]
		},
		...
	],
	"count": 4
}
```

### GET /admin/roles/assignments

List all role assignments (which tokens have which roles).

**Authorization:** Requires `admin.roles` permission (admin only)

**Response:**
```json
{
	"success": true,
	"assignments": [
		{
			"token_id": "abc-123-def-456",
			"role_name": "developer",
			"assigned_at": 1733155200.0,
			"assigned_by": "admin"
		},
		...
	],
	"count": 5
}
```

### POST /admin/roles/assign

Assign a role to a token.

**Authorization:** Requires `admin.roles` permission (admin only)

**Request:**
```json
{
	"token_id": "abc-123-def-456",
	"role_name": "developer"
}
```

**Response:**
```json
{
	"success": true,
	"message": "Role assigned successfully",
	"token_id": "abc-123-def-456",
	"role_name": "developer"
}
```

### POST /admin/roles/revoke

Remove role assignment from token (reverts to default readonly role).

**Authorization:** Requires `admin.roles` permission (admin only)

**Request:**
```json
{
	"token_id": "abc-123-def-456"
}
```

**Response:**
```json
{
	"success": true,
	"message": "Role assignment removed, token reverted to default role (readonly)",
	"token_id": "abc-123-def-456"
}
```

### GET /admin/security/audit

View RBAC audit log (authorization events, role assignments, etc.).

**Authorization:** Requires `admin.audit` permission (admin only)

**Response:**
```json
{
	"success": true,
	"audit_log": [
		{
			"timestamp": 1733155200.0,
			"event_type": "authorization_denied",
			"details": {
				"token_id": "abc-123",
				"permission": "debug.execute",
				"reason": "Role 'readonly' does not have required permission"
			}
		},
		...
	],
	"count": 42
}
```

---

## HTTP Status Codes

The RBAC system uses standard HTTP status codes:

- **200 OK** - Authorization successful
- **401 Unauthorized** - Invalid or missing authentication token
- **403 Forbidden** - Valid token but insufficient permissions
- **404 Not Found** - Endpoint or role not found
- **500 Internal Server Error** - RBAC system error

### Response Formats

#### 401 Unauthorized
```json
{
	"error": "Unauthorized",
	"message": "Missing or invalid authentication token",
	"details": "Include 'Authorization: Bearer <token>' header"
}
```

#### 403 Forbidden
```json
{
	"error": "Forbidden",
	"message": "Insufficient permissions",
	"required_permission": "debug.execute",
	"your_role": "readonly",
	"reason": "Role 'readonly' does not have required permission",
	"details": "Contact an administrator to request elevated permissions"
}
```

---

## Audit Logging

All authorization events are logged for security auditing:

### Event Types

- `authorization_denied` - Permission check failed
- `role_assigned` - Role assigned to token
- `role_removed` - Role assignment removed
- `privilege_escalation_attempt` - Unauthorized role assignment attempt
- `token_rejected` - Token validation failed

### Audit Log Format

```json
{
	"timestamp": 1733155200.0,
	"event_type": "authorization_denied",
	"details": {
		"token_id": "abc-123-def-456",
		"permission": "debug.execute",
		"reason": "Role 'readonly' does not have required permission"
	}
}
```

### Accessing Audit Logs

```bash
# Via API (admin only)
curl -X GET http://127.0.0.1:8080/admin/security/audit \
  -H "Authorization: Bearer <admin_token>"
```

```gdscript
# Via code
const SecuritySystem = preload("res://scripts/security/security_system.gd")

var audit_log = SecuritySystem.get_audit_log(100)  # Last 100 entries
for entry in audit_log:
	print(entry.event_type, " at ", entry.timestamp)
```

---

## Security Best Practices

### 1. Principle of Least Privilege

Always assign the minimal role required:

- **Monitoring/Dashboards** → `readonly`
- **External Integrations** → `api_client`
- **Development/Testing** → `developer`
- **System Administration** → `admin`

### 2. Regular Role Audits

Regularly review role assignments:

```bash
# List all role assignments
curl -X GET http://127.0.0.1:8080/admin/roles/assignments \
  -H "Authorization: Bearer <admin_token>"
```

### 3. Token Rotation

Rotate tokens with elevated permissions regularly:

```bash
# Rotate admin token every 7 days
curl -X POST http://127.0.0.1:8080/auth/rotate \
  -H "Authorization: Bearer <current_admin_token>"
```

### 4. Monitor Privilege Escalation

Monitor audit logs for privilege escalation attempts:

```gdscript
var audit_log = SecuritySystem.get_audit_log(1000)
var escalation_attempts = audit_log.filter(
	func(e): return e.event_type == "privilege_escalation_attempt"
)

if escalation_attempts.size() > 0:
	push_warning("SECURITY ALERT: Privilege escalation attempts detected!")
```

### 5. Protect Admin Tokens

- Never commit admin tokens to version control
- Use environment variables or secure vaults
- Rotate admin tokens frequently
- Limit admin token distribution

---

## Metrics and Monitoring

### Authorization Metrics

```gdscript
const SecuritySystem = preload("res://scripts/security/security_system.gd")

var metrics = SecuritySystem.get_metrics()

print("Authorization Checks: ", metrics.authorization.authorization_checks_total)
print("Granted: ", metrics.authorization.authorization_granted_total)
print("Denied: ", metrics.authorization.authorization_denied_total)
print("Success Rate: ", metrics.authorization.authorization_success_rate, "%")
print("Privilege Escalation Attempts: ", metrics.authorization.privilege_escalation_attempts_total)
```

### Metrics Available

- `authorization_checks_total` - Total authorization checks performed
- `authorization_granted_total` - Successful authorizations
- `authorization_denied_total` - Failed authorizations
- `authorization_success_rate` - Percentage of successful checks
- `privilege_escalation_attempts_total` - Privilege escalation attempts detected
- `role_assignments_total` - Total role assignments made
- `total_roles` - Number of defined roles
- `total_role_assignments` - Number of active role assignments

---

## Testing

Comprehensive test suite located at:
- `C:/godot/tests/security/test_rbac.gd`

### Run Tests

```bash
# Via GdUnit4 from Godot editor
# Or via command line:
godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd --test-suite tests/security/test_rbac.gd
```

### Test Coverage

- ✅ Role initialization and permissions
- ✅ Role inheritance
- ✅ Authorization checks (grant/deny)
- ✅ Role assignments and revocations
- ✅ Privilege escalation prevention
- ✅ Audit logging
- ✅ Metrics tracking
- ✅ Persistence
- ✅ Middleware integration

---

## Troubleshooting

### Issue: 403 Forbidden on All Requests

**Cause:** Token has default readonly role

**Solution:**
```bash
# Assign appropriate role
curl -X POST http://127.0.0.1:8080/admin/roles/assign \
  -H "Authorization: Bearer <admin_token>" \
  -d '{"token_id": "<your_token_id>", "role_name": "developer"}'
```

### Issue: Cannot Assign Roles (403 Forbidden)

**Cause:** Your token doesn't have `admin.roles` permission

**Solution:** Only admin role can assign roles. Contact an administrator.

### Issue: RBAC Not Initialized

**Cause:** Security system not initialized on server startup

**Solution:**
```gdscript
# In http_api_server.gd _ready():
const SecuritySystem = preload("res://scripts/security/security_system.gd")
SecuritySystem.initialize()
```

### Issue: All Requests Return 401

**Cause:** Token expired or invalid

**Solution:**
```bash
# Refresh token or get new token
curl -X POST http://127.0.0.1:8080/auth/rotate \
  -H "Authorization: Bearer <current_token>"
```

---

## Configuration Files

### Role Configuration
- **Location:** `C:/godot/config/roles.json`
- **Format:** JSON
- **Purpose:** Documents role definitions and permissions

### Role Assignments
- **Location:** `user://security/role_assignments.json`
- **Format:** JSON
- **Purpose:** Persists token-to-role mappings

### RBAC Config
- **Location:** `user://security/rbac_config.json`
- **Format:** JSON
- **Purpose:** Persists RBAC configuration (future use)

---

## Migration from Non-RBAC System

If upgrading from a system without RBAC:

1. **All existing tokens will default to `readonly` role**
2. **Assign elevated roles as needed:**

```bash
# Assign developer role to your development tokens
curl -X POST http://127.0.0.1:8080/admin/roles/assign \
  -H "Authorization: Bearer <admin_token>" \
  -d '{"token_id": "<dev_token_id>", "role_name": "developer"}'
```

3. **Update client applications** to handle 403 responses
4. **Review and audit all role assignments**

---

## References

- [VULN-002: Missing Authorization](./VULNERABILITIES.md#vuln-002-no-authorization-controls)
- [Security Audit Report](./SECURITY_AUDIT_REPORT.md)
- [Token Management](../../scripts/http_api/token_manager.gd)
- [HTTP API Documentation](../../addons/godot_debug_connection/HTTP_API.md)

---

**Document Version:** 1.0
**Last Updated:** 2025-12-02
**Status:** ✅ COMPLETE
