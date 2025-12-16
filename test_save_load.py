import requests
import json
import time

URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def log(msg):
    print(f"[QA SaveLoad] {msg}")

def execute(payload):
    try:
        requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=5)
    except Exception as e:
        log(f"Error: {e}")

def test_save_load():
    log("Starting Save/Load Test...")

    # 1. Setup Scene (Manager, Player, Ship)
    execute({ "action": "create", "type": "empty", "name": "GameRoot", "position": [0,0,0], "scale": [1,1,1] })
    # Add Managers
    execute({ "action": "add_component", "type": "Core.WorldMover", "name": "GameRoot" })
    execute({ "action": "add_component", "type": "Gameplay.ShipSystems", "name": "GameRoot" })
    execute({ "action": "add_component", "type": "Gameplay.ResourceInventory", "name": "GameRoot" })
    execute({ "action": "add_component", "type": "Gameplay.Persistence.SaveManager", "name": "GameRoot" })

    # 2. Modify State (Set Health to 50, Add Inventory)
    log("Modifying State...")
    # Health -> 50
    # Note: ShipSystems has regen. It might regen before we save if we are slow.
    # Health regen isn't implemented? ShipSystems has Energy Regen only. Health is static unless damaged.
    execute({ 
        "action": "set_property", 
        "name": "GameRoot", 
        "type": "Gameplay.ShipSystems", 
        "propertyName": "health", 
        "value": "50" 
    })
    
    # Inventory -> Add Iron: 10
    # Can't easily invoke AddResource via AgentBridge (no method call).
    # But SaveManager uses serialized dictionary.
    # Ideally, we verify Health persistence which is easiest.
    
    # 3. Save Game
    log("Saving Game...")
    execute({ 
        "action": "set_property", 
        "name": "GameRoot", 
        "type": "Gameplay.Persistence.SaveManager", 
        "propertyName": "triggerSave", 
        "value": "true" 
    })
    
    time.sleep(2.0)
    
    # 4. Modify State Again (Scramble)
    log("Scrambling State (Health -> 10)...")
    execute({ 
        "action": "set_property", 
        "name": "GameRoot", 
        "type": "Gameplay.ShipSystems", 
        "propertyName": "health", 
        "value": "10" 
    })
    
    time.sleep(1.0)
    
    # 5. Load Game
    log("Loading Game...")
    execute({ 
        "action": "set_property", 
        "name": "GameRoot", 
        "type": "Gameplay.Persistence.SaveManager", 
        "propertyName": "triggerLoad", 
        "value": "true" 
    })
    
    # 6. Verify (Manual Check logs for now, or assume if health was restored it worked)
    # Since we can't GET property values via AgentBridge easy (GET /hierarchy returns dump but maybe too big),
    # checking Unity Console logs: "[SaveManager] Game Loaded" and ShipSystems debug logs could help.
    # ShipSystems doesn't log on health set.
    # But SaveManager logs "Game Loaded".
    
    log("Test Complete. Check logs for '[SaveManager] Game Loaded' and verify Health is 50 in Inspector.")

if __name__ == "__main__":
    test_save_load()
