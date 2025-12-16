# Video Tutorial Script - HTTP Scene Management API

## Series Overview

**Series Title:** "Mastering Godot Scene Management via HTTP API"

**Target Audience:** Game developers, DevOps engineers, automation enthusiasts

**Total Runtime:** ~35 minutes (4 tutorials)

**Skill Level:** Intermediate (basic Godot and HTTP knowledge required)

---

## Tutorial 1: "HTTP Scene Management API - Quick Start"

**Duration:** 5 minutes

**Learning Objectives:**
- Understand what the HTTP Scene Management API is
- Start Godot with debug services enabled
- Execute basic scene management commands via curl
- Verify scene transitions in real-time

**Prerequisites:**
- Godot 4.5+ installed
- Basic command line knowledge
- curl or similar HTTP client
- SpaceTime project cloned

### Script with Timestamps

#### 0:00-0:30 - Introduction
**Voiceover:**
"Welcome to the HTTP Scene Management API Quick Start. In this tutorial, you'll learn how to control Godot scenes remotely using simple HTTP requests. This powerful feature enables automation, testing, and external tool integration for your Godot projects."

**On Screen:**
- Title card: "HTTP Scene Management API - Quick Start"
- Show SpaceTime project logo
- Display key benefits:
  - Remote scene control
  - Automation ready
  - Testing friendly
  - CI/CD integration

#### 0:30-1:30 - Starting Godot with Debug Services
**Voiceover:**
"First, we need to start Godot with debug services enabled. The HTTP API runs on port 8080, alongside the Debug Adapter Protocol on 6006 and Language Server Protocol on 6005. On Windows, we've provided a convenient restart script."

**On Screen:**
- Show terminal window
- Display command: `godot --path "C:/godot" --dap-port 6006 --lsp-port 6005`
- Highlight the three ports with annotations
- Show Godot editor opening
- Alternative: Run `restart_godot_with_debug.bat`

**Commands to Run:**
```bash
# Windows Quick Start
cd C:\godot
.\restart_godot_with_debug.bat

# OR Manual Start (all platforms)
godot --path "C:/godot" --dap-port 6006 --lsp-port 6005
```

**Expected Output:**
```
Searching for Godot executable...
Found Godot at: C:\Program Files\Godot\godot.exe
Killing existing Godot processes...
Starting Godot with debug services...
[Godot Editor Opens]
```

#### 1:30-2:15 - Verifying Connection
**Voiceover:**
"Let's verify that the HTTP API is running and ready. We'll use the status endpoint to check all services."

**On Screen:**
- Split screen: Terminal + Godot Editor
- Show curl command with syntax highlighting
- Display JSON response with pretty formatting
- Highlight `overall_ready: true` field

**Commands to Run:**
```bash
curl http://127.0.0.1:8080/status
```

**Expected Output:**
```json
{
  "status": "ready",
  "overall_ready": true,
  "services": {
    "godot_bridge": true,
    "telemetry_server": true,
    "dap_adapter": true,
    "lsp_adapter": true
  },
  "timestamp": "2025-12-02T10:30:45Z"
}
```

#### 2:15-3:00 - Loading Your First Scene
**Voiceover:**
"Now for the exciting part - loading a scene remotely. We'll use the scene load endpoint with the path to our VR main scene. Watch the Godot editor as the scene loads instantly."

**On Screen:**
- Terminal command with JSON payload
- Godot editor showing scene tree changing
- Highlight the loaded scene in the tree
- Show 3D viewport updating

**Commands to Run:**
```bash
curl -X POST http://127.0.0.1:8080/scene/load \
  -H "Content-Type: application/json" \
  -d "{\"scene_path\": \"res://vr_main.tscn\"}"
```

**Expected Output:**
```json
{
  "success": true,
  "scene_path": "res://vr_main.tscn",
  "load_time_ms": 145.7,
  "node_count": 23,
  "root_node": "VRMain"
}
```

#### 3:00-3:45 - Querying Scene Information
**Voiceover:**
"You can query detailed information about the current scene, including its hierarchy, node types, and properties. This is incredibly useful for automated testing and validation."

**On Screen:**
- Show curl command
- Display JSON tree structure
- Animate expansion of nested nodes
- Highlight interesting properties (XROrigin3D, controllers)

**Commands to Run:**
```bash
curl http://127.0.0.1:8080/scene/info
```

**Expected Output:**
```json
{
  "current_scene": "res://vr_main.tscn",
  "root_node": "VRMain",
  "node_count": 23,
  "scene_tree": {
    "VRMain": {
      "type": "Node3D",
      "children": {
        "XROrigin3D": {
          "type": "XROrigin3D",
          "children": {
            "XRCamera3D": {"type": "XRCamera3D"},
            "LeftController": {"type": "XRController3D"},
            "RightController": {"type": "XRController3D"}
          }
        }
      }
    }
  }
}
```

#### 3:45-4:30 - Reloading the Scene
**Voiceover:**
"During development, you'll often need to reload scenes to test changes. The reload endpoint preserves the current scene path and reinitializes everything cleanly. This is perfect for rapid iteration."

**On Screen:**
- Show reload command
- Godot editor briefly flashing as scene reloads
- Terminal showing response
- Highlight load_time_ms metric

**Commands to Run:**
```bash
curl -X POST http://127.0.0.1:8080/scene/reload
```

**Expected Output:**
```json
{
  "success": true,
  "scene_path": "res://vr_main.tscn",
  "reload_time_ms": 132.4,
  "node_count": 23
}
```

#### 4:30-5:00 - Wrap Up
**Voiceover:**
"Congratulations! You've learned the basics of the HTTP Scene Management API. You can now load, query, and reload scenes remotely. In the next tutorial, we'll build a complete Python client to automate scene management. Don't forget to check the resources in the description below."

**On Screen:**
- Summary slide:
  - ✓ Started Godot with debug services
  - ✓ Verified API connection
  - ✓ Loaded scenes via HTTP
  - ✓ Queried scene information
- "Next: Building a Scene Controller with Python"
- Resource links:
  - HTTP_API.md documentation
  - GitHub repository
  - Discord community

**Common Pitfalls to Highlight:**
- ⚠️ Godot must run in GUI mode, not headless
- ⚠️ Wait 5-10 seconds after Godot starts before API calls
- ⚠️ Use `res://` protocol for all scene paths
- ⚠️ Check firewall isn't blocking ports 6005, 6006, 8080

---

## Tutorial 2: "Building a Scene Controller with Python"

**Duration:** 10 minutes

**Learning Objectives:**
- Create a reusable Python client for scene management
- Implement proper error handling and retry logic
- Build a command-line tool for scene operations
- Understand API best practices

**Prerequisites:**
- Python 3.8+ installed
- Tutorial 1 completed
- Basic Python knowledge
- requests library (`pip install requests`)

### Script with Timestamps

#### 0:00-0:30 - Introduction
**Voiceover:**
"Welcome back! In this tutorial, we'll build a professional Python client for the Scene Management API. You'll learn proper error handling, retry logic, and how to create a command-line tool that you can use in your development workflow."

**On Screen:**
- Title card: "Building a Scene Controller with Python"
- Show final tool in action (teaser)
- Learning objectives list

#### 0:30-2:00 - Project Setup
**Voiceover:**
"Let's start by setting up our Python environment. We'll create a dedicated directory, set up a virtual environment, and install the requests library. This keeps our dependencies isolated and reproducible."

**On Screen:**
- Terminal showing commands
- File explorer showing directory structure
- requirements.txt file creation

**Commands to Run:**
```bash
cd C:\godot\examples
mkdir scene_controller
cd scene_controller
python -m venv .venv
.venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Linux/Mac
pip install requests
```

**Expected Output:**
```
Successfully installed requests-2.31.0 urllib3-2.0.7 ...
```

**Create requirements.txt:**
```
requests>=2.31.0
typing-extensions>=4.5.0
```

#### 2:00-4:00 - Building the SceneManager Class (Part 1)
**Voiceover:**
"Now we'll create our SceneManager class. This class will handle all communication with the API, including connection validation, error handling, and retry logic. Notice how we use a circuit breaker pattern to avoid hammering a failed service."

**On Screen:**
- VS Code or preferred editor
- Live coding session
- Highlight key sections:
  - Class initialization
  - Base URL configuration
  - Timeout settings

**Code to Show:**
```python
# scene_manager.py
import requests
import time
from typing import Optional, Dict, Any
from dataclasses import dataclass

@dataclass
class SceneInfo:
    """Scene information data class"""
    scene_path: str
    root_node: str
    node_count: int
    scene_tree: Dict[str, Any]

class SceneManager:
    """Client for Godot Scene Management HTTP API"""

    def __init__(self, base_url: str = "http://127.0.0.1:8080",
                 timeout: int = 10):
        """
        Initialize Scene Manager

        Args:
            base_url: Base URL for HTTP API (default: http://127.0.0.1:8080)
            timeout: Request timeout in seconds (default: 10)
        """
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self.session = requests.Session()
        self.circuit_breaker_fails = 0
        self.circuit_breaker_threshold = 3

    def _is_circuit_open(self) -> bool:
        """Check if circuit breaker is open (too many failures)"""
        return self.circuit_breaker_fails >= self.circuit_breaker_threshold

    def _reset_circuit(self):
        """Reset circuit breaker on successful call"""
        self.circuit_breaker_fails = 0

    def _increment_circuit(self):
        """Increment circuit breaker failure count"""
        self.circuit_breaker_fails += 1
```

#### 4:00-6:00 - Building the SceneManager Class (Part 2)
**Voiceover:**
"Let's add the core methods: checking status, loading scenes, and querying information. Each method includes comprehensive error handling and returns clean data structures."

**On Screen:**
- Continue live coding
- Show method signatures
- Highlight error handling blocks

**Code to Show:**
```python
    def check_status(self) -> Dict[str, Any]:
        """Check if API is ready"""
        if self._is_circuit_open():
            raise RuntimeError("Circuit breaker open - too many failures")

        try:
            response = self.session.get(
                f"{self.base_url}/status",
                timeout=self.timeout
            )
            response.raise_for_status()
            data = response.json()
            self._reset_circuit()
            return data
        except requests.RequestException as e:
            self._increment_circuit()
            raise RuntimeError(f"Status check failed: {e}")

    def wait_until_ready(self, max_wait: int = 30,
                        check_interval: float = 1.0) -> bool:
        """
        Wait for API to become ready

        Args:
            max_wait: Maximum wait time in seconds
            check_interval: Time between checks in seconds

        Returns:
            True if ready, False if timeout
        """
        start_time = time.time()
        while time.time() - start_time < max_wait:
            try:
                status = self.check_status()
                if status.get("overall_ready", False):
                    return True
            except:
                pass
            time.sleep(check_interval)
        return False

    def load_scene(self, scene_path: str) -> Dict[str, Any]:
        """
        Load a scene by path

        Args:
            scene_path: Scene path (e.g., "res://vr_main.tscn")

        Returns:
            Scene load response with metrics
        """
        if self._is_circuit_open():
            raise RuntimeError("Circuit breaker open - too many failures")

        try:
            response = self.session.post(
                f"{self.base_url}/scene/load",
                json={"scene_path": scene_path},
                timeout=self.timeout
            )
            response.raise_for_status()
            data = response.json()
            self._reset_circuit()
            return data
        except requests.RequestException as e:
            self._increment_circuit()
            raise RuntimeError(f"Scene load failed: {e}")

    def get_scene_info(self) -> SceneInfo:
        """
        Get current scene information

        Returns:
            SceneInfo object with scene details
        """
        if self._is_circuit_open():
            raise RuntimeError("Circuit breaker open - too many failures")

        try:
            response = self.session.get(
                f"{self.base_url}/scene/info",
                timeout=self.timeout
            )
            response.raise_for_status()
            data = response.json()
            self._reset_circuit()

            return SceneInfo(
                scene_path=data["current_scene"],
                root_node=data["root_node"],
                node_count=data["node_count"],
                scene_tree=data["scene_tree"]
            )
        except requests.RequestException as e:
            self._increment_circuit()
            raise RuntimeError(f"Scene info query failed: {e}")

    def reload_scene(self) -> Dict[str, Any]:
        """
        Reload current scene

        Returns:
            Scene reload response with metrics
        """
        if self._is_circuit_open():
            raise RuntimeError("Circuit breaker open - too many failures")

        try:
            response = self.session.post(
                f"{self.base_url}/scene/reload",
                timeout=self.timeout
            )
            response.raise_for_status()
            data = response.json()
            self._reset_circuit()
            return data
        except requests.RequestException as e:
            self._increment_circuit()
            raise RuntimeError(f"Scene reload failed: {e}")
```

#### 6:00-8:00 - Creating the CLI Tool
**Voiceover:**
"Now let's wrap our SceneManager in a command-line interface. We'll use argparse to create a professional CLI tool with subcommands for each operation. This makes it easy to integrate into scripts and CI/CD pipelines."

**On Screen:**
- Create new file: cli.py
- Show argparse configuration
- Highlight subcommand structure

**Code to Show:**
```python
# cli.py
import argparse
import sys
import json
from scene_manager import SceneManager

def cmd_status(args):
    """Handle status command"""
    manager = SceneManager(base_url=args.url)
    try:
        status = manager.check_status()
        print(json.dumps(status, indent=2))
        return 0 if status.get("overall_ready") else 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

def cmd_load(args):
    """Handle load command"""
    manager = SceneManager(base_url=args.url)
    try:
        if args.wait:
            print("Waiting for API to be ready...")
            if not manager.wait_until_ready():
                print("Error: API did not become ready", file=sys.stderr)
                return 1

        result = manager.load_scene(args.scene_path)
        print(f"✓ Loaded: {result['scene_path']}")
        print(f"  Load time: {result['load_time_ms']:.1f}ms")
        print(f"  Node count: {result['node_count']}")
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

def cmd_info(args):
    """Handle info command"""
    manager = SceneManager(base_url=args.url)
    try:
        info = manager.get_scene_info()
        if args.json:
            print(json.dumps({
                "scene_path": info.scene_path,
                "root_node": info.root_node,
                "node_count": info.node_count,
                "scene_tree": info.scene_tree
            }, indent=2))
        else:
            print(f"Current Scene: {info.scene_path}")
            print(f"Root Node: {info.root_node}")
            print(f"Node Count: {info.node_count}")
            if args.tree:
                print("\nScene Tree:")
                print(json.dumps(info.scene_tree, indent=2))
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

def cmd_reload(args):
    """Handle reload command"""
    manager = SceneManager(base_url=args.url)
    try:
        result = manager.reload_scene()
        print(f"✓ Reloaded: {result['scene_path']}")
        print(f"  Reload time: {result['reload_time_ms']:.1f}ms")
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

def main():
    parser = argparse.ArgumentParser(
        description="Godot Scene Management CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--url",
        default="http://127.0.0.1:8080",
        help="API base URL (default: http://127.0.0.1:8080)"
    )

    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Status command
    parser_status = subparsers.add_parser("status", help="Check API status")
    parser_status.set_defaults(func=cmd_status)

    # Load command
    parser_load = subparsers.add_parser("load", help="Load a scene")
    parser_load.add_argument("scene_path", help="Scene path (e.g., res://vr_main.tscn)")
    parser_load.add_argument("--wait", action="store_true", help="Wait for API to be ready")
    parser_load.set_defaults(func=cmd_load)

    # Info command
    parser_info = subparsers.add_parser("info", help="Get scene information")
    parser_info.add_argument("--json", action="store_true", help="Output as JSON")
    parser_info.add_argument("--tree", action="store_true", help="Show scene tree")
    parser_info.set_defaults(func=cmd_info)

    # Reload command
    parser_reload = subparsers.add_parser("reload", help="Reload current scene")
    parser_reload.set_defaults(func=cmd_reload)

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    return args.func(args)

if __name__ == "__main__":
    sys.exit(main())
```

#### 8:00-9:30 - Testing the CLI Tool
**Voiceover:**
"Let's test our new CLI tool! We'll run each command and see how clean the output is. Notice the friendly formatting and helpful error messages. This is production-ready code you can use immediately."

**On Screen:**
- Terminal showing CLI commands
- Split screen: Terminal + Godot
- Show successful operations
- Demonstrate error handling with bad scene path

**Commands to Run:**
```bash
# Check status
python cli.py status

# Load a scene with wait
python cli.py --wait load res://vr_main.tscn

# Get scene info
python cli.py info

# Get scene info with tree
python cli.py info --tree

# Get scene info as JSON
python cli.py info --json

# Reload scene
python cli.py reload

# Test error handling
python cli.py load res://nonexistent.tscn
```

**Expected Output:**
```
# Status
{
  "status": "ready",
  "overall_ready": true,
  ...
}

# Load
Waiting for API to be ready...
✓ Loaded: res://vr_main.tscn
  Load time: 145.7ms
  Node count: 23

# Info
Current Scene: res://vr_main.tscn
Root Node: VRMain
Node Count: 23

# Reload
✓ Reloaded: res://vr_main.tscn
  Reload time: 132.4ms

# Error
Error: Scene load failed: 404 Client Error: Not Found
```

#### 9:30-10:00 - Wrap Up
**Voiceover:**
"Excellent work! You've built a professional Scene Management client with error handling, retry logic, and a clean CLI interface. This tool is ready for automation, testing, and integration into your development workflow. In the next tutorial, we'll explore the web dashboard for visual scene management."

**On Screen:**
- Summary slide:
  - ✓ Created reusable SceneManager class
  - ✓ Implemented error handling & circuit breaker
  - ✓ Built CLI tool with argparse
  - ✓ Tested all operations
- "Next: Web Dashboard Deep Dive"
- Code repository link

**Common Pitfalls to Highlight:**
- ⚠️ Always use circuit breaker pattern for production
- ⚠️ Include timeout parameters to prevent hanging
- ⚠️ Validate scene paths before making API calls
- ⚠️ Handle network errors gracefully
- ⚠️ Use dataclasses for clean API responses

---

## Tutorial 3: "Web Dashboard Deep Dive"

**Duration:** 8 minutes

**Learning Objectives:**
- Navigate the scene_manager.html dashboard
- Load and reload scenes visually
- Validate scenes with automated checks
- Track scene history and metrics
- Understand dashboard architecture

**Prerequisites:**
- Tutorial 1 completed
- Modern web browser (Chrome, Firefox, Edge)
- Godot running with debug services
- Basic HTML/JavaScript knowledge (optional)

### Script with Timestamps

#### 0:00-0:30 - Introduction
**Voiceover:**
"Welcome to the Web Dashboard Deep Dive! The Scene Manager dashboard provides a visual interface for all scene operations, complete with real-time validation, history tracking, and performance metrics. It's perfect for non-technical team members or quick manual testing."

**On Screen:**
- Title card: "Web Dashboard Deep Dive"
- Preview of dashboard interface
- Key features list

#### 0:30-1:30 - Opening the Dashboard
**Voiceover:**
"The dashboard is a single HTML file that runs entirely in your browser - no web server needed. Let's open it and explore the interface. The dashboard automatically attempts to connect to the API on localhost port 8080."

**On Screen:**
- File explorer showing scene_manager.html location
- Double-click to open in browser
- Show dashboard loading
- Highlight connection status indicator

**Steps:**
1. Navigate to `C:\godot\examples\`
2. Double-click `scene_manager.html`
3. Dashboard opens in default browser
4. Connection status shows green "Connected"

#### 1:30-3:00 - Dashboard Layout Tour
**Voiceover:**
"The dashboard is divided into four main sections. At the top, we have the connection status and settings. The main section contains scene controls. Below that is the validation panel with automated checks. And at the bottom, we have the history panel showing all your recent operations."

**On Screen:**
- Animate highlighting of each section:
  1. Top bar (connection status, API URL, settings)
  2. Scene Controls (load, reload, info buttons)
  3. Validation Panel (checks list, run button)
  4. History Panel (operation log with timestamps)

**Dashboard Sections:**
```
┌─────────────────────────────────────────────┐
│ Connection Status: ● Connected | API URL    │
├─────────────────────────────────────────────┤
│ Scene Controls                              │
│ [Scene Path Input] [Load] [Reload] [Info]  │
│ Current: res://vr_main.tscn                 │
├─────────────────────────────────────────────┤
│ Validation                                  │
│ ☑ Scene has root node                      │
│ ☑ Required nodes present                   │
│ ☑ VR components configured                 │
│ [Run Validation]                            │
├─────────────────────────────────────────────┤
│ History                                     │
│ 14:23:45 - Loaded res://vr_main.tscn       │
│ 14:22:10 - Reloaded scene                  │
│ [Clear History]                             │
└─────────────────────────────────────────────┘
```

#### 3:00-4:30 - Loading Scenes with the Dashboard
**Voiceover:**
"Let's load a scene using the dashboard. Type or select a scene path, then click Load. Watch the real-time feedback as the scene loads, including timing metrics and node counts. The operation is automatically logged to history."

**On Screen:**
- Type scene path: `res://vr_main.tscn`
- Click Load button
- Show loading spinner
- Display success message with metrics
- Highlight history entry added
- Show Godot editor scene changing in background

**Demo Actions:**
1. Clear scene path input
2. Type: `res://vr_main.tscn`
3. Click "Load Scene" button
4. Success notification appears: "Scene loaded in 145.7ms (23 nodes)"
5. History shows: "14:25:33 - Loaded res://vr_main.tscn (145.7ms)"

#### 4:30-5:30 - Scene Info and Tree Visualization
**Voiceover:**
"The Scene Info button retrieves complete information about the current scene. The dashboard displays this as an expandable tree view, making it easy to explore the scene hierarchy and verify that all required nodes are present."

**On Screen:**
- Click "Scene Info" button
- Modal popup appears with scene tree
- Animate expanding tree nodes
- Highlight node types and properties
- Show depth of nesting (XROrigin3D → XRCamera3D)

**Tree Visualization:**
```
VRMain (Node3D)
├─ XROrigin3D (XROrigin3D)
│  ├─ XRCamera3D (XRCamera3D)
│  ├─ LeftController (XRController3D)
│  │  └─ MeshInstance3D (MeshInstance3D)
│  └─ RightController (XRController3D)
│     └─ MeshInstance3D (MeshInstance3D)
├─ DirectionalLight3D (DirectionalLight3D)
├─ WorldEnvironment (WorldEnvironment)
└─ ResonanceSystem (Node)
```

#### 5:30-6:45 - Validation System
**Voiceover:**
"The validation system runs automated checks against the loaded scene. These checks verify that required nodes exist, VR components are properly configured, and the scene structure matches expectations. You can customize these checks for your specific project needs."

**On Screen:**
- Show validation panel
- Click "Run Validation" button
- Animate checks running (progress indicator)
- Show results with checkmarks and X marks
- Highlight any failures in red

**Validation Checks:**
```
✓ Scene has root node
✓ Root node is Node3D type
✓ XROrigin3D node present
✓ XRCamera3D node present
✓ Left controller present
✓ Right controller present
✓ VR comfort system configured
✗ Player spawn point defined (OPTIONAL)
✓ Scene tree depth < 10 levels
✓ No circular node references
```

**Demo Actions:**
1. Click "Run Validation"
2. Progress bar fills
3. Results appear with timing: "Validation complete (8/9 checks passed in 234ms)"
4. Expand failed check to see details

#### 6:45-7:30 - History and Metrics
**Voiceover:**
"Every operation is logged to the history panel with timestamps and performance metrics. This is invaluable for tracking down issues and understanding scene load times. You can export the history as JSON for further analysis or clear it to start fresh."

**On Screen:**
- Scroll through history panel
- Highlight different operation types (Load, Reload, Info)
- Show timing metrics for each
- Click "Export History" to download JSON
- Click "Clear History" and confirm

**History Panel:**
```
Recent Operations (showing 10 of 47)

14:30:15 - Validation run (8/9 passed, 234ms)
14:29:42 - Scene info retrieved (23 nodes)
14:28:05 - Reloaded res://vr_main.tscn (132.4ms)
14:26:30 - Loaded res://vr_main.tscn (145.7ms)
14:25:10 - Connection established
14:23:55 - Status check (overall_ready: true)

[Export History] [Clear History]
```

#### 7:30-8:00 - Wrap Up
**Voiceover:**
"The web dashboard provides a user-friendly interface for scene management without requiring command-line knowledge. It's perfect for designers, QA testers, and anyone who needs quick visual feedback. In the next tutorial, we'll integrate scene management into CI/CD pipelines for automated testing."

**On Screen:**
- Summary slide:
  - ✓ Explored dashboard interface
  - ✓ Loaded and validated scenes
  - ✓ Viewed scene hierarchy
  - ✓ Tracked operations in history
- "Next: Advanced Integration - CI/CD & Testing"
- Dashboard customization guide link

**Common Pitfalls to Highlight:**
- ⚠️ Dashboard requires browser with JavaScript enabled
- ⚠️ CORS may block API calls if served from file://
- ⚠️ Use localhost, not 127.0.0.1, for best compatibility
- ⚠️ Clear browser cache if dashboard doesn't update
- ⚠️ Check browser console for connection errors

---

## Tutorial 4: "Advanced Integration: CI/CD & Testing"

**Duration:** 12 minutes

**Learning Objectives:**
- Set up automated scene testing in CI/CD
- Configure GitHub Actions workflow
- Implement performance monitoring
- Create deployment validation pipeline
- Handle production scenarios

**Prerequisites:**
- Tutorials 1-3 completed
- Git and GitHub account
- Basic CI/CD knowledge
- pytest installed (`pip install pytest`)
- Understanding of automation concepts

### Script with Timestamps

#### 0:00-0:30 - Introduction
**Voiceover:**
"Welcome to the final tutorial in our series! Now we'll take scene management to production by integrating it into CI/CD pipelines. You'll learn how to automate scene testing, validate performance metrics, and ensure every commit maintains scene integrity. This is essential for professional game development teams."

**On Screen:**
- Title card: "Advanced Integration: CI/CD & Testing"
- Show CI/CD pipeline diagram
- Production deployment flow

#### 0:30-2:00 - Test Suite Architecture
**Voiceover:**
"Let's start by building a comprehensive test suite using pytest. We'll create tests that load scenes, validate their structure, check performance metrics, and ensure VR components are properly configured. Each test is independent and can run in parallel."

**On Screen:**
- Create file: `tests/test_scene_management.py`
- Show pytest configuration
- Highlight test structure

**Code to Show:**
```python
# tests/test_scene_management.py
import pytest
import time
from scene_manager import SceneManager, SceneInfo

@pytest.fixture
def scene_manager():
    """Create SceneManager instance for tests"""
    manager = SceneManager()
    # Wait for Godot to be ready
    assert manager.wait_until_ready(max_wait=30), "API not ready"
    yield manager

def test_api_status(scene_manager):
    """Test that API is ready and all services are running"""
    status = scene_manager.check_status()
    assert status["overall_ready"] is True
    assert status["services"]["godot_bridge"] is True
    assert status["services"]["dap_adapter"] is True
    assert status["services"]["lsp_adapter"] is True

def test_load_vr_main(scene_manager):
    """Test loading VR main scene"""
    result = scene_manager.load_scene("res://vr_main.tscn")
    assert result["success"] is True
    assert result["scene_path"] == "res://vr_main.tscn"
    assert result["node_count"] > 0
    assert result["load_time_ms"] < 1000  # Should load in < 1 second

def test_scene_info_structure(scene_manager):
    """Test scene info returns correct structure"""
    # Load scene first
    scene_manager.load_scene("res://vr_main.tscn")

    # Get info
    info = scene_manager.get_scene_info()
    assert info.scene_path == "res://vr_main.tscn"
    assert info.root_node == "VRMain"
    assert info.node_count > 0
    assert "VRMain" in info.scene_tree

def test_vr_components_present(scene_manager):
    """Test that all required VR components are present"""
    scene_manager.load_scene("res://vr_main.tscn")
    info = scene_manager.get_scene_info()

    # Check VR structure
    tree = info.scene_tree
    assert "VRMain" in tree
    vr_main = tree["VRMain"]

    # Check for XROrigin3D
    assert "children" in vr_main
    children = vr_main["children"]
    assert "XROrigin3D" in children

    # Check for camera and controllers
    xr_origin = children["XROrigin3D"]
    xr_children = xr_origin["children"]
    assert "XRCamera3D" in xr_children
    assert "LeftController" in xr_children
    assert "RightController" in xr_children

def test_scene_reload_performance(scene_manager):
    """Test that scene reload is performant"""
    # Load scene
    scene_manager.load_scene("res://vr_main.tscn")

    # Reload and check timing
    result = scene_manager.reload_scene()
    assert result["success"] is True
    assert result["reload_time_ms"] < 500  # Should reload in < 0.5 seconds

def test_multiple_scene_loads(scene_manager):
    """Test loading multiple different scenes"""
    scenes = [
        "res://vr_main.tscn",
        # Add more scenes as needed
    ]

    for scene_path in scenes:
        result = scene_manager.load_scene(scene_path)
        assert result["success"] is True
        assert result["scene_path"] == scene_path
        time.sleep(0.5)  # Brief pause between loads

@pytest.mark.parametrize("invalid_scene", [
    "res://nonexistent.tscn",
    "res://invalid/path.tscn",
    "",
    "not_a_res_path.tscn"
])
def test_invalid_scene_handling(scene_manager, invalid_scene):
    """Test that invalid scenes are handled gracefully"""
    with pytest.raises(RuntimeError):
        scene_manager.load_scene(invalid_scene)

def test_scene_reload_preserves_path(scene_manager):
    """Test that reload preserves the current scene path"""
    # Load specific scene
    load_result = scene_manager.load_scene("res://vr_main.tscn")
    original_path = load_result["scene_path"]

    # Reload
    reload_result = scene_manager.reload_scene()
    assert reload_result["scene_path"] == original_path

def test_concurrent_operations_safety(scene_manager):
    """Test that multiple operations don't cause race conditions"""
    # Load scene
    scene_manager.load_scene("res://vr_main.tscn")

    # Get info
    info = scene_manager.get_scene_info()
    assert info.scene_path == "res://vr_main.tscn"

    # Reload
    reload_result = scene_manager.reload_scene()
    assert reload_result["success"] is True

    # Get info again
    info2 = scene_manager.get_scene_info()
    assert info2.scene_path == info.scene_path

# Performance benchmarking
def test_load_performance_benchmark(scene_manager, benchmark):
    """Benchmark scene loading performance"""
    def load_scene():
        scene_manager.load_scene("res://vr_main.tscn")

    # Run benchmark (requires pytest-benchmark)
    result = benchmark(load_scene)
    # Assert performance SLA
    assert result.stats.mean < 0.5  # Mean load time < 500ms
```

#### 2:00-3:30 - pytest Configuration
**Voiceover:**
"Now let's configure pytest with proper fixtures, markers, and reporting. We'll set up HTML reports, code coverage, and parallel test execution. This configuration makes your test suite production-ready."

**On Screen:**
- Create file: `pytest.ini`
- Create file: `tests/conftest.py`
- Show configuration options

**Code to Show:**
```ini
# pytest.ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*

# Markers
markers =
    slow: marks tests as slow (deselect with '-m "not slow"')
    integration: marks tests as integration tests
    vr: marks tests that require VR components
    performance: marks performance benchmark tests

# Output
addopts =
    --verbose
    --tb=short
    --strict-markers
    --disable-warnings
    -ra

# Timeouts
timeout = 30
timeout_method = thread

# Coverage (if pytest-cov installed)
# --cov=scene_manager
# --cov-report=html
# --cov-report=term-missing
```

```python
# tests/conftest.py
import pytest
import time
import subprocess
import sys
from pathlib import Path

def pytest_configure(config):
    """Configure pytest with custom settings"""
    config.addinivalue_line(
        "markers", "requires_godot: test requires Godot running"
    )

@pytest.fixture(scope="session")
def ensure_godot_running():
    """Ensure Godot is running before tests start"""
    from scene_manager import SceneManager

    manager = SceneManager()
    if not manager.wait_until_ready(max_wait=5):
        # Try to start Godot
        godot_path = Path("C:/godot")
        script_path = godot_path / "restart_godot_with_debug.bat"

        if script_path.exists():
            print("Starting Godot with debug services...")
            subprocess.Popen([str(script_path)], cwd=str(godot_path))
            time.sleep(10)  # Wait for startup

            if not manager.wait_until_ready(max_wait=20):
                pytest.exit("Could not start Godot")
        else:
            pytest.exit("Godot not running and cannot start automatically")

    return manager

@pytest.fixture(autouse=True)
def reset_scene_state(scene_manager):
    """Reset scene state before each test"""
    yield
    # Cleanup after test if needed
    try:
        scene_manager.load_scene("res://vr_main.tscn")
    except:
        pass  # Ignore cleanup errors
```

#### 3:30-5:30 - GitHub Actions Workflow
**Voiceover:**
"Let's create a GitHub Actions workflow that runs our tests on every commit. This workflow starts Godot in headless mode with debug services, waits for it to be ready, runs the test suite, and reports results. It even caches dependencies for faster builds."

**On Screen:**
- Create file: `.github/workflows/scene_tests.yml`
- Show YAML structure
- Highlight key steps

**Code to Show:**
```yaml
# .github/workflows/scene_tests.yml
name: Scene Management Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  workflow_dispatch:  # Allow manual trigger

jobs:
  test:
    runs-on: windows-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
        cache: 'pip'

    - name: Install Python dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r tests/requirements.txt

    - name: Download Godot
      run: |
        # Download Godot 4.5+ stable
        $godotVersion = "4.5-stable"
        $godotUrl = "https://downloads.tuxfamily.org/godotengine/$godotVersion/Godot_v$godotVersion_win64.exe.zip"

        Write-Host "Downloading Godot $godotVersion..."
        Invoke-WebRequest -Uri $godotUrl -OutFile godot.zip

        Write-Host "Extracting Godot..."
        Expand-Archive godot.zip -DestinationPath godot_bin

        # Find exe
        $godotExe = Get-ChildItem -Path godot_bin -Filter "Godot*.exe" -Recurse | Select-Object -First 1
        echo "GODOT_BIN=$($godotExe.FullName)" >> $env:GITHUB_ENV
      shell: pwsh

    - name: Cache Godot editor data
      uses: actions/cache@v3
      with:
        path: ~/.local/share/godot
        key: ${{ runner.os }}-godot-${{ hashFiles('project.godot') }}

    - name: Import Godot project
      run: |
        # Import project to generate .godot folder
        & $env:GODOT_BIN --headless --editor --quit --path "${{ github.workspace }}"
      timeout-minutes: 5

    - name: Start Godot with debug services
      run: |
        # Start Godot in background with debug services
        $process = Start-Process -FilePath $env:GODOT_BIN `
          -ArgumentList "--path `"${{ github.workspace }}`" --dap-port 6006 --lsp-port 6005" `
          -PassThru -WindowStyle Hidden

        echo "GODOT_PID=$($process.Id)" >> $env:GITHUB_ENV

        # Wait for services to be ready
        Write-Host "Waiting for debug services to start..."
        Start-Sleep -Seconds 15
      shell: pwsh

    - name: Wait for API readiness
      run: |
        # Wait for HTTP API to be ready
        $maxAttempts = 30
        $attempt = 0

        while ($attempt -lt $maxAttempts) {
          try {
            $response = Invoke-RestMethod -Uri "http://127.0.0.1:8080/status" -TimeoutSec 2
            if ($response.overall_ready -eq $true) {
              Write-Host "✓ API is ready!"
              exit 0
            }
          } catch {
            Write-Host "Waiting for API... (attempt $($attempt + 1)/$maxAttempts)"
          }
          Start-Sleep -Seconds 2
          $attempt++
        }

        Write-Host "✗ API did not become ready in time"
        exit 1
      shell: pwsh

    - name: Run tests
      run: |
        pytest tests/test_scene_management.py `
          --verbose `
          --tb=short `
          --junit-xml=test-results.xml `
          --html=test-report.html `
          --self-contained-html
      continue-on-error: false

    - name: Upload test results
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: test-results
        path: |
          test-results.xml
          test-report.html

    - name: Publish test results
      if: always()
      uses: EnricoMi/publish-unit-test-result-action/composite@v2
      with:
        files: test-results.xml

    - name: Stop Godot
      if: always()
      run: |
        if ($env:GODOT_PID) {
          Stop-Process -Id $env:GODOT_PID -Force -ErrorAction SilentlyContinue
        }
      shell: pwsh

    - name: Check test results
      if: failure()
      run: |
        Write-Host "Tests failed! Check the test report artifact for details."
        exit 1
      shell: pwsh
```

#### 5:30-7:00 - Performance Monitoring
**Voiceover:**
"Performance monitoring is critical for maintaining smooth VR experiences. Let's create a monitoring script that tracks scene load times, validates they meet SLAs, and alerts if performance degrades. This runs automatically in CI and can be used in production."

**On Screen:**
- Create file: `tests/performance_monitor.py`
- Show metrics collection
- Display threshold checks

**Code to Show:**
```python
# tests/performance_monitor.py
import time
import statistics
from dataclasses import dataclass
from typing import List, Dict
from scene_manager import SceneManager

@dataclass
class PerformanceMetrics:
    """Performance metrics for scene operations"""
    operation: str
    samples: List[float]

    @property
    def mean(self) -> float:
        return statistics.mean(self.samples)

    @property
    def median(self) -> float:
        return statistics.median(self.samples)

    @property
    def stdev(self) -> float:
        return statistics.stdev(self.samples) if len(self.samples) > 1 else 0

    @property
    def min(self) -> float:
        return min(self.samples)

    @property
    def max(self) -> float:
        return max(self.samples)

    @property
    def p95(self) -> float:
        """95th percentile"""
        sorted_samples = sorted(self.samples)
        index = int(len(sorted_samples) * 0.95)
        return sorted_samples[index]

class PerformanceMonitor:
    """Monitor scene management performance"""

    # Performance SLAs (in milliseconds)
    SLA_LOAD_TIME = 500.0
    SLA_RELOAD_TIME = 300.0
    SLA_INFO_TIME = 100.0

    def __init__(self):
        self.manager = SceneManager()
        self.results: Dict[str, PerformanceMetrics] = {}

    def benchmark_load(self, scene_path: str, iterations: int = 10) -> PerformanceMetrics:
        """Benchmark scene loading"""
        print(f"Benchmarking scene load: {scene_path} ({iterations} iterations)")
        samples = []

        for i in range(iterations):
            result = self.manager.load_scene(scene_path)
            samples.append(result["load_time_ms"])
            print(f"  Iteration {i+1}: {result['load_time_ms']:.1f}ms")
            time.sleep(0.5)  # Brief pause

        metrics = PerformanceMetrics("load", samples)
        self.results["load"] = metrics
        return metrics

    def benchmark_reload(self, iterations: int = 10) -> PerformanceMetrics:
        """Benchmark scene reloading"""
        print(f"Benchmarking scene reload ({iterations} iterations)")
        samples = []

        for i in range(iterations):
            result = self.manager.reload_scene()
            samples.append(result["reload_time_ms"])
            print(f"  Iteration {i+1}: {result['reload_time_ms']:.1f}ms")
            time.sleep(0.5)

        metrics = PerformanceMetrics("reload", samples)
        self.results["reload"] = metrics
        return metrics

    def benchmark_info(self, iterations: int = 10) -> PerformanceMetrics:
        """Benchmark scene info retrieval"""
        print(f"Benchmarking scene info ({iterations} iterations)")
        samples = []

        for i in range(iterations):
            start = time.time()
            self.manager.get_scene_info()
            elapsed = (time.time() - start) * 1000
            samples.append(elapsed)
            print(f"  Iteration {i+1}: {elapsed:.1f}ms")

        metrics = PerformanceMetrics("info", samples)
        self.results["info"] = metrics
        return metrics

    def validate_slas(self) -> Dict[str, bool]:
        """Validate performance against SLAs"""
        print("\n=== SLA Validation ===")
        validation = {}

        if "load" in self.results:
            load_metrics = self.results["load"]
            meets_sla = load_metrics.p95 <= self.SLA_LOAD_TIME
            validation["load"] = meets_sla
            status = "✓ PASS" if meets_sla else "✗ FAIL"
            print(f"Load Time P95: {load_metrics.p95:.1f}ms (SLA: {self.SLA_LOAD_TIME}ms) {status}")

        if "reload" in self.results:
            reload_metrics = self.results["reload"]
            meets_sla = reload_metrics.p95 <= self.SLA_RELOAD_TIME
            validation["reload"] = meets_sla
            status = "✓ PASS" if meets_sla else "✗ FAIL"
            print(f"Reload Time P95: {reload_metrics.p95:.1f}ms (SLA: {self.SLA_RELOAD_TIME}ms) {status}")

        if "info" in self.results:
            info_metrics = self.results["info"]
            meets_sla = info_metrics.p95 <= self.SLA_INFO_TIME
            validation["info"] = meets_sla
            status = "✓ PASS" if meets_sla else "✗ FAIL"
            print(f"Info Time P95: {info_metrics.p95:.1f}ms (SLA: {self.SLA_INFO_TIME}ms) {status}")

        return validation

    def print_report(self):
        """Print detailed performance report"""
        print("\n=== Performance Report ===")

        for operation, metrics in self.results.items():
            print(f"\n{operation.upper()} Operation:")
            print(f"  Samples: {len(metrics.samples)}")
            print(f"  Mean: {metrics.mean:.1f}ms")
            print(f"  Median: {metrics.median:.1f}ms")
            print(f"  Std Dev: {metrics.stdev:.1f}ms")
            print(f"  Min: {metrics.min:.1f}ms")
            print(f"  Max: {metrics.max:.1f}ms")
            print(f"  P95: {metrics.p95:.1f}ms")

    def export_metrics(self, filename: str = "performance_metrics.json"):
        """Export metrics to JSON file"""
        import json

        data = {}
        for operation, metrics in self.results.items():
            data[operation] = {
                "samples": metrics.samples,
                "mean": metrics.mean,
                "median": metrics.median,
                "stdev": metrics.stdev,
                "min": metrics.min,
                "max": metrics.max,
                "p95": metrics.p95
            }

        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)

        print(f"\nMetrics exported to {filename}")

def main():
    """Run performance monitoring"""
    monitor = PerformanceMonitor()

    # Wait for API
    print("Waiting for API to be ready...")
    if not monitor.manager.wait_until_ready(max_wait=30):
        print("Error: API not ready")
        return 1
    print("API ready!\n")

    # Run benchmarks
    try:
        monitor.benchmark_load("res://vr_main.tscn", iterations=10)
        monitor.benchmark_reload(iterations=10)
        monitor.benchmark_info(iterations=10)

        # Print report
        monitor.print_report()

        # Validate SLAs
        validation = monitor.validate_slas()

        # Export metrics
        monitor.export_metrics()

        # Return exit code based on SLA validation
        if all(validation.values()):
            print("\n✓ All SLAs met!")
            return 0
        else:
            print("\n✗ Some SLAs failed!")
            return 1

    except Exception as e:
        print(f"Error during benchmarking: {e}")
        return 1

if __name__ == "__main__":
    import sys
    sys.exit(main())
```

#### 7:00-9:00 - Deployment Validation Pipeline
**Voiceover:**
"Before deploying to production, we need a validation pipeline that checks scene integrity, performance, and compatibility. This script runs a comprehensive suite of checks and generates a deployment readiness report."

**On Screen:**
- Create file: `tests/deployment_validator.py`
- Show validation checks
- Display readiness report

**Code to Show:**
```python
# tests/deployment_validator.py
import sys
from dataclasses import dataclass
from typing import List, Dict, Any
from scene_manager import SceneManager

@dataclass
class ValidationCheck:
    """Validation check result"""
    name: str
    passed: bool
    message: str
    severity: str = "error"  # error, warning, info

class DeploymentValidator:
    """Validate deployment readiness"""

    def __init__(self):
        self.manager = SceneManager()
        self.checks: List[ValidationCheck] = []

    def run_all_checks(self, scene_paths: List[str]) -> bool:
        """Run all validation checks"""
        print("=== Deployment Validation ===\n")

        # API connectivity
        self.check_api_connectivity()

        # Scene validation
        for scene_path in scene_paths:
            self.validate_scene(scene_path)

        # Performance validation
        self.validate_performance()

        # Generate report
        return self.print_report()

    def check_api_connectivity(self):
        """Check API is accessible"""
        print("Checking API connectivity...")
        try:
            status = self.manager.check_status()
            if status.get("overall_ready"):
                self.checks.append(ValidationCheck(
                    "API Connectivity",
                    True,
                    "API is ready and all services are running"
                ))
            else:
                self.checks.append(ValidationCheck(
                    "API Connectivity",
                    False,
                    f"API not fully ready: {status}",
                    "error"
                ))
        except Exception as e:
            self.checks.append(ValidationCheck(
                "API Connectivity",
                False,
                f"Cannot connect to API: {e}",
                "error"
            ))

    def validate_scene(self, scene_path: str):
        """Validate a scene"""
        print(f"Validating scene: {scene_path}")

        # Load scene
        try:
            result = self.manager.load_scene(scene_path)
            self.checks.append(ValidationCheck(
                f"Load: {scene_path}",
                True,
                f"Loaded successfully ({result['load_time_ms']:.1f}ms, {result['node_count']} nodes)"
            ))
        except Exception as e:
            self.checks.append(ValidationCheck(
                f"Load: {scene_path}",
                False,
                f"Failed to load: {e}",
                "error"
            ))
            return

        # Get scene info
        try:
            info = self.manager.get_scene_info()
            self.checks.append(ValidationCheck(
                f"Info: {scene_path}",
                True,
                f"Scene has {info.node_count} nodes with root '{info.root_node}'"
            ))

            # Validate structure
            self.validate_scene_structure(info)

        except Exception as e:
            self.checks.append(ValidationCheck(
                f"Info: {scene_path}",
                False,
                f"Failed to get info: {e}",
                "error"
            ))

    def validate_scene_structure(self, info):
        """Validate scene structure"""
        # Check for VR components
        tree = info.scene_tree

        if "XROrigin3D" in str(tree):
            self.checks.append(ValidationCheck(
                "VR Components",
                True,
                "XROrigin3D found in scene tree"
            ))
        else:
            self.checks.append(ValidationCheck(
                "VR Components",
                False,
                "XROrigin3D not found - VR may not work",
                "warning"
            ))

        if "XRCamera3D" in str(tree):
            self.checks.append(ValidationCheck(
                "VR Camera",
                True,
                "XRCamera3D found in scene tree"
            ))
        else:
            self.checks.append(ValidationCheck(
                "VR Camera",
                False,
                "XRCamera3D not found - VR may not work",
                "warning"
            ))

    def validate_performance(self):
        """Validate performance metrics"""
        print("Validating performance...")

        try:
            # Test reload performance
            result = self.manager.reload_scene()
            reload_time = result["reload_time_ms"]

            if reload_time < 500:
                self.checks.append(ValidationCheck(
                    "Reload Performance",
                    True,
                    f"Reload time: {reload_time:.1f}ms (< 500ms SLA)"
                ))
            else:
                self.checks.append(ValidationCheck(
                    "Reload Performance",
                    False,
                    f"Reload time: {reload_time:.1f}ms (exceeds 500ms SLA)",
                    "warning"
                ))
        except Exception as e:
            self.checks.append(ValidationCheck(
                "Reload Performance",
                False,
                f"Performance check failed: {e}",
                "error"
            ))

    def print_report(self) -> bool:
        """Print validation report"""
        print("\n=== Validation Report ===\n")

        passed = 0
        failed = 0
        warnings = 0

        for check in self.checks:
            if check.passed:
                symbol = "✓"
                passed += 1
            else:
                symbol = "✗" if check.severity == "error" else "⚠"
                if check.severity == "error":
                    failed += 1
                else:
                    warnings += 1

            print(f"{symbol} {check.name}")
            print(f"  {check.message}")

        print(f"\n--- Summary ---")
        print(f"Passed: {passed}")
        print(f"Failed: {failed}")
        print(f"Warnings: {warnings}")
        print(f"Total: {len(self.checks)}")

        if failed == 0:
            print("\n✓ DEPLOYMENT READY")
            return True
        else:
            print("\n✗ DEPLOYMENT BLOCKED")
            return False

def main():
    """Run deployment validation"""
    scenes = [
        "res://vr_main.tscn",
        # Add more critical scenes
    ]

    validator = DeploymentValidator()

    # Wait for API
    print("Waiting for API to be ready...")
    if not validator.manager.wait_until_ready(max_wait=30):
        print("Error: API not ready")
        return 1

    # Run validation
    if validator.run_all_checks(scenes):
        return 0
    else:
        return 1

if __name__ == "__main__":
    sys.exit(main())
```

#### 9:00-10:30 - Integration with CI/CD
**Voiceover:**
"Now let's integrate our validation pipeline into the GitHub Actions workflow. We'll add deployment validation as a required check before merging pull requests. This ensures only validated code reaches production."

**On Screen:**
- Edit `.github/workflows/scene_tests.yml`
- Add deployment validation step
- Show pull request checks

**Code to Add:**
```yaml
    - name: Run deployment validation
      run: |
        python tests/deployment_validator.py
      continue-on-error: false

    - name: Run performance monitoring
      run: |
        python tests/performance_monitor.py
      continue-on-error: false

    - name: Upload performance metrics
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: performance-metrics
        path: performance_metrics.json
```

#### 10:30-11:30 - Production Deployment Example
**Voiceover:**
"Finally, let's look at a complete production deployment script. This script runs all validations, performs a canary deployment, monitors metrics, and can automatically rollback if issues are detected. This is the gold standard for production deployments."

**On Screen:**
- Create file: `deploy/production_deploy.py`
- Show deployment stages
- Highlight rollback logic

**Code to Show (abbreviated):**
```python
# deploy/production_deploy.py
import sys
import time
from scene_manager import SceneManager

def deploy_to_production():
    """Deploy to production with validation"""
    print("=== Production Deployment ===\n")

    manager = SceneManager()

    # Step 1: Pre-deployment validation
    print("Step 1: Pre-deployment validation...")
    if not validate_deployment():
        print("✗ Pre-deployment validation failed")
        return 1
    print("✓ Pre-deployment validation passed\n")

    # Step 2: Canary deployment
    print("Step 2: Canary deployment...")
    if not deploy_canary(manager):
        print("✗ Canary deployment failed")
        return 1
    print("✓ Canary deployment successful\n")

    # Step 3: Monitor canary
    print("Step 3: Monitoring canary...")
    if not monitor_canary(manager):
        print("✗ Canary metrics show issues - rolling back")
        rollback()
        return 1
    print("✓ Canary metrics healthy\n")

    # Step 4: Full deployment
    print("Step 4: Full deployment...")
    if not deploy_full(manager):
        print("✗ Full deployment failed - rolling back")
        rollback()
        return 1
    print("✓ Full deployment successful\n")

    print("✓ DEPLOYMENT COMPLETE")
    return 0

if __name__ == "__main__":
    sys.exit(deploy_to_production())
```

#### 11:30-12:00 - Wrap Up and Series Conclusion
**Voiceover:**
"Congratulations! You've mastered the Scene Management API from basic HTTP requests to production-grade CI/CD integration. You now have the tools to automate scene testing, monitor performance, and deploy with confidence. This workflow is used by professional game development teams to maintain quality and velocity. Thank you for watching this series!"

**On Screen:**
- Summary slide:
  - ✓ Built comprehensive test suite
  - ✓ Configured GitHub Actions workflow
  - ✓ Implemented performance monitoring
  - ✓ Created deployment validation pipeline
- Series completion:
  - Tutorial 1: HTTP API basics
  - Tutorial 2: Python client development
  - Tutorial 3: Web dashboard
  - Tutorial 4: CI/CD integration
- Resources:
  - Full code on GitHub
  - Documentation
  - Discord community
  - Office hours schedule
- Call to action: "Star the repo, join Discord, share your projects!"

**Common Pitfalls to Highlight:**
- ⚠️ Always validate scenes before deployment
- ⚠️ Monitor performance SLAs continuously
- ⚠️ Implement circuit breakers for API calls
- ⚠️ Use canary deployments for production changes
- ⚠️ Keep test environments isolated from production
- ⚠️ Document all validation checks and SLAs

---

## Series Learning Outcomes

Upon completing this tutorial series, viewers will be able to:

1. **HTTP API Fundamentals**
   - Start Godot with debug services enabled
   - Execute scene management operations via HTTP
   - Verify API connectivity and status
   - Understand the scene management lifecycle

2. **Python Client Development**
   - Build reusable API client classes
   - Implement error handling and retry logic
   - Create command-line tools with argparse
   - Apply circuit breaker patterns for resilience

3. **Web Dashboard Usage**
   - Navigate the scene management dashboard
   - Load, reload, and query scenes visually
   - Run automated validation checks
   - Track operation history and metrics

4. **CI/CD Integration**
   - Write comprehensive pytest test suites
   - Configure GitHub Actions workflows
   - Monitor performance and validate SLAs
   - Implement deployment validation pipelines
   - Handle production deployments safely

## Key Technical Skills Gained

- RESTful API consumption
- Python client library development
- Test automation with pytest
- CI/CD pipeline configuration
- Performance monitoring and benchmarking
- Deployment validation and rollback strategies
- Error handling and resilience patterns

## Total Tutorial Runtime

**35 minutes** across 4 tutorials:
- Tutorial 1: 5 minutes (Quick Start)
- Tutorial 2: 10 minutes (Python Client)
- Tutorial 3: 8 minutes (Web Dashboard)
- Tutorial 4: 12 minutes (CI/CD Integration)
