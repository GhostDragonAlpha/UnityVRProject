using UnityEngine;

namespace Core
{
    /// <summary>
    /// The Root of a System. Emits Light and Heat.
    /// "Principles": High Mass -> High Temp -> High Frequency.
    /// </summary>
    public class Star : CelestialBody
    {
        [Header("Stellar Properties")]
        public float Temperature = 5778.0f; // Kelvin (Sun)
        public float Luminosity = 1.0f;     // Solar Luminosity
        public string SpectralType = "G";   // G-Type (Yellow Dwarf)

        private void OnValidate()
        {
            // Principle: Mass defines Temperature (Simplified Main Sequence)
            // L ~ M^3.5
            // T ~ M^0.5 (approx)
            
            float massRatio = (float)Mass; // Assuming 1.0 = Sun Mass
            Luminosity = Mathf.Pow(massRatio, 3.5f);
            Temperature = 5778.0f * Mathf.Pow(massRatio, 0.5f);
            
            // Recalculate Frequency based on new Mass/Density
            CalculateResonantFrequency();
        }

        public Color GetColor()
        {
            // Principle: Blackbody Radiation Color Temperature
            if (Temperature < 3500) return new Color(1.0f, 0.5f, 0.3f); // Red
            if (Temperature < 5000) return new Color(1.0f, 0.8f, 0.6f); // Orange
            if (Temperature < 6000) return new Color(1.0f, 1.0f, 0.9f); // Yellow (Sun)
            if (Temperature < 7500) return new Color(1.0f, 1.0f, 1.0f); // White
            if (Temperature < 10000) return new Color(0.9f, 0.95f, 1.0f); // Blue-White
            return new Color(0.7f, 0.8f, 1.0f); // Blue
        }
    }
}
