#version 450

layout(location = 0) in vec3 f_WorldNormal;
layout(location = 1) in vec2 f_Texcoord;
layout(location = 2) in vec4 f_WorldPos;
layout(location = 3) in vec3 f_WorldTangent;
layout(location = 4) in vec3 f_WorldBioTangent;
layout(location = 5) in vec4 f_LightSpacePos;

layout(location = 0) out vec4 gPosition;
layout(location = 1) out vec4 gNormal;
layout(location = 2) out vec4 gAlbedo;
layout(location = 3) out vec4 gDepth;

layout(binding = 0) uniform UniformBufferObject{
	mat4 model;
    mat4 view;
    mat4 proj;
	mat4 lightVPMat;

	vec4 lightDir;
	vec4 lightColor;
	vec4 cameraPos;

	vec4 baseColorFactor;
	vec4 emissiveFactor;

    float time;
    float metallicFactor;
    float roughnessFactor;
    float normalMapScale;

	float occlusionStrength;
    // MipCount�ɂ͔��˃L���[�u�}�b�v��IBL��SpecularMap�̒l�������Ă���(�����͕K���ǂ��炩��������g�p����Ȃ�����)
	float mipCount;
    float ShadowMapX;
    float ShadowMapY;

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
    int   pad1;
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

// �Ȃ�UnityPBR�ł��݂��l���Ȃ�
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

// �}�C�N���t�@�Z�b�g(�����ʖ@�����z�֐�)(Microfacet Distribution). Distribution�͕��z�ɈӖ�
// ���z�֐��Ȃ̂œ��v�w�I�ɋ��߂�ꂽ����
// �}�C�N���t�@�Z�b�g�̖ʐς�Ԃ�
// �ʐς��������قǃ}�C�N���t�@�Z�b�g���U��΂��Ă��čr���Ƃ������Ƃ��ȁH �� �傫���قǓʉ��̂Ȃ���̕��ʂɋ߂Â�
// https://learnopengl.com/PBR/Theory#:~:text=GGX%20for%20G.-,Normal%20distribution%20function,-The%20normal%20distribution
float CalcMicrofacet(PBRParam param)
{
	float roughness2 = param.alphaRoughness * param.alphaRoughness; // �O���t�̌��z����������
	
	//
	float f = (param.NdotH * roughness2 - param.NdotH) * param.NdotH + 1.0;
	// = ( param.NdotH * (roughness2 - 1.0) ) * param.NdotH + 1.0
	// = pow(param.NdotH, 2.0) * (roughness2 - 1.0) + 1.0
	// �����Ɠ����`�ɂȂ�. (n�Eh)^2 * (a^2 - 1) + 1
	
	//
	return roughness2 / (PI * f * f);
}

// �􉽌�����(Geometric Occlusion)
// �}�C�N���t�@�Z�b�g�̔������ʂ����̌o�H���Ւf���邱�Ƃɂ�莸���Ă��܂����̌����ʂ��v�Z����֐�
float CalcGeometricOcculusion(PBRParam param)
{
	float NdotL = param.NdotL;
	float NdotV = param.NdotV;
	// �\�ʂ��r���قǁA�������ʂ������Č����B������₷���Ȃ�
	float r = param.alphaRoughness;

	// �ڂ�������(https://google.github.io/filament/Filament.md.html#materialsystem/specularbrdf/geometricshadowing(specularg))
	// �V���h�E�C���O�̍����v�Z(���ˌ������̔������ʂɎՂ��ĉe�ɂȂ�����������镪)
	float attenuationL = 2.0 * NdotL / ( NdotL + sqrt(r * r + (1.0 - r * r) * (NdotL * NdotL)) );
	// = 2.0 * NdotL / ( NdotL * () )
	// �}�X�L���O�̍����v�Z(���ˌ������̔������ʂɎՂ��Ă��̌����ڂɓ͂��Ȃ����ƂŌ������镪)
	float attenuationV = 2.0 * NdotV / ( NdotV + sqrt(r * r + (1.0 - r * r) * (NdotV * NdotV)) );

	// �􉽌������͏�L�̏�Z����
	return attenuationL * attenuationV;
}

// �t���l������(�t���l����). 
// �t���l�����˂Ƃ�View�����ɉ����Ĕ��˗����ω����镨�����ۂ̂��Ƃł��� 
// �����ł�GGX���ł̃t���l�����˂̓I�u�W�F�N�g�̒[�ł���قǔ��˗�������(���ːF�����邢)���Ƃ������Ă���
// https://marmoset.co/posts/basic-theory-of-physically-based-rendering/
// ���̉摜���킩��₷�� --> https://marmoset.co/wp-content/uploads/2016/11/pbr_theory_fresnel.png
// GGX�̃t���l�����̎��́A�悭���w�̕���Ō���������悤�ȃt���l���̎��̋ߎ����ł���(https://ja.wikipedia.org/wiki/%E3%83%95%E3%83%AC%E3%83%8D%E3%83%AB%E3%81%AE%E5%BC%8F)
// https://learnopengl.com/PBR/Theory#:~:text=return%20ggx1%20*%20ggx2%3B%0A%7D-,Fresnel%20equation,-The%20Fresnel%20equation
vec3 CalcFrenelReflection(PBRParam param)
{
	// ��{�̔��˗�: reflectance0
	// ����ɑ΂��Ď�������ɂ�锽�˗��̕ω��������Z���Ă���
	// ���Ɛ�������reflectance90��1.0�Ȃ̂ō��͂���܂�[���l���Ȃ��Ă����������H
	// ����������reflectance90�͔}���̋��ܗ��Ɋ֌W���Ă���H�^�󂾂�1.0�Ȃ̂ŁA���̐����Ƃ����ƂЂƂ܂��^��Ɖ��肵�Ă���H
	return param.reflectance0 + (param.reflectance90 - param.reflectance0) * pow(clamp(1.0 - param.VdotH, 0.0, 1.0), 5.0);
}

// �f�B�t���[�Y��BRDF���v�Z
// https://google.github.io/filament/Filament.md.html#materialsystem/diffusebrdf
// ���̋L���ɂ��Ɗg�U�F��BRDF�͋ߎ��I�Ɂw1.0 / PI�x�ƒ�܂�Ƃ̂���
vec3 CalcDiffuseBRDF(PBRParam param)
{
	return param.diffuseColor / PI;
}

// �@���̎擾(�m�[�}���}�b�v���g�����Ƃ�����. �� ���łɕ׋�����)
vec3 getNormal()
{
	vec3 nomral = vec3(0.0);

	if(ubo.useNormalTexture != 0)
	{
		// Tangent, SubTangent, Normal�ō\���������W�ϊ��x�N�g�����쐬����
		// ���̂悤�ȕϊ��s��̂��Ƃ𓪕������Ƃ��� TBN Matrix �ƌĂ�
		// �@���}�b�v�̎����@�������͏�ɒ萔�ł���A�I�u�W�F�N�g����]������ƃ��[���h���W��̌���������Ȃ��Ȃ�̂ŁA���W�ϊ����Đ��������̂ɂ���K�v������
		// �Ⴆ��Z�����������@���}�b�v������Plane�I�u�W�F�N�g��X�������90�x��]������ƁA�@��������Y�����ɂȂ�̂��������͂��Ȃ̂ɁA�@���}�b�v�̒l���萔�ł��邽�߁A
		// ���̂܂�Z�������������C�e�B���O���������Ȃ��ƂɂȂ�
		// https://learnopengl.com/Advanced-Lighting/Normal-Mapping#:~:text=tangent%20space.-,Tangent%20space,-Normal%20vectors%20in
		// TBN Matrix�̌v�Z��@
		// �@���͗ǂ��Ȃ�.
		// �ړ_�ƕ��ڐ��̃x�N�g���������T�[�t�F�C�X�̃e�N�X�`�����W�̕����ƈ�v���Ă���Ƃ������Ƃ𗘗p���Čv�Z����(��L�̐ڐ���Ԃ̍��ڂ��)
		// �O�p�`�̒��_�Ƃ��̃e�N�X�`�����W����ڐ��ƕ��ڐ����v�Z���邱�Ƃ��ł���
		// �� ����̓��������ڐ���ԋL����E1�EE2���\���͖̂ʐςł͂Ȃ��AP1�EP2�EP3���g�����w�x�N�g���x
		// �� �Ȃ̂Ńx�N�g���ŎO�p�`������Όv�Z�͂ł���̂ŁA����Plane�ł͂Ȃ��|���S���P�ʂŐڐ��̌v�Z���s�����Ƃ��ł���
		// Shader�x�[�X�̒��_�Z�o�̓p�t�H�[�}���X�����̂ŁA�ЂƂ܂��v�Z��CPU�ōs���Ă���
		// �����͂���(https://drive.google.com/file/d/1A4WK5GLRzWRD9yt9_yxSjyz8Yrmb5Is8/view?usp=sharing)

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

// Lenear�͌��w�ɑ������F���(�����̌��̎d�g��
// sRGB�̓��j�^�[�Ɏg����F��ԂŐl�Ԃ̐F�̒m�o�ɑ����Ă���
// Linear���sRGB�̕������邢
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

	// �}�b�n�o���h�΍��Shadow Bias
	// ShadowBias�Ƃ͐[�x�̃I�t�Z�b�g�̂���
	// �}�b�n�o���h��ShawMap�̉𑜓x�ɂ�蔭������B�����̃t���O�����g�����������r�I����Ă���ꍇ�A�[�x�}�b�v���瓯���l���T���v�����O����\��������B
	// ���̓��ˊp���I�N���[�_�[�̖@���ɑ΂��Ď΂߂ȂƂ��A��L�̗��R����Ⴆ�Ώ����[�x���傫���ׂ̕\�ʂ̐[�x���T���v�����O���Ă��܂��A����ShadowMap�̌��̐[�x���傫���Ȃ��Ă��܂����ƂŎȁX�ɂȂ�(�傫���Ƃ������Ƃ͉e�ɂȂ�, ���F)
	// ���̑΍�ŃI�N���[�_�[���ق�̏���������O�ɂ���B��O�ɂ��邱�Ƃ�Shadowmap�����[�x���������Ȃ邽�߉e�ɂȂ�ɂ����Ȃ�
	// https://drive.google.com/file/d/1tyDT7xQVSYzKnZXt6vvDwt-rlWEjVGDP/view?usp=sharing
	// ���̖@���ƃ��C�g�����̐����p�x�������ɂȂ�قǁABias����������
	// https://learnopengl.com/Advanced-Lighting/Shadows/Shadow-Mapping
	float ShadowBias = max(0.005, 0.05 * (1.0 - dot(nomral, lightDir)) );

	float distance = lsp.z - ShadowBias;

	// ShadowMap�̐[�x������O�Ȃ̂ŕ��ʂɕ`�悷��
	if((distance) <= moments.x)
	{
		return 1.0;
	}
	
	// ���Ȃ̂ŉe�ɂ���
	// �o���A���X�̌v�Z
	float variance = moments.y - (moments.x * moments.x);
	variance = max(0.005, variance);

	float d = distance - moments.x;
	float p_max = variance / (variance + d * d);

	// �{���e�ɂȂ�Ƃ���Ɍ����ɂ���ł���悤�ȃA�[�e�B�t�@�N�g���o�邱�Ƃ�����̂ł��̑΍�
	//p_max = ReduceLightBleeding(0.1, p_max);

	return p_max;
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
	// ���˃J���[���v�Z
	vec3 reflectColor = vec3(0.0);
	if(ubo.useCubeMap != 0)
	{
		float mipCount = ubo.mipCount;
		float lod = mipCount * pbrParam.perceptualRoughness;
		#ifdef USE_OPENGL
		reflectColor = LINEARtoSRGB(textureLod(cubemapTexture, reflect(v, n), lod)).rgb;
		#else
		reflectColor = LINEARtoSRGB(textureLod(samplerCube(cubemapTexture, cubemapTextureSampler), reflect(v, n), lod)).rgb;
		#endif
	}
	else if(ubo.useDirCubemap != 0)
	{
		vec2 st = CastDirToSt(reflect(v, n));
		
		float mipCount = ubo.mipCount;
		float lod = mipCount * pbrParam.perceptualRoughness;
		#ifdef USE_OPENGL
		reflectColor = LINEARtoSRGB(textureLod(cubeMap2DTexture, st, lod)).rgb;
		#else
		reflectColor = LINEARtoSRGB(textureLod(sampler2D(cubeMap2DTexture, cubeMap2DTextureSampler), st, lod)).rgb;
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

	// �e�N�X�`���v�Z
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

	return diffuse + specular;
}

void main(){
	vec4 col = vec4(1.0);

	// ���t�l�X�ƃ��^���b�N���擾�B�e�N�X�`���Ƀp�b�L���O����Ă��邱�Ƃ�����
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

	// �x�[�X�J���[�̎擾. �x�[�X�J���[�͒P���ȕ\�ʐF
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
	
	vec3 n = getNormal();
	float depth = gl_FragCoord.z;

	gPosition = f_WorldPos;
	gNormal = vec4(n, 1.0);
	gAlbedo = baseColor;
	gDepth = vec4(depth);
}