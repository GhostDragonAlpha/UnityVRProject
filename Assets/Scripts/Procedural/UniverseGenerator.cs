using UnityEngine;
using Core;

namespace Procedural
{
    /// <summary>
    /// The Architect.
    /// Uses Deterministic Principles (Golden Ratio) to place stars.
    /// Root Method: "GenerateOrigin" -> Places the Sun at (0,0,0).
    /// </summary>
    public class UniverseGenerator : MonoBehaviour
    {
        public int Seed = 0;
        public GameObject StarPrefab; // Must have Star component
        
        public void GenerateOrigin()
        {
            // Principle: The Observer starts at the Root.
            // Create "Sol"
            GameObject sunObj;
            if (StarPrefab != null)
            {
                sunObj = Instantiate(StarPrefab, Vector3.zero, Quaternion.identity);
            }
            else
            {
                sunObj = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                sunObj.GetComponent<Renderer>().material.color = Color.yellow;
                // Add Light
                var light = sunObj.AddComponent<Light>();
                light.type = LightType.Point;
                light.range = 1000f;
                light.intensity = 2f;
            }
            
            sunObj.name = "Sol";
            
            Core.Star sun = sunObj.GetComponent<Core.Star>();
            if (sun == null) sun = sunObj.AddComponent<Core.Star>();
            
            // Configure Sol (The Standard)
            // If Earth is 1e7, Sol should be ~3e12 (300,000x Earth mass ratio)
            sun.Mass = 1000000000000.0; // 1e12
            sun.Radius = 50.0; // Scaled for VR visibility, simpler than 1000 for now
            sun.Coordinates = new Vector3Int(0,0,0);
            
            // Register with Physics
            if (Core.PhysicsEngine.Instance != null)
            {
                Core.PhysicsEngine.Instance.RegisterBody(sun);
            }
            Debug.Log("[UniverseGenerator] Creating Earth...");
            // Create Earth (The Arena) at (200, 0, 0)
            GameObject earthObj = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            earthObj.name = "Earth";
            earthObj.transform.position = new Vector3(200, 0, 0);
            earthObj.transform.localScale = new Vector3(20, 20, 20); // Visual scale
            earthObj.GetComponent<Renderer>().material.color = Color.blue;
            
            Core.Planet planet = earthObj.AddComponent<Core.Planet>();
            // Tuning for g ~ 9.8 at R=10
            // 9.8 = G * M / 100
            // M = 980 / 0.0001 = 9,800,000
            planet.Mass = 9800000; 
            planet.Radius = 10.0;
            
            // 1:1 Coorindate System Initialization
            planet.Position = new Vector3d(200, 0, 0); 
            planet.Coordinates = new Vector3Int(200, 0, 0); 
            
            // Orbital Motion Principle: v = sqrt(GM/r) for circular orbit
            // r = 200
            // M (Sun) = 1.0 (Assume G=0.0001 from PhysicsEngine defaults for now)
            // But PhysicsEngine.Instance.G might vary.
            // Hardcoded approx for stability or dynamic?
            // Let's use robust dynamic calculation if possible, or static for Phase 0 proof.
            // v = sqrt(0.0001 * 1.0 / 200.0) = sqrt(0.0000005) ~= 0.000707
            // Direction: Tangent to (200,0,0) is (0,0,1)
            
            double G = 0.0001; // Must match PhysicsEngine
            double r = 200.0;
            double M_Sol = 1000000000000.0;
            double vMag = System.Math.Sqrt(G * M_Sol / r); 
            
            planet.Velocity = new Vector3d(0, 0, vMag);
            
             // Register with Physics
            if (Core.PhysicsEngine.Instance != null)
            {
                Core.PhysicsEngine.Instance.RegisterBody(planet);
            }
            
        }
    }
}
