using UnityEngine;
using UnityEditor;
using Core;

namespace EditorScripts
{
    [InitializeOnLoad]
    public class BridgeLoader
    {
        static BridgeLoader()
        {
            EditorApplication.delayCall += EnsureBridgeExists;
        }

        static void EnsureBridgeExists()
        {
            var bridge = Object.FindFirstObjectByType<ZeroMQBridge>();
            if (bridge == null)
            {
                // Check if GameRoot exists
                var root = GameObject.Find("GameRoot");
                if (root == null)
                {
                    root = new GameObject("GameRoot");
                }
                
                Debug.Log("[BridgeLoader] Adding ZeroMQBridge to GameRoot...");
                root.AddComponent<ZeroMQBridge>();
            }
            
            var saveMgr = Object.FindFirstObjectByType<Gameplay.Persistence.SaveManager>();
            if (saveMgr == null)
            {
                 var root = GameObject.Find("GameRoot");
                 if (root) root.AddComponent<Gameplay.Persistence.SaveManager>();
            }

            // Ensure PhysicsEngine
            var phys = Object.FindFirstObjectByType<PhysicsEngine>();
            if (phys == null)
            {
                 var root = GameObject.Find("GameRoot");
                 if (root) 
                 {
                     Debug.Log("[BridgeLoader] Adding PhysicsEngine to GameRoot...");
                     root.AddComponent<PhysicsEngine>();
                 }
            }
        }
    }
}
