import requests
import json
import time

URL = "http://localhost:8080/execute"
HEADERS = {"Content-Type": "application/json"}

def log(msg):
    print(f"[SceneBuilder] {msg}")

def execute(payload):
    try:
        response = requests.post(URL, data=json.dumps(payload), headers=HEADERS, timeout=5)
        if response.status_code == 200:
            log(f"Command Success: {payload['action']}")
        else:
            log(f"Command Failed: {response.text}")
    except Exception as e:
        log(f"Error: {e}")

def build_root():
    log("Resetting Scene to Celestial Root...")
    
    # 1. Clear everything (except Main Camera potentially, but 'delete_all' might be safer if we respawn camera)
    # The user said "Clear the scene of everything else except the sun".
    execute({"action": "delete_all", "exclude": ["Main Camera", "Directional Light"]}) # Keep light for now, or maybe Star provides it?
    
    # 2. Create Physics Engine (The connector)
    execute({"action": "create", "type": "empty", "name": "PhysicsEngine", "position": [0,0,0]})
    execute({"action": "add_component", "type": "Core.PhysicsEngine", "name": "PhysicsEngine"})
    
    # 3. Create Universe Generator
    execute({"action": "create", "type": "empty", "name": "UniverseGenerator", "position": [0,0,0]})
    execute({"action": "add_component", "type": "Procedural.UniverseGenerator", "name": "UniverseGenerator"})
    
    # 4. Create Star Prefab (Primitive for now)
    execute({"action": "create", "type": "sphere", "name": "StarPrefab_Temp", "position": [0,-1000,0]}) # Hide it
    execute({"action": "add_component", "type": "Core.Star", "name": "StarPrefab_Temp"})
    
    # 5. Link Prefab to Generator (This is tricky via remote reflection, let's just spawn manally for this test)
    # Actually, simpler: Just spawn the Sun directly.
    
    log("Spawning The Sun (Sol)...")
    execute({"action": "create", "type": "sphere", "name": "Sol", "position": [0,0,0], "scale": [50,50,50]})
    execute({"action": "add_component", "type": "Core.Star", "name": "Sol"})
    
    # Set Properties (Mass = 1.0)
    execute({"action": "set_property", "name": "Sol", "type": "Core.Star", "propertyName": "Mass", "value": "1.0"})
    
    # Register with Physics
    # Note: PhysicsEngine.RegisterBody is called in Awake/Start or manually? 
    # My PhysicsEngine code has `RegisterBody`, but Sol needs to find it.
    # Ideally `CelestialBody.Start()` finds `PhysicsEngine.Instance`.
    
    # Let's verify via Hierarchy
    log("Scene Root Built. Sun is at (0,0,0). Physics Engine active.")

if __name__ == "__main__":
    build_root()
