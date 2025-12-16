using UnityEngine;
using Core;

namespace Gameplay
{
    public class CockpitHUD : MonoBehaviour
    {
        [Header("Settings")]
        public Vector3 offset = new Vector3(0, 1.5f, 2.0f); // In front of cockpit
        public float scale = 0.1f;
        public Color textColor = Color.cyan;

        private ShipSystems ship;
        private TextMesh healthText;
        private TextMesh energyText;
        private TextMesh speedText;

        private void Start()
        {
            ship = GetComponentInParent<ShipSystems>();
            Debug.Log("[HUD] Initialized. Creating Text Elements...");
            
            // Auto-setup Text Elements
            healthText = CreateTextElement("HealthDisplay", new Vector3(-1f, 0, 0));
            speedText = CreateTextElement("SpeedDisplay", new Vector3(0, 0.5f, 0));
            energyText = CreateTextElement("EnergyDisplay", new Vector3(1f, 0, 0));
            
            // Parent to this (HUD Root)
            // If this object is on the ship, the text moves with it.
        }

        private TextMesh CreateTextElement(string name, Vector3 localPos)
        {
            GameObject go = new GameObject(name);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = localPos;
            go.transform.localScale = Vector3.one * scale;
            go.transform.localRotation = Quaternion.identity;

            TextMesh tm = go.AddComponent<TextMesh>();
            tm.color = textColor;
            tm.characterSize = 0.5f;
            tm.fontSize = 48; // High res + scale down = crisp
            tm.anchor = TextAnchor.MiddleCenter;
            tm.alignment = TextAlignment.Center;
            
            return tm;
        }

        private void Update()
        {
            // Health
            if (ship != null)
            {
                healthText.text = $"HP: {ship.health:F0} / {ship.maxHealth:F0}";
                healthText.color = Color.Lerp(Color.red, Color.green, ship.health / ship.maxHealth);
                
                energyText.text = $"NRG: {ship.energy:F0}";
            }
            else
            {
                healthText.text = "NO SYSTEMS";
            }

            // Speed
            if (WorldMover.Instance != null)
            {
                var vel = WorldMover.Instance.VirtualVelocity;
                // Using Magnitude property I added to Vector3d
                double speed = vel.Magnitude; 
                speedText.text = $"SPD: {speed:F1} m/s\nPOS: {WorldMover.Instance.VirtualPosition.z:F0}";
            }
        }
    }
}
