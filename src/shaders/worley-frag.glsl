#version 300 es

precision highp float;

uniform vec4 u_Color;
uniform float u_Time;
uniform float u_WorleyScale;

in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col;

vec3 random3f(vec3 seed) {
    // Hashing based on integer coordinates
    seed = vec3(dot(seed, vec3(127.1, 311.7, 74.7)),
                dot(seed, vec3(269.5, 183.3, 246.1)),
                dot(seed, vec3(113.5, 271.9, 124.6)));

    // Fractal sin-based output
    return -1.0 + 2.0 * fract(sin(seed) * 43758.5453123);
}

// Worley noise function
float worley(vec3 p)
{
    vec3 pi = floor(p);
    vec3 pf = p - pi;

float minDistance = 1e10; // Renamed to avoid confusion with vec3 d
vec3 diff;
float dist;

for (int i = -1; i <= 1; i++) {
    for (int j = -1; j <= 1; j++) {
        for (int k = -1; k <= 1; k++) {
            vec3 offset = vec3(float(i), float(j), float(k));
            vec3 randomOffset = random3f(pi + offset);
            vec3 point = offset + randomOffset;
            diff = point - pf;
            dist = sqrt(dot(diff, diff)); // Simplified computation
            if (dist < minDistance) {
                minDistance = dist;
            }
        }
    }
}

    return minDistance;
}

void main()
{
    vec3 p = vec3(fs_Pos);
    p = sin(p * 0.2);
    float d = worley(p * u_WorleyScale);
    float noiseEffect = clamp(d / 2.0, 0.0, 1.0);
    noiseEffect = smoothstep(0.1, 0.5, noiseEffect);
    vec4 diffuseColor = u_Color;
    vec4 ambientColor = vec4(0.2, 0.2, 0.2, 1.0);
    float lightIntensity = noiseEffect + ambientColor.r;
    //lightIntensity = clamp(lightIntensity, 0.0, 1.0);
    out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
    //out_Col = vec4(d, d, d, 1.0);
    //out_Col = vec4(fract(u_Time), 0.0, 0.0, 1.0);
}