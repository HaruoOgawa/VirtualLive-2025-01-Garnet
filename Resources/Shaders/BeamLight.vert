#version 450

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inTexcoord;
layout(location = 3) in vec4 inTangent;
layout(location = 4) in uvec4 inJoint0;
layout(location = 5) in vec4 inWeights0;

layout(binding = 0) uniform VertUniformBufferObject{
	mat4 model;
    mat4 view;
    mat4 proj;
	mat4 lightVMat;

    float LocalTopHeight; // ローカル座標系でのトップの高さ。DCCツールで値をみて設定
    float fPad0;
    float fPad1;
    float fPad2;
} v_ubo;

layout(location = 0) out float v2g_HeightAlpha;

void main()
{
    vec4 pos = vec4(inPosition, 1.0);

    float HeightAlpha = 1.0 - pos.y / v_ubo.LocalTopHeight;

    gl_Position = v_ubo.proj * v_ubo.view * v_ubo.model * pos;
    v2g_HeightAlpha = clamp(HeightAlpha, 0.0, 1.0);
}