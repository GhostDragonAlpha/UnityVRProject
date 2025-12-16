import requests
import json
import time

URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def log(msg):
    print(f"[QA Info] {msg}")

def execute(payload):
    try:
        requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=1)
    except:
        pass

def check_logs_for(text, max_retries=10):
    for i in range(max_retries):
        try:
            resp = requests.get(f"{URL}/console", timeout=1)
            if text in resp.text:
                return True
        except:
            pass
        time.sleep(0.5)
    return False

def run_test():
    log("Starting QA Test: Mining System...")

    # 1. Create Asteroid
    execute({
        "action": "create", "type": "cube", "name": "Asteroid_Iron", "position": [0, 0, 5], "scale": [1,1,1]
    })
    execute({
        "action": "add_component", "type": "Gameplay.MiningTarget", "name": "Asteroid_Iron"
    })
    
    # 2. Create Laser (on Camera)
    execute({
        "action": "add_component", "type": "Gameplay.MiningLaser", "name": "Main Camera"
    })
    
    # 3. Fire Laser!
    log("Firing Laser...")
    execute({
        "action": "set_property", "name": "Main Camera", "type": "Gameplay.MiningLaser", 
        "propertyName": "isFiring", "value": "true"
    })

    # 4. Verify
    log("Monitoring Console for Extraction...")
    if check_logs_for("[Mining] Extracted"):
        log("SUCCESS: Mining verified. Logs confirmed extraction.")
    else:
        log("FAILURE: No extraction logs found.")

if __name__ == "__main__":
    run_test()
