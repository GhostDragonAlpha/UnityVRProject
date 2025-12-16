# Batch Operations API

The Batch Operations API allows you to execute multiple scene management operations in a single request, with support for transactional and continue-on-error modes.

## Table of Contents

- [Overview](#overview)
- [Endpoint](#endpoint)
- [Request Format](#request-format)
- [Operation Types](#operation-types)
- [Execution Modes](#execution-modes)
- [Response Format](#response-format)
- [Rate Limiting](#rate-limiting)
- [Examples](#examples)
- [Error Handling](#error-handling)

## Overview

Batch operations enable efficient execution of multiple scene management tasks:
- Load multiple scenes sequentially
- Validate multiple scenes in one request
- Mix different operation types
- Choose between transactional (all-or-nothing) or continue-on-error modes
- Get detailed results for each operation

## Endpoint

```
POST /batch
```

**Authentication:** Required (Bearer token)

## Request Format

```json
{
  "operations": [
    {
      "action": "load|validate|get_info",
      "scene_path": "res://path/to/scene.tscn"  // Required for load and validate
    }
  ],
  "mode": "continue|transactional"  // Optional, defaults to "continue"
}
```

### Fields

- **operations** (required): Array of operation objects (max 50)
- **mode** (optional): Execution mode - "continue" or "transactional"

### Operation Object

- **action** (required): Operation type - "load", "validate", or "get_info"
- **scene_path** (required for load/validate): Path to scene file

## Operation Types

### 1. load

Loads a scene file.

```json
{
  "action": "load",
  "scene_path": "res://vr_main.tscn"
}
```

**Requirements:**
- Scene path must be whitelisted
- Scene file must exist
- Path must start with "res://" and end with ".tscn"

### 2. validate

Validates a scene without loading it.

```json
{
  "action": "validate",
  "scene_path": "res://test_scene.tscn"
}
```

**Returns:**
- Validation status
- Error messages
- Warnings
- Scene metadata (node count, root type, etc.)

### 3. get_info

Gets information about the currently loaded scene.

```json
{
  "action": "get_info"
}
```

**Returns:**
- Current scene name
- Current scene path
- Load status

## Execution Modes

### Continue Mode (default)

Executes all operations regardless of failures. Each operation's success/failure is tracked independently.

```json
{
  "mode": "continue",
  "operations": [...]
}
```

**Characteristics:**
- All operations are attempted
- Failures don't stop execution
- Partial success is possible
- Best for independent operations

**Use cases:**
- Validating multiple scenes
- Mixed operations where some failures are acceptable
- Gathering information from multiple sources

### Transactional Mode

Stops execution on first failure and rolls back successful operations.

```json
{
  "mode": "transactional",
  "operations": [...]
}
```

**Characteristics:**
- Stops on first failure
- Rolls back successful operations
- All-or-nothing execution
- Guarantees consistency

**Use cases:**
- Critical operations that must all succeed
- Operations with dependencies
- When partial execution is unacceptable

## Response Format

```json
{
  "mode": "continue",
  "total": 3,
  "successful": 2,
  "failed": 1,
  "message": "Batch completed with 2 successful and 1 failed operations",
  "operations": [
    {
      "index": 0,
      "action": "validate",
      "scene_path": "res://vr_main.tscn",
      "success": true,
      "result": {
        "valid": true,
        "errors": [],
        "warnings": [],
        "scene_info": {
          "node_count": 42,
          "root_type": "Node3D",
          "root_name": "VRMain"
        }
      }
    },
    {
      "index": 1,
      "action": "load",
      "scene_path": "res://nonexistent.tscn",
      "success": false,
      "error": "Scene file not found: res://nonexistent.tscn"
    },
    {
      "index": 2,
      "action": "get_info",
      "scene_path": "",
      "success": true,
      "result": {
        "scene_name": "VRMain",
        "scene_path": "res://vr_main.tscn",
        "status": "loaded"
      }
    }
  ]
}
```

### Transactional Rollback Response

```json
{
  "mode": "transactional",
  "total": 3,
  "successful": 1,
  "failed": 1,
  "rollback": true,
  "message": "Transaction failed, rolled back 1 operations",
  "operations": [
    {
      "index": 0,
      "action": "validate",
      "scene_path": "res://vr_main.tscn",
      "success": true,
      "result": {...}
    },
    {
      "index": 1,
      "action": "load",
      "scene_path": "res://nonexistent.tscn",
      "success": false,
      "error": "Scene file not found"
    }
  ]
}
```

## Rate Limiting

Batch operations are rate-limited to prevent abuse:

- **Limit:** 10 batch requests per minute
- **Response on limit:** HTTP 429 Too Many Requests
- **Retry header:** `retry_after: 60` (seconds)

Rate limit exceeded response:

```json
{
  "error": "Too Many Requests",
  "message": "Batch operation rate limit exceeded",
  "retry_after": 60
}
```

**Note:** This triggers a `rate_limit.exceeded` webhook event if configured.

## Examples

### Example 1: Validate Multiple Scenes

```bash
curl -X POST http://localhost:8080/batch \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "operations": [
      {"action": "validate", "scene_path": "res://vr_main.tscn"},
      {"action": "validate", "scene_path": "res://node_3d.tscn"},
      {"action": "validate", "scene_path": "res://test_scene.tscn"}
    ]
  }'
```

### Example 2: Load Scene with Validation (Transactional)

```bash
curl -X POST http://localhost:8080/batch \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "transactional",
    "operations": [
      {"action": "validate", "scene_path": "res://vr_main.tscn"},
      {"action": "load", "scene_path": "res://vr_main.tscn"}
    ]
  }'
```

### Example 3: Get Info and Validate

```bash
curl -X POST http://localhost:8080/batch \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "operations": [
      {"action": "get_info"},
      {"action": "validate", "scene_path": "res://test_scene.tscn"}
    ]
  }'
```

### Example 4: Python Client

```python
import requests

API_URL = "http://localhost:8080"
TOKEN = "your_api_token"

headers = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

batch_request = {
    "mode": "continue",
    "operations": [
        {"action": "validate", "scene_path": "res://vr_main.tscn"},
        {"action": "validate", "scene_path": "res://node_3d.tscn"},
        {"action": "get_info"}
    ]
}

response = requests.post(
    f"{API_URL}/batch",
    headers=headers,
    json=batch_request
)

if response.status_code == 200:
    data = response.json()
    print(f"Batch completed: {data['successful']}/{data['total']} successful")

    for op in data['operations']:
        status = "✓" if op['success'] else "✗"
        print(f"{status} Operation {op['index']}: {op['action']}")
        if not op['success']:
            print(f"  Error: {op['error']}")
else:
    print(f"Error: {response.status_code}")
    print(response.json())
```

## Error Handling

### Common Error Codes

| Code | Description | Solution |
|------|-------------|----------|
| 400 | Bad Request | Check request format, operation types, and scene paths |
| 401 | Unauthorized | Include valid Bearer token |
| 403 | Forbidden | Scene not whitelisted or path traversal detected |
| 413 | Payload Too Large | Reduce number of operations (max 50) |
| 429 | Too Many Requests | Wait 60 seconds before retrying |

### Validation Errors

**Empty operations array:**
```json
{
  "error": "Bad Request",
  "message": "Operations array cannot be empty"
}
```

**Invalid mode:**
```json
{
  "error": "Bad Request",
  "message": "Invalid mode. Must be 'transactional' or 'continue'"
}
```

**Missing scene_path:**
```json
{
  "error": "Bad Request",
  "message": "Operation 0 missing 'scene_path' field"
}
```

**Scene not whitelisted:**
```json
{
  "error": "Bad Request",
  "message": "Operation 0: Scene not in whitelist"
}
```

**Batch size exceeded:**
```json
{
  "error": "Bad Request",
  "message": "Batch size exceeds maximum of 50"
}
```

### Best Practices

1. **Use continue mode** for independent operations
2. **Use transactional mode** when operations have dependencies
3. **Validate scenes** before loading in production
4. **Handle rate limits** with exponential backoff
5. **Check individual operation results** even when status is 200
6. **Keep batches small** for better error isolation
7. **Use webhooks** to monitor batch operation completion

### Troubleshooting

**Problem:** Batch request returns 429 Too Many Requests

**Solution:** Implement rate limit handling:

```python
import time

def batch_request_with_retry(url, headers, data, max_retries=3):
    for attempt in range(max_retries):
        response = requests.post(url, headers=headers, json=data)

        if response.status_code == 429:
            retry_after = response.json().get('retry_after', 60)
            print(f"Rate limited, waiting {retry_after}s...")
            time.sleep(retry_after)
            continue

        return response

    raise Exception("Max retries exceeded")
```

**Problem:** Transactional mode not rolling back

**Solution:** Check that operations are actually succeeding before the failure point. Rollback only undoes successful operations before the first failure.

**Problem:** Operations executing out of order

**Solution:** Operations execute sequentially in the order provided. Use the `index` field in results to verify ordering.

## Integration with Webhooks

Batch operations trigger webhook events:

- `scene.loaded` - When a scene load operation completes
- `scene.failed` - When a scene load operation fails
- `scene.validated` - When a scene validation completes
- `rate_limit.exceeded` - When rate limit is hit

See [WEBHOOKS.md](./WEBHOOKS.md) for webhook configuration.

## Integration with Job Queue

For long-running batch operations, use the Job Queue API:

```bash
curl -X POST http://localhost:8080/jobs \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "batch_operations",
    "parameters": {
      "operations": [...],
      "mode": "continue"
    }
  }'
```

See [JOB_QUEUE.md](./JOB_QUEUE.md) for details.

## Performance Considerations

- Each operation adds ~50-100ms overhead
- Validation operations are fast (~10-50ms)
- Load operations are slower (~500ms-2s)
- Transactional mode adds rollback overhead
- Rate limiting prevents server overload
- Consider job queue for >20 operations

## Security Notes

- All scene paths must be whitelisted in `security_config.gd`
- Path traversal attacks are prevented (no ".." in paths)
- Authentication required for all batch operations
- Rate limiting prevents DoS attacks
- Maximum batch size prevents memory exhaustion
- Failed authentication triggers `auth.failed` webhook event

## See Also

- [HTTP API Reference](./API_REFERENCE.md)
- [Webhooks Documentation](./WEBHOOKS.md)
- [Job Queue Documentation](./JOB_QUEUE.md)
- [Security Testing Guide](../../tests/http_api/SECURITY_TESTING_GUIDE.md)
