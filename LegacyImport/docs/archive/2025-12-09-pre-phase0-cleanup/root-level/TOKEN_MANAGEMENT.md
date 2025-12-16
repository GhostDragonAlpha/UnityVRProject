# Token Management Guide

This guide explains the API token rotation and refresh system implemented in the Godot HTTP API.

## Overview

The token management system provides secure, rotating API tokens with automatic expiry, refresh capabilities, and comprehensive audit logging. This enhances security by ensuring tokens have limited lifetimes and can be rotated without service interruption.

## Key Features

- **Automatic Token Rotation**: Tokens automatically rotate every 24 hours
- **Grace Period**: During rotation, old tokens remain valid for 1 hour to prevent service disruption
- **Token Refresh**: Extend token lifetime without changing the token secret
- **Multiple Active Tokens**: Support multiple valid tokens simultaneously during transitions
- **Token Revocation**: Immediately invalidate tokens when needed
- **Comprehensive Auditing**: All token operations are logged for security review
- **Metrics Tracking**: Monitor token usage, rotations, and rejections
- **Persistent Storage**: Tokens persist across Godot restarts

## Token Lifecycle

### Token Structure

Each token has the following properties:

- **Token ID**: UUID v4 identifier for the token
- **Token Secret**: 32-byte (64 hex character) secret used in Authorization header
- **Created Timestamp**: When the token was generated
- **Expiry Timestamp**: When the token expires (default: 24 hours from creation)
- **Last Used Timestamp**: Last time the token was validated
- **Revoked Flag**: Whether the token has been revoked
- **Refresh Count**: How many times the token has been refreshed

### Token States

1. **Active**: Valid, non-expired, non-revoked token
2. **Expired**: Token past its expiry time (rejected on validation)
3. **Revoked**: Token manually invalidated (rejected on validation)
4. **Grace Period**: Old token during rotation overlap period

## API Endpoints

### POST /auth/rotate

Rotate to a new token. The old token remains valid for a grace period.

**Request:**
```bash
curl -X POST http://127.0.0.1:8080/auth/rotate \
  -H "Authorization: Bearer <current_token>"
```

**Response:**
```json
{
  "success": true,
  "message": "Token rotated successfully",
  "new_token": "1a2b3c4d...",
  "token_id": "550e8400-e29b-41d4-a716-446655440000",
  "expires_at": 1733270400.0,
  "expires_in_seconds": 86400,
  "grace_period_seconds": 3600,
  "old_token_id": "450e8400-e29b-41d4-a716-446655440000",
  "note": "Old token remains valid for grace period"
}
```

### POST /auth/refresh

Refresh current token to extend its expiry time.

**Request:**
```bash
curl -X POST http://127.0.0.1:8080/auth/refresh \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"extension_hours": 24.0}'
```

**Response:**
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "token_id": "550e8400-e29b-41d4-a716-446655440000",
  "expires_at": 1733270400.0,
  "expires_in_seconds": 86400,
  "refresh_count": 3,
  "note": "Token expiry extended, same token secret remains valid"
}
```

### POST /auth/revoke

Revoke a token immediately.

**Request:**
```bash
curl -X POST http://127.0.0.1:8080/auth/revoke \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"reason": "security_breach"}'
```

**Response:**
```json
{
  "success": true,
  "message": "Token revoked successfully",
  "token_id": "550e8400-e29b-41d4-a716-446655440000",
  "reason": "security_breach",
  "note": "Token is now invalid and cannot be used"
}
```

### GET /auth/status

Get current token status and metadata.

**Request:**
```bash
curl http://127.0.0.1:8080/auth/status \
  -H "Authorization: Bearer <token>"
```

**Response:**
```json
{
  "valid": true,
  "token_id": "550e8400-e29b-41d4-a716-446655440000",
  "created_at": 1733184000.0,
  "expires_at": 1733270400.0,
  "expires_in_seconds": 86400,
  "last_used_at": 1733184100.0,
  "refresh_count": 0,
  "age_seconds": 100,
  "expires_in_hours": 24.0
}
```

### GET /auth/metrics

Get token management metrics.

**Request:**
```bash
curl http://127.0.0.1:8080/auth/metrics
```

**Response:**
```json
{
  "success": true,
  "metrics": {
    "token_rotations_total": 5,
    "token_refreshes_total": 12,
    "token_revocations_total": 2,
    "expired_tokens_rejected_total": 8,
    "invalid_tokens_rejected_total": 15,
    "tokens_created_total": 7,
    "active_tokens_count": 2,
    "total_tokens_count": 7
  }
}
```

### GET /auth/audit

Get token audit log (recent events).

**Request:**
```bash
curl http://127.0.0.1:8080/auth/audit \
  -H "Content-Type: application/json" \
  -d '{"limit": 50}'
```

**Response:**
```json
{
  "success": true,
  "audit_log": [
    {
      "timestamp": 1733184100.0,
      "event_type": "token_rotated",
      "details": {
        "new_token_id": "550e8400-e29b-41d4-a716-446655440000",
        "old_token_id": "450e8400-e29b-41d4-a716-446655440000",
        "grace_period_hours": 1
      }
    },
    {
      "timestamp": 1733180500.0,
      "event_type": "token_refreshed",
      "details": {
        "token_id": "450e8400-e29b-41d4-a716-446655440000",
        "new_expiry": 1733266900.0,
        "refresh_count": 1
      }
    }
  ],
  "count": 2
}
```

## Python Client Usage

### Basic Usage

```python
from godot_api_client import GodotAPIClient

# Create client with auto-refresh enabled
client = GodotAPIClient(
    base_url="http://127.0.0.1:8080",
    auto_refresh=True,
    refresh_threshold_hours=1.0  # Refresh when <1 hour until expiry
)

# Make authenticated requests
status = client.get_status()

# Token is automatically refreshed when needed
# Token is automatically stored in ~/.godot_api/token.json
```

### Manual Token Operations

```python
# Manually refresh token
client.refresh_token(extension_hours=24.0)

# Manually rotate token
client.rotate_token()

# Revoke token
client.revoke_token(reason="user_logout")

# Check token status
status = client.get_token_status()
print(f"Token expires in {status['expires_in_hours']:.1f} hours")
```

### Automatic Refresh

The client automatically refreshes tokens in the background:

```python
# Client refreshes token when expiry is within threshold
client = GodotAPIClient(
    auto_refresh=True,
    refresh_threshold_hours=1.0  # Refresh when <1 hour remaining
)

# Background thread monitors token and refreshes automatically
# No action needed from your code

# Clean up when done
client.close()
```

### Context Manager

```python
# Use context manager for automatic cleanup
with GodotAPIClient(auto_refresh=True) as client:
    # Make API calls
    status = client.get_status()

# Client automatically closed, refresh thread stopped
```

### Handling 401 Errors

The client automatically retries on 401 errors:

```python
# If a request gets 401 (token expired/revoked)
# Client automatically attempts to refresh token and retry
try:
    result = client.get_token_status()
except requests.HTTPError as e:
    # Only raised if refresh also failed
    print(f"Authentication failed: {e}")
```

## Token Storage

### Storage Location

Tokens are stored in:
- **Godot**: `user://tokens/active_tokens.json`
- **Python Client**: `~/.godot_api/token.json`

### Storage Format (Godot)

```json
{
  "version": 1,
  "saved_at": 1733184100.0,
  "tokens": [
    {
      "token_id": "550e8400-e29b-41d4-a716-446655440000",
      "token_secret": "1a2b3c4d5e6f...",
      "created_at": 1733184000.0,
      "expires_at": 1733270400.0,
      "last_used_at": 1733184100.0,
      "revoked": false,
      "refresh_count": 0
    }
  ]
}
```

### Storage Format (Python Client)

```json
{
  "token_secret": "1a2b3c4d5e6f...",
  "token_id": "550e8400-e29b-41d4-a716-446655440000",
  "expires_at": 1733270400.0,
  "refresh_count": 0,
  "saved_at": 1733184100.0
}
```

## Security Best Practices

### 1. Token Rotation

Rotate tokens regularly, especially:
- After security incidents
- When team members leave
- Periodically as a security measure

```python
# Rotate token
client.rotate_token()
```

### 2. Token Storage

- Tokens are stored with secure file permissions (0600 on Unix)
- Never commit token files to version control
- Add to `.gitignore`: `**/tokens/`, `~/.godot_api/`

### 3. Token Revocation

Revoke tokens immediately when:
- Security breach detected
- Token accidentally exposed
- User/service decommissioned

```python
# Revoke immediately
client.revoke_token(reason="security_breach")
```

### 4. Monitoring

Regularly review metrics and audit logs:

```python
# Check metrics
metrics = client.get_metrics()
print(f"Expired tokens rejected: {metrics['metrics']['expired_tokens_rejected_total']}")

# Review audit log
audit = client.get_audit_log(limit=100)
for event in audit['audit_log']:
    print(f"{event['timestamp']}: {event['event_type']}")
```

### 5. Automatic Refresh

Enable auto-refresh to prevent service disruption:

```python
# Auto-refresh prevents expired token errors
client = GodotAPIClient(
    auto_refresh=True,
    refresh_threshold_hours=1.0
)
```

## Configuration

### Godot Configuration

Edit `scripts/http_api/token_manager.gd`:

```gdscript
# Token lifetime (hours)
const DEFAULT_TOKEN_LIFETIME_HOURS = 24

# Grace period during rotation (hours)
const ROTATION_OVERLAP_HOURS = 1

# Enable automatic rotation
const AUTO_ROTATION_ENABLED = true

# Maximum active tokens (prevent unbounded growth)
const MAX_ACTIVE_TOKENS = 10
```

### Disable Token Manager (Use Legacy Mode)

In `scripts/http_api/security_config.gd`:

```gdscript
# Disable token manager, use legacy single token
static var use_token_manager: bool = false
```

## Migration from Legacy Tokens

The system automatically migrates legacy tokens on first startup:

1. Legacy token from `SecurityConfig.get_token()` is detected
2. Token is converted to new format with UUID and expiry
3. Token is saved to persistent storage
4. Legacy token remains usable during grace period

No manual migration needed!

## Troubleshooting

### Token Not Found

**Symptom**: `401 Unauthorized - Token not found`

**Solution**: Generate a new token or get token from Godot console output

### Token Expired

**Symptom**: `401 Unauthorized - Token has expired`

**Solutions**:
1. Enable auto-refresh in client
2. Manually refresh token: `client.refresh_token()`
3. Rotate to new token: `client.rotate_token()`

### Token Revoked

**Symptom**: `401 Unauthorized - Token has been revoked`

**Solution**: Get a new token from Godot or rotate to new token

### Auto-Refresh Not Working

**Checklist**:
1. Verify `auto_refresh=True` in client constructor
2. Check token expiry is properly set: `client.get_token_status()`
3. Ensure background thread is running: `client._refresh_thread.is_alive()`
4. Check client logs for refresh errors

### Storage Permissions

**Issue**: Cannot save/load tokens

**Solutions**:
1. Check directory permissions: `~/.godot_api/` (Python) or `user://tokens/` (Godot)
2. Create directory manually with proper permissions
3. On Unix: `mkdir -p ~/.godot_api && chmod 700 ~/.godot_api`

## Advanced Usage

### Custom Storage Location

```python
# Use custom storage directory
client = GodotAPIClient(
    storage_dir="/path/to/custom/storage"
)
```

### Custom Refresh Threshold

```python
# Refresh when 30 minutes remaining
client = GodotAPIClient(
    auto_refresh=True,
    refresh_threshold_hours=0.5
)
```

### Multiple Clients

```python
# Multiple clients share same token storage
client1 = GodotAPIClient()
client2 = GodotAPIClient()

# client2 uses token saved by client1
# Both clients auto-refresh independently
```

### Metrics Collection

```python
import time

# Collect metrics periodically
while True:
    metrics = client.get_metrics()

    # Log to monitoring system
    log_metric("token_rotations", metrics["metrics"]["token_rotations_total"])
    log_metric("active_tokens", metrics["metrics"]["active_tokens_count"])

    time.sleep(60)
```

## API Reference

### GodotAPIClient

```python
class GodotAPIClient:
    def __init__(
        self,
        base_url: str = "http://127.0.0.1:8080",
        token: str = None,
        auto_refresh: bool = True,
        refresh_threshold_hours: float = 1.0,
        storage_dir: str = None
    )

    def get_token_status(self) -> Dict[str, Any]
    def refresh_token(self, extension_hours: float = 24.0) -> Dict[str, Any]
    def rotate_token(self) -> Dict[str, Any]
    def revoke_token(self, reason: str = "manual_revocation") -> Dict[str, Any]
    def get_metrics(self) -> Dict[str, Any]
    def get_audit_log(self, limit: int = 100) -> Dict[str, Any]
    def close(self) -> None
```

### TokenStorage

```python
class TokenStorage:
    def __init__(self, storage_dir: str = None)
    def save_token(self, token_data: Dict[str, Any]) -> None
    def load_token(self) -> Optional[Dict[str, Any]]
    def delete_token(self) -> None
```

## Example Workflows

### Service Startup

```python
# Load or generate token
client = GodotAPIClient(auto_refresh=True)

# Verify token works
status = client.get_token_status()
print(f"Token valid until: {datetime.fromtimestamp(status['expires_at'])}")

# Start using API
while True:
    # Token automatically refreshed in background
    result = client.get_status()
    time.sleep(60)
```

### Security Incident Response

```python
# 1. Revoke compromised token
client.revoke_token(reason="security_incident_2024_12_02")

# 2. Rotate to new token
new_token_result = client.rotate_token()

# 3. Update all services with new token
distribute_new_token(new_token_result["new_token"])

# 4. Review audit log
audit = client.get_audit_log(limit=1000)
analyze_for_suspicious_activity(audit["audit_log"])
```

### Scheduled Maintenance

```python
# Rotate tokens as part of regular maintenance
def monthly_token_rotation():
    client = GodotAPIClient()

    # Rotate token
    result = client.rotate_token()

    # Notify team
    send_notification(f"Token rotated: {result['token_id']}")

    # Log for audit
    log_maintenance("token_rotation", result)

# Run monthly
schedule.every().month.at("02:00").do(monthly_token_rotation)
```

## Support

For issues or questions:
1. Check this documentation
2. Review audit logs: `client.get_audit_log()`
3. Check metrics: `client.get_metrics()`
4. Review Godot console output for token system logs
5. See `addons/godot_debug_connection/HTTP_API.md` for API details
