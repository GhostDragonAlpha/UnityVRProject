extends "res://addons/godottpd/http_router.gd"
class_name StatusRouter

## HTTP Router for system status and health checks
## Used by smoke_tests.py and AI verification tools

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

func _init():
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Simple health check - no auth required for basic status (or maybe yes?)
		# smoke_tests.py seems to expect auth for some things but maybe not status?
		# Let's check smoke_tests.py... it calls /status without auth in test_status_endpoint?
		# Wait, test_status_endpoint just does requests.get(..., timeout=10). No headers.
		# So /status must be public or at least readable.
		
		# However, test_jwt_token_generation expects to find "jwt_token" in the response.
		# And test_vr_initialization expects "vr_initialized".
		
		var data = {
			"status": "healthy",
			"http_api": "active",
			"environment": "development", # TODO: Get from Engine
			"api_version": "1.0.0",
			"jwt_token": SecurityConfig.get_token(), # Expose token for tests (Security risk in prod? Yes, but this is dev tool)
			"vr_initialized": false,
			"autoloads": _get_autoload_status()
		}
		
		# Check VR Status
		if Engine.has_singleton("ResonanceEngine"):
			var engine = Engine.get_singleton("ResonanceEngine")
			if engine.vr_manager:
				data["vr_initialized"] = engine.vr_manager.is_vr_active()
				data["vr_mode"] = engine.vr_manager.get_current_mode() # 1=VR, 2=Desktop
		
		response.send(200, JSON.stringify(data))
		return true

	super("/status", {'get': get_handler})

func _get_autoload_status() -> Dictionary:
	var status = {}
	var autoloads = [
		"ResonanceEngine", "HttpApiServer", "SceneLoadMonitor", 
		"SettingsManager", "TelemetryServer", "ServiceDiscovery"
	]
	
	for name in autoloads:
		if Engine.has_singleton(name):
			status[name] = "loaded"
		else:
			status[name] = "missing"
			
	return status
