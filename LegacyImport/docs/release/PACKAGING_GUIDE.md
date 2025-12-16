# Production Deployment Package Guide

**Version:** 2.5.0
**Last Updated:** 2025-12-02

## Overview

This guide explains how to create, validate, and distribute production-ready deployment packages for SpaceTime VR. The packaging system automates the creation of complete, versioned releases with all necessary components, documentation, and security artifacts.

## Table of Contents

1. [Package Structure](#package-structure)
2. [Building a Package](#building-a-package)
3. [Package Contents](#package-contents)
4. [Validation and Testing](#validation-and-testing)
5. [Distribution](#distribution)
6. [Security](#security)
7. [Versioning](#versioning)
8. [Troubleshooting](#troubleshooting)

---

## Package Structure

### Overview

Each release package follows a standardized structure:

```
spacetime-vr-v2.5.0/
├── binaries/              # Compiled game server and assets
│   ├── spacetime-server.exe
│   ├── spacetime-vr-2.5.0.tar.gz (Docker image)
│   ├── scripts/          # GDScript files
│   ├── addons/           # Godot addons
│   └── VERSION.txt
│
├── config/               # Configuration templates
│   ├── production/
│   │   ├── .env.template
│   │   ├── prometheus.yml
│   │   └── nginx.conf
│   ├── staging/
│   │   └── .env.template
│   └── development/
│       └── .env.template
│
├── scripts/              # Deployment automation
│   ├── deployment/
│   │   ├── deploy.sh
│   │   ├── rollback.sh
│   │   └── setup_monitoring.sh
│   ├── maintenance/
│   │   ├── backup.sh
│   │   └── restore.sh
│   └── migration/
│       └── migrate_database.sh
│
├── kubernetes/           # K8s manifests and Helm charts
│   ├── base/
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── production/
│       └── staging/
│
├── monitoring/           # Observability configuration
│   ├── prometheus/
│   │   ├── prometheus.yml
│   │   ├── alerts.yml
│   │   └── rules/
│   ├── grafana/
│   │   └── dashboards/
│   └── alertmanager/
│       └── config.yml
│
├── docs/                 # Complete documentation
│   ├── deployment/
│   ├── operations/
│   ├── security/
│   └── api/
│
├── tests/                # Test suites
│   ├── smoke/
│   │   └── smoke_test.sh
│   ├── integration/
│   └── performance/
│
├── security/             # Security artifacts
│   ├── certificates/
│   ├── policies/
│   └── reports/
│
├── RELEASE_NOTES.md      # What's new
├── DEPLOYMENT_CHECKLIST.md
├── MANIFEST.json         # Package metadata
├── SHA256SUMS            # File checksums
└── SHA256SUMS.asc        # GPG signature
```

---

## Building a Package

### Prerequisites

Ensure the following tools are installed:

- **Godot Engine**: 4.5.1+
- **Docker**: 20.10+ (with buildx)
- **Kubernetes CLI**: kubectl 1.25+
- **Helm**: 3.x
- **Python**: 3.8+
- **Git**: 2.x
- **GPG**: 2.x (for signing)
- **sha256sum**: For checksums

### Environment Setup

1. **Set version number**:
   ```bash
   echo "2.5.0" > VERSION
   ```

2. **Configure environment variables**:
   ```bash
   export DOCKER_REGISTRY="ghcr.io/your-org"
   export ARTIFACT_REPO="s3://spacetime-artifacts"
   export GPG_KEY_ID="your-gpg-key-id"
   ```

3. **Authenticate to Docker registry**:
   ```bash
   docker login ghcr.io
   ```

4. **Authenticate to artifact repository**:
   ```bash
   aws configure  # or equivalent for your storage
   ```

### Build Process

#### Automated Build (Recommended)

```bash
cd C:/godot/release
chmod +x build_package.sh
./build_package.sh
```

The script will:
1. Validate prerequisites
2. Build Godot binary
3. Build Docker image
4. Package all components
5. Generate documentation
6. Create checksums
7. Sign package (if GPG configured)
8. Create distribution archives

#### Manual Build Steps

If you need to build components individually:

**1. Build Godot Server Binary:**
```bash
cd C:/godot
godot --headless --export-release "Windows Desktop" \
  "release/spacetime-vr-v2.5.0/binaries/spacetime-server.exe"
```

**2. Build Docker Image:**
```bash
docker build -t ghcr.io/your-org/spacetime-vr:2.5.0 \
  --build-arg VERSION=2.5.0 \
  --file Dockerfile.v2.5 .
```

**3. Package GDScript Files:**
```bash
cp -r scripts addons release/spacetime-vr-v2.5.0/binaries/
```

**4. Copy Configuration:**
```bash
cp .env.production release/spacetime-vr-v2.5.0/config/production/.env.template
```

**5. Copy Kubernetes Manifests:**
```bash
cp -r kubernetes/* release/spacetime-vr-v2.5.0/kubernetes/
```

**6. Generate Checksums:**
```bash
cd release/spacetime-vr-v2.5.0
find . -type f ! -name "SHA256SUMS*" -exec sha256sum {} \; > SHA256SUMS
```

**7. Create Archive:**
```bash
cd release
tar -czf spacetime-vr-v2.5.0.tar.gz spacetime-vr-v2.5.0/
```

---

## Package Contents

### Binaries (`binaries/`)

**Godot Server Executable:**
- `spacetime-server.exe` - Main game server binary
- Supports headless mode for Linux servers
- OpenXR VR support compiled in

**Docker Image:**
- `spacetime-vr-2.5.0.tar.gz` - Compressed Docker image
- Multi-arch: linux/amd64, linux/arm64
- Load with: `docker load < spacetime-vr-2.5.0.tar.gz`

**GDScript Files:**
- All scripts organized by subsystem
- Addons included (godot_debug_connection, gdUnit4)
- Scene files (.tscn)

### Configuration (`config/`)

**Environment Templates:**

Each environment has a `.env.template` with placeholders:

```bash
# Database
DATABASE_URL=postgresql://user:<PASSWORD>@host:5432/spacetime_vr
DATABASE_POOL_SIZE=20

# Security
JWT_SECRET=<GENERATE_32_CHAR_SECRET>
API_KEY=<GENERATE_64_CHAR_KEY>
TLS_CERT_PATH=/etc/ssl/certs/spacetime.crt
TLS_KEY_PATH=/etc/ssl/private/spacetime.key

# Redis
REDIS_URL=redis://:<PASSWORD>@redis:6379/0

# Monitoring
PROMETHEUS_URL=http://prometheus:9090
GRAFANA_URL=http://grafana:3000
```

**Service Configuration:**
- `prometheus.yml` - Metrics scraping config
- `nginx.conf` - Reverse proxy config
- `alertmanager.yml` - Alert routing

### Scripts (`scripts/`)

**Deployment:**
- `deploy.sh` - Main deployment script
- `rollback.sh` - Emergency rollback
- `setup_monitoring.sh` - Monitoring stack setup

**Maintenance:**
- `backup.sh` - Database backup
- `restore.sh` - Database restore
- `health_check.sh` - Service health verification

**Migration:**
- `migrate_database.sh` - Database schema migrations
- SQL migration files numbered sequentially

### Kubernetes (`kubernetes/`)

**Base Resources:**
- Namespace, ConfigMap, Secret
- Deployment, Service, Ingress
- HPA (Horizontal Pod Autoscaler)
- NetworkPolicy
- PVC (Persistent Volume Claims)

**Overlays (Kustomize):**
- Production overlay with replicas, resource limits
- Staging overlay with reduced resources
- Environment-specific patches

**Usage:**
```bash
kubectl apply -k kubernetes/overlays/production
```

### Monitoring (`monitoring/`)

**Prometheus:**
- Alert rules for critical metrics
- Recording rules for performance
- Service discovery configuration

**Grafana:**
- Pre-built dashboards (JSON format)
- HTTP API Overview dashboard
- Server Meshing dashboard
- VR Performance dashboard

**Alertmanager:**
- Alert routing rules
- Notification templates
- Inhibition rules

### Documentation (`docs/`)

Complete operational documentation:

- **Deployment Guide** - Step-by-step deployment
- **Operations Runbook** - Day-to-day operations
- **Security Guide** - Security best practices
- **API Reference** - Complete API documentation
- **Monitoring Guide** - Observability setup
- **Rollback Procedures** - Emergency rollback
- **Incident Response** - Incident handling

### Tests (`tests/`)

**Smoke Tests:**
- Quick validation suite (5 minutes)
- Tests critical endpoints
- Validates connectivity

**Integration Tests:**
- End-to-end workflow tests
- Database persistence tests
- Multiplayer synchronization tests

**Performance Tests:**
- Load testing scripts
- Property-based tests
- VR performance validation

### Security (`security/`)

**Certificates:**
- Example certificate configurations
- Certificate renewal procedures

**Policies:**
- Security policies and standards
- Compliance checklists
- Access control matrices

**Reports:**
- Security audit reports
- Vulnerability assessments
- Penetration test results

---

## Validation and Testing

### Package Validation

After building, validate package completeness:

```bash
cd release/spacetime-vr-v2.5.0

# Check structure
test -d binaries && echo "✓ binaries/"
test -d config && echo "✓ config/"
test -d scripts && echo "✓ scripts/"
test -d kubernetes && echo "✓ kubernetes/"
test -d monitoring && echo "✓ monitoring/"
test -d docs && echo "✓ docs/"
test -d tests && echo "✓ tests/"
test -d security && echo "✓ security/"

# Check critical files
test -f RELEASE_NOTES.md && echo "✓ RELEASE_NOTES.md"
test -f DEPLOYMENT_CHECKLIST.md && echo "✓ DEPLOYMENT_CHECKLIST.md"
test -f MANIFEST.json && echo "✓ MANIFEST.json"
test -f SHA256SUMS && echo "✓ SHA256SUMS"

# Verify checksums
sha256sum -c SHA256SUMS
```

### Checksum Verification

**Verify package integrity:**

```bash
# Verify checksums
sha256sum -c SHA256SUMS

# Verify GPG signature (if signed)
gpg --verify SHA256SUMS.asc SHA256SUMS
```

### Staging Deployment Test

**Before production, test in staging:**

```bash
# Deploy to staging
./scripts/deployment/deploy.sh staging

# Run smoke tests
./tests/smoke/smoke_test.sh

# Run integration tests
cd tests/integration
python3 test_runner.py

# Verify monitoring
curl http://staging-prometheus:9090/api/v1/targets

# Test rollback
./scripts/deployment/rollback.sh staging
```

### Load Testing

**Validate performance under load:**

```bash
# Install load testing tool
pip install locust

# Run load test
cd tests/performance
locust -f load_test.py --host=https://staging.spacetime-vr.com

# Monitor during test
# Target: 1000 concurrent users, p95 latency < 100ms
```

---

## Distribution

### Archive Creation

The build script creates two archives:

- **spacetime-vr-v2.5.0.tar.gz** - For Linux/Unix (preferred)
- **spacetime-vr-v2.5.0.zip** - For Windows

### Upload to Artifact Repository

**AWS S3 Example:**

```bash
aws s3 cp spacetime-vr-v2.5.0.tar.gz \
  s3://spacetime-artifacts/releases/v2.5.0/

aws s3 cp spacetime-vr-v2.5.0/SHA256SUMS \
  s3://spacetime-artifacts/releases/v2.5.0/

aws s3 cp spacetime-vr-v2.5.0/SHA256SUMS.asc \
  s3://spacetime-artifacts/releases/v2.5.0/
```

**Make release public (optional):**

```bash
aws s3api put-object-acl \
  --bucket spacetime-artifacts \
  --key releases/v2.5.0/spacetime-vr-v2.5.0.tar.gz \
  --acl public-read
```

### Docker Image Distribution

**Push to registry:**

```bash
docker push ghcr.io/your-org/spacetime-vr:2.5.0
docker push ghcr.io/your-org/spacetime-vr:latest
```

**Pull on deployment target:**

```bash
docker pull ghcr.io/your-org/spacetime-vr:2.5.0
```

### Helm Chart Distribution

**Package Helm chart:**

```bash
helm package kubernetes/helm/spacetime-vr

# Upload to chart repository
helm repo add spacetime https://charts.spacetime-vr.com
helm push spacetime-vr-2.5.0.tgz spacetime
```

---

## Security

### Package Signing

**Generate GPG key (if not exists):**

```bash
gpg --full-generate-key
# Select: RSA and RSA, 4096 bits, no expiration
```

**Sign package:**

```bash
cd release/spacetime-vr-v2.5.0
gpg --local-user your-key-id --detach-sign --armor SHA256SUMS
```

**Verify signature:**

```bash
gpg --verify SHA256SUMS.asc SHA256SUMS
```

### Checksum Verification

**Generate checksums:**

```bash
find . -type f ! -name "SHA256SUMS*" -exec sha256sum {} \; > SHA256SUMS
```

**Verify all files:**

```bash
sha256sum -c SHA256SUMS
```

### Vulnerability Scanning

**Scan Docker image:**

```bash
# Using Trivy
trivy image ghcr.io/your-org/spacetime-vr:2.5.0

# Using Anchore
anchore-cli image add ghcr.io/your-org/spacetime-vr:2.5.0
anchore-cli image vuln ghcr.io/your-org/spacetime-vr:2.5.0 all
```

**Scan Kubernetes manifests:**

```bash
# Using kubesec
kubesec scan kubernetes/base/deployment.yaml

# Using Polaris
polaris audit --audit-path kubernetes/
```

### Security Checklist

Before releasing:

- [ ] All secrets rotated (not using defaults)
- [ ] No hardcoded credentials in code
- [ ] Docker image scanned (no critical/high CVEs)
- [ ] Kubernetes manifests validated
- [ ] TLS certificates valid (>30 days)
- [ ] Package signed with GPG
- [ ] Checksums generated and verified
- [ ] Security audit report included
- [ ] Vulnerability assessment complete
- [ ] Penetration test passed

---

## Versioning

### Semantic Versioning

SpaceTime VR follows [Semantic Versioning 2.0.0](https://semver.org/):

**Format:** MAJOR.MINOR.PATCH (e.g., 2.5.0)

- **MAJOR**: Breaking changes, incompatible API changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Version Tagging

**Create version tag:**

```bash
# Update VERSION file
echo "2.5.0" > VERSION

# Commit version bump
git add VERSION
git commit -m "Bump version to 2.5.0"

# Create annotated tag
git tag -a v2.5.0 -m "Release v2.5.0 - VR Performance Optimizations"

# Push tag
git push origin v2.5.0
```

### Version Metadata

Each package includes version metadata in `MANIFEST.json`:

```json
{
  "name": "spacetime-vr",
  "version": "2.5.0",
  "build_date": "2025-12-02T10:30:00Z",
  "git_commit": "abc123def456",
  "git_branch": "main",
  "build_user": "ci-system"
}
```

### Docker Image Tags

**Tagging strategy:**

- `v2.5.0` - Specific version
- `v2.5` - Latest patch for minor version
- `v2` - Latest minor for major version
- `latest` - Latest stable release
- `dev` - Development builds

```bash
docker tag spacetime-vr:2.5.0 spacetime-vr:v2.5
docker tag spacetime-vr:2.5.0 spacetime-vr:v2
docker tag spacetime-vr:2.5.0 spacetime-vr:latest
```

---

## Troubleshooting

### Build Failures

**Issue: Godot export fails**

```
ERROR: Can't open file from path 'res://icon.svg'
```

**Solution:**
- Ensure running from project root
- Verify export preset configured
- Check export_presets.cfg exists

**Issue: Docker build fails**

```
ERROR: failed to solve: failed to compute cache key
```

**Solution:**
- Check Dockerfile.v2.5 exists
- Verify Docker daemon running
- Try with `--no-cache` flag

### Packaging Issues

**Issue: Missing files in package**

**Solution:**
```bash
# Check template structure
ls -la release/package_template/

# Verify source files exist
ls -la scripts/ addons/ kubernetes/

# Re-run with verbose output
bash -x release/build_package.sh
```

**Issue: Checksum verification fails**

**Solution:**
```bash
# Regenerate checksums
cd release/spacetime-vr-v2.5.0
rm SHA256SUMS
find . -type f ! -name "SHA256SUMS*" -exec sha256sum {} \; > SHA256SUMS

# Verify
sha256sum -c SHA256SUMS
```

### Distribution Issues

**Issue: Docker push authentication fails**

```
ERROR: unauthorized: authentication required
```

**Solution:**
```bash
# Re-authenticate
docker login ghcr.io -u your-username

# Use token authentication
echo $GITHUB_TOKEN | docker login ghcr.io -u your-username --password-stdin
```

**Issue: S3 upload fails**

**Solution:**
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check bucket permissions
aws s3api get-bucket-acl --bucket spacetime-artifacts

# Test upload with small file
echo "test" > test.txt
aws s3 cp test.txt s3://spacetime-artifacts/test.txt
```

### Deployment Issues

**Issue: Kubernetes resources fail to apply**

**Solution:**
```bash
# Validate manifests
kubectl apply --dry-run=client -k kubernetes/overlays/production

# Check syntax
kubectl apply --validate -k kubernetes/overlays/production

# Apply one at a time
kubectl apply -f kubernetes/base/namespace.yaml
kubectl apply -f kubernetes/base/configmap.yaml
# etc.
```

**Issue: Pods in CrashLoopBackOff**

**Solution:**
```bash
# Check pod logs
kubectl logs -l app=spacetime-vr --tail=100

# Describe pod for events
kubectl describe pod <pod-name>

# Check resource limits
kubectl get pod <pod-name> -o yaml | grep -A 5 resources

# Verify ConfigMap/Secret mounted
kubectl exec -it <pod-name> -- ls -la /config
```

---

## Best Practices

### Automation

1. **Use CI/CD**: Automate package builds on release tags
2. **Test in Staging**: Always test full deployment in staging
3. **Rollback Plan**: Test rollback procedure before production
4. **Documentation**: Keep packaging docs updated

### Security

1. **Sign Packages**: Always sign with GPG
2. **Scan Images**: Scan for vulnerabilities before release
3. **Rotate Secrets**: Rotate all secrets for each major release
4. **Audit Trail**: Maintain log of who built what and when

### Quality Assurance

1. **Smoke Tests**: Run on every build
2. **Integration Tests**: Full suite in staging
3. **Load Tests**: Validate performance targets
4. **Monitoring**: Verify observability before release

### Release Process

1. **Version Bump**: Update VERSION file first
2. **Changelog**: Update RELEASE_NOTES.md
3. **Build Package**: Run automated build
4. **Staging Deploy**: Deploy and test in staging
5. **Security Review**: Complete security checklist
6. **Production Deploy**: Follow DEPLOYMENT_CHECKLIST.md
7. **Monitor**: Watch metrics for 24 hours
8. **Post-Mortem**: Document lessons learned

---

## Reference

### Related Documentation

- **DEPLOYMENT_CHECKLIST.md** - 60+ item deployment checklist
- **RELEASE_NOTES.md** - What's new in each version
- **CI_CD_GUIDE.md** - Continuous integration setup
- **ROLLBACK_PROCEDURES.md** - Emergency rollback
- **SECURITY_GUIDE.md** - Security best practices

### Tools and Dependencies

- **Godot Engine**: https://godotengine.org/
- **Docker**: https://www.docker.com/
- **Kubernetes**: https://kubernetes.io/
- **Helm**: https://helm.sh/
- **Prometheus**: https://prometheus.io/
- **Grafana**: https://grafana.com/

### Support

For issues with packaging:
- **Documentation**: C:/godot/docs/
- **Issues**: Report to development team
- **Emergency**: See DEPLOYMENT_CHECKLIST.md

---

**Document Version**: 2.5.0
**Last Updated**: 2025-12-02
**Next Review**: 2025-12-09
