#version 450

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inTexcoord;
layout(location = 3) in vec4 inTangent;
layout(location = 4) in uvec4 inJoint0;
layout(location = 5) in vec4 inWeights0;
layout(location = 6) in vec3 inMorphVec0;
layout(location = 7) in vec3 inMorphVec1;

layout(binding = 0) uniform MorphUniformBufferObject{
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
    float mipCount;
    float ShadowMapX;
    float ShadowMapY;

    float MorphWeight_0;
    float MorphWeight_1;
    float fPad0;
    float fPad1;

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
    int   useMorph;
    int   pad2;
} ubo;

layout(binding = 1) uniform SkinMatrixBuffer
{
    mat4 SkinMat[1024];
} r_SkinMatrixBuffer;

layout(location = 0) out vec3 f_WorldNormal;
layout(location = 1) out vec2 f_Texcoord;
layout(location = 2) out vec4 f_WorldPos;
layout(location = 3) out vec3 f_WorldTangent;
layout(location = 4) out vec3 f_WorldBioTangent;
layout(location = 5) out vec4 f_LightSpacePos;

#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

void main(){
    vec3 BioTangent = cross(inNormal, inTangent.xyz);

    vec4 WorldPos;
    vec3 WorldNormal;
    vec3 WorldTangent;
    vec3 WorldBioTangent;

    vec3 LocalPos = inPosition;

    // ���[�t
    if(ubo.useMorph != 0)
    {
        LocalPos +=
            inMorphVec0 * ubo.MorphWeight_0 +
            inMorphVec1 * ubo.MorphWeight_1;
    }

    // �X�L�����b�V���A�j���[�V����
    if(ubo.useSkinMeshAnimation != 0)
    {
        mat4 SkinMat =
            inWeights0.x * r_SkinMatrixBuffer.SkinMat[inJoint0.x] +
            inWeights0.y * r_SkinMatrixBuffer.SkinMat[inJoint0.y] +
            inWeights0.z * r_SkinMatrixBuffer.SkinMat[inJoint0.z] +
            inWeights0.w * r_SkinMatrixBuffer.SkinMat[inJoint0.w ] 
        ;

        // �X�L�����b�V���A�j���[�V�����̎���ubo.model�͏�Z���Ȃ��悤�ɒ���
        WorldPos = SkinMat * vec4(LocalPos, 1.0);
        WorldNormal = normalize((SkinMat * vec4(inNormal, 0.0)).xyz);
        WorldTangent = normalize((SkinMat * inTangent).xyz);
        WorldBioTangent = normalize((SkinMat * vec4(BioTangent, 0.0)).xyz);
    }
    else
    {
        // �ʏ�̕`��
        WorldPos = ubo.model * vec4(LocalPos, 1.0);
        WorldNormal = normalize((ubo.model * vec4(inNormal, 0.0)).xyz);
        WorldTangent = normalize((ubo.model * inTangent).xyz);
        WorldBioTangent = normalize((ubo.model * vec4(BioTangent, 0.0)).xyz);
    }

    gl_Position = ubo.proj * ubo.view * WorldPos;
    f_WorldNormal = WorldNormal;
    f_Texcoord = inTexcoord;
    f_WorldPos = WorldPos;
    f_WorldTangent = WorldTangent;
    f_WorldBioTangent = WorldBioTangent;
    f_LightSpacePos = ubo.lightVPMat * WorldPos;
}