import unity_bridge
import time

import unity_bridge
import time

def build_full_level():
    unity_bridge.log("Building Full Level (BATCH MODE)...")
    unity_bridge.ensure_initialized()

    batch_cmds = []

    # 1. Reset & Infrastructure
    batch_cmds.append({"action": "delete_all", "exclude": ["Main Camera", "Directional Light"]})
    batch_cmds.append({"action": "create", "type": "empty", "name": "Cosmos", "position": [0,0,0]})
    
    # Physics
    batch_cmds.append({"action": "create", "type": "empty", "name": "Physics", "parent": "Cosmos"})
    batch_cmds.append({"action": "add_component", "type": "Core.PhysicsEngine", "name": "Physics"})

    # Generator
    batch_cmds.append({"action": "create", "type": "empty", "name": "Generator", "parent": "Cosmos"})
    batch_cmds.append({"action": "add_component", "type": "Procedural.UniverseGenerator", "name": "Generator"})

    # 2. Celestial Bodies (Sol)
    batch_cmds.append({"action": "create", "type": "sphere", "name": "Sol", "position": [0,0,0], "scale": [50,50,50], "parent": "Cosmos"})
    batch_cmds.append({"action": "add_component", "type": "Core.Star", "name": "Sol"})
    batch_cmds.append({"action": "set_property", "name": "Sol", "type": "Core.Star", "propertyName": "Mass", "value": "1.0"})

    # Earth
    batch_cmds.append({"action": "create", "type": "sphere", "name": "Earth", "position": [200,0,0], "scale": [10,10,10], "parent": "Cosmos"})
    batch_cmds.append({"action": "add_component", "type": "Core.Planet", "name": "Earth"})
    # Orbital Velocity
    batch_cmds.append({"action": "set_property", "name": "Earth", "type": "UnityEngine.Rigidbody", "propertyName": "velocity", "value": "0,0,0.707"})

    # 3. Player & Tech
    batch_cmds.append({"action": "create", "type": "cube", "name": "PlayerShip", "position": [180, 20, 0], "scale": [1,1,2], "parent": "Cosmos"})
    batch_cmds.append({"action": "add_component", "type": "UnityEngine.Rigidbody", "name": "PlayerShip"})
    batch_cmds.append({"action": "add_component", "type": "Gameplay.GravityDrive", "name": "PlayerShip"})
    batch_cmds.append({"action": "add_component", "type": "Rendering.LatticeRenderer", "name": "PlayerShip"})
    
    # Warp State
    batch_cmds.append({"action": "set_property", "name": "PlayerShip", "type": "UnityEngine.Rigidbody", "propertyName": "velocity", "value": "0,0,200"})

    # 4. WorldMover
    batch_cmds.append({"action": "create", "type": "empty", "name": "WorldMover", "position": [0,0,0]})
    batch_cmds.append({"action": "add_component", "type": "Core.WorldMover", "name": "WorldMover"})

    # 5. Camera
    cam = "Main Camera"
    batch_cmds.append({"action": "set_property", "name": cam, "type": "UnityEngine.Transform", "propertyName": "position", "value": "180,40,-30"})
    batch_cmds.append({"action": "set_property", "name": cam, "type": "UnityEngine.Transform", "propertyName": "eulerAngles", "value": "20,-10,0"})

    # 6. Save Scene (User Request)
    batch_cmds.append({"action": "save_scene"})

    # EXECUTE BATCH
    success, msg = unity_bridge.execute_batch(batch_cmds)
    if success:
        unity_bridge.log("Batch Build Complete.")
    else:
        unity_bridge.log(f"Batch Build Failed: {msg}")

if __name__ == "__main__":
    build_full_level()

if __name__ == "__main__":
    build_full_level()
