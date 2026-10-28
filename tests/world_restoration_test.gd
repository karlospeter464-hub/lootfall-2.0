extends SceneTree

const WORLD = preload("res://scripts/world_regions.gd")
const STORE = preload("res://scripts/progress_store.gd")
const JSON_STORE = preload("res://scripts/safe_json.gd")
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

func run() -> void:
	check(WORLD.reward(0, 0, 0, 0) == 0 and WORLD.reward(0, 1000, 0, 0) == 0, "Instant exits and passive waiting award no Restoration")
	check(WORLD.reward(0, 30, 3, 3) == 2 and WORLD.reward(0, 29, 3, 3) == 0, "Serious incomplete first waves have a small combat-and-time-gated reward")
	check(WORLD.reward(10, 0, 0, 0) == 220 and WORLD.reward(20, 0, 0, 0) == 840, "Later waves earn substantially more Restoration")
	check(WORLD.reward(12, 0, 0, 0) * 2 >= 600, "Two wave-12 clears can restore the first region; hypothesis, not human balance acceptance")
	var source: Dictionary = WORLD.fresh(12)
	var changed: Dictionary = WORLD.apply(source, 735, 0, 15)
	check(source.points == [0, 0, 0] and changed.points == [600, 135, 0], "Absolute overflow is exact and pure; source is not mutated")
	check(changed.best == [15, 0, 0] and WORLD.frontier(changed) == 1 and WORLD.restored(changed) == 1, "Performance, unlock and restored count remain separate")
	changed = WORLD.apply(source, 20200, 0, 100)
	check(changed.points == [600, 1400, 2800] and changed.overflow == 15400 and WORLD.valid(changed), "Exceptional rewards can heal several regions; final excess is retained")
	for bad in [{}, {"points": [600, -1, 0], "best": [0, 0, 0], "overflow": 0}, {"points": [0, 1, 0], "best": [0, 0, 0], "overflow": 0}, {"points": [0, 0, 0], "best": [0, 0, 0], "overflow": 1}]:
		check(not WORLD.valid(bad), "Malformed or non-contiguous world states are rejected")
	var store = STORE.new()
	store.path = "user://world_unit_%d.json" % OS.get_process_id()
	var legacy := {"version": 2, "echoes": 123, "best_wave": 12, "talents": {"power_1": 27}}
	JSON_STORE.write_object(store.path, legacy)
	var original: PackedByteArray = FileAccess.get_file_as_bytes(store.path)
	check(store.load_progress() and store.world.best == [12, 0, 0] and store.talents.power_1 == 27, "Legacy record and exact paid talent price survive read-only loading")
	check(FileAccess.get_file_as_bytes(store.path) == original, "Loading does not rewrite a legacy save")
	check(store.settle_expedition(100, 10, 0, 220, "first"), "Echoes, Restoration and region record settle atomically")
	check(FileAccess.get_file_as_bytes(store.path + ".pre_world.json") == original, "First migration preserves a byte-identical pre-world backup")
	check(store.echoes == 223 and store.world.points == [220, 0, 0], "First settlement updates both rewards once")
	check(store.settle_expedition(100, 10, 0, 220, "first") and store.echoes == 223, "Retrying a successful settlement is idempotent")
	var reload = STORE.new()
	reload.path = store.path
	check(reload.load_progress() and reload.settle_expedition(100, 10, 0, 220, "first") and reload.echoes == 223, "A process restart does not repeat a saved settlement")
	check(reload.settle_expedition(400, 12, 0, 400, "second") and reload.world.points == [600, 20, 0], "Several runs accumulate and unlock Region 2 with overflow")
	check(reload.world.best == [12, 0, 0], "Unlocking a region does not copy the old region's record")
	check(not reload.settle_expedition(1, 1, 0, 4, "wrong-region"), "A stale region cannot receive a second frontier payout")
	var old_world: Dictionary = reload.world.duplicate(true)
	var old_echoes: int = reload.echoes
	var good_path: String = reload.path
	reload.path = "user://missing_world_folder/progress.json"
	check(not reload.settle_expedition(10, 2, 1, 12, "write-fails") and reload.echoes == old_echoes and reload.world == old_world, "Write failure preserves world and wallet together")
	reload.path = good_path
	check(reload.refund_all() and reload.echoes == old_echoes + 27 and reload.world == old_world, "Exact old-price refunds leave world progress untouched")
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	# Preserve this suite's historical global-tree fixture.
	game.progress.companions = game.COMPANIONS.fresh(false)
	game.companion_magic.reset()
	game.town_panel.refresh()
	await process_frame
	game.set_process(false)
	game.progress = reload
	game.restart_run()
	check(game.run_region == 1 and game.wave == 0 and game.bag_used() == 0 and game.mechanic_cards.is_empty(), "Next expedition uses the new frontier with a fresh run build")
	game.begin_wave()
	check(game.wave == 1 and game.best_wave == 1 and game.wave_settings(1).health == 28, "Region 2 starts at local wave 1 without cancelling talent growth by region scaling")
	game.completed_waves = 2
	game.wave = 3
	game.finish_run(false)
	check(game.reward_saved and game.progress.world.points == [600, 32, 0] and game.progress.world.best == [12, 3, 0], "Real scene finish commits the current region's two-wave reward and reached record")
	var saved_echoes: int = game.progress.echoes
	game.settle_reward()
	check(game.progress.echoes == saved_echoes, "Scene settlement cannot be repeated")
	game.return_to_town()
	check(game.progress.award(20000, 3), "Isolated tree test funds are saved")
	for id in game.TALENTS.NODES:
		check(game.buy_talent(id), "Expanded tree has a connected purchasable path: " + id)
	check(game.progress.talents.size() == 45 and game.progress.invested() == 11790, "All 45 talents coexist; exact default full-tree cost is 11790 Echoes")
	var tree_reload = STORE.new()
	tree_reload.path = "user://full_tree_%d.json" % OS.get_process_id()
	JSON_STORE.write_object(tree_reload.path, JSON_STORE.read_object(game.progress.path))
	check(tree_reload.load_progress() and tree_reload.talents.size() == 45, "All expanded purchases and prices reload through the production validator")
	var tree_wallet: int = tree_reload.echoes
	var tree_world: Dictionary = tree_reload.world.duplicate(true)
	check(tree_reload.refund_all() and tree_reload.echoes == tree_wallet + 11790 and tree_reload.world == tree_world, "Expanded free reset refunds every paid price without resetting regions")
	check(game.progress.settle_expedition(0, 4, 1, 1375, "third-frontier") and game.progress.world.points == [600, 1400, 7], "The second region also completes with exact overflow into the third")
	game.restart_run()
	check(game.run_region == 2 and game.wave == 0, "Region 3 is a playable frontier with its own fresh local wave counter")
	check(is_equal_approx(game.player.damage, 14 * 1.88) and is_equal_approx(game.player.health_limit, 210) and is_equal_approx(game.player.cast_interval, 0.36 * 0.65), "Permanent growth materially boosts damage, survival and cast speed without changing base stats")
	game.begin_wave()
	game.mechanic_cards.assign([3, 4, 5])
	game.update_build()
	check(is_equal_approx(game.player.damage, 14 * 2.06), "Convergence rewards discovered mechanic cards, not a preselected starter build")
	check(is_equal_approx(game.burst_damage(20), 20 * 0.7 * 1.35), "Wildfire scales area damage without creating extra events")
	var codex: Dictionary = game.build_for("", "cinder_codex")
	check(is_equal_approx(codex.splash_damage, codex.damage * 0.6 * 1.35), "Inventory comparison reports the same Wildfire Codex damage as combat")
	game.player.kindling_remaining = 5
	game.spawn_projectile(Vector2(400, 400), Vector2.RIGHT, 10, {}, true)
	var shot = game.projectiles.get_child(-1)
	shot.set_physics_process(false)
	check(is_equal_approx(shot.kindling_bonus, 0.5), "Cinder Memory improves one existing Kindling projectile")
	game.spawn_projectile(Vector2(400, 450), Vector2.RIGHT, 10, {}, false, true)
	shot = game.projectiles.get_child(-1)
	shot.set_physics_process(false)
	check(is_equal_approx(shot.damage, 13), "Resonant Echo increases the existing echo's direct damage")
	for index in 4:
		game.player.record_direct_hit()
	check(game.player.momentum_remaining == 5 and is_equal_approx(game.player.effective_interval(), game.player.cast_interval * 0.88), "Afterglow and Unbound combine with real four-hit Momentum")
	game.remaining_to_spawn = 2
	game.spawn_enemy("chaser")
	game.spawn_enemy("chaser")
	var primary = game.enemies.get_child(0)
	var secondary = game.enemies.get_child(1)
	primary.set_physics_process(false)
	secondary.set_physics_process(false)
	primary.position = Vector2(400, 250)
	secondary.position = Vector2(580, 250)
	primary.boss_name = "TEST BOSS"
	check(is_equal_approx(game.talent_direct_damage(primary, 20, {}), 25), "Giant Slayer composes through the production direct-hit modifier")
	primary.boss_name = ""
	secondary.health = 1000
	game.equipment.book = "storm_grimoire"
	game.item_direct_hit(primary, 20, {"storm_used": false, "book_epoch": game.book_epoch})
	check(is_equal_approx(secondary.health, 988.75), "Chain Current reaches a real target beyond base Storm range and increases damage once")
	game.active_talents.erase("flow_12")
	secondary.health = 1000
	game.item_direct_hit(primary, 20, {"storm_used": false, "book_epoch": game.book_epoch})
	check(secondary.health == 1000, "The same target stays outside Storm range without Chain Current")
	game.active_talents.flow_12 = 420
	game.equipment.book = "phoenix_grimoire"
	game.phoenix_hits = 9
	game.player.health = 100
	game.item_direct_hit(primary, 20, {"book_epoch": game.book_epoch})
	check(is_equal_approx(game.player.health, 100 + 210 * 0.03 * 1.25), "Living Spring increases an actual Phoenix heal while retaining its cooldown")
	game.player.health = 100
	game.player.protection = 0
	game.player.take_damage(200)
	check(game.player.health > 0 and game.player.last_light_used and game.player.protection == 2, "Last Light catches a lethal hit once with protection; Emberguard may heal afterward")
	game.player.protection = 0
	game.player.take_damage(1000)
	check(game.player.health == 0, "Last Light does not become repeatable through subsequent hits")
	game.return_to_town()
	var normal_path: String = game.progress.path
	var normal_bytes: PackedByteArray = FileAccess.get_file_as_bytes(normal_path)
	check(game.enter_world_sandbox() and game.sandbox and game.progress.path != normal_path, "Town sandbox explicitly switches to a separate save")
	check(game.sandbox_preview(2) and game.sandbox_complete(), "Sandbox previews healing and demonstrates overflow without a full run")
	check(FileAccess.get_file_as_bytes(normal_path) == normal_bytes, "Sandbox tools never touch the original save")
	check(game.enter_world_sandbox() and not game.sandbox, "Leaving sandbox reloads the normal profile")
	game.queue_free()
	await process_frame
	print("WORLD RESTORATION TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
