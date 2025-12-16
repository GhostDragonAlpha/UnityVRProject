import requests
import json
import time

URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def log(msg):
    print(f"[Cleanup] {msg}")

def execute(payload):
    try:
        resp = requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=5)
        return resp.json()
    except Exception as e:
        log(f"Error: {e}")
        return {}

def cleanup_scene():
    log("Cleaning Scene Duplicates...")

    targets = [
        "XR Origin",
        "WorldMover_Manager",
        "GravityManager",
        "Enemy_Drone",
        "TestShip",
        "ShipRoot",
        "HUD_Display",
        "AgentVerified_Cube",
        "MiningShip",
        "Iron_Ore_Vein",
        "Virtual_Cube"
    ]
    
    for t in targets:
        log(f"Deleting '{t}'...")
        res = execute({ "action": "delete", "name": t })
        if "message" in res:
            log(f"Result: {res['message']}")

    log("Scene Cleaned.")

if __name__ == "__main__":
    cleanup_scene()
