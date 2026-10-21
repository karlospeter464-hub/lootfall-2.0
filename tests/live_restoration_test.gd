extends SceneTree

const STORE = preload("res://scripts/progress_store.gd")
const WORLD = preload("res://scripts/world_regions.gd")
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
	var store = STORE.new()
	store.path = "user://live_restoration_%d.json" % OS.get_process_id()
	var world: Dictionary = WORLD.fresh(12)
	world.points[0] = 590
	var old := {"version": 3, "echoes": 77, "best_wave": 12, "talents": {"power_1": 27}, "world": world, "last_settlement": "old-run"}
	JSON_STORE.write_object(store.path, old)
	var original: PackedByteArray = FileAccess.get_file_as_bytes(store.path)
	check(store.load_progress() and store.echoes == 77 and store.talents.power_1 == 27 and store.world == world, "Existing v3 world, wallet and paid prices load intact")
	check(FileAccess.get_file_as_bytes(store.path) == original, "Loading v3 is read-only")
	check(store.restore_during_run(4, 1, 0, "live") and store.world.points == [594, 0, 0] and store.echoes == 77, "First wave immediately saves four points, without paying Echoes")
	check(store.restore_during_run(4, 1, 0, "live") and store.world.points[0] == 594, "Repeated wave notification cannot award twice")
	var reload = STORE.new()
	reload.path = store.path
	check(reload.load_progress() and reload.restoration_run.credited == 4, "Saved live credit survives process reload")
	check(reload.restore_during_run(12, 2, 0, "live") and reload.world.points == [600, 2, 0], "Second wave gives only eight new points and unlocks the next frontier")
	check(reload.restore_during_run(24, 3, 0, "live") and reload.world.points == [600, 14, 0], "Same expedition can continue after its origin region is restored")
	check(not reload.restore_during_run(12, 2, 0, "live"), "A regressing cumulative wave credit is rejected")
	check(reload.settle_expedition(60, 4, 0, 24, "live") and reload.echoes == 137 and reload.world.points == [600, 14, 0], "Run end pays Echoes once and does not repay live Restoration")
	check(not reload.restore_during_run(40, 4, 0, "live"), "A settled expedition cannot generate further live credits")
	check(reload.settle_expedition(60, 4, 0, 24, "live") and reload.echoes == 137, "Final settlement remains idempotent")
	check(reload.restore_during_run(4, 1, 1, "new") and reload.world.points == [600, 18, 0], "Next expedition begins its own credit counter in Region 2")
	var bad: Dictionary = JSON_STORE.read_object(store.path)
	bad.restoration_run.credited = -1
	var invalid = STORE.new()
	invalid.path = "user://bad_live_%d.json" % OS.get_process_id()
	JSON_STORE.write_object(invalid.path, bad)
	check(not invalid.load_progress() and not invalid.award(1, 1), "Corrupt live metadata blocks writes without altering the original")
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var initial: Dictionary = WORLD.fresh()
	initial.points[0] = 146
	game.progress._save(0, 0, {}, initial)
	game.restart_run()
	game.player.controls_enabled = false
	game.begin_wave()
	game.remaining_to_spawn = 0
	game.complete_wave()
	check(game.progress.world.points[0] == 150 and game.progress.echoes == 0 and game.player.health > 0, "Actual scene wave completion reaches 25% while player is still alive")
	game.restoration_tween.custom_step(2.0)
	check(is_equal_approx(game.restoration_visual, 0.25), "Visual terrain tween reaches the newly saved healing fraction")
	game.begin_wave()
	game.remaining_to_spawn = 0
	var good_path: String = game.progress.path
	game.progress.path = "user://missing_live_folder/progress.json"
	game.complete_wave()
	check(game.restoration_pending and game.progress.world.points[0] == 150, "Failed live save sets a visible pending state; no false visual credit")
	game.restart_run()
	check(game.wave == 2 and game.restoration_pending, "Restart cannot silently discard failed live progress")
	game.progress.path = good_path
	check(game.restore_completed_waves() and not game.restoration_pending and game.progress.world.points[0] == 158, "Retry saves the missing difference once")
	game.finish_run(false)
	check(game.reward_saved and game.progress.world.points[0] == 158 and game.progress.echoes == 30, "Death after two waves pays only the normal Echoes balance")
	game.return_to_town()
	game.restart_run()
	check(game.run_region == 0 and game.wave == 0 and game.progress.world.points[0] == 158, "Restart retains live world progress with a fresh run counter")
	game.queue_free()
	await process_frame
	print("LIVE RESTORATION TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
