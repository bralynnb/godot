extends Node3D

var camera: Camera3D
var firelight: OmniLight3D
var daylight: DirectionalLight3D
var flames: Array[MeshInstance3D] = []
var sparks: Array[MeshInstance3D] = []
var target := Vector3(0, 1.15, 0)
var yaw := 0.70
var pitch := 0.60
var zoom := 9.0
var clock := 0.0
var fire_on := true
var night := false
var mats: Dictionary = {}
var rng := RandomNumberGenerator.new()
var touch_points: Dictionary = {}

func mat(hex: String, emission: float = 0.0) -> StandardMaterial3D:
	var key := hex + str(emission)
	if mats.has(key): return mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.88
	if emission > 0:
		m.emission_enabled = true
		m.emission = Color(hex)
		m.emission_energy_multiplier = emission
	mats[key] = m
	return m

func block(p: Vector3, s: Vector3, color: String, parent: Node3D = self, emission: float = 0.0) -> MeshInstance3D:
	var b := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = s
	b.mesh = mesh
	b.material_override = mat(color, emission)
	parent.add_child(b)
	b.position = p
	return b

func _ready() -> void:
	rng.seed = 84
	build_room()
	build_fire()
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("211c19")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("b5c0d1")
	e.ambient_light_energy = 0.40
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	daylight = DirectionalLight3D.new()
	daylight.rotation_degrees = Vector3(-48, -32, 0)
	daylight.light_color = Color("ffe2af")
	daylight.light_energy = 1.7
	daylight.shadow_enabled = true
	daylight.directional_shadow_max_distance = 24
	add_child(daylight)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.6, 2.7, -0.4)
	fill.light_color = Color("cadced")
	fill.light_energy = 1.5
	fill.omni_range = 6
	add_child(fill)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	camera.far = 60
	add_child(camera)
	build_ui()
	update_camera()

func build_room() -> void:
	block(Vector3(0,-0.16,0),Vector3(6.6,0.3,6.3),"332319")
	for row in range(15):
		for col in range(4):
			var x := -2.43 + col * 1.63
			var z := -2.9 + row * 0.415
			block(Vector3(x,0.015,z),Vector3(1.61,0.10,0.397),["795030","8f6039","a37244","98673d"][rng.randi_range(0,3)])
	block(Vector3(0,2.1,-3.1),Vector3(6.6,4.25,0.18),"bba58b")
	# Open left wall window, made of real geometry.
	block(Vector3(-3.25,0.64,0),Vector3(0.18,1.4,6.3),"bba58b")
	block(Vector3(-3.25,3.91,0),Vector3(0.18,0.6,6.3),"bba58b")
	block(Vector3(-3.25,2.45,-2.70),Vector3(0.18,2.2,0.8),"bba58b")
	block(Vector3(-3.25,2.45,2.15),Vector3(0.18,2.2,1.9),"bba58b")
	block(Vector3(-3.21,2.5,-0.72),Vector3(0.055,2.25,3.18),"b8d2db",self,0.25)
	for z in [-2.30,-1.50,-0.70,0.10,0.90]:
		block(Vector3(-3.1,2.5,z),Vector3(0.12,2.36,0.055),"e3dac9")
	for y in [1.32,1.91,2.50,3.09,3.68]:
		block(Vector3(-3.1,y,-0.70),Vector3(0.13,0.055,3.3),"e3dac9")
	block(Vector3(-2.98,1.28,-0.7),Vector3(0.57,0.14,3.55),"d0bda0")
	block(Vector3(0,0.20,-2.96),Vector3(6.4,0.27,0.12),"66462e")
	block(Vector3(-3.11,0.20,0),Vector3(0.12,0.27,6.1),"66462e")
	# Fireplace: recessed black hearth, two pillars and stepped chimney.
	block(Vector3(0.75,0.15,-2.24),Vector3(2.30,0.26,1.35),"38281f")
	block(Vector3(0.75,0.9,-2.93),Vector3(1.65,1.5,0.12),"261b15")
	for x in [-0.19,1.69]:
		block(Vector3(x,0.92,-2.38),Vector3(0.42,1.6,0.90),"a94719")
	block(Vector3(0.75,1.72,-2.38),Vector3(2.3,0.35,1.03),"b65722")
	block(Vector3(0.75,2.02,-2.44),Vector3(1.99,0.26,0.90),"c06a2b")
	block(Vector3(0.75,2.26,-2.50),Vector3(1.61,0.24,0.77),"b95a22")
	block(Vector3(0.75,3.28,-2.66),Vector3(0.92,1.82,0.57),"b25a26")
	for i in range(17):
		block(Vector3(0.75+rng.randf_range(-0.31,0.31),2.45+i*0.1,-2.364),Vector3(0.25,0.09,0.016),["bd6629","a24c20","cc7730"][i%3])
	bookshelf(Vector3(-1.78,0,-2.60),1.22,2.36)
	bookshelf(Vector3(2.64,0,-2.60),1.02,1.62)
	wall_shelf(Vector3(-1.75,3.48,-2.82),1.32)
	wall_shelf(Vector3(2.53,3.11,-2.82),1.18)
	# Chairs and sofa surround the woven rug.
	chair(Vector3(-2.04,0,-0.56),0.18,"ae592c",false)
	chair(Vector3(2.10,0,1.54),-0.65,"573723",false)
	chair(Vector3(-0.7,0,2.10),PI,"9a742c",true)
	block(Vector3(0,0.086,0.43),Vector3(3.70,0.045,2.63),"be995c")
	block(Vector3(0,0.114,0.43),Vector3(3.35,0.02,2.29),"683e32")
	for i in range(9):
		var z := -0.51+i*0.235
		var w := 2.62-absf(i-4)*0.31
		block(Vector3(0,0.131,z),Vector3(w,0.017,0.18),["a15b3d","d5b779","8b4534"][i%3])
	for i in range(16):
		for z in [-0.98,1.84]:
			block(Vector3(-1.68+i*0.22,0.089,z),Vector3(0.065,0.028,0.20),"c2a16c")
	table(Vector3(-1.45,0,-1.6))
	table(Vector3(0.90,0,2.51))
	plant(Vector3(-2.91,1.37,-1.90),0.72)
	plant(Vector3(-2.91,1.37,-0.72),0.50)
	plant(Vector3(-2.91,1.37,0.49),0.66)
	plant(Vector3(-2.61,0.08,1.02),1.20)

func bookshelf(p: Vector3, w: float, h: float) -> void:
	block(p+Vector3(0,h/2,0),Vector3(w,h,0.13),"5b3b22")
	for x in [-w/2,w/2]:
		block(p+Vector3(x,h/2,0.22),Vector3(0.12,h,0.57),"9a642d")
	for y in [0.14,h*0.36,h*0.68,h]:
		block(p+Vector3(0,y,0.22),Vector3(w+0.18,0.13,0.65),"ac7738")
	for level in range(3):
		var y := 0.22+level*h*0.32
		for i in range(5):
			var bh := rng.randf_range(0.28,h*0.26)
			var b := block(p+Vector3(-w*0.37+i*w*0.18,y+bh/2,0.22),Vector3(w*0.12,bh,0.32),["526b54","a56141","c0a16c","536978","743d32"][i])
			if i == 3: b.rotation.z = 0.1
	for i in range(3):
		block(p+Vector3(0.13,h+0.13+i*0.075,0.2),Vector3(0.43,0.065,0.31),["6f3c2b","bcad7c","596a5a"][i])

func wall_shelf(p: Vector3,w: float) -> void:
	block(p,Vector3(w,0.66,0.14),"543520")
	for x in [-w/2,w/2]: block(p+Vector3(x,0,0.17),Vector3(0.11,0.66,0.46),"57371f")
	for y in [-0.30,0.30]: block(p+Vector3(0,y,0.17),Vector3(w,0.11,0.46),"644226")
	for i in range(5):
		var b := block(p+Vector3(-w*0.35+i*w*0.17,-0.025,0.19),Vector3(0.12,0.42,0.22),["9b593c","607b69","c4b483","667787","ae7e4b"][i])
		b.rotation.z = (i%2)*0.13

func chair(p: Vector3,angle: float,col: String,sofa: bool) -> void:
	var root := Node3D.new()
	add_child(root)
	root.position = p
	root.rotation.y = angle
	var w := 2.48 if sofa else 1.22
	block(Vector3(0,0.40,0),Vector3(w,0.43,1.18),col,root)
	block(Vector3(0,0.69,-0.06),Vector3(w-0.22,0.24,0.96),"c9a66d",root)
	block(Vector3(0,1.10,-0.52),Vector3(w,0.94,0.24),col,root)
	block(Vector3(0,1.14,-0.35),Vector3(w-0.20,0.65,0.22),"cfaf79",root)
	for x in [-w/2,w/2]:
		block(Vector3(x,0.84,0.06),Vector3(0.23,0.45,1.22),col,root)
		for z in [-0.43,0.43]: block(Vector3(x*0.87,0.16,z),Vector3(0.15,0.3,0.15),"4b3020",root)
	var cushion := block(Vector3(-w*0.19,0.99,-0.14),Vector3(0.54,0.47,0.18),"e4c58a",root)
	cushion.rotation.z = -0.13
	cushion.rotation.x = -0.16

func table(p: Vector3) -> void:
	block(p+Vector3(0,0.73,0),Vector3(0.60,0.13,0.59),"8b592e")
	for x in [-0.22,0.22]:
		for z in [-0.22,0.22]: block(p+Vector3(x,0.37,z),Vector3(0.09,0.67,0.09),"79502c")
	block(p+Vector3(0,0.85,0),Vector3(0.22,0.13,0.22),"57442d")
	block(p+Vector3(0,1.05,0),Vector3(0.09,0.32,0.09),"d8cba7")
	block(p+Vector3(0,1.23,0),Vector3(0.055,0.095,0.055),"ffc66b",self,2.0)

func plant(p: Vector3,s: float) -> void:
	block(p+Vector3(0,0.17*s,0),Vector3(0.40,0.33,0.40)*s,"a35736")
	block(p+Vector3(0,0.33*s,0),Vector3(0.46,0.1,0.46)*s,"bb7348")
	block(p+Vector3(0,0.39*s,0),Vector3(0.33,0.05,0.33)*s,"3c3323")
	for i in range(19):
		var pos := Vector3(rng.randf_range(-0.29,0.29),rng.randf_range(0.45,0.99),rng.randf_range(-0.23,0.23))*s
		block(p+pos,Vector3(0.22,0.23,0.22)*s,["546e35","758847","435930","8b9854"][i%4])

func build_fire() -> void:
	for i in range(4):
		var log_mesh := block(Vector3(0.41+i*0.22,0.38,-2.34),Vector3(0.18,0.20,0.71),"49301f")
		log_mesh.rotation.y = -0.30+i*0.20
		block(Vector3(0.41+i*0.22,0.39,-1.99),Vector3(0.135,0.14,0.035),"c36b28",self,0.8)
	for i in range(28):
		var b := block(Vector3.ZERO,Vector3(0.13,0.25,0.13),["ff7e18","ffad22","ffe274","fff2bb"][i%4],self,2.2)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flames.append(b)
	for i in range(14):
		var b := block(Vector3.ZERO,Vector3.ONE*0.023,"ffb54d",self,2.0)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sparks.append(b)
	firelight = OmniLight3D.new()
	firelight.position = Vector3(0.75,0.95,-1.95)
	firelight.light_color = Color("ff9f43")
	firelight.light_energy = 5.5
	firelight.omni_range = 6.0
	firelight.omni_attenuation = 1.2
	firelight.shadow_enabled = true
	firelight.shadow_bias = 0.05
	add_child(firelight)

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = "F I R E S I D E"
	title.position = Vector2(28,22)
	title.add_theme_font_size_override("font_size",23)
	layer.add_child(title)
	var hint := Label.new()
	hint.text = "Drag to orbit  ·  Right-drag / Shift-drag to pan  ·  Scroll to zoom"
	hint.position = Vector2(28,57)
	hint.add_theme_font_size_override("font_size",14)
	hint.modulate = Color("d2bda6")
	layer.add_child(hint)
	var bar := HBoxContainer.new()
	bar.position = Vector2(28,89)
	bar.add_theme_constant_override("separation",10)
	layer.add_child(bar)
	for item in ["Reset view", "Day / Night", "Fire on / off", "Fullscreen"]:
		var button := Button.new()
		button.text = item
		button.custom_minimum_size.y = 34
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func():
			match item:
				"Reset view":
					yaw = 0.70
					pitch = 0.60
					zoom = 9.0
					target = Vector3(0,1.15,0)
				"Day / Night":
					night = not night
					daylight.light_energy = 0.18 if night else 1.7
				"Fire on / off": fire_on = not fire_on
				"Fullscreen":
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		)
		bar.add_child(button)

func update_camera() -> void:
	camera.size = zoom
	camera.position = target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*14
	camera.look_at(target)

func pan(relative: Vector2) -> void:
	var speed := zoom / maxf(get_viewport().get_visible_rect().size.y,1.0)
	target += (-camera.global_basis.x*relative.x+camera.global_basis.y*relative.y)*speed
	target.x = clampf(target.x,-3,3)
	target.y = clampf(target.y,-0.3,3)
	target.z = clampf(target.z,-3,3)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_RIGHT or (event.button_mask & MOUSE_BUTTON_MASK_LEFT and event.shift_pressed):
			pan(event.relative)
		elif event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			yaw -= event.relative.x*0.006
			pitch = clampf(pitch+event.relative.y*0.005,0.12,1.38)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom = maxf(4.3,zoom-0.45)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom = minf(14,zoom+0.45)
	if event is InputEventScreenTouch:
		if event.pressed: touch_points[event.index] = event.position
		else: touch_points.erase(event.index)
	if event is InputEventScreenDrag:
		if touch_points.size() == 2:
			var old := touch_points.values()
			var old_dist: float = old[0].distance_to(old[1])
			touch_points[event.index] = event.position
			var updated := touch_points.values()
			var new_dist: float = updated[0].distance_to(updated[1])
			zoom = clampf(zoom-(new_dist-old_dist)*0.015,4.3,14)
			pan(event.relative*0.5)
		else:
			yaw -= event.relative.x*0.006
			pitch = clampf(pitch+event.relative.y*0.005,0.12,1.38)
			touch_points[event.index] = event.position
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _process(delta: float) -> void:
	clock += delta
	for i in range(flames.size()):
		var f := flames[i]
		f.visible = fire_on
		var life := fmod(clock*(0.57+(i%5)*0.07)+i*0.137,1.0)
		var spread := (1.0-life)*0.30
		f.position = Vector3(0.75+sin(i*4.2+clock*2)*spread,0.43+life*0.81,-2.31+cos(i*2.7)*0.17)
		f.scale = Vector3.ONE*(1.0-life)*1.45+Vector3(0.1,0.1,0.1)
		f.scale.y *= 1.3+sin(clock*7+i)*0.35
	for i in range(sparks.size()):
		var life := fmod(clock*0.3+i*0.17,1.0)
		sparks[i].visible = fire_on and life < 0.80
		sparks[i].position = Vector3(0.75+sin(i+clock)*life*0.23,0.60+life*1.5,-2.3+cos(i)*0.16)
		sparks[i].scale = Vector3.ONE*(1-life)
	firelight.light_energy = (5.4+sin(clock*12)*0.39+sin(clock*19.7)*0.23) if fire_on else 0.0
	update_camera()
