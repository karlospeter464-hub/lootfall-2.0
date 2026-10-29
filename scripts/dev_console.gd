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
	["Waves", "arena", "total_waves", "Prototype safety wave cap", 5, 100, 1, "Technical stop, not victory; cards every five-wave block"],
	["Waves", "arena", "ascent_health_scale", "HP multiplier / wave after 6", 1, 1.35, 0.01, "New enemies; bounded for prototype safety"],
	["Waves", "arena", "ascent_damage_growth", "Damage growth / wave", 0, 0.1, 0.01, "New enemies; 0.04 = 4%"],
	["Waves", "arena", "ascent_budget_cap", "Normal wave budget ceiling", 1, 60, 1, "Next wave; does not change active enemy cap"],
	["Waves", "arena", "ascent_spawn_decay", "Spawn interval reduction / wave", 0, 0.1, 0.01, "Next spawn; minimum 0.18s"],
	["Waves", "arena", "boss_health_multiplier", "Boss HP multiplier", 1, 15, 0.5, "New bosses; Prophet adds another 1.5x"],
	["Waves", "arena", "boss_escorts", "Boss escort budget", 0, 10, 1, "Next boss wave; boss also occupies one spawn slot"],
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
	["Enemies", "arena", "ranged_limit", "Active seer cap", 0, 6, 1, "New spawns from wave 2; 0 disables seers"],
	["Enemies", "arena", "ranged_windup", "Seer warning duration (s)", 0.4, 3, 0.1, "New seers; target position is locked"],
	["Enemies", "arena", "ranged_interval", "Seer recovery (s)", 0.5, 6, 0.1, "New seers"],
	["Enemies", "arena", "ranged_radius", "Seer impact radius", 20, 100, 1, "New seers; leave the marked circle"],
	["Enemies", "arena", "seer_health_multiplier", "Seer HP multiplier", 1, 10, 0.5, "New seers; enough HP to test interruption"],
	["Enemies", "arena", "seer_interrupt_hits", "Seer direct hits to interrupt", 0, 12, 1, "New seers; within warning; 0 disables"],
	["Enemies", "arena", "guardian_first_wave", "Guardian first wave", 3, 100, 1, "New spawns"],
	["Enemies", "arena", "guardian_every", "Guardian candidate every N spawns", 1, 30, 1, "New spawns; replaces a normal spawn"],
	["Enemies", "arena", "guardian_limit", "Active guardian cap", 0, 2, 1, "New spawns; total enemy cap still applies"],
	["Enemies", "arena", "guardian_health_multiplier", "Guardian HP multiplier", 1, 10, 0.5, "New guardians"],
	["Enemies", "arena", "guardian_speed_ratio", "Guardian speed multiplier", 0.1, 1, 0.05, "New guardians"],
	["Enemies", "arena", "guardian_armor", "Guardian flat damage reduction", 0, 50, 1, "New guardians; applies once per hit, including splash"],
	["Enemies", "arena", "guardian_minimum_ratio", "Guardian minimum damage ratio", 0.05, 1, 0.05, "New guardians; fraction of incoming damage"],
	["Combat & loot", "arena", "projectile_speed", "Projectile speed", 100, 1500, 25, "New projectiles"],
	["Combat & loot", "arena", "projectile_lifetime", "Projectile lifetime (s)", 0.1, 5, 0.1, "New projectiles"],
	["Combat & loot", "arena", "projectile_spread", "Side-shot spread (radians)", 0, 0.6, 0.01, "Next cast"],
	["Combat & loot", "arena", "upgrade_damage_bonus", "Power card: base damage bonus", 0, 1, 0.01, "Live; 0.35 = +35% per chosen card"],
	["Combat & loot", "arena", "upgrade_cast_reduction", "Quick card: interval reduction", 0, 0.8, 0.01, "Live; 0.2 = 20% per chosen card"],
	["Combat & loot", "arena", "upgrade_projectiles", "Fan card: extra projectiles", 1, 3, 1, "Live; aimed shot preserved"],
	["Combat & loot", "arena", "burst_radius", "Ember Burst radius", 20, 150, 5, "Next direct kill with Ember Burst"],
	["Combat & loot", "arena", "burst_damage_ratio", "Ember Burst / shot damage", 0.05, 2, 0.05, "Next direct kill; indirect damage cannot retrigger"],
	["Combat & loot", "arena", "overcharge_bonus", "Overcharge damage bonus", 0.05, 2, 0.05, "Next charged main shot; 4 direct hits to charge"],
	["Combat & loot", "arena", "echo_delay", "Echo delay (s)", 0.05, 0.3, 0.01, "Next fourth attack; normal damage, no copied charge"],
	["Combat & loot", "arena", "echo_damage_ratio", "Echo / normal shot damage", 0.1, 1, 0.05, "Next scheduled echo; one central shot"],
	["Combat & loot", "arena", "hunter_step", "Hunter additional-hit bonus", 0.01, 0.2, 0.01, "Next direct hit; first hit has no bonus"],
	["Combat & loot", "arena", "hunter_cap", "Hunter maximum bonus", 0.1, 1, 0.05, "Next direct hit; per target"],
	["Combat & loot", "arena", "hunter_duration", "Hunter streak lifetime (s)", 0.5, 6, 0.5, "Next direct hit; gameplay time, pauses stop expiry"],
	["Combat & loot", "arena", "storm_radius", "Storm jump range", 50, 300, 10, "First direct hit per attack"],
	["Combat & loot", "arena", "storm_damage_ratio", "Storm / shot damage", 0.1, 1, 0.05, "Next jump; indirect, no chaining"],
	["Combat & loot", "arena", "phoenix_heal_ratio", "Phoenix max-HP heal ratio", 0.01, 0.05, 0.01, "10 direct hits outside cooldown; max HP cap"],
	["Combat & loot", "arena", "phoenix_cooldown", "Phoenix heal cooldown (s)", 2, 10, 0.5, "Next heal; not reset by gear swapping"],
	["Enemies", "arena", "champion_warning", "Champion warning (s)", 0.2, 2, 0.1, "Next warning; current telegraph kept"],
	["Enemies", "arena", "champion_duration", "Champion rush duration (s)", 0.1, 1, 0.05, "Next warning; path length uses this duration"],
	["Enemies", "arena", "champion_recovery", "Champion recovery (s)", 0.2, 2, 0.1, "Next warning"],
	["Enemies", "arena", "champion_cooldown", "Champion walk cooldown (s)", 0.5, 8, 0.5, "After recovery; next cycle, default 2 s"],
	["Combat & loot", "arena", "equipment_drop_chance", "Item chance per kill (0..1)", 0, 1, 0.01, "First roll; independent of rarity"],
	["Combat & loot", "arena", "drop_chance", "Legendary check per item", 0, 1, 0.005, "First rarity roll; natural Codex limit still applies"],
	["Combat & loot", "arena", "rare_chance", "Rare check after Legendary", 0, 1, 0.01, "Only after Legendary fails or its pool is exhausted"],
	["Combat & loot", "arena", "magic_chance", "Magic check after Rare", 0, 1, 0.01, "Only after higher tiers fail; Normal is guaranteed rest"],
	["Combat & loot", "arena", "ground_loot_limit", "Ground item cap", 1, 64, 1, "Live; existing items are kept"],
	["Combat & loot", "arena", "scepter_damage_bonus", "Ember Scepter damage bonus", 0, 2, 0.05, "Live when equipped; additive with Focus bonus"],
	["Combat & loot", "arena", "scepter_cast_reduction", "Swift Scepter interval reduction", 0, 0.8, 0.05, "Live when equipped; multiplies card interval"],
	["Combat & loot", "arena", "focus_damage_bonus", "Focus Grimoire damage bonus", 0, 2, 0.05, "Live when equipped; replaces Codex splash"],
	["Combat & loot", "arena", "pickup_radius", "Item pickup radius", 10, 100, 1, "Live"],
	["Combat & loot", "arena", "explosion_radius", "Codex explosion radius", 20, 250, 5, "Next impact with Codex"],
	["Combat & loot", "arena", "explosion_damage_ratio", "Codex splash / shot damage", 0, 3, 0.05, "Next impact; excludes the directly hit enemy"],
	["Rewards & tools", "arena", "echoes_per_wave", "Echoes per completed wave tier", 0, 1000, 1, "Wave budget split across pickups; tier * (1 + 2 + ... + cleared)"],
	["Rewards & tools", "arena", "echoes_after_six", "First extra wave reward (wave 7)", 0, 1000, 1, "Pickup budget; waves 1-6 keep their original formula"],
	["Rewards & tools", "arena", "echoes_after_six_growth", "Extra wave reward growth", 0, 100, 1, "Pickup budget; adds 2 per later cleared wave by default"],
	["Skill tree", "arena", "tree_cost_1", "Tier 1 cost", 1, 10000, 1, "Next purchase; refunds keep the paid price"],
	["Skill tree", "arena", "tree_cost_2", "Tier 2 cost", 1, 10000, 1, "Next purchase"],
	["Skill tree", "arena", "tree_cost_3", "Tier 3 cost", 1, 10000, 1, "Next purchase"],
	["Skill tree", "arena", "tree_cost_4", "Notable cost", 1, 10000, 1, "Next purchase"],
	["Skill tree", "arena", "tree_cost_5", "Key node cost", 1, 10000, 1, "Next purchase"],
	["Skill tree", "arena", "tree_power_step", "Power: small node bonus", 0, 0.5, 0.01, "Live for active talents; ownership applies next run"],
	["Skill tree", "arena", "tree_power_notable", "Power: notable bonus", 0, 1, 0.01, "Live for active talents"],
	["Skill tree", "arena", "tree_health_step", "Vitality: small node bonus", 0, 0.5, 0.01, "Live; clamps health, does not heal"],
	["Skill tree", "arena", "tree_health_notable", "Vitality: notable bonus", 0, 1, 0.01, "Live; clamps health, does not heal"],
	["Skill tree", "arena", "tree_flow_step", "Flow: small interval reduction", 0, 0.15, 0.01, "Live; total Flow capped at 60%"],
	["Skill tree", "arena", "tree_flow_notable", "Flow: notable interval reduction", 0, 0.15, 0.01, "Live; total Flow capped at 60%"],
	["Skill tree", "arena", "tree_opening_bonus", "First Spark: direct hit bonus", 0, 2, 0.05, "New projectiles; full-health targets only"],
	["Skill tree", "arena", "tree_wave_heal", "Renewal: max-health ratio", 0, 0.5, 0.01, "Next newly cleared wave"],
	["Skill tree", "arena", "tree_hurt_haste", "Second Wind: interval reduction", 0, 0.8, 0.05, "Live; triggers on actual health loss"],
	["Skill tree", "arena", "tree_haste_duration", "Second Wind: duration (s)", 0.5, 10, 0.5, "Next nonlethal hit"],
	["Skill tree", "arena", "tree_kindling_bonus", "Kindling: direct damage bonus", 0, 2, 0.05, "Next empowered central shot; no Echo or splash"],
	["Skill tree", "arena", "tree_kindling_duration", "Kindling: ready duration (s)", 0.5, 10, 0.5, "Next kill; gameplay time"],
	["Skill tree", "arena", "tree_emberguard_heal", "Emberguard: max-HP heal ratio", 0, 0.5, 0.01, "First nonlethal enemy hit each wave"],
	["Skill tree", "arena", "tree_momentum_bonus", "Momentum: movement speed bonus", 0, 1, 0.01, "Live for active talent; never changes base speed"],
	["Skill tree", "arena", "tree_momentum_duration", "Momentum: duration (s)", 0.5, 10, 0.5, "Next fourth direct hit"],
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
var health_input: SpinBox

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
	for group in ["Metrics", "Player", "Waves", "Enemies", "Combat & loot", "Rewards & tools", "Skill tree", "Test tools"]:
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
	build_test_tools(pages["Test tools"])
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
			enemy.take_damage(enemy.health / enemy.minimum_ratio + enemy.armor if enemy.get_script() == game.GUARDIAN_ENEMY else enemy.health)
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
	var ce3_row := HBoxContainer.new()
	var ce4_row := HBoxContainer.new()
	pages["Rewards & tools"].add_child(ce4_row)
	var ce4_choice := OptionButton.new()
	var ce4_ids := ["echo_scepter", "hunter_scepter", "storm_grimoire", "phoenix_grimoire"]
	for item_id in ce4_ids:
		ce4_choice.add_item(game.CATALOG.ITEMS[item_id].name)
	ce4_row.add_child(ce4_choice)
	var ce4_group := CheckBox.new()
	ce4_group.text = "Group (else single)"
	ce4_row.add_child(ce4_group)
	button(ce4_row, "Start CE4 test", func():
		if game.start_item_test(ce4_ids[ce4_choice.selected], ce4_group.button_pressed):
			sync_controls()
			status.text = "CE4 isolated test ready. Close F1 and aim right."
		else:
			status.text = "Requires -- --test-mode and no pending save error.")
	pages["Rewards & tools"].add_child(ce3_row)
	var ce3_choice := OptionButton.new()
	for build_title in ["Burst + Power + Ember", "Piercing + Fan + Codex", "Overcharge + Quick + Fan"]:
		ce3_choice.add_item(build_title)
	ce3_row.add_child(ce3_choice)
	button(ce3_row, "Start CE3 test", func():
		if game.start_card_test(ce3_choice.selected):
			sync_controls()
			status.text = "Seed 42 isolated CE3 build ready. Close F1 and aim right."
		else:
			status.text = "Requires -- --test-mode and no pending save error.")
	var ce1_row := HBoxContainer.new()
	pages["Rewards & tools"].add_child(ce1_row)
	var build_choice := OptionButton.new()
	for title_text in ["Rapid: Swift + 2 Quick", "Heavy: Ember + Focus + 2 Power", "Area: Ember + Codex + 2 Fan"]:
		build_choice.add_item(title_text)
	ce1_row.add_child(build_choice)
	var role_choice := OptionButton.new()
	for title_text in ["Chaser group", "Cinder Seer", "Rune Guardian"]:
		role_choice.add_item(title_text)
	ce1_row.add_child(role_choice)
	button(ce1_row, "Start CE1 test", func():
		if game.start_counterplay_test(build_choice.selected, role_choice.selected):
			open_console()
			status.text = "CE1 arrangement ready. Close F1 and aim right. Existing tuning kept; talents inactive for this test run."
		else:
			status.text = "Launch with -- --test-mode for isolated CE1 tests. Check pending save errors if already isolated."
	)
	var ascent_row := HBoxContainer.new()
	pages["Rewards & tools"].add_child(ascent_row)
	var wave_input := SpinBox.new()
	wave_input.min_value = 1
	wave_input.max_value = 100
	wave_input.value = 5
	wave_input.custom_minimum_size.x = 120
	ascent_row.add_child(wave_input)
	button(ascent_row, "Jump to wave (isolated)", func():
		if game.start_ascent_test(int(wave_input.value)):
			open_console()
			status.text = "Isolated run reset at selected wave. Existing tuning kept; use gear drops and invulnerability as needed."
		else:
			status.text = "Requires -- --test-mode, a wave within the safety cap, and no pending save error."
	)
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

func build_test_tools(page: VBoxContainer) -> void:
	var help := Label.new()
	help.text = "DEBUG ONLY — changes the currently loaded save (normal or sandbox).\nJump starts wave N and credits waves 1..N-1 immediately. Existing build stays.\nNo skipped cards/items. Forward only; start a new run to test earlier waves.\nWallet edits preserve talents and Restoration. Zero does not cancel future run rewards."
	page.add_child(help)
	var jump_row := HBoxContainer.new()
	page.add_child(jump_row)
	var wave_input := SpinBox.new()
	wave_input.min_value = 1
	wave_input.max_value = 100
	wave_input.value = 5
	jump_row.add_child(wave_input)
	var preview := Label.new()
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var refresh_preview := func():
		var cleared: int = int(wave_input.value) - 1
		preview.text = "Wave %d: through %d cleared; cumulative %d Echoes / %d Restoration (only unpaid difference added)." % [cleared + 1, cleared, game.reward_for_waves(cleared), game.WORLD.reward(cleared, 0, 0, 0)]
	wave_input.value_changed.connect(func(_value: float): refresh_preview.call())
	button(jump_row, "Jump + credit progress", func():
		if game.debug_jump_wave(int(wave_input.value)):
			open_console()
			status.text = "Wave %d ready. Echoes and Restoration saved; build kept." % game.wave
		else:
			status.text = "Jump failed: choose a later wave within the cap; leave the result screen first. " + game.progress.message)
	page.add_child(preview)
	refresh_preview.call()
	var wallet_row := HBoxContainer.new()
	page.add_child(wallet_row)
	var amount := SpinBox.new()
	amount.min_value = 0
	amount.max_value = game.progress.MAX_ECHOES
	amount.value = 1000
	amount.custom_minimum_size.x = 160
	wallet_row.add_child(amount)
	button(wallet_row, "Add Echoes", func(): edit_echoes(game.progress.echoes + int(amount.value)))
	button(wallet_row, "Set Echoes", func(): edit_echoes(int(amount.value)))
	button(wallet_row, "Zero Echoes", func(): edit_echoes(0))
	var health_row := HBoxContainer.new()
	page.add_child(health_row)
	var health_label := Label.new()
	health_label.text = "Current HP (1..effective maximum)"
	health_row.add_child(health_label)
	health_input = SpinBox.new()
	health_input.min_value = 1
	health_input.max_value = game.player.health_limit
	health_input.value = game.player.health
	health_input.custom_minimum_size.x = 130
	health_row.add_child(health_input)
	button(health_row, "Set current HP", func():
		status.text = "Current HP set to %.1f / %.1f." % [game.player.health, game.player.health_limit] if set_current_health(health_input.value) else "Cannot set HP: use a finite value >= 1 during a living run.")
	var actions := HBoxContainer.new()
	page.add_child(actions)
	button(actions, "Restore health", heal_player)
	button(actions, "Finish current wave", func():
		if game.state != game.State.FIGHTING:
			status.text = "Resume combat first (including boss introduction)."
			return
		for enemy in game.enemies.get_children():
			game.enemies.remove_child(enemy)
			enemy.queue_free()
		game.remaining_to_spawn = 0
		close_console()
		game.complete_wave()
		open_console()
		status.text = "Wave cleared without kill loot; normal rewards and card choice apply.")
	button(page, "Reset talents + Echoes + friend story to 0 (town only)", reset_character)
	var friends_row := HBoxContainer.new()
	page.add_child(friends_row)
	button(friends_row, "Friends: unlock both (current save)", func():
		if not game.progress.companions.enabled:
			status.text = "Convert the legacy tree in Emberhaven first (exact refund + backup)."
			return
		var ok: bool = game.progress.rescue_companion("gravity") and game.progress.rescue_companion("prism")
		status.text = "Both friends saved. Return to Emberhaven for purchases; start a new run for Q/E." if ok else game.progress.message
		if game.state == game.State.TOWN: game.town_panel.refresh())
	button(friends_row, "Ready Q/E (current run)", func():
		game.companion_magic.cooldowns.fill(0.0)
		status.text = "Companion cooldowns reset. Close F1, aim and press Q/E.")
	var hint := Label.new()
	hint.text = "Rewards & tools: invulnerability, freeze, any item drop, RNG seed and isolated encounter presets.\nEmberhaven: World Sandbox keeps experimental world progress in a separate save."
	page.add_child(hint)

func edit_echoes(value: int) -> bool:
	var ok: bool = game.progress.debug_set_echoes(value)
	status.text = "Wallet saved: %d Echoes." % game.progress.echoes if ok else game.progress.message
	game.update_hud()
	if game.state == game.State.TOWN:
		game.town_panel.refresh()
	update_metrics()
	return ok

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
	if game.state == game.State.TOWN:
		game.town_panel.restore_focus()
	elif game.inventory_panel.is_open:
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
	metrics.text = "FPS: %d   |   Frame: %.2f ms   |   Static memory: %.1f MiB\nState: %s   |   Active run time: %.1f s   |   Seed: %d\nWave: %d / %d   |   Cleared: %d   |   Best: %d\nEnemies: %d / %d cap   |   Still to spawn: %d   |   Active enemy HP: %.0f\nKills: %d   |   Projectiles alive: %d   |   Projectiles fired / hit: %d / %d\nDamage dealt: %.1f   |   Average run DPS: %.1f   |   Health lost: %.1f\nPlayer: %.0f / %.0f HP   |   Speed: %.0f   |   Protection left: %.2f s\nFireball: %.1f damage   |   %.3f s interval   |   %d projectiles\nCards: %d total   |   Power / Quick / Fan: %d / %d / %d\nCodex active: %s   |   Items on floor: %d   |   Drops this run: %d\nSplash: %.0f radius / %.0f%% damage   |   Legendary check: %.2f%%\nEchoes: %d saved   |   Current payout: %d   |   Saved progress available: %s" % [Engine.get_frames_per_second(), 1000.0 / maxf(Engine.get_frames_per_second(), 1), OS.get_static_memory_usage() / 1048576.0, game.State.keys()[game.state], game.elapsed, game.rng.seed, game.wave, game.total_waves, game.completed_waves, game.best_wave, game.enemies.get_child_count(), game.enemy_limit, game.remaining_to_spawn, total_hp, game.kills, game.projectiles.get_child_count(), game.shots_fired, game.shots_hit, game.damage_dealt, game.damage_dealt / maxf(game.elapsed, 0.001), game.damage_taken, game.player.health, game.player.max_health, game.player.move_speed, game.player.protection, game.player.damage, game.player.cast_interval, game.player.projectile_count, game.upgrades_chosen, game.power_upgrades, game.quick_upgrades, game.fan_upgrades, str(game.codex_active), game.loot.get_child_count(), game.drops_created, game.explosion_radius, game.explosion_damage_ratio * 100, game.drop_chance * 100, game.progress.echoes, game.predicted_reward(), str(game.progress.available)]

	metrics.text += "\nEcho orbs: %d / 48   |   Run earned / collected: %d / %d   |   Save pending: %s" % [game.feel.orbs.size(), game.echo_earned(), game.echo_paid(), str(game.feel.save_pending)]
	metrics.text += "\nBag: %d / 8   |   Scepter: %s   |   Book: %s" % [game.bag_used(), game.equipment.scepter, game.equipment.book]
	metrics.text += "\nDEV prepaid Echoes: %d   |   Save: %s   |   Region Restoration: %.1f%%" % [game.debug_echoes_paid, "SANDBOX" if game.sandbox else ("ISOLATED TEST" if OS.get_cmdline_user_args().has("--test-mode") else "NORMAL"), game.WORLD.fraction(game.progress.world, game.run_region) * 100]
	metrics.text += "\nEcho attacks: %d/4 (pending %s)   |   Hunter targets: %d   |   Phoenix hits: %d/10, cooldown %.1fs" % [game.echo_attacks, str(not game.pending_echo.is_empty()), game.hunter_marks.size(), game.phoenix_hits, game.phoenix_left]
	metrics.text += "\nBurst / Pierce / Overcharge: %s / %s / %s   |   Charge: %d/4 %s" % [str(game.mechanic_cards.has(3)), str(game.mechanic_cards.has(4)), str(game.mechanic_cards.has(5)), game.player.overcharge_hits, "READY" if game.player.overcharge_ready else ""]
	metrics.text += "\nTalents saved / active: %d / %d   |   Echoes invested: %d   |   Second Wind: %.1fs" % [game.progress.talents.size() + game.progress.companions.purchases.size(), game.active_talents.size() + game.companion_magic.talents.size(), game.progress.invested(), game.player.haste_remaining]
	var rates: Dictionary = game.rarity_rates()
	metrics.text += "\nItem chance / kill: %.2f%%   |   Natural Codex available: %s" % [game.equipment_drop_chance * 100, str(not game.codex_spawned)]
	metrics.text += "\nActual share / item (L / R / M / N): %.2f%% / %.2f%% / %.2f%% / %.2f%%" % [rates.legendary * 100, rates.rare * 100, rates.magic * 100, rates.normal * 100]
	metrics.text += "\nActual chance / kill (L / R / M / N): %.3f%% / %.3f%% / %.3f%% / %.3f%%" % [rates.legendary * game.equipment_drop_chance * 100, rates.rare * game.equipment_drop_chance * 100, rates.magic * game.equipment_drop_chance * 100, rates.normal * game.equipment_drop_chance * 100]
	var interruptions: int = 0
	for enemy in game.enemies.get_children():
		if enemy.get_script() == game.RANGED_ENEMY:
			interruptions += enemy.interruptions
	metrics.text += "\nActive seers: %d total interruptions   |   Effective cast interval: %.3fs" % [interruptions, game.player.effective_interval()]
	metrics.text += "\nRun wall time (includes choices / pauses / F1): %.1fs   |   Current wave combat: %.1fs" % [game.run_wall_seconds(), game.wave_seconds]
	for index in range(maxi(0, game.wave_summaries.size() - 5), game.wave_summaries.size()):
		var row: Dictionary = game.wave_summaries[index]
		metrics.text += "\nWave %d %s: %.1fs combat, %.1f HP lost; C/S/G/B %d/%d/%d/%d" % [row.wave, row.boss, row.seconds, row.damage_taken, row.roles.get("chaser", 0), row.roles.get("seer", 0), row.roles.get("guardian", 0), row.roles.get("boss", 0)]

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
		health_input.max_value = game.player.health_limit
		for pickup in game.loot.get_children():
			pickup.pickup_radius = game.pickup_radius
		game.update_hud()
		if game.state == game.State.TOWN:
			game.town_panel.refresh()
		controls[key].set_value_no_signal(float(value))
		return true
	return false

func sync_controls() -> void:
	health_input.max_value = game.player.health_limit
	health_input.set_value_no_signal(maxf(1, game.player.health))
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
	var error: Error = SAFE_JSON.write_object(profile_path, {"version": 10, "values": values})
	status.text = "Profile saved: %s" % ProjectSettings.globalize_path(profile_path) if error == OK else "Profile not saved: %s" % error_string(error)
	return error == OK

func load_profile() -> bool:
	var data: Dictionary = SAFE_JSON.read_object(profile_path)
	if (data.get("version") != 1 and data.get("version") != 2 and data.get("version") != 3 and data.get("version") != 4 and data.get("version") != 5 and data.get("version") != 6 and data.get("version") != 7 and data.get("version") != 8 and data.get("version") != 9 and data.get("version") != 10) or not data.get("values") is Dictionary:
		status.text = "Invalid or missing profile. Nothing changed."
		return false
	var values: Dictionary = data.values
	var version: int = int(data.version)
	var expected: int = 0
	for field in FIELDS:
		if field_version(field) <= version:
			expected += 1
	if values.size() != expected:
		status.text = "Profile has missing or unknown settings. Nothing changed."
		return false
	for field in FIELDS:
		var key: String = field[1] + "." + field[2]
		if field_version(field) > version:
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
	status.text = "Legacy values loaded. Loot uses a per-item rarity cascade; new fields use startup defaults. Saved item chances are preserved; reset defaults for CE4 (5% items) and ascent safety stops." if version < 10 else "Profile loaded. Test switches and progress are not part of profiles."
	return true

func field_version(field: Array) -> int:
	if field[2].begins_with("tree_kindling_") or field[2].begins_with("tree_emberguard_") or field[2].begins_with("tree_momentum_"):
		return 10
	if field[2].begins_with("echo_") or field[2].begins_with("hunter_") or field[2].begins_with("storm_") or field[2].begins_with("phoenix_") or field[2].begins_with("champion_"):
		return 9
	if field[2] in ["burst_radius", "burst_damage_ratio", "overcharge_bonus"]:
		return 8
	if field[2].begins_with("ascent_") or field[2].begins_with("boss_") or field[2].begins_with("echoes_after_"):
		return 7
	if field[2].begins_with("guardian_") or field[2].begins_with("seer_"):
		return 6
	if field[2] in ["rare_chance", "magic_chance"]:
		return 5
	if field[2].begins_with("ranged_"):
		return 4
	if field[2].begins_with("tree_"):
		return 3
	return 2 if field[1] + "." + field[2] in ITEM_FIELDS else 1

func heal_player() -> void:
	if game.state == game.State.FINISHED:
		return
	game.player.health = game.player.health_limit
	game.player.health_changed.emit(game.player.health, game.player.health_limit)

func set_current_health(value: float) -> bool:
	if not OS.is_debug_build() or not is_finite(value) or value < 1 or game.player.health <= 0 or game.state in [game.State.FINISHED, game.State.TOWN]:
		return false
	game.player.health = minf(value, game.player.health_limit)
	# A test edit is not an enemy hit and must not inflate damage-taken metrics.
	game.last_health = game.player.health
	game.player.health_changed.emit(game.player.health, game.player.health_limit)
	health_input.max_value = game.player.health_limit
	health_input.set_value_no_signal(game.player.health)
	return true

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

func reset_character() -> bool:
	if not OS.is_debug_build() or game.state != game.State.TOWN:
		status.text = "Return to Emberhaven first. Reset affects the currently loaded save; regions stay healed."
		return false
	if not game.progress.debug_reset_character():
		status.text = game.progress.message
		return false
	close_console()
	game.restart_run()
	game._show_town()
	open_console()
	status.text = "Reset saved: talents, Echoes and friend rescues cleared. Regions and records preserved."
	return true
