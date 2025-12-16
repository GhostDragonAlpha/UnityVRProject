using System;
using System.Collections.Generic;
using UnityEngine;
using Core;

namespace Gameplay.Persistence
{
    [Serializable]
    public class SaveData
    {
        public string saveName;
        public long timestamp;
        
        // Player
        public Vector3d playerPosition;
        public Vector3d playerVelocity;
        
        // Ship Systems
        public float health;
        public float energy;
        
        // Inventory (Wrapped for JsonUtility)
        public List<InventoryItemData> inventoryItems = new List<InventoryItemData>();
        
        // Upgrades (List of strings)
        public List<string> upgrades = new List<string>();
    }

    [Serializable]
    public class InventoryItemData
    {
        public string id;
        public float amount;
        
        public InventoryItemData(string id, float amount)
        {
            this.id = id;
            this.amount = amount;
        }
    }
}
