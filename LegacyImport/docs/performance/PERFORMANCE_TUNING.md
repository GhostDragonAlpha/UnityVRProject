# Performance Tuning Guide

**SpaceTime VR - Secured HTTP API Optimization Guide**

This guide provides comprehensive instructions for optimizing the performance of the secured HTTP API system. Use this guide to tune security components, identify bottlenecks, and achieve optimal performance.

---

## Table of Contents

1. [Performance Targets](#performance-targets)
2. [Quick Start Optimization](#quick-start-optimization)
3. [Component-by-Component Tuning](#component-by-component-tuning)
4. [Configuration Reference](#configuration-reference)
5. [Profiling and Diagnostics](#profiling-and-diagnostics)
6. [Common Performance Issues](#common-performance-issues)
7. [Advanced Optimizations](#advanced-optimizations)
8. [Monitoring and Alerting](#monitoring-and-alerting)

---

## 1. Performance Targets

### Production SLAs

| Metric | Target | Critical Threshold |
|--------|--------|-------------------|
| Security Overhead | <5ms | <10ms |
| p99 Latency | <50ms | <100ms |
| p999 Latency | <100ms | <200ms |
| Throughput | >1,000 req/sec | >500 req/sec |
| Error Rate | <1% | <5% |
| Memory per Session | <2 KB | <5 KB |

### Performance Goals

**Excellent:** All metrics well within targets (>20% margin)
**Good:** All metrics within targets
**Acceptable:** Some metrics at critical threshold
**Poor:** Any metric exceeding critical threshold

---

## 2. Quick Start Optimization

### Step 1: Baseline Measurement

Before optimizing, establish a performance baseline:

```bash
# Run security overhead test
cd tests/performance
python test_security_overhead.py

# Check results
cat tests/test-reports/security_overhead_*.json | grep "full_overhead_ms"
```

**Expected Result:** 2-3ms security overhead

### Step 2: Apply Quick Wins

Implement these high-impact, low-effort optimizations:

#### A. Enable Token Caching

**File:** `scripts/security/token_manager.gd` or equivalent

```gdscript
# Add to TokenManager class
const TOKEN_CACHE_SIZE: int = 1000
const TOKEN_CACHE_TTL_SECONDS: float = 300.0  # 5 minutes

var _token_cache: Dictionary = {}  # secret -> {token, timestamp}
var _cache_hits: int = 0
var _cache_misses: int = 0

func validate_token(token_secret: String) -> Dictionary:
    var current_time = Time.get_unix_time_from_system()

    # Check cache first
    if _token_cache.has(token_secret):
        var cached = _token_cache[token_secret]
        if current_time - cached.timestamp < TOKEN_CACHE_TTL_SECONDS:
            _cache_hits += 1
            return cached.token

    # Cache miss - validate normally
    _cache_misses += 1
    var result = _validate_token_internal(token_secret)

    # Update cache
    if result.valid:
        _token_cache[token_secret] = {
            "token": result,
            "timestamp": current_time
        }

        # Evict old entries if cache is full
        if _token_cache.size() > TOKEN_CACHE_SIZE:
            _evict_oldest_cache_entry()

    return result
```

**Expected Improvement:** 40-50% reduction in token validation time (0.8ms → 0.4ms)

#### B. Enable Permission Caching

**File:** `scripts/security/rbac.gd` or equivalent

```gdscript
# Add to RBAC class
const PERMISSION_CACHE_SIZE: int = 500
const PERMISSION_CACHE_TTL_SECONDS: float = 600.0  # 10 minutes

var _permission_cache: Dictionary = {}  # "role:permission" -> {result, timestamp}

func check_authorization(token_id: String, permission: Permission) -> Dictionary:
    var role = get_role_for_token(token_id)
    if not role:
        return {"authorized": false, "error": "No role assigned"}

    var cache_key = "%s:%d" % [role.role_name, permission]
    var current_time = Time.get_unix_time_from_system()

    # Check cache
    if _permission_cache.has(cache_key):
        var cached = _permission_cache[cache_key]
        if current_time - cached.timestamp < PERMISSION_CACHE_TTL_SECONDS:
            return {"authorized": cached.result}

    # Cache miss - check permission
    var result = _check_permission_internal(role, permission)

    # Update cache
    _permission_cache[cache_key] = {
        "result": result,
        "timestamp": current_time
    }

    return {"authorized": result}
```

**Expected Improvement:** 50-60% reduction in authorization time (0.6ms → 0.24ms)

#### C. Optimize Input Validation

**File:** `scripts/http_api/input_validator.gd`

```gdscript
# Optimize validate_vector3 with fast path
static func validate_vector3(value, min_coord: float = MIN_POSITION_COORD,
                             max_coord: float = MAX_POSITION_COORD,
                             field_name: String = "vector3") -> Dictionary:
    # Fast path validation
    if typeof(value) != TYPE_ARRAY or value.size() != 3:
        return {"valid": false, "error": "%s must be [x, y, z] array" % field_name}

    # Validate all coordinates in single pass
    var x = value[0]
    var y = value[1]
    var z = value[2]

    # Type and range check together
    if typeof(x) != TYPE_FLOAT and typeof(x) != TYPE_INT:
        return {"valid": false, "error": "%s.x must be a number" % field_name}
    if typeof(y) != TYPE_FLOAT and typeof(y) != TYPE_INT:
        return {"valid": false, "error": "%s.y must be a number" % field_name}
    if typeof(z) != TYPE_FLOAT and typeof(z) != TYPE_INT:
        return {"valid": false, "error": "%s.z must be a number" % field_name}

    if x < min_coord or x > max_coord or y < min_coord or y > max_coord or z < min_coord or z > max_coord:
        return {"valid": false, "error": "%s coordinates out of range" % field_name}

    # Success - create vector
    return {"valid": true, "vector": Vector3(float(x), float(y), float(z))}
```

**Expected Improvement:** 30-40% reduction in validation time (0.5ms → 0.3ms)

### Step 3: Verify Improvements

After applying optimizations, re-run tests:

```bash
python test_security_overhead.py
```

**Expected Results:**
- Security overhead: 1.2-1.5ms (was 2.2ms)
- Overall improvement: 40-45%

---

## 3. Component-by-Component Tuning

### 3.1 TokenManager Optimization

#### Configuration Parameters

```gdscript
# Token lifetime settings
const DEFAULT_TOKEN_LIFETIME_HOURS: float = 24.0  # Longer = fewer rotations
const MAX_TOKEN_LIFETIME_HOURS: float = 168.0  # 7 days max

# Cache settings
const TOKEN_CACHE_SIZE: int = 1000  # Increase for high-traffic systems
const TOKEN_CACHE_TTL_SECONDS: float = 300.0  # 5 minutes

# Cleanup settings
const CLEANUP_INTERVAL_SECONDS: float = 3600.0  # 1 hour
```

#### Performance Tips

1. **Increase Cache Size** for systems with many concurrent users:
   ```gdscript
   const TOKEN_CACHE_SIZE: int = 5000  # For 5000+ concurrent users
   ```

2. **Longer Cache TTL** for stable user bases:
   ```gdscript
   const TOKEN_CACHE_TTL_SECONDS: float = 900.0  # 15 minutes
   ```

3. **Secondary Index** for fast token lookups:
   ```gdscript
   var _tokens_by_secret: Dictionary = {}  # secret -> token_id
   ```

4. **Lazy Cleanup** to reduce overhead:
   ```gdscript
   # Only cleanup when cache size exceeds threshold
   if _token_cache.size() > TOKEN_CACHE_SIZE * 1.2:
       _cleanup_cache()
   ```

#### Monitoring Metrics

```gdscript
func get_performance_metrics() -> Dictionary:
    return {
        "cache_hit_rate": float(_cache_hits) / float(_cache_hits + _cache_misses),
        "cache_size": _token_cache.size(),
        "active_tokens": _tokens.size(),
        "avg_validation_time_ms": _avg_validation_time
    }
```

**Target:** Cache hit rate >80%

### 3.2 RateLimiter Optimization

#### Configuration Parameters

```gdscript
# Rate limit settings
const DEFAULT_RATE_LIMIT: int = 200  # Increase from 100 for production
const RATE_LIMIT_WINDOW: float = 60.0  # Keep at 60s

# Endpoint-specific limits
const ENDPOINT_LIMITS: Dictionary = {
    "/status": 500,  # Cheap endpoint - high limit
    "/scene": 30,  # Expensive - low limit
    "/player/position": 200,  # Frequent - medium limit
}

# Cleanup settings
const CLEANUP_INTERVAL: float = 600.0  # 10 minutes (was 5)
const BUCKET_EXPIRY: float = 3600.0  # 1 hour
```

#### Performance Tips

1. **Increase Default Rate Limit** for trusted environments:
   ```gdscript
   const DEFAULT_RATE_LIMIT: int = 500
   ```

2. **Longer Cleanup Interval** to reduce overhead:
   ```gdscript
   const CLEANUP_INTERVAL: float = 1800.0  # 30 minutes
   ```

3. **Bucket Pooling** to reduce allocations:
   ```gdscript
   var _bucket_pool: Array = []

   func _get_or_create_bucket(key: String) -> Dictionary:
       if _bucket_pool.is_empty():
           return {
               "tokens": float(limit),
               "last_update": current_time
           }
       else:
           var bucket = _bucket_pool.pop_back()
           bucket.tokens = float(limit)
           bucket.last_update = current_time
           return bucket
   ```

4. **Fast Path for Non-Limited IPs:**
   ```gdscript
   # Whitelist trusted IPs
   const TRUSTED_IPS: Array[String] = ["127.0.0.1", "::1"]

   func check_rate_limit(client_ip: String, endpoint: String) -> Dictionary:
       if client_ip in TRUSTED_IPS:
           return {"allowed": true}  # Skip rate limiting
       # ... normal rate limiting
   ```

#### Monitoring Metrics

```gdscript
func get_performance_metrics() -> Dictionary:
    return {
        "active_buckets": _rate_limit_buckets.size(),
        "requests_per_second": _total_requests / uptime,
        "block_rate": float(_total_blocked) / float(_total_requests),
        "avg_check_time_ms": _avg_check_time
    }
```

**Target:** <0.3ms per check

### 3.3 InputValidator Optimization

#### Configuration Parameters

```gdscript
# Validation ranges (adjust for your game)
const MAX_POSITION_COORD: float = 100000.0
const MIN_POSITION_COORD: float = -100000.0

# String length limits
const MAX_STRING_LENGTH: int = 256
const MAX_JSON_SIZE: int = 1048576  # 1MB

# Validation caching
const VALIDATION_CACHE_SIZE: int = 100
```

#### Performance Tips

1. **Pre-compiled Regex** for pattern matching:
   ```gdscript
   # Compile regex once at class load
   static var _alphanumeric_regex: RegEx = _compile_regex("^[a-zA-Z0-9_-]+$")

   static func _compile_regex(pattern: String) -> RegEx:
       var regex = RegEx.new()
       regex.compile(pattern)
       return regex
   ```

2. **Inline Range Checks** instead of function calls:
   ```gdscript
   # Fast inline check
   if x < -100000.0 or x > 100000.0:
       return {"valid": false}

   # Slower function call
   var result = validate_float(x, -100000.0, 100000.0)
   ```

3. **Validation Result Caching** for repeated inputs:
   ```gdscript
   var _validation_cache: Dictionary = {}

   func validate_creature_type(type: String) -> Dictionary:
       if _validation_cache.has(type):
           return _validation_cache[type]

       var result = _validate_creature_type_internal(type)
       _validation_cache[type] = result
       return result
   ```

4. **Skip Validation in Development:**
   ```gdscript
   const ENABLE_VALIDATION: bool = !OS.is_debug_build()

   func validate_position(pos) -> Dictionary:
       if not ENABLE_VALIDATION:
           return {"valid": true, "vector": Vector3(pos[0], pos[1], pos[2])}
       # ... full validation
   ```

#### Monitoring Metrics

```gdscript
static func get_performance_metrics() -> Dictionary:
    return {
        "validations_per_second": _total_validations / uptime,
        "cache_hit_rate": float(_cache_hits) / float(_total_validations),
        "avg_validation_time_ms": _avg_validation_time
    }
```

**Target:** <0.3ms per validation

### 3.4 AuditLogger Optimization

#### Configuration Parameters

```gdscript
# Batching settings
const BATCH_SIZE: int = 100  # Increase from 50
const FLUSH_INTERVAL_SECONDS: float = 5.0  # Increase from 1s

# Queue settings
const MAX_QUEUE_SIZE: int = 10000  # Prevent memory exhaustion
const ENABLE_ASYNC_LOGGING: bool = true  # Keep enabled

# File settings
const ENABLE_COMPRESSION: bool = true  # Compress old logs
const MAX_LOG_FILE_SIZE_MB: int = 100
```

#### Performance Tips

1. **Larger Batch Size** for high-traffic systems:
   ```gdscript
   const BATCH_SIZE: int = 500
   const FLUSH_INTERVAL_SECONDS: float = 10.0
   ```

2. **Async File I/O:**
   ```gdscript
   func _flush_events_async():
       var thread = Thread.new()
       thread.start(_write_events_to_disk.bind(_event_queue.duplicate()))
       _event_queue.clear()
   ```

3. **Selective Logging** to reduce volume:
   ```gdscript
   # Log levels
   enum LogLevel { DEBUG, INFO, WARNING, ERROR, CRITICAL }
   const MIN_LOG_LEVEL: LogLevel = LogLevel.INFO  # Skip DEBUG in production

   func log_event(level: LogLevel, event_type: String, details: Dictionary):
       if level < MIN_LOG_LEVEL:
           return  # Skip
       # ... log event
   ```

4. **Log Sampling** for high-frequency events:
   ```gdscript
   const SAMPLE_RATE: float = 0.1  # Log 10% of events

   func log_high_frequency_event(event_type: String, details: Dictionary):
       if randf() > SAMPLE_RATE:
           return  # Skip this event
       log_event(event_type, details)
   ```

#### Monitoring Metrics

```gdscript
func get_performance_metrics() -> Dictionary:
    return {
        "queue_size": _event_queue.size(),
        "events_per_second": _total_events / uptime,
        "avg_write_time_ms": _avg_write_time,
        "disk_usage_mb": _get_total_log_size_mb()
    }
```

**Target:** <0.1ms per log (async), queue size <1000

### 3.5 RBAC Optimization

#### Configuration Parameters

```gdscript
# Cache settings
const PERMISSION_CACHE_SIZE: int = 500
const PERMISSION_CACHE_TTL_SECONDS: float = 600.0  # 10 minutes

# Role assignment cache
const ROLE_CACHE_SIZE: int = 1000
const ROLE_CACHE_TTL_SECONDS: float = 300.0  # 5 minutes
```

#### Performance Tips

1. **Permission Bitmap** for faster checks:
   ```gdscript
   # Convert permissions to bitmap
   const PERMISSION_BITMAP: Dictionary = {
       Permission.READ_STATUS: 1 << 0,
       Permission.WRITE_POSITION: 1 << 1,
       Permission.SPAWN_ENTITIES: 1 << 2,
       # ... etc
   }

   var _role_permissions: Dictionary = {
       "readonly": 0b00000001,
       "api_client": 0b00000011,
       "developer": 0b11111111
   }

   func has_permission(role: String, perm: Permission) -> bool:
       var role_bits = _role_permissions.get(role, 0)
       var perm_bit = PERMISSION_BITMAP.get(perm, 0)
       return (role_bits & perm_bit) != 0
   ```

2. **Role Hierarchy** to reduce checks:
   ```gdscript
   # Admin inherits all permissions
   func check_authorization(token_id: String, perm: Permission) -> Dictionary:
       var role = get_role_for_token(token_id)
       if role.role_name == "admin":
           return {"authorized": true}  # Skip check
       # ... normal check
   ```

3. **Lazy Role Loading:**
   ```gdscript
   # Only load role details when needed
   var _role_cache: Dictionary = {}

   func get_role_for_token(token_id: String) -> Dictionary:
       if _role_cache.has(token_id):
           return _role_cache[token_id]

       var role = _load_role_from_storage(token_id)
       _role_cache[token_id] = role
       return role
   ```

#### Monitoring Metrics

```gdscript
func get_performance_metrics() -> Dictionary:
    return {
        "permission_cache_hit_rate": _get_cache_hit_rate(),
        "role_cache_size": _role_cache.size(),
        "avg_check_time_ms": _avg_check_time,
        "checks_per_second": _total_checks / uptime
    }
```

**Target:** <0.25ms per authorization check

---

## 4. Configuration Reference

### Production Configuration

**File:** `scripts/security/security_config.gd`

```gdscript
extends RefCounted
class_name SecurityConfig

# === TOKEN MANAGER ===
const TOKEN_LIFETIME_HOURS: float = 24.0
const TOKEN_CACHE_SIZE: int = 2000
const TOKEN_CACHE_TTL_SECONDS: float = 600.0  # 10 minutes
const TOKEN_CLEANUP_INTERVAL_SECONDS: float = 3600.0  # 1 hour

# === RATE LIMITER ===
const DEFAULT_RATE_LIMIT: int = 200
const RATE_LIMIT_WINDOW_SECONDS: float = 60.0
const RATE_LIMIT_CLEANUP_INTERVAL: float = 600.0  # 10 minutes
const RATE_LIMIT_BAN_THRESHOLD: int = 5
const RATE_LIMIT_BAN_DURATION: float = 3600.0  # 1 hour

# === INPUT VALIDATOR ===
const MAX_POSITION_COORD: float = 100000.0
const MAX_STRING_LENGTH: int = 256
const MAX_JSON_SIZE: int = 1048576  # 1MB
const VALIDATION_CACHE_SIZE: int = 200

# === AUDIT LOGGER ===
const AUDIT_BATCH_SIZE: int = 100
const AUDIT_FLUSH_INTERVAL: float = 5.0
const AUDIT_MAX_QUEUE_SIZE: int = 10000
const AUDIT_ENABLE_COMPRESSION: bool = true

# === RBAC ===
const PERMISSION_CACHE_SIZE: int = 500
const PERMISSION_CACHE_TTL_SECONDS: float = 600.0  # 10 minutes
const ROLE_CACHE_SIZE: int = 1000

# === PERFORMANCE ===
const ENABLE_PERFORMANCE_METRICS: bool = true
const METRICS_COLLECTION_INTERVAL: float = 60.0  # 1 minute
```

### Development Configuration

For development/testing, use more lenient settings:

```gdscript
# Override for development
const TOKEN_LIFETIME_HOURS: float = 168.0  # 7 days
const DEFAULT_RATE_LIMIT: int = 10000  # Very high
const VALIDATION_CACHE_SIZE: int = 0  # Disable caching for testing
const AUDIT_BATCH_SIZE: int = 1  # Immediate flush
```

### Environment-Specific Configs

Use environment variables to override:

```gdscript
static func get_token_lifetime() -> float:
    var env_value = OS.get_environment("SPACETIME_TOKEN_LIFETIME_HOURS")
    if env_value:
        return float(env_value)
    return TOKEN_LIFETIME_HOURS
```

---

## 5. Profiling and Diagnostics

### 5.1 Built-in Performance Metrics

Enable metrics collection:

```gdscript
# In security components
var _metrics: Dictionary = {
    "total_calls": 0,
    "total_time_ms": 0.0,
    "min_time_ms": INF,
    "max_time_ms": 0.0
}

func _track_performance(operation: Callable) -> Variant:
    var start = Time.get_ticks_usec()
    var result = operation.call()
    var elapsed_ms = (Time.get_ticks_usec() - start) / 1000.0

    _metrics.total_calls += 1
    _metrics.total_time_ms += elapsed_ms
    _metrics.min_time_ms = min(_metrics.min_time_ms, elapsed_ms)
    _metrics.max_time_ms = max(_metrics.max_time_ms, elapsed_ms)

    return result
```

### 5.2 Python Profiling Tools

Use our performance test suite:

```bash
# CPU profiling
python tests/performance/performance_profile.py --profile-type=cpu

# Memory profiling
python tests/performance/performance_profile.py --profile-type=memory

# Full profiling
python tests/performance/performance_profile.py --profile-type=all
```

### 5.3 Real-time Monitoring

Query metrics endpoint:

```bash
curl http://127.0.0.1:8080/admin/security/metrics
```

Returns:

```json
{
  "token_manager": {
    "cache_hit_rate": 0.87,
    "avg_validation_time_ms": 0.4,
    "active_tokens": 1234
  },
  "rate_limiter": {
    "requests_per_second": 850.2,
    "block_rate": 0.02,
    "active_buckets": 456
  },
  "rbac": {
    "permission_cache_hit_rate": 0.92,
    "avg_check_time_ms": 0.25
  }
}
```

### 5.4 Performance Flamegraphs

Generate flamegraphs for visualization:

```bash
# Capture profile
python -m cProfile -o profile.stats tests/performance/load_test_secured.py

# Convert to flamegraph format
python -m flameprof profile.stats > flamegraph.svg
```

---

## 6. Common Performance Issues

### Issue 1: High Latency Spikes

**Symptom:** p99 latency >100ms, but p50 is normal

**Diagnosis:**
```bash
python test_security_overhead.py | grep "p99"
```

**Common Causes:**
1. **Garbage Collection pauses**
   - Solution: Reduce allocations, use object pooling
2. **Disk I/O blocking**
   - Solution: Enable async audit logging
3. **Cache misses**
   - Solution: Increase cache size

**Fix:**
```gdscript
# Enable async operations
const AUDIT_ENABLE_ASYNC: bool = true

# Increase cache sizes
const TOKEN_CACHE_SIZE: int = 5000
const PERMISSION_CACHE_SIZE: int = 1000
```

### Issue 2: Low Throughput

**Symptom:** Actual RPS << target RPS

**Diagnosis:**
```bash
python load_test_secured.py --scenario=medium
```

**Common Causes:**
1. **Rate limiting too aggressive**
   - Solution: Increase rate limits
2. **Thread pool exhaustion**
   - Solution: Increase concurrent workers
3. **Network bottleneck**
   - Solution: Optimize request/response size

**Fix:**
```gdscript
# Increase rate limits
const DEFAULT_RATE_LIMIT: int = 500

# Optimize response size
func get_status() -> Dictionary:
    return {
        "ready": true
        # Remove unnecessary fields
    }
```

### Issue 3: Memory Growth

**Symptom:** Memory usage increases over time

**Diagnosis:**
```bash
python performance_profile.py --profile-type=memory
```

**Common Causes:**
1. **Cache not evicting old entries**
   - Solution: Implement LRU eviction
2. **Audit log queue unbounded**
   - Solution: Set MAX_QUEUE_SIZE
3. **Memory leak in validation**
   - Solution: Reuse temporary objects

**Fix:**
```gdscript
# LRU cache eviction
func _evict_oldest_cache_entry():
    var oldest_key = null
    var oldest_time = INF

    for key in _cache:
        if _cache[key].timestamp < oldest_time:
            oldest_time = _cache[key].timestamp
            oldest_key = key

    if oldest_key:
        _cache.erase(oldest_key)

# Bounded queue
func log_event(event: Dictionary):
    if _event_queue.size() >= MAX_QUEUE_SIZE:
        _event_queue.pop_front()  # Drop oldest
    _event_queue.append(event)
```

### Issue 4: High CPU Usage

**Symptom:** CPU at 100% under moderate load

**Diagnosis:**
```bash
python performance_profile.py --profile-type=cpu
```

**Common Causes:**
1. **Inefficient validation loops**
   - Solution: Use early bailout
2. **Excessive string operations**
   - Solution: Pre-compile patterns
3. **No caching**
   - Solution: Enable all caches

**Fix:**
```gdscript
# Early bailout validation
func validate_array(arr: Array) -> bool:
    if arr.is_empty():
        return false  # Early return

    for item in arr:
        if not is_valid_item(item):
            return false  # Early return

    return true

# Pre-compile regex
static var _regex_cache: Dictionary = {}

static func get_compiled_regex(pattern: String) -> RegEx:
    if not _regex_cache.has(pattern):
        var regex = RegEx.new()
        regex.compile(pattern)
        _regex_cache[pattern] = regex
    return _regex_cache[pattern]
```

---

## 7. Advanced Optimizations

### 7.1 GDNative Hot Paths

For maximum performance, move hot paths to C++:

**File:** `modules/security_native/token_manager.cpp`

```cpp
// Native token validation (10x faster)
#include "core/variant/variant.h"
#include <unordered_map>

class NativeTokenManager {
private:
    std::unordered_map<String, Token> tokens;

public:
    Dictionary validate_token(const String& token_secret) {
        auto it = tokens.find(token_secret);
        if (it != tokens.end()) {
            // Fast native validation
            return Dictionary::from(it->second);
        }
        return Dictionary();  // Invalid
    }
};
```

**Expected Improvement:** 10x faster (0.8ms → 0.08ms)

### 7.2 Memory Pooling

Reduce allocations with object pooling:

```gdscript
# Object pool for validation results
class ValidationResultPool:
    var _pool: Array = []
    var _pool_size: int = 100

    func get_result() -> Dictionary:
        if _pool.is_empty():
            return {}
        return _pool.pop_back()

    func return_result(result: Dictionary):
        if _pool.size() < _pool_size:
            result.clear()  # Reset
            _pool.append(result)

# Usage
var _result_pool = ValidationResultPool.new()

func validate_position(pos) -> Dictionary:
    var result = _result_pool.get_result()
    # ... populate result
    return result
```

**Expected Improvement:** 30% reduction in GC time

### 7.3 SIMD Vector Validation

Use SIMD for parallel validation (GDNative):

```cpp
// Validate 4 vectors simultaneously
#include <immintrin.h>

bool validate_vectors_simd(const Vector3* vectors, int count) {
    __m128 min = _mm_set1_ps(-100000.0f);
    __m128 max = _mm_set1_ps(100000.0f);

    for (int i = 0; i < count; i += 4) {
        // Load 4 x-coordinates
        __m128 x = _mm_set_ps(
            vectors[i+0].x, vectors[i+1].x,
            vectors[i+2].x, vectors[i+3].x
        );

        // Range check all 4 at once
        __m128 valid = _mm_and_ps(
            _mm_cmpge_ps(x, min),
            _mm_cmple_ps(x, max)
        );

        if (_mm_movemask_ps(valid) != 0xF) {
            return false;  // Out of range
        }
    }

    return true;
}
```

**Expected Improvement:** 4x faster for batch validation

### 7.4 Distributed Caching

For multi-instance deployments, use Redis:

```gdscript
# Redis-backed token cache
var redis_client = RedisClient.new("127.0.0.1", 6379)

func validate_token(token_secret: String) -> Dictionary:
    # Check Redis cache
    var cached = redis_client.get("token:" + token_secret)
    if cached:
        return JSON.parse_string(cached)

    # Validate and cache
    var result = _validate_token_internal(token_secret)
    if result.valid:
        redis_client.setex("token:" + token_secret, 300, JSON.stringify(result))

    return result
```

**Expected Improvement:** Shared cache across instances, 50% cache hit improvement

---

## 8. Monitoring and Alerting

### 8.1 Prometheus Metrics

Export security metrics for monitoring:

```gdscript
# metrics_exporter.gd
extends Node

var _prometheus_server: HTTPServer

func _ready():
    _prometheus_server = HTTPServer.new()
    _prometheus_server.listen(9090)

func _export_metrics() -> String:
    var metrics = []

    # Token manager metrics
    metrics.append('security_token_validation_seconds{quantile="0.99"} %f' %
                  [SecuritySystem.get_token_manager().get_p99_time_ms() / 1000.0])

    # Rate limiter metrics
    metrics.append('security_rate_limit_blocked_total %d' %
                  [SecuritySystem.get_rate_limiter().get_total_blocked()])

    return "\n".join(metrics)
```

### 8.2 Grafana Dashboard

Create performance dashboard:

```json
{
  "dashboard": {
    "title": "Security Performance",
    "panels": [
      {
        "title": "Security Overhead",
        "targets": [
          {
            "expr": "security_overhead_milliseconds"
          }
        ],
        "alert": {
          "conditions": [
            {
              "evaluator": {
                "type": "gt",
                "params": [5.0]
              }
            }
          ]
        }
      }
    ]
  }
}
```

### 8.3 Alerting Rules

Set up alerts for performance degradation:

```yaml
# prometheus_alerts.yml
groups:
  - name: security_performance
    rules:
      - alert: HighSecurityOverhead
        expr: security_overhead_milliseconds > 5
        for: 5m
        annotations:
          summary: "Security overhead exceeds 5ms"

      - alert: LowThroughput
        expr: rate(http_requests_total[1m]) < 1000
        for: 5m
        annotations:
          summary: "Throughput below 1000 req/sec"

      - alert: HighP99Latency
        expr: http_request_duration_seconds{quantile="0.99"} > 0.05
        for: 5m
        annotations:
          summary: "p99 latency exceeds 50ms"
```

---

## Summary

### Quick Reference

| Optimization | Complexity | Impact | Implementation Time |
|--------------|-----------|--------|-------------------|
| Token Cache | LOW | HIGH (0.4ms) | 2 hours |
| Permission Cache | LOW | HIGH (0.36ms) | 2 hours |
| Vector Validation | MEDIUM | MEDIUM (0.2ms) | 3 hours |
| Async Logging | LOW | MEDIUM | 1 hour |
| Object Pooling | MEDIUM | LOW | 1 day |
| GDNative | HIGH | HIGH (10x) | 2 weeks |

### Performance Checklist

- [ ] Enable token caching (TARGET: 80% hit rate)
- [ ] Enable permission caching (TARGET: 90% hit rate)
- [ ] Optimize vector validation (TARGET: <0.3ms)
- [ ] Configure rate limits for production (TARGET: 200 req/min)
- [ ] Enable async audit logging (TARGET: <0.1ms)
- [ ] Set up monitoring (Prometheus + Grafana)
- [ ] Configure alerting rules
- [ ] Run load tests (TARGET: 1000+ req/sec)
- [ ] Verify security overhead (TARGET: <5ms)
- [ ] Check memory usage (TARGET: <2KB per session)

### Next Steps

1. Apply quick wins (Steps 1-3 above)
2. Verify improvements with test suite
3. Monitor production metrics
4. Iterate on optimizations based on data
5. Consider advanced optimizations for scale

---

**Last Updated:** 2025-12-02
**Version:** 1.0.0
**Maintainer:** Performance Engineering Team
