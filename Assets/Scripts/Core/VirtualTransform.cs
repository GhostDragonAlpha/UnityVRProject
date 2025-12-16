using UnityEngine;

namespace Core
{
    public class VirtualTransform : MonoBehaviour
    {
        public Vector3d WorldPosition;
        public Vector3d VirtualPosition { get { return WorldPosition; } set { WorldPosition = value; } }
        
        [Header("Debug")]
        public Vector3 initialUnityOffset; 

        private void Start()
        {
            // Initialize virtual position from initial Unity placement (relative to 0,0,0 start)
            initialUnityOffset = transform.position;
            WorldPosition = new Vector3d(initialUnityOffset.x, initialUnityOffset.y, initialUnityOffset.z);
            
            if (WorldMover.Instance != null)
            {
                WorldMover.Instance.Register(this);
            }
        }

        private void OnDestroy()
        {
            if (WorldMover.Instance != null)
            {
                WorldMover.Instance.Unregister(this);
            }
        }
    }
}
