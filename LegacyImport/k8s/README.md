# Kubernetes Deployment for SpaceTime with TLS

This directory contains Kubernetes manifests for deploying SpaceTime with HTTPS/TLS support.

## Prerequisites

- Kubernetes cluster (1.25+)
- kubectl configured
- cert-manager installed (for automatic certificate management)
- Ingress controller (NGINX recommended)

## Quick Start

### 1. Install cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

Wait for cert-manager to be ready:
```bash
kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s
```

### 2. Update Configuration

Edit `cert-manager.yaml`:
- Change `admin@example.com` to your email
- Change `spacetime.example.com` to your domain

### 3. Create TLS Secret (Development/Self-Signed)

For development, create a self-signed certificate secret:

```bash
# Generate self-signed cert
python scripts/certificate_manager.py --generate-dev

# Create Kubernetes secret
kubectl create namespace spacetime
kubectl create secret tls tls-secret \
  --cert=certs/dev/server.crt \
  --key=certs/dev/server.key \
  -n spacetime
```

### 4. Deploy SpaceTime

```bash
# Create namespace
kubectl apply -f deployment.tls.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=godot-api -n spacetime --timeout=300s
kubectl wait --for=condition=ready pod -l app=nginx-tls -n spacetime --timeout=300s
```

### 5. Configure cert-manager (Production)

For production with Let's Encrypt:

```bash
# Apply cert-manager configuration
kubectl apply -f cert-manager.yaml

# Wait for certificate to be issued
kubectl get certificate -n spacetime
kubectl describe certificate spacetime-tls -n spacetime
```

## Architecture

```
Internet
    |
    v
LoadBalancer (NGINX Service)
    |
    v
NGINX TLS Pods (2+ replicas)
    |-- TLS Termination
    |-- Rate Limiting
    |-- Security Headers
    |
    v
Godot API Pods (2-10 replicas via HPA)
    |-- HTTP API (8080)
    |-- WebSocket Telemetry (8081)
```

## Monitoring

Check deployment status:
```bash
kubectl get all -n spacetime
```

View logs:
```bash
# Godot API logs
kubectl logs -f deployment/godot-api -n spacetime

# NGINX logs
kubectl logs -f deployment/nginx-tls -n spacetime
```

Check certificate status:
```bash
kubectl get certificate -n spacetime
kubectl describe certificate spacetime-tls -n spacetime
```

## Scaling

### Manual Scaling

```bash
# Scale Godot API
kubectl scale deployment godot-api --replicas=5 -n spacetime

# Scale NGINX
kubectl scale deployment nginx-tls --replicas=3 -n spacetime
```

### Automatic Scaling

Horizontal Pod Autoscaler (HPA) is configured:
- Godot API: 2-10 replicas based on CPU (70%) and memory (80%)
- NGINX: 2-5 replicas based on CPU (75%)

Check HPA status:
```bash
kubectl get hpa -n spacetime
kubectl describe hpa godot-api-hpa -n spacetime
```

## Updating

### Update Application

```bash
# Build new image
docker build -t spacetime/godot-api:v2.0 -f docker/Dockerfile.tls .

# Push to registry
docker push spacetime/godot-api:v2.0

# Update deployment
kubectl set image deployment/godot-api godot-api=spacetime/godot-api:v2.0 -n spacetime

# Check rollout status
kubectl rollout status deployment/godot-api -n spacetime
```

### Rollback

```bash
# View rollout history
kubectl rollout history deployment/godot-api -n spacetime

# Rollback to previous version
kubectl rollout undo deployment/godot-api -n spacetime

# Rollback to specific revision
kubectl rollout undo deployment/godot-api --to-revision=2 -n spacetime
```

## Troubleshooting

### Certificate Issues

Check certificate status:
```bash
kubectl describe certificate spacetime-tls -n spacetime
kubectl describe certificaterequest -n spacetime
kubectl logs -n cert-manager deployment/cert-manager
```

Force certificate renewal:
```bash
kubectl delete secret tls-secret -n spacetime
kubectl delete certificate spacetime-tls -n spacetime
kubectl apply -f cert-manager.yaml
```

### Pod Failures

Check pod status:
```bash
kubectl get pods -n spacetime
kubectl describe pod <pod-name> -n spacetime
kubectl logs <pod-name> -n spacetime
```

### Ingress Issues

Check ingress status:
```bash
kubectl get ingress -n spacetime
kubectl describe ingress spacetime-ingress -n spacetime
```

Test from inside cluster:
```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n spacetime -- sh
curl http://godot-api-service:8080/health
```

## Security

### Network Policies

Network policies are configured to:
- Restrict ingress to Godot API pods (only from NGINX)
- Allow egress for DNS and inter-pod communication

View network policies:
```bash
kubectl get networkpolicy -n spacetime
kubectl describe networkpolicy spacetime-network-policy -n spacetime
```

### Secrets Management

Store sensitive data in Kubernetes secrets:

```bash
# Create API token secret
kubectl create secret generic api-token \
  --from-literal=token=$(openssl rand -hex 32) \
  -n spacetime

# Use in deployment (add to env in deployment.tls.yaml):
env:
- name: API_TOKEN
  valueFrom:
    secretKeyRef:
      name: api-token
      key: token
```

## Cleanup

Remove all resources:
```bash
kubectl delete namespace spacetime
kubectl delete clusterissuer letsencrypt-staging letsencrypt-prod
```

## Production Checklist

- [ ] Domain DNS configured (A/AAAA records)
- [ ] Email configured in cert-manager.yaml
- [ ] Resource limits appropriate for workload
- [ ] Monitoring and alerting configured
- [ ] Backup strategy for certificates
- [ ] Security scanning enabled
- [ ] Network policies tested
- [ ] Disaster recovery plan documented
