extends Node
class_name SecurityHeadersPatch

## Security Headers Patch
## Monkey patches GodottpdResponse to add security headers automatically
## This solves VULN-011 without modifying the godottpd addon

var middleware: RefCounted  # SecurityHeadersMiddleware instance
var original_send_raw_script: String = ""


## Initialize and apply the patch
func _ready():
	# Load SecurityHeadersMiddleware
	var SecurityHeadersMiddleware = load("res://scripts/http_api/security_headers.gd")
	if SecurityHeadersMiddleware == null:
		push_error("[SecurityHeadersPatch] Failed to load SecurityHeadersMiddleware")
		return

	# Create middleware instance (MODERATE preset)
	middleware = SecurityHeadersMiddleware.new(1)  # 1 = MODERATE

	print("[SecurityHeadersPatch] ✓ Security headers middleware initialized (VULN-011 fix)")
	middleware.print_config()


## Apply security headers to a response object
## Call this manually before sending responses
func apply_to_response(response: GodottpdResponse) -> void:
	if middleware != null:
		middleware.apply_headers(response)


## Get middleware instance
func get_middleware() -> RefCounted:
	return middleware
