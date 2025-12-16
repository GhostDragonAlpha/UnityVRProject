# Endpoint-Specific Authentication - Quick Reference

## Problem

Sensitive GET endpoints allowed unauthenticated access:
- `GET /auth/metrics` - Exposed token metrics
- `GET /auth/audit` - Exposed complete audit log
- `GET /auth/status` - Exposed token details

## Solution

Three-layer security model implemented in `security_config.gd`

## How to Use

### In Your Router

```gdscript
extends "res://addons/godottpd/http_router.gd"

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

func _init():
    var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
        # NEW: Use endpoint-specific auth validation
        var client_ip = _extract_client_ip(request)
        var endpoint = "/your/endpoint"
        var method = "GET"

        var auth_result = SecurityConfig.validate_auth_with_endpoint(
            request, endpoint, method, client_ip
        )

        if not auth_result.authorized:
            response.send(401, JSON.stringify(
                SecurityConfig.create_auth_error_response()
            ))
            return true

        # Your handler logic here...
        return true

    super("/your/endpoint", {'get': get_handler})
```

## Public Endpoints (No Auth Required)

Pre-configured public endpoints:
- `GET /health`
- `GET /status`
- `OPTIONS *` (CORS)

To add more:
```gdscript
SecurityConfig._public_endpoints["/my_public_endpoint"] = ["GET", "OPTIONS"]
```

## Sensitive Endpoints (Always Require Auth)

Pre-configured sensitive endpoints:
- `/auth/metrics`
- `/auth/audit`
- `/auth/status`
- `/admin/*`

Automatically protected - no special handling needed.

## Role-Based Access Control

### Requiring Specific Roles

```gdscript
# Define which roles can access an endpoint
SecurityConfig._role_protected_endpoints["/admin/users"] = ["admin"]
SecurityConfig._role_protected_endpoints["/admin/audit"] = ["admin", "auditor"]
```

### Checking Roles in JWT Token

Roles are automatically validated by `validate_auth_with_endpoint()`:

```gdscript
# Return value includes role information
var auth_result = SecurityConfig.validate_auth_with_endpoint(
    request, "/admin/users", "GET", client_ip
)

if auth_result.required_roles:
    print("Required roles: ", auth_result.required_roles)
    print("User roles: ", auth_result.user_roles)
```

## Response Format

Success (200):
```json
{
    "status": "ok",
    "data": {...}
}
```

Unauthorized (401):
```json
{
    "error": "Unauthorized",
    "message": "Missing or invalid authentication token",
    "details": "Include 'Authorization: Bearer <token>' header"
}
```

Insufficient Role (403):
```json
{
    "error": "Forbidden",
    "message": "Access denied"
}
```

## Auth Result Dictionary

```gdscript
{
    "authorized": bool,           # true if access allowed
    "reason": String,             # "Authenticated", "Public endpoint", etc.
    "auth_method": String,        # "bearer_token", "public", "cors_preflight"
    "required_roles": Array,      # For RBAC endpoints (optional)
    "user_roles": Array           # User's roles from JWT (optional)
}
```

## Audit Logging

Automatic logging of all auth attempts:

```
[AUTH_SUCCESS] /endpoint: 127.0.0.1 (Valid token)
[AUTH_FAILURE] /endpoint: 127.0.0.1 (Invalid or missing token)
[AUTH_SUCCESS] /endpoint: 127.0.0.1 (Public endpoint (GET))
```

View logs: `user://logs/http_api_audit.log`

## Common Patterns

### Protect a New Endpoint

```gdscript
# 1. Add to sensitive endpoints
SecurityConfig._sensitive_endpoints.append("/my/sensitive/endpoint")

# 2. Use validation in router
var auth_result = SecurityConfig.validate_auth_with_endpoint(
    request, "/my/sensitive/endpoint", method, client_ip
)

if not auth_result.authorized:
    response.send(401, JSON.stringify(
        SecurityConfig.create_auth_error_response()
    ))
    return true
```

### Require Admin Role

```gdscript
# 1. Define requirement
SecurityConfig._role_protected_endpoints["/my/admin/endpoint"] = ["admin"]

# 2. Use validation (role check is automatic)
var auth_result = SecurityConfig.validate_auth_with_endpoint(
    request, "/my/admin/endpoint", method, client_ip
)

if not auth_result.authorized:
    response.send(401, JSON.stringify(
        SecurityConfig.create_auth_error_response()
    ))
    return true
```

### Allow Public Access

```gdscript
# 1. Add to public endpoints
SecurityConfig._public_endpoints["/my/public/endpoint"] = ["GET", "OPTIONS"]

# 2. No special handling needed - validate_auth_with_endpoint will allow it
var auth_result = SecurityConfig.validate_auth_with_endpoint(
    request, "/my/public/endpoint", "GET", client_ip
)
# Returns: {"authorized": true, "auth_method": "public"}
```

## Testing

```bash
# Test public endpoint (should work)
curl http://127.0.0.1:8080/health

# Test sensitive endpoint without token (should fail)
curl http://127.0.0.1:8080/auth/metrics
# 401 Unauthorized

# Test sensitive endpoint with token (should work)
TOKEN="<valid_jwt_token>"
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/auth/metrics
# 200 OK

# Test admin endpoint without admin role (should fail)
TOKEN="<jwt_with_user_role>"
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/admin/users
# 403 Forbidden

# Test admin endpoint with admin role (should work)
TOKEN="<jwt_with_admin_role>"
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/admin/users
# 200 OK
```

## Security Checklist

- [ ] All routers use `validate_auth_with_endpoint()`
- [ ] Sensitive endpoints explicitly listed
- [ ] Role requirements defined for admin operations
- [ ] Public endpoints only explicitly whitelisted
- [ ] CORS preflight requests tested
- [ ] Audit logs monitored for suspicious activity
- [ ] JWT tokens include roles claim
- [ ] Error messages don't leak information

## Reference

- Full documentation: `ENDPOINT_AUTH_IMPLEMENTATION_GUIDE.md`
- Security config file: `security_config.gd`
- Audit logger: `audit_logger.gd`

## Support

For questions, see:
1. Function documentation in `security_config.gd`
2. Implementation guide: `ENDPOINT_AUTH_IMPLEMENTATION_GUIDE.md`
3. Audit logs: `user://logs/http_api_audit.log`
