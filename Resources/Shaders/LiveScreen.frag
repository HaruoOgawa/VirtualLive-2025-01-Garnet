#version 450

layout(location = 0) in vec3 f_WorldNormal;
layout(location = 1) in vec2 f_Texcoord;
layout(location = 2) in vec4 f_WorldPos;
layout(location = 3) in vec3 f_WorldTangent;
layout(location = 4) in vec3 f_WorldBioTangent;
layout(location = 5) in vec4 f_LightSpacePos;

layout(location = 0) out vec4 outColor;

layout(binding = 2) uniform FragUniformBufferObject{
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
#define PI 3.1415

float Cube(vec3 p,vec3 s){
  return length(max(abs(p)-s,0.0));
}

vec3 ifs(vec3 p){
  p=abs(p);

  for(int i=0;i<6;i++){
    p=abs(p)-0.35;
    p.xy*=rot(0.25);
    p.xz*=rot(1.95);
    p.yz*=rot(0.98);

    p.xy=(p.x<p.y)? p.yx : p.xy;
    p.xz=(p.x<p.z)? p.zx : p.xz;
    p.yz=(p.y<p.z)? p.zy : p.yz;
  }

  return p;
}

float map(vec3 p){

  vec3 pt=p;

  pt.z-=f_ubo.time;
  float k=1.25;
  vec3 id=floor(pt/k)*k;
  pt=mod(pt,k)-k*0.5;
  pt.xy*=rot(PI/4.0);
  float baseCube=Cube(pt,vec3(0.5));

  //
  pt=mod(pt,2.0)-1.0;
  pt=ifs(pt);
  float subCube=Cube(pt,vec3(0.3));

  float d=max(baseCube,subCube);

  return d;
}

vec3 gn(vec3 p){
  vec2 e=vec2(0.001,0.0);
  return normalize(vec3(
      map(p+e.xyy)-map(p-e.xyy),
      map(p+e.yxy)-map(p-e.yxy),
      map(p+e.yyx)-map(p-e.yyx)
    ));
}

void main(){
    vec3 col = vec3(0.0);
	
    {
        vec3 WorldScreenCenter = vec3(0.0, 5.895, 11.4);

        vec3 pos = f_WorldPos.xyz - WorldScreenCenter.xyz;
        vec2 st = pos.xy;

        st *= 0.25;

        vec3 ro=vec3(cos(f_ubo.time)*0.25,sin(f_ubo.time)*0.25,1.0);
		vec3 ta=vec3(0.0);
		
		vec3 cdir=normalize(ta-ro);
		vec3 cside=normalize(cross(cdir,vec3(0.0,1.0,0.0)));
		vec3 cup=normalize(cross(cdir,cside));
		
		vec3 rd=normalize(st.x*cside+st.y*cup+cdir*1.0);

		int marchingNum=0;
		float d,t,acc=0.0;
		for(int i=0;i<128;i++){
			d=map(ro+rd*t);
			marchingNum=i;
			if(d<minD||t>1000.0)break;
			t+=d;
			acc+=exp(-3.0*d);
			marchingNum=128-1;
		}

		// if(d < minD)
		{
			vec3 rayCol = vec3(0.0);

			float glow=0.0;
			const float s = 0.0075;
			vec3 n0=gn(ro+rd*t);
			vec3 n1=gn(ro+rd*t+vec3(sign(n0.x)*s,0.0,0.0));
			vec3 n2=gn(ro+rd*t+vec3(0.0,sign(n0.y)*s,0.0));

			glow=max(0.0,dot(n0,rd));

			float emw=0.8;
			if(dot(n0, n1)<emw || dot(n0, n2)<emw) {
					glow += 4.5;
				}

			glow *= min(1.0,
			4.0-(4.0*float(marchingNum) / float(128-1))
			);

			rayCol=acc*vec3(0.5,0.2,.6)*0.075+vec3(1.0)*glow*acc;

			vec3 refro=ro+rd*t;
			rd=reflect(rd,n0);
			ro=refro;
			t=0.1;
			float acc2=0.0;

			for(int i=0;i<64;i++){
			d=map(ro+rd*t);
			if(d<minD)break;
			t+=d;
			acc2+=exp(-3.0*d);
			}

			rayCol+=vec3(0.4,0.25,0.8)*acc2*0.025;

			float emission = 1.5;
			rayCol = min(vec3(emission), rayCol);

			col += rayCol;
		}
    }

	// カラースペースをリニアにする
	col.rgb = pow(col.rgb, vec3(1.0/2.2));

    outColor = vec4(col, 1.0);
}