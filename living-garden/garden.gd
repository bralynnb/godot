extends Node2D

const SIZE = 800.0
const COLORS = [Color("f1c570"),Color("e88991"),Color("80b9c8"),Color("eee4ca"),Color("8fa76b"),Color("9b86ba")]
var graph = AStar2D.new()
var nodes: Array[Vector2] = []
var edges: Array[Vector2i] = []
var people: Array[Dictionary] = []
var boats: Array[Dictionary] = []
var petals: Array[Dictionary] = []
var player = Vector2(341,706)
var player_route = PackedVector2Array()
var player_dir = Vector2.DOWN
var walking = false
var clock = 0.0
var paused = false
var cam: Camera2D
var target_zoom = 1.0
var follow = false
var dragging = false
var dragged = false
var press = Vector2.ZERO
var hud: Label
var message: Label
var stats: Label
var map_button: Button
var sky = true
var night = false
var ambience = false
var sound: AudioStreamPlayer
var synth: AudioStreamGeneratorPlayback
var sound_phase = 0.0
var discoveries = {}
var landmarks = {"Pagoda":Vector2(420,476),"Tea garden":Vector2(151,686),"Red bridge":Vector2(261,545),"Torii gates":Vector2(647,665),"Cherry walk":Vector2(296,232)}
var last_message = "Click a path to stroll. Take your time."

func _ready():
	seed(84)
	var bg = Sprite2D.new()
	bg.texture = load("res://assets/garden.png")
	bg.centered = false
	bg.scale = Vector2.ONE * SIZE / bg.texture.get_width()
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat = ShaderMaterial.new()
	mat.shader = load("res://water.gdshader")
	bg.material = mat
	bg.z_index = -10
	add_child(bg)
	# Paths are hand-traced to the supplied composition. Two separate banks.
	add_path([[0,377],[52,370],[106,342],[148,321],[167,285],[202,262],[261,257],[294,234],[342,234]])
	add_path([[461,233],[509,209],[552,188],[580,173],[612,157],[682,156],[709,147],[681,110],[641,88],[594,63],[556,51],[522,20],[500,0]])
	add_path([[0,624],[71,613],[112,604],[153,590],[180,588],[216,613],[260,637],[278,674],[341,706],[415,706],[483,674],[554,670],[609,644],[654,663],[709,697],[799,682]])
	add_path([[180,588],[210,564],[236,540],[272,519],[312,513],[336,491],[346,470],[380,479],[416,479],[453,463],[479,493],[509,501],[541,475]])
	add_path([[341,706],[297,730],[246,753],[207,725],[166,703],[130,683],[99,665]])
	add_path([[609,644],[656,614],[687,575],[710,533],[723,497],[722,470],[738,447],[773,425],[800,408]])
	for i in range(nodes.size()): graph.add_point(i,nodes[i])
	for e in edges: graph.connect_points(e.x,e.y)
	for i in range(52):
		var start = i % nodes.size()
		people.append({"p":nodes[start],"route":PackedVector2Array(),"speed":randf_range(5,11),"wait":randf_range(0,5),"color":COLORS[i%COLORS.size()],"phase":randf()*6,"dir":Vector2.DOWN,"home":start,"moving":false})
	var waterways = [
		[[163,568],[150,539],[191,475],[248,430],[287,371],[299,326]],
		[[229,580],[279,615],[359,634],[419,623],[475,590],[561,567],[598,520]],
		[[552,425],[586,381],[589,313],[625,278],[691,256],[757,270]],
		[[65,554],[39,541],[24,495],[19,456]],
		[[600,326],[657,311],[714,311],[766,346]]]
	for i in range(9):
		var route = PackedVector2Array()
		for p in waterways[i%waterways.size()]: route.append(Vector2(p[0],p[1]))
		boats.append({"route":route,"u":randf(),"speed":randf_range(.009,.018),"kind":i%3,"color":COLORS[i%6]})
	for i in range(100): petals.append({"p":Vector2(randf()*800,randf()*800),"speed":randf_range(3,9),"phase":randf()*TAU})
	cam=Camera2D.new()
	cam.position=Vector2(400,400)
	cam.position_smoothing_enabled=true
	cam.position_smoothing_speed=7
	add_child(cam)
	make_ui()
	fit_map()
	setup_audio()

func add_path(points: Array):
	var prev=-1
	for p in points:
		var v=Vector2(p[0],p[1])
		var idx=nodes.find(v)
		if idx<0:
			idx=nodes.size()
			nodes.append(v)
		if prev>=0: edges.append(Vector2i(prev,idx))
		prev=idx

func make_ui():
	var layer=CanvasLayer.new()
	add_child(layer)
	var panel=PanelContainer.new()
	panel.position=Vector2(20,20)
	var style=StyleBoxFlat.new()
	style.bg_color=Color(.04,.12,.13,.93)
	style.corner_radius_top_left=12
	style.corner_radius_top_right=12
	style.corner_radius_bottom_left=12
	style.corner_radius_bottom_right=12
	style.content_margin_left=18
	style.content_margin_right=18
	style.content_margin_top=12
	style.content_margin_bottom=12
	panel.add_theme_stylebox_override("panel",style)
	layer.add_child(panel)
	var box=VBoxContainer.new()
	panel.add_child(box)
	hud=Label.new()
	hud.text="SAKURA  /  A LIVING GARDEN"
	hud.add_theme_font_size_override("font_size",18)
	hud.modulate=Color("f0dfbe")
	box.add_child(hud)
	stats=Label.new()
	stats.add_theme_font_size_override("font_size",12)
	stats.modulate=Color("a4c6b8")
	box.add_child(stats)
	var row=HBoxContainer.new()
	box.add_child(row)
	add_button(row,"−",func(): zoom_by(.8))
	add_button(row,"+",func(): zoom_by(1.25))
	add_button(row,"Overview",fit_map)
	add_button(row,"Follow",func(): follow=true;target_zoom=4.0)
	add_button(row,"Pause",func(): paused=not paused)
	var row2=HBoxContainer.new()
	box.add_child(row2)
	add_button(row2,"Clouds",func(): sky=not sky)
	add_button(row2,"Dusk",func(): night=not night)
	add_button(row2,"Sound",func(): ambience=not ambience)
	add_button(row2,"Full screen",func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN))
	message=Label.new()
	message.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	message.position=Vector2(20,830)
	message.add_theme_font_size_override("font_size",14)
	message.add_theme_color_override("font_shadow_color",Color("102e33"))
	message.add_theme_constant_override("shadow_offset_x",2)
	message.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(message)

func add_button(row: HBoxContainer,caption: String,action: Callable):
	var b=Button.new()
	b.text=caption
	b.add_theme_font_size_override("font_size",12)
	b.pressed.connect(action)
	row.add_child(b)

func fit_map():
	follow=false
	cam.position=Vector2(400,400)
	target_zoom=min(get_viewport_rect().size.x/840.0,get_viewport_rect().size.y/840.0)

func zoom_by(factor: float):
	target_zoom=clamp(target_zoom*factor,.65,8.0)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom_by(1.2)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom_by(1/1.2)
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				press=event.position
				dragged=false
				dragging=true
			else:
				dragging=false
				if not dragged: walk_to(get_global_mouse_position())
	if event is InputEventMouseMotion and dragging:
		if event.position.distance_to(press)>5: dragged=true
		if dragged:
			follow=false
			cam.position-=event.relative/cam.zoom
			cam.position=cam.position.clamp(Vector2.ZERO,Vector2(800,800))
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_SPACE: paused=not paused
		if event.keycode==KEY_HOME: fit_map()
		if event.keycode==KEY_F: follow=not follow
		if event.keycode==KEY_E: ferry()
		if event.keycode==KEY_ESCAPE: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func nearest_path(p: Vector2) -> Vector2:
	var best=Vector2.ZERO
	var distance=INF
	for e in edges:
		var q=Geometry2D.get_closest_point_to_segment(p,nodes[e.x],nodes[e.y])
		if p.distance_squared_to(q)<distance:
			distance=p.distance_squared_to(q)
			best=q
	return best

func walk_to(p: Vector2):
	var dest=nearest_path(p)
	if p.distance_to(dest)>35:
		last_message="Choose a path to walk on. Drag to look around."
		return
	var a=graph.get_closest_point(player)
	var b=graph.get_closest_point(dest)
	player_route=graph.get_point_path(a,b)
	if player_route.is_empty():
		last_message="A separate riverbank. Press E near the red bridge to take the ferry."
	else:
		player_route.append(dest)
		last_message="Strolling through the garden…"

func ferry():
	if player.distance_to(Vector2(180,588))<45:
		player=Vector2(106,342)
		player_route.clear()
		last_message="Ferry crossing complete. Explore the cherry walk. E here to return."
	elif player.distance_to(Vector2(106,342))<45:
		player=Vector2(180,588)
		player_route.clear()
		last_message="Back at the red bridge."
	else: last_message="Ferry stop: west end of the red bridge. Walk there and press E."

func _process(delta):
	cam.zoom=cam.zoom.lerp(Vector2.ONE*target_zoom,1-exp(-delta*9))
	if follow: cam.position=player
	fill_audio()
	if not paused:
		clock+=delta
		walking=false
		var input=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		if input.length()>0:
			player_route.clear()
			var candidate=player+input.normalized()*30*delta
			if candidate.distance_to(nearest_path(candidate))<9:
				player=candidate
				walking=true
				player_dir=input
		elif not player_route.is_empty():
			var diff=player_route[0]-player
			if diff.length()<1: player_route.remove_at(0)
			else:
				player_dir=diff.normalized()
				player=player.move_toward(player_route[0],delta*25)
				walking=true
		for person in people:
			person.moving=false
			if person.wait>0:
				person.wait-=delta
			elif person.route.is_empty():
				var a=graph.get_closest_point(person.p)
				var dest=randi()%nodes.size()
				person.route=graph.get_point_path(a,dest)
			else:
				var diff=person.route[0]-person.p
				if diff.length()<.5:
					person.route.remove_at(0)
					if person.route.is_empty(): person.wait=randf_range(1,6)
				else:
					person.dir=diff.normalized()
					person.p=person.p.move_toward(person.route[0],person.speed*delta)
					person.moving=true
		for boat in boats: boat.u=fposmod(boat.u+boat.speed*delta,1.0)
		for petal in petals:
			petal.p+=Vector2(petal.speed,petal.speed*.45)*delta
			if petal.p.x>805: petal.p.x=-5
			if petal.p.y>805: petal.p.y=-5
		for key in landmarks:
			if player.distance_to(landmarks[key])<22 and not discoveries.has(key):
				discoveries[key]=true
				last_message="Discovered: "+key+"  ·  "+str(discoveries.size())+" / 5 peaceful places"
	stats.text="52 visitors  ·  9 boats  ·  %.1f× zoom  ·  %s" % [cam.zoom.x,"PAUSED" if paused else "LIVE"]
	message.text=last_message+"\nClick: walk  ·  Drag: pan  ·  Wheel: zoom  ·  WASD: move  ·  F: follow  ·  Home: overview  ·  E: ferry"
	queue_redraw()

func _draw():
	for boat in boats: draw_boat(boat)
	# Sort actors by their feet so crossings read correctly.
	var actors=people.duplicate()
	actors.append({"p":player,"dir":player_dir,"color":Color("f4d27d"),"phase":0.0,"moving":walking,"player":true})
	actors.sort_custom(func(a,b): return a.p.y<b.p.y)
	for person in actors: draw_person(person)
	for petal in petals:
		var p=petal.p+Vector2(sin(clock+petal.phase)*3,cos(clock*.8+petal.phase)*2)
		draw_rect(Rect2(p,Vector2(1.6,.8)),Color(1,.76,.82,.55))
	# Small flocks crossing the river, with a two-phase wingbeat.
	for i in range(7):
		var p=Vector2(fposmod(clock*9+i*29,940)-70,140+i*12+sin(clock*.13)*35)
		var wing=sin(clock*5+i)*2
		draw_polyline(PackedVector2Array([p+Vector2(-4,-wing),p,p+Vector2(4,-wing)]),Color("eee5cd"),1)
	if sky:
		for i in range(4):
			var p=Vector2(fposmod(clock*1.7+i*249,1120)-160,35+i*195)
			draw_cloud(p,i)
	if night:
		draw_rect(Rect2(0,0,800,800),Color(.12,.08,.24,.28))
		for p in [Vector2(401,432),Vector2(360,372),Vector2(457,368),Vector2(617,634),Vector2(159,682)]:
			for r in range(15,0,-3): draw_circle(p,r,Color(1,.7,.28,.014))
			draw_rect(Rect2(p-Vector2(1,2),Vector2(2,3)),Color("ffd693"))

func draw_person(a: Dictionary):
	var p: Vector2=a.p.round()
	var phase: float=clock*8+a.phase
	var stride: float=round(sin(phase)*1.3) if a.moving else 0.0
	var bob: float=0 if not a.moving else round(abs(sin(phase))*.6)
	var coat: Color=a.color
	var side: float=sign(a.dir.x)
	draw_set_transform(p)
	draw_rect(Rect2(-3,-1,6,2),Color(.08,.21,.23,.32))
	if a.has("player"):
		draw_arc(Vector2.ZERO,5,0,TAU,20,Color(1,.89,.57,.8),.65)
		draw_colored_polygon(PackedVector2Array([Vector2(-2,-18),Vector2(2,-18),Vector2(0,-15)]),Color("ffde81"))
	draw_rect(Rect2(-2,-4+stride,1.7,4-stride),Color("414653"))
	draw_rect(Rect2(.4,-4-stride,1.7,4+stride),Color("414653"))
	draw_rect(Rect2(-2,-.5+stride,2,1),Color("eee1c3"))
	draw_rect(Rect2(.4,-.5-stride,2,1),Color("eee1c3"))
	draw_rect(Rect2(-2.5,-9-bob,5,5.5),coat.darkened(.15))
	draw_rect(Rect2(-1.5,-9-bob,3,5),coat)
	draw_rect(Rect2(-3.5,-8-bob+stride*.4,1.3,4),Color("e4b59b"))
	draw_rect(Rect2(2.3,-8-bob-stride*.4,1.3,4),Color("e4b59b"))
	draw_rect(Rect2(-2,-13-bob,4,4),Color("edc4a4"))
	draw_rect(Rect2(-2,-14-bob,4,2),Color("494052"))
	if a.dir.y<-.2: draw_rect(Rect2(-2,-12-bob,4,2),Color("494052"))
	else: draw_rect(Rect2(side if side!=0 else 1,-11-bob,1,1),Color("494052"))
	draw_set_transform(Vector2.ZERO)

func route_position(route: PackedVector2Array,u: float) -> Vector2:
	var v=(.5-.5*cos(u*TAU))*(route.size()-1)
	var i=min(int(v),route.size()-2)
	return route[i].lerp(route[i+1],v-i)

func draw_boat(b: Dictionary):
	var p=route_position(b.route,b.u)
	var ahead=route_position(b.route,fposmod(b.u+.001,1.0))
	var flip=1.0 if ahead.x>=p.x else -1.0
	draw_set_transform(p,0,Vector2(flip,1))
	for j in range(3):
		var w=9+j*4+sin(clock*2+j)*2
		draw_arc(Vector2(-j*4,4),w,.2,2.7,12,Color(.66,.93,.9,.35-j*.07),.7)
	draw_colored_polygon(PackedVector2Array([Vector2(-14,0),Vector2(11,-3),Vector2(17,0),Vector2(8,8),Vector2(-9,8),Vector2(-14,4)]),Color("71bdc8"))
	draw_colored_polygon(PackedVector2Array([Vector2(-14,-2),Vector2(9,-5),Vector2(17,-1),Vector2(7,4),Vector2(-9,4)]),Color("e4e6cf"))
	draw_rect(Rect2(-6,-5,12,6),b.color.darkened(.2))
	if b.kind==0:
		draw_rect(Rect2(-8,-14,18,2),Color("285b60"))
		draw_rect(Rect2(-8,-12,1,10),Color("d3bc9a"))
		draw_rect(Rect2(8,-12,1,10),Color("d3bc9a"))
		draw_colored_polygon(PackedVector2Array([Vector2(-12,-14),Vector2(5,-18),Vector2(15,-14),Vector2(-3,-10)]),Color("3b7272"))
	elif b.kind==1:
		draw_rect(Rect2(8,-13,3,12),Color("f2e7ca"))
		draw_rect(Rect2(7,-15,7,4),Color("f2e7ca"))
		draw_rect(Rect2(14,-13,3,1),Color("e5ad66"))
		draw_rect(Rect2(12,-14,1,1),Color("4b5260"))
	else:
		draw_line(Vector2(-6,0),Vector2(-15,7+sin(clock*3)*3),Color("bc8768"),1.5)
		draw_line(Vector2(5,0),Vector2(15,5+sin(clock*3)*3),Color("bc8768"),1.5)
	# Every passenger is drawn on their moving craft.
	for x in [-3,3]:
		draw_rect(Rect2(x,-6,3,4),b.color)
		draw_rect(Rect2(x,-9,3,3),Color("e8b69b"))
		draw_rect(Rect2(x,-10,3,1),Color("4e4356"))
	draw_set_transform(Vector2.ZERO)

func draw_cloud(p: Vector2,i: int):
	for j in range(7):
		var q=p+Vector2(j*12,sin(j*1.7+i)*9)
		draw_circle(q,17+sin(j*2.0)*7,Color(.94,.91,.81,.13))

func setup_audio():
	sound=AudioStreamPlayer.new()
	var generator=AudioStreamGenerator.new()
	generator.mix_rate=22050
	generator.buffer_length=.15
	sound.stream=generator
	sound.volume_db=-22
	add_child(sound)
	sound.play()
	synth=sound.get_stream_playback()

func fill_audio():
	if synth==null: return
	for i in range(synth.get_frames_available()):
		sound_phase+=1.0/22050.0
		var chirp=pow(max(0,sin(sound_phase*.63)),18)*sin(sound_phase*(1800+180*sin(sound_phase*9))*TAU)*.15
		var water=randf_range(-.035,.035)
		var sample=(chirp+water) if ambience and not paused else 0.0
		synth.push_frame(Vector2.ONE*sample)
