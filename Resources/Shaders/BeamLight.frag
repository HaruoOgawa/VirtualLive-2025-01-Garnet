#version 450

layout(binding = 1) uniform FragUniformBufferObject{
	mat4 model;
    mat4 view;
    mat4 proj;
	mat4 lightVMat;
} f_ubo;

layout(location = 0) out vec4 outColor;

void main()
{
    vec3 col = vec3(1.0);
    float alpha = 1.0;

    outColor = vec4(col, alpha);
}