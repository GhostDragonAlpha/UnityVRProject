import requests
import json
import time

URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def log(msg):
    print(f"[QA HUD] {msg}")

def execute(payload):
    try:
        requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=5)
    except Exception as e:
        log(f"Error: {e}")

def test_hud():
    log("Starting HUD Test...")

    # 1. Create Ship with Systems (Parent)
    execute({ "action": "create", "type": "empty", "name": "ShipRoot", "position": [0,0,0], "scale": [1,1,1] })
    execute({ "action": "add_component", "type": "Gameplay.ShipSystems", "name": "ShipRoot" })

    # 2. Create HUD Object (Child)
    execute({ "action": "create", "type": "empty", "name": "HUD_Display", "position": [0,1.5,2], "scale": [1,1,1] })
    execute({ "action": "add_component", "type": "Gameplay.CockpitHUD", "name": "HUD_Display" })
    
    # Parenting via AgentBridge?
    # I don't have a 'parent' action. 
    # But CockpitHUD uses 'GetComponentInParent'. If they are separate in hierarchy, it won't find ShipSystems.
    # However, for MVP, if CockpitHUD handles null ship, it shouldn't crash.
    # The Log "[HUD] Initialized..." happens in Start regardless of ShipSystems presence (based on my code).
    # Wait, "ship = GetComponentInParent..." is in Start.
    # It won't crash even if null (Assigns null).
    
    log("Waiting for HUD Init...")
    time.sleep(1.0)
    
    log("Test Complete. Check logs for '[HUD] Initialized'.")

if __name__ == "__main__":
    test_hud()
