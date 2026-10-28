extends SceneTree

const ART = preload("res://scripts/world_art.gd")
const STORE = preload("res://scripts/progress_store.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--test-mode"):
		quit(1)
		return
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	for index in ART.MARSH_POOLS.size():
		var basin: Rect2 = ART.MARSH_POOLS[index]
		var bank := Rect2(basin.get_center() - basin.size * 0.545, basin.size * 1.09)
		check(ART.BOUNDS.encloses(bank), "Shore remains inside arena")
		for other in range(index):
			var peer: Rect2 = ART.MARSH_POOLS[other]
			var peer_bank := Rect2(peer.get_center() - peer.size * 0.545, peer.size * 1.09)
			check(not bank.intersects(peer_bank), "Separate basins and banks never overlap")
		var shore: PackedVector2Array = ART.pool_outline(index)
		for point in ART.pool_outline(index, 0.74):
			check(Geometry2D.is_point_in_polygon(point, shore), "Depth stays within the water shoreline")
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	# Preserve this suite's historical global-tree fixture.
	game.progress.companions = game.COMPANIONS.fresh(false)
	game.companion_magic.reset()
	game.town_panel.refresh()
	await process_frame
	game.set_process(false)
	var dev = game.dev_console
	check(dev.tabs.get_child(dev.tabs.get_child_count() - 1).name == "Test tools", "Test tab exists")
	check(dev.edit_echoes(1000) and game.progress.echoes == 1000, "Wallet can be set in town")
	check(game.buy_talent("power_1"), "Buy a real talent before test wallet reset")
	var talents: Dictionary = game.progress.talents.duplicate()
	check(dev.edit_echoes(0) and game.progress.talents == talents, "Zero wallet preserves bought talents")
	check(not dev.edit_echoes(-1) and not dev.edit_echoes(game.progress.MAX_ECHOES), "Negative and invested overflow wallets rejected")
	check(game.debug_jump_wave(5), "Town jump creates run and starts boss wave 5")
	check(game.completed_waves == 4 and game.progress.echoes == 100 and game.progress.world.points[0] == 40, "Skipped clears credit Echoes and Restoration immediately")
	check(game.state == game.State.BOSS_INTRO and game.wave == 5, "Normal boss intro retained")
	game.player.invulnerable = true
	game.player.protection = 1
	var damage_before: float = game.damage_taken
	dev.health_input.value = 25
	for control in dev.screen.find_children("*", "Button", true, false):
		if control.text == "Set current HP":
			control.pressed.emit()
	check(game.player.health == 25 and game.health_bar.value == 25, "HP button sets exact current health and HUD through invulnerability")
	check(game.damage_taken == damage_before, "HP editing does not count as combat damage")
	check(dev.set_current_health(100000) and game.player.health == game.player.health_limit, "HP capped at effective maximum")
	check(not dev.set_current_health(NAN) and not dev.set_current_health(INF) and not dev.set_current_health(0) and not dev.set_current_health(-1), "Invalid HP rejected")
	check(dev.set_current_health(1), "Low-health state available")
	dev.heal_player()
	check(game.player.health == game.player.health_limit, "Restore health still refills player")
	game.accept_item("swift_scepter")
	game.equip_item(game.bag.find("swift_scepter"))
	game.quick_upgrades = 2
	game.update_build()
	var run_id: String = game.run_id
	dev.open_console()
	check(game.debug_jump_wave(10), "Forward jump works from console")
	check(not paused and not dev.is_open, "Jump clears old console pause")
	check(game.run_id == run_id and game.equipment.scepter == "swift_scepter" and game.quick_upgrades == 2, "Jump preserves run and build")
	var paid: int = game.reward_for_waves(9)
	check(game.progress.echoes == paid and game.progress.world.points[0] == 180, "Repeated forward jump pays only cumulative difference")
	check(not game.debug_jump_wave(10) and not game.debug_jump_wave(2) and not game.debug_jump_wave(101), "Repeat/backward/out-of-cap jumps rejected")
	var persisted = STORE.new()
	persisted.path = game.progress.path
	check(persisted.load_progress() and persisted.echoes == paid and persisted.world.points[0] == 180, "Jump credits persist on disk")
	var path: String = game.progress.path
	game.progress.path = "user://absent_parent_%d/progress.json" % OS.get_process_id()
	check(not dev.edit_echoes(99) and game.progress.echoes == paid, "Failed wallet write preserves balance")
	check(not game.debug_jump_wave(15) and game.wave == 10 and game.progress.echoes == paid and game.completed_waves == 9, "Failed atomic write leaves current wave and rewards untouched")
	game.progress.path = path
	check(dev.edit_echoes(0), "Wallet reset during run works")
	game.player.health = 0
	game.finish_run(false)
	check(game.reward_saved and game.progress.echoes == 0 and game.progress.world.points[0] == 180, "Death never repays skipped Echoes or Restoration after wallet reset")
	check(not dev.set_current_health(25) and game.player.health == 0, "HP tool cannot revive finished run")
	game.settle_reward()
	check(game.progress.echoes == 0, "Repeated result save cannot repay")
	game.return_to_town()
	check(game.debug_jump_wave(20), "New run may jump again")
	check(game.run_region == 0 and game.progress.world.points[0] == 600 and game.progress.world.points[1] == 340, "Jump carries Restoration across frontier in current run")
	check(game.debug_jump_wave(21) and game.run_region == 0 and game.progress.world.points[1] == 420, "Further jump retains origin region and pays only missing Restoration")
	game.player.health = 0
	game.finish_run(false)
	check(game.reward_saved and game.predicted_reward() == 0, "Final save succeeds after origin restored")
	game.return_to_town()
	check(game.run_region == 1 and game.debug_echoes_paid == 0, "Next run selects frontier and clears prepaid counter")
	check(dev.edit_echoes(0) and game.debug_jump_wave(2), "Prepare wave 2 with one skipped clear")
	game.state = game.State.FIGHTING
	game.spawn_enemy()
	dev.open_console()
	for control in dev.screen.find_children("*", "Button", true, false):
		if control.text == "Finish current wave":
			control.pressed.emit()
	check(game.completed_waves == 2 and game.enemies.get_child_count() == 0 and game.remaining_to_spawn == 0, "Finish wave button clears current and pending enemies")
	check(game.state == game.State.UPGRADE and paused and dev.is_open, "Finish wave preserves normal card selection behind console")
	dev.close_console()
	check(paused and game.state == game.State.UPGRADE, "Closing console retains card-selection pause")
	game.choose_upgrade(game.offered_cards[0])
	check(not paused, "Card choice resumes skipped-wave test normally")
	game.player.health = 0
	game.finish_run(false)
	check(game.reward_saved and game.progress.echoes == 30, "Actually completed next wave pays only its new Echoes at death")
	game.queue_free()
	await process_frame
	print("DEV TOOLS / HABITATS TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
