# Planetary Survival - Troubleshooting Guide

This guide covers common issues, debugging procedures, and performance tuning for Planetary Survival deployments.

## Table of Contents

1. [Common Issues](#common-issues)
2. [Log Locations](#log-locations)
3. [Debug Procedures](#debug-procedures)
4. [Performance Tuning](#performance-tuning)
5. [Database Issues](#database-issues)
6. [Network Issues](#network-issues)

## Common Issues

### Issue 1: Pods Stuck in Pending State

**Symptoms**:
```bash
$ kubectl get pods -n planetary-survival
NAME                READY   STATUS    RESTARTS   AGE
game-server-0       0/1     Pending   0          5m
```

**Causes & Solutions**:

1. **Insufficient Resources**
   ```bash
   # Check node resources
   kubectl describe node | grep -A 5 "Allocated resources"

   # Solution: Add more nodes or reduce resource requests
   kubectl scale deployment cluster-autoscaler -n kube-system --replicas=1
   ```

2. **PVC Not Bound**
   ```bash
   # Check PVC status
   kubectl get pvc -n planetary-survival

   # If PVC is pending, check storage class
   kubectl get sc

   # Solution: Create storage class or fix provisioner
   kubectl apply -f kubernetes/storage-class.yaml
   ```

3. **Node Selector Mismatch**
   ```bash
   # Check pod events
   kubectl describe pod game-server-0 -n planetary-survival

   # Solution: Label nodes correctly
   kubectl label node <node-name> node-role.kubernetes.io/game-server=true
   ```

### Issue 2: Game Server Crash Loop

**Symptoms**:
```bash
$ kubectl get pods -n planetary-survival
NAME                READY   STATUS             RESTARTS   AGE
game-server-0       0/1     CrashLoopBackOff   5          3m
```

**Debugging Steps**:

1. **Check logs**:
   ```bash
   # View pod logs
   kubectl logs game-server-0 -n planetary-survival

   # View previous container logs
   kubectl logs game-server-0 -n planetary-survival --previous
   ```

2. **Check events**:
   ```bash
   kubectl describe pod game-server-0 -n planetary-survival
   ```

3. **Common causes**:
   - Database connection failure
   - Missing secrets
   - Invalid configuration
   - OOM (Out of Memory)

**Solutions**:

```bash
# Fix database connection
kubectl exec -it game-server-0 -n planetary-survival -- \
  nc -zv cockroachdb-public 26257

# Check secrets exist
kubectl get secrets -n planetary-survival

# Check memory limits
kubectl top pod game-server-0 -n planetary-survival

# Increase memory if needed
helm upgrade planetary-survival helm/planetary-survival \
  --set gameServer.resources.limits.memory=16Gi
```

### Issue 3: Players Can't Connect

**Symptoms**:
- Players see connection timeout
- Game servers appear healthy
- Load balancer is running

**Debugging Steps**:

1. **Check service endpoints**:
   ```bash
   kubectl get endpoints game-server-lb -n planetary-survival
   # Should show multiple IPs
   ```

2. **Test from inside cluster**:
   ```bash
   kubectl run test --image=busybox --restart=Never --rm -it -- \
     nc -zv game-server-lb 7777
   ```

3. **Check load balancer**:
   ```bash
   kubectl get svc game-server-lb -n planetary-survival
   # Should have EXTERNAL-IP assigned
   ```

4. **Verify firewall rules**:
   ```bash
   # AWS example
   aws ec2 describe-security-groups \
     --filters "Name=tag:kubernetes.io/cluster/<cluster-name>,Values=owned"

   # Ensure UDP 7777 is open
   ```

**Solutions**:

```bash
# Recreate service if no external IP
kubectl delete svc game-server-lb -n planetary-survival
kubectl apply -f kubernetes/services.yaml

# Check ingress controller
kubectl get pods -n ingress-nginx

# Verify DNS
nslookup planetary-survival.example.com
```

### Issue 4: High Latency / Low FPS

**Symptoms**:
- Players report lag
- Average FPS < 85
- High CPU usage

**Debugging Steps**:

1. **Check metrics**:
   ```bash
   # CPU usage
   kubectl top pods -n planetary-survival

   # Custom metrics
   kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1/namespaces/planetary-survival/pods/*/avg_fps
   ```

2. **Check inter-server latency**:
   ```bash
   # Port forward to coordinator
   kubectl port-forward -n planetary-survival svc/mesh-coordinator 8080:8080

   # Query latency metrics
   curl http://localhost:8080/metrics | grep latency
   ```

3. **Profile game server**:
   ```bash
   # Access profiling endpoint
   kubectl port-forward -n planetary-survival game-server-0 8080:8080
   curl http://localhost:8080/debug/pprof/profile?seconds=30 > cpu.prof
   ```

**Solutions**:

1. **Scale horizontally**:
   ```bash
   # Add more servers to distribute load
   ./scripts/scale.sh production 30 game-server
   ```

2. **Optimize physics**:
   ```bash
   # Reduce physics tick rate temporarily
   kubectl set env statefulset/game-server -n planetary-survival \
     PHYSICS_TICK_RATE=60
   ```

3. **Reduce player density**:
   ```bash
   # Lower max players per server
   kubectl set env statefulset/game-server -n planetary-survival \
     MAX_PLAYERS_PER_SERVER=30
   ```

4. **Enable performance mode**:
   ```bash
   kubectl set env statefulset/game-server -n planetary-survival \
     ENABLE_PERFORMANCE_MODE=true
   ```

### Issue 5: Database Connection Failures

**Symptoms**:
```
Error: connection refused: cockroachdb-public:26257
```

**Debugging Steps**:

1. **Check CockroachDB pods**:
   ```bash
   kubectl get pods -n planetary-survival -l app=cockroachdb
   ```

2. **Check CockroachDB logs**:
   ```bash
   kubectl logs cockroachdb-0 -n planetary-survival | tail -100
   ```

3. **Test connection**:
   ```bash
   kubectl exec -it cockroachdb-0 -n planetary-survival -- \
     /cockroach/cockroach sql --insecure
   ```

**Solutions**:

```bash
# Restart CockroachDB pods
kubectl rollout restart statefulset/cockroachdb -n planetary-survival

# Check cluster status
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach node status --insecure

# Verify network policy
kubectl get networkpolicy -n planetary-survival
```

### Issue 6: Authority Transfer Failures

**Symptoms**:
- Players disconnect during region transitions
- High authority_transfer_failures metric
- Coordinator logs show errors

**Debugging Steps**:

1. **Check coordinator logs**:
   ```bash
   kubectl logs -n planetary-survival -l component=mesh-coordinator --tail=200
   ```

2. **Check gRPC connectivity**:
   ```bash
   # Test gRPC connection between servers
   kubectl exec game-server-0 -n planetary-survival -- \
     grpcurl -plaintext game-server-1:9090 list
   ```

3. **Check player state size**:
   ```bash
   # Large player states can cause transfer timeouts
   kubectl logs game-server-0 -n planetary-survival | grep "player_state_size"
   ```

**Solutions**:

```bash
# Increase transfer timeout
kubectl set env deployment/mesh-coordinator -n planetary-survival \
  AUTHORITY_TRANSFER_TIMEOUT_MS=5000

# Reduce player state size by compressing
kubectl set env statefulset/game-server -n planetary-survival \
  ENABLE_STATE_COMPRESSION=true

# Check network between servers
kubectl exec game-server-0 -n planetary-survival -- \
  ping game-server-1.game-server-headless
```

## Log Locations

### Game Server Logs

```bash
# Container logs
kubectl logs game-server-0 -n planetary-survival

# Follow logs in real-time
kubectl logs -f game-server-0 -n planetary-survival

# All game server logs
kubectl logs -n planetary-survival -l component=game-server --tail=50

# Persistent logs (if volume mounted)
kubectl exec game-server-0 -n planetary-survival -- ls /app/logs/
```

### Mesh Coordinator Logs

```bash
# Coordinator logs
kubectl logs -n planetary-survival -l component=mesh-coordinator --tail=100

# Specific coordinator instance
kubectl logs mesh-coordinator-7d8f9b5c-xyz -n planetary-survival
```

### Database Logs

```bash
# CockroachDB logs
kubectl logs cockroachdb-0 -n planetary-survival

# Query slow queries
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    SELECT * FROM crdb_internal.node_queries
    WHERE query_duration > '1s'"
```

### Redis Logs

```bash
# Redis logs
kubectl logs redis-0 -n planetary-survival

# Redis slowlog
kubectl exec redis-0 -n planetary-survival -- \
  redis-cli slowlog get 10
```

### Event Logs

```bash
# Kubernetes events (last hour)
kubectl get events -n planetary-survival \
  --sort-by='.lastTimestamp' | tail -50

# Warning events only
kubectl get events -n planetary-survival \
  --field-selector type=Warning
```

## Debug Procedures

### Enable Debug Logging

```bash
# Enable debug logs for game server
kubectl set env statefulset/game-server -n planetary-survival \
  LOG_LEVEL=debug \
  ENABLE_DEBUG_LOGS=true

# Restart to apply
kubectl rollout restart statefulset/game-server -n planetary-survival
```

### Interactive Debugging

```bash
# Shell into game server
kubectl exec -it game-server-0 -n planetary-survival -- /bin/bash

# Shell into coordinator
kubectl exec -it mesh-coordinator-xyz -n planetary-survival -- /bin/bash

# Run debug commands
ps aux  # Check running processes
netstat -tlnp  # Check listening ports
top  # Monitor resources
```

### Network Debugging

```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup game-server-headless.planetary-survival.svc.cluster.local

# Test connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- \
  tcpdump -i any port 7777

# Check latency
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  ping game-server-0.game-server-headless.planetary-survival.svc.cluster.local
```

### Database Debugging

```bash
# Check database health
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach node status --insecure

# Check replication
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    SELECT * FROM crdb_internal.cluster_replication_status"

# Check ranges
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    SELECT * FROM crdb_internal.ranges LIMIT 10"

# Vacuum database
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    VACUUM ANALYZE"
```

### Capture Network Traffic

```bash
# Install tcpdump on game server pod
kubectl exec game-server-0 -n planetary-survival -- \
  apt-get update && apt-get install -y tcpdump

# Capture traffic
kubectl exec game-server-0 -n planetary-survival -- \
  tcpdump -i any -w /tmp/capture.pcap port 7777

# Download capture
kubectl cp planetary-survival/game-server-0:/tmp/capture.pcap ./capture.pcap

# Analyze with Wireshark locally
wireshark capture.pcap
```

## Performance Tuning

### Game Server Optimization

```yaml
# Optimize resource allocation
resources:
  requests:
    cpu: "3000m"  # Increase CPU for better FPS
    memory: "6Gi"
  limits:
    cpu: "5000m"
    memory: "10Gi"

# Enable performance optimizations
env:
  - name: ENABLE_VR_OPTIMIZATIONS
    value: "true"
  - name: PHYSICS_THREADS
    value: "4"
  - name: RENDER_THREADS
    value: "2"
  - name: MAX_TERRAIN_CHUNKS
    value: "500"
```

### Database Optimization

```bash
# Increase connection pool
kubectl set env statefulset/game-server -n planetary-survival \
  DATABASE_MAX_CONNECTIONS=100

# Enable query caching
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    SET CLUSTER SETTING sql.query_cache.enabled = true"

# Adjust cache size
kubectl exec cockroachdb-0 -n planetary-survival -- \
  /cockroach/cockroach sql --insecure --execute="
    SET CLUSTER SETTING sql.query_cache.size = '256MiB'"
```

### Redis Optimization

```bash
# Adjust maxmemory policy
kubectl exec redis-0 -n planetary-survival -- \
  redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Disable persistence for cache-only use
kubectl exec redis-0 -n planetary-survival -- \
  redis-cli CONFIG SET save ""

# Enable lazy freeing
kubectl exec redis-0 -n planetary-survival -- \
  redis-cli CONFIG SET lazyfree-lazy-eviction yes
```

### Network Optimization

```bash
# Enable TCP BBR congestion control (on nodes)
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Increase network buffers
kubectl set env statefulset/game-server -n planetary-survival \
  NET_BUFFER_SIZE=4194304

# Enable compression
kubectl set env statefulset/game-server -n planetary-survival \
  ENABLE_NETWORK_COMPRESSION=true
```

### Node-Level Tuning

```bash
# Disable swap
sudo swapoff -a

# Increase file descriptors
echo "fs.file-max = 2097152" | sudo tee -a /etc/sysctl.conf
echo "fs.nr_open = 2097152" | sudo tee -a /etc/sysctl.conf

# Optimize network stack
echo "net.core.rmem_max = 134217728" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max = 134217728" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 87380 67108864" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 67108864" | sudo tee -a /etc/sysctl.conf

sudo sysctl -p
```

## Emergency Procedures

### Emergency Scale Down

```bash
# In case of resource exhaustion
./scripts/scale.sh production 5 game-server

# Disable auto-scaling temporarily
kubectl patch hpa game-server-hpa -n planetary-survival \
  --type=merge -p '{"spec":{"maxReplicas":5}}'
```

### Emergency Rollback

```bash
# Immediate rollback
./scripts/rollback.sh production

# Force delete stuck pods
kubectl delete pod game-server-0 -n planetary-survival --force --grace-period=0
```

### Emergency Maintenance Mode

```bash
# Block new player connections
kubectl scale ingress-controller --replicas=0

# Gracefully shutdown game servers
kubectl scale statefulset/game-server -n planetary-survival --replicas=0

# Perform maintenance...

# Restore service
kubectl scale statefulset/game-server -n planetary-survival --replicas=10
kubectl scale ingress-controller --replicas=3
```

## Getting Help

### Collect Diagnostics

```bash
# Create diagnostics bundle
kubectl cluster-info dump -n planetary-survival > cluster-dump.txt

# Collect all logs
for pod in $(kubectl get pods -n planetary-survival -o name); do
  kubectl logs $pod -n planetary-survival > ${pod}.log
done

# Export metrics
kubectl port-forward -n planetary-survival svc/prometheus 9090:9090 &
curl http://localhost:9090/api/v1/query?query=up > metrics.json
```

### Support Channels

- **Slack**: #planetary-survival-ops
- **Email**: ops@planetary-survival.example.com
- **On-call**: PagerDuty escalation policy
- **Documentation**: https://docs.planetary-survival.example.com
