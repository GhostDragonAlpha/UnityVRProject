# Endpoint-Specific Authentication - Code Reference

## Function Signatures

### Public API Functions

```gdscript
## Check if endpoint is public (no auth required)
static func is_public_endpoint(endpoint: String, method: String) -> bool

## Check if endpoint is sensitive (always requires auth)
static func is_sensitive_endpoint(endpoint: String) -> bool

## Validate authorization with endpoint-specific rules
static func validate_auth_with_endpoint(
    headers: Variant,
    endpoint: String,
    method: String,
    client_ip: String = "127.0.0.1"
) -> Dictionary
```

### Internal Functions

```gdscript
## Extract and validate role from JWT claims
static func _validate_role_access(
    headers: Variant,
    endpoint: String,
    client_ip: String
) -> Dictionary

## Log authentication attempts to audit log
static func _log_auth_attempt(
    client_ip: String,
    endpoint: String,
    success: bool,
    reason: String
) -> void
```

## Configuration Variables

### Public Endpoints Dictionary

```gdscript
static var _public_endpoints: Dictionary = {
    "/health": ["GET", "OPTIONS"],
    "/status": ["GET", "OPTIONS"],
    "/": ["OPTIONS"],
}
```

Format: `{"/endpoint/path": ["METHOD1", "METHOD2", ...]}`

### Sensitive Endpoints Array

```gdscript
static var _sensitive_endpoints: Array[String] = [
    "/auth/metrics",
    "/auth/audit",
    "/auth/status",
    "/admin",
    "/admin/",
]
```

### Role-Protected Endpoints Dictionary

```gdscript
static var _role_protected_endpoints: Dictionary = {
    "/admin/users": ["admin"],
    "/admin/config": ["admin"],
    "/admin/audit": ["admin", "auditor"],
}
```

Format: `{"/endpoint": ["role1", "role2", ...]}`

## Return Value Formats

### Success - Public Endpoint

```gdscript
{
    "authorized": true,
    "reason": "Public endpoint",
    "auth_method": "public"
}
```

### Success - Authenticated

```gdscript
{
    "authorized": true,
    "reason": "Authenticated",
    "auth_method": "bearer_token"
}
```

### Success - CORS Preflight

```gdscript
{
    "authorized": true,
    "reason": "CORS preflight",
    "auth_method": "cors_preflight"
}
```

### Failure - Missing Auth

```gdscript
{
    "authorized": false,
    "reason": "Missing or invalid authentication token",
    "auth_method": "none"
}
```

### Failure - Insufficient Role

```gdscript
{
    "authorized": false,
    "reason": "Insufficient permissions",
    "required_roles": ["admin"],
    "user_roles": ["user"],
    "auth_method": "none"
}
```

## Integration Example

```gdscript
extends "res://addons/godottpd/http_router.gd"

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

func _init():
    var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
        # Validate auth with endpoint-specific rules
        var auth_result = SecurityConfig.validate_auth_with_endpoint(
            request,
            "/my/endpoint",
            "GET",
            _extract_client_ip(request)
        )

        # Check authorization
        if not auth_result.authorized:
            response.send(401, JSON.stringify(
                SecurityConfig.create_auth_error_response()
            ))
            return true

        # Proceed with handler logic
        response.send(200, JSON.stringify({"status": "success"}))
        return true

    super("/my/endpoint", {"get": get_handler})

func _extract_client_ip(request: HttpRequest) -> String:
    if request.headers:
        for header in request.headers:
            if header.begins_with("X-Forwarded-For:"):
                var ip = header.split(":", 1)[1].strip_edges()
                return ip.split(",")[0].strip_edges()
    return "127.0.0.1"
```

## Audit Logging Format

```
[TIMESTAMP] [LEVEL] [IP_ADDRESS] [ENDPOINT] [OPERATION] DETAILS
```

Examples:
```
[2024-12-03 10:45:23] [INFO] [127.0.0.1] [/auth/metrics] [AUTH_SUCCESS] Valid token
[2024-12-03 10:45:25] [WARN] [127.0.0.1] [/auth/metrics] [AUTH_FAILURE] Invalid or missing token
[2024-12-03 10:45:27] [INFO] [127.0.0.1] [/health] [AUTH_SUCCESS] Public endpoint (GET)
```

Log file: `user://logs/http_api_audit.log`

## JWT Claims Format

Minimum claims:
```json
{
    "sub": "user_id",
    "exp": 1234567890,
    "type": "api_access"
}
```

With roles:
```json
{
    "sub": "user_id",
    "exp": 1234567890,
    "type": "api_access",
    "roles": ["admin", "auditor"]
}
```

## Error HTTP Status Codes

- **200 OK** - Successful authentication and authorization
- **401 Unauthorized** - Missing or invalid authentication
- **403 Forbidden** - Insufficient role/permissions
- **429 Too Many Requests** - Rate limit exceeded

## Configuration Examples

### Add Public Endpoint

```gdscript
SecurityConfig._public_endpoints["/my/public/endpoint"] = ["GET", "POST"]
```

### Add Sensitive Endpoint

```gdscript
SecurityConfig._sensitive_endpoints.append("/my/sensitive/endpoint")
```

### Add Role-Protected Endpoint

```gdscript
SecurityConfig._role_protected_endpoints["/my/admin/endpoint"] = ["admin", "moderator"]
```

## Validation Logic Flow

1. **Null Check** - Reject null headers
2. **OPTIONS Check** - Allow CORS preflight
3. **Public Endpoint Check** - Allow public endpoints
4. **Token Validation** - Validate Bearer token
5. **Role Check** - Validate user roles (if applicable)
6. **Log Result** - Log all decisions

## Performance Characteristics

- Dictionary lookup: O(1)
- String comparison: O(n) where n = endpoint path length
- Role validation: O(m) where m = number of roles
- JWT verification: O(1) with caching

Typical request processing time: < 1ms

## Common Patterns

### Require Authentication

```gdscript
SecurityConfig._sensitive_endpoints.append("/my/endpoint")
var auth_result = SecurityConfig.validate_auth_with_endpoint(...)
if not auth_result.authorized:
    response.send(401, ...)
```

### Require Specific Role

```gdscript
SecurityConfig._role_protected_endpoints["/admin/endpoint"] = ["admin"]
var auth_result = SecurityConfig.validate_auth_with_endpoint(...)
if not auth_result.authorized:
    if auth_result.required_roles:
        response.send(403, ...)  # Insufficient role
    else:
        response.send(401, ...)  # Missing auth
```

### Allow Public Access

```gdscript
SecurityConfig._public_endpoints["/my/endpoint"] = ["GET"]
var auth_result = SecurityConfig.validate_auth_with_endpoint(...)
# Will return authorized=true for GET requests without auth
```

## Troubleshooting

### Request returns 401 but should succeed

Check:
1. Token format: `Authorization: Bearer <token>`
2. Token expiration: JWT not expired
3. Endpoint not marked sensitive
4. Headers passed correctly to validator

### Request returns 403 but should succeed

Check:
1. Endpoint role requirements: `_role_protected_endpoints`
2. JWT includes `roles` claim
3. User roles match required roles
4. Role format (string or array)

### Audit logs not appearing

Check:
1. Log directory exists: `user://logs/`
2. `HttpApiAuditLogger` initialized
3. File permissions
4. `_log_auth_attempt()` being called
