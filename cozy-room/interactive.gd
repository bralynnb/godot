extends "res://room.gd"

# Geometry is inherited; interaction, collision and wall visibility live here.
var objects: Array[Dictionary] = []
var wall_groups: Array[Node3D] = []
var wall_normals: Array[Vector3] = []
var selected: Dictionary = {}
var pockets: Array[String] = []
var actor: CharacterBody3D
var avatar: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var seated: Dictionary = {}
var first_person := false
var look_yaw := 0.0
var look_pitch := -0.08
var walls_mode := 0 # Automatic / Hidden / All
var status_label: Label
var object_label: Label
var inventory_list: ItemList
var inventory_panel: PanelContainer
var wall_button: Button
var view_button: Button
var crosshair: Label
var action_buttons: Dictionary = {}
var drag_start := Vector2.ZERO
var drag_distance := 0.0
var save_timer := 0.0
var ready_to_save := false
var walk_clock := 0.0
var outline: MeshInstance3D
var testing := false

func _ready() -> void:
	testing = OS.get_cmdline_user_args().has("--test-room")
	super._ready()
	# The window is dark blue and the only outside illumination is moonlight.
	night = true
	daylight.light_color = Color("9db3df")
	daylight.light_energy = 0.22
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.ambient_light_color = Color("8b9ab9")
			child.environment.ambient_light_energy = 0.29
			child.environment.background_color = Color("111521")
		elif child is OmniLight3D and child != firelight:
			child.light_energy = 0.35
			child.light_color = Color("96b0de")
	build_actor()
	build_collision()
	make_outline()
	load_room()
	ready_to_save = true
	update_inventory()
	update_camera()
	if testing: call_deferred("run_tests")
	if OS.get_cmdline_user_args().has("--capture-room"): call_deferred("capture_room")

func build_room() -> void:
	super.build_room()
	var north := Node3D.new()
	var west := Node3D.new()
	add_child(north)
	add_child(west)
	# Collect original architecture only, leaving furniture independently movable.
	for child in get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var p: Vector3 = child.position
			var s: Vector3 = child.mesh.size
			if p.z < -2.94 and s.x > 5:
				child.reparent(north)
			elif p.x < -2.95 and (s.z > 1 or s.y > 2 or p.y > 1.2):
				child.reparent(west)
				if absf(p.x+3.21) < 0.02:
					child.material_override = mat("17283f",0.08)
	for child in get_children():
		if child.has_meta("north_fixture"): child.reparent(north,true)
	wall_groups = [north,west]
	wall_normals = [Vector3(0,0,-1),Vector3(-1,0,0)]
	var south := Node3D.new()
	var east := Node3D.new()
	add_child(south)
	add_child(east)
	block(Vector3(0,2.1,3.12),Vector3(6.6,4.25,0.18),"bba58b",south)
	block(Vector3(0,0.2,2.97),Vector3(6.4,0.27,0.12),"66462e",south)
	block(Vector3(3.25,2.1,0),Vector3(0.18,4.25,6.3),"bba58b",east)
	block(Vector3(3.11,0.2,0),Vector3(0.12,0.27,6.1),"66462e",east)
	# A framed picture gives the two newly built walls some character.
	block(Vector3(0,2.45,2.99),Vector3(1.3,0.94,0.12),"533922",south)
	block(Vector3(0,2.45,2.91),Vector3(1.12,0.76,0.035),"263849",south)
	block(Vector3(0.29,2.60,2.88),Vector3(0.23,0.23,0.035),"d4c99a",south,0.15)
	block(Vector3(3.10,2.48,0.65),Vector3(0.13,1.18,0.90),"563a24",east)
	block(Vector3(3.02,2.48,0.65),Vector3(0.035,0.99,0.72),"637060",east)
	wall_groups.append(south)
	wall_groups.append(east)
	wall_normals.append(Vector3(0,0,1))
	wall_normals.append(Vector3(1,0,0))

func wrap_nodes(nodes: Array, p: Vector3) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.position = p
	for node in nodes:
		node.reparent(root,true)
	return root

func new_nodes(start: int) -> Array:
	var result: Array = []
	var children := get_children()
	for i in range(start,children.size()): result.append(children[i])
	return result

func register_object(root: Node3D, label: String, size: Vector3, offset: Vector3, pickable: bool, seat: bool = false) -> void:
	var item := {"id":"item_%02d" % objects.size(),"label":label,"node":root,"size":size,"offset":offset,"pickable":pickable,"seat":seat,"stored":false,"support":""}
	root.name = label.replace(" ","_")+"_"+str(objects.size())
	objects.append(item)

func chair(p: Vector3,angle: float,col: String,sofa: bool) -> void:
	super.chair(p,angle,col,sofa)
	var root: Node3D = get_child(get_child_count()-1)
	var label := "Mustard sofa" if sofa else ("Reading chair" if col == "ae592c" else "Brown armchair")
	register_object(root,label,Vector3(2.75 if sofa else 1.48,1.57,1.30),Vector3(0,0.78,0),false,true)

func bookshelf(p: Vector3,w: float,h: float) -> void:
	var start := get_child_count()
	super.bookshelf(p,w,h)
	var contents := new_nodes(start)
	var frame: Array = []
	var books: Array[Dictionary] = []
	for child in contents:
		if child.mesh.size.z < 0.4 and child.mesh.size.z > 0.2:
			var root := wrap_nodes([child],child.position)
			register_object(root,["Green book","Rust book","Cream book","Blue book","Burgundy book"][books.size()%5],child.mesh.size,Vector3.ZERO,true)
			books.append(objects.back())
		else: frame.append(child)
	var shelf := wrap_nodes(frame,p)
	register_object(shelf,"Tall bookcase" if h > 2 else "Low bookcase",Vector3(w+0.2,h,0.68),Vector3(0,h/2,0.22),false)
	for book in books: book.support = objects.back().id

func wall_shelf(p: Vector3,w: float) -> void:
	var start := get_child_count()
	super.wall_shelf(p,w)
	var books: Array = []
	var frame: Array = []
	for child in new_nodes(start):
		if child.mesh.size.z < 0.3 and child.mesh.size.y > 0.2:
			var root := wrap_nodes([child],child.position)
			register_object(root,"Display book",child.mesh.size,Vector3.ZERO,true)
			books.append(objects.back())
		else: frame.append(child)
	var fixture := wrap_nodes(frame,p)
	fixture.set_meta("north_fixture",true)
	for book in books: book.support = "north-wall"

func plant(p: Vector3,s: float) -> void:
	var start := get_child_count()
	super.plant(p,s)
	var root := wrap_nodes(new_nodes(start),p)
	register_object(root,"Small potted plant" if s < 1 else "Floor plant",Vector3(0.66,1.13,0.60)*s,Vector3(0,0.54*s,0),s < 1)

func table(p: Vector3) -> void:
	var start := get_child_count()
	super.table(p)
	var parts := new_nodes(start)
	var candle_parts := parts.slice(5)
	var table_parts := parts.slice(0,5)
	var root := wrap_nodes(table_parts,p)
	register_object(root,"Side table",Vector3(0.62,0.81,0.62),Vector3(0,0.40,0),false)
	var support_id: String = objects.back().id
	var candle := wrap_nodes(candle_parts,p+Vector3(0,0.8,0))
	register_object(candle,"Candle",Vector3(0.24,0.48,0.24),Vector3(0,0.22,0),true)
	objects.back().support = support_id

func collider(parent: Node3D, size: Vector3, offset: Vector3, layer: int = 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	parent.add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = offset
	body.add_child(shape)
	return body

func build_collision() -> void:
	collider(self,Vector3(6.6,0.15,6.3),Vector3(0,-0.025,0))
	# Wall collision stays active even while walls are visually cut away.
	for p in [Vector3(0,2,-3.1),Vector3(0,2,3.1)]: collider(self,Vector3(6.6,4,0.18),p)
	for p in [Vector3(-3.25,2,0),Vector3(3.25,2,0)]: collider(self,Vector3(0.18,4,6.3),p)
	collider(self,Vector3(2.3,2.3,1.3),Vector3(0.75,1.15,-2.45))
	for item in objects:
		var is_bookcase: bool = item.label in ["Tall bookcase","Low bookcase"]
		var body := collider(item.node,item.size,item.offset,1 if is_bookcase else (2 if item.pickable else 3))
		if is_bookcase:
			# Pick the actual shelf planks, not an invisible box over the books.
			for part in item.node.get_children():
				if part is MeshInstance3D:
					var hit := collider(part,part.mesh.size,Vector3.ZERO,2)
					hit.set_meta("item_id",item.id)
		body.set_meta("item_id",item.id)
		item["body"] = body

func build_actor() -> void:
	actor = CharacterBody3D.new()
	actor.name = "Resident"
	actor.collision_layer = 4
	actor.collision_mask = 1
	add_child(actor)
	actor.position = Vector3(0.1,0.08,0.65)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.19
	capsule.height = 1.45
	shape.shape = capsule
	shape.position.y = 0.75
	actor.add_child(shape)
	avatar = Node3D.new()
	actor.add_child(avatar)
	block(Vector3(0,0.89,0),Vector3(0.40,0.49,0.25),"5d777c",avatar)
	block(Vector3(0,1.29,0),Vector3(0.30,0.32,0.29),"ce9b76",avatar)
	block(Vector3(0,1.45,-0.025),Vector3(0.32,0.12,0.31),"423328",avatar)
	block(Vector3(0,1.30,0.148),Vector3(0.18,0.047,0.014),"332b25",avatar)
	left_leg = limb(Vector3(-0.115,0.66,0),Vector3(0.17,0.50,0.19),"514a42",avatar)
	right_leg = limb(Vector3(0.115,0.66,0),Vector3(0.17,0.50,0.19),"514a42",avatar)
	block(Vector3(0,-0.49,0.055),Vector3(0.18,0.13,0.30),"352b23",left_leg)
	block(Vector3(0,-0.49,0.055),Vector3(0.18,0.13,0.30),"352b23",right_leg)
	left_arm = limb(Vector3(-0.29,1.09,0),Vector3(0.16,0.43,0.19),"6b8588",avatar)
	right_arm = limb(Vector3(0.29,1.09,0),Vector3(0.16,0.43,0.19),"6b8588",avatar)
	block(Vector3(0,-0.44,0),Vector3(0.15,0.14,0.17),"ce9b76",left_arm)
	block(Vector3(0,-0.44,0),Vector3(0.15,0.14,0.17),"ce9b76",right_arm)

func limb(p: Vector3,size: Vector3,color: String,parent: Node3D) -> Node3D:
	var joint := Node3D.new()
	parent.add_child(joint)
	joint.position = p
	block(Vector3(0,-size.y/2,0),size,color,joint)
	return joint

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := VBoxContainer.new()
	top.position = Vector2(20,16)
	top.add_theme_constant_override("separation",7)
	layer.add_child(top)
	var title := Label.new()
	title.text = "F I R E S I D E  /  AFTER DARK"
	title.add_theme_font_size_override("font_size",19)
	top.add_child(title)
	var controls := Label.new()
	controls.text = "WASD walk · Click an object · Drag orbit · Right-drag pan · Scroll zoom\nF first person · E pick up / sit · Space stand · Q/R rotate · I inventory · Esc release mouse"
	controls.add_theme_font_size_override("font_size",13)
	controls.modulate = Color("dfcdb5")
	top.add_child(controls)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	top.add_child(row)
	view_button = ui_button(row,"First person [F]",toggle_view)
	wall_button = ui_button(row,"Walls: Auto",cycle_walls)
	ui_button(row,"Inventory [I]",toggle_inventory)
	ui_button(row,"Center view",func(): target = Vector3(0,1.15,0); yaw = 0.70; pitch = 0.60; zoom = 9.0)
	ui_button(row,"Fire",func(): fire_on = not fire_on; save_room())
	# Bottom actions wrap rather than extending beyond a narrow screen.
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 18
	bottom.offset_right = -18
	bottom.offset_top = -113
	bottom.offset_bottom = -16
	layer.add_child(bottom)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09,0.08,0.075,0.93)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	style.set_corner_radius_all(6)
	bottom.add_theme_stylebox_override("panel",style)
	var box := VBoxContainer.new()
	bottom.add_child(box)
	object_label = Label.new()
	object_label.text = "Click a chair, book, candle or plant."
	box.add_child(object_label)
	var actions := HFlowContainer.new()
	box.add_child(actions)
	for action in ["Pick up","Sit","Stand","Push","Pull","Rotate ↶","Rotate ↷"]:
		action_buttons[action] = ui_button(actions,action,func(): act(action))
	status_label = Label.new()
	status_label.text = "Walk close to an object to interact. Your inventory and room layout save in this browser."
	status_label.add_theme_font_size_override("font_size",13)
	status_label.modulate = Color("c4b79f")
	box.add_child(status_label)
	inventory_panel = PanelContainer.new()
	inventory_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	inventory_panel.offset_left = -282
	inventory_panel.offset_right = -18
	inventory_panel.offset_top = 135
	inventory_panel.offset_bottom = 440
	inventory_panel.add_theme_stylebox_override("panel",style)
	layer.add_child(inventory_panel)
	var inv_box := VBoxContainer.new()
	inventory_panel.add_child(inv_box)
	var heading := Label.new()
	heading.text = "YOUR INVENTORY"
	inv_box.add_child(heading)
	inventory_list = ItemList.new()
	inventory_list.custom_minimum_size = Vector2(240,180)
	inventory_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inv_box.add_child(inventory_list)
	ui_button(inv_box,"Place selected item",place_inventory_item)
	ui_button(inv_box,"Close",toggle_inventory)
	inventory_panel.hide()
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -6
	crosshair.offset_top = -12
	crosshair.add_theme_font_size_override("font_size",22)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(crosshair)
	crosshair.hide()

func ui_button(parent: Node, text: String, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 31
	b.pressed.connect(fn)
	parent.add_child(b)
	return b

func make_outline() -> void:
	outline = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	outline.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1,0.74,0.25,0.14)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline.material_override = material
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(outline)
	outline.hide()

func find_item(id: String) -> Dictionary:
	for item in objects:
		if item.id == id: return item
	return {}

func say(message: String) -> void:
	status_label.text = message

func choose(item: Dictionary) -> void:
	selected = item
	refresh_selection()

func refresh_selection() -> void:
	if selected.is_empty() or selected.stored:
		outline.hide()
		object_label.text = "Click an object to select it."
	else:
		outline.show()
		outline.global_transform = selected.node.global_transform
		outline.position = selected.node.to_global(selected.offset)
		outline.scale = selected.size + Vector3.ONE*0.04
		object_label.text = selected.label + (" · pick up and keep" if selected.pickable else " · move / rotate")
	for action in action_buttons:
		var valid: bool = not selected.is_empty() and not selected.get("stored",false)
		if action == "Stand": valid = not seated.is_empty()
		elif action == "Pick up": valid = valid and selected.get("pickable",false)
		elif action == "Sit": valid = valid and selected.get("seat",false) and seated.is_empty()
		elif action != "Stand": valid = valid and seated.is_empty()
		action_buttons[action].disabled = not valid

func select_at(screen: Vector2) -> void:
	var origin := camera.project_ray_origin(screen)
	var query := PhysicsRayQueryParameters3D.create(origin,origin+camera.project_ray_normal(screen)*40,2)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result and result.collider.has_meta("item_id"):
		choose(find_item(result.collider.get_meta("item_id")))
	else: choose({})

func close_enough(item: Dictionary) -> bool:
	var center: Vector3 = item.node.to_global(item.offset)
	var horizontal := Vector2(center.x-actor.position.x,center.z-actor.position.z).length()
	if horizontal > 1.95 + minf(item.size.x,item.size.z)*0.35:
		say("Walk closer to the " + item.label.to_lower() + ".")
		return false
	return true

func act(action: String) -> void:
	if action == "Stand": stand_up(); return
	if selected.is_empty(): say("Select an object first."); return
	if not seated.is_empty(): say("Stand up before moving or picking up objects."); return
	if not close_enough(selected): return
	match action:
		"Pick up": pick_up(selected)
		"Sit": sit_down(selected)
		"Push": move_item(1.0)
		"Pull": move_item(-1.0)
		"Rotate ↶": rotate_item(-PI/12)
		"Rotate ↷": rotate_item(PI/12)
	refresh_selection()
	save_room()

func pick_up(item: Dictionary) -> void:
	if not item.pickable or item.stored: return
	item.stored = true
	item.node.hide()
	item.body.collision_layer = 0
	pockets.append(item.id)
	item.support = ""
	say(item.label + " added to your inventory.")
	choose({})
	update_inventory()

func update_inventory() -> void:
	inventory_list.clear()
	for id in pockets:
		var item := find_item(id)
		inventory_list.add_item(item.label)
		inventory_list.set_item_metadata(inventory_list.item_count-1,id)
	if pockets.is_empty():
		inventory_list.add_item("Nothing collected yet")
		inventory_list.set_item_disabled(0,true)

func toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible
	if inventory_panel.visible: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func facing() -> Vector3:
	if first_person: return Vector3(-sin(look_yaw),0,-cos(look_yaw))
	return avatar.global_basis.z.normalized()

func place_inventory_item() -> void:
	var indices := inventory_list.get_selected_items()
	if indices.is_empty() or pockets.is_empty(): say("Select an item in your inventory."); return
	var item := find_item(inventory_list.get_item_metadata(indices[0]))
	var where := actor.position+facing()*0.85
	where.y = 0.07 + item.size.y/2 - item.offset.y
	var support_id := ""
	if not selected.is_empty() and not selected.stored and selected.label in ["Side table","Low bookcase","Tall bookcase"]:
		if not close_enough(selected): return
		where = selected.node.to_global(selected.offset)
		where.y += selected.size.y/2 + item.size.y/2 - item.offset.y + 0.02
		support_id = selected.id
	if absf(where.x) > 2.95 or absf(where.z) > 2.80: say("There is no room to place that here."); return
	# Reject occupied floor space or another loose item on the same surface.
	for other in objects:
		if other.id == item.id or other.stored or other.id == support_id: continue
		var a := world_box(item,where,item.node.rotation.y)
		var b := world_box(other,other.node.position,other.node.rotation.y)
		if a.intersects(b): say("That spot is occupied. Face an open spot or select a table."); return
	if world_box(item,where,item.node.rotation.y).intersects(AABB(Vector3(-0.4,0,-3.05),Vector3(2.3,2.3,1.3))):
		say("Keep items clear of the fireplace."); return
	item.node.position = where
	item.node.show()
	item.stored = false
	item.body.collision_layer = 2
	item.support = support_id
	pockets.erase(item.id)
	update_inventory()
	choose(item)
	say(item.label + " placed " + ("on the selected surface." if support_id != "" else "in front of you."))
	save_room()

func world_box(item: Dictionary,p: Vector3,angle: float) -> AABB:
	var basis := Basis(Vector3.UP,angle)
	var center: Vector3 = p+basis*item.offset
	var size: Vector3 = item.size
	var extent := Vector3(absf(cos(angle))*size.x+absf(sin(angle))*size.z,size.y,absf(sin(angle))*size.x+absf(cos(angle))*size.z)
	return AABB(center-extent/2,extent)

func can_transform(item: Dictionary,p: Vector3,angle: float) -> bool:
	var bounds := world_box(item,p,angle)
	if bounds.position.x < -3.08 or bounds.end.x > 3.08 or bounds.position.z < -2.95 or bounds.end.z > 2.94:
		say("The wall blocks that move."); return false
	var fireplace := AABB(Vector3(-0.4,0,-3.05),Vector3(2.3,2.3,1.3))
	if bounds.intersects(fireplace): say("The fireplace is in the way."); return false
	for other in objects:
		if other.id == item.id or other.stored or other.support == item.id or item.support == other.id: continue
		if bounds.intersects(world_box(other,other.node.position,other.node.rotation.y)):
			# Existing touching furniture can be moved away from its overlap.
			var old_overlap := world_box(item,item.node.position,item.node.rotation.y).intersection(world_box(other,other.node.position,other.node.rotation.y)).get_volume()
			if bounds.intersection(world_box(other,other.node.position,other.node.rotation.y)).get_volume() > old_overlap + 0.0001:
				say("The " + other.label.to_lower() + " is in the way."); return false
	var player_box := AABB(actor.position+Vector3(-0.19,0.03,-0.19),Vector3(0.38,1.42,0.38))
	if bounds.intersects(player_box): say("Step aside to make space."); return false
	return true

func transform_item(item: Dictionary,p: Vector3,angle: float) -> void:
	var old: Transform3D = item.node.transform
	item.node.position = p
	item.node.rotation.y = angle
	var delta_transform: Transform3D = item.node.transform*old.affine_inverse()
	for child in objects:
		if child.support == item.id and not child.stored: child.node.transform = delta_transform*child.node.transform

func move_item(direction: float) -> void:
	var delta: Vector3 = selected.node.position-actor.position
	delta.y = 0
	if delta.length() < 0.05: delta = facing()
	var p: Vector3 = selected.node.position+delta.normalized()*0.24*direction
	var previous_support: String = selected.support
	if selected.pickable:
		var on_support := false
		var support := find_item(previous_support)
		if not support.is_empty():
			var bounds := world_box(support,support.node.position,support.node.rotation.y)
			on_support = p.x > bounds.position.x and p.x < bounds.end.x and p.z > bounds.position.z and p.z < bounds.end.z
		# The fixed windowsill is also a support surface.
		if p.x < -2.70 and p.x > -3.15 and p.z > -2.4 and p.z < 1.0 and p.y > 1.2: on_support = true
		if not on_support:
			p.y = 0.07 + selected.size.y/2 - selected.offset.y
			selected.support = ""
	if can_transform(selected,p,selected.node.rotation.y):
		transform_item(selected,p,selected.node.rotation.y)
		say(("Pushed " if direction > 0 else "Pulled ")+selected.label.to_lower()+".")
	else: selected.support = previous_support

func rotate_item(angle: float) -> void:
	var rot: float = selected.node.rotation.y+angle
	if can_transform(selected,selected.node.position,rot):
		transform_item(selected,selected.node.position,rot)
		say("Rotated " + selected.label.to_lower() + " 15°.")

func sit_down(item: Dictionary) -> void:
	if not item.seat: return
	seated = item
	actor.velocity = Vector3.ZERO
	actor.position = item.node.to_global(Vector3(0,0.19,0.12))
	avatar.rotation.y = item.node.rotation.y
	left_leg.rotation.x = -PI/2
	right_leg.rotation.x = -PI/2
	left_arm.rotation.x = -0.4
	right_arm.rotation.x = -0.4
	look_yaw = item.node.rotation.y+PI
	say("Seated in the " + item.label.to_lower() + ". Press Space or Stand to get up.")

func free_standing_spot(p: Vector3) -> bool:
	if absf(p.x) > 2.93 or absf(p.z) > 2.77: return false
	var bounds := AABB(p+Vector3(-0.20,0.04,-0.20),Vector3(0.4,1.45,0.4))
	if bounds.intersects(AABB(Vector3(-0.4,0,-3.05),Vector3(2.3,2.3,1.3))): return false
	for item in objects:
		if not item.stored and not item.pickable and bounds.intersects(world_box(item,item.node.position,item.node.rotation.y)): return false
	return true

func stand_up() -> void:
	if seated.is_empty(): say("You are already standing."); return
	var found := false
	for offset in [Vector3(0,0,1.03),Vector3(1.12,0,0),Vector3(-1.12,0,0),Vector3(0,0,-1.0),Vector3(0,0,1.4),Vector3(-1.3,0,-0.7),Vector3(-0.7,0,-1.3),Vector3(0.7,0,-1.3),Vector3(0,0,-1.5)]:
		var p: Vector3 = seated.node.to_global(offset)
		p.y = 0.08
		if free_standing_spot(p): actor.position = p; found = true; break
	if not found: say("There is no clear space beside this seat."); return
	seated = {}
	for joint in [left_leg,right_leg,left_arm,right_arm]: joint.rotation.x = 0
	refresh_selection()
	say("Standing.")
	save_room()

func toggle_view() -> void:
	first_person = not first_person
	if first_person:
		look_yaw = avatar.rotation.y+PI
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		inventory_panel.hide()
	else: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	avatar.visible = not first_person
	crosshair.visible = first_person
	view_button.text = "Room view [F]" if first_person else "First person [F]"
	update_camera()

func cycle_walls() -> void:
	walls_mode = (walls_mode+1)%3
	wall_button.text = ["Walls: Auto","Walls: Hidden","Walls: All"][walls_mode]
	update_walls()

func update_walls() -> void:
	for i in range(wall_groups.size()):
		var toward_camera := camera.global_position.dot(wall_normals[i]) > 0.10
		wall_groups[i].visible = walls_mode != 1 and (walls_mode == 2 or first_person or not toward_camera)
	for item in objects:
		if item.support == "north-wall" and not item.stored:
			item.node.visible = wall_groups[0].visible
			if item.has("body"): item.body.collision_layer = 2 if wall_groups[0].visible else 0

func update_camera() -> void:
	if not is_instance_valid(camera): return
	if first_person and is_instance_valid(actor):
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 73
		camera.near = 0.04
		camera.position = actor.position+Vector3(0,1.37,0)
		camera.rotation = Vector3(look_pitch,look_yaw,0)
	else:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		super.update_camera()
	update_walls()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F: toggle_view()
			KEY_I: toggle_inventory()
			KEY_SPACE: stand_up()
			KEY_Q: act("Rotate ↶")
			KEY_R: act("Rotate ↷")
			KEY_E:
				if not selected.is_empty(): act("Pick up" if selected.pickable else "Sit")
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if first_person:
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			look_yaw -= event.relative.x*0.003
			look_pitch = clampf(look_pitch-event.relative.y*0.003,-1.35,1.25)
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else: select_at(get_viewport().get_visible_rect().size/2)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: drag_start = event.position; drag_distance = 0
		elif drag_distance < 6: select_at(event.position)
	if event is InputEventMouseMotion: drag_distance += event.relative.length()
	super._unhandled_input(event)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(actor) or not seated.is_empty(): return
	var input := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	var forward := -camera.global_basis.z
	forward.y = 0
	forward = forward.normalized()
	var right := camera.global_basis.x
	right.y = 0
	var move := (right*input.x-forward*input.y).normalized()
	actor.velocity.x = move.x*1.65
	actor.velocity.z = move.z*1.65
	actor.velocity.y = -0.2 if actor.is_on_floor() else actor.velocity.y-9.8*delta
	actor.move_and_slide()
	if move.length() > 0.1:
		avatar.rotation.y = lerp_angle(avatar.rotation.y,atan2(move.x,move.z),minf(delta*12,1))
		walk_clock += delta*9.0
		left_leg.rotation.x = sin(walk_clock)*0.5
		right_leg.rotation.x = -sin(walk_clock)*0.5
		left_arm.rotation.x = -sin(walk_clock)*0.35
		right_arm.rotation.x = sin(walk_clock)*0.35
	else:
		for joint in [left_leg,right_leg,left_arm,right_arm]: joint.rotation.x = lerpf(joint.rotation.x,0,delta*12)

func _process(delta: float) -> void:
	super._process(delta)
	firelight.position.x = 0.75+sin(clock*4.6)*0.025
	if not is_instance_valid(actor): return
	refresh_selection()
	save_timer += delta
	if save_timer > 3:
		save_timer = 0
		save_room()

func save_room() -> void:
	if not ready_to_save or testing: return
	var state: Dictionary = {"version":2,"inventory":pockets,"objects":[],"player":[actor.position.x,actor.position.y,actor.position.z],"fire":fire_on}
	for item in objects:
		var p: Vector3 = item.node.position
		state.objects.append({"id":item.id,"p":[p.x,p.y,p.z],"angle":item.node.rotation.y,"stored":item.stored,"support":item.support})
	var file := FileAccess.open("user://fireside-room-v2.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(state))

func load_room() -> void:
	if testing or not FileAccess.file_exists("user://fireside-room-v2.json"): return
	var state = JSON.parse_string(FileAccess.get_file_as_string("user://fireside-room-v2.json"))
	if not state is Dictionary or state.get("version",0) != 2: return
	for saved in state.get("objects",[]):
		var item := find_item(saved.id)
		if item.is_empty(): continue
		item.node.position = Vector3(saved.p[0],saved.p[1],saved.p[2])
		item.node.rotation.y = saved.angle
		item.stored = saved.stored
		item.support = saved.get("support","")
		item.node.visible = not item.stored
		item.body.collision_layer = 0 if item.stored else (2 if item.pickable else (1 if item.label in ["Tall bookcase","Low bookcase"] else 3))
	pockets.clear()
	for id in state.get("inventory",[]):
		if not find_item(id).is_empty() and find_item(id).stored: pockets.append(id)
	fire_on = state.get("fire",true)
	var p = state.get("player",[0.1,0.08,0.65])
	var position_candidate := Vector3(p[0],0.08,p[2])
	if free_standing_spot(position_candidate): actor.position = position_candidate

func capture_room() -> void:
	await get_tree().create_timer(2).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/fireside-v2.png")
	yaw += PI
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/fireside-v2-reverse.png")
	toggle_view()
	look_yaw = 0
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/fireside-v2-first.png")
	get_tree().quit()

func run_tests() -> void:
	await get_tree().physics_frame
	assert(wall_groups.size() == 4)
	camera.position = Vector3(10,8,10)
	update_walls()
	assert(wall_groups[0].visible and wall_groups[1].visible)
	assert(not wall_groups[2].visible and not wall_groups[3].visible)
	camera.position = Vector3(-10,8,-10)
	update_walls()
	assert(not wall_groups[0].visible and not wall_groups[1].visible)
	assert(wall_groups[2].visible and wall_groups[3].visible)
	walls_mode = 1
	update_walls()
	for wall in wall_groups: assert(not wall.visible)
	walls_mode = 0
	var candle: Dictionary = {}
	var seat: Dictionary = {}
	for item in objects:
		if item.label == "Candle": candle = item
		if item.label == "Brown armchair": seat = item
	assert(not candle.is_empty() and not seat.is_empty())
	pick_up(candle)
	assert(candle.stored and candle.id in pockets and candle.body.collision_layer == 0)
	actor.position = Vector3(0,0.08,0.0)
	avatar.rotation.y = 0
	inventory_list.select(0)
	place_inventory_item()
	assert(not candle.stored and pockets.is_empty())
	actor.position = Vector3(1.2,0.08,0.5)
	sit_down(seat)
	assert(not seated.is_empty())
	stand_up()
	assert(seated.is_empty())
	var old: Vector3 = seat.node.position
	transform_item(seat,old+Vector3(0.05,0,0),seat.node.rotation.y+0.2)
	assert(seat.node.position != old)
	toggle_view()
	assert(first_person and camera.projection == Camera3D.PROJECTION_PERSPECTIVE)
	for wall in wall_groups: assert(wall.visible)
	toggle_view()
	assert(not first_person)
	assert(not can_transform(seat,Vector3(10,0,10),0))
	# Raycast a specific book through the open bookcase front.
	await get_tree().physics_frame
	for item in objects:
		if item.label == "Green book":
			var center: Vector3 = item.node.global_position
			var ray := PhysicsRayQueryParameters3D.create(center+Vector3(0,0,0.8),center,2)
			var hit := get_world_3d().direct_space_state.intersect_ray(ray)
			assert(hit and hit.collider.get_meta("item_id") == item.id)
			break
	print("ROOM TESTS PASSED: four-wall culling, inventory pickup/place, sit/stand, item transform, first-person.")
	get_tree().quit()
