struct PBRParam {
    NdotL: f32,
    NdotV: f32,
    NdotH: f32,
    LdotH: f32,
    VdotH: f32,
    perceptualRoughness: f32,
    metallic: f32,
    reflectance0_: vec3<f32>,
    reflectance90_: vec3<f32>,
    alphaRoughness: f32,
    diffuseColor: vec3<f32>,
    specularColor: vec3<f32>,
}

struct UniformBufferObject {
    model: mat4x4<f32>,
    view: mat4x4<f32>,
    proj: mat4x4<f32>,
    lightVMat: mat4x4<f32>,
    lightPMat: mat4x4<f32>,
    lightDir: vec4<f32>,
    lightColor: vec4<f32>,
    cameraPos: vec4<f32>,
    baseColorFactor: vec4<f32>,
    emissiveFactor: vec4<f32>,
    time: f32,
    metallicFactor: f32,
    roughnessFactor: f32,
    normalMapScale: f32,
    occlusionStrength: f32,
    mipCount: f32,
    ShadowMapX: f32,
    ShadowMapY: f32,
    useBaseColorTexture: i32,
    useMetallicRoughnessTexture: i32,
    useEmissiveTexture: i32,
    useNormalTexture: i32,
    useOcclusionTexture: i32,
    useCubeMap: i32,
    useShadowMap: i32,
    useIBL: i32,
    useSkinMeshAnimation: i32,
    useDirCubemap: i32,
    pad1_: i32,
    pad2_: i32,
}

@group(0) @binding(0) 
var<uniform> ubo: UniformBufferObject;
var<private> f_WorldTangent_1: vec3<f32>;
var<private> f_WorldBioTangent_1: vec3<f32>;
var<private> f_WorldNormal_1: vec3<f32>;
@group(0) @binding(8) 
var normalTexture: texture_2d<f32>;
@group(0) @binding(9) 
var normalTextureSampler: sampler;
var<private> f_Texcoord_1: vec2<f32>;
@group(0) @binding(14) 
var shadowmapTexture: texture_2d<f32>;
@group(0) @binding(15) 
var shadowmapTextureSampler: sampler;
@group(0) @binding(12) 
var cubemapTexture: texture_cube<f32>;
@group(0) @binding(13) 
var cubemapTextureSampler: sampler;
@group(0) @binding(22) 
var cubeMap2DTexture: texture_2d<f32>;
@group(0) @binding(23) 
var cubeMap2DTextureSampler: sampler;
@group(0) @binding(20) 
var IBL_GGXLUT_Texture: texture_2d<f32>;
@group(0) @binding(21) 
var IBL_GGXLUT_TextureSampler: sampler;
@group(0) @binding(16) 
var IBL_Diffuse_Texture: texture_2d<f32>;
@group(0) @binding(17) 
var IBL_Diffuse_TextureSampler: sampler;
@group(0) @binding(18) 
var IBL_Specular_Texture: texture_2d<f32>;
@group(0) @binding(19) 
var IBL_Specular_TextureSampler: sampler;
@group(0) @binding(4) 
var metallicRoughnessTexture: texture_2d<f32>;
@group(0) @binding(5) 
var metallicRoughnessTextureSampler: sampler;
@group(0) @binding(2) 
var baseColorTexture: texture_2d<f32>;
@group(0) @binding(3) 
var baseColorTextureSampler: sampler;
var<private> f_WorldPos_1: vec4<f32>;
@group(0) @binding(10) 
var occlusionTexture: texture_2d<f32>;
@group(0) @binding(11) 
var occlusionTextureSampler: sampler;
@group(0) @binding(6) 
var emissiveTexture: texture_2d<f32>;
@group(0) @binding(7) 
var emissiveTextureSampler: sampler;
var<private> f_LightSpacePos_1: vec4<f32>;
var<private> outColor: vec4<f32>;

fn ComputePCFvf2_(uv: ptr<function, vec2<f32>>) -> vec2<f32> {
    var moments: vec2<f32>;
    var texelSize: vec2<f32>;

    moments = vec2<f32>(0.0, 0.0);
    let _e98 = ubo.ShadowMapX;
    let _e101 = ubo.ShadowMapY;
    texelSize = vec2<f32>((1.0 / _e98), (1.0 / _e101));
    let _e104 = (*uv);
    let _e105 = texelSize;
    let _e108 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e104 + (vec2<f32>(-1.0, -1.0) * _e105)));
    let _e110 = moments;
    moments = (_e110 + _e108.xy);
    let _e112 = (*uv);
    let _e113 = texelSize;
    let _e116 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e112 + (vec2<f32>(-1.0, 0.0) * _e113)));
    let _e118 = moments;
    moments = (_e118 + _e116.xy);
    let _e120 = (*uv);
    let _e121 = texelSize;
    let _e124 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e120 + (vec2<f32>(-1.0, 1.0) * _e121)));
    let _e126 = moments;
    moments = (_e126 + _e124.xy);
    let _e128 = (*uv);
    let _e129 = texelSize;
    let _e132 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e128 + (vec2<f32>(0.0, -1.0) * _e129)));
    let _e134 = moments;
    moments = (_e134 + _e132.xy);
    let _e136 = (*uv);
    let _e137 = texelSize;
    let _e140 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e136 + (vec2<f32>(0.0, 0.0) * _e137)));
    let _e142 = moments;
    moments = (_e142 + _e140.xy);
    let _e144 = (*uv);
    let _e145 = texelSize;
    let _e148 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e144 + (vec2<f32>(0.0, 1.0) * _e145)));
    let _e150 = moments;
    moments = (_e150 + _e148.xy);
    let _e152 = (*uv);
    let _e153 = texelSize;
    let _e156 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e152 + (vec2<f32>(1.0, -1.0) * _e153)));
    let _e158 = moments;
    moments = (_e158 + _e156.xy);
    let _e160 = (*uv);
    let _e161 = texelSize;
    let _e164 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e160 + (vec2<f32>(1.0, 0.0) * _e161)));
    let _e166 = moments;
    moments = (_e166 + _e164.xy);
    let _e168 = (*uv);
    let _e169 = texelSize;
    let _e172 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e168 + (vec2<f32>(1.0, 1.0) * _e169)));
    let _e174 = moments;
    moments = (_e174 + _e172.xy);
    let _e176 = moments;
    moments = (_e176 / vec2<f32>(9.0));
    let _e179 = moments;
    return _e179;
}

fn CalcShadowvf3vf3vf3_(lsp: ptr<function, vec3<f32>>, nomral: ptr<function, vec3<f32>>, lightDir: ptr<function, vec3<f32>>) -> f32 {
    var moments_1: vec2<f32>;
    var param: vec2<f32>;
    var ShadowBias: f32;
    var distance: f32;

    let _e101 = (*lsp);
    param = _e101.xy;
    let _e103 = ComputePCFvf2_((&param));
    moments_1 = _e103;
    let _e104 = moments_1;
    moments_1 = ((_e104 * 0.5) + vec2<f32>(0.5));
    let _e108 = (*nomral);
    let _e109 = (*lightDir);
    ShadowBias = max(0.0, (0.0010000000474974513 * (1.0 - dot(_e108, _e109))));
    let _e115 = (*lsp)[2u];
    let _e116 = ShadowBias;
    distance = (_e115 - _e116);
    let _e118 = distance;
    let _e120 = moments_1[0u];
    if (_e118 <= _e120) {
        return 1.0;
    }
    return 0.10000000149011612;
}

fn SRGBtoLINEARvf4_(srgbIn: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e95 = (*srgbIn);
    let _e97 = pow(_e95.xyz, vec3<f32>(2.200000047683716, 2.200000047683716, 2.200000047683716));
    let _e99 = (*srgbIn)[3u];
    return vec4<f32>(_e97.x, _e97.y, _e97.z, _e99);
}

fn CastDirToStvf3_(Dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var pi: f32;
    var theta: f32;
    var phi: f32;
    var st: vec2<f32>;

    pi = 3.1414999961853027;
    let _e100 = (*Dir)[1u];
    theta = acos(_e100);
    let _e103 = (*Dir)[2u];
    let _e105 = (*Dir)[0u];
    phi = atan2(_e103, _e105);
    let _e107 = phi;
    let _e108 = pi;
    let _e111 = theta;
    let _e112 = pi;
    st = vec2<f32>((_e107 / (2.0 * _e108)), (_e111 / _e112));
    let _e115 = st;
    return _e115;
}

fn LINEARtoSRGBvf4_(srgbIn_1: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e95 = (*srgbIn_1);
    let _e97 = pow(_e95.xyz, vec3<f32>(0.4545454680919647, 0.4545454680919647, 0.4545454680919647));
    let _e99 = (*srgbIn_1)[3u];
    return vec4<f32>(_e97.x, _e97.y, _e97.z, _e99);
}

fn ComputeReflectionColorstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31vf3vf3_(pbrParam: ptr<function, PBRParam>, v: ptr<function, vec3<f32>>, n: ptr<function, vec3<f32>>) -> vec3<f32> {
    var reflectColor: vec3<f32>;
    var mipCount: f32;
    var lod: f32;
    var param_1: vec4<f32>;
    var st_1: vec2<f32>;
    var param_2: vec3<f32>;
    var mipCount_1: f32;
    var lod_1: f32;
    var param_3: vec4<f32>;

    reflectColor = vec3<f32>(0.0, 0.0, 0.0);
    let _e107 = ubo.useCubeMap;
    if (_e107 != 0) {
        let _e110 = ubo.mipCount;
        mipCount = _e110;
        let _e111 = mipCount;
        let _e113 = (*pbrParam).perceptualRoughness;
        lod = (_e111 * _e113);
        let _e115 = (*v);
        let _e116 = (*n);
        let _e118 = lod;
        let _e119 = textureSampleLevel(cubemapTexture, cubemapTextureSampler, reflect(_e115, _e116), _e118);
        param_1 = _e119;
        let _e120 = LINEARtoSRGBvf4_((&param_1));
        reflectColor = _e120.xyz;
    } else {
        let _e123 = ubo.useDirCubemap;
        if (_e123 != 0) {
            let _e125 = (*v);
            let _e126 = (*n);
            param_2 = reflect(_e125, _e126);
            let _e128 = CastDirToStvf3_((&param_2));
            st_1 = _e128;
            let _e130 = ubo.mipCount;
            mipCount_1 = _e130;
            let _e131 = mipCount_1;
            let _e133 = (*pbrParam).perceptualRoughness;
            lod_1 = (_e131 * _e133);
            let _e135 = st_1;
            let _e136 = lod_1;
            let _e137 = textureSampleLevel(cubeMap2DTexture, cubeMap2DTextureSampler, _e135, _e136);
            param_3 = _e137;
            let _e138 = LINEARtoSRGBvf4_((&param_3));
            reflectColor = _e138.xyz;
        }
    }
    let _e140 = reflectColor;
    return _e140;
}

fn GetSphericalTexcoordvf3_(Dir_1: ptr<function, vec3<f32>>) -> vec2<f32> {
    var pi_1: f32;
    var theta_1: f32;
    var phi_1: f32;
    var st_2: vec2<f32>;

    pi_1 = 3.1414999961853027;
    let _e100 = (*Dir_1)[1u];
    theta_1 = acos(_e100);
    let _e103 = (*Dir_1)[2u];
    let _e105 = (*Dir_1)[0u];
    phi_1 = atan2(_e103, _e105);
    let _e107 = phi_1;
    let _e108 = pi_1;
    let _e111 = theta_1;
    let _e112 = pi_1;
    st_2 = vec2<f32>((_e107 / (2.0 * _e108)), (_e111 / _e112));
    let _e115 = st_2;
    return _e115;
}

fn ComputeIBLstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31vf3vf3_(pbrParam_1: ptr<function, PBRParam>, v_1: ptr<function, vec3<f32>>, n_1: ptr<function, vec3<f32>>) -> vec3<f32> {
    var mipCount_2: f32;
    var lod_2: f32;
    var brdf: vec3<f32>;
    var param_4: vec4<f32>;
    var diffuseLight: vec3<f32>;
    var param_5: vec3<f32>;
    var param_6: vec4<f32>;
    var specularLight: vec3<f32>;
    var param_7: vec3<f32>;
    var param_8: vec4<f32>;
    var diffuse: vec3<f32>;
    var specular: vec3<f32>;

    let _e110 = ubo.mipCount;
    mipCount_2 = _e110;
    let _e111 = mipCount_2;
    let _e113 = (*pbrParam_1).perceptualRoughness;
    lod_2 = (_e111 * _e113);
    let _e116 = (*pbrParam_1).NdotV;
    let _e118 = (*pbrParam_1).perceptualRoughness;
    let _e121 = textureSample(IBL_GGXLUT_Texture, IBL_GGXLUT_TextureSampler, vec2<f32>(_e116, (1.0 - _e118)));
    param_4 = _e121;
    let _e122 = SRGBtoLINEARvf4_((&param_4));
    brdf = _e122.xyz;
    let _e124 = (*n_1);
    param_5 = _e124;
    let _e125 = GetSphericalTexcoordvf3_((&param_5));
    let _e126 = textureSample(IBL_Diffuse_Texture, IBL_Diffuse_TextureSampler, _e125);
    param_6 = _e126;
    let _e127 = SRGBtoLINEARvf4_((&param_6));
    diffuseLight = _e127.xyz;
    let _e129 = (*v_1);
    let _e130 = (*n_1);
    param_7 = reflect(_e129, _e130);
    let _e132 = GetSphericalTexcoordvf3_((&param_7));
    let _e133 = lod_2;
    let _e134 = textureSampleLevel(IBL_Specular_Texture, IBL_Specular_TextureSampler, _e132, _e133);
    param_8 = _e134;
    let _e135 = SRGBtoLINEARvf4_((&param_8));
    specularLight = _e135.xyz;
    let _e137 = diffuseLight;
    let _e139 = (*pbrParam_1).diffuseColor;
    diffuse = (_e137 * _e139);
    let _e141 = specularLight;
    let _e143 = (*pbrParam_1).specularColor;
    let _e145 = brdf[0u];
    let _e148 = brdf[1u];
    specular = (_e141 * ((_e143 * _e145) + vec3<f32>(_e148)));
    let _e152 = diffuse;
    let _e153 = specular;
    return (_e152 + _e153);
}

fn CalcDiffuseBRDFstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_9: ptr<function, PBRParam>) -> vec3<f32> {
    let _e96 = (*param_9).diffuseColor;
    return (_e96 / vec3<f32>(3.1415927410125732));
}

fn CalcFrenelReflectionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_10: ptr<function, PBRParam>) -> vec3<f32> {
    let _e96 = (*param_10).reflectance0_;
    let _e98 = (*param_10).reflectance90_;
    let _e100 = (*param_10).reflectance0_;
    let _e103 = (*param_10).VdotH;
    return (_e96 + ((_e98 - _e100) * pow(clamp((1.0 - _e103), 0.0, 1.0), 5.0)));
}

fn CalcGeometricOcculusionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_11: ptr<function, PBRParam>) -> f32 {
    var NdotL: f32;
    var NdotV: f32;
    var r: f32;
    var attenuationL: f32;
    var attenuationV: f32;

    let _e101 = (*param_11).NdotL;
    NdotL = _e101;
    let _e103 = (*param_11).NdotV;
    NdotV = _e103;
    let _e105 = (*param_11).alphaRoughness;
    r = _e105;
    let _e106 = NdotL;
    let _e108 = NdotL;
    let _e109 = r;
    let _e110 = r;
    let _e112 = r;
    let _e113 = r;
    let _e116 = NdotL;
    let _e117 = NdotL;
    attenuationL = ((2.0 * _e106) / (_e108 + sqrt(((_e109 * _e110) + ((1.0 - (_e112 * _e113)) * (_e116 * _e117))))));
    let _e124 = NdotV;
    let _e126 = NdotV;
    let _e127 = r;
    let _e128 = r;
    let _e130 = r;
    let _e131 = r;
    let _e134 = NdotV;
    let _e135 = NdotV;
    attenuationV = ((2.0 * _e124) / (_e126 + sqrt(((_e127 * _e128) + ((1.0 - (_e130 * _e131)) * (_e134 * _e135))))));
    let _e142 = attenuationL;
    let _e143 = attenuationV;
    return (_e142 * _e143);
}

fn CalcMicrofacetstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_12: ptr<function, PBRParam>) -> f32 {
    var roughness2_: f32;
    var f: f32;

    let _e98 = (*param_12).alphaRoughness;
    let _e100 = (*param_12).alphaRoughness;
    roughness2_ = (_e98 * _e100);
    let _e103 = (*param_12).NdotH;
    let _e104 = roughness2_;
    let _e107 = (*param_12).NdotH;
    let _e110 = (*param_12).NdotH;
    f = ((((_e103 * _e104) - _e107) * _e110) + 1.0);
    let _e113 = roughness2_;
    let _e114 = f;
    let _e116 = f;
    return (_e113 / ((3.1415927410125732 * _e114) * _e116));
}

fn getNormal() -> vec3<f32> {
    var nomral_1: vec3<f32>;
    var t: vec3<f32>;
    var b: vec3<f32>;
    var n_2: vec3<f32>;
    var tbn: mat3x3<f32>;

    nomral_1 = vec3<f32>(0.0, 0.0, 0.0);
    let _e100 = ubo.useNormalTexture;
    if (_e100 != 0) {
        let _e102 = f_WorldTangent_1;
        t = normalize(_e102);
        let _e104 = f_WorldBioTangent_1;
        b = normalize(_e104);
        let _e106 = f_WorldNormal_1;
        n_2 = normalize(_e106);
        let _e108 = t;
        let _e109 = b;
        let _e110 = n_2;
        tbn = mat3x3<f32>(vec3<f32>(_e108.x, _e108.y, _e108.z), vec3<f32>(_e109.x, _e109.y, _e109.z), vec3<f32>(_e110.x, _e110.y, _e110.z));
        let _e124 = f_Texcoord_1;
        let _e125 = textureSample(normalTexture, normalTextureSampler, _e124);
        nomral_1 = _e125.xyz;
        let _e127 = tbn;
        let _e128 = nomral_1;
        let _e133 = ubo.normalMapScale;
        let _e135 = ubo.normalMapScale;
        nomral_1 = normalize((_e127 * (((_e128 * 2.0) - vec3<f32>(1.0)) * vec3<f32>(_e133, _e135, 1.0))));
    } else {
        let _e140 = f_WorldNormal_1;
        nomral_1 = _e140;
    }
    let _e141 = nomral_1;
    return _e141;
}

fn main_1() {
    var col: vec4<f32>;
    var perceptualRoughness: f32;
    var metallic: f32;
    var metallicRoughnessColor: vec4<f32>;
    var alphaRoughness: f32;
    var baseColor: vec4<f32>;
    var f0_: vec3<f32>;
    var diffuseColor: vec3<f32>;
    var specularColor: vec3<f32>;
    var reflectance: f32;
    var reflectance90_: f32;
    var specularEnvironmentR0_: vec3<f32>;
    var specularEnvironmentR90_: vec3<f32>;
    var n_3: vec3<f32>;
    var v_2: vec3<f32>;
    var l: vec3<f32>;
    var h: vec3<f32>;
    var reflection: vec3<f32>;
    var NdotL_1: f32;
    var NdotV_1: f32;
    var NdotH: f32;
    var LdotH: f32;
    var VdotH: f32;
    var pbrParam_2: PBRParam;
    var specular_1: vec3<f32>;
    var diffuse_1: vec3<f32>;
    var D: f32;
    var param_13: PBRParam;
    var G: f32;
    var param_14: PBRParam;
    var F: vec3<f32>;
    var param_15: PBRParam;
    var param_16: PBRParam;
    var param_17: PBRParam;
    var param_18: vec3<f32>;
    var param_19: vec3<f32>;
    var param_20: PBRParam;
    var param_21: vec3<f32>;
    var param_22: vec3<f32>;
    var gi_diffuse: vec3<f32>;
    var ao: f32;
    var emissive: vec3<f32>;
    var param_23: vec4<f32>;
    var lsp_1: vec3<f32>;
    var shadowCol: f32;
    var outSide: bool;
    var param_24: vec3<f32>;
    var param_25: vec3<f32>;
    var param_26: vec3<f32>;
    var phi_1022_: bool;
    var phi_1029_: bool;
    var phi_1042_: bool;
    var phi_1049_: bool;
    var phi_1050_: bool;

    col = vec4<f32>(1.0, 1.0, 1.0, 1.0);
    let _e144 = ubo.roughnessFactor;
    perceptualRoughness = _e144;
    let _e146 = ubo.metallicFactor;
    metallic = _e146;
    let _e148 = ubo.useMetallicRoughnessTexture;
    if (_e148 != 0) {
        let _e150 = f_Texcoord_1;
        let _e151 = textureSample(metallicRoughnessTexture, metallicRoughnessTextureSampler, _e150);
        metallicRoughnessColor = _e151;
        let _e152 = perceptualRoughness;
        let _e154 = metallicRoughnessColor[1u];
        perceptualRoughness = (_e152 * _e154);
        let _e156 = metallic;
        let _e158 = metallicRoughnessColor[2u];
        metallic = (_e156 * _e158);
    }
    let _e160 = perceptualRoughness;
    perceptualRoughness = clamp(_e160, 0.03999999910593033, 1.0);
    let _e162 = metallic;
    metallic = clamp(_e162, 0.0, 1.0);
    let _e164 = perceptualRoughness;
    let _e165 = perceptualRoughness;
    alphaRoughness = (_e164 * _e165);
    let _e168 = ubo.useBaseColorTexture;
    if (_e168 != 0) {
        let _e170 = f_Texcoord_1;
        let _e171 = textureSample(baseColorTexture, baseColorTextureSampler, _e170);
        baseColor = _e171;
    } else {
        let _e173 = ubo.baseColorFactor;
        baseColor = _e173;
    }
    f0_ = vec3<f32>(0.03999999910593033, 0.03999999910593033, 0.03999999910593033);
    let _e174 = baseColor;
    let _e176 = f0_;
    diffuseColor = (_e174.xyz * (vec3<f32>(1.0, 1.0, 1.0) - _e176));
    let _e179 = metallic;
    let _e181 = diffuseColor;
    diffuseColor = (_e181 * (1.0 - _e179));
    let _e183 = f0_;
    let _e184 = baseColor;
    let _e186 = metallic;
    specularColor = mix(_e183, _e184.xyz, vec3<f32>(_e186));
    let _e190 = specularColor[0u];
    let _e192 = specularColor[1u];
    let _e195 = specularColor[2u];
    reflectance = max(max(_e190, _e192), _e195);
    let _e197 = reflectance;
    reflectance90_ = clamp((_e197 * 25.0), 0.0, 1.0);
    let _e200 = specularColor;
    specularEnvironmentR0_ = _e200;
    let _e201 = reflectance90_;
    specularEnvironmentR90_ = (vec3<f32>(1.0, 1.0, 1.0) * _e201);
    let _e203 = getNormal();
    n_3 = _e203;
    let _e204 = f_WorldPos_1;
    let _e207 = ubo.cameraPos;
    v_2 = (normalize((_e204.xyz - _e207.xyz)) * -1.0);
    let _e213 = ubo.lightDir;
    l = (normalize(_e213.xyz) * -1.0);
    let _e217 = v_2;
    let _e218 = l;
    h = normalize((_e217 + _e218));
    let _e221 = v_2;
    let _e222 = n_3;
    reflection = normalize(reflect(_e221, _e222));
    let _e225 = n_3;
    let _e226 = l;
    NdotL_1 = clamp(dot(_e225, _e226), 0.0, 1.0);
    let _e229 = n_3;
    let _e230 = v_2;
    NdotV_1 = clamp(abs(dot(_e229, _e230)), 0.0, 1.0);
    let _e234 = n_3;
    let _e235 = h;
    NdotH = clamp(dot(_e234, _e235), 0.0, 1.0);
    let _e238 = l;
    let _e239 = h;
    LdotH = clamp(dot(_e238, _e239), 0.0, 1.0);
    let _e242 = v_2;
    let _e243 = h;
    VdotH = clamp(dot(_e242, _e243), 0.0, 1.0);
    let _e246 = NdotL_1;
    let _e247 = NdotV_1;
    let _e248 = NdotH;
    let _e249 = LdotH;
    let _e250 = VdotH;
    let _e251 = perceptualRoughness;
    let _e252 = metallic;
    let _e253 = specularEnvironmentR0_;
    let _e254 = specularEnvironmentR90_;
    let _e255 = alphaRoughness;
    let _e256 = diffuseColor;
    let _e257 = specularColor;
    pbrParam_2 = PBRParam(_e246, _e247, _e248, _e249, _e250, _e251, _e252, _e253, _e254, _e255, _e256, _e257);
    specular_1 = vec3<f32>(0.0, 0.0, 0.0);
    diffuse_1 = vec3<f32>(0.0, 0.0, 0.0);
    let _e259 = pbrParam_2;
    param_13 = _e259;
    let _e260 = CalcMicrofacetstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_13));
    D = _e260;
    let _e261 = pbrParam_2;
    param_14 = _e261;
    let _e262 = CalcGeometricOcculusionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_14));
    G = _e262;
    let _e263 = pbrParam_2;
    param_15 = _e263;
    let _e264 = CalcFrenelReflectionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_15));
    F = _e264;
    let _e265 = NdotL_1;
    let _e267 = NdotV_1;
    if ((_e265 > 0.0) || (_e267 > 0.0)) {
        let _e270 = D;
        let _e271 = G;
        let _e273 = F;
        let _e275 = NdotL_1;
        let _e277 = NdotV_1;
        let _e281 = specular_1;
        specular_1 = (_e281 + ((_e273 * (_e270 * _e271)) / vec3<f32>(((4.0 * _e275) * _e277))));
        let _e283 = specular_1;
        specular_1 = max(_e283, vec3<f32>(0.0, 0.0, 0.0));
        let _e285 = F;
        let _e288 = pbrParam_2;
        param_16 = _e288;
        let _e289 = CalcDiffuseBRDFstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_16));
        let _e291 = diffuse_1;
        diffuse_1 = (_e291 + ((vec3<f32>(1.0) - _e285) * _e289));
        let _e293 = NdotL_1;
        let _e294 = specular_1;
        let _e295 = diffuse_1;
        let _e297 = ((_e294 + _e295) * _e293);
        col[0u] = _e297.x;
        col[1u] = _e297.y;
        col[2u] = _e297.z;
    }
    let _e305 = ubo.useIBL;
    if (_e305 != 0) {
        let _e307 = pbrParam_2;
        param_17 = _e307;
        let _e308 = v_2;
        param_18 = _e308;
        let _e309 = n_3;
        param_19 = _e309;
        let _e310 = ComputeIBLstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31vf3vf3_((&param_17), (&param_18), (&param_19));
        let _e311 = col;
        let _e313 = (_e311.xyz + _e310);
        col[0u] = _e313.x;
        col[1u] = _e313.y;
        col[2u] = _e313.z;
    } else {
        let _e320 = pbrParam_2;
        param_20 = _e320;
        let _e321 = v_2;
        param_21 = _e321;
        let _e322 = n_3;
        param_22 = _e322;
        let _e323 = ComputeReflectionColorstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31vf3vf3_((&param_20), (&param_21), (&param_22));
        let _e324 = F;
        let _e326 = col;
        let _e328 = (_e326.xyz + (_e323 * _e324));
        col[0u] = _e328.x;
        col[1u] = _e328.y;
        col[2u] = _e328.z;
        let _e335 = specular_1;
        gi_diffuse = clamp(_e335, vec3<f32>(0.03999999910593033), vec3<f32>(1.0));
        let _e339 = gi_diffuse;
        let _e340 = diffuse_1;
        let _e342 = col;
        let _e344 = (_e342.xyz + (_e339 * _e340));
        col[0u] = _e344.x;
        col[1u] = _e344.y;
        col[2u] = _e344.z;
    }
    let _e352 = ubo.useOcclusionTexture;
    if (_e352 != 0) {
        let _e354 = f_Texcoord_1;
        let _e355 = textureSample(occlusionTexture, occlusionTextureSampler, _e354);
        ao = _e355.x;
        let _e357 = col;
        let _e359 = col;
        let _e361 = ao;
        let _e364 = ubo.occlusionStrength;
        let _e366 = mix(_e357.xyz, (_e359.xyz * _e361), vec3<f32>(_e364));
        col[0u] = _e366.x;
        col[1u] = _e366.y;
        col[2u] = _e366.z;
    }
    let _e374 = ubo.useEmissiveTexture;
    if (_e374 != 0) {
        let _e376 = f_Texcoord_1;
        let _e377 = textureSample(emissiveTexture, emissiveTextureSampler, _e376);
        param_23 = _e377;
        let _e378 = SRGBtoLINEARvf4_((&param_23));
        let _e381 = ubo.emissiveFactor;
        emissive = (_e378.xyz * _e381.xyz);
        let _e384 = emissive;
        let _e385 = col;
        let _e387 = (_e385.xyz + _e384);
        col[0u] = _e387.x;
        col[1u] = _e387.y;
        col[2u] = _e387.z;
    }
    let _e395 = ubo.useShadowMap;
    if (_e395 != 0) {
        let _e397 = f_LightSpacePos_1;
        let _e400 = f_LightSpacePos_1[3u];
        lsp_1 = (_e397.xyz / vec3<f32>(_e400));
        let _e403 = lsp_1;
        lsp_1 = ((_e403 * 0.5) + vec3<f32>(0.5));
        shadowCol = 1.0;
        let _e408 = lsp_1[0u];
        let _e409 = (_e408 < 0.0);
        phi_1022_ = _e409;
        if !(_e409) {
            let _e412 = lsp_1[1u];
            phi_1022_ = (_e412 < 0.0);
        }
        let _e415 = phi_1022_;
        phi_1029_ = _e415;
        if !(_e415) {
            let _e418 = lsp_1[2u];
            phi_1029_ = (_e418 < 0.0);
        }
        let _e421 = phi_1029_;
        phi_1050_ = _e421;
        if !(_e421) {
            let _e424 = lsp_1[0u];
            let _e425 = (_e424 > 1.0);
            phi_1042_ = _e425;
            if !(_e425) {
                let _e428 = lsp_1[1u];
                phi_1042_ = (_e428 > 1.0);
            }
            let _e431 = phi_1042_;
            phi_1049_ = _e431;
            if !(_e431) {
                let _e434 = lsp_1[2u];
                phi_1049_ = (_e434 > 1.0);
            }
            let _e437 = phi_1049_;
            phi_1050_ = _e437;
        }
        let _e439 = phi_1050_;
        outSide = _e439;
        let _e440 = outSide;
        if !(_e440) {
            let _e442 = lsp_1;
            param_24 = _e442;
            let _e443 = n_3;
            param_25 = _e443;
            let _e444 = l;
            param_26 = _e444;
            let _e445 = CalcShadowvf3vf3vf3_((&param_24), (&param_25), (&param_26));
            shadowCol = _e445;
        }
        let _e446 = shadowCol;
        let _e447 = col;
        let _e449 = (_e447.xyz * _e446);
        col[0u] = _e449.x;
        col[1u] = _e449.y;
        col[2u] = _e449.z;
    }
    let _e456 = col;
    let _e458 = pow(_e456.xyz, vec3<f32>(0.4545454680919647, 0.4545454680919647, 0.4545454680919647));
    col[0u] = _e458.x;
    col[1u] = _e458.y;
    col[2u] = _e458.z;
    let _e466 = baseColor[3u];
    col[3u] = _e466;
    let _e468 = col;
    outColor = _e468;
    return;
}

@fragment 
fn main(@location(3) f_WorldTangent: vec3<f32>, @location(4) f_WorldBioTangent: vec3<f32>, @location(0) f_WorldNormal: vec3<f32>, @location(1) f_Texcoord: vec2<f32>, @location(2) f_WorldPos: vec4<f32>, @location(5) f_LightSpacePos: vec4<f32>) -> @location(0) vec4<f32> {
    f_WorldTangent_1 = f_WorldTangent;
    f_WorldBioTangent_1 = f_WorldBioTangent;
    f_WorldNormal_1 = f_WorldNormal;
    f_Texcoord_1 = f_Texcoord;
    f_WorldPos_1 = f_WorldPos;
    f_LightSpacePos_1 = f_LightSpacePos;
    main_1();
    let _e13 = outColor;
    return _e13;
}
