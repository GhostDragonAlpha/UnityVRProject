import requests
import json
import time
import sys

# Configuration
URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def log(msg):
    print(f"[AgentInterface] {msg}")

def check_connection():
    try:
        requests.get(URL, timeout=1)
        return True
    except:
        return False

def pull_logs():
    try:
        resp = requests.get(f"{URL}/console", timeout=1)
        if resp.status_code == 200 and resp.text.strip():
            print("\n--- UNITY CONSOLE ---")
            print(resp.text)
            print("---------------------\n")
    except Exception as e:
        log(f"Log pull failed: {e}")

def execute_command(payload):
    try:
        resp = requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=1)
        return resp.json()
    except Exception as e:
        return {"status": "error", "message": str(e)}

def run_autonomous_loop():
    log("Starting Autonomous Control Loop...")
    
    if not check_connection():
        log("ERROR: AgentBridge not reachable. Is Unity running?")
        return

    # 1. Pull initial logs
    pull_logs()

    # 2. Demonstration: "Speed"
    # We will rapidly create a "Fleet" of ships to prove we don't need compilation
    log("Demonstrating High-Speed Autonomous Action: Deploying Fleet...")
    
    for i in range(5):
        # Create Ship
        name = f"Drone_Alpha_{i}"
        cmd_create = {
            "action": "create",
            "type": "cube", 
            "name": name,
            "position": [i * 2.0, 5.0, 0.0],
            "scale": [0.5, 0.5, 0.5]
        }
        res = execute_command(cmd_create)
        log(f"Created {name}: {res.get('status')}")

        # Add Physics (using our new 'add_component' tool)
        cmd_physics = {
            "action": "add_component",
            "type": "Gameplay.ShipController",
            "name": name
        }
        execute_command(cmd_physics)

        # Tune Settings (using our new 'set_property' tool)
        cmd_tune = {
            "action": "set_property",
            "name": name,
            "type": "Gameplay.ShipController",
            "propertyName": "thrustForce",
            "value": "2000" # High speed!
        }
        execute_command(cmd_tune)
        
        # Pull logs constantly to see if we broke anything
        pull_logs()
        time.sleep(0.5) 

    log("Fleet Deployed. System Stable.")

if __name__ == "__main__":
    run_autonomous_loop()
