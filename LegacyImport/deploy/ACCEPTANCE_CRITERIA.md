# SpaceTime VR - Deployment Acceptance Criteria

**Version:** 1.0.0
**Date:** 2025-12-04
**Status:** ACTIVE

## Overview

This document defines the acceptance criteria that must be met for a SpaceTime VR deployment to be considered successful and ready for production use.

## Deployment Success Definition

A deployment is considered **SUCCESSFUL** when:
1. All **CRITICAL** acceptance criteria are met
2. At least 80% of **IMPORTANT** acceptance criteria are met
3. No **BLOCKER** issues are present
4. Post-deployment validation completes with overall status of PASSED or WARNING

A deployment must be **ROLLED BACK** if:
1. Any **CRITICAL** criterion fails
2. More than 50% of **IMPORTANT** criteria fail
3. Any **BLOCKER** issue is discovered

---

## 1. API Health & Availability

### CRITICAL

**AC-001: Health Endpoint Responds**
- **Requirement:** `/health` endpoint returns 200 OK with `{"status": "ok"}`
- **Test:** `GET http://localhost:8080/health`
- **Expected:** HTTP 200, JSON response with status "ok"
- **Timeout:** 10 seconds
- **Validation:** Automated via smoke_tests.py

**AC-002: Status Endpoint Returns Healthy**
- **Requirement:** `/status` endpoint returns healthy system status
- **Test:** `GET http://localhost:8080/status`
- **Expected:** HTTP 200, `status: "healthy"`, `http_api: "active"`
- **Timeout:** 10 seconds
- **Validation:** Automated via smoke_tests.py

**AC-003: API Version Present**
- **Requirement:** API version information is available
- **Test:** `/status` response includes `api_version` field
- **Expected:** Version string (e.g., "2.5.0")
- **Validation:** Automated via smoke_tests.py

### IMPORTANT

**AC-004: API Response Time**
- **Requirement:** API endpoints respond within acceptable time
- **Test:** Multiple requests to `/status` and `/health`
- **Expected:** Average response time < 500ms
- **Validation:** Automated via smoke_tests.py (timing in TestResult)

---

## 2. Security & Authentication

### CRITICAL

**AC-101: JWT Token Generation**
- **Requirement:** System generates JWT token on startup
- **Test:** `/status` response includes `jwt_token` field
- **Expected:** Valid JWT token string
- **Validation:** Automated via smoke_tests.py

**AC-102: Authentication Required**
- **Requirement:** Protected endpoints require authentication
- **Test:** Access `/scene` without Authorization header
- **Expected:** HTTP 401 Unauthorized
- **Validation:** Automated via smoke_tests.py

**AC-103: Valid Token Accepted**
- **Requirement:** Valid JWT token grants access to protected endpoints
- **Test:** Access `/scene` with `Authorization: Bearer {token}`
- **Expected:** HTTP 200 or appropriate success response
- **Validation:** Automated via smoke_tests.py

**AC-104: Invalid Token Rejected**
- **Requirement:** Invalid/expired tokens are rejected
- **Test:** Access `/scene` with invalid token
- **Expected:** HTTP 401 Unauthorized
- **Validation:** Automated via smoke_tests.py

### IMPORTANT

**AC-105: HTTPS in Production**
- **Requirement:** Production deployments use HTTPS (not HTTP)
- **Test:** Manual verification of endpoint URL
- **Expected:** URL starts with `https://`
- **Validation:** Manual (HTTPS setup is deployment-specific)

**AC-106: Localhost Binding**
- **Requirement:** API binds to localhost (127.0.0.1) only
- **Test:** Check server configuration
- **Expected:** `bind_address: "127.0.0.1"`
- **Validation:** Manual via configuration review

---

## 3. Rate Limiting & DDoS Protection

### CRITICAL

**AC-201: Rate Limiting Active**
- **Requirement:** Rate limiting prevents excessive requests
- **Test:** Send 65 rapid requests to `/status`
- **Expected:** HTTP 429 (Too Many Requests) returned before 65th request
- **Validation:** Automated via smoke_tests.py

### IMPORTANT

**AC-202: Rate Limit Configuration**
- **Requirement:** Rate limits are configured per environment
- **Test:** Check security configuration
- **Expected:** Production has stricter limits than development
- **Validation:** Manual via configuration review

---

## 4. Scene Management

### CRITICAL

**AC-301: Main Scene Loaded**
- **Requirement:** Main VR scene is loaded on startup
- **Test:** `GET http://localhost:8080/state/scene`
- **Expected:** `current_scene` contains "vr_main.tscn"
- **Validation:** Automated via smoke_tests.py

**AC-302: Scene Whitelist Enforced**
- **Requirement:** Only whitelisted scenes can be loaded
- **Test:** Attempt to load test scene `res://tests/debug.tscn`
- **Expected:** HTTP 403 Forbidden in production/staging
- **Validation:** Automated via smoke_tests.py

### IMPORTANT

**AC-303: Player Spawned**
- **Requirement:** Player node exists in loaded scene
- **Test:** `GET http://localhost:8080/state/player`
- **Expected:** `exists: true`
- **Validation:** Automated via smoke_tests.py

**AC-304: Scene Reload Works**
- **Requirement:** Hot-reload functionality works
- **Test:** `POST http://localhost:8080/scene/reload` (with auth)
- **Expected:** HTTP 200, scene reloads successfully
- **Validation:** Manual testing (not included in smoke tests)

---

## 5. Performance Benchmarks

### CRITICAL

**AC-401: Minimum FPS**
- **Requirement:** System maintains acceptable frame rate
- **Test:** Query `/performance` endpoint
- **Expected:** `engine.fps >= 30`
- **Target:** `engine.fps >= 60` (VR target: 90)
- **Validation:** Automated via smoke_tests.py

### IMPORTANT

**AC-402: Memory Usage**
- **Requirement:** Memory usage within acceptable limits
- **Test:** Query `/performance` endpoint
- **Expected:** `memory.usage_mb < 2048` (2GB)
- **Target:** `memory.usage_mb < 1024` (1GB)
- **Validation:** Automated via post_deployment_validation.py

**AC-403: Performance Metrics Available**
- **Requirement:** Performance endpoint provides all metrics
- **Test:** `GET http://localhost:8080/performance` (with auth)
- **Expected:** Response includes `cache`, `memory`, and `engine` sections
- **Validation:** Automated via smoke_tests.py

**AC-404: No Memory Leaks**
- **Requirement:** Memory usage remains stable over time
- **Test:** Monitor `/performance` over 15 minutes
- **Expected:** Memory usage increase < 10% over period
- **Validation:** Manual monitoring (long-running test)

---

## 6. Telemetry & Monitoring

### IMPORTANT

**AC-501: WebSocket Telemetry**
- **Requirement:** Telemetry WebSocket accepts connections
- **Test:** Connect to `ws://localhost:8081`
- **Expected:** Connection successful, receives heartbeat
- **Validation:** Automated via smoke_tests.py

**AC-502: Telemetry Data Streaming**
- **Requirement:** Telemetry streams performance data
- **Test:** Connect to WebSocket and wait for data
- **Expected:** Receive binary telemetry packets (type 0x01 or 0x02)
- **Validation:** Manual via telemetry_client.py

---

## 7. VR System

### IMPORTANT

**AC-601: VR Initialization Status**
- **Requirement:** VR system status is reported
- **Test:** `/status` response includes `vr_initialized` field
- **Expected:** Boolean value (true if OpenXR active, false if desktop mode)
- **Validation:** Automated via smoke_tests.py

**AC-602: OpenXR Support**
- **Requirement:** OpenXR initializes if headset is connected
- **Test:** Run with VR headset connected
- **Expected:** `vr_initialized: true` in status
- **Validation:** Manual (requires VR hardware)

**AC-603: Desktop Fallback**
- **Requirement:** System runs without VR headset
- **Test:** Run without VR headset
- **Expected:** `vr_initialized: false`, system still functional
- **Validation:** Manual testing

---

## 8. Autoload Subsystems

### CRITICAL

**AC-701: All Autoloads Loaded**
- **Requirement:** All 6 autoload subsystems are loaded
- **Test:** `/status` response includes `autoloads` with all expected subsystems
- **Expected:** All 6 autoloads show status "loaded":
  - ResonanceEngine
  - HttpApiServer
  - SceneLoadMonitor
  - SettingsManager
  - TelemetryServer
  - ServiceDiscovery
- **Validation:** Automated via smoke_tests.py

### IMPORTANT

**AC-702: Autoload Initialization Order**
- **Requirement:** Autoloads initialize in correct dependency order
- **Test:** Check logs for initialization sequence
- **Expected:** No dependency errors in logs
- **Validation:** Manual via log analysis

---

## 9. Configuration & Environment

### CRITICAL

**AC-801: Correct Environment Detected**
- **Requirement:** System detects and loads correct environment config
- **Test:** `/status` response includes `environment` field
- **Expected:** "production" for prod, "staging" for staging, "development" for dev
- **Validation:** Automated via post_deployment_validation.py

**AC-802: Production Build Type**
- **Requirement:** Production uses release build, not debug
- **Test:** `/status` response includes `build_type` field
- **Expected:** "release" for production environment
- **Validation:** Automated via post_deployment_validation.py

### IMPORTANT

**AC-803: Environment Variables Set**
- **Requirement:** Required environment variables are configured
- **Test:** Check for `GODOT_ENVIRONMENT`, `GODOT_ENABLE_HTTP_API`
- **Expected:** Variables set correctly for environment
- **Validation:** Manual via system check

---

## 10. Stability & Reliability

### CRITICAL

**AC-901: No Crashes for 15 Minutes**
- **Requirement:** System runs without crashing
- **Test:** Run deployment for 15 minutes with monitoring
- **Expected:** Process remains running, no restarts
- **Validation:** Manual monitoring

### IMPORTANT

**AC-902: No Critical Errors in Logs**
- **Requirement:** No critical errors in recent logs
- **Test:** Analyze last 100 lines of log file
- **Expected:** No lines matching error patterns (ERROR:, FATAL:, SCRIPT ERROR:)
- **Validation:** Automated via post_deployment_validation.py (with --check-logs)

**AC-903: Graceful Degradation**
- **Requirement:** System handles missing optional components gracefully
- **Test:** Run without VR headset, without telemetry client
- **Expected:** System continues to function, logs warnings (not errors)
- **Validation:** Manual testing

---

## 11. Rollback Readiness

### CRITICAL

**AC-1001: Rollback Script Available**
- **Requirement:** Rollback script exists and is executable
- **Test:** Check for `deploy/scripts/rollback.sh`
- **Expected:** File exists, has execute permissions
- **Validation:** Automated via post_deployment_validation.py (with --test-rollback)

**AC-1002: Backup Available**
- **Requirement:** Previous version backup exists
- **Test:** Check for `deploy/rollback/backup/`
- **Expected:** Backup directory exists with previous deployment
- **Validation:** Automated via post_deployment_validation.py (with --test-rollback)

### IMPORTANT

**AC-1003: Rollback Tested**
- **Requirement:** Rollback procedure has been tested (dry-run)
- **Test:** Execute rollback script with `--dry-run` flag
- **Expected:** Script completes without errors
- **Validation:** Manual via rollback script

---

## Acceptance Summary

### By Priority

| Priority | Total Criteria | Category |
|----------|---------------|----------|
| CRITICAL | 15 | Must pass all |
| IMPORTANT | 17 | Must pass 80% (14/17) |

### By Category

| Category | CRITICAL | IMPORTANT | Total |
|----------|----------|-----------|-------|
| API Health | 3 | 1 | 4 |
| Security | 4 | 2 | 6 |
| Rate Limiting | 1 | 1 | 2 |
| Scene Management | 2 | 2 | 4 |
| Performance | 1 | 3 | 4 |
| Telemetry | 0 | 2 | 2 |
| VR System | 0 | 3 | 3 |
| Autoloads | 1 | 1 | 2 |
| Configuration | 2 | 1 | 3 |
| Stability | 1 | 2 | 3 |
| Rollback | 2 | 1 | 3 |
| **TOTAL** | **17** | **19** | **36** |

---

## Validation Tools

### Automated Validation

**Primary Tool:** `tests/smoke_tests.py`
- Covers: AC-001 through AC-104, AC-201, AC-301 through AC-403, AC-501, AC-601, AC-701

**Secondary Tool:** `tests/post_deployment_validation.py`
- Covers: Full validation including log analysis, security checks, performance baseline
- Generates comprehensive validation report

### Manual Validation

**Required Manual Tests:**
- AC-105: HTTPS verification (production only)
- AC-106: Localhost binding check
- AC-304: Scene reload testing
- AC-404: Memory leak monitoring (15-minute test)
- AC-502: Telemetry data streaming
- AC-602/603: VR initialization with/without headset
- AC-702: Autoload initialization order
- AC-803: Environment variable check
- AC-901: Stability testing (15-minute run)
- AC-903: Graceful degradation testing
- AC-1003: Rollback dry-run

---

## Sign-Off Requirements

For deployment to be approved, the following must sign off:

1. **Technical Lead** - All automated tests pass, critical criteria met
2. **QA Lead** - Manual tests complete, acceptance criteria validated
3. **DevOps Lead** - Infrastructure ready, monitoring active, rollback tested
4. **Product Owner** - Business requirements met, deployment approved

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | 2025-12-04 | Initial acceptance criteria | Claude Code |

---

## References

- [Deployment Runbook](RUNBOOK.md)
- [Deployment Checklist](CHECKLIST.md)
- [Deployment Sign-Off](DEPLOYMENT_SIGNOFF.md)
- [Smoke Tests](../tests/smoke_tests.py)
- [Post-Deployment Validation](../tests/post_deployment_validation.py)
