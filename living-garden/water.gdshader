shader_type canvas_item;
void fragment() {
 vec4 c=texture(TEXTURE,UV);
 float water=step(c.r*1.7,c.g)*step(c.b*.79,c.g)*step(c.g*.74,c.b)*step(.43,c.g);
 float ripple=sin(UV.y*800.0+TIME*1.5+sin(UV.x*110.0+TIME*.4)*2.0);
 c.rgb += water * step(.96,ripple)*.022;
 COLOR=c;
}
