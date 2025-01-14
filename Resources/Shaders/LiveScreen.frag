#version 450

layout(location = 0) in vec3 f_WorldNormal;
layout(location = 1) in vec2 f_Texcoord;
layout(location = 2) in vec4 f_WorldPos;
layout(location = 3) in vec3 f_WorldTangent;
layout(location = 4) in vec3 f_WorldBioTangent;
layout(location = 5) in vec4 f_LightSpacePos;

layout(location = 0) out vec4 outColor;

layout(binding = 1) uniform FragUniformBufferObject{
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

#define repeat(p, a) mod(p, a) - a * 0.5
#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))
#define minD 0.001

float cube(vec3 p, vec3 s)
{
    return length(max(vec3(0.0), abs(p) - s));
}

float map(vec3 p)
{
    // p.xy *= rot(f_ubo.time);
    // p.yz *= rot(f_ubo.time);
    // p.xz *= rot(f_ubo.time);

    p.z += f_ubo.time;
    p = repeat(p, 2.0);

    // float d = length(p) - 0.75;
    float d = cube(p, vec3(0.5));

    return d;
}

vec3 gn(vec3 p)
{
    vec2 e = vec2(minD, 0.0);

    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

void main(){
    vec3 WorldScreenCenter = vec3(0.0, 5.895, 11.4);

    vec3 pos = f_WorldPos.xyz - WorldScreenCenter.xyz;
    vec2 st = pos.xy;

    st *= 0.1;

    vec3 col = vec3(0.0);
    

    vec3 ro = vec3(0.0, 0.0, 1.0);
    vec3 rd = normalize(vec3(st, -1.0));

    float d, t = 0.0;

    for(int i = 0; i < 64; i++)
    {
        d = map(ro + rd * t);
        if(d < minD) break;

        t += d;
    }

    if(d < minD)
    {
        vec3 p = ro + rd * t;
        vec3 n = gn(p);

        col = n * 0.5 + 0.5;
    }

    outColor = vec4(col, 1.0);
}