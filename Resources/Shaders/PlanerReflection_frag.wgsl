var<private> v2f_UV_1: vec2<f32>;
@group(0) @binding(0) 
var frameTexture: texture_2d<f32>;
@group(0) @binding(1) 
var frameTextureSampler: sampler;
var<private> outColor: vec4<f32>;

fn main_1() {
    var st: vec2<f32>;
    var col: vec3<f32>;
    var alpha: f32;

    let _e14 = v2f_UV_1;
    st = _e14;
    let _e16 = st[0u];
    st[0u] = (1.0 - _e16);
    let _e19 = st;
    let _e20 = textureSample(frameTexture, frameTextureSampler, _e19);
    col = _e20.xyz;
    alpha = 0.5;
    let _e22 = col;
    let _e23 = alpha;
    outColor = vec4<f32>(_e22.x, _e22.y, _e22.z, _e23);
    return;
}

@fragment 
fn main(@location(0) v2f_UV: vec2<f32>) -> @location(0) vec4<f32> {
    v2f_UV_1 = v2f_UV;
    main_1();
    let _e3 = outColor;
    return _e3;
}
