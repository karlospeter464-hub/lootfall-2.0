extends SceneTree

const SAFE_JSON = preload("res://scripts/safe_json.gd")
var game
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

func frames(count: int = 2) -> void:
	for index in count:
		await physics_frame
	await process_frame

func open_fight(number: int) -> void:
	check(game.start_ascent_test(number), "Isolated wave jump works at %d" % number)
	game.set_process(false)
	game.player.controls_enabled = false
	game.equipment_drop_chance = 0
	if game.state == game.State.BOSS_INTRO:
		game._process(2.1)
	game.player.controls_enabled = false

func drain_wave() -> void:
	while game.remaining_to_spawn > 0 or game.enemies.get_child_count() > 0:
		game.spawn_enemy()
		for enemy in game.enemies.get_children():
			enemy.take_damage(1000000000)
		await process_frame

func compare_threshold(threshold: int, build_index: int) -> void:
	game.seer_interrupt_hits = threshold
	game.start_counterplay_test(build_index, 1)
	game.set_process(false)
	game.player.controls_enabled = false
	var seer = game.enemies.get_child(0)
	seer.set_physics_process(false)
	seer.cooldown = 0
	seer._physics_process(0)
	for index in 84:
		game.player.attack(game.player.position.direction_to(seer.position))
		seer._physics_process(1.0 / 60)
		seer.position = Vector2(660, 420)
		await frames(1)
	var expected: bool = build_index == 0 or threshold == 3
	check((threshold == 4 or (seer.interruptions == 1) == expected) and seer.interruptions <= 1 and seer.health > 0, "Real profile %d versus %d-hit seer; four is a timing boundary" % [build_index, threshold])
	print("INTERRUPT COMPARISON: threshold=%d profile=%d interruptions=%d hits=%d hp=%.2f" % [threshold, build_index, seer.interruptions, game.shots_hit, seer.health])

func run() -> void:
	game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.total_waves == 100 and game.seer_interrupt_hits == 3, "CE2 defaults use safety cap 100 and three direct hits")
	game.restart_run()
	game.set_process(false)
	game.player.controls_enabled = false
	game.equipment_drop_chance = 0
	var choices: Array[int] = []
	for number in range(1, 21):
		game.begin_wave()
		if game.is_boss_wave(number):
			check(game.state == game.State.BOSS_INTRO and game.enemies.get_child_count() == 0, "Boss %d is announced before spawning" % number)
			game.complete_wave()
			check(game.completed_waves == number - 1, "Announcement cannot complete or reward the boss wave")
			game._process(2.1)
		game.spawn_enemy()
		if game.is_boss_wave(number):
			check(is_instance_valid(game.boss) and game.boss.boss_name == game.boss_title(number), "Correct recurring boss at wave %d" % number)
			check(game.boss.get_script() == (game.RANGED_ENEMY if number % 10 == 0 else game.GUARDIAN_ENEMY), "Boss reuses the correct existing behavior")
			game.boss.take_damage(1000000000)
			await process_frame
			game.complete_wave()
			check(game.state == game.State.FIGHTING and game.completed_waves < number, "Dead boss alone cannot finish a wave with pending escorts")
		await drain_wave()
		game.complete_wave()
		check(game.completed_waves == number and game.progress.echoes == 0, "Wave %d completes once without interim currency" % number)
		if game.card_wave(number):
			choices.append(number)
			check(game.state == game.State.UPGRADE and game.buttons.get_child_count() == 3, "Three random valid mechanics offered after card wave %d" % number)
			check(game.overlay_title.text.contains("BOSS") == game.is_boss_wave(number), "Boss cards have distinct presentation")
			game.offered_cards.assign([0])
			game.choose_upgrade(0)
			var count: int = game.upgrades_chosen
			game.offered_cards.assign([0])
			game.choose_upgrade(0)
			check(game.upgrades_chosen == count, "Stale card action cannot grant another upgrade")
		check(game.state == game.State.BETWEEN_WAVES, "Ascent continues after wave %d" % number)
	check(choices == [2, 4, 5, 7, 9, 10, 12, 14, 15, 17, 19, 20], "Exact repeating normal and boss card schedule through twenty")
	check(game.wave_summaries.size() == 20, "Each completed wave has one bounded timing / composition record")
	for number in [0, 1, 2, 3, 4, 5, 6, 7, 10, 15, 20, 100]:
		game.completed_waves = number
		var expected: int = 10 * number * (number + 1) / 2 if number <= 6 else 210 + (number - 6) * 25 + (number - 6) * (number - 7)
		check(game.predicted_reward() == expected, "Piecewise Echoes curve at %d" % number)
	game.completed_waves = 20
	game.finish_run(false)
	check(game.progress.echoes == 742 and game.reward_saved, "Long-run death pays exactly 742 once")
	game.settle_reward()
	check(game.progress.echoes == 742, "Repeated settlement cannot duplicate long-run reward")
	var loaded = game.PROGRESS.new()
	loaded.path = game.progress.path
	check(loaded.load_progress() and loaded.best_wave == 20 and loaded.echoes == 742, "Best reached wave and long-run reward persist")
	var ended: float = game.run_wall_seconds()
	await frames(3)
	check(game.run_wall_seconds() == ended, "Result freezes wall duration")
	game.return_to_town()
	check(game.state == game.State.TOWN and game.progress.echoes == 742, "Long ascent returns safely to Emberhaven")
	game.restart_run()
	game.begin_wave()
	check(game.wave == 1 and game.upgrades_chosen == 0 and game.bag_used() == 0, "New ascent restarts at wave one without run gear or cards")
	open_fight(10)
	game.enemy_limit = 1
	game.spawn_enemy()
	var prophet = game.boss
	prophet.set_physics_process(false)
	prophet.cooldown = 0
	prophet._physics_process(0)
	for index in 3:
		prophet.take_projectile_hit(1)
	check(prophet.interruptions == 1 and prophet.protected_cast and not prophet.charging, "First boss cast can be interrupted and protects the next cast")
	prophet.cooldown = 0
	prophet._physics_process(0)
	for index in 20:
		prophet.take_projectile_hit(1)
	check(prophet.charging and prophet.interruptions == 1, "Next boss cast cannot be permanently locked by repeated hits")
	var hp: float = game.player.health
	game.player.position += Vector2(0, 180)
	prophet._physics_process(prophet.windup)
	check(not prophet.protected_cast and game.player.health == hp, "Protected boss cast still resolves with normal dodge counterplay")
	game.spawn_enemy()
	check(game.enemies.get_child_count() == 1 and game.remaining_to_spawn == game.boss_escorts, "Total cap one defers escorts without consuming their budget")
	await drain_wave()
	game.complete_wave()
	check(game.state == game.State.UPGRADE, "Boss plus escorts can be cleared with total cap one")
	game.offered_cards.assign([0])
	game.choose_upgrade(0)
	game.enemy_limit = 12
	game.start_ascent_test(5)
	var intro: float = game.break_clock
	game.pause_run()
	game._process(1)
	check(game.break_clock == intro, "Escape pause freezes boss announcement")
	game.resume_run()
	game.dev_console.open_console()
	game._process(1)
	check(game.break_clock == intro and game.state == game.State.BOSS_INTRO, "F1 preserves announcement state and timer")
	game.dev_console.close_console()
	game.inventory_panel.open_inventory()
	game._process(1)
	await frames(3)
	check(game.break_clock == intro and game.run_wall_seconds() > 0, "Inventory freezes gameplay but wall time includes decision / pause time")
	game.inventory_panel.close_inventory()
	game._process(2.1)
	game.spawn_enemy()
	game.boss.set_physics_process(false)
	game.inventory_panel.open_inventory()
	var combat: float = game.wave_seconds
	game._process(1)
	check(game.wave_seconds == combat, "Inventory does not count paused time as wave combat")
	game.inventory_panel.close_inventory()
	game._process(0.2)
	check(game.wave_seconds >= combat + 0.2, "Wave combat timer advances only in active combat")
	game.power_upgrades = 100
	game.quick_upgrades = 100
	game.fan_upgrades = 100
	game.update_build()
	game.player.hurt_haste_ratio = 0.8
	game.player.haste_remaining = 3
	check(game.player.effective_interval() == 0.08 and game.player.projectile_count == 9 and is_finite(game.player.damage), "Repeated cards and haste respect technical limits")
	game.state = game.State.UPGRADE
	game.mechanic_cards.assign([3, 4, 5])
	game.roll_upgrade_cards()
	game.refresh_upgrade_cards()
	check(game.offered_cards == [0] and game.buttons.get_child_count() == 1, "Saturated cards are excluded and Power remains usable")
	var before: int = game.upgrades_chosen
	game.offered_cards.assign([2])
	game.choose_upgrade(2)
	check(game.upgrades_chosen == before, "Saturated card cannot be selected through a stale signal")
	game.state = game.State.FIGHTING
	paused = false
	for index in 300:
		game._cast(game.player.position, Vector2.RIGHT, 1)
	check(game.projectiles.get_child_count() == 256, "Live projectile cap prevents runaway spawning")
	for number in range(1, 101):
		var settings: Dictionary = game.wave_settings(number)
		check(is_finite(settings.health) and settings.health > 0 and settings.health <= 1000000 and settings.damage <= 200 and settings.speed <= 200 and settings.budget <= 28 and settings.spawn_interval >= 0.18, "Bounded scaling at wave %d" % number)
	check(game.wave_settings(6).health < game.wave_settings(7).health and game.wave_settings(6).seer_every > game.wave_settings(7).seer_every, "Post-boss recovery eases health and role pressure")
	game.ascent_health_scale = 1.35
	game.ascent_damage_growth = 0.1
	game.enemy_health = 500
	game.enemy_health_growth = 50
	game.enemy_damage = 100
	game.boss_health_multiplier = 15
	open_fight(100)
	game.spawn_enemy()
	check(game.boss.max_health == 1000000 and game.boss.contact_damage <= 200 and is_finite(game.boss.health), "Maximum configured scaling produces finite capped boss values")
	game.dev_console.reset_defaults()
	game.ranged_limit = 0
	game.guardian_limit = 0
	open_fight(10)
	game.spawn_enemy()
	check(is_instance_valid(game.boss) and game.boss.boss_name == "ASH PROPHET", "Zero escort-role caps cannot accidentally remove the mandatory boss")
	var dev = game.dev_console
	dev.reset_defaults()
	dev.save_profile()
	var profile: Dictionary = SAFE_JSON.read_object(dev.profile_path)
	check(profile.version == 9 and profile.values.size() == 87, "New balancing profile includes all 87 values")
	profile.version = 6
	for field in dev.FIELDS:
		if dev.field_version(field) > 6:
			profile.values.erase(field[1] + "." + field[2])
	profile.values["arena.total_waves"] = 6
	SAFE_JSON.write_object(dev.profile_path, profile)
	dev.apply_setting("arena.echoes_after_six", 999)
	check(dev.load_profile() and game.echoes_after_six == 25 and game.total_waves == 6 and profile.values.size() == 63, "Legacy v6 keeps its old numeric cap and defaults new ascent fields")
	game.start_ascent_test(6)
	await drain_wave()
	game.complete_wave()
	check(game.state == game.State.FINISHED and game.overlay_title.text.contains("LIMIT") and game.overlay_text.text.contains("not a victory"), "Legacy six-wave cap is a clear safety stop rather than a win")
	dev.reset_defaults()
	for threshold in [3, 4, 5]:
		for build_index in [0, 1, 2]:
			await compare_threshold(threshold, build_index)
	game.queue_free()
	await process_frame
	print("ASCENT TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
