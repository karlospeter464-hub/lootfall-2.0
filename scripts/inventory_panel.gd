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
var bag_title: Label
var notice: Label
var equip_button: Button
var unequip_button: Button
var drop_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.06, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(40, 90)
	panel.size = Vector2(1200, 620)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1a2533")
	style.border_color = Color("937952")
	style.set_border_width_all(1)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	screen.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	label(column, "APPRENTICE  /  EQUIPMENT", 27, Color("efd2a2"))
	label(column, "Picking up puts an item in your bag. Equip it to activate its effect. Items last for this run only.", 15)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 22)
	column.add_child(body)
	var equipment := VBoxContainer.new()
	equipment.custom_minimum_size.x = 210
	equipment.add_theme_constant_override("separation", 12)
	body.add_child(equipment)
	label(equipment, "EQUIPPED", 15, Color("c9aa7e"))
	for slot in ["scepter", "book"]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(210, 76)
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(select_slot.bind(slot))
		button.focus_entered.connect(select_slot.bind(slot))
		button.toggle_mode = true
		equipment.add_child(button)
		slot_buttons[slot] = button
	equipped_stats = label(equipment, "", 16)
	var bag := VBoxContainer.new()
	bag.custom_minimum_size.x = 414
	bag.add_theme_constant_override("separation", 12)
	body.add_child(bag)
	bag_title = label(bag, "", 15, Color("c9aa7e"))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 10)
	bag.add_child(grid)
	for index in 8:
		var button := Button.new()
		button.custom_minimum_size = Vector2(99, 92)
		button.add_theme_font_size_override("font_size", 13)
		button.toggle_mode = true
		button.pressed.connect(select_bag.bind(index))
		button.focus_entered.connect(select_bag.bind(index))
		grid.add_child(button)
		bag_buttons.append(button)
	label(bag, "Select a bag item to compare it.\nA swap returns the old item to that bag field.\nA full bag leaves ground loot where it is.", 14, Color("aab7c6"))
	var inspection := VBoxContainer.new()
	inspection.custom_minimum_size.x = 450
	inspection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspection.add_theme_constant_override("separation", 12)
	body.add_child(inspection)
	title = label(inspection, "", 24, Color("efd2a2"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_type = label(inspection, "", 14, Color("aab7c6"))
	details = RichTextLabel.new()
	details.custom_minimum_size.y = 150
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_theme_font_size_override("normal_font_size", 16)
	inspection.add_child(details)
	comparison = label(inspection, "", 16)
	notice = label(column, "", 14, Color("edca8b"))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	column.add_child(actions)
	equip_button = action_button(actions, "Equip selected", equip_selected)
	unequip_button = action_button(actions, "Unequip selected", unequip_selected)
	drop_button = action_button(actions, "Put on the ground", drop_selected)
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
		button.set_pressed_no_signal(selected_bag == index)
		button.tooltip_text = "Empty bag field" if id.is_empty() else game.CATALOG.ITEMS[id].name + "\n" + game.CATALOG.description(id, game)
	for slot in slot_buttons:
		var id: String = game.equipment[slot]
		var button: Button = slot_buttons[slot]
		button.text = slot.to_upper() + "\n" + ("Empty" if id.is_empty() else game.CATALOG.ITEMS[id].name)
		button.icon = game.CATALOG.icon(id)
		button.set_pressed_no_signal(selected_slot == slot)
	equipped_stats.text = "CURRENT BUILD\n\nDamage: %.1f\nCast interval: %.3fs\nProjectiles: %d\nSplash: %s" % [game.player.damage, game.player.cast_interval, game.player.projectile_count, "ON" if game.codex_active else "OFF"]
	if game.player.haste_remaining > 0:
		equipped_stats.text += "\nSecond Wind: %.1fs\nActive interval: %.3fs" % [game.player.haste_remaining, game.player.effective_interval()]
	var selected: String = game.bag[selected_bag] if selected_bag >= 0 else game.equipment.get(selected_slot, "")
	equip_button.disabled = selected.is_empty() or selected_bag < 0
	unequip_button.disabled = selected.is_empty() or selected_slot.is_empty()
	drop_button.disabled = selected.is_empty()
	if selected.is_empty():
		title.text = "Choose an item"
		item_type.text = "Picking up is not equipping."
		details.text = "Your bag holds found items for this run.\n\nSelect an item or an equipped slot to read its effect. Equipped items can be changed at any time while this window pauses combat."
		comparison.text = ""
		return
	var item: Dictionary = game.CATALOG.ITEMS[selected]
	title.text = item.name
	item_type.text = "%s  /  %s  /  THIS RUN ONLY" % [item.slot.to_upper(), "IN BAG — INACTIVE" if selected_bag >= 0 else "EQUIPPED — ACTIVE"]
	details.text = game.CATALOG.description(selected, game)
	var before: Dictionary = game.build_for(game.equipment.scepter, game.equipment.book)
	var after: Dictionary = before
	if selected_bag >= 0:
		after = game.build_for(selected if item.slot == "scepter" else game.equipment.scepter, selected if item.slot == "book" else game.equipment.book)
	var current: String = game.equipment[item.slot]
	var current_name: String = "Empty" if current.is_empty() else game.CATALOG.ITEMS[current].name
	comparison.text = "%s\n\nDamage: %.1f → %.1f\nCast interval: %.3fs → %.3fs\nSplash: %s → %s" % [("Replaces: " + current_name) if selected_bag >= 0 else "Currently equipped", before.damage, after.damage, before.interval, after.interval, "ON" if before.splash else "OFF", "ON" if after.splash else "OFF"]

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
	control.custom_minimum_size = Vector2(235, 42)
	control.pressed.connect(action)
	parent.add_child(control)
	return control
