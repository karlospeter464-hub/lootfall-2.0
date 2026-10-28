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

func reset(owned: Dictionary = {}) -> void:
	game.restart_run()
	game.set_process(false)
	game.player.set_physics_process(false)
	game.player.controls_enabled = false
	game.active_talents = owned.duplicate()
	game.state = game.State.FIGHTING
	game.wave = 1
	game.equipment_drop_chance = 0
	game.player.position = Vector2(375, 420)
	game.update_build()

func target_at(at: Vector2, hp: float = 1000):
	game.remaining_to_spawn = 1
	game.spawn_enemy("chaser")
	var enemy = game.enemies.get_child(game.enemies.get_child_count() - 1)
	enemy.position = at
	enemy.max_health = hp
	enemy.health = hp
	enemy.set_physics_process(false)
	return enemy

func attack() -> Array:
	game.player.cooldown = 0
	var before: int = game.projectiles.get_child_count()
	game.player.attack(Vector2.RIGHT)
	var shots: Array = game.projectiles.get_children().slice(before)
	for shot in shots:
		shot.set_physics_process(false)
	return shots

func settle() -> void:
	await physics_frame
	await process_frame

func run() -> void:
	game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	# Preserve this suite's historical global-tree fixture.
	game.progress.companions = game.COMPANIONS.fresh(false)
	game.companion_magic.reset()
	game.town_panel.refresh()
	await process_frame
	for cleared in 3:
		game.completed_waves = cleared
		check(game.predicted_reward() == [0, 10, 30][cleared], "Early payout is unchanged for %d cleared waves" % cleared)
	reset()
	game.enemy_slain(Vector2.ZERO)
	game.player.take_damage(20)
	for index in 4:
		game.player.record_direct_hit()
	check(game.player.kindling_remaining == 0 and game.player.health == 80 and game.player.momentum_remaining == 0, "No root effect without ownership")
	reset({"power_1": 30})
	check(game.player.damage == 14, "Kindling replaces the old flat Power root bonus")
	game.enemy_slain(Vector2.ZERO)
	check(game.player.kindling_remaining == 5, "A kill arms Kindling even when no loot drops")
	game.player._physics_process(2)
	game.enemy_slain(Vector2.ZERO)
	check(game.player.kindling_remaining == 5, "Another kill refreshes without stacking")
	game.fan_upgrades = 2
	game.update_build()
	var shots: Array = attack()
	check(shots.size() == 3 and shots[0].kindling_bonus == 0.25 and shots[1].kindling_bonus == 0 and shots[2].kindling_bonus == 0, "Only the aimed regular fireball receives Kindling")
	check(game.player.kindling_remaining == 0 and attack()[0].kindling_bonus == 0, "The next attack cannot reuse the consumed charge")
	game.enemy_slain(Vector2.ZERO)
	game.player._physics_process(5.1)
	check(attack()[0].kindling_bonus == 0, "Unspent Kindling expires after five gameplay seconds")
	game.enemy_slain(Vector2.ZERO)
	game.spawn_projectile(Vector2(400, 300), Vector2.RIGHT, 10, {}, false, true)
	var echo = game.projectiles.get_child(game.projectiles.get_child_count() - 1)
	echo.set_physics_process(false)
	check(echo.kindling_bonus == 0 and game.player.kindling_remaining == 5, "Automatic Echo neither copies nor consumes Kindling")
	for shot in game.projectiles.get_children():
		game.projectiles.remove_child(shot)
		shot.queue_free()
	for index in 256:
		game.spawn_projectile(Vector2(100, 200), Vector2.RIGHT, 10, {}, false)
		game.projectiles.get_child(index).set_physics_process(false)
	attack()
	check(game.player.kindling_remaining == 5, "Projectile safety cap does not consume a shot that never spawns")
	reset({"power_1": 30, "power_5": 130})
	game.equipment = {"scepter": "ember_scepter", "book": "cinder_codex"}
	game.mechanic_cards.assign([5])
	game.update_build()
	game.enemy_slain(Vector2.ZERO)
	game.player.overcharge_ready = true
	var primary = target_at(Vector2(460, 420))
	var splash = target_at(Vector2(460, 470))
	await settle()
	shots = attack()
	shots[0]._physics_process(0.2)
	await process_frame
	var charged: float = game.player.damage * (1.0 + game.overcharge_bonus)
	check(is_equal_approx(primary.health, 1000 - charged * 1.35 * 1.25), "Real hit multiplies Kindling, First Spark, Overcharge and Ember equipment")
	check(is_equal_approx(splash.health, 1000 - charged * game.explosion_damage_ratio), "Kindling and First Spark do not multiply Codex splash")
	reset({"power_1": 30})
	game.mechanic_cards.assign([3])
	game.update_build()
	primary = target_at(Vector2(460, 420), 15)
	splash = target_at(Vector2(460, 470))
	game.enemy_slain(Vector2.ZERO)
	await settle()
	shots = attack()
	shots[0]._physics_process(0.2)
	var killed: bool = primary.dead
	await process_frame
	check(killed and is_equal_approx(splash.health, 1000 - 14 * game.burst_damage_ratio), "Kindling enables a direct kill and normal-damage Ember Burst")
	check(game.player.kindling_remaining == 5, "A kill from the empowered shot arms a new charge")
	reset({"vitality_1": 30, "vitality_2": 45, "flow_5": 130})
	game.player.health = game.player.health_limit
	game.player.health_changed.emit(game.player.health, game.player.health_limit)
	game.player.take_damage(20)
	check(is_equal_approx(game.player.health, 105 - 20 + 8.4), "Emberguard restores eight percent of effective maximum HP")
	check(game.emberguard_used and game.player.haste_remaining == 3, "Emberguard coexists with Second Wind on the same real hit")
	check(game.damage_taken == 20 and game.effects.any(func(effect): return effect.get("heal", false)), "Healing feedback does not hide actual damage telemetry")
	game.player.protection = 0
	game.player.take_damage(10)
	check(is_equal_approx(game.player.health, 83.4), "A second hit in the same wave grants no further heal")
	game.begin_wave()
	game.player.protection = 1
	game.player.take_damage(10)
	check(not game.emberguard_used, "Protected damage cannot consume Emberguard")
	game.player.protection = 0
	game.player.invulnerable = true
	game.player.take_damage(10)
	check(not game.emberguard_used, "Debug invulnerability cannot consume Emberguard")
	game.player.invulnerable = false
	game.dev_console.heal_player()
	check(not game.emberguard_used, "Debug healing cannot activate Emberguard")
	game.player.take_damage(1)
	check(game.player.health == 105 and game.emberguard_used, "A new wave refreshes Emberguard and healing caps at full HP")
	game.begin_wave()
	game.player.protection = 0
	game.player.take_damage(1000)
	check(game.player.health == 0 and not game.emberguard_used and game.state == game.State.FINISHED, "Lethal damage is never revived by Emberguard")
	reset({"vitality_1": 30, "vitality_5": 130})
	game.equipment.book = "phoenix_grimoire"
	game.update_build()
	game.player.health = 50
	game.player.take_damage(10)
	check(game.player.health == 48, "Defensive combination starts with the first-hit heal")
	primary = target_at(Vector2(460, 420))
	game.phoenix_hits = 9
	await settle()
	shots = attack()
	shots[0]._physics_process(0.2)
	await process_frame
	check(game.player.health == 51 and game.phoenix_left > 0, "Real Phoenix hit heals alongside the spent Emberguard")
	game.enemies.remove_child(primary)
	primary.queue_free()
	game.remaining_to_spawn = 0
	game.complete_wave()
	check(game.player.health == 57, "Renewal still heals separately on wave completion")
	reset({"flow_1": 30})
	check(game.player.cast_interval == 0.36 and game.player.move_speed == 245, "Momentum replaces root interval stats without changing movement base")
	game.fan_upgrades = 1
	game.mechanic_cards.assign([4])
	game.equipment.book = "storm_grimoire"
	game.update_build()
	primary = target_at(Vector2(460, 420))
	var pierce = target_at(Vector2(510, 420))
	var side = target_at(Vector2(480, 400))
	await settle()
	shots = attack()
	shots[0]._physics_process(0.2)
	await process_frame
	check(game.player.momentum_hits == 2 and game.player.momentum_remaining == 0, "Two distinct real pierce hits count; Storm jump does not")
	check(side.health < 1000, "The indirect Storm control target actually took damage")
	shots[1]._physics_process(0.2)
	await process_frame
	check(game.player.momentum_hits >= 3, "A real fan side projectile also contributes direct hits")
	while game.player.momentum_remaining == 0:
		game.player.record_direct_hit()
	check(game.player.momentum_hits == 0 and game.player.momentum_remaining == 3 and is_equal_approx(game.player.effective_move_speed(), 245 * 1.12), "Fourth direct hit grants the configured temporary movement speed")
	game.player._physics_process(1)
	for index in 4:
		game.player.record_direct_hit()
	check(game.player.momentum_remaining == 3 and is_equal_approx(game.player.effective_move_speed(), 245 * 1.12), "Subsequent four hits refresh duration without multiplying speed")
	game.area_damage(side.position, 1, 200, null, true)
	check(game.player.momentum_hits == 0, "Indirect explosion damage never advances Momentum")
	game.player.kindling_remaining = 4
	game.player.set_physics_process(true)
	game.inventory_panel.open_inventory()
	await settle()
	check(game.player.momentum_remaining == 3 and game.player.kindling_remaining == 4, "Inventory pause freezes both temporary root timers")
	game.inventory_panel.close_inventory()
	game.player.set_physics_process(false)
	game.player._physics_process(3.1)
	check(game.player.momentum_remaining == 0 and game.player.effective_move_speed() == 245, "Momentum expiry restores exact base speed")
	game.active_talents["flow_5"] = 130
	game.update_build()
	game.player.take_damage(1)
	for index in 4:
		game.player.record_direct_hit()
	check(game.player.haste_remaining == 3 and game.player.momentum_remaining == 3, "Second Wind attack speed and Momentum movement speed coexist")
	game.finish_run(false)
	game.return_to_town()
	game.progress.award(100, 2)
	check(game.buy_talent("flow_1"), "Root ownership uses the existing safe ledger")
	game.restart_run()
	check(game.active_talents.has("flow_1") and game.player.momentum_remaining == 0 and game.player.momentum_hits == 0, "New snapshot activates ownership with no leftover temporary progress")
	game.finish_run(false)
	game.return_to_town()
	check(game.refund_talents(), "Root refund remains available")
	game.restart_run()
	check(game.active_talents.is_empty() and game.player.momentum_bonus == 0 and game.player.effective_move_speed() == 245 and game.player.kindling_remaining == 0 and not game.emberguard_used, "Run without talents removes all root state after reset")
	var dev = game.dev_console
	check(dev.save_profile(), "CE5 balance profile saves")
	var profile: Dictionary = SAFE_JSON.read_object(dev.profile_path)
	check(profile.version == 10 and profile.values.size() == 92, "Five root tuning fields are versioned with the existing controls")
	for field in dev.FIELDS:
		if dev.field_version(field) == 10:
			profile.values.erase(field[1] + "." + field[2])
	profile.version = 9
	profile.values["player.move_speed"] = 300
	SAFE_JSON.write_object(dev.profile_path, profile)
	dev.apply_setting("arena.tree_kindling_bonus", 1)
	check(dev.load_profile() and game.tree_kindling_bonus == 0.25 and game.tree_emberguard_heal == 0.08 and game.tree_momentum_bonus == 0.12 and game.player.move_speed == 300, "Legacy v9 retains old settings and defaults only new root fields")
	check(SAFE_JSON.read_object(dev.profile_path).version == 9, "Loading old balance profile does not rewrite it")
	game.finish_run(false)
	game.return_to_town()
	var town = game.town_panel
	town.show_tree()
	town.node_buttons["power_1"].grab_focus()
	var event := InputEventKey.new()
	event.keycode = KEY_DOWN
	event.pressed = true
	root.push_input(event)
	await process_frame
	check(town.selected == "power_2" and root.gui_get_focus_owner() == town.node_buttons["power_2"], "Arrow keys navigate the actual tree and select details")
	for id in game.TALENTS.NODES:
		town.select_node(id)
		await process_frame
		check(town.detail.get_global_rect().end.y <= town.condition.get_global_rect().position.y and town.condition.get_global_rect().end.y <= town.buy_button.get_global_rect().position.y, "Talent details fit without overlapping actions: " + id)
	check(town.skill_button.text.contains("affordable"), "Town identifies affordable talent purchases")
	game.queue_free()
	await process_frame
	print("EARLY PROGRESSION TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
