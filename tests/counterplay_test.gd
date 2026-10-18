extends SceneTree

const SAFE_JSON = preload("res://scripts/safe_json.gd")
var checks: int = 0
var failures: int = 0
var game

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

func frames(count: int) -> void:
	for index in count:
		await physics_frame
	await process_frame

func setup(build_index: int, role_index: int):
	check(game.start_counterplay_test(build_index, role_index), "Isolated arrangement can be restarted")
	game.set_process(false)
	game.player.controls_enabled = false
	for enemy in game.enemies.get_children():
		enemy.set_physics_process(false)
	return game.enemies.get_child(0)

func shoot_during_warning(build_index: int) -> Dictionary:
	var seer = setup(0 if build_index == -1 else build_index, 1)
	if build_index == -1:
		game.quick_upgrades = 0
		game.equipment.scepter = ""
		game.update_build()
	seer.cooldown = 0
	seer._physics_process(0)
	var initial_hp: float = seer.health
	# Real player cooldown, real swept projectiles, fixed warning and moving-knockback-free target.
	for index in 72:
		if not is_instance_valid(seer):
			break
		if index < 66:
			game.player.attack(game.player.global_position.direction_to(seer.global_position))
		seer._physics_process(1.0 / 60)
		seer.position = Vector2(660, 420)
		await frames(1)
	var result := {"interruptions": seer.interruptions if is_instance_valid(seer) else 0, "hp": seer.health if is_instance_valid(seer) else 0.0, "initial_hp": initial_hp, "hits": game.shots_hit}
	print("CE1 projectiles / %s: %s" % ["Rapid" if build_index == 0 else "Heavy", result])
	return result

func run() -> void:
	game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var guardian = setup(0, 2)
	var hp: float = guardian.health
	guardian.take_projectile_hit(14)
	check(is_equal_approx(hp - guardian.health, 6), "Guardian subtracts flat armor once on direct hits")
	hp = guardian.health
	guardian.take_damage(4)
	check(is_equal_approx(hp - guardian.health, 0.8), "Small splash hits retain the minimum incoming fraction")
	hp = guardian.health
	guardian.take_damage(0)
	guardian.take_damage(-5)
	check(guardian.health == hp, "Non-positive damage cannot heal or damage a guardian")
	guardian.take_damage(40)
	check(is_equal_approx(hp - guardian.health, 32), "Large hits lose the same flat armor rather than a percentage")
	check(6.0 / 14 < 32.0 / 40, "Equal raw DPS keeps a larger share with heavy hits")
	guardian.minimum_ratio = 1
	hp = guardian.health
	guardian.take_damage(10)
	check(is_equal_approx(hp - guardian.health, 10), "A 100-percent floor permits full incoming damage")
	var primary = setup(2, 0)
	game.remaining_to_spawn = 1
	game.spawn_enemy("guardian")
	guardian = game.enemies.get_child(game.enemies.get_child_count() - 1)
	guardian.set_physics_process(false)
	guardian.position = primary.position + Vector2(40, 0)
	hp = guardian.health
	game.projectile_impact(primary.position, 20, primary)
	check(is_equal_approx(hp - guardian.health, 4), "Real Codex splash applies 20 * 0.6 - 8 armor once")
	hp = guardian.health
	game.projectile_impact(guardian.position, 20, guardian)
	check(guardian.health == hp, "Direct target never takes a second Codex splash hit")
	var seer = setup(0, 1)
	seer.cooldown = 0
	seer._physics_process(0)
	for index in 4:
		seer.take_projectile_hit(1)
	check(seer.charging and seer.concentration_hits == 4, "Insufficient direct hits preserve the warning")
	seer.take_damage(1)
	check(seer.concentration_hits == 4, "Splash does not impersonate a direct projectile")
	seer.take_projectile_hit(1)
	check(not seer.charging and seer.interruptions == 1 and seer.interrupted_left > 0, "Fifth direct hit breaks concentration with visual feedback")
	check(seer.charge_left == 0 and seer.concentration_hits == 0 and seer.cooldown == seer.attack_interval and seer.impact_left == 0, "Interruption clears attack and grants a full recovery")
	seer.take_projectile_hit(1)
	check(seer.interruptions == 1 and seer.concentration_hits == 0, "Recovery hits cannot interrupt a second time")
	seer.cooldown = 0
	seer._physics_process(0)
	check(seer.charging and seer.concentration_hits == 0, "Next warning starts with fresh concentration")
	seer.take_projectile_hit(1)
	seer._physics_process(seer.windup)
	check(not seer.charging and seer.concentration_hits == 0 and seer.impact_left > 0, "Insufficient hits let the cast resolve and clear the counter")
	seer.cooldown = 0
	seer._physics_process(0)
	seer.interrupt_hits = 0
	for index in 8:
		seer.take_projectile_hit(1)
	check(seer.charging and seer.concentration_hits == 0, "Zero threshold explicitly disables interruption")
	seer.interrupt_hits = 5
	seer.take_projectile_hit(1)
	seer.set_physics_process(true)
	game.inventory_panel.open_inventory()
	var left: float = seer.charge_left
	await frames(8)
	check(seer.charge_left == left and seer.concentration_hits == 1, "Inventory pause freezes warning and hit counter")
	game.inventory_panel.close_inventory()
	seer.frozen = true
	await frames(8)
	check(seer.charge_left == left and seer.concentration_hits == 1, "Enemy freeze preserves concentration")
	seer.take_damage(10000)
	check(seer.dead and not seer.charging and seer.concentration_hits == 0 and seer.charge_left == 0, "Lethal damage clears a pending cast immediately")
	await frames(2)
	seer = setup(0, 1)
	seer.cooldown = 0
	seer.set_physics_process(true)
	await frames(2)
	game.player.protection = 0
	game.player.take_damage(10000)
	left = seer.charge_left
	await frames(8)
	check(game.state == game.State.FINISHED and seer.charge_left == left, "Player death pauses pending enemy attacks")
	game.restart_run()
	check(game.enemies.get_child_count() == 0 and game.projectiles.get_child_count() == 0, "Restart removes all pending attacks and projectiles")
	var rapid: Dictionary = await shoot_during_warning(0)
	check(rapid.interruptions == 1 and rapid.hp > 0 and rapid.hits >= 5, "Actual Swift + two Quick build interrupts a living default seer")
	var heavy: Dictionary = await shoot_during_warning(1)
	check(heavy.interruptions == 0 and heavy.hits < 5, "Actual heavy build cannot reach the interruption threshold")
	check(heavy.hp < heavy.initial_hp, "Heavy build still damages the seer")
	var standard: Dictionary = await shoot_during_warning(-1)
	check(standard.interruptions == 0 and standard.hp > 0 and standard.hits < 5, "Standard 0.36-second fireball cannot interrupt the living seer")
	var chaser = setup(2, 0)
	var group_hp: float = 0
	for enemy in game.enemies.get_children():
		group_hp += enemy.health
	game.projectile_impact(chaser.position, game.player.damage, chaser)
	var group_after: float = 0
	for enemy in game.enemies.get_children():
		group_after += enemy.health
	check(is_equal_approx(group_hp - group_after, 5 * game.player.damage * game.explosion_damage_ratio), "Area arrangement splashes all five neighboring chasers, excluding primary")
	guardian = setup(0, 2)
	game.guardian_minimum_ratio = 1
	game.guardian_armor = 0
	# Existing guardians keep their spawn-time armor settings.
	for enemy in game.enemies.get_children():
		enemy.take_damage(enemy.health / enemy.minimum_ratio + enemy.armor if enemy.get_script() == game.GUARDIAN_ENEMY else enemy.health)
	check(guardian.dead, "Debug defeat remains lethal even after tuning changes existing guardian armor")
	game.restart_run()
	game.player.controls_enabled = false
	game.set_process(false)
	for wave_index in [1, 2, 3, 6]:
		game.restart_run()
		game.wave = wave_index - 1
		game.begin_wave()
		for index in 40:
			game.spawn_enemy()
		var guardians: Array = game.enemies.get_children().filter(func(enemy): return enemy.get_script() == game.GUARDIAN_ENEMY)
		var seers: Array = game.enemies.get_children().filter(func(enemy): return enemy.get_script() == game.RANGED_ENEMY)
		check(guardians.size() == (0 if wave_index < 3 else 1), "Guardian first wave and one-alive cap: wave %d" % wave_index)
		check(seers.size() <= game.ranged_limit and game.enemies.get_child_count() <= game.enemy_limit, "Both role caps respect global cap: wave %d" % wave_index)
	game.restart_run()
	game.guardian_limit = 0
	game.ranged_limit = 0
	game.wave = 5
	game.begin_wave()
	for index in 12:
		game.spawn_enemy()
	check(game.enemies.get_children().all(func(enemy): return enemy.get_script() != game.GUARDIAN_ENEMY and enemy.get_script() != game.RANGED_ENEMY), "Zero role caps disable new spawns")
	var dev = game.dev_console
	dev.reset_defaults()
	check(dev.save_profile(), "CE1 profile saves")
	var profile: Dictionary = SAFE_JSON.read_object(dev.profile_path)
	check(profile.version == 6 and profile.values.size() == 63, "Profile six has all 63 values")
	profile.version = 5
	for field in dev.FIELDS:
		if dev.field_version(field) > 5:
			profile.values.erase(field[1] + "." + field[2])
	SAFE_JSON.write_object(dev.profile_path, profile)
	dev.apply_setting("arena.guardian_armor", 30)
	check(dev.load_profile() and game.guardian_armor == 8 and profile.values.size() == 54, "Legacy v5 loads with CE1 startup defaults")
	profile.values["arena.guardian_armor"] = 30
	SAFE_JSON.write_object(dev.profile_path, profile)
	check(not dev.load_profile() and game.guardian_armor == 8, "Unexpected legacy CE1 keys reject atomically")
	for build_index in 3:
		for role_index in 3:
			setup(build_index, role_index)
			check(game.active_talents.is_empty() and game.upgrades_chosen == 2, "All nine arrangements use the same no-talent baseline")
	game.queue_free()
	await process_frame
	print("COUNTERPLAY TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
