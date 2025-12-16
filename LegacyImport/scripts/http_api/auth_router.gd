extends RefCounted
class_name HttpApiAuthRouter

## Authentication Router for Token Management
## Provides endpoints for token rotation, refresh, and revocation

# Reference to TokenManager
var token_manager: HttpApiTokenManager

func _init(tm: HttpApiTokenManager):
	token_manager = tm


## Route authentication requests
func route_request(method: String, path: String, headers: Dictionary, body: String) -> Dictionary:
	# POST /auth/rotate - Rotate to a new token
	if method == "POST" and path == "/auth/rotate":
		return _handle_rotate(headers, body)

	# POST /auth/refresh - Refresh current token expiry
	elif method == "POST" and path == "/auth/refresh":
		return _handle_refresh(headers, body)

	# POST /auth/revoke - Revoke a token
	elif method == "POST" and path == "/auth/revoke":
		return _handle_revoke(headers, body)

	# GET /auth/status - Get token status
	elif method == "GET" and path == "/auth/status":
		return _handle_status(headers)

	# GET /auth/metrics - Get token metrics
	elif method == "GET" and path == "/auth/metrics":
		return _handle_metrics()

	# GET /auth/audit - Get audit log
	elif method == "GET" and path == "/auth/audit":
		return _handle_audit(body)

	else:
		return {
			"status": 404,
			"body": {"error": "Not Found", "message": "Authentication endpoint not found"}
		}


## Handle POST /auth/rotate
func _handle_rotate(headers: Dictionary, body: String) -> Dictionary:
	# Extract current token from Authorization header
	var auth_header = headers.get("Authorization", "")
	if auth_header.is_empty() or not auth_header.begins_with("Bearer "):
		return {
			"status": 401,
			"body": {
				"error": "Unauthorized",
				"message": "Current token required for rotation",
				"details": "Include 'Authorization: Bearer <token>' header"
			}
		}

	var current_token = auth_header.substr(7).strip_edges()

	# Validate current token first
	var validation = token_manager.validate_token(current_token)
	if not validation.valid:
		return {
			"status": 401,
			"body": {
				"error": "Unauthorized",
				"message": "Invalid current token",
				"details": validation.error
			}
		}

	# Perform rotation
	var result = token_manager.rotate_token(current_token)

	if result.success:
		var new_token = result.new_token
		return {
			"status": 200,
			"body": {
				"success": true,
				"message": "Token rotated successfully",
				"new_token": new_token.token_secret,
				"token_id": new_token.token_id,
				"expires_at": new_token.expires_at,
				"expires_in_seconds": int(new_token.expires_at - Time.get_unix_time_from_system()),
				"grace_period_seconds": result.grace_period_seconds,
				"old_token_id": result.old_token_id,
				"note": "Old token remains valid for grace period"
			}
		}
	else:
		return {
			"status": 400,
			"body": {
				"error": "Rotation Failed",
				"message": result.error
			}
		}


## Handle POST /auth/refresh
func _handle_refresh(headers: Dictionary, body: String) -> Dictionary:
	# Extract token from Authorization header
	var auth_header = headers.get("Authorization", "")
	if auth_header.is_empty() or not auth_header.begins_with("Bearer "):
		return {
			"status": 401,
			"body": {
				"error": "Unauthorized",
				"message": "Token required for refresh",
				"details": "Include 'Authorization: Bearer <token>' header"
			}
		}

	var token_secret = auth_header.substr(7).strip_edges()

	# Parse optional extension hours from body
	var extension_hours = token_manager.DEFAULT_TOKEN_LIFETIME_HOURS
	if not body.is_empty():
		var json = JSON.new()
		var parse_result = json.parse(body)
		if parse_result == OK and json.data is Dictionary:
			var data = json.data as Dictionary
			if data.has("extension_hours"):
				extension_hours = float(data.extension_hours)

	# Perform refresh
	var result = token_manager.refresh_token(token_secret, extension_hours)

	if result.success:
		var token = result.token
		return {
			"status": 200,
			"body": {
				"success": true,
				"message": "Token refreshed successfully",
				"token_id": token.token_id,
				"expires_at": result.new_expiry,
				"expires_in_seconds": int(result.new_expiry - Time.get_unix_time_from_system()),
				"refresh_count": token.refresh_count,
				"note": "Token expiry extended, same token secret remains valid"
			}
		}
	else:
		return {
			"status": 401,
			"body": {
				"error": "Refresh Failed",
				"message": result.error
			}
		}


## Handle POST /auth/revoke
func _handle_revoke(headers: Dictionary, body: String) -> Dictionary:
	# Extract token from Authorization header (the token to revoke)
	var auth_header = headers.get("Authorization", "")
	if auth_header.is_empty() or not auth_header.begins_with("Bearer "):
		return {
			"status": 401,
			"body": {
				"error": "Unauthorized",
				"message": "Token required for revocation",
				"details": "Include 'Authorization: Bearer <token>' header"
			}
		}

	var token_secret = auth_header.substr(7).strip_edges()

	# Parse optional revocation reason from body
	var reason = "manual_revocation"
	if not body.is_empty():
		var json = JSON.new()
		var parse_result = json.parse(body)
		if parse_result == OK and json.data is Dictionary:
			var data = json.data as Dictionary
			if data.has("reason"):
				reason = str(data.reason)

	# Perform revocation
	var result = token_manager.revoke_token(token_secret, reason)

	if result.success:
		return {
			"status": 200,
			"body": {
				"success": true,
				"message": "Token revoked successfully",
				"token_id": result.token_id,
				"reason": reason,
				"note": "Token is now invalid and cannot be used"
			}
		}
	else:
		return {
			"status": 404,
			"body": {
				"error": "Revocation Failed",
				"message": result.error
			}
		}


## Handle GET /auth/status
func _handle_status(headers: Dictionary) -> Dictionary:
	# Extract token from Authorization header
	var auth_header = headers.get("Authorization", "")
	if auth_header.is_empty() or not auth_header.begins_with("Bearer "):
		return {
			"status": 401,
			"body": {
				"error": "Unauthorized",
				"message": "Token required for status check",
				"details": "Include 'Authorization: Bearer <token>' header"
			}
		}

	var token_secret = auth_header.substr(7).strip_edges()

	# Validate token
	var validation = token_manager.validate_token(token_secret)

	if validation.valid:
		var token = validation.token
		var now = Time.get_unix_time_from_system()
		return {
			"status": 200,
			"body": {
				"valid": true,
				"token_id": token.token_id,
				"created_at": token.created_at,
				"expires_at": token.expires_at,
				"expires_in_seconds": validation.expires_in_seconds,
				"last_used_at": token.last_used_at,
				"refresh_count": token.refresh_count,
				"age_seconds": int(now - token.created_at),
				"expires_in_hours": validation.expires_in_seconds / 3600.0
			}
		}
	else:
		return {
			"status": 401,
			"body": {
				"valid": false,
				"error": "Invalid Token",
				"message": validation.error
			}
		}


## Handle GET /auth/metrics
func _handle_metrics() -> Dictionary:
	var metrics = token_manager.get_metrics()
	return {
		"status": 200,
		"body": {
			"success": true,
			"metrics": metrics
		}
	}


## Handle GET /auth/audit
func _handle_audit(body: String) -> Dictionary:
	var limit = 100

	# Parse optional limit from body
	if not body.is_empty():
		var json = JSON.new()
		var parse_result = json.parse(body)
		if parse_result == OK and json.data is Dictionary:
			var data = json.data as Dictionary
			if data.has("limit"):
				limit = int(data.limit)

	var audit_log = token_manager.get_audit_log(limit)

	return {
		"status": 200,
		"body": {
			"success": true,
			"audit_log": audit_log,
			"count": audit_log.size()
		}
	}
