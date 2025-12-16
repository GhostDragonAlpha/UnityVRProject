using UnityEngine;
using UnityEngine.Events;

// Note: This script assumes 'com.unity.xr.interaction.toolkit' is installed.
// If you see errors here, ensure the package is added via Package Manager.

namespace VR
{
    // Placeholder inheritance - usually this would be XRGrabInteractable
    // public class SimpleInteractable : UnityEngine.XR.Interaction.Toolkit.XRGrabInteractable
    // For safety during initial setup (before package install), we use MonoBehaviour
    
    public class SimpleInteractable : MonoBehaviour 
    {
        [SerializeField] private UnityEvent onInteract;

        public void Interact()
        {
            Debug.Log($"[SimpleInteractable] Interacted with {gameObject.name}");
            onInteract?.Invoke();
        }

        // TODO: Uncomment once XRI is installed
        /*
        protected override void OnSelectEntered(UnityEngine.XR.Interaction.Toolkit.SelectEnterEventArgs args)
        {
            base.OnSelectEntered(args);
            Interact();
        }
        */
    }
}
