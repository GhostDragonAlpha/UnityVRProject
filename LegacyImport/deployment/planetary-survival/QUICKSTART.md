# Planetary Survival - Quick Start Guide

Get Planetary Survival deployed in minutes with this quick start guide.

## Prerequisites Check

```bash
# Verify tools are installed
kubectl version --client
helm version
docker version

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

## 5-Minute Development Setup

```bash
# 1. Clone repository
git clone https://github.com/your-org/planetary-survival.git
cd planetary-survival/deployment/planetary-survival

# 2. Deploy to development
./scripts/deploy.sh dev

# 3. Wait for pods to be ready (2-3 minutes)
kubectl get pods -n planetary-survival -w
# Press Ctrl+C when all pods show 1/1 READY

# 4. Run health check
./scripts/health-check.sh dev

# 5. Access services
kubectl port-forward -n planetary-survival svc/game-server-lb 7777:7777 &
kubectl port-forward -n planetary-survival svc/grafana 3000:3000 &

# 6. Test connection
# Point your VR client to localhost:7777

# 7. View metrics at http://localhost:3000
```

## 15-Minute Staging Setup

```bash
# 1. Configure kubectl for staging cluster
kubectl config use-context staging-cluster

# 2. Set up storage class (if not exists)
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs  # or your provider
parameters:
  type: gp3
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

# 3. Create secrets
kubectl create namespace planetary-survival
kubectl create secret generic database-credentials \
  --from-literal=COCKROACHDB_PASSWORD="$(openssl rand -base64 32)" \
  --from-literal=REDIS_PASSWORD="$(openssl rand -base64 32)" \
  --namespace=planetary-survival

kubectl create secret generic api-keys \
  --from-literal=API_TOKEN="$(openssl rand -base64 32)" \
  --from-literal=JWT_SECRET="$(openssl rand -base64 32)" \
  --namespace=planetary-survival

kubectl create secret generic game-server-keys \
  --from-literal=INTER_SERVER_SECRET="$(openssl rand -base64 32)" \
  --from-literal=MESH_COORDINATOR_TOKEN="$(openssl rand -base64 32)" \
  --namespace=planetary-survival

# 4. Deploy
./scripts/deploy.sh staging

# 5. Verify deployment (5-7 minutes)
./scripts/health-check.sh staging

# 6. Configure DNS (point to load balancer)
kubectl get svc -n planetary-survival game-server-lb
# Create DNS A record: staging.planetary-survival.example.com → EXTERNAL-IP
```

## 30-Minute Production Setup

```bash
# 1. Prerequisites
# - Production cluster with 10+ nodes
# - cert-manager installed
# - Ingress controller installed
# - Storage class configured
# - DNS management access

# 2. Install cert-manager (if not installed)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/instance=cert-manager \
  -n cert-manager --timeout=300s

# 3. Install NGINX Ingress (if not installed)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer

# 4. Create ClusterIssuer
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

# 5. Create storage class
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com  # Adjust for your cloud provider
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

# 6. Generate production secrets
export COCKROACHDB_PASSWORD="$(openssl rand -base64 32)"
export REDIS_PASSWORD="$(openssl rand -base64 32)"
export API_TOKEN="$(openssl rand -base64 32)"
export JWT_SECRET="$(openssl rand -base64 64)"
export INTER_SERVER_SECRET="$(openssl rand -base64 32)"
export MESH_COORDINATOR_TOKEN="$(openssl rand -base64 32)"

# IMPORTANT: Save these to a secure vault!
# Do not commit to git!

# 7. Create secrets
kubectl create namespace planetary-survival

kubectl create secret generic database-credentials \
  --from-literal=COCKROACHDB_PASSWORD="$COCKROACHDB_PASSWORD" \
  --from-literal=COCKROACHDB_USER="planetary_admin" \
  --from-literal=COCKROACHDB_DATABASE="planetary_survival" \
  --from-literal=REDIS_PASSWORD="$REDIS_PASSWORD" \
  --namespace=planetary-survival

kubectl create secret generic api-keys \
  --from-literal=API_TOKEN="$API_TOKEN" \
  --from-literal=JWT_SECRET="$JWT_SECRET" \
  --namespace=planetary-survival

kubectl create secret generic game-server-keys \
  --from-literal=INTER_SERVER_SECRET="$INTER_SERVER_SECRET" \
  --from-literal=MESH_COORDINATOR_TOKEN="$MESH_COORDINATOR_TOKEN" \
  --namespace=planetary-survival

# 8. Configure production values
cp helm/planetary-survival/values-production.yaml \
   helm/planetary-survival/values-production-custom.yaml

# Edit domain names in values file
sed -i 's/planetary-survival.example.com/yourdomain.com/g' \
  helm/planetary-survival/values-production-custom.yaml

# 9. Deploy
./scripts/deploy.sh production

# 10. Monitor deployment (10-15 minutes)
watch kubectl get pods -n planetary-survival

# 11. Verify deployment
./scripts/health-check.sh production

# 12. Configure DNS
# Get load balancer IP
kubectl get svc -n planetary-survival game-server-lb
kubectl get ingress -n planetary-survival

# Create DNS records:
# planetary-survival.yourdomain.com → game-server-lb EXTERNAL-IP
# api.planetary-survival.yourdomain.com → ingress EXTERNAL-IP
# coordinator.planetary-survival.yourdomain.com → ingress EXTERNAL-IP
# monitoring.planetary-survival.yourdomain.com → ingress EXTERNAL-IP

# 13. Wait for TLS certificates (2-5 minutes)
kubectl get certificate -n planetary-survival
# Wait until READY = True

# 14. Test endpoints
curl https://api.planetary-survival.yourdomain.com/health
curl https://coordinator.planetary-survival.yourdomain.com/health

# 15. Access monitoring
open https://monitoring.planetary-survival.yourdomain.com/grafana
```

## Common First-Time Issues

### Issue: Pods stuck in Pending

```bash
# Check if storage class exists
kubectl get sc

# If missing, create fast-ssd storage class
kubectl apply -f kubernetes/storage-class.yaml

# Check node resources
kubectl describe nodes | grep -A 5 "Allocated resources"

# If insufficient, scale up cluster
```

### Issue: Database won't start

```bash
# Check CockroachDB logs
kubectl logs cockroachdb-0 -n planetary-survival

# Initialize cluster manually if needed
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach init --insecure --host=cockroachdb-0
```

### Issue: Can't connect to game server

```bash
# Check load balancer
kubectl get svc game-server-lb -n planetary-survival
# Should show EXTERNAL-IP (not <pending>)

# If pending, check cloud provider load balancer support

# Check security groups/firewall
# Ensure UDP 7777 and TCP 7778 are open
```

### Issue: TLS certificate not issued

```bash
# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Check certificate status
kubectl describe certificate planetary-survival-tls -n planetary-survival

# Common causes:
# - DNS not pointing to ingress
# - Port 80 not accessible (needed for HTTP-01 challenge)
# - Rate limit from Let's Encrypt (use staging issuer for testing)
```

## Testing Your Deployment

### 1. Health Check

```bash
./scripts/health-check.sh production

# Should show all checks passing:
# ✓ Namespace exists
# ✓ All pods running
# ✓ Game servers ready
# ✓ Coordinators ready
# ✓ Database connection successful
# ✓ Redis connection successful
# ✓ Service endpoints available
# ✓ All PVCs bound
```

### 2. API Test

```bash
# Get API token
API_TOKEN=$(kubectl get secret api-keys -n planetary-survival \
  -o jsonpath='{.data.API_TOKEN}' | base64 -d)

# Test game server API
curl -H "Authorization: Bearer $API_TOKEN" \
  https://api.planetary-survival.yourdomain.com/health

# Expected response:
# {"status":"healthy","servers":5,"players":0}
```

### 3. VR Client Test

```bash
# Port forward for local testing
kubectl port-forward -n planetary-survival svc/game-server-lb 7777:7777

# Connect VR client to localhost:7777
# Should see connection established in logs:
kubectl logs -f -n planetary-survival -l component=game-server | grep "player_connected"
```

### 4. Load Test (Optional)

```bash
# Simple load test with 100 simulated players
kubectl run load-test --image=planetary-survival/load-tester \
  --env="GAME_SERVER=planetary-survival.yourdomain.com" \
  --env="NUM_PLAYERS=100"

# Monitor metrics during load test
kubectl port-forward -n planetary-survival svc/grafana 3000:3000
# Open http://localhost:3000 - View "Server Performance" dashboard
```

## Scaling Your Deployment

### Automatic Scaling

Auto-scaling is enabled by default in staging and production:

```bash
# Check HPA status
kubectl get hpa -n planetary-survival

# View scaling events
kubectl describe hpa game-server-hpa -n planetary-survival
```

### Manual Scaling

```bash
# Scale to specific number
./scripts/scale.sh production 20 game-server

# Enable auto-scaling
./scripts/scale.sh production auto
```

## Accessing Monitoring

```bash
# Get Grafana admin password
kubectl get secret grafana-credentials -n planetary-survival \
  -o jsonpath='{.data.admin-password}' | base64 -d

# Port forward to Grafana
kubectl port-forward -n planetary-survival svc/grafana 3000:3000

# Open http://localhost:3000
# Login: admin / <password from above>

# Or access via ingress (production):
open https://monitoring.planetary-survival.yourdomain.com/grafana
```

## Next Steps

After successful deployment:

1. **Configure Alerts**: Edit AlertManager configuration
2. **Set Up Backups**: Configure automated backups to S3/GCS
3. **Configure Monitoring**: Customize Grafana dashboards
4. **Load Testing**: Run comprehensive load tests
5. **Documentation**: Read full docs in DEPLOYMENT.md

## Getting Help

- **Documentation**: See README.md for full documentation index
- **Troubleshooting**: See TROUBLESHOOTING.md for common issues
- **Slack**: #planetary-survival-ops
- **Email**: ops@planetary-survival.example.com

---

**Congratulations!** You now have a production-ready Planetary Survival deployment running.
