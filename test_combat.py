import requests
import json
import time

URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def log(msg):
    print(f"[QA Combat] {msg}")

def execute(payload):
    try:
        requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=5)
    except Exception as e:
        log(f"Error: {e}")

def test_combat():
    log("Starting Combat AI Test...")

    # 1. Setup Scene (WorldMover, Gravity)
    execute({ "action": "create", "type": "empty", "name": "WorldMover_Manager", "position": [0,0,0], "scale": [1,1,1] })
    execute({ "action": "add_component", "type": "Core.WorldMover", "name": "WorldMover_Manager" })
    
    # 2. Spawn Player (XR Origin) at (0,0,0)
    # Note: VirtualTransform assumes (0,0,0) virtual pos for new objects unless set.
    execute({ "action": "create", "type": "empty", "name": "XR Origin", "position": [0,0,0], "scale": [1,1,1] })
    execute({ "action": "add_component", "type": "Gameplay.VirtualShip", "name": "XR Origin" })

    # 3. Spawn Drone at (0, 0, 400)
    # Need to set VirtualTransform pos. But standard 'create' uses 'position' which is local.
    # If we create at (0,0,400) and add VT, VT takes that as initial pos.
    execute({ "action": "create", "type": "cube", "name": "Enemy_Drone", "position": [0,0,400], "scale": [2,2,2] })
    execute({ "action": "add_component", "type": "VirtualTransform", "name": "Enemy_Drone" })
    execute({ "action": "add_component", "type": "Combat.DroneAI", "name": "Enemy_Drone" })
    
    # 4. Wait for AI to Chase (Speed 20, Dist 400 -> ~20s to reach attack range of 50)
    # Wait, 400m - 50m = 350m / 20mps = 17.5s.
    # We can spawn it closer, say 100m.
    # 100m -> 50m = 2.5s.
    execute({ 
        "action": "set_property", 
        "name": "Enemy_Drone", 
        "type": "Transform", 
        "propertyName": "position", 
        "value": [0, 0, 100]
    })
    # If VT updates from Transform on Start, this works.
    
    log("Waiting for Drone to Attack...")
    time.sleep(5.0)
    
    log("Test Complete. Check logs for '[Combat] Drone Firing'.")

if __name__ == "__main__":
    test_combat()
