extends SceneTree

const SAFE_JSON = preload("res://scripts/safe_json.gd")
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

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event)

func frames() -> void:
	for index in 3:
		await physics_frame
	await process_frame

func run() -> void:
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.restart_run()
	game.set_process(false)
	var panel = game.inventory_panel
	var dev = game.dev_console
	var base: float = game.player.base_damage
	check(game.bag_used() == 0 and game.equipment.book == "", "A run begins with eight empty bag fields and empty equipment")
	for id in game.CATALOG.ITEMS:
		check(game.CATALOG.icon(id) != null, "Each item has a generated inspection icon: " + id)
	check(not game.accept_item("unknown") and not game.equip_item(8) and not game.unequip_item("unknown"), "Invalid inventory actions are rejected")
	game.drop_item("cinder_codex", game.player.position)
	await frames()
	check(game.bag[0] == "cinder_codex" and not game.codex_active and game.player.damage == base, "A physical pickup stays inactive in the bag")
	key(KEY_I)
	await process_frame
	check(panel.is_open and paused and not game.player.controls_enabled, "I opens equipment and pauses world controls")
	check(panel.title.text == "Cinder Codex" and panel.comparison.text.contains("OFF → ON"), "Inspection explains the Codex before equipping")
	panel.equip_button.pressed.emit()
	check(game.codex_active and game.bag_used() == 0, "The Equip button activates the selected book")
	game.accept_item("focus_grimoire")
	panel.select_bag(0)
	check(panel.comparison.text.contains("ON → OFF") and panel.details.text.contains("40%"), "A replacement previews lost splash and the new damage bonus")
	panel.equip_button.pressed.emit()
	check(not game.codex_active and is_equal_approx(game.player.damage, base * 1.4) and game.bag[0] == "cinder_codex", "Equipping another book swaps safely and removes splash")
	game.accept_item("ember_scepter")
	game.equip_item(1)
	check(is_equal_approx(game.player.damage, base * 1.7), "Scepter and book damage bonuses add without repeated multiplication")
	game.power_upgrades = 1
	game.quick_upgrades = 1
	game.update_build()
	check(is_equal_approx(game.player.damage, base * 1.35 * 1.7), "Equipment composes with the existing wave cards")
	game.accept_item("swift_scepter")
	game.equip_item(1)
	check(is_equal_approx(game.player.cast_interval, game.player.base_cast_interval * 0.8 * 0.8), "Swift Scepter multiplies the interval after the card reduction")
	check(is_equal_approx(game.player.damage, base * 1.35 * 1.4) and game.bag[1] == "ember_scepter", "A scepter swap removes its previous damage bonus")
	dev.apply_setting("arena.scepter_cast_reduction", 0.5)
	dev.apply_setting("arena.focus_damage_bonus", 0.8)
	check(is_equal_approx(game.player.damage, base * 1.35 * 1.8) and is_equal_approx(game.player.cast_interval, game.player.base_cast_interval * 0.8 * 0.5), "Item console values update the actual equipped build")
	key(KEY_F1)
	await process_frame
	check(dev.is_open and panel.is_open and paused, "F1 can open over equipment")
	key(KEY_ESCAPE)
	await process_frame
	check(not dev.is_open and panel.is_open and paused and root.gui_get_focus_owner() == panel.bag_buttons[panel.selected_bag], "Closing F1 restores equipment focus and pause")
	key(KEY_ESCAPE)
	await process_frame
	check(not panel.is_open and not paused and game.state != game.State.PAUSED and game.player.controls_enabled, "Escape closes equipment without triggering a second arena pause")
	game.pause_run()
	game.buttons.get_child(1).pressed.emit()
	check(panel.is_open and paused, "The pause menu Equipment button opens the same inventory")
	panel.close_inventory()
	check(paused and game.state == game.State.PAUSED, "Closing equipment restores the original pause menu")
	game.resume_run()
	game.wave = 2
	game.state = game.State.FIGHTING
	game.remaining_to_spawn = 0
	for enemy in game.enemies.get_children():
		game.enemies.remove_child(enemy)
		enemy.queue_free()
	game.complete_wave()
	check(game.state == game.State.UPGRADE and paused, "The wave-two card event remains intact")
	var choices: int = game.buttons.get_child_count()
	panel.open_inventory()
	panel.close_inventory()
	check(game.state == game.State.UPGRADE and paused and game.buttons.get_child_count() == choices, "Inspecting equipment preserves a pending card choice")
	game.offered_cards.assign([2])
	game.choose_upgrade(2)
	while game.bag_used() < 8:
		game.accept_item("focus_grimoire")
	check(not game.accept_item("ember_scepter"), "A full bag rejects extra pickups")
	check(not game.unequip_item("book") and game.equipment.book == "focus_grimoire", "Unequipping into a full bag preserves the equipped item")
	check(game.equip_item(0) and game.codex_active and game.bag_used() == 8 and game.bag[0] == "focus_grimoire", "A full bag still allows lossless equipment swaps")
	game.drop_item("swift_scepter", game.player.position)
	await frames()
	check(game.loot.get_child_count() == 1 and not game.loot.get_child(0).taken, "A rejected physical pickup remains on the ground")
	game.ground_loot_limit = 1
	var original: String = game.bag[0]
	check(not game.drop_owned_item(0, "") and game.bag[0] == original, "A full ground cap cannot destroy a bag item")
	check(not game.drop_owned_item(99, "book") and game.codex_active, "An invalid bag index cannot drop an equipped item")
	game.ground_loot_limit = 16
	check(game.drop_owned_item(0, "") and game.bag_used() == 7, "Putting an item down frees exactly one bag field")
	await frames()
	check(game.bag_used() == 8 and game.loot.get_child_count() == 1 and game.bag[0] == "swift_scepter", "The previously blocked pickup can fill the newly free bag field")
	check(game.drop_owned_item(-1, "book") and not game.codex_active, "Putting equipped gear down immediately removes its effect")
	game.drop_chance = 0
	game.equipment_drop_chance = 1
	game.state = game.State.FIGHTING
	game.enemy_slain(Vector2(200, 300))
	check(game.loot.get_child_count() == 3 and game.loot.get_child(2).item_id != "cinder_codex", "A guaranteed other-gear roll creates a physical regular item")
	check(dev.save_profile(), "The expanded profile can be saved")
	var modern: Dictionary = SAFE_JSON.read_object(dev.profile_path)
	check(modern.version == 10 and modern.values.size() == 92, "New profiles explicitly use version ten with all settings")
	var legacy: Dictionary = modern.duplicate(true)
	legacy.version = 1
	for field in dev.FIELDS:
		if dev.field_version(field) > 1:
			legacy.values.erase(field[1] + "." + field[2])
	legacy.values["player.move_speed"] = 345
	SAFE_JSON.write_object(dev.profile_path, legacy)
	var legacy_loaded: bool = dev.load_profile()
	check(legacy_loaded and game.player.move_speed == 345 and is_equal_approx(game.focus_damage_bonus, 0.4), "Old 28-value profiles retain tuning and default only the five new fields: " + dev.status.text)
	check(SAFE_JSON.read_object(dev.profile_path).version == 1, "Loading a legacy profile does not rewrite the source file")
	legacy.values["unknown.item"] = 1
	SAFE_JSON.write_object(dev.profile_path, legacy)
	check(not dev.load_profile() and game.player.move_speed == 345, "Unknown legacy settings are rejected atomically")
	modern.version = 11
	SAFE_JSON.write_object(dev.profile_path, modern)
	check(not dev.load_profile(), "Future profile versions are rejected")
	panel.open_inventory()
	game.completed_waves = 2
	game.finish_run(false)
	check(not panel.is_open and paused and game.reward_saved and game.progress.echoes == 30, "Run end closes equipment and pays only the unchanged cleared-wave reward")
	check(not game.accept_item("cinder_codex") and not game.equip_item(0), "The finished run cannot mutate owned items")
	panel.open_inventory()
	check(not panel.is_open, "Equipment cannot reopen over the result screen")
	var saved: Dictionary = SAFE_JSON.read_object(game.progress.path)
	check(saved.size() == 4 and saved.version == 2 and not saved.has("equipment"), "The new progress format saves talents without persisting equipment")
	game.restart_run()
	check(game.bag_used() == 0 and game.equipment.book == "" and game.equipment.scepter == "" and game.loot.get_child_count() == 0 and not game.codex_spawned, "Restart clears bag, gear, ground loot and natural Codex eligibility")
	check(game.progress.echoes == 30 and game.player.damage == base and not paused, "Restart keeps Echoes and restores the base build")
	game.queue_free()
	await process_frame
	print("INVENTORY TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
