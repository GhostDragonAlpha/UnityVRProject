# SpaceTime VR - Release Engineering

This directory contains all tools, templates, and documentation for creating production-ready deployment packages.

## Quick Start

```bash
# Build a complete deployment package
./build_package.sh

# Output: spacetime-vr-v2.5.0/ directory and archives
```

## Contents

### Build System

- **`build_package.sh`** - Automated package builder (800+ lines)
  - Compiles Godot binaries
  - Builds Docker images
  - Packages all components
  - Generates documentation
  - Creates checksums and signatures
  - Produces distribution archives

### Templates

- **`package_template/`** - Complete package structure template
  - Binaries directory structure
  - Configuration templates
  - Deployment scripts
  - Kubernetes manifests
  - Monitoring configuration
  - Documentation templates
  - Test suites
  - Security artifacts

### Documentation

- **`DEPLOYMENT_CHECKLIST.md`** - 125+ item deployment checklist
  - Pre-deployment preparation (65 items)
  - Deployment execution (25 steps)
  - Post-deployment validation (35 checks)
  - Rollback procedures
  - Emergency contacts

- **`RELEASE_NOTES_v2.5.0.md`** - Comprehensive release notes
  - What's new (6 major features)
  - Breaking changes and migration guide
  - Known issues and workarounds
  - Testing summary
  - Security audit results

- **`PACKAGE_DELIVERY_SUMMARY.md`** - Delivery documentation
  - Complete deliverables list
  - Package structure details
  - Validation procedures
  - Usage instructions
  - Metrics and statistics

### Guides

- **`C:/godot/docs/release/PACKAGING_GUIDE.md`** - Complete packaging guide
  - Package structure overview
  - Building packages (automated and manual)
  - Validation and testing
  - Distribution methods
  - Security (signing, scanning)
  - Versioning strategy
  - Troubleshooting

## Building a Package

### Prerequisites

```bash
# Required tools
- godot (4.5.1+)
- docker (20.10+)
- kubectl (1.25+)
- helm (3.x)
- python3 (3.8+)
- sha256sum
- gpg (for signing)
```

### Configuration

```bash
# Set environment variables (optional)
export DOCKER_REGISTRY="ghcr.io/your-org"
export ARTIFACT_REPO="s3://spacetime-artifacts"
export GPG_KEY_ID="your-gpg-key-id"
```

### Build Process

```bash
# Update version
echo "2.5.0" > ../VERSION

# Run build
./build_package.sh

# Output
spacetime-vr-v2.5.0/           # Complete package directory
spacetime-vr-v2.5.0.tar.gz     # Linux/Unix archive
spacetime-vr-v2.5.0.zip        # Windows archive
```

### Verification

```bash
cd spacetime-vr-v2.5.0

# Verify checksums
sha256sum -c SHA256SUMS

# Verify GPG signature (if signed)
gpg --verify SHA256SUMS.asc SHA256SUMS

# Validate structure
ls -la binaries/ config/ scripts/ kubernetes/ monitoring/ docs/ tests/ security/
```

## Package Contents

### Binaries

- Godot server executable
- Docker image archive (multi-arch)
- GDScript source files
- Godot addons
- Scene files
- Version metadata

### Configuration

- Production environment templates
- Staging environment templates
- Development environment templates
- Service configuration (Prometheus, Nginx, etc.)

### Scripts

- **Deployment**: `deploy.sh`, `rollback.sh`, `setup_monitoring.sh`
- **Maintenance**: `backup.sh`, `restore.sh`, `health_check.sh`
- **Migration**: `migrate_database.sh`, migration SQL files

### Kubernetes

- Base manifests (namespace, deployment, service, ingress, etc.)
- Environment overlays (production, staging)
- Kustomization files
- Helm charts

### Monitoring

- Prometheus configuration and alert rules
- Grafana dashboards (HTTP API, Server Meshing, VR Performance)
- Alertmanager routing configuration

### Documentation

- Deployment guides
- Operations runbooks
- Security documentation
- API reference
- Troubleshooting guides

### Tests

- Smoke tests (10 critical tests, 5 minutes)
- Integration tests (50+ workflow tests)
- Performance tests (load testing, property tests)

### Security

- TLS certificate templates
- Security policies and standards
- Security audit reports
- Vulnerability scan results

## Deployment

### Quick Deployment

```bash
# Extract package
tar -xzf spacetime-vr-v2.5.0.tar.gz
cd spacetime-vr-v2.5.0

# Verify
sha256sum -c SHA256SUMS

# Configure
cp config/production/.env.template config/production/.env
# Edit .env with your values

# Deploy
./scripts/deployment/deploy.sh production

# Verify
./tests/smoke/smoke_test.sh
```

### Full Deployment Process

1. **Read checklist**: `DEPLOYMENT_CHECKLIST.md`
2. **Review release notes**: `RELEASE_NOTES_v2.5.0.md`
3. **Complete pre-deployment items**: 65 checklist items
4. **Execute deployment**: Follow 25-step process
5. **Validate deployment**: Complete 35 post-deployment checks
6. **Monitor for 24 hours**: Watch dashboards and logs

## Rollback

If issues occur:

```bash
# Execute rollback
./scripts/deployment/rollback.sh production

# Verify
./tests/smoke/smoke_test.sh

# Restore database (if needed)
./scripts/maintenance/restore.sh <backup-timestamp>
```

## Automation

### CI/CD Integration

```yaml
# Example GitHub Actions workflow
name: Build Release Package

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build package
        run: |
          cd release
          ./build_package.sh
      - name: Upload artifacts
        uses: actions/upload-artifact@v2
        with:
          name: deployment-package
          path: release/spacetime-vr-v*.tar.gz
```

### Scheduled Builds

```bash
# Cron job for nightly builds
0 2 * * * cd /path/to/godot/release && ./build_package.sh 2>&1 | tee build.log
```

## Directory Structure

```
release/
├── README.md                          # This file
├── build_package.sh                   # Automated package builder
├── DEPLOYMENT_CHECKLIST.md            # 125+ item deployment checklist
├── RELEASE_NOTES_v2.5.0.md            # Release notes
├── PACKAGE_DELIVERY_SUMMARY.md        # Delivery documentation
├── package_template/                  # Package structure template
│   ├── README.md
│   ├── MANIFEST.json
│   ├── binaries/
│   ├── config/
│   ├── scripts/
│   │   ├── deployment/
│   │   ├── maintenance/
│   │   └── migration/
│   ├── kubernetes/
│   ├── monitoring/
│   ├── docs/
│   ├── tests/
│   │   ├── smoke/
│   │   ├── integration/
│   │   └── performance/
│   └── security/
└── [generated packages]/              # Created by build_package.sh
```

## Best Practices

### Version Management

```bash
# Update VERSION file first
echo "2.5.1" > ../VERSION

# Tag in git
git tag -a v2.5.1 -m "Release v2.5.1"
git push --tags

# Build package
./build_package.sh
```

### Security

- Always verify checksums after download
- Verify GPG signatures if available
- Scan Docker images before deployment
- Rotate all secrets before production deployment
- Review security audit reports

### Testing

- Test in staging first (always!)
- Run full smoke test suite
- Validate performance benchmarks
- Test rollback procedure
- Document any issues found

### Documentation

- Update RELEASE_NOTES.md for each version
- Keep DEPLOYMENT_CHECKLIST.md current
- Document all breaking changes
- Provide migration guides
- Update troubleshooting docs

## Troubleshooting

### Build Issues

**Godot export fails:**
```bash
# Check Godot version
godot --version

# Verify export preset
cat ../export_presets.cfg

# Try with verbose output
godot --verbose --headless --export-release "Windows Desktop" output.exe
```

**Docker build fails:**
```bash
# Check Docker daemon
docker info

# Build with no cache
docker build --no-cache -t spacetime-vr:2.5.0 .

# Check Dockerfile syntax
docker build --dry-run .
```

### Package Issues

**Missing files:**
```bash
# Verify template structure
ls -la package_template/

# Check source directories
ls -la ../scripts/ ../addons/ ../kubernetes/
```

**Checksum mismatch:**
```bash
# Regenerate checksums
cd spacetime-vr-v2.5.0
rm SHA256SUMS
find . -type f ! -name "SHA256SUMS*" -exec sha256sum {} \; > SHA256SUMS
```

## Support

### Documentation

- **Packaging Guide**: `C:/godot/docs/release/PACKAGING_GUIDE.md`
- **Deployment Guide**: `C:/godot/docs/deployment/README.md`
- **Operations Runbook**: `C:/godot/docs/operations/RUNBOOK.md`

### Contact

- **DevOps Team**: devops@spacetime-vr.com
- **Security Team**: security@spacetime-vr.com
- **Emergency**: See DEPLOYMENT_CHECKLIST.md

### Resources

- **Project Docs**: https://docs.spacetime-vr.com
- **Status Page**: https://status.spacetime-vr.com
- **Support Portal**: https://support.spacetime-vr.com

## Metrics

### Package Statistics

- **Total Files**: 500+ files
- **Package Size**: ~1.2 GB (compressed)
- **Build Time**: ~15 minutes
- **Documentation**: 30,000+ words
- **Test Coverage**: 250+ unit tests, 50+ integration tests

### Performance Targets

- **VR FPS**: 90+ average, 85+ minimum
- **API Latency**: <50ms p95, <100ms p99
- **Deployment Time**: 5-10 minutes
- **Rollback Time**: <5 minutes

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.5.0 | 2025-12-02 | Initial production package system |
| 2.4.0 | 2025-11-15 | Previous release |
| 2.3.0 | 2025-11-01 | Previous release |

## License

See LICENSE file in project root.

---

**Ready to build?** Run `./build_package.sh` to get started!

**Questions?** Check `PACKAGING_GUIDE.md` or contact devops@spacetime-vr.com

---

**Last Updated**: 2025-12-02
**Maintained By**: DevOps Team
