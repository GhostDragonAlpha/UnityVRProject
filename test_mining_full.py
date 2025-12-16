import requests
import json
import time

URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def log(msg):
    print(f"[QA Mining] {msg}")

def execute(payload):
    try:
        requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=5)
    except Exception as e:
        log(f"Error: {e}")

def test_mining_full():
    log("Starting Full Mining Test...")

    # 1. Setup Ship with Inventory and Laser
    # Ensure XR Origin exists (it holds the scripts usually)
    execute({ "action": "create", "type": "empty", "name": "MiningShip", "position": [0,0,0], "scale": [1,1,1] })
    execute({ "action": "add_component", "type": "Gameplay.ResourceInventory", "name": "MiningShip" })
    execute({ "action": "add_component", "type": "Gameplay.MiningLaser", "name": "MiningShip" })
    
    # 2. Setup Target in front of ship (Z-forward)
    execute({ "action": "create", "type": "cube", "name": "Iron_Ore_Vein", "position": [0,0,5], "scale": [2,2,2] })
    execute({ "action": "add_component", "type": "Gameplay.MiningTarget", "name": "Iron_Ore_Vein" })
    
    # 3. Start Firing
    log("Firing Laser...")
    execute({ 
        "action": "set_property", 
        "name": "MiningShip", 
        "type": "Gameplay.MiningLaser", 
        "propertyName": "isFiring", 
        "value": "true" 
    })
    
    # 4. Wait for Extraction
    time.sleep(2.0)
    
    # 5. Stop Firing
    execute({ 
        "action": "set_property", 
        "name": "MiningShip", 
        "type": "Gameplay.MiningLaser", 
        "propertyName": "isFiring", 
        "value": "false" 
    })
    
    log("Test Complete. Check logs for '[Inventory] Added...' messages.")

if __name__ == "__main__":
    test_mining_full()
