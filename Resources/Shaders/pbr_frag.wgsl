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
    spatialCullPos: vec4<f32>,
    ambientColor: vec4<f32>,
    time: f32,
    metallicFactor: f32,
    roughnessFactor: f32,
    normalMapScale: f32,
    occlusionStrength: f32,
    mipCount: f32,
    ShadowMapX: f32,
    ShadowMapY: f32,
    emissiveStrength: f32,
    fPad0_: f32,
    fPad1_: f32,
    fPad2_: f32,
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
    useSpatialCulling: i32,
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

    moments = vec2<f32>(0f, 0f);
    let _e99 = ubo.ShadowMapX;
    let _e102 = ubo.ShadowMapY;
    texelSize = vec2<f32>((1f / _e99), (1f / _e102));
    let _e105 = (*uv);
    let _e106 = texelSize;
    let _e109 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e105 + (vec2<f32>(-1f, -1f) * _e106)));
    let _e111 = moments;
    moments = (_e111 + _e109.xy);
    let _e113 = (*uv);
    let _e114 = texelSize;
    let _e117 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e113 + (vec2<f32>(-1f, 0f) * _e114)));
    let _e119 = moments;
    moments = (_e119 + _e117.xy);
    let _e121 = (*uv);
    let _e122 = texelSize;
    let _e125 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e121 + (vec2<f32>(-1f, 1f) * _e122)));
    let _e127 = moments;
    moments = (_e127 + _e125.xy);
    let _e129 = (*uv);
    let _e130 = texelSize;
    let _e133 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e129 + (vec2<f32>(0f, -1f) * _e130)));
    let _e135 = moments;
    moments = (_e135 + _e133.xy);
    let _e137 = (*uv);
    let _e138 = texelSize;
    let _e141 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e137 + (vec2<f32>(0f, 0f) * _e138)));
    let _e143 = moments;
    moments = (_e143 + _e141.xy);
    let _e145 = (*uv);
    let _e146 = texelSize;
    let _e149 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e145 + (vec2<f32>(0f, 1f) * _e146)));
    let _e151 = moments;
    moments = (_e151 + _e149.xy);
    let _e153 = (*uv);
    let _e154 = texelSize;
    let _e157 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e153 + (vec2<f32>(1f, -1f) * _e154)));
    let _e159 = moments;
    moments = (_e159 + _e157.xy);
    let _e161 = (*uv);
    let _e162 = texelSize;
    let _e165 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e161 + (vec2<f32>(1f, 0f) * _e162)));
    let _e167 = moments;
    moments = (_e167 + _e165.xy);
    let _e169 = (*uv);
    let _e170 = texelSize;
    let _e173 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e169 + (vec2<f32>(1f, 1f) * _e170)));
    let _e175 = moments;
    moments = (_e175 + _e173.xy);
    let _e177 = moments;
    moments = (_e177 / vec2(9f));
    let _e180 = moments;
    return _e180;
}

fn CalcShadowvf3vf3vf3_(lsp: ptr<function, vec3<f32>>, nomral: ptr<function, vec3<f32>>, lightDir: ptr<function, vec3<f32>>) -> f32 {
    var moments_1: vec2<f32>;
    var param: vec2<f32>;
    var ShadowBias: f32;
    var distance: f32;

    let _e102 = (*lsp);
    param = _e102.xy;
    let _e104 = ComputePCFvf2_((&param));
    moments_1 = _e104;
    let _e105 = moments_1;
    moments_1 = ((_e105 * 0.5f) + vec2(0.5f));
    let _e109 = (*nomral);
    let _e110 = (*lightDir);
    ShadowBias = max(0f, (0.001f * (1f - dot(_e109, _e110))));
    let _e116 = (*lsp)[2u];
    let _e117 = ShadowBias;
    distance = (_e116 - _e117);
    let _e119 = distance;
    let _e121 = moments_1[0u];
    if (_e119 <= _e121) {
        return 1f;
    }
    return 0.1f;
}

fn SRGBtoLINEARvf4_(srgbIn: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e96 = (*srgbIn);
    let _e98 = pow(_e96.xyz, vec3<f32>(2.2f, 2.2f, 2.2f));
    let _e100 = (*srgbIn)[3u];
    return vec4<f32>(_e98.x, _e98.y, _e98.z, _e100);
}

fn CastDirToStvf3_(Dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var pi: f32;
    var theta: f32;
    var phi: f32;
    var st: vec2<f32>;

    pi = 3.1415f;
    let _e101 = (*Dir)[1u];
    theta = acos(_e101);
    let _e104 = (*Dir)[2u];
    let _e106 = (*Dir)[0u];
    phi = atan2(_e104, _e106);
    let _e108 = phi;
    let _e109 = pi;
    let _e112 = theta;
    let _e113 = pi;
    st = vec2<f32>((_e108 / (2f * _e109)), (_e112 / _e113));
    let _e116 = st;
    return _e116;
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

    reflectColor = vec3<f32>(0f, 0f, 0f);
    let _e108 = ubo.useCubeMap;
    if (_e108 != 0i) {
        let _e111 = ubo.mipCount;
        mipCount = _e111;
        let _e112 = mipCount;
        let _e114 = (*pbrParam).perceptualRoughness;
        lod = (_e112 * _e114);
        let _e116 = (*v);
        let _e117 = (*n);
        let _e119 = lod;
        let _e120 = textureSampleLevel(cubemapTexture, cubemapTextureSampler, reflect(_e116, _e117), _e119);
        param_1 = _e120;
        let _e121 = SRGBtoLINEARvf4_((&param_1));
        reflectColor = _e121.xyz;
    } else {
        let _e124 = ubo.useDirCubemap;
        if (_e124 != 0i) {
            let _e126 = (*v);
            let _e127 = (*n);
            param_2 = reflect(_e126, _e127);
            let _e129 = CastDirToStvf3_((&param_2));
            st_1 = _e129;
            let _e131 = ubo.mipCount;
            mipCount_1 = _e131;
            let _e132 = mipCount_1;
            let _e134 = (*pbrParam).perceptualRoughness;
            lod_1 = (_e132 * _e134);
            let _e136 = st_1;
            let _e137 = lod_1;
            let _e138 = textureSampleLevel(cubeMap2DTexture, cubeMap2DTextureSampler, _e136, _e137);
            param_3 = _e138;
            let _e139 = SRGBtoLINEARvf4_((&param_3));
            reflectColor = _e139.xyz;
        }
    }
    let _e141 = reflectColor;
    return _e141;
}

fn GetSphericalTexcoordvf3_(Dir_1: ptr<function, vec3<f32>>) -> vec2<f32> {
    var pi_1: f32;
    var theta_1: f32;
    var phi_1: f32;
    var st_2: vec2<f32>;

    pi_1 = 3.1415f;
    let _e101 = (*Dir_1)[1u];
    theta_1 = acos(_e101);
    let _e104 = (*Dir_1)[2u];
    let _e106 = (*Dir_1)[0u];
    phi_1 = atan2(_e104, _e106);
    let _e108 = phi_1;
    let _e109 = pi_1;
    let _e112 = theta_1;
    let _e113 = pi_1;
    st_2 = vec2<f32>((_e108 / (2f * _e109)), (_e112 / _e113));
    let _e116 = st_2;
    return _e116;
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

    let _e111 = ubo.mipCount;
    mipCount_2 = _e111;
    let _e112 = mipCount_2;
    let _e114 = (*pbrParam_1).perceptualRoughness;
    lod_2 = (_e112 * _e114);
    let _e117 = (*pbrParam_1).NdotV;
    let _e119 = (*pbrParam_1).perceptualRoughness;
    let _e122 = textureSample(IBL_GGXLUT_Texture, IBL_GGXLUT_TextureSampler, vec2<f32>(_e117, (1f - _e119)));
    param_4 = _e122;
    let _e123 = SRGBtoLINEARvf4_((&param_4));
    brdf = _e123.xyz;
    let _e125 = (*n_1);
    param_5 = _e125;
    let _e126 = GetSphericalTexcoordvf3_((&param_5));
    let _e127 = textureSample(IBL_Diffuse_Texture, IBL_Diffuse_TextureSampler, _e126);
    param_6 = _e127;
    let _e128 = SRGBtoLINEARvf4_((&param_6));
    diffuseLight = _e128.xyz;
    let _e130 = (*v_1);
    let _e131 = (*n_1);
    param_7 = reflect(_e130, _e131);
    let _e133 = GetSphericalTexcoordvf3_((&param_7));
    let _e134 = lod_2;
    let _e135 = textureSampleLevel(IBL_Specular_Texture, IBL_Specular_TextureSampler, _e133, _e134);
    param_8 = _e135;
    let _e136 = SRGBtoLINEARvf4_((&param_8));
    specularLight = _e136.xyz;
    let _e138 = diffuseLight;
    let _e140 = (*pbrParam_1).diffuseColor;
    diffuse = (_e138 * _e140);
    let _e142 = specularLight;
    let _e144 = (*pbrParam_1).specularColor;
    let _e146 = brdf[0u];
    let _e149 = brdf[1u];
    specular = (_e142 * ((_e144 * _e146) + vec3(_e149)));
    let _e153 = specular;
    return _e153;
}

fn CalcDiffuseBRDFstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_9: ptr<function, PBRParam>) -> vec3<f32> {
    var oneminus: f32;

    let _e98 = (*param_9).metallic;
    oneminus = (0.96f - (_e98 * 0.96f));
    let _e102 = (*param_9).diffuseColor;
    let _e103 = oneminus;
    return (_e102 * _e103);
}

fn CalcFrenelReflectionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_10: ptr<function, PBRParam>) -> vec3<f32> {
    let _e97 = (*param_10).reflectance0_;
    let _e99 = (*param_10).reflectance90_;
    let _e101 = (*param_10).reflectance0_;
    let _e104 = (*param_10).VdotH;
    return (_e97 + ((_e99 - _e101) * pow(clamp((1f - _e104), 0f, 1f), 5f)));
}

fn CalcGeometricOcculusionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_11: ptr<function, PBRParam>) -> f32 {
    var NdotL: f32;
    var NdotV: f32;
    var r: f32;
    var attenuationL: f32;
    var attenuationV: f32;

    let _e102 = (*param_11).NdotL;
    NdotL = _e102;
    let _e104 = (*param_11).NdotV;
    NdotV = _e104;
    let _e106 = (*param_11).alphaRoughness;
    r = _e106;
    let _e107 = NdotL;
    let _e109 = NdotL;
    let _e110 = r;
    let _e111 = r;
    let _e113 = r;
    let _e114 = r;
    let _e117 = NdotL;
    let _e118 = NdotL;
    attenuationL = ((2f * _e107) / (_e109 + sqrt(((_e110 * _e111) + ((1f - (_e113 * _e114)) * (_e117 * _e118))))));
    let _e125 = NdotV;
    let _e127 = NdotV;
    let _e128 = r;
    let _e129 = r;
    let _e131 = r;
    let _e132 = r;
    let _e135 = NdotV;
    let _e136 = NdotV;
    attenuationV = ((2f * _e125) / (_e127 + sqrt(((_e128 * _e129) + ((1f - (_e131 * _e132)) * (_e135 * _e136))))));
    let _e143 = attenuationL;
    let _e144 = attenuationV;
    return (_e143 * _e144);
}

fn CalcMicrofacetstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_12: ptr<function, PBRParam>) -> f32 {
    var roughness2_: f32;
    var f: f32;

    let _e99 = (*param_12).alphaRoughness;
    let _e101 = (*param_12).alphaRoughness;
    roughness2_ = (_e99 * _e101);
    let _e104 = (*param_12).NdotH;
    let _e105 = roughness2_;
    let _e108 = (*param_12).NdotH;
    let _e111 = (*param_12).NdotH;
    f = ((((_e104 * _e105) - _e108) * _e111) + 1f);
    let _e114 = roughness2_;
    let _e115 = f;
    let _e117 = f;
    return (_e114 / ((3.1415927f * _e115) * _e117));
}

fn getNormal() -> vec3<f32> {
    var nomral_1: vec3<f32>;
    var t: vec3<f32>;
    var b: vec3<f32>;
    var n_2: vec3<f32>;
    var tbn: mat3x3<f32>;

    nomral_1 = vec3<f32>(0f, 0f, 0f);
    let _e101 = ubo.useNormalTexture;
    if (_e101 != 0i) {
        let _e103 = f_WorldTangent_1;
        t = normalize(_e103);
        let _e105 = f_WorldBioTangent_1;
        b = normalize(_e105);
        let _e107 = f_WorldNormal_1;
        n_2 = normalize(_e107);
        let _e109 = t;
        let _e110 = b;
        let _e111 = n_2;
        tbn = mat3x3<f32>(vec3<f32>(_e109.x, _e109.y, _e109.z), vec3<f32>(_e110.x, _e110.y, _e110.z), vec3<f32>(_e111.x, _e111.y, _e111.z));
        let _e125 = f_Texcoord_1;
        let _e126 = textureSample(normalTexture, normalTextureSampler, _e125);
        nomral_1 = _e126.xyz;
        let _e128 = tbn;
        let _e129 = nomral_1;
        let _e134 = ubo.normalMapScale;
        let _e136 = ubo.normalMapScale;
        nomral_1 = normalize((_e128 * (((_e129 * 2f) - vec3(1f)) * vec3<f32>(_e134, _e136, 1f))));
    } else {
        let _e141 = f_WorldNormal_1;
        nomral_1 = _e141;
    }
    let _e142 = nomral_1;
    return _e142;
}

fn CalcSurface() -> vec4<f32> {
    var col: vec3<f32>;
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
    var alpha: f32;
    var result: vec4<f32>;
    var phi_877_: bool;
    var phi_983_: bool;
    var phi_990_: bool;
    var phi_1003_: bool;
    var phi_1010_: bool;
    var phi_1011_: bool;

    col = vec3<f32>(0f, 0f, 0f);
    let _e147 = ubo.roughnessFactor;
    perceptualRoughness = _e147;
    let _e149 = ubo.metallicFactor;
    metallic = _e149;
    let _e151 = ubo.useMetallicRoughnessTexture;
    if (_e151 != 0i) {
        let _e153 = f_Texcoord_1;
        let _e154 = textureSample(metallicRoughnessTexture, metallicRoughnessTextureSampler, _e153);
        metallicRoughnessColor = _e154;
        let _e155 = perceptualRoughness;
        let _e157 = metallicRoughnessColor[1u];
        perceptualRoughness = (_e155 * _e157);
        let _e159 = metallic;
        let _e161 = metallicRoughnessColor[2u];
        metallic = (_e159 * _e161);
    }
    let _e163 = perceptualRoughness;
    perceptualRoughness = clamp(_e163, 0.04f, 1f);
    let _e165 = metallic;
    metallic = clamp(_e165, 0f, 1f);
    let _e167 = perceptualRoughness;
    let _e168 = perceptualRoughness;
    alphaRoughness = (_e167 * _e168);
    let _e171 = ubo.useBaseColorTexture;
    if (_e171 != 0i) {
        let _e173 = f_Texcoord_1;
        let _e174 = textureSample(baseColorTexture, baseColorTextureSampler, _e173);
        baseColor = _e174;
    } else {
        let _e176 = ubo.baseColorFactor;
        baseColor = _e176;
    }
    f0_ = vec3<f32>(0.04f, 0.04f, 0.04f);
    let _e177 = baseColor;
    let _e179 = f0_;
    diffuseColor = (_e177.xyz * (vec3<f32>(1f, 1f, 1f) - _e179));
    let _e182 = f0_;
    let _e183 = baseColor;
    let _e185 = metallic;
    specularColor = mix(_e182, _e183.xyz, vec3(_e185));
    let _e189 = specularColor[0u];
    let _e191 = specularColor[1u];
    let _e194 = specularColor[2u];
    reflectance = max(max(_e189, _e191), _e194);
    let _e196 = reflectance;
    reflectance90_ = clamp((_e196 * 25f), 0f, 1f);
    let _e199 = specularColor;
    specularEnvironmentR0_ = _e199;
    let _e200 = reflectance90_;
    specularEnvironmentR90_ = (vec3<f32>(1f, 1f, 1f) * _e200);
    let _e202 = getNormal();
    n_3 = _e202;
    let _e203 = f_WorldPos_1;
    let _e206 = ubo.cameraPos;
    v_2 = (normalize((_e203.xyz - _e206.xyz)) * -1f);
    let _e212 = ubo.lightDir;
    l = (normalize(_e212.xyz) * -1f);
    let _e216 = v_2;
    let _e217 = l;
    h = normalize((_e216 + _e217));
    let _e220 = v_2;
    let _e221 = n_3;
    reflection = normalize(reflect(_e220, _e221));
    let _e224 = n_3;
    let _e225 = l;
    NdotL_1 = clamp(dot(_e224, _e225), 0f, 1f);
    let _e228 = n_3;
    let _e229 = v_2;
    NdotV_1 = clamp(abs(dot(_e228, _e229)), 0f, 1f);
    let _e233 = n_3;
    let _e234 = h;
    NdotH = clamp(dot(_e233, _e234), 0f, 1f);
    let _e237 = l;
    let _e238 = h;
    LdotH = clamp(dot(_e237, _e238), 0f, 1f);
    let _e241 = v_2;
    let _e242 = h;
    VdotH = clamp(dot(_e241, _e242), 0f, 1f);
    let _e245 = NdotL_1;
    let _e246 = NdotV_1;
    let _e247 = NdotH;
    let _e248 = LdotH;
    let _e249 = VdotH;
    let _e250 = perceptualRoughness;
    let _e251 = metallic;
    let _e252 = specularEnvironmentR0_;
    let _e253 = specularEnvironmentR90_;
    let _e254 = alphaRoughness;
    let _e255 = diffuseColor;
    let _e256 = specularColor;
    pbrParam_2 = PBRParam(_e245, _e246, _e247, _e248, _e249, _e250, _e251, _e252, _e253, _e254, _e255, _e256);
    specular_1 = vec3<f32>(0f, 0f, 0f);
    diffuse_1 = vec3<f32>(0f, 0f, 0f);
    let _e258 = pbrParam_2;
    param_13 = _e258;
    let _e259 = CalcMicrofacetstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_13));
    D = _e259;
    let _e260 = pbrParam_2;
    param_14 = _e260;
    let _e261 = CalcGeometricOcculusionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_14));
    G = _e261;
    let _e262 = pbrParam_2;
    param_15 = _e262;
    let _e263 = CalcFrenelReflectionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_15));
    F = _e263;
    let _e264 = NdotL_1;
    let _e266 = NdotV_1;
    if ((_e264 > 0f) || (_e266 > 0f)) {
        let _e269 = D;
        let _e270 = G;
        let _e272 = F;
        let _e274 = NdotL_1;
        let _e276 = NdotV_1;
        let _e280 = specular_1;
        specular_1 = (_e280 + ((_e272 * (_e269 * _e270)) / vec3(((4f * _e274) * _e276))));
        let _e282 = specular_1;
        specular_1 = max(_e282, vec3<f32>(0f, 0f, 0f));
        let _e284 = F;
        let _e287 = pbrParam_2;
        param_16 = _e287;
        let _e288 = CalcDiffuseBRDFstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_16));
        let _e290 = diffuse_1;
        diffuse_1 = (_e290 + ((vec3(1f) - _e284) * _e288));
        let _e292 = NdotL_1;
        let _e293 = specular_1;
        let _e294 = diffuse_1;
        col = ((_e293 + _e294) * _e292);
    }
    let _e298 = ubo.useIBL;
    if (_e298 != 0i) {
        let _e300 = pbrParam_2;
        param_17 = _e300;
        let _e301 = v_2;
        param_18 = _e301;
        let _e302 = n_3;
        param_19 = _e302;
        let _e303 = ComputeIBLstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31vf3vf3_((&param_17), (&param_18), (&param_19));
        let _e304 = col;
        col = (_e304 + _e303);
    } else {
        let _e307 = ubo.useCubeMap;
        let _e308 = (_e307 != 0i);
        phi_877_ = _e308;
        if !(_e308) {
            let _e311 = ubo.useDirCubemap;
            phi_877_ = (_e311 != 0i);
        }
        let _e314 = phi_877_;
        if _e314 {
            let _e315 = pbrParam_2;
            param_20 = _e315;
            let _e316 = v_2;
            param_21 = _e316;
            let _e317 = n_3;
            param_22 = _e317;
            let _e318 = ComputeReflectionColorstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31vf3vf3_((&param_20), (&param_21), (&param_22));
            let _e319 = F;
            let _e321 = col;
            col = (_e321 + (_e318 * _e319));
        } else {
            let _e324 = ubo.ambientColor;
            gi_diffuse = _e324.xyz;
            let _e326 = gi_diffuse;
            let _e327 = col;
            col = (_e327 + _e326);
        }
    }
    let _e330 = ubo.useOcclusionTexture;
    if (_e330 != 0i) {
        let _e332 = f_Texcoord_1;
        let _e333 = textureSample(occlusionTexture, occlusionTextureSampler, _e332);
        ao = _e333.x;
        let _e335 = col;
        let _e336 = col;
        let _e337 = ao;
        let _e340 = ubo.occlusionStrength;
        col = mix(_e335, (_e336 * _e337), vec3(_e340));
    }
    let _e344 = ubo.emissiveFactor;
    let _e347 = ubo.emissiveStrength;
    emissive = (_e344.xyz * _e347);
    let _e350 = ubo.useEmissiveTexture;
    if (_e350 != 0i) {
        let _e352 = f_Texcoord_1;
        let _e353 = textureSample(emissiveTexture, emissiveTextureSampler, _e352);
        param_23 = _e353;
        let _e354 = SRGBtoLINEARvf4_((&param_23));
        let _e356 = emissive;
        emissive = (_e356 * _e354.xyz);
    }
    let _e358 = emissive;
    let _e359 = col;
    col = (_e359 + _e358);
    let _e362 = ubo.useShadowMap;
    if (_e362 != 0i) {
        let _e364 = f_LightSpacePos_1;
        let _e367 = f_LightSpacePos_1[3u];
        lsp_1 = (_e364.xyz / vec3(_e367));
        let _e370 = lsp_1;
        lsp_1 = ((_e370 * 0.5f) + vec3(0.5f));
        shadowCol = 1f;
        let _e375 = lsp_1[0u];
        let _e376 = (_e375 < 0f);
        phi_983_ = _e376;
        if !(_e376) {
            let _e379 = lsp_1[1u];
            phi_983_ = (_e379 < 0f);
        }
        let _e382 = phi_983_;
        phi_990_ = _e382;
        if !(_e382) {
            let _e385 = lsp_1[2u];
            phi_990_ = (_e385 < 0f);
        }
        let _e388 = phi_990_;
        phi_1011_ = _e388;
        if !(_e388) {
            let _e391 = lsp_1[0u];
            let _e392 = (_e391 > 1f);
            phi_1003_ = _e392;
            if !(_e392) {
                let _e395 = lsp_1[1u];
                phi_1003_ = (_e395 > 1f);
            }
            let _e398 = phi_1003_;
            phi_1010_ = _e398;
            if !(_e398) {
                let _e401 = lsp_1[2u];
                phi_1010_ = (_e401 > 1f);
            }
            let _e404 = phi_1010_;
            phi_1011_ = _e404;
        }
        let _e406 = phi_1011_;
        outSide = _e406;
        let _e407 = outSide;
        if !(_e407) {
            let _e409 = lsp_1;
            param_24 = _e409;
            let _e410 = n_3;
            param_25 = _e410;
            let _e411 = l;
            param_26 = _e411;
            let _e412 = CalcShadowvf3vf3vf3_((&param_24), (&param_25), (&param_26));
            shadowCol = _e412;
        }
        let _e413 = shadowCol;
        let _e414 = col;
        col = (_e414 * _e413);
    }
    let _e416 = col;
    col = pow(_e416, vec3<f32>(0.45454547f, 0.45454547f, 0.45454547f));
    let _e419 = baseColor[3u];
    alpha = _e419;
    let _e420 = col;
    let _e421 = alpha;
    result = vec4<f32>(_e420.x, _e420.y, _e420.z, _e421);
    let _e426 = result;
    return _e426;
}

fn main_1() {
    var result_1: vec4<f32>;
    var phi_1056_: bool;

    result_1 = vec4<f32>(0f, 0f, 0f, 0f);
    let _e97 = ubo.useSpatialCulling;
    let _e98 = (_e97 != 0i);
    phi_1056_ = _e98;
    if _e98 {
        let _e100 = f_WorldPos_1[1u];
        let _e103 = ubo.spatialCullPos[1u];
        phi_1056_ = (_e100 < _e103);
    }
    let _e106 = phi_1056_;
    if _e106 {
        discard;
    } else {
        let _e107 = CalcSurface();
        result_1 = _e107;
    }
    let _e108 = result_1;
    outColor = _e108;
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
