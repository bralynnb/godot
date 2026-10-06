extends Node2D
# World is 2400 × 1600. Artist coordinates are 1536 × 1024.
const WORLD=Vector2(2400,1600)
const UNIT=1.5625
const COLORS=[Color("e9b973"),Color("cd7fa1"),Color("65a5b5"),Color("b2b482"),Color("9583b6"),Color("c6d0c2")]
var graph=AStar2D.new()
var nodes: Array[Vector2]=[]
var edges: Array[Vector2i]=[]
var people: Array[Dictionary]=[]
var vendors: Array[Dictionary]=[]
var motes: Array[Dictionary]=[]
var player=Vector2(750,645)*UNIT
var player_route=PackedVector2Array()
var player_dir=Vector2.DOWN
var walking=false
var clock=0.0
var paused=false
var cam: Camera2D
var target_zoom=.7
var follow=false
var dragging=false
var dragged=false
var press=Vector2.ZERO
var hud: Label
var objective: Label
var message: Label
var stats: Label
var hud_panel: PanelContainer
var bottom: PanelContainer
var dialogue: PanelContainer
var dialogue_title: Label
var dialogue_text: Label
var dialogue_action: Button
var bag_panel: PanelContainer
var bag_text: Label
var ui_hidden=false
var selected_vendor=-1
var pending_vendor=-1
var tokens=100
var stage=0
var inventory=["Resident ID — New Arrival", "Apartment key — 10C", "Subway pass"]
var lore_read={}
var ambience=false
var sound: AudioStreamPlayer
var synth: AudioStreamGeneratorPlayback
var sound_phase=0.0
var glow=true
var last_message="Your first shift. Find Piper at the newspaper stand."
var objective_text=["FIRST SHIFT  •  Find Piper's Press", "FIRST SHIFT  •  Deliver Piper's papers to Stella", "FIRST SHIFT  •  Take Stella's cake to Meepo & Harley", "FIRST SHIFT  •  Return the signed receipt to Piper", "SHIFT COMPLETE  •  Explore the market"]

func P(x:float,y:float)->Vector2: return Vector2(x,y)*UNIT

func _ready():
	seed(1985)
	var bg=Sprite2D.new()
	bg.texture=load("res://assets/tsfm-1985.png")
	bg.centered=false
	bg.scale=WORLD/Vector2(bg.texture.get_size())
	bg.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	bg.z_index=-10
	add_child(bg)
	# Streets and market aisles traced from the new plate; junctions share IDs.
	add_path([[210,429],[355,371],[548,312],[707,266],[800,227],[928,291],[1109,384],[1240,448],[1373,514],[1405,571],[1360,649],[1243,755],[1150,824],[1084,873],[970,925]])
	add_path([[210,429],[181,497],[214,585],[292,658],[353,719],[450,779],[540,837],[650,906],[768,978]])
	add_path([[292,658],[372,613],[441,557],[541,509],[644,451],[723,409],[887,362],[993,414],[1093,478],[1190,536],[1279,587],[1360,649]])
	add_path([[355,371],[364,421],[401,470],[441,557],[519,606],[634,574],[682,604],[750,645],[820,676],[933,658],[1049,595],[1103,552],[1190,536]])
	add_path([[548,312],[633,363],[723,409],[783,443],[850,479],[909,511],[966,559],[1049,595]])
	add_path([[800,227],[797,177],[816,135],[815,107]])
	add_path([[1373,514],[1450,489],[1536,450]])
	add_path([[210,429],[112,390],[13,340]])
	add_path([[353,719],[334,781],[421,837],[508,891],[606,954],[677,1024]])
	add_path([[1150,824],[1164,903],[1265,961],[1374,1019]])
	add_path([[993,414],[967,445]])
	add_path([[519,606],[467,651]])
	add_path([[1093,478],[1128,503]])
	add_path([[966,559],[1006,588]])
	add_path([[933,658],[984,690]])
	for i in range(nodes.size()):graph.add_point(i,nodes[i])
	for e in edges:graph.connect_points(e.x,e.y)
	# Named characters stay near their stalls and visibly idle / turn / pace.
	vendors=[
		{"name":"PIPER'S PRESS","character":"Piper","p":P(467,651),"kind":"dachshund","color":Color("a97e59")},
		{"name":"STELLA'S CAKES","character":"Stella","p":P(1006,588),"kind":"rottweiler","color":Color("d8ab67")},
		{"name":"MEEPO & HARLEY","character":"Meepo & Harley","p":P(984,690),"kind":"alien","color":Color("9bc597")},
		{"name":"TOKEN EXCHANGE","character":"Exchange clerk","p":P(967,445),"kind":"android","color":Color("94afbd")},
		{"name":"RESIDENT SERVICES","character":"Buddy-Bot","p":P(1128,503),"kind":"android","color":Color("beada2")},
		{"name":"PORTAL CHECKPOINT","character":"Market security","p":P(815,107),"kind":"android","color":Color("7eb9c4")}
	]
	for i in range(64):
		var k="human"
		if i%4==0:k="alien"
		if i%11==0:k="android"
		if i%17==0:k="rabbit"
		people.append({"p":nodes[i%nodes.size()],"route":PackedVector2Array(),"speed":randf_range(12,22),"wait":randf_range(0,4),"color":COLORS[i%6],"phase":randf()*TAU,"dir":Vector2.DOWN,"moving":false,"kind":k})
	for i in range(85):motes.append({"p":Vector2(randf()*WORLD.x,randf()*WORLD.y),"phase":randf()*TAU})
	cam=Camera2D.new()
	cam.position=P(790,530)
	cam.position_smoothing_enabled=false
	add_child(cam)
	cam.zoom=Vector2.ONE*.7
	make_ui()
	setup_audio()
	load_progress()
	get_viewport().size_changed.connect(layout_ui)
	layout_ui()
	constrain_camera()

func add_path(points:Array):
	var prev=-1
	for p in points:
		var v=P(p[0],p[1])
		var idx=nodes.find(v)
		if idx<0:
			idx=nodes.size()
			nodes.append(v)
		if prev>=0:edges.append(Vector2i(prev,idx))
		prev=idx

func panel_style()->StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=Color(.035,.06,.095,.92)
	s.border_color=Color(.44,.52,.57,.55)
	s.set_border_width_all(1)
	s.set_corner_radius_all(5)
	s.content_margin_left=14
	s.content_margin_right=14
	s.content_margin_top=10
	s.content_margin_bottom=10
	return s

func new_panel(layer:Node)->PanelContainer:
	var p=PanelContainer.new()
	p.add_theme_stylebox_override("panel",panel_style())
	layer.add_child(p)
	return p

func label(text:String,size:int=14,color:Color=Color("d2dad7"))->Label:
	var l=Label.new()
	l.text=text
	l.add_theme_font_size_override("font_size",size)
	l.modulate=color
	return l

func button(row:Node,caption:String,action:Callable)->Button:
	var b=Button.new()
	b.text=caption
	b.add_theme_font_size_override("font_size",13)
	b.pressed.connect(action)
	row.add_child(b)
	return b

func make_ui():
	var layer=CanvasLayer.new()
	add_child(layer)
	hud_panel=new_panel(layer)
	hud_panel.position=Vector2(12,12)
	var box=VBoxContainer.new()
	hud_panel.add_child(box)
	hud=label("THE STRANGEST FLEA MARKET",19,Color("edb879"))
	box.add_child(hud)
	stats=label("",12,Color("9baec0"));box.add_child(stats)
	objective=label("",13,Color("adccbc"));box.add_child(objective)
	var row=HBoxContainer.new();box.add_child(row)
	button(row,"−",func():zoom_by(.8))
	button(row,"+",func():zoom_by(1.25))
	button(row,"0.7×",fit_map)
	button(row,"Follow",func():follow=not follow)
	button(row,"Bag [I]",toggle_bag)
	button(row,"Sound",func():ambience=not ambience)
	button(row,"⛶",toggle_fullscreen)
	button(row,"Hide [H]",toggle_ui)
	bottom=new_panel(layer)
	message=label("",13)
	bottom.add_child(message)
	dialogue=new_panel(layer)
	var col=VBoxContainer.new();col.add_theme_constant_override("separation",12);dialogue.add_child(col)
	dialogue_title=label("",20,Color("efbf87"));col.add_child(dialogue_title)
	dialogue_text=label("",16);dialogue_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;dialogue_text.custom_minimum_size=Vector2(0,150);col.add_child(dialogue_text)
	var actions=HBoxContainer.new();col.add_child(actions)
	dialogue_action=button(actions,"Continue",perform_action)
	button(actions,"Close [Esc]",func():dialogue.hide();selected_vendor=-1)
	dialogue.hide()
	bag_panel=new_panel(layer)
	var bagcol=VBoxContainer.new();bag_panel.add_child(bagcol)
	bag_text=label("",16);bagcol.add_child(bag_text)
	button(bagcol,"Close",func():bag_panel.hide())
	bag_panel.hide()

func layout_ui():
	var view=get_viewport_rect().size
	bottom.position=Vector2(12,view.y-67)
	dialogue.size=Vector2(min(560,view.x-32),0)
	dialogue.position=Vector2((view.x-dialogue.size.x)/2,view.y*.46)
	bag_panel.position=Vector2(max(12,view.x-330),170)

func fit_map():
	follow=false
	target_zoom=.7
	cam.position=P(790,530)

func minimum_zoom()->float:
	var v=get_viewport_rect().size
	return max(v.x/WORLD.x,v.y/WORLD.y)

func zoom_by(factor:float):target_zoom=clamp(target_zoom*factor,minimum_zoom(),5.6)

func constrain_camera():
	target_zoom=max(target_zoom,minimum_zoom())
	cam.zoom=Vector2.ONE*max(cam.zoom.x,minimum_zoom())
	var half=get_viewport_rect().size/(cam.zoom*2)
	cam.position=cam.position.clamp(half,WORLD-half)

func toggle_fullscreen():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func toggle_ui():
	ui_hidden=not ui_hidden
	hud_panel.visible=not ui_hidden
	bottom.visible=not ui_hidden

func toggle_bag():
	bag_text.text="RESIDENT WALLET\n\n%d market tokens\n\n%s\n\nGoods stay inside NYC." % [tokens,"\n".join(inventory)]
	bag_panel.visible=not bag_panel.visible

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:zoom_by(1.2)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:zoom_by(1/1.2)
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				press=event.position;dragged=false;dragging=true
			else:
				dragging=false
				if not dragged and not dialogue.visible:
					var point=get_global_mouse_position()
					var near=closest_vendor(point)
					if point.distance_to(vendors[near].p)<55:
						pending_vendor=near
						walk_to(vendors[near].p)
					else:
						pending_vendor=-1
						walk_to(point)
	if event is InputEventMouseMotion and dragging:
		if event.position.distance_to(press)>5:dragged=true
		if dragged:
			follow=false
			cam.position-=event.relative/cam.zoom
			constrain_camera()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_SPACE:paused=not paused
		if event.keycode==KEY_HOME:fit_map()
		if event.keycode==KEY_F:follow=not follow
		if event.keycode==KEY_H:toggle_ui()
		if event.keycode==KEY_I:toggle_bag()
		if event.keycode==KEY_E:interact()
		if event.keycode==KEY_ESCAPE:
			dialogue.hide();bag_panel.hide();selected_vendor=-1

func closest_vendor(p:Vector2)->int:
	var idx=0
	for i in range(vendors.size()):
		if p.distance_to(vendors[i].p)<p.distance_to(vendors[idx].p):idx=i
	return idx

func nearest_path(p:Vector2)->Vector2:
	var best=Vector2.ZERO
	var distance=INF
	for e in edges:
		var q=Geometry2D.get_closest_point_to_segment(p,nodes[e.x],nodes[e.y])
		if p.distance_squared_to(q)<distance:distance=p.distance_squared_to(q);best=q
	return best

func walk_to(p:Vector2):
	var dest=nearest_path(p)
	if p.distance_to(dest)>65:
		last_message="Use the streets and market aisles. Click a named vendor to visit."
		return
	player_route=graph.get_point_path(graph.get_closest_point(player),graph.get_closest_point(dest))
	if not player_route.is_empty():player_route.append(dest)

func interact():
	var i=closest_vendor(player)
	if player.distance_to(vendors[i].p)<65:show_dialogue(i)
	else:last_message="Walk up to a named vendor, then press E."

func show_dialogue(i:int):
	selected_vendor=i
	pending_vendor=-1
	player_route.clear()
	dialogue_title.text=vendors[i].character+"  /  "+vendors[i].name
	var text=""
	var action=""
	match i:
		0:
			if stage==0:
				text="Piper, the little dachshund behind PIPER'S PRESS, taps a stack of newspapers.\n\n‘First day? Then here's your first shift. Take these to Stella. Everyone works if they want to live here.’\n\nThe headline: EARTH STILL ON PROBATION."
				action="Accept delivery shift"
			elif stage==3:
				text="‘A signed receipt! You're already more reliable than half the galaxy.’\n\nPiper counts out 25 market tokens. ‘Keep the subway pass handy. And remember: the market's goods stay in New York.’"
				action="Hand over receipt · Earn 25 tokens"
			else:text="‘June 19, 1984. One Earth communications satellite, one very unexpected invitation. Now look at us: New York, 1985, hosting an interstellar flea market.\n\nI print the news. I do not explain the weather inside jar number six.’"
		1:
			if stage==1:
				text="Stella, a Rottweiler in a rain suit, shelters a cake beneath her awning.\n\n‘Piper's papers! Put them somewhere dry. Could you take this cake to Meepo and Harley? Their stall is just down the aisle.’"
				action="Deliver papers · Take cake"
			else:
				text="‘A slice is five tokens. Earth dollars won't help you here, sweetheart. Try the Exchange Center.\n\nAnd don't lean on that cake. It's having a difficult afternoon.’"
				action="Buy cake slice · 5 tokens"
		2:
			if stage==2:
				text="Meepo and Harley lean over the counter of trinkets and potions.\n\n‘Stella sent cake? Good. The jar was beginning to bargain for it.’\n\nHarley signs your delivery receipt. ‘Back to Piper. Your first shift is nearly done.’"
				action="Deliver cake · Collect receipt"
			else:text="‘Trinkets and potions. Nothing invasive, toxic, stolen, or designed to start a planetary argument.\n\nBarter is welcome. That little bottle? It's empty. We're selling the story of what used to be inside.’"
		3:
			text="EXCHANGE CENTER\n\nEarth currency cannot be spent at the market. Exchanges turn accepted value into market tokens; vendors can also barter.\n\nSeeds, water, compounds, gems, cultural creations: value comes from what another world needs.\n\nYou have %d tokens. Your resident wallet is already active." % tokens
		4:
			text="Buddy-Bot checks your resident ID.\n\n‘Assignment: apartment 10C. Starting balance: 100 tokens. Work is a condition of residence. Vendors, guides, drivers, cleaners and security all keep the market running.\n\nNonhuman visitors must remain within New York City. Market goods must remain here, too. Have a productive evening.’"
		5:
			text="EARTH: PROBATIONARY HOST\n\n‘Humans may not use these portals to visit other markets. Your subway pass is valid for a considerably shorter journey.’\n\nAn android watches the arch. Bird sentinels survey the rooftops. Theft means banishment. Lethal weapons are prohibited.\n\nBeyond the checkpoint, the portal keeps glowing."
	lore_read[str(i)]=true
	dialogue_text.text=text
	dialogue_action.text=action
	dialogue_action.visible=not action.is_empty()
	dialogue.show()
	layout_ui()
	save_progress()

func perform_action():
	match selected_vendor:
		0:
			if stage==0:stage=1;inventory.append("Piper's newspaper bundle");last_message="Take the papers to Stella's cake stand."
			elif stage==3:stage=4;inventory.erase("Signed delivery receipt");tokens+=25;last_message="First shift complete. 25 tokens earned. Welcome to the market."
		1:
			if stage==1:stage=2;inventory.erase("Piper's newspaper bundle");inventory.append("Stella's cake delivery");last_message="Deliver the cake to Meepo & Harley."
			elif tokens>=5:tokens-=5;inventory.append("Stella's cake slice");last_message="Cake acquired. Somehow still warm."
			else:last_message="You need five market tokens."
		2:
			if stage==2:stage=3;inventory.erase("Stella's cake delivery");inventory.append("Signed delivery receipt");last_message="Bring the receipt back to Piper for your pay."
	dialogue.hide();selected_vendor=-1
	save_progress()

func save_progress():
	var f=FileAccess.open("user://tsfm-resident.json",FileAccess.WRITE)
	if f:f.store_string(JSON.stringify({"tokens":tokens,"stage":stage,"inventory":inventory,"lore":lore_read}))

func load_progress():
	if not FileAccess.file_exists("user://tsfm-resident.json"):return
	var data=JSON.parse_string(FileAccess.get_file_as_string("user://tsfm-resident.json"))
	if data is Dictionary:
		tokens=max(0,int(data.get("tokens",100)))
		stage=clamp(int(data.get("stage",0)),0,4)
		if data.get("inventory") is Array:inventory=data.inventory
		if data.get("lore") is Dictionary:lore_read=data.lore

func _process(delta):
	cam.zoom=cam.zoom.lerp(Vector2.ONE*target_zoom,1-exp(-delta*10))
	if follow:cam.position=cam.position.lerp(player,1-exp(-delta*6))
	constrain_camera()
	fill_audio()
	walking=false
	if not paused:
		clock+=delta
		var input=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		if dialogue.visible or bag_panel.visible:input=Vector2.ZERO
		if input.length()>0:
			player_route.clear();pending_vendor=-1
			var candidate=player+input.normalized()*65*delta
			if candidate.distance_to(nearest_path(candidate))<17:player=candidate;walking=true;player_dir=input
		elif not player_route.is_empty() and not dialogue.visible:
			var diff=player_route[0]-player
			if diff.length()<1:player_route.remove_at(0)
			else:player_dir=diff.normalized();player=player.move_toward(player_route[0],delta*62);walking=true
		if pending_vendor>=0 and player.distance_to(vendors[pending_vendor].p)<28:show_dialogue(pending_vendor)
		for person in people:
			person.moving=false
			if person.wait>0:person.wait-=delta
			elif person.route.is_empty():person.route=graph.get_point_path(graph.get_closest_point(person.p),randi()%nodes.size())
			else:
				var diff=person.route[0]-person.p
				if diff.length()<.5:
					person.route.remove_at(0)
					if person.route.is_empty():person.wait=randf_range(.5,5)
				else:person.dir=diff.normalized();person.p=person.p.move_toward(person.route[0],person.speed*delta);person.moving=true
	stats.text="NYC · 1985    /    %d TOKENS    /    %.1f×    /    %s" % [tokens,cam.zoom.x,"PAUSED" if paused else "64 RESIDENTS"]
	objective.text=objective_text[stage]
	var near=closest_vendor(player)
	var hint="  [E] "+vendors[near].character if player.distance_to(vendors[near].p)<65 else ""
	message.text=last_message+hint+"\nClick: walk / visit  ·  Drag: pan  ·  Wheel: zoom  ·  WASD: move  ·  E: talk  ·  H: hide UI"
	queue_redraw()

func _draw():
	# Separate residents and vendors sorted by foot position.
	var actors=people.duplicate()
	for i in range(vendors.size()):
		var v=vendors[i]
		var offset=Vector2(sin(clock*.55+i)*4,cos(clock*.4+i)*2)
		actors.append({"p":v.p+offset,"dir":Vector2(sin(clock*.4+i),1),"color":v.color,"phase":float(i),"moving":true,"kind":v.kind})
		if i==2:actors.append({"p":v.p+Vector2(22,5)+offset,"dir":Vector2(-1,1),"color":Color("b998bf"),"phase":2.2,"moving":true,"kind":"alien"})
	actors.append({"p":player,"dir":player_dir,"color":Color("da9d67"),"phase":0.0,"moving":walking,"kind":"human","player":true})
	actors.sort_custom(func(a,b):return a.p.y<b.p.y)
	for a in actors:draw_person(a)
	for i in range(vendors.size()):
		var v=vendors[i]
		var p:Vector2=v.p+Vector2(0,-40)
		var important=(i==0 and (stage==0 or stage==3)) or (i==1 and stage==1) or (i==2 and stage==2)
		var color=Color("f3c980") if important else Color("b8cdd2")
		var font=ThemeDB.fallback_font
		var text:String=v.name
		var width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		draw_rect(Rect2(p-Vector2(width/2+7,16),Vector2(width+14,23)),Color(.035,.065,.095,.9))
		draw_string(font,p-Vector2(width/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)
		if important:draw_colored_polygon(PackedVector2Array([p+Vector2(-4,11),p+Vector2(4,11),p+Vector2(0,18)]),color)
	# Rooftop bird sentinels: they remain at their posts, scanning the street.
	for i in range(9):
		var spots=[P(352,152),P(492,167),P(175,154),P(1110,133),P(1290,203),P(1407,252),P(543,753),P(748,786),P(947,806)]
		var p:Vector2=spots[i]
		var d=1 if sin(clock*.5+i)>0 else -1
		draw_circle(p,3,Color("26333d"))
		draw_line(p,p+Vector2(d*5,-3),Color("26333d"),3)
		draw_circle(p+Vector2(d*6,-4),.8,Color("c5f0e2"))
	# Rooftop steam and subway vents, generated in small translucent pixels.
	for source in [P(206,93),P(1229,81),P(713,716),P(152,295),P(1413,617)]:
		for j in range(8):
			var t=fposmod(clock*.35+j*.14,1.0)
			var p=source+Vector2(sin(t*5+source.x)*8,-t*60)
			draw_rect(Rect2(p,Vector2(8+t*16,5+t*9)),Color(.62,.68,.73,(1-t)*.07))
	if glow:
		var portal=P(817,82)
		for i in range(25):
			var angle=clock*.4+i*TAU/25
			var p=portal+Vector2(cos(angle)*31,sin(angle)*44)
			draw_rect(Rect2(p,Vector2(2,2)),Color(.37,.97,.96,.3+.3*sin(clock*2+i)))
		for m in motes:
			var p:Vector2=m.p+Vector2(sin(clock*.3+m.phase)*8,cos(clock*.2+m.phase)*6)
			draw_rect(Rect2(p,Vector2(1.5,1.5)),Color(.71,.74,.77,.12))

func draw_person(a:Dictionary):
	var p:Vector2=a.p.round()
	var phase:float=clock*7+a.phase
	var stride:float=round(sin(phase)*2) if a.moving else 0.0
	var bob:float=round(abs(sin(phase))*.8) if a.moving else 0.0
	var coat:Color=a.color
	var side:float=sign(a.dir.x)
	draw_set_transform(p)
	draw_rect(Rect2(-6,-1,12,3),Color(.01,.02,.05,.36))
	if a.has("player"):
		draw_arc(Vector2.ZERO,9,0,TAU,24,Color(.98,.79,.45,.9),1)
		draw_colored_polygon(PackedVector2Array([Vector2(-4,-36),Vector2(4,-36),Vector2(0,-30)]),Color("f4cb7f"))
	if a.kind=="dachshund" or a.kind=="rottweiler":
		var fur=Color("805536") if a.kind=="dachshund" else Color("37313b")
		var width=19.0 if a.kind=="dachshund" else 15.0
		draw_rect(Rect2(-width/2,-12-bob,width,8),fur)
		for x in [-7,5]:draw_rect(Rect2(x,-5,3,5+stride*.4),fur)
		draw_rect(Rect2(5,-19-bob,8,10),fur)
		draw_rect(Rect2(11,-15-bob,6,4),Color("bb855b"))
		draw_rect(Rect2(6,-17-bob,3,10),fur.darkened(.3))
		draw_rect(Rect2(11,-18-bob,1.6,1.6),Color("eadbc5"))
		draw_line(Vector2(-width/2,-9),Vector2(-width/2-5,-14+sin(clock*5)*3),fur,2)
		if a.kind=="rottweiler":
			draw_rect(Rect2(-7,-14-bob,13,9),Color("d7a966"))
			draw_rect(Rect2(4,-21-bob,10,3),Color("d7a966"))
	else:
		draw_rect(Rect2(-4,-7+stride,3,7-stride),Color("394454"))
		draw_rect(Rect2(1,-7-stride,3,7+stride),Color("394454"))
		draw_rect(Rect2(-5,-1+stride,4,2),Color("988d8c"))
		draw_rect(Rect2(1,-1-stride,4,2),Color("988d8c"))
		draw_rect(Rect2(-5,-18-bob,10,11),coat.darkened(.18))
		draw_rect(Rect2(-3,-18-bob,6,10),coat)
		var skin=Color("d2a186")
		if a.kind=="alien":skin=coat.lightened(.18)
		if a.kind=="android":skin=Color("92aeb6")
		if a.kind=="rabbit":skin=Color("dfd7c8")
		draw_rect(Rect2(-7,-16-bob+stride*.4,2,7),skin)
		draw_rect(Rect2(5,-16-bob-stride*.4,2,7),skin)
		draw_rect(Rect2(-4,-26-bob,8,8),skin)
		if a.kind=="human":
			draw_rect(Rect2(-4,-28-bob,8,4),Color("413343"))
			if a.dir.y<-.2:draw_rect(Rect2(-4,-25-bob,8,5),Color("413343"))
			else:draw_rect(Rect2(side*2,-22-bob,1,1),Color("293542"))
		elif a.kind=="alien":
			draw_rect(Rect2(-6,-27-bob,12,5),skin)
			draw_rect(Rect2(-4,-23-bob,3,2),Color("253348"))
			draw_rect(Rect2(2,-23-bob,3,2),Color("253348"))
			draw_line(Vector2(-4,-27-bob),Vector2(-6,-32-bob),skin,1)
		elif a.kind=="android":
			draw_rect(Rect2(-3,-23-bob,6,2),Color("83ece4"))
			draw_rect(Rect2(-2,-16-bob,4,3),Color("83ece4"))
		else:
			draw_rect(Rect2(-4,-36-bob,3,11),skin)
			draw_rect(Rect2(2,-35-bob,3,10),skin)
			draw_rect(Rect2(1,-23-bob,2,2),Color("443645"))
	draw_set_transform(Vector2.ZERO)

func setup_audio():
	sound=AudioStreamPlayer.new()
	var generator=AudioStreamGenerator.new()
	generator.mix_rate=22050;generator.buffer_length=.15
	sound.stream=generator;sound.volume_db=-24
	add_child(sound);sound.play();synth=sound.get_stream_playback()

func fill_audio():
	if synth==null:return
	for i in range(synth.get_frames_available()):
		sound_phase+=1.0/22050
		var rumble=sin(sound_phase*48*TAU)*.08+randf_range(-.025,.025)
		var distant=sin(sound_phase*330*TAU)*pow(max(0,sin(sound_phase*.16)),32)*.1
		var sample=(rumble+distant) if ambience and not paused else 0.0
		synth.push_frame(Vector2.ONE*sample)

func _exit_tree():
	if sound:sound.stop()
	synth=null
