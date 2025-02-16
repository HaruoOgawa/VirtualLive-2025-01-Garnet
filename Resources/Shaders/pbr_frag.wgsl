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

    moments = vec2<f32>(0.0, 0.0);
    let _e103 = ubo.ShadowMapX;
    let _e106 = ubo.ShadowMapY;
    texelSize = vec2<f32>((1.0 / _e103), (1.0 / _e106));
    let _e109 = (*uv);
    let _e110 = texelSize;
    let _e113 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e109 + (vec2<f32>(-1.0, -1.0) * _e110)));
    let _e115 = moments;
    moments = (_e115 + _e113.xy);
    let _e117 = (*uv);
    let _e118 = texelSize;
    let _e121 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e117 + (vec2<f32>(-1.0, 0.0) * _e118)));
    let _e123 = moments;
    moments = (_e123 + _e121.xy);
    let _e125 = (*uv);
    let _e126 = texelSize;
    let _e129 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e125 + (vec2<f32>(-1.0, 1.0) * _e126)));
    let _e131 = moments;
    moments = (_e131 + _e129.xy);
    let _e133 = (*uv);
    let _e134 = texelSize;
    let _e137 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e133 + (vec2<f32>(0.0, -1.0) * _e134)));
    let _e139 = moments;
    moments = (_e139 + _e137.xy);
    let _e141 = (*uv);
    let _e142 = texelSize;
    let _e145 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e141 + (vec2<f32>(0.0, 0.0) * _e142)));
    let _e147 = moments;
    moments = (_e147 + _e145.xy);
    let _e149 = (*uv);
    let _e150 = texelSize;
    let _e153 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e149 + (vec2<f32>(0.0, 1.0) * _e150)));
    let _e155 = moments;
    moments = (_e155 + _e153.xy);
    let _e157 = (*uv);
    let _e158 = texelSize;
    let _e161 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e157 + (vec2<f32>(1.0, -1.0) * _e158)));
    let _e163 = moments;
    moments = (_e163 + _e161.xy);
    let _e165 = (*uv);
    let _e166 = texelSize;
    let _e169 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e165 + (vec2<f32>(1.0, 0.0) * _e166)));
    let _e171 = moments;
    moments = (_e171 + _e169.xy);
    let _e173 = (*uv);
    let _e174 = texelSize;
    let _e177 = textureSample(shadowmapTexture, shadowmapTextureSampler, (_e173 + (vec2<f32>(1.0, 1.0) * _e174)));
    let _e179 = moments;
    moments = (_e179 + _e177.xy);
    let _e181 = moments;
    moments = (_e181 / vec2<f32>(9.0));
    let _e184 = moments;
    return _e184;
}

fn CalcShadowvf3vf3vf3_(lsp: ptr<function, vec3<f32>>, nomral: ptr<function, vec3<f32>>, lightDir: ptr<function, vec3<f32>>) -> f32 {
    var moments_1: vec2<f32>;
    var param: vec2<f32>;
    var ShadowBias: f32;
    var distance: f32;

    let _e106 = (*lsp);
    param = _e106.xy;
    let _e108 = ComputePCFvf2_((&param));
    moments_1 = _e108;
    let _e109 = moments_1;
    moments_1 = ((_e109 * 0.5) + vec2<f32>(0.5));
    let _e113 = (*nomral);
    let _e114 = (*lightDir);
    ShadowBias = max(0.0, (0.0010000000474974513 * (1.0 - dot(_e113, _e114))));
    let _e120 = (*lsp)[2u];
    let _e121 = ShadowBias;
    distance = (_e120 - _e121);
    let _e123 = distance;
    let _e125 = moments_1[0u];
    if (_e123 <= _e125) {
        return 1.0;
    }
    return 0.10000000149011612;
}

fn SRGBtoLINEARvf4_(srgbIn: ptr<function, vec4<f32>>) -> vec4<f32> {
    let _e100 = (*srgbIn);
    let _e102 = pow(_e100.xyz, vec3<f32>(2.200000047683716, 2.200000047683716, 2.200000047683716));
    let _e104 = (*srgbIn)[3u];
    return vec4<f32>(_e102.x, _e102.y, _e102.z, _e104);
}

fn CastDirToStvf3_(Dir: ptr<function, vec3<f32>>) -> vec2<f32> {
    var pi: f32;
    var theta: f32;
    var phi: f32;
    var st: vec2<f32>;

    pi = 3.1414999961853027;
    let _e105 = (*Dir)[1u];
    theta = acos(_e105);
    let _e108 = (*Dir)[2u];
    let _e110 = (*Dir)[0u];
    phi = atan2(_e108, _e110);
    let _e112 = phi;
    let _e113 = pi;
    let _e116 = theta;
    let _e117 = pi;
    st = vec2<f32>((_e112 / (2.0 * _e113)), (_e116 / _e117));
    let _e120 = st;
    return _e120;
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
    let _e112 = ubo.useCubeMap;
    if (_e112 != 0) {
        let _e115 = ubo.mipCount;
        mipCount = _e115;
        let _e116 = mipCount;
        let _e118 = (*pbrParam).perceptualRoughness;
        lod = (_e116 * _e118);
        let _e120 = (*v);
        let _e121 = (*n);
        let _e123 = lod;
        let _e124 = textureSampleLevel(cubemapTexture, cubemapTextureSampler, reflect(_e120, _e121), _e123);
        param_1 = _e124;
        let _e125 = SRGBtoLINEARvf4_((&param_1));
        reflectColor = _e125.xyz;
    } else {
        let _e128 = ubo.useDirCubemap;
        if (_e128 != 0) {
            let _e130 = (*v);
            let _e131 = (*n);
            param_2 = reflect(_e130, _e131);
            let _e133 = CastDirToStvf3_((&param_2));
            st_1 = _e133;
            let _e135 = ubo.mipCount;
            mipCount_1 = _e135;
            let _e136 = mipCount_1;
            let _e138 = (*pbrParam).perceptualRoughness;
            lod_1 = (_e136 * _e138);
            let _e140 = st_1;
            let _e141 = lod_1;
            let _e142 = textureSampleLevel(cubeMap2DTexture, cubeMap2DTextureSampler, _e140, _e141);
            param_3 = _e142;
            let _e143 = SRGBtoLINEARvf4_((&param_3));
            reflectColor = _e143.xyz;
        }
    }
    let _e145 = reflectColor;
    return _e145;
}

fn GetSphericalTexcoordvf3_(Dir_1: ptr<function, vec3<f32>>) -> vec2<f32> {
    var pi_1: f32;
    var theta_1: f32;
    var phi_1: f32;
    var st_2: vec2<f32>;

    pi_1 = 3.1414999961853027;
    let _e105 = (*Dir_1)[1u];
    theta_1 = acos(_e105);
    let _e108 = (*Dir_1)[2u];
    let _e110 = (*Dir_1)[0u];
    phi_1 = atan2(_e108, _e110);
    let _e112 = phi_1;
    let _e113 = pi_1;
    let _e116 = theta_1;
    let _e117 = pi_1;
    st_2 = vec2<f32>((_e112 / (2.0 * _e113)), (_e116 / _e117));
    let _e120 = st_2;
    return _e120;
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

    let _e115 = ubo.mipCount;
    mipCount_2 = _e115;
    let _e116 = mipCount_2;
    let _e118 = (*pbrParam_1).perceptualRoughness;
    lod_2 = (_e116 * _e118);
    let _e121 = (*pbrParam_1).NdotV;
    let _e123 = (*pbrParam_1).perceptualRoughness;
    let _e126 = textureSample(IBL_GGXLUT_Texture, IBL_GGXLUT_TextureSampler, vec2<f32>(_e121, (1.0 - _e123)));
    param_4 = _e126;
    let _e127 = SRGBtoLINEARvf4_((&param_4));
    brdf = _e127.xyz;
    let _e129 = (*n_1);
    param_5 = _e129;
    let _e130 = GetSphericalTexcoordvf3_((&param_5));
    let _e131 = textureSample(IBL_Diffuse_Texture, IBL_Diffuse_TextureSampler, _e130);
    param_6 = _e131;
    let _e132 = SRGBtoLINEARvf4_((&param_6));
    diffuseLight = _e132.xyz;
    let _e134 = (*v_1);
    let _e135 = (*n_1);
    param_7 = reflect(_e134, _e135);
    let _e137 = GetSphericalTexcoordvf3_((&param_7));
    let _e138 = lod_2;
    let _e139 = textureSampleLevel(IBL_Specular_Texture, IBL_Specular_TextureSampler, _e137, _e138);
    param_8 = _e139;
    let _e140 = SRGBtoLINEARvf4_((&param_8));
    specularLight = _e140.xyz;
    let _e142 = diffuseLight;
    let _e144 = (*pbrParam_1).diffuseColor;
    diffuse = (_e142 * _e144);
    let _e146 = specularLight;
    let _e148 = (*pbrParam_1).specularColor;
    let _e150 = brdf[0u];
    let _e153 = brdf[1u];
    specular = (_e146 * ((_e148 * _e150) + vec3<f32>(_e153)));
    let _e157 = specular;
    return _e157;
}

fn CalcDiffuseBRDFstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_9: ptr<function, PBRParam>) -> vec3<f32> {
    var oneminus: f32;

    let _e102 = (*param_9).metallic;
    oneminus = (0.9599999785423279 - (_e102 * 0.9599999785423279));
    let _e106 = (*param_9).diffuseColor;
    let _e107 = oneminus;
    return (_e106 * _e107);
}

fn CalcFrenelReflectionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_10: ptr<function, PBRParam>) -> vec3<f32> {
    let _e101 = (*param_10).reflectance0_;
    let _e103 = (*param_10).reflectance90_;
    let _e105 = (*param_10).reflectance0_;
    let _e108 = (*param_10).VdotH;
    return (_e101 + ((_e103 - _e105) * pow(clamp((1.0 - _e108), 0.0, 1.0), 5.0)));
}

fn CalcGeometricOcculusionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_11: ptr<function, PBRParam>) -> f32 {
    var NdotL: f32;
    var NdotV: f32;
    var r: f32;
    var attenuationL: f32;
    var attenuationV: f32;

    let _e106 = (*param_11).NdotL;
    NdotL = _e106;
    let _e108 = (*param_11).NdotV;
    NdotV = _e108;
    let _e110 = (*param_11).alphaRoughness;
    r = _e110;
    let _e111 = NdotL;
    let _e113 = NdotL;
    let _e114 = r;
    let _e115 = r;
    let _e117 = r;
    let _e118 = r;
    let _e121 = NdotL;
    let _e122 = NdotL;
    attenuationL = ((2.0 * _e111) / (_e113 + sqrt(((_e114 * _e115) + ((1.0 - (_e117 * _e118)) * (_e121 * _e122))))));
    let _e129 = NdotV;
    let _e131 = NdotV;
    let _e132 = r;
    let _e133 = r;
    let _e135 = r;
    let _e136 = r;
    let _e139 = NdotV;
    let _e140 = NdotV;
    attenuationV = ((2.0 * _e129) / (_e131 + sqrt(((_e132 * _e133) + ((1.0 - (_e135 * _e136)) * (_e139 * _e140))))));
    let _e147 = attenuationL;
    let _e148 = attenuationV;
    return (_e147 * _e148);
}

fn CalcMicrofacetstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_(param_12: ptr<function, PBRParam>) -> f32 {
    var roughness2_: f32;
    var f: f32;

    let _e103 = (*param_12).alphaRoughness;
    let _e105 = (*param_12).alphaRoughness;
    roughness2_ = (_e103 * _e105);
    let _e108 = (*param_12).NdotH;
    let _e109 = roughness2_;
    let _e112 = (*param_12).NdotH;
    let _e115 = (*param_12).NdotH;
    f = ((((_e108 * _e109) - _e112) * _e115) + 1.0);
    let _e118 = roughness2_;
    let _e119 = f;
    let _e121 = f;
    return (_e118 / ((3.1415927410125732 * _e119) * _e121));
}

fn getNormal() -> vec3<f32> {
    var nomral_1: vec3<f32>;
    var t: vec3<f32>;
    var b: vec3<f32>;
    var n_2: vec3<f32>;
    var tbn: mat3x3<f32>;

    nomral_1 = vec3<f32>(0.0, 0.0, 0.0);
    let _e105 = ubo.useNormalTexture;
    if (_e105 != 0) {
        let _e107 = f_WorldTangent_1;
        t = normalize(_e107);
        let _e109 = f_WorldBioTangent_1;
        b = normalize(_e109);
        let _e111 = f_WorldNormal_1;
        n_2 = normalize(_e111);
        let _e113 = t;
        let _e114 = b;
        let _e115 = n_2;
        tbn = mat3x3<f32>(vec3<f32>(_e113.x, _e113.y, _e113.z), vec3<f32>(_e114.x, _e114.y, _e114.z), vec3<f32>(_e115.x, _e115.y, _e115.z));
        let _e129 = f_Texcoord_1;
        let _e130 = textureSample(normalTexture, normalTextureSampler, _e129);
        nomral_1 = _e130.xyz;
        let _e132 = tbn;
        let _e133 = nomral_1;
        let _e138 = ubo.normalMapScale;
        let _e140 = ubo.normalMapScale;
        nomral_1 = normalize((_e132 * (((_e133 * 2.0) - vec3<f32>(1.0)) * vec3<f32>(_e138, _e140, 1.0))));
    } else {
        let _e145 = f_WorldNormal_1;
        nomral_1 = _e145;
    }
    let _e146 = nomral_1;
    return _e146;
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

    col = vec3<f32>(0.0, 0.0, 0.0);
    let _e151 = ubo.roughnessFactor;
    perceptualRoughness = _e151;
    let _e153 = ubo.metallicFactor;
    metallic = _e153;
    let _e155 = ubo.useMetallicRoughnessTexture;
    if (_e155 != 0) {
        let _e157 = f_Texcoord_1;
        let _e158 = textureSample(metallicRoughnessTexture, metallicRoughnessTextureSampler, _e157);
        metallicRoughnessColor = _e158;
        let _e159 = perceptualRoughness;
        let _e161 = metallicRoughnessColor[1u];
        perceptualRoughness = (_e159 * _e161);
        let _e163 = metallic;
        let _e165 = metallicRoughnessColor[2u];
        metallic = (_e163 * _e165);
    }
    let _e167 = perceptualRoughness;
    perceptualRoughness = clamp(_e167, 0.03999999910593033, 1.0);
    let _e169 = metallic;
    metallic = clamp(_e169, 0.0, 1.0);
    let _e171 = perceptualRoughness;
    let _e172 = perceptualRoughness;
    alphaRoughness = (_e171 * _e172);
    let _e175 = ubo.useBaseColorTexture;
    if (_e175 != 0) {
        let _e177 = f_Texcoord_1;
        let _e178 = textureSample(baseColorTexture, baseColorTextureSampler, _e177);
        baseColor = _e178;
    } else {
        let _e180 = ubo.baseColorFactor;
        baseColor = _e180;
    }
    f0_ = vec3<f32>(0.03999999910593033, 0.03999999910593033, 0.03999999910593033);
    let _e181 = baseColor;
    let _e183 = f0_;
    diffuseColor = (_e181.xyz * (vec3<f32>(1.0, 1.0, 1.0) - _e183));
    let _e186 = f0_;
    let _e187 = baseColor;
    let _e189 = metallic;
    specularColor = mix(_e186, _e187.xyz, vec3<f32>(_e189));
    let _e193 = specularColor[0u];
    let _e195 = specularColor[1u];
    let _e198 = specularColor[2u];
    reflectance = max(max(_e193, _e195), _e198);
    let _e200 = reflectance;
    reflectance90_ = clamp((_e200 * 25.0), 0.0, 1.0);
    let _e203 = specularColor;
    specularEnvironmentR0_ = _e203;
    let _e204 = reflectance90_;
    specularEnvironmentR90_ = (vec3<f32>(1.0, 1.0, 1.0) * _e204);
    let _e206 = getNormal();
    n_3 = _e206;
    let _e207 = f_WorldPos_1;
    let _e210 = ubo.cameraPos;
    v_2 = (normalize((_e207.xyz - _e210.xyz)) * -1.0);
    let _e216 = ubo.lightDir;
    l = (normalize(_e216.xyz) * -1.0);
    let _e220 = v_2;
    let _e221 = l;
    h = normalize((_e220 + _e221));
    let _e224 = v_2;
    let _e225 = n_3;
    reflection = normalize(reflect(_e224, _e225));
    let _e228 = n_3;
    let _e229 = l;
    NdotL_1 = clamp(dot(_e228, _e229), 0.0, 1.0);
    let _e232 = n_3;
    let _e233 = v_2;
    NdotV_1 = clamp(abs(dot(_e232, _e233)), 0.0, 1.0);
    let _e237 = n_3;
    let _e238 = h;
    NdotH = clamp(dot(_e237, _e238), 0.0, 1.0);
    let _e241 = l;
    let _e242 = h;
    LdotH = clamp(dot(_e241, _e242), 0.0, 1.0);
    let _e245 = v_2;
    let _e246 = h;
    VdotH = clamp(dot(_e245, _e246), 0.0, 1.0);
    let _e249 = NdotL_1;
    let _e250 = NdotV_1;
    let _e251 = NdotH;
    let _e252 = LdotH;
    let _e253 = VdotH;
    let _e254 = perceptualRoughness;
    let _e255 = metallic;
    let _e256 = specularEnvironmentR0_;
    let _e257 = specularEnvironmentR90_;
    let _e258 = alphaRoughness;
    let _e259 = diffuseColor;
    let _e260 = specularColor;
    pbrParam_2 = PBRParam(_e249, _e250, _e251, _e252, _e253, _e254, _e255, _e256, _e257, _e258, _e259, _e260);
    specular_1 = vec3<f32>(0.0, 0.0, 0.0);
    diffuse_1 = vec3<f32>(0.0, 0.0, 0.0);
    let _e262 = pbrParam_2;
    param_13 = _e262;
    let _e263 = CalcMicrofacetstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_13));
    D = _e263;
    let _e264 = pbrParam_2;
    param_14 = _e264;
    let _e265 = CalcGeometricOcculusionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_14));
    G = _e265;
    let _e266 = pbrParam_2;
    param_15 = _e266;
    let _e267 = CalcFrenelReflectionstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_15));
    F = _e267;
    let _e268 = NdotL_1;
    let _e270 = NdotV_1;
    if ((_e268 > 0.0) || (_e270 > 0.0)) {
        let _e273 = D;
        let _e274 = G;
        let _e276 = F;
        let _e278 = NdotL_1;
        let _e280 = NdotV_1;
        let _e284 = specular_1;
        specular_1 = (_e284 + ((_e276 * (_e273 * _e274)) / vec3<f32>(((4.0 * _e278) * _e280))));
        let _e286 = specular_1;
        specular_1 = max(_e286, vec3<f32>(0.0, 0.0, 0.0));
        let _e288 = F;
        let _e291 = pbrParam_2;
        param_16 = _e291;
        let _e292 = CalcDiffuseBRDFstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31_((&param_16));
        let _e294 = diffuse_1;
        diffuse_1 = (_e294 + ((vec3<f32>(1.0) - _e288) * _e292));
        let _e296 = NdotL_1;
        let _e297 = specular_1;
        let _e298 = diffuse_1;
        col = ((_e297 + _e298) * _e296);
    }
    let _e302 = ubo.useIBL;
    if (_e302 != 0) {
        let _e304 = pbrParam_2;
        param_17 = _e304;
        let _e305 = v_2;
        param_18 = _e305;
        let _e306 = n_3;
        param_19 = _e306;
        let _e307 = ComputeIBLstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31vf3vf3_((&param_17), (&param_18), (&param_19));
        let _e308 = col;
        col = (_e308 + _e307);
    } else {
        let _e311 = ubo.useCubeMap;
        let _e312 = (_e311 != 0);
        phi_877_ = _e312;
        if !(_e312) {
            let _e315 = ubo.useDirCubemap;
            phi_877_ = (_e315 != 0);
        }
        let _e318 = phi_877_;
        if _e318 {
            let _e319 = pbrParam_2;
            param_20 = _e319;
            let _e320 = v_2;
            param_21 = _e320;
            let _e321 = n_3;
            param_22 = _e321;
            let _e322 = ComputeReflectionColorstructPBRParamf1f1f1f1f1f1f1vf3vf3f1vf3vf31vf3vf3_((&param_20), (&param_21), (&param_22));
            let _e323 = F;
            let _e325 = col;
            col = (_e325 + (_e322 * _e323));
        } else {
            let _e328 = ubo.ambientColor;
            gi_diffuse = _e328.xyz;
            let _e330 = gi_diffuse;
            let _e331 = col;
            col = (_e331 + _e330);
        }
    }
    let _e334 = ubo.useOcclusionTexture;
    if (_e334 != 0) {
        let _e336 = f_Texcoord_1;
        let _e337 = textureSample(occlusionTexture, occlusionTextureSampler, _e336);
        ao = _e337.x;
        let _e339 = col;
        let _e340 = col;
        let _e341 = ao;
        let _e344 = ubo.occlusionStrength;
        col = mix(_e339, (_e340 * _e341), vec3<f32>(_e344));
    }
    let _e348 = ubo.emissiveFactor;
    let _e351 = ubo.emissiveStrength;
    emissive = (_e348.xyz * _e351);
    let _e354 = ubo.useEmissiveTexture;
    if (_e354 != 0) {
        let _e356 = f_Texcoord_1;
        let _e357 = textureSample(emissiveTexture, emissiveTextureSampler, _e356);
        param_23 = _e357;
        let _e358 = SRGBtoLINEARvf4_((&param_23));
        let _e360 = emissive;
        emissive = (_e360 * _e358.xyz);
    }
    let _e362 = emissive;
    let _e363 = col;
    col = (_e363 + _e362);
    let _e366 = ubo.useShadowMap;
    if (_e366 != 0) {
        let _e368 = f_LightSpacePos_1;
        let _e371 = f_LightSpacePos_1[3u];
        lsp_1 = (_e368.xyz / vec3<f32>(_e371));
        let _e374 = lsp_1;
        lsp_1 = ((_e374 * 0.5) + vec3<f32>(0.5));
        shadowCol = 1.0;
        let _e379 = lsp_1[0u];
        let _e380 = (_e379 < 0.0);
        phi_983_ = _e380;
        if !(_e380) {
            let _e383 = lsp_1[1u];
            phi_983_ = (_e383 < 0.0);
        }
        let _e386 = phi_983_;
        phi_990_ = _e386;
        if !(_e386) {
            let _e389 = lsp_1[2u];
            phi_990_ = (_e389 < 0.0);
        }
        let _e392 = phi_990_;
        phi_1011_ = _e392;
        if !(_e392) {
            let _e395 = lsp_1[0u];
            let _e396 = (_e395 > 1.0);
            phi_1003_ = _e396;
            if !(_e396) {
                let _e399 = lsp_1[1u];
                phi_1003_ = (_e399 > 1.0);
            }
            let _e402 = phi_1003_;
            phi_1010_ = _e402;
            if !(_e402) {
                let _e405 = lsp_1[2u];
                phi_1010_ = (_e405 > 1.0);
            }
            let _e408 = phi_1010_;
            phi_1011_ = _e408;
        }
        let _e410 = phi_1011_;
        outSide = _e410;
        let _e411 = outSide;
        if !(_e411) {
            let _e413 = lsp_1;
            param_24 = _e413;
            let _e414 = n_3;
            param_25 = _e414;
            let _e415 = l;
            param_26 = _e415;
            let _e416 = CalcShadowvf3vf3vf3_((&param_24), (&param_25), (&param_26));
            shadowCol = _e416;
        }
        let _e417 = shadowCol;
        let _e418 = col;
        col = (_e418 * _e417);
    }
    let _e420 = col;
    col = pow(_e420, vec3<f32>(0.4545454680919647, 0.4545454680919647, 0.4545454680919647));
    let _e423 = baseColor[3u];
    alpha = _e423;
    let _e424 = col;
    let _e425 = alpha;
    result = vec4<f32>(_e424.x, _e424.y, _e424.z, _e425);
    let _e430 = result;
    return _e430;
}

fn main_1() {
    var result_1: vec4<f32>;
    var phi_1056_: bool;

    result_1 = vec4<f32>(0.0, 0.0, 0.0, 0.0);
    let _e101 = ubo.useSpatialCulling;
    let _e102 = (_e101 != 0);
    phi_1056_ = _e102;
    if _e102 {
        let _e104 = f_WorldPos_1[1u];
        let _e107 = ubo.spatialCullPos[1u];
        phi_1056_ = (_e104 < _e107);
    }
    let _e110 = phi_1056_;
    if _e110 {
    } else {
        let _e111 = CalcSurface();
        result_1 = _e111;
    }
    let _e112 = result_1;
    outColor = _e112;
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
