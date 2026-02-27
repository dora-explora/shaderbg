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

const vec4 BACKGROUND = vec4(0.12, 0.02, 0.15, 1.);

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

void mainImage(out vec4 o, in vec2 u)
{
    ivec2 iu = ivec2(u);
    vec2 pos = u / iResolution.xy;
    vec4 bgcolor = vec4(0., 0., 0., 1.);
    // bgcolor.rgb = skycolor(int(mod(iDate.w, 86400)));
    bgcolor.rgb = skycolor(int(mod(iTime * 5000., 86400.)));
    o = bgcolor;
}
