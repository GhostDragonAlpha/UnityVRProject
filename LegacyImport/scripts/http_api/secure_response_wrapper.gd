extends RefCounted
class_name SecureResponseWrapper

## Secure Response Wrapper
## Wraps GodottpdResponse to automatically add security headers
## This solves VULN-011 without modifying the godottpd library

var _response: GodottpdResponse
var _middleware: RefCounted  # SecurityHeadersMiddleware instance

## Initialize wrapper with response and middleware
func _init(response: GodottpdResponse, middleware: RefCounted):
	_response = response
	_middleware = middleware


## Pass-through methods that delegate to wrapped response

func set_header(field: StringName, value: Variant) -> void:
	_response.set(field, value)

func cookie(name: String, value: String, options: Dictionary = {}) -> void:
	_response.cookie(name, value, options)


## Wrapped send methods - apply security headers before sending

func send_raw(status_code: int, data: PackedByteArray = PackedByteArray([]), content_type: String = "application/octet-stream", extra_header: String = "") -> void:
	# Apply security headers
	if _middleware != null:
		_middleware.apply_headers(_response)

	# Call original send_raw
	_response.send_raw(status_code, data, content_type, extra_header)


func send(status_code: int, data: String = "", content_type = "text/html") -> void:
	# Apply security headers
	if _middleware != null:
		_middleware.apply_headers(_response)

	# Call original send
	_response.send(status_code, data, content_type)


func json(status_code: int, data) -> void:
	# Apply security headers
	if _middleware != null:
		_middleware.apply_headers(_response)

	# Call original json
	_response.json(status_code, data)


## Access to underlying properties

func get_client() -> StreamPeer:
	return _response.client

func set_access_control_origin(origin: String) -> void:
	_response.access_control_origin = origin

func set_server_identifier(identifier: String) -> void:
	_response.server_identifier = identifier
