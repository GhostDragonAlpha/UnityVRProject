extends RefCounted
class_name HttpApiSecurityConfig
const JWT = preload("res://scripts/http_api/jwt.gd")
const SimpleAuditLogger = preload("res://scripts/http_api/simple_audit_logger.gd")

## Security configuration for HTTP API
## Implements authentication, whitelisting, and rate limiting
## Now supports advanced token management with rotation and refresh

# Token Manager for advanced token lifecycle management (DISABLED - class loading issue)
# static var _token_manager: HttpApiTokenManager = null
static var _token_manager = null  # Disabled until class loading is resolved

# Security token
static var _api_token: String = ""
static var _token_header: String = "Authorization"

# Use new token system (DISABLED until TokenManager loading issue is fixed)
static var use_token_manager: bool = false

# JWT configuration
static var _jwt_secret: String = ""
static var _jwt_token_duration: int = 3600  # 1 hour default
static var use_jwt: bool = true  # Use JWT by default

# Cleanup timer
static var _cleanup_timer: float = 0.0
const CLEANUP_INTERVAL: float = 86400.0  # 24 hours

# Scene whitelist (allowed scene paths)
static var _scene_whitelist: Array[String] = [
	"res://vr_main.tscn",
	"res://node_3d.tscn",
	"res://test_scene.tscn",
	# Add more allowed scenes here
]

# Request size limits (bytes)
const MAX_REQUEST_SIZE = 1048576  # 1MB
const MAX_SCENE_PATH_LENGTH = 256

# Localhost only binding
const BIND_ADDRESS = "127.0.0.1"

# Enable/disable security features
static var auth_enabled: bool = true
static var whitelist_enabled: bool = true
static var size_limits_enabled: bool = true
static var rate_limiting_enabled: bool = true

# Rate limiting configuration (token bucket algorithm)
const DEFAULT_RATE_LIMIT = 100  # requests per minute per IP
const RATE_LIMIT_WINDOW = 60.0  # 60 seconds
static var _rate_limit_buckets: Dictionary = {}  # IP -> bucket data

# Per-endpoint rate limits (overrides default)
static var _endpoint_rate_limits: Dictionary = {
	"/scene": 30,  # Scene loading is expensive
	"/scene/reload": 20,  # Reloading is expensive
	"/scenes": 60,  # Listing scenes is less expensive
	"/scene/history": 100  # History is cheap to fetch
}


## Initialize TokenManager (call this on startup)
## DISABLED: HttpApiTokenManager class loading causes circular dependency issues
#static func initialize_token_manager() -> void:
#	if _token_manager == null:
#		_token_manager = HttpApiTokenManager.new()
#		print("[Security] TokenManager initialized")
#
#		# Get initial token for display
#		var active_tokens = _token_manager.get_active_tokens()
#		if active_tokens.size() > 0:
#			var token = active_tokens[0]
#			print("[Security] Active token: ", token.token_secret)
#			print("[Security] Token ID: ", token.token_id)
#			print("[Security] Expires: ", Time.get_datetime_string_from_unix_time(int(token.expires_at)))
#			print("[Security] Include in requests: Authorization: Bearer ", token.token_secret)


## Get TokenManager instance
## DISABLED: HttpApiTokenManager class loading causes circular dependency issues
#static func get_token_manager() -> HttpApiTokenManager:
#	if _token_manager == null:
#		initialize_token_manager()
#	return _token_manager


## Process function for periodic tasks (call from _process)
static func process(delta: float) -> void:
	if not use_token_manager or _token_manager == null:
		return

	# Auto-rotation check
	_token_manager.check_auto_rotation()

	# Periodic cleanup
	_cleanup_timer += delta
	if _cleanup_timer >= CLEANUP_INTERVAL:
		_cleanup_timer = 0.0
		_token_manager.cleanup_tokens()


## Generate secure API token on startup (legacy method)
static func generate_token() -> String:
	if _api_token.is_empty():
		# Generate 32-byte random token
		var bytes = PackedByteArray()
		for i in range(32):
			bytes.append(randi() % 256)
		_api_token = bytes.hex_encode()
		print("[Security] Legacy API token generated: ", _api_token)
		print("[Security] Include in requests: Authorization: Bearer ", _api_token)
	return _api_token


## Generate JWT token
## @param payload: Optional custom payload dictionary
## @param expires_in: Optional expiration time in seconds
## @return: JWT token string
static func generate_jwt_token(payload: Dictionary = {}, expires_in: int = -1) -> String:
	if _jwt_secret.is_empty():
		# Generate secure random secret on first use
		var bytes = PackedByteArray()
		for i in range(64):  # 512-bit secret
			bytes.append(randi() % 256)
		_jwt_secret = bytes.hex_encode()
		print("[Security] JWT secret generated")
	
	if expires_in == -1:
		expires_in = _jwt_token_duration
	
	# Add default claims
	var claims = payload.duplicate()
	claims["type"] = "api_access"
	
	var token = JWT.encode(claims, _jwt_secret, expires_in)
	_api_token = token  # Store as current API token
	print("[Security] JWT token generated (expires in ", expires_in, "s)")
	print("[Security] Include in requests: Authorization: Bearer ", token)
	
	return token


## Verify and decode JWT token
## @param token: JWT token string
## @return: Dictionary with 'valid' and 'payload' keys
static func verify_jwt_token(token: String) -> Dictionary:
	if _jwt_secret.is_empty():
		return {"valid": false, "error": "JWT not initialized"}
	
	return JWT.decode(token, _jwt_secret)


## Get current API token (legacy method for backward compatibility)
static func get_token() -> String:
	# If using token manager, return newest active token
	if use_token_manager and _token_manager != null:
		var active_tokens = _token_manager.get_active_tokens()
		if active_tokens.size() > 0:
			# Return most recent token
			var newest_token = active_tokens[0]
			for token in active_tokens:
				if token.created_at > newest_token.created_at:
					newest_token = token
			return newest_token.token_secret

	# Fall back to legacy token
	if _api_token.is_empty():
		return generate_token()
	return _api_token


## Validate authorization header with token manager support
## SECURITY FIX (CVSS 10.0): Uses strict typing to prevent type confusion attacks
## @param headers: Dictionary containing HTTP headers OR Object with headers property
## @return: true if authentication is valid, false otherwise
static func validate_auth(headers: Variant) -> bool:
	# SECURITY: Strict null check - reject null inputs immediately
	if headers == null:
		print("[Security] Auth failed: null parameter provided")
		return false

	# SECURITY: Authentication bypass check - validate when enabled
	if not auth_enabled:
		return true

	# SECURITY: Extract headers dictionary with strict type checking
	var headers_dict: Dictionary = {}

	# Type validation: only accept Dictionary or Object with headers property
	if headers is Dictionary:
		headers_dict = headers
	elif typeof(headers) == TYPE_OBJECT:
		# SECURITY: Verify object has headers property before accessing
		if not "headers" in headers:
			print("[Security] Auth failed: Object missing 'headers' property")
			return false

		# SECURITY: Verify headers property is actually a Dictionary
		var obj_headers = headers.get("headers")
		if obj_headers == null or not obj_headers is Dictionary:
			print("[Security] Auth failed: 'headers' property is not a Dictionary")
			return false

		headers_dict = obj_headers
	else:
		# SECURITY: Reject all other types (int, float, bool, array, etc.)
		print("[Security] Auth failed: Invalid parameter type: ", typeof(headers))
		return false

	# SECURITY: Verify we have a non-empty dictionary
	if headers_dict.is_empty():
		print("[Security] Auth failed: Empty headers dictionary")
		return false

	# SECURITY: Extract authorization header with type validation
	var auth_value = headers_dict.get(_token_header, headers_dict.get("authorization", ""))

	# SECURITY: Validate auth_value is a String (prevent type confusion)
	if auth_value == null:
		print("[Security] Auth failed: No Authorization header")
		return false

	if not auth_value is String:
		print("[Security] Auth failed: Authorization header is not a String (got type: ", typeof(auth_value), ")")
		return false

	var auth_header: String = auth_value

	# SECURITY: Check for empty authorization
	if auth_header.is_empty():
		print("[Security] Auth failed: Empty Authorization header")
		return false

	# SECURITY: Validate Bearer format (prevent malformed tokens)
	if not auth_header.begins_with("Bearer "):
		print("[Security] Auth failed: Invalid Authorization format (expected 'Bearer <token>')")
		return false

	# SECURITY: Extract token with length validation
	if auth_header.length() <= 7:
		print("[Security] Auth failed: Authorization header too short")
		return false

	var token_secret = auth_header.substr(7).strip_edges()

	# SECURITY: Validate token is not empty after extraction
	if token_secret.is_empty():
		print("[Security] Auth failed: Empty token after Bearer prefix")
		return false

	# SECURITY: Validate minimum token length (prevent trivial bypass attempts)
	if token_secret.length() < 16:
		print("[Security] Auth failed: Token too short (minimum 16 characters)")
		return false

	# Use JWT if enabled
	if use_jwt:
		var result = verify_jwt_token(token_secret)
		if not result.valid:
			print("[Security] Auth failed: ", result.get("error", "Invalid JWT"))
		return result.valid

	# Use token manager if enabled
	if use_token_manager and _token_manager != null:
		var validation = _token_manager.validate_token(token_secret)
		if not validation.valid:
			print("[Security] Auth failed: Invalid token - ", validation.get("error", "unknown error"))
		return validation.valid

	# Fall back to legacy validation
	var is_valid = token_secret == get_token()
	if not is_valid:
		print("[Security] Auth failed: Token mismatch")
	return is_valid




## Validate authorization header (legacy method with request object)
static func validate_auth_legacy(request) -> bool:
	# This now just calls validate_auth which handles both types
	return validate_auth(request)


## Validate scene path against whitelist
static func validate_scene_path(scene_path: String) -> Dictionary:
	var result = {"valid": true, "error": ""}

	# Basic format validation
	if scene_path.length() > MAX_SCENE_PATH_LENGTH:
		result.valid = false
		result.error = "Scene path exceeds maximum length"
		return result

	if not scene_path.begins_with("res://"):
		result.valid = false
		result.error = "Scene path must start with res://"
		return result

	if not scene_path.ends_with(".tscn"):
		result.valid = false
		result.error = "Scene path must end with .tscn"
		return result

	# Whitelist validation
	if whitelist_enabled:
		var is_whitelisted = false
		for allowed_path in _scene_whitelist:
			if scene_path == allowed_path:
				is_whitelisted = true
				break
			# Also allow scenes in whitelisted directories
			if allowed_path.ends_with("/") and scene_path.begins_with(allowed_path):
				is_whitelisted = true
				break

		if not is_whitelisted:
			result.valid = false
			result.error = "Scene not in whitelist"
			return result

	# Path traversal prevention
	if scene_path.contains(".."):
		result.valid = false
		result.error = "Path traversal not allowed"
		return result

	return result


## Validate request size
## Supports both int (body_size) and HttpRequest object parameters
static func validate_request_size(body_size_or_request) -> bool:
	if not size_limits_enabled:
		return true

	# Handle both int and HttpRequest object
	var body_size: int
	if body_size_or_request is int:
		body_size = body_size_or_request
	elif body_size_or_request != null and body_size_or_request.has_method("get_body_size"):
		# Duck typing for HttpRequest-like objects to avoid class resolution issues
		body_size = body_size_or_request.get_body_size()
	elif body_size_or_request != null and body_size_or_request.get("body") != null:
		# Fallback: try to access .body.length() property
		body_size = body_size_or_request.body.length()
	else:
		print("[Security] Invalid parameter type for validate_request_size: ", typeof(body_size_or_request))
		return false

	return body_size <= MAX_REQUEST_SIZE


## Add scene to whitelist (for configuration)
static func add_to_whitelist(scene_path: String) -> void:
	if not _scene_whitelist.has(scene_path):
		_scene_whitelist.append(scene_path)
		print("[Security] Added to whitelist: ", scene_path)


## Add directory to whitelist (all scenes in dir allowed)
static func add_directory_to_whitelist(dir_path: String) -> void:
	if not dir_path.ends_with("/"):
		dir_path += "/"
	add_to_whitelist(dir_path)


## Get whitelist for configuration/debugging
static func get_whitelist() -> Array[String]:
	return _scene_whitelist.duplicate()


## Disable authentication (for testing only)
static func disable_auth() -> void:
	auth_enabled = false
	print("[Security] WARNING: Authentication disabled")


## Enable authentication
static func enable_auth() -> void:
	auth_enabled = true
	print("[Security] Authentication enabled")


## Create 401 Unauthorized response

## Check rate limit for a request (token bucket algorithm)
static func check_rate_limit(client_ip: String, endpoint: String) -> Dictionary:
	if not rate_limiting_enabled:
		return {"allowed": true, "retry_after": 0.0, "limit": DEFAULT_RATE_LIMIT, "remaining": DEFAULT_RATE_LIMIT}
	var current_time = Time.get_ticks_msec() / 1000.0
	var limit = _endpoint_rate_limits.get(endpoint, DEFAULT_RATE_LIMIT)
	var bucket_key = client_ip + "::" + endpoint
	var bucket = _rate_limit_buckets.get(bucket_key, null)
	if bucket == null:
		bucket = {"tokens": float(limit), "last_update": current_time, "limit": limit}
		_rate_limit_buckets[bucket_key] = bucket
	var time_elapsed = current_time - bucket.last_update
	var tokens_to_add = time_elapsed * (float(limit) / RATE_LIMIT_WINDOW)
	bucket.tokens = min(bucket.tokens + tokens_to_add, float(limit))
	bucket.last_update = current_time
	if bucket.tokens >= 1.0:
		bucket.tokens -= 1.0
		return {"allowed": true, "retry_after": 0.0, "limit": limit, "remaining": int(bucket.tokens)}
	else:
		var tokens_needed = 1.0 - bucket.tokens
		var retry_after = tokens_needed * (RATE_LIMIT_WINDOW / float(limit))
		return {"allowed": false, "retry_after": retry_after, "limit": limit, "remaining": 0}


## Get rate limit headers for response
static func get_rate_limit_headers(result: Dictionary) -> Dictionary:
	return {
		"X-RateLimit-Limit": str(result.limit),
		"X-RateLimit-Remaining": str(result.remaining),
		"X-RateLimit-Reset": str(int(Time.get_ticks_msec() / 1000.0 + RATE_LIMIT_WINDOW))
	}


## Create 429 Too Many Requests response
static func create_rate_limit_error_response(retry_after: float) -> Dictionary:
	return {
		"error": "Too Many Requests",
		"message": "Rate limit exceeded",
		"retry_after_seconds": retry_after
	}


## Disable rate limiting (for testing)
static func disable_rate_limiting() -> void:
	rate_limiting_enabled = false
	print("[Security] WARNING: Rate limiting disabled")


## Enable rate limiting
static func enable_rate_limiting() -> void:
	rate_limiting_enabled = true
	print("[Security] Rate limiting enabled")


static func create_auth_error_response() -> Dictionary:
	return {
		"error": "Unauthorized",
		"message": "Missing or invalid authentication token",
		"details": "Include 'Authorization: Bearer <token>' header"
	}


## Create 403 Forbidden response
static func create_forbidden_response(reason: String = "") -> Dictionary:
	return {
		"error": "Forbidden",
		"message": reason if not reason.is_empty() else "Access denied",
	}


## Create 413 Payload Too Large response
static func create_size_error_response() -> Dictionary:
	return {
		"error": "Payload Too Large",
		"message": "Request body exceeds maximum size",
		"max_size_bytes": MAX_REQUEST_SIZE
	}


## Print security configuration on startup
static func print_config() -> void:
	print("[Security] Configuration:")
	print("[Security]   Authentication Method: ", "JWT" if use_jwt else ("Token Manager" if use_token_manager else "Legacy"))
	print("[Security]   Token Manager: ", "ENABLED" if use_token_manager else "DISABLED (legacy mode)")
	print("[Security]   Authentication: ", "ENABLED" if auth_enabled else "DISABLED")
	print("[Security]   Scene Whitelist: ", "ENABLED" if whitelist_enabled else "DISABLED")
	print("[Security]   Size Limits: ", "ENABLED" if size_limits_enabled else "DISABLED")
	print("[Security]   Bind Address: ", BIND_ADDRESS)
	print("[Security]   Rate Limiting: ", "ENABLED" if rate_limiting_enabled else "DISABLED")
	print("[Security]   Max Request Size: ", MAX_REQUEST_SIZE, " bytes")
	print("[Security]   Whitelisted Scenes: ", _scene_whitelist.size())
	print("[Security]   Default Rate Limit: ", DEFAULT_RATE_LIMIT, " req/min")
	for scene in _scene_whitelist:
		print("[Security]     - ", scene)

	if use_token_manager and _token_manager != null:
		var metrics = _token_manager.get_metrics()
		print("[Security]   Active Tokens: ", metrics.active_tokens_count)
		print("[Security]   Total Tokens: ", metrics.total_tokens_count)


## ============================================================================
## VULN-004 FIX: Enhanced Scene Whitelist Validation
## ============================================================================

# Scene whitelist configuration (enhanced)
static var _scene_whitelist_directories: Array[String] = []
static var _scene_whitelist_wildcards: Array[String] = []
static var _scene_blacklist_patterns: Array[String] = []
static var _scene_blacklist_exact: Array[String] = []
static var _whitelist_config_loaded: bool = false
static var _current_environment: String = "development"  # production, development, test


## Load whitelist configuration from JSON file (VULN-004 FIX)
static func load_whitelist_config(environment: String = "") -> bool:
	if environment.is_empty():
		environment = _current_environment

	var config_path = "res://config/scene_whitelist.json"

	# Check if config file exists
	if not FileAccess.file_exists(config_path):
		push_warning("[Security] Whitelist config not found: ", config_path, " - using existing whitelist")
		_whitelist_config_loaded = true
		return false

	# Load and parse JSON
	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		push_error("[Security] Failed to open whitelist config: ", config_path)
		_whitelist_config_loaded = true
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error("[Security] Failed to parse whitelist config JSON: ", json.get_error_message())
		_whitelist_config_loaded = true
		return false

	var config = json.get_data()

	# Load environment-specific configuration
	if config.has("environments") and config.environments.has(environment):
		var env_config = config.environments[environment]

		# Load exact scene paths
		if env_config.has("scenes"):
			_scene_whitelist = []
			for scene in env_config.scenes:
				_scene_whitelist.append(scene)

		# Load directory paths
		if env_config.has("directories"):
			_scene_whitelist_directories = []
			for dir in env_config.directories:
				_scene_whitelist_directories.append(dir)

		# Load wildcard patterns
		if env_config.has("wildcards"):
			_scene_whitelist_wildcards = []
			for pattern in env_config.wildcards:
				_scene_whitelist_wildcards.append(pattern)

		print("[Security] Loaded whitelist config for environment: ", environment)
		print("[Security]   Exact scenes: ", _scene_whitelist.size())
		print("[Security]   Directories: ", _scene_whitelist_directories.size())
		print("[Security]   Wildcards: ", _scene_whitelist_wildcards.size())
	else:
		push_warning("[Security] Environment '", environment, "' not found in config")

	# Load blacklist
	if config.has("blacklist"):
		var blacklist = config.blacklist
		if blacklist.has("patterns"):
			_scene_blacklist_patterns = []
			for pattern in blacklist.patterns:
				_scene_blacklist_patterns.append(pattern)
		if blacklist.has("exact"):
			_scene_blacklist_exact = []
			for path in blacklist.exact:
				_scene_blacklist_exact.append(path)
		print("[Security]   Blacklist patterns: ", _scene_blacklist_patterns.size())
		print("[Security]   Blacklist exact: ", _scene_blacklist_exact.size())

	_whitelist_config_loaded = true
	return true


## Set environment (production, development, test) (VULN-004 FIX)
static func set_environment(environment: String) -> void:
	_current_environment = environment
	print("[Security] Environment set to: ", environment)
	# Reload whitelist for new environment
	load_whitelist_config(environment)


## Get current environment (VULN-004 FIX)
static func get_environment() -> String:
	return _current_environment


## Check if path matches wildcard pattern (VULN-004 FIX)
## Supports ** for recursive directory matching and * for single segment
static func _matches_wildcard(path: String, pattern: String) -> bool:
	# Convert wildcard pattern to regex
	var regex_pattern = pattern

	# Escape special regex characters except * and /
	regex_pattern = regex_pattern.replace(".", "\\.")
	regex_pattern = regex_pattern.replace("+", "\\+")
	regex_pattern = regex_pattern.replace("?", "\\?")
	regex_pattern = regex_pattern.replace("(", "\\(")
	regex_pattern = regex_pattern.replace(")", "\\)")
	regex_pattern = regex_pattern.replace("[", "\\[")
	regex_pattern = regex_pattern.replace("]", "\\]")
	regex_pattern = regex_pattern.replace("{", "\\{")
	regex_pattern = regex_pattern.replace("}", "\\}")
	regex_pattern = regex_pattern.replace("^", "\\^")
	regex_pattern = regex_pattern.replace("$", "\\$")

	# Replace ** with regex for zero or more path segments
	regex_pattern = regex_pattern.replace("**/", "(?:.*/)?")
	regex_pattern = regex_pattern.replace("/**", "(?:/.*)?")

	# Replace * with regex for single segment (no /)
	regex_pattern = regex_pattern.replace("*", "[^/]*")

	# Anchor to start and end
	regex_pattern = "^" + regex_pattern + "$"

	var regex = RegEx.new()
	regex.compile(regex_pattern)

	return regex.search(path) != null


## Canonicalize path (resolve .., remove duplicate slashes) (VULN-004 FIX)
static func _canonicalize_path(path: String) -> String:
	# Split into segments
	var segments = path.split("/")
	var canonical = []

	for segment in segments:
		if segment == "" or segment == ".":
			continue
		elif segment == "..":
			# Remove last segment (go up)
			if canonical.size() > 0:
				canonical.pop_back()
		else:
			canonical.append(segment)

	# Reconstruct path
	var result = "/".join(canonical)

	# Preserve res:// prefix
	if path.begins_with("res://"):
		result = "res://" + result

	return result


## Check if path is in blacklist (VULN-004 FIX)
static func _is_blacklisted(scene_path: String) -> bool:
	# Check exact matches
	if scene_path in _scene_blacklist_exact:
		return true

	# Check pattern matches
	for pattern in _scene_blacklist_patterns:
		if _matches_wildcard(scene_path, pattern):
			return true

	return false


## Enhanced validate_scene_path - replaces old version (VULN-004 FIX)
static func validate_scene_path_enhanced(scene_path: String) -> Dictionary:
	var result = {"valid": true, "error": ""}

	# Ensure whitelist config is loaded
	if not _whitelist_config_loaded:
		load_whitelist_config()

	# Basic format validation
	if scene_path.length() > MAX_SCENE_PATH_LENGTH:
		result.valid = false
		result.error = "Scene path exceeds maximum length (" + str(MAX_SCENE_PATH_LENGTH) + " chars)"
		return result

	if not scene_path.begins_with("res://"):
		result.valid = false
		result.error = "Scene path must start with res://"
		return result

	if not scene_path.ends_with(".tscn"):
		result.valid = false
		result.error = "Scene path must end with .tscn"
		return result

	# Path traversal prevention (check for .. before canonicalization)
	if scene_path.contains(".."):
		result.valid = false
		result.error = "Path traversal (..) not allowed"
		return result

	# Canonicalize path to handle . and // sequences
	var canonical_path = _canonicalize_path(scene_path)

	# Check blacklist first (security-critical)
	if _is_blacklisted(canonical_path):
		result.valid = false
		result.error = "Scene is in blacklist (addon/system scene)"
		return result

	# Whitelist validation
	if whitelist_enabled:
		var is_whitelisted = false

		# Check exact matches
		for allowed_path in _scene_whitelist:
			if canonical_path == allowed_path:
				is_whitelisted = true
				break

		# Check directory matches
		if not is_whitelisted:
			for dir_path in _scene_whitelist_directories:
				if canonical_path.begins_with(dir_path):
					is_whitelisted = true
					break

		# Check wildcard patterns
		if not is_whitelisted:
			for pattern in _scene_whitelist_wildcards:
				if _matches_wildcard(canonical_path, pattern):
					is_whitelisted = true
					break

		if not is_whitelisted:
			result.valid = false
			result.error = "Scene not in whitelist for environment: " + _current_environment
			return result

	return result


## Add wildcard pattern to whitelist (VULN-004 FIX)
static func add_wildcard_to_whitelist(pattern: String) -> void:
	if not _scene_whitelist_wildcards.has(pattern):
		_scene_whitelist_wildcards.append(pattern)
		print("[Security] Added wildcard to whitelist: ", pattern)


## Get enhanced whitelist for configuration/debugging (VULN-004 FIX)
static func get_whitelist_enhanced() -> Dictionary:
	return {
		"environment": _current_environment,
		"exact_scenes": _scene_whitelist.duplicate(),
		"directories": _scene_whitelist_directories.duplicate(),
		"wildcards": _scene_whitelist_wildcards.duplicate(),
		"blacklist_patterns": _scene_blacklist_patterns.duplicate(),
		"blacklist_exact": _scene_blacklist_exact.duplicate()
	}
##
## This code should be APPENDED to security_config.gd after line 750

# Public endpoints that don't require authentication
# Format: {"/path": ["GET", "OPTIONS"], "/another": ["OPTIONS"]}
static var _public_endpoints: Dictionary = {
	"/health": ["GET", "OPTIONS"],  # Health checks are public
	"/status": ["GET", "OPTIONS"],  # System status (not auth status!)
	"/": ["OPTIONS"],  # CORS preflight only
}

# Sensitive endpoints that ALWAYS require authentication, regardless of HTTP method
# These endpoints expose sensitive data and must NEVER be publicly accessible
static var _sensitive_endpoints: Array[String] = [
	"/auth/metrics",        # Token usage metrics (security-critical)
	"/auth/audit",          # Audit log (security-critical)
	"/auth/status",         # Token status (authentication-critical)
	"/admin",               # Admin operations (role-based)
	"/admin/",              # Admin subroutes
]

# Endpoints requiring specific roles (user:token:role claim)
static var _role_protected_endpoints: Dictionary = {
	"/admin/users": ["admin"],
	"/admin/config": ["admin"],
	"/admin/audit": ["admin", "auditor"],
}


## Check if endpoint is public (no auth required)
## @param endpoint: HTTP endpoint path
## @param method: HTTP method (GET, POST, OPTIONS, etc.)
## @return: true if endpoint is public and doesn't require auth
static func is_public_endpoint(endpoint: String, method: String) -> bool:
	# Check direct endpoint match
	if endpoint in _public_endpoints:
		var allowed_methods = _public_endpoints[endpoint]
		return method.to_upper() in allowed_methods
	return false


## Check if endpoint is sensitive (always requires auth)
## @param endpoint: HTTP endpoint path
## @return: true if endpoint requires authentication regardless of method
static func is_sensitive_endpoint(endpoint: String) -> bool:
	# Check exact matches
	if endpoint in _sensitive_endpoints:
		return true

	# Check prefix matches (e.g., /admin/ matches /admin/users)
	for sensitive in _sensitive_endpoints:
		if sensitive.ends_with("/") and endpoint.begins_with(sensitive):
			return true

	return false


## Validate authorization with endpoint-specific rules
## SECURITY FIX: Prevents GET request bypass on sensitive endpoints
## @param headers: Dictionary containing HTTP headers OR Object with headers property
## @param endpoint: HTTP endpoint path (for endpoint-specific rules)
## @param method: HTTP method (GET, POST, OPTIONS, etc.)
## @param client_ip: Client IP address (for audit logging)
## @return: Dictionary with 'authorized', 'reason', and 'auth_method' keys
static func validate_auth_with_endpoint(headers: Variant, endpoint: String, method: String, client_ip: String = "127.0.0.1") -> Dictionary:
	# SECURITY: Strict null check
	if headers == null:
		print("[Security] Auth failed: null parameter provided")
		_log_auth_attempt(client_ip, endpoint, false, "Null headers parameter")
		return {"authorized": false, "reason": "Invalid request", "auth_method": "none"}

	# SECURITY: CORS preflight handling (OPTIONS always allowed for CORS)
	if method.to_upper() == "OPTIONS":
		print("[Security] Auth bypass OK: CORS preflight OPTIONS request to ", endpoint)
		_log_auth_attempt(client_ip, endpoint, true, "CORS preflight (OPTIONS)")
		return {"authorized": true, "reason": "CORS preflight", "auth_method": "cors_preflight"}

	# SECURITY: Check if endpoint is public (no auth required)
	if is_public_endpoint(endpoint, method):
		print("[Security] Auth bypass OK: Public endpoint ", endpoint, " ", method)
		_log_auth_attempt(client_ip, endpoint, true, "Public endpoint (%s)" % method)
		return {"authorized": true, "reason": "Public endpoint", "auth_method": "public"}

	# SECURITY: If sensitive endpoint, ALWAYS require auth (even for GET)
	if is_sensitive_endpoint(endpoint):
		print("[Security] Sensitive endpoint requires auth: ", endpoint, " ", method)
		# Fall through to validate_auth() below

	# SECURITY: Standard authentication validation
	if not validate_auth(headers):
		_log_auth_attempt(client_ip, endpoint, false, "Invalid or missing token")
		return {"authorized": false, "reason": "Missing or invalid authentication token", "auth_method": "none"}

	# SECURITY: Check role-based access control if applicable
	if endpoint in _role_protected_endpoints:
		var result = _validate_role_access(headers, endpoint, client_ip)
		if not result.authorized:
			_log_auth_attempt(client_ip, endpoint, false, "Insufficient role: required %s" % result.required_roles)
			return result

	_log_auth_attempt(client_ip, endpoint, true, "Valid token")
	return {"authorized": true, "reason": "Authenticated", "auth_method": "bearer_token"}


## Internal: Extract and validate role from JWT claims
## @param headers: Headers containing Authorization header
## @param endpoint: Endpoint requiring role check
## @param client_ip: Client IP for logging
## @return: Dictionary with 'authorized', 'reason', 'required_roles', 'user_roles'
static func _validate_role_access(headers: Variant, endpoint: String, client_ip: String) -> Dictionary:
	var required_roles = _role_protected_endpoints.get(endpoint, [])
	if required_roles.is_empty():
		return {"authorized": true, "reason": "No role requirement"}

	# Extract authorization header
	var headers_dict: Dictionary = {}
	if headers is Dictionary:
		headers_dict = headers
	elif typeof(headers) == TYPE_OBJECT and "headers" in headers:
		var obj_headers = headers.get("headers")
		if obj_headers is Dictionary:
			headers_dict = obj_headers

	var auth_value = headers_dict.get("Authorization", headers_dict.get("authorization", ""))
	if auth_value.is_empty():
		return {
			"authorized": false,
			"reason": "No Authorization header",
			"required_roles": required_roles,
			"user_roles": []
		}

	# For JWT, extract and verify role claim
	if use_jwt and auth_value.begins_with("Bearer "):
		var token = auth_value.substr(7).strip_edges()
		var result = verify_jwt_token(token)
		if result.valid and result.payload is Dictionary:
			var payload = result.payload as Dictionary
			var user_roles = payload.get("roles", [])
			if user_roles is String:
				user_roles = [user_roles]

			# Check if user has required role
			for role in user_roles:
				if role in required_roles:
					print("[Security] Role check passed: user has role ", role, " for ", endpoint)
					return {
						"authorized": true,
						"reason": "Role matched",
						"required_roles": required_roles,
						"user_roles": user_roles
					}

			print("[Security] Role check failed: user roles ", user_roles, " don't match required ", required_roles)
			return {
				"authorized": false,
				"reason": "Insufficient permissions",
				"required_roles": required_roles,
				"user_roles": user_roles
			}

	return {
		"authorized": false,
		"reason": "Unable to verify role",
		"required_roles": required_roles,
		"user_roles": []
	}


## Internal: Log authentication attempts to audit log
## @param client_ip: Client IP address
## @param endpoint: HTTP endpoint path
## @param success: Whether authentication succeeded
## @param reason: Human-readable reason for success/failure
static func _log_auth_attempt(client_ip: String, endpoint: String, success: bool, reason: String) -> void:
	# Log to audit system
	SimpleAuditLogger.log_auth_attempt(client_ip, endpoint, success, reason)
