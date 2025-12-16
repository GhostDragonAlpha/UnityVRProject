using UnityEngine;

namespace Core
{
    /// <summary>
    /// The fundamental atomic unit of the World Model.
    /// Represents any object with Mass that interacts via Gravity.
    /// </summary>
    [ExecuteAlways]
    public class CelestialBody : MonoBehaviour
    {
        [Header("Physical Properties")]
        [Tooltip("Mass in kg (scaled). 1.0 = Earth Mass standard.")]
        public double Mass = 1.0;

        [Tooltip("Radius in meters (scaled).")]
        public double Radius = 1000.0;

        [Header("Derived Physics")]
        [Tooltip("Current Velocity in measuring frame.")]
        public Vector3d Velocity;

        [Tooltip("Base Resonant Frequency derived from Mass/Density.")]
        public float ResonantFrequency;

        public Vector3d Position { get; set; } // High-precision position
        public Vector3Int Coordinates; // Sector Coordinates

        private void OnValidate()
        {
            // Principle: Frequency is a property of Matter.
            // Simplified derivation: f ~ sqrt(Density)
            // For game feel, we map Mass to a bounded frequency range (100Hz - 1000Hz)
            CalculateResonantFrequency();
        }

        private void Awake()
        {
            CalculateResonantFrequency();
        }

        private void OnEnable()
        {
            if (PhysicsEngine.Instance != null) PhysicsEngine.Instance.RegisterBody(this);
        }

        private void OnDisable()
        {
            if (PhysicsEngine.Instance != null) PhysicsEngine.Instance.UnregisterBody(this);
        }

        public void CalculateResonantFrequency()
        {
            // Deterministic hash-based frequency from Mass
            // This ensures the "Science" (Mass) dictates the "Tech" (Scanner Reading)
            double density = Mass / ((4.0/3.0) * System.Math.PI * System.Math.Pow(Radius, 3));
            
            // Map density to audible range
            // This satisfies the user's "Connecting Principle" requirement
            ResonantFrequency = (float)((density * 1000) % 900 + 100);
        }

        public void UpdatePosition(Vector3d delta)
        {
            Position += delta;
            // Removed direct transform update here to decouple Physics/Render
        }

        private void LateUpdate()
        {
             if (WorldMover.Instance != null)
             {
                 transform.position = (Position - WorldMover.Instance.VirtualPosition).ToVector3();
             }
        }
    }
}
