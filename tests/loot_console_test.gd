extends SceneTree

const SAFE_JSON = preload("res://scripts/safe_json.gd")
const PROGRESS = preload("res://scripts/progress_store.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--test-mode"):
		push_error("Pass -- --test-mode to isolate progress and profiles.")
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
	game.drop_chance = 1.0
	game.begin_wave()
	game.spawn_enemy()
	var first = game.enemies.get_child(0)
	var drop_position: Vector2 = first.position
	first.take_damage(10000)
	await process_frame
	check(game.loot.get_child_count() == 1, "A guaranteed eligible kill drops one physical Codex")
	check(game.loot.get_child(0).position == drop_position, "The item stays at the defeated enemy")
	check(game.progress.echoes == 0, "An item drop does not award Echoes")
	game.spawn_enemy()
	game.enemies.get_child(0).take_damage(10000)
	await process_frame
	check(game.loot.get_child_count() == 1, "A pending item prevents duplicate drops")
	game.player.position = drop_position
	await frames(3)
	check(game.codex_active and game.loot.get_child_count() == 0, "Physical contact collects the item exactly once")
	game.drop_codex(game.player.position)
	check(game.loot.get_child_count() == 0, "An active Codex cannot stack")
	game.spawn_enemy()
	game.spawn_enemy()
	var primary = game.enemies.get_child(0)
	var secondary = game.enemies.get_child(1)
	primary.position = Vector2(850, 420)
	secondary.position = Vector2(850, 475)
	primary.set_physics_process(false)
	secondary.set_physics_process(false)
	game.player.position = Vector2(640, 420)
	var primary_hp: float = primary.health
	var secondary_hp: float = secondary.health
	game.player.cooldown = 0
	game.player.attack(Vector2.RIGHT)
	await frames(30)
	check(primary.health == primary_hp - game.player.damage, "Explosion does not double-hit the primary enemy")
	check(is_equal_approx(secondary.health, secondary_hp - game.player.damage * game.explosion_damage_ratio), "Actual projectile impact applies splash to a nearby enemy")
	check(game.shots_hit == 1 and game.damage_dealt > game.player.damage, "Combat metrics include direct and splash damage")
	game.restart_run()
	game.player.controls_enabled = false
	check(not game.codex_active and game.loot.get_child_count() == 0, "Run restart removes the Codex and ground loot")
	game.drop_chance = 0
	game.begin_wave()
	game.spawn_enemy()
	game.enemies.get_child(0).take_damage(10000)
	await process_frame
	check(game.loot.get_child_count() == 0, "Zero drop chance suppresses random items")
	game.completed_waves = 0
	check(game.predicted_reward() == 0, "Entering a wave alone earns no Echoes")
	game.completed_waves = 3
	check(game.predicted_reward() == 60, "Cleared wave tiers pay 10 + 20 + 30")
	game.completed_waves = 6
	check(game.predicted_reward() == 210, "Pushing to wave six increases the payout")
	game.completed_waves = 3
	game.finish_run(false)
	check(game.reward_saved and game.progress.echoes == 60, "Death pays once based on cleared waves")
	game.finish_run(false)
	game.settle_reward()
	check(game.progress.echoes == 60, "Repeated finish and save calls cannot duplicate the reward")
	var persisted = PROGRESS.new()
	persisted.path = game.progress.path
	check(persisted.load_progress() and persisted.echoes == 60, "Echoes survive a fresh progress-store instance")
	check(persisted.award(5, 4), "A second save replaces the progress file safely")
	check(SAFE_JSON.read_object(persisted.path + ".bak").get("echoes") == 60, "The previous valid wallet is retained as a backup")
	var recovered = PROGRESS.new()
	recovered.path = "user://backup_test_%d.json" % OS.get_process_id()
	SAFE_JSON.write_object(recovered.path + ".bak", {"version": 1, "echoes": 15, "best_wave": 2})
	check(recovered.load_progress() and recovered.echoes == 15, "An interrupted rename can load a validated backup")
	check(recovered.award(5, 3) and FileAccess.file_exists(recovered.path), "A recovered wallet can be saved back to the main file")
	game.restart_run()
	game.player.controls_enabled = false
	check(game.progress.echoes == 60 and game.completed_waves == 0, "A new run retains currency but resets wave credit")
	game.settle_reward()
	check(game.progress.echoes == 60, "A save call during a run cannot pay out")
	var dev = game.dev_console
	check(dev.controls.size() == 28, "Every supported setting has a console control")
	var original_speed: float = game.player.move_speed
	check(dev.apply_setting("player.move_speed", 350) and game.player.move_speed == 350, "Movement tuning reaches the real player")
	check(not dev.apply_setting("arena.enemy_limit", -1), "Negative caps are rejected")
	check(not dev.apply_setting("arena.enemy_limit", 1.5), "Fractional enemy caps are rejected")
	check(not dev.apply_setting("player.base_damage", NAN), "Non-finite settings are rejected")
	check(not dev.apply_setting("unknown.key", 1), "Unknown settings are rejected")
	dev.controls["player.base_damage"].value = 20
	check(game.player.damage == 20, "A real SpinBox signal changes actual fireball damage")
	game.state = game.State.UPGRADE
	game.choose_upgrade(0)
	dev.apply_setting("player.base_damage", 30)
	check(is_equal_approx(game.player.damage, 40.5), "Tuning preserves existing upgrade multipliers")
	game.state = game.State.UPGRADE
	game.choose_upgrade(2)
	dev.apply_setting("arena.upgrade_projectiles", 3)
	check(game.player.projectile_count == 4, "Projectile-card tuning updates the active build")
	game.state = game.State.FIGHTING
	game.player.cooldown = 0
	game.player.attack(Vector2.RIGHT)
	var directions: Array[Vector2] = []
	for shot in game.projectiles.get_children():
		directions.append(shot.direction)
	check(directions.size() == 4 and directions[1] != directions[3], "Larger fans use distinct side angles")
	dev.open_console()
	check(paused and not game.player.controls_enabled, "Opening the console freezes gameplay and disables world input")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	await process_frame
	check(not dev.is_open and not paused and game.state == game.State.FIGHTING, "Escape closes the console without also pausing the arena")
	game.pause_run()
	dev.open_console()
	dev.close_console()
	check(paused and game.state == game.State.PAUSED, "Closing the console preserves an existing pause")
	game.resume_run()
	game.state = game.State.UPGRADE
	paused = true
	dev.open_console()
	dev.close_console()
	check(paused and game.state == game.State.UPGRADE, "Closing the console does not resume an upgrade choice")
	paused = false
	game.state = game.State.FIGHTING
	dev.open_console()
	dev.tabs.current_tab = 2
	dev.close_console()
	check(dev.save_profile(), "A real balance profile is saved")
	dev.apply_setting("player.move_speed", 250)
	check(dev.load_profile() and game.player.move_speed == 350, "Saved settings load back into the game")
	var profile: Dictionary = SAFE_JSON.read_object(dev.profile_path)
	profile.values["player.move_speed"] = 400
	profile.values["arena.enemy_limit"] = -8
	check(SAFE_JSON.write_object(dev.profile_path, profile) == OK, "The invalid-profile fixture is written")
	check(not dev.load_profile() and game.player.move_speed == 350, "Whole-profile validation prevents a partially applied invalid profile")
	dev.freeze_enemies(true)
	game.remaining_to_spawn = 1
	game.spawn_enemy()
	check(game.enemies.get_child(0).frozen, "Freeze applies to future spawns")
	game.player.invulnerable = true
	var health_before: float = game.player.health
	game.player.take_damage(20)
	check(game.player.health == health_before, "Invulnerability reaches actual damage handling")
	dev.reset_defaults()
	check(game.player.move_speed == original_speed and not game.player.invulnerable and not game.enemies_frozen, "Default reset restores startup values and clears test switches")
	game.player.invulnerable = true
	game.restart_run()
	game.player.controls_enabled = false
	check(not game.player.invulnerable and not game.enemies_frozen, "New runs clear transient test switches")
	var corrupt_path: String = "user://corrupt_test_%d.json" % OS.get_process_id()
	var file := FileAccess.open(corrupt_path, FileAccess.WRITE)
	file.store_string("{broken original")
	file.close()
	var damaged = PROGRESS.new()
	damaged.path = corrupt_path
	check(not damaged.load_progress() and not damaged.award(10, 2), "Corrupt saves block destructive replacement")
	check(FileAccess.get_file_as_string(corrupt_path) == "{broken original", "The corrupt original remains byte-for-byte intact")
	var invalid_path: String = "user://invalid_test_%d.json" % OS.get_process_id()
	SAFE_JSON.write_object(invalid_path, {"version": 1, "echoes": -1, "best_wave": 2})
	damaged.path = invalid_path
	check(not damaged.load_progress(), "Negative currency is rejected at the save boundary")
	SAFE_JSON.write_object(invalid_path, {"version": 1, "echoes": 1.5, "best_wave": 2})
	check(not damaged.load_progress(), "Fractional currency is rejected at the save boundary")
	var failure_store = PROGRESS.new()
	failure_store.path = "user://missing_parent_%d/progress.json" % OS.get_process_id()
	check(not failure_store.award(10, 2) and failure_store.echoes == 0, "Failed writes do not mutate the in-memory wallet")
	game.progress = failure_store
	game.completed_waves = 2
	game.finish_run(false)
	game.restart_run()
	check(game.state == game.State.FINISHED and not game.reward_saved, "A failed payout cannot be silently abandoned by restart")
	failure_store.path = "user://recovered_test_%d.json" % OS.get_process_id()
	game.settle_reward()
	check(game.reward_saved and failure_store.echoes == 30, "A failed payout can be retried successfully")
	game.settle_reward()
	check(failure_store.echoes == 30, "A successful retry cannot pay twice")
	game.restart_run()
	check(not paused and game.state == game.State.BETWEEN_WAVES, "Restart succeeds after the pending reward is saved")
	game.queue_free()
	await process_frame
	print("LOOT / CONSOLE TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
