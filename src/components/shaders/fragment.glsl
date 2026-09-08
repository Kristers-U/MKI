varying vec3 vWorldPos;

uniform vec3 uColor;
uniform float uThickness;

float gridLine(float coord) {
    //fwidth() returns how fast value changes across the screen. Works like antialias

    float coord_change = fwidth(coord);

    //abs() returns non-negative value
    //fract() turns 1.2 into 0.2

    float line = abs(fract(coord - 0.5) - 0.5) / coord_change;  //line / coord_change is antialias

    //float line = fract(coord)/0.9; //Original

    return 1.0 - smoothstep(0.0, uThickness, line);

    //return 1.0 -step(0.5, line); //Original
}

void main() {
    float gx = gridLine(vWorldPos.x);
    float gz = gridLine(vWorldPos.z);
    float grid = max(gx, gz);

    if (grid < 0.01) discard;
    gl_FragColor = vec4(uColor, grid);

}
