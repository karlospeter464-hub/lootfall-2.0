extends SceneTree

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--test-mode"):
		quit(1)
		return
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.restart_run()
	game.player.controls_enabled = false
	var world: Dictionary = game.WORLD.fresh()
	world.points[0] = 288
	game.progress._save(0, 0, {}, world)
	game.restoration_visual = 0.48
	game.wave = 11
	game.begin_wave()
	game.remaining_to_spawn = 0
	# Controlled capture: the real wave-clear path supplies 312 points and its normal budget.
	for index in 24:
		game.feel.add_orb(Vector2(150 + index % 8 * 140, 250 + index / 8 * 170), 1)
	game.secure_echo_total(24, Vector2(200,500))
	# Decorative positions above redistribute the same 24 earned units, not extra rewards.
	game.feel.orbs.pop_back()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/living_frames"))
	for frame in 32:
		if frame == 4: game.complete_wave()
		await create_timer(0.125, true).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/living_frames/%02d.png" % frame)
	# Native stress sample includes fully grown terrain, 48 merged pickups and 80 enemies.
	paused = false
	game.overlay.hide()
	game.state = game.State.FIGHTING
	game.enemy_limit = 80
	game.remaining_to_spawn = 80
	for index in 80:
		game.spawn_enemy()
	for enemy in game.enemies.get_children(): enemy.set_physics_process(false)
	for index in 1000: game.feel.add_orb(Vector2(90 + index % 1100, 200 + index % 450), 1)
	game.feel.set_process(false)
	var samples: Array[float] = []
	var previous: int = Time.get_ticks_usec()
	for frame in 180:
		await process_frame
		var now: int = Time.get_ticks_usec()
		if frame >= 30: samples.append(float(now - previous) / 1000)
		previous = now
	samples.sort()
	print("NATIVE STRESS: %d enemies, %d orbs, median %.2f ms, p95 %.2f ms (150 samples; VSync included)" % [game.enemies.get_child_count(), game.feel.orbs.size(), samples[75], samples[142]])
	game.queue_free()
	await process_frame
	quit()
