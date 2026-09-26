extends Node
const Story = preload("res://scripts/story.gd")
const World = preload("res://scripts/world.gd")
var view: SubViewport
var world: Node3D
var player: CharacterBody3D
var camera: Camera3D
var torch: SpotLight3D
var chapter = 0
var step = 0
var active = false
var modal = false
var pending = ""
var guided = false
var eye_timer = 0.0
var blink_left = 0.0
var elapsed = 0.0
var entries: Array[String] = []
var ui: Control
var shade: ColorRect
var lid: ColorRect
var header: Label
var objective: Label
var prompt: Label
var status: Label
var dialog: PanelContainer
var dialog_title: Label
var dialog_body: Label
var dialog_hint: Label
var menu: PanelContainer
var marker: Label3D
var sound: AudioStreamPlayer
var footsteps = 0.0
var sensitivity = .0024
var smoke_mode = false

func _ready() -> void:
 _inputs()
 var container = SubViewportContainer.new()
 container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 container.stretch = true
 container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 add_child(container)
 view = SubViewport.new()
 view.size = Vector2i(480,360)
 view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 container.add_child(view)
 container.stretch_shrink = 2
 sound = AudioStreamPlayer.new()
 sound.stream = load("res://assets/room.wav")
 sound.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
 sound.volume_db = -21
 add_child(sound)
 sound.play()
 _ui()
 _load_chapter(0,false)
 _menu()
 if "--smoke" in OS.get_cmdline_user_args():
  smoke_mode = true
  _smoke_test.call_deferred()

func _inputs() -> void:
 var keys = {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"use":KEY_E,"journal":KEY_J,"torch":KEY_F,"blink":KEY_B,"help":KEY_H,"guide":KEY_G,"confirm":KEY_ENTER,"pause_game":KEY_ESCAPE,"retry":KEY_R}
 for action in keys:
  InputMap.add_action(action)
  var e = InputEventKey.new()
  e.physical_keycode = keys[action]
  InputMap.action_add_event(action,e)

func text_label(size: int, color: String = "d6e1db") -> Label:
 var l = Label.new()
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",Color(color))
 return l

func panel_style() -> StyleBoxFlat:
 var s = StyleBoxFlat.new()
 s.bg_color = Color(.025,.045,.057,.97)
 s.border_color = Color("486668")
 s.set_border_width_all(1)
 s.content_margin_left = 28
 s.content_margin_right = 28
 s.content_margin_top = 22
 s.content_margin_bottom = 22
 return s

func _ui() -> void:
 var layer = CanvasLayer.new()
 add_child(layer)
 ui = Control.new()
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
 layer.add_child(ui)
 shade = ColorRect.new()
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.color = Color(0,0,0,.12)
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 ui.add_child(shade)
 header = text_label(18,"9fb6b4")
 header.position = Vector2(32,26)
 ui.add_child(header)
 objective = text_label(22)
 objective.position = Vector2(32,53)
 ui.add_child(objective)
 var cross = text_label(18,"bac9bb")
 cross.text = "+"
 cross.position = Vector2(474,349)
 ui.add_child(cross)
 prompt = text_label(21)
 prompt.position = Vector2(140,572)
 prompt.size = Vector2(680,65)
 prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 ui.add_child(prompt)
 status = text_label(15,"9caaa9")
 status.position = Vector2(32,665)
 status.size = Vector2(896,44)
 ui.add_child(status)
 lid = ColorRect.new()
 lid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 lid.color = Color.BLACK
 lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
 lid.hide()
 ui.add_child(lid)
 dialog = PanelContainer.new()
 dialog.position = Vector2(100,190)
 dialog.size = Vector2(760,360)
 dialog.add_theme_stylebox_override("panel",panel_style())
 ui.add_child(dialog)
 var box = VBoxContainer.new()
 box.add_theme_constant_override("separation",22)
 dialog.add_child(box)
 dialog_title = text_label(24,"b4cba7")
 box.add_child(dialog_title)
 dialog_body = text_label(21)
 dialog_body.custom_minimum_size = Vector2(704,190)
 dialog_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 box.add_child(dialog_body)
 dialog_hint = text_label(16,"99acac")
 dialog_hint.text = "ENTER / E  ·  Continue"
 box.add_child(dialog_hint)
 dialog.hide()

func _menu() -> void:
 header.hide()
 objective.hide()
 active = false
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 menu = PanelContainer.new()
 menu.position = Vector2(80,135)
 menu.size = Vector2(620,470)
 menu.add_theme_stylebox_override("panel",panel_style())
 ui.add_child(menu)
 var box = VBoxContainer.new()
 box.add_theme_constant_override("separation",14)
 menu.add_child(box)
 var eyebrow = text_label(16,"95b3ad")
 eyebrow.text = "A DOCTOR WHO FAN GAME  /  GODOT 4"
 box.add_child(eyebrow)
 var title = text_label(82,"e2e7d8")
 title.text = "B L I N K"
 box.add_child(title)
 var sub = text_label(22,"adc1bf")
 sub.text = "WESTER DRUMLINS"
 box.add_child(sub)
 var desc = text_label(17)
 desc.text = "Twelve chapters. One impossible message.\nPS1-style playable prototype · original scenery and audio"
 box.add_child(desc)
 for item in ["BEGIN STORY", "CONTINUE CHECKPOINT", "CONTROLS"]:
  var b = Button.new()
  b.text = item
  b.custom_minimum_size.y = 40
  b.add_theme_font_size_override("font_size",18)
  box.add_child(b)
  if item == "BEGIN STORY": b.pressed.connect(_start)
  elif item == "CONTINUE CHECKPOINT":
   b.disabled = not FileAccess.file_exists("user://blink-save.json")
   b.pressed.connect(_continue)
  else: b.pressed.connect(func(): _show("CONTROLS",_help_text(),"menu"))

func _start() -> void:
 header.show()
 objective.show()
 menu.hide()
 entries.clear()
 active = true
 _load_chapter(0,true)

func _continue() -> void:
 header.show()
 objective.show()
 var data = JSON.parse_string(FileAccess.get_file_as_string("user://blink-save.json"))
 if not data is Dictionary or not data.has("chapter"):
  _start()
  return
 entries.clear()
 for e in data.get("entries",[]): entries.append(str(e))
 guided = bool(data.get("guided",false))
 menu.hide()
 active = true
 _load_chapter(clampi(int(data.chapter),0,11),true)

func _save() -> void:
 if smoke_mode: return
 var f = FileAccess.open("user://blink-save.json",FileAccess.WRITE)
 if f: f.store_string(JSON.stringify({"chapter":chapter,"entries":entries,"guided":guided}))

func _load_chapter(index: int, show_intro: bool = true) -> void:
 chapter = index
 step = 0
 eye_timer = 0
 blink_left = 0
 if world:
  view.remove_child(world)
  world.free()
 world = World.new()
 view.add_child(world)
 world.build(Story.CHAPTERS[chapter].place,chapter)
 player = CharacterBody3D.new()
 world.add_child(player)
 player.position = Vector3(0,0,7)
 var col = CollisionShape3D.new()
 var cap = CapsuleShape3D.new()
 cap.radius = .28
 cap.height = 1.7
 col.shape = cap
 col.position.y = .85
 player.add_child(col)
 camera = Camera3D.new()
 camera.position.y = 1.6
 camera.fov = 68
 player.add_child(camera)
 torch = SpotLight3D.new()
 camera.add_child(torch)
 torch.light_color = Color("d9e0d3")
 torch.light_energy = 3
 torch.spot_range = 18
 torch.spot_angle = 35
 torch.spot_attenuation = 1.1
 torch.shadow_enabled = true
 torch.position = Vector3(.2,-.15,0)
 marker = Label3D.new()
 world.add_child(marker)
 marker.text = "◇"
 marker.font_size = 54
 marker.pixel_size = .009
 marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 marker.modulate = Color("cadb9e")
 marker.no_depth_test = false
 for id in ["kathy","visitor","larry","key","doctor","folder","list"]:
  if world.objects.has(id):
   var relevant = false
   for s in Story.CHAPTERS[chapter].steps:
    if s[0] == id: relevant = true
   world.objects[id].visible = relevant
 _refresh()
 if show_intro:
  _save()
  _show(Story.CHAPTERS[chapter].title,Story.CHAPTERS[chapter].intro,"resume")

func _show(title: String, body: String, next: String = "resume") -> void:
 modal = true
 if not active and is_instance_valid(menu) and next == "menu": menu.hide()
 pending = next
 dialog_title.text = title
 dialog_body.text = body
 dialog.show()
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close() -> void:
 dialog.hide()
 modal = false
 match pending:
  "next":
   if chapter == 11:
    active = false
    _show("THE LOOP IS CLOSED","Sally’s evidence completes the circle.\n\nYou finished this playable adaptation of Blink.\n\nOriginal code, low-poly models, textures and sound.\nEpisode by Steven Moffat · Doctor Who belongs to its rights holders.","end")
   else: _load_chapter(chapter+1,true)
  "retry", "retry_confirm": _load_chapter(chapter,true)
  "menu": menu.show()
  "end":
   menu.show()
   active = false
 if active and not modal: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _refresh() -> void:
 header.text = Story.CHAPTERS[chapter].title
 var s = Story.CHAPTERS[chapter].steps[step]
 objective.text = s[1]
 marker.position = world.objects[s[0]].position + Vector3(0,2.75,0)
 marker.visible = guided

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and active and not modal and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  player.rotate_y(-event.relative.x*sensitivity)
  camera.rotation.x = clampf(camera.rotation.x-event.relative.y*sensitivity,-1.25,1.25)
 if event.is_action_pressed("confirm") or event.is_action_pressed("use"):
  if modal: _close()
  elif active: _interact()
  elif not menu.visible: menu.show()
 if event.is_action_pressed("pause_game"):
  if modal:
   if pending == "retry_confirm": pending = "resume"
   _close()
  elif active: _show("PAUSED", "The world is paused.\n\n"+_help_text())
 if not active or modal: return
 if event is InputEventMouseButton and event.pressed: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 if event.is_action_pressed("torch"): torch.visible = not torch.visible
 if event.is_action_pressed("blink") and blink_left <= 0:
  blink_left = .22
  eye_timer = 0
 if event.is_action_pressed("journal"):
  var recent = entries.slice(maxi(0,entries.size()-5))
  _show("EVIDENCE / MOST RECENT", "\n\n".join(recent) if not recent.is_empty() else "Your journal is empty. Photograph the writing at Wester Drumlins.")
 if event.is_action_pressed("help"): _show("CONTROLS",_help_text())
 if event.is_action_pressed("guide"):
  guided = not guided
  _refresh()
 if event.is_action_pressed("retry"): _show("RESTART CHECKPOINT?","Press Enter to restart this chapter, or Escape to cancel.","retry_confirm")

func _help_text() -> String:
 return "WASD  Move     Mouse / arrow keys  Look\nE  Interact     F  Torch     B  Blink\nJ  Evidence     G  Guided mode     R  Restart chapter\nEsc  Pause     Enter  Continue text\n\nAngels move outside your sight. Walls block sight.\nBlinking is automatic after 13 seconds. G shows a goal marker and slows Angels. Progress saves at chapter starts."

func _target() -> Node3D:
 return world.objects[Story.CHAPTERS[chapter].steps[step][0]]

func _can_interact() -> bool:
 var target = _target().global_position + Vector3(0,1.3,0)
 var delta = target-camera.global_position
 return delta.length() < 3.6 and -camera.global_basis.z.dot(delta.normalized()) > .65

func _interact() -> void:
 if not _can_interact(): return
 _advance_step()

func _advance_step() -> void:
 var s = Story.CHAPTERS[chapter].steps[step]
 entries.append(s[2])
 if chapter == 0 and step == 0: world.objects.paper.get_child(1).show()
 if chapter == 2 and step == 1: world.objects.kathy.hide()
 if chapter == 5 and step == 2:
  world.objects.box.hide()
  world.objects.billy.hide()
 if chapter == 10 and step == 0:
  world.objects.console.hide()
  for p in [Vector3(-3,0,-3),Vector3(3,0,-3),Vector3(0,0,-6),Vector3(0,0,0)]:
   var a = world.angel(p)
   a.look_at(Vector3(0,1,-3)+Vector3(.001,0,.001))
 if step == Story.CHAPTERS[chapter].steps.size()-1:
  _show("EVIDENCE RECORDED",s[2],"next")
 else:
  step += 1
  _refresh()
  _show("EVIDENCE RECORDED",s[2])

func _physics_process(delta: float) -> void:
 if not active or modal: return
 elapsed += delta
 var look = float(Input.is_physical_key_pressed(KEY_LEFT))-float(Input.is_physical_key_pressed(KEY_RIGHT))
 player.rotate_y(look*delta*1.8)
 var tilt = float(Input.is_physical_key_pressed(KEY_UP))-float(Input.is_physical_key_pressed(KEY_DOWN))
 camera.rotation.x = clampf(camera.rotation.x+tilt*delta,-1.25,1.25)
 var vec = Input.get_vector("left","right","forward","back")
 var dir = player.global_basis * Vector3(vec.x,0,vec.y)
 player.velocity = dir*3.0
 player.velocity.y = -2.0
 player.move_and_slide()
 if vec.length() > .1:
  footsteps += delta*9
  camera.position.y = 1.6 + sin(footsteps)*.022
 eye_timer += delta
 if eye_timer > 13:
  eye_timer = 0
  blink_left = .22
 blink_left = maxf(0,blink_left-delta)
 lid.visible = blink_left > 0
 _update_angels(delta)
 prompt.text = "E  ·  " + str(Story.CHAPTERS[chapter].steps[step][1]) if _can_interact() else ""
 status.text = "E  INTERACT   /   J  EVIDENCE   /   H  HELP   /   G  GUIDE %s\nEYE STRAIN  %02d%%     •     %s" % ["ON" if guided else "OFF", int(eye_timer/13*100),"KEEP WATCHING" if Story.CHAPTERS[chapter].get("danger",false) else "INVESTIGATE"]

func observed(a: Node3D) -> bool:
 if blink_left > 0: return false
 for offset in [Vector3(0,1.9,0),Vector3(-.6,1.5,0),Vector3(.6,1.5,0),Vector3(0,.8,0)]:
  var p = a.global_position + offset
  if not camera.is_position_in_frustum(p): continue
  var q = PhysicsRayQueryParameters3D.create(camera.global_position,p)
  q.exclude = [player.get_rid()]
  var hit = world.get_world_3d().direct_space_state.intersect_ray(q)
  if hit.is_empty(): return true
 return false

func _update_angels(delta: float) -> void:
 if not Story.CHAPTERS[chapter].get("danger",false): return
 for a in world.angels:
  if observed(a): continue
  var towards = player.global_position-a.global_position
  towards.y = 0
  if towards.length() < .7:
   _show("DISPLACED", "A touch. A different year.\n\nReturn to the checkpoint and keep the Angel in view. Back away instead of turning around.","retry")
   return
  var movement = towards.normalized()*delta*(1.2 if guided else 2.3)
  var q = PhysicsRayQueryParameters3D.create(a.global_position+Vector3(0,.9,0),a.global_position+Vector3(0,.9,0)+movement*3)
  q.exclude = [player.get_rid()]
  if world.get_world_3d().direct_space_state.intersect_ray(q).is_empty(): a.position += movement
  a.look_at(Vector3(player.global_position.x,a.global_position.y,player.global_position.z))

func _smoke_test() -> void:
 # Exercise actual progression, capture/retry and observation rather than only parsing.
 active = true
 menu.hide()
 for c in range(12):
  _load_chapter(c,false)
  await get_tree().physics_frame
  for s in range(Story.CHAPTERS[c].steps.size()):
   assert(world.objects.has(Story.CHAPTERS[c].steps[s][0]))
   player.position = _target().position + Vector3(0,0,2.7)
   camera.look_at(_target().position+Vector3(0,1.3,0))
   assert(_can_interact(),"Target cannot be reached")
   var previous_count = entries.size()
   _interact()
   assert(entries.size() == previous_count+1,"Interaction failed")
   dialog.hide()
   modal = false
  print("PASS chapter ",c+1)
 _load_chapter(9,false)
 await get_tree().physics_frame
 var a = world.angels[0]
 player.position = Vector3(-5,0,0)
 camera.look_at(a.position+Vector3(0,1.7,0))
 await get_tree().physics_frame
 assert(observed(a),"Visible Angel must freeze")
 var old = a.position
 _update_angels(.1)
 assert(a.position == old,"Observed Angel moved")
 blink_left = .2
 assert(not observed(a),"Blink must release Angel")
 _update_angels(.1)
 assert(a.position != old,"Unobserved Angel did not move")
 blink_left = 0
 world.block(world,Vector3(-5,1.6,-3),Vector3(3,3,.3),world.stone)
 await get_tree().physics_frame
 assert(not observed(a),"Wall must block gaze")
 print("PASS observation, blink, movement, occlusion; all 12 chapter chains")
 await get_tree().process_frame
 get_tree().quit()
