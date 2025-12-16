# SpaceTime VR - Deployment Checklist

Quick reference checklist for deploying SpaceTime VR to production.

## Pre-Deployment Checklist

### Code Quality
- [ ] All tests passing (57+ HTTP API tests)
- [ ] Security tests passing (68 security checks)
- [ ] Property-based tests passing
- [ ] Integration tests passing
- [ ] Code review completed
- [ ] No unresolved merge conflicts
- [ ] Branch up to date with main

### Security
- [ ] Security scan completed (no critical issues)
- [ ] Dependencies updated to latest secure versions
- [ ] No secrets in code (`git grep -i "password\|secret\|key"`)
- [ ] `.env` files not committed
- [ ] TLS certificates valid and not expiring
- [ ] API tokens rotated if needed
- [ ] Database credentials secure

### Configuration
- [ ] `.env.production` file configured
- [ ] Database connection verified
- [ ] Redis connection verified
- [ ] External services configured
- [ ] DNS records updated
- [ ] Load balancer configured
- [ ] Monitoring configured

### Infrastructure
- [ ] Servers provisioned and accessible
- [ ] Docker installed and running
- [ ] Required ports open (8080, 8081, 6006, 6005, 9090, 3000)
- [ ] Sufficient disk space (100GB+ available)
- [ ] Sufficient memory (16GB+ available)
- [ ] Backup system configured

### Documentation
- [ ] Deployment plan reviewed
- [ ] Rollback plan reviewed
- [ ] Runbook updated
- [ ] Team notified of deployment
- [ ] Maintenance window scheduled (if applicable)

## Deployment Steps

### 1. Prepare Deployment

```bash
# Set environment variables
export ENVIRONMENT=production
export IMAGE_TAG=v2.5.0
export DEPLOYMENT_ID=$(date +%Y%m%d-%H%M%S)

# Navigate to deployment directory
cd C:/godot/deploy

# Verify scripts are executable
ls -lah *.sh
```

- [ ] Environment variables set
- [ ] Working directory correct
- [ ] Scripts executable

### 2. Run Pre-Flight Checks

```bash
# Check prerequisites
bash deploy.sh --check

# Run health check on current system
bash health_check.sh --url https://spacetime.example.com --verbose

# Run security validation
bash security_validation.sh --url https://spacetime.example.com
```

- [ ] Prerequisites check passed
- [ ] Current system healthy
- [ ] Security validation passed

### 3. Create Backup

```bash
# Automatic backup created by deploy.sh
# Or create manual backup:
mkdir -p ../backups/${DEPLOYMENT_ID}
docker-compose ps > ../backups/${DEPLOYMENT_ID}/containers.txt
docker-compose config > ../backups/${DEPLOYMENT_ID}/docker-compose.yml
docker-compose logs --tail=1000 > ../backups/${DEPLOYMENT_ID}/logs.txt
```

- [ ] Backup created
- [ ] Backup verified
- [ ] Backup location noted

### 4. Deploy New Version

#### Option A: Manual Deployment

```bash
# Run deployment script
bash deploy.sh

# Script will:
# - Check prerequisites ✓
# - Create backup ✓
# - Pull new image ✓
# - Stop old containers ✓
# - Start new containers ✓
# - Run health checks ✓
# - Run smoke tests ✓
```

- [ ] Deployment script executed
- [ ] All steps completed successfully
- [ ] No errors in output

#### Option B: Blue-Green Deployment

```bash
# Deploy to green environment
DEPLOYMENT_COLOR=green IMAGE_TAG=v2.5.0 \
  docker-compose -f docker-compose.blue-green.yml up -d godot-green

# Validate green environment
bash health_check.sh --url http://godot-green:8080

# Switch traffic to green
bash blue-green-switch.sh green
```

- [ ] Green environment deployed
- [ ] Green environment validated
- [ ] Traffic switched to green

#### Option C: GitHub Actions

```bash
# Trigger deployment workflow
gh workflow run deploy.yml \
  -f environment=production \
  -f image_tag=v2.5.0

# Approve deployment (if required)
# Visit: https://github.com/your-org/your-repo/actions

# Monitor deployment
gh run watch
```

- [ ] Workflow triggered
- [ ] Approval granted (if required)
- [ ] Workflow completed successfully

### 5. Verify Deployment

```bash
# Check container status
docker-compose ps

# Run health checks
bash health_check.sh --url https://spacetime.example.com --verbose

# Run security validation
bash security_validation.sh --url https://spacetime.example.com

# Run smoke tests
bash smoke_tests.sh
```

- [ ] All containers running
- [ ] All containers healthy
- [ ] Health checks passed
- [ ] Security validation passed
- [ ] Smoke tests passed

### 6. Post-Deployment Monitoring

```bash
# Monitor logs
docker-compose logs -f

# Check metrics
curl https://spacetime.example.com/metrics

# Check Prometheus
open https://spacetime.example.com:9090

# Check Grafana
open https://spacetime.example.com/grafana
```

Monitor for:
- [ ] No error spikes in logs
- [ ] Response times normal (<500ms)
- [ ] Memory usage normal (<80%)
- [ ] CPU usage normal (<70%)
- [ ] No failed requests
- [ ] All subsystems initialized

### 7. Validate Functionality

```bash
# Test critical endpoints
curl https://spacetime.example.com/status
curl https://spacetime.example.com/health
curl -H "Authorization: Bearer $API_TOKEN" \
  https://spacetime.example.com/api/scene/list
```

Test:
- [ ] Status endpoint working
- [ ] Health endpoint working
- [ ] Authentication working
- [ ] API endpoints responding
- [ ] Telemetry stream working
- [ ] VR initialization working

## Post-Deployment Checklist

### Immediate (0-30 minutes)

- [ ] All health checks passing
- [ ] No errors in logs
- [ ] All containers healthy
- [ ] Monitoring dashboards green
- [ ] Critical functionality tested
- [ ] Response times acceptable
- [ ] Memory usage stable
- [ ] CPU usage stable

### Short-term (30 minutes - 2 hours)

- [ ] No error rate increase
- [ ] No performance degradation
- [ ] User reports positive (if applicable)
- [ ] Background jobs running
- [ ] Database queries performing well
- [ ] Cache hit rate normal
- [ ] No security alerts

### Medium-term (2-24 hours)

- [ ] System stable overnight
- [ ] No memory leaks detected
- [ ] No disk space issues
- [ ] Backups running successfully
- [ ] Monitoring data looks normal
- [ ] No unusual traffic patterns
- [ ] Security logs normal

## Rollback Checklist

If issues detected, follow rollback procedure:

### Quick Rollback

```bash
# Immediate rollback to previous version
cd C:/godot/deploy
bash rollback.sh --quick

# Verify rollback
bash health_check.sh --url https://spacetime.example.com
```

- [ ] Rollback script executed
- [ ] Previous version restored
- [ ] Health checks passing
- [ ] System stable

### Blue-Green Rollback

```bash
# Instant traffic switch back to blue
bash blue-green-switch.sh blue

# Verify
bash blue-green-switch.sh status
```

- [ ] Traffic switched back
- [ ] Blue environment active
- [ ] System stable

### Kubernetes Rollback

```bash
# Rollback to previous revision
kubectl rollout undo deployment/spacetime-godot -n spacetime

# Verify
kubectl rollout status deployment/spacetime-godot -n spacetime
```

- [ ] Rollout undone
- [ ] Pods restarted
- [ ] System stable

### Post-Rollback

- [ ] Incident documented
- [ ] Root cause identified
- [ ] Fix planned
- [ ] Team notified
- [ ] Postmortem scheduled

## Communication Checklist

### Before Deployment

- [ ] Team notified of deployment
- [ ] Stakeholders informed
- [ ] Maintenance window scheduled (if needed)
- [ ] Rollback plan communicated

### During Deployment

- [ ] Status updates provided
- [ ] Issues escalated if needed
- [ ] Progress tracked

### After Deployment

- [ ] Success announced
- [ ] Known issues communicated
- [ ] Documentation updated
- [ ] Lessons learned captured

## Emergency Procedures

### Critical Issues Detected

1. **Immediate Actions**:
   - [ ] Stop deployment
   - [ ] Assess severity
   - [ ] Initiate rollback if needed
   - [ ] Notify team

2. **Escalation**:
   - [ ] Contact on-call engineer
   - [ ] Create incident ticket
   - [ ] Start war room if critical
   - [ ] Document timeline

3. **Resolution**:
   - [ ] Issue resolved or mitigated
   - [ ] System stable
   - [ ] Postmortem scheduled
   - [ ] Preventive measures identified

### Contact Information

- **On-Call Engineer**: [Contact Info]
- **DevOps Team**: [Contact Info]
- **Security Team**: [Contact Info]
- **Escalation Path**: [Escalation Procedure]

## Useful Commands

### Quick Status Check

```bash
# One-liner to check everything
docker-compose ps && \
  curl -sf https://spacetime.example.com/status | jq '.overall_ready' && \
  docker-compose logs --tail=20 | grep -i error | wc -l
```

### Quick Rollback

```bash
# Emergency rollback
cd C:/godot/deploy && bash rollback.sh --quick
```

### View Deployment History

```bash
# List recent deployments
ls -lt ../deployments/*.json | head -5

# View deployment details
cat ../deployments/$(ls -t ../deployments | head -1)
```

### Monitor Live Logs

```bash
# Follow logs with error highlighting
docker-compose logs -f | grep --color=always -i "error\|warning\|critical"
```

## Success Criteria

Deployment is successful when:

- ✅ All health checks passing
- ✅ All security validations passing
- ✅ Zero errors in logs (or only expected warnings)
- ✅ Response times <500ms
- ✅ Memory usage <80%
- ✅ CPU usage <70%
- ✅ All critical features functional
- ✅ Monitoring dashboards green
- ✅ No rollback required
- ✅ System stable for 2+ hours

## Failure Criteria

Rollback required if:

- ❌ Health checks failing
- ❌ High error rate (>1% of requests)
- ❌ Severe performance degradation (>2x response time)
- ❌ Memory/CPU exhaustion
- ❌ Data corruption detected
- ❌ Security vulnerability exposed
- ❌ Critical features broken
- ❌ System unstable after 30 minutes

## Documentation

### Update After Deployment

- [ ] `CHANGELOG.md` updated
- [ ] `VERSION` file updated
- [ ] Deployment notes added
- [ ] Known issues documented
- [ ] Runbook updated if needed

### Files to Reference

- **Deployment Guide**: `docs/deployment/DEPLOYMENT_GUIDE.md`
- **CI/CD Guide**: `CI_CD_GUIDE.md`
- **Monitoring Guide**: `MONITORING.md`
- **Security Guide**: `docs/security/SECURITY.md`
- **Troubleshooting**: `docs/deployment/DEPLOYMENT_GUIDE.md#troubleshooting`

## Notes

- Always test in staging before production
- Keep rollback plan ready
- Monitor closely for first 2 hours
- Document any issues encountered
- Update checklist based on lessons learned

---

**Version**: 2.5.0
**Last Updated**: 2025-12-02
**Next Review**: After each production deployment
