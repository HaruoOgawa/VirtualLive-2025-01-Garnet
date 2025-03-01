struct FragUniformBufferObject {
    model: mat4x4<f32>,
    view: mat4x4<f32>,
    proj: mat4x4<f32>,
    lightVMat: mat4x4<f32>,
    emissionColor: vec4<f32>,
    cameraPos: vec4<f32>,
    emissionPower: f32,
    fPad0_: f32,
    fPad1_: f32,
    fPad2_: f32,
}

@group(0) @binding(1) 
var<uniform> f_ubo: FragUniformBufferObject;
var<private> v2g_initPos_1: vec4<f32>;
var<private> v2g_localTopHeight_1: f32;
var<private> outColor: vec4<f32>;

fn main_1() {
    var col: vec3<f32>;
    var pos: vec4<f32>;
    var HeightRate: f32;
    var HeightAlpha: f32;
    var NoDeformedWorldPos: vec4<f32>;
    var WorldViewDir: vec3<f32>;
    var ObjectViewDir: vec3<f32>;
    var VertDir: vec2<f32>;
    var EdgeAlpha: f32;
    var alpha: f32;

    let _e26 = f_ubo.emissionColor;
    let _e29 = f_ubo.emissionPower;
    col = (_e26.xyz * _e29);
    let _e31 = v2g_initPos_1;
    pos = _e31;
    let _e33 = pos[1u];
    let _e34 = v2g_localTopHeight_1;
    HeightRate = (_e33 / _e34);
    let _e36 = HeightRate;
    HeightAlpha = (1.0 - _e36);
    let _e39 = f_ubo.model;
    let _e40 = pos;
    NoDeformedWorldPos = (_e39 * _e40);
    let _e42 = NoDeformedWorldPos;
    let _e45 = f_ubo.cameraPos;
    WorldViewDir = normalize((_e42.xyz - _e45.xyz));
    let _e49 = WorldViewDir;
    let inv_m = inverse(_e39);
    let ObjectViewDir_vec4 = inv_m * vec4<f32>(_e49.x, _e49.y, _e49.z, 0.0);
    ObjectViewDir = ObjectViewDir_vec4.xyz;
    let _e55 = pos;
    VertDir = normalize(_e55.xz);
    let _e58 = VertDir;
    let _e59 = ObjectViewDir;
    EdgeAlpha = abs(dot(_e58, normalize(_e59.xz)));
    let _e64 = HeightAlpha;
    let _e65 = EdgeAlpha;
    alpha = clamp((_e64 * _e65), 0.0, 1.0);
    let _e68 = col;
    let _e69 = alpha;
    outColor = vec4<f32>(_e68.x, _e68.y, _e68.z, _e69);
    return;
}

@fragment 
fn main(@location(0) v2g_initPos: vec4<f32>, @location(1) v2g_localTopHeight: f32) -> @location(0) vec4<f32> {
    v2g_initPos_1 = v2g_initPos;
    v2g_localTopHeight_1 = v2g_localTopHeight;
    main_1();
    let _e5 = outColor;
    return _e5;
}
