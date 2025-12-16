# SpaceTime VR - Deployment and CI/CD Guide

**Version:** 1.0.0
**Last Updated:** 2025-12-02
**Target Godot Version:** 4.5+

This guide covers production deployment, CI/CD integration, containerization, monitoring, and security hardening for the SpaceTime VR project with its AI integration debug services.

---

## Table of Contents

1. [Production Deployment](#production-deployment)
2. [CI/CD Integration](#cicd-integration)
3. [Docker Deployment](#docker-deployment)
4. [Monitoring & Alerting](#monitoring--alerting)
5. [Security Hardening](#security-hardening)
6. [Troubleshooting](#troubleshooting)

---

## Production Deployment

### Overview

SpaceTime uses a **dual-layer architecture** for production:
- **Python Management Server** (`godot_editor_server.py`) - Process manager, health monitoring, HTTP API proxy
- **Godot Engine** - Game runtime with autoloaded debug services (DAP, LSP, HTTP API, Telemetry)

### Critical Requirements

**1. GUI Mode is MANDATORY**
```bash
# ✓ CORRECT - GUI mode with debug services
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005 --editor

# ✗ WRONG - Headless mode disables autoloads and debug servers
godot --headless --path "C:/godot"
```

**Why:** Godot's autoload system (which powers GodotBridge, TelemetryServer, ResonanceEngine, etc.) only initializes when the editor GUI is running. Headless mode will cause all debug services to fail.

**2. Port Configuration**

| Service | Port | Protocol | Required | Fallback Ports |
|---------|------|----------|----------|----------------|
| Python Manager | 8090 | HTTP | Yes | None |
| Godot HTTP API | 8081 | HTTP | Yes | 8083-8085 |
| Telemetry | 8081 | WebSocket | Yes | None |
| DAP | 6006 | TCP | Yes | None |
| LSP | 6005 | TCP | Yes | None |
| Service Discovery | 8087 | UDP | Optional | None |

### Deployment Methods

#### Method 1: Python Server (Recommended)

The Python server provides automatic process management, health monitoring, and crash recovery.

**Start the server:**
```bash
python godot_editor_server.py \
  --port 8090 \
  --godot-port 8080 \
  --godot-path "/path/to/godot" \
  --project-path "/path/to/project" \
  --auto-load-scene \
  --scene-path "res://vr_main.tscn" \
  --player-timeout 30
```

**Features:**
- Automatic Godot process start/restart
- Health monitoring with configurable intervals
- Auto-restart on crash (max 3 failures)
- Scene loading and player spawn verification
- HTTP API proxy with retry logic
- Log rotation to `godot_editor_server.log`

**Health check:**
```bash
curl http://127.0.0.1:8090/health
```

**Response:**
```json
{
  "server": "healthy",
  "timestamp": "2025-12-02T10:30:00",
  "godot_process": {
    "running": true,
    "pid": 12345
  },
  "godot_api": {
    "reachable": true
  },
  "scene": {
    "loaded": true,
    "name": "vr_main"
  },
  "player": {
    "spawned": true
  },
  "overall_healthy": true,
  "blocking_issues": []
}
```

#### Method 2: Direct Godot Launch

For development or when the Python server is unavailable.

**Start Godot directly:**
```bash
godot --path "/path/to/project" --dap-port 6006 --lsp-port 6005 --editor
```

**Verify services:**
```bash
# Check HTTP API
curl http://127.0.0.1:8080/status

# Check DAP port
nc -zv 127.0.0.1 6006

# Check LSP port
nc -zv 127.0.0.1 6005

# Check Telemetry (requires websockets)
python telemetry_client.py
```

### Process Management

#### systemd (Linux)

**Create service file:** `/etc/systemd/system/spacetime-server.service`

```ini
[Unit]
Description=SpaceTime VR Python Management Server
After=network.target

[Service]
Type=simple
User=spacetime
Group=spacetime
WorkingDirectory=/opt/spacetime
Environment="PATH=/opt/spacetime/.venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/home/spacetime/.Xauthority"
ExecStart=/opt/spacetime/.venv/bin/python godot_editor_server.py \
  --port 8090 \
  --godot-path /usr/local/bin/godot \
  --project-path /opt/spacetime \
  --auto-load-scene
Restart=always
RestartSec=10
StandardOutput=append:/var/log/spacetime/server.log
StandardError=append:/var/log/spacetime/server.log

[Install]
WantedBy=multi-user.target
```

**Key settings:**
- `DISPLAY=:0` - Required for Godot GUI mode
- `XAUTHORITY` - X11 authorization for GUI access
- `Restart=always` - Auto-restart on crash
- `RestartSec=10` - Wait 10 seconds between restarts

**Enable and start:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable spacetime-server
sudo systemctl start spacetime-server
sudo systemctl status spacetime-server
```

**View logs:**
```bash
sudo journalctl -u spacetime-server -f
```

#### supervisord (Linux/Mac)

**Create config:** `/etc/supervisor/conf.d/spacetime.conf`

```ini
[program:spacetime-server]
command=/opt/spacetime/.venv/bin/python godot_editor_server.py --port 8090 --godot-path /usr/local/bin/godot --project-path /opt/spacetime --auto-load-scene
directory=/opt/spacetime
user=spacetime
environment=DISPLAY=":0",XAUTHORITY="/home/spacetime/.Xauthority",PATH="/opt/spacetime/.venv/bin:/usr/local/bin:/usr/bin:/bin"
autostart=true
autorestart=true
startsecs=10
startretries=3
redirect_stderr=true
stdout_logfile=/var/log/spacetime/server.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=10
stopwaitsecs=30
```

**Reload and start:**
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start spacetime-server
sudo supervisorctl status spacetime-server
```

#### Windows Service (NSSM)

**Install NSSM:**
```powershell
choco install nssm
```

**Create service:**
```powershell
nssm install SpaceTimeServer "C:\godot\.venv\Scripts\python.exe" `
  "C:\godot\godot_editor_server.py" `
  "--port" "8090" `
  "--godot-path" "C:\Godot\Godot_v4.5.1-stable_win64.exe" `
  "--project-path" "C:\godot" `
  "--auto-load-scene"

nssm set SpaceTimeServer AppDirectory "C:\godot"
nssm set SpaceTimeServer DisplayName "SpaceTime VR Server"
nssm set SpaceTimeServer Description "SpaceTime VR Python Management Server"
nssm set SpaceTimeServer Start SERVICE_AUTO_START
nssm set SpaceTimeServer AppStdout "C:\godot\logs\server.log"
nssm set SpaceTimeServer AppStderr "C:\godot\logs\server.log"
nssm set SpaceTimeServer AppRotateFiles 1
nssm set SpaceTimeServer AppRotateBytes 52428800
nssm set SpaceTimeServer AppRotateOnline 1

nssm start SpaceTimeServer
```

**Manage service:**
```powershell
# Status
nssm status SpaceTimeServer

# Stop/Start/Restart
nssm stop SpaceTimeServer
nssm start SpaceTimeServer
nssm restart SpaceTimeServer

# Remove
nssm remove SpaceTimeServer confirm
```

### Firewall Configuration

#### Linux (UFW)
```bash
# Allow Python server
sudo ufw allow 8090/tcp comment "SpaceTime Python Server"

# Allow Godot services (if needed externally)
sudo ufw allow 8080/tcp comment "SpaceTime HTTP API"
sudo ufw allow 8081/tcp comment "SpaceTime Telemetry"
sudo ufw allow 6006/tcp comment "SpaceTime DAP"
sudo ufw allow 6005/tcp comment "SpaceTime LSP"
sudo ufw allow 8087/udp comment "SpaceTime Service Discovery"

sudo ufw reload
```

#### Linux (iptables)
```bash
# Allow Python server
iptables -A INPUT -p tcp --dport 8090 -j ACCEPT

# Allow Godot services
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 8081 -j ACCEPT
iptables -A INPUT -p tcp --dport 6006 -j ACCEPT
iptables -A INPUT -p tcp --dport 6005 -j ACCEPT
iptables -A INPUT -p udp --dport 8087 -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
```

#### Windows (Firewall)
```powershell
# Allow Python server
New-NetFirewallRule -DisplayName "SpaceTime Python Server" `
  -Direction Inbound -LocalPort 8090 -Protocol TCP -Action Allow

# Allow Godot services
New-NetFirewallRule -DisplayName "SpaceTime HTTP API" `
  -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "SpaceTime Telemetry" `
  -Direction Inbound -LocalPort 8081 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "SpaceTime DAP" `
  -Direction Inbound -LocalPort 6006 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "SpaceTime LSP" `
  -Direction Inbound -LocalPort 6005 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "SpaceTime Service Discovery" `
  -Direction Inbound -LocalPort 8087 -Protocol UDP -Action Allow
```

### Log Management

#### Log Rotation (Linux)

**Create config:** `/etc/logrotate.d/spacetime`

```
/var/log/spacetime/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0644 spacetime spacetime
    sharedscripts
    postrotate
        systemctl reload spacetime-server >/dev/null 2>&1 || true
    endscript
}
```

**Test rotation:**
```bash
sudo logrotate -f /etc/logrotate.d/spacetime
```

#### Python Server Logs

The Python server automatically logs to:
- `godot_editor_server.log` (in working directory)
- Console output (stdout)

**Log levels:**
- `INFO` - Normal operations
- `WARNING` - Non-critical issues (e.g., API timeouts)
- `ERROR` - Critical failures (e.g., Godot crash)

**Example log monitoring:**
```bash
# Follow logs
tail -f godot_editor_server.log

# Filter for errors
grep ERROR godot_editor_server.log

# Check recent restarts
grep "Restarting Godot" godot_editor_server.log
```

---

## CI/CD Integration

### Overview

SpaceTime's CI/CD pipeline validates code quality, runs tests, and builds exports. The pipeline must handle:
- GDScript linting and validation
- Python test suite (pytest + property-based tests)
- Scene validation
- Export builds for target platforms

### GitHub Actions

#### Complete Workflow

**File:** `.github/workflows/ci.yml`

```yaml
name: SpaceTime VR CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

env:
  GODOT_VERSION: "4.5.1"
  GODOT_PLATFORM: "linux.x86_64"

jobs:
  gdscript-lint:
    name: GDScript Linting
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install gdlint
        run: pip install gdtoolkit

      - name: Lint GDScript files
        run: gdlint scripts/**/*.gd addons/**/*.gd

      - name: Format check
        run: gdformat --check scripts/**/*.gd addons/**/*.gd

  python-tests:
    name: Python Tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'

      - name: Install dependencies
        run: |
          pip install -r tests/property/requirements.txt
          pip install pytest pytest-timeout pytest-cov hypothesis

      - name: Run property-based tests
        run: |
          cd tests/property
          pytest -v --timeout=30 --cov=../../scripts test_*.py

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./tests/property/coverage.xml

  scene-validation:
    name: Scene Validation
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.5.1
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Validate project.godot
        run: |
          godot --check-only --headless --path .

      - name: Validate scenes
        run: |
          # Validate all .tscn files can be loaded
          for scene in $(find . -name "*.tscn"); do
            echo "Validating $scene..."
            godot --headless --path . --script scripts/ci/validate_scene.gd -- "$scene"
          done

      - name: Check for parse errors
        run: |
          godot --headless --path . --script scripts/ci/check_parse_errors.gd

  godot-tests:
    name: GDScript Unit Tests (GdUnit4)
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.5.1
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install GdUnit4
        run: |
          mkdir -p addons
          git clone https://github.com/MikeSchulze/gdUnit4.git addons/gdUnit4

      - name: Run GdUnit4 tests
        run: |
          godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd \
            --test-suite tests/ \
            --report-junit junit_report.xml

      - name: Publish test results
        uses: EnricoMi/publish-unit-test-result-action@v2
        if: always()
        with:
          files: junit_report.xml

  build-exports:
    name: Build Exports
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.5.1
    needs: [gdscript-lint, python-tests, scene-validation, godot-tests]
    strategy:
      matrix:
        platform: [windows, linux]
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Create export directory
        run: mkdir -p build

      - name: Export for Windows
        if: matrix.platform == 'windows'
        run: |
          godot --headless --export-release "Windows Desktop" "build/SpaceTime-Windows.exe"

      - name: Export for Linux
        if: matrix.platform == 'linux'
        run: |
          godot --headless --export-release "Linux/X11" "build/SpaceTime-Linux.x86_64"

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: SpaceTime-${{ matrix.platform }}
          path: build/*

  docker-build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: [gdscript-lint, python-tests, scene-validation]
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: |
            myorg/spacetime:latest
            myorg/spacetime:${{ github.sha }}
          cache-from: type=registry,ref=myorg/spacetime:buildcache
          cache-to: type=registry,ref=myorg/spacetime:buildcache,mode=max
```

#### CI Helper Scripts

**Scene Validator:** `scripts/ci/validate_scene.gd`

```gdscript
extends SceneTree

func _init():
	var args = OS.get_cmdline_args()
	var scene_path = args[args.find("--") + 1] if "--" in args else ""

	if scene_path.is_empty():
		print("Error: No scene path provided")
		quit(1)
		return

	print("Validating scene: ", scene_path)

	var scene = load(scene_path)
	if scene == null:
		print("Error: Failed to load scene")
		quit(1)
		return

	var instance = scene.instantiate()
	if instance == null:
		print("Error: Failed to instantiate scene")
		quit(1)
		return

	print("✓ Scene is valid")
	quit(0)
```

**Parse Error Checker:** `scripts/ci/check_parse_errors.gd`

```gdscript
extends SceneTree

func _init():
	var errors = []
	_scan_directory("res://scripts", errors)
	_scan_directory("res://addons/godot_debug_connection", errors)

	if errors.size() > 0:
		print("Parse errors found:")
		for error in errors:
			print("  - ", error)
		quit(1)
	else:
		print("✓ No parse errors found")
		quit(0)

func _scan_directory(path: String, errors: Array):
	var dir = DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		var full_path = path + "/" + file_name

		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				_scan_directory(full_path, errors)
		elif file_name.ends_with(".gd"):
			var script = load(full_path)
			if script == null:
				errors.append(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()
```

### GitLab CI

**File:** `.gitlab-ci.yml`

```yaml
stages:
  - lint
  - test
  - build
  - deploy

variables:
  GODOT_VERSION: "4.5.1"
  DOCKER_IMAGE: "barichello/godot-ci:${GODOT_VERSION}"

# Caching
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - .venv/
    - .godot/

gdscript-lint:
  stage: lint
  image: python:3.11
  script:
    - pip install gdtoolkit
    - gdlint scripts/**/*.gd addons/**/*.gd
    - gdformat --check scripts/**/*.gd addons/**/*.gd

python-tests:
  stage: test
  image: python:3.11
  before_script:
    - pip install -r tests/property/requirements.txt
  script:
    - cd tests/property
    - pytest -v --timeout=30 --cov=../../scripts test_*.py
  coverage: '/(?i)total.*? (100(?:\.0+)?\%|[1-9]?\d(?:\.\d+)?\%)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: tests/property/coverage.xml

scene-validation:
  stage: test
  image: ${DOCKER_IMAGE}
  script:
    - godot --check-only --headless --path .
    - for scene in $(find . -name "*.tscn"); do
        echo "Validating $scene...";
        godot --headless --path . --script scripts/ci/validate_scene.gd -- "$scene";
      done

godot-tests:
  stage: test
  image: ${DOCKER_IMAGE}
  before_script:
    - mkdir -p addons
    - git clone https://github.com/MikeSchulze/gdUnit4.git addons/gdUnit4
  script:
    - godot -s addons/gdUnit4/bin/GdUnitCmdTool.gd
        --test-suite tests/
        --report-junit junit_report.xml
  artifacts:
    reports:
      junit: junit_report.xml

build-exports:
  stage: build
  image: ${DOCKER_IMAGE}
  only:
    - main
    - tags
  parallel:
    matrix:
      - PLATFORM: ["Windows Desktop", "Linux/X11"]
  script:
    - mkdir -p build
    - godot --headless --export-release "$PLATFORM" "build/SpaceTime-${PLATFORM// /-}"
  artifacts:
    paths:
      - build/*
    expire_in: 1 week

docker-build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  only:
    - main
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest

deploy-staging:
  stage: deploy
  image: alpine:latest
  only:
    - develop
  before_script:
    - apk add --no-cache openssh-client
  script:
    - ssh staging@server "cd /opt/spacetime && docker-compose pull && docker-compose up -d"

deploy-production:
  stage: deploy
  image: alpine:latest
  only:
    - main
  when: manual
  before_script:
    - apk add --no-cache openssh-client
  script:
    - ssh production@server "cd /opt/spacetime && docker-compose pull && docker-compose up -d"
```

### Pre-commit Hooks

**Install pre-commit:**
```bash
pip install pre-commit
```

**Create config:** `.pre-commit-config.yaml`

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-added-large-files
        args: ['--maxkb=5000']

  - repo: https://github.com/Scony/godot-gdscript-toolkit
    rev: 4.2.2
    hooks:
      - id: gdlint
        files: \.gd$
      - id: gdformat
        files: \.gd$

  - repo: https://github.com/psf/black
    rev: 24.1.1
    hooks:
      - id: black
        language_version: python3.11
        files: ^(tests/|examples/).*\.py$

  - repo: https://github.com/pycqa/flake8
    rev: 7.0.0
    hooks:
      - id: flake8
        args: ['--max-line-length=100']
        files: ^(tests/|examples/).*\.py$
```

**Install hooks:**
```bash
pre-commit install
pre-commit install --hook-type commit-msg
```

**Run manually:**
```bash
# Run on all files
pre-commit run --all-files

# Run on staged files
pre-commit run
```

---

## Docker Deployment

### Overview

Docker deployment provides:
- Consistent runtime environment
- Simplified dependency management
- Isolation from host system
- Easy scaling and orchestration

**IMPORTANT:** Docker deployments require X11 forwarding or VNC for GUI mode. Headless mode will not work.

### Dockerfile

**File:** `Dockerfile`

```dockerfile
# Use Godot CI base image
FROM barichello/godot-ci:4.5.1

# Install Python for management server
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    x11-xserver-utils \
    xvfb \
    libgl1-mesa-glx \
    libxrandr2 \
    libxi6 \
    libxcursor1 \
    libxinerama1 \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy project files
COPY . .

# Create virtual environment and install Python dependencies
RUN python3 -m venv .venv && \
    .venv/bin/pip install --no-cache-dir -r tests/property/requirements.txt && \
    .venv/bin/pip install --no-cache-dir aiohttp websockets

# Expose ports
EXPOSE 8090 8081 8081 6006 6005 8087/udp

# Set environment variables
ENV DISPLAY=:99
ENV PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://127.0.0.1:8090/health || exit 1

# Start with Xvfb for virtual display
CMD ["sh", "-c", "Xvfb :99 -screen 0 1280x1024x24 & sleep 2 && .venv/bin/python godot_editor_server.py --port 8090 --godot-path /usr/local/bin/godot --project-path /app --auto-load-scene"]
```

### Docker Compose

**File:** `docker-compose.yml`

```yaml
version: '3.8'

services:
  spacetime:
    build:
      context: .
      dockerfile: Dockerfile
    image: spacetime:latest
    container_name: spacetime-server
    restart: unless-stopped
    ports:
      - "8090:8090"    # Python Management Server
      - "8081:8081"    # Godot HTTP API
      - "8081:8081"    # Telemetry WebSocket
      - "6006:6006"    # DAP
      - "6005:6005"    # LSP
      - "8087:8087/udp" # Service Discovery
    volumes:
      # Mount project files for hot-reload
      - ./scripts:/app/scripts:ro
      - ./addons:/app/addons:ro
      - ./scenes:/app/scenes:ro
      # Persistent logs
      - ./logs:/app/logs
      # Persistent save data
      - ./saves:/app/saves
    environment:
      - DISPLAY=:99
      - PYTHONUNBUFFERED=1
      - LOG_LEVEL=INFO
    healthcheck:
      test: ["CMD", "curl", "-f", "http://127.0.0.1:8090/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    networks:
      - spacetime-network

  # Optional: Prometheus monitoring
  prometheus:
    image: prom/prometheus:latest
    container_name: spacetime-prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - spacetime-network

  # Optional: Grafana dashboard
  grafana:
    image: grafana/grafana:latest
    container_name: spacetime-grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards:ro
      - ./monitoring/grafana/datasources:/etc/grafana/provisioning/datasources:ro
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    networks:
      - spacetime-network

networks:
  spacetime-network:
    driver: bridge

volumes:
  prometheus-data:
  grafana-data:
```

### Docker Commands

**Build image:**
```bash
docker build -t spacetime:latest .
```

**Run container:**
```bash
# Single container
docker run -d \
  --name spacetime \
  -p 8090:8090 -p 8080:8080 -p 8081:8081 -p 6006:6006 -p 6005:6005 -p 8087:8087/udp \
  -v $(pwd)/logs:/app/logs \
  spacetime:latest

# With Docker Compose
docker-compose up -d
```

**View logs:**
```bash
docker logs -f spacetime
docker-compose logs -f spacetime
```

**Health check:**
```bash
docker exec spacetime curl -f http://127.0.0.1:8090/health
```

**Stop/Restart:**
```bash
docker stop spacetime
docker restart spacetime

# Docker Compose
docker-compose stop
docker-compose restart
docker-compose down
```

### Volume Mounts

**Development setup** (hot-reload):
```yaml
volumes:
  - ./scripts:/app/scripts:ro
  - ./addons:/app/addons:ro
  - ./scenes:/app/scenes:ro
```

**Production setup** (immutable):
```yaml
volumes:
  - ./logs:/app/logs
  - ./saves:/app/saves
```

### Docker Health Checks

**Built-in health check:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://127.0.0.1:8090/health || exit 1
```

**Docker Compose health check:**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://127.0.0.1:8090/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

**Manual health check:**
```bash
docker inspect --format='{{.State.Health.Status}}' spacetime
```

---

## Monitoring & Alerting

### Health Check Endpoints

#### Python Server Health

**Endpoint:** `GET http://127.0.0.1:8090/health`

**Response:**
```json
{
  "server": "healthy",
  "timestamp": "2025-12-02T10:30:00",
  "godot_process": {
    "running": true,
    "pid": 12345
  },
  "godot_api": {
    "reachable": true
  },
  "scene": {
    "loaded": true,
    "name": "vr_main"
  },
  "player": {
    "spawned": true
  },
  "overall_healthy": true,
  "blocking_issues": []
}
```

**Status codes:**
- `200` - All systems healthy
- `503` - System unhealthy (check `blocking_issues`)

#### Godot API Health

**Endpoint:** `GET http://127.0.0.1:8080/status`

**Response:**
```json
{
  "debug_adapter": {
    "service_name": "Debug Adapter",
    "port": 6006,
    "state": 2,
    "retry_count": 0,
    "last_activity": 1733140200.0
  },
  "language_server": {
    "service_name": "Language Server",
    "port": 6005,
    "state": 2,
    "retry_count": 0,
    "last_activity": 1733140200.0
  },
  "overall_ready": true
}
```

**State values:**
- `0` - DISCONNECTED
- `1` - CONNECTING
- `2` - CONNECTED
- `3` - CIRCUIT_BREAKER_OPEN

### Prometheus Integration

#### Metrics Exporter

**Create:** `scripts/monitoring/prometheus_exporter.py`

```python
#!/usr/bin/env python3
"""
Prometheus metrics exporter for SpaceTime.
Scrapes health endpoints and exposes metrics on port 9091.
"""

import time
import requests
from prometheus_client import start_http_server, Gauge, Counter, Histogram
from typing import Optional, Dict, Any

# Metrics
HEALTH_STATUS = Gauge('spacetime_health_status', 'Overall health status (1=healthy, 0=unhealthy)')
GODOT_RUNNING = Gauge('spacetime_godot_running', 'Godot process running (1=yes, 0=no)')
SCENE_LOADED = Gauge('spacetime_scene_loaded', 'Main scene loaded (1=yes, 0=no)')
PLAYER_SPAWNED = Gauge('spacetime_player_spawned', 'Player spawned (1=yes, 0=no)')
API_RESPONSE_TIME = Histogram('spacetime_api_response_time_seconds', 'API response time')
RESTART_COUNT = Counter('spacetime_restart_total', 'Total Godot restarts')
ERROR_COUNT = Counter('spacetime_error_total', 'Total errors', ['type'])

# Configuration
PYTHON_SERVER_URL = "http://127.0.0.1:8090"
GODOT_API_URL = "http://127.0.0.1:8080"
SCRAPE_INTERVAL = 15  # seconds


class MetricsCollector:
    """Collects and exports metrics from SpaceTime servers."""

    def __init__(self):
        self.previous_pid = None

    def collect_metrics(self):
        """Collect metrics from health endpoints."""
        # Python server health
        try:
            start_time = time.time()
            response = requests.get(f"{PYTHON_SERVER_URL}/health", timeout=5)
            response_time = time.time() - start_time

            API_RESPONSE_TIME.observe(response_time)

            if response.status_code == 200:
                data = response.json()

                # Update metrics
                HEALTH_STATUS.set(1 if data.get("overall_healthy") else 0)
                GODOT_RUNNING.set(1 if data.get("godot_process", {}).get("running") else 0)
                SCENE_LOADED.set(1 if data.get("scene", {}).get("loaded") else 0)
                PLAYER_SPAWNED.set(1 if data.get("player", {}).get("spawned") else 0)

                # Detect restarts
                current_pid = data.get("godot_process", {}).get("pid")
                if self.previous_pid and current_pid != self.previous_pid:
                    RESTART_COUNT.inc()
                self.previous_pid = current_pid
            else:
                HEALTH_STATUS.set(0)
                ERROR_COUNT.labels(type='http_error').inc()

        except requests.exceptions.RequestException as e:
            print(f"Error collecting metrics: {e}")
            HEALTH_STATUS.set(0)
            ERROR_COUNT.labels(type='connection_error').inc()

    def run(self):
        """Run metrics collection loop."""
        print(f"Starting Prometheus exporter on port 9091")
        start_http_server(9091)

        print(f"Scraping metrics every {SCRAPE_INTERVAL}s")
        while True:
            self.collect_metrics()
            time.sleep(SCRAPE_INTERVAL)


if __name__ == "__main__":
    collector = MetricsCollector()
    collector.run()
```

**Run exporter:**
```bash
pip install prometheus-client requests
python scripts/monitoring/prometheus_exporter.py
```

#### Prometheus Configuration

**File:** `monitoring/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'spacetime'
    static_configs:
      - targets: ['spacetime:9091']
        labels:
          instance: 'spacetime-server'

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - 'alerts.yml'
```

#### Alert Rules

**File:** `monitoring/alerts.yml`

```yaml
groups:
  - name: spacetime_alerts
    interval: 30s
    rules:
      # System down
      - alert: SpaceTimeDown
        expr: up{job="spacetime"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "SpaceTime server is down"
          description: "SpaceTime server has been down for more than 2 minutes"

      # Health status
      - alert: SpaceTimeUnhealthy
        expr: spacetime_health_status == 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "SpaceTime is unhealthy"
          description: "SpaceTime health status has been unhealthy for 5 minutes"

      # Godot process
      - alert: GodotProcessDown
        expr: spacetime_godot_running == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Godot process not running"
          description: "Godot process has been down for 1 minute"

      # Scene not loaded
      - alert: SceneNotLoaded
        expr: spacetime_scene_loaded == 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Main scene not loaded"
          description: "Main scene has not been loaded for 5 minutes"

      # Frequent restarts
      - alert: FrequentRestarts
        expr: rate(spacetime_restart_total[5m]) > 0.05
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Frequent Godot restarts detected"
          description: "Godot is restarting more than 3 times per 5 minutes"

      # High error rate
      - alert: HighErrorRate
        expr: rate(spacetime_error_total[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is above threshold for 5 minutes"

      # Slow API responses
      - alert: SlowAPIResponses
        expr: histogram_quantile(0.95, rate(spacetime_api_response_time_seconds_bucket[5m])) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "API responses are slow"
          description: "95th percentile API response time is above 2 seconds"
```

### Grafana Dashboard

**Create:** `monitoring/grafana/dashboards/spacetime.json`

```json
{
  "dashboard": {
    "title": "SpaceTime VR Monitoring",
    "panels": [
      {
        "title": "Overall Health",
        "targets": [
          {
            "expr": "spacetime_health_status",
            "legendFormat": "Health Status"
          }
        ],
        "type": "stat"
      },
      {
        "title": "Godot Process Status",
        "targets": [
          {
            "expr": "spacetime_godot_running",
            "legendFormat": "Running"
          }
        ],
        "type": "stat"
      },
      {
        "title": "Scene & Player Status",
        "targets": [
          {
            "expr": "spacetime_scene_loaded",
            "legendFormat": "Scene Loaded"
          },
          {
            "expr": "spacetime_player_spawned",
            "legendFormat": "Player Spawned"
          }
        ],
        "type": "graph"
      },
      {
        "title": "API Response Time",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(spacetime_api_response_time_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.50, rate(spacetime_api_response_time_seconds_bucket[5m]))",
            "legendFormat": "50th percentile"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Restart Count",
        "targets": [
          {
            "expr": "rate(spacetime_restart_total[5m])",
            "legendFormat": "Restarts/min"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(spacetime_error_total[5m])",
            "legendFormat": "{{type}}"
          }
        ],
        "type": "graph"
      }
    ]
  }
}
```

**Access dashboard:**
```
http://localhost:3000
Username: admin
Password: admin (change this!)
```

### Telemetry Monitoring

SpaceTime's WebSocket telemetry provides real-time monitoring without polling.

**Python client example:**
```python
#!/usr/bin/env python3
import asyncio
import websockets
import json
from datetime import datetime

async def monitor_telemetry():
    async with websockets.connect('ws://127.0.0.1:8081') as ws:
        print(f"[{datetime.now()}] Connected to telemetry")

        async for message in ws:
            data = json.loads(message)
            event = data.get('event')

            if event == 'fps':
                fps = data['data']['fps']
                frame_time = data['data']['frame_time_ms']
                print(f"FPS: {fps:.1f} | Frame Time: {frame_time:.2f}ms")

            elif event == 'error':
                print(f"ERROR: {data['data']}")

            elif event == 'vr_tracking':
                headset = data['data']['headset']
                print(f"VR Headset: {headset['position']}")

asyncio.run(monitor_telemetry())
```

**Run monitor:**
```bash
python telemetry_client.py
```

---

## Security Hardening

### Network Security

#### Localhost-Only Binding (Default)

All services bind to `127.0.0.1` by default, preventing external access.

**Verify bindings:**
```bash
# Linux/Mac
netstat -tuln | grep -E '(8090|8080|8081|6006|6005)'

# Windows
netstat -an | findstr "8090 8080 8081 6006 6005"
```

**Expected output:**
```
tcp        0      0 127.0.0.1:8090          0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.1:8080          0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.1:8081          0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.1:6006          0.0.0.0:*               LISTEN
tcp        0      0 127.0.0.1:6005          0.0.0.0:*               LISTEN
```

#### Reverse Proxy (Nginx)

For external access, use a reverse proxy with authentication.

**Install Nginx:**
```bash
sudo apt-get install nginx apache2-utils
```

**Create password file:**
```bash
sudo htpasswd -c /etc/nginx/.htpasswd spacetime_user
```

**Configure Nginx:** `/etc/nginx/sites-available/spacetime`

```nginx
server {
    listen 443 ssl http2;
    server_name spacetime.example.com;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/spacetime.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/spacetime.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Basic authentication
    auth_basic "SpaceTime API";
    auth_basic_user_file /etc/nginx/.htpasswd;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req zone=api_limit burst=20 nodelay;

    # Python server proxy
    location /api/ {
        proxy_pass http://127.0.0.1:8090/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # WebSocket telemetry
    location /telemetry {
        proxy_pass http://127.0.0.1:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }

    # Access logs
    access_log /var/log/nginx/spacetime-access.log;
    error_log /var/log/nginx/spacetime-error.log;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name spacetime.example.com;
    return 301 https://$server_name$request_uri;
}
```

**Enable site:**
```bash
sudo ln -s /etc/nginx/sites-available/spacetime /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

**Test with authentication:**
```bash
curl -u spacetime_user:password https://spacetime.example.com/api/health
```

### Rate Limiting

#### Application-Level (Python)

**Install flask-limiter:**
```bash
pip install flask-limiter
```

**Add to godot_editor_server.py:**
```python
from flask import Flask
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

app = Flask(__name__)
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["100 per hour", "10 per minute"]
)

@app.route('/health')
@limiter.limit("30 per minute")
def health():
    # ... health check logic
    pass

@app.route('/restart', methods=['POST'])
@limiter.limit("5 per hour")
def restart():
    # ... restart logic
    pass
```

#### Nginx Rate Limiting

Already configured in the Nginx example above:
```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_req zone=api_limit burst=20 nodelay;
```

**Limits:**
- `rate=10r/s` - 10 requests per second per IP
- `burst=20` - Allow bursts up to 20 requests
- `nodelay` - Process burst requests immediately

### Authentication Options

#### API Key Authentication

**Add to GodotBridge:**

```gdscript
# In godot_bridge.gd
const API_KEYS: Array[String] = [
    "spacetime_key_abc123",
    "spacetime_key_def456"
]

func _validate_api_key(request_headers: Dictionary) -> bool:
    var auth_header = request_headers.get("Authorization", "")
    if auth_header.begins_with("Bearer "):
        var key = auth_header.substr(7)
        return key in API_KEYS
    return false

func _handle_request(client: StreamPeerTCP, request: Dictionary):
    # Check API key
    if not _validate_api_key(request.headers):
        _send_response(client, 401, {
            "error": "Unauthorized",
            "message": "Invalid or missing API key"
        })
        return

    # ... process request
```

**Client usage:**
```bash
curl -H "Authorization: Bearer spacetime_key_abc123" \
  http://127.0.0.1:8080/status
```

#### JWT Authentication

**Install PyJWT:**
```bash
pip install pyjwt
```

**Python server with JWT:**
```python
import jwt
from datetime import datetime, timedelta

SECRET_KEY = "your-secret-key-change-this"
ALGORITHM = "HS256"

def generate_token(user_id: str) -> str:
    payload = {
        "user_id": user_id,
        "exp": datetime.utcnow() + timedelta(hours=24)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str) -> bool:
    try:
        jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return True
    except jwt.ExpiredSignatureError:
        return False
    except jwt.InvalidTokenError:
        return False
```

### HTTPS/TLS Setup

#### Self-Signed Certificate (Development)

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout spacetime.key \
  -out spacetime.crt \
  -subj "/CN=localhost"

# Use with Nginx
ssl_certificate /path/to/spacetime.crt;
ssl_certificate_key /path/to/spacetime.key;
```

#### Let's Encrypt (Production)

```bash
# Install Certbot
sudo apt-get install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d spacetime.example.com

# Auto-renewal (Certbot sets this up automatically)
sudo certbot renew --dry-run
```

**Certbot configuration:**
```bash
# Renewal hook to reload Nginx
sudo cat > /etc/letsencrypt/renewal-hooks/post/reload-nginx.sh <<'EOF'
#!/bin/bash
systemctl reload nginx
EOF

sudo chmod +x /etc/letsencrypt/renewal-hooks/post/reload-nginx.sh
```

### Network Isolation

#### Docker Network Isolation

```yaml
# docker-compose.yml
services:
  spacetime:
    networks:
      - internal

  nginx:
    networks:
      - internal
      - external
    ports:
      - "443:443"

networks:
  internal:
    internal: true
  external:
```

**Effect:** Only Nginx can access external network, SpaceTime is isolated.

#### Firewall Rules (UFW)

```bash
# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTPS only (no direct API access)
sudo ufw allow 443/tcp

# Block direct API ports
sudo ufw deny 8090/tcp
sudo ufw deny 8080/tcp

# Enable firewall
sudo ufw enable
```

### Input Validation

**Critical areas:**
- Scene paths (prevent directory traversal)
- File paths (validate `res://` prefix)
- Command injection (sanitize inputs)

**Example validation:**
```gdscript
func _validate_scene_path(path: String) -> bool:
    # Must start with res://
    if not path.begins_with("res://"):
        return false

    # No directory traversal
    if ".." in path:
        return false

    # Valid file extension
    if not path.ends_with(".tscn"):
        return false

    return true
```

### Secure Defaults

**Environment variables:**
```bash
# Production
export DEBUG_MODE=false
export LOG_LEVEL=INFO
export ENABLE_TELEMETRY=true
export API_KEY_REQUIRED=true

# Development
export DEBUG_MODE=true
export LOG_LEVEL=DEBUG
export ENABLE_TELEMETRY=true
export API_KEY_REQUIRED=false
```

**Configuration file:** `config/production.json`
```json
{
  "security": {
    "require_auth": true,
    "rate_limit_enabled": true,
    "rate_limit_per_minute": 60,
    "allowed_origins": ["https://spacetime.example.com"],
    "max_request_size_mb": 10
  },
  "monitoring": {
    "telemetry_enabled": true,
    "metrics_enabled": true,
    "log_level": "INFO"
  },
  "features": {
    "auto_restart_on_crash": true,
    "max_restart_attempts": 3,
    "health_check_interval_seconds": 30
  }
}
```

---

## Troubleshooting

### Common Issues

#### Issue: Services not starting

**Symptoms:**
- Port already in use errors
- Connection refused errors

**Solutions:**
```bash
# Check what's using ports
lsof -i :8090
lsof -i :8080

# Kill existing processes
kill -9 <PID>

# Try fallback ports
python godot_editor_server.py --port 8091
```

#### Issue: Autoloads not initializing

**Symptoms:**
- HTTP API returns 404
- Telemetry not connecting
- `/status` endpoint fails

**Cause:** Godot running in headless mode

**Solution:**
```bash
# ✗ WRONG - Headless disables autoloads
godot --headless --path .

# ✓ CORRECT - GUI mode required
godot --path . --dap-port 6006 --lsp-port 6005 --editor

# ✓ CORRECT - Use Python server
python godot_editor_server.py
```

#### Issue: Docker container unhealthy

**Symptoms:**
- Container status shows "unhealthy"
- Health checks failing

**Debug:**
```bash
# Check container logs
docker logs spacetime

# Exec into container
docker exec -it spacetime /bin/bash

# Check health manually
curl http://127.0.0.1:8090/health

# Check Xvfb running
ps aux | grep Xvfb

# Restart container
docker-compose restart spacetime
```

#### Issue: High memory usage

**Symptoms:**
- Godot consuming excessive RAM
- System slowdown

**Solutions:**
```bash
# Monitor memory
top -p $(pgrep godot)

# Set memory limits (Docker)
docker update --memory 4g spacetime

# Set memory limits (systemd)
# Add to service file:
MemoryLimit=4G
MemoryMax=6G
```

#### Issue: Frequent restarts

**Symptoms:**
- Godot restarting repeatedly
- Restart counter increasing

**Debug:**
```bash
# Check logs for crash reasons
grep ERROR godot_editor_server.log

# Check Godot logs
cat ~/.local/share/godot/app_userdata/SpaceTime/logs/godot.log

# Check system resources
free -h
df -h
```

**Common causes:**
- Out of memory (increase limits)
- Parse errors in scripts (check `/status` endpoint)
- Missing dependencies (verify scene files)
- GPU driver issues (update drivers)

### Performance Tuning

#### Godot Settings

**project.godot:**
```ini
[physics]
common/physics_ticks_per_second=90  # Match VR refresh rate
3d/physics_engine="GodotPhysics3D"

[rendering]
renderer/rendering_method="forward_plus"
anti_aliasing/quality/msaa_3d=2
textures/vram_compression/import_etc2_astc=true
```

#### Python Server Settings

```python
# godot_editor_server.py
# Adjust these parameters for your workload

# Health check interval (seconds)
--check-interval 30

# Scene load timeout (seconds)
--player-timeout 30

# Max restart attempts
MAX_RESTART_ATTEMPTS = 3

# Request timeout (seconds)
REQUEST_TIMEOUT = 10
```

#### Docker Resource Limits

```yaml
# docker-compose.yml
services:
  spacetime:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
```

### Logging Best Practices

**Log levels:**
- `DEBUG` - Development only, verbose output
- `INFO` - Production, normal operations
- `WARNING` - Issues that don't block functionality
- `ERROR` - Critical failures requiring attention

**Log rotation:**
```bash
# Linux (logrotate)
/var/log/spacetime/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
}
```

**Structured logging:**
```python
import logging
import json

logger = logging.getLogger(__name__)

# JSON logging for parsing
logger.info(json.dumps({
    "event": "scene_loaded",
    "scene_path": "res://vr_main.tscn",
    "timestamp": time.time(),
    "pid": os.getpid()
}))
```

---

## Summary

### Deployment Options Covered

1. **Python Management Server** - Recommended for production with automatic process management
2. **Direct Godot Launch** - Suitable for development and testing
3. **systemd Service** - Linux production deployment with auto-restart
4. **supervisord** - Alternative Linux/Mac process manager
5. **Windows Service (NSSM)** - Windows production deployment
6. **Docker Container** - Containerized deployment with orchestration
7. **Docker Compose** - Multi-container setup with monitoring

### Critical Production Considerations

**Top 5 Must-Know Facts:**

1. **GUI Mode is Mandatory**
   - Headless mode disables autoloads (GodotBridge, TelemetryServer, etc.)
   - Use Xvfb for virtual display in Docker/headless environments
   - Python server automatically manages GUI mode

2. **Port Configuration**
   - 6 services on 6 ports (8090, 8080, 8081, 6006, 6005, 8087)
   - HTTP API has automatic fallback ports (8083-8085)
   - All services bind to localhost by default for security

3. **Auto-Restart Required**
   - Godot can crash due to VR, GPU, or script errors
   - Python server provides health monitoring and auto-restart (max 3 attempts)
   - systemd/supervisord can restart the entire Python server

4. **Scene Loading is Asynchronous**
   - Scene must be loaded before player spawns
   - Use `/health` endpoint to verify scene and player status
   - Python server can auto-load scene on startup with `--auto-load-scene`

5. **Monitoring is Essential**
   - Use `/health` endpoint for health checks
   - Telemetry WebSocket provides real-time monitoring
   - Prometheus + Grafana for production observability

### Security Recommendations

**Priority 1 (Critical):**
- [ ] Change default passwords (Grafana, Nginx, etc.)
- [ ] Enable HTTPS with valid certificates (Let's Encrypt)
- [ ] Use authentication for external access (API keys or JWT)
- [ ] Bind to localhost only (127.0.0.1) unless reverse proxy used

**Priority 2 (Important):**
- [ ] Enable rate limiting (10-60 requests/minute)
- [ ] Set up firewall rules (block direct API access)
- [ ] Implement input validation (scene paths, file paths)
- [ ] Use network isolation (Docker networks, VPCs)

**Priority 3 (Recommended):**
- [ ] Set resource limits (CPU, memory, disk)
- [ ] Enable audit logging (access logs, API calls)
- [ ] Set up alerts (Prometheus, email, Slack)
- [ ] Regular security updates (Godot, Python, dependencies)

**Priority 4 (Optional):**
- [ ] Use VPN for remote access
- [ ] Implement IP whitelisting
- [ ] Set up intrusion detection (fail2ban)
- [ ] Enable two-factor authentication

### Quick Start Checklist

**For Production Deployment:**

1. [ ] Install dependencies (Python, Godot, Docker if needed)
2. [ ] Configure firewall (allow required ports)
3. [ ] Set up process manager (systemd/supervisord/NSSM)
4. [ ] Enable log rotation (logrotate or native)
5. [ ] Configure monitoring (Prometheus + Grafana)
6. [ ] Set up reverse proxy (Nginx with HTTPS)
7. [ ] Enable authentication (API keys or JWT)
8. [ ] Test health endpoints (`/health`, `/status`)
9. [ ] Configure alerts (Prometheus alerts)
10. [ ] Document runbook for team

**For CI/CD Integration:**

1. [ ] Add pre-commit hooks (gdlint, gdformat, black)
2. [ ] Set up CI workflow (GitHub Actions or GitLab CI)
3. [ ] Configure test jobs (Python, GDScript, scene validation)
4. [ ] Add build job (export for target platforms)
5. [ ] Set up Docker build and push
6. [ ] Configure deployment jobs (staging, production)
7. [ ] Add status badges to README
8. [ ] Document CI/CD process

### Support Resources

- **Project Documentation:** `CLAUDE.md`, `HTTP_API.md`, `TELEMETRY_GUIDE.md`
- **Health Monitor:** `tests/health_monitor.py`
- **Python Server:** `godot_editor_server.py`
- **Test Suite:** `tests/test_runner.py`
- **Example Clients:** `examples/` directory

---

**End of Deployment Guide**

For questions or issues, consult the project documentation or create an issue in the project repository.
