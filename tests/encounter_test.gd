extends SceneTree

const SAFE_JSON = preload("res://scripts/safe_json.gd")
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

func frames(count: int) -> void:
	for index in count:
		await physics_frame
	await process_frame

func run() -> void:
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	# Preserve this suite's historical global-tree fixture.
	game.progress.companions = game.COMPANIONS.fresh(false)
	game.companion_magic.reset()
	game.town_panel.refresh()
	await process_frame
	game.restart_run()
	game.set_process(false)
	game.player.controls_enabled = false
	game.drop_chance = 0
	game.equipment_drop_chance = 0
	game.ranged_windup = 0.4
	game.begin_wave()
	for index in 8:
		game.spawn_enemy()
	check(game.enemies.get_children().all(func(enemy): return enemy.get_script() != game.RANGED_ENEMY), "Wave one remains melee-only")
	game.restart_run()
	game.wave = 1
	game.begin_wave()
	for index in 12:
		game.spawn_enemy()
	var seers: Array = game.enemies.get_children().filter(func(enemy): return enemy.get_script() == game.RANGED_ENEMY)
	check(seers.size() == 2 and game.enemies.get_child_count() == 12, "Mixed wave respects the total and ranged caps")
	for enemy in game.enemies.get_children():
		enemy.set_physics_process(false)
	var seer = seers[0]
	seer.position = Vector2(350, 420)
	game.player.position = Vector2(640, 420)
	seer.cooldown = 0
	seer.set_physics_process(true)
	await frames(2)
	check(seer.charging and seer.charge_left > 0, "Seer announces an attack before dealing damage")
	var marked: Vector2 = seer.marked_position
	var hp: float = game.player.health
	game.player.position += Vector2(0, 100)
	await frames(30)
	check(seer.marked_position == marked and game.player.health == hp and not seer.charging, "Moving out of the locked warning avoids the attack")
	seer.cooldown = 0
	await frames(2)
	game.inventory_panel.open_inventory()
	var remaining: float = seer.charge_left
	await frames(10)
	check(seer.charge_left == remaining and game.player.health == hp, "Equipment pause freezes the warning timer")
	game.inventory_panel.close_inventory()
	seer.frozen = true
	await frames(10)
	check(seer.charge_left == remaining, "F1 enemy freeze also freezes pending ranged attacks")
	seer.frozen = false
	await frames(30)
	check(is_equal_approx(game.player.health, hp - seer.contact_damage) and not seer.charging, "Staying in the marked circle takes a single wave-scaled hit")
	var after: float = game.player.health
	await frames(20)
	check(game.player.health == after, "The attack does not repeatedly damage during recovery")
	game.player.protection = 0
	seer.cooldown = 0
	await frames(2)
	check(seer.charging, "The next attack has a fresh warning")
	seer.take_damage(10000)
	await frames(30)
	check(game.player.health == after, "Killing a seer cancels its pending attack")
	game.accept_item("ember_scepter")
	game.equip_item(0)
	while game.bag_used() < 8:
		game.accept_item("focus_grimoire")
	game.drop_item("swift_scepter", game.player.position)
	await frames(3)
	check(game.loot.get_child_count() == 1, "A full bag leaves the desired physical drop available")
	game.inventory_panel.open_inventory()
	game.inventory_panel.select_bag(0)
	var echoes: int = game.progress.echoes
	game.inventory_panel.destroy_button.pressed.emit()
	check(game.bag_used() == 7 and game.loot.get_child_count() == 1, "Destroy frees a bag field without creating another ground item")
	check(game.progress.echoes == echoes and game.equipment.scepter == "ember_scepter", "Destroy awards no currency and preserves equipped gear")
	game.inventory_panel.select_slot("scepter")
	check(game.inventory_panel.destroy_button.disabled and not game.destroy_bag_item(-1) and not game.destroy_bag_item(8), "Equipped slots and invalid indices cannot be destroyed")
	game.inventory_panel.close_inventory()
	await frames(3)
	check(game.bag_used() == 8 and game.bag.has("swift_scepter") and game.loot.get_child_count() == 0, "The waiting desired drop can now be collected")
	game.finish_run(false)
	check(not game.destroy_bag_item(0), "Finished runs cannot destroy bag contents")
	game.return_to_town()
	check(not game.destroy_bag_item(0), "Town cannot destroy run inventory")
	var values: Dictionary = {}
	var dev = game.dev_console
	for field in dev.FIELDS:
		if dev.field_version(field) <= 3:
			values[field[1] + "." + field[2]] = dev.defaults[field[1] + "." + field[2]]
	SAFE_JSON.write_object(dev.profile_path, {"version": 3, "values": values})
	dev.apply_setting("arena.ranged_windup", 2.5)
	check(dev.load_profile() and values.size() == 48 and is_equal_approx(game.ranged_windup, 1.4), "Legacy v3 profiles preserve old values and default new enemy fields")
	check(SAFE_JSON.read_object(dev.profile_path).version == 3, "Legacy loading does not rewrite the old profile")
	game.queue_free()
	await process_frame
	print("ENCOUNTER / DISPOSAL TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
