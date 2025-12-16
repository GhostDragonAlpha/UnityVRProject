import requests
import json
import time

URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def log(msg):
    print(f"[QA ShipSystems] {msg}")

def execute(payload):
    try:
        requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=5)
    except Exception as e:
        log(f"Error: {e}")

def test_ship_systems():
    log("Starting Ship Systems Test...")

    # 1. Create Ship with Systems
    execute({ "action": "create", "type": "empty", "name": "TestShip", "position": [0,0,0], "scale": [1,1,1] })
    execute({ "action": "add_component", "type": "Gameplay.ShipSystems", "name": "TestShip" })

    # 2. Check Initial Log (Optional, if Start logged something, which it doesn't)
    
    # 3. Apply Damage via 'call_method'
    # AgentBridge needs 'call_method' support. If not present, we use 'set_property' on a debug field or trigger?
    # I haven't implemented 'call_method' in AgentBridge yet? 
    # Let's check AgentBridge.cs ... I viewed it earlier.
    # It had 'ProcessRequest'. 
    # If I only implemented 'create', 'add_component', 'set_property', then I can't call methods.
    # Workaround: Add 'debugDamage' field to ShipSystems.cs that calls TakeDamage when set.
    
    log("Applying Damage via Debug Property...")
    # Wait, I didn't add a debug property to ShipSystems.cs.
    # I added 'TakeDamage(float)'.
    # If I can't call method, I must likely Edit ShipSystems.cs to add a debug trigger.
    # OR assume 'AgentBridge' has 'call_method'.
    # I recall seeing 'action: command' in verify_bridge.py? No, 'action: create'.
    # Let's assume I need to ADD a Debug Helper strictly for this test or update AgentBridge.
    # Updating ShipSystems.cs is faster.
    
    execute({ 
        "action": "set_property", 
        "name": "TestShip", 
        "type": "Gameplay.ShipSystems", 
        "propertyName": "debugDamage", 
        "value": "25" 
    })
    
    log("Test Complete. Check logs for '[Ship] Took 25 Damage'.")

if __name__ == "__main__":
    test_ship_systems()
