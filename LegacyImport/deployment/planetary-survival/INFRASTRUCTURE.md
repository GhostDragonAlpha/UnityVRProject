# Planetary Survival - Infrastructure Architecture

This document describes the infrastructure architecture for the Planetary Survival VR multiplayer game with server meshing.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Component Descriptions](#component-descriptions)
3. [Network Topology](#network-topology)
4. [Security Model](#security-model)
5. [Storage Architecture](#storage-architecture)
6. [Monitoring Stack](#monitoring-stack)

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Load Balancer                           │
│                      (Ingress Controller)                       │
└────────────┬────────────────────────────────────┬───────────────┘
             │                                    │
    ┌────────▼────────┐                  ┌───────▼────────┐
    │  Game Servers   │                  │ Mesh Coordinator│
    │  (StatefulSet)  │◄────────────────►│  (Deployment)  │
    │   Replicas: 3+  │                  │   Replicas: 3  │
    └────────┬────────┘                  └───────┬────────┘
             │                                    │
             │          ┌────────────────────────┤
             │          │                        │
    ┌────────▼──────────▼───┐          ┌────────▼────────┐
    │    CockroachDB        │          │      Redis      │
    │    (StatefulSet)      │          │  (StatefulSet)  │
    │    Replicas: 3        │          │   Replicas: 3   │
    └───────────────────────┘          └─────────────────┘
             │                                    │
    ┌────────▼────────────────────────────────────▼───────┐
    │               Persistent Storage                     │
    │           (Fast SSD Storage Class)                   │
    └──────────────────────────────────────────────────────┘
             │
    ┌────────▼────────────────────────────────────────────┐
    │          Monitoring & Alerting                      │
    │      Prometheus + Grafana + AlertManager            │
    └─────────────────────────────────────────────────────┘
```

### Server Meshing Architecture

```
                    ┌────────────────────────┐
                    │  Mesh Coordinator      │
                    │  (Leader Election)     │
                    │  - Region Management   │
                    │  - Authority Transfer  │
                    │  - Load Balancing      │
                    └───────────┬────────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
        ┌───────▼──────┐ ┌─────▼──────┐ ┌─────▼──────┐
        │ Game Server  │ │ Game Server│ │ Game Server│
        │   Region A   │ │  Region B  │ │  Region C  │
        │  Players: 40 │ │ Players: 35│ │ Players: 42│
        └──────┬───────┘ └─────┬──────┘ └─────┬──────┘
               │               │               │
               │    100m Overlap Zones        │
               └───────────────┴───────────────┘
                    (Boundary Sync)

Region Structure:
- Default: 2000m³ cubic regions
- Minimum: 500m³ (after subdivision)
- Overlap: 100m border zones for seamless transfer
```

## Component Descriptions

### 1. Game Servers (StatefulSet)

**Purpose**: Host game instances and manage player sessions

**Specifications**:
- **Replicas**: 3-100 (auto-scaling)
- **Resources**: 2-4 CPU, 4-8GB RAM per pod
- **Storage**: 50GB persistent volume per server
- **Ports**:
  - 7777/UDP: Game traffic
  - 7778/TCP: Query port
  - 8080/TCP: HTTP API
  - 8081/TCP: Telemetry
  - 9090/TCP: gRPC inter-server

**Key Features**:
- VR-optimized (90 FPS target)
- Voxel terrain with procedural generation
- Real-time physics simulation
- Player state synchronization
- Authority handoff support

**Auto-Scaling Triggers**:
- CPU > 70%
- Memory > 75%
- Active players > 40 per server
- Average FPS < 88

**Health Checks**:
- Liveness: HTTP GET /health every 30s
- Readiness: HTTP GET /ready every 10s

### 2. Mesh Coordinator (Deployment)

**Purpose**: Manage distributed server mesh and region assignments

**Specifications**:
- **Replicas**: 3-10 (with leader election)
- **Resources**: 1-2 CPU, 2-4GB RAM per pod
- **Ports**:
  - 8080/TCP: HTTP API
  - 9090/TCP: gRPC
  - 7946/TCP: Gossip protocol

**Key Responsibilities**:
- Region assignment and subdivision
- Player authority transfer
- Load balancing across servers
- Server health monitoring
- Failure detection and recovery

**Leader Election**:
- Uses Raft consensus protocol
- Automatic failover < 5 seconds
- Distributed state in CockroachDB

### 3. CockroachDB (StatefulSet)

**Purpose**: Distributed SQL database for game state

**Specifications**:
- **Replicas**: 3-5 nodes
- **Resources**: 2-4 CPU, 8-16GB RAM per node
- **Storage**: 100-200GB per node
- **Replication**: 3x (default)

**Data Stored**:
- Player accounts and progression
- World modifications (deltas from procedural)
- Base structures and automation
- Server mesh topology
- Authority transfer logs

**Consistency Model**:
- Serializable isolation
- Multi-region support
- Automatic rebalancing

### 4. Redis (StatefulSet)

**Purpose**: Caching and pub/sub for real-time events

**Specifications**:
- **Replicas**: 3 (master + 2 replicas)
- **Resources**: 0.5-1 CPU, 2-4GB RAM per node
- **Storage**: 20GB per node
- **Sentinel**: Enabled for automatic failover

**Use Cases**:
- Player session cache
- Region boundary entity cache
- Real-time event broadcasting
- Rate limiting
- Leaderboards

**Persistence**:
- RDB snapshots every 60s
- AOF for durability

### 5. Monitoring Stack

#### Prometheus

**Purpose**: Metrics collection and alerting

**Specifications**:
- **Resources**: 1-2 CPU, 4-8GB RAM
- **Storage**: 100GB (30-90 day retention)
- **Scrape Interval**: 15s

**Metrics Collected**:
- Server CPU/Memory usage
- Active players per server
- FPS and frame time
- Network bandwidth
- Authority transfer latency
- Database query performance
- Cache hit rates

#### Grafana

**Purpose**: Visualization and dashboards

**Specifications**:
- **Resources**: 0.5-1 CPU, 1-2GB RAM
- **Storage**: 10GB

**Dashboards**:
1. **Cluster Overview**: Total players, servers, regions
2. **Server Performance**: CPU, memory, FPS per server
3. **Network Metrics**: Bandwidth, latency, packet loss
4. **Database Health**: Query times, connection pools
5. **Player Distribution**: Heatmap of player density
6. **Authority Transfers**: Transfer times, success rate

#### AlertManager

**Purpose**: Alert routing and notification

**Alert Severities**:
- **Critical**: Immediate attention (PagerDuty)
- **Warning**: Investigate within 1 hour (Slack)
- **Info**: For awareness (Slack)

**Alert Rules**:
- Server down > 1 minute → Critical
- High CPU > 80% for 5 min → Warning
- Low FPS < 85 for 2 min → Critical
- Database connection errors → Critical
- High latency > 15ms → Warning

## Network Topology

### Internal Network (ClusterIP)

```
planetary-survival namespace:
├── game-server-headless (7777/UDP, 7778/TCP, 8080/TCP, 9090/TCP)
├── mesh-coordinator (8080/TCP, 9090/TCP)
├── cockroachdb-public (26257/TCP, 8080/TCP)
└── redis-master (6379/TCP)
```

### External Network (LoadBalancer/Ingress)

```
Internet
    │
    ├──► https://planetary-survival.example.com
    │    └──► Ingress → game-server-lb:7777/UDP
    │
    ├──► https://api.planetary-survival.example.com
    │    └──► Ingress → game-server-headless:8080
    │
    ├──► https://coordinator.planetary-survival.example.com
    │    └──► Ingress → mesh-coordinator:8080
    │
    └──► https://monitoring.planetary-survival.example.com
         ├──► /grafana → grafana:3000
         └──► /prometheus → prometheus:9090
```

### Network Policies

**Game Server Policy**:
```yaml
Ingress:
  - From: mesh-coordinator (8080, 9090)
  - From: ingress-controller (8080)
  - From: anywhere (7777/UDP, 7778/TCP)

Egress:
  - To: cockroachdb (26257)
  - To: redis (6379)
  - To: mesh-coordinator (8080, 9090)
  - To: other-game-servers (9090)
  - To: DNS (53)
```

**Mesh Coordinator Policy**:
```yaml
Ingress:
  - From: game-servers (8080, 9090)
  - From: other-coordinators (7946)

Egress:
  - To: cockroachdb (26257)
  - To: redis (6379)
  - To: game-servers (9090)
  - To: DNS (53)
```

## Security Model

### Authentication & Authorization

**Game Servers**:
- JWT tokens for player authentication
- API keys for HTTP API access
- Inter-server mTLS (optional)

**Mesh Coordinator**:
- Bearer token authentication
- RBAC for Kubernetes API access
- Server-to-server shared secret

**Database**:
- Username/password authentication
- Client certificates (production)
- Network policies restricting access

### Encryption

**In Transit**:
- TLS 1.3 for all external connections
- gRPC with TLS for inter-server communication
- Optional: mTLS for game-to-game traffic

**At Rest**:
- Encrypted persistent volumes (cloud provider)
- Application-level encryption for sensitive data
- Encrypted database backups

### Secrets Management

**Development**:
- Kubernetes Secrets (base64 encoded)

**Production**:
- External secrets operator (recommended)
- HashiCorp Vault integration
- Cloud provider secret managers (AWS Secrets Manager, GCP Secret Manager)

### Pod Security

**Security Context**:
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
```

**Pod Disruption Budgets**:
- Ensures minimum availability during updates
- game-server: minAvailable: 2
- mesh-coordinator: minAvailable: 2

## Storage Architecture

### Storage Classes

**fast-ssd** (Primary):
```yaml
provisioner: ebs.csi.aws.com  # or equivalent
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

### Persistent Volume Claims

**Game Server** (per pod):
- Size: 50GB
- Access: ReadWriteOnce
- Content: World data, player saves, cache

**CockroachDB** (per pod):
- Size: 100-200GB
- Access: ReadWriteOnce
- Content: Database files

**Redis** (per pod):
- Size: 20GB
- Access: ReadWriteOnce
- Content: RDB dumps, AOF logs

**Prometheus**:
- Size: 100GB
- Access: ReadWriteOnce
- Content: Time-series metrics

**Grafana**:
- Size: 10GB
- Access: ReadWriteOnce
- Content: Dashboards, datasources

### Backup Strategy

**Automated Backups**:
```bash
# Daily database backup (CronJob)
schedule: "0 2 * * *"  # 2 AM daily
retention: 30 days
storage: S3/GCS bucket

# Weekly full backup
schedule: "0 1 * * 0"  # Sunday 1 AM
retention: 90 days

# Pre-deployment backup
trigger: Before production deployments
retention: 7 days
```

**Backup Locations**:
- Primary: Cloud object storage (S3/GCS)
- Secondary: Different region
- Tertiary: On-premise (optional)

## Monitoring Stack

### Metrics Collection

**Node Exporter**:
- Collect node-level metrics
- CPU, memory, disk, network

**kube-state-metrics**:
- Kubernetes object metrics
- Pod, deployment, service status

**Game Server Metrics**:
```
# Godot-specific metrics
server_fps_avg
server_cpu_usage
server_memory_mb
active_players
active_regions
terrain_chunks_loaded
physics_step_ms

# Network metrics
bytes_sent_total
bytes_received_total
packets_dropped_total
avg_inter_server_latency_ms

# Authority transfer
authority_transfer_count
authority_transfer_duration_ms
authority_transfer_failures
```

### Log Aggregation

**Log Collection**:
- Fluentd/Fluent Bit for log shipping
- Elasticsearch for log storage (optional)
- Kibana for log visualization (optional)

**Log Levels**:
- ERROR: Service failures, exceptions
- WARN: Performance issues, high latency
- INFO: Authority transfers, player joins
- DEBUG: Detailed operation logs (dev only)

### Distributed Tracing

**OpenTelemetry** (optional):
- Trace authority transfers
- Track player join flow
- Identify bottlenecks

## Disaster Recovery

### RTO/RPO Targets

| Component | RTO | RPO |
|-----------|-----|-----|
| Game Servers | 5 minutes | 0 (stateless) |
| Mesh Coordinator | 30 seconds | 0 (ephemeral) |
| CockroachDB | 5 minutes | 1 hour |
| Redis | 1 minute | 15 minutes |

### Failure Scenarios

**Single Server Failure**:
1. Coordinator detects failure (5s)
2. Marks server as unavailable
3. Migrates players to adjacent regions
4. Promotes backup region

**Coordinator Failure**:
1. Raft detects leader loss
2. Elects new leader (<5s)
3. New leader resumes operations
4. No player impact

**Database Node Failure**:
1. CockroachDB detects failure
2. Automatic rebalancing
3. Queries redirected to healthy nodes
4. Performance may degrade temporarily

**Complete Region Failure**:
1. Multi-region deployment
2. Traffic routed to healthy region
3. Data replicated across regions
4. RTO: 15 minutes

## Capacity Planning

### Scaling Calculations

**Per Game Server**:
- Max players: 50
- Regions: 1-3
- CPU: 2-4 cores (90 FPS requirement)
- Memory: 4-8GB
- Network: 20Mbps per player

**Example: 1000 Players**:
- Game servers needed: 20-25
- Coordinators: 3-5
- Database nodes: 3-5
- Redis nodes: 3
- Total CPU: ~60 cores
- Total Memory: ~160GB
- Total bandwidth: ~20Gbps

### Cost Estimation

**AWS Example (us-east-1)**:
```
Compute:
- 25x c5.2xlarge (8 vCPU, 16GB): $0.34/hr × 25 = $8.50/hr
- 5x t3.xlarge (4 vCPU, 16GB): $0.166/hr × 5 = $0.83/hr
Total compute: $9.33/hr (~$6,720/month)

Storage:
- 2TB gp3 SSD: $160/month

Load Balancer:
- Network Load Balancer: $16.20/month + data transfer

Data Transfer:
- Assume 10TB/month: $900/month

Total: ~$7,800/month (1000 concurrent players)
```

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [CockroachDB Documentation](https://www.cockroachlabs.com/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
