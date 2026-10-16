extends CanvasLayer

const SAFE_JSON = preload("res://scripts/safe_json.gd")
const ITEM_FIELDS := ["arena.equipment_drop_chance", "arena.ground_loot_limit", "arena.scepter_damage_bonus", "arena.scepter_cast_reduction", "arena.focus_damage_bonus"]

# Group, target, property, label, minimum, maximum, step, application time.
const FIELDS := [
	["Player", "player", "move_speed", "Movement speed", 50, 600, 5, "Live"],
	["Player", "player", "max_health", "Maximum health", 1, 500, 1, "Live; clamps current HP without healing"],
	["Player", "player", "base_damage", "Base fireball damage", 1, 100, 1, "Next cast; existing upgrades preserved"],
	["Player", "player", "base_cast_interval", "Base cast interval (s)", 0.08, 2, 0.01, "Next cooldown"],
	["Player", "player", "hit_protection", "Hit protection (s)", 0.1, 2, 0.05, "Next hit"],
	["Waves", "arena", "total_waves", "Run wave limit", 5, 100, 1, "Next wave completion; choices remain at 2 and 4"],
	["Waves", "arena", "first_wave_enemies", "First-wave enemies", 1, 50, 1, "Next wave"],
	["Waves", "arena", "enemies_per_wave", "Extra enemies / wave", 0, 20, 1, "Next wave"],
	["Waves", "arena", "enemy_limit", "Simultaneous enemy cap", 1, 100, 1, "Live; does not delete existing enemies"],
	["Waves", "arena", "spawn_interval", "Spawn interval (s)", 0.1, 3, 0.05, "Next spawn timer"],
	["Waves", "arena", "safe_spawn_distance", "Safe spawn distance", 100, 600, 10, "New spawns"],
	["Waves", "arena", "intermission", "Between-wave break (s)", 0.1, 10, 0.1, "Next break"],
	["Enemies", "arena", "enemy_health", "Base enemy HP", 1, 500, 1, "New enemies"],
	["Enemies", "arena", "enemy_health_growth", "HP growth / wave", 0, 50, 1, "New enemies"],
	["Enemies", "arena", "enemy_speed", "Base enemy speed", 10, 300, 5, "New enemies"],
	["Enemies", "arena", "enemy_speed_growth", "Speed growth / wave", 0, 30, 1, "New enemies"],
	["Enemies", "arena", "enemy_damage", "Contact damage", 1, 100, 1, "New enemies"],
	["Combat & loot", "arena", "projectile_speed", "Projectile speed", 100, 1500, 25, "New projectiles"],
	["Combat & loot", "arena", "projectile_lifetime", "Projectile lifetime (s)", 0.1, 5, 0.1, "New projectiles"],
	["Combat & loot", "arena", "projectile_spread", "Side-shot spread (radians)", 0, 0.6, 0.01, "Next cast"],
	["Combat & loot", "arena", "upgrade_damage_bonus", "Power card: base damage bonus", 0, 1, 0.01, "Live; 0.35 = +35% per chosen card"],
	["Combat & loot", "arena", "upgrade_cast_reduction", "Quick card: interval reduction", 0, 0.8, 0.01, "Live; 0.2 = 20% per chosen card"],
	["Combat & loot", "arena", "upgrade_projectiles", "Fan card: extra projectiles", 1, 3, 1, "Live; aimed shot preserved"],
	["Combat & loot", "arena", "drop_chance", "Codex drop chance (0..1)", 0, 1, 0.005, "Next kill; at most one Codex per run"],
	["Combat & loot", "arena", "equipment_drop_chance", "Other gear drop chance (0..1)", 0, 1, 0.01, "Next kill without a Codex drop; one of three items"],
	["Combat & loot", "arena", "ground_loot_limit", "Ground item cap", 1, 64, 1, "Live; existing items are kept"],
	["Combat & loot", "arena", "scepter_damage_bonus", "Ember Scepter damage bonus", 0, 2, 0.05, "Live when equipped; additive with Focus bonus"],
	["Combat & loot", "arena", "scepter_cast_reduction", "Swift Scepter interval reduction", 0, 0.8, 0.05, "Live when equipped; multiplies card interval"],
	["Combat & loot", "arena", "focus_damage_bonus", "Focus Grimoire damage bonus", 0, 2, 0.05, "Live when equipped; replaces Codex splash"],
	["Combat & loot", "arena", "pickup_radius", "Item pickup radius", 10, 100, 1, "Live"],
	["Combat & loot", "arena", "explosion_radius", "Codex explosion radius", 20, 250, 5, "Next impact with Codex"],
	["Combat & loot", "arena", "explosion_damage_ratio", "Codex splash / shot damage", 0, 3, 0.05, "Next impact; excludes the directly hit enemy"],
	["Rewards & tools", "arena", "echoes_per_wave", "Echoes per completed wave tier", 0, 1000, 1, "At run end; tier * (1 + 2 + ... + cleared)"],
]

var game
var is_open: bool = false
var was_paused: bool = false
var previous_controls: bool = true
var profile_path: String = "user://balance_profile.json"
var screen: Control
var metrics: Label
var status: Label
var tabs: TabContainer
var controls: Dictionary = {}
var defaults: Dictionary = {}
var invulnerable_box: CheckBox
var freeze_box: CheckBox
var refresh_clock: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	if not OS.is_debug_build():
		queue_free()
		return
	if OS.get_cmdline_user_args().has("--test-mode"):
		profile_path = "user://test_balance_%d.json" % OS.get_process_id()
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.04, 0.07, 0.94)
	screen.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(70, 65)
	panel.size = Vector2(1140, 670)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b2532")
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	screen.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := Label.new()
	title.text = "DEVELOPER CONSOLE   /   F1 or Esc to close"
	title.add_theme_font_size_override("font_size", 23)
	column.add_child(title)
	var hint := Label.new()
	hint.text = "Gameplay pauses while editing. Balancing and test actions affect real runs and saved Echoes."
	hint.add_theme_font_size_override("font_size", 14)
	column.add_child(hint)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size.y = 440
	column.add_child(tabs)
	var pages: Dictionary = {}
	for group in ["Metrics", "Player", "Waves", "Enemies", "Combat & loot", "Rewards & tools"]:
		var scroll := ScrollContainer.new()
		scroll.name = group
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tabs.add_child(scroll)
		var page := VBoxContainer.new()
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.add_theme_constant_override("separation", 12)
		scroll.add_child(page)
		pages[group] = page
	metrics = Label.new()
	metrics.add_theme_font_size_override("font_size", 16)
	pages["Metrics"].add_child(metrics)
	for field in FIELDS:
		var key: String = field[1] + "." + field[2]
		var target: Object = game.player if field[1] == "player" else game
		defaults[key] = target.get(field[2])
		var row := HBoxContainer.new()
		pages[field[0]].add_child(row)
		var label := Label.new()
		label.text = field[3]
		label.custom_minimum_size.x = 305
		row.add_child(label)
		var spin := SpinBox.new()
		spin.min_value = field[4]
		spin.max_value = field[5]
		spin.step = field[6]
		spin.custom_minimum_size.x = 130
		spin.value = defaults[key]
		spin.value_changed.connect(func(value: float): apply_setting(key, value))
		row.add_child(spin)
		controls[key] = spin
		var timing := Label.new()
		timing.text = field[7]
		timing.add_theme_font_size_override("font_size", 13)
		row.add_child(timing)
	invulnerable_box = CheckBox.new()
	invulnerable_box.text = "Invulnerable (resets on new run)"
	invulnerable_box.toggled.connect(func(value: bool): game.player.invulnerable = value)
	pages["Rewards & tools"].add_child(invulnerable_box)
	freeze_box = CheckBox.new()
	freeze_box.text = "Freeze enemies (resets on new run)"
	freeze_box.toggled.connect(freeze_enemies)
	pages["Rewards & tools"].add_child(freeze_box)
	var actions := HBoxContainer.new()
	pages["Rewards & tools"].add_child(actions)
	button(actions, "Restore health", heal_player)
	button(actions, "Drop Codex", func(): game.drop_codex(game.player.position + Vector2(90, 0)))
	button(actions, "Defeat active enemies", func():
		for enemy in game.enemies.get_children():
			enemy.take_damage(enemy.health)
	)
	var item_row := HBoxContainer.new()
	pages["Rewards & tools"].add_child(item_row)
	var item_choice := OptionButton.new()
	for id in game.CATALOG.ITEMS:
		item_choice.add_item(game.CATALOG.ITEMS[id].name)
	item_row.add_child(item_choice)
	button(item_row, "Drop selected item", func():
		var id: String = game.CATALOG.ITEMS.keys()[item_choice.selected]
		status.text = "Item placed near the player; collect and equip it." if game.drop_item(id, game.player.position + Vector2(120, 0)) else "No item dropped: ground is full or the run has ended."
	)
	var seed_row := HBoxContainer.new()
	pages["Rewards & tools"].add_child(seed_row)
	var seed_input := SpinBox.new()
	seed_input.min_value = 0
	seed_input.max_value = 2147483647
	seed_input.custom_minimum_size.x = 180
	seed_input.value = 42
	seed_row.add_child(seed_input)
	button(seed_row, "Apply RNG seed", func(): game.rng.seed = int(seed_input.value); status.text = "RNG restarted from seed %d. Same settings and actions are needed for reproduction." % int(seed_input.value))
	var footer := HBoxContainer.new()
	column.add_child(footer)
	button(footer, "Save profile", save_profile)
	button(footer, "Load profile", load_profile)
	button(footer, "Reset defaults", reset_defaults)
	button(footer, "Close [F1]", close_console)
	status = Label.new()
	status.text = "Profiles store balancing values only. Loading is manual; game progress is stored separately."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 14)
	column.add_child(status)
	screen.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 or (is_open and event.keycode == KEY_ESCAPE):
			if is_open:
				close_console()
			else:
				open_console()
			get_viewport().set_input_as_handled()

func open_console() -> void:
	if is_open or not OS.is_debug_build():
		return
	was_paused = get_tree().paused
	previous_controls = game.player.controls_enabled
	game.player.controls_enabled = false
	get_tree().paused = true
	is_open = true
	sync_controls()
	screen.show()
	update_metrics()

func close_console() -> void:
	if not is_open:
		return
	is_open = false
	screen.hide()
	game.player.controls_enabled = previous_controls
	get_tree().paused = was_paused
	# SpinBox edits must not keep keyboard focus after the console closes.
	get_viewport().gui_release_focus()
	if game.inventory_panel.is_open:
		game.inventory_panel.restore_focus()
	elif game.overlay.visible and game.buttons.get_child_count() > 0:
		game.buttons.get_child(0).grab_focus()

func _process(delta: float) -> void:
	if not is_open:
		return
	refresh_clock -= delta
	if refresh_clock <= 0:
		update_metrics()
		refresh_clock = 0.2

func update_metrics() -> void:
	var total_hp: float = 0.0
	for enemy in game.enemies.get_children():
		total_hp += enemy.health
	metrics.text = "FPS: %d   |   Frame: %.2f ms   |   Static memory: %.1f MiB\nState: %s   |   Active run time: %.1f s   |   Seed: %d\nWave: %d / %d   |   Cleared: %d   |   Best: %d\nEnemies: %d / %d cap   |   Still to spawn: %d   |   Active enemy HP: %.0f\nKills: %d   |   Projectiles alive: %d   |   Projectiles fired / hit: %d / %d\nDamage dealt: %.1f   |   Average run DPS: %.1f   |   Health lost: %.1f\nPlayer: %.0f / %.0f HP   |   Speed: %.0f   |   Protection left: %.2f s\nFireball: %.1f damage   |   %.3f s interval   |   %d projectiles\nCards: %d / 2   |   Power / Quick / Fan: %d / %d / %d\nCodex active: %s   |   Items on floor: %d   |   Drops this run: %d\nSplash: %.0f radius / %.0f%% damage   |   Drop chance: %.2f%%\nEchoes: %d saved   |   Current payout: %d   |   Saved progress available: %s" % [Engine.get_frames_per_second(), 1000.0 / maxf(Engine.get_frames_per_second(), 1), OS.get_static_memory_usage() / 1048576.0, game.State.keys()[game.state], game.elapsed, game.rng.seed, game.wave, game.total_waves, game.completed_waves, game.best_wave, game.enemies.get_child_count(), game.enemy_limit, game.remaining_to_spawn, total_hp, game.kills, game.projectiles.get_child_count(), game.shots_fired, game.shots_hit, game.damage_dealt, game.damage_dealt / maxf(game.elapsed, 0.001), game.damage_taken, game.player.health, game.player.max_health, game.player.move_speed, game.player.protection, game.player.damage, game.player.cast_interval, game.player.projectile_count, game.upgrades_chosen, game.power_upgrades, game.quick_upgrades, game.fan_upgrades, str(game.codex_active), game.loot.get_child_count(), game.drops_created, game.explosion_radius, game.explosion_damage_ratio * 100, game.drop_chance * 100, game.progress.echoes, game.predicted_reward(), str(game.progress.available)]

	metrics.text += "\nBag: %d / 8   |   Scepter: %s   |   Book: %s" % [game.bag_used(), game.equipment.scepter, game.equipment.book]

func valid_value(field: Array, value: Variant) -> bool:
	if not (value is int or value is float) or not is_finite(float(value)):
		return false
	if float(value) < field[4] or float(value) > field[5]:
		return false
	return field[6] != 1 or float(value) == floorf(float(value))

func apply_setting(key: String, value: Variant) -> bool:
	for field in FIELDS:
		if key != field[1] + "." + field[2]:
			continue
		if not valid_value(field, value):
			return false
		var target: Object = game.player if field[1] == "player" else game
		target.set(field[2], int(value) if target.get(field[2]) is int else float(value))
		game.update_build()
		for pickup in game.loot.get_children():
			pickup.pickup_radius = game.pickup_radius
		game.update_hud()
		controls[key].set_value_no_signal(float(value))
		return true
	return false

func sync_controls() -> void:
	for field in FIELDS:
		var target: Object = game.player if field[1] == "player" else game
		controls[field[1] + "." + field[2]].set_value_no_signal(target.get(field[2]))
	invulnerable_box.set_pressed_no_signal(game.player.invulnerable)
	freeze_box.set_pressed_no_signal(game.enemies_frozen)

func reset_defaults() -> void:
	for key in defaults:
		apply_setting(key, defaults[key])
	game.player.invulnerable = false
	freeze_enemies(false)
	sync_controls()
	status.text = "Inspector startup defaults restored. Test switches cleared. Current HP is not refilled."

func save_profile() -> bool:
	var values: Dictionary = {}
	for field in FIELDS:
		var target: Object = game.player if field[1] == "player" else game
		values[field[1] + "." + field[2]] = target.get(field[2])
	var error: Error = SAFE_JSON.write_object(profile_path, {"version": 2, "values": values})
	status.text = "Profile saved: %s" % ProjectSettings.globalize_path(profile_path) if error == OK else "Profile not saved: %s" % error_string(error)
	return error == OK

func load_profile() -> bool:
	var data: Dictionary = SAFE_JSON.read_object(profile_path)
	if (data.get("version") != 1 and data.get("version") != 2) or not data.get("values") is Dictionary:
		status.text = "Invalid or missing profile. Nothing changed."
		return false
	var values: Dictionary = data.values
	var legacy: bool = data.version == 1
	if values.size() != FIELDS.size() - (ITEM_FIELDS.size() if legacy else 0):
		status.text = "Profile has missing or unknown settings. Nothing changed."
		return false
	for field in FIELDS:
		var key: String = field[1] + "." + field[2]
		if legacy and key in ITEM_FIELDS:
			if values.has(key):
				status.text = "Unexpected legacy setting. Nothing changed."
				return false
			continue
		if not valid_value(field, values.get(key)):
			status.text = "Invalid profile setting: %s. Nothing changed." % key
			return false
	for field in FIELDS:
		var key: String = field[1] + "." + field[2]
		apply_setting(key, values.get(key, defaults[key]))
	sync_controls()
	status.text = "Legacy profile loaded; new item settings use startup defaults." if legacy else "Profile loaded. Test switches and progress are not part of profiles."
	return true

func heal_player() -> void:
	if game.state == game.State.FINISHED:
		return
	game.player.health = game.player.max_health
	game.player.health_changed.emit(game.player.health, game.player.max_health)

func freeze_enemies(value: bool) -> void:
	game.enemies_frozen = value
	for enemy in game.enemies.get_children():
		enemy.frozen = value

func button(parent: Node, text: String, action: Callable) -> void:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 34
	control.pressed.connect(action)
	parent.add_child(control)
