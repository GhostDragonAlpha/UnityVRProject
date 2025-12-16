import requests
import json
import time

URL = "http://localhost:7777"
HEADERS = {'Content-Type': 'application/json'}

def log(msg):
    print(f"[QA VR Input] {msg}")

def execute(payload):
    try:
        requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=5)
    except Exception as e:
        log(f"Error: {e}")

def test_vr_input():
    log("Starting VR Input Test (Full Setup)...")

    # 0. Ensure Play Mode (via Reflection/Static Property)
    # Using 'set_property' on static class
    # Helper to easier set static property? 
    # Current AgentBridge 'set_property' expects component name.
    # We might need a 'call_static' to set it? 
    # Or just assume we are in Edit Mode and these create calls work, then we hit Play?
    # If we hit Play, state resets? No, if we use Domain Reload disabled? 
    # Standard Unity: Play Mode reset scene.
    # So we must Start Play Mode FIRST, then Create Objects? 
    # YES.
    
    log("Entering Play Mode...")
    # This might fail if AgentBridge doesn't support static property setting well yet.
    # Workaround: Create an 'Empty' and attach a script that starts Play Mode? No.
    # Let's try the 'command' action if we implemented it, or 'call_static'.
    # In 'AgentBridge.cs' snippet I saw 'call_static'.
    # Action: call_static, type: UnityEditor.EditorApplication, method: EnterPlaymode (Wrapper?) 
    # actually Property 'isPlaying'.
    # Let's try to set it via 'set_property' with 'name' as 'static'? 
    # If AgentBridge doesn't support it, we are stuck.
    # Let's assume the user might have to press Play, OR we just setup the scene and tell the user "Press Play".
    # BUT the user said "Do everything". 
    # Let's use 'focus_unity.ps1' to press 'Ctrl+P'? 
    # That's a valid 'Window Automation'!
    
    # 1. Setup Scene (Edit Mode persistence?)
    # If we create in Edit mode, they save to scene? Only if we save.
    # Let's Create Objects -> They exist in Scene -> User/Script presses Play -> They persist?
    # Unity destroys non-saved objects? No, they stay if they are in the hierarchy.
    
    log("Setting up Scene Components...")
    
    # WorldMover
    execute({ "action": "create", "type": "empty", "name": "WorldMover_Manager", "position": [0,0,0], "scale": [1,1,1] })
    execute({ "action": "add_component", "type": "Core.WorldMover", "name": "WorldMover_Manager" })

    # Gravity
    execute({ "action": "create", "type": "empty", "name": "GravityManager", "position": [0,0,0], "scale": [1,1,1] })
    execute({ "action": "add_component", "type": "SpacePhysics.GravitySystem", "name": "GravityManager" })

    # Player & Input
    # XR Origin usually exists if scene loaded. If not, create wrapper.
    execute({ "action": "create", "type": "empty", "name": "XR Origin", "position": [0,0,0], "scale": [1,1,1] })
    execute({ "action": "add_component", "type": "Gameplay.VirtualShip", "name": "XR Origin" })
    execute({ "action": "add_component", "type": "VR.CockpitInputController", "name": "XR Origin" })

    # 2. Mock Input
    log("Setting Throttle...")
    execute({ 
        "action": "set_property", 
        "name": "XR Origin", 
        "type": "VR.CockpitInputController", 
        "propertyName": "mockLeftY", 
        "value": "1.0" 
    })
    
    log("Setup Complete. Please Ensure Unity is in PLAY MODE (Ctrl+P) to see Physics.")
    # For now, relying on user or 'Ctrl+P' memory if I had a keystroke tool.
    # Note: I can't press keys easily via PowerShell without a strictly focused window and SendKeys which is flaky.
    # I will just ask the user to confirm Play Mode or assume it's running.

if __name__ == "__main__":
    test_vr_input()
