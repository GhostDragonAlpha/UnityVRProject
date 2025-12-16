import requests
import json
import time

URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def execute(payload):
    try:
        res = requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=1)
        print(f"CMD {payload.get('action')}: {res.text}")
    except Exception as e:
        print(f"Error: {e}")

def setup_stationary_scene():
    print("Setting up Stationary Player / WorldMover...")

    # 1. Create WorldMover Manager
    execute({
        "action": "create",
        "type": "empty",
        "name": "WorldMover_Manager",
        "position": [0,0,0],
        "scale": [1,1,1]
    })
    execute({
        "action": "add_component",
        "type": "Core.WorldMover",
        "name": "WorldMover_Manager"
    })

    # 2. Attach VirtualShip to VR Origin (The Player)
    execute({
        "action": "add_component",
        "type": "Gameplay.VirtualShip",
        "name": "XR Origin"
    })

    # 3. Attach VirtualTransform to the Test Cube (The Reference Object)
    # We must ensure it exists first
    execute({
        "action": "create",
        "type": "cube",
        "name": "Reference_Cube",
        "position": [0, 0, 10], # 10 meters in front
        "scale": [1, 1, 1]
    })
    execute({
        "action": "add_component",
        "type": "Core.VirtualTransform",
        "name": "Reference_Cube"
    })
    
    # 4. Cleanup Old ShipController (if it exists) from Cube? 
    # Not strictly necessary if we made a new cube, but good practice.

    print("Setup Complete. Use WASD to move the World.")

if __name__ == "__main__":
    setup_stationary_scene()
