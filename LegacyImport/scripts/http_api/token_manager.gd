extends RefCounted
class_name HttpApiTokenManager

## Token Manager for API Token Rotation and Refresh
## Implements secure token lifecycle management with automatic rotation,
## refresh capabilities, and multi-token support for graceful transitions.

# Token data structure
class Token:
	var token_id: String  # UUID
	var token_secret: String  # 32-byte hex
	var created_at: float  # Unix timestamp
	var expires_at: float  # Unix timestamp
	var last_used_at: float  # Unix timestamp
	var revoked: bool = false
	var refresh_count: int = 0

	func _init(id: String, secret: String, created: float, expiry: float):
		token_id = id
		token_secret = secret
		created_at = created
		expires_at = expiry
		last_used_at = created
		revoked = false
		refresh_count = 0

	func to_dict() -> Dictionary:
		return {
			"token_id": token_id,
			"token_secret": token_secret,
			"created_at": created_at,
			"expires_at": expires_at,
			"last_used_at": last_used_at,
			"revoked": revoked,
			"refresh_count": refresh_count
		}

	static func from_dict(data: Dictionary) -> Token:
		var token = Token.new(
			data.get("token_id", ""),
			data.get("token_secret", ""),
			data.get("created_at", 0.0),
			data.get("expires_at", 0.0)
		)
		token.last_used_at = data.get("last_used_at", token.created_at)
		token.revoked = data.get("revoked", false)
		token.refresh_count = data.get("refresh_count", 0)
		return token

	func is_expired() -> bool:
		return Time.get_unix_time_from_system() >= expires_at

	func is_valid() -> bool:
		return not revoked and not is_expired()

	func update_last_used() -> void:
		last_used_at = Time.get_unix_time_from_system()

# Configuration
const TOKEN_STORAGE_PATH = "user://tokens/active_tokens.json"
const DEFAULT_TOKEN_LIFETIME_HOURS = 24
const ROTATION_OVERLAP_HOURS = 1  # Grace period for old token after rotation
const AUTO_ROTATION_ENABLED = true
const MAX_ACTIVE_TOKENS = 10  # Prevent unbounded growth

# Active tokens (keyed by token_secret for fast lookup)
var _active_tokens: Dictionary = {}  # token_secret -> Token

# Metrics
var _metrics = {
	"token_rotations_total": 0,
	"token_refreshes_total": 0,
	"token_revocations_total": 0,
	"expired_tokens_rejected_total": 0,
	"invalid_tokens_rejected_total": 0,
	"tokens_created_total": 0
}

# Auto-rotation state
var _last_rotation_time: float = 0.0
var _rotation_interval_seconds: float = DEFAULT_TOKEN_LIFETIME_HOURS * 3600

# Audit log
var _audit_log: Array[Dictionary] = []
const MAX_AUDIT_LOG_SIZE = 1000


func _init():
	print("[TokenManager] Initializing token management system")
	_ensure_storage_directory()
	_load_tokens()
	_migrate_legacy_token()
	_schedule_cleanup()


## Ensure storage directory exists
func _ensure_storage_directory() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("tokens"):
		dir.make_dir("tokens")
		print("[TokenManager] Created tokens storage directory")


## Generate a new token
func generate_token(lifetime_hours: float = DEFAULT_TOKEN_LIFETIME_HOURS) -> Token:
	var token_id = _generate_uuid()
	var token_secret = _generate_secret()
	var now = Time.get_unix_time_from_system()
	var expiry = now + (lifetime_hours * 3600)

	var token = Token.new(token_id, token_secret, now, expiry)
	_active_tokens[token_secret] = token

	_metrics.tokens_created_total += 1
	_audit_log_event("token_created", {"token_id": token_id, "expires_at": expiry})

	print("[TokenManager] Generated new token: ", token_id, " (expires: ", Time.get_datetime_string_from_unix_time(int(expiry)), ")")

	_save_tokens()
	return token


## Validate a token and update last used time
func validate_token(token_secret: String) -> Dictionary:
	var result = {
		"valid": false,
		"error": "",
		"token": null,
		"expires_in_seconds": 0
	}

	if not _active_tokens.has(token_secret):
		result.error = "Token not found"
		_metrics.invalid_tokens_rejected_total += 1
		return result

	var token: Token = _active_tokens[token_secret]

	if token.revoked:
		result.error = "Token has been revoked"
		_metrics.invalid_tokens_rejected_total += 1
		_audit_log_event("token_rejected", {"token_id": token.token_id, "reason": "revoked"})
		return result

	if token.is_expired():
		result.error = "Token has expired"
		_metrics.expired_tokens_rejected_total += 1
		_audit_log_event("token_rejected", {"token_id": token.token_id, "reason": "expired"})
		return result

	# Valid token - update last used
	token.update_last_used()
	result.valid = true
	result.token = token
	result.expires_in_seconds = int(token.expires_at - Time.get_unix_time_from_system())

	_save_tokens()  # Save updated last_used_at
	return result


## Rotate tokens - create new token and mark old one for grace period
func rotate_token(current_token_secret: String = "") -> Dictionary:
	var result = {
		"success": false,
		"new_token": null,
		"old_token_id": "",
		"grace_period_seconds": ROTATION_OVERLAP_HOURS * 3600,
		"error": ""
	}

	# If current token provided, validate it
	if not current_token_secret.is_empty():
		var validation = validate_token(current_token_secret)
		if not validation.valid:
			result.error = "Current token is invalid: " + validation.error
			return result
		result.old_token_id = validation.token.token_id

	# Generate new token with full lifetime
	var new_token = generate_token(DEFAULT_TOKEN_LIFETIME_HOURS)

	# If we have an old token, adjust its expiry to grace period
	if not current_token_secret.is_empty() and _active_tokens.has(current_token_secret):
		var old_token: Token = _active_tokens[current_token_secret]
		var grace_expiry = Time.get_unix_time_from_system() + (ROTATION_OVERLAP_HOURS * 3600)
		old_token.expires_at = min(old_token.expires_at, grace_expiry)
		print("[TokenManager] Old token ", old_token.token_id, " grace period until: ",
			  Time.get_datetime_string_from_unix_time(int(grace_expiry)))

	result.success = true
	result.new_token = new_token

	_metrics.token_rotations_total += 1
	_last_rotation_time = Time.get_unix_time_from_system()
	_audit_log_event("token_rotated", {
		"new_token_id": new_token.token_id,
		"old_token_id": result.old_token_id,
		"grace_period_hours": ROTATION_OVERLAP_HOURS
	})

	_save_tokens()
	print("[TokenManager] Token rotation complete. New token: ", new_token.token_id)

	return result


## Refresh a token - extend expiry and return same token
func refresh_token(token_secret: String, extension_hours: float = DEFAULT_TOKEN_LIFETIME_HOURS) -> Dictionary:
	var result = {
		"success": false,
		"token": null,
		"new_expiry": 0.0,
		"error": ""
	}

	var validation = validate_token(token_secret)
	if not validation.valid:
		result.error = validation.error
		return result

	var token: Token = validation.token
	var now = Time.get_unix_time_from_system()
	var new_expiry = now + (extension_hours * 3600)

	token.expires_at = new_expiry
	token.refresh_count += 1

	result.success = true
	result.token = token
	result.new_expiry = new_expiry

	_metrics.token_refreshes_total += 1
	_audit_log_event("token_refreshed", {
		"token_id": token.token_id,
		"new_expiry": new_expiry,
		"refresh_count": token.refresh_count
	})

	_save_tokens()
	print("[TokenManager] Token refreshed: ", token.token_id, " (new expiry: ",
		  Time.get_datetime_string_from_unix_time(int(new_expiry)), ")")

	return result


## Revoke a token
func revoke_token(token_secret: String, reason: String = "") -> Dictionary:
	var result = {
		"success": false,
		"token_id": "",
		"error": ""
	}

	if not _active_tokens.has(token_secret):
		result.error = "Token not found"
		return result

	var token: Token = _active_tokens[token_secret]
	token.revoked = true

	result.success = true
	result.token_id = token.token_id

	_metrics.token_revocations_total += 1
	_audit_log_event("token_revoked", {
		"token_id": token.token_id,
		"reason": reason if not reason.is_empty() else "manual_revocation"
	})

	_save_tokens()
	print("[TokenManager] Token revoked: ", token.token_id, " (reason: ", reason, ")")

	return result


## Get all active (non-revoked, non-expired) tokens
func get_active_tokens() -> Array[Token]:
	var active: Array[Token] = []
	for token in _active_tokens.values():
		if token.is_valid():
			active.append(token)
	return active


## Get metrics
func get_metrics() -> Dictionary:
	var metrics = _metrics.duplicate()
	metrics["active_tokens_count"] = get_active_tokens().size()
	metrics["total_tokens_count"] = _active_tokens.size()
	return metrics


## Get audit log (recent events)
func get_audit_log(limit: int = 100) -> Array[Dictionary]:
	var log_size = _audit_log.size()
	var start_idx = max(0, log_size - limit)
	return _audit_log.slice(start_idx, log_size)


## Check if automatic rotation is needed
func check_auto_rotation() -> bool:
	if not AUTO_ROTATION_ENABLED:
		return false

	var now = Time.get_unix_time_from_system()
	var time_since_last_rotation = now - _last_rotation_time

	if time_since_last_rotation >= _rotation_interval_seconds:
		# Find the newest active token to use as "current"
		var newest_token = _get_newest_active_token()
		var newest_secret = newest_token.token_secret if newest_token else ""

		var rotation_result = rotate_token(newest_secret)
		if rotation_result.success:
			print("[TokenManager] Automatic rotation completed")
			return true
		else:
			push_warning("[TokenManager] Automatic rotation failed: " + rotation_result.error)

	return false


## Cleanup expired and revoked tokens
func cleanup_tokens() -> Dictionary:
	var result = {
		"removed_count": 0,
		"expired_count": 0,
		"revoked_count": 0
	}

	var now = Time.get_unix_time_from_system()
	var to_remove: Array[String] = []

	for token_secret in _active_tokens.keys():
		var token: Token = _active_tokens[token_secret]

		# Remove tokens that expired more than 24 hours ago, or are revoked and old
		var should_remove = false
		if token.revoked and (now - token.last_used_at) > 86400:  # 24 hours
			should_remove = true
			result.revoked_count += 1
		elif token.is_expired() and (now - token.expires_at) > 86400:  # 24 hours past expiry
			should_remove = true
			result.expired_count += 1

		if should_remove:
			to_remove.append(token_secret)

	# Remove marked tokens
	for token_secret in to_remove:
		var token: Token = _active_tokens[token_secret]
		_audit_log_event("token_cleaned", {"token_id": token.token_id})
		_active_tokens.erase(token_secret)
		result.removed_count += 1

	if result.removed_count > 0:
		_save_tokens()
		print("[TokenManager] Cleanup removed ", result.removed_count, " tokens (",
			  result.expired_count, " expired, ", result.revoked_count, " revoked)")

	return result


## Migrate legacy static token from SecurityConfig
func _migrate_legacy_token() -> void:
	# Check if SecurityConfig has a static token
	var legacy_token = HttpApiSecurityConfig.get_token()

	# If we have no active tokens and legacy token exists, migrate it
	if get_active_tokens().size() == 0 and not legacy_token.is_empty():
		print("[TokenManager] Migrating legacy token to new system")

		# Create a token entry for the legacy token
		var token_id = _generate_uuid()
		var now = Time.get_unix_time_from_system()
		var expiry = now + (DEFAULT_TOKEN_LIFETIME_HOURS * 3600)

		var token = Token.new(token_id, legacy_token, now, expiry)
		_active_tokens[legacy_token] = token

		_audit_log_event("legacy_token_migrated", {
			"token_id": token_id,
			"migrated_at": now
		})

		_save_tokens()
		print("[TokenManager] Legacy token migrated successfully")

	# If we have no tokens at all, generate initial token
	if get_active_tokens().size() == 0:
		print("[TokenManager] No active tokens found, generating initial token")
		var initial_token = generate_token()
		print("[TokenManager] Initial token created: ", initial_token.token_secret)
		print("[TokenManager] Include in requests: Authorization: Bearer ", initial_token.token_secret)


## Save tokens to disk
func _save_tokens() -> void:
	var data = {
		"version": 1,
		"saved_at": Time.get_unix_time_from_system(),
		"tokens": []
	}

	for token in _active_tokens.values():
		data.tokens.append(token.to_dict())

	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open(TOKEN_STORAGE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		push_warning("[TokenManager] Failed to save tokens to: " + TOKEN_STORAGE_PATH)


## Load tokens from disk
func _load_tokens() -> void:
	if not FileAccess.file_exists(TOKEN_STORAGE_PATH):
		print("[TokenManager] No existing token storage found")
		return

	var file = FileAccess.open(TOKEN_STORAGE_PATH, FileAccess.READ)
	if not file:
		push_warning("[TokenManager] Failed to load tokens from: " + TOKEN_STORAGE_PATH)
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_warning("[TokenManager] Failed to parse token storage JSON")
		return

	var data = json.data
	if not data is Dictionary:
		push_warning("[TokenManager] Invalid token storage format")
		return

	var tokens_data = data.get("tokens", [])
	for token_dict in tokens_data:
		var token = Token.from_dict(token_dict)
		_active_tokens[token.token_secret] = token

	print("[TokenManager] Loaded ", _active_tokens.size(), " tokens from storage")

	# Update last rotation time to most recent token creation
	for token in _active_tokens.values():
		if token.created_at > _last_rotation_time:
			_last_rotation_time = token.created_at


## Schedule periodic cleanup
func _schedule_cleanup() -> void:
	# Cleanup happens via periodic check in get_tree().create_timer() calls
	# This is called from process() in the autoload that uses TokenManager
	pass


## Generate UUID v4
func _generate_uuid() -> String:
	# Simple UUID v4 implementation
	var bytes = PackedByteArray()
	for i in range(16):
		bytes.append(randi() % 256)

	# Set version (4) and variant bits
	bytes[6] = (bytes[6] & 0x0F) | 0x40
	bytes[8] = (bytes[8] & 0x3F) | 0x80

	var hex = bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8),
		hex.substr(8, 4),
		hex.substr(12, 4),
		hex.substr(16, 4),
		hex.substr(20, 12)
	]


## Generate secure random token secret (32 bytes hex)
func _generate_secret() -> String:
	var bytes = PackedByteArray()
	for i in range(32):
		bytes.append(randi() % 256)
	return bytes.hex_encode()


## Get newest active token
func _get_newest_active_token() -> Token:
	var newest: Token = null
	for token in get_active_tokens():
		if newest == null or token.created_at > newest.created_at:
			newest = token
	return newest


## Add audit log entry
func _audit_log_event(event_type: String, details: Dictionary = {}) -> void:
	var entry = {
		"timestamp": Time.get_unix_time_from_system(),
		"event_type": event_type,
		"details": details
	}

	_audit_log.append(entry)

	# Trim audit log if too large
	if _audit_log.size() > MAX_AUDIT_LOG_SIZE:
		_audit_log = _audit_log.slice(_audit_log.size() - MAX_AUDIT_LOG_SIZE, _audit_log.size())
