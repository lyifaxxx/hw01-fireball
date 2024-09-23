#version 300 es

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time;       // The time in seconds since the program started running
uniform vec4 u_FireNoiseParams;


in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;            // The position of each vertex. This is implicitly passed to the fragment shader.
out float fs_radius;        // RADIUS OF THE FIREBALL
out vec2 texCoord;          // The texture coordinates of each vertex. This is implicitly passed to the fragment shader.

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

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


void main()
{
    fs_Col = vs_Col;                        
    fs_Nor = u_ModelInvTr * vs_Nor;  
    fs_radius = length(vs_Pos.xyz); 

    // get coord of vertex on surface of sphere
    float theta = atan(vs_Pos.x, vs_Pos.z);
    float phi = acos(vs_Pos.y / length(vs_Pos));

    texCoord.x = (theta + 3.14159265359) / (2.0 * 3.14159265359);
    texCoord.y = phi / 3.14159265359;

    float rotationSpeed = u_FireNoiseParams[1] / 10.0;
    vec2 noiseCoord;
    noiseCoord.x = 0.5 * (1.0 + sin(theta + u_Time * rotationSpeed));
    noiseCoord.y = 0.5 * (1.0 + cos(phi + u_Time * rotationSpeed));
    
    texCoord.x = noiseCoord.x;
    texCoord.y = noiseCoord.y;

    float bumpness = u_FireNoiseParams[2];
    // compute the radius of the fireball
    float radius = 0.2;
    float corona_length = 0.3;
    //radius =  radius * fbm(1.0 * (-3.0 * vs_Pos.y - 3.0 * vs_Pos.x - 5.0 * vs_Pos.z + u_Time * 0.1 ), 0.3);
    radius = radius * fbm3(vs_Pos.yzx, 0.6);
    radius += noise(vs_Pos.xyz * 0.4) * corona_length *( 0.1 * sin(u_Time) + 0.2) + 0.3;
    // apply another layer of noise to smooth the surface
    radius += bumpness * noise(vs_Pos.yxz * 0.1) * fbm3(vs_Pos.zyx * 0.8, 0.1) * sin(u_Time * 0.01);
    vec4 newPos = vs_Pos + vs_Nor * radius;

    vec4 modelposition = u_Model * newPos;   // Temporarily store the transformed vertex positions for use below
    fs_Pos = modelposition;                  // Pass the vertex positions to the fragment shader for interpolation
    fs_Col = vs_Col;
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies


    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
