#version 450

layout(location = 0) in vec2 fragTexCoord;

layout(location = 0) out vec4 outColor;

layout(binding = 0) uniform UniformBufferObject
{
	float rate;
	float time;
	float alpha;
	float pad;
} ubo;

void main()
{
	vec2 uv = fragTexCoord;
	vec2 st = fragTexCoord * 2.0 - 1.0;

	vec2  pad = vec2(0.2, 0.48); // �c���̌��ԁE�p�f�B���O. uv�Ȃ̂�0.0 ~ 0.5�̒l
	uv = (uv - pad) * vec2(1.0 / (1.0 - 2.0 *pad));  // uv�� pad ~ (1.0 - pad) �܂ł̋�Ԃ� 0.0 ~ 1.0 �ɕ⊮���� => ���[�f�B���O�o�[�̗̈�

	vec3 col = vec3(0.0);

	if(uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0)
	{
		if(uv.x <= ubo.rate)
		{
			col = mix(vec3(0.1), vec3(1.0), uv.x);
		}
		else
		{
			col = vec3(0.1);
		}
	}
	else
	{
		float w = 0.04;
		if( length(max(vec2(0.0), abs(st) - vec2(0.5 + w * 2.35, w))) <= 0.01)
		{
			col += vec3(1.0);
		}
	}

	outColor = vec4(col, ubo.alpha);
}