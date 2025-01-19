#version 450

layout(location = 0) in vec3 f_WorldNormal;
layout(location = 1) in vec2 f_Texcoord;
layout(location = 2) in vec4 f_WorldPos;
layout(location = 3) in vec3 f_WorldTangent;
layout(location = 4) in vec3 f_WorldBioTangent;
layout(location = 5) in vec4 f_LightSpacePos;

layout(location = 0) out vec4 outColor;


layout(binding = 0) uniform UniformBufferObject{
	mat4 model;
    mat4 view;
    mat4 proj;
	mat4 lightVMat;
	mat4 lightPMat;

	vec4 lightDir;
	vec4 lightColor;
	vec4 cameraPos;

	vec4 baseColorFactor;
	vec4 emissiveFactor;
	vec4 spatialCullPos;
	vec4 ambientColor;

    float time;
    float metallicFactor;
    float roughnessFactor;
    float normalMapScale;

	float occlusionStrength;
    float mipCount;
    float ShadowMapX;
    float ShadowMapY;

	float emissiveStrength;

    int   useBaseColorTexture;
    int   useMetallicRoughnessTexture;
    int   useEmissiveTexture;
    int   useNormalTexture;
    
    int   useOcclusionTexture;
    int   useCubeMap;
    int   useShadowMap;
    int   useIBL;

    int   useSkinMeshAnimation;
    int   useDirCubemap;
    int   useSpatialCulling;
    int   pad2;
} ubo;

#ifdef USE_OPENGL
layout(binding = 2) uniform sampler2D baseColorTexture;
layout(binding = 4) uniform sampler2D metallicRoughnessTexture;
layout(binding = 6) uniform sampler2D emissiveTexture;
layout(binding = 8) uniform sampler2D normalTexture;
layout(binding = 10) uniform sampler2D occlusionTexture;
layout(binding = 12) uniform samplerCube cubemapTexture;
layout(binding = 14) uniform sampler2D shadowmapTexture;
layout(binding = 16) uniform sampler2D IBL_Diffuse_Texture;
layout(binding = 18) uniform sampler2D IBL_Specular_Texture;
layout(binding = 20) uniform sampler2D IBL_GGXLUT_Texture;
layout(binding = 22) uniform sampler2D cubeMap2DTexture;
#else
layout(binding = 2) uniform texture2D baseColorTexture;
layout(binding = 3) uniform sampler baseColorTextureSampler;

layout(binding = 4) uniform texture2D metallicRoughnessTexture;
layout(binding = 5) uniform sampler metallicRoughnessTextureSampler;

layout(binding = 6) uniform texture2D emissiveTexture;
layout(binding = 7) uniform sampler emissiveTextureSampler;

layout(binding = 8) uniform texture2D normalTexture;
layout(binding = 9) uniform sampler normalTextureSampler;

layout(binding = 10) uniform texture2D occlusionTexture;
layout(binding = 11) uniform sampler occlusionTextureSampler;

layout(binding = 12) uniform textureCube cubemapTexture;
layout(binding = 13) uniform sampler cubemapTextureSampler;

layout(binding = 14) uniform texture2D shadowmapTexture;
layout(binding = 15) uniform sampler shadowmapTextureSampler;

layout(binding = 16) uniform texture2D IBL_Diffuse_Texture;
layout(binding = 17) uniform sampler IBL_Diffuse_TextureSampler;

layout(binding = 18) uniform texture2D IBL_Specular_Texture;
layout(binding = 19) uniform sampler IBL_Specular_TextureSampler;

layout(binding = 20) uniform texture2D IBL_GGXLUT_Texture;
layout(binding = 21) uniform sampler IBL_GGXLUT_TextureSampler;

layout(binding = 22) uniform texture2D cubeMap2DTexture;
layout(binding = 23) uniform sampler cubeMap2DTextureSampler;
#endif

layout(binding = 24) uniform FragUniformBufferObject{
	mat4 model;
    mat4 view;
    mat4 proj;
	mat4 lightVMat;

    vec4 screenCenter;

    float uvScale;
    float time;
    float fPad1;
    float fPad2;
} f_ubo;

// なんかUnityPBRでもみた値だなぁ
const float MIN_ROUGHNESS = 0.04;
const float PI = 3.14159265;

struct PBRParam
{
	float NdotL;
	float NdotV;
	float NdotH;
	float LdotH;
	float VdotH;
	float perceptualRoughness;
	float metallic;
	vec3 reflectance0;
	vec3 reflectance90;
	float alphaRoughness;
	vec3 diffuseColor;
	vec3 specularColor;
};

// マイクロファセット(微小面法線分布関数)(Microfacet Distribution). Distributionは分布に意味
// 分布関数なので統計学的に求められた数式
// マイクロファセットの面積を返す
// 面積が小さいほどマイクロファセットが散らばっていて荒いということかな？ → 大きいほど凸凹のない一つの平面に近づく
// https://learnopengl.com/PBR/Theory#:~:text=GGX%20for%20G.-,Normal%20distribution%20function,-The%20normal%20distribution
float CalcMicrofacet(PBRParam param)
{
	float roughness2 = param.alphaRoughness * param.alphaRoughness; // グラフの勾配を高くする
	
	//
	float f = (param.NdotH * roughness2 - param.NdotH) * param.NdotH + 1.0;
	// = ( param.NdotH * (roughness2 - 1.0) ) * param.NdotH + 1.0
	// = pow(param.NdotH, 2.0) * (roughness2 - 1.0) + 1.0
	// 数式と同じ形になる. (n・h)^2 * (a^2 - 1) + 1
	
	//
	return roughness2 / (PI * f * f);
}

// 幾何減衰項(Geometric Occlusion)
// マイクロファセットの微小平面が光の経路を遮断することにより失われてしまう光の減衰量を計算する関数
float CalcGeometricOcculusion(PBRParam param)
{
	float NdotL = param.NdotL;
	float NdotV = param.NdotV;
	// 表面が荒いほど、微小平面が増えて光が隠蔽されやすくなる
	float r = param.alphaRoughness;

	// 詳しい数式(https://google.github.io/filament/Filament.md.html#materialsystem/specularbrdf/geometricshadowing(specularg))
	// シャドウイングの項を計算(入射光が他の微小平面に遮られて影になり光が減衰する分)
	float attenuationL = 2.0 * NdotL / ( NdotL + sqrt(r * r + (1.0 - r * r) * (NdotL * NdotL)) );
	// = 2.0 * NdotL / ( NdotL * () )
	// マスキングの項を計算(反射光が他の微小平面に遮られてその光が目に届かないことで減衰する分)
	float attenuationV = 2.0 * NdotV / ( NdotV + sqrt(r * r + (1.0 - r * r) * (NdotV * NdotV)) );

	// 幾何減衰項は上記の乗算結果
	return attenuationL * attenuationV;
}

// フレネル反射(フレネル項). 
// フレネル反射とはView方向に応じて反射率が変化する物理現象のことである 
// ここでのGGX項でのフレネル反射はオブジェクトの端であるほど反射率が高い(反射色が明るい)ことを示している
// https://marmoset.co/posts/basic-theory-of-physically-based-rendering/
// この画像がわかりやすい --> https://marmoset.co/wp-content/uploads/2016/11/pbr_theory_fresnel.png
// GGXのフレネル項の式は、よく光学の分野で見聞きするようなフレネルの式の近似式である(https://ja.wikipedia.org/wiki/%E3%83%95%E3%83%AC%E3%83%8D%E3%83%AB%E3%81%AE%E5%BC%8F)
// https://learnopengl.com/PBR/Theory#:~:text=return%20ggx1%20*%20ggx2%3B%0A%7D-,Fresnel%20equation,-The%20Fresnel%20equation
vec3 CalcFrenelReflection(PBRParam param)
{
	// 基本の反射率: reflectance0
	// それに対して視野方向による反射率の変化分を加算している
	// 割と数式だとreflectance90は1.0なので今はあんまり深く考えなくてもいいかも？
	// もしかしてreflectance90は媒質の屈折率に関係している？真空だと1.0なので、他の数式とかだとひとます真空と仮定している？
	return param.reflectance0 + (param.reflectance90 - param.reflectance0) * pow(clamp(1.0 - param.VdotH, 0.0, 1.0), 5.0);
}

// ディフューズのBRDFを計算
// https://google.github.io/filament/Filament.md.html#materialsystem/diffusebrdf
// この記事によると拡散色のBRDFは近似的に『1.0 / PI』と定まるとのこと
vec3 CalcDiffuseBRDF(PBRParam param)
{
	float oneminus = (1.0 - 0.04) - param.metallic * (1.0 - 0.04);

	return param.diffuseColor * oneminus;
	// return param.diffuseColor / PI;
}

// 法線の取得(ノーマルマップを使うことがある. → ついでに勉強する)
vec3 getNormal()
{
	vec3 nomral = vec3(0.0);

	if(ubo.useNormalTexture != 0)
	{
		// Tangent, SubTangent, Normalで構成される座標変換ベクトルを作成する
		// このような変換行列のことを頭文字をとって TBN Matrix と呼ぶ
		// 法線マップの示す法線方向は常に定数であり、オブジェクトを回転させるとワールド座標上の向きが合わなくなるので、座標変換して正しいものにする必要がある
		// 例えばZ軸正を示す法線マップを持つPlaneオブジェクトをX軸を基準に90度回転させると、法線方向はY軸正になるのが正しいはずなのに、法線マップの値が定数であるため、
		// そのままZ軸正を示しライティングがおかしなことになる
		// https://learnopengl.com/Advanced-Lighting/Normal-Mapping#:~:text=tangent%20space.-,Tangent%20space,-Normal%20vectors%20in
		// TBN Matrixの計算手法
		// 法線は良しなに.
		// 接点と複接線のベクトル方向がサーフェイスのテクスチャ座標の方向と一致しているということを利用して計算する(上記の接線空間の項目より)
		// 三角形の頂点とそのテクスチャ座標から接線と複接線を計算することができる
		// ※ これはメモだが接線空間記事のE1・E2が表すのは面積ではなく、P1・P2・P3を使った『ベクトル』
		// ※ なのでベクトルで三角形が作れれば計算はできるので、実質Planeではなくポリゴン単位で接線の計算を行うことができる
		// Shaderベースの頂点算出はパフォーマンス悪いので、ひとまず計算はCPUで行っている
		// 数式はこれ(https://drive.google.com/file/d/1A4WK5GLRzWRD9yt9_yxSjyz8Yrmb5Is8/view?usp=sharing)

		vec3 t = normalize(f_WorldTangent.xyz);
		vec3 b = normalize(f_WorldBioTangent.xyz);
		vec3 n = normalize(f_WorldNormal.xyz);

		mat3 tbn = mat3(t, b, n);

		#ifdef USE_OPENGL
		nomral = texture(normalTexture, f_Texcoord).rgb;
		#else
		nomral = texture(sampler2D(normalTexture, normalTextureSampler), f_Texcoord).rgb;
		#endif
		
		nomral = normalize( tbn * ((2.0 * nomral - 1.0) * vec3(ubo.normalMapScale, ubo.normalMapScale, 1.0)) );
	}
	else
	{
		nomral = f_WorldNormal;
	}

	return nomral;
}

// Lenearは光学に則した色空間(現実の光の仕組み
// sRGBはモニターに使われる色空間で人間の色の知覚に則している
// LinearよりsRGBの方が明るい
// https://www.willgibbons.com/linear-workflow/#:~:text=sRGB%20is%20a%20non%2Dlinear,curve%20applied%20to%20the%20brightness.
// https://lettier.github.io/3d-game-shaders-for-beginners/gamma-correction.html
vec4 SRGBtoLINEAR(vec4 srgbIn)
{
	return vec4(pow(srgbIn.xyz, vec3(2.2)), srgbIn.a);
}

vec4 LINEARtoSRGB(vec4 srgbIn)
{
	return vec4(pow(srgbIn.xyz, vec3(1.0 / 2.2)), srgbIn.a);
}

float linstep(float min, float max, float v)
{
	return clamp((v - min) / (max - min), 0.0, 1.0);
}

float ReduceLightBleeding(float p_max, float Amount)
{
	return linstep(Amount, 1.0, p_max);
}

vec2 ComputePCF(vec2 uv)
{
	vec2 moments = vec2(0.0);

	vec2 texelSize = vec2(1.0 / ubo.ShadowMapX, 1.0 / ubo.ShadowMapY);

	/*for(float x = -1.0; x <= 1.0; x++)
	{
		for(float y = -1.0; y <= 1.0; y++)
		{
			#ifdef USE_OPENGL
			moments += texture(shadowmapTexture, uv + vec2(x, y) * texelSize).rg;
			#else
			moments += texture(sampler2D(shadowmapTexture, shadowmapTextureSampler), uv + vec2(x, y) * texelSize).rg;
			#endif
		}
	}*/

	#ifdef USE_OPENGL
	moments += texture(shadowmapTexture, uv + vec2(-1.0, -1.0) * texelSize).rg;
	moments += texture(shadowmapTexture, uv + vec2(-1.0, 0.0) * texelSize).rg;
	moments += texture(shadowmapTexture, uv + vec2(-1.0, 1.0) * texelSize).rg;
	moments += texture(shadowmapTexture, uv + vec2(0.0, -1.0) * texelSize).rg;
	moments += texture(shadowmapTexture, uv + vec2(0.0, 0.0) * texelSize).rg;
	moments += texture(shadowmapTexture, uv + vec2(0.0, 1.0) * texelSize).rg;
	moments += texture(shadowmapTexture, uv + vec2(1.0, -1.0) * texelSize).rg;
	moments += texture(shadowmapTexture, uv + vec2(1.0, 0.0) * texelSize).rg;
	moments += texture(shadowmapTexture, uv + vec2(1.0, 1.0) * texelSize).rg;
	#else
	moments += texture(sampler2D(shadowmapTexture, shadowmapTextureSampler), uv + vec2(-1.0, -1.0) * texelSize).rg;
	moments += texture(sampler2D(shadowmapTexture, shadowmapTextureSampler), uv + vec2(-1.0, 0.0) * texelSize).rg;
	moments += texture(sampler2D(shadowmapTexture, shadowmapTextureSampler), uv + vec2(-1.0, 1.0) * texelSize).rg;
	moments += texture(sampler2D(shadowmapTexture, shadowmapTextureSampler), uv + vec2(0.0, -1.0) * texelSize).rg;
	moments += texture(sampler2D(shadowmapTexture, shadowmapTextureSampler), uv + vec2(0.0, 0.0) * texelSize).rg;
	moments += texture(sampler2D(shadowmapTexture, shadowmapTextureSampler), uv + vec2(0.0, 1.0) * texelSize).rg;
	moments += texture(sampler2D(shadowmapTexture, shadowmapTextureSampler), uv + vec2(1.0, -1.0) * texelSize).rg;
	moments += texture(sampler2D(shadowmapTexture, shadowmapTextureSampler), uv + vec2(1.0, 0.0) * texelSize).rg;
	moments += texture(sampler2D(shadowmapTexture, shadowmapTextureSampler), uv + vec2(1.0, 1.0) * texelSize).rg;
	#endif

	moments /= 9.0;

	#ifdef USE_OPENGL
	//moments = texture(shadowmapTexture, uv).rg;
	#else
	//moments = texture(sampler2D(shadowmapTexture, shadowmapTextureSampler), uv ).rg;
	#endif

	return moments;
}

float CalcShadow(vec3 lsp, vec3 nomral, vec3 lightDir)
{
	vec2 moments = ComputePCF(lsp.xy);

	#ifndef USE_OPENGL
	// Vulkan・WebGPUではDepthBufferの値が-1.0 ~ 1.0になっているので0.0 ~ 1.0に補正する
	moments = moments * 0.5 + 0.5;
	#endif

	// マッハバンド対策のShadow Bias
	// ShadowBiasとは深度のオフセットのこと
	// マッハバンドはShawMapの解像度により発生する。複数のフラグメントが光源から比較的離れている場合、深度マップから同じ値をサンプリングする可能性がある。
	// 光の入射角がオクルーダーの法線に対して斜めなとき、上記の理由から例えば少し深度が大きい隣の表面の深度をサンプリングしてしまい、結果ShadowMapの元の深度より大ききなってしまうことで縞々になる(大きいということは影になる, 黒色)
	// その対策でオクルーダーをほんの少しだけ手前にする。手前にすることでShadowmapよりも深度が小さくなるため影になりにくくなる
	// https://drive.google.com/file/d/1tyDT7xQVSYzKnZXt6vvDwt-rlWEjVGDP/view?usp=sharing
	// 床の法線とライト方向の成す角度が垂直になるほど、Biasを強くする
	// https://learnopengl.com/Advanced-Lighting/Shadows/Shadow-Mapping
	float ShadowBias = max(0.0, 0.001 * (1.0 - dot(nomral, lightDir)) );

	float distance = lsp.z - ShadowBias;

	// ShadowMapの深度よりも手前なので普通に描画する
	if(distance <= moments.x)
	{
		return 1.0;
	}
	
	return 0.1;

	/*// 後ろなので影にする
	// バリアンスの計算
	float variance = moments.y - (moments.x * moments.x);
	variance = max(0.005, variance);

	float d = distance - moments.x;
	float p_max = variance / (variance + d * d);

	// 本来影になるところに光がにじんでいるようなアーティファクトが出ることがあるのでその対策
	//p_max = ReduceLightBleeding(0.1, p_max);

	return p_max;*/
}

vec2 CastDirToSt(vec3 Dir)
{
	float pi = 3.1415;

	float theta = acos(Dir.y);
	float phi = atan(Dir.z, Dir.x);

	vec2 st = vec2(phi / (2.0 * pi), theta / pi);

	return st;
}

vec3 ComputeReflectionColor(PBRParam pbrParam, vec3 v, vec3 n)
{
	// 反射カラーを計算
	vec3 reflectColor = vec3(0.0);
	if(ubo.useCubeMap != 0)
	{
		float mipCount = ubo.mipCount;
		float lod = mipCount * pbrParam.perceptualRoughness;
		#ifdef USE_OPENGL
		reflectColor = SRGBtoLINEAR(textureLod(cubemapTexture, reflect(v, n), lod)).rgb;
		#else
		reflectColor = SRGBtoLINEAR(textureLod(samplerCube(cubemapTexture, cubemapTextureSampler), reflect(v, n), lod)).rgb;
		#endif
	}
	else if(ubo.useDirCubemap != 0)
	{
		vec2 st = CastDirToSt(reflect(v, n));
		
		float mipCount = ubo.mipCount;
		float lod = mipCount * pbrParam.perceptualRoughness;
		#ifdef USE_OPENGL
		reflectColor = SRGBtoLINEAR(textureLod(cubeMap2DTexture, st, lod)).rgb;
		#else
		reflectColor = SRGBtoLINEAR(textureLod(sampler2D(cubeMap2DTexture, cubeMap2DTextureSampler), st, lod)).rgb;
		#endif
	}

	return reflectColor;
}

vec2 GetSphericalTexcoord(vec3 Dir)
{
	float pi = 3.1415;

	float theta = acos(Dir.y);
	float phi = atan(Dir.z, Dir.x);

	vec2 st = vec2(phi / (2.0 * pi), theta / pi);

	return st;
}

vec3 ComputeIBL(PBRParam pbrParam, vec3 v, vec3 n) 
{
	float mipCount = ubo.mipCount;
	float lod = mipCount * pbrParam.perceptualRoughness;

	// テクスチャ計算
	#ifdef USE_OPENGL
	vec3 brdf = SRGBtoLINEAR(texture(IBL_GGXLUT_Texture, vec2(pbrParam.NdotV, 1.0 - pbrParam.perceptualRoughness))).rgb;
	vec3 diffuseLight = SRGBtoLINEAR(texture(IBL_Diffuse_Texture, GetSphericalTexcoord(n))).rgb;
	vec3 specularLight = SRGBtoLINEAR(textureLod(IBL_Specular_Texture, GetSphericalTexcoord(reflect(v, n)), lod)).rgb;
	#else
	vec3 brdf = SRGBtoLINEAR(texture(sampler2D(IBL_GGXLUT_Texture, IBL_GGXLUT_TextureSampler), vec2(pbrParam.NdotV, 1.0 - pbrParam.perceptualRoughness))).rgb;
	vec3 diffuseLight = SRGBtoLINEAR(texture(sampler2D(IBL_Diffuse_Texture, IBL_Diffuse_TextureSampler), GetSphericalTexcoord(n))).rgb;
	vec3 specularLight = SRGBtoLINEAR(textureLod(sampler2D(IBL_Specular_Texture, IBL_Specular_TextureSampler), GetSphericalTexcoord(reflect(v, n)), lod)).rgb;
	#endif

	// 
	vec3 diffuse = diffuseLight * pbrParam.diffuseColor;
	vec3 specular = specularLight * (pbrParam.specularColor * brdf.x + brdf.y);

	return specular;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define repeat(p, a) mod(p, a) - a * 0.5
#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))
#define minD 0.001

float cube(vec3 p,vec3 s){
  return length(max(abs(p)-s,0.));
}

vec2 fmod(vec2 p,float r){
  float a=atan(p.x,p.y)+PI/r;
  float n=(2.*PI)/r;
  a=floor(a/n)*n;
  return rot(a)*p;
}


float m1(vec3 p){
 p.xz*=rot(ubo.time);

for(int i=0;i<5;i++){
  p=abs(p)-0.5;
  if(p.x<p.y)p.xy=p.yx;
  if(p.x<p.z)p.xz=p.zx;
  if(p.y<p.z)p.yz=p.zy;

  p.xy=fmod(p.xy,24.0);
  p.x-=abs(p.x)-0.5;
  p.y=abs(p.y)-0.15;

  float t=floor(ubo.time*0.25)+pow(fract(ubo.time*0.25),.5);
  p.xy*=rot(t+0.123);
  p.yz*=rot(ubo.time+0.456);
  p.xz*=rot(ubo.time+.789)*1.025;

  p.z-abs(p.z)-0.45;

}

p.yz=fmod(p.yz,12.0);
p.xz=fmod(p.xz,6.0);

  float m=cube(p,vec3(.5,3.,2.));

  return m;
}

float map(vec3 p){

 p.z-=ubo.time*20.;

   float t=floor(ubo.time*2.0)+pow(fract(ubo.time*2.0),.75);
p.xy*=rot(t);

  p.xy=fmod(p.xy,12.0);
float k=10.5;
p=mod(p,k)-k*0.5;

  float m=m1(p);


  return m;
}

vec3 gn(vec3 p){
  vec2 e=vec2(0.001,0.0);
  return normalize(vec3(
      map(p+e.xyy)-map(p-e.xyy),
      map(p+e.yxy)-map(p-e.yxy),
      map(p+e.yyx)-map(p-e.yyx)
    ));
}

void main(){
    vec3 col = vec3(0.0);

	// ラフネスとメタリックを取得。テクスチャにパッキングされていることもある
	float perceptualRoughness = ubo.roughnessFactor;
	float metallic = ubo.metallicFactor;

	if(ubo.useMetallicRoughnessTexture != 0)
	{
		// G Channel: Roughness Map, B Channel: Metallic Map 
		#ifdef USE_OPENGL
		vec4 metallicRoughnessColor = texture(metallicRoughnessTexture, f_Texcoord);
		#else
		vec4 metallicRoughnessColor = texture(sampler2D(metallicRoughnessTexture, metallicRoughnessTextureSampler), f_Texcoord);
		#endif
		
		perceptualRoughness = perceptualRoughness * metallicRoughnessColor.g;
		metallic  = metallic  * metallicRoughnessColor.b;
	}

	perceptualRoughness = clamp(perceptualRoughness, MIN_ROUGHNESS, 1.0);
	metallic  = clamp(metallic, 0.0, 1.0);

	// 実際に計算に使用するラフネスかな
	float alphaRoughness = perceptualRoughness * perceptualRoughness;

	// ベースカラーの取得. ベースカラーは単純な表面色
	vec4 baseColor;
	if(ubo.useBaseColorTexture != 0)
	{
		#ifdef USE_OPENGL
		baseColor = texture(baseColorTexture, f_Texcoord);
		#else
		baseColor = texture(sampler2D(baseColorTexture, baseColorTextureSampler), f_Texcoord);
		#endif
	}
	else
	{
		baseColor = ubo.baseColorFactor;
	}
	
	// 
	vec3 f0 = vec3(0.04);
	// diffuseColor. 訳すと拡散色. ライトで照らされたときにその物体が反射する色. 光学的には反射して目に入る色
	// https://help.autodesk.com/view/3DSMAX/2023/ENU/?guid=GUID-3CEBFC6A-7A8F-4E78-9CF2-F78BA9CFCDC3
	// たぶんこの0.04という数値は経験から得られた値で物理学者がいい感じにチューニングして得た綺麗な描画結果を出すのにちょうどいい値ということだと思う
	// → さらに調べてみるとこの0.04は入射反射率4%という意味らしく、たぶんどんな物体でも最低でも4%は反射するということなのかもしれない
	vec3 diffuseColor = baseColor.rgb * (vec3(1.0) - f0); // 0.04だけ減衰させる. たぶん光エネルギーが色以外のとこで減衰した分を考慮している(?)
	//diffuseColor *= (1.0 - metallic); // metallicが1.0ならdiffuseColorは0になる。完全な金属の表面色は周りの映り込み色だけになることを表している
	// specularColor. 意味は鏡面色. サーフェイス上のハイライトの色らしい.
	// https://help.autodesk.com/view/3DSMAX/2023/ENU/?guid=GUID-90065A74-C223-474C-8D85-7596D70E5004
	// 金属であるほどハイライト色がベースカラーに近づく.
	// とはいえ確かに金属はきらっとしてて逆にマットなオブジェクトは全く光ってないようなイメージがある
	// metallic : 0.0(マット) <--> 1.0(金属) って意味だと思う
	vec3 specularColor = mix(f0, baseColor.rgb, metallic); // specularColor

	// 反射率(reflectance)の計算
	// ハイライトカラーはRGBが一番大きいやつの色になるので、どれくらい反射するかもその値(色)を基準にするはずである
	float reflectance = max(max(specularColor.r, specularColor.g), specularColor.b);

	// フレネル項で必要なパラメーター
	// reflectanceに対して0.04(4%) * 25.0 = 1.0(100%)といった計算を行い、0.04(4%)以上は強制的に1.0(100%)に、それより下の値で0.0 ~ 1.0の分布を作っている。つまりグラフを急勾配にしている
	float reflectance90 = clamp(reflectance * 25.0, 0.0, 1.0);
	vec3 specularEnvironmentR0 = specularColor.rgb; // 通常の反射率
	vec3 specularEnvironmentR90 = vec3(1.0, 1.0, 1.0) * reflectance90; // 急勾配ば反射率

	// PBRに使うベクトル系のパラメーターを計算する
	vec3 n = getNormal();
	vec3 v = (-1.0f) * normalize(f_WorldPos.xyz - ubo.cameraPos.xyz);
	
	// 計算に使用するのでライト方向は反転させておく
	// 図を書くとわかるがそのままのベクトルを使うと180度回転した分の結果になってしまう
	// 法線方向を基準に考える
	vec3 l = (-1.0f) * normalize(ubo.lightDir.xyz);
	
	// ハーフベクトルはvとlの中間に位置するベクトルのこと
	// 光源の方向ベクトルはCGの慣例として光源方向に向けた方がいいのかも？
	// https://qiita.com/emadurandal/items/76348ad118c36317ec5c#:~:text=%E3%81%97%E3%81%A6%E3%81%84%E3%81%BE%E3%81%99%E3%80%82-,h,%E3%81%AF%E3%83%8F%E3%83%BC%E3%83%95%E3%83%99%E3%82%AF%E3%83%88%E3%83%AB%E3%81%A8%E3%81%84%E3%81%84,-%E3%80%81%E3%83%A9%E3%82%A4%E3%83%88%E3%83%99%E3%82%AF%E3%83%88%E3%83%AB%E3%81%A8
	vec3 h = normalize(v + l);
	vec3 reflection = normalize(reflect(v, n));

	// 考え方としては内積は二つのベクトルの角度がどれだけ水平・垂直に近いかを示す値としてみることができる
	float NdotL = clamp(dot(n, l), 0.0, 1.0);
	float NdotV = clamp(abs(dot(n, v)), 0.0, 1.0);
	float NdotH = clamp(dot(n, h), 0.0, 1.0);
	float LdotH = clamp(dot(l, h), 0.0, 1.0);
	float VdotH = clamp(dot(v, h), 0.0, 1.0);

	//
	PBRParam pbrParam = PBRParam(
		NdotL,
		NdotV,
		NdotH,
		LdotH,
		VdotH,
		perceptualRoughness,
		metallic,
		specularEnvironmentR0,
		specularEnvironmentR90,
		alphaRoughness,
		diffuseColor,
		specularColor
	);

	//
	vec3 specular = vec3(0.0);
	vec3 diffuse = vec3(0.0);

	// クックトランスモデルによるスペキュラーのGGXを計算する
	float D = CalcMicrofacet(pbrParam); // マイクロファセット(微小面法線分布関数)
	float G = CalcGeometricOcculusion(pbrParam); // 幾何減衰項
	vec3 F = CalcFrenelReflection(pbrParam); // フレネル項

	if(NdotL > 0.0 || NdotV > 0.0)
	{
		// スペキュラーBRDFを構築
		// スペキュラーは鏡面反射: 鏡面反射とは入射角と出射角が等しい反射
		// https://ja.wikipedia.org/wiki/%E9%8F%A1%E9%9D%A2%E5%8F%8D%E5%B0%84
		specular += D * G * F / (4.0 * NdotL * NdotV);

		specular = max(specular, vec3(0.0));

		// ディフューズBRDFを計算
		// Diffuseは拡散反射 : 拡散反射とは鏡面反射に比べて反射角に依存せず、多様な方向に同程度の光度を放つ反射のこと
		// https://ja.wikipedia.org/wiki/%E6%8B%A1%E6%95%A3%E5%8F%8D%E5%B0%84
		diffuse += (1.0 - F) * CalcDiffuseBRDF(pbrParam);

		// レンダリング方程式を構築
		col.rgb = NdotL * (specular + diffuse);
	}

	// 間接光
	// ハイライトだけでは光が当たらない部分が真っ黒になってしまうので間接光を適応する必要がある
	if(ubo.useIBL != 0)
	{
		// IBL
		col.rgb += ComputeIBL(pbrParam, v, n);
	}
	else if(ubo.useCubeMap != 0 || ubo.useDirCubemap != 0)
	{
		// 反射カラーを計算
		col.rgb += ComputeReflectionColor(pbrParam, v, n) * F;
	}
	else
	{
		// IBLやリフレクションプローブが有効な時はそれらが間接光の役割を果たすが、そうでない時はAmbientLight(単純な色の加算)を使用する
		// https://cgworld.jp/terms/%E3%82%A2%E3%83%B3%E3%83%93%E3%82%A8%E3%83%B3%E3%83%88.html
		vec3 gi_diffuse = ubo.ambientColor.rgb;
		col.rgb += gi_diffuse;
	}

	// AO Mapの適応
	if(ubo.useOcclusionTexture != 0)
	{ 
		#ifdef USE_OPENGL
		float ao = texture(occlusionTexture, f_Texcoord).r;
		#else
		float ao = texture(sampler2D(occlusionTexture, occlusionTextureSampler), f_Texcoord).r;
		#endif
		
		col.rgb = mix(col.rgb, col.rgb * ao, ubo.occlusionStrength);
	}

	// Emissive
	vec3 emissive = ubo.emissiveFactor.rgb * ubo.emissiveStrength;
	if(ubo.useEmissiveTexture != 0)
	{
		#ifdef USE_OPENGL
		emissive *= SRGBtoLINEAR(texture(emissiveTexture, f_Texcoord)).rgb;
		#else
		emissive *= SRGBtoLINEAR(texture(sampler2D(emissiveTexture, emissiveTextureSampler), f_Texcoord)).rgb;
		#endif
	}

	col.rgb += emissive;

	// Shadow
	// LightSpaceScreenPos
	if(ubo.useShadowMap != 0)
	{
		// https://qiita.com/Haru86_/items/d563ce1f65cf55e547a3
		// 正規化デバイス座標(NDC)に変換する
		vec3 lsp = f_LightSpacePos.xyz / f_LightSpacePos.w;
		// スクリーンUVとデプスを取り出す
		lsp = lsp * 0.5 + 0.5;
		
		float shadowCol = 1.0;

		bool outSide = (lsp.x < 0.0 || lsp.y < 0.0 || lsp.z < 0.0) || (lsp.x > 1.0 || lsp.y > 1.0 || lsp.z > 1.0);

		if(!outSide)
		{
			shadowCol = CalcShadow(lsp, n, l);
		}

		col.rgb *= shadowCol;
	}

    {
        vec3 WorldScreenCenter = vec3(0.0, 5.895, 11.4);

        vec3 pos = f_WorldPos.xyz - WorldScreenCenter.xyz;
        vec2 st = pos.xy;

        st *= 0.1;

        vec3 ro = vec3(0.0, 0.0, 1.0);
        vec3 rd = normalize(vec3(st, -1.0));

        float d, t = 0.0, acc = 0.0;

        for(int i = 0; i < 64; i++)
        {
            d = map(ro + rd * t);
            if(d < minD) break;

            t += d;
			acc += exp(-3.0*d);
        }

		vec3 refo = ro + rd * t;
     	vec3 n = gn(refo);
    	rd = reflect(refo,n);
    	ro = refo;
    	t = 0.1;
    	float acc2 = 0.;

		if(d < minD)
		{
			vec3 rayCol = vec3(0.0);

			rayCol += vec3(1.,0.5,1.) * acc * 0.1;

			/*for(int i = 0; i < 32; i++)
			{
				d = map(ro + rd * t);
				if(d < minD) break;

				t += d;
				acc2 += exp(-3.0*d);
			}

			rayCol += vec3(0.,.5,1.) * acc2 * 0.075;*/
			col += rayCol;
		}
    }

	// カラースペースをリニアにする
	col.rgb = pow(col.rgb, vec3(1.0/2.2));

    outColor = vec4(col, 1.0);
}