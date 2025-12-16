import requests
import json
import time
import sys

URL = "http://localhost:7777/execute"
HEADERS = {"Content-Type": "application/json"}

def log(msg):
    print(f"[MasterBuilder] {msg}")

def execute(payload, retry=3):
    for i in range(retry):
        try:
            response = requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=10)
            if response.status_code == 200:
                return True
            else:
                log(f"Command Failed ({response.status_code}): {response.text}")
        except Exception as e:
            log(f"Connection Error (Attempt {i+1}/{retry}): {e}")
            time.sleep(2)
    return False

def check_connection():
    log("Checking connection to Unity...")
    for i in range(10):
        if execute({"action": "ping"}):
            log("Unity Connected!")
            return True
        log("Waiting for Unity compilation/server...")
        time.sleep(2)
    return False

def build_hierarchy():
    if not check_connection():
        log("Could not connect to Unity. Aborting.")
        sys.exit(1)

    log("Building Master Hierarchy...")

    # 1. Clear Scene (The Blank Canvas)
    execute({"action": "delete_all", "exclude": ["Main Camera", "Directional Light"]})

    # 2. Create The Root Context ("Cosmos")
    execute({"action": "create", "type": "empty", "name": "Cosmos", "position": [0,0,0]})

    # 3. Create The Laws ("Physics")
    # Parented to Cosmos
    execute({"action": "create", "type": "empty", "name": "Physics", "parent": "Cosmos"})
    execute({"action": "add_component", "type": "Core.PhysicsEngine", "name": "Physics"})

    # 4. Create The Architect ("Generator")
    # Parented to Cosmos
    execute({"action": "create", "type": "empty", "name": "Generator", "parent": "Cosmos"})
    execute({"action": "add_component", "type": "Procedural.UniverseGenerator", "name": "Generator"})

    # 5. Create The System Root ("Sol")
    # Parented to Cosmos (or a Sector container if we get advanced, but Sol is root for now)
    log("Planting the Root: Sol")
    execute({"action": "create", "type": "sphere", "name": "Sol", "position": [0,0,0], "scale": [50,50,50], "parent": "Cosmos"})
    execute({"action": "add_component", "type": "Core.Star", "name": "Sol"})
    
    # Configure Sol
    # Note: OnValidate in Unity might auto-calculate logic, but we set base values
    execute({"action": "set_property", "name": "Sol", "type": "Core.Star", "propertyName": "Mass", "value": "1.0"})
    
    # 6. Verify
    log("Hierarchy Built.")
    # We can request a dump if AgentBridge supports it, or just verify via logs

if __name__ == "__main__":
    build_hierarchy()
