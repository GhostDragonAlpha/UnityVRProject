Shader "Custom/Lattice"
{
    Properties
    {
        _Color ("Grid Color", Color) = (0, 1, 1, 1)
        _Spacing ("Grid Spacing", Float) = 10.0
        _Thickness ("Line Thickness", Range(0, 1)) = 0.02
        _Offset ("World Offset", Vector) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            float4 _Color;
            float _Spacing;
            float _Thickness;
            float4 _Offset;
            float _Alpha;          // Controlled by Speed
            float _GravityOverlay; // Controlled by Gravity Strength

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz + _Offset.xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 1. Grid Calculation
                float3 pos = i.worldPos;
                
                // Derivatives for anti-aliasing
                float3 grid = abs(frac(pos / _Spacing - 0.5) - 0.5) * _Spacing;
                float3 fw = fwidth(pos);
                
                // Lines
                float lineX = smoothstep(_Thickness + fw.x, _Thickness, grid.x);
                float lineZ = smoothstep(_Thickness + fw.z, _Thickness, grid.z);
                
                float lineVal = max(lineX, lineZ);
                
                // 2. Gravity Color Shift
                // Shift from Base Color to Red/Orange as Gravity increases
                float3 finalColor = lerp(_Color.rgb, float3(1, 0.2, 0), _GravityOverlay);
                
                // 3. Final Alpha
                // Multiply by lineVal (shape) and _Alpha (fade)
                float alpha = lineVal * _Color.a * _Alpha;
                
                return fixed4(finalColor, alpha);
            }
            ENDCG
        }
    }
}
