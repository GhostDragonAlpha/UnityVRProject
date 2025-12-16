# Endpoint-Specific Authentication Fix (FIX-CVSS-8.1)

## Vulnerability Overview

**CVSS Score: 8.1 (High)**
**Severity: Critical**
**Type: Authentication Bypass**

### The Problem

The original authentication system allowed unrestricted GET and OPTIONS requests on sensitive endpoints:

```
GET /auth/metrics       <- NO AUTH REQUIRED!
GET /auth/audit         <- NO AUTH REQUIRED!
GET /auth/status        <- NO AUTH REQUIRED!
```

An unauthenticated attacker could access:
- Token usage metrics (reveals active sessions)
- Complete audit log (reveals all API operations)
- Authentication status (reveals token lifetime information)

**Attack Scenario:**
```bash
# Attacker discovers your API endpoint
curl http://127.0.0.1:8080/auth/metrics
# Returns complete token metrics without authentication!

curl http://127.0.0.1:8080/auth/audit
# Returns complete audit log without authentication!
```

## Solution Architecture

### Three-Layer Security Model

**Layer 1: Public Endpoints (No Auth Required)**
- `/health` - System health checks
- `/status` - General system status (not sensitive data)
- `OPTIONS *` - CORS preflight requests

**Layer 2: Sensitive Endpoints (Always Require Auth)**
- `/auth/metrics` - Token usage metrics
- `/auth/audit` - Audit logs
- `/auth/status` - Token status information
- `/admin/*` - Administrative operations

**Layer 3: Role-Based Access Control (RBAC)**
- `/admin/users` - Requires "admin" role
- `/admin/config` - Requires "admin" role
- `/admin/audit` - Requires "admin" or "auditor" role

## Implementation Details

### New Functions in `security_config.gd`

#### 1. `is_public_endpoint(endpoint: String, method: String) -> bool`

Checks if an endpoint is publicly accessible without authentication.

```gdscript
# Check if GET /health is public
if SecurityConfig.is_public_endpoint("/health", "GET"):
    # Allow access without auth
```

#### 2. `is_sensitive_endpoint(endpoint: String) -> bool`

Checks if an endpoint contains sensitive data and requires authentication.

```gdscript
# Check if /auth/metrics is sensitive
if SecurityConfig.is_sensitive_endpoint("/auth/metrics"):
    # Always require authentication, even for GET
```

#### 3. `validate_auth_with_endpoint(...) -> Dictionary`

Main validation function for endpoint-specific authentication.

**Parameters:**
- `headers: Variant` - HTTP headers (Dictionary or Object)
- `endpoint: String` - HTTP endpoint path (e.g., "/auth/metrics")
- `method: String` - HTTP method (GET, POST, OPTIONS, etc.)
- `client_ip: String` - Client IP address (for audit logging)

**Return Value:**
```gdscript
{
    "authorized": bool,      # true if request is allowed
    "reason": String,        # Human-readable reason
    "auth_method": String,   # "public", "bearer_token", "cors_preflight", "none"
    "required_roles": Array, # For RBAC endpoints (if applicable)
    "user_roles": Array      # User's actual roles (if applicable)
}
```

**Example Usage:**
```gdscript
var client_ip = "127.0.0.1"
var endpoint = "/auth/metrics"
var method = "GET"
var headers = request.headers

var auth_result = SecurityConfig.validate_auth_with_endpoint(
    headers, endpoint, method, client_ip
)

if not auth_result.authorized:
    # Return 401 Unauthorized
    response.send(401, JSON.stringify(
        SecurityConfig.create_auth_error_response()
    ))
    return
```

#### 4. `_validate_role_access(...) -> Dictionary`

Extracts and validates user roles from JWT claims.

**Return Value:**
```gdscript
{
    "authorized": bool,      # true if user has required role
    "reason": String,        # "Role matched", "Insufficient permissions", etc.
    "required_roles": Array, # Required roles for this endpoint
    "user_roles": Array      # User's actual roles from JWT
}
```

#### 5. `_log_auth_attempt(...) -> void`

Logs all authentication attempts to the audit log.

**Logs include:**
- Client IP address
- Endpoint accessed
- Success/failure status
- Reason for success/failure

## Router Integration

### Updating Routers to Use Endpoint-Specific Auth

**Before (Vulnerable):**
```gdscript
var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
    # Generic auth check - allows unauthenticated GET!
    if not SecurityConfig.validate_auth(request):
        response.send(401, JSON.stringify(
            SecurityConfig.create_auth_error_response()
        ))
        return true
```

**After (Secure):**
```gdscript
var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
    var client_ip = _extract_client_ip(request)
    var endpoint = "/auth/metrics"
    var method = "GET"

    # Use endpoint-specific auth validation
    var auth_result = SecurityConfig.validate_auth_with_endpoint(
        request, endpoint, method, client_ip
    )

    if not auth_result.authorized:
        response.send(401, JSON.stringify(
            SecurityConfig.create_auth_error_response()
        ))
        return true

    # Log successful access
    HttpApiAuditLogger.log_auth_attempt(client_ip, endpoint, true, auth_result.reason)

    # Proceed with handler logic...
```

## Configuration

### Adding Public Endpoints

```gdscript
# In security_config.gd static initialization
_public_endpoints["/my_health_endpoint"] = ["GET", "OPTIONS"]
```

### Adding Sensitive Endpoints

```gdscript
# Mark entire endpoint family as sensitive
_sensitive_endpoints.append("/sensitive_data/")
_sensitive_endpoints.append("/secret_metrics")
```

### Adding Role-Protected Endpoints

```gdscript
# Require specific roles
_role_protected_endpoints["/admin/users"] = ["admin"]
_role_protected_endpoints["/admin/audit"] = ["admin", "auditor"]
```

### JWT Token with Roles

When generating JWT tokens, include roles claim:

```gdscript
var payload = {
    "user_id": "user123",
    "roles": ["admin", "auditor"]  # Include roles
}
var token = SecurityConfig.generate_jwt_token(payload)
```

## Audit Logging

All authentication attempts are logged with:

```
[AUTH_SUCCESS] /auth/metrics: 127.0.0.1 (Valid token)
[AUTH_FAILURE] /auth/audit: 127.0.0.1 (Invalid or missing token)
[AUTH_SUCCESS] /health: 127.0.0.1 (Public endpoint (GET))
[AUTH_SUCCESS] OPTIONS: 127.0.0.1 (CORS preflight (OPTIONS))
[AUTH_FAILURE] /admin/users: 192.168.1.1 (Insufficient role: required [admin])
```

Log file location: `user://logs/http_api_audit.log`

## Security Best Practices

### 1. Principle of Least Privilege

Mark endpoints as sensitive unless they are explicitly public:

```gdscript
# DEFAULT: All endpoints require auth
# Explicitly whitelist public endpoints only
_public_endpoints["/health"] = ["GET", "OPTIONS"]
```

### 2. Consistent Authentication Across All Routers

All routers must use `validate_auth_with_endpoint()`:

```gdscript
# File: auth_router.gd
var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
    var auth_result = SecurityConfig.validate_auth_with_endpoint(
        request, "/auth/metrics", "GET", _extract_client_ip(request)
    )
    if not auth_result.authorized:
        response.send(401, JSON.stringify(
            SecurityConfig.create_auth_error_response()
        ))
        return true
```

### 3. Role-Based Access Control

Always validate roles for admin endpoints:

```gdscript
# Endpoints requiring specific roles
_role_protected_endpoints["/admin/config"] = ["admin"]
_role_protected_endpoints["/admin/audit"] = ["admin", "auditor"]

# Validation happens automatically in validate_auth_with_endpoint()
```

### 4. Monitor Audit Logs

Regular audit log review for suspicious patterns:

```bash
# Check for failed auth attempts
grep "AUTH_FAILURE" user://logs/http_api_audit.log | tail -100

# Check for unauthorized role attempts
grep "Insufficient role" user://logs/http_api_audit.log

# Check for public endpoint access
grep "Public endpoint" user://logs/http_api_audit.log
```

## Testing

### Test Cases

1. **Public Endpoint Access (No Auth)**
```bash
curl http://127.0.0.1:8080/health
# Should return 200 OK
```

2. **Sensitive Endpoint Without Auth (Should Fail)**
```bash
curl http://127.0.0.1:8080/auth/metrics
# Should return 401 Unauthorized
```

3. **Sensitive Endpoint With Valid Token (Should Succeed)**
```bash
TOKEN="<valid_jwt_token>"
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/auth/metrics
# Should return 200 OK with metrics
```

4. **CORS Preflight (OPTIONS)**
```bash
curl -X OPTIONS http://127.0.0.1:8080/auth/metrics
# Should return 200 OK (CORS preflight always allowed)
```

5. **Role-Protected Endpoint Without Role (Should Fail)**
```bash
# Token with only "user" role, trying to access "/admin/users" (requires "admin")
TOKEN="<jwt_with_user_role>"
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/admin/users
# Should return 401 Unauthorized (insufficient permissions)
```

## Migration Checklist

- [ ] Review all routers in `scripts/http_api/`
- [ ] Update each router to use `validate_auth_with_endpoint()`
- [ ] Add client_ip extraction to each router
- [ ] Define endpoint parameter for each route
- [ ] Add sensitive endpoints to `_sensitive_endpoints` array
- [ ] Add role requirements to `_role_protected_endpoints` dict
- [ ] Update JWT token generation to include roles
- [ ] Test with and without authentication
- [ ] Test CORS preflight requests
- [ ] Monitor audit logs for suspicious activity
- [ ] Document all protected endpoints

## Files Modified

1. **C:/godot/scripts/http_api/security_config.gd**
   - Added endpoint-specific authentication rules
   - Added public endpoint whitelist
   - Added sensitive endpoint list
   - Added role-based access control
   - Added `validate_auth_with_endpoint()` function
   - Added `_validate_role_access()` function
   - Added `_log_auth_attempt()` function
   - Added `is_public_endpoint()` function
   - Added `is_sensitive_endpoint()` function

## Summary

This fix prevents authentication bypass by:

1. **Explicit Whitelisting** - Only explicitly marked endpoints are public
2. **Sensitive Endpoint Protection** - Marked endpoints always require auth
3. **Role-Based Access Control** - Admin operations require specific roles
4. **Comprehensive Auditing** - All auth attempts are logged
5. **CORS Support** - OPTIONS requests still work for CORS preflight

**Impact:**
- Closes CVSS 8.1 authentication bypass vulnerability
- Provides defense-in-depth with multiple security layers
- Enables future role-based permission systems
- Creates complete audit trail for compliance
