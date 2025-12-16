using UnityEngine;
using System.Collections.Generic;

namespace Gameplay
{
    public class ResourceInventory : MonoBehaviour
    {
        // Simple Dictionary for MVP
        public Dictionary<string, float> resources = new Dictionary<string, float>();

        public void AddResource(string type, float amount)
        {
            if (!resources.ContainsKey(type))
            {
                resources[type] = 0f;
            }
            resources[type] += amount;
            
            // Debug Log for verification
            Debug.Log($"[Inventory] Added {amount} {type}. Total: {resources[type]}");
        }

        public float GetAmount(string type)
        {
            if (resources.ContainsKey(type)) return resources[type];
            return 0f;
        }
        
        // Helper for Debugging via AgentBridge
        public void LogInventory()
        {
            foreach (var kvp in resources)
            {
                Debug.Log($"[Inventory State] {kvp.Key}: {kvp.Value}");
            }
        }
    }
}
