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

func frames(count: int = 3) -> void:
	for index in count:
		await physics_frame
	await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event)

func click(control: Control) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = control.get_global_rect().get_center()
		root.push_input(event, true)

func run() -> void:
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var town = game.town_panel
	var dev = game.dev_console
	var store = game.progress
	check(game.state == game.State.TOWN and paused and town.screen.visible, "The application starts in town")
	check(town.node_buttons.size() == 45 and dev.controls.size() == 92, "All 45 talents and 92 balance controls are present")
	key(KEY_I)
	await process_frame
	check(not game.inventory_panel.is_open and game.bag_used() == 0, "Town cannot open run equipment")
	check(not game.drop_item("cinder_codex", game.player.position), "Town cannot receive run loot")
	check(not game.buy_talent("power_1") and store.echoes == 0, "Insufficient Echoes leaves progress intact")
	game.finish_run(false)
	check(game.state == game.State.TOWN and not FileAccess.file_exists(store.path), "Town cannot be finished for extra rewards")
	town.start_button.pressed.emit()
	game.completed_waves = 2
	game.wave = 3
	game.best_wave = 3
	game.accept_item("cinder_codex")
	game.finish_run(false)
	check(store.echoes == 30 and game.reward_saved, "Ending a run awards the unchanged completed-wave payout")
	game.buttons.get_child(0).pressed.emit()
	check(game.state == game.State.TOWN and paused and game.bag_used() == 0 and game.wave == 0, "The actual result button returns to town and clears run possessions")
	game.finish_run(false)
	game.settle_reward()
	check(store.echoes == 30, "Returning to town cannot pay the previous run twice")
	town.skill_button.pressed.emit()
	await process_frame
	check(town.showing_tree and town.buy_button.disabled == false, "The tree opens with the affordable root selected")
	click(town.buy_button)
	await process_frame
	check(store.talents.has("power_1") and store.echoes == 0 and town.buy_button.disabled, "A real viewport mouse click buys a talent and prevents repeated purchase")
	check(not game.buy_talent("power_1") and not game.buy_talent("power_5") and not game.buy_talent("unknown"), "Duplicates, disconnected talents and unknown IDs are rejected")
	check(game.active_talents.is_empty(), "Town purchases do not alter the previous run snapshot")
	key(KEY_F1)
	await process_frame
	dev.apply_setting("arena.tree_cost_1", 100)
	key(KEY_ESCAPE)
	await process_frame
	check(not dev.is_open and paused and town.showing_tree and root.gui_get_focus_owner() == town.node_buttons[town.selected], "Closing F1 restores tree focus and keeps town paused")
	town.reset_button.pressed.emit()
	check(store.echoes == 30 and store.talents.is_empty(), "A reset refunds the actual 30 paid even after raising the current price")
	check(not game.refund_talents() and store.echoes == 30, "Repeated reset cannot mint Echoes")
	dev.reset_defaults()
	check(store.award(2000, 3), "An isolated high-currency fixture can be saved")
	check(game.buy_talent("power_1") and game.buy_talent("power_2") and game.buy_talent("vitality_3"), "An owned neighbor opens the real cross-branch connection")
	check(not store.talents.has("vitality_2"), "The cross-link does not require buying an unrelated earlier node")
	for id in game.TALENTS.NODES:
		if game.TALENTS.NODES[id].tier > 5:
			continue
		if not store.talents.has(id):
			check(game.buy_talent(id), "Each talent is purchasable through a valid path: " + id)
	check(store.talents.size() == 15 and store.invested() == 1080, "All paths coexist with the exact cumulative default cost")
	var loaded = PROGRESS.new()
	loaded.path = store.path
	check(loaded.load_progress() and loaded.talents.size() == 15 and loaded.invested() == store.invested() and loaded.echoes == store.echoes, "A fresh store reloads wallet and all talent purchase prices")
	key(KEY_ESCAPE)
	await process_frame
	check(not town.showing_tree and paused, "Escape from the tree returns to town without starting a run")
	town.start_button.pressed.emit()
	check(game.state == game.State.BETWEEN_WAVES and not paused and not town.screen.visible, "Start Run leaves town and resumes gameplay")
	check(game.active_talents.size() == 15 and is_equal_approx(game.player.damage, 14 * 1.16), "The new run applies purchased Power exactly once")
	check(is_equal_approx(game.player.health_limit, 120) and game.player.health == 120, "Vitality increases effective max HP and starts full without changing the base stat")
	check(game.player.max_health == 100 and is_equal_approx(game.player.cast_interval, 0.36 * 0.89), "Base max HP stays tunable and Flow applies its own interval multiplier")
	check(not game.buy_talent("unknown") and not game.refund_talents(), "Talents can only be transacted in town")
	game.power_upgrades = 1
	game.quick_upgrades = 1
	game.accept_item("ember_scepter")
	game.equip_item(0)
	game.accept_item("cinder_codex")
	game.equip_item(0)
	check(is_equal_approx(game.player.damage, 14 * 1.16 * 1.35 * 1.3) and game.codex_active, "Tree, wave cards and gear compose through the shared build")
	game.begin_wave()
	game.enemy_health = 500
	game.drop_chance = 0
	game.equipment_drop_chance = 0
	game.spawn_enemy()
	game.spawn_enemy()
	var primary = game.enemies.get_child(0)
	var secondary = game.enemies.get_child(1)
	primary.position = Vector2(850, 420)
	secondary.position = Vector2(850, 475)
	primary.set_physics_process(false)
	secondary.set_physics_process(false)
	game.player.position = Vector2(640, 420)
	game.player.controls_enabled = false
	game.player.cooldown = 0
	game.player.attack(Vector2.RIGHT)
	await frames(30)
	check(is_equal_approx(primary.health, 500 - game.player.damage * 1.35), "A real projectile applies First Spark only to its full-health direct target")
	check(is_equal_approx(secondary.health, 500 - game.player.damage * game.explosion_damage_ratio), "First Spark does not multiply the existing Codex splash")
	game.player.cooldown = 0
	game.player.attack(Vector2.RIGHT)
	await frames(30)
	check(is_equal_approx(primary.health, 500 - game.player.damage * 2.35), "The next direct hit receives no full-health bonus")
	game.player.protection = 0
	game.player.take_damage(10)
	check(game.player.haste_remaining == 3 and is_equal_approx(game.player.effective_interval(), game.player.cast_interval * 0.8), "Actual health loss activates Second Wind")
	game.player.haste_remaining = 1
	game.player.take_damage(10)
	check(game.player.haste_remaining == 1, "A protected hit cannot trigger or refresh Second Wind")
	game.player.protection = 0
	game.player.take_damage(10)
	check(game.player.haste_remaining == 3, "Another real hit refreshes duration without stacking speed")
	game.player.cooldown = 0
	game.player.attack(Vector2.RIGHT)
	check(is_equal_approx(game.player.cooldown, game.player.cast_interval * 0.8), "The real cast cooldown uses the temporary haste")
	game.inventory_panel.open_inventory()
	var paused_haste: float = game.player.haste_remaining
	await frames(4)
	check(game.player.haste_remaining == paused_haste, "Equipment pause does not consume Second Wind duration")
	game.inventory_panel.close_inventory()
	game.player.haste_remaining = 0.01
	await frames()
	check(game.player.haste_remaining == 0 and game.player.effective_interval() == game.player.cast_interval, "Temporary haste expires back to the unchanged normal interval")
	game.player.health = 50
	game.remaining_to_spawn = 0
	for enemy in game.enemies.get_children():
		game.enemies.remove_child(enemy)
		enemy.queue_free()
	game.complete_wave()
	check(is_equal_approx(game.player.health, 57.2), "Renewal heals the configured max-health ratio on a real wave completion")
	game.state = game.State.FIGHTING
	game.complete_wave()
	check(is_equal_approx(game.player.health, 57.2), "Completing the same wave again cannot duplicate healing")
	game.begin_wave()
	game.player.health = 119
	game.remaining_to_spawn = 0
	game.complete_wave()
	check(game.player.health == 120 and game.state == game.State.UPGRADE and paused, "Renewal clamps to max health and preserves the wave-two card event")
	game.offered_cards.assign([0])
	game.choose_upgrade(0)
	game.finish_run(false)
	game.return_to_town()
	check(game.refund_talents(), "All talents can be refunded after the run")
	game.restart_run()
	check(game.active_talents.is_empty() and game.player.health_limit == 100 and game.player.damage == 14 and game.player.cast_interval == 0.36, "After refund the next run removes all meta and run bonuses exactly")
	game.finish_run(false)
	game.return_to_town()
	var profile: Dictionary = {}
	for field in dev.FIELDS:
		if dev.field_version(field) <= 2:
			profile[field[1] + "." + field[2]] = dev.defaults[field[1] + "." + field[2]]
	SAFE_JSON.write_object(dev.profile_path, {"version": 2, "values": profile})
	dev.apply_setting("arena.tree_opening_bonus", 1.0)
	check(dev.load_profile() and profile.size() == 33 and game.tree_opening_bonus == 0.35, "Old v2 profiles load all 33 original values and default the new tree fields")
	var legacy_path: String = "user://legacy_tree_%d.json" % OS.get_process_id()
	SAFE_JSON.write_object(legacy_path, {"version": 1, "echoes": 77, "best_wave": 4})
	loaded.path = legacy_path
	check(loaded.load_progress() and loaded.echoes == 77 and loaded.talents.is_empty(), "Existing version-one wallets load with no lost Echoes or invented talents")
	check(SAFE_JSON.read_object(legacy_path).version == 1, "Loading a legacy wallet does not rewrite it")
	check(loaded.buy("power_1", 30) and SAFE_JSON.read_object(legacy_path).version == 3 and loaded.echoes == 47, "The next successful purchase migrates the wallet atomically")
	var fixture := {"version": 2, "echoes": 12, "best_wave": 2, "talents": {"power_5": 130}}
	SAFE_JSON.write_object(legacy_path, fixture)
	check(not loaded.load_progress() and not loaded.buy("power_1", 1) and not loaded.refund_all(), "Disconnected corrupt talent data blocks purchases and refunds")
	check(SAFE_JSON.read_object(legacy_path) == JSON.parse_string(JSON.stringify(fixture)), "Invalid source progress remains intact")
	for bad in [{"unknown": 1}, {"power_1": -1}, {"power_1": 1.5}, {"power_1": "30"}, {"power_1": 1000000000}]:
		fixture.talents = bad
		SAFE_JSON.write_object(legacy_path, fixture)
		check(not loaded.load_progress(), "Unknown, fractional, negative, nonnumeric or overflowing talent ledgers are rejected")
	var failing = PROGRESS.new()
	failing.path = "user://missing_tree_parent_%d/progress.json" % OS.get_process_id()
	failing.echoes = 100
	check(not failing.buy("power_1", 30) and failing.echoes == 100 and failing.talents.is_empty(), "A failed purchase write changes neither balance nor ownership")
	failing.talents = {"power_1": 30}
	check(not failing.refund_all() and failing.echoes == 100 and failing.talents.has("power_1"), "A failed refund write keeps the original wallet and talents")
	game.progress = failing
	game.restart_run()
	game.completed_waves = 2
	game.finish_run(false)
	check(not game.return_to_town() and game.state == game.State.FINISHED and not game.reward_saved, "An unsaved payout blocks leaving the result screen")
	failing.path = "user://tree_recovered_%d.json" % OS.get_process_id()
	game.settle_reward()
	check(game.reward_saved and game.return_to_town(), "Retrying a failed payout restores the full return-to-town loop")
	game.queue_free()
	await process_frame
	print("TOWN / TREE TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
