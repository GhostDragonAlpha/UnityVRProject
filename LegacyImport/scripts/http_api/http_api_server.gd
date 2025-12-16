extends Node

## HttpApiServer - ACTIVE Production HTTP API
##
## Provides a production-grade REST API for remote control and scene management.
## This is the ACTIVE SYSTEM that replaces the deprecated godot_bridge.gd
##
## PORT: 8080 (was 8080 in legacy GodotBridge)
## TECHNOLOGY: godottpd library (proven, lightweight HTTP server)
## SECURITY: v2.5+ includes JWT authentication, rate limiting, RBAC, and audit logging
##
## MIGRATION STATUS: GodotBridge (addons/godot_debug_connection/) is now DEPRECATED
##                   - Disabled in autoload (project.godot line 23 is commented out)
##                   - Retained for reference security implementations only
##                   - Use THIS system (port 8080) for all new development
##
## Features:
##   - RESTful API with scene management and hot-reloading
##   - JWT token authentication for security
##   - Rate limiting and DDoS protection
##   - Role-based access control (RBAC)
##   - Audit logging of all operations
##   - Batch operations and async job queue
##   - Webhook management with delivery tracking
##   - Performance metrics and profiling
##   - WebSocket telemetry streaming (port 8081)
##   - Service discovery via UDP (port 8087)
##   - ENVIRONMENT-AWARE: Automatically loads correct config based on build type

const PORT = 8080
const SecurityConfig = preload("res://scripts/http_api/security_config.gd")
const SimpleAuditLogger = preload("res://scripts/http_api/simple_audit_logger.gd")

## Environment detection constants
const ENV_DEVELOPMENT = "development"
const ENV_PRODUCTION = "production"
const ENV_TEST = "test"

## Current runtime environment (detected at startup)
var current_environment: String = ENV_DEVELOPMENT

## Flag to disable HTTP API entirely in release builds (security hardening)
var api_disabled: bool = false

var server: Node


func _ready():
	# Detect environment and configure accordingly
	_detect_environment()

	# Check if API should be disabled (security hardening for production)
	if api_disabled:
		print("[HttpApiServer] SECURITY: HTTP API is DISABLED for this environment")
		print("[HttpApiServer] To enable, set GODOT_ENABLE_HTTP_API=1 environment variable")
		return

	print("[HttpApiServer] Initializing SECURE HTTP API server on port ", PORT)
	print("[HttpApiServer] Build Type: ", "DEBUG" if OS.is_debug_build() else "RELEASE")
	print("[HttpApiServer] Environment: ", current_environment)

	# Initialize simple file-based audit logging
	SimpleAuditLogger.initialize()

	# Load whitelist configuration for detected environment
	SecurityConfig.load_whitelist_config(current_environment)
	print("[HttpApiServer] Whitelist configuration loaded for '", current_environment, "' environment")

	# Generate security token
	SecurityConfig.generate_jwt_token()
	SecurityConfig.print_config()

	# Create HTTP server
	server = load("res://addons/godottpd/http_server.gd").new()

	# Set port and bind address
	server.port = PORT
	# Bind to localhost only for security
	server.bind_address = SecurityConfig.BIND_ADDRESS

	# Register routers
	_register_routers()

	# Add server to scene tree
	add_child(server)

	# CRITICAL FIX: Add error handling for server start failure
	# Start server (godottpd start() returns void, not error code)
	server.start()

	# Verify server actually started by checking if it's listening
	# Small delay to allow server to initialize
	await get_tree().create_timer(0.1).timeout

	# CRITICAL FIX: HttpServer class does not expose is_listening() method
	# Access internal TCPServer directly to verify server started successfully
	if server._server == null or not server._server.is_listening():
		push_error("[HttpApiServer] CRITICAL: Failed to start HTTP server on port %d" % PORT)
		push_error("[HttpApiServer] This may be due to:")
		push_error("[HttpApiServer]   - Port %d already in use by another process" % PORT)
		push_error("[HttpApiServer]   - Insufficient permissions to bind to %s:%d" % [SecurityConfig.BIND_ADDRESS, PORT])
		push_error("[HttpApiServer]   - Firewall blocking the port")
		push_error("[HttpApiServer] Recommendation: Check for conflicting processes or try a different port")
		# Consider implementing graceful degradation or retry logic in the future
		return

	print("[HttpApiServer] SECURE HTTP API server started on ", SecurityConfig.BIND_ADDRESS, ":", PORT)
	print("[HttpApiServer] Available endpoints:")
	print("[HttpApiServer]   POST /scene - Load a scene (AUTH REQUIRED)")
	print("[HttpApiServer]   GET  /scene - Get current scene (AUTH REQUIRED)")
	print("[HttpApiServer]   PUT  /scene - Validate a scene (AUTH REQUIRED)")
	print("[HttpApiServer]   GET  /scenes - List available scenes (AUTH REQUIRED)")
	print("[HttpApiServer]   POST /scene/reload - Reload current scene (AUTH REQUIRED)")
	print("[HttpApiServer]   GET  /scene/history - Get scene load history (AUTH REQUIRED)")
	print("[HttpApiServer] ")
	print("[HttpApiServer] API TOKEN: ", SecurityConfig.get_token())
	print("[HttpApiServer] Use: curl -H 'Authorization: Bearer ", SecurityConfig.get_token(), "' ...")
	
	# Save token to file for automated testing
	var token_file = FileAccess.open("res://jwt_token.txt", FileAccess.WRITE)
	if token_file:
		token_file.store_string(SecurityConfig.get_token())
		token_file.close()
		print("[HttpApiServer] Token saved to jwt_token.txt")


## Detect environment from build type and environment variables
## Priority order:
##   1. OS.get_environment("GODOT_ENV") - explicit override
##   2. OS.get_environment("GODOT_ENABLE_HTTP_API") - can disable HTTP API entirely
##   3. OS.is_debug_build() - use debug for development, release for production
func _detect_environment() -> void:
	print("[HttpApiServer] Detecting environment...")

	# Check for explicit environment override
	var env_override = OS.get_environment("GODOT_ENV")
	if not env_override.is_empty():
		current_environment = env_override.to_lower()
		print("[HttpApiServer]   Environment from GODOT_ENV: ", current_environment)
		return

	# Check for HTTP API disable flag (security: disable in production by default)
	var http_api_enabled = OS.get_environment("GODOT_ENABLE_HTTP_API")
	if http_api_enabled.to_lower() == "false" or http_api_enabled.to_lower() == "0":
		api_disabled = true
		print("[HttpApiServer]   HTTP API disabled via GODOT_ENABLE_HTTP_API=false")
		return

	# Detect from build type
	if OS.is_debug_build():
		current_environment = ENV_DEVELOPMENT
		print("[HttpApiServer]   Environment from build type: ", current_environment, " (DEBUG)")
	else:
		current_environment = ENV_PRODUCTION
		print("[HttpApiServer]   Environment from build type: ", current_environment, " (RELEASE)")

		# SECURITY HARDENING: In production release builds, disable HTTP API by default
		# This prevents accidental exposure of the API in shipped builds
		# EXCEPTION: Always enable in editor mode for development convenience
		# Users can explicitly enable in exported builds with: GODOT_ENABLE_HTTP_API=true

		# Check if running in editor (OS.has_feature("editor") available in Godot 4.x)
		var is_editor = OS.has_feature("editor")
		if is_editor:
			print("[HttpApiServer]   EDITOR MODE: HTTP API auto-enabled for development")
		else:
			var explicit_enable = OS.get_environment("GODOT_ENABLE_HTTP_API")
			if explicit_enable.to_lower() != "true" and explicit_enable.to_lower() != "1":
				api_disabled = true
				print("[HttpApiServer]   SECURITY: HTTP API disabled by default in RELEASE build")
				print("[HttpApiServer]   To enable in production, set: GODOT_ENABLE_HTTP_API=true")


## Get current environment name
func get_environment() -> String:
	return current_environment


## Check if API is disabled
func is_api_disabled() -> bool:
	return api_disabled


## Check if running in development mode
func is_development() -> bool:
	return current_environment == ENV_DEVELOPMENT


## Check if running in production mode
func is_production() -> bool:
	return current_environment == ENV_PRODUCTION


## Check if running in test mode
func is_test() -> bool:
	return current_environment == ENV_TEST


func _register_routers():
	"""Register all HTTP routers for different endpoints"""

	# Register specific routes BEFORE generic routes (godottpd uses prefix matching)

	# Scene history router (/scene/history must come before /scene)
	var scene_history_router = load("res://scripts/http_api/scene_history_router.gd").new()
	server.register_router(scene_history_router)
	print("[HttpApiServer] Registered /scene/history router")

	# Status router (for smoke tests)
	var status_router = load("res://scripts/http_api/status_router.gd").new()
	server.register_router(status_router)
	print("[HttpApiServer] Registered /status router")

	# Scene reload router (/scene/reload must come before /scene)
	var scene_reload_router = load("res://scripts/http_api/scene_reload_router.gd").new()
	server.register_router(scene_reload_router)
	print("[HttpApiServer] Registered /scene/reload router")

	# Scene management router (generic /scene route)
	var scene_router = load("res://scripts/http_api/scene_router.gd").new()
	server.register_router(scene_router)
	print("[HttpApiServer] Registered /scene router")

	# Scenes list router
	var scenes_list_router = load("res://scripts/http_api/scenes_list_router.gd").new()
	server.register_router(scenes_list_router)
	print("[HttpApiServer] Registered /scenes router")

	# Scene dump router (for AI inspection)
	var scene_dump_router = load("res://scripts/http_api/scene_dump_router.gd").new()
	server.register_router(scene_dump_router)
	print("[HttpApiServer] Registered /scene/dump router")

	# Screenshot router (for visual proof)
	var screenshot_router = load("res://scripts/http_api/screenshot_router.gd").new()
	server.register_router(screenshot_router)
	print("[HttpApiServer] Registered /debug/screenshot router")

	# === PHASE 1: PERFORMANCE MONITORING ===

	# Performance monitoring router
	var performance_router = load("res://scripts/http_api/performance_router.gd").new()
	server.register_router(performance_router)
	print("[HttpApiServer] Registered /performance router")

	# === PHASE 2: WEBHOOKS AND JOB QUEUE ===

	# Webhook detail router (must register BEFORE generic webhook router)
	var webhook_detail_router = load("res://scripts/http_api/webhook_detail_router.gd").new()
	server.register_router(webhook_detail_router)
	print("[HttpApiServer] Registered /webhooks/:id router")

	# Webhook router
	var webhook_router = load("res://scripts/http_api/webhook_router.gd").new()
	server.register_router(webhook_router)
	print("[HttpApiServer] Registered /webhooks router")

	# Job detail router (must register BEFORE generic job router)
	var job_detail_router = load("res://scripts/http_api/job_detail_router.gd").new()
	server.register_router(job_detail_router)
	print("[HttpApiServer] Registered /jobs/:id router")

	# Job router
	var job_router = load("res://scripts/http_api/job_router.gd").new()
	server.register_router(job_router)
	print("[HttpApiServer] Registered /jobs router")


func _exit_tree():
	# Shutdown audit logging
	SimpleAuditLogger.shutdown()

	if server:
		print("[HttpApiServer] Stopping HTTP server...")
		server.stop()
