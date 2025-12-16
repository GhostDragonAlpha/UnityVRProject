extends RefCounted
class_name JWT

## JWT (JSON Web Token) implementation for Godot
## Supports HS256 (HMAC-SHA256) signing algorithm
##
## Usage:
##   # Create a token
##   var jwt = JWT.new()
##   var token = jwt.encode({"user_id": "123", "role": "admin"}, "your-secret-key", 3600)
##
##   # Verify and decode a token
##   var result = jwt.decode(token, "your-secret-key")
##   if result.valid:
##       print("User ID: ", result.payload.user_id)

const ALGORITHM = "HS256"

## Encodes a payload into a JWT token
## @param payload: Dictionary with claims to encode
## @param secret: Secret key for signing
## @param expires_in: Optional expiration time in seconds (default: 1 hour)
## @return: JWT token string
static func encode(payload: Dictionary, secret: String, expires_in: int = 3600) -> String:
	# Add standard claims
	var now = Time.get_unix_time_from_system()
	var claims = payload.duplicate()
	claims["iat"] = int(now)  # Issued at
	claims["exp"] = int(now + expires_in)  # Expiration

	# Create header
	var header = {
		"alg": ALGORITHM,
		"typ": "JWT"
	}

	# Encode header and payload
	var header_b64 = _base64url_encode(JSON.stringify(header))
	var payload_b64 = _base64url_encode(JSON.stringify(claims))

	# Create signature
	var message = header_b64 + "." + payload_b64
	var signature = _sign_hmac_sha256(message, secret)
	var signature_b64 = _base64url_encode(signature)

	# Return complete JWT
	return message + "." + signature_b64


## Decodes and verifies a JWT token
## @param token: JWT token string
## @param secret: Secret key for verification
## @return: Dictionary with 'valid', 'payload', and optional 'error' keys
static func decode(token: String, secret: String) -> Dictionary:
	# Split token into parts
	var parts = token.split(".")
	if parts.size() != 3:
		return {"valid": false, "error": "Invalid token format"}

	var header_b64 = parts[0]
	var payload_b64 = parts[1]
	var signature_b64 = parts[2]

	# Verify signature
	var message = header_b64 + "." + payload_b64
	var expected_signature = _sign_hmac_sha256(message, secret)
	var expected_signature_b64 = _base64url_encode(expected_signature)

	if signature_b64 != expected_signature_b64:
		return {"valid": false, "error": "Invalid signature"}

	# Decode header
	var header_json = _base64url_decode(header_b64)
	var header_parse = JSON.parse_string(header_json)
	if header_parse == null:
		return {"valid": false, "error": "Invalid header JSON"}

	# Check algorithm
	if header_parse.get("alg") != ALGORITHM:
		return {"valid": false, "error": "Unsupported algorithm: " + str(header_parse.get("alg"))}

	# Decode payload
	var payload_json = _base64url_decode(payload_b64)
	var payload = JSON.parse_string(payload_json)
	if payload == null:
		return {"valid": false, "error": "Invalid payload JSON"}

	# Check expiration
	if payload.has("exp"):
		var now = Time.get_unix_time_from_system()
		if int(payload.exp) < now:
			return {"valid": false, "error": "Token expired", "payload": payload}

	return {"valid": true, "payload": payload}


## Encodes data to base64url format (URL-safe base64)
## @param data: String or PackedByteArray to encode
## @return: Base64URL encoded string
static func _base64url_encode(data) -> String:
	var bytes: PackedByteArray
	if data is String:
		bytes = data.to_utf8_buffer()
	elif data is PackedByteArray:
		bytes = data
	else:
		push_error("Invalid data type for base64url encoding")
		return ""

	var b64 = Marshalls.raw_to_base64(bytes)
	# Convert to URL-safe base64
	b64 = b64.replace("+", "-")
	b64 = b64.replace("/", "_")
	b64 = b64.trim_suffix("=")  # Remove padding
	return b64


## Decodes base64url format back to string
## @param data: Base64URL encoded string
## @return: Decoded string
static func _base64url_decode(data: String) -> String:
	# Convert from URL-safe base64 to standard base64
	var b64 = data.replace("-", "+")
	b64 = b64.replace("_", "/")

	# Add padding if needed
	var padding = (4 - (b64.length() % 4)) % 4
	for i in range(padding):
		b64 += "="

	var bytes = Marshalls.base64_to_raw(b64)
	return bytes.get_string_from_utf8()


## Signs a message with HMAC-SHA256
## @param message: Message to sign
## @param secret: Secret key
## @return: Signature as PackedByteArray
static func _sign_hmac_sha256(message: String, secret: String) -> PackedByteArray:
	var crypto = Crypto.new()
	var key = secret.to_utf8_buffer()
	var msg = message.to_utf8_buffer()

	# Use Godot's built-in HMAC
	var context = HMACContext.new()
	context.start(HashingContext.HASH_SHA256, key)
	context.update(msg)
	var signature = context.finish()

	return signature


## Quick validation without decoding payload (useful for performance)
## @param token: JWT token string
## @param secret: Secret key for verification
## @return: true if token is valid and not expired
static func quick_verify(token: String, secret: String) -> bool:
	var result = decode(token, secret)
	return result.valid


## Refreshes a token (creates new token with same payload but new expiration)
## @param token: Existing JWT token
## @param secret: Secret key
## @param expires_in: New expiration time in seconds
## @return: New JWT token or empty string if original token is invalid
static func refresh(token: String, secret: String, expires_in: int = 3600) -> String:
	var result = decode(token, secret)
	if not result.valid:
		return ""

	# Remove old timestamps
	var payload = result.payload.duplicate()
	payload.erase("iat")
	payload.erase("exp")

	return encode(payload, secret, expires_in)
