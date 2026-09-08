//varying => value thats passed between vertex and fragment shader
//Transform => position, scale, rotation
//modelMatrix => position, scale, rotation of the model
//viewMatrix => position, orientation of the camera
//projectionMatrix => projects object onto the screen (aspect ratio and the perspective)

varying vec3 vWorldPos;
void main() {




    vec4 world_position_inside_a_plane = modelMatrix * vec4(position, 1.0);
    vWorldPos = world_position_inside_a_plane.xyz;//passes per vertex world position to fragment shader.
    gl_Position = projectionMatrix * viewMatrix * world_position_inside_a_plane;
    
    
}