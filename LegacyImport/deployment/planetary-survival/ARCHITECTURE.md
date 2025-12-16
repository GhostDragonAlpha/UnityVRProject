# Planetary Survival - Architecture Diagrams

This document provides visual representations of the Planetary Survival deployment architecture.

## Table of Contents

1. [System Overview](#system-overview)
2. [Server Meshing Architecture](#server-meshing-architecture)
3. [Network Flow](#network-flow)
4. [Data Flow](#data-flow)
5. [Scaling Architecture](#scaling-architecture)

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INTERNET / PLAYERS                                 │
└─────────────────────────────┬───────────────────────────────────────────────┘
                              │
                              │ HTTPS/TLS, UDP
                              │
┌─────────────────────────────▼───────────────────────────────────────────────┐
│                         LOAD BALANCER LAYER                                  │
│  ┌─────────────────────┐  ┌─────────────────┐  ┌──────────────────────┐   │
│  │  Network LB (UDP)   │  │  Ingress (HTTP) │  │  cert-manager (TLS)  │   │
│  │   Game Traffic      │  │   API/Metrics   │  │  Auto cert renewal   │   │
│  └─────────┬───────────┘  └────────┬────────┘  └──────────────────────┘   │
└────────────┼──────────────────────┼────────────────────────────────────────┘
             │                      │
             │                      │
┌────────────▼──────────────────────▼────────────────────────────────────────┐
│                        APPLICATION LAYER                                     │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────┐       │
│  │              GAME SERVERS (StatefulSet)                          │       │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ...  ┌───┐   │       │
│  │  │Game Server │  │Game Server │  │Game Server │        │...│   │       │
│  │  │    Pod 0   │  │    Pod 1   │  │    Pod 2   │        │100│   │       │
│  │  │            │  │            │  │            │        └───┘   │       │
│  │  │Region: A   │  │Region: B   │  │Region: C   │                │       │
│  │  │Players: 45 │  │Players: 38 │  │Players: 42 │                │       │
│  │  │CPU: 3.2    │  │CPU: 2.8    │  │CPU: 3.5    │                │       │
│  │  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘                │       │
│  └────────┼───────────────┼───────────────┼────────────────────────┘       │
│           │               │               │                                 │
│           │               │               │ gRPC                            │
│  ┌────────▼───────────────▼───────────────▼────────────────────────┐       │
│  │           MESH COORDINATOR (Deployment)                          │       │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │       │
│  │  │Coordinator 0 │  │Coordinator 1 │  │Coordinator 2 │          │       │
│  │  │  (Leader)    │  │  (Follower)  │  │  (Follower)  │          │       │
│  │  │              │◄─┤              │◄─┤              │          │       │
│  │  │ Raft Leader  │  │              │  │              │          │       │
│  │  │ Election     │  │              │  │              │          │       │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │       │
│  └─────────┼──────────────────┼──────────────────┼──────────────────┘       │
└────────────┼──────────────────┼──────────────────┼──────────────────────────┘
             │                  │                  │
             │                  │                  │
┌────────────▼──────────────────▼──────────────────▼──────────────────────────┐
│                           DATA LAYER                                         │
│                                                                              │
│  ┌───────────────────────────────────┐  ┌──────────────────────────────┐   │
│  │    CockroachDB (StatefulSet)      │  │    Redis (StatefulSet)       │   │
│  │  ┌────────┐  ┌────────┐  ┌────┐  │  │  ┌─────┐  ┌─────┐  ┌─────┐  │   │
│  │  │ Node 0 │◄─┤ Node 1 │◄─┤ N2 │  │  │  │Mstr │◄─┤Repl1│◄─┤Repl2│  │   │
│  │  │Primary │  │Secondary  │Sec │  │  │  └──┬──┘  └─────┘  └─────┘  │   │
│  │  │        │  │           │    │  │  │     │                        │   │
│  │  │Raft    │  │Raft       │Raft│  │  │  ┌──▼──────────────────┐   │   │
│  │  │Replica │  │Replica    │Rep │  │  │  │  Sentinel (HA)      │   │   │
│  │  └───┬────┘  └───┬───────┘────┘  │  │  │  Auto-Failover      │   │   │
│  └──────┼───────────┼───────────────┘  │  └─────────────────────┘   │   │
│         │           │                   │                             │   │
│  ┌──────▼───────────▼──────────────┐   └─────────────────────────────┘   │
│  │  Persistent Volumes (Fast SSD)  │                                      │
│  │  - World Data: 50GB × N servers │                                      │
│  │  - Database: 100-200GB × nodes  │                                      │
│  │  - Redis: 20GB × nodes          │                                      │
│  │  - Backups: Daily to S3/GCS     │                                      │
│  └─────────────────────────────────┘                                      │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                       OBSERVABILITY LAYER                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │
│  │  Prometheus  │  │   Grafana    │  │ AlertManager │                  │
│  │  (Metrics)   │  │ (Dashboards) │  │  (Alerts)    │                  │
│  │              │  │              │  │              │                  │
│  │ 15s scrape   │◄─┤ Visualize    │  │ PagerDuty    │                  │
│  │ 30d retention│  │ Query        │  │ Slack        │                  │
│  └──────────────┘  └──────────────┘  └──────────────┘                  │
└──────────────────────────────────────────────────────────────────────────┘
```

## Server Meshing Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      VIRTUAL WORLD SPACE                                 │
│                     (Infinite Procedural Universe)                       │
│                                                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │  Region A   │  │  Region B   │  │  Region C   │  │  Region D   │  │
│  │  2000m³     │  │  2000m³     │  │  2000m³     │  │  2000m³     │  │
│  │             │  │             │  │             │  │             │  │
│  │ Server: 0   │  │ Server: 1   │  │ Server: 2   │  │ Server: 3   │  │
│  │ Players: 45 │  │ Players: 38 │  │ Players: 42 │  │ Players: 12 │  │
│  │ CPU: 85%    │  │ CPU: 72%    │  │ CPU: 88%    │  │ CPU: 35%    │  │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  │
│         │                │                │                │          │
│         │    100m        │    100m        │    100m        │          │
│         │  Overlap       │  Overlap       │  Overlap       │          │
│         │    Zone        │    Zone        │    Zone        │          │
│         └────────────────┴────────────────┴────────────────┘          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                               │
                               │ Coordinates
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   MESH COORDINATOR                                       │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────┐          │
│  │            Region Assignment Map                         │          │
│  │  Region ID  │  Server ID  │  Players  │  CPU  │ Status  │          │
│  │─────────────┼─────────────┼───────────┼───────┼─────────│          │
│  │  (0,0,0)    │  0          │  45       │  85%  │ Active  │          │
│  │  (2000,0,0) │  1          │  38       │  72%  │ Active  │          │
│  │  (4000,0,0) │  2          │  42       │  88%  │ HOT!    │          │
│  │  (6000,0,0) │  3          │  12       │  35%  │ Active  │          │
│  └──────────────────────────────────────────────────────────┘          │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────┐          │
│  │               Load Balancing Logic                       │          │
│  │                                                           │          │
│  │  IF region.cpu > 70% AND region.players > 40:           │          │
│  │    TRIGGER: Subdivide region                            │          │
│  │    ACTION: Split into 8 sub-regions (1000m³ each)       │          │
│  │    ASSIGN: Sub-regions to available servers             │          │
│  │                                                           │          │
│  │  IF adjacent_regions.cpu < 30% AND total_players < 20:  │          │
│  │    TRIGGER: Merge regions                               │          │
│  │    ACTION: Combine into single region                   │          │
│  │    ASSIGN: Merged region to single server               │          │
│  └──────────────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                  AUTHORITY TRANSFER FLOW                                 │
│                                                                          │
│  Player moves from Region A to Region B:                                │
│                                                                          │
│  Step 1: Player approaches boundary                                     │
│  ┌─────────────┐                    ┌─────────────┐                    │
│  │  Region A   │   100m Overlap     │  Region B   │                    │
│  │  Server 0   │◄──────────────────►│  Server 1   │                    │
│  │             │                    │             │                    │
│  │  Player @   │                    │             │                    │
│  │  (1950,0,0) │                    │             │                    │
│  └─────────────┘                    └─────────────┘                    │
│                                                                          │
│  Step 2: Enter overlap zone - player visible to both servers            │
│  ┌─────────────┐                    ┌─────────────┐                    │
│  │  Region A   │   Player in        │  Region B   │                    │
│  │  Server 0   │   overlap zone     │  Server 1   │                    │
│  │             │                    │             │                    │
│  │          @──┼────────────────────┤             │                    │
│  │  (2050,0,0) │                    │             │                    │
│  └─────────────┘                    └─────────────┘                    │
│        │                                   │                            │
│        └──────► Coordinate transfer ◄─────┘                            │
│                                                                          │
│  Step 3: Authority transferred to Server 1                              │
│  ┌─────────────┐                    ┌─────────────┐                    │
│  │  Region A   │                    │  Region B   │                    │
│  │  Server 0   │                    │  Server 1   │                    │
│  │             │                    │             │                    │
│  │             │                    │  @ Player   │                    │
│  │             │                    │  (2150,0,0) │                    │
│  └─────────────┘                    └─────────────┘                    │
│                                            │                            │
│                                    Authority owner                      │
│                                                                          │
│  Target: Transfer complete in < 100ms                                   │
│  Player never disconnects, seamless transition                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Network Flow

```
┌───────────────┐
│   Player      │
│   (VR Client) │
└───────┬───────┘
        │ UDP 7777 (Game Traffic)
        │ TCP 7778 (Query Port)
        │
        ▼
┌──────────────────────────────────┐
│   Network Load Balancer          │
│   - UDP passthrough              │
│   - Session affinity (ClientIP)  │
│   - Health checks                │
└───────┬──────────────────────────┘
        │
        ▼
┌──────────────────────────────────┐
│   Game Server Pod                │
│   ┌────────────────────────────┐ │
│   │  Game Server Container     │ │
│   │  - Port 7777/UDP: Game     │ │
│   │  - Port 7778/TCP: Query    │ │
│   │  - Port 8080/TCP: HTTP API │ │
│   │  - Port 9090/TCP: gRPC     │ │
│   └────────┬───────────────────┘ │
└────────────┼─────────────────────┘
             │
             ├────► TCP 26257 ────► CockroachDB (Player data)
             │
             ├────► TCP 6379 ─────► Redis (Cache, Pub/Sub)
             │
             ├────► TCP 8080 ─────► Mesh Coordinator (Region updates)
             │
             └────► TCP 9090 ─────► Other Game Servers (Inter-server)

┌───────────────────────────────────────────────────────────────┐
│              INTERNAL SERVICE MESH                             │
│                                                                │
│  game-server-headless.planetary-survival.svc.cluster.local    │
│  ├─ game-server-0.game-server-headless:9090                   │
│  ├─ game-server-1.game-server-headless:9090                   │
│  └─ game-server-N.game-server-headless:9090                   │
│                                                                │
│  mesh-coordinator.planetary-survival.svc.cluster.local        │
│  ├─ mesh-coordinator-0:8080 (Leader)                          │
│  ├─ mesh-coordinator-1:8080 (Follower)                        │
│  └─ mesh-coordinator-2:8080 (Follower)                        │
│                                                                │
│  cockroachdb-public.planetary-survival.svc.cluster.local      │
│  └─ Load-balanced across all CockroachDB nodes               │
│                                                                │
│  redis-master.planetary-survival.svc.cluster.local            │
│  └─ Master node (Sentinel manages failover)                  │
└───────────────────────────────────────────────────────────────┘
```

## Data Flow

```
┌────────────────────────────────────────────────────────────────────┐
│                     PLAYER ACTION                                   │
│              (e.g., Dig terrain, place structure)                   │
└────────────────────────────┬───────────────────────────────────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │   Game Server        │
                  │   (Authority owner)  │
                  └──────────┬───────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
           ▼                 ▼                 ▼
  ┌────────────────┐ ┌──────────────┐ ┌──────────────┐
  │ Local State    │ │ Broadcast to │ │ Persist to   │
  │ Update         │ │ Nearby       │ │ Database     │
  │ (Immediate)    │ │ Players      │ │ (Async)      │
  └────────────────┘ └──────┬───────┘ └──────┬───────┘
                            │                │
                            │                │
                            ▼                ▼
                  ┌──────────────────┐ ┌──────────────┐
                  │ Inter-Server     │ │ CockroachDB  │
                  │ Communication    │ │              │
                  │ (gRPC)           │ │ Store delta  │
                  └──────────────────┘ └──────────────┘
                            │
                            ▼
                  ┌──────────────────┐
                  │ Adjacent Servers │
                  │ (Overlap zones)  │
                  └──────────────────┘
                            │
                            ▼
                  ┌──────────────────┐
                  │ Players in       │
                  │ Boundary Zone    │
                  └──────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│                   DATABASE WRITE FLOW                               │
│                                                                     │
│  Game Server                                                        │
│      │                                                              │
│      │ 1. Batch modifications (100ms buffer)                       │
│      ▼                                                              │
│  ┌──────────────┐                                                  │
│  │ Write Buffer │                                                  │
│  └──────┬───────┘                                                  │
│         │ 2. Compress delta                                        │
│         ▼                                                           │
│  ┌──────────────┐                                                  │
│  │ Compression  │ (zstd)                                           │
│  └──────┬───────┘                                                  │
│         │ 3. Async write                                           │
│         ▼                                                           │
│  ┌──────────────────────────────────┐                             │
│  │      CockroachDB Cluster         │                             │
│  │  ┌──────┐  ┌──────┐  ┌──────┐  │                             │
│  │  │Node 0│  │Node 1│  │Node 2│  │                             │
│  │  └───┬──┘  └───┬──┘  └───┬──┘  │                             │
│  │      │         │         │      │                             │
│  │      └────┬────┴────┬────┘      │                             │
│  │           │ Raft    │           │                             │
│  │           │ Repl    │           │                             │
│  │           ▼         ▼           │                             │
│  │      Replicated to 3 nodes      │                             │
│  └──────────────────────────────────┘                             │
│         │ 4. Acknowledge                                           │
│         ▼                                                           │
│  ┌──────────────┐                                                  │
│  │ Game Server  │                                                  │
│  │ (Confirmed)  │                                                  │
│  └──────────────┘                                                  │
└────────────────────────────────────────────────────────────────────┘
```

## Scaling Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                   AUTO-SCALING DECISION TREE                        │
│                                                                     │
│                    ┌───────────────┐                               │
│                    │  HPA Monitor  │                               │
│                    │  (Every 15s)  │                               │
│                    └───────┬───────┘                               │
│                            │                                        │
│              ┌─────────────┼─────────────┐                         │
│              │             │             │                         │
│              ▼             ▼             ▼                         │
│       ┌───────────┐ ┌───────────┐ ┌───────────┐                  │
│       │CPU > 70%  │ │Mem > 75%  │ │Players>40 │                  │
│       └─────┬─────┘ └─────┬─────┘ └─────┬─────┘                  │
│             │             │             │                         │
│             └─────────────┼─────────────┘                         │
│                           │ Any trigger?                          │
│                           ▼                                        │
│                    ┌──────────────┐                               │
│                    │ YES: Scale Up│                               │
│                    └──────┬───────┘                               │
│                           │                                        │
│                           ▼                                        │
│              ┌────────────────────────┐                           │
│              │ Create new Game Server │                           │
│              └────────┬───────────────┘                           │
│                       │                                            │
│         ┌─────────────┼─────────────┐                             │
│         │             │             │                             │
│         ▼             ▼             ▼                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                          │
│  │Provision │ │Initialize│ │Register  │                          │
│  │   Pod    │ │   Data   │ │with Mesh │                          │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘                          │
│       │            │            │                                 │
│       └────────────┴────────────┘                                 │
│                    │                                               │
│                    ▼                                               │
│           ┌─────────────────┐                                     │
│           │  Server Ready   │                                     │
│           │  (30s target)   │                                     │
│           └─────────────────┘                                     │
│                    │                                               │
│                    ▼                                               │
│           ┌─────────────────┐                                     │
│           │ Coordinator     │                                     │
│           │ Assigns Regions │                                     │
│           └─────────────────┘                                     │
└────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│                   CLUSTER AUTOSCALER                                │
│                                                                     │
│  Node Pool: game-servers                                           │
│  Min: 10 nodes                                                     │
│  Max: 100 nodes                                                    │
│                                                                     │
│  Triggers:                                                         │
│  ├─ Pending pods (can't schedule due to resources)                │
│  ├─ Node CPU > 80% across all nodes                               │
│  └─ Node memory > 85% across all nodes                            │
│                                                                     │
│  Scale Up:                                                         │
│  ├─ Add 10% more nodes                                            │
│  ├─ Max 5 nodes per scale event                                   │
│  └─ Complete in 3-5 minutes                                       │
│                                                                     │
│  Scale Down:                                                       │
│  ├─ Remove underutilized nodes (< 50% for 10 min)                 │
│  ├─ Drain pods gracefully                                         │
│  ├─ Wait 10 minutes stabilization                                 │
│  └─ Never scale below minimum                                     │
└────────────────────────────────────────────────────────────────────┘
```

## Component Interaction Diagram

```
Player Join Flow:
─────────────────

┌──────┐         ┌──────┐         ┌──────┐         ┌──────┐
│Client│         │ LB   │         │Server│         │Coord │
└───┬──┘         └───┬──┘         └───┬──┘         └───┬──┘
    │                │                │                │
    │ 1. Join Request│                │                │
    ├───────────────►│                │                │
    │                │ 2. Route to    │                │
    │                │    Server      │                │
    │                ├───────────────►│                │
    │                │                │ 3. Query Region│
    │                │                ├───────────────►│
    │                │                │ 4. Assign      │
    │                │                │    Region      │
    │                │                │◄───────────────┤
    │                │                │                │
    │                │                │ 5. Load World  │
    │                │                │    Data        │
    │                │                ├───────►┐       │
    │                │                │        │(DB)   │
    │                │                │◄───────┘       │
    │                │ 6. Send World  │                │
    │                │    State       │                │
    │◄───────────────┴────────────────┤                │
    │                                 │                │
    │ 7. Player active in Region      │                │
    │◄────────────────────────────────┤                │
    │                                 │                │
```

---

For more details, see:
- [INFRASTRUCTURE.md](INFRASTRUCTURE.md) - Detailed component descriptions
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment procedures
- [README.md](README.md) - Quick start guide
