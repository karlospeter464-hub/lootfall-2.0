extends "res://tests/visual_depth/depth_slice.gd"

const DIRECTIONAL = preload("res://tests/mage_four_directions/direction_visual.gd")
var visual
var strafe_seen: bool = false

func setup_character(player: CharacterBody2D) -> void:
	comparison_frame = 98
	check(FileAccess.get_sha256("res://assets/art/characters/apprentice/apprentice_v01.png") == "831023c026176d2949e3e8a085148ea1cb79d72d1684a0b7977fbbead3053128","Original v01 remains unchanged")
	visual = DIRECTIONAL.new()
	player.add_child(visual)
	visual.setup(player)
	motion_animator = visual.puppets[visual.facing].animator
	visual.facing_changed.connect(func(animator): motion_animator = animator)
	var original: Transform2D = player.transform
	for direction in 4:
		player.aim = visual.VECTORS[direction]
		visual.update_facing()
		check(visual.facing == direction,"Mouse aim selects "+visual.LABELS[direction])
		var puppet = visual.puppets[direction]
		puppet.pose(Vector3(-0.18,0.12,-0.035)*puppet.articulation_gain)
		var minimum: float = INF
		for triangle in puppet.mesh.polygons:
			var a: Vector2 = puppet.mesh.polygon[triangle[0]]
			var b: Vector2 = puppet.mesh.polygon[triangle[1]]
			var c: Vector2 = puppet.mesh.polygon[triangle[2]]
			minimum = minf(minimum,(b-a).cross(c-a))
		check(minimum > 0,"Articulated "+visual.LABELS[direction]+" pose has no inverted triangles")
		var foot: int = 38*33+16
		check(puppet.mesh.polygon[foot].is_equal_approx(puppet.points[foot]) and player.transform == original,"Foot mesh and physics root stay fixed in "+visual.LABELS[direction])
		check(puppet.art_texture.get_image().get_pixel(0,0).a < 0.03,"Transparent corner for "+visual.LABELS[direction])
		if DisplayServer.get_name() != "headless":
			check(puppet.art_texture.get_image().save_png(output+"/source_"+visual.LABELS[direction]+".png") == OK,"Save normalized direction")
		puppet.pose(Vector3.ZERO)
		puppet.animator.play("idle")
	# Heading hysteresis and fallback must not alter aim or physics.
	player.aim = Vector2.LEFT
	visual.update_facing()
	player.aim = Vector2(-0.70,-0.71).normalized()
	visual.update_facing()
	check(visual.facing == 3,"Near-diagonal noise does not flicker the facing")
	var key := InputEventKey.new()
	key.keycode=KEY_V
	key.pressed=true
	visual._unhandled_key_input(key)
	check(not visual.enabled and player.artwork.texture == visual.puppets[0].SOURCE and player.visuals.mode == 2,"V restores full original v01/A+")
	visual._unhandled_key_input(key)
	check(visual.enabled and player.transform == original,"V returns to four-direction puppet without physics changes")
	visual.seen.clear()

func test_aim(player, target, frame: int) -> Vector2:
	var aim: Vector2 = visual.VECTORS[(frame/28)%4] if frame < 112 else player.global_position.direction_to(target.global_position)
	strafe_seen = strafe_seen or absf(player.velocity.normalized().dot(aim)) < 0.5
	return aim

func pair(game) -> void:
	check(visual.seen.size() == 4,"All four facings were seen during actual active combat")
	check(strafe_seen,"Player moves sideways independently of aim/facing")
	paused=true
	var state: String = snapshot(game)
	visual.select(false)
	await capture("before")
	visual.select(true)
	visual.update_facing()
	visual.puppets[visual.facing].pose(Vector3.ZERO)
	await capture("after")
	check(snapshot(game) == state,"Directional swap leaves gameplay and camera unchanged")
	pair_verified = snapshot(game) == state
	var aim: Vector2 = game.player.aim
	for direction in 4:
		game.player.aim = visual.VECTORS[direction]
		visual.update_facing()
		visual.puppets[direction].pose(Vector3.ZERO)
		await capture(visual.LABELS[direction])
	game.player.aim = aim
	visual.update_facing()
	visual.puppets[visual.facing].animator.play("idle")
	var file := FileAccess.open(output+"/direction_metrics.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify({"seen_in_live_combat":visual.seen,"strafe_seen":strafe_seen,"four_true_sources":true,"mirroring":false,"logical_height_target":64,"pixel_canvas":Vector2i(256,320),"foot_anchor":Vector2(128,300)},"\t"))
	paused=false
