using UnityEngine;
using Core;

namespace Gameplay
{
    /// <summary>
    /// 6DOF Flight Controller powered by Gravity manipulation.
    /// "Map Mode" (Lattice) engages at high speeds.
    /// </summary>
    [RequireComponent(typeof(Rigidbody))]
    public class GravityDrive : MonoBehaviour
    {
        [Header("Flight Characteristics")]
        public float Acceleration = 50f;
        public float RotationSpeed = 2.0f;
        public float MaxSpeed = 500f; // Warp Threshold
        public float WarpThreshold = 100f;
        
        [Header("Physics Link")]
        public bool EnableGravitySlingshot = true;
        
        private Rigidbody rb;
        private Vector3 inputVector;
        private Vector3 rotationInput;
        
        // State
        public bool IsWarping => rb.linearVelocity.magnitude > WarpThreshold;
        public float CurrentSpeed => rb.linearVelocity.magnitude;

        private void Start()
        {
            rb = GetComponent<Rigidbody>();
            rb.useGravity = false; // We use Custom PhysicsEngine
            rb.linearDamping = 1.0f; // Space drag
        }

        private void Update()
        {
            HandleInput();
        }

        private void FixedUpdate()
        {
            ApplyMovement();
            ApplyCustomGravity();
        }

        private void HandleInput()
        {
            // Keyboard / VR Input (Placeholder for WASD/Arrow)
            float x = Input.GetAxis("Horizontal");
            float z = Input.GetAxis("Vertical");
            float y = 0;
            if (Input.GetKey(KeyCode.Space)) y = 1;
            if (Input.GetKey(KeyCode.LeftControl)) y = -1;
            
            inputVector = new Vector3(x, y, z);
            
            // Rotation (Q/E Roll, Mouse Pitch/Yaw)
            float yaw = Input.GetAxis("Mouse X");
            float pitch = -Input.GetAxis("Mouse Y");
            float roll = 0;
            if (Input.GetKey(KeyCode.Q)) roll = 1;
            if (Input.GetKey(KeyCode.E)) roll = -1;
            
            rotationInput = new Vector3(pitch, yaw, roll);
        }

        private void ApplyMovement()
        {
            // Local Space Flight
            Vector3 force = transform.TransformDirection(inputVector) * Acceleration;
            rb.AddForce(force, ForceMode.Acceleration);
            
            // Torque
            rb.AddRelativeTorque(rotationInput * RotationSpeed, ForceMode.VelocityChange);
        }

        private void ApplyCustomGravity()
        {
            if (EnableGravitySlingshot && PhysicsEngine.Instance != null)
            {
                // Core Philosophy: We surf the lattice.
                // Just use the standard N-Body gravity for now.
                // PhysicsEngine should already be applying force to us if we are registered?
                // Actually, PhysicsEngine iterates "RegisteredBodies". The Player ship needs to optionally be one.
                // For now, let's manually query gravity at our position to feel the "Field".
                
                // NOT actually applying force here to avoid double dipping if registered.
                // Just calculating it for UI/Feedback.
                Vector3d posD = new Vector3d(transform.position.x, transform.position.y, transform.position.z);
                Vector3 netGravity = PhysicsEngine.Instance.CalculateGravityAtPoint(posD, 100.0f); // Assume mass 100
                // rb.AddForce(netGravity); // Uncomment to feel the pull
            }
        }
    }
}
