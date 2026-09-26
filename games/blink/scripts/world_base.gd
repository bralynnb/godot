extends Node3D
var stone: StandardMaterial3D
var wood: StandardMaterial3D
var plaster: StandardMaterial3D
var blue: StandardMaterial3D
var dark: StandardMaterial3D
var brass: StandardMaterial3D
var objects = {}
var angels: Array[Node3D] = []
var lights: Array[OmniLight3D] = []

func material(c: Color, texture_name: String = "") -> StandardMaterial3D:
 var m = StandardMaterial3D.new()
 m.albedo_color = c
 m.roughness = 0.95
 m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
 m.uv1_scale = Vector3(2,2,2)
 if texture_name != "": m.albedo_texture = load("res://assets/" + texture_name + ".png")
 return m

func block(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, solid: bool = true) -> MeshInstance3D:
 var m = MeshInstance3D.new()
 var mesh = BoxMesh.new()
 mesh.size = size
 m.mesh = mesh
 m.material_override = mat
 parent.add_child(m)
 m.position = pos
 if solid:
  var body = StaticBody3D.new()
  m.add_child(body)
  var shape = CollisionShape3D.new()
  var box = BoxShape3D.new()
  box.size = size
  shape.shape = box
  body.add_child(shape)
 return m

func cylinder(parent: Node3D, pos: Vector3, top: float, bottom: float, height: float, mat: Material) -> MeshInstance3D:
 var m = MeshInstance3D.new()
 var mesh = CylinderMesh.new()
 mesh.top_radius = top
 mesh.bottom_radius = bottom
 mesh.height = height
 mesh.radial_segments = 7
 mesh.rings = 1
 m.mesh = mesh
 m.material_override = mat
 parent.add_child(m)
 m.position = pos
 return m

func label3(parent: Node3D, text: String, pos: Vector3, size: int = 36) -> void:
 var l = Label3D.new()
 parent.add_child(l)
 l.position = pos
 l.text = text
 l.font_size = size
 l.pixel_size = 0.007
 l.modulate = Color("cbd9d4")
 l.no_depth_test = false

func light_at(pos: Vector3, color: Color, energy: float, radius: float) -> void:
 var l = OmniLight3D.new()
 add_child(l)
 l.position = pos
 l.light_color = color
 l.light_energy = energy
 l.omni_range = radius
 lights.append(l)

func prop(id: String, pos: Vector3, kind: String = "paper") -> Node3D:
 var p = Node3D.new()
 add_child(p)
 p.position = pos
 p.set_meta("id",id)
 objects[id] = p
 match kind:
  "person":
   cylinder(p,Vector3(0,.85,0),.25,.36,1.25,wood)
   cylinder(p,Vector3(0,1.65,0),.19,.19,.36,material(Color("a39280")))
   for x in [-.19,.19]: block(p,Vector3(x,.22,0),Vector3(.17,.45,.2),dark,false)
  "tv":
   block(p,Vector3(0,.75,0),Vector3(1.3,.8,.6),dark)
   block(p,Vector3(0,.79,.32),Vector3(1.05,.56,.04),material(Color("628c87")),false)
   label3(p,"SIGNAL / 1969",Vector3(0,.8,.35),20)
   block(p,Vector3(0,.28,0),Vector3(1.6,.12,.8),wood)
   for x in [-.65,.65]: block(p,Vector3(x,.15,0),Vector3(.08,.3,.5),wood)
  "door":
   block(p,Vector3(0,1.4,0),Vector3(1.35,2.8,.18),wood)
   block(p,Vector3(.45,1.25,.14),Vector3(.1,.12,.12),brass,false)
  "grave":
   block(p,Vector3(0,.65,0),Vector3(1,.95,.2),stone)
   label3(p,"KATHERINE\nWAINWRIGHT",Vector3(0,.7,.13),23)
  "key":
   cylinder(p,Vector3(0,1.65,.4),.08,.08,.045,brass)
   block(p,Vector3(0,1.57,.4),Vector3(.035,.2,.04),brass,false)
  "paper":
   block(p,Vector3(0,.85,0),Vector3(1.2,.1,.8),wood)
   block(p,Vector3(0,.92,0),Vector3(.5,.015,.4),material(Color("d6ccb1")),false)
  "window":
   block(p,Vector3(0,1.7,0),Vector3(2.3,2.2,.1),material(Color("597d8b")),false)
   for x in [-1.2,0,1.2]: block(p,Vector3(x,1.7,.06),Vector3(.1,2.3,.1),wood,false)
   block(p,Vector3(0,1.7,.06),Vector3(2.4,.12,.1),wood,false)
  "wall":
   block(p,Vector3(0,1.6,0),Vector3(2.6,1.8,.04),material(Color("968f77"),"paper"),false)
  "box":
   block(p,Vector3(0,1.4,0),Vector3(2,2.8,2),blue)
   block(p,Vector3(0,2.95,0),Vector3(2.25,.22,2.2),dark)
   for x in [-.47,.47]:
    block(p,Vector3(x,2,1.015),Vector3(.75,.55,.03),material(Color("9eafb0")),false)
    for y in [.5,1.2]: block(p,Vector3(x,y,1.02),Vector3(.72,.52,.06),blue,false)
   label3(p,"POLICE  PUBLIC CALL  BOX",Vector3(0,2.67,1.03),19)
   cylinder(p,Vector3(0,3.2,0),.13,.13,.3,material(Color("b4d6df")))
  "console":
   cylinder(p,Vector3(0,.7,0),1.5,.6,.6,brass)
   cylinder(p,Vector3(0,1.5,0),.3,.3,1.4,material(Color("5d9b90")))
   for i in range(6):
    var a = i * TAU/6
    block(p,Vector3(cos(a),1.04,sin(a)),Vector3(.25,.07,.3),blue,false)
 return p

func angel(pos: Vector3) -> Node3D:
 var a = Node3D.new()
 add_child(a)
 a.position = pos
 cylinder(a,Vector3(0,.65,0),.25,.6,1.3,stone)
 cylinder(a,Vector3(0,1.38,0),.32,.24,.55,stone)
 cylinder(a,Vector3(0,1.96,0),.23,.21,.4,stone)
 for side in [-1,1]:
  var arm = block(a,Vector3(side*.26,1.68,.23),Vector3(.18,.55,.22),stone,false)
  arm.rotation.z = side*.3
  block(a,Vector3(side*.13,1.95,.23),Vector3(.14,.3,.13),stone,false)
  for i in range(6):
   var feather = block(a,Vector3(side*(.45+i*.12),1.55+i*.08,-.17-i*.025),Vector3(.14,1.15-i*.07,.18),stone,false)
   feather.rotation.z = side*(-.2-i*.07)
 angels.append(a)
 return a

func build(kind: String, chapter: int) -> void:
 stone = material(Color("8e9898"),"stone")
 wood = material(Color("77736b"),"wood")
 plaster = material(Color("7f8881"),"wall")
 blue = material(Color("244d74"),"wood")
 dark = material(Color("222b33"))
 brass = material(Color("887c53"))
 var env = WorldEnvironment.new()
 env.environment = Environment.new()
 env.environment.background_mode = Environment.BG_COLOR
 env.environment.background_color = Color("151e29")
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color("8094a7")
 env.environment.ambient_light_energy = .52
 env.environment.fog_enabled = true
 env.environment.fog_light_color = Color("263640")
 env.environment.fog_density = .025
 add_child(env)
 block(self,Vector3(0,-.12,0),Vector3(18,.24,22),material(Color("626864"),"floor"))
 if kind != "garden":
  block(self,Vector3(-9,2,0),Vector3(.25,4,22),plaster)
  block(self,Vector3(9,2,0),Vector3(.25,4,22),plaster)
  block(self,Vector3(0,2,-11),Vector3(18,4,.25),plaster)
  block(self,Vector3(0,2,11),Vector3(18,4,.25),plaster)
  block(self,Vector3(0,4,0),Vector3(18,.2,22),dark)
  for x in [-8.8,8.8]:
   block(self,Vector3(x,.22,0),Vector3(.12,.35,22),wood,false)
  for z in [-7,0,7]:
   for x in [-8.6,8.6]: block(self,Vector3(x,1.9,z),Vector3(.32,3.8,.32),wood)
 light_at(Vector3(-3,3,2),Color("92b5c6"),1.6,12)
 light_at(Vector3(5,3,-6),Color("a7a58a"),1.1,11)
 match kind:
  "house":
   prop("paper",Vector3(-4,0,-10.75),"wall")
   objects["message"] = objects.paper
   label3(objects.paper,"SALLY SPARROW\n1969",Vector3(0,1.65,.05),32)
   objects.paper.get_child(1).visible = chapter != 0
   prop("window",Vector3(3,0,-10.7),"window")
   prop("visitor",Vector3(7,0,7),"person")
   prop("kathy",Vector3(-6,0,-4),"person")
   prop("key",Vector3(5,0,-6),"key")
   prop("exit",Vector3(6,0,10.7),"door").rotation.y = PI
   prop("cellar",Vector3(-6,0,10.7),"door").rotation.y = PI
   prop("tv",Vector3(-3,0,-3),"tv")
   prop("larry",Vector3(-1,0,-3),"person")
   angel(Vector3(5,0,-6))
   if chapter == 9: angel(Vector3(-7,0,-8))
   # Victorian arch framing and period furnishings: independent geometry.
   for x in [-7.2,-1.8,1.8,7.2]:
    block(self,Vector3(x,1.75,0),Vector3(.32,3.5,.5),wood)
    block(self,Vector3(x,.25,0),Vector3(.55,.5,.7),wood)
   for x in [-4.5,4.5]:
    block(self,Vector3(x,3.35,0),Vector3(5.7,.3,.55),wood)
   block(self,Vector3(0,.015,4),Vector3(3.1,.025,5),material(Color("4a4248"),"paper"),false)
   cylinder(self,Vector3(0,3.6,3),.04,.04,.8,brass)
   cylinder(self,Vector3(0,3.1,3),.65,.65,.08,brass)
   for i in range(6):
    var ca = i*TAU/6
    cylinder(self,Vector3(cos(ca)*.62,3.3,3+sin(ca)*.62),.04,.04,.35,material(Color("bcb698")))
   for x in [-8.75,8.75]:
    for z in [-6,3,7]:
     var frame = block(self,Vector3(x,2,z),Vector3(.15,1.15,.95),brass,false)
     block(self,Vector3(x*.998,2,z),Vector3(.18,.95,.74),material(Color("323c37"),"stone"),false)
   for i in range(12):
    cylinder(self,Vector3(7.7+i*.075,.6,-10.6),.04,.04,1.05,stone)
   block(self,Vector3(-6,.5,4),Vector3(1.7,.16,.8),wood)
   block(self,Vector3(-6,.85,4.3),Vector3(1.7,.75,.13),wood)
   for x in [-6.6,-5.4]: block(self,Vector3(x,.24,4),Vector3(.1,.48,.65),wood)
   # Fireplace, mantel, wainscot and scattered boards.
   block(self,Vector3(-8.4,1.1,-3),Vector3(1,2.2,3.4),dark)
   block(self,Vector3(-8.15,2.3,-3),Vector3(1.6,.22,3.8),stone)
   for i in range(12):
    var debris = block(self,Vector3(-7+i*.8,.05,1+sin(i)*2),Vector3(.15,.06,.9),wood,false)
    debris.rotation.y = i*.9
  "flat", "shop":
   prop("tv",Vector3(0,0,-6),"tv")
   prop("kathy",Vector3(-4,0,-3),"person")
   prop("larry",Vector3(3,0,-6),"person")
   prop("list",Vector3(3,0,-3))
   prop("folder",Vector3(-2,0,-3))
   prop("doctor",Vector3(5,0,5),"person")
   for x in [-8,8]:
    for y in [.4,1.1,1.8,2.5]:
     block(self,Vector3(x,y,-4),Vector3(1,.1,10),wood)
     for i in range(22): block(self,Vector3(x,y+.25,-8.6+i*.42),Vector3(.55,.45,.16),material(Color.from_hsv(fmod(i*.17,.99),.3,.55)),false)
  "garden":
   prop("letter",Vector3(-3,0,1))
   prop("grave",Vector3(1,0,-5),"grave")
   for i in range(16):
    var x = -7.5 + fmod(i*3.1,15)
    var z = -8.0 + floor(i/5.0)*5
    cylinder(self,Vector3(x,2,z),.1,.25,4,wood)
    cylinder(self,Vector3(x,3.7,z),0,1.4,2.5,material(Color("2d4541")))
   angel(Vector3(6,0,-7))
  "garage":
   prop("billy",Vector3(-3,0,-2),"person")
   prop("box",Vector3(4,0,-6),"box")
   prop("exit",Vector3(0,0,10.7),"door").rotation.y = PI
   for x in [-6,0]:
    block(self,Vector3(x,.6,-6),Vector3(2.4,1,4),blue)
    block(self,Vector3(x,1.35,-6),Vector3(2,1,2),dark)
  "hospital":
   prop("billy",Vector3(-2,0,-4),"person")
   prop("list",Vector3(1,0,-3))
   prop("window",Vector3(3,0,-10.7),"window")
   block(self,Vector3(-2,.5,-5),Vector3(1.5,.45,3),material(Color("d2d7cd")))
   block(self,Vector3(-2,.9,-6.2),Vector3(1.2,.2,.6),plaster)
  "cellar":
   prop("box",Vector3(0,0,-6),"box")
   for p in [Vector3(-5,0,-6),Vector3(5,0,-6),Vector3(-4,0,1),Vector3(4,0,1)]: angel(p)
   for x in [-7,7]:
    for z in [-7,-2,4]: block(self,Vector3(x,1.7,z),Vector3(.45,3.4,.45),stone)
  "tardis":
   prop("console",Vector3(0,0,-3),"console")
   objects["angels"] = objects.console
   for i in range(16):
    var a = i*TAU/16
    cylinder(self,Vector3(cos(a)*7,1.8,sin(a)*7),.45,.45,.2,brass).rotation.x = PI/2
   light_at(Vector3(0,2,-3),Color("65c9bc"),2,12)
