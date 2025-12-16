# Planetary Survival - Kubernetes Deployment

Complete production-ready deployment infrastructure for Planetary Survival VR multiplayer game with server meshing architecture.

## Quick Start

```bash
# 1. Configure kubectl
kubectl config use-context your-cluster

# 2. Deploy to development
./scripts/deploy.sh dev

# 3. Deploy to production
./scripts/deploy.sh production

# 4. Verify deployment
./scripts/health-check.sh production

# 5. Access monitoring
kubectl port-forward -n planetary-survival svc/grafana 3000:3000
# Open http://localhost:3000
```

## Project Structure

```
deployment/planetary-survival/
├── kubernetes/                 # Raw Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap-game.yaml
│   ├── configmap-monitoring.yaml
│   ├── secret.yaml
│   ├── statefulset-game-server.yaml
│   ├── deployment-coordinator.yaml
│   ├── services.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   ├── cockroachdb.yaml
│   ├── redis.yaml
│   ├── monitoring.yaml
│   └── rbac.yaml
│
├── helm/                       # Helm charts
│   └── planetary-survival/
│       ├── Chart.yaml
│       ├── values.yaml         # Default values
│       ├── values-dev.yaml     # Development overrides
│       ├── values-staging.yaml # Staging overrides
│       ├── values-production.yaml  # Production overrides
│       └── templates/
│           └── _helpers.tpl
│
├── .github/                    # CI/CD pipelines
│   └── workflows/
│       └── deploy.yml
│
├── scripts/                    # Deployment automation
│   ├── deploy.sh              # Main deployment script
│   ├── scale.sh               # Scaling operations
│   ├── rollback.sh            # Rollback procedure
│   └── health-check.sh        # Post-deployment validation
│
├── docs/                       # Documentation
│   ├── DEPLOYMENT.md          # Deployment guide
│   ├── INFRASTRUCTURE.md      # Architecture documentation
│   ├── TROUBLESHOOTING.md     # Troubleshooting guide
│   └── RUNBOOK.md             # Operations runbook
│
└── README.md                   # This file
```

## Features

### Core Infrastructure

- **Game Servers**: StatefulSet with auto-scaling (3-100 replicas)
- **Mesh Coordinator**: Deployment with leader election (3-10 replicas)
- **CockroachDB**: Distributed SQL database (3-5 nodes)
- **Redis**: Caching and pub/sub (3 replicas with Sentinel)
- **Monitoring**: Prometheus, Grafana, AlertManager

### Auto-Scaling

- **Horizontal Pod Autoscaler**: Based on CPU, memory, and custom metrics
- **Cluster Autoscaler**: Automatic node provisioning
- **Custom Metrics**:
  - Active players per server
  - Average FPS
  - Authority transfer latency

### High Availability

- **Multi-replica deployments**: All components redundant
- **Pod Disruption Budgets**: Maintain minimum availability
- **Health checks**: Liveness and readiness probes
- **Automatic failover**: Leader election for coordinators

### Security

- **Network Policies**: Restrict pod-to-pod communication
- **RBAC**: Least-privilege service accounts
- **Secret Management**: Kubernetes Secrets (external secrets recommended)
- **TLS**: All external connections encrypted
- **Pod Security**: Non-root containers, read-only filesystems

### Monitoring & Alerting

- **Metrics**: Comprehensive Prometheus metrics
- **Dashboards**: Pre-configured Grafana dashboards
- **Alerts**: Multi-level alerting (Critical, Warning, Info)
- **Logs**: Centralized logging with structured output

## Prerequisites

### Required Tools

- kubectl v1.27+
- helm v3.12+
- docker v24+ (for building images)
- git

### Cluster Requirements

#### Development
- 3 nodes (4 CPU, 8GB RAM each)
- 100GB storage
- Single zone

#### Staging
- 5 nodes (8 CPU, 16GB RAM each)
- 500GB storage
- Multi-zone (recommended)

#### Production
- 10+ nodes (16 CPU, 32GB RAM each)
- 2TB+ storage
- Multi-zone/region
- Load balancer support
- Auto-scaling enabled

## Deployment Environments

### Development (dev)

Minimal resources for local testing:

```bash
./scripts/deploy.sh dev
```

**Configuration**:
- 1 game server replica
- 1 coordinator replica
- 1 database node
- No auto-scaling
- No TLS
- Debug logging enabled

### Staging

Production-like environment for testing:

```bash
./scripts/deploy.sh staging
```

**Configuration**:
- 2-20 game server replicas (auto-scaling)
- 2-5 coordinator replicas
- 3 database nodes
- Auto-scaling enabled
- TLS enabled
- Info-level logging

### Production

Full production deployment:

```bash
./scripts/deploy.sh production
```

**Configuration**:
- 5-100 game server replicas (auto-scaling)
- 3-10 coordinator replicas
- 5 database nodes
- Full monitoring and alerting
- TLS with cert-manager
- Warn-level logging
- Backup automation

## Common Operations

### Deploy or Update

```bash
# Deploy new version
./scripts/deploy.sh production --helm-upgrade

# Dry run (see what will change)
./scripts/deploy.sh production --dry-run

# Force deployment (skip validation)
./scripts/deploy.sh production --force
```

### Scale Components

```bash
# Scale game servers
./scripts/scale.sh production 30 game-server

# Enable auto-scaling
./scripts/scale.sh production auto game-server

# Scale coordinators
./scripts/scale.sh production 5 coordinator
```

### Rollback

```bash
# Rollback to previous version
./scripts/rollback.sh production

# Rollback to specific revision
./scripts/rollback.sh production 3

# View rollback history
helm history planetary-survival -n planetary-survival
```

### Health Check

```bash
# Run health checks
./scripts/health-check.sh production

# Check specific component
kubectl get pods -n planetary-survival -l component=game-server
kubectl top pods -n planetary-survival
kubectl get events -n planetary-survival --sort-by='.lastTimestamp'
```

### Monitoring

```bash
# Access Grafana
kubectl port-forward -n planetary-survival svc/grafana 3000:3000
# http://localhost:3000 (admin / <check secret>)

# Access Prometheus
kubectl port-forward -n planetary-survival svc/prometheus 9090:9090
# http://localhost:9090

# View metrics
curl http://localhost:9090/api/v1/query?query=sum(active_players)
```

### Logs

```bash
# View game server logs
kubectl logs -n planetary-survival -l component=game-server --tail=100

# Follow logs in real-time
kubectl logs -f -n planetary-survival game-server-0

# View coordinator logs
kubectl logs -n planetary-survival -l component=mesh-coordinator --tail=100

# View all logs for last 1 hour
kubectl logs -n planetary-survival --all-containers --since=1h
```

## Configuration

### Secrets

Production secrets should be managed securely:

```bash
# Option 1: Kubernetes Secrets (dev/staging only)
kubectl create secret generic database-credentials \
  --from-literal=COCKROACHDB_PASSWORD=<password> \
  --from-literal=REDIS_PASSWORD=<password> \
  --namespace=planetary-survival

# Option 2: Sealed Secrets (recommended)
# Install sealed-secrets controller first
kubeseal < secret.yaml > sealed-secret.yaml
kubectl apply -f sealed-secret.yaml

# Option 3: External Secrets Operator (production)
# Integrate with HashiCorp Vault, AWS Secrets Manager, etc.
```

### Custom Configuration

Edit values file for your environment:

```bash
# Copy production values
cp helm/planetary-survival/values-production.yaml \
   helm/planetary-survival/values-production-custom.yaml

# Edit configuration
vim helm/planetary-survival/values-production-custom.yaml

# Deploy with custom values
helm upgrade planetary-survival helm/planetary-survival \
  --namespace planetary-survival \
  --values helm/planetary-survival/values-production-custom.yaml
```

## CI/CD Pipeline

GitHub Actions workflow automates deployment:

### Workflow Triggers

- **Push to main**: Deploy to production (with approval)
- **Push to staging**: Deploy to staging
- **Push to develop**: Deploy to development
- **Tags (v*)**: Deploy versioned release to production
- **Pull requests**: Build and test only

### Pipeline Steps

1. **Build**: Build Docker images for game-server and coordinator
2. **Test**: Run unit tests and security scans
3. **Push**: Push images to container registry
4. **Deploy**: Deploy to target environment
5. **Verify**: Run smoke tests
6. **Notify**: Send Slack notification

### Manual Workflow

```bash
# Trigger manual deployment
gh workflow run deploy.yml \
  -f environment=production

# View workflow runs
gh run list --workflow=deploy.yml

# View logs
gh run view <run-id> --log
```

## Performance Metrics

### Target SLOs

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Availability | 99.9% | < 99.5% |
| FPS | 90 | < 85 |
| Latency (inter-server) | < 10ms | > 15ms |
| Authority Transfer | < 100ms | > 150ms |
| Player Join Time | < 5s | > 10s |
| Database Query | < 100ms | > 500ms |

### Capacity Planning

**Per 100 Players**:
- Game servers: 2-3 servers
- CPU: ~6 cores
- Memory: ~16GB
- Storage: ~100GB
- Network: ~2Gbps

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed troubleshooting guide.

### Quick Troubleshooting

```bash
# Check pod status
kubectl get pods -n planetary-survival

# Describe pod for events
kubectl describe pod <pod-name> -n planetary-survival

# View logs
kubectl logs <pod-name> -n planetary-survival

# Run health checks
./scripts/health-check.sh production

# Check resource usage
kubectl top pods -n planetary-survival
kubectl top nodes
```

### Common Issues

- **Pods Pending**: Check resource availability and PVC status
- **Crash Loop**: Check logs and environment variables
- **Connection Issues**: Verify service endpoints and network policies
- **Performance Issues**: Check CPU/memory, scale horizontally
- **Database Issues**: Check CockroachDB cluster status

## Documentation

Comprehensive documentation available:

- **[DEPLOYMENT.md](DEPLOYMENT.md)**: Complete deployment guide with step-by-step instructions
- **[INFRASTRUCTURE.md](INFRASTRUCTURE.md)**: Architecture overview, component descriptions, network topology
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**: Common issues, debugging procedures, performance tuning
- **[RUNBOOK.md](RUNBOOK.md)**: Operational procedures, incident response, maintenance tasks

## Support

### Getting Help

- **Documentation**: Read the docs in the `docs/` directory
- **Slack**: #planetary-survival-ops
- **Email**: ops@planetary-survival.example.com
- **On-Call**: PagerDuty escalation

### Reporting Issues

```bash
# Collect diagnostics
kubectl cluster-info dump -n planetary-survival > diagnostics.txt

# Collect logs
kubectl logs -n planetary-survival --all-containers > all-logs.txt

# Include in issue report:
# - Deployment environment
# - Kubernetes version
# - Helm chart version
# - Error messages
# - Diagnostics bundle
```

## Contributing

### Making Changes

1. **Create feature branch**: `git checkout -b feature/my-change`
2. **Make changes**: Update manifests, scripts, or documentation
3. **Test on dev**: `./scripts/deploy.sh dev`
4. **Test on staging**: `./scripts/deploy.sh staging`
5. **Submit PR**: Create pull request for review
6. **Deploy to production**: After approval and merge

### Testing Changes

```bash
# Lint Helm charts
helm lint helm/planetary-survival

# Dry run deployment
./scripts/deploy.sh production --dry-run

# Test on staging first
./scripts/deploy.sh staging
./scripts/health-check.sh staging
```

## License

Copyright © 2023 Planetary Survival Team. All rights reserved.

## Changelog

### Version 1.0.0 (2023-10-15)

- Initial production-ready deployment
- Complete Kubernetes manifests
- Helm charts with multi-environment support
- Automated CI/CD pipeline
- Comprehensive monitoring and alerting
- Full documentation suite

---

**Need help?** Check the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide or contact the ops team.
