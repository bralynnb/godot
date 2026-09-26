extends Control
var player_pos = Vector3.ZERO
var base = Vector2(95,180)
var scale_factor = 20.0
func _draw() -> void:
 draw_rect(Rect2(45,120,870,490),Color(.02,.035,.045,.97))
 var font = ThemeDB.fallback_font
 for level in [0,1]:
  var origin = base+Vector2(level*440,0)
  draw_string(font,origin+Vector2(0,-20),"GROUND FLOOR" if level == 0 else "UPPER FLOOR",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("c9d6c6"))
  draw_rect(Rect2(origin,Vector2(320,360)),Color("67837e"),false,2)
  for x in [118,202]: draw_line(origin+Vector2(x,0),origin+Vector2(x,360),Color("67837e"),2)
  draw_line(origin+Vector2(0,180),origin+Vector2(118,180),Color("67837e"),2)
  draw_line(origin+Vector2(202,180),origin+Vector2(320,180),Color("67837e"),2)
  var labels = ["REAR PARLOR","CONSERVATORY","DRAWING ROOM","STUDY"] if level==0 else ["WARNING ROOM","STATUE GALLERY","WEST BEDROOM","EAST BEDROOM"]
  var offsets = [Vector2(5,78),Vector2(207,78),Vector2(5,275),Vector2(207,275)]
  for i in range(4): draw_string(font,origin+offsets[i],labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("cbd6d0"))
  for i in range(12): draw_line(origin+Vector2(137,80+i*10),origin+Vector2(183,80+i*10),Color("798575"),1)
  draw_string(font,origin+Vector2(134,245),"HALL",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("cbd6d0"))
  # Door openings in the drawn plan.
  for x in [118,202]:
   for z in [44,280]: draw_line(origin+Vector2(x,z-16),origin+Vector2(x,z+16),Color("101d23"),4)
  if (player_pos.y>2.6) == (level==1): draw_circle(origin+Vector2((player_pos.x+8)*20,(player_pos.z+9)*20),5,Color("e6bc70"))
 draw_string(font,Vector2(95,582),"M / ESC  Close     •     Gold dot: you     •     Stairs connect both floors",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("cbd6d0"))
