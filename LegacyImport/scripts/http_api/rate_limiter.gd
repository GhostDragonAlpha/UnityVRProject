extends RefCounted
class_name HttpApiRateLimiter

## HTTP API Rate Limiter
## Implements token bucket algorithm with per-IP tracking, IP banning, and automatic cleanup
## Prevents DoS attacks by limiting request rates per IP address and endpoint
##
## Features:
## - Token bucket algorithm for smooth rate limiting
## - Per-IP and per-endpoint tracking
## - Automatic IP banning after repeated violations
## - Auto-cleanup of old entries
## - Configurable limits per endpoint
## - Rate limit headers (X-RateLimit-*)

# Rate limit configuration (requests per minute unless otherwise specified)
const DEFAULT_RATE_LIMIT: int = 100  # requests per minute
const RATE_LIMIT_WINDOW: float = 60.0  # 60 seconds

# IP banning configuration
const BAN_THRESHOLD: int = 5  # Number of violations before ban
const BAN_WINDOW: float = 600.0  # 10 minutes window to track violations
const BAN_DURATION: float = 3600.0  # 1 hour ban duration

# Cleanup configuration
const CLEANUP_INTERVAL: float = 300.0  # 5 minutes
const BUCKET_EXPIRY: float = 3600.0  # Remove buckets unused for 1 hour

# Per-endpoint rate limits (overrides default)
const ENDPOINT_LIMITS: Dictionary = {
	"/scene": 30,  # Scene loading is expensive
	"/scene/reload": 20,  # Reloading is expensive
	"/scenes": 60,  # Listing scenes is less expensive
	"/scene/history": 100,  # History is cheap
	"/auth/rotate": 10,  # Token rotation should be limited
	"/auth/refresh": 30,  # Token refresh
	"/admin/metrics": 60,  # Metrics
	"/admin/config": 10,  # Config changes
}

# Rate limit buckets: IP:endpoint -> {tokens, last_update, last_request_time, limit}
var _rate_limit_buckets: Dictionary = {}

# IP violation tracking: IP -> [violation_timestamps]
var _ip_violations: Dictionary = {}

# Banned IPs: IP -> {banned_at, ban_expires, violation_count, reason}
var _banned_ips: Dictionary = {}

# Cleanup timer
var _last_cleanup: float = 0.0

# Statistics
var _total_requests: int = 0
var _total_blocked: int = 0
var _total_violations: int = 0
var _total_bans: int = 0


## Check if request is allowed (main entry point)
func check_rate_limit(client_ip: String, endpoint: String) -> Dictionary:
	_total_requests += 1
	var current_time = Time.get_unix_time_from_system()

	# Check if IP is banned
	if _is_ip_banned(client_ip, current_time):
		_total_blocked += 1
		var ban_info = _banned_ips[client_ip]
		var remaining = ban_info.ban_expires - current_time

		return {
			"allowed": false,
			"reason": "ip_banned",
			"message": "IP address temporarily banned for rate limit violations",
			"retry_after": int(remaining),
			"ban_expires": ban_info.ban_expires,
			"violation_count": ban_info.violation_count
		}

	# Get rate limit for endpoint
	var limit = _get_endpoint_limit(endpoint)
	var bucket_key = _get_bucket_key(client_ip, endpoint)

	# Get or create bucket
	var bucket = _get_or_create_bucket(bucket_key, limit, current_time)

	# Calculate time elapsed since last update
	var time_elapsed = current_time - bucket.last_update

	# Refill tokens based on time elapsed (token bucket algorithm)
	var tokens_to_add = time_elapsed * (float(limit) / RATE_LIMIT_WINDOW)
	bucket.tokens = min(bucket.tokens + tokens_to_add, float(limit))
	bucket.last_update = current_time
	bucket.last_request_time = current_time

	# Check if we have tokens available
	if bucket.tokens >= 1.0:
		# Allow request and consume one token
		bucket.tokens -= 1.0

		return {
			"allowed": true,
			"limit": limit,
			"remaining": int(bucket.tokens),
			"reset": int(current_time + RATE_LIMIT_WINDOW)
		}
	else:
		# Rate limit exceeded
		_total_blocked += 1
		_record_violation(client_ip, endpoint, current_time)

		# Calculate retry_after (time needed to accumulate 1 token)
		var tokens_needed = 1.0 - bucket.tokens
		var retry_after = tokens_needed * (RATE_LIMIT_WINDOW / float(limit))

		return {
			"allowed": false,
			"reason": "rate_limit_exceeded",
			"message": "Rate limit exceeded for endpoint: %s" % endpoint,
			"retry_after": int(ceil(retry_after)),
			"limit": limit,
			"remaining": 0,
			"reset": int(current_time + RATE_LIMIT_WINDOW)
		}


## Get rate limit headers for HTTP response
func get_rate_limit_headers(result: Dictionary) -> Dictionary:
	var headers = {
		"X-RateLimit-Limit": str(result.get("limit", DEFAULT_RATE_LIMIT)),
		"X-RateLimit-Remaining": str(result.get("remaining", 0)),
		"X-RateLimit-Reset": str(result.get("reset", 0))
	}

	# Add Retry-After header if rate limited
	if not result.get("allowed", true):
		headers["Retry-After"] = str(result.get("retry_after", 60))

	return headers


## Check if IP is banned
func _is_ip_banned(client_ip: String, current_time: float) -> bool:
	if not _banned_ips.has(client_ip):
		return false

	var ban_info = _banned_ips[client_ip]

	# Check if ban has expired
	if current_time >= ban_info.ban_expires:
		# Remove expired ban
		_banned_ips.erase(client_ip)
		print("[RateLimiter] Ban expired for IP: ", client_ip)
		return false

	return true


## Record a rate limit violation
func _record_violation(client_ip: String, endpoint: String, current_time: float) -> void:
	_total_violations += 1

	# Initialize violations array if needed
	if not _ip_violations.has(client_ip):
		_ip_violations[client_ip] = []

	# Add violation timestamp
	_ip_violations[client_ip].append(current_time)

	# Remove old violations outside the ban window
	_ip_violations[client_ip] = _ip_violations[client_ip].filter(
		func(timestamp): return current_time - timestamp < BAN_WINDOW
	)

	# Check if threshold exceeded
	var violation_count = _ip_violations[client_ip].size()
	if violation_count >= BAN_THRESHOLD:
		_ban_ip(client_ip, current_time, violation_count, endpoint)


## Ban an IP address
func _ban_ip(client_ip: String, current_time: float, violation_count: int, endpoint: String) -> void:
	_total_bans += 1

	var ban_info = {
		"banned_at": current_time,
		"ban_expires": current_time + BAN_DURATION,
		"violation_count": violation_count,
		"reason": "rate_limit_abuse",
		"endpoint": endpoint
	}

	_banned_ips[client_ip] = ban_info

	# Clear violations since IP is now banned
	_ip_violations.erase(client_ip)

	# Log the ban
	push_warning("[RateLimiter] BANNED IP: %s for %d violations on endpoint %s (ban expires in %.0f seconds)" % [
		client_ip,
		violation_count,
		endpoint,
		BAN_DURATION
	])

	print("[RateLimiter] Ban details: ", ban_info)


## Get rate limit for specific endpoint
func _get_endpoint_limit(endpoint: String) -> int:
	return ENDPOINT_LIMITS.get(endpoint, DEFAULT_RATE_LIMIT)


## Get bucket key for IP and endpoint
func _get_bucket_key(client_ip: String, endpoint: String) -> String:
	return "%s::%s" % [client_ip, endpoint]


## Get or create rate limit bucket
func _get_or_create_bucket(bucket_key: String, limit: int, current_time: float) -> Dictionary:
	if not _rate_limit_buckets.has(bucket_key):
		_rate_limit_buckets[bucket_key] = {
			"tokens": float(limit),  # Start with full bucket
			"last_update": current_time,
			"last_request_time": current_time,
			"limit": limit
		}

	return _rate_limit_buckets[bucket_key]


## Cleanup old buckets and expired bans (call periodically)
func cleanup() -> void:
	var current_time = Time.get_unix_time_from_system()

	# Skip if cleanup was done recently
	if current_time - _last_cleanup < CLEANUP_INTERVAL:
		return

	_last_cleanup = current_time

	var initial_bucket_count = _rate_limit_buckets.size()
	var initial_ban_count = _banned_ips.size()

	# Remove old unused buckets
	var buckets_to_remove = []
	for bucket_key in _rate_limit_buckets:
		var bucket = _rate_limit_buckets[bucket_key]
		if current_time - bucket.last_request_time > BUCKET_EXPIRY:
			buckets_to_remove.append(bucket_key)

	for bucket_key in buckets_to_remove:
		_rate_limit_buckets.erase(bucket_key)

	# Remove expired bans
	var bans_to_remove = []
	for ip in _banned_ips:
		if current_time >= _banned_ips[ip].ban_expires:
			bans_to_remove.append(ip)

	for ip in bans_to_remove:
		_banned_ips.erase(ip)

	# Remove old violation records
	var violations_to_remove = []
	for ip in _ip_violations:
		# Filter out old violations
		_ip_violations[ip] = _ip_violations[ip].filter(
			func(timestamp): return current_time - timestamp < BAN_WINDOW
		)

		# If no violations left, mark for removal
		if _ip_violations[ip].is_empty():
			violations_to_remove.append(ip)

	for ip in violations_to_remove:
		_ip_violations.erase(ip)

	# Log cleanup results if anything was cleaned
	if buckets_to_remove.size() > 0 or bans_to_remove.size() > 0 or violations_to_remove.size() > 0:
		print("[RateLimiter] Cleanup completed:")
		print("  Removed %d old buckets (total: %d -> %d)" % [
			buckets_to_remove.size(),
			initial_bucket_count,
			_rate_limit_buckets.size()
		])
		print("  Removed %d expired bans (total: %d -> %d)" % [
			bans_to_remove.size(),
			initial_ban_count,
			_banned_ips.size()
		])
		print("  Removed %d stale violation records" % violations_to_remove.size())


## Get statistics
func get_stats() -> Dictionary:
	return {
		"total_requests": _total_requests,
		"total_blocked": _total_blocked,
		"total_violations": _total_violations,
		"total_bans": _total_bans,
		"active_buckets": _rate_limit_buckets.size(),
		"active_bans": _banned_ips.size(),
		"tracked_violations": _ip_violations.size(),
		"block_rate": (float(_total_blocked) / float(_total_requests) * 100.0) if _total_requests > 0 else 0.0
	}


## Get banned IPs list
func get_banned_ips() -> Array:
	var result = []
	var current_time = Time.get_unix_time_from_system()

	for ip in _banned_ips:
		var ban_info = _banned_ips[ip].duplicate()
		ban_info["ip"] = ip
		ban_info["remaining_seconds"] = int(ban_info.ban_expires - current_time)
		result.append(ban_info)

	return result


## Get violation history for an IP
func get_ip_violations(client_ip: String) -> Dictionary:
	if not _ip_violations.has(client_ip):
		return {
			"ip": client_ip,
			"violations": [],
			"violation_count": 0,
			"is_banned": _banned_ips.has(client_ip)
		}

	return {
		"ip": client_ip,
		"violations": _ip_violations[client_ip].duplicate(),
		"violation_count": _ip_violations[client_ip].size(),
		"is_banned": _banned_ips.has(client_ip)
	}


## Manually ban an IP (admin action)
func manually_ban_ip(client_ip: String, duration_seconds: float = BAN_DURATION, reason: String = "manual_ban") -> void:
	var current_time = Time.get_unix_time_from_system()

	_banned_ips[client_ip] = {
		"banned_at": current_time,
		"ban_expires": current_time + duration_seconds,
		"violation_count": 0,
		"reason": reason,
		"endpoint": "manual"
	}

	print("[RateLimiter] Manually banned IP: %s for %.0f seconds (reason: %s)" % [
		client_ip,
		duration_seconds,
		reason
	])


## Manually unban an IP (admin action)
func unban_ip(client_ip: String) -> bool:
	if _banned_ips.has(client_ip):
		_banned_ips.erase(client_ip)
		_ip_violations.erase(client_ip)
		print("[RateLimiter] Manually unbanned IP: ", client_ip)
		return true
	return false


## Reset all rate limiting state (admin action - use with caution)
func reset_all() -> void:
	_rate_limit_buckets.clear()
	_ip_violations.clear()
	_banned_ips.clear()
	_total_requests = 0
	_total_blocked = 0
	_total_violations = 0
	_total_bans = 0
	print("[RateLimiter] All rate limiting state reset")


## Get detailed information for debugging
func get_debug_info() -> Dictionary:
	return {
		"stats": get_stats(),
		"banned_ips": get_banned_ips(),
		"config": {
			"default_rate_limit": DEFAULT_RATE_LIMIT,
			"rate_limit_window": RATE_LIMIT_WINDOW,
			"ban_threshold": BAN_THRESHOLD,
			"ban_window": BAN_WINDOW,
			"ban_duration": BAN_DURATION,
			"cleanup_interval": CLEANUP_INTERVAL,
			"bucket_expiry": BUCKET_EXPIRY,
			"endpoint_limits": ENDPOINT_LIMITS
		}
	}
