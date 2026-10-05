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
			var m = (e.position/0.75-Vector2(320,200))/zoom_level+Vector2(320,200)-Vector2(320,64)
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
	var snapped=PackedVector2Array()
	for p in points: snapped.append(p.round())
	draw_colored_polygon(snapped,Color(color))

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

func rect(p,s,c): draw_rect(Rect2(p.round(),s.round()),Color(c))

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
		# Individual brick courses on both visible walls.
		for row in range(1,int(o.h/5)):
			var z=row*5
			for col in range(int(r.size.x*5)):
				var u=(col+0.5*(row%2))/5.0
				if u+0.18>r.size.x: continue
				var q=iso(r.position+Vector2(u,r.size.y))-Vector2(0,z)
				poly([q,q+Vector2(4,2),q+Vector2(4,-1),q+Vector2(0,-3)], ["66504d","796052","59464b","846554"][(row*7+col*3)%4])
			for col in range(int(r.size.y*5)):
				var u=(col+0.5*(row%2))/5.0
				if u+0.18>r.size.y: continue
				var q=iso(r.position+Vector2(r.size.x,u))-Vector2(0,z)
				poly([q,q+Vector2(-4,2),q+Vector2(-4,-1),q+Vector2(0,-3)], ["3b3949","514451","423c4d"][(row+col)%3])
		# Roof gravel in a restricted palette.
		for ix in range(int(r.size.x*12)):
			for iy in range(int(r.size.y*12)):
				var q=iso(r.position+Vector2(ix/12.0,iy/12.0))-Vector2(0,o.h)
				if (ix*13+iy*7)%5==0: rect(q.round(),Vector2.ONE,"69707a")
				elif (ix+iy)%3==0: rect(q.round(),Vector2.ONE,"414654")
		for x in [0.22,0.67]:
			for h in [20,44]:
				var a=iso(r.position+Vector2(r.size.x*x,r.size.y))-Vector2(0,h)
				poly([a,a+Vector2(10,5),a+Vector2(10,-8),a+Vector2(0,-13)],"efba73")
				# Pixel curtains, window ledges and warm checkerboard falloff.
				for xx in range(1,10):
					for yy in range(-11,2):
						if (xx+yy)%3==0: rect((a+Vector2(xx,yy+xx/2.0)).round(),Vector2.ONE,"b78055")
				draw_line(a+Vector2(5,2),a+Vector2(5,-10),Color("493b43"),2)
				draw_line(a+Vector2(0,-5),a+Vector2(10,0),Color("62494a"),1)
				draw_line(a+Vector2(-2,1),a+Vector2(12,8),Color("ad8b70"),2)
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
		for xx in range(-12,13):
			for yy in range(-12,13):
				if xx*xx+yy*yy<120 and (xx+yy)%4==0:
					rect(p+Vector2(xx,yy-36),Vector2.ONE,"81705b")

func _draw():
	draw_set_transform(Vector2(320,200)*(1-zoom_level)*0.75,0,Vector2.ONE*zoom_level*0.75)
	box(Rect2(0,0,13,13),-8,"354552","1e2b39","172331")
	for x in range(13):
		for y in range(13):
			var a=iso(Vector2(x,y))
			var col=["465258","4b565b","424f56","50595b"][(x*7+y*13)%4]
			poly([a+Vector2(0,1),a+Vector2(21,11),a+Vector2(0,21),a+Vector2(-21,11)],col)
			for j in range(14):
				var dx=(j*13+x*7+y*3)%35-17
				var dy=(j*7+x*3)%15+3
				if abs(dx)/2+abs(dy-11)<9:
					rect(a+Vector2(dx,dy),Vector2(2,1),"677077" if j%3==0 else "35414e")
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
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*0.75)
	draw_string(font,Vector2(20,28),"L A N T E R N   C O U R T",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("e7c9a0"))
	draw_string(font,Vector2(20,45),"An evening in the market",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("879da9"))
	draw_string(font,Vector2(20,382),"WASD / ARROWS  Walk    SHIFT  Run    CLICK  Walk to    WHEEL  Zoom    R  Reset",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("b8c1be"))
