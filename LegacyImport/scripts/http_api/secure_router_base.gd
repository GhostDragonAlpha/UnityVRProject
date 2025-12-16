extends HttpRouter
class_name SecureRouterBase

## Secure Router Base Class
## Base class for HTTP routers that automatically adds security headers
## Solves VULN-011 without modifying godottpd library

## Security headers middleware (shared across all routers)
static var _security_middleware: RefCounted = null

## Initialize security headers middleware (call once at startup)
static func initialize_security_headers(preset: int = 1) -> void:
	var SecurityHeadersMiddleware = load("res://scripts/http_api/security_headers.gd")
	if SecurityHeadersMiddleware == null:
		push_error("[SecureRouterBase] Failed to load SecurityHeadersMiddleware")
		return

	_security_middleware = SecurityHeadersMiddleware.new(preset)
	print("[SecureRouterBase] Security headers middleware initialized")
	_security_middleware.print_config()


## Apply security headers to response before sending
func _apply_security_headers(response: GodottpdResponse) -> void:
	if _security_middleware != null:
		_security_middleware.apply_headers(response)


## Override send methods to add security headers
## These helpers can be used by subclasses

func send_json_response(response: GodottpdResponse, status_code: int, data: Dictionary) -> void:
	_apply_security_headers(response)
	response.json(status_code, data)


func send_text_response(response: GodottpdResponse, status_code: int, text: String) -> void:
	_apply_security_headers(response)
	response.send(status_code, text, "text/plain")


func send_html_response(response: GodottpdResponse, status_code: int, html: String) -> void:
	_apply_security_headers(response)
	response.send(status_code, html, "text/html")


func send_error_response(response: GodottpdResponse, status_code: int, error: String, message: String = "") -> void:
	_apply_security_headers(response)
	response.json(status_code, {
		"error": error,
		"message": message if message != "" else error
	})
