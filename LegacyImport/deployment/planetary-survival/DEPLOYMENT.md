# Planetary Survival - Deployment Guide

This guide covers the complete deployment process for the Planetary Survival VR multiplayer game with server meshing architecture.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Environment Configuration](#environment-configuration)
4. [Deployment Procedure](#deployment-procedure)
5. [Scaling Guide](#scaling-guide)
6. [Update Procedure](#update-procedure)
7. [Rollback Procedure](#rollback-procedure)
8. [Post-Deployment Validation](#post-deployment-validation)

## Prerequisites

### Required Tools

- **kubectl** (v1.27+) - Kubernetes command-line tool
- **helm** (v3.12+) - Kubernetes package manager
- **docker** (v24+) - Container runtime (for building images)
- **git** - Version control

### Cluster Requirements

#### Development Environment
- Kubernetes cluster (1.27+)
- 3 nodes minimum
- Node resources: 4 CPU, 8GB RAM per node
- Storage: 100GB total

#### Staging Environment
- Kubernetes cluster (1.27+)
- 5 nodes minimum
- Node resources: 8 CPU, 16GB RAM per node
- Storage: 500GB total
- Load balancer support

#### Production Environment
- Kubernetes cluster (1.27+)
- 10+ nodes (auto-scaling enabled)
- Node resources: 16 CPU, 32GB RAM per node
- Storage: 2TB+ total
- Load balancer support
- Multi-zone/region setup (recommended)
- Monitoring infrastructure

### Access Requirements

- Kubernetes cluster admin access
- Container registry access (for pushing/pulling images)
- DNS configuration access
- TLS certificate management (cert-manager or manual)

## Initial Setup

### 1. Clone Repository

```bash
git clone https://github.com/your-org/planetary-survival.git
cd planetary-survival/deployment/planetary-survival
```

### 2. Configure kubectl Context

```bash
# List available contexts
kubectl config get-contexts

# Set context for target environment
kubectl config use-context <your-cluster-context>

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### 3. Install cert-manager (Production)

For production deployments with TLS:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/instance=cert-manager \
  -n cert-manager \
  --timeout=300s

# Create ClusterIssuer for Let's Encrypt
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ops@planetary-survival.example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### 4. Install Ingress Controller

```bash
# Install NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.metrics.enabled=true
```

### 5. Create Storage Classes

```bash
# Create fast-ssd storage class (example for AWS)
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF
```

## Environment Configuration

### Development (dev)

Development environment uses minimal resources for testing:

```bash
cd helm/planetary-survival

# Review dev configuration
cat values-dev.yaml

# Customize if needed
cp values-dev.yaml values-dev-custom.yaml
# Edit values-dev-custom.yaml
```

### Staging

Staging mirrors production but with reduced scale:

```bash
# Review staging configuration
cat values-staging.yaml

# Important: Set real credentials
export COCKROACHDB_PASSWORD="<secure-password>"
export REDIS_PASSWORD="<secure-password>"
export API_TOKEN="<secure-token>"
```

### Production

Production requires careful configuration:

```bash
# Copy production values template
cp values-production.yaml values-production-custom.yaml

# Edit values-production-custom.yaml
# Set all secret values (do not commit secrets to git!)
vim values-production-custom.yaml
```

**Critical Production Settings:**

1. **Secrets**: Use a secret management solution (HashiCorp Vault, AWS Secrets Manager, etc.)
2. **Domain names**: Update all `*.example.com` domains
3. **Resource limits**: Adjust based on expected load
4. **Backup strategy**: Configure automated backups
5. **Monitoring alerts**: Configure Slack/PagerDuty webhooks

## Deployment Procedure

### Quick Deployment

For standard deployment:

```bash
# Deploy to development
./scripts/deploy.sh dev

# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production
./scripts/deploy.sh production
```

### Advanced Deployment Options

```bash
# Dry run (see what will be deployed)
./scripts/deploy.sh production --dry-run

# Force deployment (skip validation)
./scripts/deploy.sh production --force

# Skip post-deployment tests
./scripts/deploy.sh production --skip-tests

# Use helm upgrade (for updates)
./scripts/deploy.sh production --helm-upgrade
```

### Manual Deployment (Alternative)

```bash
# Create namespace
kubectl create namespace planetary-survival

# Apply secrets (use secure method in production)
kubectl apply -f kubernetes/secret.yaml

# Install with Helm
helm install planetary-survival helm/planetary-survival \
  --namespace planetary-survival \
  --values helm/planetary-survival/values-production.yaml \
  --timeout 15m \
  --wait
```

### Verify Deployment

```bash
# Check all resources
kubectl get all -n planetary-survival

# Check pods status
kubectl get pods -n planetary-survival -w

# Check services
kubectl get svc -n planetary-survival

# Check ingress
kubectl get ingress -n planetary-survival

# Run health checks
./scripts/health-check.sh production
```

## Scaling Guide

### Automatic Scaling (HPA)

The deployment includes Horizontal Pod Autoscalers:

```bash
# View HPA status
kubectl get hpa -n planetary-survival

# HPA automatically scales based on:
# - CPU utilization (target: 70%)
# - Memory utilization (target: 75%)
# - Active players (target: 40 per server)
# - FPS (target: 88 average)
```

### Manual Scaling

#### Scale Game Servers

```bash
# Scale to specific number
./scripts/scale.sh production 20 game-server

# Enable auto-scaling
./scripts/scale.sh production auto game-server
```

#### Scale Mesh Coordinator

```bash
# Scale coordinators
./scripts/scale.sh production 5 coordinator
```

#### Scale All Components

```bash
# Scale everything
./scripts/scale.sh production 15 all
```

### Cluster Autoscaling

Enable cluster autoscaler for node-level scaling:

```bash
# Example for AWS
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-autoscaler-config
  namespace: kube-system
data:
  min-nodes: "10"
  max-nodes: "100"
  scale-down-delay: "10m"
  scale-down-unneeded-time: "10m"
EOF
```

## Update Procedure

### Rolling Updates

```bash
# Update container images
# 1. Build and push new images
docker build -t ghcr.io/your-org/game-server:v1.1.0 .
docker push ghcr.io/your-org/game-server:v1.1.0

# 2. Update values file
sed -i 's/tag: "v1.0.0"/tag: "v1.1.0"/' helm/planetary-survival/values-production.yaml

# 3. Deploy update
./scripts/deploy.sh production --helm-upgrade

# 4. Monitor rollout
kubectl rollout status statefulset/game-server -n planetary-survival
kubectl rollout status deployment/mesh-coordinator -n planetary-survival
```

### Zero-Downtime Updates

The deployment uses rolling updates with pod disruption budgets:

```yaml
# Ensures minimum 2 replicas always available
podDisruptionBudget:
  minAvailable: 2
```

### Configuration Updates

```bash
# Update ConfigMaps
kubectl edit configmap game-server-config -n planetary-survival

# Restart pods to apply changes
kubectl rollout restart statefulset/game-server -n planetary-survival
```

## Rollback Procedure

### Quick Rollback

```bash
# Rollback to previous version
./scripts/rollback.sh production

# Rollback to specific revision
./scripts/rollback.sh production 3
```

### View Rollback History

```bash
# View deployment history
helm history planetary-survival -n planetary-survival

# Example output:
# REVISION  UPDATED                   STATUS      DESCRIPTION
# 1         Mon Oct 16 10:00:00 2023  superseded  Install complete
# 2         Mon Oct 16 11:00:00 2023  superseded  Upgrade complete
# 3         Mon Oct 16 12:00:00 2023  deployed    Upgrade complete
```

### Manual Rollback

```bash
# Rollback using Helm
helm rollback planetary-survival 2 -n planetary-survival --wait

# Verify rollback
kubectl get pods -n planetary-survival
./scripts/health-check.sh production
```

### Emergency Rollback

In case of critical issues:

```bash
# 1. Immediate rollback
helm rollback planetary-survival -n planetary-survival --wait --timeout=5m

# 2. Scale down if needed
./scripts/scale.sh production 3 game-server

# 3. Check logs
kubectl logs -n planetary-survival -l component=game-server --tail=100

# 4. Restore from backup if database issues
kubectl exec -n planetary-survival cockroachdb-0 -- \
  /cockroach/cockroach sql --insecure < backup-latest.sql
```

## Post-Deployment Validation

### Automated Validation

```bash
# Run comprehensive health checks
./scripts/health-check.sh production

# Expected output:
# [PASS] Namespace planetary-survival exists
# [PASS] All pods running (15/15)
# [PASS] Game servers ready (10/10)
# [PASS] Coordinators ready (3/3)
# [PASS] Database connection successful
# [PASS] Redis connection successful
# [PASS] Game server service has 10 endpoints
# [PASS] All PVCs are bound
# [PASS] No excessive restarts
# [PASS] No pods with excessive CPU usage
```

### Manual Validation

#### 1. Check Pod Status

```bash
kubectl get pods -n planetary-survival
# All pods should be Running and Ready (1/1 or 2/2)
```

#### 2. Test Game Server API

```bash
# Port forward to game server
kubectl port-forward -n planetary-survival svc/game-server-lb 8080:8080

# Test health endpoint
curl http://localhost:8080/health

# Expected response:
# {"status":"healthy","servers":10,"players":0}
```

#### 3. Test Mesh Coordinator

```bash
# Port forward to coordinator
kubectl port-forward -n planetary-survival svc/mesh-coordinator 8080:8080

# Test health endpoint
curl http://localhost:8080/health

# Check region assignment
curl http://localhost:8080/regions
```

#### 4. Check Metrics

```bash
# Port forward to Prometheus
kubectl port-forward -n planetary-survival svc/prometheus 9090:9090

# Access Prometheus at http://localhost:9090
# Check these queries:
# - up{job="game-servers"}
# - server_cpu_usage
# - active_players
```

#### 5. Check Grafana Dashboards

```bash
# Port forward to Grafana
kubectl port-forward -n planetary-survival svc/grafana 3000:3000

# Access Grafana at http://localhost:3000
# Default credentials: admin / (check secret)
```

#### 6. Test Database

```bash
# Connect to database
kubectl exec -it -n planetary-survival cockroachdb-0 -- \
  /cockroach/cockroach sql --insecure

# Run test query
SELECT count(*) FROM system.namespace;
```

#### 7. Load Testing

```bash
# Run load test (example)
kubectl run load-test --image=busybox --restart=Never -- \
  sh -c "while true; do wget -q -O- http://game-server-lb:8080/health; done"

# Monitor during load test
watch kubectl top pods -n planetary-survival
```

### Smoke Tests

Automated smoke tests are included:

```bash
# Located at: scripts/smoke-tests.sh
./scripts/smoke-tests.sh production

# Tests include:
# - API endpoint accessibility
# - Database connectivity
# - Redis connectivity
# - Service discovery
# - Player connection simulation
# - Region assignment
```

## Troubleshooting

For troubleshooting issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Next Steps

- Configure monitoring alerts: See [INFRASTRUCTURE.md](INFRASTRUCTURE.md)
- Set up backup automation: See [RUNBOOK.md](RUNBOOK.md)
- Configure disaster recovery: See [RUNBOOK.md](RUNBOOK.md)
- Review operational procedures: See [RUNBOOK.md](RUNBOOK.md)
