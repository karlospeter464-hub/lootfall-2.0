extends "res://tests/visual_slice_a.gd"

func run() -> void:
	output = "res://.godot/blender_mage"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "Create output directory")
	var game = load("res://tests/blender_mage_arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.restart_run()
	game.set_process(false)
	var player = game.player
	var visual = player.visuals
	player.controls_enabled = false
	player.set_physics_process(false)
	visual.set_process(false)
	game.rng.seed = 42
	game.wave = 2
	game.begin_wave()
	for index in 12:
		game.spawn_enemy()
		var enemy = game.enemies.get_child(index)
		enemy.position = Vector2(240 + (index % 4) * 230, 240 + (index / 4) * 160)
		enemy.set_physics_process(false)
		enemy.set_process(false)
	game.remaining_to_spawn = 0
	game.update_hud()
	check(visual.render_selected and visual.art.material == null, "Blender render uses unmodified materials, no v01 flame shader")
	check(visual.source_image.get_size() == Vector2i(512, 640), "512x640 source")
	check(visual.source_image.detect_alpha() == Image.ALPHA_BLEND and visual.source_image.get_pixel(0, 0).a == 0, "Real transparent antialiased alpha")
	check(visual.art.texture.get_image().has_mipmaps(), "Mipmaps enabled")
	check(is_equal_approx(visual.used_rect.size.y * player.artwork_base_scale.y, 64), "64 logical pixel silhouette")
	check(visual.art.to_global(visual.FOOT + visual.art.offset).is_equal_approx(player.global_position), "Projected ground anchor coincides with player origin")
	check(player.get_canvas_transform() == Transform2D.IDENTITY and root.content_scale_size == Vector2i(1280, 800), "Normal gameplay camera and logical resolution")
	check(player.get_node("CollisionShape2D").shape.radius == 15 and player.move_speed == 245 and player.damage == 14 and player.cast_interval == 0.36, "Original gameplay values")
	var body: Transform2D = player.transform
	for state in ["idle", "move", "cast"]:
		visual.animator.play(state)
		visual.animator.seek(visual.animator.get_animation(state).length / 2, true)
		check(player.transform == body and visual.motion.transform != Transform2D.IDENTITY, state + " changes only visual wrapper")
	visual.animator.play("idle")
	visual.animator.seek(0, true)
	var key := InputEventKey.new()
	key.keycode = KEY_V
	key.pressed = true
	visual._unhandled_key_input(key)
	check(not visual.render_selected and visual.mode == 2 and visual.art.texture == visual.ART_TEXTURE and visual.art.offset == Vector2(-128, -300), "V restores production v01/A+")
	if DisplayServer.get_name() != "headless": await capture("fallback_idle")
	visual._unhandled_key_input(key)
	check(visual.render_selected and visual.mode == 1 and visual.art.texture == visual.RENDER_TEXTURE and visual.art.material == null, "V returns to Blender sprite")
	visual.animator.seek(0, true)
	if DisplayServer.get_name() != "headless": await capture("prototype_idle")
	paused = true
	var pose: Transform2D = visual.motion.transform
	await process_frame
	await process_frame
	check(visual.motion.transform == pose, "Pause freezes animation")
	paused = false
	var file := FileAccess.open(output + "/render_metrics.json", FileAccess.WRITE)
	check(file != null, "Render metrics open")
	if file: file.store_string(JSON.stringify({"source_size":str(visual.source_image.get_size()), "alpha_bounds":str(visual.used_rect), "scale":player.artwork_base_scale.x, "logical_height":64, "foot":str(visual.FOOT), "canvas_transform":str(player.get_canvas_transform()), "checks":checks, "failures":failures}, "\t"))
	if OS.get_cmdline_user_args().has("--verify") or OS.get_cmdline_user_args().has("--combat-capture"):
		await capture_live_combat(game, visual)
		game.queue_free()
		await process_frame
		quit(0 if failures == 0 else 1)
		return
	visual.set_process(true)
	player.set_physics_process(true)
	player.controls_enabled = true
	game.set_process(true)
	for enemy in game.enemies.get_children():
		enemy.set_physics_process(true)
		enemy.set_process(true)
	print("BLENDER COMPARISON: WASD / Mouse / LMB; V: Blender / production v01 A+. Test saves only.")
