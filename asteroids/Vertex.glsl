attribute vec4 vertexPosition;
attribute vec4 vertexColor;

varying vec4 pointColor;

uniform mat4 projection;
uniform mat4 modelview;

attribute vec2 texCoordIn;
varying vec2 texCoordOut;

void main()
{
    pointColor = vertexColor;
    gl_Position = projection * modelview * vertexPosition;
    texCoordOut = texCoordIn;
}