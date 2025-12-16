# SpaceTime VR - Production Deployment Package

**Version:** 2.5.0
**Build Date:** 2025-12-02

## Quick Start

1. **Extract Package**:
   ```bash
   tar -xzf spacetime-vr-v2.5.0.tar.gz
   cd spacetime-vr-v2.5.0
   ```

2. **Verify Integrity**:
   ```bash
   sha256sum -c SHA256SUMS
   ```

3. **Read Documentation**:
   ```bash
   cat DEPLOYMENT_CHECKLIST.md
   cat RELEASE_NOTES.md
   ```

4. **Configure Environment**:
   ```bash
   cp config/production/.env.template config/production/.env
   # Edit .env file with your configuration
   ```

5. **Deploy**:
   ```bash
   ./scripts/deployment/deploy.sh production
   ```

## Package Contents

### Binaries (`binaries/`)
- `spacetime-server.exe` - Godot game server
- `spacetime-vr-2.5.0.tar.gz` - Docker image
- `scripts/` - GDScript source files
- `addons/` - Godot plugins

### Configuration (`config/`)
- Environment-specific templates
- Service configuration files
- Security settings

### Kubernetes (`kubernetes/`)
- Base manifests
- Environment overlays (production/staging)
- Kustomization files
- Helm charts

### Monitoring (`monitoring/`)
- Prometheus configuration
- Grafana dashboards
- Alertmanager rules

### Scripts (`scripts/`)
- Deployment automation
- Maintenance scripts
- Database migrations

### Documentation (`docs/`)
- Deployment guides
- Operations runbooks
- Security documentation
- API reference

### Tests (`tests/`)
- Smoke tests
- Integration tests
- Performance tests

### Security (`security/`)
- Security policies
- Certificate templates
- Audit reports

## Requirements

### Minimum Requirements

- **Kubernetes**: 1.25+
- **PostgreSQL**: 15+
- **Redis**: 7+
- **CPU**: 32 cores
- **Memory**: 128 GB
- **Storage**: 500 GB (persistent)

### Software Dependencies

- `kubectl` - Kubernetes CLI
- `docker` - Container runtime
- `helm` - Kubernetes package manager
- `psql` - PostgreSQL client
- `curl` - HTTP client

## Pre-Deployment Checklist

Before deploying, complete these critical items:

- [ ] Read `DEPLOYMENT_CHECKLIST.md` (60+ items)
- [ ] Review `RELEASE_NOTES.md` for breaking changes
- [ ] Configure all environment variables
- [ ] Set up database (PostgreSQL 15+)
- [ ] Set up cache (Redis 7+)
- [ ] Configure TLS certificates
- [ ] Set up monitoring (Prometheus/Grafana)
- [ ] Test in staging environment
- [ ] Create database backup
- [ ] Notify users of maintenance window

## Deployment Process

### 1. Pre-Deployment

```bash
# Backup current system
./scripts/maintenance/backup.sh

# Verify backup
ls -lh /backup/latest/
```

### 2. Database Migration

```bash
# Run migrations
./scripts/migration/migrate_database.sh

# Verify migrations
psql $DATABASE_URL -c "SELECT * FROM schema_migrations;"
```

### 3. Deploy Application

```bash
# Deploy to production
./scripts/deployment/deploy.sh production

# Monitor deployment
kubectl rollout status deployment/spacetime-vr -n spacetime-vr-production
```

### 4. Run Smoke Tests

```bash
# Automated smoke tests
./tests/smoke/smoke_test.sh

# Manual verification
curl https://spacetime-vr.com/health
```

### 5. Monitor

```bash
# Check Grafana dashboards
open http://grafana:3000/d/http-api-overview

# Check Prometheus metrics
open http://prometheus:9090/graph
```

## Rollback Procedure

If issues occur:

```bash
# Execute rollback
./scripts/deployment/rollback.sh production

# Verify rollback success
./tests/smoke/smoke_test.sh
```

## Support

### Documentation

- **Deployment Guide**: `docs/deployment/README.md`
- **Operations Runbook**: `docs/operations/RUNBOOK.md`
- **Security Guide**: `docs/security/SECURITY_GUIDE.md`
- **Troubleshooting**: `docs/TROUBLESHOOTING.md`

### Contact

- **Technical Support**: support@spacetime-vr.com
- **Security Issues**: security@spacetime-vr.com
- **Emergency**: See `DEPLOYMENT_CHECKLIST.md`

## Version Information

- **Version**: 2.5.0
- **Release Date**: 2025-12-02
- **Build**: Production Release
- **Godot**: 4.5.1
- **API Version**: 2.5

## License

See LICENSE file for details.

---

**Ready to deploy?** Follow `DEPLOYMENT_CHECKLIST.md` step by step.
