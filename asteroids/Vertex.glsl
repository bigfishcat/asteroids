attribute vec4 vertexPosition;

uniform mat4 projection;
uniform mat4 modelview;

attribute vec2 texCoordIn;
varying vec2 texCoordOut;

void main()
{
    gl_Position = projection * modelview * vertexPosition;
    texCoordOut = texCoordIn;
}