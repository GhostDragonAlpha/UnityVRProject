import requests
import json
import time
import sys

# --- CONFIGURATION (HARDCODED) ---
# DO NOT CHANGE THIS PORT UNLESS UNITY EDITOR SETTINGS CHANGE
PORT = 7777 
URL = f"http://localhost:{PORT}/execute"
HEADERS = {"Content-Type": "application/json"}
# ---------------------------------

import subprocess
import os

# --- WIN32 POWER TOOl ---
FOCUS_SCRIPT = "focus_unity.ps1"

def focus_unity_window():
    """Forces Unity to Foreground to ensure compilation/execution."""
    if os.path.exists(FOCUS_SCRIPT):
        try:
            # Run detached so we don't block? Or sync?
            # Sync is better to ensure focus happens BEFORE http request.
            subprocess.run(["powershell", "-ExecutionPolicy", "Bypass", "-File", FOCUS_SCRIPT], check=False, timeout=2)
        except Exception:
            pass # Best effort

def log(msg):
    print(f"[UnityBridge] {msg}")

def execute(payload, retry=5, verbose=True):
    """
    Executes a command against the Unity AgentBridge.
    Retries on connection failure.
    Returns (success: bool, response_text: str)
    """
    for i in range(retry):
        try:
            # WORKFLOW FIX: Focus Unity first!
            focus_unity_window()
            time.sleep(0.5) # Give Windows a moment to switch context
            
            response = requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=10)
            if response.status_code == 200:
                # Command received by AgentBridge and executed (or queued)
                return True, response.text
            else:
                log(f"Command Failed ({response.status_code}): {response.text}")
                return False, response.text
        except requests.exceptions.ConnectionError:
            log(f"Connection Attempt {i+1}/{retry} failed. (Target: Port {PORT})")
            time.sleep(1)
        except Exception as e:
            log(f"Unexpected Error: {e}")
            return False, str(e)
            
    log(f"CRITICAL: Could not connect to Unity on Port {PORT}. Check AgentBridge/Unity status.")
    return False, "Connection Failed"

def execute_batch(commands, retry=5, verbose=True):
    """
    Executes a list of commands in a single HTTP request.
    Focuses Unity ONCE.
    """
    payload = {
        "action": "batch",
        "batch": commands
    }
    return execute(payload, retry, verbose)

def check_connection():
    log(f"Verifying connection to Unity (Port {PORT})...")
    success, _ = execute({"action": "ping"}, retry=2, verbose=False)
    if success:
        log("Connection Verified.")
    return success

def ensure_initialized():
    if not check_connection():
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: unity_bridge.py [action] [args...]")
        sys.exit(1)

    action = sys.argv[1]

    if action == "ping":
        check_connection()
    elif action == "log":
        msg = sys.argv[2] if len(sys.argv) > 2 else "Test Log"
        execute({"action": "log", "name": msg})
    elif action == "set":
        # Usage: python unity_bridge.py set [name] [prop] [val]
        # Example: set "Main Camera" position/scale/etc... complex parsing omitted for speed
        pass
    elif action == "set_transform":
        # Usage: set_transform [name] x y z
        name = sys.argv[2]
        x = float(sys.argv[3])
        y = float(sys.argv[4])
        z = float(sys.argv[5])
        execute({
            "action": "set",
            "name": name,
            "type": "transform",
            "propertyName": "position",
            "position": [x, y, z]
        })
    elif action == "screenshot":
        execute({"action": "screenshot", "filename": "unity_screenshot.png"})
    elif action == "add_component":
        name = sys.argv[2]
        comp = sys.argv[3]
        execute({"action": "add_component", "name": name, "type": comp})
    elif action == "generate_universe":
        execute({"action": "generate_universe"})
    elif action == "call_method":
        name = sys.argv[2]
        comp = sys.argv[3]
        method = sys.argv[4]
        execute({
            "action": "call_method", 
            "name": name, 
            "type": comp, 
            "value": method
        })
    elif action == "destroy":
        name = sys.argv[2]
        execute({"action": "destroy", "name": name})
    elif action == "save_scene":
        filename = sys.argv[2] if len(sys.argv) > 2 else ""
        execute({"action": "save_scene", "filename": filename})
    else:
        log(f"Unknown action: {action}")
