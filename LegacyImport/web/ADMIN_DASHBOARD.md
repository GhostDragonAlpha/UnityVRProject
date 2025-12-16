# SpaceTime Admin Dashboard

**Version:** 2.5
**Last Updated:** 2025-12-02

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Features](#features)
4. [Dashboard Sections](#dashboard-sections)
5. [Admin Token Setup](#admin-token-setup)
6. [API Endpoints](#api-endpoints)
7. [WebSocket Updates](#websocket-updates)
8. [Troubleshooting](#troubleshooting)
9. [Security](#security)
10. [Screenshots](#screenshots)

---

## Overview

The SpaceTime Admin Dashboard is a comprehensive real-time monitoring and management interface for the HTTP API server. Built with Vue.js 3 and modern web technologies, it provides operations teams with powerful tools to monitor system health, manage security, and configure the server.

**Key Features:**
- Real-time metrics and monitoring
- Live request tracking
- Security event logging
- Scene whitelist management
- Webhook configuration
- Job queue monitoring
- System configuration
- Dark/Light mode support
- Responsive design (desktop and tablet)

---

## Quick Start

### 1. Start Godot with HTTP API

```bash
godot --path "C:/godot"
```

The HTTP API server will start on port 8080.

### 2. Get Admin Token

When the server starts, it will print the admin token to the console:

```
[AdminRouter] ADMIN TOKEN: admin_a1b2c3d4e5f6...
[AdminRouter] Use: curl -H 'X-Admin-Token: admin_a1b2c3d4e5f6...' ...
```

**Copy this token** - you'll need it to access the dashboard.

### 3. Open Dashboard

Open `C:/godot/web/admin_dashboard.html` in a modern web browser (Chrome, Firefox, Edge).

Or serve it via HTTP:

```bash
cd C:/godot/web
python -m http.server 8000
# Then open http://localhost:8000/admin_dashboard.html
```

### 4. Enter Admin Token

When prompted, enter the admin token you copied from the console.

---

## Features

### Real-Time Monitoring
- **Live Metrics Updates:** Automatically refreshes every 5 seconds
- **WebSocket Integration:** Real-time event streaming
- **Request Tracking:** View last 100 requests with full details
- **Performance Graphs:** Request rate and latency distribution charts

### Security Management
- **Token Management:** View, generate, and revoke API tokens
- **Security Events:** Track authentication attempts and suspicious activity
- **Audit Log:** Complete log of all administrative actions
- **Rate Limiting:** Monitor rate limit hits by IP address

### Scene Management
- **Whitelist Editor:** Add/remove scenes from whitelist
- **Load Statistics:** Track scene load counts and performance
- **Validation:** Test scene paths before adding to whitelist

### System Configuration
- **Security Settings:** Enable/disable authentication, whitelist, rate limiting
- **Server Settings:** View server configuration
- **Live Updates:** Changes take effect immediately

### Webhook Integration
- **Webhook Registry:** Manage webhook endpoints
- **Event Filtering:** Subscribe to specific events
- **Delivery History:** Track webhook delivery success/failure
- **Test Functionality:** Test webhooks before deployment

### Job Queue
- **Job Monitoring:** View active, pending, and completed jobs
- **Job Control:** Cancel running jobs, retry failed jobs
- **Progress Tracking:** Real-time job progress updates

---

## Dashboard Sections

### 1. Overview Page

**Purpose:** High-level system health and key metrics at a glance

**Features:**
- System health status indicator (green/yellow/red)
- Key metric cards:
  - Requests/second (last minute average)
  - Active connections
  - Success rate (last hour)
  - Average response time (P50 latency)
- Recent alerts (last 10)
- Quick action buttons:
  - Reload configuration
  - Clear cache
  - Restart server

**Screenshot Description:**
```
+-----------------------------------------------------------+
| OVERVIEW                                   [HEALTHY ✓]   |
+-----------------------------------------------------------+
| [Requests/Sec]  [Active Conn]  [Success Rate]  [Latency]|
|     2.45            3            98.5%          45ms     |
+-----------------------------------------------------------+
| Recent Alerts                            [Clear All]     |
| ✓ No alerts - everything running smoothly               |
+-----------------------------------------------------------+
| Quick Actions                                            |
| [🔄 Reload] [🗑️ Clear Cache] [⚠️ Restart Server]        |
+-----------------------------------------------------------+
```

### 2. Real-Time Monitoring Page

**Purpose:** Live system metrics and request logs

**Features:**
- Request rate graph (line chart, last 60 seconds)
- Response time distribution graph (P50, P95, P99)
- Recent requests table (last 100):
  - Timestamp
  - HTTP method
  - Path
  - Status code
  - Response time
- Pause/Resume monitoring
- Manual refresh button

**Screenshot Description:**
```
+-----------------------------------------------------------+
| REAL-TIME MONITORING                    [⏸️ Pause] [🔄]  |
+-----------------------------------------------------------+
| Request Rate                                              |
| [Line graph showing requests over time]                   |
+-----------------------------------------------------------+
| Response Time Distribution                                |
| [Multi-line graph: P50 (green), P95 (orange), P99 (red)] |
+-----------------------------------------------------------+
| Recent Requests (Last 100)                                |
| Time      | Method | Path        | Status | Response      |
| 14:23:45  | POST   | /scene      | 200    | 125ms        |
| 14:23:42  | GET    | /scenes     | 200    | 45ms         |
+-----------------------------------------------------------+
```

### 3. Security Page

**Purpose:** Authentication, tokens, and security monitoring

**Features:**
- Active tokens table:
  - Token type (API/Admin)
  - Token preview (first 8 characters)
  - Created timestamp
  - Revoke button
- Generate new token button
- Recent security events table:
  - Timestamp
  - Event description
  - IP address
  - Affected path
- Audit log with filters:
  - Action type
  - User
  - Details (JSON)
- Export audit log button

**Screenshot Description:**
```
+-----------------------------------------------------------+
| SECURITY                           [🔑 Generate Token]   |
+-----------------------------------------------------------+
| Active Tokens                                             |
| Type   | Preview     | Created           | Actions       |
| API    | a1b2c3d4... | 2025-12-02 14:00  | [Revoke]     |
| ADMIN  | admin_e5... | 2025-12-02 14:00  | [Revoke]     |
+-----------------------------------------------------------+
| Recent Security Events                                    |
| Timestamp        | Event                    | IP          |
| 2025-12-02 14:20 | Failed auth attempt      | 127.0.0.1  |
+-----------------------------------------------------------+
| Audit Log                                  [📥 Export]   |
| Timestamp        | Action          | User  | Details     |
| 2025-12-02 14:15 | whitelist_add   | admin | {...}       |
+-----------------------------------------------------------+
```

### 4. Scenes Page

**Purpose:** Scene whitelist and load statistics

**Features:**
- Scene whitelist manager:
  - Current whitelist table
  - Add scene form (with validation)
  - Remove scene button
- Scene load statistics:
  - Scene path
  - Total load count
  - Success count
  - Failure count
  - Average load time

**Screenshot Description:**
```
+-----------------------------------------------------------+
| SCENE MANAGEMENT                                          |
+-----------------------------------------------------------+
| Scene Whitelist                                           |
| Add Scene: [res://path/to/scene.tscn ___________] [Add]  |
|                                                           |
| Scene Path                        | Actions               |
| res://vr_main.tscn               | [Remove]              |
| res://node_3d.tscn               | [Remove]              |
+-----------------------------------------------------------+
| Scene Load Statistics                                     |
| Path              | Loads | Success | Fail | Avg Time    |
| res://vr_main.tscn|  342  |   340   |  2   | 125ms       |
| res://node_3d.tscn|  156  |   156   |  0   | 89ms        |
+-----------------------------------------------------------+
```

### 5. Webhooks Page

**Purpose:** Manage webhook integrations

**Features:**
- Registered webhooks table:
  - URL
  - Subscribed events
  - Created timestamp
  - Test button
  - Delete button
- Add webhook modal:
  - URL input
  - Events input (comma-separated)
- Webhook delivery history

**Screenshot Description:**
```
+-----------------------------------------------------------+
| WEBHOOKS                                  [+ Add Webhook]|
+-----------------------------------------------------------+
| Registered Webhooks                                       |
| URL                      | Events        | Created        |
| https://example.com/hook | scene.load... | 2025-12-02    |
|                          | [Test] [Delete]               |
+-----------------------------------------------------------+
```

### 6. Jobs Page

**Purpose:** Background job monitoring and control

**Features:**
- Job statistics cards:
  - Active jobs count
  - Pending jobs count
  - Completed today count
  - Failed jobs count
- All jobs table:
  - Job ID
  - Type
  - Status (running/pending/completed/failed)
  - Progress percentage
  - Created timestamp
  - Actions (Cancel/Retry)

**Screenshot Description:**
```
+-----------------------------------------------------------+
| JOB QUEUE                                                 |
+-----------------------------------------------------------+
| [Active: 2]  [Pending: 5]  [Completed: 47]  [Failed: 0] |
+-----------------------------------------------------------+
| All Jobs                                                  |
| Job ID | Type         | Status    | Progress | Actions    |
| #1234  | scene_load   | running   | 75%      | [Cancel]   |
| #1235  | cache_clear  | pending   | 0%       | -          |
| #1233  | export       | failed    | 100%     | [Retry]    |
+-----------------------------------------------------------+
```

### 7. Configuration Page

**Purpose:** Server and security settings

**Features:**
- Security settings:
  - ☑ Enable Authentication
  - ☑ Enable Scene Whitelist
  - ☑ Enable Request Size Limits
  - Bind Address (read-only)
  - Max Request Size (read-only)
- Server settings (informational)
- Save changes button
- Restart required notice

**Screenshot Description:**
```
+-----------------------------------------------------------+
| CONFIGURATION                           [💾 Save Changes]|
+-----------------------------------------------------------+
| Security Settings                                         |
| ☑ Enable Authentication                                  |
| ☑ Enable Scene Whitelist                                |
| ☑ Enable Request Size Limits                            |
|                                                           |
| Bind Address: 127.0.0.1 (read-only)                      |
| Max Request Size: 1048576 bytes (read-only)              |
+-----------------------------------------------------------+
| ℹ️ Restart Required                                      |
| Changes to server settings require a server restart      |
+-----------------------------------------------------------+
```

### 8. Logs Page

**Purpose:** System logs and event history

**Features:**
- Log filters:
  - Log level dropdown (All/Info/Warning/Error/Debug)
  - Search input
  - Search button
- Log entries table:
  - Timestamp
  - Level (color-coded badge)
  - Message
- Export logs button
- Clear logs button

**Screenshot Description:**
```
+-----------------------------------------------------------+
| SYSTEM LOGS                      [📥 Export] [🗑️ Clear]  |
+-----------------------------------------------------------+
| Filter: [All Levels ▼]  Search: [____________] [🔍]      |
+-----------------------------------------------------------+
| Log Entries                                               |
| Timestamp        | Level   | Message                      |
| 2025-12-02 14:30 | INFO    | Server started               |
| 2025-12-02 14:29 | WARNING | High memory usage            |
| 2025-12-02 14:28 | ERROR   | Failed to load scene         |
+-----------------------------------------------------------+
```

---

## Admin Token Setup

### Token Generation

Admin tokens are automatically generated when the server starts. The token is printed to the console:

```
[AdminRouter] ADMIN TOKEN: admin_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
[AdminRouter] Use: curl -H 'X-Admin-Token: admin_...' ...
```

### Using the Token

**In the Dashboard:**
1. Open `admin_dashboard.html`
2. Enter the token when prompted
3. Token is stored in browser session (not persisted)

**Via API:**
```bash
curl -H 'X-Admin-Token: admin_...' http://127.0.0.1:8080/admin/metrics
```

### Token Security

- Admin token is **separate** from API token
- Admin token grants full administrative access
- Token is regenerated on server restart
- Keep token secure - do not share or commit to version control
- Token is required for all `/admin/*` endpoints

### Revoking Tokens

To revoke and regenerate a token:

1. Go to Security page in dashboard
2. Find the token in Active Tokens table
3. Click **Revoke** button
4. New token will be generated immediately
5. Old token becomes invalid instantly

---

## API Endpoints

All admin endpoints require the `X-Admin-Token` header.

### Metrics

**GET /admin/metrics**

Returns current system metrics.

**Response:**
```json
{
  "uptime_ms": 3600000,
  "uptime_seconds": 3600,
  "requests": {
    "total": 1234,
    "success": 1200,
    "errors": 34,
    "success_rate": 97.2
  },
  "performance": {
    "requests_per_second": 2.45,
    "avg_response_time_ms": 45.3,
    "p50_response_time_ms": 42.0,
    "p95_response_time_ms": 89.5,
    "p99_response_time_ms": 156.2
  },
  "connections": {
    "active": 3
  },
  "timestamp": 1733155200
}
```

### Health

**GET /admin/health**

Returns detailed health status.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": 1733155200,
  "components": {
    "http_server": {"status": "up"},
    "security": {"status": "up", "auth_enabled": true},
    "scene_manager": {"status": "up"}
  },
  "metrics": {
    "error_rate": 2.8,
    "uptime_seconds": 3600
  }
}
```

### Logs

**GET /admin/logs**

Returns system logs with optional filtering.

**Query Parameters:**
- `level` (optional): Filter by log level (info, warning, error, debug)
- `search` (optional): Search term
- `limit` (optional): Maximum entries to return (default: 100)

**Response:**
```json
{
  "logs": [
    {
      "timestamp": 1733155200,
      "level": "info",
      "message": "Server started"
    }
  ]
}
```

### Configuration

**GET /admin/config**

Returns current configuration.

**POST /admin/config**

Updates configuration.

**Request Body:**
```json
{
  "auth_enabled": true,
  "whitelist_enabled": true
}
```

### Cache

**POST /admin/cache/clear**

Clears all internal caches.

### Security

**GET /admin/security/events**

Returns recent security events.

**GET /admin/security/tokens**

Returns active tokens.

**POST /admin/security/revoke**

Revokes and regenerates a token.

**Request Body:**
```json
{
  "token_type": "api"
}
```

### Audit Log

**GET /admin/audit**

Returns audit log entries.

**Query Parameters:**
- `limit` (optional): Maximum entries (default: 100)

### Scenes

**GET /admin/scenes/whitelist**

Returns scene whitelist.

**POST /admin/scenes/whitelist**

Adds scene to whitelist.

**Request Body:**
```json
{
  "scene_path": "res://path/to/scene.tscn"
}
```

**GET /admin/scenes/stats**

Returns scene load statistics.

### Webhooks

**GET /admin/webhooks**

Returns registered webhooks.

**POST /admin/webhooks**

Registers a new webhook.

**Request Body:**
```json
{
  "url": "https://example.com/webhook",
  "events": ["scene.load", "scene.reload"]
}
```

### Jobs

**GET /admin/jobs**

Returns job queue status.

### Connections

**GET /admin/connections**

Returns active connections.

### Restart

**POST /admin/restart**

Initiates server restart (not yet implemented).

---

## WebSocket Updates

### Connection

Connect to: `ws://127.0.0.1:8083/admin/ws`

**Note:** WebSocket server runs on port 8083 (different from HTTP API port 8080)

### Message Types

**Metrics Update:**
```json
{
  "type": "metrics_update",
  "data": { /* metrics object */ },
  "timestamp": 1733155200
}
```

**Alert:**
```json
{
  "type": "alert",
  "data": {
    "severity": "warning",
    "message": "High memory usage",
    "details": {}
  },
  "timestamp": 1733155200
}
```

**Request Event:**
```json
{
  "type": "request",
  "data": {
    "method": "POST",
    "path": "/scene",
    "status": 200,
    "response_time": 125
  },
  "timestamp": 1733155200
}
```

**Job Update:**
```json
{
  "type": "job_update",
  "data": {
    "id": 1234,
    "type": "scene_load",
    "status": "completed",
    "progress": 100
  },
  "timestamp": 1733155200
}
```

**Security Event:**
```json
{
  "type": "security_event",
  "data": {
    "event": "Failed authentication",
    "ip": "127.0.0.1",
    "path": "/admin/metrics"
  },
  "timestamp": 1733155200
}
```

### Client Messages

**Ping:**
```json
{
  "type": "ping"
}
```

**Subscribe:**
```json
{
  "type": "subscribe",
  "channels": ["metrics", "alerts", "requests"]
}
```

**Request Metrics:**
```json
{
  "type": "request_metrics"
}
```

---

## Troubleshooting

### Dashboard Won't Load

**Issue:** Dashboard HTML file doesn't open or shows errors

**Solutions:**
1. Ensure you're using a modern browser (Chrome, Firefox, Edge)
2. Check browser console for JavaScript errors (F12)
3. Try serving via HTTP instead of opening file directly:
   ```bash
   cd C:/godot/web
   python -m http.server 8000
   ```

### Can't Connect to API

**Issue:** Dashboard shows "Disconnected" or API calls fail

**Solutions:**
1. Verify Godot server is running
2. Check HTTP API is on port 8080:
   ```bash
   curl http://127.0.0.1:8080/admin/health
   ```
3. Check firewall settings
4. Verify admin token is correct
5. Check browser console for CORS errors

### Invalid Admin Token

**Issue:** All API calls return 401 Unauthorized

**Solutions:**
1. Copy admin token from Godot console output
2. Ensure no extra spaces in token
3. Token is regenerated on server restart - get new token
4. Check you're using `X-Admin-Token` header (not `Authorization`)

### WebSocket Won't Connect

**Issue:** Real-time updates not working, WebSocket shows disconnected

**Solutions:**
1. Verify WebSocket server is running (port 8083)
2. Check browser console for WebSocket errors
3. Ensure firewall allows WebSocket connections
4. Try refreshing page to reconnect
5. Check Godot console for WebSocket errors

### Metrics Not Updating

**Issue:** Dashboard shows old data or zeros

**Solutions:**
1. Click manual refresh button
2. Check "Pause" isn't enabled
3. Verify WebSocket connection is active
4. Make some API requests to generate metrics
5. Check admin token hasn't expired

### Charts Not Showing

**Issue:** Monitoring page charts are blank

**Solutions:**
1. Check Chart.js library loaded (browser console)
2. Navigate away and back to monitoring page
3. Ensure canvas elements are present in HTML
4. Check browser supports HTML5 canvas
5. Try different browser

---

## Security

### Best Practices

1. **Keep Admin Token Secret**
   - Never commit token to version control
   - Don't share token in plain text
   - Rotate token regularly

2. **Network Security**
   - Only bind to localhost (127.0.0.1) in production
   - Use reverse proxy with TLS for remote access
   - Implement IP whitelist if exposing remotely

3. **Browser Security**
   - Use HTTPS when serving dashboard remotely
   - Implement CSP headers
   - Clear browser session when done

4. **Access Control**
   - Limit admin access to operations team only
   - Use separate tokens for different admin users (future feature)
   - Monitor audit log for suspicious activity

### Security Features

- **Token-Based Authentication:** All admin endpoints require valid token
- **Separate Admin Token:** Admin token is different from API token
- **Audit Logging:** All admin actions logged with timestamp and user
- **Security Event Tracking:** Failed auth attempts logged and displayed
- **CORS Protection:** API bound to localhost by default
- **Input Validation:** All inputs validated server-side

---

## Screenshots

### Overview Page
```
Compact dashboard view showing:
- 4 metric cards in grid layout
- Health status badge (green)
- Recent alerts section (empty state)
- Quick action buttons
```

### Monitoring Page
```
Real-time monitoring with:
- Request rate line chart (60-second window)
- Latency distribution multi-line chart (P50/P95/P99)
- Recent requests table (scrollable)
- Pause and refresh controls
```

### Security Page
```
Security management showing:
- Active tokens table with revoke buttons
- Security events list
- Audit log with JSON details
- Export functionality
```

### Scenes Page
```
Scene management with:
- Add scene form with input validation
- Whitelist table with remove buttons
- Statistics table with load metrics
```

### Configuration Page
```
Settings panel with:
- Checkbox toggles for security features
- Read-only server settings
- Save button with confirmation
- Restart required notice
```

---

## Support

For issues or questions:

1. Check troubleshooting section above
2. Review Godot console output for errors
3. Check browser console (F12) for JavaScript errors
4. Verify API endpoints with curl
5. Consult API documentation in `C:/godot/web/API_MONITORING.md`

---

**Document Version:** 1.0
**Compatible with:** SpaceTime v2.5+
**Last Updated:** December 2, 2025
