extends Node2D

const SPEED := 155.0
const ROOM_NAMES := ["THE ENTRY VAULT", "THE STILL CISTERN", "THE MOON CHAMBER"]
const ATLAS = preload("res://assets/walker.png")
const LIGHT = preload("res://assets/light.png")
var lighting_enabled := true
var reflections_enabled := true
var halo: PointLight2D
var room_material: CanvasTexture
var room := 0
var player: CharacterBody2D
var actor: Node2D
var sorter: Node2D
var camera: Camera2D
var zoom_target := 1.0
var overview := false
var pillars: Array[Sprite2D] = []
var physical_lights: Array[Vector2] = []
var shadow_sources: Array[Vector3] = []
var pillar_positions: Array[Vector2] = []
var footstep: AudioStreamPlayer
var step_distance := 0.0
var sprite: Sprite2D
var scenery: Node2D
var lights: Array[PointLight2D] = []
var flames: Array[Vector2] = []
var clock := 0.0
var walk_frame := 0.0
var moving := false
var transitioning := false
var started := false
var paused := false
var muted := false
var visited := [true, false, false]
var hud: Label
var hint: Label
var curtain: ColorRect
var intro: Label
var ambience: AudioStreamPlayer
var overlay: Node2D
var stick_origin := Vector2.ZERO
var stick_vector := Vector2.ZERO
var finger := -1

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for action in ["left", "right", "up", "down"]:
		InputMap.add_action(action)
	var bindings := {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN]}
	for action in bindings:
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	scenery = Node2D.new()
	scenery.show_behind_parent = true
	add_child(scenery)
	var ambient := CanvasModulate.new()
	ambient.color = Color(0.29, 0.34, 0.44)
	add_child(ambient)
	player = CharacterBody2D.new()
	player.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13
	shape.shape = circle
	player.add_child(shape)
	add_child(player)
	player.position = Vector2(235, 315)
	sprite = Sprite2D.new()
	sprite.texture = ATLAS
	sprite.hframes = 64
	sprite.vframes = 6
	sprite.position.y = -40
	sprite.scale = Vector2(0.64, 0.64)
	sprite.frame = 5 * 64
	sorter = Node2D.new()
	sorter.y_sort_enabled = true
	add_child(sorter)
	actor = Node2D.new()
	sorter.add_child(actor)
	actor.add_child(sprite)
	actor.position = project_iso(player.position)
	halo = PointLight2D.new()
	halo.texture = LIGHT
	halo.texture_scale = 1.5
	halo.color = Color(0.71, 0.81, 1.0)
	halo.energy = 0.34
	halo.position.y = -30
	actor.add_child(halo)
	ambience = AudioStreamPlayer.new()
	var sound: AudioStreamOggVorbis = load("res://assets/ambience.ogg")
	sound.loop = true
	ambience.stream = sound
	ambience.volume_db = -12
	add_child(ambience)
	camera = Camera2D.new()
	camera.position = actor.position + Vector2(0, -105)
	add_child(camera)
	var ui := CanvasLayer.new()
	add_child(ui)
	hud = label_at(ui, Vector2(28, 24), "", 16)
	hint = label_at(ui, Vector2(28, 510), "WASD / ARROWS  WALK    WHEEL  ZOOM    Z  OVERVIEW    L  LIGHTS    R  REFLECTIONS    M  SOUND    ESC  PAUSE", 11)
	hint.modulate = Color(0.69, 0.72, 0.77, 0.9)
	intro = label_at(ui, Vector2(0, 188), "H O L L O W\n\nA quiet descent\n\nMove to begin", 24)
	intro.size = Vector2(960, 170)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_shadow_color", Color(0.02, 0.025, 0.04, 0.9))
	intro.add_theme_constant_override("shadow_offset_x", 1)
	intro.add_theme_constant_override("shadow_offset_y", 2)
	curtain = ColorRect.new()
	curtain.size = Vector2(960, 540)
	curtain.color = Color(0.025, 0.03, 0.05, 0)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(curtain)
	build_room()

func label_at(parent: Node, pos: Vector2, text: String, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("d9d1bb"))
	parent.add_child(l)
	return l

func wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size / 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	scenery.add_child(body)

func lamp(pos: Vector2, color: Color, energy: float, radius: float, flame := true, elevation := 112.0) -> void:
	var light := PointLight2D.new()
	light.texture = LIGHT
	var screen_pos := project_iso(pos) - Vector2(0, elevation)
	light.position = screen_pos
	light.color = color
	light.energy = energy
	light.texture_scale = radius
	light.height = elevation
	light.shadow_enabled = true
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.shadow_filter_smooth = 2.3
	light.shadow_color = Color(0.015, 0.023, 0.05, 0.72)
	light.set_meta("base_energy", energy)
	scenery.add_child(light)
	lights.append(light)
	physical_lights.append(screen_pos)
	shadow_sources.append(Vector3(pos.x, pos.y, elevation))
	if flame:
		flames.append(screen_pos)
		var torch := Sprite2D.new()
		torch.texture = load("res://assets/torch-%d.png" % (0 if pos.x < 10 else 1))
		torch.scale = Vector2.ONE * (55.0 / torch.texture.get_height())
		torch.position = screen_pos + Vector2(0, 25)
		scenery.add_child(torch)

func pillar(pos: Vector2, broken := false) -> void:
	wall(Rect2(pos - Vector2(25, 25), Vector2(50, 50)))
	var column := Sprite2D.new()
	column.texture = load("res://assets/pillar-broken.png" if broken else "res://assets/pillar.png")
	column.position = project_iso(pos)
	column.scale = Vector2.ONE * (96.0 / column.texture.get_width())
	column.offset = Vector2(0, -column.texture.get_height() * 0.5 + 20)
	column.set_meta("height", 155.0 if broken else 360.0)
	sorter.add_child(column)
	pillars.append(column)
	pillar_positions.append(pos)
	var shade := LightOccluder2D.new()
	var shape := OccluderPolygon2D.new()
	# A compact footprint casts onto the floor; the tall texture is sorted by its base.
	shape.polygon = PackedVector2Array([Vector2(-23, -6), Vector2(0, -17), Vector2(23, -6), Vector2(0, 7)])
	shade.occluder = shape
	shade.position = column.position
	scenery.add_child(shade)

func build_room() -> void:
	for child in scenery.get_children():
		scenery.remove_child(child)
		child.queue_free()
	for column in pillars:
		sorter.remove_child(column)
		column.queue_free()
	pillars.clear()
	lights.clear()
	flames.clear()
	physical_lights.clear()
	shadow_sources.clear()
	pillar_positions.clear()
	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = load("res://assets/room-unlit.png" if room == 0 else "res://assets/room%d.png" % room)
	if room == 0:
		bg.scale = Vector2.ONE * 0.5
		room_material = CanvasTexture.new()
		room_material.diffuse_texture = bg.texture
		room_material.normal_texture = load("res://assets/room-normal.png")
		room_material.specular_texture = load("res://assets/room-specular.png")
		room_material.specular_shininess = 0.65
		room_material.specular_color = Color(0.24, 0.27, 0.32)
		bg.texture = room_material
	scenery.add_child(bg)
	# Room dimensions are now 960 by 800 logical floor units.
	if room == 0:
		wall(Rect2(-35, -35, 35, 870))
		wall(Rect2(960, -35, 35, 395))
		wall(Rect2(960, 460, 35, 375))
	elif room == 1:
		wall(Rect2(-35, -35, 35, 385))
		wall(Rect2(-35, 470, 35, 365))
		wall(Rect2(960, -35, 35, 870))
	else:
		wall(Rect2(-35, -35, 35, 870))
		wall(Rect2(960, -35, 35, 870))
	if room == 1:
		wall(Rect2(0, -35, 430, 35))
		wall(Rect2(530, -35, 430, 35))
		wall(Rect2(315, 270, 335, 310))
	else:
		wall(Rect2(0, -35, 960, 35))
	if room == 2:
		wall(Rect2(0, 800, 440, 35))
		wall(Rect2(520, 800, 440, 35))
	else:
		wall(Rect2(0, 800, 960, 35))
	pillar(Vector2(195, 185))
	pillar(Vector2(770, 190))
	pillar(Vector2(180, 655), true)
	pillar(Vector2(790, 660))
	if room == 0:
		# All illumination is live; the diffuse room plate has no light effects.
		lamp(Vector2(0, 539), Color("ffbb83"), 1.65, 3.2, true, 130.0)
		lamp(Vector2(42, 0), Color("ffce98"), 1.7, 3.3, true, 120.0)
		lamp(Vector2(704, 0), Color("ffc391"), 1.65, 3.3, true, 122.0)
		lamp(Vector2(425, 0), Color("a8c8ff"), 1.0, 4.0, false, 125.0)
	else:
		lamp(Vector2(45, 5), Color("ffd2a4"), 0.95, 2.4)
		lamp(Vector2(625, 5), Color("ffc690"), 1.0, 2.65)
		lamp(Vector2(5, 255), Color("ffbf87"), 0.95, 2.6)
		lamp(Vector2(5, 755), Color("ffcda0"), 0.95, 2.5)
		if room == 2:
			lamp(Vector2(470, 5), Color("a6bdf0"), 0.9, 3.0, false, 125.0)
	visited[room] = true
	hud.text = "%02d  /  %s" % [room + 1, ROOM_NAMES[room]]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M:
			muted = not muted
			ambience.volume_db = -80 if muted else -12
			hint.text = "WASD / ARROWS  WALK    WHEEL  ZOOM    Z  OVERVIEW    L  LIGHTS    R  REFLECTIONS    M  SOUND %s    ESC  PAUSE" % ("OFF" if muted else "ON")
		if event.physical_keycode == KEY_ESCAPE and started:
			paused = not paused
			intro.text = "PAUSED\n\nEsc to return"
			intro.visible = paused
		if event.physical_keycode == KEY_L:
			lighting_enabled = not lighting_enabled
		if event.physical_keycode == KEY_R:
			reflections_enabled = not reflections_enabled
		if event.physical_keycode == KEY_Z:
			overview = not overview
		if event.physical_keycode in [KEY_EQUAL, KEY_PLUS, KEY_MINUS]:
			overview = false
			zoom_target = clampf(zoom_target + (-0.1 if event.physical_keycode == KEY_MINUS else 0.1), 0.65, 1.65)
		if event.physical_keycode == KEY_F:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			overview = false
			zoom_target = clampf(zoom_target + (0.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -0.1), 0.65, 1.65)
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1:
			if paused:
				paused = false
				intro.hide()
			finger = event.index
			stick_origin = event.position
		elif not event.pressed and event.index == finger:
			finger = -1
			stick_vector = Vector2.ZERO
	if event is InputEventScreenDrag and event.index == finger:
		stick_vector = (event.position - stick_origin) / 26.0
		stick_vector = stick_vector.limit_length()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		stick_vector = Vector2.ZERO
		finger = -1
		if started and is_instance_valid(intro):
			paused = true
			intro.text = "PAUSED\n\nEsc to return"
			intro.visible = true

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	if stick_vector.length() > 0.15:
		direction = stick_vector
	if paused or transitioning:
		player.velocity = Vector2.ZERO
		return
	if direction.length() > 0.1 and not started:
		started = true
		intro.hide()
		ambience.play()
	var desired_world := unproject_direction(direction * SPEED)
	player.velocity = player.velocity.move_toward(desired_world, 2200.0 * delta)
	player.move_and_slide()
	actor.position = project_iso(player.position)
	var screen_velocity := project_direction(player.get_real_velocity())
	moving = screen_velocity.length() > 2.0
	if moving:
		walk_frame += screen_velocity.length() * delta * 0.10
		var row := 5
		sprite.flip_h = false
		if direction.y < -0.35:
			row = 4 if absf(direction.x) < 0.3 else 0
			sprite.flip_h = direction.x > 0
		elif absf(direction.x) > 0.35:
			row = 3 if direction.y > 0.35 else 2
			sprite.flip_h = direction.x > 0
		sprite.frame = row * 64 + int(walk_frame) % 64
	elif direction.length() < 0.1:
		sprite.frame = (sprite.frame / 64) * 64
		walk_frame = 0
	if room == 0 and player.position.x > 979:
		change_room(1, Vector2(28, 410))
	elif room == 1 and player.position.x < -19:
		change_room(0, Vector2(930, 410))
	elif room == 1 and player.position.y < -19:
		change_room(2, Vector2(480, 770))
	elif room == 2 and player.position.y > 819:
		change_room(1, Vector2(480, 48))

func change_room(next: int, arrival: Vector2) -> void:
	if transitioning:
		return
	transitioning = true
	var fade := create_tween()
	fade.tween_property(curtain, "color:a", 1.0, 0.16)
	await fade.finished
	room = next
	player.position = arrival
	actor.position = project_iso(arrival)
	player.velocity = Vector2.ZERO
	build_room()
	camera.position = actor.position + Vector2(0, -105)
	var reveal := create_tween()
	reveal.tween_property(curtain, "color:a", 0.0, 0.22)
	await reveal.finished
	transitioning = false

func _process(delta: float) -> void:
	if not paused:
		clock += delta
	halo.enabled = lighting_enabled
	if is_instance_valid(room_material):
		room_material.specular_color = Color(0.24, 0.27, 0.32) if reflections_enabled else Color.BLACK
	for i in range(lights.size()):
		var l := lights[i]
		l.enabled = lighting_enabled
		l.energy = float(l.get_meta("base_energy")) * (1.0 + 0.012 * sin(clock * 3.6 + i * 5) + 0.008 * sin(clock * 9.1 + i))
	var target_zoom := 0.48 if overview else zoom_target
	camera.zoom = camera.zoom.lerp(Vector2.ONE * target_zoom, 1.0 - exp(-delta * 8.0))
	var aim := Vector2(855, 585) if overview else actor.position + Vector2(0, -105)
	if not overview:
		aim.x = clampf(aim.x, 470, 1310)
		aim.y = clampf(aim.y, 280, 930)
	camera.position = camera.position.lerp(aim, 1.0 - exp(-delta * 7.0))
	# Foreground pillars become translucent only when they hide the character.
	for column in pillars:
		var height: float = column.get_meta("height")
		var hides_player := actor.position.y < column.position.y + 5 and actor.position.y > column.position.y - height and absf(actor.position.x - column.position.x) < 43
		column.modulate.a = lerpf(column.modulate.a, 0.26 if hides_player else 1.0, 1.0 - exp(-delta * 9.0))
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player):
		return
	for i in range(pillar_positions.size()) if lighting_enabled else []:
		cast_shadow(pillar_positions[i], 125.0 if i == 2 else 340.0, 26.0, 0.075)
	var feet := project_iso(player.position)
	# Project the character's contact shadow away from the nearest physical light.
	var nearest := Vector2(790, 160)
	var distance := INF
	for source in physical_lights:
		var dist := feet.distance_squared_to(source)
		if dist < distance:
			distance = dist
			nearest = source
	var away := (feet - nearest).normalized()
	var shadow_length := clampf(sqrt(distance) * 0.14, 20, 65)
	for layer in range(4) if lighting_enabled else []:
		var width: float = 10.0 + layer * 2
		var side: Vector2 = Vector2(-away.y, away.x) * width
		var tip := feet + away * shadow_length
		draw_colored_polygon(PackedVector2Array([feet - side * 0.6, feet + side * 0.6, tip + side, tip - side]), Color(0.012, 0.02, 0.042, 0.055))
	draw_set_transform(feet + Vector2(0, -1), 0, Vector2(1, 0.38))
	draw_circle(Vector2.ZERO, 17, Color(0.009, 0.014, 0.026, 0.5))
	draw_set_transform(Vector2.ZERO)
	for p in flames if lighting_enabled else []:
		var sway := int(sin(clock * 5 + p.x) * 2)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 5), p + Vector2(-5, -6), p + Vector2(sway, -20), p + Vector2(3, -8), p + Vector2(6, 4)]), Color("bd613d"))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 5), p + Vector2(-3, -4), p + Vector2(sway, -12), p + Vector2(4, 4)]), Color("eea658"))
		draw_rect(Rect2(p + Vector2(-2, -4), Vector2(4, 9)), Color("ffe4ac"))
		for k in range(2):
			var rise := fposmod(clock * 12 + k * 17 + p.x, 42)
			draw_rect(Rect2(p + Vector2(sin(rise * 0.2 + k) * 3, -14 - rise), Vector2.ONE), Color(0.9, 0.52, 0.2, 0.35 * (1.0 - rise / 42)))
	for i in range(85):
		var x := fposmod(i * 97.3 + sin(clock * 0.15 + i) * 15, 920) + 20
		var y := fposmod(i * 57.7 - clock * (1 + i % 3) * 0.7, 750) + 25
		draw_rect(Rect2((project_iso(Vector2(x, y)) - Vector2(0, 14 + i % 60)).floor(), Vector2.ONE), Color(0.72, 0.78, 0.87, 0.16 + 0.1 * sin(clock + i)))
	if room == 1 and lighting_enabled and reflections_enabled:
		for i in range(24):
			var x := 344.0 + fposmod(i * 29 + clock * 3, 275)
			var y := 300.0 + i * 10
			var p := project_iso(Vector2(x, y))
			draw_line(p, p + Vector2(8 + sin(clock + i) * 4, 0), Color(0.40, 0.65, 0.75, 0.16))
	elif room in [0, 2] and lighting_enabled:
		# Subtle window shaft; lit floor streaks follow the floor projection.
		var opening_left := project_iso(Vector2(395, 0)) - Vector2(0, 110)
		var opening_right := project_iso(Vector2(545, 0)) - Vector2(0, 110)
		for i in range(3):
			var offset := Vector2(i * 12, 0)
			draw_colored_polygon(PackedVector2Array([opening_left + offset, opening_right - offset, project_iso(Vector2(800 - i * 25, 540)), project_iso(Vector2(440 + i * 25, 540))]), Color(0.55, 0.65, 0.88, 0.018))

func project_iso(point: Vector2) -> Vector2:
	return (Vector2(785, 312) if room == 0 else Vector2(790, 300)) + project_direction(point)

func project_direction(value: Vector2) -> Vector2:
	if room == 0:
		return Vector2(value.x * 0.839 - value.y * 0.816, value.x * 0.412 + value.y * 0.384)
	return Vector2((value.x - value.y) * 0.8, (value.x + value.y) * 0.4)

func unproject_direction(value: Vector2) -> Vector2:
	if room == 0:
		var det := 0.839 * 0.384 + 0.816 * 0.412
		return Vector2((0.384 * value.x + 0.816 * value.y) / det, (-0.412 * value.x + 0.839 * value.y) / det)
	return Vector2((value.x / 0.8 + value.y / 0.4) / 2.0, (value.y / 0.4 - value.x / 0.8) / 2.0)

func cast_shadow(pos: Vector2, height: float, width: float, opacity: float) -> void:
	var near := Vector3.ZERO
	var nearest_dist := INF
	for source in shadow_sources:
		var dist := pos.distance_squared_to(Vector2(source.x, source.y))
		if dist < nearest_dist:
			nearest_dist = dist
			near = source
	var away := (pos - Vector2(near.x, near.y)).normalized()
	var length_world := minf(360.0, sqrt(nearest_dist) * height / maxf(near.z - height, 60.0))
	var start := project_iso(pos)
	var endpoint := (pos + away * length_world).clamp(Vector2(30, 30), Vector2(930, 770))
	var end := project_iso(endpoint)
	var axis := (end - start).normalized()
	for layer in range(5):
		var perpendicular := Vector2(-axis.y, axis.x) * (width + layer * 2.0)
		draw_colored_polygon(PackedVector2Array([start - perpendicular * 0.65, start + perpendicular * 0.65, end + perpendicular, end - perpendicular]), Color(0.006, 0.01, 0.02, opacity * (1.0 - layer * 0.12)))
