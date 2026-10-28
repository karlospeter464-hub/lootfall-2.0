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
	game.progress.rescue_companion("gravity")
	game.progress.rescue_companion("prism")
	game.restart_run()
	game.set_process(false)
	game.player.controls_enabled = false
	game.player.invulnerable = true
	game.begin_wave()
	var count: int = 12 if OS.get_cmdline_user_args().has("--normal") else 80
	game.enemy_limit = count
	game.remaining_to_spawn = count
	game.wave_budget = count
	for i in count:
		game.spawn_enemy()
		var enemy = game.enemies.get_child(i)
		enemy.position = Vector2(350 + (i % 10) * 52, 220 + (i / 10) * 48)
		enemy.max_health = 100000
		enemy.health = 100000
	game.remaining_to_spawn = 0
	var times: Array[float] = []
	for frame in 180:
		if frame % 30 == 0 and not OS.get_cmdline_user_args().has("--no-magic"):
			game.companion_magic.cooldowns.fill(0.0)
			game.companion_magic.field.clear()
			game.companion_magic.beam.clear()
			game.companion_magic.cast(0, Vector2(640, 400))
			game.companion_magic.cast(1, Vector2(900, 400))
		var start: int = Time.get_ticks_usec()
		await process_frame
		if frame >= 30: times.append((Time.get_ticks_usec() - start) / 1000.0)
	times.sort()
	print("COMPANION PERF: %d live AI enemies, magic=%s, 150 measured frames after warmup; median %.2f ms / p95 %.2f ms; native frame time incl VSync, no kill/save IO" % [count, str(not OS.get_cmdline_user_args().has("--no-magic")), times[times.size()/2], times[int(times.size()*0.95)]])
	game.queue_free()
	await process_frame
	quit()
