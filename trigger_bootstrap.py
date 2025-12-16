import requests
import json
import time

URL = "http://localhost:7777"

def trigger_bootstrap():
    print(f"Connecting to Unity Agent Bridge at {URL}...")
    try:
        # Command: Call Static Method VRBootstrap.SetupScene
        payload = {
            "action": "call_static",
            "type": "EditorScripts.VRBootstrap",
            "name": "SetupScene",
            "parent": "", # Unused
            "position": [],
            "scale": []
        }
        
        print(f"Sending Command: {json.dumps(payload)}")
        headers = {'Content-Type': 'application/json'}
        resp = requests.post(URL, data=json.dumps(payload), headers=headers, timeout=5)
        
        print(f"Response: {resp.status_code} - {resp.text}")
        
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    trigger_bootstrap()
