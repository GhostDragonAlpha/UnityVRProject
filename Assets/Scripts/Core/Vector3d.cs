using System;
using UnityEngine;

namespace Core
{
    [System.Serializable]
    public struct Vector3d
    {
        public double x;
        public double y;
        public double z;

        public Vector3d(double x, double y, double z)
        {
            this.x = x;
            this.y = y;
            this.z = z;
        }

        public static Vector3d Zero => new Vector3d(0, 0, 0);

        public double Magnitude => Math.Sqrt(x * x + y * y + z * z);
        public double SqrMagnitude => x * x + y * y + z * z;

        public Vector3d Normalized
        {
            get
            {
                double m = Magnitude;
                if (m > 1e-15) return this / m;
                return Zero;
            }
        }

        public Vector3 ToVector3()
        {
            return new Vector3((float)x, (float)y, (float)z);
        }

        public static Vector3d operator +(Vector3d a, Vector3d b) => new Vector3d(a.x + b.x, a.y + b.y, a.z + b.z);
        public static Vector3d operator -(Vector3d a, Vector3d b) => new Vector3d(a.x - b.x, a.y - b.y, a.z - b.z);
        public static Vector3d operator *(Vector3d a, double b) => new Vector3d(a.x * b, a.y * b, a.z * b);
        public static Vector3d operator /(Vector3d a, double b) => new Vector3d(a.x / b, a.y / b, a.z / b);
        
        public override string ToString() => $"({x:F4}, {y:F4}, {z:F4})";
    }
}
