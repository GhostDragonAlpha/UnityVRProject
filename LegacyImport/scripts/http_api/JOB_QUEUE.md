# Job Queue API

The Job Queue API enables asynchronous execution of long-running operations with status tracking, progress monitoring, and result storage.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Endpoints](#endpoints)
- [Job Types](#job-types)
- [Job Lifecycle](#job-lifecycle)
- [Examples](#examples)
- [Best Practices](#best-practices)

## Overview

The Job Queue system provides:
- **Async execution** of long-running tasks
- **Status tracking** (queued, running, completed, failed, cancelled)
- **Progress monitoring** with real-time updates
- **Result storage** for 24 hours
- **Concurrent execution** (up to 3 jobs simultaneously)
- **Cancellation** for queued jobs

**Use cases:**
- Large batch operations (>20 scenes)
- Scene preloading for performance
- Cache warming
- Background processing

## Quick Start

### 1. Submit a Job

```bash
curl -X POST http://localhost:8080/jobs \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "scene_preload",
    "parameters": {
      "scene_paths": [
        "res://vr_main.tscn",
        "res://node_3d.tscn",
        "res://test_scene.tscn"
      ]
    }
  }'
```

Response (202 Accepted):
```json
{
  "success": true,
  "job_id": "1",
  "status": "queued"
}
```

### 2. Check Job Status

```bash
curl http://localhost:8080/jobs/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Response:
```json
{
  "success": true,
  "job": {
    "id": "1",
    "type": "scene_preload",
    "status": "running",
    "progress": 0.67,
    "created_at": 1699564800,
    "started_at": 1699564801,
    "completed_at": null,
    "result": null,
    "error": null
  }
}
```

### 3. Get Job Result

After completion:
```json
{
  "success": true,
  "job": {
    "id": "1",
    "type": "scene_preload",
    "status": "completed",
    "progress": 1.0,
    "created_at": 1699564800,
    "started_at": 1699564801,
    "completed_at": 1699564805,
    "result": {
      "scenes_loaded": 3,
      "total_scenes": 3,
      "scenes": [
        {"scene_path": "res://vr_main.tscn", "success": true},
        {"scene_path": "res://node_3d.tscn", "success": true},
        {"scene_path": "res://test_scene.tscn", "success": true}
      ]
    },
    "error": null
  }
}
```

## Endpoints

### Submit Job

```
POST /jobs
```

**Request:**
```json
{
  "type": "batch_operations|scene_preload|cache_warming",
  "parameters": { /* type-specific parameters */ }
}
```

**Response:** 202 Accepted
```json
{
  "success": true,
  "job_id": "1",
  "status": "queued"
}
```

**Error codes:**
- 400: Invalid job type or parameters
- 401: Authentication required
- 413: Payload too large

### Get Job Status

```
GET /jobs/:id
```

**Response:** 200 OK
```json
{
  "success": true,
  "job": {
    "id": "1",
    "type": "scene_preload",
    "status": "running",
    "progress": 0.5,
    "created_at": 1699564800,
    "started_at": 1699564801,
    "completed_at": null,
    "result": null,
    "error": null
  }
}
```

**Error codes:**
- 404: Job not found
- 401: Authentication required

### List Jobs

```
GET /jobs?status=queued
```

**Query parameters:**
- `status` (optional): Filter by status (queued, running, completed, failed, cancelled)

**Response:** 200 OK
```json
{
  "success": true,
  "jobs": [
    {
      "id": "1",
      "type": "scene_preload",
      "status": "running",
      "progress": 0.5,
      "created_at": 1699564800
    },
    {
      "id": "2",
      "type": "batch_operations",
      "status": "queued",
      "progress": 0.0,
      "created_at": 1699564850
    }
  ],
  "count": 2
}
```

### Cancel Job

```
DELETE /jobs/:id
```

**Response:** 200 OK
```json
{
  "success": true,
  "message": "Job cancelled"
}
```

**Error codes:**
- 404: Job not found
- 400: Can only cancel queued jobs
- 401: Authentication required

## Job Types

### 1. batch_operations

Execute batch scene operations asynchronously.

**Parameters:**
```json
{
  "operations": [
    {"action": "load", "scene_path": "res://scene1.tscn"},
    {"action": "validate", "scene_path": "res://scene2.tscn"}
  ],
  "mode": "continue"
}
```

**Result:**
```json
{
  "total": 2,
  "message": "Batch operations completed"
}
```

**Use when:**
- Processing >20 operations
- Operations take >5 seconds total
- Non-urgent batch processing

### 2. scene_preload

Preload scenes into cache for faster loading.

**Parameters:**
```json
{
  "scene_paths": [
    "res://vr_main.tscn",
    "res://node_3d.tscn"
  ]
}
```

**Result:**
```json
{
  "scenes_loaded": 2,
  "total_scenes": 2,
  "scenes": [
    {"scene_path": "res://vr_main.tscn", "success": true},
    {"scene_path": "res://node_3d.tscn", "success": true}
  ]
}
```

**Use when:**
- Warming up scene cache
- Preloading levels
- Improving first-load performance

### 3. cache_warming

Warm up internal caches.

**Parameters:**
```json
{}
```

**Result:**
```json
{
  "cache_warmed": true,
  "message": "Cache warming completed"
}
```

**Use when:**
- After application startup
- After cache clear
- Performance optimization

## Job Lifecycle

### Status Flow

```
QUEUED → RUNNING → COMPLETED
              ↓
            FAILED
              ↓
          CANCELLED (only from QUEUED)
```

### Status Descriptions

| Status | Description | Can Cancel? |
|--------|-------------|-------------|
| queued | Waiting in queue | Yes |
| running | Currently executing | No |
| completed | Finished successfully | No |
| failed | Finished with error | No |
| cancelled | Cancelled by user | No |

### Retention Policy

- **Results stored:** 24 hours after completion
- **Auto-cleanup:** Runs every hour
- **Access after cleanup:** Returns 404

## Examples

### Example 1: Preload Multiple Scenes

```python
import requests
import time

API_URL = "http://localhost:8080"
TOKEN = "your_api_token"

headers = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

# Submit job
response = requests.post(
    f"{API_URL}/jobs",
    headers=headers,
    json={
        "type": "scene_preload",
        "parameters": {
            "scene_paths": [
                "res://vr_main.tscn",
                "res://node_3d.tscn",
                "res://test_scene.tscn"
            ]
        }
    }
)

job_id = response.json()["job_id"]
print(f"Job submitted: {job_id}")

# Poll for completion
while True:
    response = requests.get(
        f"{API_URL}/jobs/{job_id}",
        headers=headers
    )

    job = response.json()["job"]
    print(f"Status: {job['status']}, Progress: {job['progress']*100:.0f}%")

    if job["status"] in ["completed", "failed", "cancelled"]:
        break

    time.sleep(1)

# Get result
if job["status"] == "completed":
    print("Result:", job["result"])
else:
    print("Error:", job["error"])
```

### Example 2: Large Batch Operation

```python
# Submit large batch as job instead of direct request
operations = [
    {"action": "validate", "scene_path": f"res://scene{i}.tscn"}
    for i in range(50)
]

response = requests.post(
    f"{API_URL}/jobs",
    headers=headers,
    json={
        "type": "batch_operations",
        "parameters": {
            "operations": operations,
            "mode": "continue"
        }
    }
)

job_id = response.json()["job_id"]
print(f"Batch job submitted: {job_id}")
```

### Example 3: Job Cancellation

```python
# Submit job
response = requests.post(
    f"{API_URL}/jobs",
    headers=headers,
    json={
        "type": "cache_warming",
        "parameters": {}
    }
)

job_id = response.json()["job_id"]

# Cancel immediately
response = requests.delete(
    f"{API_URL}/jobs/{job_id}",
    headers=headers
)

if response.json()["success"]:
    print("Job cancelled successfully")
```

### Example 4: Monitor Multiple Jobs

```python
def monitor_jobs(job_ids):
    while job_ids:
        for job_id in list(job_ids):
            response = requests.get(
                f"{API_URL}/jobs/{job_id}",
                headers=headers
            )

            job = response.json()["job"]
            print(f"Job {job_id}: {job['status']} ({job['progress']*100:.0f}%)")

            if job["status"] in ["completed", "failed", "cancelled"]:
                job_ids.remove(job_id)

        if job_ids:
            time.sleep(1)

# Monitor multiple jobs
job_ids = ["1", "2", "3"]
monitor_jobs(job_ids)
```

### Example 5: Job Status Dashboard

```python
from flask import Flask, render_template
import requests

app = Flask(__name__)

@app.route('/jobs')
def jobs_dashboard():
    response = requests.get(
        f"{API_URL}/jobs",
        headers=headers
    )

    jobs = response.json()["jobs"]
    return render_template('jobs.html', jobs=jobs)

@app.route('/jobs/<job_id>')
def job_detail(job_id):
    response = requests.get(
        f"{API_URL}/jobs/{job_id}",
        headers=headers
    )

    job = response.json()["job"]
    return render_template('job_detail.html', job=job)
```

## Best Practices

### When to Use Job Queue

**Use job queue for:**
- Operations taking >5 seconds
- Batch operations with >20 items
- Background processing
- Non-urgent tasks
- Operations that can fail gracefully

**Use direct API for:**
- Single scene operations
- Urgent operations
- Operations needing immediate feedback
- Small batches (<10 items)

### Polling Best Practices

```python
def poll_job_with_backoff(job_id, max_wait=300):
    """Poll job with exponential backoff"""
    wait_times = [0.5, 1, 2, 5, 10]  # seconds
    wait_index = 0
    elapsed = 0

    while elapsed < max_wait:
        response = requests.get(
            f"{API_URL}/jobs/{job_id}",
            headers=headers
        )

        job = response.json()["job"]

        if job["status"] in ["completed", "failed", "cancelled"]:
            return job

        # Exponential backoff
        wait_time = wait_times[min(wait_index, len(wait_times)-1)]
        time.sleep(wait_time)
        elapsed += wait_time
        wait_index += 1

    raise TimeoutError(f"Job {job_id} did not complete in {max_wait}s")
```

### Error Handling

```python
def submit_job_with_retry(job_data, max_retries=3):
    """Submit job with retry on failure"""
    for attempt in range(max_retries):
        try:
            response = requests.post(
                f"{API_URL}/jobs",
                headers=headers,
                json=job_data,
                timeout=10
            )

            if response.status_code == 202:
                return response.json()["job_id"]

            if response.status_code == 400:
                # Invalid request, don't retry
                raise ValueError(response.json())

        except requests.exceptions.RequestException as e:
            if attempt == max_retries - 1:
                raise
            time.sleep(2 ** attempt)  # Exponential backoff

    raise Exception("Max retries exceeded")
```

### Webhook Integration

Use webhooks to get notified when jobs complete:

```python
# Register webhook for job completion
requests.post(
    f"{API_URL}/webhooks",
    headers=headers,
    json={
        "url": "https://your-server.com/webhook",
        "events": ["scene.loaded", "scene.validated"],
        "secret": "webhook_secret"
    }
)

# Submit job
job_id = submit_job(...)

# Webhook will notify when complete
# No need to poll!
```

### Concurrent Job Management

```python
from concurrent.futures import ThreadPoolExecutor
import queue

def submit_and_monitor_job(job_params):
    """Submit job and monitor to completion"""
    response = requests.post(
        f"{API_URL}/jobs",
        headers=headers,
        json=job_params
    )

    job_id = response.json()["job_id"]

    # Wait for completion
    while True:
        response = requests.get(
            f"{API_URL}/jobs/{job_id}",
            headers=headers
        )

        job = response.json()["job"]

        if job["status"] in ["completed", "failed"]:
            return job

        time.sleep(1)

# Submit multiple jobs concurrently
jobs_params = [
    {"type": "scene_preload", "parameters": {"scene_paths": [f"res://scene{i}.tscn"]}}}
    for i in range(10)
]

with ThreadPoolExecutor(max_workers=5) as executor:
    results = list(executor.map(submit_and_monitor_job, jobs_params))

print(f"Completed {len(results)} jobs")
```

## Performance Considerations

### Job Queue Limits

- **Max concurrent jobs:** 3
- **Max queue size:** Unlimited (but consider memory)
- **Result retention:** 24 hours
- **Cleanup frequency:** Every hour

### Job Sizing

| Job Size | Recommended Type | Expected Duration |
|----------|------------------|-------------------|
| 1-10 operations | Direct API | <1s |
| 10-50 operations | Job Queue | 1-10s |
| 50+ operations | Job Queue | 10s+ |

### Optimization Tips

1. **Batch similar operations** together
2. **Use scene_preload** for cache warming
3. **Poll with backoff** to reduce server load
4. **Cancel unused jobs** to free resources
5. **Use webhooks** instead of polling when possible

## Troubleshooting

### Job Stuck in Queued State

**Cause:** Max concurrent jobs reached (3)

**Solution:** Wait for running jobs to complete, or cancel unnecessary jobs

```bash
# List running jobs
curl http://localhost:8080/jobs?status=running \
  -H "Authorization: Bearer YOUR_TOKEN"

# Cancel if needed
curl -X DELETE http://localhost:8080/jobs/ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Job Results Not Found

**Cause:** Results cleaned up after 24 hours

**Solution:** Poll job status periodically, or store results when received

### Job Failed Without Error

**Cause:** Job execution error

**Solution:** Check job result for error field

```python
job = get_job_status(job_id)
if job["status"] == "failed":
    print(f"Job failed: {job.get('error', 'Unknown error')}")
```

### Cannot Cancel Running Job

**Cause:** Only queued jobs can be cancelled

**Solution:** Wait for job to complete, or design jobs to be cancellable

## Security Notes

- All job operations require authentication
- Job results stored securely for 24 hours
- Jobs cannot access files outside whitelist
- Job parameters validated before execution
- Failed authentication triggers webhook event

## See Also

- [Batch Operations](./BATCH_OPERATIONS.md)
- [Webhooks](./WEBHOOKS.md)
- [HTTP API Reference](./API_REFERENCE.md)
- [Performance Benchmarks](../../tests/http_api/benchmark_performance.py)
