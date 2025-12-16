import requests
import json
import time

URL = "http://localhost:7777"

def verify():
    print(f"Connecting to Unity Agent Bridge at {URL}...")
    try:
        # 1. Health Check
        resp = requests.get(URL, timeout=2)
        print(f"Health Check: {resp.status_code} - {resp.text}")
        
        if resp.status_code != 200:
            print("FAILED: Bridge returned non-200 status.")
            return

        # 2. Command: Create Cube
        payload = {
            "action": "create",
            "type": "cube",
            "name": "AgentVerified_Cube",
            "position": [0, 2, 0],
            "scale": [1, 1, 1]
        }
        
        print(f"Sending Command: {json.dumps(payload)}")
        headers = {'Content-Type': 'application/json'}
        resp = requests.post(URL, data=json.dumps(payload), headers=headers, timeout=5)
        
        print(f"Response: {resp.status_code} - {resp.text}")
        
        if "AgentVerified_Cube" in resp.text:
            print("SUCCESS: Cube created via Bridge.")
        else:
            print("WARNING: Cube creation might have failed or response was unexpected.")

    except requests.exceptions.ConnectionError:
        print("ERROR: Could not connect to Unity. Is the project open and compiled?")
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    verify()
