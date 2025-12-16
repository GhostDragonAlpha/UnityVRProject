using UnityEngine;

namespace Gameplay
{
    public class MiningLaser : MonoBehaviour
    {
        [Header("Settings")]
        public float range = 50f;
        public float extractionRate = 10f; // Units per second
        public LayerMask mineableLayer;

        [Header("Visuals")]
        public LineRenderer beamLine;
        public ParticleSystem hitEffect;

        [Header("State")]
        public bool isFiring;
        public RaycastHit currentHit;

        private ResourceInventory inventory;
        
        private void Start()
        {
            inventory = GetComponentInParent<ResourceInventory>();
        }

        private void Update()
        {
            if (isFiring)
            {
                ProcessMining();
                UpdateVisuals(true);
            }
            else
            {
                UpdateVisuals(false);
            }
        }
        
        public void SetFiring(bool firing)
        {
            isFiring = firing;
        }

        private void ProcessMining()
        {
            // Raycast forward from laser position (Ignore LayerMask for now to ensure hit)
            if (UnityEngine.Physics.Raycast(transform.position, transform.forward, out currentHit, range))
            {
                // Logic: Did we hit a MiningTarget?
                MiningTarget target = currentHit.collider.GetComponent<MiningTarget>();
                if (target != null)
                {
                    // Debug.Log($"[Mining] Hitting {target.name}"); // Sparse Logging
                    
                    // Extract
                    float amount = extractionRate * Time.deltaTime;
                    target.Extract(amount);
                    
                    // Add to Inventory
                    if (inventory != null)
                    {
                        inventory.AddResource(target.resourceName, amount);
                    }
                }
                else
                {
                     Debug.Log($"[Mining] Hit {currentHit.collider.name} but no MiningTarget component found.");
                }
            }
            else
            {
                 Debug.Log("[Mining] Raycast Hit Nothing.");
            }
        }

        private void UpdateVisuals(bool active)
        {
            if (beamLine == null) return;
            
            beamLine.enabled = active;
            if (active)
            {
                beamLine.SetPosition(0, transform.position);
                if (currentHit.collider != null)
                {
                    beamLine.SetPosition(1, currentHit.point);
                    // Move hit effect
                    if (hitEffect != null)
                    {
                        hitEffect.transform.position = currentHit.point;
                        if (!hitEffect.isPlaying) hitEffect.Play();
                    }
                }
                else
                {
                    // Shoot into distance
                    beamLine.SetPosition(1, transform.position + transform.forward * range);
                    if (hitEffect != null) hitEffect.Stop();
                }
            }
            else
            {
                if (hitEffect != null) hitEffect.Stop();
            }
        }
    }
}
