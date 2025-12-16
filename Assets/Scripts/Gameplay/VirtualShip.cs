using UnityEngine;
using Core;

namespace Gameplay
{
    public class VirtualShip : MonoBehaviour
    {
        [Header("Ship Stats")]
        public float acceleration = 10.0f;
        public float maxSpeed = 1000.0f; // c?
        public float rotationSpeed = 100.0f;

        [Header("Input")]
        public float throttle;
        public float yaw;
        public float pitch;
        public float roll;
        public bool boost;

        private void Update()
        {
            HandleInput();
            ApplyPhysics();
        }

        private void HandleInput()
        {
            // Keyboard Fallback
            throttle = Input.GetAxis("Vertical"); // W/S
            yaw = Input.GetAxis("Horizontal");    // A/D
            
            // TODO: XR Input mapping (Joystick)
            
            boost = Input.GetKey(KeyCode.LeftShift);
        }

        private void ApplyPhysics()
        {
            if (WorldMover.Instance == null) return;

            // Rotation (Real Unity Rotation - Player actually rotates)
            // But we might want the world to rotate? No, standard space sim: You rotate, world translates.
            transform.Rotate(Vector3.right * pitch * rotationSpeed * Time.deltaTime);
            transform.Rotate(Vector3.up * yaw * rotationSpeed * Time.deltaTime);
            transform.Rotate(Vector3.forward * roll * rotationSpeed * Time.deltaTime);

            // Throttle -> Virtual Velocity
            float currentAccel = acceleration * (boost ? 5f : 1f);
            
            // We need to add velocity in the direction we are facing
            Vector3 forward = transform.forward;
            
            // Convert to double for precision
            Vector3d forwardD = new Vector3d(forward.x, forward.y, forward.z);
            
            // Add acceleration to connection 
            // Note: In real physics, drag applies.
            
            if (Mathf.Abs(throttle) > 0.01f)
            {
                WorldMover.Instance.VirtualVelocity += forwardD * throttle * currentAccel * Time.deltaTime;
            }
            
            // Drag / Deceleration (Simple)
            // WorldMover.Instance.VirtualVelocity = WorldMover.Instance.VirtualVelocity * 0.99d; 
        }
    }
}
