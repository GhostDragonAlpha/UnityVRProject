using UnityEngine;
using Core;

namespace Combat
{
    [RequireComponent(typeof(VirtualTransform))]
    public class Projectile : MonoBehaviour
    {
        public float speed = 100f;
        public float damage = 10f;
        public float lifetime = 5f;

        private VirtualTransform vt;
        private Vector3d velocity;

        private void Start()
        {
            vt = GetComponent<VirtualTransform>();
            // Assumes forward launch
            Vector3 fwd = transform.forward;
            velocity = new Vector3d(fwd.x, fwd.y, fwd.z) * speed;
            
            Destroy(gameObject, lifetime);
        }

        private void Update()
        {
            if (vt != null)
            {
                vt.WorldPosition += velocity * Time.deltaTime;
            }
            
            // Collision Detection
            // For MVP High Speed, Raycast is better than Collider
            // But we can use simple Trigger Collider if speed isn't insane.
            
            // Visual Rotation
            transform.LookAt(transform.position + transform.forward);
        }
        
        private void OnTriggerEnter(Collider other)
        {
            // Debug.Log($"[Combat] Projectile hit {other.name}!");
            
            // Try to damage
            var ship = other.GetComponentInParent<Gameplay.ShipSystems>();
            if (ship != null)
            {
                ship.TakeDamage(damage);
            }
            
            Destroy(gameObject);
        }
    }
}
