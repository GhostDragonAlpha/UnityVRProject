# JWT Authentication Audit Logging Flow Diagram

## Complete Request Flow with Audit Logging

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CLIENT REQUEST WITH JWT TOKEN                        │
│                     GET /scene HTTP/1.1                                      │
│              Authorization: Bearer eyJhbGciOiAiSFMyNTYi...                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        HTTP ROUTER (e.g., SceneRouter)                      │
│                                                                              │
│  1. Receive HTTP request with Authorization header                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                   SecurityConfig.validate_auth(headers)                     │
│                                                                              │
│  1. Extract Authorization header                                            │
│     - Try "Authorization" and "authorization" (case-insensitive)            │
│                                                                              │
│  2. Validate Bearer format                                                  │
│     - Check: "Bearer " prefix                                               │
│     - If missing/invalid → RETURN FALSE                                     │
│                                                                              │
│  3. Extract token secret                                                    │
│     - Remove "Bearer " prefix and trim                                      │
│                                                                              │
│  4. Route to appropriate validator:                                         │
│     ├─ If use_jwt=true:                                                     │
│     │   └─→ JWT.decode(token_secret)                                        │
│     └─ If use_token_manager=true:                                           │
│         └─→ TokenManager.validate_token(token_secret)                       │
│                                                                              │
│  Returns: boolean (true=valid, false=invalid)                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
            VALID (TRUE)                   INVALID (FALSE)
                    │                               │
                    ▼                               ▼
        ┌──────────────────────┐    ┌──────────────────────────────┐
        │   JWT.decode()       │    │  JWT.decode() OR             │
        │   Validates:         │    │  TokenManager.validate_token()│
        │ 1. Signature match   │    │  Returns error:              │
        │ 2. Token not expired │    │ - "No Authorization header"  │
        │ 3. Payload valid JSON│    │ - "Invalid signature"        │
        │                      │    │ - "Token expired"            │
        │ Returns:             │    │ - "Token has been revoked"   │
        │ {valid: true,        │    │ - "Token not found"          │
        │  payload: {...}}     │    │                              │
        │                      │    │ Returns:                     │
        │                      │    │ {valid: false,               │
        │                      │    │  error: "reason"}            │
        └──────────────────────┘    └──────────────────────────────┘
                    │                               │
                    ▼                               ▼
        ┌──────────────────────┐    ┌──────────────────────────────┐
        │  HTTP Router         │    │  HTTP Router                 │
        │  if valid==true      │    │  if valid==false             │
        │  audit_helper.       │    │  audit_helper.               │
        │  log_auth_success()  │    │  log_auth_failure(reason)    │
        │                      │    │                              │
        │  Send 200 OK         │    │  Send 401 Unauthorized       │
        └──────────────────────┘    └──────────────────────────────┘
                    │                               │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AuditHelper (Middleware)                             │
│                                                                              │
│  log_auth_success(request, endpoint):                                       │
│  ├─ user_id = get_user_id_from_request()                                    │
│  ├─ ip = get_ip_from_request()                                              │
│  └─ audit_logger.log_authentication(user_id, ip, endpoint, true, reason)    │
│                                                                              │
│  log_auth_failure(request, reason, endpoint):                               │
│  ├─ ip = get_ip_from_request()                                              │
│  └─ audit_logger.log_authentication("unknown", ip, endpoint, false, reason) │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      SecurityAuditLogger (Core)                             │
│                                                                              │
│  log_authentication(user_id, ip, endpoint, success, reason):                │
│                                                                              │
│  1. Determine event type and severity:                                      │
│     ├─ success=true  → event_type="authentication_success", severity="info" │
│     └─ success=false → event_type="authentication_failure", severity="warn" │
│                                                                              │
│  2. Increment event counter:                                                │
│     _event_counters[event_type] += 1                                        │
│                                                                              │
│  3. Create structured log entry:                                            │
│     {                                                                        │
│       "timestamp": 1701518400,                                              │
│       "timestamp_iso": "2025-12-02 12:00:00",                               │
│       "event_type": "authentication_success|failure",                       │
│       "severity": "info|warning",                                           │
│       "user_id": "550e8400-e29b-41d4-a716-446655440000",                    │
│       "ip_address": "127.0.0.1",                                            │
│       "endpoint": "/scene",                                                 │
│       "action": "authenticate",                                             │
│       "result": "success|failure",                                          │
│       "details": {                                                          │
│         "reason": "Valid token|Invalid signature|Token expired|...",        │
│         "token_validated": true|false                                       │
│       }                                                                      │
│     }                                                                        │
│                                                                              │
│  4. Sign entry (if USE_LOG_SIGNING=true):                                   │
│     entry["signature"] = HMAC-SHA256(canonical_data, signing_key)           │
│                                                                              │
│  5. Write to log file:                                                      │
│     _log_file.store_buffer(JSON.stringify(entry) + "\n")                    │
│     _log_file.flush()                                                       │
│                                                                              │
│  6. Check rotation:                                                         │
│     ├─ Daily rotation (new day)                                             │
│     └─ Size rotation (if >50MB)                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    AUDIT LOG FILE (JSON Lines Format)                       │
│                                                                              │
│  File: user://logs/security/audit_2025-12-02.jsonl                          │
│                                                                              │
│  Line 1: {"timestamp":1701518400,...,"event_type":"authentication_success"} │
│  Line 2: {"timestamp":1701518401,...,"event_type":"authentication_failure"} │
│  Line 3: {"timestamp":1701518402,...,"event_type":"authentication_failure"} │
│  ...                                                                         │
│                                                                              │
│  Features:                                                                  │
│  ├─ One JSON object per line (JSONL format)                                 │
│  ├─ HMAC-SHA256 signatures for tamper detection                             │
│  ├─ Daily rotation (new file each day)                                      │
│  ├─ Size-based rotation (new file when >50MB)                               │
│  └─ 30-day retention (auto-delete old files)                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## JWT Token Validation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│              JWT.decode(token_string, secret)                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────────┐
            │ 1. SPLIT TOKEN BY DOTS              │
            │    eyJhbGc.eyJ1c2.TJNK               │
            │    ├─ parts[0] = header_b64         │
            │    ├─ parts[1] = payload_b64        │
            │    └─ parts[2] = signature_b64      │
            └─────────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────────┐
            │ 2. VERIFY SIGNATURE                 │
            │    expected_sig = HMAC-SHA256(      │
            │      "header_b64.payload_b64",      │
            │      secret                         │
            │    )                                 │
            │    if expected_sig != signature_b64 │
            │      → return {valid: false,         │
            │               error: "Invalid sig"} │
            └─────────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────────┐
            │ 3. DECODE HEADER (base64url)        │
            │    {alg: "HS256", typ: "JWT"}       │
            │    Check: alg == "HS256"            │
            │    if alg != "HS256"                 │
            │      → return {valid: false,         │
            │               error: "Bad alg"}     │
            └─────────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────────┐
            │ 4. DECODE PAYLOAD (base64url)       │
            │    {user_id: "123",                 │
            │     role: "admin",                  │
            │     iat: 1701518400,                │
            │     exp: 1701604800}                │
            │    Validate JSON parse              │
            │    if JSON invalid                  │
            │      → return {valid: false,        │
            │               error: "Bad JSON"}    │
            └─────────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────────┐
            │ 5. CHECK EXPIRATION                 │
            │    now = current_unix_time          │
            │    if payload.exp < now             │
            │      → return {valid: false,        │
            │               error: "Expired"}     │
            └─────────────────────────────────────┘
                              │
                              ▼
            ┌─────────────────────────────────────┐
            │ 6. RETURN SUCCESS                   │
            │    {valid: true,                    │
            │     payload: {user_id, role, ...}}  │
            └─────────────────────────────────────┘
```

---

## Token Manager Lifecycle with Audit Events

```
┌──────────────────────────────────────────────────────────────────┐
│                      TOKEN LIFECYCLE                             │
└──────────────────────────────────────────────────────────────────┘

TOKEN CREATION
──────────────
generate_token()
├─ Generate token_id (UUID v4)
├─ Generate token_secret (32-byte hex)
├─ Set created_at, expires_at
├─ Store in _active_tokens dict
├─ _audit_log_event("token_created", {...})
└─ Save to disk (user://tokens/active_tokens.json)

    ┌─────────────────────────────────────────┐
    │ AUDIT LOG:                              │
    │ event_type: "token_created"             │
    │ details:                                │
    │   token_id: "550e8400-e29b-41d4..."     │
    │   expires_at: 1701604800                │
    └─────────────────────────────────────────┘

TOKEN VALIDATION (Authentication)
─────────────────────────────────
validate_token(token_secret)
│
├─ Check: token exists in _active_tokens
│  ├─ NOT FOUND → _audit_log_event("token_rejected", {reason:"not_found"})
│  │             return {valid: false, error: "Token not found"}
│  │
│  └─ FOUND → Check token status
│
├─ Check: token.revoked == false
│  ├─ REVOKED → _audit_log_event("token_rejected", {reason:"revoked"})
│  │            return {valid: false, error: "Token has been revoked"}
│  │
│  └─ NOT REVOKED → Check expiration
│
├─ Check: token.expires_at > now
│  ├─ EXPIRED → _audit_log_event("token_rejected", {reason:"expired"})
│  │            return {valid: false, error: "Token has expired"}
│  │
│  └─ VALID → Update usage and return
│
└─ Valid token:
   ├─ token.update_last_used()
   ├─ Save updated token
   └─ return {valid: true, token: {...}}

    ┌──────────────────────────────────────────┐
    │ AUDIT LOG (for failures):                │
    │ event_type: "token_rejected"             │
    │ details:                                 │
    │   token_id: "550e8400-e29b-41d4..."      │
    │   reason: "revoked|expired|not_found"   │
    └──────────────────────────────────────────┘

TOKEN ROTATION
──────────────
rotate_token(current_token_secret)
├─ Validate current token
├─ Generate new token (same as TOKEN CREATION)
├─ Set old token grace period
├─ _metrics.token_rotations_total += 1
├─ _audit_log_event("token_rotated", {...})
└─ Save to disk

    ┌──────────────────────────────────────────┐
    │ AUDIT LOG:                               │
    │ event_type: "token_rotated"              │
    │ details:                                 │
    │   new_token_id: "new-uuid"               │
    │   old_token_id: "old-uuid"               │
    │   grace_period_hours: 1                  │
    └──────────────────────────────────────────┘

TOKEN REFRESH
─────────────
refresh_token(token_secret, extension_hours)
├─ Validate current token
├─ Extend expiry: expires_at += extension_hours * 3600
├─ Increment refresh_count
├─ _metrics.token_refreshes_total += 1
├─ _audit_log_event("token_refreshed", {...})
└─ Save to disk

    ┌──────────────────────────────────────────┐
    │ AUDIT LOG:                               │
    │ event_type: "token_refreshed"            │
    │ details:                                 │
    │   token_id: "550e8400-e29b-41d4..."      │
    │   new_expiry: 1701604800                 │
    │   refresh_count: 2                       │
    └──────────────────────────────────────────┘

TOKEN REVOCATION
────────────────
revoke_token(token_secret, reason)
├─ Find token by secret
├─ Set token.revoked = true
├─ _metrics.token_revocations_total += 1
├─ _audit_log_event("token_revoked", {...})
└─ Save to disk

    ┌──────────────────────────────────────────┐
    │ AUDIT LOG:                               │
    │ event_type: "token_revoked"              │
    │ details:                                 │
    │   token_id: "550e8400-e29b-41d4..."      │
    │   reason: "manual_revocation|..."        │
    └──────────────────────────────────────────┘

TOKEN CLEANUP
─────────────
cleanup_tokens()
├─ Find tokens: revoked >24hrs old OR expired >24hrs old
├─ Remove from _active_tokens dict
├─ _audit_log_event("token_cleaned", {...})
└─ Save to disk

    ┌──────────────────────────────────────────┐
    │ AUDIT LOG:                               │
    │ event_type: "token_cleaned"              │
    │ details:                                 │
    │   token_id: "550e8400-e29b-41d4..."      │
    └──────────────────────────────────────────┘
```

---

## Authentication Failure Reasons and Log Entries

```
┌──────────────────────────────────────────────────────────────────┐
│         AUTHENTICATION FAILURE SCENARIOS & LOG ENTRIES           │
└──────────────────────────────────────────────────────────────────┘

1. MISSING AUTHORIZATION HEADER
   ┌────────────────────────────────────────────────────────────┐
   │ Request: GET /scene                                        │
   │          (no Authorization header)                         │
   └────────────────────────────────────────────────────────────┘

   SecurityConfig.validate_auth():
   ├─ auth_header = headers.get("Authorization", "")
   ├─ if auth_header.is_empty():
   │    print("[Security] Auth failed: No Authorization header")
   │    return false
   └─

   Log Entry:
   {
     "event_type": "authentication_failure",
     "severity": "warning",
     "user_id": "unknown",
     "ip_address": "127.0.0.1",
     "endpoint": "/scene",
     "result": "failure",
     "details": {
       "reason": "No Authorization header",
       "token_validated": false
     }
   }

2. MALFORMED AUTHORIZATION HEADER
   ┌────────────────────────────────────────────────────────────┐
   │ Request: GET /scene                                        │
   │          Authorization: BasicAuth xyz123                   │
   └────────────────────────────────────────────────────────────┘

   SecurityConfig.validate_auth():
   ├─ if not auth_header.begins_with("Bearer "):
   │    print("[Security] Auth failed: Invalid Authorization format...")
   │    return false
   └─

   Log Entry:
   {
     "event_type": "authentication_failure",
     "severity": "warning",
     "user_id": "unknown",
     "ip_address": "127.0.0.1",
     "endpoint": "/scene",
     "result": "failure",
     "details": {
       "reason": "Invalid Authorization format (expected 'Bearer <token>')",
       "token_validated": false
     }
   }

3. INVALID JWT SIGNATURE
   ┌────────────────────────────────────────────────────────────┐
   │ Request: GET /scene                                        │
   │          Authorization: Bearer eyJhbGc.eyJ1c.TAMPERED      │
   └────────────────────────────────────────────────────────────┘

   JWT.decode():
   ├─ expected_sig = HMAC-SHA256(header.payload, secret)
   ├─ if expected_sig != signature_b64:
   │    return {valid: false, error: "Invalid signature"}
   └─

   SecurityConfig.verify_jwt_token():
   ├─ result = JWT.decode(token, secret)
   ├─ if not result.valid:
   │    print("[Security] Auth failed: Invalid JWT")
   │    return false
   └─

   Log Entry:
   {
     "event_type": "authentication_failure",
     "severity": "warning",
     "user_id": "unknown",
     "ip_address": "127.0.0.1",
     "endpoint": "/scene",
     "result": "failure",
     "details": {
       "reason": "Invalid signature",
       "token_validated": false
     }
   }

4. TOKEN EXPIRED
   ┌────────────────────────────────────────────────────────────┐
   │ Request: GET /scene                                        │
   │          Authorization: Bearer <valid_but_expired_token>   │
   │          (token exp: 1701432000, now: 1701604800)          │
   └────────────────────────────────────────────────────────────┘

   JWT.decode():
   ├─ if payload.has("exp"):
   │    now = Time.get_unix_time_from_system()
   │    if int(payload.exp) < now:
   │       return {valid: false, error: "Token expired", payload: {...}}
   └─

   Log Entry:
   {
     "event_type": "authentication_failure",
     "severity": "warning",
     "user_id": "unknown",
     "ip_address": "127.0.0.1",
     "endpoint": "/scene",
     "result": "failure",
     "details": {
       "reason": "Token expired",
       "token_validated": false
     }
   }

5. TOKEN NOT FOUND (TokenManager)
   ┌────────────────────────────────────────────────────────────┐
   │ Request: GET /scene                                        │
   │          Authorization: Bearer unknown_token_secret        │
   └────────────────────────────────────────────────────────────┘

   TokenManager.validate_token():
   ├─ if not _active_tokens.has(token_secret):
   │    _metrics.invalid_tokens_rejected_total += 1
   │    _audit_log_event("token_rejected", {reason: "not_found"})
   │    return {valid: false, error: "Token not found"}
   └─

   Log Entry:
   {
     "event_type": "authentication_failure",
     "severity": "warning",
     "user_id": "unknown",
     "ip_address": "127.0.0.1",
     "endpoint": "/scene",
     "result": "failure",
     "details": {
       "reason": "Token not found",
       "token_validated": false
     }
   }

6. TOKEN REVOKED
   ┌────────────────────────────────────────────────────────────┐
   │ Request: GET /scene                                        │
   │          Authorization: Bearer <revoked_token>             │
   └────────────────────────────────────────────────────────────┘

   TokenManager.validate_token():
   ├─ if token.revoked:
   │    _metrics.invalid_tokens_rejected_total += 1
   │    _audit_log_event("token_rejected", {reason: "revoked"})
   │    return {valid: false, error: "Token has been revoked"}
   └─

   Log Entry:
   {
     "event_type": "authentication_failure",
     "severity": "warning",
     "user_id": "unknown",
     "ip_address": "127.0.0.1",
     "endpoint": "/scene",
     "result": "failure",
     "details": {
       "reason": "Token has been revoked",
       "token_validated": false
     }
   }
```

