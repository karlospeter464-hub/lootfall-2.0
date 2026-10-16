extends SceneTree

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--test-mode"):
		push_error("Pass -- --test-mode to isolate progress.")
		quit(1)
		return
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in count:
		await physics_frame
	await process_frame

func run() -> void:
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.player.controls_enabled = false
	check(game.player.health == game.player.max_health, "A run starts with full health")
	check(game.wave == 0 and game.upgrades_chosen == 0, "A run starts without wave or upgrades")
	game.player.take_damage(10)
	game.player.take_damage(10)
	check(game.player.health == game.player.max_health - 10, "Contact protection rejects overlapping hits")
	game.player.reset_run()
	game.player.controls_enabled = true
	var before: Vector2 = game.player.position
	Input.action_press("move_right")
	await frames(6)
	Input.action_release("move_right")
	check(game.player.position.x > before.x, "The configured movement action moves the player")
	game.player.position = Vector2(1210, 420)
	Input.action_press("move_right")
	await frames(6)
	Input.action_release("move_right")
	check(game.player.position.x <= game.BOUNDS.end.x - 17, "The player cannot cross the arena boundary")
	game.player.controls_enabled = false
	game.player.position = Vector2(640, 420)
	game.begin_wave()
	game.enemy_limit = 2
	game.spawn_enemy()
	game.spawn_enemy()
	game.spawn_enemy()
	check(game.enemies.get_child_count() == 2, "The spawner enforces the active enemy cap")
	check(game.remaining_to_spawn == game.first_wave_enemies - 2, "Blocked spawns do not consume the wave budget")
	for enemy in game.enemies.get_children():
		check(enemy.position.distance_to(game.player.position) >= game.safe_spawn_distance, "Enemies spawn away from the player")
		check(game.BOUNDS.has_point(enemy.position), "Enemies spawn inside the arena")
		check(enemy.health > 0, "Spawned enemies have initialized health")
	game.player.cooldown = 0
	game.player.attack(Vector2.RIGHT)
	game.player.attack(Vector2.RIGHT)
	check(game.projectiles.get_child_count() == 1, "Holding fire respects the cast interval")
	game.pause_run()
	var enemy_before: Vector2 = game.enemies.get_child(0).position
	var shot_before: Vector2 = game.projectiles.get_child(0).position
	await frames(4)
	check(game.enemies.get_child(0).position == enemy_before, "Pause freezes enemy movement")
	check(game.projectiles.get_child(0).position == shot_before, "Pause freezes projectiles")
	var escape := InputEventAction.new()
	escape.action = "pause"
	escape.pressed = true
	root.push_input(escape)
	await process_frame
	check(not paused and game.state == game.State.FIGHTING, "Escape reaches the arena and resumes while paused")
	game.restart_run()
	game.player.controls_enabled = false
	check(game.enemies.get_child_count() == 0 and game.projectiles.get_child_count() == 0, "Restart clears every active entity immediately")
	game.begin_wave()
	game.spawn_enemy()
	var victim = game.enemies.get_child(0)
	victim.position = Vector2(940, 420)
	victim.set_physics_process(false)
	var old_health: float = victim.health
	game.player.cooldown = 0
	game.player.projectile_count = 2
	game.player.attack(Vector2.RIGHT)
	check(game.projectiles.get_child_count() == 2, "Fire Fan adds a projectile to the cast")
	check(game.projectiles.get_child(0).direction == Vector2.RIGHT, "Fire Fan preserves the aimed central shot")
	await frames(40)
	check(victim.health == old_health - game.player.damage, "A real swept projectile hits an enemy exactly once")
	check(game.projectiles.get_child_count() == 1, "Only the fireball that hit is consumed")
	victim.position = game.player.position
	victim.set_physics_process(true)
	await frames(4)
	check(game.player.health < game.player.max_health, "A real enemy contact damages the player")
	game.restart_run()
	game.player.controls_enabled = false
	game.begin_wave()
	game._cast(game.player.position, Vector2.UP, 1)
	await frames(120)
	check(game.projectiles.get_child_count() == 0, "Missed projectiles expire")
	game.restart_run()
	game.player.controls_enabled = false
	game.enemy_limit = 18
	for wave_index in range(1, 7):
		game.begin_wave()
		check(game.wave == wave_index, "Wave number progresses once")
		check(game.remaining_to_spawn == game.first_wave_enemies + (wave_index - 1) * game.enemies_per_wave, "Wave pressure increases")
		while game.remaining_to_spawn > 0:
			game.spawn_enemy()
			var enemy = game.enemies.get_child(0)
			enemy.take_damage(10000)
			enemy.take_damage(10000)
			await process_frame
		game.complete_wave()
		if wave_index in [2, 4]:
			check(paused and game.state == game.State.UPGRADE, "Wave 2 and 4 freeze combat for a choice")
			check(game.buttons.get_child_count() == 3, "Exactly three upgrade cards are offered")
			var previous_count: int = game.player.projectile_count
			game.buttons.get_child(2).pressed.emit()
			check(game.player.projectile_count == previous_count + 1, "The actual Fire Fan button adds one projectile")
			game.choose_upgrade(2)
			check(game.player.projectile_count == previous_count + 1, "A stale click cannot apply a second upgrade")
			check(not paused, "Choosing an upgrade resumes the run")
	check(game.state == game.State.FINISHED and paused, "Completing wave 6 ends the run")
	check(game.upgrades_chosen == 2, "A complete run offers exactly two choices")
	check(game.kills == 108, "Six waves count each defeated enemy once")
	check(game.best_wave == 6, "The session record reaches wave 6")
	game.restart_run()
	game.player.controls_enabled = false
	check(game.best_wave == 6 and game.wave == 0, "Restart retains only the session record")
	check(game.player.projectile_count == 1 and game.player.damage == game.player.base_damage, "Restart resets build modifiers")
	check(game.player.cast_interval == game.player.base_cast_interval and game.kills == 0, "Restart resets cast speed and kills")
	game.state = game.State.UPGRADE
	game.choose_upgrade(0)
	check(is_equal_approx(game.player.damage, game.player.base_damage * 1.35), "Ember Power increases actual attack damage")
	game.state = game.State.UPGRADE
	game.choose_upgrade(1)
	check(is_equal_approx(game.player.cast_interval, game.player.base_cast_interval * 0.8), "Quick Casting shortens the actual cooldown")
	game.restart_run()
	game.player.controls_enabled = false
	game.player.take_damage(game.player.max_health)
	check(game.state == game.State.FINISHED and paused, "Lethal damage ends the run")
	game.buttons.get_child(0).pressed.emit()
	check(not paused and game.player.health == game.player.max_health, "The result button starts a healthy new run")
	game.pause_run()
	game.resume_run()
	check(game.state == game.State.BETWEEN_WAVES, "Pausing an intermission preserves its state")
	game.queue_free()
	await process_frame
	print("ARENA TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
