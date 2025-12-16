import unity_bridge

def run_phase_2():
    unity_bridge.log("Starting Phase 2: Lattice & Gravity Drive Verification")
    unity_bridge.ensure_initialized()
    
    # 1. Ensure Infrastructure (WorldMover)
    # Check if exists, if not create.
    # Note: 'create' command usually duplicates if name exists unless unique logic handled in Bridge (it returns ID).
    # We will just create "WorldMover_System" and assume duplicates are harmless or handled.
    unity_bridge.log("Spawning WorldMover...")
    unity_bridge.execute({"action": "create", "type": "empty", "name": "WorldMover_System", "position": [0,0,0]})
    unity_bridge.execute({"action": "add_component", "type": "Core.WorldMover", "name": "WorldMover_System"})

    # 2. Spawn PlayerShip
    unity_bridge.log("Spawning PlayerShip...")
    unity_bridge.execute({"action": "create", "type": "cube", "name": "PlayerShip", "position": [0,0,0], "scale": [1,1,2]})
    unity_bridge.execute({"action": "add_component", "type": "UnityEngine.Rigidbody", "name": "PlayerShip"})
    
    # 3. Add Tech
    unity_bridge.log("Installing Gravity Drive & Lattice Renderer...")
    unity_bridge.execute({"action": "add_component", "type": "Gameplay.GravityDrive", "name": "PlayerShip"})
    unity_bridge.execute({"action": "add_component", "type": "Rendering.LatticeRenderer", "name": "PlayerShip"})
    
    # 4. Verification: Engage Warp
    # GravityDrive.WarpThreshold is 100 by default (from code).
    # Set Velocity to 200.
    unity_bridge.log("Engaging Gravity Drive (Velocity -> 200)...")
    unity_bridge.execute({"action": "set_property", "name": "PlayerShip", "type": "Gameplay.GravityDrive", "propertyName": "EnableGravitySlingshot", "value": "true"})
    
    # We need to set Rigidbody velocity. Bridge supports setting Component properties.
    # Rigidbody.velocity is a Vector3 property.
    unity_bridge.execute({"action": "set_property", "name": "PlayerShip", "type": "UnityEngine.Rigidbody", "propertyName": "velocity", "value": "0,0,200"})
    
    unity_bridge.log("Warp Engaged. Lattice should be VISIBLE and ORANGE (Gravity Distortion).")
    unity_bridge.log("Please verify in Unity Game View.")

if __name__ == "__main__":
    run_phase_2()
