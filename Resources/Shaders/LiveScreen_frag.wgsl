struct FragUniformBufferObject {
    model: mat4x4<f32>,
    view: mat4x4<f32>,
    proj: mat4x4<f32>,
    lightVMat: mat4x4<f32>,
    screenCenter: vec4<f32>,
    uvScale: f32,
    time: f32,
    fPad1_: f32,
    fPad2_: f32,
}

@group(0) @binding(2) 
var<uniform> f_ubo: FragUniformBufferObject;
var<private> f_WorldPos_1: vec4<f32>;
var<private> outColor: vec4<f32>;
var<private> f_WorldNormal_1: vec3<f32>;
var<private> f_Texcoord_1: vec2<f32>;
var<private> f_WorldTangent_1: vec3<f32>;
var<private> f_WorldBioTangent_1: vec3<f32>;
var<private> f_LightSpacePos_1: vec4<f32>;

fn ifsvf3_(p: ptr<function, vec3<f32>>) -> vec3<f32> {
    var i: i32;
    var local: vec2<f32>;
    var local_1: vec2<f32>;
    var local_2: vec2<f32>;

    let _e86 = (*p);
    (*p) = abs(_e86);
    i = 0;
    loop {
        let _e88 = i;
        if (_e88 < 6) {
            let _e90 = (*p);
            (*p) = (abs(_e90) - vec3<f32>(0.3499999940395355));
            let _e94 = (*p);
            let _e96 = (_e94.xy * mat2x2<f32>(vec2<f32>(0.9689124226570129, 0.24740396440029144), vec2<f32>(-0.24740396440029144, 0.9689124226570129)));
            (*p)[0u] = _e96.x;
            (*p)[1u] = _e96.y;
            let _e101 = (*p);
            let _e103 = (_e101.xz * mat2x2<f32>(vec2<f32>(-0.3701808452606201, 0.9289597272872925), vec2<f32>(-0.9289597272872925, -0.3701808452606201)));
            (*p)[0u] = _e103.x;
            (*p)[2u] = _e103.y;
            let _e108 = (*p);
            let _e110 = (_e108.yz * mat2x2<f32>(vec2<f32>(0.5570225715637207, 0.8304973840713501), vec2<f32>(-0.8304973840713501, 0.5570225715637207)));
            (*p)[1u] = _e110.x;
            (*p)[2u] = _e110.y;
            let _e116 = (*p)[0u];
            let _e118 = (*p)[1u];
            if (_e116 < _e118) {
                let _e120 = (*p);
                local = _e120.yx;
            } else {
                let _e122 = (*p);
                local = _e122.xy;
            }
            let _e124 = local;
            (*p)[0u] = _e124.x;
            (*p)[1u] = _e124.y;
            let _e130 = (*p)[0u];
            let _e132 = (*p)[2u];
            if (_e130 < _e132) {
                let _e134 = (*p);
                local_1 = _e134.zx;
            } else {
                let _e136 = (*p);
                local_1 = _e136.xz;
            }
            let _e138 = local_1;
            (*p)[0u] = _e138.x;
            (*p)[2u] = _e138.y;
            let _e144 = (*p)[1u];
            let _e146 = (*p)[2u];
            if (_e144 < _e146) {
                let _e148 = (*p);
                local_2 = _e148.zy;
            } else {
                let _e150 = (*p);
                local_2 = _e150.yz;
            }
            let _e152 = local_2;
            (*p)[1u] = _e152.x;
            (*p)[2u] = _e152.y;
            continue;
        } else {
            break;
        }
        continuing {
            let _e157 = i;
            i = (_e157 + 1);
        }
    }
    let _e159 = (*p);
    return _e159;
}

fn Cubevf3vf3_(p_1: ptr<function, vec3<f32>>, s: ptr<function, vec3<f32>>) -> f32 {
    let _e83 = (*p_1);
    let _e85 = (*s);
    return length(max((abs(_e83) - _e85), vec3<f32>(0.0)));
}

fn mapvf3_(p_2: ptr<function, vec3<f32>>) -> f32 {
    var pt: vec3<f32>;
    var k: f32;
    var id: vec3<f32>;
    var baseCube: f32;
    var param: vec3<f32>;
    var param_1: vec3<f32>;
    var param_2: vec3<f32>;
    var subCube: f32;
    var param_3: vec3<f32>;
    var param_4: vec3<f32>;
    var d: f32;

    let _e93 = (*p_2);
    pt = _e93;
    let _e95 = f_ubo.time;
    let _e97 = pt[2u];
    pt[2u] = (_e97 - _e95);
    k = 1.25;
    let _e100 = pt;
    let _e101 = k;
    let _e105 = k;
    id = (floor((_e100 / vec3<f32>(_e101))) * _e105);
    let _e107 = pt;
    let _e108 = k;
    let _e109 = vec3<f32>(_e108);
    let _e114 = k;
    pt = ((_e107 - (floor((_e107 / _e109)) * _e109)) - vec3<f32>((_e114 * 0.5)));
    let _e118 = pt;
    let _e120 = (_e118.xy * mat2x2<f32>(vec2<f32>(0.7071231603622437, 0.7070903778076172), vec2<f32>(-0.7070903778076172, 0.7071231603622437)));
    pt[0u] = _e120.x;
    pt[1u] = _e120.y;
    let _e125 = pt;
    param = _e125;
    param_1 = vec3<f32>(0.5, 0.5, 0.5);
    let _e126 = Cubevf3vf3_((&param), (&param_1));
    baseCube = _e126;
    let _e127 = pt;
    let _e128 = vec3<f32>(2.0);
    pt = ((_e127 - (floor((_e127 / _e128)) * _e128)) - vec3<f32>(1.0));
    let _e135 = pt;
    param_2 = _e135;
    let _e136 = ifsvf3_((&param_2));
    pt = _e136;
    let _e137 = pt;
    param_3 = _e137;
    param_4 = vec3<f32>(0.30000001192092896, 0.30000001192092896, 0.30000001192092896);
    let _e138 = Cubevf3vf3_((&param_3), (&param_4));
    subCube = _e138;
    let _e139 = baseCube;
    let _e140 = subCube;
    d = max(_e139, _e140);
    let _e142 = d;
    return _e142;
}

fn gnvf3_(p_3: ptr<function, vec3<f32>>) -> vec3<f32> {
    var e: vec2<f32>;
    var param_5: vec3<f32>;
    var param_6: vec3<f32>;
    var param_7: vec3<f32>;
    var param_8: vec3<f32>;
    var param_9: vec3<f32>;
    var param_10: vec3<f32>;

    e = vec2<f32>(0.0010000000474974513, 0.0);
    let _e89 = (*p_3);
    let _e90 = e;
    param_5 = (_e89 + _e90.xyy);
    let _e93 = mapvf3_((&param_5));
    let _e94 = (*p_3);
    let _e95 = e;
    param_6 = (_e94 - _e95.xyy);
    let _e98 = mapvf3_((&param_6));
    let _e100 = (*p_3);
    let _e101 = e;
    param_7 = (_e100 + _e101.yxy);
    let _e104 = mapvf3_((&param_7));
    let _e105 = (*p_3);
    let _e106 = e;
    param_8 = (_e105 - _e106.yxy);
    let _e109 = mapvf3_((&param_8));
    let _e111 = (*p_3);
    let _e112 = e;
    param_9 = (_e111 + _e112.yyx);
    let _e115 = mapvf3_((&param_9));
    let _e116 = (*p_3);
    let _e117 = e;
    param_10 = (_e116 - _e117.yyx);
    let _e120 = mapvf3_((&param_10));
    return normalize(vec3<f32>((_e93 - _e98), (_e104 - _e109), (_e115 - _e120)));
}

fn main_1() {
    var col: vec3<f32>;
    var WorldScreenCenter: vec3<f32>;
    var pos: vec3<f32>;
    var st: vec2<f32>;
    var ro: vec3<f32>;
    var ta: vec3<f32>;
    var cdir: vec3<f32>;
    var cside: vec3<f32>;
    var cup: vec3<f32>;
    var rd: vec3<f32>;
    var marchingNum: i32;
    var acc: f32;
    var i_1: i32;
    var d_1: f32;
    var t: f32;
    var param_11: vec3<f32>;
    var rayCol: vec3<f32>;
    var glow: f32;
    var n0_: vec3<f32>;
    var param_12: vec3<f32>;
    var n1_: vec3<f32>;
    var param_13: vec3<f32>;
    var n2_: vec3<f32>;
    var param_14: vec3<f32>;
    var emw: f32;
    var refro: vec3<f32>;
    var acc2_: f32;
    var i_2: i32;
    var param_15: vec3<f32>;
    var emission: f32;
    var phi_443_: bool;

    col = vec3<f32>(0.0, 0.0, 0.0);
    WorldScreenCenter = vec3<f32>(0.0, 5.894999980926514, 11.399999618530273);
    let _e111 = f_WorldPos_1;
    let _e113 = WorldScreenCenter;
    pos = (_e111.xyz - _e113);
    let _e115 = pos;
    st = _e115.xy;
    let _e117 = st;
    st = (_e117 * 0.25);
    let _e120 = f_ubo.time;
    let _e124 = f_ubo.time;
    ro = vec3<f32>((cos(_e120) * 0.25), (sin(_e124) * 0.25), 1.0);
    ta = vec3<f32>(0.0, 0.0, 0.0);
    let _e128 = ta;
    let _e129 = ro;
    cdir = normalize((_e128 - _e129));
    let _e132 = cdir;
    cside = normalize(cross(_e132, vec3<f32>(0.0, 1.0, 0.0)));
    let _e135 = cdir;
    let _e136 = cside;
    cup = normalize(cross(_e135, _e136));
    let _e140 = st[0u];
    let _e141 = cside;
    let _e144 = st[1u];
    let _e145 = cup;
    let _e148 = cdir;
    rd = normalize((((_e141 * _e140) + (_e145 * _e144)) + (_e148 * 1.0)));
    marchingNum = 0;
    acc = 0.0;
    i_1 = 0;
    loop {
        let _e152 = i_1;
        if (_e152 < 128) {
            let _e154 = ro;
            let _e155 = rd;
            let _e156 = t;
            param_11 = (_e154 + (_e155 * _e156));
            let _e159 = mapvf3_((&param_11));
            d_1 = _e159;
            let _e160 = i_1;
            marchingNum = _e160;
            let _e161 = d_1;
            let _e163 = t;
            if ((_e161 < 0.0010000000474974513) || (_e163 > 1000.0)) {
                break;
            }
            let _e166 = d_1;
            let _e167 = t;
            t = (_e167 + _e166);
            let _e169 = d_1;
            let _e172 = acc;
            acc = (_e172 + exp((-3.0 * _e169)));
            marchingNum = 127;
            continue;
        } else {
            break;
        }
        continuing {
            let _e174 = i_1;
            i_1 = (_e174 + 1);
        }
    }
    rayCol = vec3<f32>(0.0, 0.0, 0.0);
    glow = 0.0;
    let _e176 = ro;
    let _e177 = rd;
    let _e178 = t;
    param_12 = (_e176 + (_e177 * _e178));
    let _e181 = gnvf3_((&param_12));
    n0_ = _e181;
    let _e182 = ro;
    let _e183 = rd;
    let _e184 = t;
    let _e188 = n0_[0u];
    param_13 = ((_e182 + (_e183 * _e184)) + vec3<f32>((sign(_e188) * 0.007499999832361937), 0.0, 0.0));
    let _e193 = gnvf3_((&param_13));
    n1_ = _e193;
    let _e194 = ro;
    let _e195 = rd;
    let _e196 = t;
    let _e200 = n0_[1u];
    param_14 = ((_e194 + (_e195 * _e196)) + vec3<f32>(0.0, (sign(_e200) * 0.007499999832361937), 0.0));
    let _e205 = gnvf3_((&param_14));
    n2_ = _e205;
    let _e206 = n0_;
    let _e207 = rd;
    glow = max(0.0, dot(_e206, _e207));
    emw = 0.800000011920929;
    let _e210 = n0_;
    let _e211 = n1_;
    let _e213 = emw;
    let _e214 = (dot(_e210, _e211) < _e213);
    phi_443_ = _e214;
    if !(_e214) {
        let _e216 = n0_;
        let _e217 = n2_;
        let _e219 = emw;
        phi_443_ = (dot(_e216, _e217) < _e219);
    }
    let _e222 = phi_443_;
    if _e222 {
        let _e223 = glow;
        glow = (_e223 + 4.5);
    }
    let _e225 = marchingNum;
    let _e231 = glow;
    glow = (_e231 * min(1.0, (4.0 - ((4.0 * f32(_e225)) / 127.0))));
    let _e233 = acc;
    let _e236 = glow;
    let _e238 = acc;
    rayCol = (((vec3<f32>(0.5, 0.20000000298023224, 0.6000000238418579) * _e233) * 0.07500000298023224) + ((vec3<f32>(1.0, 1.0, 1.0) * _e236) * _e238));
    let _e241 = ro;
    let _e242 = rd;
    let _e243 = t;
    refro = (_e241 + (_e242 * _e243));
    let _e246 = rd;
    let _e247 = n0_;
    rd = reflect(_e246, _e247);
    let _e249 = refro;
    ro = _e249;
    t = 0.10000000149011612;
    acc2_ = 0.0;
    i_2 = 0;
    loop {
        let _e250 = i_2;
        if (_e250 < 64) {
            let _e252 = ro;
            let _e253 = rd;
            let _e254 = t;
            param_15 = (_e252 + (_e253 * _e254));
            let _e257 = mapvf3_((&param_15));
            d_1 = _e257;
            let _e258 = d_1;
            if (_e258 < 0.0010000000474974513) {
                break;
            }
            let _e260 = d_1;
            let _e261 = t;
            t = (_e261 + _e260);
            let _e263 = d_1;
            let _e266 = acc2_;
            acc2_ = (_e266 + exp((-3.0 * _e263)));
            continue;
        } else {
            break;
        }
        continuing {
            let _e268 = i_2;
            i_2 = (_e268 + 1);
        }
    }
    let _e270 = acc2_;
    let _e273 = rayCol;
    rayCol = (_e273 + ((vec3<f32>(0.4000000059604645, 0.25, 0.800000011920929) * _e270) * 0.02500000037252903));
    emission = 1.5;
    let _e275 = emission;
    let _e277 = rayCol;
    rayCol = min(vec3<f32>(_e275), _e277);
    let _e279 = rayCol;
    let _e280 = col;
    col = (_e280 + _e279);
    let _e282 = col;
    col = pow(_e282, vec3<f32>(0.4545454680919647, 0.4545454680919647, 0.4545454680919647));
    let _e284 = col;
    outColor = vec4<f32>(_e284.x, _e284.y, _e284.z, 1.0);
    return;
}

@fragment 
fn main(@location(2) f_WorldPos: vec4<f32>, @location(0) f_WorldNormal: vec3<f32>, @location(1) f_Texcoord: vec2<f32>, @location(3) f_WorldTangent: vec3<f32>, @location(4) f_WorldBioTangent: vec3<f32>, @location(5) f_LightSpacePos: vec4<f32>) -> @location(0) vec4<f32> {
    f_WorldPos_1 = f_WorldPos;
    f_WorldNormal_1 = f_WorldNormal;
    f_Texcoord_1 = f_Texcoord;
    f_WorldTangent_1 = f_WorldTangent;
    f_WorldBioTangent_1 = f_WorldBioTangent;
    f_LightSpacePos_1 = f_LightSpacePos;
    main_1();
    let _e13 = outColor;
    return _e13;
}
