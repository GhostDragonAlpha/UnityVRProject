# Godot Web Dashboards

Two web-based dashboards for managing and monitoring Godot via the HTTP API.

## Quick Start

### 1. Start Godot with Debug Services

```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

Or use the quick restart script on Windows:
```bash
cd C:/godot
./restart_godot_with_debug.bat
```

### 2. Serve the Dashboards

```bash
cd C:/godot/web
python -m http.server 8000
```

### 3. Access the Dashboards

- **Scene Manager**: http://localhost:8000/scene_manager.html
- **API Monitor**: http://localhost:8000/api_monitor.html

---

## Dashboard 1: Scene Manager

**File**: `scene_manager.html`

### Purpose
Manage and load Godot scenes through a visual interface.

### Features
- Real-time scene monitoring (auto-refresh every 3 seconds)
- Click-to-load any available scene
- Visual status indicators
- Current scene highlighting
- Toast notifications
- Loading states and animations

### Use Cases
- Quick scene switching during development
- Testing different scenes
- Visual scene management
- Scene catalog browsing

### API Endpoints Used
- `GET /status` - Connection check
- `GET /state/game` - Current scene info
- `POST /scene/load` - Load new scene

---

## Dashboard 2: API Monitor

**File**: `api_monitor.html`
**Documentation**: `API_MONITORING.md`

### Purpose
Real-time performance monitoring and analytics for the HTTP API.

### Features

#### 1. Real-time Metrics
- **Requests/second**: Live counter of API request rate
- **Response time**: Average and latest response times
- **API health**: Green/yellow/red status indicator
- **Uptime**: Dashboard monitoring duration
- **Current scene**: Currently loaded scene name

#### 2. Service Status
- HTTP API connection status
- DAP (Debug Adapter Protocol) state
- LSP (Language Server Protocol) state
- Quick connect/refresh controls

#### 3. Endpoint Statistics Table
Tracks for each endpoint:
- Total request count
- Success rate percentage
- Average response time
- Last request timestamp

#### 4. Response Time Chart
- Interactive line chart (Chart.js)
- Last 50 requests
- Real-time updates
- Performance trend visualization

#### 5. Live Request Log
- Color-coded by status (green/yellow/red)
- Timestamp + method + endpoint + duration
- Automatic scrolling
- Last 50 entries visible

### Use Cases
- Development monitoring
- Performance analysis
- Load testing observation
- Debugging API issues
- Production health checks
- Integration testing

### Metrics to Watch

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Response Time | < 50ms | 50-200ms | > 500ms |
| Success Rate | 95-100% | 90-95% | < 90% |
| API Health | Green | Yellow | Red |

### Keyboard Shortcuts
- **Ctrl+R**: Refresh status
- **Ctrl+Shift+C**: Connect services

---

## Common Setup

### Serving Options

#### Python 3.x (Recommended)
```bash
cd C:/godot/web
python -m http.server 8000
```

#### Python 2.x
```bash
cd C:/godot/web
python -m SimpleHTTPServer 8000
```

#### Node.js
```bash
npm install -g http-server
cd C:/godot/web
http-server -p 8000
```

#### PHP
```bash
cd C:/godot/web
php -S localhost:8000
```

### Why Serve via HTTP?

Modern browsers block cross-origin requests when opening HTML files directly (file:// protocol). By serving via HTTP (localhost:8000), dashboards can make requests to the Godot API (localhost:8080).

---

## Troubleshooting

### "Connection Failed" Error

1. **Verify Godot is running:**
   ```bash
   curl http://127.0.0.1:8080/status
   ```

2. **Check port accessibility:**
   ```bash
   netstat -an | findstr 8080
   ```

3. **Ensure GUI mode** (not headless)

4. **Try alternate ports** (8083-8085 if 8080 busy)

### Dashboard Not Loading

1. Check browser console (F12) for errors
2. Verify you're serving via HTTP (not file://)
3. Clear browser cache (Ctrl+Shift+Delete)
4. Try hard refresh (Ctrl+F5)
5. Test with different browser

### No Data Appearing

1. Verify Godot is running with debug services
2. Check CORS is not blocking requests
3. Make a test request: `curl http://127.0.0.1:8080/status`
4. Click manual refresh button
5. Check auto-refresh is enabled

### Services Not Connecting

1. Verify Godot debug flags: `--lsp-port 6005 --dap-port 6006`
2. Check ports not in use: `netstat -an | grep 600[56]`
3. Wait 10-15 seconds after clicking connect
4. Check Godot output for errors
5. Restart Godot with proper flags

---

## Integration Examples

### Monitoring Script

```python
import requests
import time

BASE_URL = "http://127.0.0.1:8080"

while True:
    try:
        response = requests.get(f"{BASE_URL}/status", timeout=5)
        data = response.json()

        print(f"API Health: {'OK' if data.get('overall_ready') else 'DEGRADED'}")
        print(f"Response Time: {response.elapsed.total_seconds()*1000:.0f}ms")

        if response.elapsed.total_seconds() > 0.5:
            print("WARNING: Slow response!")

    except Exception as e:
        print(f"ERROR: {e}")

    time.sleep(30)
```

### Load Testing

```python
import requests
import concurrent.futures

def make_request():
    try:
        requests.get("http://127.0.0.1:8080/status", timeout=5)
        return True
    except:
        return False

# Run 100 concurrent requests
with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
    results = list(executor.map(lambda _: make_request(), range(100)))

success_rate = sum(results) / len(results) * 100
print(f"Success Rate: {success_rate:.1f}%")
```

### Automated Monitoring

```python
import requests
import json
from datetime import datetime

def log_metrics():
    metrics = {
        'timestamp': datetime.now().isoformat(),
        'status': None,
        'response_time_ms': None,
        'error': None
    }

    try:
        start = time.time()
        response = requests.get("http://127.0.0.1:8080/status", timeout=5)
        metrics['response_time_ms'] = (time.time() - start) * 1000
        metrics['status'] = 'healthy' if response.json().get('overall_ready') else 'degraded'
    except Exception as e:
        metrics['status'] = 'offline'
        metrics['error'] = str(e)

    # Append to log file
    with open('api_metrics.jsonl', 'a') as f:
        f.write(json.dumps(metrics) + '\n')

# Run every minute
import schedule
schedule.every(1).minutes.do(log_metrics)
while True:
    schedule.run_pending()
    time.sleep(1)
```

---

## Technical Details

### Technologies Used

**Scene Manager:**
- Vanilla JavaScript (no frameworks)
- Fetch API for HTTP requests
- CSS3 animations and gradients
- Responsive design

**API Monitor:**
- Vanilla JavaScript
- Chart.js 4.4.0 for visualization
- Fetch API for HTTP requests
- Real-time data processing
- CSS3 with backdrop filters

### Browser Compatibility

Both dashboards support:
- Chrome 60+
- Firefox 55+
- Edge 79+
- Safari 12+

### Performance

**Scene Manager:**
- Lightweight: Single HTML file
- Auto-refresh: 200 bytes/request every 3s
- Minimal CPU usage

**API Monitor:**
- Chart rendering: 60 FPS animations disabled for performance
- Request tracking: Last 100 requests stored
- Chart data: Last 50 data points
- Log display: Last 50 entries visible
- Memory efficient: Auto-cleanup of old data

---

## API Endpoint Reference

### Status Check
```bash
GET http://127.0.0.1:8080/status

Response:
{
  "debug_adapter": { "state": 2, "port": 6006, ... },
  "language_server": { "state": 2, "port": 6005, ... },
  "overall_ready": true
}
```

### Scene Load
```bash
POST http://127.0.0.1:8080/scene/load
Content-Type: application/json

{
  "scene_path": "res://vr_main.tscn"
}

Response:
{
  "status": "loading",
  "scene": "res://vr_main.tscn",
  "message": "Scene load initiated successfully"
}
```

### Connect Services
```bash
POST http://127.0.0.1:8080/connect

Response:
{
  "status": "connecting",
  "message": "Connection initiated"
}
```

---

## Related Documentation

- **API Monitor Guide**: `C:/godot/web/API_MONITORING.md` (comprehensive monitoring documentation)
- **Scene Manager Guide**: `C:/godot/web/README.md` (original scene manager docs)
- **HTTP API Reference**: `C:/godot/addons/godot_debug_connection/HTTP_API.md`
- **Telemetry Guide**: `C:/godot/TELEMETRY_GUIDE.md`
- **Development Workflow**: `C:/godot/DEVELOPMENT_WORKFLOW.md`
- **Project Overview**: `C:/godot/CLAUDE.md`

---

## Future Enhancements

### Scene Manager
- Scene search/filter
- Scene thumbnails
- Recent scenes history
- Favorites/bookmarks
- Scene details (nodes, file size)
- Batch operations

### API Monitor
- Prometheus metrics export
- Grafana dashboard integration
- Alert configuration UI
- Historical data storage
- Performance profiling
- Endpoint comparison
- Export metrics as CSV/JSON
- Custom alert thresholds
- Email/Slack notifications

---

## License

Part of the SpaceTime VR project. See main project LICENSE for details.
