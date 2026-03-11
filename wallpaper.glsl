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

const float TAU = 6.2831853;
const float PI = TAU / 2.;

float rand(in float seed) {
    // return fract(sin(seed) * 43758.5453);
    seed = fract(seed * 0.1031);
    seed *= seed + 33.33;
    seed *= seed + seed;
    return fract(seed);
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

float light(vec3 raypos, vec3 normal, vec3 lightpos) {
    vec3 light = normalize(lightpos - raypos);
    float dif = dot(normal, light);
    dif = max(dif, 0.);
    dif *= 0.5;
    dif += 0.5;
    return dif;
}

float sdfBox(vec3 pos, vec3 dimensions) { // TYSM INIGO QUILEZ!!!!
    vec3 delta = abs(pos) - dimensions;
    return length(max(delta, 0.)) + min(maxcomp(delta), 0.);
}

vec3 normalBox(vec3 pos, vec3 dimensions, float distance) // yoinked from https://timcoster.com/2020/02/11/raymarching-shader-pt1-glsl/
{
    vec2 epsilon = vec2(0.02, 0.);
    vec3 n = distance - vec3(
    sdfBox(pos - epsilon.xyy, dimensions),
    sdfBox(pos - epsilon.yxy, dimensions),
    sdfBox(pos - epsilon.yyx, dimensions));

    return normalize(n);
}

const float RAY_THRESHOLD = 0.01;
const float MAX_RAY_DIST = 40.;
const int MAX_RAY_STEPS = 50;

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

const vec3 CLOUD_DIMENSIONS = vec3(1., 0.25, 1.);

float renderCloud(vec3 ro, vec3 rd, int secs) {
    vec2 tdbox = renderBox(ro, rd, CLOUD_DIMENSIONS);
    float traveled = tdbox.x;
    float distance = tdbox.y;
    if (distance < RAY_THRESHOLD) {
        vec3 raypos = ro + rd * traveled;
        vec3 normal = normalBox(raypos, CLOUD_DIMENSIONS, distance);
        float lighttime = ((float(secs) / 86400.) * TAU) - PI/2.;
        vec3 lightpos = vec3(
            5. - cos(lighttime) * 3.,
            max(sin(lighttime), 0.) * 5.,
            cos(lighttime) * -10.
        );
        float mainlight = 0.7 * light(raypos, normal, lightpos);
        float ambientlight = 0.3 * light(raypos, normal, vec3(5., 2., -5.));
        float lightfactor = min(sin(lighttime), 0.) * 0.7 + 1.3;
        return lightfactor * (mainlight + ambientlight);
    }
    return 0.;
}

const float CLOUD_CHANCE = 0.05;

float renderClouds(vec2 uv, int secs) {
    float result = 0.;

    vec2 rduv = uv - 0.8;
    rduv.x *= iResolution.x / iResolution.y;
    float pos = iTime * 0.05 + 15.;
    vec3 rd = normalize(vec3(rduv, 1.));

    for (float z = -20.; z <= -9.; z++) {
        int offset = 0;
        float x = pos;
        for (int i = 0; normalize(vec3(x, -1.2, z)).x > -0.5; i++) {
            vec3 ro = vec3(x, -1.2, z);

            if (normalize(ro).x > 0.9) {
                float delta = floor(x) - z * -2.;
                delta = max(delta, 1.);
                offset += int(delta);
                x -= delta;
                i--;
                continue;
            }
            x--;
            if (rand(mod(z * 1.63287 + float(i + offset), sqrt(2.))) > CLOUD_CHANCE) { continue; }
            float cloud = renderCloud(ro, rd, secs);
            if (cloud > 0.) { result = cloud; }
        }
    }
    return result;
}

void mainImage(out vec4 o, in vec2 coord) {
    vec2 pos = coord / iResolution.xy;
    ivec2 ipos = ivec2(coord);
    // int secs = int(mod(iDate.w, 86400));
    int secs = int(mod(iTime * 1000., 86400.));

    vec4 bgcolor = vec4(skycolor(secs), 1.);
    // bgcolor = vec4(vec3(0.), 1.);
    o = bgcolor;

    float cloud = renderClouds(pos, secs);
    if (cloud > 0.) { o = mix(o, vec4(vec3(cloud), 1.), 0.8); }
}
