using UnityEngine;
using Core;

namespace SpacePhysics
{
    public class GravitySource : MonoBehaviour
    {
        [Header("Settings")]
        public double mass = 5.972e24; // Earth mass
        public double radius = 6371000; // Earth radius (m)
        
        // Cache the VirtualTransform for position access
        private VirtualTransform vt;

        public Vector3d Position
        {
            get 
            {
                if (vt == null) vt = GetComponent<VirtualTransform>();
                if (vt != null) return vt.WorldPosition;
                return new Vector3d(transform.position.x, transform.position.y, transform.position.z); // Fallback
            }
        }

        private void OnEnable()
        {
            if (GravitySystem.Instance != null) GravitySystem.Instance.RegisterSource(this);
        }

        private void OnDisable()
        {
            if (GravitySystem.Instance != null) GravitySystem.Instance.UnregisterSource(this);
        }
    }
}
