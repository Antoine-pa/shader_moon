 #define S(a, b, t) smoothstep(a, b, t)

mat2 Rot(float a){
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float TaperBox(vec2 p, float wb, float wt, float yb, float yt, float blur){
    //wb = long bas, wt = long haut, yb = espacement entre le bas et le milieu, yt = espacement entre le haut et le milieu
    float m = S(-blur, blur, p.y - yb);
    m *= S(blur, -blur, p.y - yt);
    
    p.x = abs(p.x);
    
    float w = mix(wb, wt, (p.y - yb) / (yt - yb));
    m *= S(blur, -blur, p.x - w);
    return m;
}

vec4 Tree(vec2 uv, vec3 col, float blur, float stage){
    float m = TaperBox(uv, 0.03, 0.03, 0.0, 1.0/(stage+1.0), blur);
    float shadow = 0.0;
    
    for(float i = 1.0; i < (stage+1.0); i++){
        m += TaperBox(vec2(uv.x, uv.y-1.0/(stage+1.0)), (stage-i)*0.05+0.1, (stage-i)*0.05, 1.0/(stage+1.0)*(i-1.0), 1.0/(stage+1.0)*i, blur);
        vec2 _uv = uv;
        if((int(i)%2)==0){
            _uv -= vec2(0.25, 0);
        }
        else{
            _uv += vec2(0.25, 0);
        }
        shadow += TaperBox(_uv, 0.1, 0.5, 1.0/(stage+1.0)*i-0.05, 1.0/(stage+1.0)*i, blur);
    }
    
    col -= shadow * 0.8;
    
    return vec4(col, m);
}

float GetHeight(float x){
    return sin(x*0.494)+sin(x)*0.3;
}

vec4 Layer(vec2 uv, float blur){
    vec4 col = vec4(0);
    
    float id = floor(uv.x);
    float n = fract(sin(id*532.45)*5541.21)*2.0-1.0;
    float x = n*0.3;
    float y = GetHeight(uv.x);
    float ground = S(blur, -blur, uv.y+y);
    col += ground;
    
    y = GetHeight(id+0.5+x);
    uv.x = fract(uv.x)-0.5;
    
    vec4 tree = Tree((uv-vec2(x, -y-0.01))*vec2(1.0, 1.0+n*0.2), vec3(1.0), blur, float(int(3.5+sin(x)*3.0)));
    col = mix(col, tree, tree.a);
    col.a = max(ground, col.a);
    return col;
}

float Hash21(vec2 p){
    p = fract(p*vec2(534.02, 964.547));
    p += dot(p, p+531.154);
    return fract(p.x*p.y);
}

float Stars(vec2 uv){
    float v = TaperBox(uv * Rot(0.5) - vec2(-0.3, 0.1), 0.1, 0.1, -2.0, 0.5, 0.3);
    return pow(Hash21(uv), 300.0/pow(v+1.0, 4.0));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy)/iResolution.y;
    
    vec2 M = (iMouse.xy/iResolution.xy)*2.0-1.0;
    
    float t = iTime*0.5;
    
    float blur;
    
    vec4 layer;
    
    vec4 col = vec4(0.0);
    col += Stars(uv);
    
    float moon = S(0.01, -0.01, length(uv-vec2(0.4, 0.2))-0.15);
    col *= 1.0-moon;
    moon *= S(-0.01, 0.1, length(uv-vec2(0.48, 0.24))-0.15);
    col += moon;
    
    for(float i = 0.0; i<1.0; i+=1.0/10.){
        blur = mix(0.04, 0.001, i);
        float scale = mix(30.0, 1.0, i);
        layer = Layer(uv*scale+vec2(t+sin(i)*1354.2, i*2.0)-M, blur);
        layer.rgb *= (1.0-i)*vec3(0.9, 0.9, 1.0);
        
        col = mix(col, layer, layer.a);
    }
    layer = Layer(uv+vec2(t, 1.5)-M, 0.07);

    col = mix(col, layer*0.1, layer.a);
    
    fragColor = col;
}
