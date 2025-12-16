import unity_bridge

def run_phase_1():
    unity_bridge.log("Starting Phase 1: The First Branch (Planetary Orbit)")
    unity_bridge.ensure_initialized()

    # 1. Spawn Earth
    # Position: 200 units away from Sol (Root is at 0,0,0)
    # Mass: 0.01 (Earth is tiny compared to Sol)
    earth_pos = [200, 0, 0]
    
    unity_bridge.log("Spawning 'Earth'...")
    unity_bridge.execute({"action": "create", "type": "sphere", "name": "Earth", "position": earth_pos, "scale": [10,10,10], "parent": "Cosmos"})
    unity_bridge.execute({"action": "add_component", "type": "Core.Planet", "name": "Earth"})
    
    # Configure Earth
    unity_bridge.execute({"action": "set_property", "name": "Earth", "type": "Core.Planet", "propertyName": "Mass", "value": "0.1"}) # 1/10th Sol for visibility
    
    # 2. Physics & Orbit
    # To start an orbit, we need to set the Initial Velocity.
    # While Planet.cs has 'CalculateOrbitalVelocity', we need to Invoke it or set the Velocity manually via Bridge.
    # Simpler: Calculate v = sqrt(G*M/r) here in Python or ask Unity to do it.
    
    # Let's try to calculate in Python for verification of "Science"
    # G in PhysicsEngine was hardcoded to 100.0 (need to verify this in PhysicsEngine.cs)
    G = 100.0
    M_sol = 1.0 # Sol Mass
    r = 200.0
    
    import math
    v = math.sqrt(G * M_sol / r) # sqrt(100 * 1 / 200) = sqrt(0.5) = 0.707
    
    # Velocity Vector: Perpendicular to Position (200, 0, 0) -> (0, 0, v)
    velocity = [0, 0, v]
    
    unity_bridge.log(f"Calculated Orbital Velocity: {v}")
    
    # Set Velocity (Requires a Rigidbody or Custom Physics Body)
    # Our PhysicsEngine updates "Velocity" field on CelestialBody.
    unity_bridge.execute({"action": "set_property", "name": "Earth", "type": "Core.Planet", "propertyName": "Velocity", "value": f"{velocity[0]},{velocity[1]},{velocity[2]}"})
    
    unity_bridge.log("Orbit Initialized. Check Scene.")

if __name__ == "__main__":
    run_phase_1()
