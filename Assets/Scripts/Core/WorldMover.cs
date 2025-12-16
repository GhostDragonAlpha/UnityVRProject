using UnityEngine;
using System.Collections.Generic;

namespace Core
{


    [ExecuteAlways]
    public class WorldMover : MonoBehaviour
    {
        public static WorldMover Instance;

        [Header("Player State")]
        public Vector3d VirtualPosition;
        public Vector3d VirtualVelocity;

        [Header("Settings")]
        public float renderDistance = 10000f;

        private List<VirtualTransform> registeredObjects = new List<VirtualTransform>();

        private void Awake()
        {
            Instance = this;
        }

        private void LateUpdate()
        {
            // Update Player Virtual Position
            VirtualPosition += VirtualVelocity * Time.deltaTime;

            // Update all registered virtual objects
            foreach (var obj in registeredObjects)
            {
                if (obj == null) continue;
                UpdateObjectPosition(obj);
            }
        }

        public void Register(VirtualTransform obj)
        {
            if (!registeredObjects.Contains(obj)) registeredObjects.Add(obj);
        }

        public void Unregister(VirtualTransform obj)
        {
            if (registeredObjects.Contains(obj)) registeredObjects.Remove(obj);
        }

        private void UpdateObjectPosition(VirtualTransform obj)
        {
            // Calculate relative position: Object - Player
            Vector3d relativePos = obj.WorldPosition - VirtualPosition;

            // Check distance
            Vector3 floatPos = relativePos.ToVector3();
            if (floatPos.magnitude > renderDistance)
            {
                // Too far - disable or hide (simple culling)
                obj.gameObject.SetActive(false);
            }
            else
            {
                obj.gameObject.SetActive(true);
                obj.transform.position = floatPos; // Place object relative to stationary player (0,0,0)
            }
        }
    }
}
