extends Node2D

const SAVE_PATH = "user://tsfm-native-v1.json"
var catalog: Dictionary = {}
var player = Vector2(8.6,6.2)
var scene_id = "apt"
var floor_no = 10
var tokens = 100
var game_minutes = 1427.0
var needs = {"energy":70.0,"hunger":65.0,"hygiene":80.0}
var furniture: Array = []
var inventory: Array = []
var packages: Array = []
var room_light = false
var locked = true
var door_open = false
var curtains = false
var walls_visible = true
var view_rotation = 0
var zoom_amount = 1.0
var clock = 0.0
var save_clock = 0.0
var moving = false
var facing = 1
var skin = Color("c69070")
var shirt = Color("408a91")
var char_name = "Resident"
var path: Array = []
var grid = AStarGrid2D.new()
var world: Node2D
var shade: CanvasModulate
var light_root: Node2D
var ui: CanvasLayer
var hud: Label
var hint: Label
var notice: Label
var panel: PanelContainer
var panel_list: VBoxContainer
var panel_title: Label
var status_bar: ProgressBar
var activity = ""
var activity_time = 0.0
var activity_duration = 0.0
var selected = -1
var place_id = ""
var place_rotation = 0
var place_point = Vector2.ZERO
var destination = ""
var font: Font
var buttons: Array = []

func _ready():
	font = ThemeDB.fallback_font
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://catalog.json"))
	for item in data: catalog[item.id] = item
	furniture = [{"id":"bed","x":11.55,"y":4.7,"r":1,"on":false},{"id":"nightstand","x":12.9,"y":3.4,"r":0,"on":false},{"id":"cactus","x":8.9,"y":.3,"r":0,"on":false},{"id":"sofa","x":5.7,"y":8.8,"r":0,"on":false},{"id":"tv","x":5.0,"y":5.1,"r":0,"on":false}]
	load_game()
	world = Node2D.new()
	add_child(world)
	world.draw.connect(draw_world)
	shade = CanvasModulate.new()
	world.add_child(shade)
	light_root = Node2D.new()
	world.add_child(light_root)
	build_ui()
	enter_scene(scene_id,player)
	if char_name == "Resident": character_menu()
	toast("Welcome to Apartment 10C. E to use nearby objects.")

func dimensions() -> Vector2:
	match scene_id:
		"apt": return Vector2(14,12)
		"hall": return Vector2(22,4.4)
		"lobby": return Vector2(13,9)
		"street": return Vector2(22,12)
		"market": return Vector2(18,14)
		"subway": return Vector2(18,8)
	return Vector2(14,12)

func rotate_point(v: Vector2) -> Vector2:
	var dim=dimensions()
	match view_rotation:
		1:return Vector2(v.y,dim.x-v.x)
		2:return dim-v
		3:return Vector2(dim.y-v.y,v.x)
	return v

func project(v: Vector2,z: float=0.0) -> Vector2:
	var p=rotate_point(v)
	return Vector2((p.x-p.y)*12,(p.x+p.y)*6-z*12).round()

func unproject(p: Vector2) -> Vector2:
	var q=Vector2(p.x/24+p.y/12,p.y/12-p.x/24)
	var dim=dimensions()
	match view_rotation:
		1:return Vector2(dim.x-q.y,q.x)
		2:return dim-q
		3:return Vector2(q.y,dim.y-q.x)
	return q

func polygon(points: Array,c: Color):
	world.draw_colored_polygon(PackedVector2Array(points),c)

func box(rect: Rect2,z0: float,z1: float,c: Color):
	var corners=[rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]
	var top: Array=[]
	var bot: Array=[]
	for p in corners:
		top.append(project(p,z1));bot.append(project(p,z0))
	for i in range(4):
		var j=(i+1)%4
		if top[j].x < top[i].x:
			polygon([bot[i],bot[j],top[j],top[i]],c.darkened(.17 if i%2==0 else .32))
	polygon(top,c)
	for i in range(4):
		world.draw_line(top[i],top[(i+1)%4],c.lightened(.1),1)

func item_rect(item: Dictionary) -> Rect2:
	var d=catalog[item.id]
	var size=Vector2(d.w,d.d)
	if int(item.r)%2: size=Vector2(size.y,size.x)
	return Rect2(Vector2(item.x,item.y),size)

func rotate_box(b: Array,d: Dictionary,r: int) -> Array:
	var out=b.duplicate()
	var w=float(d.w)
	var depth=float(d.d)
	for k in range(r):
		out=[depth-out[4],out[0],out[2],depth-out[1],out[3],out[5]]
		var old=w;w=depth;depth=old
	return out

func color_from(value) -> Color:
	if value is Array: return Color(float(value[0])/255,float(value[1])/255,float(value[2])/255)
	return Color("887166")

func draw_item(item: Dictionary,ghost=false):
	var d=catalog[item.id]
	var parts=d.parts.duplicate()
	parts.sort_custom(func(a,b):return float(a.b[2])+float(a.b[5]) < float(b.b[2])+float(b.b[5]))
	if parts.is_empty():
		box(item_rect(item),0,float(d.h),Color("7b6657"))
	else:
		for part in parts:
			if not part is Dictionary or not part.has("b"):continue
			var b=rotate_box(part.b,d,int(item.r))
			var c=color_from(part.c)
			if ghost:c=Color(.35,.9,.75,.5)
			box(Rect2(float(item.x)+b[0],float(item.y)+b[1],b[3]-b[0],b[4]-b[1]),b[2],b[5],c)
	if item.get("on",false) and "tv" in item.id:
		var pos=project(item_rect(item).get_center(),.8)
		world.draw_rect(Rect2(pos-Vector2(8,8),Vector2(16,12)),Color(.35+.1*sin(clock*3),.5,.7))
	if item.id=="cactus":
		var pos=project(item_rect(item).get_center(),1)
		world.draw_rect(Rect2(pos-Vector2(2,11),Vector2(4,11)),Color("619060"))

func fixtures() -> Array:
	match scene_id:
		"apt":return [
			{"name":"Apartment door","p":Vector2(.6,5),"action":"door"},
			{"name":"Light switch","p":Vector2(.6,6),"action":"light"},
			{"name":"Kitchen / refrigerator","p":Vector2(1.6,8),"action":"food"},
			{"name":"Shower","p":Vector2(1.7,2.2),"action":"shower"},
			{"name":"Computer / catalog","p":Vector2(6,1.7),"action":"shop"},
			{"name":"Window blinds","p":Vector2(9.0,.7),"action":"curtain"},
			{"name":"Delivery packages","p":Vector2(1.3,5.8),"action":"packages"}]
		"hall":return [{"name":"Apartment 10C","p":Vector2(3,1),"action":"home"},{"name":"Stairs","p":Vector2(.8,2.2),"action":"stairs"},{"name":"Elevator","p":Vector2(19,1),"action":"elevator"},{"name":"Apartment 10B","p":Vector2(8,1),"action":"neighbor"},{"name":"Apartment 10A","p":Vector2(13,1),"action":"neighbor"}]
		"lobby":return [{"name":"Elevator","p":Vector2(10,1),"action":"elevator"},{"name":"Building exit","p":Vector2(7,8),"action":"outside"},{"name":"Mailboxes","p":Vector2(2,1.5),"action":"mail"},{"name":"Stairs","p":Vector2(1,6),"action":"stairs"}]
		"street":return [{"name":"No. 110 — front steps","p":Vector2(5,3.5),"action":"lobby"},{"name":"Building call box","p":Vector2(7,3.5),"action":"buzzer"},{"name":"The Strangest Flea Market","p":Vector2(20,6),"action":"market"},{"name":"Subway entrance","p":Vector2(2,8),"action":"subway"}]
		"market":return [{"name":"Return to Barrow Street","p":Vector2(1,7),"action":"street"},{"name":"Furniture merchant","p":Vector2(5,5),"action":"shop"},{"name":"Food cart","p":Vector2(11,5),"action":"food"},{"name":"Sweep the market — earn 15 tokens","p":Vector2(8,10),"action":"job"}]
		"subway":return [{"name":"Street stairs","p":Vector2(2,3),"action":"street"},{"name":"Downtown train","p":Vector2(12,4),"action":"train"}]
	return []

func solids() -> Array:
	var result: Array=[]
	if scene_id=="apt":
		result=[Rect2(0,3.9,3.9,.15),Rect2(3.9,0,.15,2.7),Rect2(0,6.9,1.1,4.8),Rect2(0,.9,1.3,2.8),Rect2(1.7,0,.8,.9),Rect2(2.9,0,.7,.6),Rect2(4.8,.3,2.5,1.0)]
		for i in furniture:
			if catalog[i.id].kind not in ["rug","wall"]:result.append(item_rect(i))
	elif scene_id=="street":result=[Rect2(1,0,10,2.7),Rect2(13,0,8,2.7),Rect2(1,8.7,3,2)]
	elif scene_id=="market":result=[Rect2(3,2,4,2),Rect2(9,2,4,2),Rect2(12,9,3,2)]
	elif scene_id=="subway":result=[Rect2(0,5.5,18,2.5),Rect2(6,2,.7,.7)]
	return result

func free_position(p: Vector2) -> bool:
	var dim=dimensions()
	if p.x<.3 or p.y<.3 or p.x>dim.x-.3 or p.y>dim.y-.3:return false
	for r in solids():
		if r.grow(.18).has_point(p):return false
	return true

func rebuild_navigation():
	var dim=dimensions()
	grid.region=Rect2i(0,0,int(dim.x*2),int(dim.y*2))
	grid.cell_size=Vector2(.5,.5)
	grid.offset=Vector2(.25,.25)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in grid.region.size.y:
		for x in grid.region.size.x:
			grid.set_point_solid(Vector2i(x,y),not free_position(Vector2(x*.5+.25,y*.5+.25)))

func walk_to(p: Vector2):
	var start=Vector2i((player/.5).floor())
	var goal=Vector2i((p/.5).floor())
	if not grid.is_in_boundsv(goal):return
	if grid.is_point_solid(goal):
		var best=1000.0
		for dy in range(-4,5):
			for dx in range(-4,5):
				var q=goal+Vector2i(dx,dy)
				if grid.is_in_boundsv(q) and not grid.is_point_solid(q):
					var dist=Vector2(q-goal).length()
					if dist<best:best=dist;goal=q
	if grid.is_point_solid(start):grid.set_point_solid(start,false)
	path=Array(grid.get_point_path(start,goal))
	if path.size()>0:path.pop_front()

func enter_scene(id: String,spawn: Vector2):
	scene_id=id;player=spawn;path=[];activity="";destination="";view_rotation=0
	close_panel();rebuild_navigation();refresh_lighting();save_game()

func draw_world():
	var dim=dimensions()
	for x in int(ceil(dim.x)):
		for y in int(ceil(dim.y)):
			var c=Color("6d5150") if scene_id=="apt" else Color("646474")
			if scene_id=="market" or scene_id=="street":c=Color("464757")
			if scene_id=="hall":c=Color("742f48") if y>0 and y<3 else Color("787780")
			if (x+y)%2:c=c.darkened(.07)
			var r=Rect2(x,y,min(1,dim.x-x),min(1,dim.y-y))
			polygon([project(r.position),project(r.position+Vector2(r.size.x,0)),project(r.end),project(r.position+Vector2(0,r.size.y))],c)
			for k in range(3):
				var a=Vector2(x+float(k)/3,y)
				world.draw_line(project(a),project(a+Vector2(0,1)),c.darkened(.2))
	if walls_visible and scene_id not in ["street","market"]:
		box(Rect2(0,0,dim.x,.12),0,4.6,Color("777589"))
		box(Rect2(0,0,.12,dim.y),0,4.6,Color("777589"))
	if scene_id=="apt":
		# Three night windows and their wooden frames.
		for x in [7.8,10.0,12.0]:
			wall_window(x)
		box(Rect2(0,6.9,1.05,1.3),0,2.5,Color("b4ae9e"))
		box(Rect2(0,8.3,1.05,2.1),0,1.15,Color("a38e71"))
		box(Rect2(.08,8.8,.86,.8),1.15,1.18,Color("48525f"))
		box(Rect2(0,10.5,1.05,1.2),0,1.2,Color("c2b9a5"))
		for x in [.2,.65]:
			for y in [10.75,11.25]:box(Rect2(x,y,.22,.22),1.2,1.23,Color("34313a"))
		box(Rect2(0,.9,1.3,2.8),0,.8,Color("c7c5c2"))
		box(Rect2(.12,1.05,1.04,2.5),.8,.81,Color("8d9baa"))
		box(Rect2(1.7,0,.8,.8),0,.7,Color("c7c5c2"))
		box(Rect2(4.8,.3,2.5,1),0,.95,Color("705548"))
		box(Rect2(5.4,.45,1.05,.6),.95,1.8,Color("aaa590"))
		box(Rect2(5.55,1.04,.72,.03),1.15,1.65,Color("4a886a"))
		if walls_visible:
			box(Rect2(0,3.9,3.9,.12),0,1.6,Color("97939e"))
			box(Rect2(3.9,0,.12,2.7),0,1.6,Color("97939e"))
		for i in range(min(packages.size(),4)):box(Rect2(.5+i*.4,5.6,.5,.5),0,.45,Color("b08b66"))
	elif scene_id=="hall":
		for x in [2.5,7.8,12.8]:draw_door(Vector2(x,.2),1.4,"10C" if x==2.5 else "10B" if x==7.8 else "10A")
		draw_door(Vector2(18,.2),2.3,"ELEVATOR",Color("8c8b96"))
	elif scene_id=="lobby":
		draw_door(Vector2(9,.2),2.4,"ELEVATOR",Color("8c8b96"))
		for x in range(5):box(Rect2(.5+x*.65,.2,.55,.25),1.3,2.3,Color("ac956b"))
	elif scene_id=="street":
		box(Rect2(1,0,10,2.7),0,6,Color("645665"))
		box(Rect2(13,0,8,2.7),0,7,Color("705561"))
		for x in [2,4,8,14,17,19]:
			box(Rect2(x,2.7,.9,.03),3,4.6,Color("c89467"))
		for i in range(3):box(Rect2(3,2.7+i*.28,3,.28),0,.6-i*.18,Color("89808a"))
		draw_door(Vector2(4,2.72),1.5,"110 BARROW")
		box(Rect2(1,8.7,3,2),0,.4,Color("282639"))
	elif scene_id=="market":
		for pos in [Vector2(3,2),Vector2(9,2),Vector2(12,9)]:
			box(Rect2(pos,Vector2(3,1.8)),0,1.1,Color("806351"))
			for i in range(6):box(Rect2(pos+Vector2(i*.5,0),Vector2(.5,2)),2.4,2.5,Color("af625a") if i%2 else Color("c7b39a"))
	elif scene_id=="subway":
		box(Rect2(0,5.5,18,2.5),-.2,0,Color("282634"))
		box(Rect2(0,5.3,18,.18),0,.05,Color("c1a769"))
		box(Rect2(6,2,.7,.7),0,4.5,Color("5f836f"))
	var drawables: Array=[]
	if scene_id=="apt":
		for i in furniture:drawables.append({"type":"item","item":i,"depth":rotate_point(item_rect(i).get_center()).x+rotate_point(item_rect(i).get_center()).y})
	var q=rotate_point(player)
	drawables.append({"type":"player","depth":q.x+q.y})
	drawables.sort_custom(func(a,b):return a.depth<b.depth)
	for d in drawables:
		if d.type=="player":draw_player()
		else:draw_item(d.item)
	if place_id!="":draw_item({"id":place_id,"x":place_point.x,"y":place_point.y,"r":place_rotation,"on":false},true)
	for f in fixtures():
		if f.p.distance_to(player)<1.8:
			var p=project(f.p,1.0)
			world.draw_polyline(PackedVector2Array([p+Vector2(-3,-4),p,p+Vector2(3,-4)]),Color("ffe3a1"),1)

func wall_window(x: float):
	box(Rect2(x,.14,1.5,.05),1.8,4.0,Color("272c4b") if not curtains else Color("736577"))
	if not curtains:
		for i in range(5):
			var p=project(Vector2(x+.15+i*.26,.22),2.2+float(i%3)*.45)
			world.draw_rect(Rect2(p,Vector2(2,3)),Color("cca66f"))
		box(Rect2(x+.73,.2,.05,.08),1.8,4,Color("aca091"))
		box(Rect2(x,.2,1.5,.08),2.85,2.9,Color("aca091"))

func draw_door(p: Vector2,w: float,label: String,c=Color("75565a")):
	box(Rect2(p,Vector2(w,.1)),0,3.7,c)
	var q=project(p+Vector2(w/2,.13),2.5)
	world.draw_string(font,q-Vector2(8,0),label,HORIZONTAL_ALIGNMENT_LEFT,-1,6,Color("e7c995"))

func draw_player():
	var p=project(player)
	var step=sin(clock*12)*2 if moving else 0.0
	if activity in ["Sleeping","Watching TV","Sitting"]:p.y-=3
	world.draw_circle(p+Vector2(0,1),5,Color(0,0,0,.25))
	world.draw_rect(Rect2(p+Vector2(-3,-7+step),Vector2(3,7)),Color("494b67"))
	world.draw_rect(Rect2(p+Vector2(1,-7-step),Vector2(3,7)),Color("575771"))
	world.draw_rect(Rect2(p+Vector2(-4,-15),Vector2(8,9)),shirt)
	world.draw_rect(Rect2(p+Vector2(-5,-14-step/2),Vector2(2,7)),shirt.darkened(.15))
	world.draw_rect(Rect2(p+Vector2(4,-14+step/2),Vector2(2,7)),shirt.darkened(.15))
	world.draw_rect(Rect2(p+Vector2(-3,-22),Vector2(6,7)),skin)
	world.draw_rect(Rect2(p+Vector2(-4,-24),Vector2(7,4)),Color("413140"))
	world.draw_rect(Rect2(p+Vector2(facing*2,-20),Vector2(1,2)),Color("282333"))

func refresh_lighting():
	for n in light_root.get_children():n.queue_free()
	shade.color=Color(.46,.43,.58) if scene_id=="apt" else Color(.57,.52,.67)
	if scene_id=="apt":
		if room_light: add_lamp(Vector2(7,6),2.8,Color("ffd5a0"),1.0,330)
		for x in [8.5,10.7,12.7]:add_lamp(Vector2(x,1),2.5,Color("8c9ce9"),.28 if curtains else .7,170)
		for i in furniture:
			if i.get("on",false):add_lamp(item_rect(i).get_center(),1,Color("9cbfff") if "tv" in i.id else Color("ffd5a0"),.85,130)
	else:
		for x in [3,9,16]:add_lamp(Vector2(min(x,dimensions().x-1),2),3,Color("ffd9a8"),.9,240)

func add_lamp(pos: Vector2,z: float,c: Color,power: float,size: float):
	var gradient=Gradient.new()
	gradient.colors=PackedColorArray([Color.WHITE,Color(1,1,1,0)])
	var texture=GradientTexture2D.new()
	texture.gradient=gradient;texture.width=128;texture.height=128
	texture.fill=GradientTexture2D.FILL_RADIAL
	texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5)
	var lamp=PointLight2D.new()
	lamp.texture=texture;lamp.texture_scale=size/128;lamp.color=c;lamp.energy=power
	lamp.position=project(pos,z);light_root.add_child(lamp)

func build_ui():
	var effect_layer=CanvasLayer.new();effect_layer.layer=1;add_child(effect_layer)
	var effect=ColorRect.new();effect.size=Vector2(640,420);effect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material=ShaderMaterial.new();material.shader=load("res://CRT.gdshader");effect.material=material;effect_layer.add_child(effect)
	ui=CanvasLayer.new();ui.layer=3;add_child(ui)
	var crt_button=Button.new();crt_button.text="CRT ON";crt_button.position=Vector2(545,39);crt_button.add_theme_font_size_override("font_size",10);crt_button.pressed.connect(func():effect.visible=not effect.visible;crt_button.text="CRT ON" if effect.visible else "CRT OFF");ui.add_child(crt_button)
	var style=StyleBoxFlat.new();style.bg_color=Color("171322");style.border_color=Color("6e5975");style.set_border_width_all(1);style.set_content_margin_all(10)
	var theme=Theme.new();theme.default_font_size=12;theme.set_stylebox("panel","PanelContainer",style)
	hud=Label.new();hud.position=Vector2(12,9);hud.add_theme_font_size_override("font_size",12);ui.add_child(hud)
	hint=Label.new();hint.position=Vector2(12,373);hint.add_theme_font_size_override("font_size",11);ui.add_child(hint)
	notice=Label.new();notice.position=Vector2(12,66);notice.add_theme_font_size_override("font_size",12);notice.modulate=Color("f0c888");ui.add_child(notice)
	status_bar=ProgressBar.new();status_bar.position=Vector2(230,350);status_bar.size=Vector2(180,10);status_bar.show_percentage=false;ui.add_child(status_bar);status_bar.hide()
	panel=PanelContainer.new();panel.theme=theme;panel.position=Vector2(155,50);panel.custom_minimum_size=Vector2(330,100);ui.add_child(panel)
	var outer=VBoxContainer.new();panel.add_child(outer)
	panel_title=Label.new();outer.add_child(panel_title)
	var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(310,220);outer.add_child(scroll)
	panel_list=VBoxContainer.new();panel_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(panel_list)
	var close=Button.new();close.text="Close  [Esc]";close.pressed.connect(close_panel);outer.add_child(close)
	panel.hide()
	var bar=HBoxContainer.new();bar.position=Vector2(12,398);ui.add_child(bar)
	for entry in [["Use [E]",use_nearest],["Pockets [I]",inventory_menu],["Rotate [Q/R]",rotate_camera],["Walls [V]",toggle_walls],["Save",save_game]]:
		var b=Button.new();b.text=entry[0];b.add_theme_font_size_override("font_size",10);b.pressed.connect(entry[1]);bar.add_child(b)

func open_panel(title: String):
	path=[];activity="";status_bar.hide()
	for c in panel_list.get_children():panel_list.remove_child(c);c.queue_free()
	panel_title.text=title;panel.show()

func option(label: String,callback: Callable,disabled=false):
	var b=Button.new();b.text=label;b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.disabled=disabled;b.pressed.connect(callback);panel_list.add_child(b)

func close_panel():
	if panel:panel.hide()

func toast(message: String):
	if notice:notice.text=message
	save_clock=0

func character_menu():
	open_panel("Your resident ID")
	var name_input=LineEdit.new();name_input.text=char_name;name_input.placeholder_text="Name";name_input.max_length=24;panel_list.add_child(name_input)
	option("Change shirt color",func():shirt=Color.from_hsv(randf(),.48,.65))
	option("Change skin tone",func():skin=[Color("edc4a0"),Color("c69070"),Color("8e5f46"),Color("634335")].pick_random())
	option("Move into Apartment 10C",func():
		char_name=name_input.text.strip_edges()
		if char_name=="":char_name="Resident"
		close_panel();save_game())

func nearest():
	var best=null
	var distance=1.8
	for f in fixtures():
		var dist=player.distance_to(f.p)
		if dist<distance:best=f;distance=dist
	if scene_id=="apt":
		for i in range(furniture.size()):
			var r=item_rect(furniture[i]);var closest=Vector2(clamp(player.x,r.position.x,r.end.x),clamp(player.y,r.position.y,r.end.y))
			var dist=player.distance_to(closest)
			if dist<distance:best={"name":catalog[furniture[i].id].name,"action":"item","index":i};distance=dist
	return best

func use_nearest():
	if activity!="":activity="";status_bar.hide();return
	var f=nearest()
	if f==null:toast("Walk closer to a door, fixture, or piece of furniture.");return
	interact(f)

func interact(f: Dictionary):
	match f.action:
		"item":item_menu(f.index)
		"door":
			open_panel("Apartment door")
			option("Unlock with apartment key" if locked else "Lock door",func():locked=not locked;save_game();interact(f))
			option("Open door" if not door_open else "Close door",func():door_open=not door_open;save_game();interact(f),locked)
			option("Leave for hallway",func():enter_scene("hall",Vector2(3,1.4)),locked or not door_open)
		"light":room_light=not room_light;refresh_lighting();toast("Ceiling light on." if room_light else "Ceiling light off.");save_game()
		"curtain":curtains=not curtains;refresh_lighting();toast("Blinds closed." if curtains else "Blinds open.");save_game()
		"food":
			open_panel("Kitchen" if scene_id=="apt" else "Food cart")
			option("Eat a meal — 5 tokens",func():
				if spend(5):start_activity("Eating",4))
			option("Make coffee — 2 tokens",func():
				if spend(2):needs.energy=min(100,needs.energy+12);close_panel();toast("Hot coffee. Energy restored."))
		"shower":start_activity("Showering",6)
		"shop":shop_menu()
		"packages":
			var count=0
			for p in packages:
				if p.left<=0:inventory.append(p.id);count+=1
			packages=packages.filter(func(p):return p.left>0)
			save_game();toast("Collected %d items. Open pockets to place them."%count)
		"home":enter_scene("apt",Vector2(1.7,5))
		"elevator","stairs":
			open_panel("Elevator" if f.action=="elevator" else "Stairwell")
			option("Lobby",func():enter_scene("lobby",Vector2(10,2)))
			option("10th floor — Apartment 10C",func():enter_scene("hall",Vector2(18.5,2)))
		"outside":enter_scene("street",Vector2(5,4.3))
		"lobby":enter_scene("lobby",Vector2(7,7))
		"market":enter_scene("market",Vector2(1.5,7))
		"street":enter_scene("street",Vector2(18,6))
		"subway":enter_scene("subway",Vector2(2,3))
		"train":open_panel("Downtown train");option("Ride to the market — subway pass",func():enter_scene("market",Vector2(1.5,7)))
		"neighbor":toast("The neighboring apartments are not open in this port yet.")
		"mail":toast("Mail: Welcome to No. 110 Barrow Street, %s."%char_name)
		"buzzer":
			open_panel("110 Barrow — call box")
			for unit in ["10A","10B","10C","10D"]:
				var apartment=unit
				option(apartment+" — buzz",func():toast(apartment+": no answer.");close_panel())
		"job":start_activity("Sweeping the market",8)

func item_menu(index: int):
	if index<0 or index>=furniture.size():return
	var item=furniture[index]
	var d=catalog[item.id]
	open_panel(d.name)
	if d.sleep>0 or "bed" in item.id:option("Sleep",func():start_activity("Sleeping",12))
	if d.sit.size()>0:option("Sit",func():start_activity("Sitting",120))
	if "tv" in item.id or "lamp" in item.id:
		option("Switch off" if item.get("on",false) else "Switch on",func():item.on=not item.get("on",false);refresh_lighting();save_game();close_panel())
		if "tv" in item.id:option("Watch TV",func():item.on=true;refresh_lighting();start_activity("Watching TV",8))
	option("Move",func():selected=index;place_id=item.id;place_rotation=int(item.r);place_point=Vector2(item.x,item.y);close_panel();toast("Click a clear spot. R rotates; Esc cancels."))
	option("Rotate",func():
		var old=item.r
		item.r=(int(item.r)+1)%4
		if not valid_placement(item,index):item.r=old;toast("There isn't enough space to rotate here.")
		rebuild_navigation();save_game();close_panel())
	option("Put in storage",func():inventory.append(item.id);furniture.remove_at(index);rebuild_navigation();refresh_lighting();save_game();close_panel())
	option("Sell for %d tokens"%int(d.price*.5),func():tokens+=int(d.price*.5);furniture.remove_at(index);rebuild_navigation();refresh_lighting();save_game();close_panel())

func shop_menu():
	open_panel("Furniture catalog  ·  %d tokens"%tokens)
	for id in catalog:
		var d=catalog[id]
		if d.parts.is_empty() or d.kind not in ["floor","small","rug"]:continue
		var item_id=id
		option("%s — %d tokens"%[d.name,d.price],func():
			if spend(int(catalog[item_id].price)):packages.append({"id":item_id,"left":10.0});save_game();close_panel();toast("Ordered. Delivery arrives at your apartment in 10 seconds."),tokens<int(d.price))

func inventory_menu():
	open_panel("Pockets & storage")
	option("ID — "+char_name,character_menu)
	option("Apartment key — 10C",func():toast("Use the key at your apartment door."))
	option("Subway pass",func():toast("Valid for downtown travel."))
	for i in range(inventory.size()):
		var index=i
		option("Place: "+str(catalog[inventory[i]].name),func():
			if scene_id!="apt":toast("Furniture can only be placed in your apartment.");return
			selected=-1;place_id=inventory[index];place_rotation=0;place_point=player+Vector2(1,0);close_panel();toast("Click a clear spot. R rotates; Esc cancels."))

func spend(cost: int) -> bool:
	if tokens<cost:toast("Not enough tokens.");return false
	tokens-=cost;return true

func valid_placement(item: Dictionary,ignore: int) -> bool:
	var r=item_rect(item)
	if not Rect2(.2,.2,13.6,11.6).encloses(r):return false
	# Reserve the doorway, bathroom approach and computer access.
	for forbidden in [Rect2(0,4,2.2,2.3),Rect2(3,2.6,2,2),Rect2(4.5,1.3,3,1.2)]:
		if r.intersects(forbidden):return false
	for i in range(furniture.size()):
		if i!=ignore and r.intersects(item_rect(furniture[i])):return false
	for wall in [Rect2(0,6.9,1.1,4.8),Rect2(0,.9,1.3,2.8),Rect2(4.8,.3,2.5,1)]:
		if r.intersects(wall):return false
	return not r.grow(.2).has_point(player)

func finish_placement():
	var item={"id":place_id,"x":place_point.x,"y":place_point.y,"r":place_rotation,"on":false}
	if not valid_placement(item,selected):toast("That spot is blocked. Choose another location.");return
	if selected>=0:furniture[selected].x=item.x;furniture[selected].y=item.y;furniture[selected].r=item.r
	else:
		var index=inventory.find(place_id)
		if index<0:return
		inventory.remove_at(index);furniture.append(item)
	place_id="";selected=-1;rebuild_navigation();refresh_lighting();save_game();toast("Furniture placed.")

func start_activity(name: String,duration: float):
	close_panel();activity=name;activity_time=0;activity_duration=duration;path=[];status_bar.show();toast(name+"… E to stop.")

func save_game():
	var data={"version":1,"name":char_name,"scene":scene_id,"player":[player.x,player.y],"tokens":tokens,"minutes":game_minutes,"needs":needs,"furniture":furniture,"inventory":inventory,"packages":packages,"light":room_light,"locked":locked,"door":door_open,"curtains":curtains,"skin":skin.to_html(),"shirt":shirt.to_html()}
	var file=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file:file.store_string(JSON.stringify(data))
	elif notice:notice.text="Save failed. Browser storage may be unavailable."

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):return
	var d=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not d is Dictionary or d.get("version",0)!=1:return
	char_name=str(d.get("name","Resident"));tokens=int(d.get("tokens",100));game_minutes=float(d.get("minutes",1427))
	if d.get("scene","") in ["apt","hall","lobby","street","market","subway"]:scene_id=d.scene
	var p=d.get("player",[8.6,6.2]);player=Vector2(p[0],p[1])
	furniture=d.get("furniture",furniture).filter(func(i):return i is Dictionary and catalog.has(i.get("id","")))
	inventory=d.get("inventory",[]).filter(func(id):return catalog.has(id));packages=d.get("packages",[])
	needs.merge(d.get("needs",{}),true);room_light=d.get("light",false);locked=d.get("locked",true);door_open=d.get("door",false);curtains=d.get("curtains",false)
	skin=Color(d.get("skin","c69070"));shirt=Color(d.get("shirt","408a91"))

func rotate_camera():
	view_rotation=(view_rotation+1)%4;refresh_lighting()

func toggle_walls():walls_visible=not walls_visible

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:
			place_id="";selected=-1;activity="";status_bar.hide();close_panel();return
		if panel.visible:return
		match event.keycode:
			KEY_E:use_nearest()
			KEY_I,KEY_TAB:inventory_menu()
			KEY_R:
				if place_id!="":place_rotation=(place_rotation+1)%4
				else:rotate_camera()
			KEY_Q:view_rotation=(view_rotation+3)%4;refresh_lighting()
			KEY_V:toggle_walls()
			KEY_F:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if DisplayServer.window_get_mode()!=DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_WINDOWED)
	if panel.visible:return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom_amount=min(3,zoom_amount+.15)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom_amount=max(.7,zoom_amount-.15)
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if place_id!="":finish_placement()
			else:walk_to(unproject(world.get_local_mouse_position()))

func _process(dt):
	if not world:return
	clock+=dt;save_clock+=dt
	if save_clock>15:save_game();save_clock=0;notice.text=""
	if not panel.visible:
		game_minutes+=dt*1.5
		needs.energy=max(0,needs.energy-dt*.018);needs.hunger=max(0,needs.hunger-dt*.024)
		for p in packages:
			if p.left>0:
				p.left-=dt
				if p.left<=0:toast("Knock, knock! Your delivery is at the apartment door.")
		if activity!="":
			activity_time+=dt;status_bar.value=activity_time/activity_duration*100
			if activity_time>=activity_duration:
				match activity:
					"Sleeping":needs.energy=100;game_minutes+=480
					"Eating":needs.hunger=min(100,needs.hunger+40)
					"Showering":needs.hygiene=100
					"Sweeping the market":tokens+=15
				toast(activity+" finished.");activity="";status_bar.hide();save_game()
	moving=false
	if not panel.visible and place_id=="" and activity=="":
		var dir=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		var move=Vector2.ZERO
		if dir.length()>0:
			path=[];move=(unproject(dir)-unproject(Vector2.ZERO)).normalized()
		elif path.size()>0:
			if player.distance_to(path[0])<.12:path.pop_front()
			if path.size()>0:move=player.direction_to(path[0])
		var speed=3.7 if Input.is_physical_key_pressed(KEY_SHIFT) else 2.4
		var before=player
		if free_position(player+Vector2(move.x,0)*dt*speed):player.x+=move.x*dt*speed
		if free_position(player+Vector2(0,move.y)*dt*speed):player.y+=move.y*dt*speed
		moving=before.distance_to(player)>.001
		if moving:
			var dx=project(player).x-project(before).x
			if dx!=0:facing=1 if dx>0 else -1
	if place_id!="":place_point=(unproject(world.get_local_mouse_position())*4).round()/4
	world.scale=Vector2.ONE*zoom_amount
	var center=project(dimensions()/2)
	if zoom_amount>1.5:center=center.lerp(project(player),min(1,(zoom_amount-1.5)/1.5))
	world.position=Vector2(320,225)-center*zoom_amount
	world.queue_redraw()
	var labels={"apt":"APARTMENT 10C","hall":"10TH FLOOR HALLWAY","lobby":"110 BARROW — LOBBY","street":"BARROW STREET","market":"THE STRANGEST FLEA MARKET","subway":"CHRISTOPHER ST — SUBWAY"}
	var minutes=int(game_minutes)%1440
	hud.text="%s  ·  %02d:%02d  ·  %d TOKENS\n%s   ENERGY %d   HUNGER %d   HYGIENE %d"%[labels[scene_id],minutes/60,minutes%60,tokens,char_name,int(needs.energy),int(needs.hunger),int(needs.hygiene)]
	var nearby=nearest()
	hint.text="[E] "+nearby.name if nearby!=null else "WASD / ARROWS walk · Click to walk · Wheel zoom · F fullscreen"
	if place_id!="":hint.text="PLACE "+str(catalog[place_id].name)+" · R rotate · Click place · Esc cancel"
