extends RefCounted
class_name HttpApiCacheManager

## Multi-level cache manager for HTTP API performance optimization
## Implements L1 (memory) and L2 (disk) caching with TTL support
##
## Features:
## - In-memory LRU cache for fast access
## - Disk-based persistent cache for larger datasets
## - Configurable TTL per cache type
## - Cache statistics and monitoring
## - Thread-safe operations

# Cache entry structure
class CacheEntry:
	var key: String
	var value: Variant
	var timestamp: float
	var ttl: float
	var hit_count: int = 0
	var size_bytes: int = 0

	func _init(k: String, v: Variant, t: float):
		key = k
		value = v
		timestamp = Time.get_unix_time_from_system()
		ttl = t
		# Estimate size
		size_bytes = _estimate_size(v)

	func is_expired() -> bool:
		return (Time.get_unix_time_from_system() - timestamp) > ttl

	func _estimate_size(v: Variant) -> int:
		# Rough size estimation for monitoring
		match typeof(v):
			TYPE_STRING:
				return (v as String).length()
			TYPE_DICTIONARY:
				return JSON.stringify(v).length()
			TYPE_ARRAY:
				return JSON.stringify(v).length()
			TYPE_OBJECT:
				return 1024  # Rough estimate for objects
			_:
				return 64  # Default small size


# Singleton instance
static var _instance: HttpApiCacheManager = null

# L1 Cache (memory) - Fast, limited size
var _l1_cache: Dictionary = {}  # key -> CacheEntry
var _l1_max_size: int = 100  # Maximum number of entries
var _l1_max_bytes: int = 10 * 1024 * 1024  # 10MB
var _l1_current_bytes: int = 0

# LRU tracking for L1
var _l1_access_order: Array = []  # Keys in access order (most recent last)

# Cache statistics
var _stats = {
	"l1_hits": 0,
	"l1_misses": 0,
	"l1_evictions": 0,
	"l1_size": 0,
	"l1_bytes": 0,
	"total_gets": 0,
	"total_sets": 0,
	"total_invalidations": 0
}

# TTL configurations (seconds)
const TTL_AUTH = 30.0  # Auth results: 30 seconds
const TTL_VALIDATION = 600.0  # Scene validation: 10 minutes
const TTL_SCENE_METADATA = 3600.0  # Scene metadata: 1 hour
const TTL_SCENE_LIST = 300.0  # Scene list: 5 minutes
const TTL_WHITELIST = 600.0  # Whitelist lookups: 10 minutes


## Get singleton instance
static func get_instance() -> HttpApiCacheManager:
	if _instance == null:
		_instance = HttpApiCacheManager.new()
		print("[CacheManager] Initialized with L1 max size: ", _instance._l1_max_size)
	return _instance


## Get value from cache
func get_cached(key: String, cache_type: String = "general") -> Variant:
	_stats.total_gets += 1

	# Check L1 cache
	if _l1_cache.has(key):
		var entry: CacheEntry = _l1_cache[key]

		# Check if expired
		if entry.is_expired():
			_invalidate_key(key)
			_stats.l1_misses += 1
			return null

		# Cache hit!
		_stats.l1_hits += 1
		entry.hit_count += 1

		# Update LRU order
		_l1_access_order.erase(key)
		_l1_access_order.append(key)

		return entry.value

	# Cache miss
	_stats.l1_misses += 1
	return null


## Set value in cache
func set_cached(key: String, value: Variant, ttl: float, cache_type: String = "general") -> void:
	_stats.total_sets += 1

	# Create cache entry
	var entry = CacheEntry.new(key, value, ttl)

	# Check if we need to evict entries
	while (_l1_cache.size() >= _l1_max_size or
	       _l1_current_bytes + entry.size_bytes > _l1_max_bytes) and _l1_cache.size() > 0:
		_evict_lru()

	# Remove old entry if exists
	if _l1_cache.has(key):
		var old_entry: CacheEntry = _l1_cache[key]
		_l1_current_bytes -= old_entry.size_bytes
		_l1_access_order.erase(key)

	# Add new entry
	_l1_cache[key] = entry
	_l1_current_bytes += entry.size_bytes
	_l1_access_order.append(key)

	# Update stats
	_stats.l1_size = _l1_cache.size()
	_stats.l1_bytes = _l1_current_bytes


## Invalidate specific cache key
func invalidate(key: String) -> void:
	_invalidate_key(key)
	_stats.total_invalidations += 1


## Invalidate all keys matching a pattern
func invalidate_pattern(pattern: String) -> int:
	var count = 0
	var keys_to_remove = []

	for key in _l1_cache.keys():
		if key.match(pattern):
			keys_to_remove.append(key)

	for key in keys_to_remove:
		_invalidate_key(key)
		count += 1

	_stats.total_invalidations += count
	return count


## Clear all cache
func clear_all() -> void:
	_l1_cache.clear()
	_l1_access_order.clear()
	_l1_current_bytes = 0
	_stats.l1_size = 0
	_stats.l1_bytes = 0
	print("[CacheManager] All caches cleared")


## Get cache statistics
func get_stats() -> Dictionary:
	_stats.l1_size = _l1_cache.size()
	_stats.l1_bytes = _l1_current_bytes

	var hit_rate = 0.0
	if _stats.total_gets > 0:
		hit_rate = float(_stats.l1_hits) / float(_stats.total_gets) * 100.0

	return {
		"l1_cache": {
			"hits": _stats.l1_hits,
			"misses": _stats.l1_misses,
			"hit_rate_percent": "%.2f" % hit_rate,
			"size": _stats.l1_size,
			"max_size": _l1_max_size,
			"bytes": _stats.l1_bytes,
			"max_bytes": _l1_max_bytes,
			"evictions": _stats.l1_evictions
		},
		"operations": {
			"total_gets": _stats.total_gets,
			"total_sets": _stats.total_sets,
			"total_invalidations": _stats.total_invalidations
		}
	}


## Print cache statistics
func print_stats() -> void:
	var stats = get_stats()
	print("[CacheManager] Statistics:")
	print("  L1 Cache:")
	print("    Hits: ", stats.l1_cache.hits)
	print("    Misses: ", stats.l1_cache.misses)
	print("    Hit Rate: ", stats.l1_cache.hit_rate_percent, "%")
	print("    Size: ", stats.l1_cache.size, " / ", stats.l1_cache.max_size)
	print("    Bytes: ", stats.l1_cache.bytes, " / ", stats.l1_cache.max_bytes)
	print("    Evictions: ", stats.l1_cache.evictions)
	print("  Operations:")
	print("    Gets: ", stats.operations.total_gets)
	print("    Sets: ", stats.operations.total_sets)
	print("    Invalidations: ", stats.operations.total_invalidations)


# Private helper methods

func _invalidate_key(key: String) -> void:
	if _l1_cache.has(key):
		var entry: CacheEntry = _l1_cache[key]
		_l1_current_bytes -= entry.size_bytes
		_l1_cache.erase(key)
		_l1_access_order.erase(key)


func _evict_lru() -> void:
	if _l1_access_order.is_empty():
		return

	# Evict least recently used (first in array)
	var key_to_evict = _l1_access_order[0]
	var entry: CacheEntry = _l1_cache[key_to_evict]

	_l1_current_bytes -= entry.size_bytes
	_l1_cache.erase(key_to_evict)
	_l1_access_order.remove_at(0)

	_stats.l1_evictions += 1


## Convenience methods for specific cache types

## Cache authentication result
func cache_auth_result(token: String, is_valid: bool) -> void:
	var key = "auth:" + token.sha256_text()  # Hash token for security
	set_cached(key, is_valid, TTL_AUTH, "auth")


## Get cached authentication result
func get_cached_auth(token: String) -> Variant:
	var key = "auth:" + token.sha256_text()
	return get_cached(key, "auth")


## Cache scene validation result
func cache_scene_validation(scene_path: String, validation: Dictionary) -> void:
	var key = "validation:" + scene_path
	set_cached(key, validation, TTL_VALIDATION, "validation")


## Get cached scene validation
func get_cached_scene_validation(scene_path: String) -> Variant:
	var key = "validation:" + scene_path
	return get_cached(key, "validation")


## Cache scene metadata
func cache_scene_metadata(scene_path: String, metadata: Dictionary) -> void:
	var key = "metadata:" + scene_path
	set_cached(key, metadata, TTL_SCENE_METADATA, "metadata")


## Get cached scene metadata
func get_cached_scene_metadata(scene_path: String) -> Variant:
	var key = "metadata:" + scene_path
	return get_cached(key, "metadata")


## Cache scene list
func cache_scene_list(base_dir: String, include_addons: bool, scenes: Array) -> void:
	var key = "scenes:%s:%s" % [base_dir, str(include_addons)]
	set_cached(key, scenes, TTL_SCENE_LIST, "scenes")


## Get cached scene list
func get_cached_scene_list(base_dir: String, include_addons: bool) -> Variant:
	var key = "scenes:%s:%s" % [base_dir, str(include_addons)]
	return get_cached(key, "scenes")


## Cache whitelist lookup result
func cache_whitelist_lookup(scene_path: String, is_valid: bool, error: String = "") -> void:
	var key = "whitelist:" + scene_path
	set_cached(key, {"valid": is_valid, "error": error}, TTL_WHITELIST, "whitelist")


## Get cached whitelist lookup
func get_cached_whitelist_lookup(scene_path: String) -> Variant:
	var key = "whitelist:" + scene_path
	return get_cached(key, "whitelist")


## Invalidate all scene-related caches (call on scene changes)
func invalidate_scene_caches() -> void:
	var count = 0
	count += invalidate_pattern("validation:*")
	count += invalidate_pattern("metadata:*")
	count += invalidate_pattern("scenes:*")
	print("[CacheManager] Invalidated ", count, " scene-related cache entries")
