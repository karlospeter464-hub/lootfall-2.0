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

func clear_field() -> void:
	for container in [game.enemies, game.projectiles]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	game.effects.clear()
	game.remaining_to_spawn = 0
	game.wave = 3
	game.state = game.State.FIGHTING
	paused = false

func enemy_at(at: Vector2, hp: float = 1000, role: String = "chaser"):
	game.remaining_to_spawn = 1
	game.spawn_enemy(role)
	var enemy = game.enemies.get_child(game.enemies.get_child_count() - 1)
	enemy.position = at
	enemy.max_health = hp
	enemy.health = hp
	enemy.set_physics_process(false)
	return enemy

func fire(damage: float = 10):
	game._cast(Vector2(400, 420), Vector2.RIGHT, damage)
	return game.projectiles.get_child(game.projectiles.get_child_count() - 1)

func run() -> void:
	game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.restart_run()
	game.set_process(false)
	game.player.controls_enabled = false
	game.equipment_drop_chance = 0
	game.active_talents.clear()
	var seen: Dictionary = {}
	for seed_value in 40:
		game.rng.seed = seed_value
		game.roll_upgrade_cards()
		var offer: Array = game.offered_cards.duplicate()
		check(offer.size() == 3 and offer[0] != offer[1] and offer[0] != offer[2] and offer[1] != offer[2], "Three distinct offers at seed %d" % seed_value)
		game.rng.seed = seed_value
		game.roll_upgrade_cards()
		check(game.offered_cards == offer, "Seed reproduces offer %d" % seed_value)
		for card in offer:
			seen[card] = true
	check(seen.size() == 6, "All six cards occur across seeds")
	game.state = game.State.UPGRADE
	game.refresh_upgrade_cards()
	var held: Array = game.offered_cards.duplicate()
	game.update_build()
	check(game.offered_cards == held, "Build refresh does not reroll pending offers")
	var unoffered: int = 0
	while held.has(unoffered):
		unoffered += 1
	game.choose_upgrade(unoffered)
	check(game.upgrades_chosen == 0, "Unoffered cards cannot be selected")
	for card in [3, 4, 5]:
		game.state = game.State.UPGRADE
		game.offered_cards.assign([card])
		game.refresh_upgrade_cards()
		game.buttons.get_child(0).pressed.emit()
		check(game.mechanic_cards.has(card), "Actual mechanic card button grants %d" % card)
		game.roll_upgrade_cards()
		check(not game.offered_cards.has(card), "Unique card %d is not reoffered" % card)
	game.quick_upgrades = 100
	game.fan_upgrades = 100
	game.update_build()
	game.roll_upgrade_cards()
	check(game.offered_cards == [0], "Only Power remains when other cards are exhausted")
	game.upgrade_damage_bonus = 0
	game.roll_upgrade_cards()
	check(game.offered_cards.is_empty(), "No invalid offers forced when all cards unavailable")
	clear_field()
	game.wave = 2
	game.complete_wave()
	check(game.state == game.State.BETWEEN_WAVES and not paused, "Exhausted pool cannot deadlock a card wave")
	game.upgrade_damage_bonus = 0.35
	game.restart_run()
	game.set_process(false)
	game.player.controls_enabled = false
	check(game.mechanic_cards.is_empty() and game.offered_cards.is_empty() and not game.player.overcharge_ready and game.player.overcharge_hits == 0, "Restart clears new card state")
	clear_field()
	game.mechanic_cards.assign([3])
	game.power_upgrades = 2
	game.equipment.scepter = "ember_scepter"
	game.update_build()
	var powered_primary = enemy_at(Vector2(460, 420), 5)
	var powered_neighbor = enemy_at(Vector2(460, 460), 100)
	await frames()
	game.player.cooldown = 0
	game.player.position = Vector2(375, 420)
	game.player.attack(Vector2.RIGHT)
	await frames(12)
	check((not is_instance_valid(powered_primary) or powered_primary.dead) and is_equal_approx(powered_neighbor.health, 100 - game.player.damage * 0.7), "Power and Ember Scepter scale the real direct-kill Burst")
	game.power_upgrades = 0
	game.equipment.scepter = ""
	clear_field()
	game.mechanic_cards.assign([3, 4, 5])
	game.update_build()
	var first = enemy_at(Vector2(460, 420), 5)
	var victim = enemy_at(Vector2(490, 450), 3)
	var survivor = enemy_at(Vector2(580, 460), 100)
	await frames()
	fire()
	await frames(12)
	check(first.dead if is_instance_valid(first) else true, "Direct hit kills primary")
	check(not is_instance_valid(victim) or victim.dead, "Burst can kill a nearby enemy")
	check(is_equal_approx(survivor.health, 100), "Indirect Burst kill cannot recursively explode into survivor")
	check(game.player.overcharge_hits == 1, "Indirect kills do not charge Overcharge")
	check(game.effects.filter(func(effect): return effect.has("explosion")).size() == 1, "Only one direct-kill Burst visual")
	clear_field()
	var primary = enemy_at(Vector2(460, 420), 5)
	var neighbor = enemy_at(Vector2(470, 450), 100)
	primary.take_projectile_hit(10)
	game.projectile_impact(primary.position, 10, primary)
	game.projectile_impact(primary.position, 10, primary)
	check(is_equal_approx(neighbor.health, 93), "Duplicate kill event does not repeat Burst")
	clear_field()
	game.equipment.book = "cinder_codex"
	primary = enemy_at(Vector2(460, 420), 5)
	neighbor = enemy_at(Vector2(460, 460), 100)
	await frames()
	fire(20)
	await frames(10)
	check(is_equal_approx(neighbor.health, 74), "Burst 70% and Codex 60% combine once on neighbor")
	clear_field()
	game.equipment.book = ""
	game.player.overcharge_hits = 0
	game.player.overcharge_ready = false
	var a = enemy_at(Vector2(460, 420))
	var b = enemy_at(Vector2(510, 420))
	var c = enemy_at(Vector2(560, 420))
	await frames()
	var shot = fire()
	await frames(22)
	check(a.health == 990 and b.health == 990 and c.health == 1000, "Piercing hits two distinct enemies and stops before third")
	check(game.player.overcharge_hits == 2, "Both actual piercing hits charge Overcharge")
	check(not is_instance_valid(shot), "Projectile freed after second hit")
	clear_field()
	a = enemy_at(Vector2(460, 420))
	await frames()
	shot = fire()
	shot.speed = 1500
	shot._physics_process(0.05)
	shot._physics_process(0.05)
	check(a.health == 990 and shot.hit_bodies.size() == 1 and shot.direction == Vector2.RIGHT and shot.speed == 1500, "Piercing never re-hits its first target and preserves velocity")
	clear_field()
	a = enemy_at(Vector2(460, 420))
	b = enemy_at(Vector2(510, 420))
	await frames()
	game.player.overcharge_hits = 0
	game.player.overcharge_ready = false
	shot = fire()
	shot._physics_process(0.2)
	check(a.health == 990 and b.health == 990 and shot.hit_bodies.size() == 2, "Swept pierce handles both targets in one physics step")
	clear_field()
	game.equipment.book = "cinder_codex"
	a = enemy_at(Vector2(460, 420))
	b = enemy_at(Vector2(510, 420))
	await frames()
	fire()
	await frames(20)
	check(a.health == 984 and b.health == 984, "Piercing Codex splashes each impact once, excluding its primary")
	check(game.player.overcharge_ready and game.player.overcharge_hits == 0, "Four actual direct hits ready one charge")
	clear_field()
	game.fan_upgrades = 2
	game.update_build()
	game.player.cooldown = 0
	game.player.attack(Vector2.RIGHT)
	var shots: Array = game.projectiles.get_children()
	check(shots.size() == 3 and shots[0].charged and not shots[1].charged and not shots[2].charged, "Only main fan shot consumes charge")
	check(is_equal_approx(shots[0].damage, game.player.damage * 1.75) and shots[1].damage == game.player.damage, "Overcharge bonus applies only to main projectile")
	check(not game.player.overcharge_ready, "Charged attack consumes ready state")
	clear_field()
	game.player.overcharge_hits = 0
	game.player.overcharge_ready = true
	for index in 256:
		fire()
	game.player.overcharge_ready = true
	game._cast(Vector2.ZERO, Vector2.RIGHT, 10)
	check(game.player.overcharge_ready and game.projectiles.get_child_count() == 256, "Projectile cap does not consume a charge without firing")
	clear_field()
	game.player.overcharge_ready = false
	game.player.overcharge_hits = 0
	var seer = enemy_at(Vector2(460, 420), 1000, "seer")
	seer.charging = true
	seer.charge_left = 1
	var guardian = enemy_at(Vector2(520, 420), 1000, "guardian")
	await frames()
	fire(10)
	await frames(20)
	check(seer.concentration_hits == 1 and is_equal_approx(guardian.health, 996.8), "Piercing preserves one Seer hit and Guardian direct plus Codex armor floors")
	clear_field()
	game.equipment.book = ""
	a = enemy_at(Vector2(460, 420))
	await frames()
	fire(0)
	await frames(10)
	check(a.health == 1000 and game.player.overcharge_hits == 2, "Zero damage does not count as successful hit")
	game.player.overcharge_ready = true
	game.pause_run()
	var charge: int = game.player.overcharge_hits
	await frames()
	check(game.player.overcharge_ready and game.player.overcharge_hits == charge, "Pause preserves charge")
	game.resume_run()
	game.inventory_panel.open_inventory()
	await frames()
	check(game.player.overcharge_ready and game.player.overcharge_hits == charge, "Inventory preserves charge")
	game.inventory_panel.close_inventory()
	game.dev_console.open_console()
	await frames()
	check(game.player.overcharge_ready and game.player.overcharge_hits == charge, "Console preserves charge")
	game.dev_console.close_console()
	var dev = game.dev_console
	check(dev.save_profile(), "CE3 profile saves")
	var profile: Dictionary = SAFE_JSON.read_object(dev.profile_path)
	check(profile.version == 9 and profile.values.size() == 87, "Version 9 contains 87 numeric settings")
	profile.version = 7
	for field in dev.FIELDS:
		if dev.field_version(field) > 7:
			profile.values.erase(field[1] + "." + field[2])
	SAFE_JSON.write_object(dev.profile_path, profile)
	game.burst_radius = 120
	check(dev.load_profile() and game.burst_radius == 105, "Legacy v7 loads with CE3 startup defaults")
	game.finish_run(false)
	var count: int = game.projectiles.get_child_count()
	game.player.attack(Vector2.RIGHT)
	check(game.projectiles.get_child_count() == count, "Death/result cannot spawn a charged shot")
	game.restart_run()
	check(not game.player.overcharge_ready and game.player.overcharge_hits == 0, "Death then restart clears charge")
	for preset in 3:
		check(game.start_card_test(preset) and game.mechanic_cards == [[3], [4], [5]][preset], "Reproducible isolated preset %d" % preset)
	clear_field()
	game.mechanic_cards.assign([3, 4, 5])
	game.equipment.book = "cinder_codex"
	game.update_build()
	game.enemy_limit = 100
	for index in 64:
		enemy_at(Vector2(460 + (index % 8) * 30, 420 + (index / 8) * 5), 100)
	await frames()
	for index in 256:
		fire(100)
	var started: int = Time.get_ticks_usec()
	for projectile in game.projectiles.get_children():
		projectile._physics_process(0.5)
	var cpu_ms: float = (Time.get_ticks_usec() - started) / 1000.0
	check(game.enemies.get_children().all(func(enemy): return enemy.dead), "256 projectiles with all mechanics clear the 64-enemy stress fixture")
	check(game.effects.size() <= 512 and is_finite(game.damage_dealt), "Combined effects remain bounded without non-finite damage")
	for index in 600:
		game.area_damage(Vector2.ZERO, 1, 65, null)
	check(game.effects.size() == 512, "Visual cap holds under simultaneous explosions")
	print("CE3 STRESS: 256 shots / 64 enemies, one scripted physics batch %.2f ms; not sustained FPS" % cpu_ms)
	game.queue_free()
	await process_frame
	print("CARD SYNERGY TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
