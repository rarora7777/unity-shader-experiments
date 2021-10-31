Shader "Custom/StrokeGeometry"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0
        _BaseMap("Base Map", 2D) = "white"
        _StrokeType("Stroke Type", int) = 0
        _StrokeWidth("Stroke Width", float) = 0.02
    }

        SubShader
        {
            Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

            Pass
            {
                HLSLPROGRAM
                #pragma vertex vert
                #pragma geometry geom
                #pragma fragment frag

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

                struct Attributes
                {
                    float4 positionOS   : POSITION;
                    // The uv variable contains the UV coordinate on the texture for the
                    // given vertex.
                    float2 uv           : TEXCOORD0;
                };

                struct Geometry
                {
                    float4 position  : POSITION;
                    // The uv variable contains the UV coordinate on the texture for the
                    // given vertex.
                    float2 uv           : TEXCOORD0;
                };

                struct Varyings
                {
                    float4 positionHCS  : SV_POSITION;
                    float3 normal       : NORMAL;
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
                half4 _Color;
                int _StrokeType;
                float _StrokeWidth;
                
                //#define PI 3.14159265f;

                CBUFFER_START(UnityPerMaterial)
                    // The following line declares the _BaseMap_ST variable, so that you
                    // can use the _BaseMap variable in the fragment shader. The _ST 
                    // suffix is necessary for the tiling and offset function to work.
                    float4 _BaseMap_ST;
                CBUFFER_END

                Geometry vert(Attributes IN)
                {
                    Geometry OUT;
                    OUT.position = IN.positionOS;
                    // The TRANSFORM_TEX macro performs the tiling and offset
                    // transformation.
                    OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                    return OUT;
                }

                [maxvertexcount(4)]
                void geom(triangle Geometry input[3], inout TriangleStream<Varyings> triStream)
                {
                    Varyings o;
                    float3 v0 = input[0].position.xyz / input[0].position.w;
                    float3 v1 = input[1].position.xyz / input[1].position.w;
                    if (_StrokeType == 0)
                    {
                        v0.y = 0;
                        v1.y = 0;
                    }
                    else
                    {
                        v0 = normalize(v0);
                        v1 = normalize(v1);
                    }
                    float3 T = v1 - v0;
                    float3 N0 = float3(0, 1, 0);
                    float3 N1 = float3(0, 1, 0);
                    if (_StrokeType == 1)
                    {
                        N0 = v0;
                        N1 = v1;
                    }

                    float3 B0 = 0.5 * _StrokeWidth * normalize(cross(T, N0));
                    float3 B1 = 0.5 * _StrokeWidth * normalize(cross(T, N1));

                    float3 out0 = v0 + B0;
                    float3 out1 = v0 - B0;
                    float3 out2 = v1 + B0;
                    float3 out3 = v1 - B0;

                    
                    o.positionHCS = TransformObjectToHClip(out0);
                    o.normal = TransformObjectToWorldNormal(N0);
                    o.uv = input[0].uv;
                    triStream.Append(o);
                    
                    o.positionHCS = TransformObjectToHClip(out2);
                    o.normal = TransformObjectToWorldNormal(N1);
                    o.uv = input[1].uv;
                    triStream.Append(o);

                    o.positionHCS = TransformObjectToHClip(out1);
                    o.normal = TransformObjectToWorldNormal(N0);
                    o.uv = input[0].uv;
                    triStream.Append(o);

                    o.positionHCS = TransformObjectToHClip(out3);
                    o.normal = TransformObjectToWorldNormal(N1);
                    o.uv = input[1].uv;
                    triStream.Append(o);
                    
                    triStream.RestartStrip();

                }

                half4 frag(Varyings IN) : SV_Target
                {
                    half4 color = _Color;
                    return color;
                }



                ENDHLSL
            }
        }
}