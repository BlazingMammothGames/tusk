precision mediump float;
precision mediump int;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

attribute vec3 position;
attribute vec4 colour;

varying vec4 v_colour;

void main() {
	v_colour = colour;
	gl_PointSize = 2.0;
	gl_Position = projection * view * model * vec4(position, 1.0);
}