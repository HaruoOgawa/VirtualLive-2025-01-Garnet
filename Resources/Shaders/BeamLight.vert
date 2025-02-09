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
    
    vec4 cameraPos;

    float LocalTopHeight; // ローカル座標系でのトップの高さ。DCCツールで値をみて設定
    float BeamRadius; // ビームの基本半径
    float BeamExpand; // ビームの拡大率。始点から離れるに連れてどれぐらい広がっていくか
    float BeamHeight; // ビームの高さ
} v_ubo;

layout(location = 0) out vec4 v2g_initPos;
layout(location = 1) out float v2g_localTopHeight;

void main()
{
    vec4 initPos = vec4(inPosition, 1.0);

    vec4 pos = initPos;

    // 高さの割合
    float HeightRate = pos.y / v_ubo.LocalTopHeight;

    // ライトの変形
    vec3 DeformedScale = vec3(v_ubo.BeamRadius + v_ubo.BeamExpand * HeightRate, v_ubo.BeamHeight, v_ubo.BeamRadius + v_ubo.BeamExpand * HeightRate);
    pos *= mat4(
        DeformedScale.x, 0.0, 0.0, 0.0,
        0.0, DeformedScale.y, 0.0, 0.0,
        0.0, 0.0, DeformedScale.z, 0.0,
        0.0, 0.0, 0.0, 1.0
    );

    gl_Position = v_ubo.proj * v_ubo.view * v_ubo.model * pos;
    v2g_initPos = initPos;
    v2g_localTopHeight = v_ubo.LocalTopHeight;
}