Shader "Custom/MeromorphicURP"
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
        _BaseMap("Base Map", 2D) = "white"
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                // The uv variable contains the UV coordinate on the texture for the
                // given vertex.
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                // The uv variable contains the UV coordinate on the texture for the
                // given vertex.
                float2 uv           : TEXCOORD0;
            };


            // This macro declares _BaseMap as a Texture2D object.
            TEXTURE2D(_BaseMap);
            // This macro declares the sampler for the _BaseMap texture.
            SAMPLER(sampler_BaseMap);

            half _Glossiness;
            half _Metallic;
            half4 _ColorA;
            half4 _ColorB;
            float _pu;
            float _pv;
            int _degree;

            //#define PI 3.14159265f;

            CBUFFER_START(UnityPerMaterial)
                // The following line declares the _BaseMap_ST variable, so that you
                // can use the _BaseMap variable in the fragment shader. The _ST 
                // suffix is necessary for the tiling and offset function to work.
                float4 _BaseMap_ST;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // The TRANSFORM_TEX macro performs the tiling and offset
                // transformation.
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

			float cmag2(float2 a)
			{
				return a[0] * a[0] + a[1] * a[1];
			}

			float cmag(float2 a)
			{
				return sqrt(cmag2(a));
			}

			float carg(float2 a)
			{
				return atan2(a[1], a[0]);
			}

			float2 cmul(float2 a, float2 b)
			{
				float2 res;
				float a0b0 = a[0] * b[0];
				float a1b1 = a[1] * b[1];
				res[0] = a0b0 - a1b1;
				res[1] = (a[0] + a[1]) * (b[0] + b[1]) - a0b0 - a1b1;
				return res;
			}

			float2 cdiv(float2 a, float2 b)
			{
				float2 res;
				res[0] = a[0] * b[0] + a[1] * b[1];
				res[1] = a[1] * b[0] - a[0] * b[1];
				float b2 = cmag2(b);
				return res / b2;
			}

			float clogre(float2 a)
			{
				return log(cmag(a));
			}

			float clogim(float2 a)
			{
				return atan2(a[1], a[0]);
			}

			float2 clog(float2 a)
			{
				return float2(clogre(a), clogim(a));
			}

			float2 cpow(float2 a, int n)
			{
				float2 res = float2(1, 0);
				uint n0;

				if (n == 0)
					return float2(1, 0);
				else if (n < 0)
				{
					if (cmag2(a) < 1e-6)
						return float2(0, 0);
					a = cdiv(res, a);
					n = -n;
				}

				n0 = n;

				while (n0 > 1)
				{
					if (n0 % 2 == 0)
					{
						a = cmul(a, a);
						n0 = n0 / 2;
					}
					else
					{
						res = cmul(a, res);
						a = cmul(a, a);
						n0 = (n0 - 1) / 2;
					}
				}
				return cmul(a, res);
			}

			float2 cpolyeval(float2 z, float2 coeff[10], int k)
			{
				float2 res = float2(0.0f, 0.0f);
				for (int i = 0; i < k; ++i)
				{
					res += cmul(coeff[i], cpow(z, i));
				}

				return res;
			}

			float random(float2 uv)
			{
				return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453123);
			}

            half4 frag(Varyings IN) : SV_Target
            {
                
				float2 uv = IN.uv;
				float2 z = 2 * uv - float2(1, 1);

				float2 p = float2(_pu, _pv);
				float R = 0.9f;
				float t = 2 * PI * _Time[0];


				float2 q = p + float2(R * cos(t), R * sin(t));



				int k = min(_degree + 1, 10);
				float2 coeffa[10];
				float2 coeffb[10];
				float2 seed;
				float num1, num2, num3, num4;
				int i;
				for (i = 0; i < k; ++i)
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
					seed[0] = seed[1] = 4 * i;
					num1 = 10 * random(seed);
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

				half4 neutral = half4(0, 0, 0, 1);
				half4 color;

				if (alpha < 0.0)
					color = lerp(neutral, _ColorA, -alpha);
				else
					color = lerp(neutral, _ColorB, alpha);

				if (cmag2(denom) < 1e-6f)
					color = half4(1,1,1,1);
            
				return color;
			}



            ENDHLSL
        }
    }  
}
