extends RefCounted
class_name SecurityHeadersMiddleware

## Security Headers Middleware
## Implements VULN-011 mitigation: Missing security headers
## CVSS 5.3 MEDIUM - Protects against XSS, clickjacking, MIME sniffing
##
## This middleware automatically adds security headers to all HTTP responses
## to protect against common web vulnerabilities.

## Security header presets
enum HeaderPreset {
	STRICT,      ## Maximum security (recommended for production)
	MODERATE,    ## Balanced security (default)
	PERMISSIVE   ## Minimal restrictions (development only)
}

## Configuration
var _preset: HeaderPreset = HeaderPreset.MODERATE
var _custom_headers: Dictionary = {}
var _enabled: bool = true

## Statistics
var _responses_processed: int = 0
var _headers_added: int = 0


## Initialize middleware with optional preset
func _init(preset: HeaderPreset = HeaderPreset.MODERATE):
	_preset = preset
	print("[SecurityHeaders] Middleware initialized with preset: ", _get_preset_name(preset))


## Apply security headers to a GodottpdResponse object
## This is the main function called before sending responses
func apply_headers(response) -> void:
	if not _enabled:
		return

	_responses_processed += 1

	# Get headers based on preset
	var headers = _get_headers_for_preset(_preset)

	# Merge with custom headers (custom headers override preset)
	for key in _custom_headers:
		headers[key] = _custom_headers[key]

	# Apply headers to response object
	for header_name in headers:
		response.set(header_name, headers[header_name])
		_headers_added += 1


## Apply security headers to raw response string
## This version works with manual response building
func apply_headers_to_string(response_string: String) -> String:
	if not _enabled:
		return response_string

	# Parse the response to find header section
	var parts = response_string.split("\r\n\r\n", false, 1)
	if parts.size() < 1:
		return response_string

	var header_section = parts[0]
	var body_section = parts[1] if parts.size() > 1 else ""

	# Get headers to add
	var headers = _get_headers_for_preset(_preset)
	for key in _custom_headers:
		headers[key] = _custom_headers[key]

	# Build new header section
	var new_headers = header_section
	for header_name in headers:
		# Check if header already exists
		if not header_section.contains(header_name + ":"):
			new_headers += "\r\n" + header_name + ": " + headers[header_name]
			_headers_added += 1

	_responses_processed += 1

	# Reconstruct response
	return new_headers + "\r\n\r\n" + body_section


## Get security headers for a specific preset
func _get_headers_for_preset(preset: HeaderPreset) -> Dictionary:
	match preset:
		HeaderPreset.STRICT:
			return _get_strict_headers()
		HeaderPreset.MODERATE:
			return _get_moderate_headers()
		HeaderPreset.PERMISSIVE:
			return _get_permissive_headers()
		_:
			return _get_moderate_headers()


## STRICT preset - Maximum security
## Use this for production environments
func _get_strict_headers() -> Dictionary:
	return {
		# Prevent MIME type sniffing
		# Browsers won't interpret files as a different MIME type than declared
		"X-Content-Type-Options": "nosniff",

		# Prevent clickjacking attacks
		# Page cannot be displayed in a frame, iframe, embed, or object
		"X-Frame-Options": "DENY",

		# Enable XSS protection (legacy browsers)
		# Modern browsers use CSP, but this adds defense in depth
		"X-XSS-Protection": "1; mode=block",

		# Content Security Policy - Strict
		# Only allow resources from same origin, no inline scripts
		"Content-Security-Policy": "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'",

		# Control referrer information sent
		# Only send origin when navigating to same-origin, full URL for HTTPS->HTTPS
		"Referrer-Policy": "strict-origin-when-cross-origin",

		# Disable dangerous browser features
		# Prevent access to geolocation, microphone, camera, etc.
		"Permissions-Policy": "geolocation=(), microphone=(), camera=(), payment=(), usb=(), magnetometer=(), gyroscope=(), accelerometer=()",

		# HSTS - Force HTTPS (when TLS is enabled)
		# Note: Only include this when serving over HTTPS
		# "Strict-Transport-Security": "max-age=31536000; includeSubDomains; preload",

		# Prevent caching of sensitive data
		"Cache-Control": "no-store, no-cache, must-revalidate, private",
		"Pragma": "no-cache",
		"Expires": "0",

		# Cross-Origin policies
		"Cross-Origin-Embedder-Policy": "require-corp",
		"Cross-Origin-Opener-Policy": "same-origin",
		"Cross-Origin-Resource-Policy": "same-origin"
	}


## MODERATE preset - Balanced security (default)
## Good for most use cases
func _get_moderate_headers() -> Dictionary:
	return {
		# Prevent MIME type sniffing
		"X-Content-Type-Options": "nosniff",

		# Prevent clickjacking
		"X-Frame-Options": "DENY",

		# Enable XSS protection
		"X-XSS-Protection": "1; mode=block",

		# Content Security Policy - Moderate
		# Allow same-origin resources
		"Content-Security-Policy": "default-src 'self'; frame-ancestors 'none'",

		# Control referrer information
		"Referrer-Policy": "strict-origin-when-cross-origin",

		# Disable dangerous browser features
		"Permissions-Policy": "geolocation=(), microphone=(), camera=()",

		# Note: HSTS commented out - only use when HTTPS is configured
		# "Strict-Transport-Security": "max-age=31536000; includeSubDomains"
	}


## PERMISSIVE preset - Minimal restrictions
## Only use for development/testing
func _get_permissive_headers() -> Dictionary:
	return {
		# Only the most critical headers
		"X-Content-Type-Options": "nosniff",
		"X-Frame-Options": "SAMEORIGIN",  # Allow same-origin framing
		"X-XSS-Protection": "1; mode=block"
	}


## Set custom header (overrides preset)
func set_custom_header(name: String, value: String) -> void:
	_custom_headers[name] = value
	print("[SecurityHeaders] Custom header set: ", name)


## Remove custom header
func remove_custom_header(name: String) -> void:
	_custom_headers.erase(name)
	print("[SecurityHeaders] Custom header removed: ", name)


## Clear all custom headers
func clear_custom_headers() -> void:
	_custom_headers.clear()
	print("[SecurityHeaders] All custom headers cleared")


## Change preset
func set_preset(preset: HeaderPreset) -> void:
	_preset = preset
	print("[SecurityHeaders] Preset changed to: ", _get_preset_name(preset))


## Enable/disable middleware
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	print("[SecurityHeaders] Middleware ", "enabled" if enabled else "disabled")


## Get statistics
func get_stats() -> Dictionary:
	return {
		"enabled": _enabled,
		"preset": _get_preset_name(_preset),
		"responses_processed": _responses_processed,
		"headers_added": _headers_added,
		"custom_headers_count": _custom_headers.size()
	}


## Get current configuration
func get_config() -> Dictionary:
	var headers = _get_headers_for_preset(_preset)
	for key in _custom_headers:
		headers[key] = _custom_headers[key]

	return {
		"preset": _get_preset_name(_preset),
		"enabled": _enabled,
		"headers": headers,
		"custom_headers": _custom_headers.duplicate()
	}


## Get preset name as string
func _get_preset_name(preset: HeaderPreset) -> String:
	match preset:
		HeaderPreset.STRICT:
			return "STRICT"
		HeaderPreset.MODERATE:
			return "MODERATE"
		HeaderPreset.PERMISSIVE:
			return "PERMISSIVE"
		_:
			return "UNKNOWN"


## Helper: Enable HSTS header (only use when HTTPS is configured)
func enable_hsts(max_age: int = 31536000, include_subdomains: bool = true, enable_preload: bool = false) -> void:
	var hsts = "max-age=" + str(max_age)
	if include_subdomains:
		hsts += "; includeSubDomains"
	if enable_preload:
		hsts += "; preload"

	set_custom_header("Strict-Transport-Security", hsts)
	print("[SecurityHeaders] HSTS enabled: ", hsts)
	print("[SecurityHeaders] WARNING: Only use HSTS when serving over HTTPS!")


## Helper: Disable HSTS header
func disable_hsts() -> void:
	remove_custom_header("Strict-Transport-Security")
	print("[SecurityHeaders] HSTS disabled")


## Helper: Set custom CSP (Content Security Policy)
func set_csp(policy: String) -> void:
	set_custom_header("Content-Security-Policy", policy)
	print("[SecurityHeaders] Custom CSP set")


## Helper: Set custom Permissions-Policy
func set_permissions_policy(policy: String) -> void:
	set_custom_header("Permissions-Policy", policy)
	print("[SecurityHeaders] Custom Permissions-Policy set")


## Print configuration details
func print_config() -> void:
	print("\n" + "=".repeat(60))
	print("Security Headers Middleware Configuration")
	print("=".repeat(60))
	print("Enabled: ", _enabled)
	print("Preset: ", _get_preset_name(_preset))
	print("Responses processed: ", _responses_processed)
	print("Headers added: ", _headers_added)
	print("\nActive Headers:")

	var headers = _get_headers_for_preset(_preset)
	for key in _custom_headers:
		headers[key] = _custom_headers[key]

	for header_name in headers:
		var value = headers[header_name]
		# Truncate long values for readability
		if value.length() > 60:
			value = value.substr(0, 57) + "..."
		print("  ", header_name, ": ", value)

	if _custom_headers.size() > 0:
		print("\nCustom Headers (", _custom_headers.size(), "):")
		for key in _custom_headers:
			print("  ", key, ": ", _custom_headers[key])

	print("=".repeat(60) + "\n")


## Get header documentation
static func get_header_documentation() -> Dictionary:
	return {
		"X-Content-Type-Options": {
			"value": "nosniff",
			"purpose": "Prevents MIME type sniffing",
			"security_benefit": "Stops browsers from interpreting files as different types than declared, preventing XSS attacks",
			"compatibility": "All modern browsers",
			"reference": "https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options"
		},
		"X-Frame-Options": {
			"value": "DENY",
			"purpose": "Prevents clickjacking attacks",
			"security_benefit": "Prevents the page from being displayed in frames, protecting against UI redress attacks",
			"compatibility": "All modern browsers",
			"reference": "https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options"
		},
		"X-XSS-Protection": {
			"value": "1; mode=block",
			"purpose": "Enables XSS filter in legacy browsers",
			"security_benefit": "Stops page loading when XSS attack is detected (legacy support, CSP is preferred)",
			"compatibility": "Legacy browsers (Chrome, IE, Safari)",
			"reference": "https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-XSS-Protection"
		},
		"Content-Security-Policy": {
			"value": "default-src 'self'",
			"purpose": "Controls which resources can be loaded",
			"security_benefit": "Primary defense against XSS and injection attacks by restricting resource origins",
			"compatibility": "All modern browsers",
			"reference": "https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy"
		},
		"Referrer-Policy": {
			"value": "strict-origin-when-cross-origin",
			"purpose": "Controls referrer information sent",
			"security_benefit": "Prevents leaking sensitive URL information to third parties",
			"compatibility": "All modern browsers",
			"reference": "https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy"
		},
		"Permissions-Policy": {
			"value": "geolocation=(), microphone=(), camera=()",
			"purpose": "Disables dangerous browser features",
			"security_benefit": "Prevents unauthorized access to device capabilities",
			"compatibility": "Modern browsers (replaces Feature-Policy)",
			"reference": "https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Permissions-Policy"
		},
		"Strict-Transport-Security": {
			"value": "max-age=31536000; includeSubDomains",
			"purpose": "Forces HTTPS connections",
			"security_benefit": "Prevents man-in-the-middle attacks by enforcing encrypted connections",
			"compatibility": "All modern browsers",
			"reference": "https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security",
			"note": "ONLY use when serving over HTTPS"
		}
	}
