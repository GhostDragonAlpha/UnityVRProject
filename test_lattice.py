import requests
import json
import time

URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def log(msg):
    print(f"[QA Lattice] {msg}")

def execute(payload):
    try:
        requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=1)
    except:
        pass

def test_lattice():
    log("Starting Lattice Renderer Test...")
    
    # 1. Create Lattice Manager
    execute({ "action": "create", "type": "empty", "name": "LatticeManager", "position": [0,0,0], "scale": [1,1,1] })
    execute({ "action": "add_component", "type": "Rendering.LatticeRenderer", "name": "LatticeManager" })

    # 2. Ensure WorldMover (Dependency)
    execute({ "action": "create", "type": "empty", "name": "WorldMover_Manager", "position": [0,0,0], "scale": [1,1,1] })
    execute({ "action": "add_component", "type": "Core.WorldMover", "name": "WorldMover_Manager" })
    
    # Wait for Initialize
    time.sleep(1.0)
    
    log("Test Complete. Check logs for 'Lattice Shader not found' error. If none, success.")

if __name__ == "__main__":
    test_lattice()
