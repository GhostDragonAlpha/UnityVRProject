# Configuration Reference

Complete reference for SpaceTime VR configuration system.

## Table of Contents

- [Overview](#overview)
- [Configuration Files](#configuration-files)
- [Environment Variables](#environment-variables)
- [Security Configuration](#security-configuration)
- [Networking Configuration](#networking-configuration)
- [Database Configuration](#database-configuration)
- [Cache Configuration](#cache-configuration)
- [Monitoring Configuration](#monitoring-configuration)
- [Logging Configuration](#logging-configuration)
- [Performance Configuration](#performance-configuration)
- [Feature Flags](#feature-flags)
- [Backup Configuration](#backup-configuration)
- [High Availability](#high-availability)
- [Configuration Validation](#configuration-validation)

---

## Overview

SpaceTime VR uses a multi-layered configuration system:

1. **JSON Configuration Files** - Environment-specific settings
2. **Environment Variables** - Runtime overrides and secrets
3. **GDScript Autoloads** - In-engine configuration management

### Configuration Hierarchy

```
.env.template              # Template with all available variables
.env                       # Local environment variables (not committed)
config/
  ├── development.json     # Development environment
  ├── staging.json         # Staging environment
  ├── production.json      # Production environment
  ├── security_production.json    # Hardened security profile
  └── performance_production.json # Performance-optimized profile
```

---

## Configuration Files

### File Structure

All configuration files follow this structure:

```json
{
  "$schema": "./config_schema.json",
  "version": "1.0.0",
  "environment": "development|staging|production",
  "description": "Configuration description",
  "last_updated": "2025-12-02",
  "security": { ... },
  "networking": { ... },
  "database": { ... },
  "cache": { ... },
  "monitoring": { ... },
  "logging": { ... },
  "performance": { ... },
  "feature_flags": { ... },
  "backup": { ... }
}
```

### Environment Selection

Set the active environment via environment variable:

```bash
export ENVIRONMENT=production
```

Or load directly in code:

```gdscript
var config = ConfigManager.load_config("production")
```

---

## Environment Variables

### Variable Interpolation

Configuration files support environment variable interpolation:

```json
{
  "database": {
    "host": "${DB_HOST}",
    "username": "${DB_USER}",
    "password": "${DB_PASSWORD}"
  }
}
```

At runtime, `${VAR_NAME}` is replaced with the environment variable value.

### Priority Order

1. System environment variables
2. `.env` file (loaded at startup)
3. Configuration file defaults

---

## Security Configuration

### Authentication

```json
{
  "security": {
    "authentication": {
      "enabled": true,
      "token_rotation_enabled": true,
      "token_rotation_interval_hours": 72,
      "token_refresh_enabled": true,
      "require_token_header": true,
      "allow_legacy_tokens": false,
      "session_timeout_minutes": 120,
      "max_concurrent_sessions": 3
    }
  }
}
```

**Fields:**

- `enabled` - Enable/disable authentication (always true in production)
- `token_rotation_enabled` - Automatic token rotation
- `token_rotation_interval_hours` - Hours between rotations (24-168 recommended)
- `token_refresh_enabled` - Allow token refresh before expiry
- `require_token_header` - Require Authorization header
- `allow_legacy_tokens` - Support old token format (migration only)
- `session_timeout_minutes` - Session timeout (30-240 recommended)
- `max_concurrent_sessions` - Max sessions per user (1-5 recommended)

### Authorization (RBAC)

```json
{
  "authorization": {
    "rbac_enabled": true,
    "default_role": "readonly",
    "enforce_permissions": true,
    "role_inheritance_enabled": true
  }
}
```

**Available Roles:**
- `readonly` - Read-only access
- `api_client` - API client with scene access
- `developer` - Development access
- `admin` - Full administrative access

See `config/roles.json` for detailed permission mappings.

### Rate Limiting

```json
{
  "rate_limiting": {
    "enabled": true,
    "global_requests_per_minute": 300,
    "per_endpoint_limits": {
      "/scene": 10,
      "/scene/reload": 5,
      "/admin": 5
    },
    "burst_multiplier": 1.2,
    "ban_duration_minutes": 60
  }
}
```

**Fields:**

- `enabled` - Enable rate limiting
- `global_requests_per_minute` - Global limit per IP
- `per_endpoint_limits` - Endpoint-specific limits
- `burst_multiplier` - Allowed burst above limit (1.0-2.0)
- `ban_duration_minutes` - Ban duration on violation

### Intrusion Detection System (IDS)

```json
{
  "intrusion_detection": {
    "enabled": true,
    "threat_score_threshold": 100,
    "auto_ban_enabled": true,
    "alert_enabled": true,
    "monitoring_mode_only": false
  }
}
```

See `config/ids_rules.json` for detection rules and scoring.

### Scene Validation

```json
{
  "scene_validation": {
    "whitelist_enabled": true,
    "environment": "production",
    "allow_test_scenes": false,
    "allow_component_scenes": false,
    "require_path_validation": true,
    "check_file_exists": true
  }
}
```

See `config/scene_whitelist.json` for allowed scenes per environment.

### Encryption & TLS

```json
{
  "encryption": {
    "tls_enabled": true,
    "tls_version_min": "1.3",
    "require_client_certs": false,
    "websocket_tls_enabled": true
  }
}
```

**TLS Versions:**
- `1.2` - Minimum acceptable
- `1.3` - Recommended for production

### Security Headers

```json
{
  "headers": {
    "enable_security_headers": true,
    "enable_cors": false,
    "cors_allowed_origins": [],
    "enable_csp": true,
    "enable_hsts": true
  }
}
```

---

## Networking Configuration

### HTTP API

```json
{
  "networking": {
    "http_api": {
      "enabled": true,
      "bind_address": "0.0.0.0",
      "port": 8080,
      "fallback_ports": [8081, 8080],
      "max_concurrent_connections": 100,
      "request_timeout_seconds": 30,
      "keep_alive_timeout_seconds": 60
    }
  }
}
```

**Bind Addresses:**
- `127.0.0.1` - Localhost only (development)
- `0.0.0.0` - All interfaces (staging/production)

### WebSocket (Telemetry)

```json
{
  "websocket": {
    "enabled": true,
    "bind_address": "0.0.0.0",
    "port": 8081,
    "max_connections": 50,
    "ping_interval_seconds": 30,
    "pong_timeout_seconds": 60,
    "compression_enabled": true,
    "binary_protocol_enabled": true
  }
}
```

### Debug Protocols (DAP/LSP)

```json
{
  "dap": {
    "enabled": false,
    "port": 6006,
    "bind_address": "127.0.0.1",
    "timeout_seconds": 10,
    "max_breakpoints": 0
  },
  "lsp": {
    "enabled": false,
    "port": 6005,
    "bind_address": "127.0.0.1",
    "timeout_seconds": 10
  }
}
```

**Note:** Disable DAP/LSP in production.

### Service Discovery

```json
{
  "discovery": {
    "enabled": false,
    "port": 8087,
    "broadcast_interval_seconds": 0,
    "service_name": "SpaceTime-Production"
  }
}
```

---

## Database Configuration

```json
{
  "database": {
    "enabled": true,
    "type": "postgresql",
    "host": "${DB_HOST}",
    "port": 5432,
    "database": "spacetime_production",
    "username": "${DB_USER}",
    "pool_size": 20,
    "pool_timeout_seconds": 30,
    "connection_timeout_seconds": 10,
    "query_timeout_seconds": 30,
    "enable_query_logging": false,
    "enable_slow_query_logging": true,
    "slow_query_threshold_ms": 1000
  }
}
```

**Supported Types:**
- `postgresql` - PostgreSQL (recommended)
- `mysql` - MySQL/MariaDB
- `sqlite` - SQLite (development only)

**Connection Pooling:**
- Development: 5-10 connections
- Staging: 10-20 connections
- Production: 20-50 connections

---

## Cache Configuration

```json
{
  "cache": {
    "enabled": true,
    "type": "redis",
    "redis_host": "${REDIS_HOST}",
    "redis_port": 6379,
    "redis_db": 0,
    "ttl_seconds": 3600,
    "max_size_mb": 1024,
    "eviction_policy": "lru"
  }
}
```

**Cache Types:**
- `memory` - In-memory cache (development)
- `redis` - Redis cache (staging/production)

**Eviction Policies:**
- `lru` - Least Recently Used (recommended)
- `lfu` - Least Frequently Used
- `fifo` - First In First Out

---

## Monitoring Configuration

### Metrics

```json
{
  "monitoring": {
    "metrics": {
      "enabled": true,
      "prometheus_enabled": true,
      "scrape_interval_seconds": 15,
      "retention_days": 30,
      "high_cardinality_metrics": false
    }
  }
}
```

### Telemetry

```json
{
  "telemetry": {
    "enabled": true,
    "export_interval_seconds": 10,
    "buffer_size": 1000,
    "compression_enabled": true,
    "include_debug_data": false
  }
}
```

### Health Checks

```json
{
  "health_checks": {
    "enabled": true,
    "interval_seconds": 30,
    "timeout_seconds": 5,
    "failure_threshold": 3
  }
}
```

### Alerts

```json
{
  "alerts": {
    "enabled": true,
    "channels": ["pagerduty", "slack", "email"],
    "error_threshold": 10,
    "warning_threshold": 50,
    "alert_cooldown_minutes": 5
  }
}
```

**Alert Channels:**
- `console` - Console output (development)
- `slack` - Slack webhook
- `email` - Email notifications
- `pagerduty` - PagerDuty integration

---

## Logging Configuration

```json
{
  "logging": {
    "level": "warn",
    "format": "json",
    "output": ["file"],
    "file_path": "/var/log/spacetime/production.log",
    "max_file_size_mb": 100,
    "max_files": 30,
    "rotation_strategy": "time",
    "include_timestamps": true,
    "include_source_location": false,
    "include_thread_id": true,
    "log_performance_metrics": true,
    "log_security_events": true,
    "log_api_requests": false,
    "log_api_responses": false,
    "audit_log_enabled": true,
    "audit_log_path": "/var/log/spacetime/audit_production.log"
  }
}
```

**Log Levels:**
- `debug` - Development only
- `info` - Staging
- `warn` - Production (recommended)
- `error` - Critical errors only

**Log Formats:**
- `text` - Human-readable (development)
- `json` - Structured logging (staging/production)

**Rotation Strategies:**
- `size` - Rotate when file reaches max size
- `time` - Rotate daily/hourly

---

## Performance Configuration

### Godot Engine

```json
{
  "performance": {
    "godot": {
      "target_fps": 90,
      "physics_fps": 90,
      "vsync_enabled": true,
      "msaa": "2x",
      "fxaa_enabled": true,
      "taa_enabled": false
    }
  }
}
```

**MSAA Options:**
- `disabled` - No antialiasing
- `2x` - 2x MSAA (recommended for VR)
- `4x` - 4x MSAA (high-end)
- `8x` - 8x MSAA (very high-end)

### Optimization

```json
{
  "optimization": {
    "dynamic_quality_enabled": true,
    "min_fps_threshold": 85,
    "quality_adjustment_interval_seconds": 10,
    "lod_enabled": true,
    "occlusion_culling_enabled": true
  }
}
```

### Worker Threads

```json
{
  "worker_threads": {
    "http_workers": 8,
    "background_tasks": 4,
    "physics_threads": 4
  }
}
```

**Thread Counts by Environment:**
- Development: 2-4 workers
- Staging: 4-8 workers
- Production: 8-16 workers

### Memory

```json
{
  "memory": {
    "max_heap_size_mb": 8192,
    "gc_interval_seconds": 300,
    "texture_memory_limit_mb": 2048,
    "mesh_memory_limit_mb": 1024
  }
}
```

### Timeouts

```json
{
  "timeouts": {
    "scene_load_timeout_seconds": 30,
    "resource_load_timeout_seconds": 15,
    "script_execution_timeout_seconds": 3
  }
}
```

---

## Feature Flags

```json
{
  "feature_flags": {
    "vr_enabled": true,
    "ai_integration_enabled": false,
    "debug_mode_enabled": false,
    "profiling_enabled": false,
    "hot_reload_enabled": false,
    "scene_history_enabled": true,
    "webhook_enabled": true,
    "batch_operations_enabled": true,
    "experimental_features_enabled": false,
    "creature_system_enabled": true,
    "procedural_generation_enabled": true,
    "multiplayer_enabled": true,
    "demo_mode_enabled": false
  }
}
```

**Production Recommendations:**
- Disable all debug features (`debug_mode_enabled`, `profiling_enabled`, `hot_reload_enabled`)
- Disable experimental features unless tested
- Enable core features only (`vr_enabled`, `creature_system_enabled`, etc.)

---

## Backup Configuration

```json
{
  "backup": {
    "enabled": true,
    "schedule_cron": "0 1 * * *",
    "retention_days": 30,
    "backup_path": "/var/backups/spacetime/",
    "compress_backups": true,
    "include_logs": true,
    "include_database": true
  }
}
```

**Cron Schedule Examples:**
- `0 1 * * *` - Daily at 1 AM
- `0 */6 * * *` - Every 6 hours
- `0 0 * * 0` - Weekly (Sunday midnight)

---

## High Availability

```json
{
  "high_availability": {
    "enabled": true,
    "replica_count": 2,
    "health_check_path": "/health",
    "health_check_interval_seconds": 10,
    "load_balancer_algorithm": "least_connections",
    "session_affinity": true,
    "graceful_shutdown_timeout_seconds": 30
  }
}
```

**Load Balancer Algorithms:**
- `round_robin` - Simple round-robin
- `least_connections` - Least active connections (recommended)
- `least_response_time` - Fastest response time
- `ip_hash` - Hash-based routing

---

## Configuration Validation

### Validation Script

Validate configuration before deployment:

```bash
# Validate development config
python scripts/validate_config.py development

# Validate production config with strict mode
python scripts/validate_config.py production --strict

# Custom config directory
python scripts/validate_config.py staging --config-dir /path/to/configs
```

### Validation Checks

The validator checks:

1. **Syntax** - Valid JSON
2. **Structure** - Required fields present
3. **Types** - Correct data types
4. **Values** - Valid ranges and options
5. **Security** - Security best practices
6. **Production** - Production readiness

### Exit Codes

- `0` - Validation passed
- `1` - Validation failed (errors or critical issues)

---

## Best Practices

### Development Environment

- Use `127.0.0.1` bind address
- Enable debug features
- Lower security constraints
- Verbose logging
- Disable rate limiting

### Staging Environment

- Mirror production settings
- Enable all monitoring
- Test with production-like data
- Enable security features
- Test alerts and backups

### Production Environment

- Minimal scene whitelist
- Strict rate limits
- All security features enabled
- Comprehensive audit logging
- Disable debug features
- Use secrets management
- Enable backups and HA

### Security Hardening

1. **Never commit secrets** - Use environment variables
2. **Rotate tokens regularly** - Every 30-90 days
3. **Enable TLS** - TLS 1.3 for production
4. **Audit logs** - Retain for 365 days
5. **Rate limiting** - Prevent abuse
6. **IDS enabled** - Detect threats
7. **Minimal permissions** - Least privilege principle

---

## Troubleshooting

### Configuration Not Loading

1. Check file path and permissions
2. Validate JSON syntax
3. Check environment variable
4. Review console logs

### Environment Variables Not Interpolating

1. Ensure variable is set: `echo $VAR_NAME`
2. Check `.env` file loaded
3. Verify syntax: `${VAR_NAME}`
4. Check for typos

### Validation Errors

1. Run validator: `python scripts/validate_config.py ENV`
2. Fix reported issues
3. Re-validate
4. Test in staging before production

---

## See Also

- [PRODUCTION_HARDENING.md](./PRODUCTION_HARDENING.md) - Production hardening guide
- [TLS_SETUP.md](../TLS_SETUP.md) - TLS/SSL setup
- [TOKEN_MANAGEMENT.md](../TOKEN_MANAGEMENT.md) - Token management
- [MONITORING.md](../MONITORING.md) - Monitoring setup
