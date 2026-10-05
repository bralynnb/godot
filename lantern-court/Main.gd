extends Node2D

var player = Vector2(7, 8)
var time = 0.0
var walking = false
var facing = 1
var zoom_level = 1.0
var target = Vector2(-1,-1)
var props = []
var blocks = []
var font = ThemeDB.fallback_font

func iso(p: Vector2) -> Vector2:
	return Vector2(320 + (p.x-p.y)*22, 64 + (p.x+p.y)*11)

func _ready():
	for data in [[2,2,2.6,2.2,64,"house"],[7,1,3,2,78,"house"],[1,7,2,2.4,57,"house"],[10,5,1.6,1.2,25,"stall"],[5,4,1.6,1.2,25,"stall"],[4,10,1.4,0.7,8,"bench"],[10,10,0.6,0.6,10,"pot"],[3,5,0.6,0.6,10,"pot"],[8,11,0.6,0.6,10,"pot"],[6,2,0.3,0.3,39,"lamp"],[2,10,0.3,0.3,39,"lamp"],[11,8,0.3,0.3,39,"lamp"]]:
		var r = Rect2(data[0],data[1],data[2],data[3])
		props.append({"r":r,"h":data[4],"kind":data[5]})
		blocks.append(r.grow(0.18))

func can_walk(p):
	if p.x < 0.4 or p.y < 0.4 or p.x > 12.6 or p.y > 12.6: return false
	for r in blocks:
		if r.has_point(p): return false
	return true

func _unhandled_input(e):
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP: zoom_level = min(1.7,zoom_level+0.1)
		if e.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom_level = max(0.8,zoom_level-0.1)
		if e.button_index == MOUSE_BUTTON_LEFT:
			var m = (e.position-Vector2(320,200))/zoom_level+Vector2(320,200)-Vector2(320,64)
			target = Vector2(m.x/44+m.y/22,m.y/22-m.x/44)
	if e is InputEventKey and e.pressed:
		if e.keycode == KEY_R: player=Vector2(7,8); target=Vector2(-1,-1)
		if e.keycode == KEY_F:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if DisplayServer.window_get_mode()!=DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_WINDOWED)

func _process(delta):
	time += delta
	var direction = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	var motion = Vector2(direction.x+direction.y,direction.y-direction.x).normalized()
	if direction.length()>0: target=Vector2(-1,-1)
	elif target.x>=0:
		if player.distance_to(target)<0.12: target=Vector2(-1,-1)
		else: motion=player.direction_to(target)
	walking=motion.length()>0
	if walking:
		if motion.x-motion.y!=0: facing=1 if motion.x-motion.y>0 else -1
		var speed=3.2 if Input.is_physical_key_pressed(KEY_SHIFT) else 2.0
		var next=player+motion*delta*speed
		var old=player
		if can_walk(Vector2(next.x,player.y)): player.x=next.x
		if can_walk(Vector2(player.x,next.y)): player.y=next.y
		if player==old: target=Vector2(-1,-1); walking=false
	queue_redraw()

func poly(points, color):
	draw_colored_polygon(PackedVector2Array(points),Color(color))

func box(r: Rect2, h: float, top: String, left: String, right: String):
	var a=iso(r.position)
	var b=iso(r.position+Vector2(r.size.x,0))
	var c=iso(r.end)
	var d=iso(r.position+Vector2(0,r.size.y))
	var v=Vector2(0,-h)
	poly([d,c,c+v,d+v],left)
	poly([b,c,c+v,b+v],right)
	poly([a+v,b+v,c+v,d+v],top)
	draw_polyline(PackedVector2Array([d+v,c+v,b+v]),Color("ac9675"),1)

func rect(p,s,c): draw_rect(Rect2(p,s),Color(c))

func person():
	var p=iso(player).round()
	var step=sin(time*12)*3 if walking else 0.0
	poly([p+Vector2(-8,0),p+Vector2(0,-3),p+Vector2(8,0),p+Vector2(0,3)],"151c29")
	rect(p+Vector2(-4,-8+step),Vector2(3,8),"9a816f")
	rect(p+Vector2(1,-8-step),Vector2(3,8),"c0a184")
	rect(p+Vector2(-5,-1+step),Vector2(4,2),"182333")
	rect(p+Vector2(1,-1-step),Vector2(5,2),"182333")
	rect(p+Vector2(-5,-18),Vector2(10,12),"2b696c")
	rect(p+Vector2(-4,-18),Vector2(3,10),"54a098")
	rect(p+Vector2(-7,-15-step/2),Vector2(3,8),"367c7b")
	rect(p+Vector2(4,-15+step/2),Vector2(3,8),"367c7b")
	rect(p+Vector2(-4,-26),Vector2(8,8),"d5a078")
	rect(p+Vector2(-5,-28),Vector2(9,4),"402e33")
	rect(p+Vector2(3*facing,-23),Vector2(2,2),"202532")
	rect(p+Vector2(-4,-18),Vector2(8,2),"d58957")

func prop(o):
	var r:Rect2=o.r
	var p=iso(r.end)
	if o.kind=="house":
		box(r,o.h,"4c5261","75594e","4b4550")
		for z in range(8,int(o.h)-4,7):
			draw_line(iso(r.position+Vector2(0,r.size.y))-Vector2(0,z),p-Vector2(0,z),Color("886757"))
		for x in [0.25,0.65]:
			for h in [22,46]:
				var a=iso(r.position+Vector2(r.size.x*x,r.size.y))-Vector2(0,h)
				poly([a,a+Vector2(10,5),a+Vector2(10,-8),a+Vector2(0,-13)],"e7b76f")
				draw_line(a+Vector2(5,2),a+Vector2(5,-10),Color("694c49"),2)
		box(Rect2(r.position-Vector2(0.12,0.12),r.size+Vector2(0.24,0.24)),o.h+3,"555b6a","303643","252e3e")
		# Roof rim only; restore the wall faces below the roof.
		box(r,o.h,"555b6a","75594e","4b4550")
		for x in [0.22,0.67]:
			for h in [20,44]:
				var a=iso(r.position+Vector2(r.size.x*x,r.size.y))-Vector2(0,h)
				poly([a,a+Vector2(10,5),a+Vector2(10,-8),a+Vector2(0,-13)],"efba73")
				draw_line(a+Vector2(5,2),a+Vector2(5,-10),Color("5c4746"),2)
		box(Rect2(r.position+Vector2(0.4,0.4),Vector2(0.4,0.4)),o.h+10,"7c716a","504e54","393d4b")
	elif o.kind=="stall":
		box(r,11,"ac815d","725348","4b4043")
		for x in [0.0,r.size.x]:
			var a=iso(r.position+Vector2(x,r.size.y))
			draw_line(a,a-Vector2(0,28),Color("b3916b"),2)
		for i in range(8):
			var rr=Rect2(r.position+Vector2(i*r.size.x/8,0),Vector2(r.size.x/8,r.size.y))
			box(rr,29,"bd725f" if i%2==0 else "d3b58b","9e594e" if i%2==0 else "ac997a","744954")
		for i in range(5):
			var a=iso(r.position+Vector2(0.2+i*0.27,r.size.y))-Vector2(0,13)
			rect(a,Vector2(4,4),"cfac62" if i%2==0 else "79a082")
	elif o.kind=="bench":
		box(r,8,"ad886a","66544e","443e44")
	elif o.kind=="pot":
		box(r,9,"8f8463","9c6453","624951")
		for i in range(7):
			var a=p+Vector2(sin(i*3.0)*8,-15+cos(i*2.0)*5)
			rect(a,Vector2(5,7),"628477" if i%2==0 else "3b6260")
	else:
		rect(p-Vector2(2,38),Vector2(3,38),"394250")
		rect(p-Vector2(5,41),Vector2(9,9),"ecc78a")
		rect(p-Vector2(6,43),Vector2(11,3),"59616c")
		for i in range(3): draw_circle(p-Vector2(0,36),float(10+i*6),Color(1,0.71,0.35,0.025))

func _draw():
	draw_set_transform(Vector2(320,200)*(1-zoom_level),0,Vector2.ONE*zoom_level)
	box(Rect2(0,0,13,13),-8,"354552","1e2b39","172331")
	for x in range(13):
		for y in range(13):
			var a=iso(Vector2(x,y))
			var col=["465258","4b565b","424f56","50595b"][(x*7+y*13)%4]
			poly([a+Vector2(0,1),a+Vector2(21,11),a+Vector2(0,21),a+Vector2(-21,11)],col)
			if (x*17+y*7)%9==0: draw_line(a+Vector2(-7,11),a+Vector2(3,16),Color("647074"))
	for pos in [Vector2(8,6),Vector2(5,8),Vector2(10,3)]:
		var a=iso(pos)
		poly([a,a+Vector2(30,10),a+Vector2(6,21),a+Vector2(-17,12)],"3a5965")
		draw_line(a+Vector2(-10,12),a+Vector2(15,12),Color("759093"))
	var ordered=props.duplicate()
	ordered.append({"r":Rect2(player,Vector2.ZERO),"kind":"player"})
	ordered.sort_custom(func(a,b): return a.r.end.x+a.r.end.y < b.r.end.x+b.r.end.y)
	for o in ordered:
		if o.kind=="player": person()
		else: prop(o)
	var start=iso(Vector2(2,3))-Vector2(0,55)
	var end=iso(Vector2(10,2))-Vector2(0,45)
	for i in range(21):
		var t=float(i)/20
		var p=start.lerp(end,t)+Vector2(0,sin(t*PI)*15)
		if i>0:
			var tt=float(i-1)/20
			draw_line(start.lerp(end,tt)+Vector2(0,sin(tt*PI)*15),p,Color("232e3d"))
		if i%2==0: rect(p,Vector2(3,4),"f2c88b")
	draw_set_transform(Vector2.ZERO)
	draw_string(font,Vector2(20,28),"L A N T E R N   C O U R T",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("e7c9a0"))
	draw_string(font,Vector2(20,45),"An evening in the market",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("879da9"))
	draw_string(font,Vector2(20,382),"WASD / ARROWS  Walk    SHIFT  Run    CLICK  Walk to    WHEEL  Zoom    R  Reset",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("b8c1be"))
