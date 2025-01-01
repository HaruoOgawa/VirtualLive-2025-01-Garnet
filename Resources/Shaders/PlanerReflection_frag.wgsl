var<private> v2f_UV_1: vec2<f32>;
@group(0) @binding(0) 
var frameTexture: texture_2d<f32>;
@group(0) @binding(1) 
var frameTextureSampler: sampler;
var<private> outColor: vec4<f32>;

fn main_1() {
    var st: vec2<f32>;
    var col: vec3<f32>;

    let _e12 = v2f_UV_1;
    st = _e12;
    let _e14 = st[0u];
    st[0u] = (1.0 - _e14);
    let _e17 = st;
    let _e18 = textureSample(frameTexture, frameTextureSampler, _e17);
    col = _e18.xyz;
    let _e20 = col;
    outColor = vec4<f32>(_e20.x, _e20.y, _e20.z, 1.0);
    return;
}

@fragment 
fn main(@location(0) v2f_UV: vec2<f32>) -> @location(0) vec4<f32> {
    v2f_UV_1 = v2f_UV;
    main_1();
    let _e3 = outColor;
    return _e3;
}
