using UnityEngine;
using System.Collections.Generic;

namespace Core
{
    /// <summary>
    /// The Connecting Principle: N-Body Gravity.
    /// Connects every CelestialBody to every other CelestialBody.
    /// F = G * m1 * m2 / r^2
    /// </summary>
    /// F = G * m1 * m2 / r^2
    /// </summary>
    [ExecuteAlways]
    public class PhysicsEngine : MonoBehaviour
    {
        public static PhysicsEngine Instance;

        // Gravitational Constant (Scaled for game-feel)
        // Check PhysicsEngine.gd for original value: 6.674e-23 (if using kg/m)
        // We might need to tune this for Unity units.
        // Gravitational Constant (Scaled for game-feel)
        // Check PhysicsEngine.gd for original value: 6.674e-23 (if using kg/m)
        // We might need to tune this for Unity units.
        public double G = 0.0001; 

        public List<CelestialBody> Bodies = new List<CelestialBody>();

        [Header("Simulation Settings")]
        public float TimeScale = 1.0f;
        public int SubSteps = 4;

        private void Awake()
        {
            Instance = this;
            Physics.gravity = Vector3.zero; // Disable Unity Default Gravity
        }

        private void Start()
        {
            // Auto-register existing bodies (Fixes Execution Order issues)
            foreach (var body in FindObjectsByType<CelestialBody>(FindObjectsSortMode.None))
            {
                RegisterBody(body);
            }
        }

        public void RegisterBody(CelestialBody body)
        {
            if (!Bodies.Contains(body)) Bodies.Add(body);
        }

        public void UnregisterBody(CelestialBody body)
        {
            Bodies.Remove(body);
        }

        private void FixedUpdate()
        {
            if (Bodies.Count == 0) return;

            float dt = Time.fixedDeltaTime * TimeScale;
            float stepDt = dt / SubSteps;

            for (int step = 0; step < SubSteps; step++)
            {
                StepSimulation(stepDt);
            }
        }

        public Vector3 CalculateGravityAtPoint(Vector3d point, double massOfObject)
        {
            Vector3d totalAcceleration = Vector3d.Zero;

            foreach (var body in Bodies)
            {
                Vector3d direction = body.Position - point;
                double distSq = direction.SqrMagnitude;
                
                if (distSq < 0.001) continue;

                double force = G * body.Mass / distSq;
                totalAcceleration += direction.Normalized * force;
            }

            return totalAcceleration.ToVector3(); // Return as Unity Vector3 for rendering/physics interface
        }

        private void StepSimulation(float dt)
        {
            // Calculate Forces
            Vector3d[] accelerations = new Vector3d[Bodies.Count];

            for (int i = 0; i < Bodies.Count; i++)
            {
                for (int j = i + 1; j < Bodies.Count; j++)
                {
                    CelestialBody a = Bodies[i];
                    CelestialBody b = Bodies[j];

                    Vector3d direction = b.Position - a.Position;
                    double distanceSq = direction.x*direction.x + direction.y*direction.y + direction.z*direction.z;
                    double distance = System.Math.Sqrt(distanceSq);

                    // F = G * m1 * m2 / r^2
                    // F = ma -> a = F/m
                    // a = G * m2 / r^2
                    
                    if (distance < 0.001) continue; // Avoid singularity

                    double forceMagnitude = G / distanceSq; // Mass is multiplied in acceleration calc
                    
                    Vector3d forceDir = direction.Normalized;
                    
                    // Acceleration applied to A form B
                    accelerations[i] += forceDir * (forceMagnitude * b.Mass);

                    // Acceleration applied to B from A (Newton's 3rd Law)
                    accelerations[j] -= forceDir * (forceMagnitude * a.Mass);
                }
            }

            // Apply Velocity & Position
            for (int i = 0; i < Bodies.Count; i++)
            {
                CelestialBody b = Bodies[i];
                
                // v = v + a*t
                b.Velocity += accelerations[i] * dt;
                
                // p = p + v*t
                Vector3d deltaPos = b.Velocity * dt;
                b.UpdatePosition(deltaPos);
            }
        }
    }
}
