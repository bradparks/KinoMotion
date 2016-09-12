Shader "Custom/Spinner"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo (RGB)", 2D) = "white"{}
        _Rotation("Angular Velocity", Float) = 180
    }

    CGINCLUDE

    #include "UnityCG.cginc"

    sampler2D _MainTex;
    fixed4 _Color;
    float _Rotation;

    float4x4 _NonJitteredVP;
    float4x4 _PreviousVP;
    float4x4 _PreviousM;
    float _MotionScale;

    struct appdata_motion
    {
        float4 vertex : POSITION;
        float2 texcoord1 : TEXCOORD1;
    };

    struct v2f_motion
    {
        float4 vertex : SV_POSITION;
        float4 transfer0 : TEXCOORD0;
        float4 transfer1 : TEXCOORD1;
    };

    v2f_motion vert_motion(appdata_motion v)
    {
        float ry = _Rotation * UNITY_PI / (180 * 60);

        float4x4 rm = {
            cos(ry), 0, sin(ry), 0,
            0, 1, 0, 0,
            -sin(ry), 0, cos(ry), 0,
            0, 0, 0, 1
        };

        float4 p0 = mul(rm, v.vertex);
        float4 p1 = v.vertex;

        v2f_motion o;
        o.vertex = UnityObjectToClipPos(p1);
        o.transfer0 = mul(_PreviousVP, mul(_PreviousM, p0));
        o.transfer1 = mul(_NonJitteredVP, mul(unity_ObjectToWorld, p1));
        return o;
    }

    half4 frag_motion(v2f_motion i) : SV_Target
    {
        float3 hp0 = i.transfer0.xyz / i.transfer0.w;
        float3 hp1 = i.transfer1.xyz / i.transfer1.w;

        float2 vp0 = (hp0.xy + 1) / 2;
        float2 vp1 = (hp1.xy + 1) / 2;

    #if UNITY_UV_STARTS_AT_TOP
        vp0.y = 1 - vp0.y;
        vp1.y = 1 - vp1.y;
    #endif

        return half4(vp1 - vp0, 0, 1);
    }

    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags { "LightMode" = "MotionVectors" }
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert_motion
            #pragma fragment frag_motion
            #pragma target 3.0
            ENDCG
        }

        CGPROGRAM

        #pragma surface surf Standard fullforwardshadows nolightmap
        #pragma target 3.0

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
        }

        ENDCG
    }
    FallBack "Diffuse"
}
