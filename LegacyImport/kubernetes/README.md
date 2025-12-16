# Kubernetes Deployment - SpaceTime v2.5

Production-ready Kubernetes manifests for deploying SpaceTime v2.5 VR application.

## Overview

This directory contains Kubernetes manifests for deploying the complete SpaceTime stack:

- **Godot VR Engine** with AI debug services
- **NGINX Ingress** with SSL/TLS termination
- **Prometheus** for metrics collection
- **Grafana** for visualization
- **Redis** for caching and state management

## Prerequisites

### Required Tools

```bash
# kubectl 1.25+
kubectl version --client

# Helm 3.0+ (optional, for cert-manager)
helm version

# Docker (for building images)
docker version
```

### Cluster Requirements

**Minimum:**
- Kubernetes 1.25+
- 3 nodes with 4 CPU / 16GB RAM each
- 200GB total storage
- Ingress controller (NGINX recommended)
- StorageClass `fast-ssd` configured

**Recommended:**
- Kubernetes 1.28+
- 5 nodes with 8 CPU / 32GB RAM each
- 500GB SSD storage
- cert-manager for automatic TLS
- Metrics server enabled
- Prometheus operator (optional)

## Quick Start

### 1. Build and Push Docker Image

```bash
# Build image
docker build -f Dockerfile.v2.5 -t your-registry/spacetime:v2.5-4.5 .

# Push to registry
docker push your-registry/spacetime:v2.5-4.5

# Update deployment.yaml with your image
sed -i 's|spacetime:v2.5-4.5|your-registry/spacetime:v2.5-4.5|g' kubernetes/deployment.yaml
```

### 2. Create Secrets

```bash
# Generate API token
export API_TOKEN=$(openssl rand -base64 32)

# Generate passwords
export GRAFANA_PASSWORD=$(openssl rand -base64 24)
export REDIS_PASSWORD=$(openssl rand -base64 24)

# Create secret
kubectl create secret generic spacetime-secrets \
  --from-literal=API_TOKEN="$API_TOKEN" \
  --from-literal=GRAFANA_ADMIN_USER="admin" \
  --from-literal=GRAFANA_ADMIN_PASSWORD="$GRAFANA_PASSWORD" \
  --from-literal=REDIS_PASSWORD="$REDIS_PASSWORD" \
  -n spacetime

# Save credentials
echo "API_TOKEN=$API_TOKEN" > .credentials
echo "GRAFANA_PASSWORD=$GRAFANA_PASSWORD" >> .credentials
echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> .credentials
chmod 600 .credentials
```

### 3. Create TLS Certificate

**Option A: Self-signed (Development)**

```bash
# Generate certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=spacetime.example.com"

# Create secret
kubectl create secret tls spacetime-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n spacetime
```

**Option B: cert-manager (Production)**

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
EOF

# Certificate will be auto-created by Ingress annotation
```

### 4. Deploy Application

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Apply all manifests
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml  # If not created manually
kubectl apply -f pvc.yaml
kubectl apply -f statefulset.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f networkpolicy.yaml
kubectl apply -f hpa.yaml

# Or apply all at once
kubectl apply -f kubernetes/
```

### 5. Verify Deployment

```bash
# Check namespace
kubectl get all -n spacetime

# Check pods
kubectl get pods -n spacetime -w

# Check services
kubectl get svc -n spacetime

# Check ingress
kubectl get ingress -n spacetime

# Check PVCs
kubectl get pvc -n spacetime

# View logs
kubectl logs -f deployment/spacetime-godot -n spacetime
```

Expected output:
```
NAME                                   READY   STATUS    RESTARTS   AGE
pod/spacetime-godot-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
pod/spacetime-nginx-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
pod/spacetime-prometheus-xxxxx-xxxxx   1/1     Running   0          2m
pod/spacetime-grafana-xxxxxxxx-xxxxx   1/1     Running   0          2m
pod/spacetime-redis-0                  1/1     Running   0          2m
```

### 6. Access Services

```bash
# Get external IP (if using LoadBalancer)
kubectl get svc spacetime-nginx-service -n spacetime

# Get ingress address
kubectl get ingress spacetime-ingress -n spacetime

# Test health
curl -k https://your-domain/health

# Test API
curl -k -H "Authorization: Bearer $API_TOKEN" https://your-domain/api/status

# Access Grafana
# URL: https://your-domain/grafana
# User: admin
# Password: (from .credentials)
```

## File Reference

| File | Purpose |
|------|---------|
| `namespace.yaml` | Creates spacetime namespace |
| `configmap.yaml` | Configuration for Godot, Prometheus, NGINX |
| `secret.yaml` | Secrets template (API token, passwords) |
| `pvc.yaml` | Persistent volume claims for data storage |
| `deployment.yaml` | Deployments for Godot, NGINX, Prometheus, Grafana |
| `statefulset.yaml` | StatefulSet for Redis |
| `service.yaml` | Services for all components |
| `ingress.yaml` | Ingress for external access |
| `hpa.yaml` | Horizontal Pod Autoscalers |
| `networkpolicy.yaml` | Network policies for security |

## Configuration

### Update Domain Name

```bash
# Replace example.com with your domain
sed -i 's/spacetime.example.com/your-domain.com/g' kubernetes/ingress.yaml
```

### Update Storage Class

```bash
# If your cluster uses different storage class
sed -i 's/fast-ssd/your-storage-class/g' kubernetes/pvc.yaml
sed -i 's/fast-ssd/your-storage-class/g' kubernetes/statefulset.yaml
```

### Update Resource Limits

Edit `deployment.yaml` and adjust resources based on your needs:

```yaml
resources:
  requests:
    cpu: 4000m      # Adjust
    memory: 8Gi     # Adjust
  limits:
    cpu: 8000m      # Adjust
    memory: 16Gi    # Adjust
```

## Scaling

### Manual Scaling

```bash
# Scale NGINX replicas
kubectl scale deployment spacetime-nginx --replicas=5 -n spacetime

# Note: Godot typically runs as single instance
# Only scale if you implement distributed state management
```

### Autoscaling

HPA is configured to automatically scale NGINX based on CPU/memory:

```bash
# View HPA status
kubectl get hpa -n spacetime

# Describe HPA
kubectl describe hpa spacetime-nginx-hpa -n spacetime
```

## Monitoring

### Prometheus

```bash
# Port-forward to access Prometheus
kubectl port-forward -n spacetime svc/spacetime-prometheus-service 9090:9090

# Access at http://localhost:9090
```

### Grafana

```bash
# Port-forward to access Grafana
kubectl port-forward -n spacetime svc/spacetime-grafana-service 3000:3000

# Access at http://localhost:3000
# Or via Ingress: https://your-domain/grafana
```

### Logs

```bash
# All pods in namespace
kubectl logs -f -l app=spacetime-godot -n spacetime

# Specific pod
kubectl logs -f pod/spacetime-godot-xxxx -n spacetime

# Previous container (if crashed)
kubectl logs -p pod/spacetime-godot-xxxx -n spacetime

# Export logs
kubectl logs deployment/spacetime-godot -n spacetime > godot.log
```

### Events

```bash
# View events
kubectl get events -n spacetime --sort-by='.lastTimestamp'

# Watch events
kubectl get events -n spacetime -w
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl describe pod spacetime-godot-xxxx -n spacetime

# Check events
kubectl get events -n spacetime | grep spacetime-godot

# Check logs
kubectl logs spacetime-godot-xxxx -n spacetime
```

### Image Pull Errors

```bash
# Create registry secret
kubectl create secret docker-registry regcred \
  --docker-server=your-registry.com \
  --docker-username=your-username \
  --docker-password=your-password \
  --docker-email=your-email \
  -n spacetime

# Update deployment to use imagePullSecrets
# Add to deployment.yaml:
spec:
  template:
    spec:
      imagePullSecrets:
        - name: regcred
```

### PVC Not Binding

```bash
# Check PVC status
kubectl get pvc -n spacetime

# Check storage class
kubectl get storageclass

# Describe PVC
kubectl describe pvc spacetime-godot-data -n spacetime
```

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n spacetime

# Test from within cluster
kubectl run -it --rm debug --image=alpine --restart=Never -n spacetime -- sh
# Inside pod:
wget -O- http://spacetime-godot-service:8080/status
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress
kubectl describe ingress spacetime-ingress -n spacetime

# Check ingress logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

## Backup and Recovery

### Backup

```bash
# Backup PVC data
kubectl exec -n spacetime spacetime-godot-xxxx -- tar -czf - /app/data | \
  cat > godot-data-backup.tar.gz

# Backup Prometheus data
kubectl exec -n spacetime spacetime-prometheus-xxxx -- tar -czf - /prometheus | \
  cat > prometheus-backup.tar.gz

# Backup configurations
kubectl get configmap,secret -n spacetime -o yaml > spacetime-config-backup.yaml
```

### Restore

```bash
# Restore data to PVC
cat godot-data-backup.tar.gz | \
  kubectl exec -i -n spacetime spacetime-godot-xxxx -- tar -xzf - -C /app/data

# Restore configurations
kubectl apply -f spacetime-config-backup.yaml
```

## Upgrading

### Rolling Update

```bash
# Update image
kubectl set image deployment/spacetime-godot \
  godot=your-registry/spacetime:v2.6-4.5 \
  -n spacetime

# Check rollout status
kubectl rollout status deployment/spacetime-godot -n spacetime

# View history
kubectl rollout history deployment/spacetime-godot -n spacetime
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/spacetime-godot -n spacetime

# Rollback to specific revision
kubectl rollout undo deployment/spacetime-godot --to-revision=2 -n spacetime
```

## Security

### Network Policies

Network policies are configured to:
- Isolate pods by default
- Allow only necessary communication
- Restrict external access

```bash
# View network policies
kubectl get networkpolicy -n spacetime

# Test connectivity
kubectl run -it --rm debug --image=alpine -n spacetime -- sh
```

### Pod Security

All pods are configured with:
- Non-root users
- Read-only root filesystem (where possible)
- Dropped capabilities
- seccomp profile

### RBAC

Create ServiceAccount with minimal permissions:

```bash
# Create service account
kubectl create serviceaccount spacetime-sa -n spacetime

# Create role
kubectl create role spacetime-role \
  --verb=get,list,watch \
  --resource=pods,services \
  -n spacetime

# Create role binding
kubectl create rolebinding spacetime-binding \
  --role=spacetime-role \
  --serviceaccount=spacetime:spacetime-sa \
  -n spacetime
```

## Performance Tuning

### Resource Requests/Limits

Adjust based on actual usage:

```bash
# Get resource usage
kubectl top pods -n spacetime
kubectl top nodes
```

### Node Affinity

Pin Godot pods to high-performance nodes:

```yaml
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: node-type
                    operator: In
                    values:
                      - high-performance
```

## Cleanup

```bash
# Delete all resources
kubectl delete namespace spacetime

# Or delete individual components
kubectl delete -f kubernetes/

# Delete PVCs (if not auto-deleted)
kubectl delete pvc -n spacetime --all
```

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [cert-manager](https://cert-manager.io/)
- [Prometheus Operator](https://prometheus-operator.dev/)

## Support

For issues specific to SpaceTime deployment, see:
- [Docker Deployment Guide](../DOCKER_DEPLOYMENT_V2.5.md)
- [Main README](../README.md)
- GitHub Issues
