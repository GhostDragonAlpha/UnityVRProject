# Router Integration Guide for Rate Limiting

**Quick Reference for Integrating Rate Limiting into HTTP Routers**

---

## Quick Start

Add rate limiting to any HTTP router in 3 steps:

### Step 1: Extract Client IP

```gdscript
var client_ip = request.headers.get("X-Forwarded-For", "127.0.0.1")
```

### Step 2: Check Rate Limit

```gdscript
var rate_check = SecurityConfig.check_rate_limit(client_ip, "/your-endpoint")

if not rate_check.get("allowed", true):
	# Return 429 with headers
	var rate_headers = SecurityConfig.get_rate_limit_headers(rate_check)
	var error_body = SecurityConfig.create_rate_limit_error_response(rate_check)

	for header_name in rate_headers:
		response.headers[header_name] = rate_headers[header_name]

	response.send(429, JSON.stringify(error_body))
	return true
```

### Step 3: Add Headers to Successful Responses

```gdscript
# After successful request processing
var rate_headers = SecurityConfig.get_rate_limit_headers(rate_check)
for header_name in rate_headers:
	response.headers[header_name] = rate_headers[header_name]
```

---

## Complete Example

Here's a complete router with rate limiting integrated:

```gdscript
extends "res://addons/godottpd/http_router.gd"
class_name ExampleRouter

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

func _init():
	var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# STEP 1: Extract client IP
		var client_ip = request.headers.get("X-Forwarded-For", "127.0.0.1")

		# STEP 2: Check rate limit (BEFORE expensive operations!)
		var rate_check = SecurityConfig.check_rate_limit(client_ip, "/example")

		if not rate_check.get("allowed", true):
			# Rate limited - return 429
			var rate_headers = SecurityConfig.get_rate_limit_headers(rate_check)
			var error_body = SecurityConfig.create_rate_limit_error_response(rate_check)

			# Add rate limit headers
			for header_name in rate_headers:
				response.headers[header_name] = rate_headers[header_name]

			response.send(429, JSON.stringify(error_body))
			return true

		# STEP 3: Add rate limit headers for successful response
		var rate_headers = SecurityConfig.get_rate_limit_headers(rate_check)
		for header_name in rate_headers:
			response.headers[header_name] = rate_headers[header_name]

		# Now perform authentication check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		# Size check
		if not SecurityConfig.validate_request_size(request):
			response.send(413, JSON.stringify(SecurityConfig.create_size_error_response()))
			return true

		# Your business logic here...
		var result = {
			"status": "success",
			"message": "Operation completed"
		}

		response.send(200, JSON.stringify(result))
		return true

	# Register handler
	super("/example", {'post': post_handler})
```

---

## Important Notes

### 1. Check Rate Limit FIRST

Always check rate limiting **before** expensive operations:

```gdscript
// ✅ CORRECT ORDER
1. Rate limit check
2. Authentication check
3. Input validation
4. Database queries
5. Business logic

// ❌ WRONG ORDER
1. Database queries (expensive!)
2. Business logic (expensive!)
3. Rate limit check (too late!)
```

**Why?** Attackers can exhaust resources with invalid requests if you do expensive operations first.

### 2. Use Correct Endpoint Name

The endpoint name must match the rate limit configuration:

```gdscript
// Endpoint configuration in rate_limiter.gd
const ENDPOINT_LIMITS: Dictionary = {
	"/scene": 30,
	"/scene/reload": 20,
	"/scenes": 60,
	// ...
}

// In router - use matching name
var rate_check = SecurityConfig.check_rate_limit(client_ip, "/scene")
```

### 3. Always Add Rate Limit Headers

Even successful responses should include rate limit headers:

```gdscript
// Rate limit headers inform clients:
X-RateLimit-Limit: 30        // Maximum requests allowed
X-RateLimit-Remaining: 25     // Requests remaining
X-RateLimit-Reset: 1733184000 // When bucket resets (Unix timestamp)
```

This allows clients to:
- Implement client-side rate limiting
- Show user feedback ("25 requests remaining")
- Avoid hitting limits

### 4. Handle Localhost Correctly

For localhost development, consider using connection ID to differentiate:

```gdscript
var client_ip = request.headers.get("X-Forwarded-For", "127.0.0.1")

// Optional: For localhost, add connection ID to differentiate clients
if client_ip == "127.0.0.1" and request.has("connection_id"):
	client_ip = "%s_%d" % [client_ip, request.connection_id]

var rate_check = SecurityConfig.check_rate_limit(client_ip, endpoint)
```

---

## Testing Your Integration

### Unit Test Example

```gdscript
extends GdUnitTestSuite

func test_rate_limiting_blocks_excess_requests():
	var router = YourRouter.new()

	// Make requests up to limit
	for i in range(30):
		var request = create_mock_request("POST", "/your-endpoint")
		var response = create_mock_response()
		router.handle(request, response)
		assert_that(response.code).is_equal(200)

	// Next request should be rate limited
	var request = create_mock_request("POST", "/your-endpoint")
	var response = create_mock_response()
	router.handle(request, response)
	assert_that(response.code).is_equal(429)
```

### Manual Testing with curl

```bash
# Test rate limiting
for i in {1..35}; do
  echo "Request $i"
  curl -w "\nHTTP Status: %{http_code}\n" \
       -H "Authorization: Bearer YOUR_TOKEN" \
       -H "Content-Type: application/json" \
       -X POST http://127.0.0.1:8080/your-endpoint \
       -d '{"test": "data"}'
done
```

---

## Common Patterns

### Pattern 1: Simple GET Endpoint

```gdscript
var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
	var client_ip = request.headers.get("X-Forwarded-For", "127.0.0.1")
	var rate_check = SecurityConfig.check_rate_limit(client_ip, "/status")

	if not rate_check.allowed:
		_send_rate_limit_error(response, rate_check)
		return true

	_add_rate_headers(response, rate_check)

	// Your logic here
	response.send(200, JSON.stringify({"status": "ok"}))
	return true
```

### Pattern 2: POST with Body

```gdscript
var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
	var client_ip = request.headers.get("X-Forwarded-For", "127.0.0.1")
	var rate_check = SecurityConfig.check_rate_limit(client_ip, "/data")

	if not rate_check.allowed:
		_send_rate_limit_error(response, rate_check)
		return true

	_add_rate_headers(response, rate_check)

	if not SecurityConfig.validate_auth(request):
		response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
		return true

	var body = request.get_body_parsed()
	// Process body...

	response.send(200, JSON.stringify({"status": "created"}))
	return true
```

### Pattern 3: Helper Functions

Create helper functions for consistent handling:

```gdscript
## Send rate limit error response
func _send_rate_limit_error(response: GodottpdResponse, rate_check: Dictionary) -> void:
	var headers = SecurityConfig.get_rate_limit_headers(rate_check)
	for header_name in headers:
		response.headers[header_name] = headers[header_name]

	var error_body = SecurityConfig.create_rate_limit_error_response(rate_check)
	response.send(429, JSON.stringify(error_body))


## Add rate limit headers to response
func _add_rate_headers(response: GodottpdResponse, rate_check: Dictionary) -> void:
	var headers = SecurityConfig.get_rate_limit_headers(rate_check)
	for header_name in headers:
		response.headers[header_name] = headers[header_name]


## Combined rate limit + auth check
func _check_rate_and_auth(request: HttpRequest, response: GodottpdResponse, endpoint: String) -> bool:
	// Rate limit check
	var client_ip = request.headers.get("X-Forwarded-For", "127.0.0.1")
	var rate_check = SecurityConfig.check_rate_limit(client_ip, endpoint)

	if not rate_check.allowed:
		_send_rate_limit_error(response, rate_check)
		return false

	_add_rate_headers(response, rate_check)

	// Auth check
	if not SecurityConfig.validate_auth(request):
		response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
		return false

	return true
```

Then use in handlers:

```gdscript
var post_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
	if not _check_rate_and_auth(request, response, "/example"):
		return true

	// Your business logic here
	response.send(200, JSON.stringify({"status": "success"}))
	return true
```

---

## Checklist for New Routers

When adding a new HTTP router, verify:

- [ ] Rate limit check is **FIRST** operation in handler
- [ ] Correct endpoint name used (matches `ENDPOINT_LIMITS`)
- [ ] Rate limit headers added to **ALL** responses (success and error)
- [ ] 429 response includes `Retry-After` header
- [ ] Client IP extracted correctly
- [ ] Tests include rate limiting verification
- [ ] Documentation updated with new endpoint

---

## Troubleshooting

### Problem: Rate limiting not working

**Check:**
1. Is `SecurityConfig.rate_limiting_enabled` true?
2. Is rate limiter initialized? (`SecurityConfig.initialize_rate_limiter()`)
3. Is cleanup running? (`SecurityConfig.process(delta)` in main loop)

### Problem: All requests from localhost blocked together

**Solution:** Use connection ID to differentiate:
```gdscript
var client_ip = "127.0.0.1"
if request.has("connection_id"):
	client_ip = "%s_%d" % [client_ip, request.connection_id]
```

### Problem: Rate limit headers not showing

**Check:**
1. Are you adding headers to response? (`response.headers[name] = value`)
2. Are headers added for BOTH success and error responses?
3. Check response with `curl -v` to see all headers

---

## Reference

### Rate Limit Configuration

Edit `scripts/http_api/rate_limiter.gd`:

```gdscript
const ENDPOINT_LIMITS: Dictionary = {
	"/your-endpoint": 50,  # Add your endpoint here
}
```

### Complete Documentation

- Full implementation docs: `docs/security/RATE_LIMITING_IMPLEMENTATION.md`
- Security hardening guide: `docs/security/HARDENING_GUIDE.md`
- Test suite: `tests/security/test_rate_limiter.gd`

---

**Last Updated:** 2025-12-02
**Status:** Complete and tested
