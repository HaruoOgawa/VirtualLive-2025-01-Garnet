var<private> v2f_UV_1: vec2<f32>;
@group(0) @binding(0) 
var frameTexture: texture_2d<f32>;
@group(0) @binding(1) 
var frameTextureSampler: sampler;
var<private> outColor: vec4<f32>;

fn main_1() {
    var st: vec2<f32>;
    var col: vec3<f32>;

    let _e13 = v2f_UV_1;
    st = _e13;
    let _e15 = st[0u];
    st[0u] = (1.0 - _e15);
    let _e18 = st;
    let _e19 = textureSample(frameTexture, frameTextureSampler, _e18);
    col = _e19.xyz;
    let _e21 = col;
    outColor = vec4<f32>(_e21.x, _e21.y, _e21.z, 0.5);
    return;
}

@fragment 
fn main(@location(0) v2f_UV: vec2<f32>) -> @location(0) vec4<f32> {
    v2f_UV_1 = v2f_UV;
    main_1();
    let _e3 = outColor;
    return _e3;
}
