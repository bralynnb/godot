extends SceneTree
func _initialize():call_deferred("checks")
func checks():
	var w=load("res://main.tscn").instantiate();root.add_child(w);await process_frame;w.set_process(false)
	w.stage=0;w.tokens=100;w.inventory=["Resident ID — New Arrival","Apartment key — 10C","Subway pass"]
	var starts=[]
	for p in w.people:starts.append(p.p)
	for i in range(2400):w._process(1.0/60)
	var moved=0
	for i in range(64):
		if starts[i].distance_to(w.people[i].p)>1:moved+=1
	assert(moved==64)
	for vendor in [0,1,2,0]:
		w.walk_to(w.vendors[vendor].p)
		for i in range(6000):w._process(1.0/60)
		assert(w.player.distance_to(w.vendors[vendor].p)<2)
		w.show_dialogue(vendor);w.perform_action()
	assert(w.stage==4)
	assert(w.tokens==125)
	assert(not w.inventory.has("Signed delivery receipt"))
	w.fit_map();w._process(1)
	assert(abs(w.target_zoom-.7)<.001)
	var half=w.get_viewport_rect().size/(w.cam.zoom*2)
	assert(w.cam.position.x-half.x>=-.1 and w.cam.position.y-half.y>=-.1)
	assert(w.cam.position.x+half.x<=w.WORLD.x+.1 and w.cam.position.y+half.y<=w.WORLD.y+.1)
	w.paused=true;var t=w.clock;w._process(1);assert(w.clock==t)
	print("PASS: 64 residents moving; all four delivery legs; inventory and 25-token pay; 0.7 zoom; edge-to-edge camera bounds; pause")
	# Test resident state is removed so the release starts at the first shift.
	DirAccess.remove_absolute("user://tsfm-resident.json")
	w.queue_free();await process_frame;quit()
