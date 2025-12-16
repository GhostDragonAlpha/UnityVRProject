using UnityEngine;
using UnityEngine.InputSystem;
using Gameplay;

namespace VR
{
    public class CockpitInputManager : MonoBehaviour
    {
        public ShipController ship;
        
        // In a real scenario, we would reference Input Actions here.
        // For 'No User Testing' defaults, we will use Keycodes as fallback 
        // and try to find standard XR inputs if available.
        
        private void Update()
        {
            if (ship == null) return;

            // Keyboard Fallback (for easy testing without headset)
            ship.throttleInput = Input.GetAxis("Vertical"); // W/S
            ship.yawInput = Input.GetAxis("Horizontal");    // A/D
            
            // To be implemented: XR Input reading
            // var leftHand = ...
            // ship.throttleInput = leftHand.ReadValue<Vector2>().y;
        }
    }
}
