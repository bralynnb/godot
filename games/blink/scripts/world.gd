extends "res://scripts/world_base.gd"
# One Godot unit = one metre. Two connected levels at 0 m and 3.3 m.
var spawn = Vector3(0,0,7.7)
var location = ""
var cast: Array[Dictionary] = []
var time = 0.0
var window_lights: Array[SpotLight3D] = []
var light_tick = 0.0
var room_regions: Array[Dictionary] = []
var wallpaper: MeshInstance3D
var writing: Label3D
var dust: CPUParticles3D

func sphere(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, segments: int = 12) -> MeshInstance3D:
 var m = MeshInstance3D.new()
 var mesh = SphereMesh.new()
 mesh.radius = .5
 mesh.height = 1
 mesh.radial_segments = segments
 mesh.rings = 6
 m.mesh = mesh
 m.material_override = mat
 parent.add_child(m)
 m.position = pos
 m.scale = size
 return m

func pivot(parent: Node3D, pos: Vector3) -> Node3D:
 var p = Node3D.new()
 parent.add_child(p)
 p.position = pos
 return p

func person(id: String, pos: Vector3, stone_body: bool = false, player_body: bool = false) -> Node3D:
 var root = pivot(self,pos)
 var skin = stone if stone_body else material(Color("b28e78") if id != "billy" else Color("75533e"))
 var coat = stone if stone_body else material(Color("52574a") if id in ["sally","kathy"] else (Color("58453c") if id == "doctor" else Color("464e5b")))
 var trousers = stone if stone_body else material(Color("353c46"))
 var hair = stone if stone_body else material(Color("514037") if id in ["sally","kathy"] else Color("322a29"))
 var boots = stone if stone_body else material(Color("26282b"))
 var torso = pivot(root,Vector3(0,.95,0))
 jacket_mesh(torso,coat)
 sphere(torso,Vector3(0,-.035,0),Vector3(.34,.22,.25),trousers)
 # Collar, coat opening and buttons.
 for side in [-1,1]:
  block(torso,Vector3(side*.08,.41,.125),Vector3(.1,.17,.025),coat,false).rotation.z = side*.28
 for y in [.05,.18,.31]: sphere(torso,Vector3(.035,y,.142),Vector3(.018,.018,.015),stone if stone_body else brass,6)
 var head = pivot(torso,Vector3(0,.55,0))
 cylinder(head,Vector3(0,-.045,0),.065,.075,.12,skin)
 sphere(head,Vector3(0,.115,.01),Vector3(.235,.3,.23),skin)
 sphere(head,Vector3(0,.225,-.025),Vector3(.253,.18,.255),hair)
 if id in ["sally","kathy"]:
  sphere(head,Vector3(0,.06,-.105),Vector3(.26,.34,.12),hair)
 sphere(head,Vector3(0,.105,.139),Vector3(.046,.076,.06),skin,8)
 for side in [-1,1]:
  sphere(head,Vector3(side*.052,.15,.113),Vector3(.037,.016,.012),dark,8)
  sphere(head,Vector3(side*.122,.11,0),Vector3(.035,.07,.04),skin,8)
 block(head,Vector3(0,.052,.11),Vector3(.057,.01,.008),hair,false)
 var arms: Array[Node3D] = []
 var knees: Array[Node3D] = []
 var legs: Array[Node3D] = []
 var elbows: Array[Node3D] = []
 for side in [-1,1]:
  var arm = pivot(torso,Vector3(side*.25,.41,0))
  cylinder(arm,Vector3(0,-.14,0),.079,.067,.32,coat)
  sphere(arm,Vector3(0,0,0),Vector3(.18,.18,.18),coat)
  var elbow = pivot(arm,Vector3(0,-.3,0))
  cylinder(elbow,Vector3(0,-.13,.015),.065,.052,.29,coat)
  sphere(elbow,Vector3(0,-.3,.02),Vector3(.10,.14,.065),skin)
  for finger in range(4):
   sphere(elbow,Vector3(-.03+finger*.02,-.365,.025),Vector3(.017,.065,.019),skin,6)
  arms.append(arm)
  elbows.append(elbow)
  var leg = pivot(root,Vector3(side*.105,.88,0))
  cylinder(leg,Vector3(0,-.2,0),.095,.073,.44,trousers)
  var knee = pivot(leg,Vector3(0,-.4,0))
  cylinder(knee,Vector3(0,-.19,0),.073,.058,.40,trousers)
  sphere(knee,Vector3(0,-.4,.065),Vector3(.17,.14,.31),boots)
  legs.append(leg)
  knees.append(knee)
 if stone_body:
  for arm in arms: arm.hide()
 if player_body:
  for child in head.find_children("*","MeshInstance3D",true,false): child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
 if not stone_body:
  cast.append({"root":root,"torso":torso,"head":head,"arms":arms,"legs":legs,"knees":knees,"elbows":elbows,"origin":pos,"id":id,"player":player_body})
 return root

func angel(pos: Vector3) -> Node3D:
 var a = person("angel",pos,true)
 a.scale = Vector3.ONE*1.16
 # Sculpted robe with alternating radial folds, a shaped waist and hem.
 var surface = SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var rings = [[.08,.37],[.35,.32],[.7,.24],[.96,.19]]
 for j in range(3):
  for i in range(24):
   var pts: Array[Vector3] = []
   for k in [[j,i],[j,i+1],[j+1,i],[j+1,i+1]]:
    var angle = float(k[1])*TAU/24
    var r = float(rings[k[0]][1]) * (1.0 if int(k[1])%2 == 0 else .87)
    pts.append(Vector3(sin(angle)*r,rings[k[0]][0],cos(angle)*r))
   for idx in [0,2,1,1,2,3]: surface.add_vertex(pts[idx])
 surface.generate_normals()
 var robe = MeshInstance3D.new()
 robe.mesh = surface.commit()
 robe.material_override = stone
 a.add_child(robe)
 # Bent arms and individually layered stone feathers.
 var torso = a.get_child(0)
 for side in [-1,1]:
  for i in range(11):
   var feather = sphere(a,Vector3(side*(.28+i*.062),1.30+i*.054,-.12-i*.026),Vector3(.14,.74-i*.025,.075),stone,8)
   feather.rotation.z = side*(-.4-i*.075)
  sphere(a,Vector3(side*.21,1.48,.20),Vector3(.15,.45,.15),stone).rotation.z = side*.45
  sphere(a,Vector3(side*.087,1.67,.15),Vector3(.085,.25,.07),stone)
  for f in range(4): sphere(a,Vector3(side*(.045+f*.025),1.74,.185),Vector3(.021,.14,.025),stone,6)
 angels.append(a)
 return a

func prop(id: String, pos: Vector3, kind: String = "paper") -> Node3D:
 if kind == "person":
  var p = person(id,pos)
  objects[id] = p
  return p
 return super.prop(id,pos,kind)

func setup() -> void:
 stone = material(Color("a5a9a2"),"stone")
 wood = material(Color("6c5040"),"wood")
 plaster = material(Color("939486"),"wall")
 blue = material(Color("264f72"),"wood")
 dark = material(Color("202529"))
 brass = material(Color("978361"))
 var env = WorldEnvironment.new()
 env.environment = Environment.new()
 env.environment.background_mode = Environment.BG_COLOR
 env.environment.background_color = Color("536778")
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color("a1b1c5")
 env.environment.ambient_light_energy = .34
 env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 env.environment.fog_enabled = true
 env.environment.fog_light_color = Color("637582")
 env.environment.fog_density = .007
 add_child(env)
 var sun = DirectionalLight3D.new()
 add_child(sun)
 sun.rotation_degrees = Vector3(-25,-25,0)
 sun.light_color = Color("c0d0dc")
 sun.light_energy = .85
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 55
 sun.shadow_bias = .035

func wall(pos: Vector3, size: Vector3) -> void:
 block(self,pos,size,plaster)
 var trim = size
 trim.y = .13
 block(self,Vector3(pos.x,pos.y-size.y/2+.12,pos.z),trim+Vector3(.045,0,.045),wood,false)
 block(self,Vector3(pos.x,pos.y+size.y/2-.14,pos.z),trim+Vector3(.065,.04,.065),material(Color("aaa89a")),false)

func partition(x: float, start: float, finish: float, door_z: float, y: float) -> void:
 # Wall parallel to z, with a genuinely open 1.6 m doorway.
 for span in [[start,door_z-.8],[door_z+.8,finish]]:
  if span[1] > span[0]: wall(Vector3(x,y+1.65,(span[0]+span[1])/2),Vector3(.18,3.3,span[1]-span[0]))
 block(self,Vector3(x,y+2.88,door_z),Vector3(.2,.84,1.6),plaster)
 for z in [door_z-.86,door_z+.86]: block(self,Vector3(x,y+1.23,z),Vector3(.24,2.46,.10),wood,false)
 block(self,Vector3(x,y+2.46,door_z),Vector3(.24,.12,1.82),wood,false)

func crosswall(x1: float, x2: float, z: float, door_x: float, y: float) -> void:
 for span in [[x1,door_x-.8],[door_x+.8,x2]]:
  if span[1] > span[0]: wall(Vector3((span[0]+span[1])/2,y+1.65,z),Vector3(span[1]-span[0],3.3,.18))
 block(self,Vector3(door_x,y+2.88,z),Vector3(1.6,.84,.18),plaster)
 for x in [door_x-.86,door_x+.86]: block(self,Vector3(x,y+1.23,z),Vector3(.10,2.46,.24),wood,false)

func window_wall(center: Vector3, width: float, angle: float = 0) -> Node3D:
 var root = pivot(self,center)
 root.rotation.y = angle
 # A transparent opening, not a picture over an opaque wall.
 block(root,Vector3(0,.48,0),Vector3(width,.96,.22),plaster)
 block(root,Vector3(0,3.05,0),Vector3(width,.5,.22),plaster)
 var side = (width-1.8)/2
 for x in [-1,1]:
  block(root,Vector3(x*(.9+side/2),1.88,0),Vector3(side,1.84,.22),plaster)
  block(root,Vector3(x*.94,1.87,.04),Vector3(.12,1.98,.15),wood,false)
 block(root,Vector3(0,.99,.09),Vector3(2.15,.12,.34),wood,false)
 for y in [1.05,1.9,2.78]: block(root,Vector3(0,y,.05),Vector3(1.8,.065,.10),wood,false)
 block(root,Vector3(0,1.9,.05),Vector3(.055,1.8,.10),wood,false)
 var glass = material(Color(.55,.73,.78,.18))
 glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 glass.cull_mode = BaseMaterial3D.CULL_DISABLED
 glass.roughness = .18
 var pane = block(root,Vector3(0,1.9,0),Vector3(1.8,1.8,.015),glass,false)
 pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var body = StaticBody3D.new()
 pane.add_child(body)
 body.collision_layer = 2
 var shape = CollisionShape3D.new()
 shape.shape = BoxShape3D.new()
 shape.shape.size = Vector3(1.8,1.8,.04)
 body.add_child(shape)
 var beam = SpotLight3D.new()
 root.add_child(beam)
 beam.position = Vector3(0,2.4,.25)
 beam.rotation_degrees = Vector3(-16,180,0)
 beam.light_color = Color("b7d0e2")
 beam.light_energy = 3
 beam.spot_range = 11
 beam.spot_angle = 44
 beam.shadow_enabled = false
 beam.visible = false
 window_lights.append(beam)
 beam.shadow_bias = .02
 return root

func chair(pos: Vector3, angle: float = 0) -> void:
 var p = pivot(self,pos)
 p.rotation.y = angle
 block(p,Vector3(0,.48,0),Vector3(.46,.10,.48),wood)
 for x in [-.18,.18]:
  for z in [-.18,.18]: block(p,Vector3(x,.23,z),Vector3(.06,.46,.06),wood,false)
  block(p,Vector3(x,.76,-.19),Vector3(.06,.62,.06),wood,false)
 for y in [.71,.92]: block(p,Vector3(0,y,-.19),Vector3(.42,.1,.07),wood,false)

func fireplace(pos: Vector3, angle: float = 0) -> void:
 var p = pivot(self,pos)
 p.rotation.y = angle
 block(p,Vector3(0,.65,0),Vector3(1.8,1.3,.35),dark)
 for x in [-.87,.87]: block(p,Vector3(x,.73,.17),Vector3(.21,1.46,.55),stone)
 block(p,Vector3(0,1.49,.13),Vector3(2.12,.16,.62),stone)
 block(p,Vector3(0,.035,.3),Vector3(2.2,.07,1),stone)
 for i in range(5): block(p,Vector3(-.48+i*.24,.12,.3),Vector3(.20,.08,.45),wood,false).rotation.y = i*.2
 # Empty portrait frame above the mantel.
 for x in [-.55,.55]: block(p,Vector3(x,2.15,.02),Vector3(.08,.85,.08),brass,false)
 for y in [1.72,2.58]: block(p,Vector3(0,y,.02),Vector3(1.18,.08,.08),brass,false)
 block(p,Vector3(0,2.15,0),Vector3(1.05,.8,.03),material(Color("343f3d"),"stone"),false)

func stairs() -> void:
 for i in range(20):
  var h = (i+1)*.165
  block(self,Vector3(0,h/2,.85-i*.3),Vector3(2.35,h,.30),wood,false)
  block(self,Vector3(0,h+.008,.84-i*.3),Vector3(.94,.012,.28),material(Color("62514a"),"paper"),false)
 # Smooth collision surface under the visible treads.
 var body = StaticBody3D.new()
 add_child(body)
 body.position = Vector3(0,1.60,-2)
 body.rotation.x = atan(3.3/6.0)
 var shape = CollisionShape3D.new()
 shape.shape = BoxShape3D.new()
 shape.shape.size = Vector3(2.4,.10,sqrt(6*6+3.3*3.3))
 body.add_child(shape)
 for side in [-1,1]:
  for i in range(21):
   var z = 1-i*.30
   var y = i*.165
   cylinder(self,Vector3(side*1.24,y+.43,z),.025,.035,.86,wood)
  var rail = block(self,Vector3(side*1.24,2.58,-2),Vector3(.1,.09,6.85),wood,false)
  rail.rotation.x = atan(3.3/6.0)
  # Physical rail keeps the player from slipping out of the stairwell.
  var barrier = block(self,Vector3(side*1.31,2.17,-2),Vector3(.08,.85,6.85),wood)
  barrier.rotation.x = atan(3.3/6.0)
  barrier.visible = false
 for side in [-1,1]:
  for i in range(21): cylinder(self,Vector3(side*1.42,3.75,1-i*.3),.025,.035,.9,wood)
  block(self,Vector3(side*1.42,4.22,-2),Vector3(.1,.1,6.2),wood)

func house(chapter: int) -> void:
 setup()
 var floor_mat = material(Color("aa9181"),"floor")
 floor_mat.uv1_scale = Vector3(8,9,1)
 block(self,Vector3(0,-.12,0),Vector3(16,.24,18),floor_mat)
 # Upstairs floor leaves a real opening over the staircase.
 for rect in [[-8,-1.4,-9,9],[1.4,8,-9,9],[-1.4,1.4,-9,-5],[-1.4,1.4,1,9]]:
  block(self,Vector3((rect[0]+rect[1])/2,3.20,(rect[2]+rect[3])/2),Vector3(rect[1]-rect[0],.2,rect[3]-rect[2]),floor_mat)
 block(self,Vector3(0,6.65,0),Vector3(16,.15,18),material(Color("99988d"),"stone"))
 for y in [0.0,3.3]:
  for x in [-5.0,5.0]:
   window_wall(Vector3(x,y,-9),6)
   window_wall(Vector3(x,y,9),6,PI)
  wall(Vector3(0,y+1.65,-9),Vector3(4,3.3,.22))
  wall(Vector3(0,y+1.65,9),Vector3(4,3.3,.22))
  wall(Vector3(-8,y+1.65,0),Vector3(.22,3.3,18))
  wall(Vector3(8,y+1.65,0),Vector3(.22,3.3,18))
  for x in [-2.1,2.1]:
   partition(x,-9,0,-6.8,y)
   partition(x,0,9,5,y)
  crosswall(-8,-2.1,0,-5,y)
  crosswall(2.1,8,0,5,y)
 stairs()
 # Distinct parlor, study, upper warning room and conservatory/gallery.
 fireplace(Vector3(-7.7,0,3.3),PI/2)
 objects["fireplace"] = pivot(self,Vector3(-7.35,0,3.3))
 objects["landing"] = pivot(self,Vector3(0,3.3,-6.5))
 fireplace(Vector3(-7.7,3.3,-5.5),PI/2)
 fireplace(Vector3(7.7,0,3.6),-PI/2)
 for pos in [Vector3(-5,0,4),Vector3(-6,0,5.7),Vector3(5,0,3.7),Vector3(-5.7,3.3,-5.8)]: chair(pos,.3)
 for x in [4.5,6]:
  block(self,Vector3(x,.78,5.5),Vector3(1.3,.12,.8),wood)
  for dx in [-.5,.5]: block(self,Vector3(x+dx,.38,5.5),Vector3(.08,.76,.65),wood)
 for y in [.5,1.15,1.8,2.45]:
  block(self,Vector3(7.6,y,6.5),Vector3(.5,.09,3),wood)
  for i in range(14): block(self,Vector3(7.56,y+.22,5.1+i*.20),Vector3(.3,.4,.13),material(Color.from_hsv(.05+i*.016,.22,.35)),false)
 # Grounds visible through every real window.
 block(self,Vector3(0,-.18,0),Vector3(70,.1,70),material(Color("414a40"),"stone"),false)
 for i in range(18):
  var x = -24+fmod(i*7.3,48)
  var z = -14-fmod(i*4.9,12)
  cylinder(self,Vector3(x,2,z),.13,.32,4,wood)
  for s in [-1,1]:
   var branch = cylinder(self,Vector3(x+s*.5,3.3,z),.04,.1,2.1,wood)
   branch.rotation.z = s*.6
  sphere(self,Vector3(x,5,z),Vector3(3.5,3.7,3),material(Color("354940")),8)
 # Large barred entrance and authentic-sized cellar door.
 prop("exit",Vector3(0,0,8.83),"door").rotation.y = PI
 prop("cellar",Vector3(7.82,0,-4),"door").rotation.y = -PI/2
 prop("visitor",Vector3(.4,0,7.2),"person").rotation.y = PI
 prop("kathy",Vector3(-5,3.3,-5),"person")
 prop("larry",Vector3(-4.4,3.3,-4.2),"person")
 prop("tv",Vector3(-5.3,3.3,-7.2),"tv")
 # Warning on a side wall; glass overlooks the same garden statue.
 var paper = pivot(self,Vector3(-7.85,3.3,-7.0))
 paper.rotation.y = PI/2
 objects["paper"] = paper
 objects["message"] = paper
 wallpaper = block(paper,Vector3(0,1.55,.015),Vector3(1.8,1.45,.018),material(Color("b8b096"),"paper"),false)
 writing = Label3D.new()
 paper.add_child(writing)
 writing.position = Vector3(0,1.55,.04)
 writing.text = "SALLY SPARROW\n1969"
 writing.font_size = 36
 writing.pixel_size = .004
 writing.modulate = Color("333830")
 writing.outline_size = 0
 writing.visible = chapter != 0
 objects["window"] = pivot(self,Vector3(-5,3.3,-8.92))
 objects["window"].set_meta("focus_height",1.8)
 var garden_angel = angel(Vector3(-5,0,-13))
 garden_angel.rotation.y = 0
 if chapter == 2:
  angel(Vector3(4.7,3.3,-6))
  angel(Vector3(6.5,3.3,-7))
 prop("key",Vector3(4.7,3.3,-5.7),"key")
 if chapter == 8:
  var attacker = angel(Vector3(-6,3.3,-8))
  attacker.set_meta("pursuer",true)
 if chapter in [7,8]: spawn = Vector3(-4,3.3,-3)
 # Dust particles float in window light; no strobe lighting.
 dust = CPUParticles3D.new()
 add_child(dust)
 dust.position = Vector3(-5,4.8,-6)
 dust.amount = 65
 dust.lifetime = 10
 dust.preprocess = 10
 dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
 dust.emission_box_extents = Vector3(2,1.3,2.7)
 dust.gravity = Vector3(0,-.025,0)
 dust.initial_velocity_min = .02
 dust.initial_velocity_max = .06
 dust.scale_amount_min = .009
 dust.scale_amount_max = .018
 dust.mesh = SphereMesh.new()
 var dm = material(Color(.7,.75,.73,.20))
 dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 dust.mesh.material = dm
 light_at(Vector3(0,2.7,5.5),Color("b6a182"),.55,5.5)
 lights[-1].shadow_enabled = true

func build(kind: String, chapter: int) -> void:
 location = kind
 if kind == "house": house(chapter)
 else:
  super.build(kind,chapter)
  # Compact secondary sets without shrinking furniture or people.
  for child in get_children():
   if child is Node3D:
    child.position.x *= .68
    child.position.z *= .68
    if child is MeshInstance3D: child.scale *= Vector3(.68,1,.68)
  for person_data in cast: person_data.origin = person_data.root.position
  spawn = Vector3(0,0,5.5)
  for l in lights:
   l.shadow_enabled = true
   l.light_energy *= .7
  if kind in ["flat","shop","hospital"]:
   for child in get_children():
    if child is MeshInstance3D and absf(child.position.z+7.48)<.03 and child.position.y>1:
     remove_child(child)
     child.queue_free()
   if objects.has("window"):
    var old_window = objects.window
    remove_child(old_window)
    old_window.queue_free()
   objects["window"] = window_wall(Vector3(0,0,-7.48),12.24)
   # Wall partitions make shop counter, sitting area and patient alcove.
   partition(-3,-7.2,3,-1,0)
  if kind == "cellar":
   for a in angels: a.set_meta("pursuer",true)
   for z in [-4,0,4]:
    block(self,Vector3(0,3.45,z),Vector3(11.8,.3,.28),wood)
  for child in get_children():
   if child is WorldEnvironment:
    child.environment.ambient_light_energy = .36
    child.environment.fog_density = .012
 optimize_geometry()

func reveal_paper() -> void:
 if is_instance_valid(writing):
  writing.show()
  wallpaper.rotation.z = .06

func room_name(pos: Vector3) -> String:
 if location != "house": return location.to_upper()
 var upper = pos.y > 2.6
 if absf(pos.x)<2.1: return "UPPER LANDING" if upper else "ENTRANCE HALL / STAIRS"
 if pos.x<0:
  if pos.z<0: return "WARNING ROOM" if upper else "REAR PARLOR"
  return "WEST BEDROOM" if upper else "DRAWING ROOM"
 if pos.z<0: return "STATUE GALLERY" if upper else "CONSERVATORY / CELLAR DOOR"
 return "EAST BEDROOM" if upper else "STUDY"

func update_lights(observer: Vector3) -> void:
 var sorted = window_lights.duplicate()
 sorted.sort_custom(func(a,b): return a.global_position.distance_squared_to(observer) < b.global_position.distance_squared_to(observer))
 for i in range(sorted.size()):
  sorted[i].visible = i < 2
  sorted[i].shadow_enabled = i < 2

func animate(delta: float, observer: Node3D, speed: float) -> void:
 time += delta
 light_tick -= delta
 if light_tick <= 0:
  update_lights(observer.global_position)
  light_tick = .4
 for actor in cast:
  var root: Node3D = actor.root
  if not is_instance_valid(root) or not root.visible: continue
  var moving = speed if actor.player else 0.0
  # Kathy paces a short clear route, stopping to look around.
  if not actor.player and actor.id == "kathy":
   var phase = fmod(time,16)
   var distance = 0.0
   if phase < 4: distance = phase*.22; moving = .45
   elif phase < 8: distance = .88
   elif phase < 12: distance = (12-phase)*.22; moving = .45
   root.position = actor.origin + Vector3(0,0,distance)
   root.rotation.y = 0 if phase < 8 else PI
  var cycle = time*7.0
  actor.torso.position.y = .95+sin(time*1.8)*.006+absf(sin(cycle))*moving*.012
  for i in range(2):
   var stride = sin(cycle+i*PI)*moving*.4
   actor.legs[i].rotation.x = stride
   actor.knees[i].rotation.x = maxf(0,-stride)*.6
   actor.arms[i].rotation.x = -stride*.65+.035*sin(time+i)
   actor.elbows[i].rotation.x = -.15-absf(stride)*.2
  if not actor.player:
   var to = observer.global_position-root.global_position
   var target_yaw = wrapf(atan2(to.x,to.z)-root.rotation.y,-PI,PI)
   actor.head.rotation.y = lerp_angle(actor.head.rotation.y,clampf(target_yaw,-.6,.6),delta*2)

func chase_path(start: Vector3, goal: Vector3) -> PackedVector3Array:
 if location != "house": return PackedVector3Array([goal])
 var nav = AStar3D.new()
 var points: Array[Vector3] = []
 for y in [0.0,3.3]:
  for p in [Vector3(0,0,5),Vector3(0,0,2),Vector3(0,0,-6.8),Vector3(-2.1,0,5),Vector3(-5,0,5),Vector3(2.1,0,5),Vector3(5,0,5),Vector3(-2.1,0,-6.8),Vector3(-5,0,-6.8),Vector3(2.1,0,-6.8),Vector3(5,0,-6.8),Vector3(-5,0,0),Vector3(5,0,0)]: points.append(p+Vector3(0,y,0))
 for i in range(points.size()): nav.add_point(i,points[i])
 for offset in [0,13]:
  for e in [[0,1],[0,3],[3,4],[0,5],[5,6],[2,7],[7,8],[2,9],[9,10],[4,11],[11,8],[6,12],[12,10]]: nav.connect_points(e[0]+offset,e[1]+offset)
 # Both levels connect around the landing; ground centre passes below the stair.
 nav.add_point(26,Vector3(0,0,1.1))
 nav.add_point(27,Vector3(0,3.3,-5.1))
 nav.connect_points(1,26)
 nav.connect_points(26,27)
 nav.connect_points(27,15)
 # Upstairs east/west rooms link front and rear through real internal doors.
 var s = nav.get_closest_point(start)
 var g = nav.get_closest_point(goal)
 var result = nav.get_point_path(s,g)
 if result.size() > 0 and start.distance_to(result[0])<1: result.remove_at(0)
 result.append(goal)
 return result

func merge_group(parent: Node3D, meshes: Array) -> void:
 var groups = {}
 for mesh in meshes:
  var mat = mesh.material_override
  if mat is StandardMaterial3D and mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: continue
  var key = str(mat.get_instance_id())+":"+str(mesh.cast_shadow)
  if not groups.has(key): groups[key] = []
  groups[key].append(mesh)
 for group in groups.values():
  if group.size()<2: continue
  var st = SurfaceTool.new()
  st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for mesh in group: st.append_from(mesh.mesh,0,parent.global_transform.affine_inverse()*mesh.global_transform)
  var joined = MeshInstance3D.new()
  joined.mesh = st.commit()
  joined.material_override = group[0].material_override
  joined.cast_shadow = group[0].cast_shadow
  parent.add_child(joined)
  for mesh in group:
   for child in mesh.get_children():
    if child is Node3D: child.reparent(parent,true)
   mesh.get_parent().remove_child(mesh)
   mesh.queue_free()

func collect_static(node: Node, protected: Array, found: Array) -> void:
 for child in node.get_children():
  if child in protected: continue
  if child is MeshInstance3D and child.visible: found.append(child)
  else: collect_static(child,protected,found)

func optimize_geometry() -> void:
 var protected: Array = objects.values()
 for a in angels: protected.append(a)
 for actor in cast: protected.append(actor.root)
 var found: Array = []
 collect_static(self,protected,found)
 merge_group(self,found)
 for actor in cast:
  optimize_rig(actor.root)
 for a in angels: optimize_rig(a)

func optimize_rig(root: Node3D) -> void:
 for node in root.find_children("*","Node3D",true,false):
  var meshes: Array = []
  for child in node.get_children():
   if child is MeshInstance3D and child.is_visible_in_tree(): meshes.append(child)
  if meshes.size()>1: merge_group(node,meshes)

func jacket_mesh(parent: Node3D, mat: Material) -> void:
 var st = SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var levels = [[-.07,.17,.13],[.05,.19,.135],[.36,.245,.14],[.45,.20,.12],[.48,.09,.085]]
 for j in range(levels.size()-1):
  for i in range(8):
   var points: Array[Vector3] = []
   for corner in [[j,i],[j,i+1],[j+1,i],[j+1,i+1]]:
    var r = levels[corner[0]]
    var a = float(corner[1])*TAU/8+PI/8
    points.append(Vector3(sin(a)*r[1],r[0],cos(a)*r[2]))
   for k in [0,2,1,1,2,3]: st.add_vertex(points[k])
 st.generate_normals()
 var mesh = MeshInstance3D.new()
 mesh.mesh = st.commit()
 mesh.material_override = mat
 parent.add_child(mesh)
