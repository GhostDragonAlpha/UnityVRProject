using UnityEngine;
using Core;

namespace Procedural
{
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class ProceduralTerrain : MonoBehaviour
    {
        public int size = 100; // 100x100 vertices
        public float scale = 1.0f; // Distance between vertices
        public float heightScale = 10.0f;
        public float frequency = 0.05f;

        private Mesh mesh;
        private Vector3[] vertices;
        private int[] triangles;

        private void Start()
        {
            GenerateMesh();
            
            // Ensure we exist in the infinite world
            if (GetComponent<VirtualTransform>() == null)
            {
                gameObject.AddComponent<VirtualTransform>();
            }
        }

        private void GenerateMesh()
        {
            mesh = new Mesh();
            GetComponent<MeshFilter>().mesh = mesh;
            mesh.name = "ProceduralTerrain";

            vertices = new Vector3[(size + 1) * (size + 1)];
            Vector2[] uvs = new Vector2[vertices.Length];
            
            // Offset to center the chunk
            float offset = (size * scale) / 2.0f;

            for (int i = 0, z = 0; z <= size; z++)
            {
                for (int x = 0; x <= size; x++)
                {
                    float xPos = x * scale - offset;
                    float zPos = z * scale - offset;
                    
                    // Legacy Formula: sin(x * 0.05) * 10 + cos(z * 0.05) * 10
                    // We use world space coordinates (relative to this object's transform logic)
                    // But since this object moves via WorldMover, its local position creates the shape.
                    
                    float y = Mathf.Sin(xPos * frequency) * heightScale + Mathf.Cos(zPos * frequency) * heightScale;
                    
                    vertices[i] = new Vector3(xPos, y, zPos);
                    uvs[i] = new Vector2((float)x / size, (float)z / size);
                    i++;
                }
            }

            triangles = new int[size * size * 6];
            int vert = 0;
            int tris = 0;

            for (int z = 0; z < size; z++)
            {
                for (int x = 0; x < size; x++)
                {
                    triangles[tris + 0] = vert + 0;
                    triangles[tris + 1] = vert + size + 1;
                    triangles[tris + 2] = vert + 1;
                    triangles[tris + 3] = vert + 1;
                    triangles[tris + 4] = vert + size + 1;
                    triangles[tris + 5] = vert + size + 2;

                    vert++;
                    tris += 6;
                }
                vert++;
            }

            mesh.vertices = vertices;
            mesh.triangles = triangles;
            mesh.uv = uvs;
            mesh.RecalculateNormals();
            
            // Add Collider
            MeshCollider mc = gameObject.GetComponent<MeshCollider>();
            if (mc == null) mc = gameObject.AddComponent<MeshCollider>();
            mc.sharedMesh = mesh;
            
            Debug.Log($"[Procedural] Terrain Generated: {mesh.vertexCount} vertices.");
        }
    }
}
