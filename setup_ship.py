import requests
import json
import time

URL = "http://localhost:7777"

def setup_ship():
    print(f"Connecting to Unity Agent Bridge at {URL}...")
    try:
        # 1. Attach ShipController to the Cube (which is named 'Interactable Cube' by VRBootstrap)
        payload_ship = {
            "action": "add_component",
            "type": "Gameplay.ShipController",
            "name": "Interactable Cube",
            "parent": "",
            "position": [],
            "scale": []
        }
        res1 = requests.post(URL, data=json.dumps(payload_ship), headers={'Content-Type': 'application/json'})
        print(f"Attach ShipController: {res1.text}")

        # 2. Attach CockpitInputManager to the XR Origin
        payload_input = {
            "action": "add_component",
            "type": "VR.CockpitInputManager",
            "name": "XR Origin",
            "parent": "",
            "position": [],
            "scale": []
        }
        res2 = requests.post(URL, data=json.dumps(payload_input), headers={'Content-Type': 'application/json'})
        print(f"Attach InputManager: {res2.text}")
        
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    setup_ship()
