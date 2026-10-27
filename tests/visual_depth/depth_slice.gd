extends "res://tests/visual_slice_a.gd"

const PROP = preload("res://tests/visual_depth/depth_prop.gd")
var depth: Node2D
var motion_animator: AnimationPlayer
var pair_verified: bool = false
var motion_frames: int = 0
var frames_output: String = ""
var comparison_frame: int = 140

class DepthSwitch extends Node2D:
	func _unhandled_key_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
			visible = not visible

func snapshot(game) -> String:
	return JSON.stringify({"player":str(game.player.transform), "health":game.player.health, "aim":str(game.player.aim), "visual_clock":game.player.visual_clock, "enemies":game.enemies.get_children().map(func(enemy): return str(enemy.transform)), "shots":game.projectiles.get_children().map(func(shot): return str(shot.transform)), "rng":game.rng.state, "canvas":str(game.player.get_canvas_transform()), "wave":game.wave})

func pair(game) -> void:
	paused = true
	var state: String = snapshot(game)
	depth.visible = false
	await capture("before")
	depth.visible = true
	await capture("after")
	check(snapshot(game) == state, "Before/after share exact actor, projectile, health, camera, wave, RNG and visual-clock state")
	pair_verified = snapshot(game) == state
	paused = false

func run() -> void:
	output = "res://.godot/visual_depth"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
		if argument.begins_with("--frames-output="): frames_output = argument.trim_prefix("--frames-output=")
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "Create comparison output")
	if not frames_output.is_empty():
		check(DirAccess.make_dir_recursive_absolute(frames_output) == OK, "Create movement frame output")
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.restart_run()
	game.rng.seed = 42
	game.wave = 2
	game.begin_wave()
	for index in 12:
		game.spawn_enemy()
		var enemy = game.enemies.get_child(index)
		enemy.position = Vector2(135 if index < 6 else 1140, 170 + (index % 6) * 100)
		# Keep the original warning/body drawing above opaque environment artwork.
		enemy.z_index = 4
	game.remaining_to_spawn = 0
	var player = game.player
	player.position = Vector2(390, 370)
	player.z_index = 2
	game.projectiles.z_index = 5
	depth = DepthSwitch.new()
	depth.name = "DepthProofOnly"
	game.add_child(depth)
	for kind in 3:
		var prop = PROP.new()
		prop.kind = kind
		prop.scale = Vector2.ONE if kind == 0 else Vector2.ONE * 0.65
		prop.player = player
		prop.position = Vector2.ZERO if kind == 0 else (Vector2(470,400) if kind == 1 else Vector2(740,480))
		depth.add_child(prop)
	check(game.run_region == 0 and is_zero_approx(game.restoration_visual), "Unrestored Ashen Fields")
	check(player.visuals.mode == 2 and player.artwork.texture == player.visuals.ART_TEXTURE, "Current production character retained")
	check(player.get_canvas_transform() == Transform2D.IDENTITY and root.content_scale_size == Vector2i(1280,800), "Normal camera and resolution")
	check(player.get_node("CollisionShape2D").shape.radius == 15 and player.move_speed == 245 and player.damage == 14 and player.cast_interval == 0.36, "Original collision and combat values")
	check(depth.get_child_count() == 3 and depth.find_children("*", "CollisionObject2D", true, false).is_empty(), "Exactly two props and ground pass; no new collisions")
	var rng_before: int = game.rng.state
	for prop in depth.get_children(): prop._process(0)
	check(game.rng.state == rng_before, "Environment does not consume gameplay RNG")
	var toggle := InputEventKey.new()
	toggle.keycode = KEY_T
	toggle.pressed = true
	depth._unhandled_key_input(toggle)
	check(not depth.visible and game.rng.state == rng_before, "T disables all depth visuals without touching gameplay RNG")
	depth._unhandled_key_input(toggle)
	check(depth.visible, "T restores depth test")
	motion_animator = player.visuals.animator
	setup_character(player)
	game.update_hud()
	if not OS.get_cmdline_user_args().has("--verify") and not OS.get_cmdline_user_args().has("--capture"):
		print("DEPTH PROOF: T before/after; WASD / Mouse / LMB; V keeps the original character modes. Test saves only.")
		return
	var waypoints: Array[Vector2] = [Vector2(550,370),Vector2(550,430),Vector2(430,430),Vector2(660,450),Vector2(820,450),Vector2(820,515),Vector2(700,515)]
	var waypoint: int = 0
	var target = null
	for enemy in game.enemies.get_children():
		if enemy.get_script() == game.GUARDIAN_ENEMY: target = enemy
	var start: Vector2 = player.position
	var initial_enemies: Array = game.enemies.get_children().map(func(enemy): return enemy.position)
	var crossings: Dictionary = {"ruin_behind":false,"ruin_front":false,"rock_behind":false,"rock_front":false}
	var minimum_enemies: int = 12
	var capture_times: Array[float] = []
	var elapsed_start: float = game.elapsed
	var count_frames: int = 0
	var move_seen: bool = false
	var cast_seen: bool = false
	var movement_distance: float = 0
	var previous: Vector2 = start
	for frame in 420:
		if waypoint >= waypoints.size() or player.health <= 0: break
		var direction: Vector2 = player.position.direction_to(waypoints[waypoint])
		for action in ["move_left","move_right","move_up","move_down"]: Input.action_release(action)
		if direction.x < -0.2: Input.action_press("move_left")
		if direction.x > 0.2: Input.action_press("move_right")
		if direction.y < -0.2: Input.action_press("move_up")
		if direction.y > 0.2: Input.action_press("move_down")
		await physics_frame
		await process_frame
		if is_instance_valid(target) and not target.dead:
			player.aim = test_aim(player,target,frame)
			player.attack(player.aim)
		move_seen = move_seen or motion_animator.current_animation == "move"
		cast_seen = cast_seen or motion_animator.current_animation == "cast"
		movement_distance += player.position.distance_to(previous)
		previous = player.position
		if player.position.distance_to(waypoints[waypoint]) < 8: waypoint += 1
		for prop in depth.get_children(): prop._process(0)
		for index in [1,2]:
			var prop = depth.get_child(index)
			var near: bool = absf(player.position.x - prop.position.x) < 65
			if near:
				var side: String = "behind" if player.position.y < prop.position.y else "front"
				crossings[("ruin_" if index == 1 else "rock_") + side] = true
				if frame % 30 == 0: check(prop.z_index == (3 if side == "behind" else 1), "Prop switches at ground anchor")
		minimum_enemies = mini(minimum_enemies, game.enemies.get_child_count())
		count_frames += 1
		if frame == comparison_frame and DisplayServer.get_name() != "headless": await pair(game)
		if not frames_output.is_empty() and frame % 8 == 0 and DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(frames_output + "/%04d.png" % motion_frames) == OK, "Save real movement frame")
			capture_times.append(game.elapsed-elapsed_start)
			motion_frames += 1
	for action in ["move_left","move_right","move_up","move_down"]: Input.action_release(action)
	check(waypoint == waypoints.size() and movement_distance > 800, "Original input walks the complete route past both props")
	check(not crossings.values().has(false), "Player passed behind and in front of both objects")
	check(minimum_enemies >= 12, "Twelve active enemies throughout")
	check(game.shots_fired > 0 and game.shots_hit > 0 and game.damage_dealt > 0, "Original spells and collisions cause real damage")
	var enemies_moved: bool = false
	for index in game.enemies.get_child_count():
		if index < initial_enemies.size() and game.enemies.get_child(index).position.distance_to(initial_enemies[index]) > 1: enemies_moved = true
	check(enemies_moved, "Original enemy AI moves")
	check(move_seen and cast_seen, "Original velocity and accepted shots drive move and cast animations")
	var report := {"physics_frames":count_frames,"minimum_enemies":minimum_enemies,"waypoints_reached":waypoint,"crossings":crossings,"path_distance":movement_distance,"shots_fired":game.shots_fired,"shots_hit":game.shots_hit,"damage":game.damage_dealt,"health_end":player.health,"identical_pair_verified":pair_verified,"movement_png_frames":motion_frames,"capture_times":capture_times,"gameplay_seconds":game.elapsed-elapsed_start,"move_seen":move_seen,"cast_seen":cast_seen,"checks":checks,"failures":failures}
	var file := FileAccess.open(output + "/metrics.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report,"\t"))
	print("DEPTH PROOF: ",report)
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func setup_character(_player: CharacterBody2D) -> void:
	pass

func test_aim(player, target, _frame: int) -> Vector2:
	return player.global_position.direction_to(target.global_position)
