#version 300 es

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_LightVec; // The direction of the light in the scene.
uniform vec4 u_CamPos; // The position of the camera in the scene.
uniform float u_Time;
uniform vec4 u_BkgColor;
uniform vec4 u_FireNoiseParams;

in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in float fs_radius;
in vec2 texCoord;

out vec4 out_Col; 

#define PI 3.14159265359
#define OCT_NUM 16

float noise(vec3 position)
{
    return fract(sin(dot(position, vec3(12.9898, 78.233, 45.543)))*43758.5453);
}

float hash( int n ) 
{
	n = (n << 13) ^ n;
    n = n * (n * n * 15731 + 789221) + 1376312589;
    return -1.0+2.0*float( n & ivec3(0x0fffffff))/float(0x0fffffff);
}

float hash2( in ivec2 p ) 
{
    vec3 p3  = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash3( in ivec3 p ) 
{
    vec3 p3  = fract(vec3(p) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// gradient noise
float gnoise( in float p )
{
    int   i = int(floor(p));
    float f = fract(p);
    float u = f*f*(3.0-2.0*f);
    return mix( hash(i+0)*(f-0.0), 
                hash(i+1)*(f-1.0), u);
}

float gnoise2( in vec2 p )
{
    ivec2 i = ivec2(floor(p));
    vec2  f = fract(p);
    float a = hash2( i + ivec2(0,0) );
    float b = hash2( i + ivec2(1,0) );
    float c = hash2( i + ivec2(0,1) );
    float d = hash2( i + ivec2(1,1) );
    vec2  u = f*f*(3.0-2.0*f);
    return mix( a, b, u.x) + 
           (c - a)* u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

float gnoise3(in vec3 p) {
    ivec3 i = ivec3(floor(p));
    vec3  f = fract(p);
    float a = hash3( i + ivec3(0,0,0) );
    float b = hash3( i + ivec3(1,0,0) );
    float c = hash3( i + ivec3(0,1,0) );
    float d = hash3( i + ivec3(1,1,0) );
    float e = hash3( i + ivec3(0,0,1) );
    float j = hash3( i + ivec3(1,0,1) );
    float g = hash3( i + ivec3(0,1,1) );
    float h = hash3( i + ivec3(1,1,1) );
    vec3  u = f*f*(3.0-2.0*f);
    return mix( a, b, u.x) + 
           (c - a)* u.y * (1.0 - u.x) +
           (e - a)* u.z * (1.0 - u.x) +
           (g - c)* u.z * (1.0 - u.x) * (1.0 - u.y) +
           (d - b) * u.x * u.y +
           (j - b) * u.x * u.z * (1.0 - u.y) +
           (h - j) * u.x * u.y * u.z;
}

// fbm
float fbm( in float x, in float G )
{    
    x += 26.06;
    float n = 0.0;
    float s = 1.0;
    float a = 0.0;
    float f = 1.0;    
    for( int i=0; i<OCT_NUM; i++ )
    {
        n += s*gnoise(dot(x, f));
        a += s;
        s *= G;
        f *= 2.0;
        x += 0.31;
    }
    return n / a;
}

float fbm2( in vec2 x, in float G )
{    
    x += 26.06;
    float n = 0.0;
    float s = 1.0;
    float a = 0.0;
    float f = 1.0;    
    for( int i=0; i<OCT_NUM; i++ )
    {
        n += s*gnoise2(f * x);
        a += s;
        s *= G;
        f *= 2.0;
        x += 0.31;
    }
    return n / a;
}

float fbm3( in vec3 x, in float G )
{    
    x += 26.06;
    float n = 0.0;
    float s = 1.0;
    float a = 0.0;
    float f = 1.0;    
    for( int i=0; i<OCT_NUM; i++ )
    {
        n += s*gnoise3(f * x);
        a += s;
        s *= G;
        f *= 2.0;
        x += 0.31;
    }
    return n / a;
}

float bias(float value, float b) {
    return value / ((1.0 / b - 1.9) + value);
}

float gain(float value, float g) {
    if (value < 0.5)
        return bias(value * 2.0, g) * 0.5;
    else
        return 1.0 - bias((1.0 - value) * 2.0, g) * 0.5;
}

vec3 convertRGB(float r, float g, float b) {
    return vec3(r / 255.0, g / 255.0, b / 255.0);
}

// adjust hue
vec3 blendWithBaseColor(vec3 originalColor, vec3 baseColor, float blendFactor) {
    return mix(originalColor, baseColor, blendFactor); // Blend the original with the new base color
}

void main()
{
    vec3 viewDir = normalize(u_CamPos.xyz - fs_Pos.xyz);
    float n_dot_v = dot(normalize(fs_Nor.xyz), normalize(viewDir.xyz));

    float corona_size = 0.5;
    float intensity = n_dot_v * corona_size;
    //intensity = clamp(intensity, 0.0, 1.0);
    intensity = gain(intensity, 0.6);
    intensity = clamp(intensity, 0.0, 1.0);
    // get the distance to the center of the fireball
    float radius = length(fs_Pos.xyz);
    // normalize the distance
    float normalizedDistance = abs((radius - fs_radius) / radius);
    // apply contrast to the distance
    normalizedDistance = pow(normalizedDistance, 0.3);


    vec2 seamlessCoord = vec2(sin(2.0 * 3.14159 * texCoord.x), cos(2.0 * 3.14159 * texCoord.y));
    // Calculate fire intensity based on noise and the angle of viewing
    float fireIntensity = 0.0;
    float fireNoiseParam = u_FireNoiseParams[0];
    fireIntensity = 0.7 * pow(fbm2(texCoord, fireNoiseParam), 4.0) * (3.0 + 5.5 * intensity);
    fireIntensity = pow(fireIntensity, 0.5);
    fireIntensity = clamp(fireIntensity, 0.0, 1.0);
    // color gradient based on fire intensity from high to low (intensity = 1.0 to 0.0):
    // black - purple - blue - white - yellow - red - black
    vec3 color0 = convertRGB(0.0, 0.0, 0.0); // black
    vec3 color1 = convertRGB(79.0, 0.0, 25.0); // blue
    vec3 color2 = convertRGB(245.0, 234.0, 166.0);  // white
    vec3 color3 = convertRGB(255.0, 255.0, 59.0); // yellow
    vec3 color4 = convertRGB(227.0, 9.0, 5.0); // red
    vec3 color5 = convertRGB(0.0, 0.0, 0.0); // black
    vec3 fireColor = vec3(0.0);

    vec3 color_base = u_Color.xyz;

    // add hue to the fireball
    vec3 color_hue0 = blendWithBaseColor(color0, color_base, 0.5);
    vec3 color_hue1 = blendWithBaseColor(color1, color_base, 0.5);
    vec3 color_hue2 = blendWithBaseColor(color2, color_base, 0.5);
    vec3 color_hue3 = blendWithBaseColor(color3, color_base, 0.75);
    vec3 color_hue4 = blendWithBaseColor(color4, color_base, 0.9);
    vec3 color_hue5 = blendWithBaseColor(color5, color_base, 0.5);
    // mix color based on fire intensity
    fireColor = mix(color_hue5, color_hue4, smoothstep(0.0, 0.5, fireIntensity)); // black to red
    fireColor = mix(fireColor, color_hue3, smoothstep(0.5, 0.85, fireIntensity)); // red to yellow
    fireColor = mix(fireColor, color_hue2, smoothstep(0.85, 0.95, fireIntensity)); // yellow to white
    fireColor = mix(fireColor, color_hue1, smoothstep(0.95, 0.98, fireIntensity)); // white to blue
    fireColor = mix(fireColor, color_hue0, smoothstep(0.98, 1.0, fireIntensity)); // blue to black

    // alpha channel based on fire intensity
    float alpha = 1.0;
    
    alpha = 1.0 - pow(fireIntensity, 5.0);
    // alpha also depends on the angle of viewing
    alpha = mix(alpha, 0.0, smoothstep(0.0, 1.0, n_dot_v));
    // the larger the distance, the more transparent the fireball
    alpha = mix(alpha, 0.0, smoothstep(0.5, 1.0, normalizedDistance));
    alpha = 1.0 - alpha;
    alpha = pow(alpha, 2.0);
    alpha = clamp(alpha, 0.0, 1.0);

    
    // brightness based on fire intensity
    float brightness_param = u_FireNoiseParams[3];
    float brightness = pow(fireIntensity, brightness_param);
    //fireColor = fireColor * brightness;

    // add rim lighting
    float rim = 1.0 - n_dot_v;
    rim = pow(rim, 10.0);
    rim = clamp(rim, 0.0, 1.0);
    vec3 rimColor = convertRGB(224.0, 112.0, 0.0);
    fireColor = mix(fireColor, color3, rim);

    // mix color with background color
    fireColor = mix(u_BkgColor.rgb, fireColor, smoothstep(0.2, 0.5, alpha));


    // add bloom effect



    // add noise to the fireball
    float noiseIntensity = 0.03;
    float noiseValue = noise(fs_Pos.xyz * 0.5);
    fireColor = brightness_param * mix(fireColor, noiseValue * color3, noiseIntensity);

    
   
    // Compute final shaded color
    out_Col = vec4(fireColor.rgb, 1.0);
    //out_Col = vec4(normalizedDistance, normalizedDistance, normalizedDistance, 1.0);
    //out_Col = vec4(radius, radius, radius, 1.0);
    //out_Col = vec4(intensity, intensity, intensity, 1.0);
    //out_Col = vec4(fireIntensity,fireIntensity, fireIntensity, 1.0);
    //out_Col = vec4(viewDir, 1.0);
    //out_Col = vec4(n_dot_v, n_dot_v, n_dot_v, 1.0);
    //out_Col = normalize(u_CamPos);
    //out_Col = vec4(alpha, alpha, alpha, 1.0);
    //out_Col = vec4(texCoord, 0.0, 1.0);
}
