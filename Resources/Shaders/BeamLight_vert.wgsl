struct VertUniformBufferObject {
    model: mat4x4<f32>,
    view: mat4x4<f32>,
    proj: mat4x4<f32>,
    lightVMat: mat4x4<f32>,
    cameraPos: vec4<f32>,
    LocalTopHeight: f32,
    BeamRadius: f32,
    BeamExpand: f32,
    BeamHeight: f32,
}

struct gl_PerVertex {
    @builtin(position) gl_Position: vec4<f32>,
    gl_PointSize: f32,
    gl_ClipDistance: array<f32,1u>,
    gl_CullDistance: array<f32,1u>,
}

struct VertexOutput {
    @builtin(position) gl_Position: vec4<f32>,
    @location(0) member: vec4<f32>,
    @location(1) member_1: f32,
}

var<private> inPosition_1: vec3<f32>;
@group(0) @binding(0) 
var<uniform> v_ubo: VertUniformBufferObject;
var<private> perVertexStruct: gl_PerVertex = gl_PerVertex(vec4<f32>(0.0, 0.0, 0.0, 1.0), 1.0, array<f32,1u>(0.0), array<f32,1u>(0.0));
var<private> v2g_initPos: vec4<f32>;
var<private> v2g_localTopHeight: f32;
var<private> inNormal_1: vec3<f32>;
var<private> inTexcoord_1: vec2<f32>;
var<private> inTangent_1: vec4<f32>;
var<private> inJoint0_1: vec4<u32>;
var<private> inWeights0_1: vec4<f32>;

fn main_1() {
    var initPos: vec4<f32>;
    var pos: vec4<f32>;
    var HeightRate: f32;
    var DeformedScale: vec3<f32>;

    let _e30 = inPosition_1;
    initPos = vec4<f32>(_e30.x, _e30.y, _e30.z, 1.0);
    let _e35 = initPos;
    pos = _e35;
    let _e37 = pos[1u];
    let _e39 = v_ubo.LocalTopHeight;
    HeightRate = (_e37 / _e39);
    let _e42 = v_ubo.BeamRadius;
    let _e44 = v_ubo.BeamExpand;
    let _e45 = HeightRate;
    let _e49 = v_ubo.BeamHeight;
    let _e51 = v_ubo.BeamRadius;
    let _e53 = v_ubo.BeamExpand;
    let _e54 = HeightRate;
    DeformedScale = vec3<f32>((_e42 + (_e44 * _e45)), _e49, (_e51 + (_e53 * _e54)));
    let _e59 = DeformedScale[0u];
    let _e61 = DeformedScale[1u];
    let _e63 = DeformedScale[2u];
    let _e69 = pos;
    pos = (_e69 * mat4x4<f32>(vec4<f32>(_e59, 0.0, 0.0, 0.0), vec4<f32>(0.0, _e61, 0.0, 0.0), vec4<f32>(0.0, 0.0, _e63, 0.0), vec4<f32>(0.0, 0.0, 0.0, 1.0)));
    let _e72 = v_ubo.proj;
    let _e74 = v_ubo.view;
    let _e77 = v_ubo.model;
    let _e79 = pos;
    perVertexStruct.gl_Position = (((_e72 * _e74) * _e77) * _e79);
    let _e82 = initPos;
    v2g_initPos = _e82;
    let _e84 = v_ubo.LocalTopHeight;
    v2g_localTopHeight = _e84;
    return;
}

@vertex 
fn main(@location(0) inPosition: vec3<f32>, @location(1) inNormal: vec3<f32>, @location(2) inTexcoord: vec2<f32>, @location(3) inTangent: vec4<f32>, @location(4) inJoint0_: vec4<u32>, @location(5) inWeights0_: vec4<f32>) -> VertexOutput {
    inPosition_1 = inPosition;
    inNormal_1 = inNormal;
    inTexcoord_1 = inTexcoord;
    inTangent_1 = inTangent;
    inJoint0_1 = inJoint0_;
    inWeights0_1 = inWeights0_;
    main_1();
    let _e17 = perVertexStruct.gl_Position.y;
    perVertexStruct.gl_Position.y = -(_e17);
    let _e19 = perVertexStruct.gl_Position;
    let _e20 = v2g_initPos;
    let _e21 = v2g_localTopHeight;
    return VertexOutput(_e19, _e20, _e21);
}
