/*
    Blue Planet - Tony Monckton
    MIT licence

    Copyright 2022 Tony Monckton

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
    modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
    Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
    WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
    ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
Shader "TM/PlanetShader"
{
    Properties
    {
        _UseBumpMap ("__Use Bump Map__", int) = 1
        _BumpMap ("Bumpmap",        2D) = "bump" {}
        _Contrast ("Contrast",      Range(0,5)) = 1.0
        _Brightness ("Brightness",  Range(0,5)) = 1.0
        _Glossiness ("Smoothness",  Range(0,1)) = 0.5
        _Metallic ("Metallic",      Range(0,1)) = 0.0
        
        _Scale ("Surface Scale", Range(0,100))   = 1.0
        _Octaves("Surface Octaves", Range(1,50) ) = 8
        _Color ("Surface Color", Color)    = (1,1,1,1)
        _SeaLevelColor ("SeaLevel Color", Color)    = (1,1,1,1)
        _Alpha("Surface Alpha", Range(0, 1.0))  = 1.0

        [MaterialToggle]
        _UseRimEffect ("__Use Rim Effect__", float) = 1
        _RimColor ("Rim Color", Color) = (0,0.5,0.5,1.0)
        _RimPower ("Rim Power", Range(0.0,8.0)) = 3.0
    }
    SubShader
    {
        Tags 
        {
            "RenderType"="Opaque" 
        }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma target 3.5

        float   _Contrast;
        float   _Brightness;
        float   _Scale;
        int     _Octaves;
        float4  _Color;
        float4  _SeaLevelColor;
        float   _Alpha;

        float   _UseRimEffect;
        float4  _RimColor;
        float   _RimPower;

        sampler2D _BumpMap;

        half _Glossiness;
        half _Metallic;

        struct Input
        {
            float2 uv_BumpMap;
            float3 localPos;
            float3 viewDir;
            float4 worldPos;
            float3 worldNormal; INTERNAL_DATA
        };

        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            o.localPos = v.vertex.xyz;
            o.viewDir   = normalize(UnityWorldSpaceViewDir(o.worldPos));
        }

        float hash( float n )
        {
            return frac(sin(n)*43758.5453);
        }

        // The noise function returns a value in the range -1.0f -> 1.0f
        float noise3( float3 x )
        {
            float3 p = floor(x);
            float3 f = frac(x);

            f       = f*f*(3.0-2.0*f);
            float n = p.x + p.y*57.0 + 113.0*p.z;

            return  lerp(lerp(lerp( hash(n+0.0), hash(n+1.0),f.x),
                    lerp( hash(n+57.0), hash(n+58.0),f.x),f.y),
                    lerp(lerp( hash(n+113.0), hash(n+114.0),f.x),
                    lerp( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
        }

        float fractal3(float3 v, float o, float s, float om = 2.0f) 
        {
            float n = 0.0f;
            float oct = 1.0f;
            v *= s;
            
            for (float octave=0.0; octave<o; octave++) 
            {
                n += abs(noise3(v*oct))/oct;
                oct *= om;
            }
            return n;
        }

        float constast(float x, float gain) 
        {
            const float a = 0.5*pow(2.0*((x<0.5)?x:1.0-x), gain);
            return (x<0.5)?a:1.0-a;
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float3 localPos = IN.localPos; 
            float fNoise = fractal3(localPos, _Octaves, _Scale);
            float surface = sin( localPos.x*1.295234f*localPos.y*(localPos.z*0.5342f) *_Scale + 1.0f/fNoise );

            fixed4 nc = lerp(_SeaLevelColor, _Color, surface);
            nc.a = _Alpha;

            float3 normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
            float4 emmision = _RimColor;

            if (_UseRimEffect)
            {
                half rim    = 1.0f - saturate(dot(normalize(IN.viewDir), o.Normal));
                nc.xyz  = nc.xyz + (_RimColor.rgb * pow(rim, _RimPower));
                emmision    = _RimColor * pow(rim, _RimPower);
            }

            //o.Normal = normalize(normal);
            o.Albedo = nc.rgb * _Brightness;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = nc.a*_Alpha;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
