extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--test-mode"):
		quit(1)
		return
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.restart_run()
	game.set_process(false)
	game.player.controls_enabled = false
	game.begin_wave()
	for role in ["chaser", "seer", "guardian"]:
		game.remaining_to_spawn = 1
		game.spawn_enemy(role)
		var enemy = game.enemies.get_child(-1)
		enemy.set_physics_process(false)
		enemy.set_process(false)
		var before: Transform2D = enemy.transform
		var health: float = enemy.health
		var clock: float = enemy.visual_clock
		enemy._process(0.1)
		check(is_equal_approx(enemy.visual_clock, clock + 0.1), role + " advances its visual clock")
		enemy.frozen = true
		enemy._process(0.1)
		check(is_equal_approx(enemy.visual_clock, clock + 0.1), role + " visual animation honors frozen state")
		check(enemy.transform == before and enemy.health == health, role + " visual animation leaves body transform and health unchanged")
		enemy.frozen = false
		enemy.set_process(true)
	var rng_state: int = game.rng.state
	var position: Vector2 = game.player.position
	var health: float = game.player.health
	for index in 4:
		game.queue_redraw()
		for enemy in game.enemies.get_children():
			enemy.queue_redraw()
		await process_frame
	check(game.rng.state == rng_state, "Procedural scene animation/rendering never consumes gameplay RNG")
	check(game.player.position == position and game.player.health == health, "Idle visual updates leave player physics and health unchanged")
	paused = true
	var clocks: Array = game.enemies.get_children().map(func(enemy): return enemy.visual_clock)
	for index in 3:
		await process_frame
	check(clocks == game.enemies.get_children().map(func(enemy): return enemy.visual_clock), "Pause freezes all enemy visual clocks")
	paused = false
	game.queue_free()
	await process_frame
	print("VISUAL LIFT TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
