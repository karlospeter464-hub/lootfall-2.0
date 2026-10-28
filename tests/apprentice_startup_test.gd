extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(game)
	await process_frame
	check(game.state == game.State.TOWN and paused,"F5 opens town")
	check(game.player.directions.enabled,"Normal main scene enables new mage")
	game.restart_run()
	check(not paused and game.player.controls_enabled,"Start Run enables normal controls")
	var visual = game.player.directions
	game.player.aim = Vector2.UP
	visual.update_facing()
	check(visual.facing == 2,"Normal main scene faces approved rear image")
	game.player.cast.emit(Vector2.ZERO,Vector2.UP,14)
	await process_frame
	paused = true
	var puppet = visual.puppets[2]
	var age: float = puppet.age
	var pose: Transform2D = puppet.joints[0].transform
	for frame in 3: await process_frame
	check(puppet.age == age and puppet.joints[0].transform == pose,"Pause freezes pose and cast time")
	paused = false
	game.player.protection = 0.1
	game.player.update_artwork(0)
	puppet._process(0)
	check(puppet.mesh.self_modulate == game.player.artwork.self_modulate,"Damage tint reaches visible mesh")
	check_dependencies("res://scenes/arena.tscn",{})
	print("DIRECTIONAL STARTUP: 7 behavior checks plus runtime dependency scan; failures=",failures)
	quit(1 if failures else 0)
func check_dependencies(path: String, seen: Dictionary) -> void:
	if seen.has(path): return
	seen[path] = true
	check(not path.begins_with("res://tests/"),"Runtime must not depend on tests: "+path)
	for entry in ResourceLoader.get_dependencies(path):
		check_dependencies(entry.get_slice("::",entry.get_slice_count("::")-1),seen)
