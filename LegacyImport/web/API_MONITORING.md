# API Monitoring Dashboard Documentation

## Overview

The API Monitoring Dashboard (`api_monitor.html`) provides real-time visibility into the Godot HTTP API performance, health status, and request patterns. It's designed for development, testing, and production monitoring of the GodotBridge HTTP server.

## Quick Start

### Accessing the Dashboard

1. **Start the Godot editor with debug services:**
   ```bash
   godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
   ```

2. **Open the dashboard in your browser:**
   - Navigate to: `http://127.0.0.1:8080/api_monitor.html`
   - Or open `C:/godot/web/api_monitor.html` directly in a browser

3. **The dashboard will automatically:**
   - Connect to the API on `http://127.0.0.1:8080`
   - Start polling for status updates every 2 seconds
   - Track all API requests and responses
   - Display real-time metrics and charts

### Using the Quick Restart Script (Windows)

```bash
cd C:/godot
./restart_godot_with_debug.bat
```

This automatically kills existing Godot processes and restarts with proper debug flags.

## Dashboard Features

### 1. Real-time Metrics

#### API Health Status
- **Green (Healthy)**: All services connected, API responding normally
- **Yellow (Degraded)**: API responding but some services disconnected
- **Red (Offline)**: Cannot connect to API
- **Uptime**: Time since dashboard started monitoring

#### Requests Per Second
- Live counter showing current request rate
- Updates every second
- Useful for load testing and performance analysis

#### Response Time
- **Average (5min)**: Rolling average of last 50 requests
- **Latest**: Response time of most recent request
- Measured in milliseconds from request start to response received

#### Current Scene
- Displays the currently loaded scene in Godot
- Updates when scenes change via `/scene/load` endpoint
- Shows "None" if no scene is loaded

### 2. Service Status

Shows connection status for all services:
- **HTTP API**: Green if dashboard can connect
- **DAP (Debug Adapter Protocol)**: Connection state from `/status` endpoint
- **LSP (Language Server Protocol)**: Connection state from `/status` endpoint

**Connection States:**
- **Connected** (Green): Service fully operational
- **Connecting** (Yellow): Service attempting to connect
- **Disconnected** (Red): Service not available

**Controls:**
- **Connect Services**: Sends POST request to `/connect` to initialize DAP/LSP
- **Refresh Status**: Manually refresh all status information
- **Clear Logs**: Clear the request log display
- **Auto-refresh Toggle**: Enable/disable automatic polling (ON by default)

### 3. Endpoint Statistics Table

Comprehensive statistics for each API endpoint called:

| Column | Description |
|--------|-------------|
| **Endpoint** | Full path of the API endpoint |
| **Requests** | Total number of requests made |
| **Success Rate** | Percentage of successful responses (2xx status) |
| **Avg Response** | Average response time in milliseconds |
| **Last Called** | Timestamp of most recent request |

**Sorting:** Endpoints automatically sorted by request count (most used first)

**Use Cases:**
- Identify most-used endpoints
- Spot slow endpoints (high avg response time)
- Monitor success rates for reliability
- Track endpoint usage patterns

### 4. Response Time History Chart

Interactive line chart showing response time trends:
- **X-axis**: Timestamp of each request
- **Y-axis**: Response time in milliseconds
- **Data points**: Last 50 requests
- **Auto-updating**: New requests added in real-time

**What to look for:**
- **Consistent low times**: Healthy API performance
- **Gradual increase**: Potential memory leak or resource exhaustion
- **Spikes**: Heavy operations or network issues
- **Patterns**: Request timing patterns in your application

### 5. Live Request Log

Scrolling log of all API requests with color-coding:

**Color Coding:**
- **Green**: Successful request (HTTP 2xx)
- **Yellow**: Client error (HTTP 4xx) or warning
- **Red**: Server error (HTTP 5xx) or network failure
- **Blue**: Informational messages

**Log Entry Format:**
```
[HH:MM:SS] METHOD /endpoint → STATUS_CODE (DURATION_ms) [Error details if any]
```

**Example:**
```
[14:32:15] GET /status → 200 (23ms)
[14:32:10] POST /connect → 200 (156ms)
[14:32:05] POST /scene/load → 200 (45ms)
```

**Features:**
- Automatically limited to last 50 entries (configurable in code)
- Newest entries appear at top
- Auto-scrolls to show latest activity
- Includes error messages for failed requests

## Metrics to Watch

### Critical Metrics

#### 1. API Health Status
**Normal:** Green indicator, "Healthy" status
**Action Required:**
- **Yellow**: Check which service is disconnected, run `/connect` endpoint
- **Red**: Verify Godot is running with `--lsp-port 6005 --dap-port 6006`

#### 2. Response Time
**Thresholds:**
- **< 50ms**: Excellent - Local API performance
- **50-200ms**: Good - Normal operation
- **200-500ms**: Warning - May indicate load or complexity
- **> 500ms**: Critical - Investigate slow endpoints

**Actions:**
- Check endpoint statistics table for slowest endpoints
- Review code for blocking operations
- Consider optimizing database queries or complex calculations

#### 3. Success Rate
**Thresholds:**
- **95-100%**: Healthy
- **90-95%**: Monitor closely
- **< 90%**: Critical - Investigate errors

**Common Causes:**
- Invalid request parameters (400 errors)
- Service not connected (503 errors)
- Scene files not found (404 errors)
- Server errors (500 errors)

#### 4. Requests Per Second
**Normal Ranges:**
- **Development**: 0.5-2 req/sec (status polling + manual testing)
- **Automated Testing**: 10-50 req/sec
- **Load Testing**: 100+ req/sec

**Warning Signs:**
- Sudden drop to 0: Application hung or crashed
- Unexpected spikes: Potential infinite loop or bug
- Gradual increase: Memory leak or resource accumulation

### Performance Indicators

#### Response Time Trends
Monitor the chart for:
1. **Baseline drift**: Gradually increasing baseline (memory leak)
2. **Periodic spikes**: GC pauses or scheduled tasks
3. **Step changes**: New feature deployment or configuration change
4. **Variance**: High variance indicates inconsistent performance

#### Endpoint Usage Patterns
Review statistics table for:
1. **Hot endpoints**: Most frequently called
2. **Slow endpoints**: Highest average response time
3. **Failed endpoints**: Low success rate
4. **Unused endpoints**: Never called (consider deprecation)

## Alert Thresholds

### Recommended Alert Configuration

If integrating with external monitoring (see Integration section):

| Metric | Warning | Critical |
|--------|---------|----------|
| API Health | Yellow (Degraded) | Red (Offline) |
| Avg Response Time | > 200ms | > 500ms |
| Success Rate | < 95% | < 90% |
| Requests/sec | < 0.1 (stalled) | 0 (frozen) |
| Endpoint Response | > 300ms | > 1000ms |

### Alert Actions

**API Offline:**
1. Check if Godot process is running
2. Verify ports 8080-8085 not blocked
3. Check firewall/antivirus settings
4. Restart Godot with debug flags

**High Response Times:**
1. Check endpoint statistics for slow operations
2. Review recent code changes
3. Monitor system resources (CPU, memory)
4. Consider profiling slow endpoints

**Low Success Rate:**
1. Review request log for error patterns
2. Check server logs in Godot output
3. Verify all required services connected
4. Test endpoints individually with curl

**Stalled Requests:**
1. Check for deadlocks in Godot scripts
2. Verify no infinite loops in request handlers
3. Review recent changes to autoload scripts
4. Restart Godot if necessary

## Integration with External Monitoring

### Prometheus Integration

The dashboard can be extended to expose metrics in Prometheus format. Add a new endpoint to `godot_bridge.gd`:

```gdscript
func _handle_metrics_endpoint(client: StreamPeerTCP) -> void:
    var metrics = PackedStringArray()

    # API health
    metrics.append("api_health{service=\"http\"} 1")

    # Response time
    var avg_response = _calculate_average_response_time()
    metrics.append("api_response_time_ms %d" % avg_response)

    # Request rate
    var req_rate = _calculate_request_rate()
    metrics.append("api_requests_per_second %f" % req_rate)

    # Per-endpoint metrics
    for endpoint in endpoint_stats:
        var stats = endpoint_stats[endpoint]
        metrics.append("api_endpoint_requests_total{endpoint=\"%s\"} %d" % [endpoint, stats.count])
        metrics.append("api_endpoint_response_time_ms{endpoint=\"%s\"} %d" % [endpoint, stats.avg_time])

    _send_response(client, 200, "text/plain", "\n".join(metrics))
```

**Prometheus scrape config:**
```yaml
scrape_configs:
  - job_name: 'godot_api'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    scrape_interval: 5s
```

### Grafana Dashboard

Create a Grafana dashboard with panels for:
1. **API Uptime**: `up{job="godot_api"}`
2. **Response Time**: `api_response_time_ms`
3. **Request Rate**: `rate(api_requests_per_second[5m])`
4. **Error Rate**: `rate(api_errors_total[5m])`
5. **Endpoint Latency**: `api_endpoint_response_time_ms` (by endpoint)

### Custom Monitoring Scripts

**Python monitoring script example:**
```python
import requests
import time
import json
from datetime import datetime

class APIMonitor:
    def __init__(self, base_url="http://127.0.0.1:8080"):
        self.base_url = base_url
        self.alerts = []

    def check_health(self):
        try:
            response = requests.get(f"{self.base_url}/status", timeout=5)
            data = response.json()

            if not data.get('overall_ready'):
                self.alert("API Degraded", "Not all services ready")

            return response.elapsed.total_seconds() * 1000
        except Exception as e:
            self.alert("API Offline", str(e))
            return None

    def alert(self, title, message):
        alert = {
            'timestamp': datetime.now().isoformat(),
            'title': title,
            'message': message
        }
        self.alerts.append(alert)
        print(f"ALERT: {title} - {message}")

        # Send to monitoring system
        # self.send_to_slack(alert)
        # self.send_to_pagerduty(alert)

    def monitor_loop(self, interval=30):
        while True:
            response_time = self.check_health()

            if response_time and response_time > 500:
                self.alert("Slow Response", f"{response_time}ms")

            time.sleep(interval)

if __name__ == "__main__":
    monitor = APIMonitor()
    monitor.monitor_loop(interval=30)
```

### Slack Integration

Send alerts to Slack when thresholds are exceeded:

```python
import requests

def send_slack_alert(webhook_url, title, message, severity="warning"):
    color = {
        "info": "#36a64f",
        "warning": "#ff9800",
        "error": "#f44336"
    }.get(severity, "#808080")

    payload = {
        "attachments": [{
            "color": color,
            "title": title,
            "text": message,
            "ts": time.time()
        }]
    }

    requests.post(webhook_url, json=payload)

# Usage
send_slack_alert(
    "https://hooks.slack.com/services/YOUR/WEBHOOK/URL",
    "API Response Time Critical",
    "Average response time exceeded 500ms (current: 732ms)",
    severity="error"
)
```

### Email Alerts

Send email notifications for critical issues:

```python
import smtplib
from email.mime.text import MIMEText

def send_email_alert(to_email, subject, body):
    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = 'monitor@yourcompany.com'
    msg['To'] = to_email

    server = smtplib.SMTP('smtp.gmail.com', 587)
    server.starttls()
    server.login('your-email@gmail.com', 'your-app-password')
    server.send_message(msg)
    server.quit()

# Usage
send_email_alert(
    'devops@yourcompany.com',
    'Godot API Offline',
    'The Godot API has been offline for 5 minutes. Please investigate.'
)
```

## Troubleshooting

### Dashboard Not Loading

**Symptom:** Browser shows "Cannot connect" or "ERR_CONNECTION_REFUSED"

**Solutions:**
1. Verify Godot is running: `tasklist | grep -i godot` (Windows) or `ps aux | grep godot` (Linux)
2. Check API is accessible: `curl http://127.0.0.1:8080/status`
3. Try alternate ports: The API falls back to 8083-8085 if 8080 is busy
4. Check firewall: Ensure localhost connections allowed
5. Open directly: Navigate to `file:///C:/godot/web/api_monitor.html`

### No Data Appearing

**Symptom:** Dashboard loads but shows "No data yet" or "Checking..."

**Solutions:**
1. Check browser console (F12) for JavaScript errors
2. Verify CORS is not blocking requests (should be fine for localhost)
3. Make a test request: `curl http://127.0.0.1:8080/status` in terminal
4. Click "Refresh Status" button manually
5. Check if auto-refresh is enabled (should show "Auto-refresh: ON")

### Incorrect Metrics

**Symptom:** Metrics seem wrong or outdated

**Solutions:**
1. Click "Refresh Status" to force update
2. Clear browser cache (Ctrl+Shift+Delete)
3. Hard reload page (Ctrl+F5)
4. Check system time is correct
5. Restart dashboard (close and reopen)

### High Response Times

**Symptom:** All requests showing > 500ms response time

**Solutions:**
1. Check system resources (Task Manager / top)
2. Restart Godot to clear memory
3. Verify no background processes consuming CPU
4. Check if Godot is in headless mode (needs GUI)
5. Review recent code changes for blocking operations

### Services Not Connecting

**Symptom:** DAP/LSP show "Disconnected" even after clicking "Connect Services"

**Solutions:**
1. Verify Godot started with debug flags: `--lsp-port 6005 --dap-port 6006`
2. Check ports are not in use: `netstat -an | grep 600[56]`
3. Wait 10-15 seconds after clicking connect
4. Check Godot output for connection errors
5. Restart Godot with debug flags

### Chart Not Updating

**Symptom:** Response time chart frozen or not showing new data

**Solutions:**
1. Make some API requests to generate data
2. Check browser console for Chart.js errors
3. Verify at least one request has been made
4. Refresh the page
5. Try a different browser

## Advanced Usage

### Custom Monitoring Script

Create a script that makes periodic requests and monitors specific endpoints:

```python
import requests
import time
from datetime import datetime

BASE_URL = "http://127.0.0.1:8080"

def monitor_specific_endpoints():
    endpoints = [
        ("/status", "GET"),
        ("/scene/load", "POST", {"scene_path": "res://vr_main.tscn"}),
        ("/debug/evaluate", "POST", {"expression": "Engine.get_version_info()", "context": "watch"}),
    ]

    while True:
        print(f"\n[{datetime.now()}] Checking endpoints...")

        for endpoint_data in endpoints:
            endpoint = endpoint_data[0]
            method = endpoint_data[1]
            body = endpoint_data[2] if len(endpoint_data) > 2 else None

            try:
                start = time.time()
                if method == "GET":
                    response = requests.get(f"{BASE_URL}{endpoint}")
                else:
                    response = requests.post(f"{BASE_URL}{endpoint}", json=body)

                duration = (time.time() - start) * 1000

                print(f"  {method} {endpoint}: {response.status_code} ({duration:.0f}ms)")

                if duration > 500:
                    print(f"    WARNING: Slow response!")

                if response.status_code >= 400:
                    print(f"    ERROR: {response.json()}")

            except Exception as e:
                print(f"  {method} {endpoint}: FAILED - {e}")

        time.sleep(30)  # Check every 30 seconds

if __name__ == "__main__":
    monitor_specific_endpoints()
```

### Load Testing

Use the dashboard while running load tests to monitor API behavior:

```python
import requests
import concurrent.futures
import time

def stress_test_api(duration_seconds=60, concurrent_requests=10):
    base_url = "http://127.0.0.1:8080"
    end_time = time.time() + duration_seconds

    def make_request():
        try:
            requests.get(f"{base_url}/status", timeout=5)
            return True
        except:
            return False

    total_requests = 0
    successful_requests = 0

    with concurrent.futures.ThreadPoolExecutor(max_workers=concurrent_requests) as executor:
        while time.time() < end_time:
            futures = [executor.submit(make_request) for _ in range(concurrent_requests)]

            for future in concurrent.futures.as_completed(futures):
                total_requests += 1
                if future.result():
                    successful_requests += 1

            time.sleep(0.1)  # Brief pause between batches

    print(f"\nLoad Test Results:")
    print(f"  Total Requests: {total_requests}")
    print(f"  Successful: {successful_requests}")
    print(f"  Success Rate: {(successful_requests/total_requests)*100:.1f}%")
    print(f"  Avg Rate: {total_requests/duration_seconds:.1f} req/sec")

# Run load test while watching dashboard
stress_test_api(duration_seconds=60, concurrent_requests=5)
```

### Keyboard Shortcuts

The dashboard supports keyboard shortcuts for quick actions:

| Shortcut | Action |
|----------|--------|
| **Ctrl+R** | Refresh status |
| **Ctrl+Shift+C** | Connect services |

## Best Practices

### 1. Always Monitor During Development
Keep the dashboard open in a browser tab during active development to catch issues immediately.

### 2. Check Before Committing
Review the endpoint statistics and error rate before committing code changes.

### 3. Baseline Performance
Take screenshots of normal metrics to compare against when investigating issues.

### 4. Log Analysis
Regularly review the request log for unusual patterns or errors.

### 5. Response Time Trends
Watch for gradual increases in response time that might indicate memory leaks.

### 6. Success Rate
Investigate any endpoint with < 95% success rate.

### 7. Load Testing
Run load tests while monitoring the dashboard to identify bottlenecks.

### 8. Incident Response
Use the dashboard as first step when investigating API issues.

## Related Documentation

- [HTTP_API.md](C:/godot/addons/godot_debug_connection/HTTP_API.md) - Complete HTTP REST API reference
- [DAP_COMMANDS.md](C:/godot/addons/godot_debug_connection/DAP_COMMANDS.md) - Debug Adapter Protocol commands
- [LSP_METHODS.md](C:/godot/addons/godot_debug_connection/LSP_METHODS.md) - Language Server Protocol methods
- [TELEMETRY_GUIDE.md](C:/godot/TELEMETRY_GUIDE.md) - WebSocket telemetry streaming
- [CLAUDE.md](C:/godot/CLAUDE.md) - Project overview and development workflow

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the request log for error details
3. Check Godot console output for server-side errors
4. Verify all services connected via `/status` endpoint
5. Test endpoints individually with curl or Postman
