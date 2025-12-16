using UnityEngine;

namespace Gameplay
{
    public class ShipSystems : MonoBehaviour
    {
        [Header("Health")]
        public float health = 100f;
        public float maxHealth = 100f;
        
        [Header("Debug")]
        public float debugDamage
        {
            set { TakeDamage(value); }
            get { return 0f; }
        }

        [Header("Energy")]
        public float energy = 100f;
        public float maxEnergy = 100f;
        public float energyRegenRate = 5f;

        [Header("Shields (Optional MVP)")]
        public float shields = 0f;
        public float maxShields = 50f;

        private void Update()
        {
            // Regen Energy
            if (energy < maxEnergy)
            {
                energy += energyRegenRate * Time.deltaTime;
                if (energy > maxEnergy) energy = maxEnergy;
            }
        }

        public void TakeDamage(float amount)
        {
            // Shield Logic
            if (shields > 0)
            {
                shields -= amount;
                if (shields < 0)
                {
                    health += shields; // Apply overflow to health
                    shields = 0;
                }
            }
            else
            {
                health -= amount;
            }

            Debug.Log($"[Ship] Took {amount} Damage. Health: {health}/{maxHealth}");

            if (health <= 0)
            {
                Die();
            }
        }

        public bool ConsumeEnergy(float amount)
        {
            if (energy >= amount)
            {
                energy -= amount;
                return true;
            }
            return false;
        }

        private void Die()
        {
            Debug.Log($"[Ship] CRITICAL FAILURE. SHIP DESTROYED.");
            // Respawn logic or Game Over screen
            // For MVP: Reset
            health = maxHealth;
            transform.position = Vector3.zero; // Or VirtualTransform reset?
        }
    }
}
