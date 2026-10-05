shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float strength : hint_range(0.0,1.0) = 0.35;
void fragment(){
 vec2 uv=SCREEN_UV;
 vec3 c=texture(screen_texture,uv).rgb;
 vec2 px=SCREEN_PIXEL_SIZE;
 vec3 glow=(texture(screen_texture,uv+vec2(px.x,0.0)).rgb+texture(screen_texture,uv-vec2(px.x,0.0)).rgb+texture(screen_texture,uv+vec2(0.0,px.y)).rgb+texture(screen_texture,uv-vec2(0.0,px.y)).rgb)*0.25;
 float beam=0.86+0.14*cos(uv.y/px.y*3.14159265);
 float lane=mod(floor(uv.x/px.x),3.0);
 vec3 mask=vec3(0.92);if(lane<1.0)mask.r=1.08;else if(lane<2.0)mask.g=1.08;else mask.b=1.08;
 vec3 processed=c*beam*mask+glow*0.05;
 COLOR=vec4(mix(c,processed,strength),1.0);
}
