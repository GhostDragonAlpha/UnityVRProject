using UnityEngine;

namespace Core
{
    /// <summary>
    /// A Celestial Body that supports Life and Terrain.
    /// Branch: Derived from CelestialBody.
    /// </summary>
    public class Planet : CelestialBody
    {
        [Header("Planetary Properties")]
        public bool HasAtmosphere = false;
        public Color AtmosphereColor = Color.blue;
        
        [Header("Terrain")]
        public float TerrainRoughness = 1.0f;
        // Future: VoxelTerrain generator reference
        
        private void OnValidate()
        {
            // Calculate base frequency from Mass
            CalculateResonantFrequency();
        }
        
        /// <summary>
        /// Calculates the orbital velocity required for a stable circular orbit around a parent body.
        /// Principle: v = sqrt(G * M_parent / r)
        /// </summary>
        public Vector3 CalculateOrbitalVelocity(CelestialBody parent)
        {
            if (parent == null) return Vector3.zero;
            
            float G = PhysicsEngine.Instance != null ? (float)PhysicsEngine.Instance.G : 0.0001f; // Fallback to standard G
            
            Vector3 directionToParent = parent.transform.position - transform.position;
            float distance = directionToParent.magnitude;
            
            // v = sqrt(GM/r)
            // Note: If using PhysicsEngine G, make sure it matches. 
            // We'll rely on PhysicsEngine.GravitationalConstant if accessible, strictly implies Physics is Singleton.
            
            float velocityMagnitude = Mathf.Sqrt(G * (float)parent.Mass / distance);
            
            // Perpendicular vector for orbit (Clockwise or Counter-Clockwise)
            Vector3 orbitDirection = Vector3.Cross(directionToParent.normalized, Vector3.up);
            
            return orbitDirection * velocityMagnitude;
        }
    }
}
