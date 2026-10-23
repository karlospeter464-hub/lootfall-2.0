extends SceneTree

const STORE = preload("res://scripts/progress_store.gd")
const JSON_STORE = preload("res://scripts/safe_json.gd")
const WORLD = preload("res://scripts/world_regions.gd")
const ART = preload("res://scripts/world_art.gd")
const SFX = preload("res://scripts/game_sfx.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--test-mode"):
		quit(1)
		return
	call_deferred("run")

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(text)

func run() -> void:
	var store = STORE.new()
	store.path = "user://living_%d.json" % OS.get_process_id()
	var old := {"version": 4, "echoes": 77, "best_wave": 12, "talents": {"power_1": 27}, "world": WORLD.fresh(), "last_settlement": "old", "restoration_run": {"id": "old", "region": 0, "credited": 0}}
	JSON_STORE.write_object(store.path, old)
	var original: PackedByteArray = FileAccess.get_file_as_bytes(store.path)
	check(store.load_progress() and store.echoes == 77 and store.talents.power_1 == 27, "v4 wallet and actual purchase prices preserved")
	check(FileAccess.get_file_as_bytes(store.path) == original, "Loading old progress is read-only")
	check(store.record_echoes(10, "new") and store.echoes == 77, "Earned ground Echoes are durable before pickup")
	check(JSON_STORE.read_object(store.path + ".pre_living.json").echoes == 77 and JSON_STORE.read_object(store.path + ".pre_living.json").version == 4, "Permanent pre-upgrade backup retained")
	check(store.record_echoes(10, "new") and not store.record_echoes(9, "new"), "Cumulative credit is idempotent and cannot regress")
	check(not store.record_echoes(5, "other") and not store.claim_echoes(11, "new"), "Pending old run and excess claims cannot be overwritten")
	check(store.claim_echoes(4, "new") and store.echoes == 81, "Only collected portion enters wallet")
	check(store.claim_echoes(4, "new") and store.echoes == 81, "Repeated pickup claim cannot duplicate")
	var reload = STORE.new()
	reload.path = store.path
	check(reload.load_progress() and reload.recover_echoes() and reload.echoes == 87, "Process restart recovers uncollected durable Echoes")
	check(reload.recover_echoes() and reload.echoes == 87, "Recovery is idempotent")
	check(reload.settle_expedition(0, 1, 0, 4, "new") and reload.echoes == 87, "Settlement does not repay already claimed wave budget")
	check(not reload.record_echoes(20, "new"), "Settled run cannot generate further ground rewards")
	check(reload.record_echoes(3, "next"), "Next run starts its own cumulative ledger")
	check(not reload.debug_set_echoes(STORE.MAX_ECHOES - reload.invested()), "Wallet edits cannot consume pending reward capacity")
	var path: String = reload.path
	reload.path = "user://missing_living_folder/progress.json"
	check(not reload.claim_echoes(3, "next") and reload.echoes == 87 and reload.echo_run.paid == 0, "Failed pickup save preserves both ledger and wallet")
	reload.path = path
	check(reload.recover_echoes() and reload.echoes == 90, "Retry recovers once after write failure")
	for index in 44:
		check(ART.growth(index, 0) == 0 and ART.growth(index, 1) == 1 and ART.growth(index, 0.25) <= ART.growth(index, 0.5), "Rooted growth is monotonic across healing stages %d" % index)
	for key in ["orb", "vacuum", "card", "growth", "restored"]:
		var tone: AudioStreamWAV = SFX.tone(key)
		check(tone.data.size() > 1000 and tone.mix_rate == 22050 and tone.format == AudioStreamWAV.FORMAT_16_BITS, "Self-generated playable audio: " + key)
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.restart_run()
	game.player.controls_enabled = false
	game.feel.set_process(false)
	game.begin_wave()
	game.spawn_enemy()
	game.enemies.get_child(0).position = Vector2(150,200)
	game.enemies.get_child(0).take_damage(100000)
	await process_frame
	check(game.echo_earned() == 1 and game.echo_paid() == 0 and game.feel.orbs.size() == 1, "Actual kill creates one durable, uncollected orb")
	var good_path: String = game.progress.path
	game.progress.path = "user://missing_living_folder/progress.json"
	game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(game.echo_paid() == 0 and game.feel.orbs.size() == 1, "Normal close is blocked when ground Echoes cannot be saved")
	game.progress.path = good_path
	var rng_state: int = game.rng.state
	game.feel._process(0.1)
	check(game.rng.state == rng_state and game.echo_paid() == 0, "Distant orbs neither auto-collect nor consume gameplay RNG")
	game.player.position = Vector2(155,200)
	game.feel._process(0.1)
	check(game.progress.echoes == 1 and game.feel.orbs.is_empty(), "Nearby orb magnet and pickup credit actual wallet")
	game.remaining_to_spawn = 0
	game.complete_wave()
	check(game.echo_earned() == 10 and game.feel.vacuuming, "Wave clear fills only the remaining original budget")
	paused = true
	for frame in 120: game.feel._process(1.0 / 60)
	check(game.progress.echoes == 10 and game.feel.orbs.is_empty(), "Wave vacuum completes even under paused card/menu UI")
	paused = false
	game.begin_wave()
	game.spawn_enemy()
	game.enemies.get_child(0).position = Vector2(1100,650)
	game.enemies.get_child(0).take_damage(100000)
	await process_frame
	var earned: int = game.echo_earned()
	game.finish_run(false)
	check(game.reward_saved and game.progress.echoes == earned and earned > 10, "Death secures partial next-wave kills without repeating completed waves")
	game.settle_reward()
	check(game.progress.echoes == earned, "Repeated death settlement cannot repay pickups")
	game.return_to_town()
	game.restart_run()
	check(game.echo_earned() == 0 and game.progress.echoes == earned, "Restart resets ledger context while retaining wallet")
	game.begin_wave()
	game.secure_echo_total(5, Vector2(100,200))
	game.restart_run()
	check(game.progress.echoes == earned + 5 and game.feel.orbs.is_empty(), "Aborting a run via restart secures ground Echoes")
	for index in 1000: game.feel.add_orb(Vector2(index % 1000, 300), 1)
	var sum: int = 0
	for orb in game.feel.orbs: sum += orb.value
	check(game.feel.orbs.size() == 48 and sum == 1000, "One thousand drop events merge into at most 48 orbs without losing value")
	game.feel.reset()
	game.state = game.State.UPGRADE
	game.offered_cards.assign([0, 1, 4])
	game.show_overlay("CHOOSE YOUR FLAME", "Three ways forward")
	game.refresh_upgrade_cards()
	await process_frame
	check(game.buttons.get_child_count() == 3 and game.buttons.get_child(0).has_focus(), "New upgrade cards preserve keyboard focus and three choices")
	game.buttons.get_child(0).pressed.emit()
	check(game.power_upgrades == 1 and game.feel.card_confirm > 0 and not game.overlay.visible, "Real card button applies existing effect and confirmation")
	game.restart_run()
	var near: Dictionary = WORLD.fresh()
	near.points[0] = 588
	game.progress._save(game.progress.echoes, 0, {}, near)
	game.restoration_visual = 0.98
	game.wave = 1
	game.begin_wave()
	game.remaining_to_spawn = 0
	game.complete_wave()
	check(game.progress.world.points == [600, 0, 0] and not game.overlay.visible and game.feel.celebration > 0, "Region completion gives the growing landscape an unobscured moment")
	await create_timer(1.9, true).timeout
	check(game.overlay.visible and game.buttons.get_child_count() == 3, "Existing card choice returns after the restoration reveal")
	check(game.flush_echoes() and game.progress.record_echoes(5, "process-recovery"), "Uncollected credits prepared for a fresh arena startup")
	var wallet_before_reload: int = game.progress.echoes
	game.queue_free()
	await process_frame
	var restarted = load("res://scenes/arena.tscn").instantiate()
	root.add_child(restarted)
	await process_frame
	check(restarted.state == restarted.State.TOWN and restarted.progress.echoes == wallet_before_reload + 5 and restarted.progress.echo_run.paid == 5, "Actual startup recovers orphaned credits before opening Emberhaven")
	restarted.queue_free()
	await process_frame
	print("LIVING WORLD TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
