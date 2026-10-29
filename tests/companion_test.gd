extends SceneTree

const C = preload("res://scripts/companion_catalog.gd")
const P = preload("res://scripts/progress_store.gd")
const J = preload("res://scripts/safe_json.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--test-mode"):
		quit(1)
		return
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func frames(n: int = 2) -> void:
	for i in n: await physics_frame
	await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event)

func capture(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/companion_slice")
	root.get_texture().get_image().save_png("res://.godot/companion_slice/" + name + ".png")

func run() -> void:
	check(C.FRIENDS.size() == 6 and C.SPECIALS.size() == 2, "Six catalog schools; only the two commissioned schools implemented")
	for friend in C.SPECIALS:
		var tree: Dictionary = C.nodes(friend)
		check(tree.size() == 15, "Each friend has exactly fifteen nodes")
		var owned := {}
		var stats: int = 0
		for id in tree:
			check(C.accessible(id, owned), "Catalog order reaches every branch and special talent")
			owned[id] = tree[id].cost
			if tree[id].stat != "": stats += 1
		check(stats == 9, "Nine stats and six special nodes")
		check(is_equal_approx(C.bonuses(owned).damage, 0.24) and is_equal_approx(C.bonuses(owned).health, 0.3) and is_equal_approx(C.bonuses(owned).interval, 0.09), "Single-tree additive stats stay bounded")
	var path: String = "user://companion_migration_%d.json" % OS.get_process_id()
	for version in range(1, 6):
		var original := {"version": version, "echoes": 123, "best_wave": 12, "talents": {"power_1": 17, "power_2": 42}, "world": {"points": [600, 20, 0], "best": [12, 0, 0], "overflow": 0}, "last_settlement": "done", "restoration_run": {"id": "run", "region": 1, "credited": 4}, "echo_run": {"id": "unfinished", "earned": 30, "paid": 10}}
		var version_path: String = path + str(version)
		check(J.write_object(version_path, original) == OK, "Legacy fixture written")
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(version_path)
		var store = P.new()
		store.path = version_path
		check(store.load_progress() and not store.companions.enabled, "Versions 1–5 retain explicit legacy mode")
		check(FileAccess.get_file_as_bytes(version_path) == bytes, "Loading is read-only")
		var before_world: Dictionary = store.world.duplicate(true)
		var before_echo: Dictionary = store.echo_run.duplicate()
		check(store.migrate_companions(), "Player conversion succeeds")
		check(store.echoes == (123 if version == 1 else 182) and store.talents.is_empty(), "Exact historically paid prices returned, no repricing")
		check(store.world == before_world and store.echo_run == before_echo, "World, records and pending Echo ledger unchanged")
		check(FileAccess.get_file_as_bytes(version_path + ".pre_companions.json") == bytes, "Migration backup byte-identical")
		check(not store.migrate_companions(), "Conversion cannot refund twice")
		var reload = P.new()
		reload.path = version_path
		check(reload.load_progress() and reload.companions.enabled and reload.echoes == store.echoes, "Converted v6 reloads")
		check(reload.recover_echoes() and reload.echoes == store.echoes + (20 if version == 5 else 0), "Pending pickup recovery preserved")
	var failed = P.new()
	failed.companions = C.fresh(false)
	failed.talents = {"power_1": 17}
	failed.echoes = 80
	failed.path = "user://absent_companion_parent_%d/progress.json" % OS.get_process_id()
	check(not failed.migrate_companions() and not failed.companions.enabled and failed.echoes == 80 and failed.talents.power_1 == 17, "Failed conversion preserves wallet, mode and purchases")
	var full = P.new()
	full.path = path + "_full"
	full.companions = C.fresh(false)
	var paid: int = 0
	for id in full.TREE.NODES:
		full.talents[id] = 7 + paid % 31
		paid += int(full.talents[id])
	check(full._save(100, 12, full.talents), "Full 45-node legacy ledger saved at historic prices")
	var full_world: Dictionary = full.world.duplicate(true)
	check(full.migrate_companions() and full.echoes == 100 + paid and full.world == full_world, "All 45 legacy prices refunded exactly without changing regions")
	var recovered = P.new()
	recovered.path = path + "_backup_only"
	J.write_object(recovered.path + ".bak", {"version": 1, "echoes": 61, "best_wave": 3})
	var recovered_bytes: PackedByteArray = FileAccess.get_file_as_bytes(recovered.path + ".bak")
	check(recovered.load_progress() and recovered.migrate_companions(), "Interrupted-rename backup can be converted")
	check(FileAccess.get_file_as_bytes(recovered.path + ".pre_companions.json") == recovered_bytes, "Backup-only migration also creates byte-identical companion archive")
	var invalid = C.fresh()
	invalid.rescued = ["gravity"]
	invalid.purchases = {"gravity.collapse": 100}
	check(not C.valid(invalid), "Disconnected saved purchases cannot bypass prerequisites")
	invalid = C.fresh()
	invalid.rescued = ["gravity"]
	invalid.purchases = {"gravity.damage0": 1.5}
	check(not C.valid(invalid), "Fractional historical prices rejected")
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.set_process(false)
	await capture("town_start")
	var magic = game.companion_magic
	var store = game.progress
	check(store.companions.enabled and store.talents.is_empty(), "Fresh game starts with the companion architecture")
	check(not store.buy_companion("gravity.damage0") and not store.buy("power_1", 1), "Locked friends and parallel global purchases rejected")
	game.town_panel.show_tree()
	await frames()
	check(game.town_panel.friends.visible and game.town_panel.friends.nodes.size() == 15, "Actual Friends screen displays personal tree")
	game.town_panel.friends.close()
	game.restart_run()
	game.player.controls_enabled = false
	game.begin_wave()
	check(magic.rescue == "gravity", "First wave includes the first friend encounter")
	game.remaining_to_spawn = 0
	game.complete_wave()
	check(paused and game.buttons.get_child_count() == 1 and game.completed_waves == 1, "Wave completion offers a single permanent rescue milestone")
	await capture("rescue")
	key(KEY_ESCAPE)
	check(game.state == game.State.RESCUE and paused, "Escape cannot dismiss a pending rescue and lose its reward continuation")
	var rescue_path: String = store.path
	store.path = failed.path
	game.buttons.get_child(0).pressed.emit()
	check(game.state == game.State.RESCUE and store.companions.rescued.is_empty() and paused, "Failed rescue save keeps the milestone pending for retry")
	store.path = rescue_path
	game.buttons.get_child(0).pressed.emit()
	check("gravity" in store.companions.rescued and magic.slots[0] == "gravity" and not paused, "Real rescue button saves and equips Q immediately")
	game.begin_wave()
	game.remaining_to_spawn = 0
	game.complete_wave()
	game.buttons.get_child(0).pressed.emit()
	check("prism" in store.companions.rescued and magic.slots == ["gravity", "prism"], "Second friend is reached in wave two")
	check(game.state == game.State.UPGRADE and game.buttons.get_child_count() == 3, "Rescue continues to the unchanged wave-card reward")
	game.choose_upgrade(game.offered_cards[0])
	check(game.upgrades_chosen == 1 and not paused, "Normal card remains selectable")
	check(store.debug_set_echoes(20000), "Isolated test currency")
	check(not store.buy_companion("gravity.collapse"), "Disconnected special cannot be purchased")
	game.finish_run(false)
	check(game.return_to_town(), "Earned rescue returns to the hub")
	game.town_panel.show_tree()
	var panel = game.town_panel.friends
	panel.selected = "gravity.damage0"
	panel.refresh()
	panel.buy_button.pressed.emit()
	check(store.companions.purchases.has("gravity.damage0"), "Actual personal-tree Buy button purchases the selected talent")
	panel.friend_buttons.prism.pressed.emit()
	check(panel.friend == "prism" and panel.nodes.size() == 15, "Actual friend tab switches to the second tree")
	panel.close()
	for friend in C.SPECIALS:
		for id in C.nodes(friend):
			if not store.companions.purchases.has(id): check(store.buy_companion(id), "All fifteen permanent nodes purchasable per friend")
	check(store.companions.purchases.size() == 30 and C.valid(store.companions), "Both complete trees remain valid")
	check(not store.equip_companions(["gravity", "gravity"]) and not store.equip_companions(["gravity", "storm"]) and not store.equip_companions(["gravity", "prism", "storm"]), "Duplicates, unrescued and third slot rejected")
	check(store.equip_companions(["gravity", ""]), "One equipped friend supported")
	game.restart_run()
	check(magic.talents.size() == 15 and store.companions.purchases.size() == 30, "Unequipped investments persist without granting bonuses")
	check(is_equal_approx(game.player.health_limit, game.player.max_health * 1.3), "Only equipped health nodes apply")
	store.equip_companions(["gravity", "prism"])
	check(magic.slots == ["gravity", ""], "Town loadout changes cannot mutate an existing run snapshot")
	game.restart_run()
	check(magic.talents.size() == 30 and is_equal_approx(game.player.health_limit, game.player.max_health * 1.6), "Two equipped trees combine additively")
	game.player.controls_enabled = false
	game.begin_wave()
	game.remaining_to_spawn = 6
	game.wave_budget = 6
	game.spawn_enemy()
	game.spawn_enemy()
	game.spawn_enemy()
	game.remaining_to_spawn = 0
	var targets: Array = game.enemies.get_children()
	game.player.position = Vector2(250, 430)
	for i in targets.size():
		targets[i].position = Vector2(560 + i * 75, 390 + i * 30)
		targets[i].health = 500
		targets[i].max_health = 500
	magic.talents = {} # Baseline ability works without any talents.
	check(magic.cast(0, Vector2(650, 430)), "Baseline Black Hole casts")
	check(not magic.cast(0, Vector2(650, 430)) and magic.cooldowns[1] == 0, "Independent cooldowns prevent repeat Q")
	var before: float = targets[0].position.distance_to(magic.field.at)
	await frames(30)
	check(targets[0].position.distance_to(magic.field.at) < before, "Live physics actually pulls enemies into the field")
	check(magic.cast(1, Vector2(650, 430)), "Baseline Light Beam casts alongside Black Hole")
	var hp: float = targets[0].health
	await frames(45)
	check(targets[0].health < hp and targets[1].health < 500 and targets[2].health < 500, "Beam pierces the gathered group")
	magic.talents = C.snapshot(store.companions)
	magic.cooldowns.fill(0.0)
	magic.field.clear()
	magic.beam.clear()
	magic.rays.clear()
	for i in targets.size(): targets[i].position = Vector2(570 + i * 70, 430)
	magic.cast(0, Vector2(650, 430))
	check(magic.field.radius == 200 and magic.field.left == 5, "Radius and duration talents affect actual field")
	var boosted: float = magic.fireball_damage(targets[0], 20)
	check(is_equal_approx(boosted, 25) and targets[0].companion_slow == 1.5 and targets[0].get_meta("prism_until") > magic.clock, "Fireballs slow, mark and gain damage inside Black Hole")
	check(magic.cast(1, Vector2(900, 430)) and is_equal_approx(magic.beam.left, 0.3) and magic.beam.width == 54, "Prisma width and charge talents apply")
	await capture("charge")
	magic.fire_beam()
	check(magic.rays.size() == 3, "One split produces exactly two nonrecursive extra rays")
	await capture("combo")
	var dead_target = targets[0]
	dead_target.dead = true
	magic.fireball_hit(dead_target)
	check(magic.ash_charge > 0, "Fireball kill reduces future windup")
	dead_target.dead = false
	magic.field.kills = 10
	hp = targets[1].health
	magic.collapse()
	check(magic.field.is_empty() and targets[1].health < hp, "Bounded harvest amplifies collapse damage")
	magic.cooldowns.fill(0.0)
	magic.beam.clear()
	magic.rays.clear()
	game.pause_run()
	check(not magic.cast(0, Vector2(650, 430)), "Pause prevents casting")
	game.resume_run()
	key(KEY_Q)
	check(not magic.field.is_empty(), "Actual Q input casts slot one")
	var frozen_left: float = magic.field.left
	game.pause_run()
	await frames(10)
	check(is_equal_approx(magic.field.left, frozen_left), "Pause freezes duration and cooldown clocks")
	game.resume_run()
	key(KEY_E)
	check(not magic.beam.is_empty(), "Actual E input casts slot two")
	game.finish_run(false)
	await frames()
	check(magic.field.is_empty() and magic.beam.is_empty(), "Death clears active spells without posthumous damage")
	check(game.return_to_town(), "Return to town remains functional")
	await capture("town_home")
	game.town_panel.show_tree()
	await frames()
	await capture("tree")
	var reloaded = P.new()
	reloaded.path = store.path
	var did_load: bool = reloaded.load_progress()
	if not did_load: print("RELOAD DEBUG ", J.read_object(store.path), " catalog valid: ", C.valid(J.read_object(store.path).get("companions")))
	check(did_load and reloaded.companions == JSON.parse_string(JSON.stringify(store.companions)), "Rescues, loadout, all investments survive reload")
	var good_state: Dictionary = store.companions.duplicate(true)
	var good_echoes: int = store.echoes
	var good_path: String = store.path
	store.path = failed.path
	check(not store.equip_companions(["", ""]) and store.companions == good_state and store.echoes == good_echoes, "Failed loadout save is atomic")
	store.path = good_path
	var malformed := good_state.duplicate(true)
	malformed.purchases["gravity.fake"] = 1
	check(not C.valid(malformed), "Unknown purchase IDs rejected")
	malformed = good_state.duplicate(true)
	malformed.slots = ["gravity", "gravity"]
	check(not C.valid(malformed), "Malformed duplicate loadout rejected on read")
	var reset_world: Dictionary = store.world.duplicate(true)
	store.path = failed.path
	check(not game.dev_console.reset_character() and store.companions == good_state and store.echoes == good_echoes, "Failed reset preserves purchases and wallet")
	store.path = good_path
	check(game.dev_console.reset_character(), "Developer reset succeeds in town")
	check(store.echoes == 0 and store.talents.is_empty() and store.companions == C.fresh(), "Reset clears wallet, talents, rescues and slots without refund")
	check(store.world == reset_world and game.companion_magic.talents.is_empty(), "World preserved and active talent snapshot cleared")
	check(store.recover_echoes() and store.echoes == 0, "Old pending Echoes cannot return after reset")
	check(reloaded.load_progress() and reloaded.echoes == 0 and reloaded.companions.rescued.is_empty(), "Reset persists after reload")
	game.dev_console.close_console()
	game.restart_run()
	game.owed_echo_total = 200
	game.completed_waves = 2
	game.dev_console.open_console()
	var reset_button = game.dev_console.find_children("*", "Button", true, false).filter(func(b): return b.text.begins_with("Reset talents"))[0]
	reset_button.pressed.emit()
	check(game.state == game.State.TOWN and store.echoes == 0 and game.owed_echo_total == 0, "Actual reset button ends an active run without restoring old credits")
	check(store.recover_echoes() and store.echoes == 0, "Active-run reset cannot recover discarded rewards")
	game.queue_free()
	await process_frame
	print("COMPANION TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
