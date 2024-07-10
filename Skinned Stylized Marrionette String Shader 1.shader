// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Skinned Stylized Marrionette String Shader" 
{
    Properties 
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Color ("Color (RGBA)", Color) = (1, 1, 1, 1) // add _Color property
        _PeakColor ("PeakColor (RGBA)", Color) = (1, 1, 1, 1) // add _Color property
        _PeakColorAmount  ("PeakColor Amount", Range(0, 1)) = 1
        _DebugScale ("Segment Sizes", Range(0, 100)) = 10
        _viewAngleFactor ("ScreenSpace Factor", Range(-100, 100)) = 10
        _sectionWidth("Section Width", Range(-10, 10)) = 3
        _animSpeed("Animation Speed", Range(0, 10)) = 1
        _animOffset("Animation Offset", Range(0, 1000)) = 1

        _xPosScale ("xPosAffect", Range(-10, 10)) = 1.2
        _yPosScale ("yPosAffect", Range(-10, 10)) = -1.5

    }

    SubShader 
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        Cull off 
        LOD 100

        Pass 
        {
            CGPROGRAM

            #pragma vertex vert alpha
            #pragma fragment frag alpha
            #pragma geometry geom

            #include "UnityCG.cginc"

            struct appdata_t 
            {
                float4 vertex   : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal   : NORMAL;
            };

            struct v2g
            {
                float4 vertex  : SV_POSITION;
                half2 texcoord : TEXCOORD0;
                float  angle      : TEXCOORD2;
            };

            struct g2f 
            {
                float4 vertex  : SV_POSITION;
                half2 texcoord : TEXCOORD0;
                float4 world_pos : TEXCOORD1;
                float  angle      : TEXCOORD2;
            };

            

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _DebugScale;
            float _viewAngleFactor;
            float _sectionWidth;
            float _animSpeed;
            float4 _PeakColor;
            float _PeakColorAmount;
            float _animOffset;
            float _xPosScale;
            float _yPosScale;

            float3x3 AngleAxis3x3(float angle, float3 axis)
            {
                float c, s;
                sincos(angle, s, c);

                float t = 1 - c;
                float x = axis.x;
                float y = axis.y;
                float z = axis.z;

                return float3x3(
                    t * x * x + c,      t * x * y - s * z,  t * x * z + s * y,
                    t * x * y + s * z,  t * y * y + c,      t * y * z - s * x,
                    t * x * z - s * y,  t * y * z + s * x,  t * z * z + c
                );
            }

            // returns a value (0, 1)
            float nonPeriodic(float phase)
            {
                return (sin(phase) + sin(UNITY_PI  * phase) / 4) + 0.5 + (sin(phase) + sin(UNITY_PI * 0.2  * phase) / 4) + 0.5;
            }

            v2g vert (appdata_t v)
            { 
                // Referenced https://github.com/Toocanzs/Vertical-Billboard?tab=readme-ov-fileGitHub for having mesh always face camera
                // Thanks to Toocanzs and Nestorboy

                v2g o;

                v.texcoord.x = 1 - v.texcoord.x;
                o.texcoord   = TRANSFORM_TEX(v.texcoord, _MainTex);


                // dir from cam to obj
                // float3 forward = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz);
                
                // // right of dir to obj
                // float3 right = cross(forward, float3(0, 1, 0));

                // // camera yaw
                // float yawCamera = atan2(right.x, forward.x) - UNITY_PI / 2;//Add 90 for quads to face towards camera

                // float sy, cy;
                // sincos(yawCamera, sy, cy);

                // float sx, cx;
                // sincos( 0, sx, cx);

                // // Transposed is the same as inverse for orthogonal matricies (ObjectToWorld is orthogoanl)
                // float3x3 transposed = transpose((float3x3)unity_ObjectToWorld);
                // float3 scale = float3(length(transposed[0]), length(transposed[1]), length(transposed[2]));

                // // Create new Basis vectors
                // float3x3 newBasis = float3x3(
                //     float3(cy * scale.x ,      0,           sy * scale.z ),
                //     float3(0,                  1 * scale.y,            0 ),
                //     float3(-sy * scale.x ,     0,           cy * scale.z )
                // );//Rotate yaw to point towards camera, and scale by transform.scale


                // float4x4 objectToWorld = unity_ObjectToWorld;
                // //Overwrite basis vectors so the object rotation isn't taken into account
                // // objectToWorld[0].xyz = newBasis[0];
                // // objectToWorld[1].xyz = newBasis[1];
                // // objectToWorld[2].xyz = newBasis[2];

                o.vertex = v.vertex;

                o.angle = abs(dot(v.normal, UNITY_MATRIX_V[2].xyz)) + abs(dot(v.normal, UNITY_MATRIX_V[1].xyz));

                return o;
            }

            float3x3 getNewBasis(float3 tri_pos, float3 rot_axis)
            {
                float3x3 newBasis;
                
                // dir from cam to obj
                float3 forward = normalize(_WorldSpaceCameraPos - tri_pos);
                
                // right of dir to obj
                float3 right = cross(forward, float3(0, 1, 0));

                // camera yaw
                float yawCamera = atan2(right.x, forward.x) - UNITY_PI / 2;//Add 90 for quads to face towards camera

                float sy, cy;
                sincos(yawCamera, sy, cy);


                return newBasis;
            }

            [maxvertexcount(3)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> triStream)
            {
                g2f o;
                
                for(int i = 0; i < 3; i++)
                {
                    o.texcoord = input[i].texcoord;
                    o.world_pos = mul(UNITY_MATRIX_M, input[i].vertex);
                    o.vertex = mul(UNITY_MATRIX_VP,  o.world_pos);
                    o.angle = input[i].angle;
                    triStream.Append(o);
                }
 
                triStream.RestartStrip();
            }


            fixed4 frag (g2f i) : SV_Target
            {   
                fixed4 col;

                float viewAngleOffset = (i.angle) * _viewAngleFactor;

                
                col.w = smoothstep(
                        0, 
                        1, 
                        nonPeriodic(
                            (i.world_pos.y * _DebugScale) + nonPeriodic(_Time.w * _animSpeed + (i.world_pos.x * _xPosScale) + (i.world_pos.y * _yPosScale) + _animOffset
                        ) + viewAngleOffset) + _sectionWidth
                );

                col.w *= sin(i.texcoord.x * UNITY_PI);

                // Figure out color
                col.xyz = lerp(_Color, _PeakColor, col.w - _PeakColorAmount);

                return fixed4(1, 0, 0, 1);
            }

            ENDCG
        }
    }
}