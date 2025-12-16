# Example CI/CD Workflow Logs

This document shows example outputs from successful CI/CD pipeline runs.

## Table of Contents

- [Test Suite Workflow](#test-suite-workflow)
- [Security Scan Workflow](#security-scan-workflow)
- [Build Workflow](#build-workflow)
- [Deploy to Staging](#deploy-to-staging)
- [Deploy to Production](#deploy-to-production)

## Test Suite Workflow

### Successful Test Run

```
Run: Test Suite #142
Triggered by: push to main
Commit: abc123 - feat: add scene validation endpoint
Duration: 18m 32s
Status: ✅ Success

Jobs:
┌─────────────────────┬──────────┬──────────┐
│ Job                 │ Duration │ Status   │
├─────────────────────┼──────────┼──────────┤
│ quick-check         │ 2m 15s   │ ✅ Pass  │
│ http-api-tests      │ 8m 42s   │ ✅ Pass  │
│ security-tests      │ 6m 18s   │ ✅ Pass  │
│ property-tests      │ 5m 34s   │ ✅ Pass  │
│ integration-tests   │ 4m 27s   │ ✅ Pass  │
│ test-summary        │ 1m 16s   │ ✅ Pass  │
└─────────────────────┴──────────┴──────────┘

Test Results:
┌────────────────────┬───────┬────────┬─────────┐
│ Suite              │ Total │ Passed │ Success │
├────────────────────┼───────┼────────┼─────────┤
│ HTTP API Tests     │ 57    │ 57     │ 100%    │
│ Security Tests     │ 68    │ 68     │ 100%    │
│ Property Tests     │ 23    │ 23     │ 100%    │
│ Integration Tests  │ 12    │ 12     │ 100%    │
├────────────────────┼───────┼────────┼─────────┤
│ TOTAL              │ 160   │ 160    │ 100%    │
└────────────────────┴───────┴────────┴─────────┘

Coverage:
  Lines:      1,247 / 1,456  (85.6%)
  Branches:     324 / 389    (83.3%)
  Functions:    142 / 156    (91.0%)
  Overall:      85.6% ✅ (threshold: 80%)

Artifacts:
  📄 test-reports/http-api-report.json
  📄 test-reports/security-report.json
  📄 test-reports/property-report.json
  📄 htmlcov/index.html
  📄 combined-test-report.md
```

### HTTP API Tests Detail

```
tests/http_api/test_all_endpoints.py::TestGetCurrentScene
  ✅ test_get_current_scene_returns_200                     PASSED [  0.12s]
  ✅ test_get_current_scene_has_valid_structure             PASSED [  0.08s]
  ✅ test_get_current_scene_when_loaded                     PASSED [  0.11s]
  ✅ test_get_current_scene_responds_quickly                PASSED [  0.15s]

tests/http_api/test_all_endpoints.py::TestPostScene
  ✅ test_post_scene_with_valid_path_returns_200            PASSED [  0.34s]
  ✅ test_post_scene_actually_loads_scene                   PASSED [  1.23s]
  ✅ test_post_scene_with_invalid_path_returns_400          PASSED [  0.09s]
  ✅ test_post_scene_rejects_non_whitelisted_path           PASSED [  0.11s]

tests/http_api/test_all_endpoints.py::TestPutScene
  ✅ test_put_scene_validates_without_loading               PASSED [  0.18s]
  ✅ test_put_scene_returns_validation_results              PASSED [  0.21s]

tests/http_api/test_all_endpoints.py::TestGetScenes
  ✅ test_get_scenes_returns_200                            PASSED [  0.10s]
  ✅ test_get_scenes_returns_list_of_scenes                 PASSED [  0.14s]
  ✅ test_get_scenes_includes_vr_main                       PASSED [  0.08s]

tests/http_api/test_all_endpoints.py::TestPostSceneReload
  ✅ test_post_scene_reload_returns_200                     PASSED [  0.67s]
  ✅ test_post_scene_reload_actually_reloads                PASSED [  1.45s]

tests/http_api/test_all_endpoints.py::TestGetSceneHistory
  ✅ test_get_scene_history_returns_200                     PASSED [  0.09s]
  ✅ test_get_scene_history_includes_recent_loads           PASSED [  0.12s]

========================= 57 passed in 8.42s =========================
```

### Security Tests Detail

```
tests/http_api/test_security.py::TestAuthentication
  ✅ test_missing_authorization_header                      PASSED [  0.08s]
  ✅ test_invalid_token_format                              PASSED [  0.07s]
  ✅ test_expired_token                                     PASSED [  0.09s]

tests/http_api/test_security.py::TestPathValidation
  ✅ test_path_traversal_attack_blocked                     PASSED [  0.11s]
  ✅ test_absolute_path_blocked                             PASSED [  0.10s]
  ✅ test_non_scene_file_blocked                            PASSED [  0.09s]
  ✅ test_non_whitelisted_scene_blocked                     PASSED [  0.12s]

tests/http_api/test_security.py::TestRequestSizeLimits
  ✅ test_request_within_limit_accepted                     PASSED [  0.15s]
  ✅ test_request_exceeding_limit_rejected                  PASSED [  0.18s]

tests/http_api/test_security.py::TestRateLimiting
  ✅ test_rate_limit_enforced                               PASSED [  1.23s]
  ✅ test_rate_limit_per_endpoint                           PASSED [  1.45s]

tests/http_api/test_security.py::TestErrorResponses
  ✅ test_error_messages_sanitized                          PASSED [  0.08s]
  ✅ test_no_stack_traces_in_production                     PASSED [  0.09s]

tests/http_api/test_security_penetration.py
  ✅ test_sql_injection_attempts_blocked                    PASSED [  0.14s]
  ✅ test_xss_attempts_blocked                              PASSED [  0.12s]
  ✅ test_command_injection_blocked                         PASSED [  0.15s]
  ✅ test_xxe_injection_blocked                             PASSED [  0.11s]

========================= 68 passed in 6.18s =========================
```

## Security Scan Workflow

### Successful Security Scan

```
Run: Security Scanning #89
Triggered by: push to main
Commit: abc123 - feat: add scene validation endpoint
Duration: 12m 45s
Status: ✅ Success

Jobs:
┌─────────────────────┬──────────┬──────────┐
│ Job                 │ Duration │ Status   │
├─────────────────────┼──────────┼──────────┤
│ sast-scan           │ 3m 12s   │ ✅ Pass  │
│ dependency-scan     │ 2m 34s   │ ✅ Pass  │
│ secret-scan         │ 1m 45s   │ ✅ Pass  │
│ docker-scan         │ 4m 28s   │ ✅ Pass  │
│ code-quality        │ 2m 16s   │ ✅ Pass  │
│ security-summary    │ 0m 30s   │ ✅ Pass  │
└─────────────────────┴──────────┴──────────┘

Security Summary:
┌─────────────────────┬───────────┬──────────┐
│ Scan Type           │ Issues    │ Status   │
├─────────────────────┼───────────┼──────────┤
│ SAST (Semgrep)      │ 0 High    │ ✅ Pass  │
│                     │ 2 Medium  │          │
│                     │ 5 Low     │          │
│ Dependencies        │ 0 Critical│ ✅ Pass  │
│                     │ 0 High    │          │
│                     │ 3 Medium  │          │
│ Secrets             │ 0         │ ✅ Pass  │
│ Docker Image        │ 0 Critical│ ✅ Pass  │
│                     │ 1 High    │          │
│                     │ 8 Medium  │          │
└─────────────────────┴───────────┴──────────┘

SARIF Reports Uploaded: ✅
GitHub Security Tab Updated: ✅

Medium Issues (Review Recommended):
  1. [Semgrep] Potential logging of sensitive data
     File: scripts/core/logger.gd:45
     Severity: Medium

  2. [Semgrep] Unvalidated URL construction
     File: scripts/http_api/client.gd:78
     Severity: Medium

  3. [pip-audit] requests 2.28.0 has known vulnerability
     CVE-2023-XXXXX (CVSS 5.3)
     Fix: Upgrade to requests>=2.31.0
```

## Build Workflow

### Successful Docker Build

```
Run: Build and Publish #67
Triggered by: tag v2.5.0
Duration: 24m 18s
Status: ✅ Success

Jobs:
┌─────────────────────┬──────────┬──────────┐
│ Job                 │ Duration │ Status   │
├─────────────────────┼──────────┼──────────┤
│ build-image         │ 14m 32s  │ ✅ Pass  │
│ scan-image          │ 6m 45s   │ ✅ Pass  │
│ test-image          │ 2m 18s   │ ✅ Pass  │
│ publish-release     │ 0m 43s   │ ✅ Pass  │
└─────────────────────┴──────────┴──────────┘

Build Summary:
  Version: 2.5.0
  Commit: abc123def456
  Image Digest: sha256:789abc...

Image Tags:
  ✅ ghcr.io/username/spacetime:v2.5.0
  ✅ ghcr.io/username/spacetime:2.5
  ✅ ghcr.io/username/spacetime:2
  ✅ ghcr.io/username/spacetime:latest
  ✅ ghcr.io/username/spacetime:main-abc123

Platforms:
  ✅ linux/amd64
  ✅ linux/arm64

Image Size:
  Compressed: 487 MB
  Uncompressed: 1.2 GB

Security Scan Results:
  Trivy:
    Critical: 0
    High: 2
    Medium: 15
    Low: 43

  Grype:
    Critical: 0
    High: 3
    Medium: 18
    Low: 51

SBOM Generated: ✅ sbom.spdx.json

GitHub Release Created: ✅
  URL: https://github.com/username/spacetime/releases/tag/v2.5.0
```

## Deploy to Staging

### Successful Staging Deployment

```
Run: Deploy to Staging #45
Triggered by: push to main
Image Tag: main-abc123
Duration: 8m 32s
Status: ✅ Success

Environment: staging
URL: https://staging.spacetime.example.com

Deployment Steps:
┌─────────────────────────────────────┬──────────┬──────────┐
│ Step                                │ Duration │ Status   │
├─────────────────────────────────────┼──────────┼──────────┤
│ Configure SSH                       │ 0m 05s   │ ✅ Done  │
│ Create deployment directory         │ 0m 03s   │ ✅ Done  │
│ Copy deployment files               │ 0m 12s   │ ✅ Done  │
│ Backup current deployment           │ 0m 45s   │ ✅ Done  │
│ Pull new Docker image               │ 2m 34s   │ ✅ Done  │
│ Deploy new version                  │ 1m 23s   │ ✅ Done  │
│ Wait for services to be healthy     │ 2m 15s   │ ✅ Done  │
│ Run smoke tests                     │ 1m 15s   │ ✅ Done  │
└─────────────────────────────────────┴──────────┴──────────┘

Deployment Details:
  Deployment ID: 20251202-143022
  Previous Version: main-xyz789
  New Version: main-abc123
  Backup Location: /opt/spacetime/staging/backups/20251202-143022

Services Health:
┌─────────────────────┬──────────┬──────────┐
│ Service             │ Health   │ Uptime   │
├─────────────────────┼──────────┼──────────┤
│ godot               │ healthy  │ 2m 15s   │
│ nginx               │ healthy  │ 2m 18s   │
│ prometheus          │ healthy  │ 2m 12s   │
│ grafana             │ healthy  │ 2m 08s   │
└─────────────────────┴──────────┴──────────┘

Smoke Tests Results:
  ✅ HTTP API /status endpoint                              PASSED
  ✅ HTTP API /scene endpoint                               PASSED
  ✅ HTTP API /scenes endpoint                              PASSED
  ✅ HTTP API /scene/history endpoint                       PASSED
  ✅ DAP port (6006) connectivity                           PASSED
  ✅ LSP port (6005) connectivity                           PASSED
  ✅ Telemetry port (8081) connectivity                     PASSED
  ✅ API response time (<1s)                                PASSED
  ✅ Error handling (404 for invalid endpoint)              PASSED
  ✅ HTTP headers present                                   PASSED
  ✅ Container health status                                PASSED
  ✅ Memory usage (<90%)                                    PASSED
  ✅ CPU usage (<95%)                                       PASSED

  Total:  13
  Passed: 13
  Failed: 0

Post-Deployment Monitoring (5 minutes):
  Average Response Time: 142ms
  Error Rate: 0.0%
  Request Rate: 23 req/s
  CPU Usage: 18%
  Memory Usage: 42%

Deployment Complete: ✅
  Monitor at: https://staging.spacetime.example.com/grafana
  Rollback command: bash deploy/rollback.sh 20251202-143022
```

## Deploy to Production

### Successful Production Deployment

```
Run: Deploy to Production #23
Triggered by: workflow_dispatch
Image Tag: v2.5.0
Duration: 22m 47s
Status: ✅ Success

Environment: production
URL: https://spacetime.example.com

Pre-Deployment Validation:
┌─────────────────────────────────────┬──────────┐
│ Check                               │ Status   │
├─────────────────────────────────────┼──────────┤
│ Image tag exists                    │ ✅ Pass  │
│ Staging deployment verified         │ ✅ Pass  │
│ No critical vulnerabilities         │ ✅ Pass  │
│ All requirements met                │ ✅ Pass  │
└─────────────────────────────────────┴──────────┘

Manual Approval:
  ⏳ Waiting for approval... (0m 00s)
  ✅ Approved by: @username (5m 23s)
  Reviewer: @username
  Comment: "Staging looks good, proceeding to production"

Blue-Green Deployment:
┌─────────────────────────────────────┬──────────┬──────────┐
│ Step                                │ Duration │ Status   │
├─────────────────────────────────────┼──────────┼──────────┤
│ Create deployment snapshot          │ 1m 45s   │ ✅ Done  │
│ Copy deployment files               │ 0m 15s   │ ✅ Done  │
│ Pull new Docker image               │ 2m 56s   │ ✅ Done  │
│ Deploy green environment            │ 1m 34s   │ ✅ Done  │
│ Wait for green to be healthy        │ 3m 12s   │ ✅ Done  │
│ Run smoke tests on green            │ 1m 28s   │ ✅ Done  │
│ Switch traffic to green (cutover)   │ 0m 08s   │ ✅ Done  │
│ Monitor green under load            │ 2m 00s   │ ✅ Done  │
│ Shut down blue environment          │ 0m 45s   │ ✅ Done  │
└─────────────────────────────────────┴──────────┴──────────┘

Deployment Details:
  Deployment ID: 20251202-150045
  Rollback Tag: 20251202-150045-rollback
  Previous Version: v2.4.9
  New Version: v2.5.0
  Strategy: Blue-Green
  Downtime: 0 seconds ✅

Green Environment Health:
┌─────────────────────┬──────────┬──────────┐
│ Service             │ Health   │ Uptime   │
├─────────────────────┼──────────┼──────────┤
│ godot-1             │ healthy  │ 5m 12s   │
│ godot-2             │ healthy  │ 5m 10s   │
│ nginx               │ healthy  │ 5m 18s   │
│ prometheus          │ healthy  │ 5m 14s   │
│ grafana             │ healthy  │ 5m 09s   │
└─────────────────────┴──────────┴──────────┘

Smoke Tests (Green Environment):
  All 13 tests passed ✅

Traffic Cutover:
  🔵 Blue (v2.4.9): 100% → 0%
  🟢 Green (v2.5.0): 0% → 100%
  Duration: <1 second
  Errors during cutover: 0

Green Under Load (2 minutes):
  Minute 1: 3 errors (acceptable)
  Minute 2: 1 error (acceptable)
  Average Response Time: 156ms
  Request Rate: 847 req/s
  CPU Usage: 34%
  Memory Usage: 52%
  Status: ✅ Stable

Blue Environment Shutdown:
  Containers stopped gracefully
  Resources released
  Logs archived

Post-Deployment Health Checks (10 minutes):
┌─────────────────────┬──────────┬──────────┐
│ Metric              │ Value    │ Status   │
├─────────────────────┼──────────┼──────────┤
│ Uptime              │ 100%     │ ✅ Good  │
│ Error Rate          │ 0.02%    │ ✅ Good  │
│ Avg Response Time   │ 148ms    │ ✅ Good  │
│ Request Rate        │ 892/s    │ ✅ Good  │
│ CPU Usage           │ 31%      │ ✅ Good  │
│ Memory Usage        │ 48%      │ ✅ Good  │
└─────────────────────┴──────────┴──────────┘

Production Smoke Tests:
  All 13 tests passed ✅

Deployment Complete: ✅
  Production URL: https://spacetime.example.com
  Grafana: https://spacetime.example.com/grafana
  Prometheus: http://spacetime.example.com:9090

Rollback Available:
  If issues detected, rollback using:
  bash deploy/rollback.sh 20251202-150045-rollback

  Or trigger rollback workflow:
  gh workflow run rollback.yml -f deployment_id=20251202-150045

Monitoring Recommendation:
  Monitor production for next 2-4 hours
  Check Grafana dashboards
  Review logs for any anomalies
  Be prepared for quick rollback if needed
```

### Example Rollback (if needed)

```
Run: Production Rollback
Triggered by: manual
Reason: High error rate detected
Duration: 3m 12s
Status: ✅ Success

Rollback Steps:
┌─────────────────────────────────────┬──────────┬──────────┐
│ Step                                │ Duration │ Status   │
├─────────────────────────────────────┼──────────┼──────────┤
│ Identify rollback version           │ 0m 05s   │ ✅ Done  │
│ Stop current containers             │ 0m 45s   │ ✅ Done  │
│ Restore previous configuration      │ 0m 12s   │ ✅ Done  │
│ Start containers with previous ver  │ 1m 23s   │ ✅ Done  │
│ Wait for health checks              │ 0m 47s   │ ✅ Done  │
└─────────────────────────────────────┴──────────┴──────────┘

Rollback Details:
  Rolled back from: v2.5.0
  Rolled back to: v2.4.9
  Downtime: <1 minute
  Data loss: None ✅

Services After Rollback:
  All services healthy ✅
  Error rate normalized ✅
  Response times normal ✅

Rollback Complete: ✅
  Previous stable version restored
  System operating normally
  Incident investigation required
```

---

These example logs demonstrate:
- ✅ Comprehensive test coverage
- ✅ Security scanning at multiple levels
- ✅ Automated builds with multi-platform support
- ✅ Zero-downtime deployments
- ✅ Automated health checks
- ✅ Quick rollback capabilities
- ✅ Detailed monitoring and reporting
