# Godot Scene Manager Web Dashboard

A single-page web application for managing Godot scenes via the HTTP API.

## Features

- **Real-time Scene Monitoring**: Auto-refreshes current scene every 3 seconds
- **Scene Loading**: Click to load any available scene via HTTP API
- **Visual Status Indicators**: Connection status, current scene highlighting
- **Modern UI**: Responsive design with smooth animations and professional styling
- **Toast Notifications**: Success/error messages for user feedback
- **Loading States**: Loading spinner during scene transitions

## Quick Start

### 1. Ensure Godot is Running with Debug Services

The dashboard requires Godot to be running with the HTTP API enabled:

```bash
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

Or use the quick restart script on Windows:

```bash
./restart_godot_with_debug.bat
```

**IMPORTANT**: The HTTP API runs on port 8080 (with automatic fallback to 8083-8085).

### 2. Serve the Dashboard

Due to CORS (Cross-Origin Resource Sharing) restrictions, you need to serve the HTML file via HTTP rather than opening it directly as a file.

#### Option A: Python HTTP Server (Recommended)

```bash
cd C:/godot/web
python -m http.server 8000
```

Then open your browser to: **http://localhost:8000/scene_manager.html**

#### Option B: Python 2.x (if available)

```bash
cd C:/godot/web
python -m SimpleHTTPServer 8000
```

#### Option C: Node.js http-server

```bash
npm install -g http-server
cd C:/godot/web
http-server -p 8000
```

#### Option D: PHP

```bash
cd C:/godot/web
php -S localhost:8000
```

### 3. Open in Browser

Navigate to: **http://localhost:8000/scene_manager.html**

## Using the Dashboard

### Current Scene Section

- **Scene Name**: Displays the currently loaded scene's name
- **Scene Path**: Shows the full res:// path
- **Connection Status**: Green indicator when connected to Godot API
- **Refresh Button**: Manually refresh current scene info
- **Auto-refresh**: Updates every 3 seconds automatically

### Available Scenes Table

- **Name**: Human-readable scene name
- **Path**: Full Godot resource path (res://...)
- **Category**: Scene category (Main, Celestial, Player, Spacecraft, UI, Test)
- **Actions**: Load button (disabled for current scene)

The currently loaded scene is highlighted in green with a "CURRENT" badge.

### Loading a Scene

1. Find the scene you want to load in the table
2. Click the "Load" button
3. Loading spinner appears
4. Toast notification confirms success/failure
5. Current scene info refreshes automatically

## API Endpoints Used

The dashboard communicates with these HTTP API endpoints:

- `GET http://127.0.0.1:8080/status` - Check API connection
- `GET http://127.0.0.1:8080/state/game` - Get current scene name
- `POST http://127.0.0.1:8080/scene/load` - Load a new scene

Example scene load request:

```json
POST http://127.0.0.1:8080/scene/load
Content-Type: application/json

{
  "scene_path": "res://vr_main.tscn"
}
```

## CORS Considerations

### Why Serve via HTTP?

Modern browsers block cross-origin requests when opening HTML files directly (file:// protocol). By serving the dashboard via HTTP (localhost:8000), it can make requests to the Godot API (localhost:8080).

### Alternative: Disable CORS in Browser (Not Recommended)

For development only, you can disable CORS:

**Chrome**:
```bash
chrome.exe --disable-web-security --user-data-dir="C:/temp/chrome-dev"
```

**Firefox**:
- Type `about:config` in address bar
- Search for `security.fileuri.strict_origin_policy`
- Set to `false`

**WARNING**: This reduces security. Only use for local development.

## Troubleshooting

### "Connection Failed" Error

1. Verify Godot is running with debug services:
   ```bash
   curl http://127.0.0.1:8080/status
   ```

2. Check if port 8080 is accessible:
   ```bash
   netstat -an | findstr 8080
   ```

3. Ensure Godot is in GUI mode (not headless)

4. Try alternative ports (8083-8085) if 8080 is in use

### Scene Won't Load

1. Check browser console (F12) for errors
2. Verify scene path is correct (must start with res://)
3. Ensure scene file exists in Godot project
4. Check Godot console for error messages

### Auto-refresh Not Working

1. Open browser developer tools (F12)
2. Check Console tab for JavaScript errors
3. Verify network requests are succeeding in Network tab

### Styling Issues

1. Clear browser cache (Ctrl+Shift+Delete)
2. Hard refresh page (Ctrl+F5)
3. Try different browser (Chrome, Firefox, Edge)

## Customization

### Add More Scenes

Edit the `AVAILABLE_SCENES` array in the JavaScript section:

```javascript
const AVAILABLE_SCENES = [
    {
        name: 'Your Scene Name',
        path: 'res://path/to/your/scene.tscn',
        category: 'YourCategory'
    },
    // ... more scenes
];
```

### Change Auto-refresh Interval

Modify the interval in the `init()` function (currently 3000ms = 3 seconds):

```javascript
autoRefreshInterval = setInterval(refreshCurrentScene, 5000); // 5 seconds
```

### Change API Base URL

If using a different port, update the constant:

```javascript
const API_BASE_URL = 'http://127.0.0.1:8083'; // Changed from 8080
```

### Color Scheme

Modify CSS variables in the `<style>` section:

- Primary accent: `#00d4ff` (cyan)
- Success color: `#00ff88` (green)
- Error color: `#ff4444` (red)
- Background: `#1e1e2e` to `#2d2d44` (dark gradient)

## Technical Details

### Stack

- **Frontend**: Vanilla JavaScript (no frameworks)
- **HTTP Client**: Fetch API
- **Styling**: CSS3 with gradients, animations, flexbox, grid
- **Server**: Any static file server (Python, Node.js, PHP)

### Browser Compatibility

- Chrome 60+
- Firefox 55+
- Edge 79+
- Safari 12+

### Performance

- Lightweight: Single HTML file, no dependencies
- Auto-refresh: Minimal network overhead (200 bytes/request)
- Responsive: Works on desktop and mobile devices

## Future Enhancements

Potential improvements:

1. **Scene Search/Filter**: Filter scenes by category or name
2. **Scene Thumbnails**: Preview images for each scene
3. **Recent Scenes**: Track recently loaded scenes
4. **Favorites**: Star/favorite frequently used scenes
5. **Scene Details**: Show scene node count, file size, etc.
6. **Batch Operations**: Load multiple scenes in sequence
7. **Scene Comparison**: Compare two scenes side-by-side
8. **Export Functionality**: Export scene list as JSON/CSV

## Related Documentation

- HTTP API Documentation: `C:/godot/addons/godot_debug_connection/HTTP_API.md`
- Telemetry Guide: `C:/godot/TELEMETRY_GUIDE.md`
- Development Workflow: `C:/godot/DEVELOPMENT_WORKFLOW.md`
- CLAUDE.md: `C:/godot/CLAUDE.md`

## License

Part of the SpaceTime VR project. See main project LICENSE for details.
