// uniforms:
// vec3 iResolution
// float iTime
// float iTimeDelta
// float iFrameRate
// int iFrame
// float iChannelTime[4]
// vec3 iChannelResolution[4]
// vec4 iMouse
// vec4 iDate
// float iSampleRate

uniform sampler2D noise;

float rand(in float seed) {
    return fract(sin(seed) * 43758.5453);
    // seed += fract(iTime);
    // seed = fract(seed * 443.897);
    // seed *= seed + 33.33;
    // seed *= seed + seed;
    // return fract(seed);
}

vec4 texrand(in vec2 pos) {
    vec2 samplepos = vec2(rand(pos.x), rand(pos.y));
    return texture2D(noise, samplepos);
}

float square(in float n) {
    return n * n;
}

vec3 skycolor(in int secs) { // thank god for desmos
    if (secs < 28800) {
        float x = float(secs) / 28800.;
        float r = .3*x + .35;
        float g = .7*x + .15;
        float b = .9 - .8*square(x - 1.);
        float f = x + 0.82574; // x + sqrt(1 / 0.3) - 1, of course
        f *= .3*f;
        return f * vec3(r, g, b);
    } else if (secs < 57600) {
        float x = float(secs - 28800) / 28880.;
        float r = .65 - .3*x;
        float g;
        if (x < 0.4) { g = .898 - .3*square(x - .4); }
        else { g = .898 - square(x - .4); }
        float b = .1*x + .9;
        return vec3(r, g, b);
    } else if (secs < 72000) {
        float x = float(secs - 57600) / 14400.;
        float r = min(1., square(5.*x) + .35);
        float g = max(0., .538 - .6*x);
        float b = .2 / (x + .2);
        float f = min(1., 1.2 - x);
        return f * vec3(r, g, b);
    } else {
        float x = float(secs - 72000) / 14400.;
        float r = 1. - .65*x;
        float g = .15*x;
        float b;
        if (x < 0.77) { b = 1. - .69*square(2.*x - 1.1); }
        else { b = .91 - square(3.*x - 2.1); }
        float f = .2;
        return f * vec3(r, g, b);
    }
}

float maxcomp(vec3 v) {
    return max(v.x, max(v.y, v.z));
}

float sdfBox(vec3 pos, vec3 dimensions) { // TYSM INIGO QUILEZ!!!!
    vec3 delta = abs(pos) - dimensions;
    return length(max(delta, 0.)) + min(maxcomp(delta), 0.);
}

vec3 normalBox(vec3 pos, vec3 dimensions, float distance) // yoinked from https://timcoster.com/2020/02/11/raymarching-shader-pt1-glsl/
{
    vec2 epsilon = vec2(0.001, 0.);
    vec3 n = distance - vec3(
    sdfBox(pos - epsilon.xyy, dimensions),
    sdfBox(pos - epsilon.yxy, dimensions),
    sdfBox(pos - epsilon.yyx, dimensions));

    return normalize(n);
}

const float RAY_THRESHOLD = 0.01;
const float MAX_RAY_DIST = 100.;
const int MAX_RAY_STEPS = 20;

vec2 renderBox(vec3 ro, vec3 rd, vec3 dimensions) { // helped by https://michaelwalczyk.com/blog-ray-marching.html
    float traveled = 0.;
    float distance = 0.;
    for (int i = 0; i < MAX_RAY_STEPS; i++) {
        vec3 pos = ro + rd * traveled;

        distance = sdfBox(pos, dimensions);
        if (distance < RAY_THRESHOLD || traveled > MAX_RAY_DIST) { break; }

        traveled += distance;
    }
    return vec2(traveled, distance);
}

void mainImage(out vec4 o, in vec2 u) {
    ivec2 iu = ivec2(u);
    vec2 uv = u / iResolution.xy;

    vec4 bgcolor = vec4(0., 0., 0., 1.);
    // bgcolor.rgb = skycolor(int(mod(iDate.w, 86400)));
    bgcolor.rgb = skycolor(int(mod(iTime * 5000., 86400.)));

    // o = bgcolor;

    vec2 rduv = uv - 0.8;
    rduv.x *= iResolution.x / iResolution.y;
    vec3 ro = vec3(iTime * 3., -1.2, -9.);
    vec3 rd = normalize(vec3(rduv, 1.));

    o = vec4(vec3(0.), 1.);
    vec3 dimensions = vec3(1.5, 0.4, 0.7);
    for (int i = 0; i < 10; i++) {
        ro.x = mod(ro.x + 10., 50.) - 10.;
        ro.x -= 5.;
        vec3 nro = normalize(ro);
        vec4 color = vec4(1.);
        if (nro.x > 0.8388 || nro.x < -0.456) { color.g = 0.; }
        vec2 tdbox = renderBox(ro, rd, dimensions);
        float traveled = tdbox.x;
        float distance = tdbox.y;
        if (distance < RAY_THRESHOLD) {
            vec3 normal = normalBox(ro + rd * traveled, dimensions, distance);
            o = vec4((normal + 1.) * 0.5, 1.);
        }
    }
}
