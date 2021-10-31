Shader "Custom/Meromorphic"
{
	Properties
	{
		_ColorA("ColorA", Color) = (1,1,1,1)
		_ColorB("ColorB", Color) = (0,0,0,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_pu("p.u", Range(-1, 1)) = 0.0
		_pv("p.v", Range(-1, 1)) = 0.0
		_degree("Degree", Int) = 1
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 200

		CGPROGRAM

		#include "UnityCG.cginc"
		#include "complex.hlsl"
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input
		{
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _ColorA;
		fixed4 _ColorB;
		float _pu;
		float _pv;
		int _degree;

		static const float PI = 3.14159265f;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)


		float random(float2 uv)
		{
			return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453123);
		}

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			float2 uv = IN.uv_MainTex;
			float2 z = 2*uv - float2(1, 1);

			float2 p = float2(_pu, _pv);
			float R = 0.9f;
			float t = 2 * PI * _Time[0];


			float2 q = p + float2(R * cos(t), R * sin(t));


			
			int k = min(_degree+1, 10);
			float2 coeffa[10];
			float2 coeffb[10];
			float2 seed;
			float num1, num2, num3, num4;
			for (int i = 0; i < k; ++i)
			{
				coeffa[i] = float2(0, 0);
				coeffb[i] = float2(0, 0);
			}
			
			coeffa[0] = -cpow(p, k);
			coeffb[0] = -cpow(q, k);
			//coeffa[1] = float2(1, 0);
			//coeffb[1] = float2(1, 0);

			for (i = 1; i < k; ++i)
			{
				seed[0] = seed[1] = 4*i;
				num1 = 10*random(seed);
				seed[0] = seed[1] = 4 * i + 1;
				num2 = random(seed);
				seed[0] = seed[1] = 4 * i + 2;
				num3 = 10 * random(seed);
				seed[0] = seed[1] = 4 * i + 3;
				num4 = random(seed);
				coeffa[i] = float2(num2 * cos(num1 * t), num2 * sin(num1 * t));
				coeffb[i] = float2(num4 * cos(num3 * t), num4 * sin(num3 * t));
			}


			float2 num;
			float2 denom;

			num = cpolyeval(z, coeffa, k);
			denom = cpolyeval(z, coeffb, k);

			float alpha;

			if (cmag2(denom) < 1e-6f)
				alpha = 0.0f;
			else
				alpha = clogim(cdiv(num, denom)) / PI;

			fixed4 neutral = fixed4(0, 0, 0, 1);
			// Albedo comes from a texture tinted by color
			//fixed alpha = sin(_Time[1]);
			fixed4 color;

			if (alpha < 0.0)
				color = lerp(neutral, _ColorA, -alpha);
			else
				color = lerp(neutral, _ColorB, alpha);

			if (cmag2(denom) < 1e-6f)
				color = float4(1,1,1,1);

			//color = color * tex2D(_MainTex, uv);

			o.Albedo = color.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = color.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
