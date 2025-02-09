#version 450

layout(binding = 1) uniform FragUniformBufferObject{
	mat4 model;
    mat4 view;
    mat4 proj;
	mat4 lightVMat;

    vec4 emissionColor;
    vec4 cameraPos;

    float emissionPower;
    float fPad0;
    float fPad1;
    float fPad2;
} f_ubo;

layout(location = 0) in vec4 v2g_initPos;
layout(location = 1) in float v2g_localTopHeight;

layout(location = 0) out vec4 outColor;

void main()
{
    // エミッションを反映
    vec3 col = f_ubo.emissionColor.rgb * f_ubo.emissionPower;

    // 透明度を計算
    vec4 pos = v2g_initPos;

    // 高さの割合
    float HeightRate = pos.y / v2g_localTopHeight;

    // ライト始点から遠いほど透明度を減衰させる
    float HeightAlpha = 1.0 - HeightRate;

    // ライトの端ほど透明度を減衰させる
    vec4 NoDeformedWorldPos = f_ubo.model * pos;
    vec3 WorldViewDir = normalize(NoDeformedWorldPos.xyz - f_ubo.cameraPos.xyz);
    vec3 ObjectViewDir = (inverse(f_ubo.model) * vec4(WorldViewDir, 0.0)).xyz;

    vec2 VertDir = normalize(pos.xz);

    float EdgeAlpha = abs(dot(VertDir, normalize(ObjectViewDir.xz)));
    float alpha = clamp(HeightAlpha * EdgeAlpha, 0.0, 1.0);

    outColor = vec4(col, alpha);
}