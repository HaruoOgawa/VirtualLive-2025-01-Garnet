struct VATUniformBuffer {
    mPad0_: mat4x4<f32>,
    mPad1_: mat4x4<f32>,
    mPad2_: mat4x4<f32>,
    mPad3_: mat4x4<f32>,
    texW: f32,
    texH: f32,
    frameNum: f32,
    endtime: f32,
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

struct gl_PerVertex {
    @builtin(position) gl_Position: vec4<f32>,
    gl_PointSize: f32,
    gl_ClipDistance: array<f32,1u>,
    gl_CullDistance: array<f32,1u>,
}

struct SkinMatrixBuffer {
    SkinMat: array<mat4x4<f32>,1024u>,
}

struct VertexOutput {
    @builtin(position) gl_Position: vec4<f32>,
    @location(0) member: vec3<f32>,
    @location(1) member_1: vec2<f32>,
    @location(2) member_2: vec4<f32>,
    @location(3) member_3: vec3<f32>,
    @location(4) member_4: vec3<f32>,
    @location(5) member_5: vec4<f32>,
}

@group(0) @binding(28) 
var<uniform> vat_ubo: VATUniformBuffer;
@group(0) @binding(26) 
var vertexAnimationTexture: texture_2d<f32>;
@group(0) @binding(27) 
var vertexAnimationTextureSampler: sampler;
var<private> inNormal_1: vec3<f32>;
var<private> inTangent_1: vec4<f32>;
var<private> gl_InstanceIndex_1: i32;
@group(0) @binding(0) 
var<uniform> ubo: UniformBufferObject;
var<private> inWeights0_1: vec4<f32>;
var<private> inJoint0_1: vec4<u32>;
var<private> inPosition_1: vec3<f32>;
var<private> perVertexStruct: gl_PerVertex = gl_PerVertex(vec4<f32>(0.0, 0.0, 0.0, 1.0), 1.0, array<f32,1u>(0.0), array<f32,1u>(0.0));
var<private> f_WorldNormal: vec3<f32>;
var<private> f_Texcoord: vec2<f32>;
var<private> inTexcoord_1: vec2<f32>;
var<private> f_WorldPos: vec4<f32>;
var<private> f_WorldTangent: vec3<f32>;
var<private> f_WorldBioTangent: vec3<f32>;
var<private> f_LightSpacePos: vec4<f32>;
@group(0) @binding(25) 
var<uniform> r_SkinMatrixBuffer: SkinMatrixBuffer;

fn fetchElementf1i1f1_(JointIndex: ptr<function, f32>, Offset: ptr<function, i32>, v: ptr<function, f32>) -> vec4<f32> {
    var texelSizeX: f32;
    var st: vec2<f32>;
    var val: vec4<f32>;

    let _e57 = vat_ubo.texW;
    texelSizeX = (1.0 / _e57);
    let _e59 = (*JointIndex);
    let _e61 = (*Offset);
    let _e65 = texelSizeX;
    let _e67 = (*v);
    st = vec2<f32>(((((_e59 * 4.0) + f32(_e61)) + 0.5) * _e65), _e67);
    let _e69 = st;
    let _e70 = textureSampleLevel(vertexAnimationTexture, vertexAnimationTextureSampler, _e69, 0.0);
    val = _e70;
    let _e71 = val;
    return _e71;
}

fn GetSkinMatFromVATu1i1_(JointIndex_1: ptr<function, u32>, FrameIndex: ptr<function, i32>) -> mat4x4<f32> {
    var f_JointIndex: f32;
    var texelSizeY: f32;
    var v_1: f32;
    var SkinMatrix: mat4x4<f32>;
    var param: f32;
    var param_1: i32;
    var param_2: f32;
    var param_3: f32;
    var param_4: i32;
    var param_5: f32;
    var param_6: f32;
    var param_7: i32;
    var param_8: f32;
    var param_9: f32;
    var param_10: i32;
    var param_11: f32;

    let _e68 = (*JointIndex_1);
    f_JointIndex = f32(_e68);
    let _e71 = vat_ubo.texH;
    texelSizeY = (1.0 / _e71);
    let _e73 = (*FrameIndex);
    let _e76 = texelSizeY;
    v_1 = ((f32(_e73) + 0.5) * _e76);
    let _e78 = f_JointIndex;
    param = _e78;
    param_1 = 0;
    let _e79 = v_1;
    param_2 = _e79;
    let _e80 = fetchElementf1i1f1_((&param), (&param_1), (&param_2));
    let _e81 = f_JointIndex;
    param_3 = _e81;
    param_4 = 1;
    let _e82 = v_1;
    param_5 = _e82;
    let _e83 = fetchElementf1i1f1_((&param_3), (&param_4), (&param_5));
    let _e84 = f_JointIndex;
    param_6 = _e84;
    param_7 = 2;
    let _e85 = v_1;
    param_8 = _e85;
    let _e86 = fetchElementf1i1f1_((&param_6), (&param_7), (&param_8));
    let _e87 = f_JointIndex;
    param_9 = _e87;
    param_10 = 3;
    let _e88 = v_1;
    param_11 = _e88;
    let _e89 = fetchElementf1i1f1_((&param_9), (&param_10), (&param_11));
    SkinMatrix = mat4x4<f32>(vec4<f32>(_e80.x, _e80.y, _e80.z, _e80.w), vec4<f32>(_e83.x, _e83.y, _e83.z, _e83.w), vec4<f32>(_e86.x, _e86.y, _e86.z, _e86.w), vec4<f32>(_e89.x, _e89.y, _e89.z, _e89.w));
    let _e111 = SkinMatrix;
    return _e111;
}

fn randvf2_(st_1: ptr<function, vec2<f32>>) -> f32 {
    let _e51 = (*st_1);
    return ((fract((sin(dot(_e51, vec2<f32>(12.989800453186035, 78.23300170898438))) * 43758.546875)) * 2.0) - 1.0);
}

fn main_1() {
    var BioTangent: vec3<f32>;
    var id: i32;
    var sidenum: f32;
    var yid: f32;
    var xid: f32;
    var LocalTime: f32;
    var param_12: vec2<f32>;
    var CurrentFrame: i32;
    var SkinMat: mat4x4<f32>;
    var param_13: u32;
    var param_14: i32;
    var param_15: u32;
    var param_16: i32;
    var param_17: u32;
    var param_18: i32;
    var param_19: u32;
    var param_20: i32;
    var base: vec3<f32>;
    var w: f32;
    var h: f32;
    var offset: vec3<f32>;
    var InsMat: mat4x4<f32>;
    var WorldPos: vec4<f32>;
    var WorldNormal: vec3<f32>;
    var WorldTangent: vec3<f32>;
    var WorldBioTangent: vec3<f32>;

    let _e76 = inNormal_1;
    let _e77 = inTangent_1;
    BioTangent = cross(_e76, _e77.xyz);
    let _e80 = gl_InstanceIndex_1;
    id = _e80;
    sidenum = 64.0;
    let _e81 = id;
    let _e83 = sidenum;
    yid = floor((f32(_e81) / _e83));
    let _e86 = id;
    let _e88 = yid;
    let _e89 = sidenum;
    xid = (f32(_e86) - (_e88 * _e89));
    let _e92 = xid;
    let _e93 = sidenum;
    xid = (_e92 - (_e93 * 0.5));
    let _e97 = ubo.time;
    let _e98 = xid;
    let _e99 = yid;
    param_12 = (vec2<f32>(_e98, _e99) * 10.0);
    let _e102 = randvf2_((&param_12));
    let _e103 = (_e97 + _e102);
    let _e105 = vat_ubo.endtime;
    LocalTime = (_e103 - (floor((_e103 / _e105)) * _e105));
    let _e110 = LocalTime;
    let _e112 = vat_ubo.endtime;
    let _e115 = vat_ubo.frameNum;
    CurrentFrame = i32(floor(((_e110 / _e112) * _e115)));
    let _e120 = inWeights0_1[0u];
    let _e122 = inJoint0_1[0u];
    param_13 = _e122;
    let _e123 = CurrentFrame;
    param_14 = _e123;
    let _e124 = GetSkinMatFromVATu1i1_((&param_13), (&param_14));
    let _e125 = (_e124 * _e120);
    let _e127 = inWeights0_1[1u];
    let _e129 = inJoint0_1[1u];
    param_15 = _e129;
    let _e130 = CurrentFrame;
    param_16 = _e130;
    let _e131 = GetSkinMatFromVATu1i1_((&param_15), (&param_16));
    let _e132 = (_e131 * _e127);
    let _e145 = mat4x4<f32>((_e125[0] + _e132[0]), (_e125[1] + _e132[1]), (_e125[2] + _e132[2]), (_e125[3] + _e132[3]));
    let _e147 = inWeights0_1[2u];
    let _e149 = inJoint0_1[2u];
    param_17 = _e149;
    let _e150 = CurrentFrame;
    param_18 = _e150;
    let _e151 = GetSkinMatFromVATu1i1_((&param_17), (&param_18));
    let _e152 = (_e151 * _e147);
    let _e165 = mat4x4<f32>((_e145[0] + _e152[0]), (_e145[1] + _e152[1]), (_e145[2] + _e152[2]), (_e145[3] + _e152[3]));
    let _e167 = inWeights0_1[3u];
    let _e169 = inJoint0_1[3u];
    param_19 = _e169;
    let _e170 = CurrentFrame;
    param_20 = _e170;
    let _e171 = GetSkinMatFromVATu1i1_((&param_19), (&param_20));
    let _e172 = (_e171 * _e167);
    SkinMat = mat4x4<f32>((_e165[0] + _e172[0]), (_e165[1] + _e172[1]), (_e165[2] + _e172[2]), (_e165[3] + _e172[3]));
    base = vec3<f32>(0.0, 0.0, -15.0);
    w = 1.0;
    h = 1.0;
    let _e186 = base;
    let _e187 = w;
    let _e188 = xid;
    let _e190 = h;
    let _e191 = yid;
    offset = (_e186 + vec3<f32>((_e187 * _e188), 0.0, (_e190 * -(_e191))));
    let _e197 = offset[0u];
    let _e199 = offset[1u];
    let _e201 = offset[2u];
    InsMat = mat4x4<f32>(vec4<f32>(1.0, 0.0, 0.0, _e197), vec4<f32>(0.0, 1.0, 0.0, _e199), vec4<f32>(0.0, 0.0, 1.0, _e201), vec4<f32>(0.0, 0.0, 0.0, 1.0));
    let _e207 = SkinMat;
    let _e208 = inPosition_1;
    WorldPos = (_e207 * vec4<f32>(_e208.x, _e208.y, _e208.z, 1.0));
    let _e214 = SkinMat;
    let _e215 = inNormal_1;
    WorldNormal = normalize((_e214 * vec4<f32>(_e215.x, _e215.y, _e215.z, 0.0)).xyz);
    let _e223 = SkinMat;
    let _e224 = inTangent_1;
    WorldTangent = normalize((_e223 * _e224).xyz);
    let _e228 = SkinMat;
    let _e229 = BioTangent;
    WorldBioTangent = normalize((_e228 * vec4<f32>(_e229.x, _e229.y, _e229.z, 0.0)).xyz);
    let _e237 = InsMat;
    let _e238 = WorldPos;
    WorldPos = (_e238 * _e237);
    let _e241 = ubo.proj;
    let _e243 = ubo.view;
    let _e245 = WorldPos;
    perVertexStruct.gl_Position = ((_e241 * _e243) * _e245);
    let _e248 = WorldNormal;
    f_WorldNormal = _e248;
    let _e249 = inTexcoord_1;
    f_Texcoord = _e249;
    let _e250 = WorldPos;
    f_WorldPos = _e250;
    let _e251 = WorldTangent;
    f_WorldTangent = _e251;
    let _e252 = WorldBioTangent;
    f_WorldBioTangent = _e252;
    let _e254 = ubo.lightPMat;
    let _e256 = ubo.lightVMat;
    let _e258 = WorldPos;
    f_LightSpacePos = ((_e254 * _e256) * _e258);
    return;
}

@vertex 
fn main(@location(1) inNormal: vec3<f32>, @location(3) inTangent: vec4<f32>, @builtin(instance_index) gl_InstanceIndex: u32, @location(5) inWeights0_: vec4<f32>, @location(4) inJoint0_: vec4<u32>, @location(0) inPosition: vec3<f32>, @location(2) inTexcoord: vec2<f32>) -> VertexOutput {
    inNormal_1 = inNormal;
    inTangent_1 = inTangent;
    gl_InstanceIndex_1 = i32(gl_InstanceIndex);
    inWeights0_1 = inWeights0_;
    inJoint0_1 = inJoint0_;
    inPosition_1 = inPosition;
    inTexcoord_1 = inTexcoord;
    main_1();
    let _e24 = perVertexStruct.gl_Position.y;
    perVertexStruct.gl_Position.y = -(_e24);
    let _e26 = perVertexStruct.gl_Position;
    let _e27 = f_WorldNormal;
    let _e28 = f_Texcoord;
    let _e29 = f_WorldPos;
    let _e30 = f_WorldTangent;
    let _e31 = f_WorldBioTangent;
    let _e32 = f_LightSpacePos;
    return VertexOutput(_e26, _e27, _e28, _e29, _e30, _e31, _e32);
}
