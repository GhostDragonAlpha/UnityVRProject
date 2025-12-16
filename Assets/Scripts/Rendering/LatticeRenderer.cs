using UnityEngine;
using Core;

namespace Rendering
{
    public class LatticeRenderer : MonoBehaviour
    {
        public Material latticeMaterial;
        public float gridSize = 1000f; // Size of the quad
        public float spacing = 10f;

        private GameObject gridQuad;
        private Material instanceMat;

        private void Start()
        {
            CreateGrid();
        }

        private void CreateGrid()
        {
            gridQuad = GameObject.CreatePrimitive(PrimitiveType.Quad);
            gridQuad.name = "LatticeGrid";
            gridQuad.transform.parent = transform; // Attached to player usually
            gridQuad.transform.localPosition = new Vector3(0, -2, 0); // Below feet
            gridQuad.transform.localRotation = Quaternion.Euler(90, 0, 0); // Flat
            gridQuad.transform.localScale = new Vector3(gridSize, gridSize, 1);

            // Setup Material
            Renderer r = gridQuad.GetComponent<Renderer>();
            
            if (latticeMaterial == null)
            {
                Shader s = Shader.Find("Custom/Lattice");
                if (s != null) latticeMaterial = new Material(s);
            }
            
            if (latticeMaterial != null)
            {
                instanceMat = new Material(latticeMaterial);
                r.material = instanceMat;
                instanceMat.SetFloat("_Spacing", spacing);
            }
            else
            {
                Debug.LogError("Lattice Shader not found!");
            }
        }

        [Header("Linkages")]
        public Gameplay.GravityDrive TargetDrive;
        
        private void Update()
        {
            if (instanceMat == null) return;
            if (TargetDrive == null) TargetDrive = FindObjectOfType<Gameplay.GravityDrive>();
            
            // 1. Position Update (Floating Origin)
            if (WorldMover.Instance != null)
            {
                Vector3d pos = WorldMover.Instance.VirtualPosition;
                instanceMat.SetVector("_Offset", new Vector4((float)pos.x, (float)pos.y, (float)pos.z, 0));
            }
            else
            {
                // Fallback for non-WorldMover setup
                instanceMat.SetVector("_Offset", transform.position);
            }
            
            // 2. Map Mode Logic (Speed -> Visibility)
            float alpha = 0.1f; // Base visibility
            if (TargetDrive != null)
            {
                float speed = TargetDrive.CurrentSpeed;
                float threshold = TargetDrive.WarpThreshold;
                
                // Fade in as we approach warp
                float warpFactor = Mathf.InverseLerp(threshold * 0.5f, threshold, speed);
                alpha = Mathf.Lerp(0.0f, 1.0f, warpFactor);
                instanceMat.SetFloat("_Alpha", alpha); // Shader needs this prop
            }
            
            // 3. Gravity Visualization (Field Strength)
            // Lines condense (Spacing decreases? Thickness increases?) as Gravity increases.
            if (Core.PhysicsEngine.Instance != null && alpha > 0.01f)
            {
                // Sample generic position (e.g. Player)
                Vector3 samplePos = transform.parent != null ? transform.parent.position : transform.position;
                Vector3d samplePosD = new Vector3d(samplePos.x, samplePos.y, samplePos.z);
                Vector3 gravity = Core.PhysicsEngine.Instance.CalculateGravityAtPoint(samplePosD, 1.0);
                float gStrength = gravity.magnitude;
                
                // Map G to Spacing/Thickness
                // High G -> Tighter Grid (Smaller Spacing)
                // G ranges 0 to Infinity. Log scale?
                // Let's create a 'Distortion' value.
                
                float distortion = Mathf.Clamp01(gStrength * 0.001f); // Tuning needed
                
                // If G is high, Spacing drops.
                float dynamicSpacing = Mathf.Lerp(spacing, spacing * 0.2f, distortion);
                
                instanceMat.SetFloat("_Spacing", dynamicSpacing);
                instanceMat.SetFloat("_GravityOverlay", distortion); // Pass to shader if we want color shift
            }
        }
    }
}
