# Webhooks API

The Webhooks API enables real-time notifications for scene management events. Configure HTTP endpoints to receive POST requests when specific events occur.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Endpoints](#endpoints)
- [Event Types](#event-types)
- [Security](#security)
- [Delivery and Retries](#delivery-and-retries)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Overview

Webhooks provide event-driven notifications for:
- Scene load successes and failures
- Scene validation results
- Authentication failures
- Rate limit violations

**Key Features:**
- HMAC-SHA256 signature verification
- Automatic retry with exponential backoff
- Delivery history tracking
- Multiple event subscriptions per webhook
- Concurrent delivery to multiple webhooks

## Quick Start

### 1. Register a Webhook

```bash
curl -X POST http://localhost:8080/webhooks \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-server.com/webhook",
    "events": ["scene.loaded", "scene.failed"],
    "secret": "your_webhook_secret"
  }'
```

Response:
```json
{
  "success": true,
  "webhook_id": "1",
  "webhook": {
    "id": "1",
    "url": "https://your-server.com/webhook",
    "events": ["scene.loaded", "scene.failed"],
    "secret": "***",
    "created_at": 1699564800,
    "enabled": true,
    "delivery_count": 0,
    "failure_count": 0
  }
}
```

### 2. Receive Webhook Events

Your webhook endpoint will receive POST requests:

```json
{
  "event": "scene.loaded",
  "webhook_id": "1",
  "timestamp": 1699564850,
  "data": {
    "scene_path": "res://vr_main.tscn"
  }
}
```

### 3. Verify Signature

```python
import hmac
import hashlib

def verify_webhook(payload_body, signature, secret):
    expected = hmac.new(
        secret.encode('utf-8'),
        payload_body.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(signature, expected)

# In your webhook handler:
signature = request.headers.get('X-Webhook-Signature')
is_valid = verify_webhook(request.body, signature, 'your_webhook_secret')
```

## Endpoints

### Register Webhook

```
POST /webhooks
```

**Request:**
```json
{
  "url": "https://example.com/webhook",
  "events": ["scene.loaded", "scene.failed"],
  "secret": "optional_signing_secret"
}
```

**Response:** 201 Created
```json
{
  "success": true,
  "webhook_id": "1",
  "webhook": {...}
}
```

### List Webhooks

```
GET /webhooks
```

**Response:** 200 OK
```json
{
  "success": true,
  "webhooks": [...],
  "count": 3
}
```

### Get Webhook Details

```
GET /webhooks/:id
```

**Response:** 200 OK
```json
{
  "success": true,
  "webhook": {
    "id": "1",
    "url": "https://example.com/webhook",
    "events": ["scene.loaded"],
    "enabled": true,
    "delivery_count": 42,
    "failure_count": 2,
    "last_delivery": 1699564900
  }
}
```

### Update Webhook

```
PUT /webhooks/:id
```

**Request:**
```json
{
  "url": "https://new-url.com/webhook",
  "events": ["scene.loaded", "scene.validated"],
  "enabled": false
}
```

**Response:** 200 OK

### Delete Webhook

```
DELETE /webhooks/:id
```

**Response:** 200 OK
```json
{
  "success": true,
  "message": "Webhook deleted"
}
```

### Get Delivery History

```
GET /webhooks/:id/deliveries?limit=50
```

**Response:** 200 OK
```json
{
  "success": true,
  "webhook_id": "1",
  "deliveries": [
    {
      "event": "scene.loaded",
      "timestamp": 1699564900,
      "success": true,
      "attempts": 1,
      "message": "Success",
      "payload_size": 156
    }
  ],
  "count": 10,
  "total": 42
}
```

## Event Types

### scene.loaded

Triggered when a scene successfully loads.

**Payload:**
```json
{
  "event": "scene.loaded",
  "webhook_id": "1",
  "timestamp": 1699564900,
  "data": {
    "scene_path": "res://vr_main.tscn"
  }
}
```

### scene.failed

Triggered when a scene fails to load.

**Payload:**
```json
{
  "event": "scene.failed",
  "webhook_id": "1",
  "timestamp": 1699564900,
  "data": {
    "scene_path": "res://nonexistent.tscn",
    "error": "Scene file not found"
  }
}
```

### scene.validated

Triggered when a scene validation completes.

**Payload:**
```json
{
  "event": "scene.validated",
  "webhook_id": "1",
  "timestamp": 1699564900,
  "data": {
    "scene_path": "res://test_scene.tscn",
    "valid": true,
    "errors": [],
    "warnings": [],
    "scene_info": {
      "node_count": 24,
      "root_type": "Node3D"
    }
  }
}
```

### scene.reloaded

Triggered when a scene is reloaded.

**Payload:**
```json
{
  "event": "scene.reloaded",
  "webhook_id": "1",
  "timestamp": 1699564900,
  "data": {
    "scene_path": "res://vr_main.tscn"
  }
}
```

### auth.failed

Triggered when authentication fails.

**Payload:**
```json
{
  "event": "auth.failed",
  "webhook_id": "1",
  "timestamp": 1699564900,
  "data": {
    "endpoint": "/scene",
    "ip": "127.0.0.1"
  }
}
```

### rate_limit.exceeded

Triggered when rate limit is exceeded.

**Payload:**
```json
{
  "event": "rate_limit.exceeded",
  "webhook_id": "1",
  "timestamp": 1699564900,
  "data": {
    "endpoint": "/batch",
    "ip": "127.0.0.1",
    "timestamp": 1699564900
  }
}
```

## Security

### HMAC Signature Verification

Every webhook delivery includes an HMAC-SHA256 signature in the `X-Webhook-Signature` header.

**Headers sent:**
```
Content-Type: application/json
X-Webhook-Signature: abc123...
X-Webhook-Event: scene.loaded
X-Webhook-ID: 1
X-Webhook-Attempt: 1
```

**Verification algorithm:**
1. Get signature from `X-Webhook-Signature` header
2. Compute HMAC-SHA256 of request body using your secret
3. Compare signatures using constant-time comparison

**Python example:**
```python
import hmac
import hashlib

def verify_webhook_signature(payload, signature, secret):
    """Verify webhook HMAC signature"""
    if not secret:
        return True  # No secret = no verification

    expected = hmac.new(
        secret.encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(signature, expected)
```

**Node.js example:**
```javascript
const crypto = require('crypto');

function verifyWebhook(payload, signature, secret) {
  if (!secret) return true;

  const expected = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expected)
  );
}
```

### Best Practices

1. **Always verify signatures** in production
2. **Use HTTPS** for webhook URLs
3. **Rotate secrets** periodically
4. **Validate event types** before processing
5. **Implement idempotency** using timestamp/ID
6. **Log failed verifications** for security monitoring
7. **Rate limit webhook endpoints** to prevent abuse

## Delivery and Retries

### Delivery Mechanism

- **Method:** HTTP POST
- **Content-Type:** application/json
- **Timeout:** 10 seconds
- **Concurrent deliveries:** Up to 5 simultaneous

### Retry Strategy

Failed deliveries are automatically retried with exponential backoff:

| Attempt | Delay | Total Time |
|---------|-------|------------|
| 1 (initial) | 0s | 0s |
| 2 | 1s | 1s |
| 3 | 5s | 6s |
| 4 | 15s | 21s |

**Conditions for retry:**
- HTTP status code >= 300
- Connection timeout
- Network error

**No retry on:**
- Max attempts reached (3)
- Webhook disabled
- Invalid webhook URL

### Success Criteria

A delivery is considered successful when:
- HTTP status code 200-299
- Response received within 10 seconds

## Examples

### Complete Webhook Server (Python/Flask)

```python
from flask import Flask, request, jsonify
import hmac
import hashlib

app = Flask(__name__)
WEBHOOK_SECRET = "your_webhook_secret"

def verify_signature(payload, signature):
    if not WEBHOOK_SECRET:
        return True

    expected = hmac.new(
        WEBHOOK_SECRET.encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(signature, expected)

@app.route('/webhook', methods=['POST'])
def webhook_handler():
    # Get signature and event type
    signature = request.headers.get('X-Webhook-Signature', '')
    event_type = request.headers.get('X-Webhook-Event', '')
    webhook_id = request.headers.get('X-Webhook-ID', '')
    attempt = request.headers.get('X-Webhook-Attempt', '1')

    # Get payload
    payload = request.get_data(as_text=True)

    # Verify signature
    if not verify_signature(payload, signature):
        print(f"Invalid signature for webhook {webhook_id}")
        return jsonify({"error": "Invalid signature"}), 401

    # Parse JSON
    data = request.get_json()

    # Process event
    print(f"Received webhook: {event_type} (attempt {attempt})")
    print(f"Data: {data}")

    # Handle different event types
    if event_type == "scene.loaded":
        handle_scene_loaded(data['data'])
    elif event_type == "scene.failed":
        handle_scene_failed(data['data'])
    elif event_type == "scene.validated":
        handle_scene_validated(data['data'])

    return jsonify({"status": "ok"}), 200

def handle_scene_loaded(data):
    scene_path = data.get('scene_path')
    print(f"Scene loaded: {scene_path}")
    # Your business logic here

def handle_scene_failed(data):
    scene_path = data.get('scene_path')
    error = data.get('error')
    print(f"Scene load failed: {scene_path} - {error}")
    # Your error handling here

def handle_scene_validated(data):
    scene_path = data.get('scene_path')
    valid = data.get('valid')
    print(f"Scene validation: {scene_path} - {'✓' if valid else '✗'}")
    # Your validation handling here

if __name__ == '__main__':
    app.run(port=9000)
```

### Testing Webhook Locally with ngrok

```bash
# Start your webhook server
python webhook_server.py

# In another terminal, expose it with ngrok
ngrok http 9000

# Register webhook with ngrok URL
curl -X POST http://localhost:8080/webhooks \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-id.ngrok.io/webhook",
    "events": ["scene.loaded", "scene.failed"],
    "secret": "test_secret"
  }'

# Trigger an event
curl -X POST http://localhost:8080/scene \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scene_path": "res://vr_main.tscn"}'
```

## Troubleshooting

### Webhook Not Receiving Events

1. **Check webhook registration:**
   ```bash
   curl http://localhost:8080/webhooks \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

2. **Verify events are subscribed:**
   - Ensure the event type is in your webhook's `events` array

3. **Check delivery history:**
   ```bash
   curl http://localhost:8080/webhooks/1/deliveries \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

4. **Verify webhook is enabled:**
   - Check `enabled: true` in webhook details

5. **Test webhook URL:**
   ```bash
   curl -X POST https://your-server.com/webhook \
     -d '{"test": true}'
   ```

### Signature Verification Failing

1. **Check secret matches:**
   - Secret used in verification must match registration secret

2. **Verify payload:**
   - Use raw request body, not parsed JSON
   - Include entire body exactly as received

3. **Debug signature:**
   ```python
   print(f"Received: {signature}")
   print(f"Expected: {expected}")
   print(f"Body: {payload}")
   ```

### Deliveries Timing Out

1. **Optimize webhook handler:**
   - Return response quickly (<10s)
   - Process events asynchronously

2. **Check network:**
   - Ensure webhook URL is accessible
   - Test with curl from Godot server

3. **Review logs:**
   - Check delivery history for timeout patterns

### High Failure Rate

1. **Check webhook server:**
   - Ensure it's running and responsive
   - Review server logs for errors

2. **Verify URL:**
   - Must be valid HTTP/HTTPS URL
   - Must be publicly accessible

3. **Test connectivity:**
   ```bash
   curl -X POST https://your-server.com/webhook \
     -H "Content-Type: application/json" \
     -d '{"test": true}'
   ```

## Advanced Usage

### Webhook Filtering

Process only specific events:

```python
@app.route('/webhook', methods=['POST'])
def webhook_handler():
    event_type = request.headers.get('X-Webhook-Event')

    # Only process scene load events
    if event_type != "scene.loaded":
        return jsonify({"status": "ignored"}), 200

    # Process event...
```

### Idempotency

Prevent duplicate processing:

```python
processed_events = set()

@app.route('/webhook', methods=['POST'])
def webhook_handler():
    data = request.get_json()
    event_id = f"{data['webhook_id']}_{data['timestamp']}"

    # Check if already processed
    if event_id in processed_events:
        return jsonify({"status": "already_processed"}), 200

    # Process event
    process_webhook(data)

    # Mark as processed
    processed_events.add(event_id)

    return jsonify({"status": "ok"}), 200
```

### Monitoring

Track webhook delivery metrics:

```python
from collections import defaultdict

webhook_stats = defaultdict(lambda: {"received": 0, "processed": 0, "failed": 0})

@app.route('/webhook', methods=['POST'])
def webhook_handler():
    event_type = request.headers.get('X-Webhook-Event')
    webhook_stats[event_type]["received"] += 1

    try:
        process_webhook(request.get_json())
        webhook_stats[event_type]["processed"] += 1
    except Exception as e:
        webhook_stats[event_type]["failed"] += 1
        raise

    return jsonify({"status": "ok"}), 200

@app.route('/webhook/stats')
def webhook_stats_endpoint():
    return jsonify(dict(webhook_stats))
```

## See Also

- [Batch Operations](./BATCH_OPERATIONS.md)
- [Job Queue](./JOB_QUEUE.md)
- [HTTP API Reference](./API_REFERENCE.md)
- [Security Testing Guide](../../tests/http_api/SECURITY_TESTING_GUIDE.md)
