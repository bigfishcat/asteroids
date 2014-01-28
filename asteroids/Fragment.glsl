varying lowp vec4 pointColor;

varying lowp vec2 texCoordOut;
uniform sampler2D Texture;

void main()
{
    gl_FragColor = pointColor * texture2D(Texture, texCoordOut);
}