using UnityEngine;
using Core;
using System.Collections;
using System.IO;

namespace Testing
{
    [ExecuteAlways]
    public class PhysicsVerifier : MonoBehaviour
    {
        // Physics Verifier: Validates Core Loop
        public bool RunOnStart = false;

        // Expected constants
        private const double ExpectedG = 9.8; // Surface gravity
        private const double SurfaceRadius = 10.0;

        private void Update()
        {
            if (RunOnStart)
            {
                RunOnStart = false;
                RunTestSeries();
            }
        }

        public void RunTestSeries()
        {
            Debug.Log("[PhysicsVerifier] Starting Test Series...");
            TestFall();
        }

        private void TestFall()
        {
            var sb = new System.Text.StringBuilder();
            sb.AppendLine("PHYSICS ENGINE RUNTIME VERIFICATION REPORT");
            sb.AppendLine("==========================================");
            sb.AppendLine($"Timestamp: {System.DateTime.Now}");

            // Setup
            // Earth is at 200, 0, 0. Radius 10. Mass 9,800,000.
            // Gravity at Surface (R=10) should be 9.8.
            // Test Point: (190, 0, 0) // At surface (Left side? Earth is at 200. Surface is 190..210)
            // Let's test at (210, 0, 0) -> 10 units away from center.

            Vector3d testPos = new Vector3d(210, 0, 0);
            
            // Check for PhysicsEngine
            if (PhysicsEngine.Instance == null)
            {
                sb.AppendLine("FATAL: PhysicsEngine.Instance is NULL. Test Aborted.");
            }
            else
            {
                Vector3 gravity = PhysicsEngine.Instance.CalculateGravityAtPoint(testPos, 1.0);

                sb.AppendLine($"Test Point: {testPos}");
                sb.AppendLine($"Gravity Vector: {gravity}");
                sb.AppendLine($"Gravity Magnitude: {gravity.magnitude}");

                // Expected: Pointing to Center (200,0,0). So Direction (-1, 0, 0).
                bool dirPass = gravity.x < 0 && Mathf.Abs(gravity.y) < 0.1f;
                sb.AppendLine($"Direction Check (-X): {(dirPass ? "PASS" : "FAIL")}");

                // Expected Magnitude: 9.8
                bool magPass = Mathf.Abs(gravity.magnitude - 9.8f) < 0.1f;
                sb.AppendLine($"Magnitude Check (~9.8): {(magPass ? "PASS" : "FAIL")}");
            }

            // Orbit Check
            var earthObj = GameObject.Find("Earth");
            if (earthObj != null)
            {
                var earth = earthObj.GetComponent<Core.Planet>();
                if (earth != null)
                {
                    sb.AppendLine($"Earth Velocity: {earth.Velocity}");
                    // Expected Vz > 0
                    bool orbitPass = earth.Velocity.z > 1.0;
                    sb.AppendLine($"Orbit Velocity Check: {(orbitPass ? "PASS" : "FAIL")}");
                }
                else
                {
                    sb.AppendLine("Earth Object found, but Planet Component missing.");
                }
            }
            else
            {
                sb.AppendLine("Earth Object: NOT FOUND");
            }

            // Write File
            // Write to project root for easy access
            string path = Path.GetFullPath(Path.Combine(Application.dataPath, "../test_results.txt"));
            File.WriteAllText(path, sb.ToString());
            Debug.Log($"[PhysicsVerifier] Report written to {path}");
        }
    }
}
