using UnityEngine;

namespace Audio
{
    [RequireComponent(typeof(AudioSource))]
    public class AudioSynthesizer : MonoBehaviour
    {
        public enum WaveType { Sine, Square, Saw, Triangle, Noise }

        [Header("Settings")]
        public WaveType waveType = WaveType.Sine;
        [Range(20f, 2000f)] public float frequency = 440f;
        [Range(0f, 1f)] public float amplitude = 0.5f;
        public bool isPlaying = false;

        private double phase;
        private double increment;
        private int sampleRate;
        private System.Random rng;

        private void Awake()
        {
            sampleRate = AudioSettings.outputSampleRate;
            rng = new System.Random();
        }

        private void Update()
        {
            // Calculate increment based on current frequency
            increment = frequency * 2.0 * Mathf.PI / sampleRate;
        }

        public void PlayTone(float freq, float amp = 0.5f, WaveType type = WaveType.Sine)
        {
            frequency = freq;
            amplitude = amp;
            waveType = type;
            isPlaying = true;
        }

        public void StopTone()
        {
            isPlaying = false;
        }

        // Unity calls this on audio thread. 
        // Need to be careful with thread safety, but float/bool/enum writes are atomic enough for MVP.
        private void OnAudioFilterRead(float[] data, int channels)
        {
            if (!isPlaying) return;

            for (int i = 0; i < data.Length; i += channels)
            {
                phase += increment;
                
                // Wrap phase to avoid precision loss
                if (phase > 2.0 * Mathf.PI) phase -= 2.0 * Mathf.PI;

                float value = 0f;

                switch (waveType)
                {
                    case WaveType.Sine:
                        value = Mathf.Sin((float)phase);
                        break;
                    case WaveType.Square:
                        value = (Mathf.Sin((float)phase) >= 0) ? 1f : -1f;
                        break;
                    case WaveType.Triangle:
                        value = Mathf.PingPong((float)phase, 2.0f * Mathf.PI) / Mathf.PI - 1f; // Approx
                        break;
                    case WaveType.Saw:
                        value = (float)(phase / (Mathf.PI) - 1.0); // Simple phasor
                        break;
                    case WaveType.Noise:
                        value = (float)(rng.NextDouble() * 2.0 - 1.0);
                        break;
                }

                value *= amplitude;

                // Write to all channels
                for (int c = 0; c < channels; c++)
                {
                    data[i + c] = value;
                }
            }
        }
    }
}
