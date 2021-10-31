Shader "Custom/StereoGraphic"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _ColorProj("Projected Color", Color) = (1,0,0,1)
        _ColorConn("Connection Color", Color) = (.5,.5,.5,1)
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0
        _BaseMap("Base Map", 2D) = "white"
        _StrokeType("Stroke Type", int) = 0
        _StrokeWidth("Stroke Width", float) = 0.02
        _DrawConn("Draw Connections", int) = 0
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
                #include "complex.hlsl"

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
                    nointerpolation float segmentType : int;
                };


                // This macro declares _BaseMap as a Texture2D object.
                TEXTURE2D(_BaseMap);
                // This macro declares the sampler for the _BaseMap texture.
                SAMPLER(sampler_BaseMap);

                half _Glossiness;
                half _Metallic;
                half4 _Color;
                half4 _ColorProj;
                half4 _ColorConn;
                int _StrokeType;
                float _StrokeWidth;
                int _DrawConn;
                
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

                void ProjectVertexToSubspace(inout float3 v, in int strokeType)
                {
                    if (strokeType == 0)    // Plane
                        v.y = 0;
                    else                    // Sphere
                    {
                        v = normalize(v);
                    }
                }

                float3 GetVertexNormal(in float3 v, in int strokeType)
                {
                    if (strokeType == 0)        // Plane
                        return float3(0, 1, 0);
                    else                        // Sphere
                        return v;
                }

                void AddSegmentToStream(
                    in float3 v0, in float3 v1,
                    in float3 N0, in float3 N1,
                    in float2 uv0, in float2 uv1,
                    in float width,
                    in int segmentType,
                    inout TriangleStream<Varyings> triStream)
                {
                    float3 T = v1 - v0;
                    float3 B0 = 0.5f * width * normalize(cross(T, N0));
                    float3 B1 = 0.5f * width * normalize(cross(T, N1));

                    float3 out0 = v0 + B0;
                    float3 out1 = v0 - B0;
                    float3 out2 = v1 + B0;
                    float3 out3 = v1 - B0;

                    Varyings o;

                    o.positionHCS = TransformObjectToHClip(out0);
                    o.normal = TransformObjectToWorldNormal(N0);
                    o.uv = uv0;
                    o.segmentType = segmentType;
                    triStream.Append(o);

                    o.positionHCS = TransformObjectToHClip(out2);
                    o.normal = TransformObjectToWorldNormal(N1);
                    o.uv = uv1;
                    o.segmentType = segmentType;
                    triStream.Append(o);

                    o.positionHCS = TransformObjectToHClip(out1);
                    o.normal = TransformObjectToWorldNormal(N0);
                    o.uv = uv0;
                    o.segmentType = segmentType;
                    triStream.Append(o);

                    o.positionHCS = TransformObjectToHClip(out3);
                    o.normal = TransformObjectToWorldNormal(N1);
                    o.uv = uv1;
                    o.segmentType = segmentType;
                    triStream.Append(o);

                    triStream.RestartStrip();

                    o.positionHCS = TransformObjectToHClip(out0);
                    o.normal = -TransformObjectToWorldNormal(N0);
                    o.uv = uv0;
                    o.segmentType = segmentType;
                    triStream.Append(o);

                    o.positionHCS = TransformObjectToHClip(out1);
                    o.normal = -TransformObjectToWorldNormal(N0);
                    o.uv = uv0;
                    o.segmentType = segmentType;
                    triStream.Append(o);

                    o.positionHCS = TransformObjectToHClip(out2);
                    o.normal = -TransformObjectToWorldNormal(N1);
                    o.uv = uv1;
                    o.segmentType = segmentType;
                    triStream.Append(o);

                    o.positionHCS = TransformObjectToHClip(out3);
                    o.normal = -TransformObjectToWorldNormal(N1);
                    o.uv = uv1;
                    o.segmentType = segmentType;
                    triStream.Append(o);

                    triStream.RestartStrip();
                }

                [maxvertexcount(32)]
                void geom(triangle Geometry input[3], inout TriangleStream<Varyings> triStream)
                {
                    float3 v0 = input[0].position.xyz / input[0].position.w;
                    float3 v1 = input[1].position.xyz / input[1].position.w;
                    ProjectVertexToSubspace(v0, _StrokeType);
                    ProjectVertexToSubspace(v1, _StrokeType);
                    
                    float3 N0 = GetVertexNormal(v0, _StrokeType);
                    float3 N1 = GetVertexNormal(v1, _StrokeType);
                    
                    // Draw the segment
                    AddSegmentToStream(
                        v0, v1, 
                        N0, N1, 
                        input[0].uv, input[1].uv, 
                        _StrokeWidth,
                        0,
                        triStream);

                    float3 v0p, v1p, N0p, N1p;
                    if (_StrokeType == 0)
                    {
                        v0p = StereographicPtoS(v0.xz).xzy;
                        v1p = StereographicPtoS(v1.xz).xzy;
                    }
                    else
                    {
                        float2 z0 = StereographicStoP(v0.xzy);
                        v0p = float3(z0.x, 0, z0.y);
                        float2 z1 = StereographicStoP(v1.xzy);
                        v1p = float3(z1.x, 0, z1.y);
                    }

                    N0p = GetVertexNormal(v0p, 1 - _StrokeType);
                    N1p = GetVertexNormal(v1p, 1 - _StrokeType);

                    // Draw the segment's projection
                    AddSegmentToStream(
                        v0p, v1p,
                        N0p, N1p,
                        input[0].uv, input[1].uv, 
                        _StrokeWidth,
                        1,
                        triStream);


                    if (_DrawConn == 0)
                        return;

                    // Now draw the connections b/w the points on the segment and the connection
                    float3 N = float3(1, 0, 0);
                    
                    float3 v;
                    float3 north = float3(0, 1, 0);
                    if (dot(v0 - north, v0 - north) > dot(v0p - north, v0p - north))
                        v = v0;
                    else
                        v = v0p;
                    
                    float3 T0 = v - north;
                    float T0mag2 = dot(T0, T0);
                    
                    if (T0mag2 > 1e-6f)
                    {
                        T0 = normalize(T0);
                        // T0 almost vertical
                        if (abs(T0.y) > .99f)
                            N = cross(T0, float3(1, 0, 0));
                        else
                            N = cross(T0, float3(0, 1, 0));


                        AddSegmentToStream(
                            v, north,
                            N, N,
                            input[0].uv, input[0].uv,
                            0.03125f * _StrokeWidth,
                            2,
                            triStream);
                    }
                }

                half4 frag(Varyings IN) : SV_Target
                {
                    half4 color = _Color;
                    if (IN.segmentType == 1)
                        color = _ColorProj;
                    else if (IN.segmentType == 2)
                        color = _ColorConn;
                    return color;
                }



                ENDHLSL
            }
        }
}