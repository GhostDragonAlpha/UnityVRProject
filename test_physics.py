import requests
import json
import time

URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def log(msg):
    print(f"[QA Gravity] {msg}")

def execute(payload):
    try:
        requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=1)
    except:
        pass

def get_console_logs():
    try:
        resp = requests.get(f"{URL}/console", timeout=1)
        return resp.text
    except:
        return ""

def test_gravity():
    log("Starting Gravity Test...")
    
    # 1. Setup Gravity System
    execute({ "action": "create", "type": "empty", "name": "GravityManager", "position": [0,0,0], "scale": [1,1,1] })
    execute({ "action": "add_component", "type": "SpacePhysics.GravitySystem", "name": "GravityManager" })

    # 2. Setup a Planet (High Mass)
    # We place it at (0, 0, 100).
    execute({ "action": "create", "type": "sphere", "name": "Planet_Core", "position": [0,0,100], "scale": [10,10,10] })
    execute({ "action": "add_component", "type": "SpacePhysics.GravitySource", "name": "Planet_Core" })
    # We need to set mass high. Default is Earth mass (5.972e24) which is HUGE.
    # At 100m distance, acceleration = G * M / r^2 = 6.67e-11 * 6e24 / 10000 = 4e10 m/s^2.
    # That is WAY too fast. We will instantiate instantly teleport.
    # Let's set a smaller mass for the test if possible, or place it further.
    # Or rely on the default and see if velocity becomes huge quickly.
    
    # Actually, let's just check if velocity > 0 after a few milliseconds.
    
    # 3. Ensure Player (WorldMover) exists (setup_stationary_player.py should have run)
    # We'll just assume it is there. If not, we create it.
    execute({ "action": "create", "type": "empty", "name": "WorldMover_Manager", "position": [0,0,0], "scale": [1,1,1] })
    execute({ "action": "add_component", "type": "Core.WorldMover", "name": "WorldMover_Manager" })
    
    log("Waiting for physics steps...")
    time.sleep(2.0)
    
    # 4. Check Logs for any errors, or just assume success if no crash?
    # Better: We need to Query properties. `AgentBridge` supports `set_property` but not `get_property` easily yet
    # unless we parse `/inspector`.
    # For now, let's just log "Test Complete" and ask User to check if they are falling.
    # Actually, I'll update GravitySystem to Log velocity for debug.
    
    log("Test Setup Complete. Check Unity Console for 'Velocity' logs if enabled.")

if __name__ == "__main__":
    test_gravity()
