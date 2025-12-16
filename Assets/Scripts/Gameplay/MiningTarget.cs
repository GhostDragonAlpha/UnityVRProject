using UnityEngine;

namespace Gameplay
{
    public class MiningTarget : MonoBehaviour
    {
        public string resourceName = "Iron";
        public float amountRemaining = 100f;
        
        public void Extract(float amount)
        {
            if (amountRemaining <= 0) return;
            
            amountRemaining -= amount;
            if (amountRemaining <= 0)
            {
                amountRemaining = 0;
                Die();
            }
        }

        private void Die()
        {
            Debug.Log($"[Mining] {resourceName} Depleted!");
            // In a real game, spawn loot or explode.
            // For Fixed Origin, maybe just disable mesh?
            gameObject.SetActive(false);
        }
    }
}
