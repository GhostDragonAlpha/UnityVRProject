using UnityEngine;
using System.Collections.Generic;
using Core;

namespace SpacePhysics
{
    public class GravitySystem : MonoBehaviour
    {
        public static GravitySystem Instance;

        [Header("Settings")]
        public double G = 6.674e-11; // Universal Constant
        public bool gravityEnabled = true;

        private List<GravitySource> sources = new List<GravitySource>();

        private void Awake()
        {
            Instance = this;
        }

        public void RegisterSource(GravitySource source)
        {
            if (!sources.Contains(source)) sources.Add(source);
        }

        public void UnregisterSource(GravitySource source)
        {
            if (sources.Contains(source)) sources.Remove(source);
        }

        private void FixedUpdate()
        {
            if (!gravityEnabled) return;

            // 1. Apply Gravity to Player (WorldMover)
            if (WorldMover.Instance != null)
            {
                Vector3d playerPos = WorldMover.Instance.VirtualPosition;
                Vector3d totalAccel = Vector3d.Zero;

                foreach (var source in sources)
                {
                    totalAccel += CalculateAcceleration(playerPos, source);
                }

                // Apply to Virtual Velocity
                WorldMover.Instance.VirtualVelocity += totalAccel * Time.fixedDeltaTime;
                
                if (Time.frameCount % 60 == 0) // Log once per second approx
                {
                   Debug.Log($"[Physics] Velocity: {WorldMover.Instance.VirtualVelocity.ToString()}");
                }
            }

            // 2. Apply Gravity to Other Virtual Objects (Asteroids etc)
            // Note: We need a way to iterate all VirtualTransforms. 
            // WorldMover has the list but it's private. Ideally WorldMover exposes it or we register here too.
            // For MVP, let's assume valid physics require GravitySystem to know about them or WorldMover to callback.
            // Simplified: We skip applying gravity to "Asteroids" for now unless we refactor VirtualTransform to register with GravitySystem.
            // ... Let's make VirtualTransform register with GravitySystem if it has a Rigidbody equivalent or just a flag 'useGravity'.
        }

        private Vector3d CalculateAcceleration(Vector3d pos, GravitySource source)
        {
             Vector3d delta = source.Position - pos;
             double distSq = delta.x * delta.x + delta.y * delta.y + delta.z * delta.z;
             double dist = System.Math.Sqrt(distSq);

             if (dist < 1.0) dist = 1.0; // Avoid singularity

             // F = G * M * m / r^2
             // a = F / m = G * M / r^2
             double accelerationMagnitude = (G * source.mass) / distSq;
             
             // Direction = delta / dist (Normalized)
             Vector3d direction = delta * (1.0 / dist);

             return direction * accelerationMagnitude;
        }
    }
}
