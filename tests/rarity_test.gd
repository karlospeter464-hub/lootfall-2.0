extends SceneTree

const CATALOG = preload("res://scripts/item_catalog.gd")
const SAFE_JSON = preload("res://scripts/safe_json.gd")
var checks: int = 0
var failures: int = 0

class Rolls extends RefCounted:
	var values: Array[float] = []
	var calls: int = 0
	func randf() -> float:
		var result: float = values[calls]
		calls += 1
		return result
	func randi_range(first: int, _last: int) -> int:
		return first

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

func run() -> void:
	var rolls := Rolls.new()
	rolls.values = [0.01]
	check(CATALOG.roll_item(rolls, 0.02, 0.25, 0.5, true) == "cinder_codex" and rolls.calls == 1, "A Legendary success stops the cascade immediately")
	rolls.calls = 0
	rolls.values = [0.03, 0.24]
	check(CATALOG.roll_item(rolls, 0.02, 0.25, 0.5, true) == "focus_grimoire" and rolls.calls == 2, "Rare gets its own independent roll after Legendary fails")
	rolls.calls = 0
	rolls.values = [0.03, 0.26, 0.49]
	check(CATALOG.roll_item(rolls, 0.02, 0.25, 0.5, true) == "swift_scepter" and rolls.calls == 3, "Magic is checked only after both higher tiers fail")
	rolls.calls = 0
	rolls.values = [0.03, 0.26, 0.51]
	check(CATALOG.roll_item(rolls, 0.02, 0.25, 0.5, true) == "ember_scepter" and rolls.calls == 3, "Normal is the guaranteed remainder without another random roll")
	rolls.calls = 0
	rolls.values = [0.01, 0.01]
	check(CATALOG.roll_item(rolls, 0.02, 0.25, 0.5, false) == "focus_grimoire", "An exhausted Legendary pool falls through to the Rare check")
	rolls.calls = 0
	rolls.values = [0.0, 0.0, 0.0]
	check(CATALOG.roll_item(rolls, 0, 0, 0, true) == "ember_scepter", "Zero chance never succeeds, even on a zero random value")
	rolls.calls = 0
	rolls.values = [1.0]
	check(CATALOG.roll_item(rolls, 1, 1, 1, true) == "cinder_codex", "A 100-percent tier succeeds even on the random endpoint")
	var random := RandomNumberGenerator.new()
	random.seed = 87654
	var counts := {"legendary": 0, "rare": 0, "magic": 0, "normal": 0}
	for index in 100000:
		var id: String = CATALOG.roll_item(random, 0.02, 0.25, 0.5, true)
		counts[CATALOG.ITEMS[id].rarity] += 1
	for rarity in counts:
		var expected: float = {"legendary": 0.02, "rare": 0.245, "magic": 0.3675, "normal": 0.3675}[rarity]
		check(absf(float(counts[rarity]) / 100000 - expected) < 0.006, "Seeded cascade frequencies match conditional probabilities: " + rarity)
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
	game.begin_wave()
	game.drop_chance = 1
	game.equipment_drop_chance = 0
	game.enemy_slain(Vector2(250, 300))
	check(game.loot.get_child_count() == 0 and not game.codex_spawned, "The separate zero item chance prevents even a guaranteed Legendary")
	game.equipment_drop_chance = 1
	game.rare_chance = 1
	game.enemy_slain(Vector2(250, 300))
	check(game.loot.get_child_count() == 1 and game.loot.get_child(0).item_id == "cinder_codex", "A real kill selects exactly one physical Legendary item")
	game.enemy_slain(Vector2(450, 300))
	check(game.loot.get_child_count() == 2 and CATALOG.ITEMS[game.loot.get_child(1).item_id].rarity == "rare", "A second kill cannot create a second natural Codex and still drops an eligible Rare item")
	check(game.progress.echoes == 0 and not game.codex_active, "Rarity drops neither pay Echoes nor equip themselves")
	game.ground_loot_limit = 2
	game.enemy_slain(Vector2(250, 500))
	check(game.loot.get_child_count() == 2, "The ground cap remains enforced for rarity drops")
	game.restart_run()
	var rates: Dictionary = game.rarity_rates()
	check(rates.legendary == 1 and rates.rare == 0, "Restart restores Legendary eligibility in actual rate metrics")
	game.dev_console.reset_defaults()
	rates = game.rarity_rates()
	check(is_equal_approx(rates.rare, 0.245) and is_equal_approx(rates.magic, 0.3675) and is_equal_approx(rates.normal, 0.3675), "F1-derived actual rates use cascaded rather than flat shares")
	check(is_equal_approx(rates.legendary * game.equipment_drop_chance, 0.001), "Default Legendary rate is 0.1 percent per kill before the Codex drops")
	game.codex_spawned = true
	rates = game.rarity_rates()
	check(rates.legendary == 0 and rates.rare == 0.25 and rates.magic == 0.375 and rates.normal == 0.375, "Metrics account for the exhausted natural Codex pool")
	game.accept_item("focus_grimoire")
	game.inventory_panel.open_inventory()
	check(game.inventory_panel.item_type.text.contains("RARE"), "Inspection identifies rarity in text, not only color")
	check(game.inventory_panel.bag_buttons[0].get_theme_color("font_color") == CATALOG.color("focus_grimoire"), "Bag rendering uses the shared rarity color")
	game.inventory_panel.close_inventory()
	game.equip_item(0)
	check(is_equal_approx(game.player.damage, 14 * 1.4), "Assigning rarity does not change the existing fixed item effect")
	var dev = game.dev_console
	check(dev.save_profile(), "The new cascade settings save in a real profile")
	var profile: Dictionary = SAFE_JSON.read_object(dev.profile_path)
	check(profile.version == 10 and profile.values.size() == 92, "New profiles contain all 92 values with version ten")
	var old: Dictionary = profile.duplicate(true)
	old.version = 4
	for field in dev.FIELDS:
		if dev.field_version(field) > 4:
			old.values.erase(field[1] + "." + field[2])
	old.values.erase("arena.rare_chance")
	old.values.erase("arena.magic_chance")
	old.values["arena.drop_chance"] = 0.04
	old.values["arena.equipment_drop_chance"] = 0.15
	SAFE_JSON.write_object(dev.profile_path, old)
	dev.apply_setting("arena.rare_chance", 1)
	check(dev.load_profile() and game.drop_chance == 0.04 and game.equipment_drop_chance == 0.15 and game.rare_chance == 0.25 and game.magic_chance == 0.5, "Old v4 numeric values load with default new cascade fields")
	check(dev.status.text.contains("per-item rarity cascade") and SAFE_JSON.read_object(dev.profile_path).version == 4, "Legacy load explains the new probability basis and preserves its source file")
	old.values["unknown.chance"] = 1
	SAFE_JSON.write_object(dev.profile_path, old)
	check(not dev.load_profile() and game.equipment_drop_chance == 0.15, "Unknown legacy values reject the whole load")
	game.queue_free()
	await process_frame
	print("RARITY TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
