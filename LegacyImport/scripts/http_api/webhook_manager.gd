extends Node
# Note: class_name removed to avoid conflict with autoload singleton named WebhookManager

## Webhook Manager
## Manages webhook registration, delivery, and retry logic with HMAC signatures
## Supports events: scene.loaded, scene.failed, scene.validated, scene.reloaded, auth.failed, rate_limit.exceeded

signal webhook_delivered(webhook_id: String, event: String, success: bool)
signal webhook_failed(webhook_id: String, event: String, attempts: int)

# Webhook storage
var _webhooks: Dictionary = {}  # webhook_id -> webhook_config
var _next_webhook_id: int = 1
var _delivery_history: Dictionary = {}  # webhook_id -> Array[delivery_record]

# Delivery configuration
const MAX_RETRY_ATTEMPTS = 3
const RETRY_BACKOFF_SECONDS = [1.0, 5.0, 15.0]  # Exponential backoff
const DELIVERY_TIMEOUT = 10.0
const MAX_HISTORY_PER_WEBHOOK = 100

# HTTP client pool for webhook delivery
var _http_clients: Array = []
const MAX_CONCURRENT_DELIVERIES = 5

# Singleton instance
static var _instance: Node = null


func _init():
	if _instance == null:
		_instance = self


func _ready():
	print("[WebhookManager] Initialized webhook system")
	# Initialize HTTP client pool
	for i in range(MAX_CONCURRENT_DELIVERIES):
		var client = HTTPRequest.new()
		add_child(client)
		client.timeout = DELIVERY_TIMEOUT
		_http_clients.append(client)


static func get_instance() -> Node:
	return _instance


## Register a new webhook
## Returns webhook_id on success, or error dictionary
func register_webhook(url: String, events: Array, secret: String = "") -> Dictionary:
	# Validate URL
	if not _is_valid_url(url):
		return {
			"success": false,
			"error": "Invalid webhook URL"
		}

	# Validate events
	var valid_events = _validate_events(events)
	if valid_events.is_empty():
		return {
			"success": false,
			"error": "No valid events specified"
		}

	# Generate webhook ID
	var webhook_id = str(_next_webhook_id)
	_next_webhook_id += 1

	# Create webhook configuration
	var webhook = {
		"id": webhook_id,
		"url": url,
		"events": valid_events,
		"secret": secret,
		"created_at": Time.get_unix_time_from_system(),
		"enabled": true,
		"delivery_count": 0,
		"failure_count": 0,
		"last_delivery": null
	}

	_webhooks[webhook_id] = webhook
	_delivery_history[webhook_id] = []

	print("[WebhookManager] Registered webhook: ", webhook_id, " for events: ", valid_events)

	return {
		"success": true,
		"webhook_id": webhook_id,
		"webhook": _sanitize_webhook_for_response(webhook)
	}


## Update an existing webhook
func update_webhook(webhook_id: String, updates: Dictionary) -> Dictionary:
	if not _webhooks.has(webhook_id):
		return {
			"success": false,
			"error": "Webhook not found"
		}

	var webhook = _webhooks[webhook_id]

	# Update allowed fields
	if updates.has("url"):
		if not _is_valid_url(updates.url):
			return {
				"success": false,
				"error": "Invalid webhook URL"
			}
		webhook.url = updates.url

	if updates.has("events"):
		var valid_events = _validate_events(updates.events)
		if valid_events.is_empty():
			return {
				"success": false,
				"error": "No valid events specified"
			}
		webhook.events = valid_events

	if updates.has("secret"):
		webhook.secret = updates.secret

	if updates.has("enabled"):
		webhook.enabled = bool(updates.enabled)

	print("[WebhookManager] Updated webhook: ", webhook_id)

	return {
		"success": true,
		"webhook": _sanitize_webhook_for_response(webhook)
	}


## Delete a webhook
func delete_webhook(webhook_id: String) -> Dictionary:
	if not _webhooks.has(webhook_id):
		return {
			"success": false,
			"error": "Webhook not found"
		}

	_webhooks.erase(webhook_id)
	_delivery_history.erase(webhook_id)

	print("[WebhookManager] Deleted webhook: ", webhook_id)

	return {
		"success": true,
		"message": "Webhook deleted"
	}


## Get webhook details
func get_webhook(webhook_id: String) -> Dictionary:
	if not _webhooks.has(webhook_id):
		return {
			"success": false,
			"error": "Webhook not found"
		}

	return {
		"success": true,
		"webhook": _sanitize_webhook_for_response(_webhooks[webhook_id])
	}


## List all webhooks
func list_webhooks() -> Dictionary:
	var webhooks = []
	for webhook_id in _webhooks.keys():
		webhooks.append(_sanitize_webhook_for_response(_webhooks[webhook_id]))

	return {
		"success": true,
		"webhooks": webhooks,
		"count": webhooks.size()
	}


## Get delivery history for a webhook
func get_delivery_history(webhook_id: String, limit: int = 50) -> Dictionary:
	if not _webhooks.has(webhook_id):
		return {
			"success": false,
			"error": "Webhook not found"
		}

	var history = _delivery_history.get(webhook_id, [])
	var limited_history = history.slice(0, min(limit, history.size()))

	return {
		"success": true,
		"webhook_id": webhook_id,
		"deliveries": limited_history,
		"count": limited_history.size(),
		"total": history.size()
	}


## Trigger a webhook event
func trigger_event(event: String, payload: Dictionary) -> void:
	print("[WebhookManager] Triggering event: ", event)

	# Find webhooks subscribed to this event
	for webhook_id in _webhooks.keys():
		var webhook = _webhooks[webhook_id]

		# Skip if webhook is disabled
		if not webhook.enabled:
			continue

		# Check if webhook is subscribed to this event
		if not webhook.events.has(event):
			continue

		# Deliver webhook asynchronously
		_deliver_webhook(webhook_id, event, payload, 0)


## Deliver a webhook with retry logic
func _deliver_webhook(webhook_id: String, event: String, payload: Dictionary, attempt: int) -> void:
	if not _webhooks.has(webhook_id):
		return

	var webhook = _webhooks[webhook_id]

	# Check if we've exceeded max retries
	if attempt >= MAX_RETRY_ATTEMPTS:
		print("[WebhookManager] Max retries exceeded for webhook: ", webhook_id)
		webhook.failure_count += 1
		_record_delivery(webhook_id, event, payload, false, attempt, "Max retries exceeded")
		webhook_failed.emit(webhook_id, event, attempt)
		return

	# Prepare webhook payload
	var webhook_payload = {
		"event": event,
		"webhook_id": webhook_id,
		"timestamp": Time.get_unix_time_from_system(),
		"data": payload
	}

	var json_payload = JSON.stringify(webhook_payload)

	# Generate HMAC signature
	var signature = _generate_hmac_signature(json_payload, webhook.secret)

	# Find an available HTTP client
	var client = _get_available_client()
	if not client:
		# No available client, retry later
		print("[WebhookManager] No available HTTP client, retrying in ", RETRY_BACKOFF_SECONDS[attempt], "s")
		get_tree().create_timer(RETRY_BACKOFF_SECONDS[attempt]).timeout.connect(
			func(): _deliver_webhook(webhook_id, event, payload, attempt)
		)
		return

	# Setup headers
	var headers = [
		"Content-Type: application/json",
		"X-Webhook-Signature: " + signature,
		"X-Webhook-Event: " + event,
		"X-Webhook-ID: " + webhook_id,
		"X-Webhook-Attempt: " + str(attempt + 1)
	]

	# Connect to request completed signal
	var on_completed = func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
			# Success
			print("[WebhookManager] Webhook delivered successfully: ", webhook_id, " (attempt ", attempt + 1, ")")
			webhook.delivery_count += 1
			webhook.last_delivery = Time.get_unix_time_from_system()
			_record_delivery(webhook_id, event, payload, true, attempt, "Success")
			webhook_delivered.emit(webhook_id, event, true)
		else:
			# Failure - retry
			var error_msg = "HTTP " + str(response_code) if result == HTTPRequest.RESULT_SUCCESS else "Request failed"
			print("[WebhookManager] Webhook delivery failed: ", webhook_id, " - ", error_msg, " (attempt ", attempt + 1, ")")

			# Schedule retry with exponential backoff
			if attempt + 1 < MAX_RETRY_ATTEMPTS:
				var delay = RETRY_BACKOFF_SECONDS[attempt]
				print("[WebhookManager] Retrying in ", delay, " seconds...")
				get_tree().create_timer(delay).timeout.connect(
					func(): _deliver_webhook(webhook_id, event, payload, attempt + 1)
				)
			else:
				# Final failure
				webhook.failure_count += 1
				_record_delivery(webhook_id, event, payload, false, attempt, error_msg)
				webhook_failed.emit(webhook_id, event, attempt + 1)

	client.request_completed.connect(on_completed, CONNECT_ONE_SHOT)

	# Send request
	var error = client.request(webhook.url, headers, HTTPClient.METHOD_POST, json_payload)
	if error != OK:
		print("[WebhookManager] Failed to send webhook request: ", error)
		# Retry
		get_tree().create_timer(RETRY_BACKOFF_SECONDS[attempt]).timeout.connect(
			func(): _deliver_webhook(webhook_id, event, payload, attempt)
		)


## Get an available HTTP client from the pool
func _get_available_client() -> HTTPRequest:
	for client in _http_clients:
		if client.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
			return client
	return null


## Generate HMAC-SHA256 signature for webhook payload
func _generate_hmac_signature(payload: String, secret: String) -> String:
	if secret.is_empty():
		return ""

	# Create HMAC context
	var hmac = HMACContext.new()
	hmac.start(HashingContext.HASH_SHA256, secret.to_utf8_buffer())
	hmac.update(payload.to_utf8_buffer())
	var signature = hmac.finish()

	# Return hex-encoded signature
	return signature.hex_encode()


## Record delivery attempt in history
func _record_delivery(webhook_id: String, event: String, payload: Dictionary, success: bool, attempt: int, message: String) -> void:
	if not _delivery_history.has(webhook_id):
		_delivery_history[webhook_id] = []

	var record = {
		"event": event,
		"timestamp": Time.get_unix_time_from_system(),
		"success": success,
		"attempts": attempt + 1,
		"message": message,
		"payload_size": JSON.stringify(payload).length()
	}

	var history = _delivery_history[webhook_id]
	history.push_front(record)

	# Keep only last MAX_HISTORY_PER_WEBHOOK entries
	if history.size() > MAX_HISTORY_PER_WEBHOOK:
		history.resize(MAX_HISTORY_PER_WEBHOOK)


## Validate webhook URL
func _is_valid_url(url: String) -> bool:
	return url.begins_with("http://") or url.begins_with("https://")


## Validate and filter events
func _validate_events(events: Array) -> Array:
	const VALID_EVENTS = [
		"scene.loaded",
		"scene.failed",
		"scene.validated",
		"scene.reloaded",
		"auth.failed",
		"rate_limit.exceeded"
	]

	var valid = []
	for event in events:
		if VALID_EVENTS.has(event):
			valid.append(event)

	return valid


## Sanitize webhook for API response (hide secret)
func _sanitize_webhook_for_response(webhook: Dictionary) -> Dictionary:
	var sanitized = webhook.duplicate()
	if sanitized.has("secret") and not sanitized.secret.is_empty():
		sanitized.secret = "***"
	return sanitized


## Get all supported event types
static func get_supported_events() -> Array:
	return [
		"scene.loaded",
		"scene.failed",
		"scene.validated",
		"scene.reloaded",
		"auth.failed",
		"rate_limit.exceeded"
	]
