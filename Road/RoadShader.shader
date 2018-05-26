Shader "Hidden/RoadShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_RoadTime("Time", Float) = 0.0
		_Curve("Curve", Float) = 1.0
		_DrawDistance("Draw Distance", Float) = .04
		_DDX("DDX", Float) = 1.0
		_DDY("DDY", Float) = 1.0
		_SideStripSize("Side Strip Size", Float) = 0.4
		_CenterStripSize("Center Strip Size", Float) = .004
		_RoadSize("Road Size", Float) = 1.0
		_FogSize("Fog Size", Float) = 0.1

		_GrassStripColor1("Grass Strip Color 1", Color) = (0.3, 0.4, 0.5)
		_GrassStripColor2("Grass Strip Color 2", Color) = (0.3, 0.2, 0.5)

		_SideStripColor1("Side Strip Color 1", Color) = (0.1, 0.2, 0.4)
		_SideStripColor2("Side Strip Color 2", Color) = (0.1, 0.2, 0.8)

		_RoadStripColor1("Road Strip Color 1", Color) = (0.5, 0.3, 0.1)
		_RoadStripColor2("Road Strip Color 2", Color) = (0.3, 0.3, 0.5)

		_CenterStripColor("Center Strip Color", Color) = (1.0, 1.0, 1.0)

		_FogColor1("Fog Color 1", Color) = (.4, .5, .5)
		_FogColor2("Fog Color 2", Color) = (.6, .7, .8)

		//These default values are mostly just random numbers and can produce strange looking road,
		//use prefab included for nice values
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

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
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;

			float _Curve, _RoadTime, _DrawDistance, _Offset, _DDX, _DDY, _SideStripSize, _CenterStripSize, _RoadSize, _FogSize;
			fixed4 _GrassStripColor1, _GrassStripColor2, _SideStripColor1, _SideStripColor2, _RoadStripColor1, _RoadStripColor2, _CenterStripColor;
			fixed4 _FogColor1, _FogColor2;

			fixed3 fog(fixed3 d) {
				float l = d.y - _DrawDistance;
				return lerp(_FogColor1.xyz, _FogColor2.xyz, l);
			}

			fixed4 frag (v2f i) : SV_Target
			{
				//this is shader from shadertoy adapted to work with unity (link to original: https://www.shadertoy.com/view/XtlGW4)

				fixed4 f = fixed4(0.0, 0.0, 0.0, 1.0);
				
				fixed3 q = fixed3(_DDX, _DDY, 0.0);
				fixed3 d = fixed3(i.uv.xy - (0.5) * q.xy, q.y) / (q.y);
				
				q = (d) / (.1 - d.y);
				//float a = _RoadTime; 
				//float k = _Curve;

				//auto scrolling, just uncomment this if you want this effect (and comment a, k above)
				float a = _Time * _RoadTime; //_RoadTime behaves there as time multiplayer
				float k = _Curve * (sin(a) * 1.1); //auto generate curves on road using sin function

				float w = q.x *= q.x -= 0.001 * k * k * k * q.z * q.z; //calculate current x coord
				w *= _RoadSize;
				
				fixed3 background_color = fog(d); //instead of fog(d) you can just put static background color (for example fixed3(0.6, 0.7, 0.8))

				//determine which piece of road is calculated here and grab proper color for that piece 
				f.xyz = d.y > _DrawDistance ? background_color :
				sin(2.0 * q.z + 30.0 * a) > 0.0 ?
				w > 1.0 + _SideStripSize ? _GrassStripColor1 : w > 1.0 ? _SideStripColor1 : _RoadStripColor1 :
				w > 1.0 + _SideStripSize ? _GrassStripColor2 : w > 1.0 ? _SideStripColor2 : (w > _CenterStripSize ? _RoadStripColor2 : _CenterStripColor).xyz;

				//lerp background with road to achieve fog effect, if you don't need this just remove whole if statement
				float fog_distance = _FogSize;
				if (d.y + fog_distance > _DrawDistance) {
					float alpha = clamp(1.0 - (d.y / (_DrawDistance + fog_distance)), 0.0, 1.0);
					f.xyz = lerp(background_color, f.xyz, alpha);
				}

				return f;
			}
				
			ENDCG
		}
	}
}
