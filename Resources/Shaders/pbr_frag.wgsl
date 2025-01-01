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
    useFrameTexture: i32,
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
@group(0) @binding(24) 
var frameTexture: texture_2d<f32>;
@group(0) @binding(25) 
var frameTextureSampler: sampler;
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
    let _e101 = ubo.ShadowMapX;
    let _e104 = ubo.ShadowMapY;
    texelSize = vec2<f32>((1.0 / _e101), (1.0 / _e104));
    let _e107 = (*uv);
    let _e108 = texelSize;
    let _e111 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e107 + (vec2<f32>(-1.0, -1.0) * _e108)));
    let _e113 = moments;
    moments = (_e113 + _e111.xy);
    let _e115 = (*uv);
    let _e116 = texelSize;
    let _e119 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e115 + (vec2<f32>(-1.0, 0.0) * _e116)));
    let _e121 = moments;
    moments = (_e121 + _e119.xy);
    let _e123 = (*uv);
    let _e124 = texelSize;
    let _e127 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e123 + (vec2<f32>(-1.0, 1.0) * _e124)));
    let _e129 = moments;
    moments = (_e129 + _e127.xy);
    let _e131 = (*uv);
    let _e132 = texelSize;
    let _e135 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e131 + (vec2<f32>(0.0, -1.0) * _e132)));
    let _e137 = moments;
    moments = (_e137 + _e135.xy);
    let _e139 = (*uv);
    let _e140 = texelSize;
    let _e143 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e139 + (vec2<f32>(0.0, 0.0) * _e140)));
    let _e145 = moments;
    moments = (_e145 + _e143.xy);
    let _e147 = (*uv);
    let _e148 = texelSize;
    let _e151 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e147 + (vec2<f32>(0.0, 1.0) * _e148)));
    let _e153 = moments;
    moments = (_e153 + _e151.xy);
    let _e155 = (*uv);
    let _e156 = texelSize;
    let _e159 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e155 + (vec2<f32>(1.0, -1.0) * _e156)));
    let _e161 = moments;
    moments = (_e161 + _e159.xy);
    let _e163 = (*uv);
    let _e164 = texelSize;
    let _e167 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e163 + (vec2<f32>(1.0, 0.0) * _e164)));
    let _e169 = moments;
    moments = (_e169 + _e167.xy);
    let _e171 = (*uv);
    let _e172 = texelSize;
    let _e175 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e171 + (vec2<f32>(1.0, 1.0) * _e172)));
    let _e177 = moments;
    moments = (_e177 + _e175.xy);
    let _e179 = moments;
    moments = (_e179 / vec2<f32>(9.0));
    let _e182 = moments;
    return _e182;
}

fn CalcShadowvf3vf3vf3_(lsp: ptr<function, vec3<f32>>, nomral: ptr<function, vec3<f32>>, lightDir: ptr<function, vec3<f32>>) -> f32 {
    var moments_1: vec2<f32>;
    var param: vec2<f32>;
    var ShadowBias: f32;
    var distance: f32;

    let _e104 = (*lsp);
    param = _e104.xy;
    let _e106 = ComputePCFvf2_((&param));
    moments_1 = _e106;
    let _e107 = moments_1;
    moments_1 = ((_e107 * 0.5) + vec2<f32>(0.5));
    let _e111 = (*nomral);
    let _e112 = (*lightDir);
    ShadowBias = max(0.0, (0.0010000000474974513 * (1.0 - dot(_e111, _e112))));
    let _e118 = (*lsp)[2u];
    let _e119 = ShadowBias;
    distance = (_e118 - _e119);
    let _e121 = distance;
    let _e123 = moments_1[0u];
    if (_e121 <= _e123) {
        return 1.0;
    }
    return 0.10000000149011612;
}

fn SRGBtoLINEARvf4_(srgbIn: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e98 = (*srgbIn);
    let _e100 = pow(_e98.xyz, vec3<f32>(2.200000047683716, 2.200000047683716, 2.200000047683716));
    let _e102 = (*srgbIn)[3u];
    return vec4<f32>(_e100.x, _e100.y, _e100.z, _e102);
}

fn CastDirToStvf3_(Dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var pi: f32;
    var theta: f32;
    var phi: f32;
    var st: vec2<f32>;

    pi = 3.1414999961853027;
    let _e103 = (*Dir)[1u];
    theta = acos(_e103);
    let _e106 = (*Dir)[2u];
    let _e108 = (*Dir)[0u];
    phi = atan2(_e106, _e108);
    let _e110 = phi;
    let _e111 = pi;
    let _e114 = theta;
    let _e115 = pi;
    st = vec2<f32>((_e110 / (2.0 * _e111)), (_e114 / _e115));
    let _e118 = st;
    return _e118;
}

fn LINEARtoSRGBvf4_(srgbIn_1: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e98 = (*srgbIn_1);
    let _e100 = pow(_e98.xyz, vec3<f32>(0.4545454680919647, 0.4545454680919647, 0.4545454680919647));
    let _e102 = (*srgbIn_1)[3u];
    return vec4<f32>(_e100.x, _e100.y, _e100.z, _e102);
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
    let _e110 = ubo.useCubeMap;
    if (_e110 != 0) {
        let _e113 = ubo.mipCount;
        mipCount = _e113;
        let _e114 = mipCount;
        let _e116 = (*pbrParam).perceptualRoughness;
        lod = (_e114 * _e116);
        let _e118 = (*v);
        let _e119 = (*n);
        let _e121 = lod;
        let _e122 = textureSampleLevel(cubemapTexture, cubemapTextureSampler, reflect(_e118, _e119), _e121);
        param_1 = _e122;
        let _e123 = LINEARtoSRGBvf4_((&param_1));
        reflectColor = _e123.xyz;
    } else {
        let _e126 = ubo.useDirCubemap;
        if (_e126 != 0) {
            let _e128 = (*v);
            let _e129 = (*n);
            param_2 = reflect(_e128, _e129);
            let _e131 = CastDirToStvf3_((&param_2));
            st_1 = _e131;
            let _e133 = ubo.mipCount;
            mipCount_1 = _e133;
            let _e134 = mipCount_1;
            let _e136 = (*pbrParam).perceptualRoughness;
            lod_1 = (_e134 * _e136);
            let _e138 = st_1;
            let _e139 = lod_1;
            let _e140 = textureSampleLevel(cubeMap2DTexture, cubeMap2DTextureSampler, _e138, _e139);
            param_3 = _e140;
            let _e141 = LINEARtoSRGBvf4_((&param_3));
            reflectColor = _e141.xyz;
        }
    }
    let _e143 = reflectColor;
    return _e143;
}

fn GetSphericalTexcoordvf3_(Dir_1: ptr<function, vec3<f32>>) -> vec2<f32> {
    var pi_1: f32;
    var theta_1: f32;
    var phi_1: f32;
    var st_2: vec2<f32>;

    pi_1 = 3.1414999961853027;
    let _e103 = (*Dir_1)[1u];
    theta_1 = acos(_e103);
    let _e106 = (*Dir_1)[2u];
    let _e108 = (*Dir_1)[0u];
    phi_1 = atan2(_e106, _e108);
    let _e110 = phi_1;
    let _e111 = pi_1;
    let _e114 = theta_1;
    let _e115 = pi_1;
    st_2 = vec2<f32>((_e110 / (2.0 * _e111)), (_e114 / _e115));
    let _e118 = st_2;
    return _e118;
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

    let _e113 = ubo.mipCount;
    mipCount_2 = _e113;
    let _e114 = mipCount_2;
    let _e116 = (*pbrParam_1).perceptualRoughness;
    lod_2 = (_e114 * _e116);
    let _e119 = (*pbrParam_1).NdotV;
    let _e121 = (*pbrParam_1).perceptualRoughness;
    let _e124 = textureSample(IBL_GGXLUT_Texture, IBL_GGXLUT_TextureSampler, vec2<f32>(_e119, (1.0 - _e121)));
    param_4 = _e124;
    let _e125 = SRGBtoLINEARvf4_((&param_4));
    brdf = _e125.xyz;
    let _e127 = (*n_1);
    param_5 = _e127;
    let _e128 = GetSphericalTexcoordvf3_((&param_5));
    let _e129 = textureSample(IBL_Diffuse_Texture, IBL_Diffuse_TextureSampler, _e128);
    param_6 = _e129;
    let _e130 = SRGBtoLINEARvf4_((&param_6));
    diffuseLight = _e130.xyz;
    let _e132 = (*v_1);
    let _e133 = (*n_1);
    param_7 = reflect(_e132, _e133);
    let _e135 = GetSphericalTexcoordvf3_((&param_7));
    let _e136 = lod_2;
    let _e137 = textureSampleLevel(IBL_Specular_Texture, IBL_Specular_TextureSampler, _e135, _e136);
    param_8 = _e137;
    let _e138 = SRGBtoLINEARvf4_((&param_8));
    specularLight = _e138.xyz;
    let _e140 = diffuseLight;
    let _e142 = (*pbrParam_1).diffuseColor;
    diffuse = (_e140 * _e142);
    let _e144 = specularLight;
    let _e146 = (*pbrParam_1).specularColor;
    let _e148 = brdf[0u];
    let _e151 = brdf[1u];
    specular = (_e144 * ((_e146 * _e148) + vec3<f32>(_e151)));
    let _e155 = diffuse;
    let _e156 = specular;
    return (_e155 + _e156);
}

fn CalcDiffuseBRDFstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_9: ptr<function, PBRParam>) -> vec3<f32> {
    let _e99 = (*param_9).diffuseColor;
    return (_e99 / vec3<f32>(3.1415927410125732));
}

fn CalcFrenelReflectionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_10: ptr<function, PBRParam>) -> vec3<f32> {
    let _e99 = (*param_10).reflectance0_;
    let _e101 = (*param_10).reflectance90_;
    let _e103 = (*param_10).reflectance0_;
    let _e106 = (*param_10).VdotH;
    return (_e99 + ((_e101 - _e103) * pow(clamp((1.0 - _e106), 0.0, 1.0), 5.0)));
}

fn CalcGeometricOcculusionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_11: ptr<function, PBRParam>) -> f32 {
    var NdotL: f32;
    var NdotV: f32;
    var r: f32;
    var attenuationL: f32;
    var attenuationV: f32;

    let _e104 = (*param_11).NdotL;
    NdotL = _e104;
    let _e106 = (*param_11).NdotV;
    NdotV = _e106;
    let _e108 = (*param_11).alphaRoughness;
    r = _e108;
    let _e109 = NdotL;
    let _e111 = NdotL;
    let _e112 = r;
    let _e113 = r;
    let _e115 = r;
    let _e116 = r;
    let _e119 = NdotL;
    let _e120 = NdotL;
    attenuationL = ((2.0 * _e109) / (_e111 + sqrt(((_e112 * _e113) + ((1.0 - (_e115 * _e116)) * (_e119 * _e120))))));
    let _e127 = NdotV;
    let _e129 = NdotV;
    let _e130 = r;
    let _e131 = r;
    let _e133 = r;
    let _e134 = r;
    let _e137 = NdotV;
    let _e138 = NdotV;
    attenuationV = ((2.0 * _e127) / (_e129 + sqrt(((_e130 * _e131) + ((1.0 - (_e133 * _e134)) * (_e137 * _e138))))));
    let _e145 = attenuationL;
    let _e146 = attenuationV;
    return (_e145 * _e146);
}

fn CalcMicrofacetstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_12: ptr<function, PBRParam>) -> f32 {
    var roughness2_: f32;
    var f: f32;

    let _e101 = (*param_12).alphaRoughness;
    let _e103 = (*param_12).alphaRoughness;
    roughness2_ = (_e101 * _e103);
    let _e106 = (*param_12).NdotH;
    let _e107 = roughness2_;
    let _e110 = (*param_12).NdotH;
    let _e113 = (*param_12).NdotH;
    f = ((((_e106 * _e107) - _e110) * _e113) + 1.0);
    let _e116 = roughness2_;
    let _e117 = f;
    let _e119 = f;
    return (_e116 / ((3.1415927410125732 * _e117) * _e119));
}

fn getNormal() -> vec3<f32> {
    var nomral_1: vec3<f32>;
    var t: vec3<f32>;
    var b: vec3<f32>;
    var n_2: vec3<f32>;
    var tbn: mat3x3<f32>;

    nomral_1 = vec3<f32>(0.0, 0.0, 0.0);
    let _e103 = ubo.useNormalTexture;
    if (_e103 != 0) {
        let _e105 = f_WorldTangent_1;
        t = normalize(_e105);
        let _e107 = f_WorldBioTangent_1;
        b = normalize(_e107);
        let _e109 = f_WorldNormal_1;
        n_2 = normalize(_e109);
        let _e111 = t;
        let _e112 = b;
        let _e113 = n_2;
        tbn = mat3x3<f32>(vec3<f32>(_e111.x, _e111.y, _e111.z), vec3<f32>(_e112.x, _e112.y, _e112.z), vec3<f32>(_e113.x, _e113.y, _e113.z));
        let _e127 = f_Texcoord_1;
        let _e128 = textureSample(normalTexture, normalTextureSampler, _e127);
        nomral_1 = _e128.xyz;
        let _e130 = tbn;
        let _e131 = nomral_1;
        let _e136 = ubo.normalMapScale;
        let _e138 = ubo.normalMapScale;
        nomral_1 = normalize((_e130 * (((_e131 * 2.0) - vec3<f32>(1.0)) * vec3<f32>(_e136, _e138, 1.0))));
    } else {
        let _e143 = f_WorldNormal_1;
        nomral_1 = _e143;
    }
    let _e144 = nomral_1;
    return _e144;
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
    var frameUV: vec2<f32>;
    var ao: f32;
    var emissive: vec3<f32>;
    var param_23: vec4<f32>;
    var lsp_1: vec3<f32>;
    var shadowCol: f32;
    var outSide: bool;
    var param_24: vec3<f32>;
    var param_25: vec3<f32>;
    var param_26: vec3<f32>;
    var phi_1052_: bool;
    var phi_1059_: bool;
    var phi_1072_: bool;
    var phi_1079_: bool;
    var phi_1080_: bool;

    col = vec4<f32>(1.0, 1.0, 1.0, 1.0);
    let _e148 = ubo.roughnessFactor;
    perceptualRoughness = _e148;
    let _e150 = ubo.metallicFactor;
    metallic = _e150;
    let _e152 = ubo.useMetallicRoughnessTexture;
    if (_e152 != 0) {
        let _e154 = f_Texcoord_1;
        let _e155 = textureSample(metallicRoughnessTexture, metallicRoughnessTextureSampler, _e154);
        metallicRoughnessColor = _e155;
        let _e156 = perceptualRoughness;
        let _e158 = metallicRoughnessColor[1u];
        perceptualRoughness = (_e156 * _e158);
        let _e160 = metallic;
        let _e162 = metallicRoughnessColor[2u];
        metallic = (_e160 * _e162);
    }
    let _e164 = perceptualRoughness;
    perceptualRoughness = clamp(_e164, 0.03999999910593033, 1.0);
    let _e166 = metallic;
    metallic = clamp(_e166, 0.0, 1.0);
    let _e168 = perceptualRoughness;
    let _e169 = perceptualRoughness;
    alphaRoughness = (_e168 * _e169);
    let _e172 = ubo.useBaseColorTexture;
    if (_e172 != 0) {
        let _e174 = f_Texcoord_1;
        let _e175 = textureSample(baseColorTexture, baseColorTextureSampler, _e174);
        baseColor = _e175;
    } else {
        let _e177 = ubo.baseColorFactor;
        baseColor = _e177;
    }
    f0_ = vec3<f32>(0.03999999910593033, 0.03999999910593033, 0.03999999910593033);
    let _e178 = baseColor;
    let _e180 = f0_;
    diffuseColor = (_e178.xyz * (vec3<f32>(1.0, 1.0, 1.0) - _e180));
    let _e183 = metallic;
    let _e185 = diffuseColor;
    diffuseColor = (_e185 * (1.0 - _e183));
    let _e187 = f0_;
    let _e188 = baseColor;
    let _e190 = metallic;
    specularColor = mix(_e187, _e188.xyz, vec3<f32>(_e190));
    let _e194 = specularColor[0u];
    let _e196 = specularColor[1u];
    let _e199 = specularColor[2u];
    reflectance = max(max(_e194, _e196), _e199);
    let _e201 = reflectance;
    reflectance90_ = clamp((_e201 * 25.0), 0.0, 1.0);
    let _e204 = specularColor;
    specularEnvironmentR0_ = _e204;
    let _e205 = reflectance90_;
    specularEnvironmentR90_ = (vec3<f32>(1.0, 1.0, 1.0) * _e205);
    let _e207 = getNormal();
    n_3 = _e207;
    let _e208 = f_WorldPos_1;
    let _e211 = ubo.cameraPos;
    v_2 = (normalize((_e208.xyz - _e211.xyz)) * -1.0);
    let _e217 = ubo.lightDir;
    l = (normalize(_e217.xyz) * -1.0);
    let _e221 = v_2;
    let _e222 = l;
    h = normalize((_e221 + _e222));
    let _e225 = v_2;
    let _e226 = n_3;
    reflection = normalize(reflect(_e225, _e226));
    let _e229 = n_3;
    let _e230 = l;
    NdotL_1 = clamp(dot(_e229, _e230), 0.0, 1.0);
    let _e233 = n_3;
    let _e234 = v_2;
    NdotV_1 = clamp(abs(dot(_e233, _e234)), 0.0, 1.0);
    let _e238 = n_3;
    let _e239 = h;
    NdotH = clamp(dot(_e238, _e239), 0.0, 1.0);
    let _e242 = l;
    let _e243 = h;
    LdotH = clamp(dot(_e242, _e243), 0.0, 1.0);
    let _e246 = v_2;
    let _e247 = h;
    VdotH = clamp(dot(_e246, _e247), 0.0, 1.0);
    let _e250 = NdotL_1;
    let _e251 = NdotV_1;
    let _e252 = NdotH;
    let _e253 = LdotH;
    let _e254 = VdotH;
    let _e255 = perceptualRoughness;
    let _e256 = metallic;
    let _e257 = specularEnvironmentR0_;
    let _e258 = specularEnvironmentR90_;
    let _e259 = alphaRoughness;
    let _e260 = diffuseColor;
    let _e261 = specularColor;
    pbrParam_2 = PBRParam(_e250, _e251, _e252, _e253, _e254, _e255, _e256, _e257, _e258, _e259, _e260, _e261);
    specular_1 = vec3<f32>(0.0, 0.0, 0.0);
    diffuse_1 = vec3<f32>(0.0, 0.0, 0.0);
    let _e263 = pbrParam_2;
    param_13 = _e263;
    let _e264 = CalcMicrofacetstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_13));
    D = _e264;
    let _e265 = pbrParam_2;
    param_14 = _e265;
    let _e266 = CalcGeometricOcculusionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_14));
    G = _e266;
    let _e267 = pbrParam_2;
    param_15 = _e267;
    let _e268 = CalcFrenelReflectionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_15));
    F = _e268;
    let _e269 = NdotL_1;
    let _e271 = NdotV_1;
    if ((_e269 > 0.0) || (_e271 > 0.0)) {
        let _e274 = D;
        let _e275 = G;
        let _e277 = F;
        let _e279 = NdotL_1;
        let _e281 = NdotV_1;
        let _e285 = specular_1;
        specular_1 = (_e285 + ((_e277 * (_e274 * _e275)) / vec3<f32>(((4.0 * _e279) * _e281))));
        let _e287 = specular_1;
        specular_1 = max(_e287, vec3<f32>(0.0, 0.0, 0.0));
        let _e289 = F;
        let _e292 = pbrParam_2;
        param_16 = _e292;
        let _e293 = CalcDiffuseBRDFstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_16));
        let _e295 = diffuse_1;
        diffuse_1 = (_e295 + ((vec3<f32>(1.0) - _e289) * _e293));
        let _e297 = NdotL_1;
        let _e298 = specular_1;
        let _e299 = diffuse_1;
        let _e301 = ((_e298 + _e299) * _e297);
        col[0u] = _e301.x;
        col[1u] = _e301.y;
        col[2u] = _e301.z;
    }
    let _e309 = ubo.useIBL;
    if (_e309 != 0) {
        let _e311 = pbrParam_2;
        param_17 = _e311;
        let _e312 = v_2;
        param_18 = _e312;
        let _e313 = n_3;
        param_19 = _e313;
        let _e314 = ComputeIBLstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31vf3vf3_((&param_17), (&param_18), (&param_19));
        let _e315 = col;
        let _e317 = (_e315.xyz + _e314);
        col[0u] = _e317.x;
        col[1u] = _e317.y;
        col[2u] = _e317.z;
    } else {
        let _e324 = pbrParam_2;
        param_20 = _e324;
        let _e325 = v_2;
        param_21 = _e325;
        let _e326 = n_3;
        param_22 = _e326;
        let _e327 = ComputeReflectionColorstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31vf3vf3_((&param_20), (&param_21), (&param_22));
        let _e328 = F;
        let _e330 = col;
        let _e332 = (_e330.xyz + (_e327 * _e328));
        col[0u] = _e332.x;
        col[1u] = _e332.y;
        col[2u] = _e332.z;
        let _e339 = specular_1;
        gi_diffuse = clamp(_e339, vec3<f32>(0.03999999910593033), vec3<f32>(1.0));
        let _e343 = gi_diffuse;
        let _e344 = diffuse_1;
        let _e346 = col;
        let _e348 = (_e346.xyz + (_e343 * _e344));
        col[0u] = _e348.x;
        col[1u] = _e348.y;
        col[2u] = _e348.z;
    }
    let _e356 = ubo.useFrameTexture;
    if (_e356 != 0) {
        let _e359 = f_Texcoord_1[0u];
        let _e362 = f_Texcoord_1[1u];
        frameUV = vec2<f32>((1.0 - _e359), _e362);
        let _e364 = frameUV;
        let _e365 = textureSample(frameTexture, frameTextureSampler, _e364);
        let _e367 = col;
        let _e369 = (_e367.xyz + _e365.xyz);
        col[0u] = _e369.x;
        col[1u] = _e369.y;
        col[2u] = _e369.z;
    }
    let _e377 = ubo.useOcclusionTexture;
    if (_e377 != 0) {
        let _e379 = f_Texcoord_1;
        let _e380 = textureSample(occlusionTexture, occlusionTextureSampler, _e379);
        ao = _e380.x;
        let _e382 = col;
        let _e384 = col;
        let _e386 = ao;
        let _e389 = ubo.occlusionStrength;
        let _e391 = mix(_e382.xyz, (_e384.xyz * _e386), vec3<f32>(_e389));
        col[0u] = _e391.x;
        col[1u] = _e391.y;
        col[2u] = _e391.z;
    }
    let _e399 = ubo.useEmissiveTexture;
    if (_e399 != 0) {
        let _e401 = f_Texcoord_1;
        let _e402 = textureSample(emissiveTexture, emissiveTextureSampler, _e401);
        param_23 = _e402;
        let _e403 = SRGBtoLINEARvf4_((&param_23));
        let _e406 = ubo.emissiveFactor;
        emissive = (_e403.xyz * _e406.xyz);
        let _e409 = emissive;
        let _e410 = col;
        let _e412 = (_e410.xyz + _e409);
        col[0u] = _e412.x;
        col[1u] = _e412.y;
        col[2u] = _e412.z;
    }
    let _e420 = ubo.useShadowMap;
    if (_e420 != 0) {
        let _e422 = f_LightSpacePos_1;
        let _e425 = f_LightSpacePos_1[3u];
        lsp_1 = (_e422.xyz / vec3<f32>(_e425));
        let _e428 = lsp_1;
        lsp_1 = ((_e428 * 0.5) + vec3<f32>(0.5));
        shadowCol = 1.0;
        let _e433 = lsp_1[0u];
        let _e434 = (_e433 < 0.0);
        phi_1052_ = _e434;
        if !(_e434) {
            let _e437 = lsp_1[1u];
            phi_1052_ = (_e437 < 0.0);
        }
        let _e440 = phi_1052_;
        phi_1059_ = _e440;
        if !(_e440) {
            let _e443 = lsp_1[2u];
            phi_1059_ = (_e443 < 0.0);
        }
        let _e446 = phi_1059_;
        phi_1080_ = _e446;
        if !(_e446) {
            let _e449 = lsp_1[0u];
            let _e450 = (_e449 > 1.0);
            phi_1072_ = _e450;
            if !(_e450) {
                let _e453 = lsp_1[1u];
                phi_1072_ = (_e453 > 1.0);
            }
            let _e456 = phi_1072_;
            phi_1079_ = _e456;
            if !(_e456) {
                let _e459 = lsp_1[2u];
                phi_1079_ = (_e459 > 1.0);
            }
            let _e462 = phi_1079_;
            phi_1080_ = _e462;
        }
        let _e464 = phi_1080_;
        outSide = _e464;
        let _e465 = outSide;
        if !(_e465) {
            let _e467 = lsp_1;
            param_24 = _e467;
            let _e468 = n_3;
            param_25 = _e468;
            let _e469 = l;
            param_26 = _e469;
            let _e470 = CalcShadowvf3vf3vf3_((&param_24), (&param_25), (&param_26));
            shadowCol = _e470;
        }
        let _e471 = shadowCol;
        let _e472 = col;
        let _e474 = (_e472.xyz * _e471);
        col[0u] = _e474.x;
        col[1u] = _e474.y;
        col[2u] = _e474.z;
    }
    let _e481 = col;
    let _e483 = pow(_e481.xyz, vec3<f32>(0.4545454680919647, 0.4545454680919647, 0.4545454680919647));
    col[0u] = _e483.x;
    col[1u] = _e483.y;
    col[2u] = _e483.z;
    let _e491 = baseColor[3u];
    col[3u] = _e491;
    let _e493 = col;
    outColor = _e493;
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
