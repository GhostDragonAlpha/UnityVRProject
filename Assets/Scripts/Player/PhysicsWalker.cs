using UnityEngine;

namespace Player
{
    /// <summary>
    /// Locomotion logic for Surface Traversal.
    /// Operates relative to the current Up alignment.
    /// </summary>
    [RequireComponent(typeof(Rigidbody))]
    public class PhysicsWalker : MonoBehaviour
    {
        public float WalkSpeed = 5f;
        public float JumpForce = 500f;
        public LayerMask GroundLayers;

        private Rigidbody rb;
        private bool isGrounded;

        private void Start()
        {
            rb = GetComponent<Rigidbody>();
        }

        private void Update()
        {
            // Input Processing (Methodology: Input -> Physics)
            float h = Input.GetAxis("Horizontal");
            float v = Input.GetAxis("Vertical");
            bool jump = Input.GetButtonDown("Jump");

            // Move
            Vector3 targetVel = (transform.forward * v + transform.right * h) * WalkSpeed;
            
            // We only want to control Horizontal Velocity (relative to surface), not Vertical (Falling)
            // Project current velocity onto ground plane
            Vector3 velocity = rb.linearVelocity;
            Vector3 velocityProjected = Vector3.ProjectOnPlane(velocity, transform.up);
            
            // Calculate force needed to reach target velocity
            Vector3 diff = targetVel - velocityProjected;
            
            if (isGrounded)
            {
                rb.AddForce(diff * 5f, ForceMode.Acceleration);
            }

            // Jump
            if (jump && isGrounded)
            {
                rb.AddForce(transform.up * JumpForce, ForceMode.Impulse);
            }
        }

        private void FixedUpdate()
        {
            // Check Ground (The Connection to the Soil)
            // Simple Raycast
            isGrounded = Physics.Raycast(transform.position, -transform.up, 1.1f, GroundLayers);
        }
    }
}
