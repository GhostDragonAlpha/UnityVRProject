using UnityEngine;
using UnityEditor;
using Player;

namespace EditorScripts
{
    [InitializeOnLoad]
    public class PlayerSetup
    {
        static PlayerSetup()
        {
            EditorApplication.delayCall += EnsurePlayerComponents;
        }

        static void EnsurePlayerComponents()
        {
            var playerObj = GameObject.Find("PlayerShip");
            if (playerObj == null)
            {
                Debug.LogWarning("[PlayerSetup] 'PlayerShip' not found in scene.");
                return;
            }

            var align = playerObj.GetComponent<GravityAlignment>();
            if (align == null)
            {
                Debug.Log("[PlayerSetup] Adding GravityAlignment to PlayerShip...");
                align = playerObj.AddComponent<GravityAlignment>();
                align.AlignToGravity = true;
                align.RotationSpeed = 5f;
            }

            var walker = playerObj.GetComponent<PhysicsWalker>();
            if (walker == null)
            {
                Debug.Log("[PlayerSetup] Adding PhysicsWalker to PlayerShip...");
                walker = playerObj.AddComponent<PhysicsWalker>();
                walker.WalkSpeed = 10f;
                walker.GroundLayers = ~0; // All layers for now
            }
            
            // Ensure Rigidbody is kinematic? No, PhysicsWalker uses forces.
            var rb = playerObj.GetComponent<Rigidbody>();
            if (rb)
            {
                 rb.useGravity = false; // Important for Orbital/Spherical gravity
                 // rb.isKinematic = false; // Must be simulated
            }
        }
    }
}
