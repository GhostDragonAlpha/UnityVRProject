extends HttpRouter
class_name ExampleRateLimitedRouter

## Example HTTP Router with Rate Limiting Integration
## This demonstrates the complete pattern for adding rate limiting to any router
##
## Key Features:
## - Rate limiting checked FIRST (before expensive operations)
## - Proper 429 responses with Retry-After headers
## - Rate limit headers on ALL responses
## - IP banning for repeated violations (handled automatically by RateLimiter)

# Note: SecurityConfig is already preloaded by the server, accessed via static methods

func _init():
	# Define POST handler with full security checks
	var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# ===================================================================
		# STEP 1: RATE LIMITING (FIRST - before any expensive operations)
		# ===================================================================
		var client_ip = request.headers.get("X-Forwarded-For", "127.0.0.1")

		# Check rate limit
		var rate_check = HttpApiSecurityConfig.check_rate_limit(client_ip, "/example")

		if not rate_check.get("allowed", true):
			# Rate limited or IP banned - return 429 with headers
			var rate_headers = HttpApiSecurityConfig.get_rate_limit_headers(rate_check)
			var error_body = HttpApiSecurityConfig.create_rate_limit_error_response(rate_check.get("retry_after", 0.0))

			# Add all rate limit headers
			for header_name in rate_headers:
				response.headers[header_name] = rate_headers[header_name]

			response.send(429, JSON.stringify(error_body), "application/json")

			# Log the rate limit violation
			print("[ExampleRouter] Rate limit exceeded for IP: ", client_ip)
			return true

		# ===================================================================
		# STEP 2: Add rate limit headers to response (for successful requests)
		# ===================================================================
		var rate_headers = HttpApiSecurityConfig.get_rate_limit_headers(rate_check)
		for header_name in rate_headers:
			response.headers[header_name] = rate_headers[header_name]

		# ===================================================================
		# STEP 3: AUTHENTICATION (after rate limiting)
		# ===================================================================
		if not HttpApiSecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(HttpApiSecurityConfig.create_auth_error_response()))
			return true

		# ===================================================================
		# STEP 4: SIZE VALIDATION
		# ===================================================================
		if not HttpApiSecurityConfig.validate_request_size(request):
			response.send(413, JSON.stringify(HttpApiSecurityConfig.create_size_error_response()))
			return true

		# ===================================================================
		# STEP 5: PARSE AND VALIDATE REQUEST BODY
		# ===================================================================
		var body = request.get_body_parsed()
		if not body:
			response.send(400, JSON.stringify({
				"error": "Bad Request",
				"message": "Invalid JSON body or missing Content-Type: application/json"
			}))
			return true

		# ===================================================================
		# STEP 6: BUSINESS LOGIC
		# ===================================================================
		var example_data = body.get("data", "default")

		print("[ExampleRouter] Processing request from IP: ", client_ip)
		print("[ExampleRouter] Data: ", example_data)

		# Your business logic here...
		# - Database queries
		# - File operations
		# - Calculations
		# etc.

		# ===================================================================
		# STEP 7: RETURN SUCCESS RESPONSE
		# ===================================================================
		var result = {
			"status": "success",
			"message": "Operation completed successfully",
			"data": example_data,
			"timestamp": Time.get_unix_time_from_system()
		}

		response.send(200, JSON.stringify(result))
		return true

	# Define GET handler (simpler example)
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Rate limiting check
		var client_ip = request.headers.get("X-Forwarded-For", "127.0.0.1")
		var rate_check = HttpApiSecurityConfig.check_rate_limit(client_ip, "/example")

		if not rate_check.get("allowed", true):
			_send_rate_limit_error(response, rate_check)
			return true

		# Add rate limit headers
		_add_rate_limit_headers(response, rate_check)

		# Auth check
		if not HttpApiSecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(HttpApiSecurityConfig.create_auth_error_response()))
			return true

		# Return data
		var data = {
			"status": "success",
			"data": {
				"example": "value",
				"timestamp": Time.get_unix_time_from_system()
			}
		}

		response.send(200, JSON.stringify(data))
		return true

	# Register handlers
	super("/example", {
		'post': post_handler,
		'get': get_handler
	})


## Helper function: Send rate limit error response
func _send_rate_limit_error(response: GodottpdResponse, rate_check: Dictionary) -> void:
	var headers = HttpApiSecurityConfig.get_rate_limit_headers(rate_check)
	for header_name in headers:
		response.headers[header_name] = headers[header_name]

	var error_body = HttpApiSecurityConfig.create_rate_limit_error_response(rate_check.get("retry_after", 0.0))
	response.send(429, JSON.stringify(error_body), "application/json")


## Helper function: Add rate limit headers to response
func _add_rate_limit_headers(response: GodottpdResponse, rate_check: Dictionary) -> void:
	var headers = HttpApiSecurityConfig.get_rate_limit_headers(rate_check)
	for header_name in headers:
		response.headers[header_name] = headers[header_name]


## Helper function: Combined rate limit + auth check
## Returns true if checks pass, false if a response was sent
func _check_rate_and_auth(request: HttpRequest, response: GodottpdResponse, endpoint: String) -> bool:
	# Rate limit check
	var client_ip = request.headers.get("X-Forwarded-For", "127.0.0.1")
	var rate_check = HttpApiSecurityConfig.check_rate_limit(client_ip, endpoint)

	if not rate_check.get("allowed", true):
		_send_rate_limit_error(response, rate_check)
		return false

	_add_rate_limit_headers(response, rate_check)

	# Auth check
	if not HttpApiSecurityConfig.validate_auth(request):
		response.send(401, JSON.stringify(HttpApiSecurityConfig.create_auth_error_response()))
		return false

	return true
