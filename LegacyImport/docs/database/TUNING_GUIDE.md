# Database Performance Tuning Guide

**Version:** 1.0
**Last Updated:** 2024-12-02
**Target:** CockroachDB + Redis for Planetary Survival

## Table of Contents

1. [Quick Start](#quick-start)
2. [CockroachDB Tuning](#cockroachdb-tuning)
3. [Redis Tuning](#redis-tuning)
4. [Connection Pool Optimization](#connection-pool-optimization)
5. [Query Optimization](#query-optimization)
6. [Cache Strategy Optimization](#cache-strategy-optimization)
7. [Monitoring and Diagnostics](#monitoring-and-diagnostics)
8. [Production Deployment](#production-deployment)

---

## Quick Start

### Performance Targets Checklist

- [ ] P95 latency <10ms
- [ ] P99 latency <50ms
- [ ] Cache hit rate >90%
- [ ] Support 10,000 concurrent players
- [ ] Connection pool no saturation
- [ ] Zero data loss under failover

### Common Issues Quick Reference

| Symptom | Likely Cause | Quick Fix |
|---------|--------------|-----------|
| High P95 latency (>10ms) | Insufficient indexes | Add missing indexes (see below) |
| Low cache hit rate (<90%) | Short TTL or small cache | Increase Redis maxmemory or TTL |
| Connection timeouts | Small pool size | Increase pool_size parameter |
| Slow spatial queries | Missing spatial index | Create composite spatial index |
| Memory pressure on Redis | Too many cached keys | Tune eviction policy |
| Write latency spikes | Transaction conflicts | Reduce transaction scope |

---

## CockroachDB Tuning

### 1. Index Optimization

#### Essential Indexes

The schema already includes basic indexes. Add these if missing:

```sql
-- Spatial query optimization (critical for performance)
CREATE INDEX IF NOT EXISTS regions_spatial_idx ON regions (region_x, region_y, region_z);

-- Entity lookups by region
CREATE INDEX IF NOT EXISTS entities_region_idx ON entities (region_id);
CREATE INDEX IF NOT EXISTS entities_region_type_idx ON entities (region_id, entity_type);

-- Player lookups
CREATE INDEX IF NOT EXISTS players_username_idx ON players (username);
CREATE INDEX IF NOT EXISTS players_region_idx ON players (region_id);

-- Time-based queries
CREATE INDEX IF NOT EXISTS entities_updated_idx ON entities (updated_at);
CREATE INDEX IF NOT EXISTS players_last_login_idx ON players (last_login);
```

#### Advanced Indexes for High-Load Scenarios

```sql
-- Covering index for common player queries (avoid table lookup)
CREATE INDEX IF NOT EXISTS players_covering_idx ON players (
    username
) STORING (
    region_id, position_x, position_y, position_z
);

-- Partial index for active players only
CREATE INDEX IF NOT EXISTS players_active_idx ON players (last_login)
WHERE last_login > NOW() - INTERVAL '1 hour';

-- Spatial range query optimization with GiST
-- (Note: CockroachDB doesn't support GiST, use composite index instead)
CREATE INDEX IF NOT EXISTS regions_spatial_composite_idx ON regions (
    region_x, region_y, region_z, is_active
) WHERE is_active = TRUE;
```

#### Verify Index Usage

```sql
-- Check if queries are using indexes
EXPLAIN (ANALYZE) SELECT * FROM regions
WHERE region_x >= 0 AND region_x <= 10
  AND region_y >= 0 AND region_y <= 10
  AND region_z >= 0 AND region_z <= 10;

-- Look for "index scan" in output, not "sequential scan"
```

### 2. Table Partitioning

For very large deployments (>1 million regions), partition tables by spatial hash:

```sql
-- Create partitioned regions table
CREATE TABLE regions_partitioned (
    region_id VARCHAR(64) PRIMARY KEY,
    region_x INT NOT NULL,
    region_y INT NOT NULL,
    region_z INT NOT NULL,
    owner_server_id INT NOT NULL,
    last_modified TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    player_count INT DEFAULT 0,
    entity_count INT DEFAULT 0
) PARTITION BY HASH (region_x) PARTITIONS 16;
```

### 3. Connection Settings

Add to CockroachDB startup or config file:

```bash
# cockroachdb.conf (create if doesn't exist)

# Increase connection limit
--max-sql-memory=512MiB

# Optimize for read-heavy workload
--cache=256MiB
--max-sql-memory=512MiB

# Transaction settings
--kv.transaction.max_refresh_spans_bytes=256000

# Reduce lock contention
--kv.allocator.range_rebalance_threshold=0.05
```

### 4. Query Optimization

#### Use Prepared Statements

Modify `state_manager.py` to use prepared statements for frequently executed queries:

```python
# In StateManager.__init__():
self.prepared_statements = {}

# Prepare common queries once
with self.get_connection() as conn:
    with conn.cursor() as cur:
        cur.execute("PREPARE get_region AS SELECT * FROM regions WHERE region_id = $1")
        cur.execute("PREPARE get_player AS SELECT * FROM players WHERE username = $1")
```

#### Batch Operations

Always use batch operations when possible:

```python
# GOOD: Batch insert
sm.batch_create_entities(entities)  # One transaction

# BAD: Individual inserts
for entity in entities:
    sm.create_entity(entity)  # N transactions
```

### 5. Transaction Optimization

#### Reduce Transaction Size

```python
# GOOD: Small, focused transactions
with self.get_connection() as conn:
    with conn.cursor() as cur:
        cur.execute("UPDATE regions SET player_count = %s WHERE region_id = %s",
                   (count, region_id))

# BAD: Large, long-running transactions
with self.get_connection() as conn:
    # Many operations...
    # Holds locks too long
```

#### Use Appropriate Isolation Levels

```python
# For read-heavy workloads
conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_READ_COMMITTED)

# For consistency-critical operations
conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_SERIALIZABLE)
```

---

## Redis Tuning

### 1. Memory Management

#### Increase Max Memory (Production)

```conf
# redis.conf
maxmemory 4gb  # Increase from 512mb for production

# Use LRU eviction for game cache
maxmemory-policy allkeys-lru
```

#### Monitor Memory Usage

```bash
# Check Redis memory stats
redis-cli INFO memory

# Check eviction stats
redis-cli INFO stats | grep evicted_keys
```

### 2. Persistence Tuning

#### For Cache-Only (Fastest)

```conf
# redis.conf - Disable persistence if cache-only
save ""
appendonly no
```

#### For Durable Cache (Recommended)

```conf
# redis.conf - Balance performance and durability
save 900 1
save 300 10
save 60 10000

appendonly yes
appendfsync everysec  # Not no-fsync (too risky), not always (too slow)
```

### 3. Network Optimization

```conf
# redis.conf
tcp-backlog 511
tcp-keepalive 300
timeout 0

# Increase max clients for high concurrency
maxclients 20000
```

### 4. Cache Key Design

#### Use Hierarchical Keys

```python
# GOOD: Hierarchical, easy to invalidate
"ps:region:0_0_0"
"ps:player:username123"
"ps:region_entities:0_0_0"

# BAD: Flat namespace
"region_0_0_0"
"username123"
```

#### Set Appropriate TTLs

```python
# Hot data (frequently accessed) - longer TTL
self.redis_client.setex("ps:region:0_0_0", 600, data)  # 10 minutes

# Cold data (rarely accessed) - shorter TTL
self.redis_client.setex("ps:entity:uuid", 60, data)  # 1 minute

# Session data - moderate TTL
self.redis_client.setex("ps:player:session", 300, data)  # 5 minutes
```

### 5. Cache Warming

Pre-populate cache with frequently accessed data:

```python
def warm_cache(self):
    """Warm Redis cache with hot data."""
    # Cache spawn region and nearby regions
    spawn_regions = self.get_regions_in_bounds((-10, -10, -10), (10, 10, 10))
    for region in spawn_regions:
        cache_key = self._get_cache_key("region", region.region_id)
        self.redis_client.setex(cache_key, 3600, json.dumps(region.__dict__))

    # Cache active players
    # ... etc
```

---

## Connection Pool Optimization

### 1. Pool Sizing

#### Calculate Optimal Pool Size

```python
# Formula: pool_size = (concurrent_requests * avg_query_time) / target_latency
# Example: (1000 concurrent * 0.005s) / 0.010s = 50 connections

StateManager(
    pool_size=50,  # For 1000 concurrent players
    # ...
)
```

#### Dynamic Pool Sizing

```python
# state_manager.py - Add dynamic pool sizing
import multiprocessing

def calculate_pool_size(self):
    """Calculate optimal pool size based on system resources."""
    cpu_count = multiprocessing.cpu_count()
    # Rule of thumb: 2-5 connections per CPU core
    return min(cpu_count * 4, 100)  # Cap at 100

# In __init__:
self.connection_pool = psycopg2.pool.ThreadedConnectionPool(
    minconn=max(5, pool_size // 10),  # 10% min connections
    maxconn=pool_size,
    **self.db_config
)
```

### 2. Connection Timeout Configuration

```python
# state_manager.py - Add connection timeout
self.db_config = {
    'host': db_host,
    'port': db_port,
    'database': db_name,
    'user': db_user,
    'connect_timeout': 10,  # seconds
    'options': '-c statement_timeout=5000',  # 5 second query timeout
}
```

### 3. Connection Health Checks

```python
def validate_connection(self, conn):
    """Validate connection before use."""
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
        return True
    except:
        return False

@contextmanager
def get_connection(self):
    """Get validated connection from pool."""
    conn = self.connection_pool.getconn()

    # Validate connection
    if not self.validate_connection(conn):
        # Connection is stale, close and get new one
        self.connection_pool.putconn(conn, close=True)
        conn = self.connection_pool.getconn()

    try:
        yield conn
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise
    finally:
        self.connection_pool.putconn(conn)
```

---

## Query Optimization

### 1. Use EXPLAIN ANALYZE

Always test query performance:

```python
def analyze_query(self, query, params):
    """Analyze query performance."""
    with self.get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(f"EXPLAIN ANALYZE {query}", params)
            print(cur.fetchall())
```

### 2. Optimize Common Queries

#### Region Queries

```python
# GOOD: Use index on region_id (primary key)
SELECT * FROM regions WHERE region_id = %s

# GOOD: Use spatial index
SELECT * FROM regions
WHERE region_x >= %s AND region_x <= %s
  AND region_y >= %s AND region_y <= %s
  AND region_z >= %s AND region_z <= %s

# BAD: Full table scan
SELECT * FROM regions WHERE owner_server_id = %s  # Add index if needed
```

#### Entity Queries

```python
# GOOD: Use region_id index
SELECT * FROM entities WHERE region_id = %s

# BETTER: Filter by type too (composite index)
SELECT * FROM entities
WHERE region_id = %s AND entity_type = %s

# BEST: Limit results
SELECT * FROM entities
WHERE region_id = %s
ORDER BY created_at DESC
LIMIT 1000
```

### 3. Avoid N+1 Queries

```python
# BAD: N+1 queries
regions = get_all_regions()
for region in regions:
    entities = get_entities_in_region(region.region_id)  # N queries!

# GOOD: Single query with JOIN or batch fetch
region_ids = [r.region_id for r in regions]
entities = get_entities_for_regions(region_ids)  # 1 query
```

---

## Cache Strategy Optimization

### 1. Cache-Aside Pattern (Current)

Current implementation uses cache-aside. Optimize it:

```python
def get_region_optimized(self, region_id: str) -> Optional[Region]:
    """Optimized region fetch with cache."""
    # 1. Try cache first (fast path)
    cached = self._cache_get("region", region_id)
    if cached:
        return Region(**json.loads(cached))

    # 2. Cache miss - fetch from DB
    with self.get_connection() as conn:
        with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
            cur.execute(
                "SELECT * FROM regions WHERE region_id = %s",
                (region_id,)
            )
            row = cur.fetchone()

            if row:
                region = Region(**row)

                # 3. Cache with TTL based on access pattern
                # Hot regions (spawn areas) - longer TTL
                ttl = 3600 if self._is_hot_region(region_id) else 300
                self._cache_set("region", region_id, json.dumps(region.__dict__), ttl)

                return region

    return None

def _is_hot_region(self, region_id: str) -> bool:
    """Check if region is frequently accessed."""
    # Spawn area and nearby regions
    return region_id in ["0_0_0", "1_0_0", "-1_0_0", "0_1_0", "0_-1_0"]
```

### 2. Cache Invalidation Strategy

```python
def update_region_with_invalidation(self, region_id: str, updates: Dict[str, Any]) -> bool:
    """Update region and invalidate related caches."""
    success = self.update_region(region_id, updates)

    if success:
        # Invalidate region cache
        self._cache_delete("region", region_id)

        # Invalidate entity cache for this region
        self._cache_delete("region_entities", region_id)

        # If region coordinates changed, invalidate spatial queries
        if any(k in updates for k in ['region_x', 'region_y', 'region_z']):
            self._invalidate_spatial_cache(region_id)

    return success
```

### 3. Batch Cache Operations

```python
def get_regions_batch(self, region_ids: List[str]) -> List[Region]:
    """Fetch multiple regions with batch cache operations."""
    # Build cache keys
    cache_keys = [self._get_cache_key("region", rid) for rid in region_ids]

    # Batch fetch from Redis using pipeline
    pipe = self.redis_client.pipeline()
    for key in cache_keys:
        pipe.get(key)
    cached_values = pipe.execute()

    # Separate hits and misses
    regions = []
    missing_ids = []

    for i, (region_id, cached) in enumerate(zip(region_ids, cached_values)):
        if cached:
            regions.append(Region(**json.loads(cached)))
            self.cache_hits += 1
        else:
            missing_ids.append(region_id)
            self.cache_misses += 1

    # Batch fetch misses from database
    if missing_ids:
        with self.get_connection() as conn:
            with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
                cur.execute(
                    "SELECT * FROM regions WHERE region_id = ANY(%s)",
                    (missing_ids,)
                )
                rows = cur.fetchall()

                # Batch cache newly fetched regions
                pipe = self.redis_client.pipeline()
                for row in rows:
                    region = Region(**row)
                    regions.append(region)
                    cache_key = self._get_cache_key("region", region.region_id)
                    pipe.setex(cache_key, self.redis_ttl, json.dumps(region.__dict__))
                pipe.execute()

    return regions
```

---

## Monitoring and Diagnostics

### 1. Enable Query Logging

```python
# state_manager.py - Add query logging
import logging

class StateManager:
    def __init__(self, *args, enable_query_logging=False, **kwargs):
        # ...
        self.query_logger = logging.getLogger('query_log')
        self.enable_query_logging = enable_query_logging

    @contextmanager
    def get_connection(self):
        conn = self.connection_pool.getconn()
        try:
            yield conn

            # Log slow queries
            if self.enable_query_logging:
                # Log queries that took >10ms
                pass

            conn.commit()
        except Exception as e:
            conn.rollback()
            logger.error(f"Database error: {e}")
            raise
        finally:
            self.connection_pool.putconn(conn)
```

### 2. Monitor Cache Statistics

```python
def get_detailed_cache_stats(self) -> Dict[str, Any]:
    """Get detailed cache statistics."""
    redis_info = self.redis_client.info()

    total_requests = self.cache_hits + self.cache_misses
    hit_rate = self.cache_hits / total_requests if total_requests > 0 else 0.0

    return {
        "cache_hits": self.cache_hits,
        "cache_misses": self.cache_misses,
        "hit_rate": hit_rate,
        "db_queries": self.db_queries,

        # Redis stats
        "redis_memory_used": redis_info.get('used_memory_human'),
        "redis_memory_peak": redis_info.get('used_memory_peak_human'),
        "redis_keys": self.redis_client.dbsize(),
        "redis_evicted_keys": redis_info.get('evicted_keys', 0),
        "redis_keyspace_hits": redis_info.get('keyspace_hits', 0),
        "redis_keyspace_misses": redis_info.get('keyspace_misses', 0),

        # Connection pool stats
        # (Add if psycopg2 pool supports this)
    }
```

### 3. Performance Metrics Collection

```python
# Add Prometheus-style metrics
from prometheus_client import Counter, Histogram, Gauge

# Metrics
db_query_duration = Histogram('db_query_duration_seconds', 'Database query duration')
cache_hit_counter = Counter('cache_hits_total', 'Cache hits')
cache_miss_counter = Counter('cache_misses_total', 'Cache misses')
active_connections = Gauge('db_active_connections', 'Active database connections')

# Use in queries
with db_query_duration.time():
    result = self.sm.get_region(region_id)
```

---

## Production Deployment

### 1. CockroachDB Production Configuration

```bash
# Start CockroachDB cluster (3+ nodes recommended)
cockroach start \
  --insecure \
  --advertise-addr=<node1-address> \
  --join=<node1-address>,<node2-address>,<node3-address> \
  --cache=25% \
  --max-sql-memory=25% \
  --background

# Initialize cluster (first node only)
cockroach init --insecure --host=<node1-address>
```

### 2. Redis Production Configuration

```conf
# redis.conf for production

# Network
bind 0.0.0.0
protected-mode yes
requirepass your_secure_password_here
port 6379

# Memory
maxmemory 16gb
maxmemory-policy allkeys-lru

# Persistence (if needed)
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfsync everysec

# Performance
tcp-backlog 511
timeout 0
tcp-keepalive 300
maxclients 20000

# Replication (for high availability)
replicaof <master-ip> <master-port>
masterauth your_secure_password_here
replica-read-only yes
```

### 3. Load Balancing

Use PgBouncer for connection pooling:

```ini
# pgbouncer.ini
[databases]
planetary_survival = host=<cockroach-lb> port=26257

[pgbouncer]
listen_port = 6432
listen_addr = 0.0.0.0
auth_type = trust
pool_mode = transaction
max_client_conn = 10000
default_pool_size = 50
reserve_pool_size = 25
reserve_pool_timeout = 3
```

### 4. Monitoring Stack

```yaml
# docker-compose.yml for monitoring
version: '3'
services:
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

---

## Troubleshooting

### High Latency Issues

1. **Check query plans:** `EXPLAIN ANALYZE` on slow queries
2. **Verify indexes:** Ensure spatial and lookup indexes exist
3. **Monitor connection pool:** Check for pool saturation
4. **Review cache hit rate:** Should be >90%

### Low Cache Hit Rate

1. **Increase TTL:** For stable data
2. **Increase Redis memory:** More keys can be cached
3. **Pre-warm cache:** Load hot data on startup
4. **Optimize eviction policy:** Consider `volatile-lru` vs `allkeys-lru`

### Connection Pool Exhaustion

1. **Increase pool size:** Based on concurrent load
2. **Reduce transaction duration:** Keep transactions small
3. **Add connection timeout:** Prevent connection leaks
4. **Use connection pooler:** PgBouncer for large deployments

---

## Benchmarking After Tuning

After applying optimizations, re-run stress tests:

```bash
cd C:/godot/tests/database
python test_stress.py
python load_test_runner.py --test-type all
```

Compare results to baseline in `STRESS_TEST_REPORT.md`.

---

## References

- CockroachDB Performance Tuning: https://www.cockroachlabs.com/docs/stable/performance-tuning.html
- Redis Best Practices: https://redis.io/docs/manual/optimization/
- PostgreSQL Connection Pooling: https://www.pgbouncer.org/
- Psycopg2 Pool Documentation: https://www.psycopg.org/docs/pool.html

---

**Last Updated:** 2024-12-02
**Maintained By:** Database Performance Team
**Contact:** [Team contact]
