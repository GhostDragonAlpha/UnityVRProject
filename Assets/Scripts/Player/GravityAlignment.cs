using UnityEngine;
using Core;

namespace Player
{
    /// <summary>
    /// Connects the entity to the Local Gravity Field.
    /// Aligns 'Up' with the opposing force of gravity.
    /// Aligns 'Up' with the opposing force of gravity.
    /// </summary>
    [ExecuteAlways]
    [RequireComponent(typeof(Rigidbody))]
    public class GravityAlignment : MonoBehaviour
    {
        public bool AlignToGravity = true;
        public float RotationSpeed = 10f;
        public bool RunInEditor = true;

        private Rigidbody rb;
        private void OnEnable()
        {
#if UNITY_EDITOR
             UnityEditor.EditorApplication.update += EditorUpdate;
#endif
        }

        private void OnDisable()
        {
#if UNITY_EDITOR
             UnityEditor.EditorApplication.update -= EditorUpdate;
#endif
        }

        private void EditorUpdate()
        {
             if (!Application.isPlaying && RunInEditor)
             {
                  Align(Time.deltaTime);
             }
        }

        private VirtualTransform vTransform;

        private void Start()
        {
            rb = GetComponent<Rigidbody>();
            vTransform = GetComponent<VirtualTransform>();
        }

        private void Update()
        {
            // Standard Update
        }

        private void FixedUpdate()
        {
            if (Application.isPlaying)
            {
                Align(Time.fixedDeltaTime);
            }
        }
        
        public void ManualUpdate(float dt)
        {
             Align(dt);
        }

        private void Align(float dt)
        {
            if (PhysicsEngine.Instance == null) return;

            Vector3d pos = (vTransform != null) ? vTransform.WorldPosition : new Vector3d(transform.position.x, transform.position.y, transform.position.z);
            Vector3 gravity = PhysicsEngine.Instance.CalculateGravityAtPoint(pos, 1.0);
            
            // Debug Log
            if (!Application.isPlaying) 
               Debug.Log($"[GravityAlignment] Pos: {pos}, Gravity: {gravity}, Bodies: {PhysicsEngine.Instance.Bodies.Count}, Align: {AlignToGravity}, Up: {transform.up}");

             // Apply Force (Play Mode Only)
            if (Application.isPlaying)
            {
                 rb.useGravity = false;
                 rb.AddForce(gravity * rb.mass);
            }

            // Align Rotation
            if (AlignToGravity)
            {
               // Debug.Log($"[GravityAlignment] Aligning... Mag: {gravity.sqrMagnitude}");
               if (gravity.sqrMagnitude > 0.001f)
               {
                   Vector3 upDir = -gravity.normalized;
                   // Instant or Smooth? Smooth for game, Instant for Editor?
                   Quaternion targetRot = Quaternion.FromToRotation(transform.up, upDir) * transform.rotation;
                   
                   if (Application.isPlaying)
                      transform.rotation = Quaternion.Slerp(transform.rotation, targetRot, RotationSpeed * dt);
                   else
                   {
                        // Debug.Log("[GravityAlignment] Instant Rotate in Editor");
                        transform.rotation = targetRot; // Instant in Editor
                   }
               }
            }
        }
    }
}
