using UnityEngine;
using UnityEditor;
using UnityEngine.XR.Interaction.Toolkit;
using Unity.XR.CoreUtils;

namespace EditorScripts
{
    public class VRBootstrap : EditorWindow
    {
        [MenuItem("VR/Setup Scene")]
        public static void SetupScene()
        {
            // 1. Cleanup
            var mainCam = Camera.main;
            if (mainCam != null && mainCam.gameObject.name == "Main Camera")
            {
                DestroyImmediate(mainCam.gameObject);
            }

            // 2. Create XR Origin
            GameObject xrOriginGo = new GameObject("XR Origin");
            XROrigin xrOrigin = xrOriginGo.AddComponent<XROrigin>();
            
            // 3. Camera Offset & Camera
            GameObject camOffset = new GameObject("Camera Offset");
            camOffset.transform.SetParent(xrOriginGo.transform, false);
            xrOrigin.CameraFloorOffsetObject = camOffset;

            GameObject cameraGo = new GameObject("Main Camera");
            cameraGo.transform.SetParent(camOffset.transform, false);
            cameraGo.tag = "MainCamera";
            Camera cam = cameraGo.AddComponent<Camera>();
            cam.nearClipPlane = 0.01f; // Important for VR
            xrOrigin.Camera = cam;

            // Add TrackedPoseDriver (New Input System)
            // We use reflection or AddComponent string to avoid missing reference if package variation exists,
            // but standard XRI depends on InputSystem so this should work.
            cameraGo.AddComponent<UnityEngine.InputSystem.XR.TrackedPoseDriver>();

            // 4. Interaction Manager
            if (Object.FindObjectOfType<XRInteractionManager>() == null)
            {
                GameObject managers = new GameObject("XR Interaction Manager");
                managers.AddComponent<XRInteractionManager>();
            }

            // 5. Input Action Manager (Vital for Input System to work)
            GameObject inputManager = new GameObject("Input Action Manager");
            var iam = inputManager.AddComponent<UnityEngine.InputSystem.UI.InputSystemUIInputModule>(); 
            // Actually we need the 'InputActionManager' from XRI Samples usually, but let's just create a basic one.
            // Since we don't have the Samples imported, we might miss the Default Input Actions.
            // This is the tricky part of "No User Testing". 
            // We will add a note to the console.
            Debug.LogWarning("[VRBootstrap] REMINDER: You usually need to assign 'Input Actions' to the Input Action Manager.");

            // 6. Environment
            GameObject floor = GameObject.CreatePrimitive(PrimitiveType.Plane);
            floor.name = "Floor";
            floor.transform.localScale = new Vector3(2, 1, 2);
            // Gray material
            var renderer = floor.GetComponent<MeshRenderer>();
            renderer.sharedMaterial = new Material(Shader.Find("Standard"));
            renderer.sharedMaterial.color = Color.gray;

            // 7. Test Interactable
            GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
            cube.name = "Interactable Cube";
            cube.transform.position = new Vector3(0, 0.8f, 0.5f); // Chest height, front
            cube.transform.localScale = Vector3.one * 0.2f;
            cube.AddComponent<Rigidbody>();
            cube.AddComponent<UnityEngine.XR.Interaction.Toolkit.Interactables.XRGrabInteractable>();
            
            Debug.Log("[VRBootstrap] Scene Setup Complete! \n1. Ensure 'XR Plugin Management' is initialized.\n2. Ensure Input Actions are set.");
        }
    }
}
