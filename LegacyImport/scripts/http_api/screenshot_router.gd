extends "res://addons/godottpd/http_router.gd"
class_name ScreenshotRouter

## HTTP Router for capturing debug screenshots
## Used by smoke_tests.py for visual verification

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

func _init():
	var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true
			
		# Capture screenshot
		var viewport = Engine.get_main_loop().root.get_viewport()
		if not viewport:
			response.send(500, JSON.stringify({"error": "No viewport available"}))
			return true
			
		# We need to wait for the next frame to capture rendering? 
		# Actually, get_texture() gets the last rendered frame.
		var tex = viewport.get_texture()
		var img = tex.get_image()
		
		# Save to user directory (safe) and res:// (for easy access in dev)
		var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
		var filename = "proof_of_life_%s.png" % timestamp
		var path = "user://screenshots/" + filename
		
		# Ensure directory exists
		if not DirAccess.dir_exists_absolute("user://screenshots"):
			DirAccess.make_dir_absolute("user://screenshots")
			
		var err = img.save_png(path)
		
		# Also save a 'latest.png' for easy checking
		img.save_png("user://screenshots/latest.png")
		
		# In dev mode, try to save to project root for easy viewing
		if OS.is_debug_build():
			img.save_png("res://proof_of_life.png")
		
		if err == OK:
			response.send(200, JSON.stringify({
				"status": "success",
				"message": "Screenshot captured",
				"path": path,
				"timestamp": timestamp
			}))
		else:
			response.send(500, JSON.stringify({
				"error": "Failed to save image",
				"code": err
			}))
			
		return true

	super("/debug/screenshot", {'post': post_handler})
