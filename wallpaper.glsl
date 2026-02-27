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
    seed += fract(iTime);
    seed = fract(seed * 443.897);
    seed *= seed + 33.33;
    seed *= seed + seed;
    return fract(seed);
}

vec4 texrand(in vec2 pos) {
    vec2 samplepos = vec2(rand(pos.x), rand(pos.y));
    return texture2D(noise, samplepos);
}

float square(in float n) {
    return n * n;
}

vec3 skycolor(in int secs) {
    if (secs < 28800) {
        float x = secs / 28800.;
        float r = .3*x + 0.35;
        float g = .7*x + .2;
        float b = 1. - .8*square(x - 1);
        vec3 o = vec3(r, g, b);
        x += 0.82574; // sqrt(1 / 0.3) - 1, of course
        x *= .3*x;
        o *= x;
        return o;
    } else {
        return vec3(0.65, 0.9, 1.);
    }
}

void mainImage(out vec4 o, in vec2 u)
{
    ivec2 iu = ivec2(u);
    vec2 pos = u / iResolution.xy;
    // if (true) { o = vec4(1.); }
    // else { o = vec4(0., 0., 0., 1.); }
    vec4 bgcolor = vec4(0., 0., 0., 1.);
    // bgcolor.rgb = skycolor(int(mod(iDate.w, 86400)));
    bgcolor.rgb = skycolor(int(iTime * 2000.));
    float glint = sin(pos.x * 2. - pos.y - iTime * 1.4);
    // o = bgcolor + 0.025 * max(glint, 2 * glint) + 0.1 * texrand(pos);
    o = bgcolor;
}
