using UnityEngine;
using UnityEngine.XR;
using Gameplay;

namespace VR
{
    public class CockpitInputController : MonoBehaviour
    {
        [Header("References")]
        public VirtualShip ship;
        
        // We use InputDevices directly for simplicity in this MVP 
        // without setting up a full Input Action Asset if possible.
        // Or we can use the legacy XR.InputDevice API which generates less clutter.
        
        [Header("Debug / Mock Input")]
        public float deadzone = 0.1f;
        // Split for simple AgentBridge set_property calls
        public float mockLeftX;
        public float mockLeftY;
        public float mockRightX;
        public float mockRightY;
        public float mockTrigger;

        private void Start()
        {
            if (ship == null) ship = GetComponent<VirtualShip>();
        }

        private void Update()
        {
            if (ship == null) return;

            // 1. Get Devices
            var leftHand = InputDevices.GetDeviceAtXRNode(XRNode.LeftHand);
            var rightHand = InputDevices.GetDeviceAtXRNode(XRNode.RightHand);

            // 2. Read Inputs (Start with Mock)
            Vector2 leftStickInput = new Vector2(mockLeftX, mockLeftY);
            Vector2 rightStickInput = new Vector2(mockRightX, mockRightY);
            float rightTriggerInput = mockTrigger;

            // Override with Real Input if available
            if (leftHand.isValid) leftHand.TryGetFeatureValue(CommonUsages.primary2DAxis, out leftStickInput);
            if (rightHand.isValid) rightHand.TryGetFeatureValue(CommonUsages.primary2DAxis, out rightStickInput);
            if (rightHand.isValid) rightHand.TryGetFeatureValue(CommonUsages.trigger, out rightTriggerInput);

            // 3. Map to Ship
            // Left Stick Y -> Throttle
            // Left Stick X -> Roll
            float throttleInput = ApplyDeadzone(leftStickInput.y);
            float rollInput = ApplyDeadzone(leftStickInput.x);

            // Right Stick Y -> Pitch
            // Right Stick X -> Yaw
            float pitchInput = ApplyDeadzone(rightStickInput.y);
            float yawInput = ApplyDeadzone(rightStickInput.x);

            // Trigger -> Firing
            bool isFiring = rightTriggerInput > 0.5f;

            // 4. Apply
            ship.throttle = throttleInput;
            ship.roll = rollInput * -1f; // Invert roll usually feels better? Or standard.
            ship.pitch = pitchInput; // Pitch up is usually down on stick?
            ship.yaw = yawInput;

            // Fire Mining Laser?
            // If we have a MiningLaser on the ship, trigger it.
            // For now, let's just expose a public bool on ship or handle it here.
            // ship.SetFiring(isFiring); // Assuming VirtualShip will have this.
        }

        private float ApplyDeadzone(float val)
        {
            if (Mathf.Abs(val) < deadzone) return 0f;
            return val;
        }
    }
}
