#version 450

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inTexcoord;
layout(location = 3) in vec4 inTangent;
layout(location = 4) in uvec4 inJoint0;
layout(location = 5) in vec4 inWeights0;

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

layout(binding = 25) uniform SkinMatrixBuffer
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

    WorldPos = vec4(inPosition, 1.0);
    WorldNormal = normalize((vec4(inNormal, 0.0)).xyz);
    WorldTangent = normalize((inTangent).xyz);
    WorldBioTangent = normalize((vec4(BioTangent, 0.0)).xyz);

    // インスタンス描画
    #ifdef USE_OPENGL
    int id = gl_InstanceID;
#else
    int id = gl_InstanceIndex;
#endif
    float sidenum = 64;
    float yid = floor(float(id) / sidenum);
    float xid = float(id) - yid * sidenum;

    xid = xid - sidenum * 0.5;

    vec3 base = vec3(0.0, 0.0, -15.0); 
    float w = 1.0, h = 1.0;
    vec3 offset = base + vec3(w * xid, 0.0, h * -yid);
    mat4 InsMat = mat4(
        1.0, 0.0, 0.0, offset.x,
        0.0, 1.0, 0.0, offset.y,
        0.0, 0.0, 1.0, offset.z,
        0.0, 0.0, 0.0, 1.0
    );

    WorldPos *= InsMat;

    //
    gl_Position = ubo.proj * ubo.view * WorldPos;
    f_WorldNormal = WorldNormal;
    f_Texcoord = inTexcoord;
    f_WorldPos = WorldPos;
    f_WorldTangent = WorldTangent;
    f_WorldBioTangent = WorldBioTangent;
    f_LightSpacePos = ubo.lightPMat * ubo.lightVMat * WorldPos;
}