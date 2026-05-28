//
// Silhouette aura fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec4 u_aura_colour;
uniform float u_alpha_cutoff;

void main()
{
    vec4 base_col = texture2D(gm_BaseTexture, v_vTexcoord);

    // dont draw fully transparent sprite pixels
    if (base_col.a <= u_alpha_cutoff)
    {
        discard;
    }

    // use the sprite alpha as the aura mask
    vec4 aura_col = u_aura_colour;
    aura_col.a *= base_col.a;

    gl_FragColor = aura_col;
}