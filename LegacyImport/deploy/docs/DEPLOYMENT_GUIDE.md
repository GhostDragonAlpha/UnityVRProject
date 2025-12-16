# SpaceTime VR - Production Deployment Guide

**Version:** 1.0.0
**Last Updated:** 2025-12-04
**Project:** SpaceTime VR - Godot 4.5+
**Status:** Production Ready (95% Confidence)

---

## Table of Contents

1. [Pre-Deployment Checklist](#1-pre-deployment-checklist)
2. [Environment Setup](#2-environment-setup)
3. [Build Process](#3-build-process)
4. [Deployment Procedures](#4-deployment-procedures)
5. [Configuration Management](#5-configuration-management)
6. [Post-Deployment Verification](#6-post-deployment-verification)
7. [Rollback Procedures](#7-rollback-procedures)
8. [Monitoring & Alerts](#8-monitoring--alerts)
9. [Troubleshooting](#9-troubleshooting)
10. [Appendices](#10-appendices)

---

## 1. Pre-Deployment Checklist

### Critical Items (MUST DO - Deployment Blockers)

- [ ] **Set `GODOT_ENABLE_HTTP_API=true`** in production environment
  - **WHY:** HTTP API is disabled by default in release builds (security hardening)
  - **WHERE:** Environment variable or startup script
  - **IMPACT:** Without this, HTTP API will not start in production
  - **COMMAND:**
    ```bash
    # Linux/Mac
    export GODOT_ENABLE_HTTP_API=true

    # Windows
    set GODOT_ENABLE_HTTP_API=true

    # Windows PowerShell
    $env:GODOT_ENABLE_HTTP_API="true"
    ```

- [ ] **Set `GODOT_ENV=production`** to load production whitelist
  - **WHY:** Limits scene loading to only essential VR scenes
  - **WHERE:** Environment variable
  - **IMPACT:** Without this, development whitelist allows test scenes
  - **COMMAND:**
    ```bash
    # Linux/Mac
    export GODOT_ENV=production

    # Windows
    set GODOT_ENV=production
    ```

- [ ] **Replace Kubernetes secret placeholders** (if deploying to K8s)
  - **RISK:** Secrets contain "REPLACE_WITH_SECURE_TOKEN" placeholders
  - **FILES:** `kubernetes/secret.yaml`, `deploy/staging/kubernetes/secrets.yaml`
  - **WHAT TO REPLACE:**
    - `API_TOKEN` - Generate with: `openssl rand -base64 32`
    - `GRAFANA_ADMIN_PASSWORD` - Use strong password (24+ characters)
    - `REDIS_PASSWORD` - Use strong password (24+ characters)
  - **COMMAND:**
    ```bash
    # Generate secure tokens
    export API_TOKEN=$(openssl rand -base64 32)
    export GRAFANA_PASSWORD=$(openssl rand -base64 24)
    export REDIS_PASSWORD=$(openssl rand -base64 24)

    # Create Kubernetes secret
    kubectl create secret generic spacetime-secrets \
      --from-literal=API_TOKEN="$API_TOKEN" \
      --from-literal=GRAFANA_ADMIN_USER="admin" \
      --from-literal=GRAFANA_ADMIN_PASSWORD="$GRAFANA_PASSWORD" \
      --from-literal=REDIS_PASSWORD="$REDIS_PASSWORD" \
      -n spacetime

    # Save credentials securely
    echo "API_TOKEN=$API_TOKEN" > .credentials
    echo "GRAFANA_PASSWORD=$GRAFANA_PASSWORD" >> .credentials
    echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> .credentials
    chmod 600 .credentials
    ```

- [ ] **Generate TLS certificates** for HTTPS
  - **CURRENT:** Placeholder base64 strings in `secret.yaml`
  - **SOLUTION (Development):**
    ```bash
    # Self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout tls.key -out tls.crt \
      -subj "/CN=spacetime.yourdomain.com"

    # Create Kubernetes TLS secret
    kubectl create secret tls spacetime-tls \
      --cert=tls.crt \
      --key=tls.key \
      -n spacetime
    ```
  - **SOLUTION (Production):**
    ```bash
    # Use cert-manager with Let's Encrypt
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

    # Create ClusterIssuer (replace email)
    cat <<EOF | kubectl apply -f -
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: admin@yourdomain.com
        privateKeySecretRef:
          name: letsencrypt-prod
        solvers:
          - http01:
              ingress:
                class: nginx
    EOF
    ```

- [ ] **Test exported build** with HTTP API enabled
  - **WHY:** Verify API starts correctly in release mode
  - **HOW:**
    ```bash
    # Export release build
    godot --headless --export-release "Windows Desktop" "build/SpaceTime.exe"

    # Run with API enabled
    GODOT_ENABLE_HTTP_API=true ./build/SpaceTime.exe

    # Verify API responds
    curl http://127.0.0.1:8080/status
    ```

### High Priority (SHOULD DO)

- [ ] **Configure scene whitelist** for production
  - **FILE:** `config/scene_whitelist.json`
  - **CURRENT:** Only `res://vr_main.tscn` allowed in production
  - **ACTION:** Review and add any additional scenes needed
  - **EXAMPLE:**
    ```json
    {
      "environments": {
        "production": {
          "scenes": [
            "res://vr_main.tscn",
            "res://scenes/menu.tscn"
          ]
        }
      }
    }
    ```

- [ ] **Review and remove log files** from repository
  - **FOUND:** 50+ .log files in root directory
  - **RISK:** May contain sensitive information
  - **ACTION:**
    ```bash
    # Review logs first
    ls *.log

    # Delete if safe (WARNING: irreversible)
    find . -name "*.log" -delete
    ```

- [ ] **Configure audit logging** (currently disabled)
  - **STATUS:** Temporarily disabled due to class loading issues
  - **LOCATION:** `scripts/http_api/http_api_server.gd` lines 64-70
  - **IMPACT:** No audit trail of HTTP API operations
  - **ACTION:** Fix HttpApiAuditLogger loading or implement file-based alternative

- [ ] **Set up monitoring and alerting**
  - **NEED:** Health check monitoring (every 5 minutes)
  - **NEED:** Performance metrics collection
  - **NEED:** Error alerting
  - **RECOMMENDATION:** Use telemetry on port 8081 + Prometheus/Grafana

### Medium Priority (CONSIDER)

- [ ] **Add export metadata** to builds
  - **FILE:** `export_presets.cfg`
  - **ADD:**
    ```ini
    application/file_version="1.0.0"
    application/product_version="1.0.0"
    application/company_name="Your Company"
    application/product_name="SpaceTime VR"
    application/file_description="VR Space Exploration Experience"
    ```

- [ ] **Review file operation security** (33 GDScript files)
  - **FOUND:** 33 files using `FileAccess.open`, `DirAccess.open`, `OS.execute`
  - **ACTION:** Manual code review (most are in trusted addons)
  - **PRIORITY FILES:**
    1. `scripts/http_api/security_config.gd` - Whitelist loading
    2. `scripts/http_api/scenes_list_router.gd` - Scene listing
    3. `scripts/http_api/audit_logger.gd` - Log file writing

---

## 2. Environment Setup

### Required Environment Variables

#### Production Deployment (CRITICAL)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GODOT_ENABLE_HTTP_API` | **YES** | `false` | Enable HTTP API in release builds |
| `GODOT_ENV` | **YES** | `development` | Environment: `production`, `staging`, `development`, `test` |

#### Optional Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GODOT_LOG_LEVEL` | No | `INFO` | Log level: `ERROR`, `WARN`, `INFO`, `DEBUG` |
| `API_TOKEN` | No | Auto-generated | JWT token for API authentication |
| `DB_HOST` | No | N/A | PostgreSQL host (if database enabled) |
| `DB_USER` | No | N/A | PostgreSQL username |
| `REDIS_HOST` | No | N/A | Redis host (if caching enabled) |
| `REDIS_PASSWORD` | No | N/A | Redis password |

### Configuration File Locations

```
config/
├── scene_whitelist.json           # Scene access control (environment-aware)
├── production.json                # Production configuration
├── staging.json                   # Staging configuration
├── development.json               # Development configuration
├── security_production.json       # Production security config
└── performance_production.json    # Production performance tuning
```

### Secret Management

#### Local/Docker Deployment

```bash
# Create .env file (DO NOT commit to git)
cat > .env <<EOF
GODOT_ENABLE_HTTP_API=true
GODOT_ENV=production
GODOT_LOG_LEVEL=warn
API_TOKEN=$(openssl rand -base64 32)
EOF

# Secure the file
chmod 600 .env
```

#### Kubernetes Deployment

```bash
# Create secret from file
kubectl create secret generic spacetime-secrets \
  --from-env-file=.env \
  -n spacetime

# Or create individual secrets
kubectl create secret generic spacetime-secrets \
  --from-literal=GODOT_ENABLE_HTTP_API=true \
  --from-literal=GODOT_ENV=production \
  --from-literal=API_TOKEN=$(openssl rand -base64 32) \
  -n spacetime
```

#### HashiCorp Vault (Enterprise)

```bash
# Store secrets in Vault
vault kv put secret/spacetime \
  GODOT_ENABLE_HTTP_API=true \
  GODOT_ENV=production \
  API_TOKEN=$(openssl rand -base64 32)

# Retrieve in deployment script
export GODOT_ENABLE_HTTP_API=$(vault kv get -field=GODOT_ENABLE_HTTP_API secret/spacetime)
export GODOT_ENV=$(vault kv get -field=GODOT_ENV secret/spacetime)
export API_TOKEN=$(vault kv get -field=API_TOKEN secret/spacetime)
```

### Port Requirements

#### Active Ports (MUST be accessible)

| Port | Protocol | Service | Purpose | Expose |
|------|----------|---------|---------|--------|
| 8080 | HTTP | HttpApiServer | Production REST API | External |
| 8081 | WebSocket | Telemetry | Real-time performance data | Internal |
| 8087 | UDP | Discovery | Service discovery broadcast | Internal |

#### Deprecated Ports (DO NOT USE)

| Port | Protocol | Service | Status |
|------|----------|---------|--------|
| 8082 | HTTP | GodotBridge | **DISABLED** (legacy, reference only) |
| 6005 | TCP | LSP | **DISABLED** (not used in production) |
| 6006 | TCP | DAP | **DISABLED** (not used in production) |

#### Firewall Rules

```bash
# Linux (iptables)
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 8081 -j ACCEPT
iptables -A INPUT -p udp --dport 8087 -j ACCEPT

# Linux (firewalld)
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --permanent --add-port=8081/tcp
firewall-cmd --permanent --add-port=8087/udp
firewall-cmd --reload

# Windows (PowerShell as Admin)
New-NetFirewallRule -DisplayName "SpaceTime HTTP API" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "SpaceTime Telemetry" -Direction Inbound -LocalPort 8081 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "SpaceTime Discovery" -Direction Inbound -LocalPort 8087 -Protocol UDP -Action Allow
```

---

## 3. Build Process

### Export Commands

#### Windows Desktop

```bash
# Export release build
godot --headless --export-release "Windows Desktop" "build/SpaceTime.exe"

# Export debug build (for troubleshooting)
godot --headless --export-debug "Windows Desktop" "build/SpaceTime_debug.exe"

# Verify build exists
ls -lh build/SpaceTime.exe
```

#### Linux

```bash
# Export release build
godot --headless --export-release "Linux/X11" "build/SpaceTime.x86_64"

# Make executable
chmod +x build/SpaceTime.x86_64

# Verify build
file build/SpaceTime.x86_64
```

#### macOS

```bash
# Export release build
godot --headless --export-release "macOS" "build/SpaceTime.dmg"

# Verify build
hdiutil info build/SpaceTime.dmg
```

### Build Verification Steps

```bash
# 1. Check build exists
ls -lh build/

# 2. Check file size (should be 100-500 MB)
du -h build/SpaceTime.exe

# 3. Run build with API enabled
GODOT_ENABLE_HTTP_API=true ./build/SpaceTime.exe &

# 4. Wait for startup (30 seconds)
sleep 30

# 5. Verify API responds
curl -f http://127.0.0.1:8080/status || echo "FAIL: API not responding"

# 6. Verify telemetry
nc -zv 127.0.0.1 8081 || echo "FAIL: Telemetry not available"

# 7. Stop build
pkill -f SpaceTime.exe
```

### Asset Optimization

#### Texture Compression

```bash
# In project.godot, verify:
# - VRAM compression enabled
# - Mipmaps enabled for 3D textures
# - Streaming enabled for large textures

# Check texture sizes
find . -name "*.import" -exec grep "compress/mode" {} \;
```

#### Mesh Optimization

```bash
# Ensure meshes use:
# - LOD (Level of Detail) where appropriate
# - Mesh compression
# - Instance rendering for repeated objects
```

#### Audio Compression

```bash
# Verify audio settings:
# - Music: Ogg Vorbis (low quality for background)
# - SFX: WAV or Ogg (higher quality for important sounds)
```

### Version Tagging

```bash
# Tag release in git
git tag -a v1.0.0 -m "Production release 1.0.0"
git push origin v1.0.0

# Update version in code
# Edit export_presets.cfg:
# application/file_version="1.0.0"
# application/product_version="1.0.0"

# Rebuild with version tag
godot --headless --export-release "Windows Desktop" "build/SpaceTime-v1.0.0.exe"
```

---

## 4. Deployment Procedures

### Local Deployment (Development)

#### Method 1: Via Python Server (Recommended)

```bash
# Start Python server with auto-start Godot
python godot_editor_server.py --port 8090 --auto-load-scene

# Server will:
# - Start Godot with correct configuration
# - Load VR scene automatically
# - Monitor health and auto-restart on crash
# - Proxy API on port 8090

# Verify health
curl http://127.0.0.1:8090/health

# Access API via proxy
curl http://127.0.0.1:8090/godot/status
```

#### Method 2: Direct Godot Launch

```bash
# Windows - Use console version for output
"C:/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe" \
  --path "C:/godot" \
  --editor

# Linux
godot --path "/path/to/project" --editor

# CRITICAL: Must run in GUI/editor mode (NOT headless)
# Headless mode causes autoloads and debug servers to fail

# Verify API started
curl http://127.0.0.1:8080/status
```

### Staging Deployment

#### Prerequisites

- Staging server with 8 CPU / 16GB RAM minimum
- Godot 4.5.1+ installed
- Environment variables configured
- Firewall rules applied

#### Deploy Steps

```bash
# 1. Copy build to staging server
scp build/SpaceTime.exe user@staging-server:/opt/spacetime/

# 2. SSH to staging server
ssh user@staging-server

# 3. Set environment variables
export GODOT_ENABLE_HTTP_API=true
export GODOT_ENV=staging
export GODOT_LOG_LEVEL=info

# 4. Create systemd service (Linux)
sudo cat > /etc/systemd/system/spacetime.service <<EOF
[Unit]
Description=SpaceTime VR Application
After=network.target

[Service]
Type=simple
User=spacetime
WorkingDirectory=/opt/spacetime
Environment="GODOT_ENABLE_HTTP_API=true"
Environment="GODOT_ENV=staging"
Environment="DISPLAY=:99"
ExecStartPre=/usr/bin/Xvfb :99 -screen 0 1920x1080x24 &
ExecStart=/opt/spacetime/SpaceTime.exe
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 5. Start service
sudo systemctl daemon-reload
sudo systemctl enable spacetime
sudo systemctl start spacetime

# 6. Verify service
sudo systemctl status spacetime
curl http://127.0.0.1:8080/status
```

### Production Deployment

#### Prerequisites

- Production-ready Kubernetes cluster (1.25+) OR bare metal servers
- 3+ nodes with 8 CPU / 32GB RAM each (K8s) OR dedicated server with 16 CPU / 64GB RAM
- 500GB SSD storage
- SSL/TLS certificates (Let's Encrypt or commercial)
- Monitoring stack (Prometheus + Grafana) configured
- Backup system configured

#### Deploy to Kubernetes

```bash
# 1. Build and push Docker image
docker build -f Dockerfile.v2.5 -t your-registry/spacetime:v1.0.0 .
docker push your-registry/spacetime:v1.0.0

# 2. Update image in deployment
sed -i 's|spacetime:v2.5-4.5|your-registry/spacetime:v1.0.0|g' kubernetes/deployment.yaml

# 3. Create namespace
kubectl apply -f kubernetes/namespace.yaml

# 4. Create secrets (see Pre-Deployment Checklist)
kubectl create secret generic spacetime-secrets \
  --from-literal=API_TOKEN=$(openssl rand -base64 32) \
  --from-literal=GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 24) \
  --from-literal=REDIS_PASSWORD=$(openssl rand -base64 24) \
  -n spacetime

kubectl create secret tls spacetime-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n spacetime

# 5. Apply all manifests
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/pvc.yaml
kubectl apply -f kubernetes/statefulset.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml
kubectl apply -f kubernetes/networkpolicy.yaml
kubectl apply -f kubernetes/hpa.yaml

# 6. Wait for rollout
kubectl rollout status deployment/spacetime-godot -n spacetime
kubectl rollout status deployment/spacetime-nginx -n spacetime

# 7. Verify pods
kubectl get pods -n spacetime

# Expected output:
# NAME                                   READY   STATUS    RESTARTS   AGE
# spacetime-godot-xxxxxxxxxx-xxxxx       1/1     Running   0          2m
# spacetime-nginx-xxxxxxxxxx-xxxxx       1/1     Running   0          2m
# spacetime-prometheus-xxxxx-xxxxx       1/1     Running   0          2m
# spacetime-grafana-xxxxxxxx-xxxxx       1/1     Running   0          2m
# spacetime-redis-0                      1/1     Running   0          2m

# 8. Get external IP
kubectl get ingress spacetime-ingress -n spacetime

# 9. Test deployment (see Post-Deployment Verification)
```

#### Deploy to Bare Metal

```bash
# 1. Copy build to production server
scp build/SpaceTime.exe user@prod-server:/opt/spacetime/

# 2. SSH to production server
ssh user@prod-server

# 3. Install dependencies
# (Godot dependencies, Xvfb for headless rendering, etc.)

# 4. Create production service
sudo cat > /etc/systemd/system/spacetime.service <<EOF
[Unit]
Description=SpaceTime VR Application
After=network.target

[Service]
Type=simple
User=spacetime
Group=spacetime
WorkingDirectory=/opt/spacetime
Environment="GODOT_ENABLE_HTTP_API=true"
Environment="GODOT_ENV=production"
Environment="GODOT_LOG_LEVEL=warn"
Environment="DISPLAY=:99"
ExecStartPre=/usr/bin/Xvfb :99 -screen 0 1920x1080x24 &
ExecStart=/opt/spacetime/SpaceTime.exe
Restart=always
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# 5. Create spacetime user
sudo useradd -r -s /bin/false spacetime
sudo chown -R spacetime:spacetime /opt/spacetime

# 6. Start service
sudo systemctl daemon-reload
sudo systemctl enable spacetime
sudo systemctl start spacetime

# 7. Verify service
sudo systemctl status spacetime
sudo journalctl -u spacetime -f

# 8. Test API
curl http://127.0.0.1:8080/status
```

### Health Check Verification After Deployment

```bash
# Run automated health check
python system_health_check.py

# Expected output:
# ========================================
# SpaceTime System Health Check
# ========================================
#
# [PASS] Godot Executable Found
# [PASS] Project Configuration Valid
# [PASS] HTTP API Files Present
# [PASS] Autoload Configuration
# [PASS] Port Configuration Correct
# [PASS] Migration Tools Present
# [PASS] Testing Infrastructure
# [PASS] Documentation Complete
# [PASS] Python Dependencies
# [PASS] Port 8080 Listening
#
# ========================================
# Summary: 10 checks PASSED, 0 checks FAILED, 0 warnings
# ========================================

# Manual verification
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/status
curl http://127.0.0.1:8080/state/scene
```

---

## 5. Configuration Management

### Scene Whitelist Configuration

**File:** `config/scene_whitelist.json`

#### Production Configuration

```json
{
  "environments": {
    "production": {
      "description": "Production environment - only essential scenes allowed",
      "scenes": [
        "res://vr_main.tscn"
      ],
      "directories": [],
      "wildcards": []
    }
  }
}
```

#### Staging Configuration

```json
{
  "environments": {
    "staging": {
      "description": "Staging environment - production + debug scenes",
      "scenes": [
        "res://vr_main.tscn",
        "res://scenes/menu.tscn"
      ],
      "directories": [
        "res://tests/integration/"
      ],
      "wildcards": [
        "res://tests/integration/**/*.tscn"
      ]
    }
  }
}
```

### Security Configuration

**File:** `config/security_production.json`

#### JWT Authentication

```json
{
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
```

#### Rate Limiting

```json
{
  "rate_limiting": {
    "enabled": true,
    "global_requests_per_minute": 300,
    "per_endpoint_limits": {
      "/scene": 10,
      "/scene/reload": 5,
      "/scene/load": 10,
      "/debug": 0,
      "/execute": 0,
      "/admin": 5,
      "/status": 100,
      "/health": 200
    },
    "burst_multiplier": 1.2,
    "ban_duration_minutes": 60
  }
}
```

#### RBAC (Role-Based Access Control)

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

**Roles:**
- `admin` - Full access to all endpoints
- `developer` - Scene management, debugging, performance monitoring
- `readonly` - Health checks, status queries only
- `guest` - Health checks only

### Performance Tuning

**File:** `config/performance_production.json`

#### Godot Performance

```json
{
  "godot": {
    "target_fps": 90,
    "physics_fps": 90,
    "vsync_enabled": true,
    "msaa": "2x",
    "fxaa_enabled": true,
    "taa_enabled": false
  }
}
```

#### Dynamic Quality Adjustment

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

### VR Settings

**VR Headset Configuration:**
- OpenXR enabled by default
- Automatic fallback to desktop mode if VR unavailable
- Comfort features: vignette, snap turns, teleport movement

**Configuration in project.godot:**
```ini
[xr]
openxr/enabled=true
openxr/startup_alert=false
shaders/enabled=true
```

---

## 6. Post-Deployment Verification

### Automated Health Checks

```bash
# Run comprehensive health check
python system_health_check.py --verbose

# Run with JSON output (for CI/CD)
python system_health_check.py --json > health_check_results.json
```

### API Health Checks

```bash
# 1. Basic health check
curl -f http://127.0.0.1:8080/health || echo "FAIL: Health check failed"

# 2. Detailed status
curl http://127.0.0.1:8080/status | jq .

# Expected output:
# {
#   "status": "healthy",
#   "version": "1.0.0",
#   "uptime_seconds": 120,
#   "http_api": "active",
#   "telemetry": "active",
#   "scene": "res://vr_main.tscn"
# }

# 3. Scene state
curl http://127.0.0.1:8080/state/scene | jq .

# 4. Player state (if VR active)
curl http://127.0.0.1:8080/state/player | jq .
```

### Telemetry Verification

```bash
# 1. Check WebSocket is listening
nc -zv 127.0.0.1 8081 || echo "FAIL: Telemetry port not open"

# 2. Monitor telemetry stream
python telemetry_client.py

# Expected output:
# Connected to telemetry stream
# FPS: 90.0, Physics: 90.0, Memory: 1024 MB
# VR Headset: Connected, Position: (0, 1.6, 0)
# ...
```

### VR Initialization

```bash
# 1. Check VR mode status
curl http://127.0.0.1:8080/state/vr | jq .

# Expected output (VR active):
# {
#   "vr_enabled": true,
#   "headset_connected": true,
#   "runtime": "OpenXR",
#   "headset_type": "Quest 2"
# }

# Expected output (Desktop fallback):
# {
#   "vr_enabled": false,
#   "headset_connected": false,
#   "fallback_mode": "desktop"
# }
```

### Performance Validation

```bash
# 1. Check FPS metrics
curl http://127.0.0.1:8080/performance/metrics | jq .fps

# Expected: 85-90 FPS (VR target is 90)

# 2. Check memory usage
curl http://127.0.0.1:8080/performance/metrics | jq .memory_mb

# Expected: 1000-2000 MB (depending on scene complexity)

# 3. Check scene load times
curl http://127.0.0.1:8080/scene/history | jq '.[-1].load_time_ms'

# Expected: <3000 ms for VR scenes
```

### Security Verification

```bash
# 1. Test authentication (should fail without token)
curl -w "%{http_code}\n" http://127.0.0.1:8080/scene

# Expected: 401 Unauthorized

# 2. Test with valid token
TOKEN=$(curl http://127.0.0.1:8080/status | jq -r .jwt_token)
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/scene

# Expected: 200 OK with scene data

# 3. Test rate limiting
for i in {1..65}; do
  curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/status
done

# Expected: First 60 succeed, then 429 Too Many Requests

# 4. Test scene whitelist
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://tests/debug.tscn"}' \
  http://127.0.0.1:8080/scene/load

# Expected: 403 Forbidden (not in production whitelist)
```

### Monitoring Stack Verification (Kubernetes)

```bash
# 1. Check Prometheus
kubectl port-forward -n spacetime svc/spacetime-prometheus-service 9090:9090 &
curl http://localhost:9090/-/healthy

# 2. Check Grafana
kubectl port-forward -n spacetime svc/spacetime-grafana-service 3000:3000 &
curl http://localhost:3000/api/health

# 3. Check Redis
kubectl exec -n spacetime spacetime-redis-0 -- redis-cli ping

# Expected: PONG
```

---

## 7. Rollback Procedures

### Quick Rollback (Kubernetes)

```bash
# 1. View deployment history
kubectl rollout history deployment/spacetime-godot -n spacetime

# Output:
# REVISION  CHANGE-CAUSE
# 1         Initial deployment
# 2         Update to v1.0.1
# 3         Update to v1.0.2 (current)

# 2. Rollback to previous version
kubectl rollout undo deployment/spacetime-godot -n spacetime

# 3. Verify rollback
kubectl rollout status deployment/spacetime-godot -n spacetime

# 4. Check pods
kubectl get pods -n spacetime -l app=spacetime-godot

# 5. Test API
curl http://your-domain/status
```

### Rollback to Specific Version (Kubernetes)

```bash
# Rollback to specific revision
kubectl rollout undo deployment/spacetime-godot --to-revision=1 -n spacetime

# Verify
kubectl describe deployment spacetime-godot -n spacetime | grep Image:
```

### Rollback on Bare Metal

```bash
# 1. Stop current service
sudo systemctl stop spacetime

# 2. Backup current version
sudo mv /opt/spacetime/SpaceTime.exe /opt/spacetime/SpaceTime.exe.backup

# 3. Restore previous version
sudo cp /opt/spacetime/backups/SpaceTime-v1.0.0.exe /opt/spacetime/SpaceTime.exe

# 4. Restart service
sudo systemctl start spacetime

# 5. Verify
sudo systemctl status spacetime
curl http://127.0.0.1:8080/status
```

### Configuration Rollback

```bash
# 1. Backup current config
kubectl get configmap spacetime-config -n spacetime -o yaml > config_backup.yaml

# 2. Restore previous config
kubectl apply -f config_previous.yaml

# 3. Restart pods to pick up config changes
kubectl rollout restart deployment/spacetime-godot -n spacetime

# 4. Verify
kubectl exec -n spacetime spacetime-godot-xxxx -- cat /app/config/production.json
```

### Version Downgrade Process

```bash
# 1. Identify target version
git tag -l

# 2. Checkout target version
git checkout v1.0.0

# 3. Rebuild
godot --headless --export-release "Windows Desktop" "build/SpaceTime-v1.0.0.exe"

# 4. Deploy downgraded version (follow deployment procedure)

# 5. Verify
curl http://127.0.0.1:8080/status | jq .version
# Expected: "1.0.0"
```

---

## 8. Monitoring & Alerts

### What to Monitor

#### Critical Metrics (Alert Immediately)

1. **HTTP API Availability**
   - Endpoint: `/health`
   - Interval: 1 minute
   - Alert if: Down for 2 consecutive checks
   - Severity: Critical

2. **FPS Below Target**
   - Metric: `fps_current`
   - Threshold: < 85 FPS (VR target is 90)
   - Alert if: Below threshold for 5 minutes
   - Severity: High

3. **Memory Usage High**
   - Metric: `memory_mb`
   - Threshold: > 12GB (of 16GB limit)
   - Alert if: Above threshold for 10 minutes
   - Severity: High

4. **Scene Load Failures**
   - Metric: `scene_load_errors`
   - Threshold: > 3 errors in 5 minutes
   - Alert if: Threshold exceeded
   - Severity: High

#### Warning Metrics (Alert During Business Hours)

1. **Request Latency High**
   - Metric: `http_request_latency_ms`
   - Threshold: > 500ms average
   - Alert if: Above threshold for 15 minutes
   - Severity: Medium

2. **Rate Limit Violations**
   - Metric: `rate_limit_violations`
   - Threshold: > 50 violations per hour
   - Alert if: Threshold exceeded
   - Severity: Medium

3. **Telemetry Connection Drops**
   - Metric: `telemetry_disconnects`
   - Threshold: > 10 disconnects per hour
   - Alert if: Threshold exceeded
   - Severity: Low

### Alert Thresholds

```yaml
# Example Prometheus alerting rules
# File: kubernetes/prometheus-alerts.yaml

groups:
  - name: spacetime_alerts
    interval: 30s
    rules:
      # Critical: API Down
      - alert: SpaceTimeAPIDown
        expr: up{job="spacetime-godot"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "SpaceTime API is down"
          description: "API has been down for 2 minutes"

      # Critical: FPS Below Target
      - alert: SpaceTimeLowFPS
        expr: spacetime_fps_current < 85
        for: 5m
        labels:
          severity: high
        annotations:
          summary: "FPS below VR target"
          description: "Current FPS: {{ $value }}, Target: 90"

      # High: Memory Usage
      - alert: SpaceTimeHighMemory
        expr: spacetime_memory_mb > 12000
        for: 10m
        labels:
          severity: high
        annotations:
          summary: "Memory usage high"
          description: "Memory: {{ $value }}MB / 16GB limit"

      # Medium: Request Latency
      - alert: SpaceTimeSlowRequests
        expr: spacetime_http_request_duration_ms > 500
        for: 15m
        labels:
          severity: medium
        annotations:
          summary: "Request latency high"
          description: "Average latency: {{ $value }}ms"
```

### Log Locations

#### Local/Bare Metal

```bash
# System logs
/var/log/spacetime/production.log
/var/log/spacetime/audit_production.log

# Systemd journal
sudo journalctl -u spacetime -f

# Application logs (if file logging enabled)
/app/logs/godot.log
/app/logs/http_api.log
```

#### Kubernetes

```bash
# View logs for all pods
kubectl logs -f -l app=spacetime-godot -n spacetime

# View logs for specific pod
kubectl logs -f spacetime-godot-xxxxxxxxxx-xxxxx -n spacetime

# View previous container logs (if crashed)
kubectl logs -p spacetime-godot-xxxxxxxxxx-xxxxx -n spacetime

# Export logs
kubectl logs deployment/spacetime-godot -n spacetime > godot.log
```

#### Docker

```bash
# View logs
docker logs -f spacetime

# Export logs
docker logs spacetime > spacetime.log 2>&1
```

### Performance Metrics

#### Key Performance Indicators (KPIs)

1. **Frame Rate**
   - Target: 90 FPS (VR)
   - Minimum: 85 FPS
   - Alert: < 85 FPS for 5 minutes

2. **Request Throughput**
   - Target: 100 requests/second
   - Maximum: 300 requests/second (rate limit)

3. **Request Latency**
   - Target: < 100ms (p50)
   - Maximum: < 500ms (p95)

4. **Scene Load Time**
   - Target: < 2 seconds
   - Maximum: < 3 seconds

5. **Memory Usage**
   - Target: 2-4 GB
   - Maximum: 12 GB (alert at 75% of 16GB)

#### Grafana Dashboard

```bash
# Access Grafana
kubectl port-forward -n spacetime svc/spacetime-grafana-service 3000:3000

# Login
# URL: http://localhost:3000
# User: admin
# Password: (from secret)

# Import SpaceTime dashboard
# Dashboard ID: (create custom dashboard with panels for above KPIs)
```

---

## 9. Troubleshooting

### Common Deployment Issues

#### Issue 1: HTTP API Not Starting in Production

**Symptoms:**
- Build starts but API not responding on port 8080
- Logs show "HTTP API disabled in release builds"

**Cause:**
- Missing `GODOT_ENABLE_HTTP_API=true` environment variable

**Solution:**
```bash
# Set environment variable
export GODOT_ENABLE_HTTP_API=true

# Restart application
sudo systemctl restart spacetime

# Or for Kubernetes
kubectl set env deployment/spacetime-godot GODOT_ENABLE_HTTP_API=true -n spacetime
```

**Verification:**
```bash
curl http://127.0.0.1:8080/status
# Should return 200 OK
```

---

#### Issue 2: Wrong Scene Whitelist Loaded

**Symptoms:**
- Test scenes loadable in production
- Production scenes rejected in staging

**Cause:**
- Missing or incorrect `GODOT_ENV` environment variable

**Solution:**
```bash
# Check current environment
curl http://127.0.0.1:8080/status | jq .environment

# Set correct environment
export GODOT_ENV=production

# Restart application
sudo systemctl restart spacetime
```

**Verification:**
```bash
# Try loading test scene (should fail in production)
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://tests/debug.tscn"}' \
  http://127.0.0.1:8080/scene/load

# Expected: 403 Forbidden
```

---

#### Issue 3: Kubernetes Secrets Not Found

**Symptoms:**
- Pods in `CreateContainerConfigError` state
- Error: "secret 'spacetime-secrets' not found"

**Cause:**
- Secrets not created or wrong namespace

**Solution:**
```bash
# Check if secrets exist
kubectl get secrets -n spacetime

# If missing, create secrets
kubectl create secret generic spacetime-secrets \
  --from-literal=API_TOKEN=$(openssl rand -base64 32) \
  --from-literal=GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 24) \
  --from-literal=REDIS_PASSWORD=$(openssl rand -base64 24) \
  -n spacetime

# Restart pods
kubectl rollout restart deployment/spacetime-godot -n spacetime
```

---

#### Issue 4: Port 8080 Already in Use

**Symptoms:**
- Error: "Address already in use"
- API fails to start

**Cause:**
- Another process using port 8080

**Solution:**
```bash
# Find process using port
# Linux
sudo lsof -i :8080
# or
sudo netstat -tulpn | grep :8080

# Windows
netstat -ano | findstr :8080

# Kill process (if safe)
sudo kill -9 <PID>

# Or change port in configuration (not recommended)
# Edit kubernetes/service.yaml or systemd service file
```

---

#### Issue 5: VR Headset Not Detected

**Symptoms:**
- Logs show "VR initialization failed"
- Fallback to desktop mode

**Cause:**
- VR headset not connected or OpenXR runtime not installed
- This is **expected behavior** in server deployments

**Solution:**
```bash
# Check VR status
curl http://127.0.0.1:8080/state/vr | jq .

# If desktop fallback is acceptable, no action needed
# If VR required:
# - Connect VR headset
# - Install SteamVR or OpenXR runtime
# - Restart application
```

---

#### Issue 6: Telemetry WebSocket Not Connecting

**Symptoms:**
- Telemetry client cannot connect to port 8081
- Error: "Connection refused"

**Cause:**
- Telemetry server not started or firewall blocking port

**Solution:**
```bash
# Check if port is listening
nc -zv 127.0.0.1 8081

# Check firewall rules
# Linux
sudo iptables -L | grep 8081
# or
sudo firewall-cmd --list-ports

# Windows
netsh advfirewall firewall show rule name=all | findstr 8081

# Add firewall rule if needed
# Linux
sudo firewall-cmd --permanent --add-port=8081/tcp
sudo firewall-cmd --reload

# Windows
netsh advfirewall firewall add rule name="SpaceTime Telemetry" dir=in action=allow protocol=TCP localport=8081
```

---

#### Issue 7: Scene Load Timeout

**Symptoms:**
- Scene load requests timeout after 30 seconds
- Error: "Scene load timeout"

**Cause:**
- Large scene with many assets
- Slow disk I/O

**Solution:**
```bash
# Increase timeout in configuration
# Edit config/production.json:
{
  "performance": {
    "timeouts": {
      "scene_load_timeout_seconds": 60
    }
  }
}

# Optimize scene:
# - Reduce poly count
# - Compress textures
# - Enable streaming for large assets

# Check disk I/O
iostat -x 1 10
```

---

#### Issue 8: High Memory Usage / Memory Leak

**Symptoms:**
- Memory usage increases over time
- Eventually hits 16GB limit and OOM killer triggers

**Cause:**
- Memory leak in subsystem
- Scene not unloaded properly

**Solution:**
```bash
# Monitor memory over time
watch -n 5 'curl -s http://127.0.0.1:8080/performance/metrics | jq .memory_mb'

# If increasing:
# 1. Reload scene to clear memory
curl -X POST http://127.0.0.1:8080/scene/reload

# 2. Check for unfreed subsystems
# Review logs for "Subsystem unregistered" messages

# 3. Restart application as workaround
sudo systemctl restart spacetime

# 4. Report issue with logs for investigation
```

---

#### Issue 9: Certificate Errors (HTTPS)

**Symptoms:**
- Ingress returns certificate errors
- Browser shows "NET::ERR_CERT_AUTHORITY_INVALID"

**Cause:**
- Self-signed certificate or expired certificate

**Solution:**
```bash
# Check certificate expiration
echo | openssl s_client -connect spacetime.yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates

# Renew certificate with cert-manager
kubectl delete secret spacetime-tls -n spacetime
# cert-manager will auto-create new certificate

# Or manually create new certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=spacetime.yourdomain.com"

kubectl create secret tls spacetime-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n spacetime
```

---

### Environment Variable Problems

#### Missing GODOT_ENABLE_HTTP_API

```bash
# Check if set
echo $GODOT_ENABLE_HTTP_API

# If empty, set it
export GODOT_ENABLE_HTTP_API=true

# Make persistent (Linux)
echo "export GODOT_ENABLE_HTTP_API=true" >> ~/.bashrc
source ~/.bashrc

# For systemd service
sudo systemctl edit spacetime
# Add:
# [Service]
# Environment="GODOT_ENABLE_HTTP_API=true"

sudo systemctl daemon-reload
sudo systemctl restart spacetime
```

#### Wrong GODOT_ENV Value

```bash
# Check current value
echo $GODOT_ENV

# Valid values: production, staging, development, test

# Set correct value
export GODOT_ENV=production

# Verify application picked it up
curl http://127.0.0.1:8080/status | jq .environment
```

---

### Permission Issues

#### Kubernetes Pod Security

```bash
# Check pod security context
kubectl describe pod spacetime-godot-xxxx -n spacetime | grep "Security Context" -A 10

# If permission errors, verify:
# - runAsUser matches file ownership
# - fsGroup matches volume permissions
# - Capabilities are correct
```

#### File System Permissions

```bash
# Check file ownership
ls -la /opt/spacetime/

# Fix ownership
sudo chown -R spacetime:spacetime /opt/spacetime/

# Check directory permissions
ls -ld /opt/spacetime/logs/

# Fix permissions
sudo chmod 755 /opt/spacetime/
sudo chmod 777 /opt/spacetime/logs/
```

---

## 10. Appendices

### Appendix A: Complete Environment Variable Reference

| Variable | Type | Default | Description | Example |
|----------|------|---------|-------------|---------|
| `GODOT_ENABLE_HTTP_API` | Boolean | `false` | Enable HTTP API in release builds | `true` |
| `GODOT_ENV` | String | `development` | Environment name | `production` |
| `GODOT_LOG_LEVEL` | String | `INFO` | Log verbosity | `ERROR`, `WARN`, `INFO`, `DEBUG` |
| `API_TOKEN` | String | Auto-gen | JWT token for API auth | `eyJhbGciOi...` |
| `DB_HOST` | String | - | PostgreSQL host | `postgres.example.com` |
| `DB_USER` | String | - | PostgreSQL username | `spacetime` |
| `DB_PASSWORD` | String | - | PostgreSQL password | `<secret>` |
| `REDIS_HOST` | String | - | Redis host | `redis.example.com` |
| `REDIS_PASSWORD` | String | - | Redis password | `<secret>` |
| `GRAFANA_ADMIN_USER` | String | `admin` | Grafana admin username | `admin` |
| `GRAFANA_ADMIN_PASSWORD` | String | - | Grafana admin password | `<secret>` |

---

### Appendix B: All Ports Used by System

#### Active Ports

| Port | Protocol | Service | Direction | Purpose |
|------|----------|---------|-----------|---------|
| 8080 | TCP/HTTP | HttpApiServer | Inbound | Production REST API |
| 8081 | TCP/WebSocket | Telemetry | Inbound | Real-time metrics streaming |
| 8087 | UDP | Discovery | Outbound | Service discovery broadcast |
| 9090 | TCP/HTTP | Prometheus | Internal | Metrics collection |
| 3000 | TCP/HTTP | Grafana | Inbound | Metrics visualization |
| 6379 | TCP | Redis | Internal | Caching and state |
| 5432 | TCP | PostgreSQL | Internal | Database (if enabled) |

#### Deprecated Ports

| Port | Protocol | Service | Status |
|------|----------|---------|--------|
| 8082 | TCP/HTTP | GodotBridge (legacy) | **DISABLED** |
| 6005 | TCP | LSP | **DISABLED** |
| 6006 | TCP | DAP | **DISABLED** |

---

### Appendix C: Configuration File Reference

#### Main Configuration Files

```
config/
├── scene_whitelist.json              # Scene access control
│   └── environments: production, staging, development, test
├── production.json                   # Production configuration
│   ├── security (auth, rate limiting, RBAC)
│   ├── networking (ports, timeouts)
│   ├── database (PostgreSQL config)
│   ├── cache (Redis config)
│   ├── monitoring (metrics, telemetry, alerts)
│   ├── logging (level, format, rotation)
│   ├── performance (FPS targets, optimization)
│   └── feature_flags (enable/disable features)
├── staging.json                      # Staging configuration
├── development.json                  # Development configuration
├── security_production.json          # Production security hardening
└── performance_production.json       # Production performance tuning
```

#### Kubernetes Configuration Files

```
kubernetes/
├── namespace.yaml                    # Namespace definition
├── configmap.yaml                    # Configuration data
├── secret.yaml                       # Secrets template
├── pvc.yaml                          # Persistent volume claims
├── deployment.yaml                   # Application deployments
├── statefulset.yaml                  # StatefulSet for Redis
├── service.yaml                      # Service definitions
├── ingress.yaml                      # Ingress for external access
├── networkpolicy.yaml                # Network isolation rules
├── hpa.yaml                          # Horizontal Pod Autoscaling
└── backup/
    └── backup-cronjob.yaml           # Automated backup job
```

---

### Appendix D: Command Reference

#### Deployment Commands

```bash
# Export build
godot --headless --export-release "Windows Desktop" "build/SpaceTime.exe"

# Run with API enabled
GODOT_ENABLE_HTTP_API=true ./build/SpaceTime.exe

# Start Python server
python godot_editor_server.py --port 8090 --auto-load-scene

# Start systemd service
sudo systemctl start spacetime

# Deploy to Kubernetes
kubectl apply -f kubernetes/

# Rollback deployment
kubectl rollout undo deployment/spacetime-godot -n spacetime
```

#### Verification Commands

```bash
# Health check
curl http://127.0.0.1:8080/health

# System status
curl http://127.0.0.1:8080/status | jq .

# Automated health check
python system_health_check.py

# Monitor telemetry
python telemetry_client.py

# Test HTTP API
python test_runtime_features.py
```

#### Monitoring Commands

```bash
# View logs (systemd)
sudo journalctl -u spacetime -f

# View logs (Kubernetes)
kubectl logs -f deployment/spacetime-godot -n spacetime

# Check metrics
curl http://127.0.0.1:8080/performance/metrics | jq .

# Check pod status
kubectl get pods -n spacetime

# Check resource usage
kubectl top pods -n spacetime
```

#### Troubleshooting Commands

```bash
# Check port listening
nc -zv 127.0.0.1 8080

# Find process on port
sudo lsof -i :8080

# Check firewall
sudo firewall-cmd --list-ports

# Test API authentication
TOKEN=$(curl http://127.0.0.1:8080/status | jq -r .jwt_token)
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:8080/scene

# Debug Kubernetes pod
kubectl describe pod spacetime-godot-xxxx -n spacetime
kubectl exec -it spacetime-godot-xxxx -n spacetime -- /bin/bash
```

---

### Appendix E: Quick Reference Checklist

#### Pre-Deployment (5 minutes)

- [ ] Set `GODOT_ENABLE_HTTP_API=true`
- [ ] Set `GODOT_ENV=production`
- [ ] Generate and set API_TOKEN
- [ ] Create TLS certificates
- [ ] Test exported build

#### Deployment (15 minutes)

- [ ] Deploy application (K8s or systemd)
- [ ] Wait for services to start (2-3 minutes)
- [ ] Run health check: `python system_health_check.py`
- [ ] Verify API: `curl http://127.0.0.1:8080/status`
- [ ] Verify telemetry: `nc -zv 127.0.0.1 8081`

#### Post-Deployment (10 minutes)

- [ ] Test scene loading
- [ ] Test authentication
- [ ] Test rate limiting
- [ ] Monitor telemetry for 5 minutes
- [ ] Check logs for errors
- [ ] Set up monitoring alerts
- [ ] Document deployment time and version

#### Rollback (2 minutes)

- [ ] Run rollback command
- [ ] Verify pods/service restarted
- [ ] Test API health
- [ ] Check logs
- [ ] Document rollback reason

---

## Document Metadata

**Created:** 2025-12-04
**Author:** Claude Code Deployment Agent
**Version:** 1.0.0
**Next Review:** After first production deployment

**Related Documents:**
- `PRODUCTION_READINESS_CHECKLIST.md` - Pre-deployment audit
- `VERIFICATION_COMPLETE.md` - System validation (95% confidence)
- `CLAUDE.md` - Project overview and architecture
- `TESTING_GUIDE.md` - Testing procedures
- `kubernetes/README.md` - Kubernetes deployment details
- `config/production.json` - Production configuration reference

---

## Conclusion

This deployment guide provides a comprehensive, step-by-step process for deploying SpaceTime VR to production. The guide covers:

- **Critical environment variables** that MUST be set
- **Security configuration** including JWT, rate limiting, RBAC
- **Multiple deployment targets** (local, staging, production, Kubernetes, bare metal)
- **Post-deployment verification** with automated health checks
- **Rollback procedures** for quick recovery
- **Monitoring and alerting** configuration
- **Troubleshooting** for common issues

**Key Success Factors:**
1. Always set `GODOT_ENABLE_HTTP_API=true` in production
2. Always set `GODOT_ENV=production` to load production whitelist
3. Always generate strong secrets (never use placeholders)
4. Always run health checks after deployment
5. Always have rollback plan ready

**Production Ready:** With these procedures followed, SpaceTime VR is ready for production deployment with 95% confidence.

---

**END OF DEPLOYMENT GUIDE**
