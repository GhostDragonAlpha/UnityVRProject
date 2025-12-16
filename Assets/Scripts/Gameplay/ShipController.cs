using UnityEngine;

namespace Gameplay
{
    [RequireComponent(typeof(Rigidbody))]
    public class ShipController : MonoBehaviour
    {
        [Header("Flight Settings")]
        public float thrustForce = 1000f;
        public float pitchSpeed = 100f;
        public float yawSpeed = 100f;
        public float rollSpeed = 100f;

        [Header("Debug Input")]
        public float throttleInput;
        public float strafeHorizontalInput;
        public float strafeVerticalInput;
        public float pitchInput;
        public float yawInput;
        public float rollInput;

        private Rigidbody rb;

        private void Awake()
        {
            rb = GetComponent<Rigidbody>();
            rb.useGravity = false;
            rb.linearDamping = 1f; // Space friction
            rb.angularDamping = 2f;
        }

        private void FixedUpdate()
        {
            HandleMovement();
            HandleRotation();
        }

        private void HandleMovement()
        {
            // Forward/Back (Throttle)
            if (Mathf.Abs(throttleInput) > 0.1f)
            {
                rb.AddRelativeForce(Vector3.forward * throttleInput * thrustForce * Time.fixedDeltaTime);
            }

            // Strafe (Left/Right, Up/Down)
            if (Mathf.Abs(strafeHorizontalInput) > 0.1f)
            {
                rb.AddRelativeForce(Vector3.right * strafeHorizontalInput * thrustForce * 0.5f * Time.fixedDeltaTime);
            }
             if (Mathf.Abs(strafeVerticalInput) > 0.1f)
            {
                rb.AddRelativeForce(Vector3.up * strafeVerticalInput * thrustForce * 0.5f * Time.fixedDeltaTime);
            }
        }

        private void HandleRotation()
        {
            // Pitch (Nose Up/Down)
            if (Mathf.Abs(pitchInput) > 0.1f)
            {
                rb.AddRelativeTorque(Vector3.right * pitchInput * pitchSpeed * Time.fixedDeltaTime);
            }

            // Yaw (Nose Left/Right)
            if (Mathf.Abs(yawInput) > 0.1f)
            {
                rb.AddRelativeTorque(Vector3.up * yawInput * yawSpeed * Time.fixedDeltaTime);
            }

            // Roll (Tilt Left/Right)
            if (Mathf.Abs(rollInput) > 0.1f)
            {
                rb.AddRelativeTorque(Vector3.back * rollInput * rollSpeed * Time.fixedDeltaTime);
            }
        }
    }
}
