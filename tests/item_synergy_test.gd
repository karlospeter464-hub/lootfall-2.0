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

func reset(scepter: String = "", book: String = "") -> void:
	game.restart_run()
	game.set_process(false)
	game.player.controls_enabled = false
	game.player.set_physics_process(false)
	game.state = game.State.FIGHTING
	game.wave = 3
	game.equipment_drop_chance = 0
	game.active_talents.clear()
	game.equipment = {"scepter": scepter, "book": book}
	game.player.position = Vector2(375, 420)
	game.update_build()

func target_at(at: Vector2, hp: float = 10000):
	game.remaining_to_spawn = 1
	game.spawn_enemy("chaser")
	var enemy = game.enemies.get_child(game.enemies.get_child_count() - 1)
	enemy.position = at
	enemy.max_health = hp
	enemy.health = hp
	enemy.set_physics_process(false)
	return enemy

func settle() -> void:
	await physics_frame
	await process_frame

func attack() -> Array:
	game.player.cooldown = 0
	var before: int = game.projectiles.get_child_count()
	game.player.attack(Vector2.RIGHT)
	var shots: Array = game.projectiles.get_children().slice(before)
	for shot in shots:
		shot.set_physics_process(false)
	return shots

func hit(shots: Array, delta: float = 0.25) -> void:
	for shot in shots:
		if is_instance_valid(shot) and not shot.is_queued_for_deletion():
			shot._physics_process(delta)
	await process_frame

func run() -> void:
	game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	# Preserve this suite's historical global-tree fixture.
	game.progress.companions = game.COMPANIONS.fresh(false)
	game.companion_magic.reset()
	game.town_panel.refresh()
	await process_frame
	check(game.CATALOG.ITEMS.size() == 8 and game.equipment_drop_chance == 0.05 and game.champion_cooldown == 2, "CE4 defaults use eight items, five percent drops and two-second walk cooldown")
	reset("echo_scepter")
	game.mechanic_cards.assign([4, 5])
	game.fan_upgrades = 2
	game.update_build()
	var a = target_at(Vector2(460, 420))
	var b = target_at(Vector2(510, 420))
	await settle()
	for index in 3:
		attack()
	check(game.echo_attacks == 3 and game.pending_echo.is_empty(), "Fan counts once per regular attack for Echo")
	game.player.overcharge_ready = true
	var shots: Array = attack()
	check(shots.size() == 3 and shots[0].charged and not shots[1].charged and game.pending_echo.damage == game.player.damage * 0.6, "Fourth charged attack schedules only an uncharged 60-percent central echo")
	game.tick_item_effects(0.14)
	check(game.projectiles.get_child_count() == 12, "Echo waits its full delay")
	game.pause_run()
	game.tick_item_effects(1)
	check(not game.pending_echo.is_empty(), "Pause freezes pending Echo")
	game.resume_run()
	game.player.overcharge_ready = true
	game.tick_item_effects(0.02)
	var echo = game.projectiles.get_child(game.projectiles.get_child_count() - 1)
	echo.set_physics_process(false)
	check(echo.echoed and not echo.charged and echo.max_hits == 2 and is_equal_approx(echo.damage, 8.4) and game.player.overcharge_ready, "Echo pierces, does not consume Overcharge and does not copy its bonus")
	game.player.overcharge_ready = false
	game.player.overcharge_hits = 0
	echo._physics_process(0.25)
	check(game.player.overcharge_hits == 2 and a.health < 10000 and b.health < 10000, "Two real Echo pierce hits count for Overcharge")
	game.tick_item_effects(1)
	check(game.pending_echo.is_empty() and game.echo_attacks == 0, "Echo cannot schedule another Echo")
	for index in 4:
		attack()
	game.equipment.scepter = "ember_scepter"
	game.update_build()
	check(game.pending_echo.is_empty() and game.echo_attacks == 0, "Scepter swap cancels delayed Echo and resets its attack counter")
	reset("hunter_scepter")
	a = target_at(Vector2(460, 420))
	b = target_at(Vector2(460, 550))
	await settle()
	var hp: float = a.health
	for index in 7:
		shots = attack()
		await hit(shots)
		var expected: float = 14 * (1 + minf(index * 0.08, 0.4))
		check(is_equal_approx(hp - a.health, expected), "Hunter real hit %d uses capped target-specific stage" % (index + 1))
		hp = a.health
	game.player.position.y = 550
	await hit(attack())
	check(b.health == 9986, "New target receives no transferred Hunter bonus")
	game.player.position.y = 420
	game.tick_item_effects(3.01)
	await hit(attack())
	check(is_equal_approx(hp - a.health, 14), "Hunter expires after three gameplay seconds")
	game.player.overcharge_ready = true
	game.mechanic_cards.assign([5])
	game.update_build()
	hp = a.health
	await hit(attack())
	check(is_equal_approx(hp - a.health, 14 * 1.75 * 1.08), "Overcharge multiplies the already-built direct Hunter stage")
	game.equipment.scepter = ""
	game.update_build()
	check(game.hunter_marks.is_empty(), "Unequipping Hunter clears target streaks")
	reset("hunter_scepter")
	game.quick_upgrades = 2
	game.fan_upgrades = 2
	game.projectile_spread = 0
	game.mechanic_cards.assign([5])
	game.update_build()
	a = target_at(Vector2(460, 420))
	await settle()
	game.player.overcharge_ready = true
	await hit(attack())
	check(is_equal_approx(10000 - a.health, 14 * 1.75 + 14 * 1.08 + 14 * 1.16) and game.player.overcharge_hits == 3 and is_equal_approx(game.player.cast_interval, 0.2304), "Quick/Fan/Hunter use independent real hits, faster cadence and only main receives Overcharge")
	reset("", "storm_grimoire")
	game.mechanic_cards.assign([4, 5])
	game.fan_upgrades = 2
	game.projectile_spread = 0
	game.update_build()
	a = target_at(Vector2(460, 420))
	b = target_at(Vector2(510, 420))
	var c = target_at(Vector2(460, 500))
	await settle()
	shots = attack()
	await hit(shots)
	check(game.shots_hit == 6 and game.player.overcharge_ready and game.player.overcharge_hits == 0, "Three fan shots each pierce twice; six real hits, no double counting or charge banking")
	check(is_equal_approx(a.health, 9958) and is_equal_approx(b.health, 9951.7) and c.health == 10000, "One 6.3-damage lightning across all fan/pierce hits, without recursion")
	check(game.effects.filter(func(effect): return effect.get("lightning", false)).size() == 1, "Lightning has one visible connection per attack")
	reset("echo_scepter", "storm_grimoire")
	a = target_at(Vector2(460, 420))
	b = target_at(Vector2(460, 500))
	await settle()
	for index in 3:
		attack()
	shots = attack()
	await hit(shots)
	game.tick_item_effects(0.16)
	echo = game.projectiles.get_child(game.projectiles.get_child_count() - 1)
	echo.set_physics_process(false)
	var lightning_count: int = game.effects.filter(func(effect): return effect.get("lightning", false)).size()
	echo._physics_process(0.25)
	check(game.effects.filter(func(effect): return effect.get("lightning", false)).size() == lightning_count, "Echo shares its original attack's consumed Storm attempt")
	reset("", "storm_grimoire")
	game.fan_upgrades = 1
	game.update_build()
	a = target_at(Vector2(460, 420))
	b = target_at(Vector2(460, 500))
	await settle()
	shots = attack()
	shots[0].direction = Vector2.UP
	shots[1].direction = Vector2.RIGHT
	await hit(shots)
	check(game.shots_hit == 1 and is_equal_approx(b.health, 9993.7), "A missed main shot does not consume Storm; successful fan side shot triggers it")
	reset("", "storm_grimoire")
	game.mechanic_cards.assign([4])
	game.update_build()
	a = target_at(Vector2(460, 420))
	b = target_at(Vector2(620, 420))
	await settle()
	shots = attack()
	shots[0]._physics_process(0.12)
	check(not game.effects.any(func(effect): return effect.get("lightning", false)), "Storm cannot jump beyond 150 range")
	b.position = Vector2(580, 420)
	await settle()
	shots[0]._physics_process(0.25)
	check(not game.effects.any(func(effect): return effect.get("lightning", false)), "A first hit with no target still spends Storm's attempt before later pierce hits")
	reset("", "phoenix_grimoire")
	game.mechanic_cards.assign([4, 5])
	game.fan_upgrades = 4
	game.projectile_spread = 0
	game.update_build()
	game.player.health = 50
	a = target_at(Vector2(460, 420))
	b = target_at(Vector2(510, 420))
	await settle()
	await hit(attack())
	check(game.shots_hit == 10 and game.player.health == 53 and game.phoenix_hits == 0 and game.phoenix_left == 4, "Ten real fan/pierce hits heal three percent once")
	check(game.effects.any(func(effect): return effect.get("heal", false)), "Phoenix heal provides visible feedback")
	await hit(attack())
	check(game.player.health == 53 and game.phoenix_hits == 0, "Hits during cooldown cannot bank or spam healing")
	game.area_damage(a.position, 10, 200, a)
	check(game.phoenix_hits == 0, "Indirect splash does not count for Phoenix")
	game.equipment.book = "storm_grimoire"
	game.update_build()
	game.equipment.book = "phoenix_grimoire"
	game.update_build()
	check(game.phoenix_left == 4 and game.phoenix_hits == 0, "Gear swap cannot bypass Phoenix cooldown")
	game.pause_run()
	game.tick_item_effects(8)
	check(game.phoenix_left == 4, "Pause freezes healing cooldown")
	game.resume_run()
	game.tick_item_effects(4)
	game.player.health = 99
	await hit(attack())
	check(game.player.health == 100 and game.phoenix_left == 4, "Healing clamps at actual max HP")
	game.tick_item_effects(4)
	shots = attack()
	game.equipment.book = ""
	game.update_build()
	await hit(shots)
	check(game.phoenix_hits == 0, "In-flight shots cannot trigger an unequipped Phoenix")
	game.equipment.book = "phoenix_grimoire"
	game.update_build()
	await hit(shots)
	check(game.phoenix_hits == 0, "Reequipping cannot reactivate old projectile item contexts")
	reset("echo_scepter")
	for index in 4:
		attack()
	game.finish_run(false)
	check(game.pending_echo.is_empty(), "Death/result cancels pending Echo without a delayed post-run shot")
	game.restart_run()
	check(game.pending_echo.is_empty() and game.hunter_marks.is_empty() and game.phoenix_hits == 0 and game.phoenix_left == 0, "New run clears all item state")
	var dev = game.dev_console
	check(dev.save_profile(), "CE4 profile saves")
	var profile: Dictionary = SAFE_JSON.read_object(dev.profile_path)
	check(profile.version == 10 and profile.values.size() == 92, "Profile ten has 92 fields")
	profile.version = 8
	for field in dev.FIELDS:
		if dev.field_version(field) > 8:
			profile.values.erase(field[1] + "." + field[2])
	profile.values["arena.equipment_drop_chance"] = 0.1
	SAFE_JSON.write_object(dev.profile_path, profile)
	check(dev.load_profile() and game.equipment_drop_chance == 0.1 and game.echo_delay == 0.15 and game.champion_cooldown == 2, "Legacy v8 preserves old item chance and defaults CE4 fields")
	check(SAFE_JSON.read_object(dev.profile_path).version == 8, "Loading legacy profile leaves source untouched")
	for id in ["echo_scepter", "hunter_scepter", "storm_grimoire", "phoenix_grimoire"]:
		for group in [false, true]:
			check(game.start_item_test(id, group) and game.enemies.get_child_count() == (6 if group else 1), "Existing debug fixture supports %s group=%s" % [id, group])
		check(game.drop_item(id, Vector2(300, 300)), "Each new item can be forced through existing drop tooling")
		game.inventory_panel.open_inventory()
		game.inventory_panel.select_slot(game.CATALOG.ITEMS[id].slot)
		check(game.inventory_panel.title.text == game.CATALOG.ITEMS[id].name and not game.inventory_panel.details.text.is_empty(), "New equipped item has overview name and mechanical details")
		game.inventory_panel.close_inventory()
	var random := RandomNumberGenerator.new()
	random.seed = 42
	var found: Dictionary = {}
	for index in 10000:
		found[game.CATALOG.roll_item(random, 0.02, 0.25, 0.5, true)] = true
	check(found.size() == 8, "All old and new items remain naturally reachable through existing pools")
	game.start_ascent_test(5)
	game._process(2.1)
	game.spawn_enemy()
	var boss = game.boss
	boss.set_physics_process(false)
	check(dev.apply_setting("arena.champion_cooldown", 1) and boss.charge_interval == 1, "F1 cooldown reaches current Champion")
	dev.apply_setting("arena.champion_warning", 1.2)
	dev.apply_setting("arena.champion_duration", 0.3)
	dev.apply_setting("arena.champion_recovery", 0.6)
	game.remaining_to_spawn = 0
	boss._physics_process(0)
	check(boss.charge_left == 1.2 and boss.charge_duration == 0.3 and boss.charge_recovery == 0.6, "F1 warning duration and recovery apply at next telegraph")
	var warning_left: float = boss.charge_left
	dev.apply_setting("arena.champion_warning", 0.4)
	dev.apply_setting("arena.champion_duration", 0.9)
	check(boss.charge_left == warning_left and boss.charge_duration == 0.3, "F1 changes do not invalidate a warning already in progress")
	reset("echo_scepter", "storm_grimoire")
	game.enemy_limit = 100
	game.fan_upgrades = 8
	game.mechanic_cards.assign([4, 5])
	game.projectile_spread = 0
	game.update_build()
	for index in 64:
		target_at(Vector2(460 + (index % 8) * 30, 420 + (index / 8) * 5), 100000)
	await settle()
	for index in 40:
		attack()
		game.tick_item_effects(0.16)
	check(game.projectiles.get_child_count() == 256 and game.pending_echo.is_empty(), "Regular and Echo projectiles share the existing 256 cap")
	var started: int = Time.get_ticks_usec()
	for shot in game.projectiles.get_children():
		shot._physics_process(0.5)
	var cpu_ms: float = (Time.get_ticks_usec() - started) / 1000.0
	check(game.effects.size() <= 512 and is_finite(game.damage_dealt) and game.shots_hit <= 512, "Echo/Storm/fan/pierce stress stays bounded without recursive direct hits")
	print("CE4 STRESS: 256 projectiles / 64 targets, one scripted batch %.2f ms; not sustained FPS" % cpu_ms)
	dev.reset_defaults()
	var kills: int = 0
	for wave in range(1, 21):
		kills += game.boss_escorts + 1 if game.is_boss_wave(wave) else int(game.wave_settings(wave).budget)
		if wave in [5, 10, 15, 20]:
			print("CE4 LOOT MODEL: clear=%d eligible_kills=%d expected_items=%.2f zero_item_chance=%.6f" % [wave, kills, kills * 0.05, pow(0.95, kills)])
	game.queue_free()
	await process_frame
	print("ITEM SYNERGY TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
