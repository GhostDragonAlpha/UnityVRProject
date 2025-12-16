# CI/CD Pipeline Guide

Complete guide to the SpaceTime VR CI/CD pipeline for automated testing, security scanning, building, and deployment.

## Table of Contents

- [Overview](#overview)
- [Pipeline Architecture](#pipeline-architecture)
- [GitHub Actions Workflows](#github-actions-workflows)
- [Running Tests Locally](#running-tests-locally)
- [Deployment Process](#deployment-process)
- [Rollback Procedures](#rollback-procedures)
- [Monitoring and Alerts](#monitoring-and-alerts)
- [Troubleshooting](#troubleshooting)

## Overview

The CI/CD pipeline automates:

- **Testing**: 57+ HTTP API tests, 68 security tests, property-based tests
- **Security**: SAST, dependency scanning, secret detection, container scanning
- **Building**: Multi-platform Docker images with security scanning
- **Deployment**: Blue-green deployments with automated rollback
- **Monitoring**: Health checks and performance monitoring

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Code Push/PR                            │
└──────────────────┬──────────────────────────────────────────┘
                   │
    ┌──────────────┴──────────────┐
    │     Quick Validation         │
    │  - Linting                   │
    │  - YAML validation           │
    │  - Secret scanning           │
    └──────────────┬──────────────┘
                   │
    ┌──────────────┴──────────────────────────────────┐
    │                                                  │
┌───┴────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│HTTP API│  │ Security │  │Property  │  │Integration│
│Tests   │  │ Tests    │  │Tests     │  │Tests     │
│(57+)   │  │ (68)     │  │          │  │          │
└───┬────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘
    │            │             │             │
    └────────────┴─────────────┴─────────────┘
                   │
        ┌──────────┴──────────┐
        │  Security Scanning   │
        │  - SAST (Semgrep)    │
        │  - Dependencies      │
        │  - Secrets           │
        │  - Docker scan       │
        └──────────┬───────────┘
                   │
        ┌──────────┴──────────┐
        │   Build & Push       │
        │   Docker Image       │
        └──────────┬───────────┘
                   │
        ┌──────────┴──────────┐
        │  Deploy to Staging   │
        │  - Smoke tests       │
        │  - Health checks     │
        └──────────┬───────────┘
                   │
        ┌──────────┴──────────┐
        │ Manual Approval      │
        └──────────┬───────────┘
                   │
        ┌──────────┴──────────┐
        │ Deploy to Production │
        │ - Blue-green         │
        │ - Automated rollback │
        └──────────────────────┘
```

## GitHub Actions Workflows

### 1. Test Suite (`test.yml`)

**Triggers:**
- Push to `main`, `develop`, `feature/*`, `release/*`
- Pull requests to `main`, `develop`
- Daily at 2 AM UTC
- Manual trigger

**Jobs:**
1. **quick-check**: Fast validation (linting, YAML, secrets)
2. **http-api-tests**: 57+ HTTP API endpoint tests with coverage
3. **security-tests**: 68 security tests
4. **property-tests**: Property-based tests with Hypothesis
5. **integration-tests**: Multi-endpoint workflow tests
6. **test-summary**: Aggregate results and post to PR

**Coverage Requirements:**
- Minimum: 80% (configurable)
- Fails if coverage below threshold

**Running Manually:**
```bash
gh workflow run test.yml -f coverage_threshold=85
```

### 2. Security Scanning (`security-scan.yml`)

**Triggers:**
- Push to `main`, `develop`
- Pull requests to `main`
- Daily at 3 AM UTC
- Manual trigger

**Jobs:**
1. **sast-scan**: Semgrep static analysis
2. **dependency-scan**: pip-audit and Safety checks
3. **secret-scan**: TruffleHog and Gitleaks
4. **docker-scan**: Trivy container scanning
5. **code-quality**: Bandit, Pylint, Radon complexity
6. **security-summary**: Aggregate all security reports

**Running Manually:**
```bash
gh workflow run security-scan.yml
```

### 3. Build and Publish (`build.yml`)

**Triggers:**
- Push to `main`, `develop`, `release/*`
- Tags matching `v*.*.*`
- Pull requests to `main`
- Manual trigger

**Jobs:**
1. **build-image**: Multi-platform Docker build (amd64, arm64)
2. **scan-image**: Trivy, Grype, SBOM generation
3. **test-image**: Smoke tests on built image
4. **publish-release**: Create GitHub release (on tags)
5. **build-summary**: Aggregate build results

**Running Manually:**
```bash
gh workflow run build.yml -f push_to_registry=true
```

**Image Tags:**
- `latest` - Latest main branch
- `main-<sha>` - Specific commit
- `v2.5.0` - Version tags
- `<branch>-<sha>` - Branch builds

### 4. Deploy to Staging (`deploy-staging.yml`)

**Triggers:**
- Push to `main`, `develop`
- Manual trigger

**Jobs:**
1. **deploy-staging**: Deploy with health checks
2. **post-deployment-monitor**: 5-minute health monitoring

**Environment:** `staging`

**Automatic Rollback:** On failure, reverts to previous backup

**Running Manually:**
```bash
gh workflow run deploy-staging.yml -f image_tag=v2.5.0
```

### 5. Deploy to Production (`deploy-production.yml`)

**Triggers:**
- Manual only (workflow_dispatch)

**Jobs:**
1. **pre-deployment-validation**: Image and security checks
2. **approval**: Manual approval required (unless skipped)
3. **deploy-production**: Blue-green deployment
4. **post-deployment-health**: Extended health checks (10 min)
5. **deployment-summary**: Final status report

**Environment:** `production`

**Strategy:** Blue-Green Deployment
- New version deployed alongside old version
- Traffic switched after validation
- Old version shut down on success
- Automatic rollback on failure

**Running Manually:**
```bash
# With approval
gh workflow run deploy-production.yml -f image_tag=v2.5.0

# Skip approval (emergency only)
gh workflow run deploy-production.yml -f image_tag=v2.5.0 -f skip_approval=true
```

## Running Tests Locally

### Prerequisites

```bash
# Install Python dependencies
pip install -r tests/requirements.txt
pip install -r tests/http_api/requirements.txt
pip install -r tests/property/requirements.txt

# Install pre-commit hooks
pip install pre-commit
pre-commit install
```

### Run All Tests

```bash
# Comprehensive test suite
python tests/test_runner.py

# With coverage report
python tests/test_runner.py --coverage

# Quick tests only
python tests/test_runner.py --quick
```

### Run Specific Test Suites

```bash
# HTTP API tests
cd tests/http_api
pytest -v

# Security tests
cd tests/http_api
pytest test_security.py test_security_penetration.py -v

# Property-based tests
cd tests/property
pytest -v

# Integration tests
cd tests/http_api
pytest test_integration_workflows.py -v
```

### Run with Coverage

```bash
cd tests/http_api
pytest --cov=. --cov-report=html --cov-report=term
```

Open `htmlcov/index.html` to view detailed coverage report.

### Pre-commit Checks

```bash
# Run all pre-commit hooks
pre-commit run --all-files

# Run specific hook
pre-commit run black --all-files
pre-commit run flake8 --all-files
```

## Deployment Process

### Staging Deployment

**Automatic:** Triggered on push to `main` or `develop`

**Manual:**
```bash
# Deploy specific image
gh workflow run deploy-staging.yml -f image_tag=main-abc1234

# Monitor deployment
gh run watch

# Check deployment status
curl https://staging.spacetime.example.com/status
```

### Production Deployment

**Manual only** - requires approval

**Process:**

1. **Prepare:**
   ```bash
   # Verify staging is healthy
   curl https://staging.spacetime.example.com/status

   # Check security scan results
   gh run list --workflow=security-scan.yml

   # Review test results
   gh run list --workflow=test.yml
   ```

2. **Initiate Deployment:**
   ```bash
   gh workflow run deploy-production.yml -f image_tag=v2.5.0
   ```

3. **Approve:**
   - Go to Actions tab in GitHub
   - Find the deployment workflow run
   - Click "Review deployments"
   - Approve "production-approval"

4. **Monitor:**
   ```bash
   # Watch deployment progress
   gh run watch

   # Check logs
   gh run view --log

   # Verify production
   curl https://spacetime.example.com/status
   ```

5. **Validate:**
   ```bash
   # Run smoke tests
   cd deploy
   TEST_URL=https://spacetime.example.com bash smoke_tests.sh

   # Check Grafana dashboards
   open https://spacetime.example.com/grafana
   ```

### Blue-Green Deployment Details

Production deployments use blue-green strategy:

1. **Blue Environment**: Current production (serving traffic)
2. **Green Environment**: New version (being deployed)
3. **Validation**: Green is validated while Blue serves traffic
4. **Cutover**: Traffic switched to Green instantly
5. **Monitoring**: Green monitored for issues
6. **Cleanup**: Blue shut down after successful validation

**Benefits:**
- Zero downtime
- Instant rollback capability
- Safe validation under production conditions

## Rollback Procedures

### Automatic Rollback

Deployments automatically rollback if:
- Health checks fail
- Smoke tests fail
- Container fails to start
- High error rate detected

### Manual Rollback

#### Quick Rollback (Latest)

```bash
# SSH to production server
ssh production-server

# Run quick rollback
cd /opt/spacetime/production
bash deploy/rollback.sh --quick
```

#### Rollback to Specific Version

```bash
# List available backups
bash deploy/rollback.sh --list

# Rollback to specific backup
bash deploy/rollback.sh 20251202-143022
```

#### Rollback via GitHub Actions

```bash
# Trigger rollback workflow (if implemented)
gh workflow run rollback.yml -f deployment_id=20251202-143022
```

#### Manual Container Rollback

```bash
# Stop current containers
docker-compose down

# Start with previous image tag
export IMAGE_TAG=v2.4.9
docker-compose up -d

# Verify health
docker-compose ps
docker-compose logs -f
```

### Rollback Validation

After rollback:

```bash
# Check service health
docker-compose ps

# Run smoke tests
bash deploy/smoke_tests.sh

# Monitor metrics
curl http://localhost:9090/api/v1/query?query=up{job="godot"}

# Check logs for errors
docker-compose logs --tail=100 | grep -i error
```

## Monitoring and Alerts

### Prometheus Metrics

**Access:** `http://spacetime.example.com:9090`

**Key Metrics:**
```promql
# Request rate
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# Response time (p95)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Service uptime
up{job="godot"}

# Memory usage
container_memory_usage_bytes / container_spec_memory_limit_bytes
```

### Grafana Dashboards

**Access:** `https://spacetime.example.com/grafana`

**Dashboards:**
1. **Overview**: System health, request rates, errors
2. **Performance**: Response times, throughput, latency
3. **Resources**: CPU, memory, disk usage
4. **Security**: Failed auth attempts, suspicious activity

### Health Checks

**Automated:**
```bash
# Run health monitor
python tests/health_monitor.py --host spacetime.example.com

# Continuous monitoring
python tests/health_monitor.py --host spacetime.example.com --continuous
```

**Manual:**
```bash
# Check status endpoint
curl https://spacetime.example.com/status | jq

# Check container health
docker ps --filter "health=unhealthy"

# Check logs
docker-compose logs --tail=100 --follow
```

### Alert Configuration

**GitHub Issues:** Critical failures create GitHub issues automatically

**Email Alerts:** Configure in `.env.production`:
```bash
ALERT_EMAIL=ops@example.com
```

**Slack Alerts:** Configure webhook:
```bash
ALERT_SLACK_WEBHOOK=https://hooks.slack.com/services/...
```

## Troubleshooting

### Tests Failing in CI

**Problem:** Tests pass locally but fail in CI

**Solutions:**
1. Check Godot is running:
   ```bash
   curl http://127.0.0.1:8080/status
   ```

2. Verify debug ports:
   ```bash
   netstat -an | grep 6006  # DAP
   netstat -an | grep 6005  # LSP
   ```

3. Check Godot logs:
   ```bash
   # In CI job logs, search for Godot output
   ```

4. Increase wait times:
   - Edit workflow to increase sleep times after starting Godot

### Coverage Below Threshold

**Problem:** Coverage is 78%, threshold is 80%

**Solutions:**
1. Add tests for uncovered code
2. Remove dead code
3. Temporarily lower threshold (not recommended):
   ```bash
   gh workflow run test.yml -f coverage_threshold=75
   ```

### Docker Build Failing

**Problem:** Docker build fails in CI

**Solutions:**
1. Check Dockerfile syntax:
   ```bash
   docker build -f Dockerfile.v2.5 -t test .
   ```

2. Verify base image exists:
   ```bash
   docker pull ubuntu:20.04
   ```

3. Check build context size:
   ```bash
   # Add .dockerignore to exclude large files
   ```

### Deployment Stuck

**Problem:** Deployment waiting for health checks

**Solutions:**
1. Check container logs:
   ```bash
   ssh production-server
   docker-compose logs --tail=100
   ```

2. Verify ports are accessible:
   ```bash
   curl http://localhost:8080/status
   ```

3. Check resource limits:
   ```bash
   docker stats
   ```

4. Manual intervention:
   ```bash
   # Cancel workflow
   gh run cancel <run-id>

   # Rollback
   bash deploy/rollback.sh --quick
   ```

### Security Scan Failures

**Problem:** Security scan finds vulnerabilities

**Solutions:**
1. Review SARIF report in GitHub Security tab
2. Update dependencies:
   ```bash
   pip install --upgrade <package>
   ```
3. For false positives, add to exclusion list
4. For critical issues, create security advisory

### Rollback Not Working

**Problem:** Rollback script fails

**Solutions:**
1. Check backup exists:
   ```bash
   ls -la /opt/spacetime/backups/
   ```

2. Verify Docker images:
   ```bash
   docker images | grep spacetime
   ```

3. Manual restore:
   ```bash
   # Use specific image tag
   export IMAGE_TAG=v2.4.9
   docker-compose up -d
   ```

### Pre-commit Hooks Slow

**Problem:** Pre-commit hooks take too long

**Solutions:**
1. Skip specific hooks:
   ```bash
   SKIP=mypy git commit -m "message"
   ```

2. Run tests in background:
   ```bash
   SKIP=pytest-quick git commit -m "message"
   ```

3. Update `.pre-commit-config.yaml` to exclude slow hooks from commit stage

## Best Practices

### Development Workflow

1. **Create feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Run tests locally**
   ```bash
   python tests/test_runner.py
   ```

3. **Run pre-commit checks**
   ```bash
   pre-commit run --all-files
   ```

4. **Commit with conventional commits**
   ```bash
   git commit -m "feat: add new endpoint"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/my-feature
   gh pr create
   ```

6. **Monitor CI results**
   - Check test results
   - Review security scan
   - Fix any failures

7. **Merge after approval**
   - Squash or rebase
   - Delete feature branch

### Deployment Best Practices

1. **Always deploy to staging first**
2. **Monitor staging for 24 hours**
3. **Run manual validation tests**
4. **Deploy production during low-traffic hours**
5. **Have rollback plan ready**
6. **Monitor closely for 2 hours post-deployment**
7. **Document any issues in deployment log**

### Versioning

Follow semantic versioning:
- **Major** (2.x.x): Breaking changes
- **Minor** (x.5.x): New features, backward compatible
- **Patch** (x.x.1): Bug fixes

Update `VERSION` file before release:
```bash
echo "2.5.1" > VERSION
git add VERSION
git commit -m "chore: bump version to 2.5.1"
git tag v2.5.1
git push --tags
```

## Additional Resources

- [HTTP API Documentation](addons/godot_debug_connection/HTTP_API.md)
- [Security Documentation](SECURITY.md)
- [Contributing Guide](CONTRIBUTING.md)
- [Architecture Overview](CLAUDE.md#architecture)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
