extends CanvasLayer

var game
var is_open: bool = false
var was_paused: bool = false
var previous_controls: bool = true
var screen: Control
var bag_buttons: Array[Button] = []
var slot_buttons: Dictionary = {}
var selected_bag: int = -1
var selected_slot: String = ""
var title: Label
var item_type: Label
var details: RichTextLabel
var comparison: Label
var equipped_stats: Label
var cards_text: RichTextLabel
var effect_stats: Label
var bag_title: Label
var notice: Label
var equip_button: Button
var unequip_button: Button
var drop_button: Button
var destroy_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.theme = Theme.new()
	screen.theme.default_font_size = 16
	add_child(screen)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.06, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(40, 30)
	panel.size = Vector2(1200, 740)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1a2533")
	style.border_color = Color("937952")
	style.set_border_width_all(1)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	screen.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	label(column, "APPRENTICE  /  BUILD & EQUIPMENT", 25, Color("efd2a2"))
	label(column, "Combat is paused. Inspect your build, compare gear and prepare your next move.", 15, Color("aab7c6"))
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	column.add_child(body)
	var equipment := VBoxContainer.new()
	equipment.custom_minimum_size.x = 526
	equipment.add_theme_constant_override("separation", 10)
	body.add_child(equipment)
	label(equipment, "EQUIPMENT & BAG", 18, Color("c9aa7e"))
	var slots := HBoxContainer.new()
	equipment.add_child(slots)
	for slot in ["scepter", "book"]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(244, 62)
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(select_slot.bind(slot))
		button.focus_entered.connect(select_slot.bind(slot))
		button.toggle_mode = true
		slots.add_child(button)
		slot_buttons[slot] = button
	bag_title = label(equipment, "", 14, Color("c9aa7e"))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	equipment.add_child(grid)
	for index in 8:
		var button := Button.new()
		button.custom_minimum_size = Vector2(120, 74)
		button.add_theme_font_size_override("font_size", 13)
		button.toggle_mode = true
		button.pressed.connect(select_bag.bind(index))
		button.focus_entered.connect(select_bag.bind(index))
		grid.add_child(button)
		bag_buttons.append(button)
	var equipment_scroll := ScrollContainer.new()
	equipment_scroll.name = "EquipmentScroll"
	equipment_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	equipment_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	equipment_scroll.focus_mode = Control.FOCUS_ALL
	equipment.add_child(equipment_scroll)
	var inspection := VBoxContainer.new()
	inspection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspection.add_theme_constant_override("separation", 10)
	equipment_scroll.add_child(inspection)
	title = label(inspection, "", 22, Color("efd2a2"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_type = label(inspection, "", 13, Color("aab7c6"))
	details = RichTextLabel.new()
	details.fit_content = true
	details.scroll_active = false
	details.add_theme_font_size_override("normal_font_size", 15)
	inspection.add_child(details)
	comparison = label(inspection, "", 15)
	comparison.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspection.move_child(details, inspection.get_child_count() - 1)
	var build := VBoxContainer.new()
	build.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build.add_theme_constant_override("separation", 10)
	body.add_child(build)
	label(build, "CURRENT BUILD / COMBAT STATS", 18, Color("c9aa7e"))
	equipped_stats = label(build, "", 16)
	var build_scroll := ScrollContainer.new()
	build_scroll.name = "BuildScroll"
	build_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	build_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	build_scroll.focus_mode = Control.FOCUS_ALL
	build.add_child(build_scroll)
	var build_details := VBoxContainer.new()
	build_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_details.add_theme_constant_override("separation", 12)
	build_scroll.add_child(build_details)
	label(build_details, "SELECTED CARDS / RUN EFFECTS", 18, Color("c9aa7e"))
	cards_text = RichTextLabel.new()
	cards_text.bbcode_enabled = true
	cards_text.fit_content = true
	cards_text.scroll_active = false
	cards_text.add_theme_font_size_override("normal_font_size", 16)
	build_details.add_child(cards_text)
	label(build_details, "GEAR, TALENTS & TRIGGERS", 18, Color("c9aa7e"))
	effect_stats = label(build_details, "", 15, Color("baf7ff"))
	effect_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice = label(column, "", 14, Color("edca8b"))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)
	equip_button = action_button(actions, "Equip selected", equip_selected)
	unequip_button = action_button(actions, "Unequip selected", unequip_selected)
	drop_button = action_button(actions, "Put on the ground", drop_selected)
	destroy_button = action_button(actions, "Destroy selected", destroy_selected)
	destroy_button.tooltip_text = "Removes this bag item for the current run. No Echoes or other reward. Equipped items must be unequipped first."
	action_button(actions, "Close  [I / Esc]", close_inventory)
	screen.hide()

func _input(event: InputEvent) -> void:
	if is_instance_valid(game.dev_console) and game.dev_console.is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var inventory_key: bool = event.keycode == KEY_I or event.physical_keycode == KEY_I
		if inventory_key or (is_open and event.keycode == KEY_ESCAPE):
			if is_open:
				close_inventory()
			else:
				open_inventory()
			get_viewport().set_input_as_handled()

func open_inventory() -> void:
	if is_open or game.state in [game.State.FINISHED, game.State.TOWN] or (is_instance_valid(game.dev_console) and game.dev_console.is_open):
		return
	was_paused = get_tree().paused
	previous_controls = game.player.controls_enabled
	game.player.controls_enabled = false
	get_tree().paused = true
	is_open = true
	notice.text = ""
	screen.show()
	selected_bag = -1
	selected_slot = ""
	refresh()
	for index in game.bag.size():
		if not game.bag[index].is_empty():
			bag_buttons[index].grab_focus()
			return
	bag_buttons[0].grab_focus()

func close_inventory() -> void:
	if not is_open:
		return
	is_open = false
	screen.hide()
	game.player.controls_enabled = previous_controls
	get_tree().paused = was_paused
	get_viewport().gui_release_focus()
	if game.overlay.visible and game.buttons.get_child_count() > 0:
		game.buttons.get_child(0).grab_focus()

func restore_focus() -> void:
	if selected_bag >= 0:
		bag_buttons[selected_bag].grab_focus()
	elif not selected_slot.is_empty():
		slot_buttons[selected_slot].grab_focus()
	else:
		bag_buttons[0].grab_focus()

func select_bag(index: int) -> void:
	selected_bag = index
	selected_slot = ""
	refresh()

func select_slot(slot: String) -> void:
	selected_bag = -1
	selected_slot = slot
	refresh()

func refresh() -> void:
	bag_title.text = "BAG  /  %d OF 8 FIELDS USED" % game.bag_used()
	for index in 8:
		var id: String = game.bag[index]
		var button: Button = bag_buttons[index]
		button.text = "%02d\nEmpty" % (index + 1) if id.is_empty() else game.CATALOG.ITEMS[id].name.replace(" ", "\n")
		button.icon = game.CATALOG.icon(id)
		button.add_theme_color_override("font_color", Color("aab7c6") if id.is_empty() else game.CATALOG.color(id))
		button.set_pressed_no_signal(selected_bag == index)
		button.tooltip_text = "Empty bag field" if id.is_empty() else game.CATALOG.ITEMS[id].name + "\n" + game.CATALOG.description(id, game)
	for slot in slot_buttons:
		var id: String = game.equipment[slot]
		var button: Button = slot_buttons[slot]
		button.text = slot.to_upper() + "\n" + ("Empty" if id.is_empty() else game.CATALOG.ITEMS[id].name)
		button.icon = game.CATALOG.icon(id)
		button.add_theme_color_override("font_color", Color("aab7c6") if id.is_empty() else game.CATALOG.color(id))
		button.set_pressed_no_signal(selected_slot == slot)
	refresh_build()
	var selected: String = game.bag[selected_bag] if selected_bag >= 0 else game.equipment.get(selected_slot, "")
	equip_button.disabled = selected.is_empty() or selected_bag < 0
	unequip_button.disabled = selected.is_empty() or selected_slot.is_empty()
	drop_button.disabled = selected.is_empty()
	destroy_button.disabled = selected.is_empty() or selected_bag < 0
	if selected.is_empty():
		title.text = "Choose an item"
		title.add_theme_color_override("font_color", Color("efd2a2"))
		item_type.text = "Picking up is not equipping."
		details.text = "Your bag holds found items for this run.\n\nSelect an item or an equipped slot to read its effect. Equipped items can be changed at any time while this window pauses combat."
		comparison.text = ""
		return
	var item: Dictionary = game.CATALOG.ITEMS[selected]
	title.text = item.name
	title.add_theme_color_override("font_color", game.CATALOG.color(selected))
	item_type.text = "%s %s  /  %s" % [game.CATALOG.label(selected).to_upper(), item.slot.to_upper(), "IN BAG — INACTIVE" if selected_bag >= 0 else "EQUIPPED — ACTIVE"]
	details.text = game.CATALOG.description(selected, game)
	var before: Dictionary = game.build_for(game.equipment.scepter, game.equipment.book)
	var after: Dictionary = before
	if selected_bag >= 0:
		after = game.build_for(selected if item.slot == "scepter" else game.equipment.scepter, selected if item.slot == "book" else game.equipment.book)
	var current: String = game.equipment[item.slot]
	var current_name: String = "Empty" if current.is_empty() else game.CATALOG.ITEMS[current].name
	comparison.text = "%s\nDirect damage: %.1f → %.1f\nEffective cast interval: %.3fs → %.3fs\nCodex splash: %s → %s" % [("Replaces: " + current_name) if selected_bag >= 0 else "Currently equipped", before.damage, after.damage, game.player.interval_with_haste(before.interval), game.player.interval_with_haste(after.interval), "ON" if before.splash else "OFF", "ON" if after.splash else "OFF"]
	if before.splash or after.splash:
		comparison.text += "\nSplash damage: %.1f → %.1f / %.0f radius" % [before.splash_damage, after.splash_damage, game.explosion_radius]
	if selected_bag >= 0 and selected != current:
		comparison.text += "\nGain: " + item_effect(selected) + "\nLose: " + item_effect(current)
	if game.mechanic_cards.has(3):
		comparison.text += "\nEmber Burst on kill: %.1f → %.1f" % [before.burst_damage, after.burst_damage]
	if game.mechanic_cards.has(5):
		comparison.text += "\nCharged main shot: %.1f → %.1f" % [before.charged_damage, after.charged_damage]
	comparison.text += "\nRun cards and talents stay active."

func item_effect(id: String) -> String:
	match id:
		"ember_scepter": return "Ember Scepter (+%.0f%% gear damage)" % (game.scepter_damage_bonus * 100)
		"swift_scepter": return "Swift Scepter (%.0f%% shorter interval)" % (game.scepter_cast_reduction * 100)
		"focus_grimoire": return "Focus Grimoire (+%.0f%% gear damage)" % (game.focus_damage_bonus * 100)
		"cinder_codex": return "Cinder Codex (impact splash, %.0f radius)" % game.explosion_radius
		"echo_scepter": return "Echo Scepter (every 4th attack: one delayed %.0f%% normal shot)" % (game.echo_damage_ratio * (1.3 if game.active_talents.has("flow_10") else 1.0) * 100)
		"hunter_scepter": return "Hunter's Scepter (conditional +%.0f%% per additional target hit, cap %.0f%%)" % [game.hunter_step * 100, game.hunter_cap * 100]
		"storm_grimoire": return "Storm Grimoire (first direct hit: %.0f%% lightning / %.0f range)" % [game.storm_damage_ratio * (1.25 if game.active_talents.has("flow_12") else 1.0) * 100, game.storm_radius * (1.4 if game.active_talents.has("flow_12") else 1.0)]
		"phoenix_grimoire": return "Phoenix Grimoire (10 direct hits: %.2f%% max-HP heal / %.1f s cooldown)" % [game.phoenix_heal_ratio * game.TALENTS.bonuses(game.active_talents, game).heal_multiplier * 100, game.phoenix_cooldown]
	return "none"

func refresh_build() -> void:
	var build: Dictionary = game.build_for(game.equipment.scepter, game.equipment.book)
	equipped_stats.text = "Direct damage / projectile     %.1f\nCast interval                             %.3f s\nProjectiles / cast                       %d\nHealth                                        %.1f / %.1f" % [game.player.damage, game.player.effective_interval(), game.player.projectile_count, game.player.health, game.player.health_limit]
	equipped_stats.text += "\nCodex splash    %.1f damage / %.0f radius" % [build.splash_damage, game.explosion_radius] if build.splash else "\nCodex splash    OFF"
	if game.player.overcharge_ready:
		equipped_stats.text += "\nNext main shot    %.1f (Overcharge READY)" % build.charged_damage
	cards_text.text = ""
	for index in game.UPGRADE_TITLES.size():
		var stacks: int = [game.power_upgrades, game.quick_upgrades, game.fan_upgrades][index] if index < 3 else (1 if game.mechanic_cards.has(index) else 0)
		if stacks <= 0:
			continue
		cards_text.text += "[b]%s%s[/b]\n%s\n\n" % [game.UPGRADE_TITLES[index], " ×%d" % stacks if index < 3 else "", game.card_description(index)]
		if index == 3:
			cards_text.text += "Normal-shot kill: %.1f area damage.\n\n" % build.burst_damage
	if cards_text.text.is_empty():
		cards_text.text = "No run cards selected yet."
	effect_stats.text = "Run gear: " + item_effect(game.equipment.scepter) + "\n" + item_effect(game.equipment.book)
	if game.equipment.scepter == "echo_scepter":
		effect_stats.text += "\nEcho attacks: %d/4%s" % [game.echo_attacks, " — echo pending" if not game.pending_echo.is_empty() else ""]
	if game.equipment.scepter == "hunter_scepter":
		effect_stats.text += "\nHunter: %d separate target streaks; not included in normal-shot damage" % game.hunter_marks.size()
	if game.equipment.book == "phoenix_grimoire":
		effect_stats.text += "\nPhoenix: " + ("cooldown %.1f s; hits not stored" % game.phoenix_left if game.phoenix_left > 0 else "%d/10 direct hits" % game.phoenix_hits)
	if game.player.overcharge_enabled:
		effect_stats.text += "\nOvercharge: " + ("READY — consumed by next main shot" if game.player.overcharge_ready else "%d/4 direct hits" % game.player.overcharge_hits)
	effect_stats.text += "\nTemporary buffs: " + ("Second Wind, %.1f s left (interval shown above)" % game.player.haste_remaining if game.player.haste_remaining > 0 else "none")
	if game.active_talents.has("power_5"):
		effect_stats.text += "\nFirst Spark: +%.0f%% direct damage only against full HP" % (game.tree_opening_bonus * 100)
	if game.active_talents.has("flow_5") and game.player.haste_remaining <= 0:
		effect_stats.text += "\nSecond Wind: available on health loss; currently inactive"
	if game.active_talents.has("vitality_5"):
		effect_stats.text += "\nRenewal: heals %.1f%% max HP on wave clear" % (game.tree_wave_heal * game.TALENTS.bonuses(game.active_talents, game).heal_multiplier * 100)
	if game.active_talents.has("power_1"):
		effect_stats.text += "\nKindling: " + ("READY %.1f s — next central shot" % game.player.kindling_remaining if game.player.kindling_remaining > 0 else "a kill arms the next central shot")
	if game.active_talents.has("vitality_1"):
		effect_stats.text += "\nEmberguard: " + ("used this wave" if game.emberguard_used else "ready for first nonlethal enemy hit")
	if game.active_talents.has("flow_1"):
		effect_stats.text += "\nMomentum: %d/4 hits; speed %.0f%s" % [game.player.momentum_hits, game.player.effective_move_speed(), " (%.1f s left)" % game.player.momentum_remaining if game.player.momentum_remaining > 0 else ""]
	for id in game.active_talents:
		if game.TALENTS.NODES[id].get("special", false):
			effect_stats.text += "\n" + game.TALENTS.NODES[id].name + ": " + game.TALENTS.description(id, game)
	if game.player.last_light:
		effect_stats.text += "\nLast Light: " + ("used this run" if game.player.last_light_used else "ready")
	effect_stats.text += "\nPermanent talents: %d in this run's snapshot" % game.active_talents.size()

func equip_selected() -> void:
	if game.equip_item(selected_bag):
		notice.text = "Equipped. The previous item was returned to your bag."
	refresh()

func unequip_selected() -> void:
	notice.text = "Returned to your bag." if game.unequip_item(selected_slot) else "Your bag is full. Swap with a bag item or put an item on the ground first."
	refresh()

func drop_selected() -> void:
	var success: bool = game.drop_owned_item(selected_bag, selected_slot)
	notice.text = "Placed nearby. Close this window and move to collect it again." if success else "Ground loot is full. Your item has been kept."
	refresh()

func destroy_selected() -> void:
	if game.destroy_bag_item(selected_bag):
		notice.text = "Item destroyed. One bag field is now free."
	refresh()

func label(parent: Node, text: String, font_size: int, color: Color = Color("e7e0d6")) -> Label:
	var control := Label.new()
	control.text = text
	control.add_theme_font_size_override("font_size", font_size)
	control.add_theme_color_override("font_color", color)
	parent.add_child(control)
	return control

func action_button(parent: Node, text: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size = Vector2(210, 42)
	control.pressed.connect(action)
	parent.add_child(control)
	return control
