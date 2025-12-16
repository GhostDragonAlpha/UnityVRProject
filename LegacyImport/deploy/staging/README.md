# Staging Environment Deployment

Complete pre-production staging environment that mirrors production infrastructure for confident testing.

## Quick Links

- **[Quick Start Guide](./QUICK_START.md)** - Get up and running in 5 minutes
- **[Full Documentation](../../docs/environments/STAGING_ENVIRONMENT.md)** - Complete staging environment guide
- **[Validation Suite](../../tests/staging/validate_staging.py)** - Automated validation tests

## Overview

The staging environment provides:

- **Production Mirror**: Identical infrastructure, configuration, and security
- **Isolated Testing**: Completely separate from production (namespace/cluster)
- **Full Observability**: Prometheus, Grafana, ELK stack, Jaeger tracing
- **Automated Deployment**: CI/CD integration with GitHub Actions
- **Realistic Data**: Test data generators for comprehensive testing
- **Validation Suite**: Automated health checks and SLA validation

## Architecture

```
Staging Environment
├── CockroachDB Cluster (3 nodes)
│   ├── Node 0: Primary
│   ├── Node 1: Replica
│   └── Node 2: Replica
├── Redis Cluster (3 nodes + Sentinel)
│   ├── Redis 0: Master
│   ├── Redis 1: Replica
│   ├── Redis 2: Replica
│   └── Sentinel: Automatic failover
├── Monitoring Stack
│   ├── Prometheus: Metrics collection
│   ├── Grafana: Visualization
│   ├── Elasticsearch: Log storage
│   ├── Logstash: Log processing
│   ├── Kibana: Log analysis
│   └── Jaeger: Distributed tracing
└── Game Servers (when deployed)
```

## Deployment Options

### Option 1: Docker Compose (Local Development)

**Best for:** Local testing, development, quick iterations

```bash
# Start environment
docker-compose up -d

# Load test data
python3 seed_data.py --environment staging

# Validate
python3 ../../tests/staging/validate_staging.py

# Access services at localhost
# - Grafana: http://localhost:3000
# - Prometheus: http://localhost:9090
# - CockroachDB UI: http://localhost:8080
```

**Resource Requirements:**
- CPU: 8 cores
- RAM: 32GB
- Disk: 200GB SSD

### Option 2: Kubernetes (Pre-Production)

**Best for:** Production-like testing, load testing, integration testing

```bash
# Deploy to cluster
./deploy_staging.sh kubernetes

# Access via port-forward or LoadBalancer
kubectl port-forward -n staging svc/grafana 3000:3000
kubectl port-forward -n staging svc/prometheus 9090:9090

# Load test data
python3 seed_data.py \
  --db-host cockroachdb-public.staging.svc.cluster.local \
  --redis-host redis-master.staging.svc.cluster.local
```

**Resource Requirements:**
- Nodes: 3-5 worker nodes
- CPU: 32 cores total
- RAM: 128GB total
- Disk: 500GB SSD per node

## Files in This Directory

```
deploy/staging/
├── README.md                          # This file
├── QUICK_START.md                     # 5-minute quick start guide
├── deploy_staging.sh                  # Main deployment script
├── seed_data.py                       # Test data generator
├── docker-compose.yml                 # Local docker compose setup
├── kubernetes/                        # Kubernetes manifests
│   ├── namespace.yaml                 # Namespace and resource limits
│   ├── cockroachdb.yaml              # CockroachDB cluster
│   ├── redis.yaml                    # Redis cluster with Sentinel
│   ├── monitoring.yaml               # Prometheus & Grafana
│   └── secrets.yaml                  # Secrets template (use sealed-secrets!)
└── monitoring/                        # Monitoring configuration
    ├── prometheus.yml                # Prometheus config
    ├── rules/                        # Alert rules
    │   └── staging-alerts.yml
    ├── grafana/                      # Grafana provisioning
    │   └── provisioning/
    │       ├── datasources/
    │       └── dashboards/
    └── logstash/                     # Logstash pipeline
        ├── config/
        └── pipeline/
```

## Quick Commands

### Start Environment

```bash
# Docker Compose
docker-compose up -d

# Kubernetes
./deploy_staging.sh kubernetes

# Dry run (preview changes)
DRY_RUN=true ./deploy_staging.sh kubernetes
```

### Check Status

```bash
# Docker Compose
docker-compose ps
docker-compose logs -f

# Kubernetes
kubectl get all -n staging
kubectl get pods -n staging -w
```

### Load Test Data

```bash
# Default (100 players, 500 sessions)
python3 seed_data.py --environment staging

# Custom amounts
python3 seed_data.py \
  --environment staging \
  --num-players 500 \
  --num-sessions 2000 \
  --num-security-events 100
```

### Run Validation

```bash
# Full validation suite
python3 ../../tests/staging/validate_staging.py

# Export results
python3 ../../tests/staging/validate_staging.py \
  --export validation_results.json
```

### Access Services

```bash
# Docker Compose (direct access)
open http://localhost:3000  # Grafana (admin/staging-admin)
open http://localhost:9090  # Prometheus
open http://localhost:8080  # CockroachDB UI
open http://localhost:5601  # Kibana
open http://localhost:16686 # Jaeger UI

# Kubernetes (port-forward)
kubectl port-forward -n staging svc/grafana 3000:3000 &
kubectl port-forward -n staging svc/prometheus 9090:9090 &
open http://localhost:3000
```

### Cleanup

```bash
# Docker Compose (keep data)
docker-compose down

# Docker Compose (remove all data)
docker-compose down -v

# Kubernetes
kubectl delete namespace staging
```

## Deployment Script Options

The `deploy_staging.sh` script supports various options:

```bash
# Basic usage
./deploy_staging.sh kubernetes              # Deploy to Kubernetes
./deploy_staging.sh docker-compose          # Deploy locally

# Environment variables
DRY_RUN=true ./deploy_staging.sh kubernetes    # Preview changes
SKIP_TESTS=true ./deploy_staging.sh kubernetes # Skip smoke tests
LOAD_SEED_DATA=false ./deploy_staging.sh kubernetes # Skip seed data

# Combined
DRY_RUN=true SKIP_TESTS=true ./deploy_staging.sh kubernetes
```

## CI/CD Integration

Automated deployment is configured via GitHub Actions:

**Triggers:**
- Push to `develop` branch → Auto-deploy to staging
- Pull request to `main` → Build and validate
- Manual workflow dispatch → Deploy on-demand

**Workflow:** `.github/workflows/staging-deploy.yml`

**Steps:**
1. Build and push Docker image
2. Deploy to Kubernetes
3. Run database migrations
4. Load seed data (optional)
5. Run smoke tests
6. Send notifications (Slack, email)
7. Create incident if failed

**Secrets Required:**
- `STAGING_KUBECONFIG`: Kubernetes config for staging cluster
- `STAGING_REDIS_PASSWORD`: Redis password
- `SLACK_WEBHOOK_URL`: Slack notifications

## Validation Tests

The validation suite checks:

1. ✅ **Database Connectivity** - CockroachDB cluster health (3 nodes)
2. ✅ **Redis Connectivity** - Redis cluster with Sentinel
3. ✅ **Monitoring Stack** - Prometheus and Grafana operational
4. ✅ **Performance SLAs** - DB latency < 100ms, Redis < 10ms
5. ✅ **Data Integrity** - Referential integrity, no orphaned records
6. ✅ **Security Configuration** - Proper isolation, authentication
7. ✅ **Backup Configuration** - Backup tools accessible
8. ✅ **Monitoring Alerts** - Alert rules configured

**Expected Result:** 8/8 tests passed (100% success rate)

## Test Data

The seed data generator creates realistic test data:

**Players (default 100):**
- Usernames, emails, VR headsets
- Levels 1-50, varying credits
- Realistic play time and preferences
- Test accounts for various scenarios

**Game Sessions (default 500):**
- 5 minutes to 4 hours duration
- FPS metrics (70-95 avg)
- Multiple locations
- Achievement tracking

**Security Events (default 50):**
- Login attempts (success/failure)
- Suspicious activity patterns
- Rate limiting events
- API abuse scenarios

**Performance Metrics (24 hours):**
- CPU and memory usage
- Active player counts
- FPS statistics
- Network latency

**Redis Cache Data:**
- Active sessions (20 players)
- Leaderboards (top 50)
- Rate limiting counters
- Player online status

## Monitoring and Alerting

### Dashboards

**Grafana Dashboards:**
- Staging Overview - Environment health at a glance
- Database Performance - CockroachDB metrics
- Redis Performance - Cache metrics
- Application Metrics - Game server stats
- System Resources - CPU, RAM, disk, network

### Alerts

**Critical Alerts:**
- Database node down
- Redis instance down
- Service unavailable

**Warning Alerts:**
- High CPU usage (>80% for 5 min)
- High memory usage (>90% for 5 min)
- Low FPS (<60 for 2 min)
- Disk space low (<10%)
- High database latency (>100ms)
- Redis rejected connections

### Log Analysis

**Elasticsearch/Kibana:**
- Index pattern: `logs-staging-*`
- Retention: 7 days
- Daily indices
- Full-text search enabled

**Example queries:**
```
level: ERROR
service: game-server AND level: WARNING
message: "connection refused"
timestamp: [now-1h TO now]
```

### Distributed Tracing

**Jaeger:**
- Trace all HTTP requests
- Database query tracing
- Redis operation tracing
- Cross-service call tracking

## Troubleshooting

### Common Issues

**1. Services not starting**
```bash
# Check logs
docker-compose logs <service>
kubectl logs -n staging <pod>

# Check resources
docker stats
kubectl top nodes
```

**2. Database connection failed**
```bash
# Verify CockroachDB ready
curl http://localhost:8080/health?ready=1

# Check cluster status
cockroach sql --insecure --host=localhost:26257 --execute="SELECT node_id, address, is_live FROM crdb_internal.gossip_liveness"
```

**3. Redis connection failed**
```bash
# Test connection
redis-cli -h localhost -p 6379 -a staging-redis-password ping

# Check Sentinel
redis-cli -p 26379 SENTINEL masters
```

**4. Validation tests failing**
```bash
# Re-run with verbose output
python3 ../../tests/staging/validate_staging.py --export debug.json

# Check individual services
curl http://localhost:9090/-/healthy  # Prometheus
curl http://localhost:3000/api/health # Grafana
curl http://localhost:8080/health     # CockroachDB
```

### Getting Help

**Diagnostic commands:**
```bash
# Full deployment log
./deploy_staging.sh kubernetes 2>&1 | tee deployment.log

# Validation with export
python3 ../../tests/staging/validate_staging.py --export diagnostics.json

# Service status
kubectl get all -n staging
docker-compose ps
```

**Support:**
- Engineering: engineering@example.com
- DevOps: devops@example.com
- Documentation: `docs/environments/STAGING_ENVIRONMENT.md`

## Best Practices

### DO

✅ Test all changes in staging before production
✅ Run validation suite after every deployment
✅ Keep staging synchronized with production config
✅ Refresh test data regularly (weekly)
✅ Monitor performance during load tests
✅ Test disaster recovery procedures
✅ Use separate credentials from production

### DON'T

❌ Use production credentials or secrets
❌ Deploy untested changes to production
❌ Skip validation steps
❌ Use real user data (PII concerns)
❌ Mix staging and production data
❌ Allow direct public internet access
❌ Ignore resource limits

## Maintenance

### Daily
- Monitor resource usage
- Review error logs
- Check alert status

### Weekly
- Run validation suite
- Review performance metrics
- Update test data

### Monthly
- Update Docker images
- Review and update seed data
- Disaster recovery drill
- Review resource allocation

## Related Documentation

- **[Full Documentation](../../docs/environments/STAGING_ENVIRONMENT.md)** - Complete guide
- **[Production Environment](../../docs/environments/PRODUCTION_ENVIRONMENT.md)** - Production setup
- **[Deployment Guide](../../docs/operations/DEPLOYMENT.md)** - General deployment
- **[Monitoring Guide](../../docs/operations/MONITORING.md)** - Monitoring setup
- **[Security Policies](../../docs/security/SECURITY_POLICIES.md)** - Security guidelines

## Support

**Questions or issues?**
- Read the [full documentation](../../docs/environments/STAGING_ENVIRONMENT.md)
- Check the [troubleshooting section](#troubleshooting)
- Run diagnostics: `python3 ../../tests/staging/validate_staging.py`
- Contact DevOps: devops@example.com

---

**Last Updated:** 2024-12-02
**Version:** 1.0.0
**Maintained By:** DevOps Team
