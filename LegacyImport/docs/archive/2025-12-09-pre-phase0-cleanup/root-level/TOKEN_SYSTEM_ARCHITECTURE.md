# Token Management System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Godot HTTP API Server                       │
│                     (GodotBridge - Port 8080)                    │
└─────────────────────────────────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
        ┌───────────▼──────────┐   ┌─────────▼─────────┐
        │   SecurityConfig     │   │   AuthRouter      │
        │  - Token validation  │   │  - /auth/rotate   │
        │  - Auth checking     │   │  - /auth/refresh  │
        │  - Integration layer │   │  - /auth/revoke   │
        └───────────┬──────────┘   │  - /auth/status   │
                    │              │  - /auth/metrics  │
                    │              │  - /auth/audit    │
        ┌───────────▼──────────┐   └───────────────────┘
        │   TokenManager       │
        │  - Token generation  │
        │  - Validation        │
        │  - Rotation          │
        │  - Refresh           │
        │  - Revocation        │
        │  - Auto-rotation     │
        │  - Cleanup           │
        │  - Metrics           │
        │  - Audit logging     │
        └───────────┬──────────┘
                    │
        ┌───────────▼──────────┐
        │  Persistent Storage  │
        │  user://tokens/      │
        │  active_tokens.json  │
        └──────────────────────┘
```

## Token Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                         Token Lifecycle                          │
└─────────────────────────────────────────────────────────────────┘

    ┌───────────┐
    │  Created  │  • Generate UUID + Secret
    │   (New)   │  • Set 24h expiry
    └─────┬─────┘  • Save to storage
          │
          │ Used by clients
          ▼
    ┌───────────┐
    │  Active   │  • Validates requests
    │  (Valid)  │  • Updates last_used
    └─────┬─────┘  • Tracks usage
          │
          ├─────────────────┬──────────────────┐
          │                 │                  │
          │ Expires         │ Refresh          │ Rotate
          ▼                 ▼                  ▼
    ┌───────────┐     ┌──────────┐      ┌──────────┐
    │  Expired  │     │ Extended │      │ New Token│
    │ (Invalid) │     │  (Active)│      │ + Grace  │
    └─────┬─────┘     └────┬─────┘      └────┬─────┘
          │                │                   │
          │ 24h grace      │ Continue          │
          ▼                ▼                   ▼
    ┌───────────┐     ┌──────────┐      ┌──────────┐
    │  Cleaned  │     │  Active  │      │  Active  │
    │ (Removed) │     │          │      │(New+Old) │
    └───────────┘     └──────────┘      └────┬─────┘
                                              │
                                              │ 1h grace
                                              ▼
                                        ┌──────────┐
                                        │  Active  │
                                        │(New Only)│
                                        └──────────┘

    Revoke ────────────────────────────────────────┐
                                                    │
                                                    ▼
                                              ┌──────────┐
                                              │ Revoked  │
                                              │(Invalid) │
                                              └────┬─────┘
                                                   │ 24h grace
                                                   ▼
                                              ┌──────────┐
                                              │ Cleaned  │
                                              │(Removed) │
                                              └──────────┘
```

## Token Rotation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Token Rotation Process                        │
└─────────────────────────────────────────────────────────────────┘

Time: T₀                     T₀ + 1h                    T₀ + 24h
      │                           │                          │
      ▼                           ▼                          ▼

┌─────────────────────────────────────────────────────────────────┐
│ Token A (Active)                                                 │
│ • Created: T₀ - 24h                                              │
│ • Expires: T₀ + 0h  ◄───── About to expire                      │
└─────────────────────────────────────────────────────────────────┘
      │
      │ Rotation Request
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ Token A (Grace)         Token B (Active)                         │
│ • Expires: T₀ + 1h      • Created: T₀                            │
│ • Status: Grace Period  • Expires: T₀ + 24h                      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ 1 hour passes
                                ▼
                          ┌─────────────────────────────────────┐
                          │ Token B (Active)                    │
                          │ • Expires: T₀ + 24h                 │
                          │                                     │
                          │ Token A expired, will be cleaned    │
                          └─────────────────────────────────────┘

Benefits:
✓ No service disruption (old token works during transition)
✓ Clients have time to update to new token
✓ Automatic cleanup after grace period
✓ Multiple clients can update at different times
```

## Client Auto-Refresh Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  Python Client Auto-Refresh                      │
└─────────────────────────────────────────────────────────────────┘

Main Thread                    Background Thread
     │                                │
     │ Create client                  │
     │ auto_refresh=True              │
     ├────────────────────────────────┤
     │                                │ Start monitoring
     │                                │ (every 5 min)
     │                                ▼
     │                          Check expiry
     │                                │
     │                                ├─── < threshold? ──┐
     │                                │                   │
     │                                │                   ▼
     │                                │              Refresh token
     │                                │                   │
     │ Make API request               │                   │
     ├────────────────────────────────┤                   │
     │ GET /status                    │                   │
     ├────────────────►               │                   │
     │                  200 OK        │                   │
     │◄────────────────               │                   │
     │                                │                   │
     │                                ▼                   │
     │                          Check expiry              │
     │                                │                   │
     │                                │                   │
     │ Make API request               │                   │
     ├────────────────────────────────┤                   │
     │ GET /status                    │                   │
     ├────────────────►               │                   │
     │                  401 Unauth    │                   │
     │◄────────────────               │                   │
     │ Retry with refresh             │                   │
     │ POST /auth/refresh             │                   │
     ├────────────────►               │                   │
     │                  200 OK        │                   │
     │◄────────────────               │                   │
     │ Retry original request         │                   │
     ├────────────────►               │                   │
     │                  200 OK        │                   │
     │◄────────────────               │                   │
     │                                │                   │
     │ client.close()                 │                   │
     ├────────────────────────────────┤                   │
     │                                │ Stop thread       │
     │                                ▼                   │
     │                          Thread exits              │
     ▼                                ▼                   ▼

Benefits:
✓ Automatic token refresh (no manual intervention)
✓ Handles expired tokens gracefully
✓ Background monitoring doesn't block main thread
✓ Automatic retry on 401 errors
✓ Configurable refresh threshold
```

## Storage Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Storage Locations                           │
└─────────────────────────────────────────────────────────────────┘

Godot Server:
  user://tokens/active_tokens.json
  └── C:\Users\<user>\AppData\Roaming\Godot\app_userdata\<project>\tokens\

Python Client:
  ~/.godot_api/token.json
  └── /home/<user>/.godot_api/  (Linux/Mac)
  └── C:\Users\<user>\.godot_api\  (Windows)


Godot Storage Format:
{
  "version": 1,
  "saved_at": 1733184100.0,
  "tokens": [
    {
      "token_id": "550e8400-e29b-41d4-a716-446655440000",
      "token_secret": "1a2b3c4d5e6f7890...",
      "created_at": 1733184000.0,
      "expires_at": 1733270400.0,
      "last_used_at": 1733184100.0,
      "revoked": false,
      "refresh_count": 0
    }
  ]
}

Python Storage Format:
{
  "token_secret": "1a2b3c4d5e6f7890...",
  "token_id": "550e8400-e29b-41d4-a716-446655440000",
  "expires_at": 1733270400.0,
  "refresh_count": 0,
  "saved_at": 1733184100.0
}
```

## Metrics and Monitoring

```
┌─────────────────────────────────────────────────────────────────┐
│                      Metrics Dashboard                           │
└─────────────────────────────────────────────────────────────────┘

GET /auth/metrics

Operational Metrics:
├── active_tokens_count: 2          ◄── Currently valid tokens
├── total_tokens_count: 7           ◄── All tokens (incl. expired)
└── token_rotations_total: 5        ◄── Total rotations performed

Usage Metrics:
├── token_refreshes_total: 12       ◄── Total refreshes
├── token_revocations_total: 2      ◄── Total revocations
└── tokens_created_total: 7         ◄── Total tokens generated

Security Metrics:
├── expired_tokens_rejected_total: 8   ◄── Expired token attempts
└── invalid_tokens_rejected_total: 15  ◄── Invalid token attempts

Alert Thresholds:
• High expired rejections → May indicate clients not refreshing
• High invalid rejections → Possible attack or misconfiguration
• Many active tokens → Check cleanup is running
• No rotations → Auto-rotation may be disabled
```

## Audit Log Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                         Audit Log                                │
└─────────────────────────────────────────────────────────────────┘

GET /auth/audit?limit=100

Event Types:
├── token_created
│   └── Details: token_id, expires_at
├── token_rotated
│   └── Details: new_token_id, old_token_id, grace_period_hours
├── token_refreshed
│   └── Details: token_id, new_expiry, refresh_count
├── token_revoked
│   └── Details: token_id, reason
├── token_rejected
│   └── Details: token_id, reason (expired/revoked)
├── token_cleaned
│   └── Details: token_id
└── legacy_token_migrated
    └── Details: token_id, migrated_at

Example Entry:
{
  "timestamp": 1733184100.0,
  "event_type": "token_rotated",
  "details": {
    "new_token_id": "550e8400-e29b-41d4-a716-446655440000",
    "old_token_id": "450e8400-e29b-41d4-a716-446655440000",
    "grace_period_hours": 1
  }
}

Max Size: 1000 entries (configurable)
Retention: In-memory, not persisted across restarts
Use Case: Security auditing, debugging, compliance
```

## Security Model

```
┌─────────────────────────────────────────────────────────────────┐
│                      Security Layers                             │
└─────────────────────────────────────────────────────────────────┘

Layer 1: Network
├── Localhost only (127.0.0.1)
├── No external access
└── Future: TLS/HTTPS

Layer 2: Authentication
├── Bearer token required
├── Token validation on every request
├── Automatic expiry (24h default)
└── Immediate revocation capability

Layer 3: Token Management
├── Cryptographically secure generation (32 bytes)
├── UUID v4 identification
├── Grace period for rotation (1h)
└── Automatic cleanup of old tokens

Layer 4: Monitoring
├── Comprehensive metrics
├── Full audit logging
├── Rejection tracking
└── Usage analytics

Layer 5: Rate Limiting (Future)
├── Per-IP rate limits
├── Per-endpoint limits
└── Token bucket algorithm

Attack Mitigations:
✓ Token expiry → Limits exposure window
✓ Token rotation → Regular key changes
✓ Token revocation → Immediate invalidation
✓ Audit logging → Forensic analysis
✓ Secure storage → Protected token files
✓ Rejection tracking → Attack detection
```

## Integration Points

```
┌─────────────────────────────────────────────────────────────────┐
│                    System Integration                            │
└─────────────────────────────────────────────────────────────────┘

GodotBridge (godot_bridge.gd)
├── Initialization
│   ├── HttpApiSecurityConfig.initialize_token_manager()
│   └── auth_router = HttpApiAuthRouter.new(...)
│
├── Request Routing
│   ├── /auth/* → _handle_auth_endpoint()
│   ├── Authentication check for all other endpoints
│   └── Token validation via SecurityConfig
│
└── Process Loop
    ├── HttpApiSecurityConfig.process(delta)
    ├── Auto-rotation checks
    └── Token cleanup

SecurityConfig (security_config.gd)
├── Token Manager Integration
│   ├── initialize_token_manager()
│   ├── get_token_manager()
│   └── validate_auth(headers)
│
└── Process Hook
    ├── Auto-rotation trigger
    └── Periodic cleanup

TokenManager (token_manager.gd)
├── Core Operations
│   ├── generate_token()
│   ├── validate_token()
│   ├── rotate_token()
│   ├── refresh_token()
│   └── revoke_token()
│
├── Maintenance
│   ├── check_auto_rotation()
│   └── cleanup_tokens()
│
└── Monitoring
    ├── get_metrics()
    └── get_audit_log()

AuthRouter (auth_router.gd)
├── Endpoint Routing
│   ├── /auth/rotate
│   ├── /auth/refresh
│   ├── /auth/revoke
│   ├── /auth/status
│   ├── /auth/metrics
│   └── /auth/audit
│
└── Request Handling
    ├── Header validation
    ├── Body parsing
    └── Response formatting
```

## Deployment Checklist

```
┌─────────────────────────────────────────────────────────────────┐
│                    Deployment Steps                              │
└─────────────────────────────────────────────────────────────────┘

Pre-Deployment:
☐ Review configuration (token lifetime, grace period)
☐ Test all auth endpoints
☐ Run full test suite (28 tests)
☐ Verify storage directories exist
☐ Check file permissions (0600 for token files)

Deployment:
☐ Integrate AuthRouter into GodotBridge
☐ Add _handle_auth_endpoint() handler
☐ Update _route_request() with auth checks
☐ Add HttpApiSecurityConfig.process(delta) to _process()
☐ Update startup messages with auth endpoints

Post-Deployment:
☐ Verify token generation on startup
☐ Test token validation
☐ Test rotation and refresh
☐ Verify auto-rotation works
☐ Check metrics are tracking
☐ Review audit log entries

Client Updates:
☐ Distribute new Python client library
☐ Update all client applications
☐ Enable auto-refresh in production clients
☐ Set up token storage directories
☐ Configure refresh thresholds

Monitoring:
☐ Set up metrics collection
☐ Configure alerts for anomalies
☐ Schedule audit log reviews
☐ Monitor token rejection rates
☐ Track rotation frequency
```

## Performance Characteristics

```
┌─────────────────────────────────────────────────────────────────┐
│                    Performance Profile                           │
└─────────────────────────────────────────────────────────────────┘

Operation              Time       Memory     Notes
─────────────────────────────────────────────────────────────────
Token Generation       < 1ms      ~500B      One-time cost
Token Validation       < 0.1ms    0B         Dictionary lookup
Token Rotation         < 2ms      ~1KB       Creates new token
Token Refresh          < 1ms      0B         Updates expiry
Token Revocation       < 1ms      0B         Sets flag
Storage Save           < 1ms      ~5KB       JSON serialization
Storage Load           < 1ms      ~5KB       JSON parsing
Auto-rotation Check    < 0.01ms   0B         Timestamp comparison
Cleanup               < 5ms       0B         Removes old tokens
Metrics Query         < 0.01ms    ~1KB       Returns counters
Audit Log Query       < 0.1ms     ~100KB     Returns array slice

Overall Impact: Negligible
• Request latency: +0.1ms per request (validation)
• Memory usage: ~5KB for 10 active tokens
• Storage I/O: Only on token operations (not per request)
• Background threads: Python client only (minimal CPU)
```

This architecture provides enterprise-grade token management with minimal performance impact and comprehensive security features.
