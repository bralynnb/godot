extends Node2D

const SPEED := 76.0
const ROOM_NAMES := ["THE ENTRY VAULT", "THE STILL CISTERN", "THE MOON CHAMBER"]
const ATLAS = preload("res://assets/walker.png")
const LIGHT = preload("res://assets/light.png")
var room := 0
var player: CharacterBody2D
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
	ambient.color = Color(0.47, 0.51, 0.65)
	add_child(ambient)
	player = CharacterBody2D.new()
	player.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6
	shape.shape = circle
	player.add_child(shape)
	add_child(player)
	player.position = Vector2(130, 178)
	sprite = Sprite2D.new()
	sprite.texture = ATLAS
	sprite.hframes = 64
	sprite.vframes = 6
	sprite.position.y = -21
	sprite.frame = 5 * 64
	player.add_child(sprite)
	var halo := PointLight2D.new()
	halo.texture = LIGHT
	halo.texture_scale = 0.66
	halo.color = Color(0.71, 0.81, 1.0)
	halo.energy = 0.55
	halo.position.y = -15
	player.add_child(halo)
	ambience = AudioStreamPlayer.new()
	var sound: AudioStreamOggVorbis = load("res://assets/ambience.ogg")
	sound.loop = true
	ambience.stream = sound
	ambience.volume_db = -12
	add_child(ambience)
	var ui := CanvasLayer.new()
	add_child(ui)
	hud = label_at(ui, Vector2(22, 18), "", 11)
	hint = label_at(ui, Vector2(22, 252), "WASD / ARROWS   WALK      M  SOUND      ESC  PAUSE", 8)
	hint.modulate = Color(0.69, 0.72, 0.77, 0.9)
	intro = label_at(ui, Vector2(0, 88), "H O L L O W\n\nA quiet descent\n\nMove to begin", 18)
	intro.size = Vector2(480, 125)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_shadow_color", Color(0.02, 0.025, 0.04, 0.9))
	intro.add_theme_constant_override("shadow_offset_x", 1)
	intro.add_theme_constant_override("shadow_offset_y", 2)
	curtain = ColorRect.new()
	curtain.size = Vector2(480, 270)
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

func lamp(pos: Vector2, color: Color, energy: float, scale_value: float, flame := true) -> void:
	var light := PointLight2D.new()
	light.texture = LIGHT
	light.position = pos
	light.color = color
	light.energy = energy
	light.texture_scale = scale_value
	light.set_meta("base_energy", energy)
	scenery.add_child(light)
	lights.append(light)
	if flame:
		flames.append(pos)

func build_room() -> void:
	for child in scenery.get_children():
		scenery.remove_child(child)
		child.queue_free()
	lights.clear()
	flames.clear()
	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = load("res://assets/room%d.png" % room)
	scenery.add_child(bg)
	# Thin side walls with a generous doorway; feet, not the whole sprite, collide.
	if room == 0:
		wall(Rect2(-15, 40, 37, 230))
		wall(Rect2(458, 40, 37, 103))
		wall(Rect2(458, 197, 37, 73))
	elif room == 1:
		wall(Rect2(-15, 40, 37, 103))
		wall(Rect2(-15, 197, 37, 73))
		wall(Rect2(458, 40, 37, 230))
	else:
		wall(Rect2(-15, 40, 37, 230))
		wall(Rect2(458, 40, 37, 230))
	if room == 1:
		wall(Rect2(0, 0, 215, 78))
		wall(Rect2(265, 0, 215, 78))
		wall(Rect2(147, 115, 186, 103))
	else:
		wall(Rect2(0, 0, 480, 78))
	if room == 2:
		wall(Rect2(0, 247, 216, 40))
		wall(Rect2(264, 247, 216, 40))
	else:
		wall(Rect2(0, 247, 480, 40))
	if room == 0:
		lamp(Vector2(66, 48), Color("ffc078"), 1.7, 1.35)
		lamp(Vector2(405, 48), Color("ffa667"), 1.6, 1.3)
		lamp(Vector2(449, 166), Color("b48358"), 0.9, 0.8, false)
	elif room == 1:
		lamp(Vector2(70, 49), Color("f8bc85"), 1.4, 1.15)
		lamp(Vector2(410, 49), Color("f8bc85"), 1.4, 1.15)
		lamp(Vector2(240, 159), Color("589eaf"), 0.9, 1.6, false)
	else:
		lamp(Vector2(240, 46), Color("afceff"), 2.4, 1.7, false)
		lamp(Vector2(76, 48), Color("ffc484"), 1.25, 1.05)
		lamp(Vector2(405, 48), Color("ffc484"), 1.25, 1.05)
	visited[room] = true
	hud.text = "%02d  /  %s" % [room + 1, ROOM_NAMES[room]]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M:
			muted = not muted
			ambience.volume_db = -80 if muted else -12
			hint.text = "WASD / ARROWS   WALK      M  SOUND %s      ESC  PAUSE" % ("OFF" if muted else "ON")
		if event.physical_keycode == KEY_ESCAPE and started:
			paused = not paused
			intro.text = "PAUSED\n\nEsc to return"
			intro.visible = paused
		if event.physical_keycode == KEY_F:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
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
	player.velocity = player.velocity.move_toward(direction * SPEED, 1100.0 * delta)
	player.move_and_slide()
	moving = player.get_real_velocity().length() > 2.0
	if moving:
		walk_frame += player.get_real_velocity().length() * delta * 0.19
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
	if room == 0 and player.position.x > 481:
		change_room(1, Vector2(29, 170))
	elif room == 1 and player.position.x < -1:
		change_room(0, Vector2(451, 170))
	elif room == 1 and player.position.y < 51:
		change_room(2, Vector2(240, 235))
	elif room == 2 and player.position.y > 271:
		change_room(1, Vector2(240, 89))

func change_room(next: int, arrival: Vector2) -> void:
	if transitioning:
		return
	transitioning = true
	var fade := create_tween()
	fade.tween_property(curtain, "color:a", 1.0, 0.16)
	await fade.finished
	room = next
	player.position = arrival
	player.velocity = Vector2.ZERO
	build_room()
	var reveal := create_tween()
	reveal.tween_property(curtain, "color:a", 0.0, 0.22)
	await reveal.finished
	transitioning = false

func _process(delta: float) -> void:
	if not paused:
		clock += delta
	for i in range(lights.size()):
		var l := lights[i]
		l.energy = float(l.get_meta("base_energy")) * (1.0 + 0.035 * sin(clock * 8 + i * 5) + 0.025 * sin(clock * 17 + i))
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player):
		return
	# Contact shadow behind the feet; the sprite itself remains unscaled while walking.
	draw_set_transform(player.position + Vector2(0, -1), 0, Vector2(1, 0.32))
	draw_circle(Vector2.ZERO, 10, Color(0.015, 0.02, 0.035, 0.47))
	draw_set_transform(Vector2.ZERO)
	for p in flames:
		draw_rect(Rect2(p + Vector2(-3, 1), Vector2(6, 10)), Color("392936"))
		draw_rect(Rect2(p + Vector2(-5, 4), Vector2(10, 3)), Color("82747d"))
		var flicker := int(sin(clock * 13 + p.x) * 2)
		draw_rect(Rect2(p + Vector2(-3, -7 + flicker), Vector2(6, 10 - flicker)), Color("de7554"))
		draw_rect(Rect2(p + Vector2(-2, -5), Vector2(4, 8)), Color("ffbc6c"))
		draw_rect(Rect2(p + Vector2(-1, -2), Vector2(2, 5)), Color("fff0bf"))
	# Sparse drifting motes, never a screen-filling particle cloud.
	for i in range(32):
		var x := fposmod(i * 97.3 + sin(clock * 0.15 + i) * 8, 438) + 21
		var y := fposmod(i * 37.7 - clock * (1 + i % 3) * 0.5, 162) + 79
		draw_rect(Rect2(Vector2(x, y).floor(), Vector2.ONE), Color(0.74, 0.79, 0.81, 0.14 + 0.12 * sin(clock + i)))
	if room == 1:
		for i in range(8):
			var x := 167.0 + fposmod(i * 29 + clock * 2, 139)
			var y := 133.0 + i * 9
			draw_line(Vector2(x, y), Vector2(x + 7 + sin(clock + i) * 3, y), Color(0.35, 0.66, 0.72, 0.15))
	if room == 2:
		draw_colored_polygon(PackedVector2Array([Vector2(221, 57), Vector2(259, 57), Vector2(320, 238), Vector2(186, 238)]), Color(0.55, 0.68, 0.94, 0.035))
