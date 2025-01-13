#version 450

layout(binding = 1) uniform FragUniformBufferObject{
	mat4 model;
    mat4 view;
    mat4 proj;
	mat4 lightVMat;

    vec4 baseColor;
} f_ubo;

layout(location = 0) in float v2g_HeightAlpha;

layout(location = 0) out vec4 outColor;

void main()
{
    vec3 col = vec3(1.0);
    float alpha = 1.0;

    col *= f_ubo.baseColor.rgb;
    alpha *= v2g_HeightAlpha;

    outColor = vec4(col, alpha);
}